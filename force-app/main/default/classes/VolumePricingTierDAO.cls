public inherited sharing class VolumePricingTierDAO {
    public static Volume_Pricing_Tier__c getById(Id recordId) {
        if (recordId == null) {
            return null;
        }

        List<Volume_Pricing_Tier__c> records = [
            SELECT
                Id,
                Name,
                Lower_Bound__c,
                Price__c,
                Sort_Order__c,
                Upper_Bound__c,
                Volume_Pricing_Schedule__c,
                Volume_Pricing_Schedule__r.Name
            FROM Volume_Pricing_Tier__c
            WHERE Id = :recordId
            LIMIT 1
        ];

        return records.isEmpty() ? null : records[0];
    }

    public static Map<Id, Volume_Pricing_Tier__c> getByIds(Set<Id> recordIds) {
        if (recordIds == null || recordIds.isEmpty()) {
            return new Map<Id, Volume_Pricing_Tier__c>();
        }

        return new Map<Id, Volume_Pricing_Tier__c>([
            SELECT
                Id,
                Name,
                Lower_Bound__c,
                Price__c,
                Sort_Order__c,
                Upper_Bound__c,
                Volume_Pricing_Schedule__c,
                Volume_Pricing_Schedule__r.Name
            FROM Volume_Pricing_Tier__c
            WHERE Id IN :recordIds
        ]);
    }


    public static List<Volume_Pricing_Tier__c> getByName(String recordName) {
        if (String.isBlank(recordName)) {
            return new List<Volume_Pricing_Tier__c>();
        }

        return [
            SELECT
                Id,
                Name,
                Lower_Bound__c,
                Price__c,
                Sort_Order__c,
                Upper_Bound__c,
                Volume_Pricing_Schedule__c,
                Volume_Pricing_Schedule__r.Name
            FROM Volume_Pricing_Tier__c
            WHERE Name = :recordName
        ];
    }

    public static List<Volume_Pricing_Tier__c> getAll() {
        return [
            SELECT
                Id,
                Name,
                Lower_Bound__c,
                Price__c,
                Sort_Order__c,
                Upper_Bound__c,
                Volume_Pricing_Schedule__c,
                Volume_Pricing_Schedule__r.Name
            FROM Volume_Pricing_Tier__c
        ];
    }
}
