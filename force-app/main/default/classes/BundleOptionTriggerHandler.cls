public class BundleOptionTriggerHandler {
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
        BundleOptionService.beforeInsert(castNewList(newList));
    }

    private static void beforeUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<Bundle_Option__c> typedNewList = castNewList(newList);
        Map<Id, Bundle_Option__c> typedOldMap = castOldMap(oldMap);
        BundleOptionService.beforeUpdate(typedNewList, typedOldMap, BundleOptionDAO.getByIds(typedOldMap.keySet()));
    }

    private static void beforeDelete(Map<Id, SObject> oldMap) {
        Map<Id, Bundle_Option__c> typedOldMap = castOldMap(oldMap);
        BundleOptionService.beforeDelete(typedOldMap, BundleOptionDAO.getByIds(typedOldMap.keySet()));
    }

    private static void afterInsert(List<SObject> newList) {
        List<Bundle_Option__c> typedNewList = castNewList(newList);
        BundleOptionService.afterInsert(BundleOptionDAO.getByIds(collectIds(typedNewList)).values());
    }

    private static void afterUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<Bundle_Option__c> typedNewList = castNewList(newList);
        Map<Id, Bundle_Option__c> typedOldMap = castOldMap(oldMap);
        BundleOptionService.afterUpdate(BundleOptionDAO.getByIds(collectIds(typedNewList)).values(), typedOldMap, BundleOptionDAO.getByIds(typedOldMap.keySet()));
    }

    private static void afterDelete(Map<Id, SObject> oldMap) {
        BundleOptionService.afterDelete(castOldMap(oldMap));
    }

    private static List<Bundle_Option__c> castNewList(List<SObject> rawRecords) {
        List<Bundle_Option__c> typedRecords = new List<Bundle_Option__c>();
        if (rawRecords == null) {
            return typedRecords;
        }
        for (SObject rawRecord : rawRecords) {
            typedRecords.add((Bundle_Option__c) rawRecord);
        }
        return typedRecords;
    }

    private static Map<Id, Bundle_Option__c> castOldMap(Map<Id, SObject> rawRecordsById) {
        Map<Id, Bundle_Option__c> typedRecordsById = new Map<Id, Bundle_Option__c>();
        if (rawRecordsById == null) {
            return typedRecordsById;
        }
        for (Id recordId : rawRecordsById.keySet()) {
            typedRecordsById.put(recordId, (Bundle_Option__c) rawRecordsById.get(recordId));
        }
        return typedRecordsById;
    }

    private static Set<Id> collectIds(List<Bundle_Option__c> records) {
        Set<Id> recordIds = new Set<Id>();
        for (Bundle_Option__c recordItem : records) {
            if (recordItem.Id != null) {
                recordIds.add(recordItem.Id);
            }
        }
        return recordIds;
    }
}
