import { LightningElement, api } from 'lwc';
import { getLocations } from 'c/cpqDataService';
import { formatCurrency, formatNumber, calculateSelectedProductsSubtotal, deepClone } from 'c/cpqUtils';
import { URGENCY_OPTIONS } from 'c/cpqConstants';

export default class CpqStepLogistics extends LightningElement {
    @api selectedProducts = [];
    @api quoteState = {};
    @api logisticsState = {};

    locations = [];
    transportRequired = false;
    deliverySiteId = '';
    agencyId = '';
    urgency = 'Standard';
    notes = '';

    urgencyOptions = URGENCY_OPTIONS;

    async connectedCallback() {
        try {
            this.locations = await getLocations();
        } catch (e) {
            console.error('Error loading locations:', e);
        }

        // Restore state
        if (this.logisticsState) {
            this.transportRequired = this.logisticsState.transportRequired || false;
            this.deliverySiteId = this.logisticsState.deliverySiteId || '';
            this.agencyId = this.logisticsState.agencyId || '';
            this.urgency = this.logisticsState.urgency || 'Standard';
            this.notes = this.logisticsState.notes || '';
        }
    }

    /* ─── Computed ─── */

    get locationOptions() {
        return this.locations.map(l => ({
            label: `${l.Name} (${l.City}, ${l.Country})`,
            value: l.Id
        }));
    }

    get agencyOptions() {
        return this.locations
            .filter(l => l.Type === 'Warehouse' || l.Type === 'Agency')
            .map(l => ({
                label: `${l.Name} (${l.City})`,
                value: l.Id
            }));
    }

    get formattedSubtotal() {
        return formatCurrency(calculateSelectedProductsSubtotal(this.selectedProducts || []));
    }

    get itemCount() {
        return (this.selectedProducts || []).length;
    }

    get totalWeight() {
        let weight = 0;
        (this.selectedProducts || []).forEach(item => {
            weight += (item.weight || 0) * item.quantity;
            if (item.options) {
                item.options.filter(o => o.isSelected).forEach(o => {
                    weight += (o.weight || 0) * o.quantity * item.quantity;
                });
            }
        });
        return weight;
    }

    get formattedWeight() {
        return formatNumber(this.totalWeight, 1);
    }

    get isSaveDisabled() {
        if (this.transportRequired) {
            return !this.deliverySiteId || !this.agencyId;
        }
        return false;
    }

    /* ─── Event Handlers ─── */

    handleTransportToggle(event) {
        this.transportRequired = event.target.checked;
        this.emitChange();
    }

    handleDeliverySiteChange(event) {
        this.deliverySiteId = event.detail.value;
        this.emitChange();
    }

    handleAgencyChange(event) {
        this.agencyId = event.detail.value;
        this.emitChange();
    }

    handleUrgencyChange(event) {
        this.urgency = event.detail.value;
        this.emitChange();
    }

    handleNotesChange(event) {
        this.notes = event.detail.value;
        this.emitChange();
    }

    handleBack() {
        this.emitChange();
        this.dispatchEvent(new CustomEvent('navigate', { detail: { direction: 'back' } }));
    }

    handleNext() {
        this.emitChange();
        this.dispatchEvent(new CustomEvent('navigate', { detail: { direction: 'next' } }));
    }

    handleSave() {
        this.emitChange();
        this.dispatchEvent(new CustomEvent('savequote', {
            detail: { logistics: deepClone(this.buildState()) }
        }));
    }

    /* ─── Internal ─── */

    buildState() {
        return {
            transportRequired: this.transportRequired,
            deliverySiteId: this.deliverySiteId,
            agencyId: this.agencyId,
            urgency: this.urgency,
            notes: this.notes
        };
    }

    emitChange() {
        this.dispatchEvent(new CustomEvent('logisticschange', {
            detail: { logistics: deepClone(this.buildState()) }
        }));
    }
}