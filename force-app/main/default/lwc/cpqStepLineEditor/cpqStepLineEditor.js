import { LightningElement, api, track } from 'lwc';
import { formatCurrency, deepClone } from 'c/cpqUtils';
import calculateLinePricesBatch from '@salesforce/apex/PricebookController.calculateLinePricesBatch';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

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

const MOCK_PRODUCTS = [
    {
        _key: 'prod-001',
        productId: '01t5g000000XXXXAA1',
        productCode: 'SALE-001',
        productName: 'Professional Workstation',
        quantity: 5,
        listUnitPrice: 1299.99,
        additionalDiscount: 10,
        netUnitPrice: 1169.99,
        netTotal: 5849.95,
        isBundle: false
    },
    {
        _key: 'prod-002',
        productId: '01t5g000000XXXXAA2',
        productCode: 'SALE-002',
        productName: 'UltraWide Monitor 34"',
        quantity: 3,
        listUnitPrice: 899.00,
        additionalDiscount: 5,
        netUnitPrice: 854.05,
        netTotal: 2562.15,
        isBundle: false
    },
    {
        _key: 'bundle-001',
        productId: '01t5g000000XXXXAA3',
        productCode: 'BUNDLE-001',
        productName: 'Developer Starter Pack',
        quantity: 2,
        listUnitPrice: 2499.00,
        additionalDiscount: 0,
        netUnitPrice: 2499.00,
        netTotal: 4998.00,
        isBundle: true,
        options: [
            {
                _key: 'bundle-001-opt-1',
                productId: '01t5g000000XXXXAA4',
                productCode: 'DEV-IDE',
                productName: 'IDE License',
                quantity: 2,
                listUnitPrice: 299.00,
                additionalDiscount: 0,
                netUnitPrice: 299.00,
                netTotal: 598.00
            },
            {
                _key: 'bundle-001-opt-2',
                productId: '01t5g000000XXXXAA5',
                productCode: 'DEV-CLOUD',
                productName: 'Cloud Workspace',
                quantity: 2,
                listUnitPrice: 199.00,
                additionalDiscount: 0,
                netUnitPrice: 199.00,
                netTotal: 398.00
            },
            {
                _key: 'bundle-001-opt-3',
                productId: '01t5g000000XXXXAA6',
                productCode: 'DEV-SUPPORT',
                productName: 'Premium Support',
                quantity: 2,
                listUnitPrice: 99.00,
                additionalDiscount: 0,
                netUnitPrice: 99.00,
                netTotal: 198.00
            }
        ]
    },
    {
        _key: 'prod-003',
        productId: '01t5g000000XXXXAA7',
        productCode: 'RENT-001',
        productName: 'Projector Rental - Daily',
        quantity: 10,
        listUnitPrice: 75.00,
        additionalDiscount: 0,
        netUnitPrice: 75.00,
        netTotal: 750.00,
        isBundle: false
    },
    {
        _key: 'prod-004',
        productId: '01t5g000000XXXXAA8',
        productCode: 'SVC-001',
        productName: 'Installation Service',
        quantity: 4,
        listUnitPrice: 150.00,
        additionalDiscount: 20,
        netUnitPrice: 120.00,
        netTotal: 480.00,
        isBundle: false
    }
];

export default class CpqStepLineEditor extends LightningElement {
    @api pricebookId = '';
    @api offerType = null;

    @track gridData = [];
    @track isCalculating = false;
    @track hasErrors = false;
    @track errorMessages = [];
    @track expandedRows = new Set();

    _pendingChanges = new Map();
    _debounceTimer = null;

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

        processItems(this.gridData || []);
        return flat;
    }

    connectedCallback() {
        this._prepareGridData();
    }

    get columns() {
        return COLUMNS;
    }

    get totalItemCount() {
        return (this.gridData || []).length;
    }

    get subtotal() {
        if (this.gridData && this.gridData.length > 0) {
            return this.gridData.reduce((sum, item) => Math.max(0, sum + (item.netTotal || 0)), 0);
        }
        return 0;
    }

    get formattedSubtotal() {
        return formatCurrency(this.subtotal);
    }

    get isEmpty() {
        return !this.gridData || this.gridData.length === 0;
    }

    get isNotEmpty() {
        return !this.isEmpty;
    }

    _prepareGridData() {
        this.gridData = MOCK_PRODUCTS.map(item => {
            const hasOptions = item.isBundle && item.options && item.options.length > 0;

            const row = {
                _key: item._key,
                _hasError: false,
                _errorMessage: '',
                productId: item.productId,
                productCode: item.productCode,
                productName: item.productName,
                quantity: item.quantity || 1,
                listUnitPrice: item.listUnitPrice || 0,
                additionalDiscount: item.additionalDiscount || 0,
                netUnitPrice: item.netUnitPrice || (item.listUnitPrice || 0) * (1 - (item.additionalDiscount || 0) / 100),
                netTotal: item.netTotal || 0,
                isBundle: item.isBundle || false
            };

            // Only add _children property for bundles to show expand/collapse icon
            if (hasOptions) {
                row._children = [];
                item.options.forEach((opt, optIdx) => {
                    row._children.push({
                        _key: opt._key || `${item._key}-opt-${optIdx}`,
                        productId: opt.productId,
                        productCode: opt.productCode,
                        productName: opt.productName,
                        quantity: opt.quantity || 1,
                        listUnitPrice: opt.listUnitPrice || 0,
                        additionalDiscount: 0,
                        netUnitPrice: opt.netUnitPrice || opt.listUnitPrice || 0,
                        netTotal: opt.netTotal || 0,
                        _isOption: true
                    });
                });
            }

            return row;
        });
        // Force track array
        this.gridData = [...this.gridData];
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
        const updatedData = this.gridData.map(item => {
            if (!item._isOption) {
                return { ...item, isSelected: isChecked };
            }
            return item;
        });
        this.gridData = updatedData;
        this._dispatchSelectionChange();
    }

    handleRowSelect(event) {
        const rowId = event.currentTarget.dataset.id;
        const isChecked = event.target.checked;
        const updatedData = this.gridData.map(item => {
            if (item._key === rowId) {
                return { ...item, isSelected: isChecked };
            }
            return item;
        });
        this.gridData = updatedData;
        this._dispatchSelectionChange();
    }

    _dispatchSelectionChange() {
        const hasSelection = this.gridData.some(item => item.isSelected);
        this.dispatchEvent(new CustomEvent('selectionchange', {
            detail: { hasSelection }
        }));
    }

    handleDeleteSelected() {
        const selectedIds = new Set(this.gridData.filter(item => item.isSelected).map(item => item._key));

        if (selectedIds.size === 0) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'No Selection',
                message: 'Please select at least one row to delete.',
                variant: 'warning'
            }));
            return;
        }

        // Filter out selected parent rows
        this.gridData = this.gridData.filter(item => !selectedIds.has(item._key));

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

        this.dispatchEvent(new ShowToastEvent({
            title: 'Rows Deleted',
            message: `Successfully deleted ${selectedIds.size} row(s).`,
            variant: 'success'
        }));

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
        if(fieldName === 'quantity' || fieldName === 'additionalDiscount') {
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
        const updatedData = [...this.gridData];
        const rowIndex = updatedData.findIndex(row => row._key === itemKey);

        if (rowIndex !== -1) {
            const row = { ...updatedData[rowIndex] };
            row[field] = value;

            if (field === 'quantity' || field === 'additionalDiscount') {
                row.netUnitPrice = (row.listUnitPrice || 0) * (1 - (row.additionalDiscount || 0) / 100);
                row.netTotal = row.netUnitPrice * row.quantity;
            }

            updatedData[rowIndex] = row;
            this.gridData = updatedData;
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

        this.isCalculating = true;
        const lineItems = [];

        for (const [itemKey, changes] of this._pendingChanges) {
            const row = this.gridData.find(r => r._key === itemKey);
            if (row) {
                lineItems.push({
                    productId: row.productId,
                    quantity: changes.quantity ?? row.quantity,
                    discount: changes.additionalDiscount ?? row.additionalDiscount
                });
            }
        }

        try {
            const results = await calculateLinePricesBatch({
                lineItems: lineItems,
                offerType: this.offerType,
                pricebookId: this.pricebookId
            });

            const updatedData = [...this.gridData];
            let hasErrors = false;

            for (let i = 0; i < results.length; i++) {
                const result = results[i];
                const itemKey = Array.from(this._pendingChanges.keys())[i];
                const rowIndex = updatedData.findIndex(r => r._key === itemKey);

                if (rowIndex !== -1) {
                    const row = { ...updatedData[rowIndex] };

                    if (result.success) {
                        row.listUnitPrice = result.listPrice;
                        row.netUnitPrice = result.netPrice;
                        row.netTotal = result.totalPrice;
                        row._hasError = false;
                        row._errorMessage = '';
                    } else {
                        row._hasError = true;
                        row._errorMessage = result.errorMessage;
                        hasErrors = true;
                    }

                    updatedData[rowIndex] = row;
                }
            }

            this.gridData = updatedData;
            this._pendingChanges.clear();

            if (hasErrors) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Pricing Warning',
                    message: 'Some items could not be priced. Check the line editor for details.',
                    variant: 'warning'
                }));
            }

        } catch (error) {
            console.error('Pricing calculation error:', error);
            this.dispatchEvent(new ShowToastEvent({
                title: 'Pricing Error',
                message: error.message || 'Pricing calculation failed',
                variant: 'error'
            }));
        } finally {
            this.isCalculating = false;
        }
    }

   

    async handleRefreshPricing() {
        this._pendingChanges.clear();
        this.gridData.forEach(row => {
            this._pendingChanges.set(row._key, {
                quantity: row.quantity,
                additionalDiscount: row.additionalDiscount
            });
        });
        await this._executeBatchCalculation();

        this.dispatchEvent(new ShowToastEvent({
            title: 'Pricing Refreshed',
            message: 'All prices have been recalculated',
            variant: 'success'
        }));
    }

    handleValidateAll() {
        const errors = [];
        const updatedData = [...this.gridData];

        updatedData.forEach(row => {
            if (row.additionalDiscount < 0 || row.additionalDiscount > 100) {
                row._hasError = true;
                row._errorMessage = 'Discount must be between 0 and 100';
                errors.push(`${row.productName}: Invalid discount`);
            } else if (row.quantity < 1) {
                row._hasError = true;
                row._errorMessage = 'Quantity must be at least 1';
                errors.push(`${row.productName}: Invalid quantity`);
            } else {
                row._hasError = false;
                row._errorMessage = '';
            }
        });

        this.gridData = updatedData;

        if (errors.length > 0) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Validation Failed',
                message: `${errors.size} item(s) have validation errors: ${errors.join(', ')}`,
                variant: 'error'
            }));
        } else {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Validation Passed',
                message: 'All line items are valid',
                variant: 'success'
            }));
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
