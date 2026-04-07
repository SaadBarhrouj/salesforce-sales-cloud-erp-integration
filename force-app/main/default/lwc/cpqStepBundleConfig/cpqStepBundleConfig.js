import { LightningElement, api, track } from 'lwc';
import { getIllustration } from 'c/cpqConstants';
import { showToast, deepClone } from 'c/cpqUtils';
// import getBundleData from '@salesforce/apex/CpqController.getBundleData';


const DATATABLE_COLUMNS = [
    {
        label: 'Qty',
        fieldName: 'quantity',
        type: 'number',
        editable: { fieldName: 'isQtyEditable' },
        typeAttributes: { step: 1, min: 0 },
        cellAttributes: { alignment: 'left' }
    },
    { label: 'Code',        fieldName: 'productCode',  type: 'text' },
    { label: 'Name',        fieldName: 'productName',  type: 'text' },
    { label: 'Description', fieldName: 'description',  type: 'text' },
    {
        label: 'Price',
        fieldName: 'unitPrice',
        type: 'currency',
        typeAttributes: { currencyCode: 'USD' },
        cellAttributes: { alignment: 'left' }
    }
];

const MOCK_FEATURES = [
    {
        Id: 'feature_memory_001',
        Name: 'Memory Cards',
        helpText: 'Veuillez sélectionner exactement une carte mémoire pour cet appareil.',
        minOptions: 1, maxOptions: 1,
        options: [
            { Id: 'opt_sd64_001', Name: 'SanDisk Ultra 64GB', productCode: 'SDU64', productName: 'SanDisk Ultra 64GB', description: 'Required 64GB storage', unitPrice: 12.00, defaultQuantity: 1, minQuantity: 1, maxQuantity: 1, quantityEditable: false, isRequired: true, isSelected: true, optionType: 'Component' },
            { Id: 'opt_sd128_001', Name: 'SanDisk Ultra 128GB', productCode: 'SD128', productName: 'SanDisk Ultra 128GB', description: 'Upgrade 128GB storage', unitPrice: 15.00, defaultQuantity: 0, minQuantity: 0, maxQuantity: 1, quantityEditable: true, isRequired: false, isSelected: false, optionType: 'Component' }
        ]
    },
    {
        Id: 'feature_headphones_001',
        Name: 'Headphones',
        helpText: 'Vous pouvez sélectionner plusieurs casques ou écouteurs facultatifs.',
        minOptions: 1, maxOptions: 2,
        options: [
            { Id: 'opt_hb01_001', Name: 'Basic Headset', productCode: 'HB01', productName: 'Basic Headset', description: 'Standard wired', unitPrice: 25.00, defaultQuantity: 0, minQuantity: 0, maxQuantity: 2, quantityEditable: true, isRequired: false, isSelected: false, optionType: 'Accessory' },
            { Id: 'opt_hb02_001', Name: 'Premium Headset', productCode: 'HB02', productName: 'Premium Headset', description: 'Wireless', unitPrice: 45.00, defaultQuantity: 0, minQuantity: 0, maxQuantity: 3, quantityEditable: true, isRequired: false, isSelected: true, optionType: 'Accessory' }
        ]
    },
    {
        Id: 'feature_mobilecards_001',
        Name: 'Mobile Cards',
        helpText: 'Option de connectivité requise. Le standard est inclus par défaut.',
        minOptions: 1, maxOptions: 1,
        options: [
            { Id: 'opt_mc01_001', Name: 'Mobile Card Standard', productCode: 'MC01', productName: 'Mobile Card Standard', description: 'Required SIM card', unitPrice: 10.00, defaultQuantity: 1, minQuantity: 1, maxQuantity: 1, quantityEditable: false, isRequired: true, isSelected: true, optionType: 'Component' },
            { Id: 'opt_mc02_001', Name: 'Mobile Card High-speed', productCode: 'MC02', productName: 'Mobile Card High-speed', description: '5G upgrade option', unitPrice: 18.00, defaultQuantity: 0, minQuantity: 0, maxQuantity: 1, quantityEditable: true, isRequired: false, isSelected: false, optionType: 'Related Product' }
        ]
    }
];


export default class cpqStepBundleConfig extends LightningElement {


    @api bundleId;
    @api bundleName = 'Apple iPhone X Package';


    @track isLoading   = true;
    @track viewMode    = 'sections';
    @track draftValues = [];
    @track localFeatures = [];


    connectedCallback() {
        this.loadConfiguration();
    }

    async loadConfiguration() {
        this.isLoading = true;

        try {
            if (this.bundleId) {
                /*
                // 1. APPEL APEX RÉEL (À décommenter plus tard)
                const result = await getBundleData({ bundleId: this.bundleId });
                // On suppose que l'Apex renvoie un objet avec les features
                this.localFeatures = deepClone(result.features);
                this.bundleName = result.bundleName || this.bundleName;
                */
            } else {
                // 2. MOCK DATA (Fallback si pas de bundleId pour les tests)
                // On simule un délai réseau de 500ms pour voir le spinner
                await new Promise(resolve => setTimeout(resolve, 500));
                this.localFeatures = deepClone(MOCK_FEATURES);
            }
        } catch (error) {
            console.error('Erreur lors du chargement des données :', error);
            showToast(this, 'Erreur de chargement', 'Impossible de charger la configuration du Bundle.', 'error');
        } finally {
            this.isLoading = false;
        }
    }


    get columns()               { return DATATABLE_COLUMNS; }
    get isSectionsView()        { return this.viewMode === 'sections'; }
    get isTabsView()            { return this.viewMode === 'tabs'; }
    get sectionsButtonVariant() { return this.isSectionsView ? 'brand' : 'neutral'; }
    get tabsButtonVariant()     { return this.isTabsView    ? 'brand' : 'neutral'; }
    get hasFeatures()           { return (this.processedFeatures || []).length > 0; }
    get hasNoFeatures()         { return !this.isLoading && !this.hasFeatures; }
    get emptyStateIllustration(){ return getIllustration('NORESULTS_SEARCH').name; }

    get processedFeatures() {
        return this.localFeatures.map(feature => {
            const options = feature.options || [];
            const min = feature.minOptions || 0;
            const max = feature.maxOptions || 999;

            const selectedIds = options.filter(opt => opt.isSelected).map(opt => opt.Id);
            const requiredIds = options.filter(opt => opt.isRequired).map(opt => opt.Id);

            let disabledIds = [];
            if (requiredIds.length >= max && max > 0) {
                disabledIds = options.map(opt => opt.Id);
            } else {
                disabledIds = requiredIds;
            }

            return {
                Id:           feature.Id,
                Name:         feature.Name,
                helpText:     feature.helpText,
                minOptions:   min,
                maxOptions:   max,
                badgeClass:   'slds-badge',
                options:      this.processOptions(options),
                selectedRows: selectedIds,
                disabledRows: disabledIds
            };
        });
    }


    processOptions(options) {
        return (options || []).map(option => ({
            Id:            option.Id,
            quantity:      option.defaultQuantity ?? option.minQuantity ?? 0,
            minQuantity:   option.minQuantity || 0,
            maxQuantity:   option.maxQuantity || 999,
            productCode:   option.productCode || '',
            productName:   option.productName || option.Name || '',
            description:   option.description || '',
            unitPrice:     option.unitPrice || 0,
            isQtyEditable: option.quantityEditable !== false,
            isRequired:    option.isRequired,
            isSelected:    option.isSelected
        }));
    }



    handleFeatureSelection(event) {
        const featureId = event.target.dataset.featureId;
        const selectedRows = event.detail.selectedRows;

        const featureIndex = this.localFeatures.findIndex(f => f.Id === featureId);
        const feature = this.localFeatures[featureIndex];

        if (selectedRows.length < feature.minOptions) {
            showToast(
              this,
              'Action impossible',
              `Vous devez sélectionner au moins ${feature.minOptions} option(s) pour "${feature.Name}".`,
              'warning'
            );
            this.localFeatures = [...this.localFeatures];
            return;
        }

        const selectedIds = selectedRows.map(row => row.Id);

        this.localFeatures[featureIndex].options = feature.options.map(opt => ({
            ...opt,
            isSelected: selectedIds.includes(opt.Id)
        }));

        this.localFeatures = [...this.localFeatures];
    }

    switchToSections() {
        this.viewMode = 'sections';
    }

    switchToTabs() {
        this.viewMode = 'tabs';
    }

    handleSaveTable(event) {
        this.draftValues = event.detail.draftValues;
        showToast(this, 'Succès', 'Les quantités ont été mises à jour', 'success');
    }
}