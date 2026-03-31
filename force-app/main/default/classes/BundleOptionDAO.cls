public inherited sharing class BundleOptionDAO {
    public static Bundle_Option__c getById(Id recordId) {
        if (recordId == null) {
            return null;
        }

        List<Bundle_Option__c> records = [
            SELECT
                Id,
                Name,
                Bundle_Product__c,
                Default_Quantity__c,
                Feature__c,
                Is_Required__c,
                Is_Selected__c,
                Max_Quantity__c,
                Min_Quantity__c,
                Option_Product__c,
                Option_Type__c,
                Quantity_Editable__c,
                Sort_Order__c,
                Bundle_Product__r.Name,
                Feature__r.Name,
                Option_Product__r.Name
            FROM Bundle_Option__c
            WHERE Id = :recordId
            LIMIT 1
        ];

        return records.isEmpty() ? null : records[0];
    }

    public static Map<Id, Bundle_Option__c> getByIds(Set<Id> recordIds) {
        if (recordIds == null || recordIds.isEmpty()) {
            return new Map<Id, Bundle_Option__c>();
        }

        return new Map<Id, Bundle_Option__c>([
            SELECT
                Id,
                Name,
                Bundle_Product__c,
                Default_Quantity__c,
                Feature__c,
                Is_Required__c,
                Is_Selected__c,
                Max_Quantity__c,
                Min_Quantity__c,
                Option_Product__c,
                Option_Type__c,
                Quantity_Editable__c,
                Sort_Order__c,
                Bundle_Product__r.Name,
                Feature__r.Name,
                Option_Product__r.Name
            FROM Bundle_Option__c
            WHERE Id IN :recordIds
        ]);
    }


    public static List<Bundle_Option__c> getByName(String recordName) {
        if (String.isBlank(recordName)) {
            return new List<Bundle_Option__c>();
        }

        return [
            SELECT
                Id,
                Name,
                Bundle_Product__c,
                Default_Quantity__c,
                Feature__c,
                Is_Required__c,
                Is_Selected__c,
                Max_Quantity__c,
                Min_Quantity__c,
                Option_Product__c,
                Option_Type__c,
                Quantity_Editable__c,
                Sort_Order__c,
                Bundle_Product__r.Name,
                Feature__r.Name,
                Option_Product__r.Name
            FROM Bundle_Option__c
            WHERE Name = :recordName
        ];
    }

    public static List<Bundle_Option__c> getAll() {
        return [
            SELECT
                Id,
                Name,
                Bundle_Product__c,
                Default_Quantity__c,
                Feature__c,
                Is_Required__c,
                Is_Selected__c,
                Max_Quantity__c,
                Min_Quantity__c,
                Option_Product__c,
                Option_Type__c,
                Quantity_Editable__c,
                Sort_Order__c,
                Bundle_Product__r.Name,
                Feature__r.Name,
                Option_Product__r.Name
            FROM Bundle_Option__c
        ];
    }
}
