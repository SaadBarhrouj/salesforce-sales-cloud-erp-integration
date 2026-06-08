/**
 * @description Domain Service class to calculate transport trips.
 * Picks the BinPacking scenario with the LOWEST total transport cost
 * (cost = sum over bins of price(zone, truck, distance)).
 */
public inherited sharing class TripService {

    // ========== CONSTANTS ==========

    /**
     * Default ISO country code used to resolve transport zones and rates.
     */
    private static final String DEFAULT_COUNTRY_CODE = 'MA';
    /**
     * Optimization mode that minimizes the number of bins used.
     */
    private static final String OBJECTIVE_MIN_BINS  = 'bins_number';
    /**
     * Optimization mode that minimizes wasted space.
     */
    private static final String OBJECTIVE_MIN_WASTE = 'bins_utilization';

    /**
     * Direction mode for delivery-only trips.
     */
    private static final String DIRECTION_DELIVERY = 'Delivery';
    /**
     * Direction mode for pickup-only trips.
     */
    private static final String DIRECTION_PICKUP   = 'Pickup';
    /**
     * Direction mode for combined delivery and pickup trips.
     */
    private static final String DIRECTION_BOTH     = 'Delivery_Pickup';

    /**
     * Exception type raised for trip calculation failures.
     */
    public class TripException extends Exception {}

    // ========== CPQ DTOs (FOR LWC COMMUNICATION) ==========

    /**
     * DTO representing a CPQ line item received from the LWC.
     */
    public class CPQItem {
        public String productId;
        public Integer quantity;
        public Decimal w;
        public Decimal h;
        public Decimal d;
        public Decimal weight;
        public List<CPQOption> options;
    }

    /**
     * DTO representing a selectable option attached to a CPQ line item.
     */
    public class CPQOption {
        public Boolean isSelected;
        public Integer quantity;
        public Decimal weight;
        public Decimal w;
        public Decimal h;
        public Decimal d;
    }

    /**
     * @description Internal value object — a fully priced candidate solution.
     */
    @TestVisible
    private class PricedSolution {
        Decimal totalCost = 0;
        String objective;
        @TestVisible
        List<Trip__c> trips = new List<Trip__c>();
    }

    // ========== PUBLIC BUSINESS METHODS ==========

    /**
     * @description Entry point for LWC. Generates trips and selects the cheapest packing solution.
     * @param opportunityId Parent Opportunity ID.
     * @param agencyId Departure agency Location Id (current LWC selection); falls back to Opportunity.Default_Agency__c.
     * @param deliverySiteId Delivery Location Id (current LWC selection); falls back to Opportunity.Delivery_Site__c.
     * @param urgency Transport priority.
     * @param cpqItemsJson JSON string of CPQ items.
     * @param directionMode One of 'Delivery' (default), 'Pickup', 'Both'. For rental opportunities the
     *        LWC asks the user which direction(s) of trips to generate. 'Both' runs the packing twice
     *        and concatenates the resulting Trip__c lists, one set per direction.
     * @return List of Trip__c records ready for review or insertion.
     */
    public static List<Trip__c> calculateTripsWithCPQItems(
        Id opportunityId,
        Id agencyId,
        Id deliverySiteId,
        String urgency,
        String cpqItemsJson,
        String directionMode
    ) {
        try {
            validateInputs(opportunityId, cpqItemsJson);

            String mode = normalizeDirectionMode(directionMode);

            // 0. Resolve agency / delivery site (LWC values win, Opportunity record is the fallback)
            Id resolvedAgencyId = agencyId;
            Id resolvedDeliveryId = deliverySiteId;
            if (resolvedAgencyId == null || resolvedDeliveryId == null) {
                Opportunity opp = OpportunityDAO.getById(opportunityId);
                if (opp == null) { throw new TripException('Opportunity not found: ' + opportunityId); }
                if (resolvedAgencyId == null)   { resolvedAgencyId   = opp.Default_Agency__c; }
                if (resolvedDeliveryId == null) { resolvedDeliveryId = opp.Delivery_Site__c; }
            }
            if (resolvedAgencyId == null || resolvedDeliveryId == null) {
                throw new TripException('Departure agency and delivery site are required.');
            }

            // Collectors flushed in a single DML batch at the very end — after every callout.
            // Apex forbids DML between callouts, so the distance log, the distance cache write,
            // and all bin-packing logs are deferred here rather than committed inline.
            List<IntegrationLoggerService.LogCalloutRequest> accumulatedLogs = new List<IntegrationLoggerService.LogCalloutRequest>();
            List<Distance_Cache__c> pendingCacheWrites = new List<Distance_Cache__c>();

            // 1. Distance: cache first, OpenRouteService on miss
            Decimal distanceKm = resolveDistance(resolvedAgencyId, resolvedDeliveryId, opportunityId, accumulatedLogs, pendingCacheWrites);
            if (distanceKm == null) {
                throw new TripException('Unable to resolve driving distance for the selected route.');
            }

            // 2. Zone derived from distance (CMDT)
            Transport_Zone__mdt zone = resolveZone(distanceKm, DEFAULT_COUNTRY_CODE);
            if (zone == null) {
                throw new TripException('No Transport_Zone__mdt matches distance ' + distanceKm + ' km for country ' + DEFAULT_COUNTRY_CODE);
            }

            // 3. Build pricing table once: Truck_Code -> Transport_Rate__mdt for the resolved zone
            Map<String, Transport_Rate__mdt> rateByTruck = buildRateMap(DEFAULT_COUNTRY_CODE, zone.Zone_Code__c);
            if (rateByTruck.isEmpty()) {
                throw new TripException('No Transport_Rate__mdt configured for zone ' + zone.Zone_Code__c + ' in country ' + DEFAULT_COUNTRY_CODE);
            }

            // 4. Parse CPQ items, exclude Service-typed products from packing
            List<CPQItem> cpqItems = (List<CPQItem>) JSON.deserialize(cpqItemsJson, List<CPQItem>.class);
            Set<Id> serviceIds = collectServiceIds(cpqItems);
            List<BinPackingAPI.ItemRequest> items = buildItemsFromCPQ(cpqItems, serviceIds);
            if (items.isEmpty()) { throw new TripException('No valid items found for transport calculation.'); }

            // Restrict the truck fleet to trucks that have a rate in this zone (otherwise we'd be packing trucks we can't price)
            List<BinPackingAPI.BinRequest> bins = fetchTrucksFromMetadata(rateByTruck.keySet());
            if (bins.isEmpty()) {
                throw new TripException('No truck templates with pricing available for zone ' + zone.Zone_Code__c);
            }

            Map<String, BinPackingAPI.BinRequest> binByCode = new Map<String, BinPackingAPI.BinRequest>();
            for (BinPackingAPI.BinRequest b : bins) { binByCode.put(b.id, b); }

            // 5. Direction branching — Both runs the packing twice (delivery + pickup) and concatenates.
            //    All callouts happen first; DML (logs + cache) is deferred to the end
            //    so the Apex "no DML between callouts" rule is never violated.
            List<Trip__c> output = new List<Trip__c>();
            if (mode == DIRECTION_BOTH) {
                output.addAll(calculateForDirection(DIRECTION_DELIVERY, items, bins, rateByTruck, binByCode, distanceKm, zone, opportunityId, accumulatedLogs));
                output.addAll(calculateForDirection(DIRECTION_PICKUP,   items, bins, rateByTruck, binByCode, distanceKm, zone, opportunityId, accumulatedLogs));
            } else {
                output.addAll(calculateForDirection(mode, items, bins, rateByTruck, binByCode, distanceKm, zone, opportunityId, accumulatedLogs));
            }

            // 6. Single DML batch, AFTER every callout — callout logs first, then the distance
            //    cache write. The direction-mode choice is persisted later in the wizard's
            //    final-save step, not here.
            if (!accumulatedLogs.isEmpty()) { IntegrationLoggerService.logCallouts(accumulatedLogs); }
            if (!pendingCacheWrites.isEmpty()) { DistanceCacheDAO.upsertCaches(pendingCacheWrites); }

            return output;

        } catch (TripException te) {
            throw te;
        } catch (Exception e) {
            throw new TripException('Trip Service Error: ' + e.getMessage());
        }
    }

    /**
     * @description Runs the two packing objectives (minBins + minWaste) for a single direction,
     * picks the cheapest priced solution, and stamps every resulting Trip__c with the given direction.
     * Log requests are appended to {@code accumulatedLogs} for a single end-of-transaction DML insert
     * — never inserted here, otherwise a subsequent direction's callouts would violate the
     * "no DML between callouts" rule and fail with CalloutException.
     * @param direction the trip direction to stamp on each generated Trip__c
     * @param items the items to pack
     * @param bins the available truck templates
     * @param rateByTruck map of truck code to its transport rate
     * @param distanceKm the route distance in kilometers
     * @param zone the resolved transport zone
     * @param opportunityId the parent Opportunity Id
     * @param accumulatedLogs collector for callout log requests to insert later
     * @return the cheapest priced solution's Trip__c list for this direction
     */
    private static List<Trip__c> calculateForDirection(
        String direction,
        List<BinPackingAPI.ItemRequest> items,
        List<BinPackingAPI.BinRequest> bins,
        Map<String, Transport_Rate__mdt> rateByTruck,
        Map<String, BinPackingAPI.BinRequest> binByCode,
        Decimal distanceKm,
        Transport_Zone__mdt zone,
        Id opportunityId,
        List<IntegrationLoggerService.LogCalloutRequest> accumulatedLogs
    ) {
        BinPackingAPI.PackingResult resMinBins  = BinPackingAPI.callPackingApi(buildRequest(OBJECTIVE_MIN_BINS,  items, bins), opportunityId);
        BinPackingAPI.PackingResult resMinWaste = BinPackingAPI.callPackingApi(buildRequest(OBJECTIVE_MIN_WASTE, items, bins), opportunityId);

        if (resMinBins.logRequest  != null) { accumulatedLogs.add(resMinBins.logRequest); }
        if (resMinWaste.logRequest != null) { accumulatedLogs.add(resMinWaste.logRequest); }

        List<PricedSolution> candidates = new List<PricedSolution>();
        if (resMinBins.isSuccess) {
            PricedSolution s = priceSolution(resMinBins.responseBody, rateByTruck, binByCode, distanceKm, zone, opportunityId, direction);
            if (s != null) { s.objective = OBJECTIVE_MIN_BINS;  candidates.add(s); }
        }
        if (resMinWaste.isSuccess) {
            PricedSolution s = priceSolution(resMinWaste.responseBody, rateByTruck, binByCode, distanceKm, zone, opportunityId, direction);
            if (s != null) { s.objective = OBJECTIVE_MIN_WASTE; candidates.add(s); }
        }

        if (candidates.isEmpty()) {
            throw new TripException('The bin-packing service could not generate a valid packing solution for direction ' + direction + '.');
        }

        PricedSolution winner = candidates[0];
        for (Integer i = 1; i < candidates.size(); i++) {
            if (candidates[i].totalCost < winner.totalCost) { winner = candidates[i]; }
        }
        return winner.trips;
    }

    /**
     * Normalizes a raw direction value to a supported direction mode constant.
     * @param raw the raw direction value from the LWC
     * @return a supported direction mode, defaulting to delivery
     */
    private static String normalizeDirectionMode(String raw) {
        if (String.isBlank(raw)) { return DIRECTION_DELIVERY; }
        if (raw == DIRECTION_PICKUP || raw == DIRECTION_BOTH || raw == DIRECTION_DELIVERY) { return raw; }
        return DIRECTION_DELIVERY;
    }

    /**
     * Collects the Ids of Service-typed products among the given CPQ items.
     * @param cpqItems the CPQ items to inspect
     * @return the set of product Ids that are Service-typed
     */
    private static Set<Id> collectServiceIds(List<CPQItem> cpqItems) {
        Set<Id> productIds = new Set<Id>();
        for (CPQItem c : cpqItems) {
            if (c.productId != null) {
                try {
                    productIds.add((Id) c.productId);
                } catch (Exception ignore) {
                    // Skip values that are not valid Ids.
                    continue;
                }
            }
        }
        return Product2DAO.getServiceIdsFromIds(productIds);
    }

    // ========== STEP 1: DISTANCE ==========

    /**
     * @description Returns driving distance in km. Uses Distance_Cache__c first; on miss calls
     * OpenRouteService. The callout log and the new cache record are appended to the supplied
     * collectors for a single end-of-transaction DML flush — never committed here, otherwise the
     * subsequent bin-packing callouts would violate the Apex "no DML between callouts" rule.
     * Returns null if no usable distance can be obtained.
     * @param agencyId the departure agency Location Id
     * @param deliveryId the delivery site Location Id
     * @param opportunityId the parent Opportunity Id
     * @param accumulatedLogs collector for the OpenRouteService callout log request
     * @param pendingCacheWrites collector for the Distance_Cache__c record to upsert later
     * @return the driving distance in kilometers, or null if unavailable
     */
    private static Decimal resolveDistance(
        Id agencyId,
        Id deliveryId,
        Id opportunityId,
        List<IntegrationLoggerService.LogCalloutRequest> accumulatedLogs,
        List<Distance_Cache__c> pendingCacheWrites
    ) {
        String cacheKey = String.valueOf(agencyId) + '_' + String.valueOf(deliveryId);
        Map<String, Distance_Cache__c> cached = DistanceCacheDAO.getByCacheKeys(new Set<String>{ cacheKey });
        if (cached.containsKey(cacheKey) && cached.get(cacheKey).Distance_Km__c != null) {
            return cached.get(cacheKey).Distance_Km__c;
        }

        Map<Id, Schema.Location> locs = LocationDAO.getByIds(new Set<Id>{ agencyId, deliveryId });
        Schema.Location origin = locs.get(agencyId);
        Schema.Location destination = locs.get(deliveryId);
        if (origin == null || destination == null
            || origin.Latitude == null || origin.Longitude == null
            || destination.Latitude == null || destination.Longitude == null) {
            return null;
        }

        RouteCalculationService.RouteResult api = RouteCalculationService.callOpenRouteService(origin, destination, opportunityId);
        if (api.logRequest != null) {
            accumulatedLogs.add(api.logRequest);
        }
        if (!api.isSuccess || api.distanceKm == null) {
            return null;
        }

        pendingCacheWrites.add(new Distance_Cache__c(
            Cache_Key__c = cacheKey,
            Origin_Location__c = origin.Id,
            Destination_Location__c = destination.Id,
            Distance_Km__c = api.distanceKm,
            Duration_Minutes__c = api.durationMinutes
        ));
        return api.distanceKm;
    }

    // ========== STEP 2: ZONE ==========

    /**
     * @description Picks the Transport_Zone__mdt whose distance bracket contains `distanceKm`.
     * Semantics follow the field documentation: Min_Distance_Km__c <= distance < Max_Distance_Km__c.
     * @param distanceKm the route distance in kilometers
     * @param countryCode the ISO country code to match
     * @return the matching transport zone, or null if none matches
     */
    private static Transport_Zone__mdt resolveZone(Decimal distanceKm, String countryCode) {
        for (Transport_Zone__mdt z : Transport_Zone__mdt.getAll().values()) {
            if (z.Country_Code__c != countryCode) { continue; }
            Decimal lo = z.Min_Distance_Km__c;
            Decimal hi = z.Max_Distance_Km__c;
            if (lo == null || hi == null) { continue; }
            if (distanceKm >= lo && distanceKm < hi) { return z; }
        }
        return null;
    }

    // ========== STEP 3: TRUCK FLEET ==========

    /**
     * @description Loads truck templates from CMDT, optionally restricted to a set of truck codes.
     * @param allowedCodes the truck codes to include, or null/empty to include all
     * @return the list of truck bin requests
     */
    private static List<BinPackingAPI.BinRequest> fetchTrucksFromMetadata(Set<String> allowedCodes) {
        List<BinPackingAPI.BinRequest> bins = new List<BinPackingAPI.BinRequest>();
        for (Truck_Type__mdt t : Truck_Type__mdt.getAll().values()) {
            if (allowedCodes != null && !allowedCodes.isEmpty() && !allowedCodes.contains(t.Truck_Code__c)) {
                continue;
            }
            BinPackingAPI.BinRequest b = new BinPackingAPI.BinRequest();
            b.id = t.Truck_Code__c;
            b.w = t.Width_cm__c;
            b.h = t.Height_cm__c;
            b.d = t.Depth_cm__c;
            b.max_wg = t.Max_Weight_Kg__c;
            b.q = (t.Quantity__c != null) ? Integer.valueOf(t.Quantity__c) : 5;
            bins.add(b);
        }
        return bins;
    }

    // ========== STEP 4 & 5: COST CALCULATION + OPTIMIZATION ==========

    /**
     * @description Build Truck_Code -> Transport_Rate__mdt map for the active country/zone.
     * @param countryCode the ISO country code to match
     * @param zoneCode the transport zone code to match
     * @return map of truck code to its transport rate for the country/zone
     */
    private static Map<String, Transport_Rate__mdt> buildRateMap(String countryCode, String zoneCode) {
        Map<String, Transport_Rate__mdt> result = new Map<String, Transport_Rate__mdt>();
        for (Transport_Rate__mdt r : Transport_Rate__mdt.getAll().values()) {
            if (r.Country_Code__c != countryCode) { continue; }
            if (r.Zone_Code__c != zoneCode) { continue; }
            result.put(r.Truck_Code__c, r);
        }
        return result;
    }

    /**
     * @description Per-trip price = max(Minimum_Price, Base_Price + max(0, distance - Included_Km) * Price_Per_Extra_Km).
     * @param rate the transport rate to apply
     * @param distanceKm the route distance in kilometers
     * @return the computed per-trip cost, scaled to two decimals
     */
    @TestVisible
    private static Decimal computeTripCost(Transport_Rate__mdt rate, Decimal distanceKm) {
        Decimal extraKm = distanceKm - (rate.Included_Km__c != null ? rate.Included_Km__c : 0);
        if (extraKm < 0) { extraKm = 0; }
        Decimal raw = (rate.Base_Price__c != null ? rate.Base_Price__c : 0)
                    + extraKm * (rate.Price_Per_Extra_Km__c != null ? rate.Price_Per_Extra_Km__c : 0);
        Decimal floor = (rate.Minimum_Price__c != null) ? rate.Minimum_Price__c : 0;
        return (raw < floor ? floor : raw).setScale(2);
    }

    /**
     * @description Parses a 3DBinPacking response, prices each bin against the rate table, and
     * builds the Trip__c list. Returns null if any bin's truck has no matching rate (the
     * solution is unpriceable so it must not win the cost comparison).
     * @param jsonResponse the raw bin-packing service response body
     * @param rateByTruck map of truck code to its transport rate
     * @param distanceKm the route distance in kilometers
     * @param zone the resolved transport zone
     * @param opportunityId the parent Opportunity Id
     * @param direction the trip direction to stamp on each Trip__c
     * @return the priced solution, or null if it cannot be priced
     */
    @TestVisible
    private static PricedSolution priceSolution(
        String jsonResponse,
        Map<String, Transport_Rate__mdt> rateByTruck,
        Map<String, BinPackingAPI.BinRequest> binByCode,
        Decimal distanceKm,
        Transport_Zone__mdt zone,
        Id opportunityId,
        String direction
    ) {
        Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
        Map<String, Object> response = (Map<String, Object>) root.get('response');
        if (response == null) { return null; }

        List<Object> binsData = (List<Object>) response.get('bins_packed');
        if (binsData == null || binsData.isEmpty()) { return null; }

        // not_packed_items is intentionally ignored: partial packs remain valid, priceable
        // scenarios (parity with the previous allowUnplaced = true behavior).
        PricedSolution sol = new PricedSolution();
        for (Object obj : binsData) {
            Map<String, Object> binWrapper = (Map<String, Object>) obj;
            Map<String, Object> binData = (Map<String, Object>) binWrapper.get('bin_data');
            if (binData == null) { return null; }

            String truckCode = (String) binData.get('id');
            Transport_Rate__mdt rate = rateByTruck.get(truckCode);
            if (rate == null) {
                // Truck without a published rate -> can't price this scenario fairly
                return null;
            }

            Decimal cost = computeTripCost(rate, distanceKm);
            sol.totalCost += cost;

            Trip__c trip = new Trip__c();
            trip.Opportunity__c           = opportunityId;
            trip.Direction__c             = direction;
            trip.Truck_Type__c            = truckCode;
            trip.Transport_Zone__c        = zone.Zone_Code__c;
            trip.Country_Code__c          = DEFAULT_COUNTRY_CODE;
            trip.Distance_Km__c           = distanceKm;
            trip.Total_Weight_Kg__c       = toDecimal(resolveLoadedWeight(binData));
            trip.System_Price__c          = cost;
            trip.Final_Price__c           = cost;
            trip.Rate_Currency__c         = rate.Currency_Code__c;
            trip.Bin_Visualization_URL__c = (String) binWrapper.get('image_complete');
            trip.Packing_Geometry__c      = buildPackingGeometry(binData, binWrapper, binByCode.get(truckCode));
            sol.trips.add(trip);
        }
        return sol;
    }

    /**
     * @description Returns the loaded cargo weight from a bin_data map. The provider's `weight`
     * is the total packed-item weight (confirmed against the live API: 4 items x 10kg -> weight=40,
     * while used_weight returned a different, mis-scaled value). Used for Total_Weight_Kg__c.
     * @param binData the bin_data map from a bins_packed entry
     * @return the cargo weight value, or null if absent
     */
    private static Object resolveLoadedWeight(Map<String, Object> binData) {
        Object w = binData.get('weight');
        return (w != null) ? w : binData.get('used_weight');
    }

    /**
     * @description Builds the 3D loading geometry JSON for one packed bin, consumed by the
     * binPacking3dViewerGl component. Bin dimensions come from the Truck_Type__mdt request
     * (guaranteed present) with the provider's bin_data as fallback; items are trimmed to
     * id + coordinates to keep the stored payload small. Returns null when there is no
     * placement geometry to render.
     * @param binData the bin_data map from a bins_packed entry
     * @param binWrapper the full bins_packed entry (carries the items array)
     * @param binReq the matching truck template request, or null
     * @return serialized geometry JSON, or null if no items are present
     */
    private static String buildPackingGeometry(
        Map<String, Object> binData,
        Map<String, Object> binWrapper,
        BinPackingAPI.BinRequest binReq
    ) {
        List<Object> rawItems = (List<Object>) binWrapper.get('items');
        if (rawItems == null || rawItems.isEmpty()) { return null; }

        List<Object> items = new List<Object>();
        for (Object obj : rawItems) {
            Map<String, Object> it = (Map<String, Object>) obj;
            if (it.get('coordinates') == null) { continue; }
            items.add(new Map<String, Object>{
                'id'          => it.get('id'),
                'coordinates' => it.get('coordinates')
            });
        }
        if (items.isEmpty()) { return null; }

        Map<String, Object> geometry = new Map<String, Object>{
            'bin_data' => new Map<String, Object>{
                'id'          => binData.get('id'),
                'w'           => (binReq != null) ? binReq.w : binData.get('w'),
                'h'           => (binReq != null) ? binReq.h : binData.get('h'),
                'd'           => (binReq != null) ? binReq.d : binData.get('d'),
                'used_space'  => binData.get('used_space'),
                'used_weight' => resolveLoadedWeight(binData)
            },
            'items' => items
        };
        return JSON.serialize(geometry, true);
    }

    // ========== HELPERS ==========

    /**
     * Builds bin-packing item requests from CPQ items, excluding Service-typed products.
     * @param cpqItems the CPQ items to convert
     * @param serviceProductIds Ids of Service-typed products to exclude from packing
     * @return the list of packable item requests
     */
    private static List<BinPackingAPI.ItemRequest> buildItemsFromCPQ(List<CPQItem> cpqItems, Set<Id> serviceProductIds) {
        List<BinPackingAPI.ItemRequest> items = new List<BinPackingAPI.ItemRequest>();
        for (CPQItem cpq : cpqItems) {
            if (cpq.w == null || cpq.h == null) { continue; }
            // Service-typed products are intangible (labor, setup, training, etc.) — they don't get packed.
            if (cpq.productId != null && serviceProductIds != null && serviceProductIds.contains((Id) cpq.productId)) { continue; }

            BinPackingAPI.ItemRequest it = new BinPackingAPI.ItemRequest();
            it.id = cpq.productId;
            it.w = cpq.w; it.h = cpq.h; it.d = cpq.d;
            it.wg = cpq.weight;
            it.q = cpq.quantity;
            it.vr = 1;
            items.add(it);

            if (cpq.options != null) {
                for (CPQOption opt : cpq.options) {
                    if (opt.isSelected && opt.w != null) {
                        BinPackingAPI.ItemRequest oit = new BinPackingAPI.ItemRequest();
                        oit.id = 'OPT-' + Crypto.getRandomInteger();
                        oit.w = opt.w; oit.h = opt.h; oit.d = opt.d;
                        oit.wg = opt.weight;
                        oit.q = opt.quantity;
                        oit.vr = 1;
                        items.add(oit);
                    }
                }
            }
        }
        return items;
    }

    /**
     * Builds a bin-packing request for the given objective.
     * @param objective the packing objective
     * @param items the items to pack
     * @param bins the available truck bins
     * @return the assembled packing request
     */
    private static BinPackingAPI.PackingRequest buildRequest(String objective, List<BinPackingAPI.ItemRequest> items, List<BinPackingAPI.BinRequest> bins) {
        BinPackingAPI.PackingRequest req = new BinPackingAPI.PackingRequest();
        req.params.optimization_mode = objective;
        req.items = items;
        req.bins = bins;
        return req;
    }

    /**
     * Validates that the required inputs for trip calculation are present.
     * @param opportunityId the parent Opportunity Id
     * @param json the CPQ items JSON string
     */
    private static void validateInputs(Id opportunityId, String json) {
        if (opportunityId == null || String.isBlank(json)) {
            throw new TripException('Opportunity ID and Items JSON are required.');
        }
    }

    /**
     * Coerces an untyped JSON value into a Decimal.
     * @param value the value to convert
     * @return the value as a Decimal, or null if it cannot be converted
     */
    private static Decimal toDecimal(Object value) {
        if (value == null) { return null; }
        if (value instanceof Decimal) { return (Decimal) value; }
        if (value instanceof Double)  { return Decimal.valueOf((Double) value); }
        if (value instanceof Integer) { return Decimal.valueOf((Integer) value); }
        try {
            return Decimal.valueOf(String.valueOf(value));
        } catch (Exception e) {
            return null;
        }
    }
}