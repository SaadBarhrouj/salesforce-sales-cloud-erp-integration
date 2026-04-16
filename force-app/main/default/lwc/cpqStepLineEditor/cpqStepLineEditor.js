import { LightningElement, api, track } from 'lwc';
import { formatCurrency, showToast } from 'c/cpqUtils';
import calculateLinePrices from '@salesforce/apex/PricebookController.calculateLinePrices';

const DEBOUNCE_DELAY = 500;

const COLUMNS = [
    { type: 'text', fieldName: 'productName', label: 'Product', isProduct: true },
    { type: 'text', fieldName: 'productCode', label: 'Code', isCode: true },
    { type: 'number', fieldName: 'quantity', label: 'Qty', editable: true, isQty: true },
    { type: 'currency', fieldName: 'listUnitPrice', label: 'List Price', isCurrency: true, isListPrice: true },
    { type: 'number', fieldName: 'additionalDiscount', label: 'Disc. %', editable: true, isDiscount: true },
    { type: 'currency', fieldName: 'netUnitPrice', label: 'Net Price', isCurrency: true, isNetPrice: true },
    { type: 'currency', fieldName: 'netTotal', label: 'Total', isCurrency: true, isTotal: true }
];

export default class CpqStepLineEditor extends LightningElement {
    _pricebookId = '';
    _offerType = null;
    _selectedProducts = [];

    @track lineItems = []; // FLATTENED state
    @track isLoading = true;
    @track expandedRows = new Set();

    _debounceTimer = null;
    _calculationSequence = 0;
    _initialPricingRequested = false;

    @api
    get pricebookId() {
        return this._pricebookId;
    }
    set pricebookId(value) {
        this._pricebookId = value;
        if (!this._initialPricingRequested && this.lineItems.length > 0) {
            this._scheduleInitialPricing();
        }
    }

    @api
    get offerType() {
        return this._offerType;
    }
    set offerType(value) {
        this._offerType = value;
    }

    @api
    get selectedProducts() {
        return this._selectedProducts;
    }
    set selectedProducts(value) {
        this._selectedProducts = value || [];
        this._initialPricingRequested = false;
        this._prepareLineItems();
        this._scheduleInitialPricing();
    }

    // ─── GETTERS ────────────────────────────────────────────────────────────

    get columns() {
        return COLUMNS;
    }

    get isEmpty() {
        return !this.lineItems || this.lineItems.length === 0;
    }

    get isNotEmpty() {
        return !this.isEmpty;
    }

    get subtotal() {
        if (!this.lineItems || this.lineItems.length === 0) return 0;
        const total = this.lineItems.reduce((sum, row) => sum + (Number(row.netTotal) || 0), 0);
        return Math.max(0, total);
    }

    get subtotalLoading() {
        return this.isLoading;
    }

    get formattedSubtotal() {
        return formatCurrency(this.subtotal);
    }

    get flattenedData() {
        // Build view models sequentially directly from the flat array,
        // skipping children if their parent is not expanded.
        const viewData = [];
        let indexInSet = 1;

        for (const row of this.lineItems) {
            // Skip children of collapsed parents
            if (row._isOption && row._parentId && !this.expandedRows.has(row._parentId)) {
                continue;
            }

            const isExpanded = this.expandedRows.has(row._key);
            const level = row._isOption ? 2 : 1;

            viewData.push({
                ...row,
                rowId: row._key,
                level,
                ariaLevel: level,
                posInSet: indexInSet++,
                setSize: this.lineItems.length, // approximation
                isExpanded,
                chevronClass: (row._hasChildren && !isExpanded) ? 'utility:chevronright' : 'utility:chevrondown',
                buttonStyle: row._hasChildren ? '' : 'visibility: hidden;',
                isQtyEditable: !row._isOption,
                isDiscountEditable: true,
                showCheckbox: !row._isOption,
                rowClass: `slds-hint-parent ${row._hasError ? 'slds-is-selected row-error' : ''}`,
                paddingStyle: `padding-left: ${level > 1 ? level * 1.5 : 0}rem;`,
                isSelected: !!row.isSelected,
                formattedListPrice: formatCurrency(Number.isFinite(row.listUnitPrice) ? row.listUnitPrice : 0),
                formattedNetPrice: formatCurrency(Number.isFinite(row.netUnitPrice) ? row.netUnitPrice : 0),
                formattedNetTotal: formatCurrency(Number.isFinite(row.netTotal) ? row.netTotal : 0),
                
            });
        }
        return viewData;
    }

    // ─── LIFECYCLE ──────────────────────────────────────────────────────────

    connectedCallback() {
        this._prepareLineItems();
        this._scheduleInitialPricing();
    }

    // ─── INITIALIZATION / FLATTENING ──────────────────────────────────────────

    _buildParentLineItem(item, hasOptions) {
        const listPrice = Number(item.listUnitPrice) || 0;
        const discount = Number(item.additionalDiscount) || 0;
        const qty = Number(item.quantity) || 1;
        const netPrice = Number(item.netUnitPrice) || listPrice * (1 - discount / 100);
        const total = Number(item.netTotal) || netPrice * qty;

        return {
            _key: item._key,
            _hasError: false,
            _errorMessage: '',
            _hasChildren: hasOptions,
            productId: item.productId,
            productCode: item.productCode,
            productName: item.productName,
            quantity: qty,
            listUnitPrice: listPrice,
            additionalDiscount: discount,
            netUnitPrice: netPrice,
            netTotal: total,
            isBundle: item.isBundle
        };
    }

    _buildOptionLineItem(parentKey, opt) {
        const optListPrice = Number(opt.unitPrice) || 0;
        const optQty = Number(opt.quantity) || 1;
        const optDiscount = Number(opt.additionalDiscount) || 0;
        const optNetPrice = optListPrice * (1 - optDiscount / 100);
        const optNetTotal = optNetPrice * optQty;

        return {
            _key: opt.Id,
            _parentId: parentKey,
            _isOption: true,
            _hasError: false,
            _errorMessage: '',
            productId: opt.productId || opt.Id,
            optionId: opt.Id,
            productCode: opt.productCode,
            productName: opt.productName,
            quantity: optQty,
            listUnitPrice: optListPrice,
            additionalDiscount: optDiscount,
            netUnitPrice: optNetPrice,
            netTotal: optNetTotal
        };
    }

    _prepareLineItems() {
        if (!this._selectedProducts) return;

        const flatItems = [];

        this._selectedProducts.forEach(item => {
            const hasOptions = item.isBundle && item.configuredOptions && item.configuredOptions.length > 0;
            flatItems.push(this._buildParentLineItem(item, hasOptions));

            if (hasOptions) {
                item.configuredOptions.forEach((opt) => {
                    flatItems.push(this._buildOptionLineItem(item._key, opt));
                });
            }
        });

        this.lineItems = flatItems;

        const currentKeys = new Set(flatItems.map(row => row._key));
        const preservedExpand = new Set();
        for (const key of this.expandedRows) {
            if (currentKeys.has(key)) preservedExpand.add(key);
        }
        this.expandedRows = preservedExpand;
        this.isLoading = false;
    }

    // ─── EVENTS / DOM ACTIONS ───────────────────────────────────────────────

    handleToggleExpand(event) {
        const rowId = event.currentTarget.dataset.id;
        if (this.expandedRows.has(rowId)) {
            this.expandedRows.delete(rowId);
        } else {
            this.expandedRows.add(rowId);
        }
        this.expandedRows = new Set(this.expandedRows); // maintain reactivity
    }

    handleSelectAll(event) {
        const isChecked = event.target.checked;
        this.lineItems = this.lineItems.map(item => {
            if (!item._isOption) {
                return { ...item, isSelected: isChecked };
            }
            return item;
        });
        this._dispatchSelectionChange();
    }

    handleRowSelect(event) {
        const rowId = event.currentTarget.dataset.id;
        const isChecked = event.target.checked;
        this.lineItems = this.lineItems.map(row => 
            row._key === rowId ? { ...row, isSelected: isChecked } : row
        );
        this._dispatchSelectionChange();
    }

    _dispatchSelectionChange() {
        const hasSelection = this.lineItems.some(item => item.isSelected);
        this.dispatchEvent(new CustomEvent('selectionchange', { detail: { hasSelection } }));
    }

    handleDeleteSelected() {
        const selectedIds = new Set(this.lineItems.filter(item => item.isSelected).map(item => item._key));

        if (selectedIds.size === 0) {
            showToast(this, 'No Selection', 'Please select at least one row to delete.', 'warning');
            return;
        }

        // Keep rows that are NOT selected AND whose parents are NOT selected
        this.lineItems = this.lineItems.filter(row => {
            const isSelfSelected = selectedIds.has(row._key);
            const isParentSelected = row._isOption && selectedIds.has(row._parentId);
            
            // Clean up state tracking for removed items
            if (isSelfSelected || isParentSelected) {
                this.expandedRows.delete(row._key);
            }
            
            return !isSelfSelected && !isParentSelected;
        });

        this.expandedRows = new Set(this.expandedRows);

        this._dispatchSelectionChange();
        showToast(this, 'Rows Deleted', `Successfully deleted selected rows.`, 'success');

        selectedIds.forEach(id => {
            this.dispatchEvent(new CustomEvent('lineremove', { detail: { itemKey: id } }));
        });

        this._schedulePricingCalculation();
    }
    
    handleInlineEdit(event) {
        const itemKey = event.currentTarget.dataset.id;
        const fieldName = event.currentTarget.dataset.field;
        let value = event.target.value;

        if (fieldName === 'quantity') {
            value = Number.isFinite(parseFloat(value)) ? parseFloat(value) : 1;
        } else if (fieldName === 'additionalDiscount') {
            value = Number.isFinite(parseFloat(value)) ? parseFloat(value) : 0;
        }

        this.lineItems = this.lineItems.map(row => {
            if (row._key !== itemKey) return row;

            const updatedRow = { ...row, [fieldName]: value };
            if (fieldName === 'quantity' || fieldName === 'additionalDiscount') {
                const listPrice = Number(updatedRow.listUnitPrice) || 0;
                const discount = Number(updatedRow.additionalDiscount) || 0;
                const qty = Number(updatedRow.quantity) || 1;
                updatedRow.netUnitPrice = listPrice * (1 - discount / 100);
                updatedRow.netTotal = updatedRow.netUnitPrice * qty;
            }
            return updatedRow;
        });

        this._schedulePricingCalculation();
    }

    // ─── PRICING CALCULATIONS ────────────────────────────────────────────────

    _schedulePricingCalculation() {
        if (this._debounceTimer) {
            clearTimeout(this._debounceTimer);
        }
        this._debounceTimer = setTimeout(() => {
            this._executePricingCalculation();
        }, DEBOUNCE_DELAY);
    }

    async _executePricingCalculation() {
        if (!this.pricebookId || this.lineItems.length === 0) {
            this.isLoading = false;
            return;
        }

        const calculationSequence = ++this._calculationSequence;
        this.isLoading = true;

        const pricingRequestItems = [];
        const pricingRequestKeys = [];
        let updatedData = [...this.lineItems];

        for (let i = 0; i < updatedData.length; i++) {
            const row = updatedData[i];
            const hasServerProductId = row.productId && row.productId !== row.optionId;

            // Local-only options don't need server pricing
            if (row._isOption && !hasServerProductId) {
                const optListPrice = Number(row.listUnitPrice) || 0;
                const optQty = Number(row.quantity) || 1;
                const optDisc = Number(row.additionalDiscount) || 0;
                const netPrice = optListPrice * (1 - optDisc / 100);

                updatedData[i] = {
                    ...row,
                    quantity: optQty,
                    additionalDiscount: optDisc,
                    netUnitPrice: netPrice,
                    netTotal: netPrice * optQty,
                    _hasError: false,
                    _errorMessage: ''
                };
                continue;
            }

            pricingRequestKeys.push(row._key);
            pricingRequestItems.push({
                productId: row.productId,
                quantity: row.quantity,
                discount: row.additionalDiscount
            });
        }

        try {
            if (pricingRequestItems.length === 0) {
                this.lineItems = updatedData;
                return;
            }

            const results = await calculateLinePrices({
                lineItems: pricingRequestItems,
                offerType: this.offerType,
                pricebookId: this.pricebookId
            });

            if (calculationSequence !== this._calculationSequence) return;

            // Map server results back to line items
            for (let i = 0; i < results.length && i < pricingRequestKeys.length; i++) {
                const result = results[i];
                const itemKey = pricingRequestKeys[i];

                const rowIndex = updatedData.findIndex(r => r._key === itemKey);
                if (rowIndex !== -1) {
                    const rowToUpdate = { ...updatedData[rowIndex] };
                    if (result.success) {
                        rowToUpdate.listUnitPrice = result.listPrice;
                        rowToUpdate.netUnitPrice = result.netPrice;
                        rowToUpdate.netTotal = result.totalPrice;
                        rowToUpdate._hasError = false;
                        rowToUpdate._errorMessage = '';
                    } else {
                        rowToUpdate._hasError = true;
                        rowToUpdate._errorMessage = result.errorMessage;
                    }
                    updatedData[rowIndex] = rowToUpdate;
                }
            }

            this.lineItems = updatedData;

        } catch (error) {
            console.error('Pricing calculation error:', error);
            showToast(this, 'Pricing Error', error.message || 'Pricing calculation failed', 'error');
        } finally {
            if (calculationSequence === this._calculationSequence) {
                this.isLoading = false;
            }
        }
    }

    async handleRefreshPricing() {
        this.isLoading = true;
        await this._executePricingCalculation();
    }

    _scheduleInitialPricing() {
        if (this._initialPricingRequested) return;
        if (this.lineItems.length === 0) return;
        if (!this.pricebookId) return;

        this._initialPricingRequested = true;
        this._schedulePricingCalculation();
    }


    // ─── VALIDATION ─────────────────────────────────────────────────────────

    @api
    validate() {
        if (this.isLoading || this.lineItems.length === 0) return false;

        let hasValidationErrors = false;
        
        this.lineItems = this.lineItems.map(row => {
            const updatedRow = { ...row };
            const discount = Number(updatedRow.additionalDiscount);
            const quantity = Number(updatedRow.quantity);

            if (!Number.isFinite(discount) || discount < 0 || discount > 100) {
                updatedRow._hasError = true;
                updatedRow._errorMessage = 'Discount must be between 0 and 100';
                hasValidationErrors = true;
            } else if (!Number.isFinite(quantity) || quantity < 1) {
                updatedRow._hasError = true;
                updatedRow._errorMessage = 'Quantity must be at least 1';
                hasValidationErrors = true;
            } else if (updatedRow._errorMessage === 'Discount must be between 0 and 100'
                    || updatedRow._errorMessage === 'Quantity must be at least 1') {
                updatedRow._hasError = false;
                updatedRow._errorMessage = '';
            }

            return updatedRow;
        });

        return !hasValidationErrors && !this._hasPricingErrors();
    }

    _hasPricingErrors() {
        return this.lineItems.some(row => row._hasError);
    }

    @api
    saveLines() {
        const updatedProducts = this._mapLineItemsToProducts();
        this.dispatchEvent(new CustomEvent('linesave', {
            detail: { lineItems: updatedProducts }
        }));
    }

    _mapLineItemsToProducts() {
        const products = [];
        const optionsMap = {};

        for (const row of this.lineItems) {
            if (row._isOption) {
                if (!optionsMap[row._parentId]) {
                    optionsMap[row._parentId] = [];
                }
                optionsMap[row._parentId].push({
                    Id: row.optionId,
                    productId: row.productId,
                    productCode: row.productCode,
                    productName: row.productName,
                    quantity: row.quantity,
                    unitPrice: row.listUnitPrice,
                    netUnitPrice: row.netUnitPrice,
                    netTotal: row.netTotal,
                    additionalDiscount: row.additionalDiscount
                });
            }
        }

        for (const row of this.lineItems) {
            if (!row._isOption) {
                products.push({
                    _key: row._key,
                    productId: row.productId,
                    productCode: row.productCode,
                    productName: row.productName,
                    quantity: row.quantity,
                    listUnitPrice: row.listUnitPrice,
                    additionalDiscount: row.additionalDiscount,
                    netUnitPrice: row.netUnitPrice,
                    netTotal: row.netTotal,
                    isBundle: row.isBundle,
                    configuredOptions: optionsMap[row._key] || []
                });
            }
        }

        return products;
    }

    @api
    resetLineItems() {
        this.lineItems = this.lineItems.map(row => {
            if (row._isOption) {
                const listPrice = Number(row.listUnitPrice) || 0;
                const qty = Number(row.quantity) || 1;
                return {
                    ...row,
                    additionalDiscount: 0,
                    netUnitPrice: listPrice,
                    netTotal: listPrice * qty,
                    _hasError: false,
                    _errorMessage: ''
                };
            }

            const listPrice = Number(row.listUnitPrice) || 0;
            const netPrice = listPrice;
            return {
                ...row,
                quantity: 1,
                additionalDiscount: 0,
                netUnitPrice: netPrice,
                netTotal: netPrice * 1,
                _hasError: false,
                _errorMessage: ''
            };
        });

        this._schedulePricingCalculation();

        this.dispatchEvent(new CustomEvent('linesave', {
            detail: { lineItems: this._mapLineItemsToProducts() }
        }));
    }

    @api
    handleHeaderAction(actionName) {
        switch (actionName) {
            case 'deleteSelected':
                this.handleDeleteSelected();
                break;
            case 'refreshPricing':
                this.handleRefreshPricing();
                break;
            default:
                break;
        }
    }
}
