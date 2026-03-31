public with sharing class ProductCategoryProductController {
    @AuraEnabled(cacheable=true)
    public static ProductCategoryProduct getById(Id recordId) {
        try {
            return ProductCategoryProductService.getLoadedRecord(ProductCategoryProductDAO.getById(recordId));
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<ProductCategoryProduct> getByIds(List<Id> recordIds) {
        try {
            Set<Id> safeIds = recordIds == null ? new Set<Id>() : new Set<Id>(recordIds);
            return ProductCategoryProductService.getLoadedRecords(ProductCategoryProductDAO.getByIds(safeIds).values());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<ProductCategoryProduct> getAll() {
        try {
            return ProductCategoryProductService.getLoadedRecords(ProductCategoryProductDAO.getAll());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled
    public static List<ProductCategoryProduct> saveRecords(List<ProductCategoryProduct> records) {
        try {
            Set<Id> recordIds = collectIds(records);
            Map<Id, ProductCategoryProduct> persistedRecordsById = ProductCategoryProductDAO.getByIds(recordIds);
            List<ProductCategoryProduct> savedRecords = ProductCategoryProductService.saveRecords(records, persistedRecordsById);
            return ProductCategoryProductService.getLoadedRecords(ProductCategoryProductDAO.getByIds(collectIds(savedRecords)).values());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled
    public static Boolean deleteRecords(List<Id> recordIds) {
        try {
            Set<Id> safeIds = recordIds == null ? new Set<Id>() : new Set<Id>(recordIds);
            Map<Id, ProductCategoryProduct> loadedRecordsById = ProductCategoryProductDAO.getByIds(safeIds);
            ProductCategoryProductService.deleteRecords(loadedRecordsById.values());
            return true;
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    private static Set<Id> collectIds(List<ProductCategoryProduct> records) {
        Set<Id> recordIds = new Set<Id>();
        if (records == null) {
            return recordIds;
        }
        for (ProductCategoryProduct recordItem : records) {
            if (recordItem.Id != null) {
                recordIds.add(recordItem.Id);
            }
        }
        return recordIds;
    }

    private static String getControllerErrorMessage() {
        return String.format(System.Label.Generic_Controller_Request_Failed, new List<String>{ ProductCategoryProduct.SObjectType.getDescribe().getLabel() });
    }
}
