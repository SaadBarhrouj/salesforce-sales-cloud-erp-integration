public with sharing class BundleFeatureController {
    @AuraEnabled(cacheable=true)
    public static Bundle_Feature__c getById(Id recordId) {
        try {
            return BundleFeatureService.getLoadedRecord(BundleFeatureDAO.getById(recordId));
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Bundle_Feature__c> getByIds(List<Id> recordIds) {
        try {
            Set<Id> safeIds = recordIds == null ? new Set<Id>() : new Set<Id>(recordIds);
            return BundleFeatureService.getLoadedRecords(BundleFeatureDAO.getByIds(safeIds).values());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Bundle_Feature__c> getAll() {
        try {
            return BundleFeatureService.getLoadedRecords(BundleFeatureDAO.getAll());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled
    public static List<Bundle_Feature__c> saveRecords(List<Bundle_Feature__c> records) {
        try {
            Set<Id> recordIds = collectIds(records);
            Map<Id, Bundle_Feature__c> persistedRecordsById = BundleFeatureDAO.getByIds(recordIds);
            List<Bundle_Feature__c> savedRecords = BundleFeatureService.saveRecords(records, persistedRecordsById);
            return BundleFeatureService.getLoadedRecords(BundleFeatureDAO.getByIds(collectIds(savedRecords)).values());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled
    public static Boolean deleteRecords(List<Id> recordIds) {
        try {
            Set<Id> safeIds = recordIds == null ? new Set<Id>() : new Set<Id>(recordIds);
            Map<Id, Bundle_Feature__c> loadedRecordsById = BundleFeatureDAO.getByIds(safeIds);
            BundleFeatureService.deleteRecords(loadedRecordsById.values());
            return true;
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    private static Set<Id> collectIds(List<Bundle_Feature__c> records) {
        Set<Id> recordIds = new Set<Id>();
        if (records == null) {
            return recordIds;
        }
        for (Bundle_Feature__c recordItem : records) {
            if (recordItem.Id != null) {
                recordIds.add(recordItem.Id);
            }
        }
        return recordIds;
    }

    private static String getControllerErrorMessage() {
        return String.format(System.Label.Generic_Controller_Request_Failed, new List<String>{ Bundle_Feature__c.SObjectType.getDescribe().getLabel() });
    }
}
