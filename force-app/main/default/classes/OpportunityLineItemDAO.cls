public inherited sharing class OpportunityLineItemDAO {
    public static OpportunityLineItem getById(Id recordId) {
        if (recordId == null) {
            return null;
        }

        List<OpportunityLineItem> records = [
            SELECT
                Id,
                Bundle_Group__c,
                Delivery_Date__c,
                Departure_Agency__c,
                Description,
                Discount,
                Is_Bundle_Product__c,
                ListPrice,
                Name,
                OpportunityId,
                Pickup_Date__c,
                Product2Id,
                ProductCode,
                Quantity,
                Rental_End_Date__c,
                Rental_Start_Date__c,
                ServiceDate,
                Subtotal,
                TotalPrice,
                Trip_Delivery__c,
                Trip_Pickup__c,
                UnitPrice,
                PricebookEntryId,
                Departure_Agency__r.Name,
                Opportunity.Name,
                Product2.Name,
                Trip_Delivery__r.Name,
                Trip_Pickup__r.Name
            FROM OpportunityLineItem
            WHERE Id = :recordId
            LIMIT 1
        ];

        return records.isEmpty() ? null : records[0];
    }

    public static Map<Id, OpportunityLineItem> getByIds(Set<Id> recordIds) {
        if (recordIds == null || recordIds.isEmpty()) {
            return new Map<Id, OpportunityLineItem>();
        }

        return new Map<Id, OpportunityLineItem>([
            SELECT
                Id,
                Bundle_Group__c,
                Delivery_Date__c,
                Departure_Agency__c,
                Description,
                Discount,
                Is_Bundle_Product__c,
                ListPrice,
                Name,
                OpportunityId,
                Pickup_Date__c,
                Product2Id,
                ProductCode,
                Quantity,
                Rental_End_Date__c,
                Rental_Start_Date__c,
                ServiceDate,
                Subtotal,
                TotalPrice,
                Trip_Delivery__c,
                Trip_Pickup__c,
                UnitPrice,
                PricebookEntryId,
                Departure_Agency__r.Name,
                Opportunity.Name,
                Product2.Name,
                Trip_Delivery__r.Name,
                Trip_Pickup__r.Name
            FROM OpportunityLineItem
            WHERE Id IN :recordIds
        ]);
    }


    public static List<OpportunityLineItem> getByName(String recordName) {
        if (String.isBlank(recordName)) {
            return new List<OpportunityLineItem>();
        }

        return [
            SELECT
                Id,
                Bundle_Group__c,
                Delivery_Date__c,
                Departure_Agency__c,
                Description,
                Discount,
                Is_Bundle_Product__c,
                ListPrice,
                Name,
                OpportunityId,
                Pickup_Date__c,
                Product2Id,
                ProductCode,
                Quantity,
                Rental_End_Date__c,
                Rental_Start_Date__c,
                ServiceDate,
                Subtotal,
                TotalPrice,
                Trip_Delivery__c,
                Trip_Pickup__c,
                UnitPrice,
                PricebookEntryId,
                Departure_Agency__r.Name,
                Opportunity.Name,
                Product2.Name,
                Trip_Delivery__r.Name,
                Trip_Pickup__r.Name
            FROM OpportunityLineItem
            WHERE Name = :recordName
        ];
    }

    public static List<OpportunityLineItem> getAll() {
        return [
            SELECT
                Id,
                Bundle_Group__c,
                Delivery_Date__c,
                Departure_Agency__c,
                Description,
                Discount,
                Is_Bundle_Product__c,
                ListPrice,
                Name,
                OpportunityId,
                Pickup_Date__c,
                Product2Id,
                ProductCode,
                Quantity,
                Rental_End_Date__c,
                Rental_Start_Date__c,
                ServiceDate,
                Subtotal,
                TotalPrice,
                Trip_Delivery__c,
                Trip_Pickup__c,
                UnitPrice,
                PricebookEntryId,
                Departure_Agency__r.Name,
                Opportunity.Name,
                Product2.Name,
                Trip_Delivery__r.Name,
                Trip_Pickup__r.Name
            FROM OpportunityLineItem
        ];
    }
}
