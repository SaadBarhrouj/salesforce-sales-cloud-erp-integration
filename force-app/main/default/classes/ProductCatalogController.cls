public with sharing class ProductCatalogController {
    @AuraEnabled(cacheable=true)
    public static ProductCatalog getById(Id recordId) {
        try {
            return ProductCatalogService.getLoadedRecord(ProductCatalogDAO.getById(recordId));
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<ProductCatalog> getByIds(List<Id> recordIds) {
        try {
            Set<Id> safeIds = recordIds == null ? new Set<Id>() : new Set<Id>(recordIds);
            return ProductCatalogService.getLoadedRecords(ProductCatalogDAO.getByIds(safeIds).values());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<ProductCatalog> getAll() {
        try {
            return ProductCatalogService.getLoadedRecords(ProductCatalogDAO.getAll());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled
    public static List<ProductCatalog> saveRecords(List<ProductCatalog> records) {
        try {
            Set<Id> recordIds = collectIds(records);
            Map<Id, ProductCatalog> persistedRecordsById = ProductCatalogDAO.getByIds(recordIds);
            List<ProductCatalog> savedRecords = ProductCatalogService.saveRecords(records, persistedRecordsById);
            return ProductCatalogService.getLoadedRecords(ProductCatalogDAO.getByIds(collectIds(savedRecords)).values());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled
    public static Boolean deleteRecords(List<Id> recordIds) {
        try {
            Set<Id> safeIds = recordIds == null ? new Set<Id>() : new Set<Id>(recordIds);
            Map<Id, ProductCatalog> loadedRecordsById = ProductCatalogDAO.getByIds(safeIds);
            ProductCatalogService.deleteRecords(loadedRecordsById.values());
            return true;
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    private static Set<Id> collectIds(List<ProductCatalog> records) {
        Set<Id> recordIds = new Set<Id>();
        if (records == null) {
            return recordIds;
        }
        for (ProductCatalog recordItem : records) {
            if (recordItem.Id != null) {
                recordIds.add(recordItem.Id);
            }
        }
        return recordIds;
    }

    private static String getControllerErrorMessage() {
        return String.format(System.Label.Generic_Controller_Request_Failed, new List<String>{ ProductCatalog.SObjectType.getDescribe().getLabel() });
    }
}
