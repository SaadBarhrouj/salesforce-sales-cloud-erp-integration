import { LightningElement, api, track } from 'lwc';
import { formatCurrency, deepClone } from 'c/cpqUtils';
import { URGENCY_OPTIONS, ILLUSTRATIONS } from 'c/cpqConstants';

export default class CpqStepLogistics extends LightningElement {
    // ---- PROPRIÉTÉS FOURNIES PAR LE PARENT ----
    @api opportunityId;
    @api accountLocations = []; // Format attendu: [{label, value, Latitude, Longitude, Name}]
    @api agencies = [];         // Format attendu: [{label, value, Latitude, Longitude, Name}]
    @api totalWeight = 0;       // Poids fourni et précalculé par le CPQ général

    urgencyOptions = URGENCY_OPTIONS;

    // ---- STATE INTERNE ----
    @track transportRequired = false;
    @track config = {
        agencyId: '',
        deliverySiteId: '',
        urgency: 'Standard'
    };
    
    @track trips = []; // Trips générés après calcul
    @track isCalculating = false;

    // ---- GETTERS REACTIFS (UI & MAP) ----
    get emptyStateIllustration() {
        return ILLUSTRATIONS.NORESULTS_UNKNOWN.name;
    }

    get selectedAgency() {
        return this.agencies.find(loc => loc.value === this.config.agencyId);
    }

    get selectedDelivery() {
        return this.accountLocations.find(loc => loc.value === this.config.deliverySiteId);
    }

    get hasValidRoute() {
        return !!(this.selectedAgency && this.selectedDelivery);
    }

    get isCalculateDisabled() {
        return !this.hasValidRoute || this.isCalculating;
    }

    get hasTrips() {
        return this.trips.length > 0;
    }

    get showEmptyState() {
        return !this.hasTrips && !this.isCalculating;
    }

    // ---- HANDLERS ----

    handleTransportToggle(event) {
        this.transportRequired = event.target.checked;
        if (!this.transportRequired) {
            // Reset state if transport is unchecked
            this.config = { agencyId: '', deliverySiteId: '', urgency: 'Standard' };
            this.trips = [];
        }
        this.emitState();
    }

    handleConfigChange(event) {
        const field = event.target.dataset.field;
        this.config[field] = event.detail.value;

        // On reset les trips car la configuration a changé
        this.trips = [];
        this.emitState();
    }

    handleOverrideChange(event) {
        const tripId = event.target.dataset.tripid;
        const newOverride = event.detail.value ? parseFloat(event.detail.value) : null;
        
        const tripIndex = this.trips.findIndex(t => t.id === tripId);
        if (tripIndex !== -1) {
            this.trips[tripIndex].overridePrice = newOverride;
        }
        
        this.emitState();
    }

    handleOverrideReasonChange(event) {
        const tripId = event.target.dataset.tripid;
        const newReason = event.detail.value;
        const tripIndex = this.trips.findIndex(t => t.id === tripId);
        if (tripIndex !== -1) {
            this.trips[tripIndex].overrideReason = newReason;
        }
        this.emitState();
    }

    // ---- BUSINESS LOGIC : CALCUL LOURD ----
    @api
    async handleCalculateTrips() {
        if (!this.hasValidRoute) return;
        this.isCalculating = true;
        this.trips = []; // Reset des trips avant nouveau calcul

        try {
            // --- MOCK DU CALCUL EXTERNE LENT ---
            await new Promise(resolve => setTimeout(resolve, 1500));

            // Génération de Trips factices basés sur la configuration
            const baseCost = (this.totalWeight || 100) * (this.config.urgency === 'Express' ? 2.5 : 1.2);
            
            this.trips = [
                {
                    id: 'trip-001',
                    type: 'Outbound',
                    calculatedCost: baseCost,
                    formattedCalculatedCost: formatCurrency(baseCost),
                    overridePrice: null
                }
            ];
            
            // Si forte urgence et poids élevé, on simule un 2ème trip (ex: escorte ou véhicule spécifique)
            if (this.config.urgency === 'Express' && (this.totalWeight || 100) > 500) {
                const expressSurcharge = baseCost * 0.3;
                this.trips.push({
                    id: 'trip-002',
                    type: 'Express Surcharge Logistics',
                    calculatedCost: expressSurcharge,
                    formattedCalculatedCost: formatCurrency(expressSurcharge),
                    overridePrice: null
                });
            }

        } catch (error) {
            console.error('Erreur lors du calcul des trips:', error);
        } finally {
            this.isCalculating = false;
            this.emitState();
        }
    }

    // ---- COMMUNICATION AVEC LE PARENT ----
    emitState() {
        // Renvoie un état propre au parent pour la sauvegarde du devis (Quote)
        const logisticsState = {
            config: deepClone(this.config),
            trips: deepClone(this.trips)
        };

        this.dispatchEvent(new CustomEvent('logisticschange', {
            detail: { logistics: logisticsState }
        }));
    }
}

