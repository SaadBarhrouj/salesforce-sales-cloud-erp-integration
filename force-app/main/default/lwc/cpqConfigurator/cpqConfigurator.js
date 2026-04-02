import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue, getFieldDisplayValue } from 'lightning/uiRecordApi';
import OPP_NAME from '@salesforce/schema/Opportunity.Name';
import OPP_ACCOUNT_ID from '@salesforce/schema/Opportunity.AccountId';
import OPP_ACCOUNT_NAME from '@salesforce/schema/Opportunity.Account.Name';
import OPP_PRICEBOOK_ID from '@salesforce/schema/Opportunity.Pricebook2Id';
import OPP_PRICEBOOK_NAME from '@salesforce/schema/Opportunity.Pricebook2.Name';
import OPP_OFFER_TYPE from '@salesforce/schema/Opportunity.Offer_Type__c';
import getSidebarCategoriesByOfferType from '@salesforce/apex/ProductCategoryController.getSidebarCategoriesByOfferType';
import { STEPS, MESSAGES, STEP_LIST, TOAST_DURATION } from 'c/cpqConstants';
import { deepClone, calculateSelectedProductsSubtotal, calculateSelectedProductTotal, formatCurrency, showToast } from 'c/cpqUtils';

const OPP_FIELDS = [OPP_NAME, OPP_ACCOUNT_ID, OPP_ACCOUNT_NAME, OPP_PRICEBOOK_ID, OPP_PRICEBOOK_NAME ,OPP_OFFER_TYPE];

export default class CpqConfigurator extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;
    @api opportunityNumber;

    /* ── wire data ────────────────────────────────── */
    @wire(getRecord, { recordId: '$recordId', fields: OPP_FIELDS })
    opportunityRecord;

    /* ── lifecycle ────────────────────────────────── */
    connectedCallback() {
        // Initialize sidebar data when component mounts
        this.initSidebarData(this.currentStep.key);
    }

    _goNext() {
        const currentIndex = STEP_LIST.findIndex(s => s.key === this.currentStep.key);
        if (currentIndex < STEP_LIST.length - 1) {
            this.currentStep = STEP_LIST[currentIndex + 1];
            this.initSidebarData(this.currentStep.key);
        }
    }

    _goBack() {
        const currentIndex = STEP_LIST.findIndex(s => s.key === this.currentStep.key);
        if (currentIndex > 0) {
            this.currentStep = STEP_LIST[currentIndex - 1];
            this.initSidebarData(this.currentStep.key);
        }
    }

    /* ── wizard state ─────────────────────────────── */
    currentStep = STEPS.SELECTION;

    /* ── sidebar state ────────────────────────────── */
    @track sidebarTitle = 'Categories';
    @track sidebarIcon = 'standard:category';
    @track sidebarSortLabel = 'Name';
    @track sidebarIsLoading = false;
    @track sidebarItems = [];
    @track selectedItemId = '';
    @track selectedItemLabel = '';

    /* ── domain state ─────────────────────────────── */
    @track quoteState = {
        accountId: '',
        accountName: '',
        contactId: '',
        contactName: '',
        catalogId: '',
        catalogName: '',
        startDate: new Date().toISOString().split('T')[0],
        subscriptionTerm: 12,
        additionalDiscountPercent: 0
    };
    @track selectedProducts = [];
    @track logisticsState = {
        isTransportRequired: false,
        deliverySite: '',
        transportAgency: '',
        transportUrgency: '',
        notes: ''
    };

    /* ═══════════════════════════════════════════════
       GETTERS
       ═══════════════════════════════════════════════ */

    /* -- step booleans -- */
    get isStepSelection() { return this.currentStep.key === STEPS.SELECTION.key; }
    get isStepConfigure() { return this.currentStep.key === STEPS.CONFIGURE.key; }
    get isStepLineEditor() { return this.currentStep.key === STEPS.LINE_EDITOR.key; }
    get isStepLogistics() { return this.currentStep.key === STEPS.LOGISTICS.key; }
    get isStepReview() { return this.currentStep.key === STEPS.REVIEW.key; }

    /* -- header -- */
    get headerTopLabel() {
        if (this.opportunityRecord?.data) {
            const name = getFieldValue(this.opportunityRecord.data, OPP_NAME);
            if (name) return name;
        }
        return this.recordId || 'OPP-000000';
    }
    get headerTitle() { return this.currentStep.label; }
    get headerSubtitle() { return this.currentStep.subtitle || ''; }
    get headerIcon() { return this.currentStep.icon || 'standard:product'; }
    get headerMetadata() {
        const metadata = [];
        
        // Account - as LINK
        if (this.opportunityRecord?.data) {
            const accountName = getFieldValue(this.opportunityRecord.data, OPP_ACCOUNT_NAME);
            const accountId = getFieldValue(this.opportunityRecord.data, OPP_ACCOUNT_ID);
            if (accountName) {
                metadata.push({
                    id: 'account',
                    label: accountName,
                    value: accountId, // Link value (recordId)
                    iconName: 'standard:account',
                    isLink: true,
                    isBold: false,
                    objectApiName: 'Account'
                });
            }
        }
        
        // Pricebook - as LINK
        if (this.opportunityRecord?.data) {
            const pbName = getFieldValue(this.opportunityRecord.data, OPP_PRICEBOOK_NAME);
            const pbId = getFieldValue(this.opportunityRecord.data, OPP_PRICEBOOK_ID);
            
            
            metadata.push({
                id: 'pricebook',
                label: pbName || 'Standard Pricebook',
                value: pbId || '#', 
                iconName: 'standard:pricebook',
                isLink: true,
                isBold: false,
                objectApiName: 'Pricebook2'
            });
        } else {
            metadata.push({
                id: 'pricebook',
                label: 'Standard Pricebook',
                value: '#', 
                iconName: 'standard:pricebook',
                isLink: true,
                isBold: false,
                objectApiName: 'Pricebook2'
            });
        }
        
        if (this.opportunityRecord?.data) {
           const offerTypeLabel = getFieldDisplayValue(this.opportunityRecord.data, OPP_OFFER_TYPE);
           const offerType = offerTypeLabel ? offerTypeLabel : getFieldValue(this.opportunityRecord.data, OPP_OFFER_TYPE);
            // Offer Type: 
            metadata.push({
                id: 'offerType',
                label: 'Offer Type:',
                value: offerType || 'Sale',
                iconName: 'standard:category',
                isLink: false,
                isBold: true
            });
        }

        return metadata;
    }
    get headerShowSearch() {
        return this.currentStep.header?.showSearch || false;
    }

    get headerSearchPlaceholder() {
        return this.currentStep.header?.searchPlaceholder || 'Search...';
    }

    get headerStepActions() {
        const actions = deepClone(this.currentStep.header?.stepActions || []);
        return actions.map(action => {
            if (action.dynamicProperty === 'disableIfCartEmpty') {
                action.disabled = (this.selectedProducts || []).length === 0;
            }
            return action;
        });
    }

    get headerGlobalActions() {
        const actions = deepClone(this.currentStep.header?.globalActions || []);
        const filtersOpen = this._getSelectionStep()?.filterPanelOpen;

        return actions.map(action => {
            if (action.isGroup && action.items) {
                action.items = action.items.map(item => {
                    if (item.dynamicProperty === 'highlightIfFiltersOpen') {
                        item.variant = filtersOpen ? 'brand' : 'border-filled';
                    }
                    return item;
                });
            }
            return action;
        });
    }


    /* -- header actions -- */
    handleHeaderAction(event) {
        const action = event.detail.action;
        if (action === 'back') this._goBack();
        else if (action === 'next') this._goNext();
        else if (action === 'select') this._goNext();
        else if (action === 'save') this._triggerSave();
        else if (action === 'cancel') this._navigateToOpportunity();
        else if (action === 'refresh') this._getSelectionStep()?.refreshProducts();
        else if (action === 'clearSelection') this._handleClearSelection();
        else if (action === 'toggleFilters') this._getSelectionStep()?.toggleFilterPanel();
        else if (action === 'viewTable') this._getSelectionStep()?.setViewMode('table');
        else if (action === 'viewCards') this._getSelectionStep()?.setViewMode('cards');
    }

    handleHeaderSearch(event) {
        const searchValue = event.detail.searchValue;
        const step = this._getSelectionStep();
        if (step) step.handleSearchInput(searchValue);
    }

    _getSelectionStep() {
        return this.template.querySelector('c-cpq-step-selection');
    }

    _handleClearSelection() {
        this.selectedProducts = [];
    }

    /* ── Sidebar Data Management ──────────────────── */
    
    initSidebarData(stepKey) {
        if (stepKey === STEPS.SELECTION.key) {
            this._loadSelectionSidebar();
        } else if (stepKey === STEPS.CONFIGURE.key) {
            this._loadConfigureSidebar();
        } else if (stepKey === STEPS.LINE_EDITOR.key) {
            this._loadLineEditorSidebar();
        } else {
            this._loadReviewSidebar();
        }
    }

    _loadSelectionSidebar() {
        this.sidebarTitle = 'Categories';
        this.sidebarIcon = 'standard:product';
        this.sidebarSortLabel = 'Products';

        if (!this.recordId) {
            this.sidebarItems = [];
            this._showToast('Error', 'Opportunity ID not available', 'error');
            return;
        }

        this.sidebarIsLoading = true;
        getSidebarCategoriesByOfferType({ opportunityId: this.recordId })
            .then(result => {
                this.sidebarItems = result || [];
            })
            .catch(error => {
                console.error('Error loading sidebar categories:', error);
                this._showToast('Error', 'Failed to load categories', 'error');
                this.sidebarItems = [];
            })
            .finally(() => {
                this.sidebarIsLoading = false;
            });
    }

    _loadConfigureSidebar() {
        this.sidebarTitle = 'Bundles';
        this.sidebarIcon = 'standard:bundle';
        this.sidebarSortLabel = 'Price';
        this.sidebarItems = [
            { 
                id: 'bun-001', 
                label: 'Starter Pack', 
                value: '2', 
                children: [
                    { id: 'bun-001-1', label: 'Option 1', value: '$99' }
                ]
            },
            { 
                id: 'bun-002', 
                label: 'Professional', 
                value: '4', 
                children: [
                    { id: 'bun-002-1', label: 'Option 1', value: '$199' },
                    { id: 'bun-002-2', label: 'Option 2', value: '$149' }
                ]
            },
            { 
                id: 'bun-003', 
                label: 'Enterprise', 
                value: '6'
            },
            { 
                id: 'bun-004', 
                label: 'Custom Bundle', 
                value: '8'
            }
        ];
    }

    _loadLineEditorSidebar() {
        this.sidebarTitle = 'Lines';
        this.sidebarIcon = 'standard:list_item';
        this.sidebarSortLabel = 'Added Date';
        this.sidebarItems = (this.selectedProducts || []).map((item, idx) => ({
            id: item._key,
            label: item.productName,
            value: item.quantity.toString()
        }));
    }

    _loadReviewSidebar() {
        this.sidebarTitle = 'Details';
        this.sidebarIcon = 'standard:info';
        this.sidebarSortLabel = 'Field';
        this.sidebarItems = [
            { id: 'det-001', label: 'Account', value: this.quoteState.accountName },
            { id: 'det-002', label: 'Start Date', value: this.quoteState.startDate },
            { id: 'det-003', label: 'Term', value: `${this.quoteState.subscriptionTerm}m` }
        ];
    }
    
    handleItemSelect(event) {
        const { selectedItemId } = event.detail;
        const selectedItem = this._findSidebarItemById(selectedItemId);
        this.selectedItemId = selectedItem ? selectedItem.id : '';
        this.selectedItemLabel = selectedItem ? selectedItem.label : '';
    }

    handleItemDeselect() {
        this.selectedItemId = '';
        this.selectedItemLabel = '';
    }

    _findSidebarItemById(itemId) {
        for (const item of this.sidebarItems) {
            if (item.id === itemId) {
                return item;
            }
            if (item.children) {
                for (const child of item.children) {
                    if (child.id === itemId) {
                        return child;
                    }
                }
            }
        }
        return null;
    }

    handleSidebarRefresh(event) {
       this.initSidebarData(this.currentStep.key);
    }

    /* ── Step 1 events ── */
    handleProductAdd(event) {
        const cartItem = deepClone(event.detail.cartItem);
        const discount = this.quoteState.additionalDiscountPercent || 0;
        cartItem._formattedTotal = formatCurrency(calculateSelectedProductTotal(cartItem, discount));
        const items = deepClone(this.selectedProducts);
        items.push(cartItem);
        this.selectedProducts = items;
    }

    handleProductRemove(event) {
        const { productId } = event.detail;
        const items = deepClone(this.selectedProducts).filter(i => i.productId !== productId);
        this.selectedProducts = items;
    }

    /* -- Step 3 events -- */
    handleConfigUpdate(event) {
        const { itemKey, options, configured } = event.detail;
        const items = deepClone(this.selectedProducts);
        const discount = this.quoteState.additionalDiscountPercent || 0;
        const idx = items.findIndex(i => i._key === itemKey);
        if (idx !== -1) {
            items[idx].options = deepClone(options);
            items[idx].configured = configured;
            items[idx]._formattedTotal = formatCurrency(calculateSelectedProductTotal(items[idx], discount));
        }
        this.selectedProducts = items;
    }

    /* -- Step 4 events -- */
    handleLineUpdate(event) {
        const { itemKey, field, value, optionId } = event.detail;
        const items = deepClone(this.selectedProducts);
        const discount = this.quoteState.additionalDiscountPercent || 0;
        const idx = items.findIndex(i => i._key === itemKey);
        if (idx !== -1) {
            if (field === 'quantity') items[idx].quantity = value;
            else if (field === 'additionalDiscount') items[idx].additionalDiscount = value;
            else if (field === 'optionQuantity' && optionId) {
                const opt = (items[idx].options || []).find(o => o.Id === optionId);
                if (opt) opt.quantity = value;
            }
            items[idx]._formattedTotal = formatCurrency(calculateSelectedProductTotal(items[idx], discount));
        }
        this.selectedProducts = items;
    }

    handleLineRemove(event) {
        const { itemKey } = event.detail;
        const items = deepClone(this.selectedProducts).filter(i => i._key !== itemKey);
        this.selectedProducts = items;
    }

    handleGlobalDiscount(event) {
        const disc = event.detail.value;
        const qs = deepClone(this.quoteState);
        qs.additionalDiscountPercent = disc;
        this.quoteState = qs;
        this._recalcAllTotals();
    }

    /* -- Step 5 events -- */
    handleLogisticsChange(event) {
        this.logisticsState = deepClone(event.detail.logistics);
    }

    handleSaveQuote() {
        this._triggerSave();
    }

    /* -- child navigate -- */
    handleNavigate(event) {
        const direction = event.detail.direction || event.detail;
        if (direction === 'next') this._goNext();
        else if (direction === 'back') this._goBack();
    }


    /* ═══════════════════════════════════════════════
       HELPERS
       ═══════════════════════════════════════════════ */

    _navigateToOpportunity() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Opportunity',
                actionName: 'view'
            }
        });
    }

    _recalcAllTotals() {
        const discount = this.quoteState.additionalDiscountPercent || 0;
        const items = deepClone(this.selectedProducts);
        items.forEach(item => {
            item._formattedTotal = formatCurrency(calculateSelectedProductTotal(item, discount));
        });
        this.selectedProducts = items;
    }

    _triggerSave() {
        this._showToast('Success', MESSAGES.SAVE_SUCCESS, 'success');
    }

    _showToast(title, message, variant = 'success') {
        showToast(this, title, message, variant);
    }
}