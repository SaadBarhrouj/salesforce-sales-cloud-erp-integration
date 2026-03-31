public class ProductCategoryTriggerHandler {
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
        ProductCategoryService.beforeInsert(castNewList(newList));
    }

    private static void beforeUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<ProductCategory> typedNewList = castNewList(newList);
        Map<Id, ProductCategory> typedOldMap = castOldMap(oldMap);
        ProductCategoryService.beforeUpdate(typedNewList, typedOldMap, ProductCategoryDAO.getByIds(typedOldMap.keySet()));
    }

    private static void beforeDelete(Map<Id, SObject> oldMap) {
        Map<Id, ProductCategory> typedOldMap = castOldMap(oldMap);
        ProductCategoryService.beforeDelete(typedOldMap, ProductCategoryDAO.getByIds(typedOldMap.keySet()));
    }

    private static void afterInsert(List<SObject> newList) {
        List<ProductCategory> typedNewList = castNewList(newList);
        ProductCategoryService.afterInsert(ProductCategoryDAO.getByIds(collectIds(typedNewList)).values());
    }

    private static void afterUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<ProductCategory> typedNewList = castNewList(newList);
        Map<Id, ProductCategory> typedOldMap = castOldMap(oldMap);
        ProductCategoryService.afterUpdate(ProductCategoryDAO.getByIds(collectIds(typedNewList)).values(), typedOldMap, ProductCategoryDAO.getByIds(typedOldMap.keySet()));
    }

    private static void afterDelete(Map<Id, SObject> oldMap) {
        ProductCategoryService.afterDelete(castOldMap(oldMap));
    }

    private static List<ProductCategory> castNewList(List<SObject> rawRecords) {
        List<ProductCategory> typedRecords = new List<ProductCategory>();
        if (rawRecords == null) {
            return typedRecords;
        }
        for (SObject rawRecord : rawRecords) {
            typedRecords.add((ProductCategory) rawRecord);
        }
        return typedRecords;
    }

    private static Map<Id, ProductCategory> castOldMap(Map<Id, SObject> rawRecordsById) {
        Map<Id, ProductCategory> typedRecordsById = new Map<Id, ProductCategory>();
        if (rawRecordsById == null) {
            return typedRecordsById;
        }
        for (Id recordId : rawRecordsById.keySet()) {
            typedRecordsById.put(recordId, (ProductCategory) rawRecordsById.get(recordId));
        }
        return typedRecordsById;
    }

    private static Set<Id> collectIds(List<ProductCategory> records) {
        Set<Id> recordIds = new Set<Id>();
        for (ProductCategory recordItem : records) {
            if (recordItem.Id != null) {
                recordIds.add(recordItem.Id);
            }
        }
        return recordIds;
    }
}
