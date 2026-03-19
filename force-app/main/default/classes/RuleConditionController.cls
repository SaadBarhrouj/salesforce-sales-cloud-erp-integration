public with sharing class RuleConditionController {
    @AuraEnabled(cacheable=true)
    public static Rule_Condition__c getById(Id recordId) {
        try {
            return RuleConditionService.getLoadedRecord(RuleConditionDAO.getById(recordId));
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Rule_Condition__c> getByIds(List<Id> recordIds) {
        try {
            Set<Id> safeIds = recordIds == null ? new Set<Id>() : new Set<Id>(recordIds);
            return RuleConditionService.getLoadedRecords(RuleConditionDAO.getByIds(safeIds).values());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Rule_Condition__c> getAll() {
        try {
            return RuleConditionService.getLoadedRecords(RuleConditionDAO.getAll());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled
    public static List<Rule_Condition__c> saveRecords(List<Rule_Condition__c> records) {
        try {
            Set<Id> recordIds = collectIds(records);
            Map<Id, Rule_Condition__c> persistedRecordsById = RuleConditionDAO.getByIds(recordIds);
            List<Rule_Condition__c> savedRecords = RuleConditionService.saveRecords(records, persistedRecordsById);
            return RuleConditionService.getLoadedRecords(RuleConditionDAO.getByIds(collectIds(savedRecords)).values());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled
    public static Boolean deleteRecords(List<Id> recordIds) {
        try {
            Set<Id> safeIds = recordIds == null ? new Set<Id>() : new Set<Id>(recordIds);
            Map<Id, Rule_Condition__c> loadedRecordsById = RuleConditionDAO.getByIds(safeIds);
            RuleConditionService.deleteRecords(loadedRecordsById.values());
            return true;
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    private static Set<Id> collectIds(List<Rule_Condition__c> records) {
        Set<Id> recordIds = new Set<Id>();
        if (records == null) {
            return recordIds;
        }
        for (Rule_Condition__c recordItem : records) {
            if (recordItem.Id != null) {
                recordIds.add(recordItem.Id);
            }
        }
        return recordIds;
    }

    private static String getControllerErrorMessage() {
        return String.format(System.Label.Generic_Controller_Request_Failed, new List<String>{ Rule_Condition__c.SObjectType.getDescribe().getLabel() });
    }
}
