import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue }    from 'lightning/uiRecordApi';
import { ShowToastEvent }              from 'lightning/platformShowToastEvent';

// Field references
import NAME_FIELD      from '@salesforce/schema/Location.Name';
import LATITUDE_FIELD  from '@salesforce/schema/Location.Latitude';
import LONGITUDE_FIELD from '@salesforce/schema/Location.Longitude';
import LOCATION_TYPE   from '@salesforce/schema/Location.LocationType';

const CORE_FIELDS     = [NAME_FIELD, LATITUDE_FIELD, LONGITUDE_FIELD];
const OPTIONAL_FIELDS = [LOCATION_TYPE];

// Header icon per LocationType
const ICON_MAP = Object.freeze({
    Warehouse : 'utility:company',
    Site      : 'utility:location'
});
const DEFAULT_ICON = 'utility:location';

export default class LocationMapViewer extends LightningElement {

    // App Builder configurable properties
    @api recordId;
    @api zoomLevel          = 14;
    @api mapHeight          = 420;
    @api hideCoordinates    = false;
    @api hideGoogleMapsLink = false;

    // LDS wire
    @wire(getRecord, {
        recordId       : '$recordId',
        fields         : CORE_FIELDS,
        optionalFields : OPTIONAL_FIELDS
    })
    record;

    // Inverted boolean visibility
    get showCoordinates()    { return !this.hideCoordinates;    }
    get showGoogleMapsLink() { return !this.hideGoogleMapsLink; }

    // State machine — mutually exclusive
    get isLoading()      { return !this.record?.data && !this.record?.error; }
    get hasError()       { return !!this.record?.error;                       }
    get showEmptyState() { return !!this.record?.data && !this._hasCoords;    }

    // Field accessors
    get locationName() { return this._val(NAME_FIELD) || 'Location'; }
    get latitude()     { return this._val(LATITUDE_FIELD);           }
    get longitude()    { return this._val(LONGITUDE_FIELD);          }
    get locationType() { return this._val(LOCATION_TYPE);            }

    // Computed UI
    get _hasCoords() { return this.latitude != null && this.longitude != null; }
    get headerIcon() { return ICON_MAP[this.locationType] ?? DEFAULT_ICON;     }

    get formattedLatitude()  { return this.latitude?.toFixed(6) ?? '—';  }
    get formattedLongitude() { return this.longitude?.toFixed(6) ?? '—'; }

    get computedZoomLevel() {
        const z = parseInt(this.zoomLevel, 10);
        return Number.isNaN(z) ? 14 : Math.max(1, Math.min(20, z));
    }

    get mapContainerStyle() { return `height:${this.mapHeight}px`; }

    // Map marker — standard red pin
    get mapMarkers() {
        if (!this._hasCoords) { return []; }

        return [{
            location : {
                Latitude  : this.latitude,
                Longitude : this.longitude
            },
            title : this.locationName,
            icon  : 'standard:location'
        }];
    }

    get googleMapsUrl() {
        return `https://www.google.com/maps/search/?api=1&query=${this.latitude},${this.longitude}`;
    }

    // Copy GPS to clipboard
    handleCopyCoordinates() {
        const coords = `${this.latitude}, ${this.longitude}`;
        if (navigator?.clipboard?.writeText) {
            navigator.clipboard.writeText(coords)
                .then(() => this._toast('Copied ✓', `GPS: ${coords}`, 'success'))
                .catch(() => this._toast('GPS Coordinates', coords, 'info'));
        } else {
            this._toast('GPS Coordinates', coords, 'info');
        }
    }

    // Helpers
    _val(fieldRef) {
        return getFieldValue(this.record?.data, fieldRef);
    }

    _toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}