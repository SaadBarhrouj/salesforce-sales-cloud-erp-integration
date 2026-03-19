public inherited sharing class RuleActionDAO {
    public static Rule_Action__c getById(Id recordId) {
        if (recordId == null) {
            return null;
        }

        List<Rule_Action__c> records = [
            SELECT
                Id,
                Name,
                Filter_Field__c,
                Filter_Operator__c,
                Filter_Value__c,
                Product_Rule__c,
                Sort_Order__c,
                Target_Product__c,
                Type__c,
                Product_Rule__r.Name,
                Target_Product__r.Name
            FROM Rule_Action__c
            WHERE Id = :recordId
            LIMIT 1
        ];

        return records.isEmpty() ? null : records[0];
    }

    public static Map<Id, Rule_Action__c> getByIds(Set<Id> recordIds) {
        if (recordIds == null || recordIds.isEmpty()) {
            return new Map<Id, Rule_Action__c>();
        }

        return new Map<Id, Rule_Action__c>([
            SELECT
                Id,
                Name,
                Filter_Field__c,
                Filter_Operator__c,
                Filter_Value__c,
                Product_Rule__c,
                Sort_Order__c,
                Target_Product__c,
                Type__c,
                Product_Rule__r.Name,
                Target_Product__r.Name
            FROM Rule_Action__c
            WHERE Id IN :recordIds
        ]);
    }


    public static List<Rule_Action__c> getByName(String recordName) {
        if (String.isBlank(recordName)) {
            return new List<Rule_Action__c>();
        }

        return [
            SELECT
                Id,
                Name,
                Filter_Field__c,
                Filter_Operator__c,
                Filter_Value__c,
                Product_Rule__c,
                Sort_Order__c,
                Target_Product__c,
                Type__c,
                Product_Rule__r.Name,
                Target_Product__r.Name
            FROM Rule_Action__c
            WHERE Name = :recordName
        ];
    }

    public static List<Rule_Action__c> getAll() {
        return [
            SELECT
                Id,
                Name,
                Filter_Field__c,
                Filter_Operator__c,
                Filter_Value__c,
                Product_Rule__c,
                Sort_Order__c,
                Target_Product__c,
                Type__c,
                Product_Rule__r.Name,
                Target_Product__r.Name
            FROM Rule_Action__c
        ];
    }
}
