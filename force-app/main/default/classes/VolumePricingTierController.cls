public with sharing class VolumePricingTierController {
    @AuraEnabled(cacheable=true)
    public static Volume_Pricing_Tier__c getById(Id recordId) {
        try {
            return VolumePricingTierService.getLoadedRecord(VolumePricingTierDAO.getById(recordId));
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Volume_Pricing_Tier__c> getByIds(List<Id> recordIds) {
        try {
            Set<Id> safeIds = recordIds == null ? new Set<Id>() : new Set<Id>(recordIds);
            return VolumePricingTierService.getLoadedRecords(VolumePricingTierDAO.getByIds(safeIds).values());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Volume_Pricing_Tier__c> getAll() {
        try {
            return VolumePricingTierService.getLoadedRecords(VolumePricingTierDAO.getAll());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled
    public static List<Volume_Pricing_Tier__c> saveRecords(List<Volume_Pricing_Tier__c> records) {
        try {
            Set<Id> recordIds = collectIds(records);
            Map<Id, Volume_Pricing_Tier__c> persistedRecordsById = VolumePricingTierDAO.getByIds(recordIds);
            List<Volume_Pricing_Tier__c> savedRecords = VolumePricingTierService.saveRecords(records, persistedRecordsById);
            return VolumePricingTierService.getLoadedRecords(VolumePricingTierDAO.getByIds(collectIds(savedRecords)).values());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled
    public static Boolean deleteRecords(List<Id> recordIds) {
        try {
            Set<Id> safeIds = recordIds == null ? new Set<Id>() : new Set<Id>(recordIds);
            Map<Id, Volume_Pricing_Tier__c> loadedRecordsById = VolumePricingTierDAO.getByIds(safeIds);
            VolumePricingTierService.deleteRecords(loadedRecordsById.values());
            return true;
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    private static Set<Id> collectIds(List<Volume_Pricing_Tier__c> records) {
        Set<Id> recordIds = new Set<Id>();
        if (records == null) {
            return recordIds;
        }
        for (Volume_Pricing_Tier__c recordItem : records) {
            if (recordItem.Id != null) {
                recordIds.add(recordItem.Id);
            }
        }
        return recordIds;
    }

    private static String getControllerErrorMessage() {
        return String.format(System.Label.Generic_Controller_Request_Failed, new List<String>{ Volume_Pricing_Tier__c.SObjectType.getDescribe().getLabel() });
    }
}
