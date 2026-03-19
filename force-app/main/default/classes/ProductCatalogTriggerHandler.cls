public class ProductCatalogTriggerHandler {
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
        ProductCatalogService.beforeInsert(castNewList(newList));
    }

    private static void beforeUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<ProductCatalog> typedNewList = castNewList(newList);
        Map<Id, ProductCatalog> typedOldMap = castOldMap(oldMap);
        ProductCatalogService.beforeUpdate(typedNewList, typedOldMap, ProductCatalogDAO.getByIds(typedOldMap.keySet()));
    }

    private static void beforeDelete(Map<Id, SObject> oldMap) {
        Map<Id, ProductCatalog> typedOldMap = castOldMap(oldMap);
        ProductCatalogService.beforeDelete(typedOldMap, ProductCatalogDAO.getByIds(typedOldMap.keySet()));
    }

    private static void afterInsert(List<SObject> newList) {
        List<ProductCatalog> typedNewList = castNewList(newList);
        ProductCatalogService.afterInsert(ProductCatalogDAO.getByIds(collectIds(typedNewList)).values());
    }

    private static void afterUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<ProductCatalog> typedNewList = castNewList(newList);
        Map<Id, ProductCatalog> typedOldMap = castOldMap(oldMap);
        ProductCatalogService.afterUpdate(ProductCatalogDAO.getByIds(collectIds(typedNewList)).values(), typedOldMap, ProductCatalogDAO.getByIds(typedOldMap.keySet()));
    }

    private static void afterDelete(Map<Id, SObject> oldMap) {
        ProductCatalogService.afterDelete(castOldMap(oldMap));
    }

    private static List<ProductCatalog> castNewList(List<SObject> rawRecords) {
        List<ProductCatalog> typedRecords = new List<ProductCatalog>();
        if (rawRecords == null) {
            return typedRecords;
        }
        for (SObject rawRecord : rawRecords) {
            typedRecords.add((ProductCatalog) rawRecord);
        }
        return typedRecords;
    }

    private static Map<Id, ProductCatalog> castOldMap(Map<Id, SObject> rawRecordsById) {
        Map<Id, ProductCatalog> typedRecordsById = new Map<Id, ProductCatalog>();
        if (rawRecordsById == null) {
            return typedRecordsById;
        }
        for (Id recordId : rawRecordsById.keySet()) {
            typedRecordsById.put(recordId, (ProductCatalog) rawRecordsById.get(recordId));
        }
        return typedRecordsById;
    }

    private static Set<Id> collectIds(List<ProductCatalog> records) {
        Set<Id> recordIds = new Set<Id>();
        for (ProductCatalog recordItem : records) {
            if (recordItem.Id != null) {
                recordIds.add(recordItem.Id);
            }
        }
        return recordIds;
    }
}
