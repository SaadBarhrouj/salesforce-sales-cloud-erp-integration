public class BundleRuleAssignmentTriggerHandler {
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
        BundleRuleAssignmentService.beforeInsert(castNewList(newList));
    }

    private static void beforeUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<Bundle_Rule_Assignment__c> typedNewList = castNewList(newList);
        Map<Id, Bundle_Rule_Assignment__c> typedOldMap = castOldMap(oldMap);
        BundleRuleAssignmentService.beforeUpdate(typedNewList, typedOldMap, BundleRuleAssignmentDAO.getByIds(typedOldMap.keySet()));
    }

    private static void beforeDelete(Map<Id, SObject> oldMap) {
        Map<Id, Bundle_Rule_Assignment__c> typedOldMap = castOldMap(oldMap);
        BundleRuleAssignmentService.beforeDelete(typedOldMap, BundleRuleAssignmentDAO.getByIds(typedOldMap.keySet()));
    }

    private static void afterInsert(List<SObject> newList) {
        List<Bundle_Rule_Assignment__c> typedNewList = castNewList(newList);
        BundleRuleAssignmentService.afterInsert(BundleRuleAssignmentDAO.getByIds(collectIds(typedNewList)).values());
    }

    private static void afterUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<Bundle_Rule_Assignment__c> typedNewList = castNewList(newList);
        Map<Id, Bundle_Rule_Assignment__c> typedOldMap = castOldMap(oldMap);
        BundleRuleAssignmentService.afterUpdate(BundleRuleAssignmentDAO.getByIds(collectIds(typedNewList)).values(), typedOldMap, BundleRuleAssignmentDAO.getByIds(typedOldMap.keySet()));
    }

    private static void afterDelete(Map<Id, SObject> oldMap) {
        BundleRuleAssignmentService.afterDelete(castOldMap(oldMap));
    }

    private static List<Bundle_Rule_Assignment__c> castNewList(List<SObject> rawRecords) {
        List<Bundle_Rule_Assignment__c> typedRecords = new List<Bundle_Rule_Assignment__c>();
        if (rawRecords == null) {
            return typedRecords;
        }
        for (SObject rawRecord : rawRecords) {
            typedRecords.add((Bundle_Rule_Assignment__c) rawRecord);
        }
        return typedRecords;
    }

    private static Map<Id, Bundle_Rule_Assignment__c> castOldMap(Map<Id, SObject> rawRecordsById) {
        Map<Id, Bundle_Rule_Assignment__c> typedRecordsById = new Map<Id, Bundle_Rule_Assignment__c>();
        if (rawRecordsById == null) {
            return typedRecordsById;
        }
        for (Id recordId : rawRecordsById.keySet()) {
            typedRecordsById.put(recordId, (Bundle_Rule_Assignment__c) rawRecordsById.get(recordId));
        }
        return typedRecordsById;
    }

    private static Set<Id> collectIds(List<Bundle_Rule_Assignment__c> records) {
        Set<Id> recordIds = new Set<Id>();
        for (Bundle_Rule_Assignment__c recordItem : records) {
            if (recordItem.Id != null) {
                recordIds.add(recordItem.Id);
            }
        }
        return recordIds;
    }
}
