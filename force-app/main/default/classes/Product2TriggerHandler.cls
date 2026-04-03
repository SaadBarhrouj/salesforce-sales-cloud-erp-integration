/**
 * @description Trigger handler for Product2 records.
 * Delegates trigger events to Product2Service for business logic execution.
 */
public class Product2TriggerHandler {
    /**
     * @description Routes trigger events to the appropriate handler method.
     * @param newList The list of new Product2 records (null for delete operations).
     * @param oldMap Map of old Product2 records by ID (null for insert operations).
     */
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
        Product2Service.beforeInsert(castNewList(newList));
    }

    private static void beforeUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<Product2> typedNewList = castNewList(newList);
        Map<Id, Product2> typedOldMap = castOldMap(oldMap);
        Product2Service.beforeUpdate(typedNewList, typedOldMap, Product2DAO.getByIds(typedOldMap.keySet()));
    }

    private static void beforeDelete(Map<Id, SObject> oldMap) {
        Map<Id, Product2> typedOldMap = castOldMap(oldMap);
        Product2Service.beforeDelete(typedOldMap, Product2DAO.getByIds(typedOldMap.keySet()));
    }

    private static void afterInsert(List<SObject> newList) {
        List<Product2> typedNewList = castNewList(newList);
        Product2Service.afterInsert(Product2DAO.getByIds(collectIds(typedNewList)).values());
    }

    private static void afterUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<Product2> typedNewList = castNewList(newList);
        Map<Id, Product2> typedOldMap = castOldMap(oldMap);
        Product2Service.afterUpdate(Product2DAO.getByIds(collectIds(typedNewList)).values(), typedOldMap, Product2DAO.getByIds(typedOldMap.keySet()));
    }

    private static void afterDelete(Map<Id, SObject> oldMap) {
        Product2Service.afterDelete(castOldMap(oldMap));
    }

    private static List<Product2> castNewList(List<SObject> rawRecords) {
        List<Product2> typedRecords = new List<Product2>();
        if (rawRecords == null) {
            return typedRecords;
        }
        for (SObject rawRecord : rawRecords) {
            typedRecords.add((Product2) rawRecord);
        }
        return typedRecords;
    }

    private static Map<Id, Product2> castOldMap(Map<Id, SObject> rawRecordsById) {
        Map<Id, Product2> typedRecordsById = new Map<Id, Product2>();
        if (rawRecordsById == null) {
            return typedRecordsById;
        }
        for (Id recordId : rawRecordsById.keySet()) {
            typedRecordsById.put(recordId, (Product2) rawRecordsById.get(recordId));
        }
        return typedRecordsById;
    }

    private static Set<Id> collectIds(List<Product2> records) {
        Set<Id> recordIds = new Set<Id>();
        for (Product2 recordItem : records) {
            if (recordItem.Id != null) {
                recordIds.add(recordItem.Id);
            }
        }
        return recordIds;
    }
}
