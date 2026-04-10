import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getIllustration } from 'c/cpqConstants';
import { showToast, deepClone, formatMessage } from 'c/cpqUtils';
import getBundleData from '@salesforce/apex/BundleOptionController.getBundleData';
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
    { label: 'Name', fieldName: 'productName', type: 'text' },
    { label: 'Description', fieldName: 'description', type: 'text' },
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

    _loadTimer;
    scheduleLoad() {
        if (!this._bundleId || !this._itemKey) return;
        clearTimeout(this._loadTimer);
        this._loadTimer = setTimeout(() => {
            this.loadConfiguration();
        }, 0);
    }

    @track isLoading = false;
    @track featureDraftValues = {};
    @track localFeatures = [];
    @track bundleName = '';
    @track viewMode = 'sections';

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

    get emptyStateTitle() {
        if (this.noBundleSelected) {
            return 'No Bundle Selected';
        }
        return 'No Configuration Options';
    }

    get emptyStateDescription() {
        if (this.noBundleSelected) {
            return 'Select a bundle above to configure its features and options.';
        }
        return 'This bundle has no configurable features.';
    }

    get emptyStateIllustration() {
        if (this.noBundleSelected) {
            return getIllustration('CART_NO_ITEMS').name;
        }
        return getIllustration('NORESULTS_SEARCH').name;
    }

    get processedFeatures() {
        return this.localFeatures.map((feature) => {
            const options = feature.options || [];
            const min = feature.minOptions;
            const max = feature.maxOptions;

            const selectedIds = options.filter((opt) => opt.isSelected).map((opt) => opt.Id);
            const requiredIds = options.filter((opt) => opt.isRequired).map((opt) => opt.Id);

            let disabledIds = [];
            if (max != null && requiredIds.length >= max && max > 0) {
                disabledIds = options.map((opt) => opt.Id);
            } else {
                disabledIds = requiredIds;
            }

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
                disabledRows: disabledIds,
                draftValues: this.featureDraftValues[feature.Id] || []
            };
        });
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
        return (options || []).map((option) => ({
            Id: option.Id,
            quantity: option.quantity !== undefined ? option.quantity : option.defaultQuantity,
            minQuantity: option.minQuantity,
            maxQuantity: option.maxQuantity,
            productCode: option.productCode,
            productName: option.productName,
            description: option.description,
            unitPrice: option.unitPrice,
            isQtyEditable: option.quantityEditable,
            isRequired: option.isRequired,
            isSelected: option.isSelected
        }));
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
    }

    @api
    switchToSections() {
        this.viewMode = 'sections';
    }

    @api
    switchToTabs() {
        this.viewMode = 'tabs';
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
}