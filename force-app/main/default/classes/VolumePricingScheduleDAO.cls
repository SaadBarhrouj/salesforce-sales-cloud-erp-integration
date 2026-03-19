public inherited sharing class VolumePricingScheduleDAO {
    public static Volume_Pricing_Schedule__c getById(Id recordId) {
        if (recordId == null) {
            return null;
        }

        List<Volume_Pricing_Schedule__c> records = [
            SELECT
                Id,
                Name,
                Is_Active__c,
                Overage_Rate__c,
                Pricebook__c,
                Pricing_Type__c,
                Product__c,
                Pricebook__r.Name,
                Product__r.Name
            FROM Volume_Pricing_Schedule__c
            WHERE Id = :recordId
            LIMIT 1
        ];

        return records.isEmpty() ? null : records[0];
    }

    public static Map<Id, Volume_Pricing_Schedule__c> getByIds(Set<Id> recordIds) {
        if (recordIds == null || recordIds.isEmpty()) {
            return new Map<Id, Volume_Pricing_Schedule__c>();
        }

        return new Map<Id, Volume_Pricing_Schedule__c>([
            SELECT
                Id,
                Name,
                Is_Active__c,
                Overage_Rate__c,
                Pricebook__c,
                Pricing_Type__c,
                Product__c,
                Pricebook__r.Name,
                Product__r.Name
            FROM Volume_Pricing_Schedule__c
            WHERE Id IN :recordIds
        ]);
    }


    public static List<Volume_Pricing_Schedule__c> getByName(String recordName) {
        if (String.isBlank(recordName)) {
            return new List<Volume_Pricing_Schedule__c>();
        }

        return [
            SELECT
                Id,
                Name,
                Is_Active__c,
                Overage_Rate__c,
                Pricebook__c,
                Pricing_Type__c,
                Product__c,
                Pricebook__r.Name,
                Product__r.Name
            FROM Volume_Pricing_Schedule__c
            WHERE Name = :recordName
        ];
    }

    public static List<Volume_Pricing_Schedule__c> getAll() {
        return [
            SELECT
                Id,
                Name,
                Is_Active__c,
                Overage_Rate__c,
                Pricebook__c,
                Pricing_Type__c,
                Product__c,
                Pricebook__r.Name,
                Product__r.Name
            FROM Volume_Pricing_Schedule__c
        ];
    }
}
