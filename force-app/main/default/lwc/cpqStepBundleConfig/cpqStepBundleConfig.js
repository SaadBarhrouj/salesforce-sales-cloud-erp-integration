import { LightningElement, api, track } from 'lwc';
import { getIllustration } from 'c/cpqConstants';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// ═══════════════════════════════════════════════════════════════════════════════
// CONSTANTS
// ═══════════════════════════════════════════════════════════════════════════════



const DATATABLE_COLUMNS = [
    {
        label: 'Qty',
        fieldName: 'quantity',
        type: 'number',
        editable: { fieldName: 'isQtyEditable' },
        typeAttributes: { step: 1, min: 0 },
        cellAttributes: {
            class: { fieldName: 'rowClass' },
            alignment: 'left'
        }
    },
    { label: 'Code',        fieldName: 'productCode',  type: 'text' },
    { label: 'Name',        fieldName: 'productName',  type: 'text' },
    { label: 'Description', fieldName: 'description',  type: 'text' },
    {
        label: 'Price',
        fieldName: 'unitPrice',
        type: 'currency',
        typeAttributes: { currencyCode: 'USD' }
    }
];

// ═══════════════════════════════════════════════════════════════════════════════

export default class cpqStepBundleConfig extends LightningElement {

    // ─────────────────────────────────────────────────────────────────────────
    // PUBLIC PROPERTIES (@api)
    // ─────────────────────────────────────────────────────────────────────────

    @api bundleName = 'Apple iPhone X Package';

    @api features = [
        // FEATURE 1 : Memory Cards (Min=1, Max=1 → RADIO)
        {
            Id: 'feature_memory_001',
            Name: 'Memory Cards',
            helpText: 'Veuillez sélectionner exactement une carte mémoire pour cet appareil.',
            minOptions: 1,
            maxOptions: 1,
            options: [
                {
                    Id: 'opt_sd64_001',
                    Name: 'SanDisk Ultra 64GB',
                    defaultQuantity:4,
                    minQuantity: 1,
                    maxQuantity: 1,
                    quantityEditable: false,
                    isRequired: true,
                    isSelected: true,
                    optionType: 'Component'
                },
                {
                    Id: 'opt_sd128_001',
                    Name: 'SanDisk Ultra 128GB',
                    defaultQuantity: 0,
                    minQuantity: 0,
                    maxQuantity: 1,
                    quantityEditable: true,
                    isRequired: false,
                    isSelected: false,
                    optionType: 'Component'
                }
            ]
        },

        // FEATURE 2 : Headphones (Min=0, Max=99 → MULTIPLE)
        {
            Id: 'feature_headphones_001',
            Name: 'Headphones',
            helpText: 'Vous pouvez sélectionner plusieurs casques ou écouteurs facultatifs.',
            minOptions: 0,
            maxOptions: 99,
            options: [
                {
                    Id: 'opt_hb01_001',
                    Name: 'Basic Headset',
                    productCode : 'CODE1',
                    defaultQuantity: 0,
                    minQuantity: 0,
                    maxQuantity: 5,
                    quantityEditable: true,
                    isRequired: false,
                    isSelected: false,
                    optionType: 'Accessory',
                },
                {
                    Id: 'opt_hb02_001',
                    Name: 'Premium Headset',
                    defaultQuantity: 0,
                    minQuantity: 0,
                    maxQuantity: 3,
                    quantityEditable: true,
                    isRequired: false,
                    isSelected: true,
                    optionType: 'Accessory',
                }
            ]
        },

        // FEATURE 3 : Mobile Cards (Min=1, Max=1 → RADIO + 1 fixe)
        {
            Id: 'feature_mobilecards_001',
            Name: 'Mobile Cards',
            helpText: 'Option de connectivité requise. Le standard est inclus par défaut.',
            minOptions: 1,
            maxOptions: 1,
            options: [
                {
                    Id: 'opt_mc01_001',
                    Name: 'Mobile Card Standard',
                    defaultQuantity: 1,
                    minQuantity: 1,
                    maxQuantity: 1,
                    quantityEditable: false,
                    isRequired: true,
                    isSelected: true,
                    optionType: 'Component',
                },
                {
                    Id: 'opt_mc02_001',
                    Name: 'Mobile Card High-speed',
                    defaultQuantity: 0,
                    minQuantity: 0,
                    maxQuantity: 1,
                    quantityEditable: true,
                    isRequired: false,
                    isSelected: false,
                    optionType: 'Related Product',
                }
            ]
        }
    ];

    // ─────────────────────────────────────────────────────────────────────────
    // TRACKED (REACTIVE) STATE
    // ─────────────────────────────────────────────────────────────────────────

    @track isLoading  = false;
    @track draftValues = [];
    @track viewMode   = 'sections';   // 'sections' | 'tabs'

    // ─────────────────────────────────────────────────────────────────────────
    // GETTERS — VIEW STATE
    // ─────────────────────────────────────────────────────────────────────────

    get columns()              { return DATATABLE_COLUMNS; }
    get isSectionsView()       { return this.viewMode === 'sections'; }
    get isTabsView()           { return this.viewMode === 'tabs'; }
    get sectionsButtonVariant(){ return this.isSectionsView ? 'brand' : 'neutral'; }
    get tabsButtonVariant()    { return this.isTabsView    ? 'brand' : 'neutral'; }

    // ─────────────────────────────────────────────────────────────────────────
    // GETTERS — FEATURES
    // ─────────────────────────────────────────────────────────────────────────

    get hasFeatures()          { return (this.processedFeatures || []).length > 0; }
    get hasNoFeatures()        { return !this.hasFeatures; }
    get emptyStateIllustration(){ return getIllustration('NORESULTS_SEARCH').name; }

    get processedFeatures() {
        return this.features.map(feature => {
            const options = feature.options || [];
            const min = feature.minOptions || 0;
            const max = feature.maxOptions || 999;

            return {
                Id:           feature.Id,
                Name:         feature.Name,
                helpText:     feature.helpText,
                minOptions:   min,
                maxOptions:   max,
                maxSelection: max,
                badgeClass:   'slds-badge',
                options:      this.processOptions(options),
                selectedRows: options.filter(opt => opt.isSelected).map(opt => opt.Id),
                disabledRows: options.filter(opt => opt.isRequired).map(opt => opt.Id)
            };
        });
    }

    // ─────────────────────────────────────────────────────────────────────────
    // HELPER METHODS
    // ─────────────────────────────────────────────────────────────────────────

    processOptions(options) {
        return (options || []).map(option => ({
            Id:           option.Id,
            quantity:     option.defaultQuantity ?? option.minQuantity ?? 0,
            minQuantity:  option.minQuantity || 0,
            maxQuantity:  option.maxQuantity || 999,
            productCode:  option.optionProduct?.ProductCode || option.productCode || '',
            productName:  option.optionProduct?.Name || option.Name,
            description:  option.optionProduct?.Description || '',
            unitPrice:    option.optionProduct?.UnitPrice || 0,
            isQtyEditable: option.quantityEditable !== false,
            isRequired:   option.isRequired,
            isSelected:   option.isSelected,
            rowClass: {
                isDisabled: !option.quantityEditable || option.isRequired
            }
        }));
    }


    // ─────────────────────────────────────────────────────────────────────────
    // EVENT HANDLERS
    // ─────────────────────────────────────────────────────────────────────────

    switchToSections() {
        this.viewMode = 'sections';
    }

    switchToTabs() {
        this.viewMode = 'tabs';
    }

    handleSaveTable(event) {
        this.draftValues = event.detail.draftValues;
        this.dispatchEvent(new ShowToastEvent({
            title:   'Success',
            message: 'Quantities updated',
            variant: 'success'
        }));
    }

    handleFeatureSelection(event) {
        // Identify the feature via the closest dataset attribute
        const featureId =
          event.target.closest('section')?.dataset?.featureId ||
          event.target.closest('lightning-tab')?.dataset?.featureId;

        const selectedRows = event.detail.selectedRows;
        const datatable    = event.target;

        // Find the feature in the tracked array
        const featureIndex = this.features.findIndex(f => f.Id === featureId);
        if (featureIndex === -1) return;

        const feat = this.features[featureIndex];

        // 1. Prevent de-selection of required options
        const requiredRowIds   = feat.options.filter(opt => opt.isRequired).map(opt => opt.Id);
        const missingRequired  = requiredRowIds.filter(reqId => !selectedRows.some(row => row.Id === reqId));

        if (missingRequired.length > 0) {
            const currentSelectedIds = selectedRows.map(row => row.Id);
            const correctedIds       = [...new Set([...currentSelectedIds, ...requiredRowIds])];

            datatable.selectedRows = correctedIds;

            this.dispatchEvent(new ShowToastEvent({
                title:   'Info',
                message: 'Certaines options sont obligatoires et ne peuvent pas être désélectionnées.',
                variant: 'info'
            }));
            return;
        }

        // 2. Update reactive state so processedFeatures recomputes (badge refresh)
        const selectedRowIds  = selectedRows.map(r => r.Id);
        const updatedOptions  = feat.options.map(opt => ({
            ...opt,
            isSelected: selectedRowIds.includes(opt.Id)
        }));

        this.features = [
            ...this.features.slice(0, featureIndex),
            { ...feat, options: updatedOptions },
            ...this.features.slice(featureIndex + 1)
        ];

        console.log('Feature selection updated:', featureId, '| selected count:', selectedRows.length);
    }
}