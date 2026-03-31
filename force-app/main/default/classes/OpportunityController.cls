public with sharing class OpportunityController {
    @AuraEnabled(cacheable=true)
    public static Opportunity getById(Id recordId) {
        try {
            return OpportunityService.getLoadedRecord(OpportunityDAO.getById(recordId));
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getByIds(List<Id> recordIds) {
        try {
            Set<Id> safeIds = recordIds == null ? new Set<Id>() : new Set<Id>(recordIds);
            return OpportunityService.getLoadedRecords(OpportunityDAO.getByIds(safeIds).values());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getAll() {
        try {
            return OpportunityService.getLoadedRecords(OpportunityDAO.getAll());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled
    public static List<Opportunity> saveRecords(List<Opportunity> records) {
        try {
            Set<Id> recordIds = collectIds(records);
            Map<Id, Opportunity> persistedRecordsById = OpportunityDAO.getByIds(recordIds);
            List<Opportunity> savedRecords = OpportunityService.saveRecords(records, persistedRecordsById);
            return OpportunityService.getLoadedRecords(OpportunityDAO.getByIds(collectIds(savedRecords)).values());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled
    public static Boolean deleteRecords(List<Id> recordIds) {
        try {
            Set<Id> safeIds = recordIds == null ? new Set<Id>() : new Set<Id>(recordIds);
            Map<Id, Opportunity> loadedRecordsById = OpportunityDAO.getByIds(safeIds);
            OpportunityService.deleteRecords(loadedRecordsById.values());
            return true;
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    private static Set<Id> collectIds(List<Opportunity> records) {
        Set<Id> recordIds = new Set<Id>();
        if (records == null) {
            return recordIds;
        }
        for (Opportunity recordItem : records) {
            if (recordItem.Id != null) {
                recordIds.add(recordItem.Id);
            }
        }
        return recordIds;
    }

    private static String getControllerErrorMessage() {
        return String.format(System.Label.Generic_Controller_Request_Failed, new List<String>{ Opportunity.SObjectType.getDescribe().getLabel() });
    }
}
