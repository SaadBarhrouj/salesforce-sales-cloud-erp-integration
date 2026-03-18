import { LightningElement, api } from 'lwc';

export default class CpqStickyHeader extends LightningElement {
    @api topLabel = '';
    @api title = '';
    @api subtitle = '';
    @api iconName = '';
    @api metadataItems = [];
    @api showSearch = false;
    @api searchPlaceholder = 'Search...';

    _stepActions = [];
    _globalActions = [];

    @api
    get stepActions() {
        return (this._stepActions || []).slice(0, 3).map(action => this.normalizeAction(action));
    }
    
    set stepActions(value) {
        this._stepActions = value || [];
    }

    get hasStepActions() {
        return (this._stepActions || []).length > 0;
    }

    get stepActionsOverflow() {
        return (this._stepActions || []).slice(3).map(action => this.normalizeAction(action));
    }

    get hasOverflowActions() {
        return (this._stepActions || []).length > 3;
    }

    @api
    get globalActions() { return this._globalActions; }
    set globalActions(value) { this._globalActions = value || []; }

    get showRow2() {
        return (this.metadataItems && this.metadataItems.length > 0) || this.showSearch || (this._globalActions && this._globalActions.length > 0);
    }

    handleAction(event) {
        const actionName = event.currentTarget.dataset.action;
        this.dispatchEvent(new CustomEvent('headeraction', {
            detail: { action: actionName },
            bubbles: true,
            composed: true
        }));
    }

    handleMenuSelect(event) {
        const actionName = event.detail.value;
        this.dispatchEvent(new CustomEvent('headeraction', {
            detail: { action: actionName },
            bubbles: true,
            composed: true
        }));
    }

    handleSearch(event) {
        this.dispatchEvent(new CustomEvent('headersearch', {
            detail: { searchValue: event.detail.value },
            bubbles: true,
            composed: true
        }));
    }

    normalizeAction(action) {
        return {
            ...action,
            variant: action?.variant || 'neutral',
            label: this.getActionLabel(action)
        };
    }

    getActionLabel(action) {
        if (!action) {
            return '';
        }

        if (action.badge !== undefined && action.badge !== null && action.badge !== '') {
            return `${action.label} (${action.badge})`;
        }

        return action.label;
    }
}
