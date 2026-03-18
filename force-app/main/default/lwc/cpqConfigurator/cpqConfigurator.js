import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import OPP_NAME from '@salesforce/schema/Opportunity.Name';
import OPP_ACCOUNT_ID from '@salesforce/schema/Opportunity.AccountId';
import OPP_ACCOUNT_NAME from '@salesforce/schema/Opportunity.Account.Name';
import { STEPS, MESSAGES, STEP_META, STEP_LIST } from 'c/cpqConstants';
import { deepClone, calculateCartSubtotal, calculateCartItemTotal, formatCurrency } from 'c/cpqUtils';

const OPP_FIELDS = [OPP_NAME, OPP_ACCOUNT_ID, OPP_ACCOUNT_NAME];

const TOAST_DURATION = 4000;

export default class CpqConfigurator extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api opportunityNumber;

    /* ── wire data ────────────────────────────────── */
    @wire(getRecord, { recordId: '$recordId', fields: OPP_FIELDS })
    opportunityRecord;

    /* ── wizard state ─────────────────────────────── */
    currentStep = STEPS.SELECTION;
    miniCartOpen = false;
    @track isSidebarOpen = true;

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

    /* ── toast state ──────────────────────────────── */
    toastMessage = '';
    toastVariant = 'success';
    _toastTimer;

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
            if (accountName) {
                metadata.push({
                    id: 'account',
                    label: accountName,
                    value: '#', // Link placeholder
                    iconName: 'standard:account',
                    isLink: true,
                    isBold: false
                });
            }
        }
        
        // Pricebook - as LINK
        metadata.push({
            id: 'pricebook',
            label: 'Standard Pricebook',
            value: '#', // Link placeholder
            iconName: 'standard:pricebook',
            isLink: true,
            isBold: false
        });
        
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
        // Dynamic placeholder based on step
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

    /* -- sidebar -- */
    get sidebarClass() {
        return this.isSidebarOpen ? 'cpq-sidebar is-open' : 'cpq-sidebar is-closed';
    }

    get sidebarTitle() {
        if (this.currentStep.key === STEPS.SELECTION.key) return 'Categories';
        if (this.currentStep.key === STEPS.CONFIGURE.key) return 'Bundles';
        if (this.currentStep.key === STEPS.LINE_EDITOR.key) return 'Lines';
        return 'Details';
    }

    get sidebarToggleIcon() {
        return this.isSidebarOpen ? 'utility:chevronleft' : 'utility:chevronright';
    }

    get sidebarLeverLabel() {
        return (this._stepMeta.label || '').toUpperCase();
    }

    /* -- cart helpers -- */
    get cartCount() { return this.cartItems.length; }

    get isCartVisible() {
        return this.currentStep.key !== STEPS.LOGISTICS.key && this.currentStep.key !== STEPS.REVIEW.key;
    }

    get showMiniCart() {
        return this.isCartVisible && this.miniCartOpen && this.cartItems.length > 0;
    }

    get miniCartClass() {
        return 'mini-cart slds-box slds-theme_default';
    }

    get numberedCartItems() {
        return this.cartItems.map((item, idx) => ({
            ...item,
            _lineNumber: idx + 1
        }));
    }

    get formattedSubtotal() {
        const discount = this.quoteState.additionalDiscountPercent || 0;
        const subtotal = calculateCartSubtotal(this.cartItems, discount);
        return formatCurrency(subtotal);
    }

    /* -- toast -- */
    get toastClass() {
        const base = 'toast-bar slds-notify slds-notify_toast slds-grid slds-grid_vertical-align-center';
        return this.toastVariant === 'error'
            ? `${base} slds-theme_error`
            : `${base} slds-theme_success`;
    }
    get toastIcon() {
        return this.toastVariant === 'error' ? 'utility:error' : 'utility:success';
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

    toggleSidebar() {
        this.isSidebarOpen = !this.isSidebarOpen;
    }


    /* -- Step 1 events -- */
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
        this._showToast('Product removed', 'success');
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
        this._showToast('Line item removed', 'success');
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

    /* -- mini-cart -- */
    toggleMiniCart() {
        this.miniCartOpen = !this.miniCartOpen;
    }

    /* -- toast -- */
    closeToast() {
        this.toastMessage = '';
        clearTimeout(this._toastTimer);
    }

    /* ═══════════════════════════════════════════════
       NAVIGATION
       ═══════════════════════════════════════════════ */

    _goNext() {
        const idx = STEP_LIST.findIndex(s => s.key === this.currentStep.key);
        if (idx < STEP_LIST.length - 1 && this._canAdvance) {
            this.currentStep = STEP_LIST[idx + 1];
        }
    }

    _goBack() {
        const idx = STEP_LIST.findIndex(s => s.key === this.currentStep.key);
        if (idx > 0) {
            this.currentStep = STEP_LIST[idx - 1];
        }
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
        this._showToast(MESSAGES.SAVE_SUCCESS, 'success');
    }

    _showToast(message, variant = 'success') {
        clearTimeout(this._toastTimer);
        this.toastMessage = message;
        this.toastVariant = variant;
        this._toastTimer = setTimeout(() => {
            this.toastMessage = '';
        }, TOAST_DURATION);
    }
}
