public with sharing class BundleOptionController {
    @AuraEnabled(cacheable=true)
    public static Bundle_Option__c getById(Id recordId) {
        try {
            return BundleOptionService.getLoadedRecord(BundleOptionDAO.getById(recordId));
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Bundle_Option__c> getByIds(List<Id> recordIds) {
        try {
            Set<Id> safeIds = recordIds == null ? new Set<Id>() : new Set<Id>(recordIds);
            return BundleOptionService.getLoadedRecords(BundleOptionDAO.getByIds(safeIds).values());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Bundle_Option__c> getAll() {
        try {
            return BundleOptionService.getLoadedRecords(BundleOptionDAO.getAll());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled
    public static List<Bundle_Option__c> saveRecords(List<Bundle_Option__c> records) {
        try {
            Set<Id> recordIds = collectIds(records);
            Map<Id, Bundle_Option__c> persistedRecordsById = BundleOptionDAO.getByIds(recordIds);
            List<Bundle_Option__c> savedRecords = BundleOptionService.saveRecords(records, persistedRecordsById);
            return BundleOptionService.getLoadedRecords(BundleOptionDAO.getByIds(collectIds(savedRecords)).values());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled
    public static Boolean deleteRecords(List<Id> recordIds) {
        try {
            Set<Id> safeIds = recordIds == null ? new Set<Id>() : new Set<Id>(recordIds);
            Map<Id, Bundle_Option__c> loadedRecordsById = BundleOptionDAO.getByIds(safeIds);
            BundleOptionService.deleteRecords(loadedRecordsById.values());
            return true;
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    private static Set<Id> collectIds(List<Bundle_Option__c> records) {
        Set<Id> recordIds = new Set<Id>();
        if (records == null) {
            return recordIds;
        }
        for (Bundle_Option__c recordItem : records) {
            if (recordItem.Id != null) {
                recordIds.add(recordItem.Id);
            }
        }
        return recordIds;
    }

    private static String getControllerErrorMessage() {
        return String.format(System.Label.Generic_Controller_Request_Failed, new List<String>{ Bundle_Option__c.SObjectType.getDescribe().getLabel() });
    }
}
