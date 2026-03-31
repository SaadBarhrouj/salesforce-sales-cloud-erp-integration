public class ProductCategoryProductTriggerHandler {
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
        ProductCategoryProductService.beforeInsert(castNewList(newList));
    }

    private static void beforeUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<ProductCategoryProduct> typedNewList = castNewList(newList);
        Map<Id, ProductCategoryProduct> typedOldMap = castOldMap(oldMap);
        ProductCategoryProductService.beforeUpdate(typedNewList, typedOldMap, ProductCategoryProductDAO.getByIds(typedOldMap.keySet()));
    }

    private static void beforeDelete(Map<Id, SObject> oldMap) {
        Map<Id, ProductCategoryProduct> typedOldMap = castOldMap(oldMap);
        ProductCategoryProductService.beforeDelete(typedOldMap, ProductCategoryProductDAO.getByIds(typedOldMap.keySet()));
    }

    private static void afterInsert(List<SObject> newList) {
        List<ProductCategoryProduct> typedNewList = castNewList(newList);
        ProductCategoryProductService.afterInsert(ProductCategoryProductDAO.getByIds(collectIds(typedNewList)).values());
    }

    private static void afterUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<ProductCategoryProduct> typedNewList = castNewList(newList);
        Map<Id, ProductCategoryProduct> typedOldMap = castOldMap(oldMap);
        ProductCategoryProductService.afterUpdate(ProductCategoryProductDAO.getByIds(collectIds(typedNewList)).values(), typedOldMap, ProductCategoryProductDAO.getByIds(typedOldMap.keySet()));
    }

    private static void afterDelete(Map<Id, SObject> oldMap) {
        ProductCategoryProductService.afterDelete(castOldMap(oldMap));
    }

    private static List<ProductCategoryProduct> castNewList(List<SObject> rawRecords) {
        List<ProductCategoryProduct> typedRecords = new List<ProductCategoryProduct>();
        if (rawRecords == null) {
            return typedRecords;
        }
        for (SObject rawRecord : rawRecords) {
            typedRecords.add((ProductCategoryProduct) rawRecord);
        }
        return typedRecords;
    }

    private static Map<Id, ProductCategoryProduct> castOldMap(Map<Id, SObject> rawRecordsById) {
        Map<Id, ProductCategoryProduct> typedRecordsById = new Map<Id, ProductCategoryProduct>();
        if (rawRecordsById == null) {
            return typedRecordsById;
        }
        for (Id recordId : rawRecordsById.keySet()) {
            typedRecordsById.put(recordId, (ProductCategoryProduct) rawRecordsById.get(recordId));
        }
        return typedRecordsById;
    }

    private static Set<Id> collectIds(List<ProductCategoryProduct> records) {
        Set<Id> recordIds = new Set<Id>();
        for (ProductCategoryProduct recordItem : records) {
            if (recordItem.Id != null) {
                recordIds.add(recordItem.Id);
            }
        }
        return recordIds;
    }
}
