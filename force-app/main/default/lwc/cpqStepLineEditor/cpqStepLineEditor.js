import { LightningElement, api, track } from 'lwc';
import { formatCurrency, calculateSelectedProductsSubtotal, deepClone } from 'c/cpqUtils';
import calculateLinePricesBatch from '@salesforce/apex/PricebookController.calculateLinePricesBatch';

const DEBOUNCE_DELAY = 500;

export default class CpqStepLineEditor extends LightningElement {
    @api selectedProducts = [];
    @api pricebookId = '';
    @api offerType = null;

    @track expandedItemKeys = new Set();
    @track isCalculating = false;
    @track pricingErrors = new Map();

    _pendingChanges = new Map();
    _debounceTimer = null;

    get totalItemCount() {
        return (this.selectedProducts || []).length;
    }

    get subtotal() {
        return calculateSelectedProductsSubtotal(this.selectedProducts || []);
    }

    get formattedSubtotal() {
        return formatCurrency(this.subtotal);
    }

    get isEmpty() {
        return !this.selectedProducts || this.selectedProducts.length === 0;
    }

    get isNotEmpty() {
        return !this.isEmpty;
    }

    get hasErrors() {
        return this.pricingErrors.size > 0;
    }

    get errorCount() {
        return this.pricingErrors.size;
    }

    get isEmptyOrHasErrors() {
        return this.isEmpty || this.hasErrors;
    }

    get numberedItems() {
        return (this.selectedProducts || []).map((item, idx) => {
            const isExpanded = this.expandedItemKeys.has(item._key);
            const hasError = this.pricingErrors.has(item._key);
            const errorMessage = this.pricingErrors.get(item._key) || '';
            
            return {
                ...item,
                _lineNumber: idx + 1,
                _isExpanded: isExpanded,
                _expandIcon: isExpanded ? 'utility:chevronup' : 'utility:chevrondown',
                _expandAltText: isExpanded ? 'Collapse' : 'Expand',
                _showOptions: item.isBundle && isExpanded,
                _hasError: hasError,
                _errorKey: item._key + '-error',
                _errorMessage: errorMessage,
                listUnitPrice: item.listUnitPrice || 0,
                additionalDiscount: item.additionalDiscount || 0,
                netUnitPrice: (item.listUnitPrice || 0) * (1 - (item.additionalDiscount || 0) / 100),
                netTotal: ((item.listUnitPrice || 0) * (1 - (item.additionalDiscount || 0) / 100)) * (item.quantity || 1)
            };
        });
    }

    handleToggleExpand(event) {
        const itemKey = event.currentTarget.dataset.itemKey;
        if (this.expandedItemKeys.has(itemKey)) {
            this.expandedItemKeys.delete(itemKey);
        } else {
            this.expandedItemKeys.add(itemKey);
        }
        this.expandedItemKeys = new Set(this.expandedItemKeys);
    }

    handleLineChange(event) {
        const target = event.target;
        const itemKey = target.dataset.itemKey;
        const field = target.dataset.field;
        let value = target.value;

        if (target.type === 'checkbox') {
            value = target.checked;
        } else if (target.type === 'number' || target.type === 'currency') {
            value = parseFloat(value) || 0;
        }

        if (field === 'quantity' || field === 'additionalDiscount') {
            this._pendingChanges.set(itemKey, { ...this._pendingChanges.get(itemKey), [field]: value });
            this._scheduleBatchCalculation();
        }

        this._notifyParent(itemKey, field, value);
    }

    _scheduleBatchCalculation() {
        if (this._debounceTimer) {
            clearTimeout(this._debounceTimer);
        }
        this._debounceTimer = setTimeout(() => {
            this._executeBatchCalculation();
        }, DEBOUNCE_DELAY);
    }

    async _executeBatchCalculation() {
        if (this._pendingChanges.size === 0 || !this.pricebookId) return;

        this.isCalculating = true;
        const lineItems = [];
        
        for (const [itemKey, changes] of this._pendingChanges) {
            const product = this.selectedProducts.find(p => p._key === itemKey);
            if (product) {
                lineItems.push({
                    productId: product.productId,
                    quantity: changes.quantity ?? product.quantity,
                    discount: changes.additionalDiscount ?? product.additionalDiscount
                });
            }
        }

        try {
            const results = await calculateLinePricesBatch({ 
                lineItems: lineItems,
                offerType: this.offerType,
                pricebookId: this.pricebookId
            });

            const updatedProducts = deepClone(this.selectedProducts);
            const newErrors = new Map();
            
            for (let i = 0; i < results.length; i++) {
                const result = results[i];
                const itemKey = Array.from(this._pendingChanges.keys())[i];
                const productIdx = updatedProducts.findIndex(p => p._key === itemKey);
                
                if (productIdx !== -1) {
                    if (result.success) {
                        updatedProducts[productIdx].listUnitPrice = result.listPrice;
                        updatedProducts[productIdx].netUnitPrice = result.netPrice;
                        updatedProducts[productIdx].netTotal = result.totalPrice;
                    } else {
                        newErrors.set(itemKey, result.errorMessage);
                    }
                }
            }

            this.pricingErrors = newErrors;
            this._pendingChanges.clear();
            
            this.dispatchEvent(new CustomEvent('productchange', {
                detail: { updatedProducts }
            }));

        } catch (error) {
            console.error('Pricing calculation error:', error);
            this.pricingErrors.set('global', error.message || 'Pricing calculation failed');
            this.pricingErrors = new Map(this.pricingErrors);
        } finally {
            this.isCalculating = false;
        }
    }

    _notifyParent(itemKey, field, value) {
        this.dispatchEvent(new CustomEvent('productchange', {
            detail: { itemKey, field, value }
        }));
    }

    handleLineRemove(event) {
        const itemKey = event.currentTarget.dataset.itemKey || event.detail?.itemKey;
        this.dispatchEvent(new CustomEvent('lineremove', {
            detail: { itemKey }
        }));
    }

    handleViewDetails(event) {
        const itemKey = event.detail.item?.dataset?.itemKey;
        if (this.expandedItemKeys.has(itemKey)) {
            this.expandedItemKeys.delete(itemKey);
        } else {
            this.expandedItemKeys.add(itemKey);
        }
        this.expandedItemKeys = new Set(this.expandedItemKeys);
    }

    handleApplyBulkDiscount() {
        const discount = prompt('Enter discount percentage (0-100):');
        if (discount !== null) {
            const discValue = parseFloat(discount);
            if (!isNaN(discValue) && discValue >= 0 && discValue <= 100) {
                const items = deepClone(this.selectedProducts);
                items.forEach(item => {
                    item.additionalDiscount = discValue;
                });
                this._setAllPendingChanges('additionalDiscount', discValue);
                this._executeBatchCalculation();
            }
        }
    }

    _setAllPendingChanges(field, value) {
        (this.selectedProducts || []).forEach(item => {
            this._pendingChanges.set(item._key, { 
                ...this._pendingChanges.get(item._key), 
                [field]: value 
            });
        });
    }

    async handleRefreshPricing() {
        this._pendingChanges.clear();
        (this.selectedProducts || []).forEach(item => {
            this._pendingChanges.set(item._key, {
                quantity: item.quantity,
                additionalDiscount: item.additionalDiscount
            });
        });
        await this._executeBatchCalculation();
    }

    handleValidateAll() {
        const items = deepClone(this.selectedProducts);
        const errors = new Map();
        
        items.forEach(item => {
            if (item.additionalDiscount < 0 || item.additionalDiscount > 100) {
                errors.set(item._key, 'Discount must be between 0 and 100');
            }
            if (!item.quantity || item.quantity < 1) {
                errors.set(item._key, 'Quantity must be at least 1');
            }
        });

        this.pricingErrors = errors;
        
        if (errors.size > 0) {
            this.dispatchEvent(new CustomEvent('showtoast', {
                detail: { 
                    title: 'Validation Errors', 
                    message: `${errors.size} item(s) have validation errors`, 
                    variant: 'error' 
                }
            }));
        }
    }

    handleBack() {
        this.dispatchEvent(new CustomEvent('navigate', { detail: { direction: 'back' } }));
    }

    handleNext() {
        if (this.hasErrors) {
            this.dispatchEvent(new CustomEvent('showtoast', {
                detail: { 
                    title: 'Cannot Proceed', 
                    message: 'Please fix all pricing errors before continuing', 
                    variant: 'error' 
                }
            }));
            return;
        }
        this.dispatchEvent(new CustomEvent('navigate', { detail: { direction: 'next' } }));
    }
}