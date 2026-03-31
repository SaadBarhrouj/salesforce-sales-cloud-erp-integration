public with sharing class ProductCategoryController {
    @AuraEnabled(cacheable=true)
    public static ProductCategory getById(Id recordId) {
        try {
            return ProductCategoryService.getLoadedRecord(ProductCategoryDAO.getById(recordId));
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<ProductCategory> getByIds(List<Id> recordIds) {
        try {
            Set<Id> safeIds = recordIds == null ? new Set<Id>() : new Set<Id>(recordIds);
            return ProductCategoryService.getLoadedRecords(ProductCategoryDAO.getByIds(safeIds).values());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<ProductCategory> getAll() {
        try {
            return ProductCategoryService.getLoadedRecords(ProductCategoryDAO.getAll());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled
    public static List<ProductCategory> saveRecords(List<ProductCategory> records) {
        try {
            Set<Id> recordIds = collectIds(records);
            Map<Id, ProductCategory> persistedRecordsById = ProductCategoryDAO.getByIds(recordIds);
            List<ProductCategory> savedRecords = ProductCategoryService.saveRecords(records, persistedRecordsById);
            return ProductCategoryService.getLoadedRecords(ProductCategoryDAO.getByIds(collectIds(savedRecords)).values());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled
    public static Boolean deleteRecords(List<Id> recordIds) {
        try {
            Set<Id> safeIds = recordIds == null ? new Set<Id>() : new Set<Id>(recordIds);
            Map<Id, ProductCategory> loadedRecordsById = ProductCategoryDAO.getByIds(safeIds);
            ProductCategoryService.deleteRecords(loadedRecordsById.values());
            return true;
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    private static Set<Id> collectIds(List<ProductCategory> records) {
        Set<Id> recordIds = new Set<Id>();
        if (records == null) {
            return recordIds;
        }
        for (ProductCategory recordItem : records) {
            if (recordItem.Id != null) {
                recordIds.add(recordItem.Id);
            }
        }
        return recordIds;
    }

    private static String getControllerErrorMessage() {
        return String.format(System.Label.Generic_Controller_Request_Failed, new List<String>{ ProductCategory.SObjectType.getDescribe().getLabel() });
    }
}
