public with sharing class RuleActionController {
    @AuraEnabled(cacheable=true)
    public static Rule_Action__c getById(Id recordId) {
        try {
            return RuleActionService.getLoadedRecord(RuleActionDAO.getById(recordId));
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Rule_Action__c> getByIds(List<Id> recordIds) {
        try {
            Set<Id> safeIds = recordIds == null ? new Set<Id>() : new Set<Id>(recordIds);
            return RuleActionService.getLoadedRecords(RuleActionDAO.getByIds(safeIds).values());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Rule_Action__c> getAll() {
        try {
            return RuleActionService.getLoadedRecords(RuleActionDAO.getAll());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled
    public static List<Rule_Action__c> saveRecords(List<Rule_Action__c> records) {
        try {
            Set<Id> recordIds = collectIds(records);
            Map<Id, Rule_Action__c> persistedRecordsById = RuleActionDAO.getByIds(recordIds);
            List<Rule_Action__c> savedRecords = RuleActionService.saveRecords(records, persistedRecordsById);
            return RuleActionService.getLoadedRecords(RuleActionDAO.getByIds(collectIds(savedRecords)).values());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled
    public static Boolean deleteRecords(List<Id> recordIds) {
        try {
            Set<Id> safeIds = recordIds == null ? new Set<Id>() : new Set<Id>(recordIds);
            Map<Id, Rule_Action__c> loadedRecordsById = RuleActionDAO.getByIds(safeIds);
            RuleActionService.deleteRecords(loadedRecordsById.values());
            return true;
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    private static Set<Id> collectIds(List<Rule_Action__c> records) {
        Set<Id> recordIds = new Set<Id>();
        if (records == null) {
            return recordIds;
        }
        for (Rule_Action__c recordItem : records) {
            if (recordItem.Id != null) {
                recordIds.add(recordItem.Id);
            }
        }
        return recordIds;
    }

    private static String getControllerErrorMessage() {
        return String.format(System.Label.Generic_Controller_Request_Failed, new List<String>{ Rule_Action__c.SObjectType.getDescribe().getLabel() });
    }
}
