public with sharing class Product2Controller {
    @AuraEnabled(cacheable=true)
    public static Product2 getById(Id recordId) {
        try {
            return Product2Service.getLoadedRecord(Product2DAO.getById(recordId));
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Product2> getByIds(List<Id> recordIds) {
        try {
            Set<Id> safeIds = recordIds == null ? new Set<Id>() : new Set<Id>(recordIds);
            return Product2Service.getLoadedRecords(Product2DAO.getByIds(safeIds).values());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Product2> getAll() {
        try {
            return Product2Service.getLoadedRecords(Product2DAO.getAll());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled
    public static List<Product2> saveRecords(List<Product2> records) {
        try {
            Set<Id> recordIds = collectIds(records);
            Map<Id, Product2> persistedRecordsById = Product2DAO.getByIds(recordIds);
            List<Product2> savedRecords = Product2Service.saveRecords(records, persistedRecordsById);
            return Product2Service.getLoadedRecords(Product2DAO.getByIds(collectIds(savedRecords)).values());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled
    public static Boolean deleteRecords(List<Id> recordIds) {
        try {
            Set<Id> safeIds = recordIds == null ? new Set<Id>() : new Set<Id>(recordIds);
            Map<Id, Product2> loadedRecordsById = Product2DAO.getByIds(safeIds);
            Product2Service.deleteRecords(loadedRecordsById.values());
            return true;
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    private static Set<Id> collectIds(List<Product2> records) {
        Set<Id> recordIds = new Set<Id>();
        if (records == null) {
            return recordIds;
        }
        for (Product2 recordItem : records) {
            if (recordItem.Id != null) {
                recordIds.add(recordItem.Id);
            }
        }
        return recordIds;
    }

    private static String getControllerErrorMessage() {
        return String.format(System.Label.Generic_Controller_Request_Failed, new List<String>{ Product2.SObjectType.getDescribe().getLabel() });
    }
}
