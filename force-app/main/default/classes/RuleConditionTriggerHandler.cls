public class RuleConditionTriggerHandler {
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
        RuleConditionService.beforeInsert(castNewList(newList));
    }

    private static void beforeUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<Rule_Condition__c> typedNewList = castNewList(newList);
        Map<Id, Rule_Condition__c> typedOldMap = castOldMap(oldMap);
        RuleConditionService.beforeUpdate(typedNewList, typedOldMap, RuleConditionDAO.getByIds(typedOldMap.keySet()));
    }

    private static void beforeDelete(Map<Id, SObject> oldMap) {
        Map<Id, Rule_Condition__c> typedOldMap = castOldMap(oldMap);
        RuleConditionService.beforeDelete(typedOldMap, RuleConditionDAO.getByIds(typedOldMap.keySet()));
    }

    private static void afterInsert(List<SObject> newList) {
        List<Rule_Condition__c> typedNewList = castNewList(newList);
        RuleConditionService.afterInsert(RuleConditionDAO.getByIds(collectIds(typedNewList)).values());
    }

    private static void afterUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<Rule_Condition__c> typedNewList = castNewList(newList);
        Map<Id, Rule_Condition__c> typedOldMap = castOldMap(oldMap);
        RuleConditionService.afterUpdate(RuleConditionDAO.getByIds(collectIds(typedNewList)).values(), typedOldMap, RuleConditionDAO.getByIds(typedOldMap.keySet()));
    }

    private static void afterDelete(Map<Id, SObject> oldMap) {
        RuleConditionService.afterDelete(castOldMap(oldMap));
    }

    private static List<Rule_Condition__c> castNewList(List<SObject> rawRecords) {
        List<Rule_Condition__c> typedRecords = new List<Rule_Condition__c>();
        if (rawRecords == null) {
            return typedRecords;
        }
        for (SObject rawRecord : rawRecords) {
            typedRecords.add((Rule_Condition__c) rawRecord);
        }
        return typedRecords;
    }

    private static Map<Id, Rule_Condition__c> castOldMap(Map<Id, SObject> rawRecordsById) {
        Map<Id, Rule_Condition__c> typedRecordsById = new Map<Id, Rule_Condition__c>();
        if (rawRecordsById == null) {
            return typedRecordsById;
        }
        for (Id recordId : rawRecordsById.keySet()) {
            typedRecordsById.put(recordId, (Rule_Condition__c) rawRecordsById.get(recordId));
        }
        return typedRecordsById;
    }

    private static Set<Id> collectIds(List<Rule_Condition__c> records) {
        Set<Id> recordIds = new Set<Id>();
        for (Rule_Condition__c recordItem : records) {
            if (recordItem.Id != null) {
                recordIds.add(recordItem.Id);
            }
        }
        return recordIds;
    }
}
