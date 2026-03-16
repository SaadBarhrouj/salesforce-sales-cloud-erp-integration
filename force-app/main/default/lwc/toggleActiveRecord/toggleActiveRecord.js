import { LightningElement, api, wire } from 'lwc';
import { updateRecord, getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ToggleActiveRecord extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api fieldName = 'Is_Active__c';
    @api successMessage = 'Status updated successfully.';

    currentValue = false;

    get dynamicField() {
        return `${this.objectApiName}.${this.fieldName}`;
    }

    @wire(getRecord, { recordId: '$recordId', fields: '$dynamicField' })
    wiredRecord({ error, data }) {
        if (data) {
            this.currentValue = getFieldValue(data, this.dynamicField);
        } else if (error) {
            console.error('Error fetching record data:', error);
        }
    }

    @api invoke() {
        const fields = {};
        fields['Id'] = this.recordId;
        fields[this.fieldName] = !this.currentValue;

        const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: this.successMessage,
                    variant: 'success'
                }));
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error updating record',
                    message: error.body ? error.body.message : error.message,
                    variant: 'error'
                }));
            });
    }
}
