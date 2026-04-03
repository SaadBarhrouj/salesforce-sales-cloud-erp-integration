import { LightningElement, api } from 'lwc';
import { formatCurrency, calculateNetUnitPrice, calculateLineTotal } from 'c/cpqUtils';

export default class CpqLineItem extends LightningElement {
    @api item = {};
    @api lineNumber = 1;

    get formattedListPrice() {
        return formatCurrency(this.item.listUnitPrice);
    }

    get formattedNetPrice() {
        return formatCurrency(calculateNetUnitPrice(this.item.listUnitPrice, this.item.additionalDiscount || 0));
    }

    get formattedNetTotal() {
        return formatCurrency(calculateLineTotal(this.item.quantity, this.item.listUnitPrice, this.item.additionalDiscount || 0));
    }

    get selectedOptions() {
        if (!this.item.options) return [];
        return this.item.options
            .filter(o => o.isSelected)
            .map(o => ({
                ...o,
                formattedListPrice: formatCurrency(o.listUnitPrice),
                formattedNetPrice: formatCurrency(o.listUnitPrice),
                formattedNetTotal: formatCurrency(
                    calculateLineTotal(o.quantity * this.item.quantity, o.listUnitPrice, 0)
                )
            }));
    }

    handleQuantityChange(event) {
        const qty = parseInt(event.target.value, 10) || 1;
        this.dispatchEvent(new CustomEvent('lineupdate', {
            detail: { itemKey: this.item._key, field: 'quantity', value: qty }
        }));
    }

    handleDiscountChange(event) {
        const disc = parseFloat(event.target.value) || 0;
        this.dispatchEvent(new CustomEvent('lineupdate', {
            detail: { itemKey: this.item._key, field: 'additionalDiscount', value: disc }
        }));
    }

    handleOptionQuantityChange(event) {
        const optionId = event.currentTarget.dataset.optionId;
        const qty = parseInt(event.target.value, 10) || 1;
        this.dispatchEvent(new CustomEvent('lineupdate', {
            detail: { itemKey: this.item._key, field: 'optionQuantity', optionId, value: qty }
        }));
    }

    handleRemove() {
        this.dispatchEvent(new CustomEvent('lineremove', {
            detail: { itemKey: this.item._key }
        }));
    }
}
