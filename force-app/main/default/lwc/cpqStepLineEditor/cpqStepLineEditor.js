import { LightningElement, api } from 'lwc';
import { calculateSelectedProductsSubtotal, formatCurrency, deepClone } from 'c/cpqUtils';

export default class CpqStepLineEditor extends LightningElement {
    @api selectedProducts = [];
    @api quoteState = {};

    get numberedItems() {
        return (this.selectedProducts || []).map((item, idx) => ({
            ...item,
            _lineNumber: idx + 1
        }));
    }

    get formattedSubtotal() {
        return formatCurrency(calculateSelectedProductsSubtotal(this.selectedProducts || []));
    }

    get isEmpty() {
        return !this.selectedProducts || this.selectedProducts.length === 0;
    }

    /* ─── Event Handlers ─── */

    handleLineUpdate(event) {
        const { itemKey, field, value, optionId } = event.detail;
        this.dispatchEvent(new CustomEvent('lineupdate', {
            detail: deepClone({ itemKey, field, value, optionId })
        }));
    }

    handleLineRemove(event) {
        const { itemKey } = event.detail;
        this.dispatchEvent(new CustomEvent('lineremove', {
            detail: { itemKey }
        }));
    }

    handleGlobalDiscountChange(event) {
        const disc = parseFloat(event.detail.value) || 0;
        this.dispatchEvent(new CustomEvent('globaldiscount', {
            detail: { value: disc }
        }));
    }

    handleBack() {
        this.dispatchEvent(new CustomEvent('navigate', { detail: { direction: 'back' } }));
    }

    handleNext() {
        this.dispatchEvent(new CustomEvent('navigate', { detail: { direction: 'next' } }));
    }
}
