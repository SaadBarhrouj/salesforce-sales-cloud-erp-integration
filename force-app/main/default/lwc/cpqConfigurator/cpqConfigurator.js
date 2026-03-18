import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import OPP_NAME from '@salesforce/schema/Opportunity.Name';
import OPP_ACCOUNT_ID from '@salesforce/schema/Opportunity.AccountId';
import OPP_ACCOUNT_NAME from '@salesforce/schema/Opportunity.Account.Name';
import OPP_PRICEBOOK_ID from '@salesforce/schema/Opportunity.Pricebook2Id';
import OPP_PRICEBOOK_NAME from '@salesforce/schema/Opportunity.Pricebook2.Name';
import { STEPS, MESSAGES, STEP_META, STEP_LIST, TOAST_DURATION } from 'c/cpqConstants';
import { deepClone, calculateCartSubtotal, calculateCartItemTotal, formatCurrency, showToast } from 'c/cpqUtils';

const OPP_FIELDS = [OPP_NAME, OPP_ACCOUNT_ID, OPP_ACCOUNT_NAME, OPP_PRICEBOOK_ID, OPP_PRICEBOOK_NAME];

export default class CpqConfigurator extends LightningElement {
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

    /* ── wizard state ─────────────────────────────── */
    currentStep = STEPS.SELECTION;
    miniCartOpen = false;

    /* ── sidebar state ────────────────────────────── */
    @track sidebarTitle = 'Categories';
    @track sidebarIcon = 'standard:category';
    @track sidebarSortLabel = 'Name';
    @track sidebarItems = [];

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
    @track cartItems = [];
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

    get headerTitle() { return this._stepMeta.label; }
    get headerSubtitle() { return ''; }
    get headerIcon() { return 'standard:product'; }

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
        
        // Offer Type: Sale (Static - NOT a link)
        metadata.push({
            id: 'offerType',
            label: 'Offer Type:',
            value: 'Sale',
            iconName: 'standard:category',
            isLink: false,
            isBold: true
        });
        
        return metadata;
    }

    get headerShowSearch() {
        return this.currentStep.key === STEPS.SELECTION.key;
    }

    get headerSearchPlaceholder() {
        if (this.currentStep.key === STEPS.SELECTION.key) return 'Search products...';
        return 'Search...';
    }

    get _stepMeta() {
        return STEP_META[this.currentStep.key] || STEP_META[STEPS.SELECTION.key];
    }

    get headerStepActions() {
        if (this.isStepSelection) {
            return [
                { name: 'cancel', label: 'Cancel', variant: 'neutral' },
                { name: 'select', label: 'Select', variant: 'brand', disabled: this.cartItems.length === 0 }
            ];
        }
        return [
            { name: 'back', label: 'Back', variant: 'neutral' },
            { name: 'save', label: 'Save', variant: 'neutral' },
            { name: 'next', label: 'Next', variant: 'brand' }
        ];
    }

    get headerGlobalActions() {
        if (this.isStepSelection) {
            const selectionStep = this._getSelectionStep();
            const filtersOpen = selectionStep?.filterPanelOpen;
            return [
                { name: 'refresh', label: 'Refresh Catalog', iconName: 'utility:refresh' },
                {
                    name: 'changeView', label: 'Change View', iconName: 'utility:table', isMenu: true, variant: 'border-filled',
                    menuItems: [
                        { name: 'viewTable', label: 'Table View', iconName: 'utility:table' },
                        { name: 'viewCards', label: 'Card View', iconName: 'utility:rows' }
                    ]
                },
                {
                    name: 'selectionGroup', isGroup: true, items: [
                        { name: 'clearSelection', label: 'Clear Selection', iconName: 'utility:clear', variant: 'border-filled' },
                        { name: 'toggleFilters', label: 'Filters', iconName: 'utility:filterList', variant: filtersOpen ? 'brand' : 'border-filled' }
                    ]
                }
            ];
        }
        return [
            { name: 'settings', label: 'List View Controls', variant: 'border-filled', iconName: 'utility:settings', isMenu: true },
            { name: 'refresh', label: 'Refresh List', variant: 'border-filled', iconName: 'utility:refresh' }
        ];
    }

    get _canAdvance() {
        if (this.currentStep.key === STEPS.SELECTION.key) return this.cartItems.length > 0;
        return true;
    }


    get formattedSubtotal() {
        const discount = this.quoteState.additionalDiscountPercent || 0;
        const subtotal = calculateCartSubtotal(this.cartItems, discount);
        return formatCurrency(subtotal);
    }


    /* -- header actions -- */
    handleHeaderAction(event) {
        const action = event.detail.action;
        if (action === 'back') this._goBack();
        else if (action === 'next') this._goNext();
        else if (action === 'select') this._goNext();
        else if (action === 'save') this._triggerSave();
        else if (action === 'cancel') this._showToast('Configuration cancelled', 'error');
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
        this.cartItems = [];
    }

    /* ── Sidebar Data Management ──────────────────── */
    
    initSidebarData(stepKey) {
        if (stepKey === STEPS.SELECTION.key) {
            this._loadCategoriesSidebar();
        } else if (stepKey === STEPS.CONFIGURE.key) {
            this._loadBundlesSidebar();
        } else if (stepKey === STEPS.LINE_EDITOR.key) {
            this._loadLinesSidebar();
        } else {
            this._loadDetailsSidebar();
        }
    }

    _loadCategoriesSidebar() {
        this.sidebarTitle = 'Categories';
        this.sidebarIcon = 'standard:product';
        this.sidebarSortLabel = 'Name';
        this.sidebarItems = [
            { 
                id: 'cat-001', 
                label: 'Electronics', 
                value: '12', 
                children: [
                    { id: 'cat-001-1', label: 'Computers', value: '5' },
                    { id: 'cat-001-2', label: 'Peripherals', value: '7' }
                ]
            },
            { 
                id: 'cat-002', 
                label: 'Furniture', 
                value: '8', 
                children: [
                    { id: 'cat-002-1', label: 'Desks', value: '3' },
                    { id: 'cat-002-2', label: 'Chairs', value: '5' }
                ]
            },
            { 
                id: 'cat-003', 
                label: 'Software Licenses', 
                value: '5'
            },
            { 
                id: 'cat-004', 
                label: 'Services', 
                value: '3'
            }
        ];
    }

    _loadBundlesSidebar() {
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

    _loadLinesSidebar() {
        this.sidebarTitle = 'Lines';
        this.sidebarIcon = 'standard:list_item';
        this.sidebarSortLabel = 'Added Date';
        this.sidebarItems = (this.cartItems || []).map((item, idx) => ({
            id: item._key,
            label: item.productName,
            value: item.quantity.toString()
        }));
    }

    _loadDetailsSidebar() {
        this.sidebarTitle = 'Details';
        this.sidebarIcon = 'standard:info';
        this.sidebarSortLabel = 'Field';
        this.sidebarItems = [
            { id: 'det-001', label: 'Account', value: this.quoteState.accountName },
            { id: 'det-002', label: 'Start Date', value: this.quoteState.startDate },
            { id: 'det-003', label: 'Term', value: `${this.quoteState.subscriptionTerm}m` }
        ];
    }

    handleSidebarItemSelect(event) {
        const { selectedItemId } = event.detail;
        this._showToast('Selection', `Selected item: ${selectedItemId}`, 'success');
    }

    handleSidebarRefresh(event) {
        this._showToast('Refresh', 'Sidebar data refreshed', 'success');
        this.initSidebarData(this.currentStep.key);
    }

    /* ── Step 1 events ── */
    handleProductAdd(event) {
        const cartItem = deepClone(event.detail.cartItem);
        const discount = this.quoteState.additionalDiscountPercent || 0;
        cartItem._formattedTotal = formatCurrency(calculateCartItemTotal(cartItem, discount));
        const items = deepClone(this.cartItems);
        items.push(cartItem);
        this.cartItems = items;
        this._showToast(`${cartItem.productName} added to cart`, 'success');
    }

    handleProductRemove(event) {
        const { productId } = event.detail;
        const items = deepClone(this.cartItems).filter(i => i.productId !== productId);
        this.cartItems = items;
        this._showToast('Success', 'Product removed', 'success');
    }

    /* -- Step 3 events -- */
    handleConfigUpdate(event) {
        const { itemKey, options, configured } = event.detail;
        const items = deepClone(this.cartItems);
        const discount = this.quoteState.additionalDiscountPercent || 0;
        const idx = items.findIndex(i => i._key === itemKey);
        if (idx !== -1) {
            items[idx].options = deepClone(options);
            items[idx].configured = configured;
            items[idx]._formattedTotal = formatCurrency(calculateCartItemTotal(items[idx], discount));
        }
        this.cartItems = items;
    }

    /* -- Step 4 events -- */
    handleLineUpdate(event) {
        const { itemKey, field, value, optionId } = event.detail;
        const items = deepClone(this.cartItems);
        const discount = this.quoteState.additionalDiscountPercent || 0;
        const idx = items.findIndex(i => i._key === itemKey);
        if (idx !== -1) {
            if (field === 'quantity') items[idx].quantity = value;
            else if (field === 'additionalDiscount') items[idx].additionalDiscount = value;
            else if (field === 'optionQuantity' && optionId) {
                const opt = (items[idx].options || []).find(o => o.Id === optionId);
                if (opt) opt.quantity = value;
            }
            items[idx]._formattedTotal = formatCurrency(calculateCartItemTotal(items[idx], discount));
        }
        this.cartItems = items;
    }

    handleLineRemove(event) {
        const { itemKey } = event.detail;
        const items = deepClone(this.cartItems).filter(i => i._key !== itemKey);
        this.cartItems = items;
        this._showToast('Removed', 'Line item removed', 'success');
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

    _recalcAllTotals() {
        const discount = this.quoteState.additionalDiscountPercent || 0;
        const items = deepClone(this.cartItems);
        items.forEach(item => {
            item._formattedTotal = formatCurrency(calculateCartItemTotal(item, discount));
        });
        this.cartItems = items;
    }

    _triggerSave() {
        this._showToast('Success', MESSAGES.SAVE_SUCCESS, 'success');
    }

    _showToast(title, message, variant = 'success') {
        showToast(this, title, message, variant);
    }
}
