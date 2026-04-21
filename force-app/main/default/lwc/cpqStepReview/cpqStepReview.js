import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { formatCurrency, formatNumber, calculateSelectedProductsSubtotal, calculateSelectedProductTotal } from 'c/cpqUtils';

export default class CpqStepReview extends NavigationMixin(LightningElement) {
    @api selectedProducts = [];
    @api opportunityState = {};
    @api opportunityRecord;
    @api logisticsState = {};

    expandedRows = new Set();

    /* ═══ Opportunity Details ═══ */

    get opportunityName() {
        return this.opportunityRecord?.data?.fields?.Name?.value || '—';
    }

    get accountName() {
        return this.opportunityState?.accountName || 
               this.opportunityRecord?.data?.fields?.Account?.displayValue || '—';
    }

    get pricebookName() {
        return this.opportunityState?.pricebookName || 
               this.opportunityRecord?.data?.fields?.Pricebook2?.displayValue || 'Standard Pricebook';
    }

    get offerTypeName() {
        return this.opportunityState?.offerTypeName || 
               this.opportunityRecord?.data?.fields?.Offer_Type__r?.displayValue || '—';
    }

    /* ═══ Line Items ═══ */

    get itemCount() {
        let count = 0;
        (this.selectedProducts || []).forEach(item => {
            count += 1;
            if (item.configuredOptions) {
                count += item.configuredOptions.length;
            }
        });
        return count;
    }

    get totalLineItems() {
        let count = 0;
        (this.selectedProducts || []).forEach(item => {
            count += 1;
            if (item.configuredOptions) {
                count += item.configuredOptions.length;
            }
        });
        return count;
    }

    get flattenedLineItems() {
        const items = [];
        let lineNum = 1;
        
        (this.selectedProducts || []).forEach((product) => {
            const hasOptions = product.configuredOptions && product.configuredOptions.length > 0;
            const isExpanded = this.expandedRows.has(product._key);
            
            items.push({
                _key: `parent-${product._key}`,
                parentKey: product._key,
                lineNumber: lineNum++,
                productName: product.productName,
                productId: product.productId,
                productCode: product.productCode,
                quantity: product.quantity,
                formattedListPrice: formatCurrency(product.listUnitPrice || 0),
                formattedDiscount: product.additionalDiscount ? `${product.additionalDiscount}%` : '0%',
                formattedNetPrice: formatCurrency(product.netUnitPrice || 0),
                formattedTotal: formatCurrency(product.netTotal || 0),
                hasOptions: hasOptions,
                isOption: false,
                ariaLevel: 1,
                chevronIcon: isExpanded ? 'utility:chevrondown' : 'utility:chevronright',
                buttonVisibility: hasOptions ? '' : 'visibility: hidden;',
                paddingStyle: 'padding-left: 0;',
                rowClass: 'slds-hint-parent'
            });
            
            if (hasOptions && isExpanded) {
                product.configuredOptions.forEach((opt, optIndex) => {
                    items.push({
                        _key: `opt-${product._key}-${optIndex}`,
                        parentKey: product._key,
                        lineNumber: '',
                        productName: opt.productName,
                        productId: opt.productId || opt.Id,
                        productCode: opt.productCode,
                        quantity: opt.quantity,
                        formattedListPrice: formatCurrency(opt.unitPrice || opt.listUnitPrice || 0),
                        formattedDiscount: opt.additionalDiscount ? `${opt.additionalDiscount}%` : '0%',
                        formattedNetPrice: formatCurrency(opt.netUnitPrice || 0),
                        formattedTotal: formatCurrency(opt.netTotal || 0),
                        hasOptions: false,
                        isOption: true,
                        ariaLevel: 2,
                        chevronIcon: '',
                        buttonVisibility: 'display: none;',
                        paddingStyle: 'padding-left: 2rem;',
                        rowClass: 'slds-hint-parent option-sub-row'
                    });
                });
            }
        });
        
        return items;
    }

    get formattedSubtotal() {
        return formatCurrency(calculateSelectedProductsSubtotal(this.selectedProducts || []));
    }

    get formattedProductsSubtotal() {
        return formatCurrency(calculateSelectedProductsSubtotal(this.selectedProducts || []));
    }

    get transportTotal() {
        if (!this.logisticsState || !this.logisticsState.trips || this.logisticsState.trips.length === 0) {
            return 0;
        }
        return this.logisticsState.trips.reduce((total, trip) => {
            return total + (trip.Final_Price__c || trip.System_Price__c || 0);
        }, 0);
    }

    get formattedTransportTotal() {
        return formatCurrency(this.transportTotal);
    }

    get grandTotal() {
        // Grand Total = Products Net Total (with discount) + Transport Cost
        const productsNetTotal = calculateSelectedProductsSubtotal(this.selectedProducts || []);
        return productsNetTotal + this.transportTotal;
    }

    get formattedGrandTotal() {
        return formatCurrency(this.grandTotal);
    }

    /* ═══ Logistics ═══ */

    get isTransportRequired() {
        if (this.logisticsState && this.logisticsState.isTransportRequired !== undefined) {
            return this.logisticsState.isTransportRequired;
        }
        return this.opportunityRecord?.data?.fields?.Is_Transport_Required__c?.value || false;
    }

    get transportDisplay() {
        return this.isTransportRequired ? 'Yes' : 'No';
    }

    get deliverySiteDisplay() {
        return this.logisticsState.deliverySiteName || '—';
    }

    get agencyDisplay() {
        return this.logisticsState.agencyName || '—';
    }

    get urgencyDisplay() {
        return this.logisticsState.urgency || '—';
    }

    get hasNotes() {
        return !!(this.logisticsState.notes);
    }

    get hasTrips() {
        // Use real trips data only
        return this.logisticsState.trips && this.logisticsState.trips.length > 0;
    }

    get formattedTrips() {
        /*
        // MOCK TRIPS DATA - Uncomment for testing only
        const mockTrips = [
            {
                Id: 'trip-1',
                Truck_Type__c: 'Flatbed 20T',
                Distance_Km__c: 125,
                System_Price__c: 2500,
                Final_Price__c: 2500,
                Is_Price_Overridden__c: false,
                Override_Reason__c: null
            },
            {
                Id: 'trip-2',
                Truck_Type__c: 'Refrigerated 15T',
                Distance_Km__c: 340,
                System_Price__c: 4800,
                Final_Price__c: 5500,
                Is_Price_Overridden__c: true,
                Override_Reason__c: 'Express delivery'
            },
            {
                Id: 'trip-3',
                Truck_Type__c: 'Standard 10T',
                Distance_Km__c: 85,
                System_Price__c: 1200,
                Final_Price__c: 1200,
                Is_Price_Overridden__c: false,
                Override_Reason__c: null
            }
        ];
        // To use mock data, uncomment: const tripsToUse = mockTrips;
        */

        if (!this.logisticsState.trips) return [];
        
        return this.logisticsState.trips.map((trip, index) => ({
            ...trip,
            rowNumber: index + 1,
            formattedSystemPrice: formatCurrency(trip.System_Price__c || 0),
            formattedFinalPrice: formatCurrency(trip.Final_Price__c || trip.System_Price__c || 0),
            formattedDistance: formatNumber(trip.Distance_Km__c || 0, 0),
            isOverridden: trip.Is_Price_Overridden__c
        }));
    }

    /* ═══ Totals ═══ */

    get formattedWeight() {
        let weight = 0;
        (this.selectedProducts || []).forEach(item => {
            weight += (item.weight || 0) * (item.quantity || 1);
            (item.configuredOptions || []).forEach(opt => {
                weight += (opt.Unit_Weight_Kg__c || opt.weight || 0) * (opt.quantity || 1);
            });
        });
        return formatNumber(weight, 1);
    }

    /* ═══ Actions ═══ */

    handleProductLinkClick(event) {
        event.preventDefault();
        event.stopPropagation();
        const productId = event.currentTarget.dataset.id;
        if (!productId) return;
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: productId,
                objectApiName: 'Product2',
                actionName: 'view'
            }
        }).then(url => window.open(url, '_blank'));
    }

    handleToggleExpand(event) {
        const parentKey = event.currentTarget.dataset.id;
        if (this.expandedRows.has(parentKey)) {
            this.expandedRows.delete(parentKey);
        } else {
            this.expandedRows.add(parentKey);
        }
        this.expandedRows = new Set(this.expandedRows);
    }

    handleBack() {
        this.dispatchEvent(new CustomEvent('navigate', { detail: { direction: 'back' } }));
    }

    handleSave() {
        this.dispatchEvent(new CustomEvent('save', {
            detail: { confirmed: true }
        }));
    }
}