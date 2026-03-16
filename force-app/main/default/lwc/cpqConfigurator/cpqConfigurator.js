import { LightningElement, api, track } from 'lwc';
import { STEPS, MESSAGES } from 'c/cpqConstants';
import { deepClone, calculateCartSubtotal, calculateCartItemTotal, formatCurrency } from 'c/cpqUtils';

const STEP_META = [
    { value: STEPS.SELECTION, label: 'Configure Products', icon: 'standard:product', subtitle: 'Select and configure products' },
    { value: STEPS.CONFIGURE, label: 'Bundle Configuration', icon: 'standard:bundle_policy', subtitle: 'Configure bundles and options' },
    { value: STEPS.LINE_EDITOR, label: 'Line Editor', icon: 'standard:order_item', subtitle: 'Review and adjust line items' },
    { value: STEPS.LOGISTICS, label: 'Logistics', icon: 'standard:shipment', subtitle: 'Delivery options' },
    { value: STEPS.REVIEW, label: 'Review & Save', icon: 'standard:task', subtitle: 'Verify everything before saving' }
];

const TOAST_DURATION = 4000;

export default class CpqConfigurator extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api opportunityNumber;

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
    get isStepSelection() { return this.currentStep === STEPS.SELECTION; }
    get isStepConfigure() { return this.currentStep === STEPS.CONFIGURE; }
    get isStepLineEditor() { return this.currentStep === STEPS.LINE_EDITOR; }
    get isStepLogistics() { return this.currentStep === STEPS.LOGISTICS; }
    get isStepReview() { return this.currentStep === STEPS.REVIEW; }

    /* -- header -- */
    get headerTopLabel() { return this.opportunityNumber || this.recordId || 'OPP-000000'; }
    get headerTitle() { return this._stepMeta.label; }
    get headerSubtitle() { return ''; }
    get headerIcon() { return 'standard:opportunity'; }

    get _stepMeta() {
        return STEP_META.find(s => s.value === this.currentStep) || STEP_META[0];
    }

    get headerStepActions() {
        return [
            { name: 'filter', label: 'Filter', variant: 'neutral', iconName: 'utility:filterList' },
            { name: 'addProducts', label: 'Add Products', variant: 'neutral', iconName: 'utility:add' },
            { name: 'calculate', label: 'Calculate', variant: 'neutral', iconName: 'utility:moneybag' }
        ];
    }

    get headerGlobalActions() {
        return [
            { name: 'cancel', label: 'Cancel', variant: 'neutral', iconName: 'utility:close' },
            { name: 'save', label: 'Save', variant: 'neutral', iconName: 'utility:save', disabled: this.currentStep !== STEPS.REVIEW }
        ];
    }

    get _canAdvance() {
        if (this.currentStep === STEPS.SELECTION) return this.cartItems.length > 0;
        return true;
    }

    /* -- sidebar -- */
    get sidebarClass() {
        return this.isSidebarOpen ? 'cpq-sidebar is-open' : 'cpq-sidebar is-closed';
    }

    get sidebarTitle() {
        if (this.currentStep === STEPS.SELECTION) return 'Categories';
        if (this.currentStep === STEPS.CONFIGURE) return 'Bundles';
        if (this.currentStep === STEPS.LINE_EDITOR) return 'Lines';
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
        return this.currentStep !== STEPS.LOGISTICS && this.currentStep !== STEPS.REVIEW;
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
        else if (action === 'save') this._triggerSave();
        else if (action === 'cancel') this._showToast('Configuration cancelled', 'error');
        else this._showToast(`Action: ${action}`, 'success');
    }

    toggleSidebar() {
        this.isSidebarOpen = !this.isSidebarOpen;
    }


    /* -- Step 1 events -- */
    handleProductAdd(event) {
        const product = deepClone(event.detail.cartItem);
        const discount = this.quoteState.additionalDiscountPercent || 0;
        product._formattedTotal = formatCurrency(calculateCartItemTotal(product, discount));
        const items = deepClone(this.cartItems);
        items.push(product);
        this.cartItems = items;
        this._showToast(`${product.productName} added to cart`, 'success');
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
        const idx = STEP_META.findIndex(s => s.value === this.currentStep);
        if (idx < STEP_META.length - 1 && this._canAdvance) {
            this.currentStep = STEP_META[idx + 1].value;
        }
    }

    _goBack() {
        const idx = STEP_META.findIndex(s => s.value === this.currentStep);
        if (idx > 0) {
            this.currentStep = STEP_META[idx - 1].value;
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
