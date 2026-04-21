import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { deepClone, showToast } from 'c/cpqUtils';
import { URGENCY_OPTIONS, ILLUSTRATIONS } from 'c/cpqConstants';
import getLocationsByAccount from '@salesforce/apex/LocationController.getLocationsByAccount';
import getAllAgencies from '@salesforce/apex/LocationController.getAllAgencies';
import getTripsByOpportunity from '@salesforce/apex/TripController.getTripsByOpportunity';
import calculateTrips from '@salesforce/apex/TripController.calculateTrips';
import LOCATION_NAME from '@salesforce/schema/Location.Name';
import LOCATION_TYPE from '@salesforce/schema/Location.LocationType';
import LOCATION_LAT from '@salesforce/schema/Location.Latitude';
import LOCATION_LNG from '@salesforce/schema/Location.Longitude';

const LOCATION_FIELDS = [LOCATION_NAME, LOCATION_TYPE, LOCATION_LAT, LOCATION_LNG];

const TRIP_COLUMNS = [
    { label: 'Trip Key', fieldName: 'Trip_Key__c', type: 'text', sortable: true },
    { label: 'Direction', fieldName: 'Direction__c', type: 'text', sortable: true },
    { label: 'Truck Type', fieldName: 'Truck_Type__c', type: 'text', sortable: true },
    { label: 'Transport Zone', fieldName: 'Transport_Zone__c', type: 'text', sortable: true },
    { label: 'Distance (km)', fieldName: 'Distance_Km__c', type: 'number', sortable: true },
    { label: 'Total Weight', fieldName: 'Total_Weight_Kg__c', type: 'number', sortable: true },
    { label: 'System Price', fieldName: 'System_Price__c', type: 'currency', sortable: true },
    { label: 'Final Price', fieldName: 'Final_Price__c', type: 'currency', editable: true, typeAttributes: { step: '0.01' } },
    { label: 'Status', fieldName: 'Status__c', type: 'text' },
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
    
    @track accountLocations = [];
    @track agencies = [];
    
    @track config = {
        agencyId: '',
        deliverySiteId: '',
        urgency: 'Standard'
    };
    
    @track trips = [];
    @track isCalculating = true; // Commencer à true pour éviter d'afficher le bloc "No Routes" avant le chargement
    @track previousConfig = {
        agencyId: '',
        deliverySiteId: ''
    };
    
    tripColumns = TRIP_COLUMNS;

    // ==================== LIFECYCLE ====================

    connectedCallback() {
        // Initialize config with defaults
        this.config = {
            agencyId: this.defaultAgencyId || '',
            deliverySiteId: this.defaultDeliverySiteId || '',
            urgency: this.defaultUrgency || 'Standard'
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
     * Disable Google Maps button if route is invalid
     */
    get disableIfNoRoute() {
        return !this.hasValidRoute;
    }

    // ==================== EVENT HANDLERS ====================

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
        
        if (isLocationChange && this.didLocationChange()) {
            // Clear trips when location changes
            this.trips = [];
            
            // Update previous config to avoid redundant clears
            this.previousConfig = deepClone(this.config);
            
            // Emit state change to trigger parent auto-recalculation
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
                        const newPrice = draft.Final_Price__c;
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

    /**
     * Public method to calculate trips
     * Called from parent when auto-calculation is triggered
     */
    @api
    async handleCalculateTrips() {
        if (!this.hasValidRoute) return;
        
        this.isCalculating = true;

        try {
            const result = await calculateTrips({
                opportunityId: this.opportunityId,
                agencyId: this.config.agencyId,
                deliverySiteId: this.config.deliverySiteId,
                urgency: this.config.urgency,
                totalWeight: this.totalWeight
            });
            
            this.trips = result.map(t => ({
                ...t,
                Final_Price__c: t.Final_Price__c || t.System_Price__c
            }));
            
            this.emitState();
        } catch (error) {
            console.error('Erreur lors du calcul des trips:', error);
            showToast(this, 'Erreur', 'Impossible de calculer les trajets', 'error');
        } finally {
            this.isCalculating = false;
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
     * Emit current state to parent component
     */
    emitState() {
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