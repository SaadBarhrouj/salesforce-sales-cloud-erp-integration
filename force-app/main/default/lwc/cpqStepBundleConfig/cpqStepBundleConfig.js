import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getIllustration } from 'c/cpqConstants';
import { showToast, deepClone } from 'c/cpqUtils';
import getBundleData from '@salesforce/apex/BundleOptionController.getBundleData';
import PRODUCT_NAME_FIELD from '@salesforce/schema/Product2.Name';

const DATATABLE_COLUMNS = [
    {
        label: 'Qty',
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
    _bundleId;

    @api
    get bundleId() {
        return this._bundleId;
    }
    set bundleId(value) {
        const hasChanged = value !== this._bundleId;
        this._bundleId = value;
        if (hasChanged && value) {
            this.loadConfiguration();
        }
    }

    @track isLoading = false;
    @track featureDraftValues = {};
    @track localFeatures = [];
    @track bundleName = '';
    @track viewMode = 'sections';

    @wire(getRecord, { recordId: '$_bundleId', fields: [PRODUCT_NAME_FIELD] })
    bundleRecord;

    async loadConfiguration() {
        this.isLoading = true;

        try {
            if (!this.bundleId) {
                throw new Error('Bundle ID is required');
            }

            // Fetch features via Apex
            const result = await getBundleData({ bundleId: this.bundleId });
            this.localFeatures = deepClone((result && result.features) || []);
            
            // Fetch bundle name from LDS wire (automatic via @wire decorator)
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
            quantity: option.defaultQuantity,
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
                        // Update defaultQuantity which drives the UI default quantity
                        options[optionIndex] = { ...options[optionIndex], defaultQuantity: Number(draft.quantity) };
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
        
        this.applyDraftValues(featureId, drafts);
        
        this.featureDraftValues = { ...this.featureDraftValues, [featureId]: [] };
    }

    @api
    saveCurrentConfig() {
        Object.keys(this.featureDraftValues).forEach(featureId => {
            const drafts = this.featureDraftValues[featureId];
            if (drafts && drafts.length > 0) {
                this.applyDraftValues(featureId, drafts);
            }
        });

        this.featureDraftValues = {}; 
        
        // Validation Min/Max rules
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

        this.dispatchEvent(new CustomEvent('bundlesave', {
            detail: {
                bundleId: this.bundleId,
                selectedOptions: selectedOptions,
                featuresState: this.localFeatures
            }
        }));

        return true;
    }
}