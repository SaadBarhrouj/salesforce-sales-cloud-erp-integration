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

    /**
     * @description Handles before insert trigger event for Product2.
     * @param newList The list of new Product2 records.
     */
    private static void beforeInsert(List<SObject> newList) {
        Product2Service.beforeInsert(castNewList(newList));
    }

    /**
     * @description Handles before update trigger event for Product2.
     * @param newList The list of new Product2 records.
     * @param oldMap Map of old Product2 records by ID.
     */
    private static void beforeUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<Product2> typedNewList = castNewList(newList);
        Map<Id, Product2> typedOldMap = castOldMap(oldMap);
        Product2Service.beforeUpdate(typedNewList, typedOldMap, Product2DAO.getByIds(typedOldMap.keySet()));
    }

    /**
     * @description Handles before delete trigger event for Product2.
     * @param oldMap Map of old Product2 records by ID.
     */
    private static void beforeDelete(Map<Id, SObject> oldMap) {
        Map<Id, Product2> typedOldMap = castOldMap(oldMap);
        Product2Service.beforeDelete(typedOldMap, Product2DAO.getByIds(typedOldMap.keySet()));
    }

    /**
     * @description Handles after insert trigger event for Product2.
     * @param newList The list of new Product2 records.
     */
    private static void afterInsert(List<SObject> newList) {
        List<Product2> typedNewList = castNewList(newList);
        Product2Service.afterInsert(Product2DAO.getByIds(collectIds(typedNewList)).values());
    }

    /**
     * @description Handles after update trigger event for Product2.
     * @param newList The list of new Product2 records.
     * @param oldMap Map of old Product2 records by ID.
     */
    private static void afterUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<Product2> typedNewList = castNewList(newList);
        Map<Id, Product2> typedOldMap = castOldMap(oldMap);
        Product2Service.afterUpdate(Product2DAO.getByIds(collectIds(typedNewList)).values(), typedOldMap, Product2DAO.getByIds(typedOldMap.keySet()));
    }

    /**
     * @description Handles after delete trigger event for Product2.
     * @param oldMap Map of old Product2 records by ID.
     */
    private static void afterDelete(Map<Id, SObject> oldMap) {
        Product2Service.afterDelete(castOldMap(oldMap));
    }

    /**
     * @description Casts a list of generic SObjects to a typed list of Product2 records.
     * @param rawRecords The list of generic SObject records.
     * @return Typed list of Product2 records.
     */
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

    /**
     * @description Casts a map of generic SObjects to a typed map of Product2 records.
     * @param rawRecordsById Map of generic SObject records by ID.
     * @return Typed map of Product2 records by ID.
     */
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

    /**
     * @description Collects non-null IDs from a list of Product2 records.
     * @param records The list of Product2 records to extract IDs from.
     * @return Set of non-null Product2 IDs.
     */
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