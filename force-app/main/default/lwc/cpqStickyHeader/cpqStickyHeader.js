import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { dispatchCustomEvent } from 'c/cpqUtils';

export default class CpqStickyHeader extends NavigationMixin(LightningElement) {
    @api topLabel = '';
    @api title = '';
    @api subtitle = '';
    @api iconName = '';
    @api stepActions = []; 
    @api globalActions = []; 
    @api metadataItems = [];
    @api showSearch = false;
    @api searchPlaceholder = 'Search...';

    /**
     * Show row 2 if there are metadata items or search is enabled
     */
    get showRow2() {
        return (this.metadataItems && this.metadataItems.length > 0) || this.showSearch || (this.globalActions && this.globalActions.length > 0);
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

    /**
     * Handle search input change
     */
    handleSearch(event) {
        dispatchCustomEvent(this, 'headersearch', { searchValue: event.detail.value });
    }
}
