public inherited sharing class BundleFeatureDAO {
    public static Bundle_Feature__c getById(Id recordId) {
        if (recordId == null) {
            return null;
        }

        List<Bundle_Feature__c> records = [
            SELECT
                Id,
                Name,
                Help_Text__c,
                Max_Options__c,
                Min_Options__c,
                Product__c,
                Sort_Order__c,
                Product__r.Name
            FROM Bundle_Feature__c
            WHERE Id = :recordId
            LIMIT 1
        ];

        return records.isEmpty() ? null : records[0];
    }

    public static Map<Id, Bundle_Feature__c> getByIds(Set<Id> recordIds) {
        if (recordIds == null || recordIds.isEmpty()) {
            return new Map<Id, Bundle_Feature__c>();
        }

        return new Map<Id, Bundle_Feature__c>([
            SELECT
                Id,
                Name,
                Help_Text__c,
                Max_Options__c,
                Min_Options__c,
                Product__c,
                Sort_Order__c,
                Product__r.Name
            FROM Bundle_Feature__c
            WHERE Id IN :recordIds
        ]);
    }


    public static List<Bundle_Feature__c> getByName(String recordName) {
        if (String.isBlank(recordName)) {
            return new List<Bundle_Feature__c>();
        }

        return [
            SELECT
                Id,
                Name,
                Help_Text__c,
                Max_Options__c,
                Min_Options__c,
                Product__c,
                Sort_Order__c,
                Product__r.Name
            FROM Bundle_Feature__c
            WHERE Name = :recordName
        ];
    }

    public static List<Bundle_Feature__c> getAll() {
        return [
            SELECT
                Id,
                Name,
                Help_Text__c,
                Max_Options__c,
                Min_Options__c,
                Product__c,
                Sort_Order__c,
                Product__r.Name
            FROM Bundle_Feature__c
        ];
    }
}
