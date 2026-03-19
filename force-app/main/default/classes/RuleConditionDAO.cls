public inherited sharing class RuleConditionDAO {
    public static Rule_Condition__c getById(Id recordId) {
        if (recordId == null) {
            return null;
        }

        List<Rule_Condition__c> records = [
            SELECT
                Id,
                Name,
                Filter_Type__c,
                Filter_Value__c,
                Index__c,
                Operator__c,
                Product_Rule__c,
                Tested_Field__c,
                Tested_Object__c,
                Product_Rule__r.Name
            FROM Rule_Condition__c
            WHERE Id = :recordId
            LIMIT 1
        ];

        return records.isEmpty() ? null : records[0];
    }

    public static Map<Id, Rule_Condition__c> getByIds(Set<Id> recordIds) {
        if (recordIds == null || recordIds.isEmpty()) {
            return new Map<Id, Rule_Condition__c>();
        }

        return new Map<Id, Rule_Condition__c>([
            SELECT
                Id,
                Name,
                Filter_Type__c,
                Filter_Value__c,
                Index__c,
                Operator__c,
                Product_Rule__c,
                Tested_Field__c,
                Tested_Object__c,
                Product_Rule__r.Name
            FROM Rule_Condition__c
            WHERE Id IN :recordIds
        ]);
    }


    public static List<Rule_Condition__c> getByName(String recordName) {
        if (String.isBlank(recordName)) {
            return new List<Rule_Condition__c>();
        }

        return [
            SELECT
                Id,
                Name,
                Filter_Type__c,
                Filter_Value__c,
                Index__c,
                Operator__c,
                Product_Rule__c,
                Tested_Field__c,
                Tested_Object__c,
                Product_Rule__r.Name
            FROM Rule_Condition__c
            WHERE Name = :recordName
        ];
    }

    public static List<Rule_Condition__c> getAll() {
        return [
            SELECT
                Id,
                Name,
                Filter_Type__c,
                Filter_Value__c,
                Index__c,
                Operator__c,
                Product_Rule__c,
                Tested_Field__c,
                Tested_Object__c,
                Product_Rule__r.Name
            FROM Rule_Condition__c
        ];
    }
}
