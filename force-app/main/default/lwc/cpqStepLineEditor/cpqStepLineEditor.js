import { LightningElement, api, track } from 'lwc';
import { formatCurrency, showToast } from 'c/cpqUtils';
import calculateLinePricesBatch from '@salesforce/apex/PricebookController.calculateLinePricesBatch';

const DEBOUNCE_DELAY = 500;

const COLUMNS = [
    {
        type: 'text',
        fieldName: 'productName',
        label: 'Product',
        isProduct: true
    },
    {
        type: 'text',
        fieldName: 'productCode',
        label: 'Code',
        isCode: true
    },
    {
        type: 'number',
        fieldName: 'quantity',
        label: 'Qty',
        editable: true,
        isQty: true
    },
    {
        type: 'currency',
        fieldName: 'listUnitPrice',
        label: 'List Price',
        isCurrency: true,
        isListPrice: true
    },
    {
        type: 'number',
        fieldName: 'additionalDiscount',
        label: 'Disc. %',
        editable: true,
        isDiscount: true
    },
    {
        type: 'currency',
        fieldName: 'netUnitPrice',
        label: 'Net Price',
        isCurrency: true,
        isNetPrice: true
    },
    {
        type: 'currency',
        fieldName: 'netTotal',
        label: 'Total',
        isCurrency: true,
        isTotal: true
    }
];

export default class CpqStepLineEditor extends LightningElement {
    @api pricebookId = '';
    @api offerType = null;

    @track lineItems = [];
    @track isCalculating = false;
    @track expandedRows = new Set();

    _pendingChanges = new Map();
    _debounceTimer = null;
    _selectedProducts = [];
    _calculationSequence = 0;

    @api
    get selectedProducts() {
        return this._selectedProducts;
    }
    set selectedProducts(value) {
        this._selectedProducts = value || [];
        this._prepareLineItems();
    }

    // Use our custom flattened data property for the template's table loop
    get flattenedData() {
        const flat = [];
        const processItems = (items, level = 1) => {
            items.forEach((item, index) => {
                const isExpanded = this.expandedRows.has(item._key);
                const hasChildren = item._children && item._children.length > 0;

                flat.push({
                    ...item,
                    rowId: item._key,
                    level,
                    ariaLevel: level,
                    posInSet: index + 1,
                    setSize: items.length,
                    isExpanded,
                    hasChildren,
                    chevronClass: (hasChildren && !isExpanded) ? 'utility:chevronright' : 'utility:chevrondown',
                    buttonStyle: hasChildren ? '' : 'visibility: hidden;',
                    isQtyEditable: !item._isOption, // quantity is read-only for options
                    isDiscountEditable: true, // discount is editable for both parents and options
                    showCheckbox: !item._isOption, // hide checkbox for bundle options
                    rowClass: `slds-hint-parent ${item._hasError ? 'slds-is-selected row-error' : ''}`,
                    paddingStyle: `padding-left: ${level > 1 ? level * 1.5 : 0}rem;`, // Ensure proper indentation for children
                    isSelected: !!item.isSelected,
                    formattedListPrice: formatCurrency(item.listUnitPrice),
                    formattedNetPrice: formatCurrency(item.netUnitPrice),
                    formattedNetTotal: formatCurrency(item.netTotal),
                    actionTitle: `More actions for ${item.productName}`
                });

                if (isExpanded && hasChildren) {
                    processItems(item._children, level + 1);
                }
            });
        };

        processItems(this.lineItems || []);
        return flat;
    }

    connectedCallback() {
        this._prepareLineItems();
    }

    get columns() {
        return COLUMNS;
    }

    get subtotal() {
        if (this.lineItems && this.lineItems.length > 0) {
            let total = 0;
            this._forEachRow(row => {
                total += Number(row.netTotal) || 0;
            });
            return Math.max(0, total);
        }
        return 0;
    }

    get formattedSubtotal() {
        return formatCurrency(this.subtotal);
    }

    get isEmpty() {
        return !this.lineItems || this.lineItems.length === 0;
    }

    get isNotEmpty() {
        return !this.isEmpty;
    }

    _forEachRow(callback) {
        if (typeof callback !== 'function') {
            return;
        }

        (this.lineItems || []).forEach(parentRow => {
            callback(parentRow, { isChild: false, parentKey: parentRow._key });
            (parentRow._children || []).forEach(childRow => {
                callback(childRow, { isChild: true, parentKey: parentRow._key });
            });
        });
    }

    _findRowByKey(rowKey) {
        if (!rowKey) {
            return null;
        }

        let matchedRow = null;
        this._forEachRow(row => {
            if (!matchedRow && row._key === rowKey) {
                matchedRow = row;
            }
        });
        return matchedRow;
    }

    _mapRowsIn(rows, updater) {
        if (typeof updater !== 'function') {
            return [...(rows || [])];
        }

        return (rows || []).map(parentRow => {
            const parentClone = { ...parentRow };
            const updatedParent = updater(parentClone, { isChild: false, parentKey: parentRow._key }) || parentClone;

            if (!updatedParent._children || updatedParent._children.length === 0) {
                return updatedParent;
            }

            const updatedChildren = updatedParent._children.map(childRow => {
                const childClone = { ...childRow };
                return updater(childClone, { isChild: true, parentKey: updatedParent._key }) || childClone;
            });

            return {
                ...updatedParent,
                _children: updatedChildren
            };
        });
    }

    _mapRows(updater) {
        return this._mapRowsIn(this.lineItems, updater);
    }

    _prepareLineItems() {
        if (!this._selectedProducts) return;

        this.lineItems = this._selectedProducts.map(item => {
            const hasOptions = item.isBundle && item.configuredOptions && item.configuredOptions.length > 0;

            const row = {
                _key: item._key,
                _hasError: false,
                _errorMessage: '',
                productId: item.productId,
                productCode: item.productCode,
                productName: item.productName,
                quantity: item.quantity,
                listUnitPrice: item.listUnitPrice,
                additionalDiscount: item.additionalDiscount,
                netUnitPrice: item.netUnitPrice,
                netTotal: item.netTotal,
                isBundle: item.isBundle
            };

            // Only add _children property for bundles to show expand/collapse icon
            if (hasOptions) {
                row._children = [];
                item.configuredOptions.forEach((opt) => {
                    row._children.push({
                        _key: opt.Id,
                        productId: opt.productId || opt.Id,
                        optionId: opt.Id,
                        productCode: opt.productCode,
                        productName: opt.productName,
                        quantity: opt.quantity,
                        listUnitPrice: opt.unitPrice,
                        additionalDiscount: 0,
                        netUnitPrice: opt.unitPrice,
                        netTotal: opt.unitPrice * opt.quantity,
                        _isOption: true
                    });
                });
            }

            return row;
        });
        // Force track array
        this.lineItems = [...this.lineItems];
        // Ensure expandedRows is clear initially (collapsed by default)
        this.expandedRows = new Set();
    }

    handleToggleExpand(event) {
        const rowId = event.currentTarget.dataset.id;
        if (this.expandedRows.has(rowId)) {
            this.expandedRows.delete(rowId);
        } else {
            this.expandedRows.add(rowId);
        }
        // assigning a new set preserves reactivity in LWC
        this.expandedRows = new Set(this.expandedRows);
    }

    handleSelectAll(event) {
        const isChecked = event.target.checked;
        const updatedData = this.lineItems.map(item => {
            if (!item._isOption) {
                return { ...item, isSelected: isChecked };
            }
            return item;
        });
        this.lineItems = updatedData;
        this._dispatchSelectionChange();
    }

    handleRowSelect(event) {
        const rowId = event.currentTarget.dataset.id;
        const isChecked = event.target.checked;
        const updatedData = this._mapRows(row => {
            if (row._key !== rowId) {
                return row;
            }
            return { ...row, isSelected: isChecked };
        });
        this.lineItems = updatedData;
        this._dispatchSelectionChange();
    }

    _dispatchSelectionChange() {
        const hasSelection = this.lineItems.some(item => item.isSelected);
        this.dispatchEvent(new CustomEvent('selectionchange', {
            detail: { hasSelection }
        }));
    }

    handleDeleteSelected() {
        const selectedIds = new Set(this.lineItems.filter(item => item.isSelected).map(item => item._key));

        if (selectedIds.size === 0) {
            showToast(this, 'No Selection', 'Please select at least one row to delete.', 'warning');
            return;
        }

        // Filter out selected parent rows
        this.lineItems = this.lineItems.filter(item => !selectedIds.has(item._key));

        // Clean up pending changes for deleted rows
        selectedIds.forEach(id => {
            this._pendingChanges.delete(id);
            this.expandedRows.delete(id);
        });

        // Re-assign to trigger reactivity
        this.expandedRows = new Set(this.expandedRows);

        // Dispatch an event to parent to update header state (e.g. disable delete button)
        this.dispatchEvent(new CustomEvent('selectionchange', {
            detail: { hasSelection: false }
        }));

        showToast(this, 'Rows Deleted', `Successfully deleted ${selectedIds.size} row(s).`, 'success');

        // Dispatch lineremove event to inform parent component
        selectedIds.forEach(id => {
            this.dispatchEvent(new CustomEvent('lineremove', {
                detail: { itemKey: id }
            }));
        });

        // Trigger calculation if any changes remain
        if (this._pendingChanges.size > 0) {
            this._scheduleBatchCalculation();
        }
    }

    // Removed standard datatable handleCellChange. Using manual custom input events.
    handleInlineEdit(event) {
        const itemKey = event.currentTarget.dataset.id;
        const fieldName = event.currentTarget.dataset.field;
        let value = event.target.value;
        if (fieldName === 'quantity' || fieldName === 'additionalDiscount') {
            value = parseFloat(value);
        }

        this._pendingChanges.set(itemKey, {
            ...this._pendingChanges.get(itemKey),
            [fieldName]: value
        });

        this._updateLocalData(itemKey, fieldName, value);
        this._scheduleBatchCalculation();
    }

    _updateLocalData(itemKey, field, value) {
        let rowWasUpdated = false;
        const updatedData = this._mapRows(row => {
            if (row._key !== itemKey) {
                return row;
            }

            rowWasUpdated = true;
            const updatedRow = { ...row, [field]: value };
            if (field === 'quantity' || field === 'additionalDiscount') {
                updatedRow.netUnitPrice = (updatedRow.listUnitPrice || 0) * (1 - (updatedRow.additionalDiscount || 0) / 100);
                updatedRow.netTotal = updatedRow.netUnitPrice * updatedRow.quantity;
            }
            return updatedRow;
        });

        if (rowWasUpdated) {
            this.lineItems = updatedData;
        }
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

        const pendingSnapshot = Array.from(this._pendingChanges.entries());
        if (pendingSnapshot.length === 0) {
            return;
        }

        const calculationSequence = ++this._calculationSequence;
        this.isCalculating = true;
        const pricingRequestItems = [];
        const pricingRequestKeys = [];
        let updatedData = [...this.lineItems];

        for (const [itemKey, changes] of pendingSnapshot) {
            const row = this._findRowByKey(itemKey);
            if (!row) {
                continue;
            }

            const quantity = changes.quantity ?? row.quantity;
            const discount = changes.additionalDiscount ?? row.additionalDiscount;

            const hasServerProductId = row.productId && row.productId !== row.optionId;

            if (row._isOption && !hasServerProductId) {
                updatedData = this._mapRowsIn(updatedData, candidateRow => {
                    if (candidateRow._key !== itemKey) {
                        return candidateRow;
                    }

                    const updatedChild = {
                        ...candidateRow,
                        quantity,
                        additionalDiscount: discount
                    };
                    updatedChild.netUnitPrice = (updatedChild.listUnitPrice || 0) * (1 - (updatedChild.additionalDiscount || 0) / 100);
                    updatedChild.netTotal = updatedChild.netUnitPrice * updatedChild.quantity;
                    updatedChild._hasError = false;
                    updatedChild._errorMessage = '';
                    return updatedChild;
                });
                continue;
            }

            pricingRequestKeys.push(itemKey);
            pricingRequestItems.push({
                productId: row.productId,
                quantity,
                discount
            });
        }

        try {
            if (pricingRequestItems.length === 0) {
                this.lineItems = updatedData;
                pendingSnapshot.forEach(([itemKey]) => {
                    this._pendingChanges.delete(itemKey);
                });
                return;
            }

            const results = await calculateLinePricesBatch({
                lineItems: pricingRequestItems,
                offerType: this.offerType,
                pricebookId: this.pricebookId
            });

            if (calculationSequence !== this._calculationSequence) {
                return;
            }

            let hasErrors = false;

            for (let i = 0; i < results.length && i < pricingRequestKeys.length; i++) {
                const result = results[i];
                const itemKey = pricingRequestKeys[i];
                updatedData = this._mapRowsIn(updatedData, row => {
                    if (row._key !== itemKey) {
                        return row;
                    }

                    const updatedRow = { ...row };
                    if (result.success) {
                        updatedRow.listUnitPrice = result.listPrice;
                        updatedRow.netUnitPrice = result.netPrice;
                        updatedRow.netTotal = result.totalPrice;
                        updatedRow._hasError = false;
                        updatedRow._errorMessage = '';
                    } else {
                        updatedRow._hasError = true;
                        updatedRow._errorMessage = result.errorMessage;
                        hasErrors = true;
                    }
                    return updatedRow;
                });
            }

            this.lineItems = updatedData;
            pendingSnapshot.forEach(([itemKey]) => {
                this._pendingChanges.delete(itemKey);
            });

            if (hasErrors) {
                showToast(this, 'Pricing Warning', 'Some items could not be priced. Check the line editor for details.', 'warning');
            }

        } catch (error) {
            console.error('Pricing calculation error:', error);
            showToast(this, 'Pricing Error', error.message || 'Pricing calculation failed', 'error');
        } finally {
            if (calculationSequence === this._calculationSequence) {
                this.isCalculating = false;
            }
        }
    }

    async handleRefreshPricing() {
        this._pendingChanges.clear();
        this._forEachRow(row => {
            this._pendingChanges.set(row._key, {
                quantity: row.quantity,
                additionalDiscount: row.additionalDiscount
            });
        });
        await this._executeBatchCalculation();

        showToast(this, 'Pricing Refreshed', 'All prices have been recalculated', 'success');
    }

    handleValidateAll() {
        const errors = [];
        const updatedData = this._mapRows(row => {
            const updatedRow = { ...row };
            const discount = Number(updatedRow.additionalDiscount);
            const quantity = Number(updatedRow.quantity);

            if (!Number.isFinite(discount) || discount < 0 || discount > 100) {
                updatedRow._hasError = true;
                updatedRow._errorMessage = 'Discount must be between 0 and 100';
                errors.push(`${updatedRow.productName}: Invalid discount`);
            } else if (!Number.isFinite(quantity) || quantity < 1) {
                updatedRow._hasError = true;
                updatedRow._errorMessage = 'Quantity must be at least 1';
                errors.push(`${updatedRow.productName}: Invalid quantity`);
            } else {
                updatedRow._hasError = false;
                updatedRow._errorMessage = '';
            }

            return updatedRow;
        });

        this.lineItems = updatedData;

        if (errors.length > 0) {
            showToast(this, 'Validation Failed', `${errors.length} item(s) have validation errors: ${errors.join(', ')}`, 'error');
        } else {
            showToast(this, 'Validation Passed', 'All line items are valid', 'success');
        }
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
            case 'validateAll':
                this.handleValidateAll();
                break;
            default:
                break;
        }
    }
}
