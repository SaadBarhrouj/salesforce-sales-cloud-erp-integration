import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
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

/* MOCK DATA - Used only when bundleId is not provided or Apex is unavailable */
const MOCK_FEATURES = [
    {
        Id: 'feature_001',
        Name: 'Feature 1',
        helpText: 'Please select exactly one option for this feature.',
        minOptions: 1,
        maxOptions: 1,
        options: [
            { Id: 'opt_001', Name: 'Option 1A', productCode: 'OPT001A', productName: 'Option 1A', description: 'First option', unitPrice: 10.0, defaultQuantity: 1, minQuantity: 1, maxQuantity: 1, quantityEditable: false, isRequired: true, isSelected: true, optionType: 'Component' },
            { Id: 'opt_002', Name: 'Option 1B', productCode: 'OPT001B', productName: 'Option 1B', description: 'Second option', unitPrice: 15.0, defaultQuantity: 0, minQuantity: 0, maxQuantity: 1, quantityEditable: true, isRequired: false, isSelected: false, optionType: 'Component' }
        ]
    },
    {
        Id: 'feature_002',
        Name: 'Feature 2',
        helpText: 'You can select multiple options from this feature.',
        minOptions: 0,
        maxOptions: 3,
        options: [
            { Id: 'opt_003', Name: 'Option 2A', productCode: 'OPT002A', productName: 'Option 2A', description: 'Optional item', unitPrice: 20.0, defaultQuantity: 0, minQuantity: 0, maxQuantity: 2, quantityEditable: true, isRequired: false, isSelected: false, optionType: 'Accessory' },
            { Id: 'opt_004', Name: 'Option 2B', productCode: 'OPT002B', productName: 'Option 2B', description: 'Additional item', unitPrice: 25.0, defaultQuantity: 0, minQuantity: 0, maxQuantity: 3, quantityEditable: true, isRequired: false, isSelected: false, optionType: 'Accessory' }
        ]
    }
];

export default class cpqStepBundleConfig extends LightningElement {
    @api bundleId;

    @track isLoading = true;
    @track draftValues = [];
    @track localFeatures = [];
    @track bundleName = '';
    @track viewMode = 'sections';

    @wire(getRecord, { recordId: '$bundleId', fields: [PRODUCT_NAME_FIELD] })
    bundleRecord;

    connectedCallback() {
        this.loadConfiguration();
    }

    async loadConfiguration() {
        this.isLoading = true;

        try {
            if (this.bundleId) {
                // Fetch features via Apex
                const result = await getBundleData({ bundleId: this.bundleId });
                this.localFeatures = deepClone((result && result.features) || []);
                
                // Fetch bundle name from LDS wire (automatic via @wire decorator)
                if (this.bundleRecord?.data?.fields?.Name?.value) {
                    this.bundleName = this.bundleRecord.data.fields.Name.value;
                } else {
                    // Fallback to generic name if LDS data not available
                    this.bundleName = 'Bundle Configuration';
                }
            } else {
                await this.loadMockConfiguration();
            }
        } catch (error) {
            console.error('Erreur lors du chargement des donnees Bundle:', error);
            showToast(this, 'Erreur de chargement', 'Chargement Apex indisponible, affichage du mode mock.', 'warning');
            await this.loadMockConfiguration();
        } finally {
            this.isLoading = false;
        }
    }

    async loadMockConfiguration() {
        await new Promise((resolve) => setTimeout(resolve, 300));
        this.localFeatures = deepClone(MOCK_FEATURES);
        this.bundleName = 'Bundle Configuration';
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

    get hasNoFeatures() {
        return !this.isLoading && !this.hasFeatures;
    }

    get emptyStateIllustration() {
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
            quantity: option.defaultQuantity ?? option.minQuantity ?? 0,
            minQuantity: option.minQuantity || 0,
            maxQuantity: option.maxQuantity || 999,
            productCode: option.productCode || '',
            productName: option.productName || option.Name || '',
            description: option.description || '',
            unitPrice: option.unitPrice || 0,
            isQtyEditable: option.quantityEditable !== false,
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
                'Action impossible',
                `Vous devez selectionner au moins ${feature.minOptions} option(s) pour "${feature.Name}".`,
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
        showToast(this, 'Succes', 'Les quantites ont ete mises a jour', 'success');
    }
}
