public with sharing class OpportunityLineItemController {
    @AuraEnabled(cacheable=true)
    public static OpportunityLineItem getById(Id recordId) {
        try {
            return OpportunityLineItemService.getLoadedRecord(OpportunityLineItemDAO.getById(recordId));
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<OpportunityLineItem> getByIds(List<Id> recordIds) {
        try {
            Set<Id> safeIds = recordIds == null ? new Set<Id>() : new Set<Id>(recordIds);
            return OpportunityLineItemService.getLoadedRecords(OpportunityLineItemDAO.getByIds(safeIds).values());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<OpportunityLineItem> getAll() {
        try {
            return OpportunityLineItemService.getLoadedRecords(OpportunityLineItemDAO.getAll());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled
    public static List<OpportunityLineItem> saveRecords(List<OpportunityLineItem> records) {
        try {
            Set<Id> recordIds = collectIds(records);
            Map<Id, OpportunityLineItem> persistedRecordsById = OpportunityLineItemDAO.getByIds(recordIds);
            List<OpportunityLineItem> savedRecords = OpportunityLineItemService.saveRecords(records, persistedRecordsById);
            return OpportunityLineItemService.getLoadedRecords(OpportunityLineItemDAO.getByIds(collectIds(savedRecords)).values());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled
    public static Boolean deleteRecords(List<Id> recordIds) {
        try {
            Set<Id> safeIds = recordIds == null ? new Set<Id>() : new Set<Id>(recordIds);
            Map<Id, OpportunityLineItem> loadedRecordsById = OpportunityLineItemDAO.getByIds(safeIds);
            OpportunityLineItemService.deleteRecords(loadedRecordsById.values());
            return true;
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    private static Set<Id> collectIds(List<OpportunityLineItem> records) {
        Set<Id> recordIds = new Set<Id>();
        if (records == null) {
            return recordIds;
        }
        for (OpportunityLineItem recordItem : records) {
            if (recordItem.Id != null) {
                recordIds.add(recordItem.Id);
            }
        }
        return recordIds;
    }

    private static String getControllerErrorMessage() {
        return String.format(System.Label.Generic_Controller_Request_Failed, new List<String>{ OpportunityLineItem.SObjectType.getDescribe().getLabel() });
    }
}
