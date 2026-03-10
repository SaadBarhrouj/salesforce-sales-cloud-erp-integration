import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue }    from 'lightning/uiRecordApi';
import TRIP_DISTANCE_KM  from '@salesforce/schema/Trip__c.Distance_Km__c';
import TRIP_DIRECTION    from '@salesforce/schema/Trip__c.Direction__c';

// Trip own fields
const TRIP_FIELDS = [
    TRIP_DISTANCE_KM,
    TRIP_DIRECTION
];

const OPTIONAL_FIELDS = [
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
    get distance()    { return getFieldValue(this.record?.data, TRIP_DISTANCE_KM);  }
    get direction()   { return getFieldValue(this.record?.data, TRIP_DIRECTION);    }

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

    get departureDotClass()   { return this.direction === 'Delivery' ? 'dot dot--warehouse' : 'dot dot--client';    }
    get destinationDotClass() { return this.direction === 'Delivery' ? 'dot dot--client'    : 'dot dot--warehouse'; }
    get lineClass()           { return this.direction === 'Delivery' ? 'line'               : 'line line--pickup';   }

    get mapMarkers() {
        if (!this._hasAllCoords) return [];

        const isDelivery = this.direction === 'Delivery';

        const warehouseIcon = { url: 'https://maps.google.com/mapfiles/ms/icons/blue-dot.png'   };
        const customerIcon  = { url: 'https://maps.google.com/mapfiles/ms/icons/orange-dot.png' };

        const departureIcon   = isDelivery ? warehouseIcon : customerIcon;
        const destinationIcon = isDelivery ? customerIcon  : warehouseIcon;

        return [
            {
                location    : { Latitude: this.departureLat, Longitude: this.departureLng },
                title       : this.departureName,
                description : isDelivery ? 'Our warehouse (departure)' : 'Client site (departure)',
                mapIcon     : departureIcon
            },
            {
                location    : { Latitude: this.destinationLat, Longitude: this.destinationLng },
                title       : this.destinationName,
                description : isDelivery ? 'Client site (destination)' : 'Our warehouse (destination)',
                mapIcon     : destinationIcon
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