import { LightningElement, api } from 'lwc';

export default class CpqStickyHeader extends LightningElement {
    @api topLabel = '';
    @api title = '';
    @api subtitle = '';
    @api iconName = '';
    @api stepActions = []; // [{ name, label, variant, disabled }] - renders as buttons in button-group
    @api globalActions = []; // [{ name, label, variant, iconName, isMenu, isGroup, items }]
    @api metadataItems = []; // [{ id, label, value, iconName, isLink, isBold }]
    @api showSearch = false; // Boolean: show/hide search based on step
    @api searchPlaceholder = 'Search...';

    /**
     * Show row 2 if there are metadata items or search is enabled
     */
    get showRow2() {
        return (this.metadataItems && this.metadataItems.length > 0) || this.showSearch || (this.globalActions && this.globalActions.length > 0);
    }

    /**
     * Handle action button clicks from header
     */
    handleAction(event) {
        const actionName = event.currentTarget.dataset.action;
        this.dispatchEvent(new CustomEvent('headeraction', {
            detail: { action: actionName },
            bubbles: true,
            composed: true
        }));
    }

    /**
     * Handle search input change
     */
    handleSearch(event) {
        this.dispatchEvent(new CustomEvent('headersearch', {
            detail: { searchValue: event.detail.value },
            bubbles: true,
            composed: true
        }));
    }
}
