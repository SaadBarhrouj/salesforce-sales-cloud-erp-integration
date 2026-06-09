import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { deepClone, showToast } from 'c/cpqUtils';
import { URGENCY_OPTIONS, DIRECTION_MODE_OPTIONS, DIRECTION_MODE, ILLUSTRATIONS } from 'c/cpqConstants';
import getLocationsByAccount from '@salesforce/apex/LocationController.getLocationsByAccount';
import getAllAgencies from '@salesforce/apex/LocationController.getAllAgencies';
import calculateTripsWithCPQItems from '@salesforce/apex/TripController.calculateTripsWithCPQItems';
import getTripsByOpportunity from '@salesforce/apex/TripController.getTripsByOpportunity';
import getRouteDistance from '@salesforce/apex/TripController.getRouteDistance';
import LOCATION_NAME from '@salesforce/schema/Location.Name';
import LOCATION_TYPE from '@salesforce/schema/Location.LocationType';
import LOCATION_LAT from '@salesforce/schema/Location.Latitude';
import LOCATION_LNG from '@salesforce/schema/Location.Longitude';
import OPP_OFFER_TYPE_NAME from '@salesforce/schema/Opportunity.Offer_Type__r.Name';
import OPP_TRIP_DIRECTION_MODE from '@salesforce/schema/Opportunity.Trip_Direction_Mode__c';
import RENTAL_CATALOG_NAMES from '@salesforce/label/c.Rental_Catalog_Names';

const LOCATION_FIELDS = [LOCATION_NAME, LOCATION_TYPE, LOCATION_LAT, LOCATION_LNG];
const OPPORTUNITY_FIELDS = [OPP_OFFER_TYPE_NAME, OPP_TRIP_DIRECTION_MODE];
const RENTAL_CATALOG_SET = new Set(
    (RENTAL_CATALOG_NAMES || '').split(',').map(s => s.trim().toLowerCase()).filter(Boolean)
);

const TRIP_COLUMNS = [
    { label: 'Direction', fieldName: 'Direction__c', type: 'text', sortable: true },
    { label: 'Truck Type', fieldName: 'Truck_Type__c', type: 'text', sortable: true },
    { label: 'Total Weight', fieldName: 'Total_Weight_Kg__c', type: 'number', sortable: true },
    { label: 'System Price', fieldName: 'System_Price__c', type: 'currency', sortable: true },
    { label: 'Final Price', fieldName: 'Final_Price__c', type: 'currency', editable: true, typeAttributes: { step: '0.01' } },
    { label: 'Override Reason', fieldName: 'Override_Reason__c', type: 'text', editable: true },
];

export default class CpqStepLogistics extends LightningElement {
    // ==================== API PROPERTIES ====================
    
    _opportunityId;

    @api
    get opportunityId() {
        return this._opportunityId;
    }
    
    set opportunityId(value) {
        console.log('setter opportunityId called with:', value);
        this._opportunityId = value;
        if (value) {
            this.loadExistingTrips();
        }
    }

    @api accountId;
    @api selectedProducts = [];  
    @api totalWeight = 0;
    @api defaultAgencyId = '';
    @api defaultDeliverySiteId = '';
    @api defaultUrgency = 'Standard';
    
    // ==================== WIRED DATA ====================
    
    @wire(getLocationsByAccount, { accountId: '$accountId' })
    wiredAccountLocations({ data, error }) {
        if (data) {
            // Merge with potentially existing default site
            let merged = [...data];
            const existingDefault = this.accountLocations.find(l => l.value === this.defaultDeliverySiteId);
            if (existingDefault && !merged.find(l => l.value === this.defaultDeliverySiteId)) {
                merged.push(existingDefault);
            }
            this.accountLocations = merged;
            
            // Re-apply default config if needed
            if (this.defaultDeliverySiteId && !this.config.deliverySiteId) {
                this.config = { ...this.config, deliverySiteId: this.defaultDeliverySiteId };
            }
            
            // Emit state to update valid route status in parent
            this.emitState();
        } else if (error) {
            console.error('Error loading account locations:', error);
            this.accountLocations = [];
        }
    }
    
    // Load all agencies
    @wire(getAllAgencies)
    wiredAgencies({ data, error }) {
        if (data) {
            let merged = [...data];
            const existingDefault = this.agencies.find(a => a.value === this.defaultAgencyId);
            if (existingDefault && !merged.find(a => a.value === this.defaultAgencyId)) {
                merged.push(existingDefault);
            }
            this.agencies = merged;
            
            // Re-apply default config if needed
            if (this.defaultAgencyId && !this.config.agencyId) {
                this.config = { ...this.config, agencyId: this.defaultAgencyId };
            }
            
            // Emit state to update valid route status in parent
            this.emitState();
        } else if (error) {
            console.error('Error loading agencies:', error);
            this.agencies = [];
        }
    }
    
    // Load default agency name by ID using standard LDS
    @wire(getRecord, { recordId: '$defaultAgencyId', fields: LOCATION_FIELDS })
    wiredDefaultAgency({ data, error }) {
        if (data && this.defaultAgencyId) {
            const agencyName = getFieldValue(data, LOCATION_NAME);
            const agencyType = getFieldValue(data, LOCATION_TYPE);
            const agencyLat = getFieldValue(data, LOCATION_LAT);
            const agencyLng = getFieldValue(data, LOCATION_LNG);
            
            // Ensure agency is in the list with full details
            if (!this.agencies.find(a => a.value === this.defaultAgencyId)) {
                this.agencies = [...this.agencies, {
                    value: this.defaultAgencyId,
                    label: agencyName,
                    Name: agencyName,
                    LocationType: agencyType,
                    Latitude: agencyLat,
                    Longitude: agencyLng
                }];
            }
            // Pre-select agency properly using spread
            this.config = { ...this.config, agencyId: this.defaultAgencyId };
            // Emit state since valid route might be ready after agency loads
            this.emitState();
        } else if (error) {
            console.warn('Error loading default agency:', error);
        }
    }
    
    // Load offer type name + persisted direction mode from Opportunity
    @wire(getRecord, { recordId: '$opportunityId', fields: OPPORTUNITY_FIELDS })
    wiredOpportunity({ data, error }) {
        if (data) {
            this.offerTypeName = getFieldValue(data, OPP_OFFER_TYPE_NAME) || '';
            const persistedMode = getFieldValue(data, OPP_TRIP_DIRECTION_MODE);
            if (persistedMode && this.config.directionMode !== persistedMode) {
                this.config = { ...this.config, directionMode: persistedMode };
                this.emitState();
            }
        } else if (error) {
            console.warn('Error loading opportunity offer type:', error);
        }
    }

    // Load default delivery site name by ID using standard LDS
    @wire(getRecord, { recordId: '$defaultDeliverySiteId', fields: LOCATION_FIELDS })
    wiredDefaultDeliveryLocation({ data, error }) {
        if (data && this.defaultDeliverySiteId) {
            const siteName = getFieldValue(data, LOCATION_NAME);
            const siteType = getFieldValue(data, LOCATION_TYPE);
            const siteLat = getFieldValue(data, LOCATION_LAT);
            const siteLng = getFieldValue(data, LOCATION_LNG);
            
            // Ensure location is in the list with full details
            if (!this.accountLocations.find(l => l.value === this.defaultDeliverySiteId)) {
                this.accountLocations = [...this.accountLocations, {
                    value: this.defaultDeliverySiteId,
                    label: siteName,
                    Name: siteName,
                    LocationType: siteType,
                    Latitude: siteLat,
                    Longitude: siteLng
                }];
            }
            // Pre-select delivery site properly using spread
            this.config = { ...this.config, deliverySiteId: this.defaultDeliverySiteId };
            // Emit state since valid route might be ready after delivery site loads
            this.emitState();
        } else if (error) {
            console.warn('Error loading default delivery site:', error);
        }
    }
    
    // ==================== INTERNAL STATE ====================

    urgencyOptions = URGENCY_OPTIONS;
    directionModeOptions = DIRECTION_MODE_OPTIONS;

    @track accountLocations = [];
    @track agencies = [];
    @track offerTypeName = '';

    @track config = {
        agencyId: '',
        deliverySiteId: '',
        urgency: 'Standard',
        directionMode: DIRECTION_MODE.DELIVERY
    };
    
    @track trips = [];
    @track isCalculating = true;
    routeDistanceKm;
    routeDurationMinutes;
    _lastFetchedPair = null;
    @track previousConfig = {
        agencyId: '',
        deliverySiteId: ''
    };
    
    tripColumns = TRIP_COLUMNS;

    // ==================== LIFECYCLE ====================

    connectedCallback() {
        // Initialize config with defaults; preserve directionMode if already hydrated by the Opportunity wire
        this.config = {
            agencyId: this.defaultAgencyId || '',
            deliverySiteId: this.defaultDeliverySiteId || '',
            urgency: this.defaultUrgency || 'Standard',
            directionMode: this.config.directionMode || DIRECTION_MODE.DELIVERY
        };

        this.previousConfig = deepClone(this.config);
    }

    async loadExistingTrips() {
        if (!this.opportunityId) return;
        
        this.isCalculating = true;
        try {
            const result = await getTripsByOpportunity({ opportunityId: this.opportunityId });
            console.log('Existing trips loaded:', JSON.stringify(result));
            
            if (result && result.length > 0) {
                this.trips = result.map(t => ({
                    ...t,
                    Final_Price__c: t.Final_Price__c || t.System_Price__c
                }));
            } else {
                console.log('No trips returned from Apex for Opp ID:', this.opportunityId);
            }
        } catch (error) {
            console.error('Error loading existing trips:', error);
            showToast(this, 'Error Loading Trips', error.body ? error.body.message : error.message, 'error');
        } finally {
            this.isCalculating = false;
            // Always emit state after load regardless of outcome to sync parent
            this.emitState();
        }
    }

    // ==================== COMPUTED PROPERTIES ====================
    
    get emptyStateIllustration() {
        return ILLUSTRATIONS.NORESULTS_UNKNOWN.name;
    }

    /**
     * Get currently selected agency from options
     */
    get selectedAgency() {
        return this.agencies.find(loc => loc.value === this.config.agencyId);
    }

    /**
     * Get currently selected delivery site from options
     */
    get selectedDelivery() {
        return this.accountLocations.find(loc => loc.value === this.config.deliverySiteId);
    }

    /**
     * Rental offers — match the Offer Type Name against the Rental_Catalog_Names custom label
     * (canonical source of truth, same convention as Apex Label.Volume_Pricing_Catalog_Names usage).
     * Sale offers never need a pickup question.
     */
    get isRental() {
        if (!this.offerTypeName) return false;
        return RENTAL_CATALOG_SET.has(this.offerTypeName.trim().toLowerCase());
    }

    /**
     * Validate that both agency and delivery site are selected
     */
    @api
    get hasValidRoute() {
        return !!(this.selectedAgency && this.selectedDelivery);
    }

    /**
     * Disable calculate button if route is invalid or already calculating
     */
    @api
    get isCalculateDisabled() {
        return !this.hasValidRoute || this.isCalculating;
    }

    /**
     * Check if trips are available
     */
    get hasTrips() {
        return this.trips.length > 0;
    }

    /**
     * Show empty state when no trips and not calculating
     */
    get showEmptyState() {
        return !this.hasTrips && !this.isCalculating;
    }

    /**
     * Aggregate every trip's packing geometry into the bins-json array the 3D viewer
     * expects ("[{...},{...}]"). Calculated trips carry Packing_Geometry__c in-memory
     * (unsaved) and loaded trips carry it from the query, so the viewer works without
     * persisting. Null when no trip has geometry, which leaves the viewer empty.
     */
    get loadPlanBinsJson() {
        const geometries = this.trips
            .map(t => t.Packing_Geometry__c)
            .filter(g => g);
        return geometries.length ? `[${geometries.join(',')}]` : null;
    }

    /**
     * Disable Google Maps button if route is invalid
     */
    get disableIfNoRoute() {
        return !this.hasValidRoute;
    }

    // ==================== EVENT HANDLERS ====================

    @api
    async handleCalculateTransport() {
        if (!this.hasValidRoute) return;
        
        this.isCalculating = true;
        try {
            let result;
            
            if (this.selectedProducts && this.selectedProducts.length > 0) {
                // Build CPQ items structure for API call
                const cpqItems = this.selectedProducts.map(item => ({
                    productId: item.productId || item.Id,
                    productCode: item.productCode,
                    productName: item.productName,
                    quantity: item.quantity || 1,
                    w: item.w,
                    h: item.h,
                    d: item.d,
                    weight: item.weight,
                    options: (item.options || item.configuredOptions || []).map(opt => ({
                        productId: opt.productId || opt.Id,
                        isSelected: opt.isSelected,
                        quantity: opt.quantity || 1,
                        weight: opt.weight || opt.Unit_Weight_Kg__c,
                        w: opt.w,
                        h: opt.h,
                        d: opt.d
                    }))
                }));
                
                result = await calculateTripsWithCPQItems({
                    opportunityId: this.opportunityId,
                    agencyId: this.config.agencyId,
                    deliverySiteId: this.config.deliverySiteId,
                    urgency: this.config.urgency,
                    cpqItemsJson: JSON.stringify(cpqItems),
                    directionMode: this.isRental ? this.config.directionMode : DIRECTION_MODE.DELIVERY
                });
            }
            
            if (result && result.length > 0) {
                this.trips = result.map((t, index) => ({
                    ...t,
                    Id: `temp_${index}`, // mock ID since it's not saved
                    Final_Price__c: t.Final_Price__c || t.System_Price__c
                }));
            } else {
                this.trips = [];
                showToast(this, 'Info', 'No optimal packing found', 'info');
            }
        } catch (error) {
            console.error('Error calculating transport:', error);
            showToast(this, 'Error Calculating Transport', error.body ? error.body.message : error.message, 'error');
            this.trips = [];
        } finally {
            this.isCalculating = false;
            this.emitState();
        }
    }

    /**
     * Handle route settings changes (Agency, Delivery Site, Urgency)
     * When departure or delivery location changes:
     *   1. Clear existing trips
     *   2. Emit updated state
     *   3. Trigger auto-recalculation via parent
     */
    handleConfigChange(event) {
        console.log('handleConfigChange triggered!', event.detail);
        const field = event.target.dataset.field;
        const newValue = event.detail.value;

        // Update config
        this.config[field] = newValue;

        // Check if location-related fields changed
        const isLocationChange = field === 'agencyId' || field === 'deliverySiteId';
        // Direction mode change invalidates existing trips (each Trip__c is stamped with a direction)
        const isDirectionChange = field === 'directionMode';

        if (isLocationChange && this.didLocationChange()) {
            // Clear trips when location changes
            this.trips = [];

            // Update previous config to avoid redundant clears
            this.previousConfig = deepClone(this.config);

            // Emit state change to trigger parent auto-recalculation
            this.emitState();
        } else if (isDirectionChange) {
            this.trips = [];
            this.emitState();
        } else {
            // For non-location changes (like urgency), just emit state
            this.emitState();
        }
    }

    /**
     * Check if location has changed since last update
     */
    didLocationChange() {
        return (
            this.previousConfig.agencyId !== this.config.agencyId ||
            this.previousConfig.deliverySiteId !== this.config.deliverySiteId
        );
    }

    /**
     * Handle datatable save event
     * Process price overrides and validate Override Reason
     */
    handleSave(event) {
        const { draftValues } = event.detail;
        
        try {
            // Process each modified trip
            draftValues.forEach(draft => {
                const tripIndex = this.trips.findIndex(t => t.Id === draft.Id);
                
                if (tripIndex !== -1) {
                    const trip = this.trips[tripIndex];
                    
                    // Update Final Price if changed
                    if (draft.Final_Price__c !== undefined) {
                        const newPrice = Number(draft.Final_Price__c);
                        const isOverridden = newPrice !== trip.System_Price__c;
                        
                        trip.Final_Price__c = newPrice;
                        trip.Is_Price_Overridden__c = isOverridden;
                    }
                    
                    // Update Override Reason if provided
                    if (draft.Override_Reason__c !== undefined) {
                        trip.Override_Reason__c = draft.Override_Reason__c;
                    }
                }
            });
            
            // Validate that overridden prices have reasons
            const isValid = this.validateOverrideReasons();
            
            if (isValid) {
                this.emitState();
                // Clear draft values in datatable
                this.clearDraftValues();
            }
        } catch (error) {
            console.error('Erreur lors du traitement des modifications:', error);
            showToast(this, 'Erreur', 'Une erreur est survenue lors de la sauvegarde', 'error');
        }
    }

    /**
     * Validate that all overridden prices have an Override Reason
     * @returns {boolean} true if all validations pass
     */
    validateOverrideReasons() {
        const invalidTrips = this.trips.filter(
            trip => trip.Is_Price_Overridden__c && !trip.Override_Reason__c
        );
        
        if (invalidTrips.length > 0) {
            const tripIds = invalidTrips.map(t => t.Truck_Type__c).join(', ');
            showToast(
                this,
                'Validation Error',
                `Override Reason is required for: ${tripIds}`,
                'error'
            );
            return false;
        }
        
        return true;
    }

    /**
     * Clear draft values in datatable
     */
    clearDraftValues() {
        const datatable = this.template.querySelector('lightning-datatable');
        if (datatable) {
            datatable.draftValues = [];
        }
    }



    // ==================== COMMUNICATION ====================

    /**
     * Open the current route in Google Maps
     * Uses coordinates from selected agency and delivery site
     */
    @api
    openRouteInGoogleMaps() {
        if (!this.hasValidRoute) {
            showToast(this, 'Invalid Route', 'Please select both departure agency and delivery site', 'warning');
            return;
        }

        const origin = `${this.selectedAgency.Latitude},${this.selectedAgency.Longitude}`;
        const destination = `${this.selectedDelivery.Latitude},${this.selectedDelivery.Longitude}`;
        
        // Google Maps Directions URL
        const googleMapsUrl = `https://www.google.com/maps/dir/?api=1&origin=${origin}&destination=${destination}`;
        
        window.open(googleMapsUrl, '_blank', 'noopener,noreferrer');
    }

    /**
     * Fetch the server-side driving distance + duration for the current route pair so the
     * map can show the same figure as the record page. Guarded by the agency/delivery pair
     * (server-cached too), so it fires at most once per distinct route. Stale responses are
     * dropped if the selection changes mid-flight.
     */
    maybeFetchRouteDistance() {
        if (!this.hasValidRoute) {
            this.routeDistanceKm = undefined;
            this.routeDurationMinutes = undefined;
            this._lastFetchedPair = null;
            return;
        }

        const pair = `${this.config.agencyId}_${this.config.deliverySiteId}`;
        if (pair === this._lastFetchedPair) return;
        this._lastFetchedPair = pair;

        getRouteDistance({
            agencyId: this.config.agencyId,
            deliverySiteId: this.config.deliverySiteId,
            opportunityId: this.opportunityId
        })
            .then(result => {
                if (`${this.config.agencyId}_${this.config.deliverySiteId}` !== pair) return;
                this.routeDistanceKm = result?.distanceKm ?? undefined;
                this.routeDurationMinutes = result?.durationMinutes ?? undefined;
            })
            .catch(error => {
                console.error('Error fetching route distance:', error);
                if (`${this.config.agencyId}_${this.config.deliverySiteId}` !== pair) return;
                this.routeDistanceKm = undefined;
                this.routeDurationMinutes = undefined;
            });
    }

    /**
     * Emit current state to parent component
     */
    emitState() {
        this.maybeFetchRouteDistance();

        const selectedAgency = this.selectedAgency;
        const selectedDelivery = this.selectedDelivery;

        const logisticsState = {
            config: deepClone(this.config),
            trips: deepClone(this.trips),
            isValid: this.validateOverrideReasons(),
            agencyName: selectedAgency?.label || selectedAgency?.Name || '',
            deliverySiteName: selectedDelivery?.label || selectedDelivery?.Name || ''
        };

        this.dispatchEvent(new CustomEvent('logisticschange', {
            detail: { logistics: logisticsState },
            bubbles: true,
            composed: true
        }));
    }
}

