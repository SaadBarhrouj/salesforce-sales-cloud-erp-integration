/**
 * @description Service layer for Opportunity save operations.
 * Orchestrates the creation of OpportunityLineItems, Opportunity transport field updates,
 * and Trip persistence as a single logical unit of work.
 * Uses inherited sharing to respect record-level security.
 */
public inherited sharing class OpportunityService {

    /**
     * @description Safely converts a deserialized Map to Map<String, Object>.
     * This handles the runtime type difference between Map<ANY,ANY> and Map<String,Object>.
     * @param obj The object to convert (typically from JSON deserialization)
     * @return A Map<String, Object> with all entries from the original map
     */
    private static Map<String, Object> toStringKeyMap(Object obj) {
        if (obj == null) {
            return null;
        }
        if (obj instanceof Map<String, Object>) {
            return (Map<String, Object>) obj;
        }
        Map<String, Object> result = new Map<String, Object>();
        Map<Object, Object> objMap = (Map<Object, Object>) obj;
        for (Object key : objMap.keySet()) {
            if (key instanceof String) {
                result.put((String) key, objMap.get(key));
            }
        }
        return result;
    }

    /**
     * @description Saves an Opportunity with its line items, transport fields, and trips.
     * Replaces all existing line items and upserts trip records.
     * Executes as a single transaction: all DML succeeds or none does.
     *
     * @param opportunityId  The Opportunity ID to save data against.
     * @param lineItemData    Line item payloads from the CPQ configurator.
     *                       Each map contains: product2Id, quantity, unitPrice, discountPercent,
     *                       isBundle, bundleGroup, and optionally an options list.
     * @param logistics       Transport configuration including agency, delivery site,
     *                       urgency, transport cost, and trip records.
     * @return The Opportunity ID on success.
     * @throws OpportunityException on validation or DML failures.
     */
    public static Id saveOpportunityWithLines(
        Id opportunityId,
        List<Map<String, Object>> lineItemData,
        Map<String, Object> logistics
    ) {
        try {
            validateInputs(opportunityId, lineItemData);

            Opportunity opportunity = OpportunityDAO.getById(opportunityId);
            if (opportunity == null) {
                throw new OpportunityException(
                    String.format(System.Label.Generic_Service_Record_Not_Found, new List<String>{ 'Opportunity' })
                );
            }

            Id pricebookId = opportunity.Pricebook2Id;
            if (pricebookId == null) {
                throw new OpportunityException('Opportunity must have a Pricebook assigned.');
            }

            Boolean isVolume = isVolumeOffer(opportunity.Offer_Type__c);
            if (isVolume) {
                validateServiceLines(lineItemData);
            }

            Map<Id, PricebookEntry> entryByProductId = resolvePricebookEntries(lineItemData, pricebookId);

            List<OpportunityLineItem> lineItems = buildLineItems(opportunityId, lineItemData, entryByProductId, isVolume);

            enforceLineRules(opportunityId, lineItemData);

            OpportunityLineItemDAO.deleteByOpportunityId(opportunityId);
            OpportunityLineItemDAO.insertLineItems(lineItems);

            updateOpportunityTransportFields(opportunityId, logistics);

            upsertTrips(opportunityId, logistics);

            return opportunityId;

        } catch (OpportunityException e) {
            System.debug(LoggingLevel.ERROR, 'OpportunityService.saveOpportunityWithLines failed: ' + e.getMessage());
            throw e;
        } catch (TripException e) {
            System.debug(LoggingLevel.ERROR, 'OpportunityService.saveOpportunityWithLines failed: ' + e.getMessage());
            throw new OpportunityException('Error saving trips: ' + e.getMessage(), e);
        }
    }

    /**
     * @description Returns true if the given Offer Type's catalog name is in
     * Volume_Pricing_Catalog_Names. Volume catalogs use day-bracketed tiers and
     * therefore require service dates and prorated UnitPrice persistence.
     * @param offerTypeId Opportunity.Offer_Type__c (ProductCatalog Id).
     * @return Whether this offer drives day-bracketed Volume Pricing.
     */
    private static Boolean isVolumeOffer(Id offerTypeId) {
        if (offerTypeId == null) {
            return false;
        }
        ProductCatalog catalog = ProductCatalogDAO.getById(offerTypeId);
        if (catalog == null) {
            return false;
        }
        String csv = Label.Volume_Pricing_Catalog_Names;
        if (String.isBlank(csv)) {
            return false;
        }
        for (String token : csv.split(',')) {
            if (token.trim().equalsIgnoreCase(catalog.Name)) {
                return true;
            }
        }
        return false;
    }

    /**
     * @description Validates that every line carries a complete service window.
     * Dates are set per line by the line editor (the header in the configurator
     * is a UI-only default that cascades into each line before save).
     * @param lineItemData Line items; each must have serviceStartDate <= serviceEndDate.
     * @throws OpportunityException if any line lacks dates or has end before start.
     */
    private static void validateServiceLines(List<Map<String, Object>> lineItemData) {
        for (Map<String, Object> item : lineItemData) {
            Date lineStart = toDate(item.get('serviceStartDate'));
            Date lineEnd = toDate(item.get('serviceEndDate'));
            if (lineStart == null || lineEnd == null) {
                throw new OpportunityException('Each service line must have both Start and End dates.');
            }
            if (lineEnd < lineStart) {
                throw new OpportunityException('Service End Date must be on or after Start Date on every line.');
            }
        }
    }

    /**
     * @description Evaluates the active Validation and Alert Product Rules against the line items
     * being saved. A fired Validation rule blocks the save; Alert rules are advisory and surfaced
     * on the Line Editor, so they do not block here.
     * @param opportunityId The Opportunity being saved.
     * @param lineItemData  The line item payloads (parents and bundle options).
     * @throws OpportunityException if any Validation rule fires.
     */
    private static void enforceLineRules(Id opportunityId, List<Map<String, Object>> lineItemData) {
        Map<String, Object> verdict = ProductRuleService.evaluateLineRules(
            opportunityId, buildRuleLines(lineItemData)
        );
        List<String> errors = (List<String>) verdict.get('validationErrors');
        if (errors != null && !errors.isEmpty()) {
            throw new OpportunityException(String.join(errors, ' '));
        }
    }

    /**
     * @description Flattens the line item payload into the minimal line maps the rule engine expects.
     * @param lineItemData Line item payloads from the configurator.
     * @return One map per parent product and per bundle option.
     */
    private static List<Map<String, Object>> buildRuleLines(List<Map<String, Object>> lineItemData) {
        List<Map<String, Object>> lines = new List<Map<String, Object>>();
        for (Map<String, Object> item : lineItemData) {
            lines.add(new Map<String, Object>{
                'productId' => item.get('product2Id'),
                'quantity' => item.get('quantity'),
                'unitPrice' => item.get('unitPrice'),
                'discountPercent' => item.get('discountPercent'),
                'isBundle' => item.get('isBundle') == true
            });
            List<Object> options = (List<Object>) item.get('options');
            if (options == null) {
                continue;
            }
            for (Object optObj : options) {
                Map<String, Object> optData = toStringKeyMap(optObj);
                if (optData == null) {
                    continue;
                }
                lines.add(new Map<String, Object>{
                    'productId' => optData.get('product2Id'),
                    'quantity' => optData.get('quantity'),
                    'unitPrice' => optData.get('unitPrice'),
                    'discountPercent' => optData.get('discountPercent'),
                    'isBundle' => false
                });
            }
        }
        return lines;
    }

    /**
     * @description Validates required inputs for the save operation.
     * @param opportunityId  The Opportunity ID.
     * @param lineItemData   The line item payloads.
     * @throws OpportunityException if validation fails.
     */
    private static void validateInputs(Id opportunityId, List<Map<String, Object>> lineItemData) {
        if (opportunityId == null) {
            throw new OpportunityException(
                String.format(System.Label.Generic_Service_Record_Id_Required, new List<String>{ 'Opportunity' })
            );
        }

        if (lineItemData == null || lineItemData.isEmpty()) {
            throw new OpportunityException(
                String.format(System.Label.Generic_Service_Records_Required, new List<String>{ 'Product' })
            );
        }
    }

    /**
     * @description Resolves PricebookEntry records for all products referenced in line items.
     * Collects Product2Ids from parent items and their bundle options, queries PricebookEntry
     * records, and returns a map keyed by Product2Id.
     * Products without a PricebookEntry are silently skipped (validation happens at bundle level).
     *
     * @param lineItemData  Line item payloads containing product2Id references.
     * @param pricebookId   The Pricebook2 ID to constrain entries to.
     * @return Map of Product2Id to PricebookEntry for products that have entries.
     */
    private static Map<Id, PricebookEntry> resolvePricebookEntries(
        List<Map<String, Object>> lineItemData,
        Id pricebookId
    ) {
        Set<Id> productIds = new Set<Id>();
        Map<Id, String> productNameById = new Map<Id, String>();

        for (Map<String, Object> itemData : lineItemData) {
            Id product2Id = toId(itemData.get('product2Id'));
            String productName = (String) itemData.get('productName');
            if (product2Id != null) {
                productIds.add(product2Id);
                if (String.isNotBlank(productName)) {
                    productNameById.put(product2Id, productName);
                }
            }

            List<Object> options = (List<Object>) itemData.get('options');
            if (options != null) {
                for (Object optObj : options) {
                    Map<String, Object> optData = toStringKeyMap(optObj);
                    if (optData == null) {
                        continue;
                    }
                    Id optProduct2Id = toId(optData.get('product2Id'));
                    String optProductName = (String) optData.get('productName');
                    if (optProduct2Id != null) {
                        productIds.add(optProduct2Id);
                        if (String.isNotBlank(optProductName)) {
                            productNameById.put(optProduct2Id, optProductName);
                        }
                    }
                }
            }
        }

        if (productIds.isEmpty()) {
            throw new OpportunityException(
                String.format(System.Label.Generic_Service_Records_Required, new List<String>{ 'Product' })
            );
        }

        Map<Id, PricebookEntry> entryByProductId = PricebookEntryDAO.getByProductsAndPricebook(productIds, pricebookId);

        for (PricebookEntry entry : entryByProductId.values()) {
            if (!productNameById.containsKey(entry.Product2Id)) {
                productNameById.put(entry.Product2Id, entry.Product2.Name);
            }
        }

        for (Id productId : productIds) {
            if (!entryByProductId.containsKey(productId)) {
                String productName = productNameById.containsKey(productId) ? productNameById.get(productId) : String.valueOf(productId);
                throw new OpportunityException('No active PricebookEntry found for product: ' + productName + ' in the assigned Pricebook.');
            }
        }

        return entryByProductId;
    }

    /**
     * @description Builds OpportunityLineItem SObjects from line item payload data.
     * Creates parent items and their bundle option items, linking them via Bundle_Group__c.
     *
     * @param opportunityId      The Opportunity ID to associate line items with.
     * @param lineItemData        Line item payloads from the CPQ configurator.
     * @param entryByProductId    Map of Product2Id to PricebookEntry for price lookups.
     * @param isVolume            Whether the active Offer Type uses day-bracketed Volume Pricing.
     * @return List of OpportunityLineItem records ready for insert.
     */
    private static List<OpportunityLineItem> buildLineItems(
        Id opportunityId,
        List<Map<String, Object>> lineItemData,
        Map<Id, PricebookEntry> entryByProductId,
        Boolean isVolume
    ) {
        List<OpportunityLineItem> items = new List<OpportunityLineItem>();

        for (Map<String, Object> itemData : lineItemData) {
            Id product2Id = toId(itemData.get('product2Id'));
            Boolean isBundle = itemData.get('isBundle') != null ? (Boolean) itemData.get('isBundle') : false;
            String bundleGroup = (String) itemData.get('bundleGroup');

            OpportunityLineItem parentItem = buildSingleLineItem(
                opportunityId, product2Id, itemData, entryByProductId, isVolume
            );
            if (parentItem == null) {
                continue;
            }

            if (isBundle) {
                parentItem.Is_Bundle_Product__c = true;
                parentItem.Bundle_Group__c = bundleGroup;
            }

            items.add(parentItem);

            List<Object> options = (List<Object>) itemData.get('options');
            if (options != null && !options.isEmpty()) {
                // Resolve source Bundle_Option__c records by (parent product, option product) pair.
                Set<Id> optProductIds = new Set<Id>();
                for (Object optObj : options) {
                    Map<String, Object> optDataPreview = toStringKeyMap(optObj);
                    if (optDataPreview == null) {
                        continue;
                    }
                    Id optProductId = toId(optDataPreview.get('product2Id'));
                    if (optProductId != null) {
                        optProductIds.add(optProductId);
                    }
                }

                Map<String, Bundle_Option__c> sourceByKey = new Map<String, Bundle_Option__c>();
                if (product2Id != null && !optProductIds.isEmpty()) {
                    Map<Id, Set<Id>> pairs = new Map<Id, Set<Id>>{ product2Id => optProductIds };
                    for (Bundle_Option__c bo : BundleOptionDAO.getByBundleAndOptionPairs(pairs)) {
                        String k = String.valueOf(bo.Bundle_Product__c) + '|' + String.valueOf(bo.Option_Product__c);
                        if (!sourceByKey.containsKey(k)) {
                            sourceByKey.put(k, bo);
                        }
                    }
                }

                Integer parentQty = toInteger(itemData.get('quantity'));

                for (Object optObj : options) {
                    Map<String, Object> optData = toStringKeyMap(optObj);
                    if (optData == null) {
                        continue;
                    }
                    if (isVolume) {
                        // Options inherit the parent's service window only when the
                        // option itself has no override (the line editor lets a rep
                        // set per-option dates on top of the bundle's defaults).
                        if (optData.get('serviceStartDate') == null) {
                            optData.put('serviceStartDate', itemData.get('serviceStartDate'));
                        }
                        if (optData.get('serviceEndDate') == null) {
                            optData.put('serviceEndDate', itemData.get('serviceEndDate'));
                        }
                    }
                    Id optProduct2Id = toId(optData.get('product2Id'));

                    String key = String.valueOf(product2Id) + '|' + String.valueOf(optProduct2Id);
                    Bundle_Option__c source = sourceByKey.get(key);
                    if (source != null && source.Default_Quantity__c != null) {
                        if (source.Option_Type__c == 'Component') {
                            optData.put('quantity', Integer.valueOf(source.Default_Quantity__c * parentQty));
                        } else if (source.Option_Type__c == 'Accessory') {
                            optData.put('quantity', Integer.valueOf(source.Default_Quantity__c));
                        }
                    }

                    OpportunityLineItem childItem = buildSingleLineItem(
                        opportunityId, optProduct2Id, optData, entryByProductId, isVolume
                    );
                    if (childItem == null) {
                        continue;
                    }
                    childItem.Bundle_Group__c = bundleGroup;
                    items.add(childItem);
                }
            }
        }

        return items;
    }

    /**
     * @description Builds a single OpportunityLineItem from a payload map.
     *
     * @param opportunityId      The Opportunity ID.
     * @param product2Id          The Product2 ID for this line item.
     * @param data                The payload map containing quantity, unitPrice, discountPercent.
     * @param entryByProductId    Map of Product2Id to PricebookEntry.
     * @param isVolume            Whether the active Offer Type uses day-bracketed Volume Pricing.
     * @return A populated OpportunityLineItem SObject (not yet inserted).
     */
    private static OpportunityLineItem buildSingleLineItem(
        Id opportunityId,
        Id product2Id,
        Map<String, Object> data,
        Map<Id, PricebookEntry> entryByProductId,
        Boolean isVolume
    ) {
        PricebookEntry entry = entryByProductId.get(product2Id);

        OpportunityLineItem item = new OpportunityLineItem();
        item.OpportunityId = opportunityId;
        item.PricebookEntryId = entry.Id;
        item.Quantity = toInteger(data.get('quantity'));
        Decimal discount = toDecimal(data.get('discountPercent'));
        if (discount != null && discount != 0) {
            item.Discount = discount;
        }

        Decimal rawUnitPrice = toDecimal(data.get('unitPrice'));

        if (isVolume) {
            Date sd = toDate(data.get('serviceStartDate'));
            Date ed = toDate(data.get('serviceEndDate'));
            Integer days = sd.daysBetween(ed) + 1;
            Decimal dailyRate = rawUnitPrice;
            item.UnitPrice = (dailyRate * days).setScale(2);
            item.Daily_Rate__c = dailyRate;
            item.Service_Start_Date__c = sd;
            item.Service_End_Date__c = ed;
        } else {
            item.UnitPrice = rawUnitPrice;
        }
        return item;
    }

    /**
     * @description Updates the Opportunity record with transport and logistics fields.
     *
     * @param opportunityId  The Opportunity ID to update.
     * @param logistics      The logistics configuration map.
     */
    private static void updateOpportunityTransportFields(Id opportunityId, Map<String, Object> logistics) {
        if (logistics == null) {
            return;
        }

        Opportunity opp = new Opportunity(Id = opportunityId);

        if (logistics.containsKey('isTransportRequired')) {
            opp.Is_Transport_Required__c = (Boolean) logistics.get('isTransportRequired');
        }
        if (logistics.containsKey('defaultAgencyId') && logistics.get('defaultAgencyId') != null) {
            opp.Default_Agency__c = toId(logistics.get('defaultAgencyId'));
        }
        if (logistics.containsKey('deliverySiteId') && logistics.get('deliverySiteId') != null) {
            opp.Delivery_Site__c = toId(logistics.get('deliverySiteId'));
        }
        if (logistics.containsKey('transportUrgency')) {
            opp.Transport_Urgency__c = (String) logistics.get('transportUrgency');
        }

        OpportunityDAO.updateRecord(opp);
    }

    /**
     * @description Persists trip records for the Opportunity.
     * Constructs Trip__c SObjects from the logistics data and delegates to TripService.
     *
     * @param opportunityId  The Opportunity ID to associate trips with.
     * @param logistics       The logistics configuration containing trip data.
     */
    private static void upsertTrips(Id opportunityId, Map<String, Object> logistics) {
        if (logistics == null) {
            return;
        }

        TripDAO.deleteTripsByOpportunity(opportunityId);

        List<Object> tripMaps = (List<Object>) logistics.get('trips');
        if (tripMaps == null || tripMaps.isEmpty()) {
            return;
        }

        List<Trip__c> trips = new List<Trip__c>();

        // Resolve a real Trip_Date__c from the opportunity's schedule (computed once, outside the loop).
        // Rental/service line items carry service dates; sales offers don't, so they fall back to today.
        Date deliveryDate = null; // earliest service start across line items
        Date pickupDate = null;   // latest service end across line items
        for (OpportunityLineItem oli : OpportunityLineItemDAO.getByOpportunityId(opportunityId)) {
            if (oli.Service_Start_Date__c != null && (deliveryDate == null || oli.Service_Start_Date__c < deliveryDate)) {
                deliveryDate = oli.Service_Start_Date__c;
            }
            if (oli.Service_End_Date__c != null && (pickupDate == null || oli.Service_End_Date__c > pickupDate)) {
                pickupDate = oli.Service_End_Date__c;
            }
        }

        for (Object tripObj : tripMaps) {
            Map<String, Object> tripData = toStringKeyMap(tripObj);
            if (tripData == null) {
                continue;
            }

            Trip__c trip = new Trip__c();
            trip.Opportunity__c = opportunityId;

            if (tripData.containsKey('truckType')) {
                trip.Truck_Type__c = (String) tripData.get('truckType');
            }
            if (tripData.containsKey('distanceKm')) {
                trip.Distance_Km__c = toDecimal(tripData.get('distanceKm'));
            }
            if (tripData.containsKey('systemPrice')) {
                trip.System_Price__c = toDecimal(tripData.get('systemPrice'));
            }
            if (tripData.containsKey('finalPrice')) {
                trip.Final_Price__c = toDecimal(tripData.get('finalPrice'));
            }
            if (tripData.containsKey('overrideReason') && tripData.get('overrideReason') != null) {
                trip.Override_Reason__c = (String) tripData.get('overrideReason');
            }
            if (tripData.containsKey('direction')) {
                trip.Direction__c = (String) tripData.get('direction');
            }
            if (tripData.containsKey('transportZone')) {
                trip.Transport_Zone__c = (String) tripData.get('transportZone');
            }
            if (tripData.containsKey('totalWeightKg')) {
                trip.Total_Weight_Kg__c = toDecimal(tripData.get('totalWeightKg'));
            }
            if (tripData.containsKey('rateCurrency')) {
                trip.Rate_Currency__c = (String) tripData.get('rateCurrency');
            }
            if (tripData.containsKey('binVisualizationUrl')) {
                trip.Bin_Visualization_URL__c = (String) tripData.get('binVisualizationUrl');
            }
            if (tripData.containsKey('countryCode') && tripData.get('countryCode') != null) {
                trip.Country_Code__c = (String) tripData.get('countryCode');
            }
            Object tripDateVal = tripData.get('tripDate');
            if (tripDateVal instanceof Date) {
                trip.Trip_Date__c = (Date) tripDateVal;
            } else if (tripDateVal instanceof String && String.isNotBlank((String) tripDateVal)) {
                try {
                    trip.Trip_Date__c = Date.valueOf((String) tripDateVal);
                } catch (Exception e) {
                    trip.Trip_Date__c = null;
                }
            }
            if (trip.Trip_Date__c == null) {
                trip.Trip_Date__c = resolveTripDate(trip.Direction__c, deliveryDate, pickupDate);
            }
            if (tripData.containsKey('tripKey') && tripData.get('tripKey') != null) {
                trip.Trip_Key__c = (String) tripData.get('tripKey');
            }

            trips.add(trip);
        }

        if (!trips.isEmpty()) {
            TripDAO.upsertTrips(trips);
        }
    }

    /**
     * @description Resolves the scheduled date for a trip. Delivery trips use the earliest line-item
     * service start; pickup trips use the latest service end. Sales offers have no service dates, so
     * they fall back to today. The result is clamped to today when it would otherwise be in the past,
     * so new Trip__c records satisfy the Trip_Date_Not_Past rule.
     * @param direction the trip direction ('Delivery' or 'Pickup')
     * @param deliveryDate earliest line-item service start date, or null
     * @param pickupDate latest line-item service end date, or null
     * @return the resolved trip date, never null and never before today
     */
    private static Date resolveTripDate(String direction, Date deliveryDate, Date pickupDate) {
        Date resolved;
        if (direction == 'Pickup') {
            resolved = (pickupDate != null) ? pickupDate : deliveryDate;
        } else {
            resolved = (deliveryDate != null) ? deliveryDate : pickupDate;
        }
        if (resolved == null || resolved < Date.today()) {
            resolved = Date.today();
        }
        return resolved;
    }

    /**
     * @description Converts an Object value to an Id.
     * Returns null if the value is null or not a valid Id string.
     * @param value The object to convert to an Id.
     * @return The Id value, or null if conversion fails.
     */
    private static Id toId(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof Id) {
            return (Id) value;
        }
        String strValue = String.valueOf(value);
        if (String.isBlank(strValue)) {
            return null;
        }
        try {
            return Id.valueOf(strValue);
        } catch (StringException e) {
            return null;
        }
    }

    /**
     * @description Converts an Object value to an Integer, defaulting to 1.
     * @param value The object to convert to an Integer.
     * @return The Integer value, or 1 if conversion fails.
     */
    private static Integer toInteger(Object value) {
        if (value == null) {
            return 1;
        }
        if (value instanceof Integer) {
            return (Integer) value;
        }
        if (value instanceof Decimal) {
            return ((Decimal) value).intValue();
        }
        if (value instanceof Long) {
            return Integer.valueOf((Long) value);
        }
        try {
            return Integer.valueOf(String.valueOf(value));
        } catch (Exception e) {
            return 1;
        }
    }

    /**
     * @description Converts an Object value to a Decimal, defaulting to 0.
     * @param value The object to convert to a Decimal.
     * @return The Decimal value, or 0 if conversion fails.
     */
    private static Decimal toDecimal(Object value) {
        if (value == null) {
            return 0;
        }
        if (value instanceof Decimal) {
            return (Decimal) value;
        }
        if (value instanceof Integer) {
            return Decimal.valueOf((Integer) value);
        }
        if (value instanceof Long) {
            return Decimal.valueOf((Long) value);
        }
        try {
            return Decimal.valueOf(String.valueOf(value));
        } catch (Exception e) {
            return 0;
        }
    }

    /**
     * @description Converts an Object value to a Date.
     * @param value The value to convert (Date instance or ISO date string).
     * @return The Date value, or null on failure.
     */
    private static Date toDate(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof Date) {
            return (Date) value;
        }
        try {
            return Date.valueOf(String.valueOf(value));
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * @description Trigger handler invoked before Opportunity insert.
     * @param newList The list of Opportunity records being inserted.
     */
    public static void beforeInsert(List<Opportunity> newList) {
        System.debug(LoggingLevel.INFO, '=== [OpportunityService] beforeInsert exécuté ===');
    }

    /**
     * @description Trigger handler invoked before Opportunity update.
     * @param newList The list of Opportunity records being updated.
     * @param oldMap  Map of Opportunity Id to the previous record state.
     */
    public static void beforeUpdate(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        System.debug(LoggingLevel.INFO, '===[OpportunityService] beforeUpdate exécuté ===');
    }

    /**
     * @description Trigger handler invoked before Opportunity delete.
     * @param oldMap Map of Opportunity Id to the record being deleted.
     */
    public static void beforeDelete(Map<Id, Opportunity> oldMap) {
        System.debug(LoggingLevel.INFO, '=== [OpportunityService] beforeDelete exécuté ===');
    }

    /**
     * @description Trigger handler invoked after Opportunity insert.
     * Enqueues distance calculation when agency and delivery site are set.
     * @param newList The list of Opportunity records just inserted.
     */
    public static void afterInsert(List<Opportunity> newList) {
        System.debug(LoggingLevel.INFO, '=== [OpportunityService] afterInsert exécuté ===');

        checkAndEnqueueDistanceCalculation(newList, null);
    }

    /**
     * @description Trigger handler invoked after Opportunity update.
     * Enqueues distance calculation when agency or delivery site changes.
     * @param newList The list of Opportunity records just updated.
     * @param oldMap  Map of Opportunity Id to the previous record state.
     */
    public static void afterUpdate(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        System.debug(LoggingLevel.INFO, '=== [OpportunityService] afterUpdate exécuté ===');

        checkAndEnqueueDistanceCalculation(newList, oldMap);
    }

    /**
     * @description Trigger handler invoked after Opportunity delete.
     * @param oldMap Map of Opportunity Id to the deleted record.
     */
    public static void afterDelete(Map<Id, Opportunity> oldMap) {
        System.debug(LoggingLevel.INFO, '=== [OpportunityService] afterDelete exécuté ===');
    }


    /**
     * @description Checks if an opportunity requires road distance calculation
     * and enqueues the asynchronous processing (Queueable).
     * @param newOpps The list of Opportunity records to evaluate.
     * @param oldMap  Map of Opportunity Id to previous state; null for insert.
     */
    private static void checkAndEnqueueDistanceCalculation(List<Opportunity> newOpps, Map<Id, Opportunity> oldMap) {
        Set<Id> oppIdsToProcess = new Set<Id>();
        
        for (Opportunity opp : newOpps) {
            if (opp.Default_Agency__c != null && opp.Delivery_Site__c != null) {
                
                if (oldMap == null || 
                    opp.Default_Agency__c != oldMap.get(opp.Id).Default_Agency__c || 
                    opp.Delivery_Site__c != oldMap.get(opp.Id).Delivery_Site__c) {
                    
                    oppIdsToProcess.add(opp.Id);
                }
            }
        }
        
        if (!oppIdsToProcess.isEmpty()) {
            System.enqueueJob(new DistanceCalculationQueueable(oppIdsToProcess));
        }
    }
}
