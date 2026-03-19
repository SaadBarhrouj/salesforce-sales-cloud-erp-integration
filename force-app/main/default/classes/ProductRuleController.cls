public with sharing class ProductRuleController {
    @AuraEnabled(cacheable=true)
    public static Product_Rule__c getById(Id recordId) {
        try {
            return ProductRuleService.getLoadedRecord(ProductRuleDAO.getById(recordId));
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Product_Rule__c> getByIds(List<Id> recordIds) {
        try {
            Set<Id> safeIds = recordIds == null ? new Set<Id>() : new Set<Id>(recordIds);
            return ProductRuleService.getLoadedRecords(ProductRuleDAO.getByIds(safeIds).values());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Product_Rule__c> getAll() {
        try {
            return ProductRuleService.getLoadedRecords(ProductRuleDAO.getAll());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled
    public static List<Product_Rule__c> saveRecords(List<Product_Rule__c> records) {
        try {
            Set<Id> recordIds = collectIds(records);
            Map<Id, Product_Rule__c> persistedRecordsById = ProductRuleDAO.getByIds(recordIds);
            List<Product_Rule__c> savedRecords = ProductRuleService.saveRecords(records, persistedRecordsById);
            return ProductRuleService.getLoadedRecords(ProductRuleDAO.getByIds(collectIds(savedRecords)).values());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled
    public static Boolean deleteRecords(List<Id> recordIds) {
        try {
            Set<Id> safeIds = recordIds == null ? new Set<Id>() : new Set<Id>(recordIds);
            Map<Id, Product_Rule__c> loadedRecordsById = ProductRuleDAO.getByIds(safeIds);
            ProductRuleService.deleteRecords(loadedRecordsById.values());
            return true;
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    private static Set<Id> collectIds(List<Product_Rule__c> records) {
        Set<Id> recordIds = new Set<Id>();
        if (records == null) {
            return recordIds;
        }
        for (Product_Rule__c recordItem : records) {
            if (recordItem.Id != null) {
                recordIds.add(recordItem.Id);
            }
        }
        return recordIds;
    }

    private static String getControllerErrorMessage() {
        return String.format(System.Label.Generic_Controller_Request_Failed, new List<String>{ Product_Rule__c.SObjectType.getDescribe().getLabel() });
    }
}
