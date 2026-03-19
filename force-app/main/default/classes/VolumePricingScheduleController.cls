public with sharing class VolumePricingScheduleController {
    @AuraEnabled(cacheable=true)
    public static Volume_Pricing_Schedule__c getById(Id recordId) {
        try {
            return VolumePricingScheduleService.getLoadedRecord(VolumePricingScheduleDAO.getById(recordId));
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Volume_Pricing_Schedule__c> getByIds(List<Id> recordIds) {
        try {
            Set<Id> safeIds = recordIds == null ? new Set<Id>() : new Set<Id>(recordIds);
            return VolumePricingScheduleService.getLoadedRecords(VolumePricingScheduleDAO.getByIds(safeIds).values());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Volume_Pricing_Schedule__c> getAll() {
        try {
            return VolumePricingScheduleService.getLoadedRecords(VolumePricingScheduleDAO.getAll());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled
    public static List<Volume_Pricing_Schedule__c> saveRecords(List<Volume_Pricing_Schedule__c> records) {
        try {
            Set<Id> recordIds = collectIds(records);
            Map<Id, Volume_Pricing_Schedule__c> persistedRecordsById = VolumePricingScheduleDAO.getByIds(recordIds);
            List<Volume_Pricing_Schedule__c> savedRecords = VolumePricingScheduleService.saveRecords(records, persistedRecordsById);
            return VolumePricingScheduleService.getLoadedRecords(VolumePricingScheduleDAO.getByIds(collectIds(savedRecords)).values());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled
    public static Boolean deleteRecords(List<Id> recordIds) {
        try {
            Set<Id> safeIds = recordIds == null ? new Set<Id>() : new Set<Id>(recordIds);
            Map<Id, Volume_Pricing_Schedule__c> loadedRecordsById = VolumePricingScheduleDAO.getByIds(safeIds);
            VolumePricingScheduleService.deleteRecords(loadedRecordsById.values());
            return true;
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    private static Set<Id> collectIds(List<Volume_Pricing_Schedule__c> records) {
        Set<Id> recordIds = new Set<Id>();
        if (records == null) {
            return recordIds;
        }
        for (Volume_Pricing_Schedule__c recordItem : records) {
            if (recordItem.Id != null) {
                recordIds.add(recordItem.Id);
            }
        }
        return recordIds;
    }

    private static String getControllerErrorMessage() {
        return String.format(System.Label.Generic_Controller_Request_Failed, new List<String>{ Volume_Pricing_Schedule__c.SObjectType.getDescribe().getLabel() });
    }
}
