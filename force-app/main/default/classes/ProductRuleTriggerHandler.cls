public class ProductRuleTriggerHandler {
    public static void handle(List<SObject> newList, Map<Id, SObject> oldMap) {
        if (Trigger.isBefore) {
            if (Trigger.isInsert) {
                beforeInsert(newList);
            } else if (Trigger.isUpdate) {
                beforeUpdate(newList, oldMap);
            } else if (Trigger.isDelete) {
                beforeDelete(oldMap);
            }
        } else if (Trigger.isAfter) {
            if (Trigger.isInsert) {
                afterInsert(newList);
            } else if (Trigger.isUpdate) {
                afterUpdate(newList, oldMap);
            } else if (Trigger.isDelete) {
                afterDelete(oldMap);
            }
        }
    }

    private static void beforeInsert(List<SObject> newList) {
        ProductRuleService.beforeInsert(castNewList(newList));
    }

    private static void beforeUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<Product_Rule__c> typedNewList = castNewList(newList);
        Map<Id, Product_Rule__c> typedOldMap = castOldMap(oldMap);
        ProductRuleService.beforeUpdate(typedNewList, typedOldMap, ProductRuleDAO.getByIds(typedOldMap.keySet()));
    }

    private static void beforeDelete(Map<Id, SObject> oldMap) {
        Map<Id, Product_Rule__c> typedOldMap = castOldMap(oldMap);
        ProductRuleService.beforeDelete(typedOldMap, ProductRuleDAO.getByIds(typedOldMap.keySet()));
    }

    private static void afterInsert(List<SObject> newList) {
        List<Product_Rule__c> typedNewList = castNewList(newList);
        ProductRuleService.afterInsert(ProductRuleDAO.getByIds(collectIds(typedNewList)).values());
    }

    private static void afterUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<Product_Rule__c> typedNewList = castNewList(newList);
        Map<Id, Product_Rule__c> typedOldMap = castOldMap(oldMap);
        ProductRuleService.afterUpdate(ProductRuleDAO.getByIds(collectIds(typedNewList)).values(), typedOldMap, ProductRuleDAO.getByIds(typedOldMap.keySet()));
    }

    private static void afterDelete(Map<Id, SObject> oldMap) {
        ProductRuleService.afterDelete(castOldMap(oldMap));
    }

    private static List<Product_Rule__c> castNewList(List<SObject> rawRecords) {
        List<Product_Rule__c> typedRecords = new List<Product_Rule__c>();
        if (rawRecords == null) {
            return typedRecords;
        }
        for (SObject rawRecord : rawRecords) {
            typedRecords.add((Product_Rule__c) rawRecord);
        }
        return typedRecords;
    }

    private static Map<Id, Product_Rule__c> castOldMap(Map<Id, SObject> rawRecordsById) {
        Map<Id, Product_Rule__c> typedRecordsById = new Map<Id, Product_Rule__c>();
        if (rawRecordsById == null) {
            return typedRecordsById;
        }
        for (Id recordId : rawRecordsById.keySet()) {
            typedRecordsById.put(recordId, (Product_Rule__c) rawRecordsById.get(recordId));
        }
        return typedRecordsById;
    }

    private static Set<Id> collectIds(List<Product_Rule__c> records) {
        Set<Id> recordIds = new Set<Id>();
        for (Product_Rule__c recordItem : records) {
            if (recordItem.Id != null) {
                recordIds.add(recordItem.Id);
            }
        }
        return recordIds;
    }
}
