import { LightningElement, api, track } from 'lwc';
import { STEPS, EVENTS, MESSAGES } from 'c/cpqConstants';
import { deepClone, calculateCartSubtotal, calculateCartItemTotal, formatCurrency } from 'c/cpqUtils';

const STEP_META = [
    { value: STEPS.INIT, label: 'Quote Setup', icon: 'standard:quote', subtitle: 'Configure quote parameters' },
    { value: STEPS.SELECTION, label: 'Product Selection', icon: 'standard:product', subtitle: 'Choose products for your quote' },
    { value: STEPS.CONFIGURE, label: 'Bundle Configuration', icon: 'standard:bundle_policy', subtitle: 'Configure bundles & options' },
    { value: STEPS.LINE_EDITOR, label: 'Line Editor', icon: 'standard:order_item', subtitle: 'Review & adjust line items' },
    { value: STEPS.LOGISTICS, label: 'Logistics', icon: 'standard:shipment', subtitle: 'Delivery options' },
    { value: STEPS.REVIEW, label: 'Review & Save', icon: 'standard:task', subtitle: 'Verify everything before saving' }
];

const TOAST_DURATION = 4000;

export default class CpqConfigurator extends LightningElement {
    @api recordId;
    @api objectApiName;

    /* ── wizard state ─────────────────────────────── */
    currentStep = STEPS.INIT;
    initCompleted = false;
    miniCartOpen = false;

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
    get isStepInit() { return this.currentStep === STEPS.INIT; }
    get isStepSelection() { return this.currentStep === STEPS.SELECTION; }
    get isStepConfigure() { return this.currentStep === STEPS.CONFIGURE; }
    get isStepLineEditor() { return this.currentStep === STEPS.LINE_EDITOR; }
    get isStepLogistics() { return this.currentStep === STEPS.LOGISTICS; }
    get isStepReview() { return this.currentStep === STEPS.REVIEW; }

    /* -- header -- */
    get headerTitle() { return this._stepMeta.label; }
    get headerSubtitle() { return this._stepMeta.subtitle; }
    get headerIcon() { return this._stepMeta.icon; }

    get _stepMeta() {
        return STEP_META.find(s => s.value === this.currentStep) || STEP_META[0];
    }

    get headerActions() {
        const actions = [];
        if (this.currentStep !== STEPS.INIT) {
            actions.push({ label: 'Back', value: 'back', variant: 'neutral', iconName: 'utility:back' });
        }
        if (this.currentStep !== STEPS.REVIEW) {
            actions.push({ label: 'Next', value: 'next', variant: 'brand', iconName: 'utility:forward', disabled: !this._canAdvance });
        }
        if (this.currentStep === STEPS.REVIEW) {
            actions.push({ label: 'Confirm & Save', value: 'save', variant: 'brand', iconName: 'utility:save' });
        }
        return actions;
    }

    get _canAdvance() {
        if (this.currentStep === STEPS.INIT) return this.initCompleted;
        if (this.currentStep === STEPS.SELECTION) return this.cartItems.length > 0;
        return true;
    }

    /* -- progress bar -- */
    get stepList() {
        return STEP_META.map(s => ({
            value: s.value,
            label: s.label
        }));
    }

    /* -- cart helpers -- */
    get cartCount() { return this.cartItems.length; }

    get isCartVisible() {
        return this.currentStep !== STEPS.INIT && this.currentStep !== STEPS.LOGISTICS && this.currentStep !== STEPS.REVIEW;
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

    /* ═══════════════════════════════════════════════
       EVENT HANDLERS
       ═══════════════════════════════════════════════ */

    /* -- header actions -- */
    handleHeaderAction(event) {
        const action = event.detail.value;
        if (action === 'back') this._goBack();
        else if (action === 'next') this._goNext();
        else if (action === 'save') this._triggerSave();
    }

    /* -- progress bar click -- */
    handleStepNavigate(event) {
        const targetStep = event.detail.value;
        const targetIdx = STEP_META.findIndex(s => s.value === targetStep);
        const currentIdx = STEP_META.findIndex(s => s.value === this.currentStep);
        if (targetIdx <= currentIdx) {
            if (targetStep === STEPS.INIT || this.initCompleted) {
                this.currentStep = targetStep;
            }
        }
    }

    /* -- Step 1 events -- */
    handleQuoteStateChange(event) {
        this.quoteState = deepClone(event.detail.quoteState);
    }

    handleInitComplete(event) {
        this.quoteState = deepClone(event.detail.quoteState);
        this.initCompleted = true;
        this._goNext();
    }

    /* -- Step 2 events -- */
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
