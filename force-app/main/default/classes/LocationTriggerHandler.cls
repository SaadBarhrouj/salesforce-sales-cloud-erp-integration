public class LocationTriggerHandler {
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
        LocationService.beforeInsert(castNewList(newList));
    }

    private static void beforeUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<Location> typedNewList = castNewList(newList);
        Map<Id, Location> typedOldMap = castOldMap(oldMap);
        LocationService.beforeUpdate(typedNewList, typedOldMap, LocationDAO.getByIds(typedOldMap.keySet()));
    }

    private static void beforeDelete(Map<Id, SObject> oldMap) {
        Map<Id, Location> typedOldMap = castOldMap(oldMap);
        LocationService.beforeDelete(typedOldMap, LocationDAO.getByIds(typedOldMap.keySet()));
    }

    private static void afterInsert(List<SObject> newList) {
        List<Location> typedNewList = castNewList(newList);
        LocationService.afterInsert(LocationDAO.getByIds(collectIds(typedNewList)).values());
    }

    private static void afterUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<Location> typedNewList = castNewList(newList);
        Map<Id, Location> typedOldMap = castOldMap(oldMap);
        LocationService.afterUpdate(LocationDAO.getByIds(collectIds(typedNewList)).values(), typedOldMap, LocationDAO.getByIds(typedOldMap.keySet()));
    }

    private static void afterDelete(Map<Id, SObject> oldMap) {
        LocationService.afterDelete(castOldMap(oldMap));
    }

    private static List<Location> castNewList(List<SObject> rawRecords) {
        List<Location> typedRecords = new List<Location>();
        if (rawRecords == null) {
            return typedRecords;
        }
        for (SObject rawRecord : rawRecords) {
            typedRecords.add((Location) rawRecord);
        }
        return typedRecords;
    }

    private static Map<Id, Location> castOldMap(Map<Id, SObject> rawRecordsById) {
        Map<Id, Location> typedRecordsById = new Map<Id, Location>();
        if (rawRecordsById == null) {
            return typedRecordsById;
        }
        for (Id recordId : rawRecordsById.keySet()) {
            typedRecordsById.put(recordId, (Location) rawRecordsById.get(recordId));
        }
        return typedRecordsById;
    }

    private static Set<Id> collectIds(List<Location> records) {
        Set<Id> recordIds = new Set<Id>();
        for (Location recordItem : records) {
            if (recordItem.Id != null) {
                recordIds.add(recordItem.Id);
            }
        }
        return recordIds;
    }
}
