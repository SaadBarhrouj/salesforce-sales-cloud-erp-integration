import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { createRecord } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Location object
import LOCATION_OBJECT from '@salesforce/schema/Location';

// Account fields
import ACCOUNT_NAME from '@salesforce/schema/Account.Name';

// Location fields
import LOCATION_NAME from '@salesforce/schema/Location.Name';
import LOCATION_TYPE from '@salesforce/schema/Location.LocationType';

// AssociatedLocation fields
import ASSOC_LOC_OBJECT from '@salesforce/schema/AssociatedLocation';
import PARENT_RECORD_ID from '@salesforce/schema/AssociatedLocation.ParentRecordId';
import LOCATION_ID from '@salesforce/schema/AssociatedLocation.LocationId';
import ASSOC_TYPE from '@salesforce/schema/AssociatedLocation.Type';
import ACTIVE_FROM from '@salesforce/schema/AssociatedLocation.ActiveFrom';
import ACTIVE_TO from '@salesforce/schema/AssociatedLocation.ActiveTo';

export default class CreateSiteAssociation extends LightningElement {

    // ─── Public property ───
    @api recordId; 
    @api objectApiName;  

    // ─── Internal state ───
    accountId = null;
    accountName = '';
    locationId = null;
    locationName = '';
    associationType = 'Ship To';
    activeFrom = null;  
    activeTo = null;     
    activeDateFrom = null; 
    activeDateTo = null;   
    showNewAccountForm = false;
    showNewLocationForm = false;
    locationPickerKey = 0;
    accountPickerKey = 0;
    _locationObjectInfo;

    @wire(getObjectInfo, { objectApiName: LOCATION_OBJECT })
    wiredLocationObjectInfo({ data, error }) {
        if (data) {
            this._locationObjectInfo = data;
            const rtInfos = data.recordTypeInfos;
            console.log('[createSiteAssociation] Location recordTypeInfos:', JSON.stringify(Object.values(rtInfos).map(rt => ({
                recordTypeId: rt.recordTypeId,
                name: rt.name,
                developerName: rt.developerName,
                master: rt.master
            }))));
            console.log('[createSiteAssociation] resolved locationSiteRecordTypeId:', this.locationSiteRecordTypeId);
        }
        if (error) {
            console.error('[createSiteAssociation] getObjectInfo error:', JSON.stringify(error));
        }
    }

    get locationSiteRecordTypeId() {
        if (!this._locationObjectInfo) return null;
        const rtInfos = this._locationObjectInfo.recordTypeInfos;
        const siteRt = Object.values(rtInfos).find(
            rt => !rt.master && (rt.name === 'Site' || rt.developerName === 'Site')
        );
        console.log('[createSiteAssociation] locationSiteRecordTypeId getter →', siteRt ? siteRt.recordTypeId : 'NOT FOUND');
        return siteRt ? siteRt.recordTypeId : null;
    }

    // ─── Detect which page we are on ───
    get isOnAccountPage() {
        return this.objectApiName === 'Account';
    }

    get isOnLocationPage() {
        return this.objectApiName === 'Location';
    }

    get cardTitle() {
        if (this.isOnAccountPage) {
            return 'Create Site for ' + (this.accountName || 'this Account');
        }
        return 'Associate Account to ' + (this.locationName || 'this Location');
    }

    get isSaveDisabled() {
        return !this.accountId || !this.locationId;
    }

    // ─── Location filter: only show Sites ───
    get locationFilter() {
        return {
            criteria: [
                {
                    fieldPath: 'LocationType',
                    operator: 'eq',
                    value: 'Site'
                }
            ]
        };
    }

    // ─── Set today as default Active From ───
    connectedCallback() {
        const today = new Date();
        this.activeDateFrom = today.toISOString().split('T')[0];
        this.activeFrom = today.toISOString();
    }

    // ─── Load Account name if on Account page ───
    @wire(getRecord, { 
        recordId: '$recordId', 
        fields: [ACCOUNT_NAME] 
    })
    wiredAccount({ data, error }) {
        if (data && this.isOnAccountPage) {
            this.accountName = getFieldValue(data, ACCOUNT_NAME);
            this.accountId = this.recordId;
        }
    }

    // ─── Load Location name if on Location page ───
    @wire(getRecord, { 
        recordId: '$recordId', 
        fields: [LOCATION_NAME, LOCATION_TYPE] 
    })
    wiredLocation({ data, error }) {
        if (data && this.isOnLocationPage) {
            this.locationName = getFieldValue(data, LOCATION_NAME);
            this.locationId = this.recordId;
        }
    }

    // ─── Event Handlers ───

    handleAccountChange(event) {
        this.accountId = event.detail.recordId;
    }

    handleLocationChange(event) {
        this.locationId = event.detail.recordId;
    }

    handleActiveFromChange(event) {
        const dateStr = event.detail.value; // YYYY-MM-DD
        this.activeDateFrom = dateStr;
        this.activeFrom = dateStr ? dateStr + 'T00:00:00.000Z' : null;
    }

    handleActiveToChange(event) {
        const dateStr = event.detail.value; // YYYY-MM-DD
        this.activeDateTo = dateStr;
        this.activeTo = dateStr ? dateStr + 'T00:00:00.000Z' : null;
    }

    // ─── New Location: show inline creation form ───
    handleNewLocation() {
        this.showNewLocationForm = true;
    }

    handleCancelNewLocation() {
        this.showNewLocationForm = false;
    }

    handleLocationSubmit(event) {
        event.preventDefault();
        const fields = { ...event.detail.fields };
        console.log('[createSiteAssociation] handleLocationSubmit - fields BEFORE:', JSON.stringify(fields));
        fields[LOCATION_TYPE.fieldApiName] = 'Site';
        console.log('[createSiteAssociation] handleLocationSubmit - fields AFTER:', JSON.stringify(fields));
        console.log('[createSiteAssociation] LOCATION_TYPE.fieldApiName =', LOCATION_TYPE.fieldApiName);
        this.template.querySelector('[data-id="locationForm"]').submit(fields);
    }

    handleLocationCreated(event) {
        this.locationId = event.detail.id;
        this.showNewLocationForm = false;
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Location created',
                message: 'The new location has been selected.',
                variant: 'success'
            })
        );
    }

    // ─── New Account: show inline creation form ───
    handleNewAccount() {
        this.showNewAccountForm = true;
    }

    handleCancelNewAccount() {
        this.showNewAccountForm = false;
    }

    handleAccountCreated(event) {
        this.accountId = event.detail.id;
        this.showNewAccountForm = false;
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Account created',
                message: 'The new account has been selected.',
                variant: 'success'
            })
        );
    }

    // ─── Cancel ───
    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
        this.resetForm();
    }

    // ─── Save ───
    async handleSave() {
        // Validate
        if (!this.accountId) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Validation', message: 'Please select an Account.', variant: 'warning' }));
            return;
        }
        if (!this.locationId) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Validation', message: 'Please select a Location.', variant: 'warning' }));
            return;
        }

        // Validate dates
        if (this.activeFrom && this.activeTo && this.activeTo < this.activeFrom) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Validation', message: 'Active To must be after Active From.', variant: 'warning' }));
            return;
        }

        try {
            // Build the record
            const fields = {};
            fields[PARENT_RECORD_ID.fieldApiName] = this.accountId;
            fields[LOCATION_ID.fieldApiName] = this.locationId;
            fields[ASSOC_TYPE.fieldApiName] = this.associationType;
            
            if (this.activeFrom) {
                fields[ACTIVE_FROM.fieldApiName] = this.activeFrom;
            }
            if (this.activeTo) {
                fields[ACTIVE_TO.fieldApiName] = this.activeTo;
            }

            // Create AssociatedLocation
            await createRecord({
                apiName: ASSOC_LOC_OBJECT.objectApiName,
                fields: fields
            });

            // Show success
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Site associated successfully!',
                    variant: 'success'
                })
            );

            // Close after 2 seconds
            setTimeout(() => {
                this.dispatchEvent(new CloseActionScreenEvent());
            }, 2000);

        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: this.extractError(error), variant: 'error', mode: 'sticky' }));
        }
    }

    // ─── Helpers ───

    resetForm() {
        const today = new Date();
        this.activeDateFrom = today.toISOString().split('T')[0];
        this.activeFrom = today.toISOString();
        this.activeDateTo = null;
        this.activeTo = null;

        this.showNewLocationForm = false;
        this.showNewAccountForm = false;
        if (this.isOnAccountPage) {
            this.locationId = null;
            this.locationPickerKey++;
        } else {
            this.accountId = null;
            this.accountPickerKey++;
        }
    }

    extractError(error) {
        if (error?.body?.message) {
            return error.body.message;
        }
        if (error?.body?.output?.errors?.length > 0) {
            return error.body.output.errors[0].message;
        }
        if (error?.message) {
            return error.message;
        }
        return 'An unexpected error occurred.';
    }
}