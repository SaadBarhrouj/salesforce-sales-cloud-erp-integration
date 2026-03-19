public class TripTriggerHandler {
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
        TripService.beforeInsert(castNewList(newList));
    }

    private static void beforeUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<Trip__c> typedNewList = castNewList(newList);
        Map<Id, Trip__c> typedOldMap = castOldMap(oldMap);
        TripService.beforeUpdate(typedNewList, typedOldMap, TripDAO.getByIds(typedOldMap.keySet()));
    }

    private static void beforeDelete(Map<Id, SObject> oldMap) {
        Map<Id, Trip__c> typedOldMap = castOldMap(oldMap);
        TripService.beforeDelete(typedOldMap, TripDAO.getByIds(typedOldMap.keySet()));
    }

    private static void afterInsert(List<SObject> newList) {
        List<Trip__c> typedNewList = castNewList(newList);
        TripService.afterInsert(TripDAO.getByIds(collectIds(typedNewList)).values());
    }

    private static void afterUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<Trip__c> typedNewList = castNewList(newList);
        Map<Id, Trip__c> typedOldMap = castOldMap(oldMap);
        TripService.afterUpdate(TripDAO.getByIds(collectIds(typedNewList)).values(), typedOldMap, TripDAO.getByIds(typedOldMap.keySet()));
    }

    private static void afterDelete(Map<Id, SObject> oldMap) {
        TripService.afterDelete(castOldMap(oldMap));
    }

    private static List<Trip__c> castNewList(List<SObject> rawRecords) {
        List<Trip__c> typedRecords = new List<Trip__c>();
        if (rawRecords == null) {
            return typedRecords;
        }
        for (SObject rawRecord : rawRecords) {
            typedRecords.add((Trip__c) rawRecord);
        }
        return typedRecords;
    }

    private static Map<Id, Trip__c> castOldMap(Map<Id, SObject> rawRecordsById) {
        Map<Id, Trip__c> typedRecordsById = new Map<Id, Trip__c>();
        if (rawRecordsById == null) {
            return typedRecordsById;
        }
        for (Id recordId : rawRecordsById.keySet()) {
            typedRecordsById.put(recordId, (Trip__c) rawRecordsById.get(recordId));
        }
        return typedRecordsById;
    }

    private static Set<Id> collectIds(List<Trip__c> records) {
        Set<Id> recordIds = new Set<Id>();
        for (Trip__c recordItem : records) {
            if (recordItem.Id != null) {
                recordIds.add(recordItem.Id);
            }
        }
        return recordIds;
    }
}
