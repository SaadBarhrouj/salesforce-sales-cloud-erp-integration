public class RuleActionTriggerHandler {
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
        RuleActionService.beforeInsert(castNewList(newList));
    }

    private static void beforeUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<Rule_Action__c> typedNewList = castNewList(newList);
        Map<Id, Rule_Action__c> typedOldMap = castOldMap(oldMap);
        RuleActionService.beforeUpdate(typedNewList, typedOldMap, RuleActionDAO.getByIds(typedOldMap.keySet()));
    }

    private static void beforeDelete(Map<Id, SObject> oldMap) {
        Map<Id, Rule_Action__c> typedOldMap = castOldMap(oldMap);
        RuleActionService.beforeDelete(typedOldMap, RuleActionDAO.getByIds(typedOldMap.keySet()));
    }

    private static void afterInsert(List<SObject> newList) {
        List<Rule_Action__c> typedNewList = castNewList(newList);
        RuleActionService.afterInsert(RuleActionDAO.getByIds(collectIds(typedNewList)).values());
    }

    private static void afterUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<Rule_Action__c> typedNewList = castNewList(newList);
        Map<Id, Rule_Action__c> typedOldMap = castOldMap(oldMap);
        RuleActionService.afterUpdate(RuleActionDAO.getByIds(collectIds(typedNewList)).values(), typedOldMap, RuleActionDAO.getByIds(typedOldMap.keySet()));
    }

    private static void afterDelete(Map<Id, SObject> oldMap) {
        RuleActionService.afterDelete(castOldMap(oldMap));
    }

    private static List<Rule_Action__c> castNewList(List<SObject> rawRecords) {
        List<Rule_Action__c> typedRecords = new List<Rule_Action__c>();
        if (rawRecords == null) {
            return typedRecords;
        }
        for (SObject rawRecord : rawRecords) {
            typedRecords.add((Rule_Action__c) rawRecord);
        }
        return typedRecords;
    }

    private static Map<Id, Rule_Action__c> castOldMap(Map<Id, SObject> rawRecordsById) {
        Map<Id, Rule_Action__c> typedRecordsById = new Map<Id, Rule_Action__c>();
        if (rawRecordsById == null) {
            return typedRecordsById;
        }
        for (Id recordId : rawRecordsById.keySet()) {
            typedRecordsById.put(recordId, (Rule_Action__c) rawRecordsById.get(recordId));
        }
        return typedRecordsById;
    }

    private static Set<Id> collectIds(List<Rule_Action__c> records) {
        Set<Id> recordIds = new Set<Id>();
        for (Rule_Action__c recordItem : records) {
            if (recordItem.Id != null) {
                recordIds.add(recordItem.Id);
            }
        }
        return recordIds;
    }
}
