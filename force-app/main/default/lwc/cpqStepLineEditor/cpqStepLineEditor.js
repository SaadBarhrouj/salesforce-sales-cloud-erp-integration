import { LightningElement, api, track } from 'lwc';
import { formatCurrency, calculateSelectedProductsSubtotal, deepClone } from 'c/cpqUtils';

const PRICING_METHOD_OPTIONS = [
    { label: 'Standard', value: 'Standard' },
    { label: 'Volume', value: 'Volume' },
    { label: 'Tiered', value: 'Tiered' },
    { label: 'Contract', value: 'Contract' },
    { label: 'Promotion', value: 'Promotion' }
];

export default class CpqStepLineEditor extends LightningElement {
    @api selectedProducts = [];

    @track expandedItemKeys = new Set();
    @track expandedOptionsKeys = new Set();

    pricingMethodOptions = PRICING_METHOD_OPTIONS;

    get numberedItems() {
        return (this.selectedProducts || []).map((item, idx) => {
            const formattedListPrice = formatCurrency(item.listUnitPrice || 0);
            const netUnitPrice = (item.listUnitPrice || 0) * (1 - (item.additionalDiscount || 0) / 100);
            const formattedNetPrice = formatCurrency(netUnitPrice);
            const formattedTotal = formatCurrency((item.quantity || 1) * netUnitPrice);
            const isExpanded = this.expandedItemKeys.has(item._key);
            const isOptionsExpanded = this.expandedOptionsKeys.has(item._key);
            
            return {
                ...item,
                _lineNumber: idx + 1,
                _isExpanded: isExpanded,
                _isOptionsExpanded: isOptionsExpanded,
                _showOptions: item.isBundle && isExpanded && isOptionsExpanded,
                _showBundleOptions: item.isBundle && isExpanded,
                _formattedListPrice: formattedListPrice,
                _formattedNetPrice: formattedNetPrice,
                _formattedTotal: formattedTotal,
                _pricingKey: item._key + '-pricing',
                _optionsHeaderKey: item._key + '-options-header'
            };
        });
    }

    get formattedSubtotal() {
        return formatCurrency(calculateSelectedProductsSubtotal(this.selectedProducts || []));
    }

    get isEmpty() {
        return !this.selectedProducts || this.selectedProducts.length === 0;
    }

    get isNotEmpty() {
        return !this.isEmpty;
    }

    toggleItemExpand(event) {
        const itemKey = event.currentTarget.dataset.itemKey;
        if (this.expandedItemKeys.has(itemKey)) {
            this.expandedItemKeys.delete(itemKey);
        } else {
            this.expandedItemKeys.add(itemKey);
        }
        this.expandedItemKeys = new Set(this.expandedItemKeys);
    }

    toggleOptionsExpand(event) {
        const itemKey = event.currentTarget.dataset.itemKey;
        if (this.expandedOptionsKeys.has(itemKey)) {
            this.expandedOptionsKeys.delete(itemKey);
        } else {
            this.expandedOptionsKeys.add(itemKey);
        }
        this.expandedOptionsKeys = new Set(this.expandedOptionsKeys);
    }

    handleLineUpdate(event) {
        const target = event.target;
        const itemKey = target.dataset.itemKey;
        const field = target.dataset.field;
        const optionId = target.dataset.optionId;
        let value = target.value;

        if (target.type === 'checkbox') {
            value = target.checked;
        } else if (target.type === 'number' || target.type === 'currency') {
            value = parseFloat(value) || 0;
        }

        this.dispatchEvent(new CustomEvent('lineupdate', {
            detail: { itemKey, field, value, optionId }
        }));
    }

    handleLineRemove(event) {
        const itemKey = event.currentTarget.dataset.itemKey;
        this.dispatchEvent(new CustomEvent('lineremove', {
            detail: { itemKey }
        }));
    }

    handleBack() {
        this.dispatchEvent(new CustomEvent('navigate', { detail: { direction: 'back' } }));
    }

    handleNext() {
        this.dispatchEvent(new CustomEvent('navigate', { detail: { direction: 'next' } }));
    }
}