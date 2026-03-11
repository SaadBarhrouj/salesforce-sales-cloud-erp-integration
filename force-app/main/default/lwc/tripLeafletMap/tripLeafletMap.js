import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';

import LEAFLET from '@salesforce/resourceUrl/leaflet';

// Schema imports — Trip core fields
import DISTANCE_KM_FIELD from '@salesforce/schema/Trip__c.Distance_Km__c';
import DIRECTION_FIELD   from '@salesforce/schema/Trip__c.Direction__c';

// Schema imports — Departure Location
import DEP_NAME_FIELD from '@salesforce/schema/Trip__c.Departure_Location__r.Name';
import DEP_LAT_FIELD  from '@salesforce/schema/Trip__c.Departure_Location__r.Latitude';
import DEP_LNG_FIELD  from '@salesforce/schema/Trip__c.Departure_Location__r.Longitude';
import DEP_TYPE_FIELD from '@salesforce/schema/Trip__c.Departure_Location__r.LocationType';

// Schema imports — Destination Location
import DEST_NAME_FIELD from '@salesforce/schema/Trip__c.Destination_Location__r.Name';
import DEST_LAT_FIELD  from '@salesforce/schema/Trip__c.Destination_Location__r.Latitude';
import DEST_LNG_FIELD  from '@salesforce/schema/Trip__c.Destination_Location__r.Longitude';
import DEST_TYPE_FIELD from '@salesforce/schema/Trip__c.Destination_Location__r.LocationType';

const TRIP_FIELDS = [DISTANCE_KM_FIELD, DIRECTION_FIELD];
const TRIP_OPTIONAL_FIELDS = [
    DEP_NAME_FIELD, DEP_LAT_FIELD, DEP_LNG_FIELD, DEP_TYPE_FIELD,
    DEST_NAME_FIELD, DEST_LAT_FIELD, DEST_LNG_FIELD, DEST_TYPE_FIELD
];

const MARKER_COLORS = Object.freeze({
    Warehouse: '#1589ee',
    Site: '#e74c3c'
});
const DEFAULT_COLOR = '#2ecc71';

// OSRM free routing API
const OSRM_BASE = 'https://router.project-osrm.org/route/v1/driving';

export default class TripLeafletMap extends LightningElement {

    @api recordId;
    @api mapHeight = 400;
    @api hideRoutePanel = false;

    _leafletInitialized = false;
    _isInitializing = false;
    _map = null;
    _layerGroup = null;

    @track formattedDuration = null;

    // ── LDS Wire ──
    @wire(getRecord, {
        recordId: '$recordId',
        fields: TRIP_FIELDS,
        optionalFields: TRIP_OPTIONAL_FIELDS
    })
    wiredRecord(result) {
        this.record = result;
        if (result.data && this._leafletInitialized) {
            this._renderMap();
        }
    }
    record;

    // ── State ──
    get isLoading() { return !this.record?.data && !this.record?.error; }
    get hasError() { return !!this.record?.error; }
    get isIncomplete() { return !!this.record?.data && !this._hasAllCoords; }
    get showRoutePanel() { return !this.hideRoutePanel; }

    // ── Field accessors ──
    get distance() { return getFieldValue(this.record?.data, DISTANCE_KM_FIELD); }
    get direction() { return getFieldValue(this.record?.data, DIRECTION_FIELD); }

    get departureName() { return getFieldValue(this.record?.data, DEP_NAME_FIELD) || 'Departure'; }
    get departureLat() { return getFieldValue(this.record?.data, DEP_LAT_FIELD); }
    get departureLng() { return getFieldValue(this.record?.data, DEP_LNG_FIELD); }
    get departureType() { return getFieldValue(this.record?.data, DEP_TYPE_FIELD); }

    get destinationName() { return getFieldValue(this.record?.data, DEST_NAME_FIELD) || 'Destination'; }
    get destinationLat() { return getFieldValue(this.record?.data, DEST_LAT_FIELD); }
    get destinationLng() { return getFieldValue(this.record?.data, DEST_LNG_FIELD); }
    get destinationType() { return getFieldValue(this.record?.data, DEST_TYPE_FIELD); }

    get _hasAllCoords() {
        return this.departureLat != null && this.departureLng != null
            && this.destinationLat != null && this.destinationLng != null;
    }

    get formattedDistance() {
        const d = this.distance;
        if (d == null) return '— km';
        return `${Number(d).toFixed(1)} km`;
    }

    get mapContainerStyle() { return `height:${this.mapHeight}px`; }

    // ── Lifecycle ──
    renderedCallback() {
        if (this._leafletInitialized || this._isInitializing || !this._hasAllCoords) return;
        this._initLeaflet();
    }

    disconnectedCallback() {
        if (this._map) {
            this._map.remove();
            this._map = null;
        }
    }

    // ══════════════════════════════════════════
    // INIT LEAFLET
    // ══════════════════════════════════════════

    async _initLeaflet() {
        this._isInitializing = true;
        try {
            await Promise.all([
                loadScript(this, LEAFLET + '/leaflet.js'),
                loadStyle(this, LEAFLET + '/leaflet.css')
            ]);
            this._leafletInitialized = true;

            // FIX: Inject Leaflet CSS into Shadow DOM manually
            this._injectLeafletCSS();

            this._renderMap();
        } catch (error) {
            console.error('Leaflet init error', error);
        } finally {
            this._isInitializing = false;
        }
    }

    // ══════════════════════════════════════════
    // FIX: Shadow DOM CSS injection
    // ══════════════════════════════════════════

    _injectLeafletCSS() {
        const style = document.createElement('style');
        style.textContent = `
            .leaflet-container {
                width: 100% !important;
                height: 100% !important;
                z-index: 0;
                font-family: inherit;
            }
            .leaflet-tile-pane {
                opacity: 1 !important;
            }
            .leaflet-tile {
                visibility: visible !important;
            }
            .leaflet-control-zoom a {
                width: 30px !important;
                height: 30px !important;
                line-height: 30px !important;
                font-size: 16px !important;
                background: white !important;
                color: #333 !important;
                border-bottom: 1px solid #ccc !important;
            }
            .leaflet-control-attribution {
                font-size: 10px !important;
                background: rgba(255,255,255,0.8) !important;
            }
            .leaflet-popup-content-wrapper {
                border-radius: 8px !important;
                box-shadow: 0 3px 14px rgba(0,0,0,0.2) !important;
            }
            .leaflet-popup-content {
                margin: 10px 14px !important;
                font-size: 13px !important;
                line-height: 1.4 !important;
            }
            .distance-label {
                background: transparent !important;
                border: none !important;
            }
            .distance-label span {
                background: rgba(255,255,255,0.95);
                padding: 3px 10px;
                border-radius: 12px;
                font-size: 12px;
                font-weight: 700;
                color: #032d60;
                white-space: nowrap;
                box-shadow: 0 1px 4px rgba(0,0,0,0.25);
            }
            .arrow-div-icon {
                background: transparent !important;
                border: none !important;
            }
            .custom-marker-icon {
                background: transparent !important;
                border: none !important;
            }
            .marker-pin {
                width: 30px;
                height: 30px;
                border-radius: 50% 50% 50% 0;
                position: absolute;
                transform: rotate(-45deg);
                left: 50%;
                top: 50%;
                margin: -15px 0 0 -15px;
                display: flex;
                align-items: center;
                justify-content: center;
                box-shadow: 0 2px 6px rgba(0,0,0,0.3);
            }
            .marker-pin span {
                transform: rotate(45deg);
                color: white;
                font-weight: bold;
                font-size: 14px;
            }
        `;

        const container = this.refs.leafletMap;
        if (container && container.getRootNode()) {
            const root = container.getRootNode();
            if (root && root.appendChild) {
                root.appendChild(style);
            }
        }
    }

    // ══════════════════════════════════════════
    // RENDER MAP with OSRM real route
    // ══════════════════════════════════════════

    async _renderMap() {
        if (!this._hasAllCoords) return;

        const container = this.refs.leafletMap;
        if (!container) return;

        // Destroy previous map
        if (this._map) {
            this._map.remove();
            this._map = null;
        }

        const L = window.L;

        const depCoords = [this.departureLat, this.departureLng];
        const destCoords = [this.destinationLat, this.destinationLng];

        // ── Initialize map ──
        const map = L.map(container, {
            scrollWheelZoom: false,
            zoomControl: true
        });
        this._map = map;

        // ── Tile layer (OpenStreetMap) ──
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OSM</a>',
            maxZoom: 19,
            crossOrigin: true
        }).addTo(map);

        // ── Layer group for easy cleanup ──
        this._layerGroup = L.layerGroup().addTo(map);

        // ── Departure Marker ──
        const depColor = MARKER_COLORS[this.departureType] || DEFAULT_COLOR;
        this._addCustomMarker(L, depCoords, depColor, 'A',
            `<b>${this._escapeHtml(this.departureName)}</b><br/>` +
            `Type: ${this._escapeHtml(this.departureType || 'N/A')}<br/>` +
            `<span style="color:${depColor}">● Departure</span>`
        );

        // ── Destination Marker ──
        const destColor = MARKER_COLORS[this.destinationType] || DEFAULT_COLOR;
        this._addCustomMarker(L, destCoords, destColor, 'B',
            `<b>${this._escapeHtml(this.destinationName)}</b><br/>` +
            `Type: ${this._escapeHtml(this.destinationType || 'N/A')}<br/>` +
            `<span style="color:${destColor}">● Destination</span>`
        );

        // ── Fetch real route from OSRM ──
        try {
            const routeCoords = await this._fetchRoute(depCoords, destCoords);

            if (routeCoords && routeCoords.length > 0) {
                // Shadow polyline (border effect)
                L.polyline(routeCoords, {
                    color: '#1a237e',
                    weight: 7,
                    opacity: 0.3,
                    lineJoin: 'round'
                }).addTo(this._layerGroup);

                // Main route polyline
                L.polyline(routeCoords, {
                    color: '#1976D2',
                    weight: 4,
                    opacity: 0.9,
                    lineJoin: 'round',
                    lineCap: 'round'
                }).addTo(this._layerGroup);

                // Direction arrows along the route
                this._addRouteArrows(L, routeCoords);

                // Distance label at midpoint of route
                const midIdx = Math.floor(routeCoords.length / 2);
                this._addDistanceLabel(L, routeCoords[midIdx]);

                // Fit bounds to route
                const routeBounds = L.latLngBounds(routeCoords);
                map.fitBounds(routeBounds, { padding: [50, 50] });
            } else {
                // Fallback: straight dashed line
                this._drawFallbackLine(L, depCoords, destCoords);
            }
        } catch (err) {
            console.warn('OSRM route failed, using straight line:', err);
            this._drawFallbackLine(L, depCoords, destCoords);
        }

        // ── Force size recalculation ──
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => { map.invalidateSize(); }, 300);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => { map.invalidateSize(); }, 1000);
    }

    // ══════════════════════════════════════════
    // OSRM ROUTE FETCHING (FREE, NO API KEY)
    // ══════════════════════════════════════════

    async _fetchRoute(from, to) {
        // OSRM expects lng,lat (not lat,lng)
        const url = `${OSRM_BASE}/${from[1]},${from[0]};${to[1]},${to[0]}`
            + `?overview=full&geometries=geojson`;

        const response = await fetch(url);
        const data = await response.json();

        if (data.code === 'Ok' && data.routes && data.routes.length > 0) {
            const route = data.routes[0];

            // Parse duration
            const durSec = route.duration;
            const hours = Math.floor(durSec / 3600);
            const mins = Math.round((durSec % 3600) / 60);
            this.formattedDuration = hours > 0
                ? `${hours}h ${mins}min`
                : `${mins} min`;

            // Convert GeoJSON [lng, lat] → Leaflet [lat, lng]
            return route.geometry.coordinates.map(c => [c[1], c[0]]);
        }

        return null;
    }

    // ══════════════════════════════════════════
    // CUSTOM PIN MARKERS
    // ══════════════════════════════════════════

    _addCustomMarker(L, coords, color, label, popupHtml) {
        const icon = L.divIcon({
            className: 'custom-marker-icon',
            html: `<div class="marker-pin" style="background:${color}">
                       <span>${label}</span>
                   </div>`,
            iconSize: [30, 42],
            iconAnchor: [15, 42],
            popupAnchor: [0, -40]
        });

        L.marker(coords, { icon: icon })
            .addTo(this._layerGroup)
            .bindPopup(popupHtml);
    }

    // ══════════════════════════════════════════
    // DIRECTION ARROWS ALONG ROUTE
    // ══════════════════════════════════════════

    _addRouteArrows(L, routeCoords) {
        const totalPoints = routeCoords.length;
        if (totalPoints < 2) return;

        // Place an arrow every ~1/12th of the route
        const step = Math.max(1, Math.floor(totalPoints / 12));

        for (let i = step; i < totalPoints - 1; i += step) {
            const from = routeCoords[i - 1];
            const to = routeCoords[i];
            const angle = this._bearing(from, to);

            const arrowIcon = L.divIcon({
                className: 'arrow-div-icon',
                html: `<div style="
                    transform: rotate(${angle}deg);
                    font-size: 14px;
                    color: #0D47A1;
                    text-shadow: 0 0 3px white, 0 0 3px white, 0 0 3px white;
                    line-height: 20px;
                    text-align: center;
                ">➤</div>`,
                iconSize: [20, 20],
                iconAnchor: [10, 10]
            });

            L.marker(to, { icon: arrowIcon, interactive: false })
                .addTo(this._layerGroup);
        }
    }

    _bearing(from, to) {
        const toRad = (d) => d * Math.PI / 180;
        const lat1 = toRad(from[0]);
        const lat2 = toRad(to[0]);
        const dLng = toRad(to[1] - from[1]);

        const y = Math.sin(dLng) * Math.cos(lat2);
        const x = Math.cos(lat1) * Math.sin(lat2)
                - Math.sin(lat1) * Math.cos(lat2) * Math.cos(dLng);

        return (Math.atan2(y, x) * 180 / Math.PI + 360) % 360;
    }

    // ══════════════════════════════════════════
    // DISTANCE LABEL ON MAP
    // ══════════════════════════════════════════

    _addDistanceLabel(L, position) {
        const distText = this.formattedDistance;

        const icon = L.divIcon({
            className: 'distance-label',
            html: `<span>📏 ${this._escapeHtml(distText)}</span>`,
            iconSize: [100, 26],
            iconAnchor: [50, 13]
        });

        L.marker(position, { icon: icon, interactive: false })
            .addTo(this._layerGroup);
    }

    // ══════════════════════════════════════════
    // FALLBACK: STRAIGHT DASHED LINE
    // ══════════════════════════════════════════

    _drawFallbackLine(L, depCoords, destCoords) {
        L.polyline([depCoords, destCoords], {
            color: '#f44336',
            weight: 3,
            dashArray: '10, 8',
            opacity: 0.7
        }).addTo(this._layerGroup);

        this._addRouteArrows(L, [depCoords, destCoords]);

        const midLat = (depCoords[0] + destCoords[0]) / 2;
        const midLng = (depCoords[1] + destCoords[1]) / 2;
        this._addDistanceLabel(L, [midLat, midLng]);

        const bounds = L.latLngBounds([depCoords, destCoords]);
        this._map.fitBounds(bounds, { padding: [50, 50] });
    }

    // ══════════════════════════════════════════
    // UTILS
    // ══════════════════════════════════════════

    _escapeHtml(str) {
        if (!str) return '';
        const div = document.createElement('div');
        div.appendChild(document.createTextNode(str));
        return div.innerHTML;
    }
}