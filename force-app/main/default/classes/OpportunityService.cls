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
            if (options != null) {
                for (Object optObj : options) {
                    Map<String, Object> optData = toStringKeyMap(optObj);
                    if (optData == null) {
                        continue;
                    }
                    if (isVolume) {
                        // Bundle options inherit the parent line's service window.
                        optData.put('serviceStartDate', itemData.get('serviceStartDate'));
                        optData.put('serviceEndDate', itemData.get('serviceEndDate'));
                    }
                    Id optProduct2Id = toId(optData.get('product2Id'));

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
        item.Discount = toDecimal(data.get('discountPercent'));

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

        OpportunityDAO.updateOpportunity(opp);
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

        List<Object> tripMaps = (List<Object>) logistics.get('trips');
        if (tripMaps == null || tripMaps.isEmpty()) {
            return;
        }

        List<Trip__c> trips = new List<Trip__c>();

        for (Object tripObj : tripMaps) {
            Map<String, Object> tripData = toStringKeyMap(tripObj);
            if (tripData == null) {
                continue;
            }

            Trip__c trip = new Trip__c();
            trip.Opportunity__c = opportunityId;

            String tripId = (String) tripData.get('id');
            if (String.isNotBlank(tripId) && tripId.startsWith('0')) {
                trip.Id = Id.valueOf(tripId);
            }

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
            if (tripData.containsKey('countryCode') && tripData.get('countryCode') != null) {
                trip.Country_Code__c = (String) tripData.get('countryCode');
            }
            if (tripData.containsKey('tripDate') && tripData.get('tripDate') != null) {
                Object tripDateVal = tripData.get('tripDate');
                if (tripDateVal instanceof Date) {
                    trip.Trip_Date__c = (Date) tripDateVal;
                }
            }
            if (tripData.containsKey('tripKey') && tripData.get('tripKey') != null) {
                trip.Trip_Key__c = (String) tripData.get('tripKey');
            }

            trips.add(trip);
        }

        if (!trips.isEmpty()) {
            TripService.updateTrips(trips);
        }
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
}