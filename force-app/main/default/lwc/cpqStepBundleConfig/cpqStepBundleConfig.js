import { LightningElement, api, track } from 'lwc';
import { getIllustration } from 'c/cpqConstants';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class cpqStepBundleConfig extends LightningElement {
    @api bundleName = 'Apple iPhone X Package';

    @track isLoading = false;
    @track draftValues = [];
    @track viewMode = 'sections';
    @api features = [
        // FEATURE 1 : Memory Cards (Min=1, Max=1 → RADIO)
        {
            Id: 'feature_memory_001',
            Name: 'Memory Cards',
            Min_Options: 1,
            Max_Options: 1,
            Sort_Order: 1,
            options: [
                {
                    Id: 'opt_sd64_001',
                    Name: 'SanDisk Ultra 64GB',
                    Default_Quantity: 1,
                    Min_Quantity__c: 1,
                    Max_Quantity__c: 1,
                    Quantity_Editable__c: false,
                    Is_Required__c: true,
                    Is_Selected__c: true,
                    Option_Type__c: 'Component',
                    Option_Product__c: {
                        Id: 'prod_sd64',
                        ProductCode: 'SDU64',
                        Name: 'SanDisk Ultra 64GB',
                        Description: 'Required 64GB storage',
                        UnitPrice: 12.00
                    }
                },
                {
                    Id: 'opt_sd128_001',
                    Name: 'SanDisk Ultra 128GB',
                    Default_Quantity__c: 0,
                    Min_Quantity__c: 0,
                    Max_Quantity__c: 1,
                    Quantity_Editable__c: true,   // ✅ Qty modifiable
                    Is_Required__c: false,
                    Is_Selected__c: false,
                    Option_Type__c: 'Component',
                    Option_Product__c: {
                        Id: 'prod_sd128',
                        ProductCode: 'SD128',
                        Name: 'SanDisk Ultra 128GB',
                        Description: 'Upgrade 128GB storage',
                        UnitPrice: 15.00
                    }
                }
            ]
        },

        // FEATURE 2 : Headphones (Min=0, Max=99 → MULTIPLE)
        {
            Id: 'feature_headphones_001',
            Name: 'Headphones',
            Min_Options__c: 0,
            Max_Options__c: 99,
            Sort_Order__c: 2,
            options: [
                {
                    Id: 'opt_hb01_001',
                    Name: 'Basic Headset',
                    Default_Quantity__c: 0,
                    Min_Quantity__c: 0,
                    Max_Quantity__c: 5,
                    Quantity_Editable__c: true,
                    Is_Required__c: false,
                    Is_Selected__c: false,
                    Option_Type__c: 'Accessory',
                    Option_Product__c: {
                        Id: 'prod_hb01',
                        ProductCode: 'HB01',
                        Name: 'Basic Headset',
                        Description: 'Standard wired headphones',
                        UnitPrice: 25.00
                    }
                },
                {
                    Id: 'opt_hb02_001',
                    Name: 'Premium Headset',
                    Default_Quantity__c: 0,
                    Min_Quantity__c: 0,
                    Max_Quantity__c: 3,
                    Quantity_Editable__c: true,
                    Is_Required__c: false,
                    Is_Selected__c: true,
                    Option_Type__c: 'Accessory',
                    Option_Product__c: {
                        Id: 'prod_hb02',
                        ProductCode: 'HB02',
                        Name: 'Premium Headset',
                        Description: 'Wireless over-ear',
                        UnitPrice: 45.00
                    }
                }
            ]
        },

        // FEATURE 3 : Mobile Cards (Min=1, Max=1 → RADIO + 1 fixe)
        {
            Id: 'feature_mobilecards_001',
            Name: 'Mobile Cards',
            Min_Options__c: 1,
            Max_Options__c: 1,
            Sort_Order__c: 3,
            options: [
                {
                    Id: 'opt_mc01_001',
                    Name: 'Mobile Card Standard',
                    Default_Quantity__c: 1,
                    Min_Quantity__c: 1,
                    Max_Quantity__c: 1,
                    Quantity_Editable__c: false,  // ❌ Qty bloqué + fixe
                    Is_Required__c: true,
                    Is_Selected__c: true,
                    Option_Type__c: 'Component',
                    Option_Product__c: {
                        Id: 'prod_mc01',
                        ProductCode: 'MC01',
                        Name: 'Mobile Card Standard',
                        Description: 'Required SIM card',
                        UnitPrice: 10.00
                    }
                },
                {
                    Id: 'opt_mc02_001',
                    Name: 'Mobile Card High-speed',
                    Default_Quantity__c: 0,
                    Min_Quantity__c: 0,
                    Max_Quantity__c: 1,
                    Quantity_Editable__c: true,
                    Is_Required__c: false,
                    Is_Selected__c: false,
                    Option_Type__c: 'Related Product',
                    Option_Product__c: {
                        Id: 'prod_mc02',
                        ProductCode: 'MC02',
                        Name: 'Mobile Card High-speed',
                        Description: '5G upgrade option',
                        UnitPrice: 18.00
                    }
                }
            ]
        }
    ];

    get processedFeatures() {
        return this.features.map(feature => ({
            Id: feature.Id,
            Name: feature.Name,
            Min_Options__c: feature.Min_Options__c || 0,
            Max_Options__c: feature.Max_Options__c || 999,
            maxSelection: feature.Max_Options__c === 1 ? 1 : undefined,
            options: this.processOptions(feature.options || []),
            selectedRows: this.getSelectedRows(feature.options || [])
        }));
    }

    processOptions(options) {
        return (options || []).map(option => ({
            Id: option.Id,
            quantity: option.Default_Quantity__c || option.Min_Quantity__c || 0,
            productCode: option.Option_Product__c?.ProductCode || '',
            productName: option.Option_Product__c?.Name || option.Name,
            description: option.Option_Product__c?.Description || '',
            unitPrice: option.Option_Product__c?.UnitPrice || 0,
            isQtyEditable: option.Quantity_Editable__c !== false,
            isRequired: option.Is_Required__c,
            isSelected: option.Is_Selected__c,
            rowClass: {
                isDisabled: !option.Quantity_Editable__c || option.Is_Required__c
            }
        }));
    }

    getSelectedRows(options) {
        return (options || []).filter(opt => opt.Is_Selected__c).map(opt => ({
            Id: opt.Id,
            quantity: opt.Default_Quantity__c || 0
        }));
    }

    columns = [
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
        { label: 'Code', fieldName: 'productCode', type: 'text' },
        { label: 'Name', fieldName: 'productName', type: 'text' },
        { label: 'Description', fieldName: 'description', type: 'text' },
        { label: 'Price', fieldName: 'unitPrice', type: 'currency', typeAttributes: { currencyCode: 'USD' } }
    ];

    get sectionsButtonVariant() {
        return this.isSectionsView ? 'brand' : 'neutral';
    }
    get tabsButtonVariant() {
        return this.isTabsView ? 'brand' : 'neutral';
    }

    get toggleLabel() {
        return this.isSectionsView ? 'Switch to Tabs' : 'Switch to Sections';
    }
    get isSectionsView() { return this.viewMode === 'sections'; }
    get isTabsView() { return this.viewMode === 'tabs'; }

    get hasFeatures() { return (this.processedFeatures || []).length > 0; }
    get hasNoFeatures() { return !this.hasFeatures; }
    get emptyStateIllustration() { return getIllustration('NORESULTS_SEARCH').name; }

    get formattedTotal() {
        let total = 0;
        this.processedFeatures.forEach(feature => {
            feature.options.forEach(row => {
                total += (row.quantity || 0) * (row.unitPrice || 0);
            });
        });
        return total.toFixed(2);
    }

    switchToSections() {
        this.viewMode = 'sections';
    }

    switchToTabs() {
        this.viewMode = 'tabs';
    }

    handleSaveTable(event) {
        this.draftValues = event.detail.draftValues;
        this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
            message: 'Quantities updated',
            variant: 'success'
        }));
    }

    handleFeatureSelection(event) {
        const featureId = event.target.closest('lightning-tab')?.dataset?.featureId ||
          event.target.closest('section')?.dataset?.featureId;
        console.log('Feature selected:', featureId, event.detail.selectedRows);
    }
}