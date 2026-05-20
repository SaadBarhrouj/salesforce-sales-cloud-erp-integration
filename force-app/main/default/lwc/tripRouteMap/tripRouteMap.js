import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue }    from 'lightning/uiRecordApi';
import OPPORTUNITY_DISTANCE_DRIVING from '@salesforce/schema/Opportunity.Distance_Driving_Route_km__c';
import OPPORTUNITY_DISTANCE_STRAIGHT from '@salesforce/schema/Opportunity.Distance_Straight_Line_km__c';
import OPPORTUNITY_DURATION_TRIP from '@salesforce/schema/Opportunity.Duration_Trip_Minutes__c';

const OPPORTUNITY_FIELDS = [
    OPPORTUNITY_DISTANCE_DRIVING,
    OPPORTUNITY_DISTANCE_STRAIGHT,
    OPPORTUNITY_DURATION_TRIP,
];

const OPTIONAL_FIELDS = [
    'Opportunity.Default_Agency__r.Name',
    'Opportunity.Default_Agency__r.Latitude',
    'Opportunity.Default_Agency__r.Longitude',
    'Opportunity.Delivery_Site__r.Name',
    'Opportunity.Delivery_Site__r.Latitude',
    'Opportunity.Delivery_Site__r.Longitude'
];

export default class TripRouteMap extends LightningElement {

    @api recordId;
    @api mapHeight          = 400;
    @api hideRoutePanel     = false;
    @api hideDirectionsLink = false;
    @api mapTitle           = 'Route Map';
    @api hideIcon           = false;

    // Manual Data Ingestion for Configurator
    @api manualDepartureLat;
    @api manualDepartureLng;
    @api manualDepartureName;
    @api manualDestinationLat;
    @api manualDestinationLng;
    @api manualDestinationName;
    @api manualDistance;

    get computedIconName() {
        return this.hideIcon ? undefined : 'action:map';
    }

    @wire(getRecord, {
        recordId       : '$recordId',
        fields         : OPPORTUNITY_FIELDS,
        optionalFields : OPTIONAL_FIELDS
    })
    record;

    // Mode detection
    get isManualMode()      { return !this.recordId; }
    get isRecordMode()      { return !!this.recordId; }

    get showRoutePanel()    { return !this.hideRoutePanel;     }
    get showDirectionsLink(){ return !this.hideDirectionsLink; }

    get isLoading()    { return this.isRecordMode && (!this.record?.data && !this.record?.error); }
    get hasError()     { return !!this.record?.error; }
    get isIncomplete() { return !this._hasAllCoords; }

    get distance() {
        if (this.isManualMode) return this.manualDistance;
        
        // Priority: Driving Distance > Straight Line Distance
        const drivingDistance = this._val(OPPORTUNITY_DISTANCE_DRIVING);
        if (drivingDistance != null) {
            return drivingDistance;
        }
        
        return this._val(OPPORTUNITY_DISTANCE_STRAIGHT);
    }

    get durationMinutes() {
        if (this.isManualMode) return null;
        return this._val(OPPORTUNITY_DURATION_TRIP);
    }

    get formattedDuration() {
        const d = this.durationMinutes;
        if (d == null) return '— min';
        return `${Math.round(d)} min`;
    }

    get isEstimated() {
        // Estimated if only straight-line distance is available (no driving distance)
        if (this.isManualMode) return false;
        const drivingDistance = this._val(OPPORTUNITY_DISTANCE_DRIVING);
        const straightDistance = this._val(OPPORTUNITY_DISTANCE_STRAIGHT);
        return drivingDistance == null && straightDistance != null;
    }

    get direction() {
        return 'Delivery';
    }

    get departureName() {
        if (this.isManualMode) return this.manualDepartureName || 'Departure';
        return this._val('Opportunity.Default_Agency__r.Name') || 'Departure';
    }

    get departureLat() {
        if (this.isManualMode) return this.manualDepartureLat;
        return this._val('Opportunity.Default_Agency__r.Latitude');
    }

    get departureLng() {
        if (this.isManualMode) return this.manualDepartureLng;
        return this._val('Opportunity.Default_Agency__r.Longitude');
    }

    // Destination
    get destinationName() {
        if (this.isManualMode) return this.manualDestinationName || 'Destination';
        return this._val('Opportunity.Delivery_Site__r.Name') || 'Destination';
    }

    get destinationLat() {
        if (this.isManualMode) return this.manualDestinationLat;
        return this._val('Opportunity.Delivery_Site__r.Latitude');
    }

    get destinationLng() {
        if (this.isManualMode) return this.manualDestinationLng;
        return this._val('Opportunity.Delivery_Site__r.Longitude');
    }

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

    get googleMapsDirectionsUrl() {
        return 'https://www.google.com/maps/dir/?api=1'
            + `&origin=${this.departureLat},${this.departureLng}`
            + `&destination=${this.destinationLat},${this.destinationLng}`
            + '&travelmode=driving';
    }

    _val(field) {
        return getFieldValue(this.record?.data, field);
    }
}