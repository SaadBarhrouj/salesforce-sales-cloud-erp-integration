import { LightningElement, api, track } from 'lwc';
import { formatCurrency, showToast, getOptionTypePolicy, OPTION_TYPE_COMPONENT } from 'c/cpqUtils';
import calculateLinePrices from '@salesforce/apex/PricebookController.calculateLinePrices';
import getOptionMetadata from '@salesforce/apex/BundleOptionController.getOptionMetadata';
import evaluateLineRules from '@salesforce/apex/ProductRuleController.evaluateLineRules';

const DEBOUNCE_DELAY = 500;

const BASE_COLUMNS = [
    { type: 'text', fieldName: 'productName', label: 'Product', isProduct: true, style: 'width: 23rem' },
    { type: 'text', fieldName: 'productCode', label: 'Code', isCode: true },
    { type: 'number', fieldName: 'quantity', label: 'Qty', editable: true, isQty: true },
    { type: 'currency', fieldName: 'listUnitPrice', label: 'List Price', isCurrency: true, isListPrice: true },
    { type: 'number', fieldName: 'additionalDiscount', label: 'Disc. %', editable: true, isDiscount: true },
    { type: 'currency', fieldName: 'netUnitPrice', label: 'Net Price', isCurrency: true, isNetPrice: true },
    { type: 'currency', fieldName: 'netTotal', label: 'Total', isCurrency: true, isTotal: true }
];

const SERVICE_COLUMNS_INSERT = [
    { type: 'date', fieldName: 'serviceStartDate', label: 'Start', editable: true, isStartDate: true },
    { type: 'date', fieldName: 'serviceEndDate', label: 'End', editable: true, isEndDate: true },
    { type: 'currency', fieldName: 'dailyRate', label: 'Daily Rate', isCurrency: true, isDailyRate: true }
];

export default class CpqStepLineEditor extends LightningElement {
    _pricebookId = '';
    _offerType = null;
    _selectedProducts = [];

    @track lineItems = []; // FLATTENED state
    @track isLoading = true;
    @track expandedRows = new Set();

    @api opportunityId;
    @track ruleMessages = { errors: [], alerts: [] };

    _debounceTimer = null;
    _calculationSequence = 0;
    _initialPricingRequested = false;

    _isVolumeOffer = false;
    _headerStart = null;
    _headerEnd = null;

    @api
    get isVolumeOffer() { return this._isVolumeOffer; }
    set isVolumeOffer(v) {
        this._isVolumeOffer = !!v;
        this._cascadeHeaderToLines();
    }

    get serviceStartDate() { return this._headerStart; }
    get serviceEndDate() { return this._headerEnd; }

    get headerDays() {
        return this._daysBetween(this._headerStart, this._headerEnd);
    }

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
        this._enrichOptionMetadataThenPrepare();
    }

    async _enrichOptionMetadataThenPrepare() {
        const needsMetadata = [];
        for (const item of this._selectedProducts) {
            if (!item.isBundle || !item.configuredOptions) continue;
            for (const opt of item.configuredOptions) {
                if (opt.optionType == null || opt.defaultQuantity == null) {
                    needsMetadata.push({ parentProductId: item.productId, optionProductId: opt.productId });
                }
            }
        }
        if (needsMetadata.length > 0) {
            const parentToOptionIds = {};
            for (const pair of needsMetadata) {
                if (!parentToOptionIds[pair.parentProductId]) parentToOptionIds[pair.parentProductId] = [];
                parentToOptionIds[pair.parentProductId].push(pair.optionProductId);
            }
            try {
                const metadata = await getOptionMetadata({ parentToOptionIds });
                for (const item of this._selectedProducts) {
                    if (!item.isBundle || !item.configuredOptions) continue;
                    for (const opt of item.configuredOptions) {
                        const key = `${item.productId}|${opt.productId}`;
                        const md = metadata[key];
                        if (md) {
                            opt.optionType = opt.optionType ?? md.optionType;
                            opt.defaultQuantity = opt.defaultQuantity ?? md.defaultQuantity;
                            opt.minQuantity = opt.minQuantity ?? md.minQuantity;
                            opt.maxQuantity = opt.maxQuantity ?? md.maxQuantity;
                        }
                    }
                }
            } catch (err) {
                console.error('getOptionMetadata failed', err);
            }
        }
        this._prepareLineItems();
        // On remount the header dates reset to null because the component was
        // unmounted by the parent's lwc:if. Recover them from the persisted
        // lines so the cascade has a sane source.
        this._hydrateHeaderFromLines();
        // After rebuilding lines, push header dates onto fresh lines so a rep
        // who set the header before adding products doesn't have to retype.
        this._cascadeHeaderToLines();
        this._scheduleInitialPricing();
    }

    // ─── GETTERS ────────────────────────────────────────────────────────────

    get columns() {
        if (!this._isVolumeOffer) return BASE_COLUMNS;
        // Insert service-period columns between Qty and List Price for visual grouping.
        const out = [...BASE_COLUMNS];
        out.splice(3, 0, ...SERVICE_COLUMNS_INSERT);
        return out;
    }

    get isEmpty() {
        return !this.lineItems || this.lineItems.length === 0;
    }

    get isNotEmpty() {
        return !this.isEmpty;
    }

    get hasValidationErrors() {
        return this.ruleMessages.errors.length > 0;
    }

    get hasAlerts() {
        return this.ruleMessages.alerts.length > 0;
    }

    get hasRuleMessages() {
        return this.hasValidationErrors || this.hasAlerts;
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
                isQtyEditable: !row._isOption || getOptionTypePolicy(row.optionType).editableInLineEditor,
                isDiscountEditable: true,
                showCheckbox: !row._isOption,
                rowClass: `slds-hint-parent ${row._hasError ? 'slds-is-selected row-error' : ''}`,
                paddingStyle: `padding-left: ${row._isOption ? 1 : 0}rem;`,
                isSelected: !!row.isSelected,
                formattedListPrice: formatCurrency(Number.isFinite(row.listUnitPrice) ? row.listUnitPrice : 0),
                formattedNetPrice: formatCurrency(Number.isFinite(row.netUnitPrice) ? row.netUnitPrice : 0),
                formattedNetTotal: formatCurrency(Number.isFinite(row.netTotal) ? row.netTotal : 0),
                formattedDailyRate: formatCurrency(Number.isFinite(row.dailyRate) ? row.dailyRate : 0),
                
            });
        }
        return viewData;
    }

    // ─── LIFECYCLE ──────────────────────────────────────────────────────────

    connectedCallback() {
        this._prepareLineItems();
        this._scheduleInitialPricing();
    }

    disconnectedCallback() {
        clearTimeout(this._debounceTimer);
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
            _serviceOverridden: !!item._serviceOverridden,
            productId: item.productId,
            productCode: item.productCode,
            productName: item.productName,
            quantity: qty,
            listUnitPrice: listPrice,
            dailyRate: Number(item.dailyRate) || listPrice,
            additionalDiscount: discount,
            netUnitPrice: netPrice,
            netTotal: total,
            isBundle: item.isBundle,
            serviceStartDate: item.serviceStartDate || null,
            serviceEndDate: item.serviceEndDate || null,
            serviceDays: this._daysBetween(item.serviceStartDate, item.serviceEndDate),
            w: item.w,
            h: item.h,
            d: item.d,
            weight: item.weight
        };
    }

    _buildOptionLineItem(parentKey, opt, parentItem) {
        const optionType = opt.optionType || 'Related Product';
        const policy = getOptionTypePolicy(optionType);
        const perBundleQty = Number(opt.defaultQuantity ?? opt.quantity) || 0;
        const parentQty = Number(parentItem && parentItem.quantity) || 1;
        const effectiveQty = policy.scalesWithParent
            ? perBundleQty * parentQty
            : (Number(opt.quantity) || perBundleQty);

        const optListPrice = Number(opt.unitPrice) || 0;
        const optDiscount = Number(opt.additionalDiscount) || 0;
        const optNetPrice = optListPrice * (1 - optDiscount / 100);
        const optNetTotal = optNetPrice * effectiveQty;

        return {
            _key: opt.Id,
            _parentId: parentKey,
            _parentProductId: parentItem && parentItem.productId,
            _isOption: true,
            _hasError: false,
            _errorMessage: '',
            _serviceOverridden: !!opt._serviceOverridden,
            productId: opt.productId || opt.Id,
            optionId: opt.Id,
            productCode: opt.productCode,
            productName: opt.productName,
            quantity: effectiveQty,
            perBundleQty,
            optionType,
            minQuantity: opt.minQuantity,
            maxQuantity: opt.maxQuantity,
            listUnitPrice: optListPrice,
            dailyRate: Number(opt.dailyRate) || optListPrice,
            additionalDiscount: optDiscount,
            netUnitPrice: optNetPrice,
            netTotal: optNetTotal,
            serviceStartDate: opt.serviceStartDate || null,
            serviceEndDate: opt.serviceEndDate || null,
            serviceDays: this._daysBetween(opt.serviceStartDate, opt.serviceEndDate),
            w: opt.w,
            h: opt.h,
            d: opt.d,
            weight: opt.weight
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
                    flatItems.push(this._buildOptionLineItem(item._key, opt, item));
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

    // ─── RENTAL HELPERS ─────────────────────────────────────────────────────

    _cascadeHeaderToLines() {
        if (!this._isVolumeOffer) return;
        if (!this.lineItems || !this.lineItems.length) return;
        // Bug guard: an empty header (component remount before the user has typed
        // dates again) must NOT nullify the dates the rep already saved on lines.
        if (!this._headerStart && !this._headerEnd) return;
        const days = this._daysBetween(this._headerStart, this._headerEnd);
        this.lineItems = this.lineItems.map(row => {
            if (row._serviceOverridden) return row;
            return {
                ...row,
                serviceStartDate: this._headerStart,
                serviceEndDate: this._headerEnd,
                serviceDays: days
            };
        });
        this._schedulePricingCalculation();
    }

    _hydrateHeaderFromLines() {
        if (!this._isVolumeOffer) return;
        if (this._headerStart || this._headerEnd) return;
        if (!this.lineItems || !this.lineItems.length) return;
        for (const row of this.lineItems) {
            if (row._isOption) continue;
            if (row.serviceStartDate && row.serviceEndDate) {
                this._headerStart = row.serviceStartDate;
                this._headerEnd = row.serviceEndDate;
                return;
            }
        }
    }

    _daysBetween(s, e) {
        if (!s || !e) return 0;
        const sd = new Date(s);
        const ed = new Date(e);
        const ms = ed.getTime() - sd.getTime();
        if (ms < 0) return 0;
        return Math.floor(ms / (1000 * 60 * 60 * 24)) + 1; // inclusive
    }

    handleHeaderServiceChange(event) {
        const field = event.target.dataset.field;
        const value = event.target.value || null;
        if (field === 'serviceStartDate') this._headerStart = value;
        if (field === 'serviceEndDate') this._headerEnd = value;
        this._cascadeHeaderToLines();
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
            if (row._key === itemKey) {
                const updatedRow = { ...row, [fieldName]: value };
                if (fieldName === 'serviceStartDate' || fieldName === 'serviceEndDate') {
                    updatedRow._serviceOverridden = true;
                    updatedRow.serviceDays = this._daysBetween(updatedRow.serviceStartDate, updatedRow.serviceEndDate);
                }
                const isPriceImpacting = fieldName === 'quantity'
                    || fieldName === 'additionalDiscount'
                    || fieldName === 'serviceStartDate'
                    || fieldName === 'serviceEndDate';
                if (isPriceImpacting) {
                    const dailyRate = Number(updatedRow.dailyRate) || Number(updatedRow.listUnitPrice) || 0;
                    const days = this._isVolumeOffer ? Math.max(updatedRow.serviceDays || 0, 0) : 1;
                    const effectiveListPrice = this._isVolumeOffer
                        ? dailyRate * days
                        : (Number(updatedRow.listUnitPrice) || 0);
                    const discount = Number(updatedRow.additionalDiscount) || 0;
                    const qty = Number(updatedRow.quantity) || 1;
                    updatedRow.netUnitPrice = effectiveListPrice * (1 - discount / 100);
                    updatedRow.netTotal = updatedRow.netUnitPrice * qty;
                    if (this._isVolumeOffer) {
                        updatedRow.listUnitPrice = effectiveListPrice;
                    }
                }
                return updatedRow;
            }

            // Re-scale Component option children when the parent row's quantity changed.
            if (fieldName === 'quantity'
                && row._isOption
                && row._parentId === itemKey
                && row.optionType === OPTION_TYPE_COMPONENT) {
                const newParentQty = Number(value) || 1;
                const newQty = (Number(row.perBundleQty) || 0) * newParentQty;
                const listPrice = Number(row.listUnitPrice) || 0;
                const disc = Number(row.additionalDiscount) || 0;
                const netPrice = listPrice * (1 - disc / 100);
                return {
                    ...row,
                    quantity: newQty,
                    netUnitPrice: netPrice,
                    netTotal: netPrice * newQty
                };
            }
            return row;
        });

        this._schedulePricingCalculation();
    }

    // ─── PRICING CALCULATIONS ────────────────────────────────────────────────

    _schedulePricingCalculation() {
        if (this._debounceTimer) {
            clearTimeout(this._debounceTimer);
        }
        this._debounceTimer = setTimeout(async () => {
            await this._executePricingCalculation();
            this._runRuleEvaluation('Edit', false);
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

            if (this._isVolumeOffer) {
                const missingDates = !row.serviceStartDate || !row.serviceEndDate;
                const inverted = !missingDates && new Date(row.serviceEndDate) < new Date(row.serviceStartDate);
                if (missingDates || inverted) {
                    updatedData[i] = { ...row, _hasError: false, _errorMessage: '' };
                    continue;
                }
            }

            pricingRequestKeys.push(row._key);
            pricingRequestItems.push({
                productId: row.productId,
                quantity: row.quantity,
                discount: row.additionalDiscount,
                serviceStartDate: this._isVolumeOffer ? row.serviceStartDate : null,
                serviceEndDate: this._isVolumeOffer ? row.serviceEndDate : null
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
                        if (result.dailyRate != null) {
                            rowToUpdate.dailyRate = result.dailyRate;
                            rowToUpdate.serviceDays = result.serviceDays;
                        }
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
            const updatedRow = { ...row, _hasError: false, _errorMessage: '' };
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
            } else if (updatedRow._isOption && getOptionTypePolicy(updatedRow.optionType).editableInLineEditor) {
                const min = Number(updatedRow.minQuantity);
                const max = Number(updatedRow.maxQuantity);
                if (Number.isFinite(min) && quantity < min) {
                    updatedRow._hasError = true;
                    updatedRow._errorMessage = `Quantity must be at least ${min}`;
                    hasValidationErrors = true;
                } else if (Number.isFinite(max) && quantity > max) {
                    updatedRow._hasError = true;
                    updatedRow._errorMessage = `Quantity must be at most ${max}`;
                    hasValidationErrors = true;
                }
            }

            if (this._isVolumeOffer && !updatedRow._hasError) {
                if (!updatedRow.serviceStartDate || !updatedRow.serviceEndDate) {
                    updatedRow._hasError = true;
                    updatedRow._errorMessage = 'Service Start and End dates are required';
                    hasValidationErrors = true;
                } else if (new Date(updatedRow.serviceEndDate) < new Date(updatedRow.serviceStartDate)) {
                    updatedRow._hasError = true;
                    updatedRow._errorMessage = 'End Date must be on or after Start Date';
                    hasValidationErrors = true;
                }
            }

            return updatedRow;
        });

        return !hasValidationErrors && !this._hasPricingErrors();
    }

    _hasPricingErrors() {
        return this.lineItems.some(row => row._hasError);
    }

    /**
     * Evaluates the Validation and Alert Product Rules against every line item.
     * Called when the rep advances from the Line Editor. Validation errors block;
     * alerts warn but allow continuing.
     * @returns {Promise<{blocked: boolean}>}
     */
    @api
    async evaluateLineRules() {
        return this._runRuleEvaluation('Save', true);
    }

    async _runRuleEvaluation(evaluationEvent, blocking) {
        const lines = this.lineItems.map((row) => ({
            productId: row.productId,
            quantity: row.quantity,
            unitPrice: row.listUnitPrice,
            discountPercent: row.additionalDiscount,
            isBundle: !!row.isBundle
        }));

        try {
            const verdict = await evaluateLineRules({
                opportunityId: this.opportunityId || null,
                lines,
                evaluationEvent
            });
            const errors = verdict.validationErrors || [];
            const alerts = verdict.alerts || [];
            this.ruleMessages = {
                errors: errors.map((text, i) => ({ id: 'lerr-' + i, text })),
                alerts: alerts.map((text, i) => ({ id: 'lalert-' + i, text }))
            };
            const blocked = blocking && errors.length > 0;
            if (blocked) {
                showToast(this, 'Validation', 'Please fix the validation errors below before continuing.', 'error');
            }
            return { blocked };
        } catch (error) {
            console.error('[cpqStepLineEditor._runRuleEvaluation] Rule evaluation failed:', error);
            const detail = error?.body?.message || error?.message || 'Rule evaluation failed.';
            showToast(this, 'Rules Error', detail, 'error');
            return { blocked: false };
        }
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
                    perBundleQty: row.perBundleQty,
                    optionType: row.optionType,
                    unitPrice: row.listUnitPrice,
                    dailyRate: row.dailyRate,
                    netUnitPrice: row.netUnitPrice,
                    netTotal: row.netTotal,
                    additionalDiscount: row.additionalDiscount,
                    serviceStartDate: row.serviceStartDate || null,
                    serviceEndDate: row.serviceEndDate || null,
                    _serviceOverridden: !!row._serviceOverridden,
                    w: row.w,
                    h: row.h,
                    d: row.d,
                    weight: row.weight
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
                    dailyRate: row.dailyRate,
                    additionalDiscount: row.additionalDiscount,
                    netUnitPrice: row.netUnitPrice,
                    netTotal: row.netTotal,
                    isBundle: row.isBundle,
                    serviceStartDate: row.serviceStartDate || null,
                    serviceEndDate: row.serviceEndDate || null,
                    _serviceOverridden: !!row._serviceOverridden,
                    w: row.w,
                    h: row.h,
                    d: row.d,
                    weight: row.weight,
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
