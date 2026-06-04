import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getIllustration, OPTION_TYPES } from 'c/cpqConstants';
import { showToast, deepClone, formatMessage, getOptionTypePolicy } from 'c/cpqUtils';
import getBundleData from '@salesforce/apex/BundleOptionController.getBundleData';
import evaluateBundleRules from '@salesforce/apex/ProductRuleController.evaluateBundleRules';
import PRODUCT_NAME_FIELD from '@salesforce/schema/Product2.Name';

const DATATABLE_COLUMNS = [
    {
        label: 'Quantity',
        fieldName: 'quantity',
        type: 'number',
        editable: { fieldName: 'isQtyEditable' },
        typeAttributes: { step: 1, min: 0 },
        cellAttributes: { alignment: 'left' }
    },
    { label: 'Code', fieldName: 'productCode', type: 'text' },
    {
        label: 'Name',
        fieldName: 'productUrl',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'productName' },
            target: '_blank',
            tooltip: { fieldName: 'productName' }
        }
    },
    { label: 'Description', fieldName: 'description', type: 'text' },
    { label: 'Type', fieldName: 'optionType', type: 'text' },
];

const OPTION_TYPE_FILTER_OPTIONS = [
    { label: 'All', value: 'all' },
    { label: 'Component', value: OPTION_TYPES.COMPONENT },
    { label: 'Accessory', value: OPTION_TYPES.ACCESSORY },
    { label: 'Related Product', value: OPTION_TYPES.RELATED_PRODUCT }
];

export default class cpqStepBundleConfig extends LightningElement {
    _itemKey;
    @api
    get itemKey() {
        return this._itemKey;
    }
    set itemKey(value) {
        this._itemKey = value;
        this.scheduleLoad();
    }
    
    _bundleId;

    @api
    get bundleId() {
        return this._bundleId;
    }
    set bundleId(value) {
        this._bundleId = value;
        this.scheduleLoad();
    }

    _cachedFeatures = null;

    @api
    get cachedFeatures() {
        return this._cachedFeatures;
    }
    set cachedFeatures(value) {
        this._cachedFeatures = value;
        this.scheduleLoad();
    }

    @api opportunityId;

    _ruleEvalTimer;

    _loadTimer;
    scheduleLoad() {
        if (!this._bundleId || !this._itemKey) return;
        clearTimeout(this._loadTimer);
        this._loadTimer = setTimeout(() => {
            this.loadConfiguration();
        }, 0);
    }

    disconnectedCallback() {
        clearTimeout(this._loadTimer);
        clearTimeout(this._ruleEvalTimer);
    }

    @track isLoading = false;
    @track featureDraftValues = {};
    @track localFeatures = [];
    @track bundleName = '';
    @track viewMode = 'sections';

    @track isFilterPanelOpen = false;
    @track pendingFilterProductCode = '';
    @track pendingFilterOptionType = 'all';
    @track filterProductCode = '';
    @track filterOptionType = 'all';
    optionTypeOptions = OPTION_TYPE_FILTER_OPTIONS;

    @api
    get currentFeaturesState() {
        return this.localFeatures;
    }

    @wire(getRecord, { recordId: '$_bundleId', fields: [PRODUCT_NAME_FIELD] })
    bundleRecord;

    async loadConfiguration() {
        this.isLoading = true;

        try {
            if (!this.bundleId || !this.itemKey) {
                return;
            }

            if (this._cachedFeatures && this._cachedFeatures.length > 0) {
                this.localFeatures = deepClone(this._cachedFeatures);
            } else {
                const result = await getBundleData({ bundleId: this.bundleId });
                this.localFeatures = deepClone((result && result.features) || []);
            }
            
            if (this.bundleRecord?.data) {
                this.bundleName = getFieldValue(this.bundleRecord.data, PRODUCT_NAME_FIELD) || 'Bundle Configuration';
            } else {
                this.bundleName = 'Bundle Configuration';
            }
        } catch (error) {
            console.error('Error loading bundle data:', error);
            showToast(this, 'Loading Error', 'Unable to load bundle configuration.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    get columns() {
        return DATATABLE_COLUMNS;
    }

    get isSectionsView() {
        return this.viewMode === 'sections';
    }

    get isTabsView() {
        return this.viewMode === 'tabs';
    }

    get sectionsButtonVariant() {
        return this.isSectionsView ? 'brand' : 'neutral';
    }

    get tabsButtonVariant() {
        return this.isTabsView ? 'brand' : 'neutral';
    }

    get hasFeatures() { 
        return (this.processedFeatures?.length > 0) && !!this._bundleId;
    }

    get noBundleSelected() {
        return !this.isLoading && !this._bundleId;
    }

    get hasNoFeatures() {
        return !this.isLoading && this._bundleId && !this.hasFeatures;
    }

    get isFilteredEmpty() {
        return !!this._bundleId
            && this.localFeatures.length > 0
            && this.hasActiveFilters
            && this.processedFeatures.length === 0;
    }

    get emptyStateTitle() {
        if (this.noBundleSelected) {
            return 'No Bundle Selected';
        }
        if (this.isFilteredEmpty) {
            return 'No Matching Options';
        }
        return 'No Configuration Options';
    }

    get emptyStateDescription() {
        if (this.noBundleSelected) {
            return 'Select a bundle above to configure its features and options.';
        }
        if (this.isFilteredEmpty) {
            return 'No options match the current filters. Adjust or reset them.';
        }
        return 'This bundle has no configurable features.';
    }

    get emptyStateIllustration() {
        if (this.noBundleSelected) {
            return getIllustration('CART_NO_ITEMS').name;
        }
        if (this.isFilteredEmpty) {
            return getIllustration('NORESULTS_FILTER').name;
        }
        return getIllustration('NORESULTS_SEARCH').name;
    }

    get filterPanelClass() {
        const base = 'filter-panel';
        return this.isFilterPanelOpen ? `${base} filter-panel--open` : base;
    }

    get filterPanelHidden() {
        return !this.isFilterPanelOpen;
    }

    @api
    get filterPanelOpen() {
        return this.isFilterPanelOpen;
    }

    get hasActiveFilters() {
        return !!this.filterProductCode || (this.filterOptionType && this.filterOptionType !== 'all');
    }

    get activeFilters() {
        const filters = [];
        if (this.filterProductCode) {
            filters.push({ id: 'productCode', label: 'Code: ' + this.filterProductCode, value: this.filterProductCode, field: 'productCode' });
        }
        if (this.filterOptionType && this.filterOptionType !== 'all') {
            filters.push({ id: 'optionType', label: 'Type: ' + this.filterOptionType, value: this.filterOptionType, field: 'optionType' });
        }
        return filters;
    }

    get processedFeatures() {
        return this.localFeatures.map((feature) => {
            const allOptions = feature.options || [];
            let options = allOptions.filter((opt) => !opt.isRuleHidden);
            const codeTerm = (this.filterProductCode || '').toLowerCase();
            if (codeTerm) {
                options = options.filter(
                    (opt) => (opt.productCode || '').toLowerCase().includes(codeTerm)
                );
            }
            if (this.filterOptionType && this.filterOptionType !== 'all') {
                options = options.filter((opt) => opt.optionType === this.filterOptionType);
            }
            const min = feature.minOptions;
            const max = feature.maxOptions;

            const selectedIds = options.filter((opt) => opt.isSelected).map((opt) => opt.Id);
            const requiredIds = options.filter((opt) => opt.isRequired).map((opt) => opt.Id);
            const lockedIds = options
                .filter((opt) => opt.isRuleLocked)
                .map((opt) => opt.Id);

            let disabledIds = [];
            if (max != null && requiredIds.length >= max && max > 0) {
                disabledIds = options.map((opt) => opt.Id);
            } else {
                disabledIds = requiredIds;
            }
            const mergedDisabled = [...new Set([...disabledIds, ...lockedIds])];

            return {
                Id: feature.Id,
                Name: feature.Name,
                helpText: feature.helpText,
                minOptions: min,
                maxOptions: max,
                minMaxDisplay: this.getMinMaxDisplay(min, max),
                badgeClass: 'slds-badge',
                options: this.processOptions(options),
                selectedRows: selectedIds,
                disabledRows: mergedDisabled,
                draftValues: this.featureDraftValues[feature.Id] || []
            };
        }).filter((feature) => !this.hasActiveFilters || feature.options.length > 0);
    }

    getMinMaxDisplay(min, max) {
        if (min != null && max != null) {
            return `Min: ${min} / Max: ${max}`;
        } else if (min != null) {
            return `Min: ${min}`;
        } else if (max != null) {
            return `Max: ${max}`;
        }
        return '';
    }

    processOptions(options) {
        return (options || []).map((option) => {
            const policy = getOptionTypePolicy(option.optionType);
            const initialQty = option.quantity !== undefined ? option.quantity : option.defaultQuantity;
            return {
                Id: option.Id,
                productId: option.productId,
                quantity: policy.editableInConfigurator ? initialQty : option.defaultQuantity,
                minQuantity: option.minQuantity,
                maxQuantity: option.maxQuantity,
                productCode: option.productCode,
                productName: option.productName,
                productUrl: option.productId ? `/${option.productId}` : null,
                description: option.description,
                unitPrice: option.unitPrice,
                optionType: option.optionType,
                defaultQuantity: option.defaultQuantity,
                isQtyEditable: policy.editableInConfigurator,
                isRequired: option.isRequired,
                isSelected: option.isSelected,
                w: option.w,
                h: option.h,
                d: option.d,
                weight: option.weight
            };
        });
    }

    handleFeatureSelection(event) {
        const featureId = event.target.dataset.featureId;
        const selectedRows = event.detail.selectedRows;

        const featureIndex = this.localFeatures.findIndex((f) => f.Id === featureId);
        const feature = this.localFeatures[featureIndex];

        if (selectedRows.length < feature.minOptions) {
            showToast(
                this,
                'Action Not Allowed',
                `You must select at least ${feature.minOptions} option(s) for "${feature.Name}".`,
                'warning'
            );
            this.localFeatures = [...this.localFeatures];
            return;
        }

        const selectedIds = selectedRows.map((row) => row.Id);

        this.localFeatures[featureIndex].options = feature.options.map((opt) => ({
            ...opt,
            isSelected: selectedIds.includes(opt.Id)
        }));

        this.localFeatures = [...this.localFeatures];
        this._scheduleRuleEvaluation();
    }

    @api
    switchToSections() {
        this.viewMode = 'sections';
    }

    @api
    switchToTabs() {
        this.viewMode = 'tabs';
    }

    async _fetchFeaturesFromServer() {
        const result = await getBundleData({ bundleId: this._bundleId });
        return deepClone((result && result.features) || []);
    }

    @api
    async refresh() {
        if (!this._bundleId) {
            showToast(this, 'No Bundle', 'Select a bundle to refresh.', 'info');
            return;
        }
        const hadUnsavedEdits = Object.keys(this.featureDraftValues || {})
            .some((key) => (this.featureDraftValues[key] || []).length > 0);
        this.isLoading = true;
        try {
            this.localFeatures = await this._fetchFeaturesFromServer();
            this.featureDraftValues = {};
            showToast(
                this,
                'Bundle Reloaded',
                hadUnsavedEdits
                    ? 'Configuration reloaded. Unsaved edits were discarded.'
                    : 'Configuration reloaded.',
                hadUnsavedEdits ? 'warning' : 'success'
            );
        } catch (error) {
            console.error('Error refreshing bundle data:', error);
            showToast(this, 'Refresh Error', 'Unable to reload bundle configuration.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    @api
    async resetCurrentBundle() {
        if (!this._bundleId) {
            showToast(this, 'No Bundle', 'Select a bundle to reset.', 'info');
            return;
        }
        this.isLoading = true;
        try {
            const features = await this._fetchFeaturesFromServer();
            this.localFeatures = features.map((feature) => ({
                ...feature,
                options: (feature.options || []).map((opt) => ({
                    ...opt,
                    isSelected: opt.isRequired ? true : !!opt.isSelected,
                    quantity: opt.defaultQuantity != null ? opt.defaultQuantity : opt.quantity
                }))
            }));
            this.featureDraftValues = {};
            showToast(this, 'Configuration Reset', 'Bundle reset to its default configuration.', 'success');
        } catch (error) {
            console.error('Error resetting bundle configuration:', error);
            showToast(this, 'Reset Error', 'Unable to reset bundle configuration.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    @api
    toggleFilterPanel() {
        this.isFilterPanelOpen = !this.isFilterPanelOpen;
        if (this.isFilterPanelOpen) {
            this.pendingFilterProductCode = this.filterProductCode;
            this.pendingFilterOptionType = this.filterOptionType;
        }
    }

    handleFilterProductCodeChange(event) {
        this.pendingFilterProductCode = event.detail.value || '';
    }

    handleFilterOptionTypeChange(event) {
        this.pendingFilterOptionType = event.detail.value;
    }

    handleApplyFilters() {
        this.filterProductCode = this.pendingFilterProductCode;
        this.filterOptionType = this.pendingFilterOptionType;
    }

    handleResetFilters() {
        this.pendingFilterProductCode = '';
        this.pendingFilterOptionType = 'all';
        this.filterProductCode = '';
        this.filterOptionType = 'all';
    }

    handleRemoveFilter(event) {
        const field = event.detail?.name || event.target?.name || event.currentTarget?.dataset?.field;
        if (field === 'productCode') {
            this.filterProductCode = '';
            this.pendingFilterProductCode = '';
        } else if (field === 'optionType') {
            this.filterOptionType = 'all';
            this.pendingFilterOptionType = 'all';
        }
    }

    handleCloseFilterPanel() {
        this.isFilterPanelOpen = false;
    }

    applyDraftValues(featureId, drafts) {
            const featureIndex = this.localFeatures.findIndex(f => f.Id === featureId);
            if (featureIndex !== -1) {
                let feature = { ...this.localFeatures[featureIndex] };
                let options = [...feature.options];
                
                drafts.forEach(draft => {
                    let optionIndex = options.findIndex(opt => opt.Id === draft.Id);
                    if (optionIndex !== -1) {
                        options[optionIndex] = { ...options[optionIndex], quantity: Number(draft.quantity) };
                    }
                });
                feature.options = options;
                
                let newFeatures = [...this.localFeatures];
                newFeatures[featureIndex] = feature;
                this.localFeatures = newFeatures;
            }
        }

    handleCancelTable(event) {
        const featureId = event.target.dataset.featureId;
        this.featureDraftValues = { ...this.featureDraftValues, [featureId]: [] };
    }

    handleSaveTable(event) {
        const featureId = event.target.dataset.featureId;
        const drafts = event.detail.draftValues;
        const featureIndex = this.localFeatures.findIndex(f => f.Id === featureId);
        if (featureIndex === -1) return;
        
        const feature = this.localFeatures[featureIndex];
        let hasValidationError = false;
        
        drafts.forEach(draft => {
            const optionIndex = feature.options.findIndex(opt => opt.Id === draft.Id);
            if (optionIndex !== -1) {
                const option = feature.options[optionIndex];
                const quantity = Number(draft.quantity);
                
                if (option.minQuantity != null && quantity < option.minQuantity) {
                    showToast(
                        this,
                        'Quantity Error',
                        `Minimum quantity for "${option.productName}" is ${option.minQuantity}`,
                        'warning'
                    );
                    hasValidationError = true;
                }
                
                if (option.maxQuantity != null && quantity > option.maxQuantity) {
                    showToast(
                        this,
                        'Quantity Error',
                        `Maximum quantity for "${option.productName}" is ${option.maxQuantity}`,
                        'warning'
                    );
                    hasValidationError = true;
                }
            }
        });
        
        if (hasValidationError) {
            return;
        }
        
        this.applyDraftValues(featureId, drafts);
        
        this.featureDraftValues = { ...this.featureDraftValues, [featureId]: [] };
    }

    @api
    saveCurrentConfig() {
        // Validate all draft values before applying
        let hasValidationError = false;
        
        Object.keys(this.featureDraftValues).forEach(featureId => {
            const drafts = this.featureDraftValues[featureId];
            if (drafts && drafts.length > 0) {
                const featureIndex = this.localFeatures.findIndex(f => f.Id === featureId);
                if (featureIndex !== -1) {
                    const feature = this.localFeatures[featureIndex];
                    
                    drafts.forEach(draft => {
                        const optionIndex = feature.options.findIndex(opt => opt.Id === draft.Id);
                        if (optionIndex !== -1) {
                            const option = feature.options[optionIndex];
                            const quantity = Number(draft.quantity);
                            
                            if (option.minQuantity != null && quantity < option.minQuantity) {
                                showToast(
                                    this,
                                    'Quantity Error',
                                    `Minimum quantity for "${option.productName}" is ${option.minQuantity}`,
                                    'warning'
                                );
                                hasValidationError = true;
                            }
                            
                            if (option.maxQuantity != null && quantity > option.maxQuantity) {
                                showToast(
                                    this,
                                    'Quantity Error',
                                    `Maximum quantity for "${option.productName}" is ${option.maxQuantity}`,
                                    'warning'
                                );
                                hasValidationError = true;
                            }
                        }
                    });
                }
            }
        });
        
        if (hasValidationError) {
            return false;
        }
        
        Object.keys(this.featureDraftValues).forEach(featureId => {
            const drafts = this.featureDraftValues[featureId];
            if (drafts && drafts.length > 0) {
                this.applyDraftValues(featureId, drafts);
            }
        });

        this.featureDraftValues = {}; 
        
        let isValid = true;
        let selectedOptions = [];

        this.localFeatures.forEach(feature => {
            const selectedCount = feature.options.filter(opt => opt.isSelected).length;
            if (selectedCount < feature.minOptions) {
                isValid = false;
                showToast(this, 'Validation Error', `Please select at least ${feature.minOptions} option(s) for ${feature.Name}`, 'error');
            }
            if (feature.maxOptions != null && selectedCount > feature.maxOptions && feature.maxOptions > 0) {
                isValid = false;
                showToast(this, 'Validation Error', `Maximum ${feature.maxOptions} option(s) allowed for ${feature.Name}`, 'error');
            }

            feature.options.filter(opt => opt.isSelected).forEach(opt => {
                selectedOptions.push(opt);
            });
        });

        if (!isValid) return false;

        try {
            this.dispatchEvent(new CustomEvent('bundlesave', {
                detail: {
                    itemKey: this.itemKey,
                    bundleId: this.bundleId,
                    selectedOptions: deepClone(selectedOptions),
                    featuresState: deepClone(this.localFeatures)
                }
            }));
        } catch (error) {
            console.error('[cpqStepBundleConfig.saveCurrentConfig] Error dispatching bundlesave event:', error);
            showToast(this, 'Save Error', 'Unable to save configuration. Please try again.', 'error');
            return false;
        }

        return true;
    }

    /**
     * Evaluates the Selection Product Rules for this bundle and applies the verdict
     * (auto select / deselect / hide / lock of options). Triggered live as the rep
     * configures, and by the "Apply Rules" button.
     */
    @api
    async evaluateRules(evaluationEvent) {
        if (!this.bundleId) {
            return;
        }
        const eventName = evaluationEvent || 'All';

        const selectedOptionIds = [];
        this.localFeatures.forEach((feature) => {
            (feature.options || []).forEach((opt) => {
                if (opt.isSelected) {
                    selectedOptionIds.push(opt.Id);
                }
            });
        });

        try {
            const verdict = await evaluateBundleRules({
                bundleProductId: this.bundleId,
                opportunityId: this.opportunityId || null,
                selectedOptionIds,
                evaluationEvent: eventName
            });
            this._applyRuleVerdict(verdict);
        } catch (error) {
            console.error('[cpqStepBundleConfig.evaluateRules] Selection rule evaluation failed:', error);
            const detail = error?.body?.message || error?.message || 'Rule evaluation failed.';
            showToast(this, 'Rules Error', detail, 'error');
        }
    }

    _scheduleRuleEvaluation() {
        clearTimeout(this._ruleEvalTimer);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this._ruleEvalTimer = setTimeout(() => {
            this.evaluateRules('Edit');
        }, 300);
    }

    _applyRuleVerdict(verdict) {
        const selectedSet = new Set(verdict.selectedOptionIds || []);
        const hiddenSet = new Set(verdict.hiddenOptionIds || []);
        const lockedSet = new Set(verdict.lockedOptionIds || []);

        this.localFeatures = this.localFeatures.map((feature) => ({
            ...feature,
            options: (feature.options || []).map((opt) => ({
                ...opt,
                isSelected: selectedSet.has(opt.Id),
                isRuleHidden: hiddenSet.has(opt.Id),
                isRuleLocked: lockedSet.has(opt.Id)
            }))
        }));
    }
}
