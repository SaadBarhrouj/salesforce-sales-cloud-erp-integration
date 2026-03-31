public inherited sharing class ProductRuleDAO {
    public static Product_Rule__c getById(Id recordId) {
        if (recordId == null) {
            return null;
        }

        List<Product_Rule__c> records = [
            SELECT
                Id,
                Name,
                Advanced_Condition__c,
                Conditions_Met__c,
                Evaluation_Event__c,
                Evaluation_Order__c,
                Is_Active__c,
                Message__c,
                Scope__c,
                Type__c
            FROM Product_Rule__c
            WHERE Id = :recordId
            LIMIT 1
        ];

        return records.isEmpty() ? null : records[0];
    }

    public static Map<Id, Product_Rule__c> getByIds(Set<Id> recordIds) {
        if (recordIds == null || recordIds.isEmpty()) {
            return new Map<Id, Product_Rule__c>();
        }

        return new Map<Id, Product_Rule__c>([
            SELECT
                Id,
                Name,
                Advanced_Condition__c,
                Conditions_Met__c,
                Evaluation_Event__c,
                Evaluation_Order__c,
                Is_Active__c,
                Message__c,
                Scope__c,
                Type__c
            FROM Product_Rule__c
            WHERE Id IN :recordIds
        ]);
    }


    public static List<Product_Rule__c> getByName(String recordName) {
        if (String.isBlank(recordName)) {
            return new List<Product_Rule__c>();
        }

        return [
            SELECT
                Id,
                Name,
                Advanced_Condition__c,
                Conditions_Met__c,
                Evaluation_Event__c,
                Evaluation_Order__c,
                Is_Active__c,
                Message__c,
                Scope__c,
                Type__c
            FROM Product_Rule__c
            WHERE Name = :recordName
        ];
    }

    public static List<Product_Rule__c> getAll() {
        return [
            SELECT
                Id,
                Name,
                Advanced_Condition__c,
                Conditions_Met__c,
                Evaluation_Event__c,
                Evaluation_Order__c,
                Is_Active__c,
                Message__c,
                Scope__c,
                Type__c
            FROM Product_Rule__c
        ];
    }
}
