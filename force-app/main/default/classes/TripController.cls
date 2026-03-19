public with sharing class TripController {
    @AuraEnabled(cacheable=true)
    public static Trip__c getById(Id recordId) {
        try {
            return TripService.getLoadedRecord(TripDAO.getById(recordId));
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Trip__c> getByIds(List<Id> recordIds) {
        try {
            Set<Id> safeIds = recordIds == null ? new Set<Id>() : new Set<Id>(recordIds);
            return TripService.getLoadedRecords(TripDAO.getByIds(safeIds).values());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Trip__c> getAll() {
        try {
            return TripService.getLoadedRecords(TripDAO.getAll());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled
    public static List<Trip__c> saveRecords(List<Trip__c> records) {
        try {
            Set<Id> recordIds = collectIds(records);
            Map<Id, Trip__c> persistedRecordsById = TripDAO.getByIds(recordIds);
            List<Trip__c> savedRecords = TripService.saveRecords(records, persistedRecordsById);
            return TripService.getLoadedRecords(TripDAO.getByIds(collectIds(savedRecords)).values());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled
    public static Boolean deleteRecords(List<Id> recordIds) {
        try {
            Set<Id> safeIds = recordIds == null ? new Set<Id>() : new Set<Id>(recordIds);
            Map<Id, Trip__c> loadedRecordsById = TripDAO.getByIds(safeIds);
            TripService.deleteRecords(loadedRecordsById.values());
            return true;
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    private static Set<Id> collectIds(List<Trip__c> records) {
        Set<Id> recordIds = new Set<Id>();
        if (records == null) {
            return recordIds;
        }
        for (Trip__c recordItem : records) {
            if (recordItem.Id != null) {
                recordIds.add(recordItem.Id);
            }
        }
        return recordIds;
    }

    private static String getControllerErrorMessage() {
        return String.format(System.Label.Generic_Controller_Request_Failed, new List<String>{ Trip__c.SObjectType.getDescribe().getLabel() });
    }
}
