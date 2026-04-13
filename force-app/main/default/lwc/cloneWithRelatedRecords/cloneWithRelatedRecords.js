import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import getRelatedChildRecords from '@salesforce/apex/CloneService.getRelatedChildRecords';
import cloneRecordWithChildren from '@salesforce/apex/CloneService.cloneRecordWithChildren';


export default class CloneWithRelatedRecords extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;

    @track childRelationships = [];
    @track selectedIdsMap = {}; // relationshipName => List<Id>
    
    isLoading = true;
    newParentId;

    @wire(getRelatedChildRecords, { recordId: '$recordId' })
    wiredChildren({ error, data }) {
        this.isLoading = true;
        if (data) {
            this.childRelationships = data.map(rel => ({
                ...rel,
                headerLabel: `${rel.childSObjectLabel} (${rel.recordCount})`
            }));
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
            this.newParentId = await cloneRecordWithChildren({ 
                recordId: this.recordId, 
                selectedIdsMap: this.selectedIdsMap 
            });

            this.showToast('Success', 'Record cloned successfully.', 'success');
            this.navigateToNewRecord();
            this.isLoading = false;
        } catch (error) {
            this.showToast('Cloning Error', error.body ? error.body.message : error.message, 'error');
            this.isLoading = false;
        }
    }

    navigateToNewRecord() {
        if (!this.newParentId) return;

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.newParentId,
                objectApiName: this.objectApiName,
                actionName: 'view'
            }
        });

        setTimeout(() => {
            this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.newParentId,
                objectApiName: this.objectApiName,
                actionName: 'edit'
            }
        });
        }, 1000);

        this.closeAction();        
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}