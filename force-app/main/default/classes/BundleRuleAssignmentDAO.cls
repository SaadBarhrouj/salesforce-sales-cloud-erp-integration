public inherited sharing class BundleRuleAssignmentDAO {
    public static Bundle_Rule_Assignment__c getById(Id recordId) {
        if (recordId == null) {
            return null;
        }

        List<Bundle_Rule_Assignment__c> records = [
            SELECT
                Id,
                Name,
                Bundle_Product__c,
                Is_Active__c,
                Product_Rule__c,
                Bundle_Product__r.Name,
                Product_Rule__r.Name
            FROM Bundle_Rule_Assignment__c
            WHERE Id = :recordId
            LIMIT 1
        ];

        return records.isEmpty() ? null : records[0];
    }

    public static Map<Id, Bundle_Rule_Assignment__c> getByIds(Set<Id> recordIds) {
        if (recordIds == null || recordIds.isEmpty()) {
            return new Map<Id, Bundle_Rule_Assignment__c>();
        }

        return new Map<Id, Bundle_Rule_Assignment__c>([
            SELECT
                Id,
                Name,
                Bundle_Product__c,
                Is_Active__c,
                Product_Rule__c,
                Bundle_Product__r.Name,
                Product_Rule__r.Name
            FROM Bundle_Rule_Assignment__c
            WHERE Id IN :recordIds
        ]);
    }


    public static List<Bundle_Rule_Assignment__c> getByName(String recordName) {
        if (String.isBlank(recordName)) {
            return new List<Bundle_Rule_Assignment__c>();
        }

        return [
            SELECT
                Id,
                Name,
                Bundle_Product__c,
                Is_Active__c,
                Product_Rule__c,
                Bundle_Product__r.Name,
                Product_Rule__r.Name
            FROM Bundle_Rule_Assignment__c
            WHERE Name = :recordName
        ];
    }

    public static List<Bundle_Rule_Assignment__c> getAll() {
        return [
            SELECT
                Id,
                Name,
                Bundle_Product__c,
                Is_Active__c,
                Product_Rule__c,
                Bundle_Product__r.Name,
                Product_Rule__r.Name
            FROM Bundle_Rule_Assignment__c
        ];
    }
}
