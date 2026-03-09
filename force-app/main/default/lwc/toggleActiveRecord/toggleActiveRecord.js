import { LightningElement, api, wire } from 'lwc';
import { updateRecord, getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import ID_FIELD from '@salesforce/schema/Product_Rule__c.Id';
import IS_ACTIVE_FIELD from '@salesforce/schema/Product_Rule__c.Is_Active__c';

export default class ToggleActiveRecord extends LightningElement {
    @api recordId;
    currentIsActive = false;

    @wire(getRecord, { recordId: '$recordId', fields: [IS_ACTIVE_FIELD] })
    wiredRecord({ error, data }) {
        if (data) {
            this.currentIsActive = data.fields.Is_Active__c.value;
        }
    }

    @api invoke() {
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[IS_ACTIVE_FIELD.fieldApiName] = !this.currentIsActive;
        
        updateRecord({ fields })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({ 
                    title: 'Success', 
                    message: fields[IS_ACTIVE_FIELD.fieldApiName] ? 'Rule Activated' : 'Rule Deactivated', 
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
