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
    {
        label: 'Price',
        fieldName: 'unitPrice',
        type: 'currency',
        typeAttributes: { currencyCode: 'USD' },
        cellAttributes: { alignment: 'left' }
    }
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
    @track draftValues = [];
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
        return (this.processedFeatures || []).length > 0;
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
            const min = feature.minOptions || 0;
            const max = feature.maxOptions || 999;

            const selectedIds = options.filter((opt) => opt.isSelected).map((opt) => opt.Id);
            const requiredIds = options.filter((opt) => opt.isRequired).map((opt) => opt.Id);

            let disabledIds = [];
            if (requiredIds.length >= max && max > 0) {
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
                badgeClass: 'slds-badge',
                options: this.processOptions(options),
                selectedRows: selectedIds,
                disabledRows: disabledIds
            };
        });
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

    handleSaveTable(event) {
        this.draftValues = event.detail.draftValues;
        showToast(this, 'Success', 'Quantities have been updated', 'success');
    }
}