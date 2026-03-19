public class OpportunityTriggerHandler {
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
        OpportunityService.beforeInsert(castNewList(newList));
    }

    private static void beforeUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<Opportunity> typedNewList = castNewList(newList);
        Map<Id, Opportunity> typedOldMap = castOldMap(oldMap);
        OpportunityService.beforeUpdate(typedNewList, typedOldMap, OpportunityDAO.getByIds(typedOldMap.keySet()));
    }

    private static void beforeDelete(Map<Id, SObject> oldMap) {
        Map<Id, Opportunity> typedOldMap = castOldMap(oldMap);
        OpportunityService.beforeDelete(typedOldMap, OpportunityDAO.getByIds(typedOldMap.keySet()));
    }

    private static void afterInsert(List<SObject> newList) {
        List<Opportunity> typedNewList = castNewList(newList);
        OpportunityService.afterInsert(OpportunityDAO.getByIds(collectIds(typedNewList)).values());
    }

    private static void afterUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<Opportunity> typedNewList = castNewList(newList);
        Map<Id, Opportunity> typedOldMap = castOldMap(oldMap);
        OpportunityService.afterUpdate(OpportunityDAO.getByIds(collectIds(typedNewList)).values(), typedOldMap, OpportunityDAO.getByIds(typedOldMap.keySet()));
    }

    private static void afterDelete(Map<Id, SObject> oldMap) {
        OpportunityService.afterDelete(castOldMap(oldMap));
    }

    private static List<Opportunity> castNewList(List<SObject> rawRecords) {
        List<Opportunity> typedRecords = new List<Opportunity>();
        if (rawRecords == null) {
            return typedRecords;
        }
        for (SObject rawRecord : rawRecords) {
            typedRecords.add((Opportunity) rawRecord);
        }
        return typedRecords;
    }

    private static Map<Id, Opportunity> castOldMap(Map<Id, SObject> rawRecordsById) {
        Map<Id, Opportunity> typedRecordsById = new Map<Id, Opportunity>();
        if (rawRecordsById == null) {
            return typedRecordsById;
        }
        for (Id recordId : rawRecordsById.keySet()) {
            typedRecordsById.put(recordId, (Opportunity) rawRecordsById.get(recordId));
        }
        return typedRecordsById;
    }

    private static Set<Id> collectIds(List<Opportunity> records) {
        Set<Id> recordIds = new Set<Id>();
        for (Opportunity recordItem : records) {
            if (recordItem.Id != null) {
                recordIds.add(recordItem.Id);
            }
        }
        return recordIds;
    }
}
