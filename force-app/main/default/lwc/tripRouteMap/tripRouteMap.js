/**
 * Interactive route map for Trip__c records.
 * Displays departure + destination markers with directional
 * route panel and distance from Trip__c.Distance_Km__c.
 * 100% LDS with spanning fields — zero Apex.
 */
import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue }    from 'lightning/uiRecordApi';

// Trip own fields
const TRIP_FIELDS = [
    'Trip__c.Distance_Km__c',
    'Trip__c.Direction__c'
];

// Trip optional + Location spanning fields
const OPTIONAL_FIELDS = [
    'Trip__c.Is_Distance_Estimated__c',
    'Trip__c.Departure_Location__r.Name',
    'Trip__c.Departure_Location__r.Latitude',
    'Trip__c.Departure_Location__r.Longitude',
    'Trip__c.Destination_Location__r.Name',
    'Trip__c.Destination_Location__r.Latitude',
    'Trip__c.Destination_Location__r.Longitude'
];

export default class TripRouteMap extends LightningElement {

    // App Builder properties
    @api recordId;
    @api mapHeight          = 380;
    @api hideRoutePanel     = false;
    @api hideDirectionsLink = false;

    // LDS wire
    @wire(getRecord, {
        recordId       : '$recordId',
        fields         : TRIP_FIELDS,
        optionalFields : OPTIONAL_FIELDS
    })
    record;

    // Inverted booleans
    get showRoutePanel()    { return !this.hideRoutePanel;     }
    get showDirectionsLink(){ return !this.hideDirectionsLink; }

    // State machine
    get isLoading()    { return !this.record?.data && !this.record?.error; }
    get hasError()     { return !!this.record?.error;                       }
    get isIncomplete() { return !!this.record?.data && !this._hasAllCoords; }

    // Trip field accessors
    get distance()    { return this._val('Trip__c.Distance_Km__c');            }
    get direction()   { return this._val('Trip__c.Direction__c');              }
    get isEstimated() { return this._val('Trip__c.Is_Distance_Estimated__c'); }

    // Departure Location accessors
    get departureName() {
        return this._val('Trip__c.Departure_Location__r.Name') || 'Departure';
    }
    get departureLat() {
        return this._val('Trip__c.Departure_Location__r.Latitude');
    }
    get departureLng() {
        return this._val('Trip__c.Departure_Location__r.Longitude');
    }

    // Destination Location accessors
    get destinationName() {
        return this._val('Trip__c.Destination_Location__r.Name') || 'Destination';
    }
    get destinationLat() {
        return this._val('Trip__c.Destination_Location__r.Latitude');
    }
    get destinationLng() {
        return this._val('Trip__c.Destination_Location__r.Longitude');
    }

    // Computed
    get _hasAllCoords() {
        return this.departureLat  != null
            && this.departureLng  != null
            && this.destinationLat != null
            && this.destinationLng != null;
    }

    get formattedDistance() {
        const d = this.distance;
        if (d == null) return '— km';
        return `${Number(d).toFixed(1)} km`;
    }

    get mapContainerStyle() { return `height:${this.mapHeight}px`; }

    // Two markers — standard red pins
    get mapMarkers() {
        if (!this._hasAllCoords) return [];

        return [
            {
                location    : { Latitude: this.departureLat, Longitude: this.departureLng },
                title       : this.departureName,
                description : 'Departure',
                icon        : 'standard:location'
            },
            {
                location    : { Latitude: this.destinationLat, Longitude: this.destinationLng },
                title       : this.destinationName,
                description : 'Destination',
                icon        : 'standard:location'
            }
        ];
    }

    // Google Maps driving directions URL
    get googleMapsDirectionsUrl() {
        return 'https://www.google.com/maps/dir/?api=1'
            + `&origin=${this.departureLat},${this.departureLng}`
            + `&destination=${this.destinationLat},${this.destinationLng}`
            + '&travelmode=driving';
    }

    // Helper
    _val(field) {
        return getFieldValue(this.record?.data, field);
    }
}