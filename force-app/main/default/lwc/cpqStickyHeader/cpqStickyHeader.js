import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { dispatchCustomEvent } from 'c/cpqUtils';

export default class CpqStickyHeader extends NavigationMixin(LightningElement) {
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

    get standaloneStepActions() {
        return (this._stepActions || [])
            .filter(a => a.isStandalone === true)
            .map(action => this.normalizeAction(action));
    }

    get groupedStepActions() {
        return (this._stepActions || [])
            .filter(a => a.isStandalone !== true)
            .slice(0, 3)
            .map(action => this.normalizeAction(action));
    }

    get hasStandaloneActions() {
        return (this._stepActions || []).some(a => a.isStandalone === true);
    }

    get hasGroupedActions() {
        return (this._stepActions || []).some(a => a.isStandalone !== true);
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

    /**
     * Handle navigation to a record page
     */
        handleLinkClick(event) {
            event.preventDefault();
            const recordId = event.currentTarget.dataset.recordId;
            const objectApiName = event.currentTarget.dataset.objectApiName;

            if (recordId && objectApiName) {
                this[NavigationMixin.GenerateUrl]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: recordId,
                        objectApiName: objectApiName,
                        actionName: 'view'
                    }
                }).then(url => {
                    window.open(url, '_blank');
                });
            }
        }

    /**
     * Handle action button clicks from header
     */
    handleAction(event) {
        const actionName = event.currentTarget.dataset.action;
        dispatchCustomEvent(this, 'headeraction', { action: actionName });
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
        dispatchCustomEvent(this, 'headersearch', { searchValue: event.detail.value });
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
