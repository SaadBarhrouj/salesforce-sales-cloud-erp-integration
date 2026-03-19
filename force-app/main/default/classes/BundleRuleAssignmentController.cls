public with sharing class BundleRuleAssignmentController {
    @AuraEnabled(cacheable=true)
    public static Bundle_Rule_Assignment__c getById(Id recordId) {
        try {
            return BundleRuleAssignmentService.getLoadedRecord(BundleRuleAssignmentDAO.getById(recordId));
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Bundle_Rule_Assignment__c> getByIds(List<Id> recordIds) {
        try {
            Set<Id> safeIds = recordIds == null ? new Set<Id>() : new Set<Id>(recordIds);
            return BundleRuleAssignmentService.getLoadedRecords(BundleRuleAssignmentDAO.getByIds(safeIds).values());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Bundle_Rule_Assignment__c> getAll() {
        try {
            return BundleRuleAssignmentService.getLoadedRecords(BundleRuleAssignmentDAO.getAll());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled
    public static List<Bundle_Rule_Assignment__c> saveRecords(List<Bundle_Rule_Assignment__c> records) {
        try {
            Set<Id> recordIds = collectIds(records);
            Map<Id, Bundle_Rule_Assignment__c> persistedRecordsById = BundleRuleAssignmentDAO.getByIds(recordIds);
            List<Bundle_Rule_Assignment__c> savedRecords = BundleRuleAssignmentService.saveRecords(records, persistedRecordsById);
            return BundleRuleAssignmentService.getLoadedRecords(BundleRuleAssignmentDAO.getByIds(collectIds(savedRecords)).values());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled
    public static Boolean deleteRecords(List<Id> recordIds) {
        try {
            Set<Id> safeIds = recordIds == null ? new Set<Id>() : new Set<Id>(recordIds);
            Map<Id, Bundle_Rule_Assignment__c> loadedRecordsById = BundleRuleAssignmentDAO.getByIds(safeIds);
            BundleRuleAssignmentService.deleteRecords(loadedRecordsById.values());
            return true;
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    private static Set<Id> collectIds(List<Bundle_Rule_Assignment__c> records) {
        Set<Id> recordIds = new Set<Id>();
        if (records == null) {
            return recordIds;
        }
        for (Bundle_Rule_Assignment__c recordItem : records) {
            if (recordItem.Id != null) {
                recordIds.add(recordItem.Id);
            }
        }
        return recordIds;
    }

    private static String getControllerErrorMessage() {
        return String.format(System.Label.Generic_Controller_Request_Failed, new List<String>{ Bundle_Rule_Assignment__c.SObjectType.getDescribe().getLabel() });
    }
}
