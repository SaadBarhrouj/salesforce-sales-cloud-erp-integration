public class OpportunityLineItemTriggerHandler {
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
        OpportunityLineItemService.beforeInsert(castNewList(newList));
    }

    private static void beforeUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<OpportunityLineItem> typedNewList = castNewList(newList);
        Map<Id, OpportunityLineItem> typedOldMap = castOldMap(oldMap);
        OpportunityLineItemService.beforeUpdate(typedNewList, typedOldMap, OpportunityLineItemDAO.getByIds(typedOldMap.keySet()));
    }

    private static void beforeDelete(Map<Id, SObject> oldMap) {
        Map<Id, OpportunityLineItem> typedOldMap = castOldMap(oldMap);
        OpportunityLineItemService.beforeDelete(typedOldMap, OpportunityLineItemDAO.getByIds(typedOldMap.keySet()));
    }

    private static void afterInsert(List<SObject> newList) {
        List<OpportunityLineItem> typedNewList = castNewList(newList);
        OpportunityLineItemService.afterInsert(OpportunityLineItemDAO.getByIds(collectIds(typedNewList)).values());
    }

    private static void afterUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<OpportunityLineItem> typedNewList = castNewList(newList);
        Map<Id, OpportunityLineItem> typedOldMap = castOldMap(oldMap);
        OpportunityLineItemService.afterUpdate(OpportunityLineItemDAO.getByIds(collectIds(typedNewList)).values(), typedOldMap, OpportunityLineItemDAO.getByIds(typedOldMap.keySet()));
    }

    private static void afterDelete(Map<Id, SObject> oldMap) {
        OpportunityLineItemService.afterDelete(castOldMap(oldMap));
    }

    private static List<OpportunityLineItem> castNewList(List<SObject> rawRecords) {
        List<OpportunityLineItem> typedRecords = new List<OpportunityLineItem>();
        if (rawRecords == null) {
            return typedRecords;
        }
        for (SObject rawRecord : rawRecords) {
            typedRecords.add((OpportunityLineItem) rawRecord);
        }
        return typedRecords;
    }

    private static Map<Id, OpportunityLineItem> castOldMap(Map<Id, SObject> rawRecordsById) {
        Map<Id, OpportunityLineItem> typedRecordsById = new Map<Id, OpportunityLineItem>();
        if (rawRecordsById == null) {
            return typedRecordsById;
        }
        for (Id recordId : rawRecordsById.keySet()) {
            typedRecordsById.put(recordId, (OpportunityLineItem) rawRecordsById.get(recordId));
        }
        return typedRecordsById;
    }

    private static Set<Id> collectIds(List<OpportunityLineItem> records) {
        Set<Id> recordIds = new Set<Id>();
        for (OpportunityLineItem recordItem : records) {
            if (recordItem.Id != null) {
                recordIds.add(recordItem.Id);
            }
        }
        return recordIds;
    }
}
