import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getRelatedChildRecords from '@salesforce/apex/CloneService.getRelatedChildRecords';
import cloneRecordWithChildren from '@salesforce/apex/CloneService.cloneRecordWithChildren';

const COLUMNS = [
    { label: 'Name', fieldName: 'Name', type: 'text' }
];

export default class CloneWithRelatedRecords extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;

    @track childRelationships = [];
    @track selectedIdsMap = {}; // relationshipName => List<Id>
    
    isLoading = true;
    columns = COLUMNS;

    @wire(getRelatedChildRecords, { recordId: '$recordId' })
    wiredChildren({ error, data }) {
        this.isLoading = true;
        if (data) {
            this.childRelationships = data;
            this.isLoading = false;
        } else if (error) {
            this.showToast('Error fetching related records', error.body.message, 'error');
            this.isLoading = false;
        }
    }

    get hasChildren() {
        return this.childRelationships && this.childRelationships.length > 0;
    }

    handleRowSelection(event) {
        const relName = event.target.dataset.rel;
        const selectedIds = event.detail.selectedRows.map(row => row.Id);
        this.selectedIdsMap = { ...this.selectedIdsMap, [relName]: selectedIds };
    }

    async handleClone() {
        this.isLoading = true;
        try {
            const newParentId = await cloneRecordWithChildren({ 
                recordId: this.recordId, 
                selectedIdsMap: this.selectedIdsMap 
            });

            this.showToast('Success', 'Record cloned successfully along with selected children.', 'success');
            
            // Navigate to the new record
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: newParentId,
                    actionName: 'view'
                }
            });

            this.closeAction();
        } catch (error) {
            this.showToast('Cloning Error', error.body ? error.body.message : error.message, 'error');
            this.isLoading = false;
        }
    }

    closeAction() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
