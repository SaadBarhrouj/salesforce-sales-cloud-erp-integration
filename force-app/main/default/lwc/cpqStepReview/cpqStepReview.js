import { LightningElement, api } from 'lwc';
import { formatCurrency, formatNumber, calculateSelectedProductsSubtotal, calculateSelectedProductTotal } from 'c/cpqUtils';

export default class CpqStepReview extends LightningElement {
    @api selectedProducts = [];
    @api quoteState = {};
    @api logisticsState = {};

    /* ═══ Quote Info ═══ */

    get contactDisplay() {
        return this.quoteState.contactName || '—';
    }

    get termDisplay() {
        return this.quoteState.subscriptionTerm ? `${this.quoteState.subscriptionTerm} months` : '—';
    }

    get discountDisplay() {
        const d = this.quoteState.additionalDiscountPercent;
        return d ? `${d}%` : '0%';
    }

    /* ═══ Line Items ═══ */

    get itemCount() {
        return (this.selectedProducts || []).length;
    }

    get numberedItems() {
        const discount = this.quoteState.additionalDiscountPercent || 0;
        return (this.selectedProducts || []).map((item, idx) => {
            const selectedOpts = (item.options || []).filter(o => o.isSelected);
            return {
                ...item,
                _lineNumber: idx + 1,
                _formattedUnitPrice: formatCurrency(item.listUnitPrice || 0),
                _formattedDiscount: item.additionalDiscount ? `${item.additionalDiscount}%` : '0%',
                _formattedTotal: formatCurrency(calculateSelectedProductTotal(item, discount)),
                hasOptions: selectedOpts.length > 0,
                options: selectedOpts.map(o => ({
                    ...o,
                    _optKey: `${item._key}-${o.Id}`,
                    _formattedPrice: formatCurrency(o.UnitPrice || 0),
                    _formattedOptionTotal: formatCurrency((o.UnitPrice || 0) * (o.quantity || 1))
                }))
            };
        });
    }

    get formattedSubtotal() {
        const discount = this.quoteState.additionalDiscountPercent || 0;
        return formatCurrency(calculateSelectedProductsSubtotal(this.selectedProducts || [], discount));
    }

    /* ═══ Bundles ═══ */

    get hasBundles() {
        return (this.selectedProducts || []).some(i => i.isBundle);
    }

    get bundleItems() {
        return (this.selectedProducts || [])
            .filter(i => i.isBundle)
            .map(b => {
                const selected = (b.options || []).filter(o => o.isSelected);
                return {
                    ...b,
                    _configLabel: b.configured ? 'Configured' : 'Incomplete',
                    _configBadgeClass: b.configured ? 'badge-success' : 'badge-warning',
                    _selectedOptions: selected.map(o => ({
                        ...o,
                        _optKey: `rev-${b._key}-${o.Id}`,
                        _formattedPrice: formatCurrency(o.UnitPrice || 0)
                    })),
                    _noOptionsSelected: selected.length === 0
                };
            });
    }

    /* ═══ Logistics ═══ */

    get transportDisplay() {
        return this.logisticsState.transportRequired ? 'Yes' : 'No';
    }

    get deliverySiteDisplay() {
        return this.logisticsState.deliverySiteId || '—';
    }

    get agencyDisplay() {
        return this.logisticsState.agencyId || '—';
    }

    get urgencyDisplay() {
        return this.logisticsState.urgency || '—';
    }

    get hasNotes() {
        return !!(this.logisticsState.notes);
    }

    /* ═══ Totals ═══ */

    get formattedWeight() {
        let weight = 0;
        (this.selectedProducts || []).forEach(item => {
            weight += (item.weight || 0) * (item.quantity || 1);
            (item.options || []).filter(o => o.isSelected).forEach(o => {
                weight += (o.Unit_Weight_Kg__c || 0) * (o.quantity || 1);
            });
        });
        return formatNumber(weight, 1);
    }

    /* ═══ Actions ═══ */

    handleBack() {
        this.dispatchEvent(new CustomEvent('navigate', { detail: { direction: 'back' } }));
    }

    handleSave() {
        this.dispatchEvent(new CustomEvent('savequote', {
            detail: { confirmed: true }
        }));
    }
}
