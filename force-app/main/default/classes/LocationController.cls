public with sharing class LocationController {
    @AuraEnabled(cacheable=true)
    public static Location getById(Id recordId) {
        try {
            return LocationService.getLoadedRecord(LocationDAO.getById(recordId));
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Location> getByIds(List<Id> recordIds) {
        try {
            Set<Id> safeIds = recordIds == null ? new Set<Id>() : new Set<Id>(recordIds);
            return LocationService.getLoadedRecords(LocationDAO.getByIds(safeIds).values());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Location> getAll() {
        try {
            return LocationService.getLoadedRecords(LocationDAO.getAll());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled
    public static List<Location> saveRecords(List<Location> records) {
        try {
            Set<Id> recordIds = collectIds(records);
            Map<Id, Location> persistedRecordsById = LocationDAO.getByIds(recordIds);
            List<Location> savedRecords = LocationService.saveRecords(records, persistedRecordsById);
            return LocationService.getLoadedRecords(LocationDAO.getByIds(collectIds(savedRecords)).values());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled
    public static Boolean deleteRecords(List<Id> recordIds) {
        try {
            Set<Id> safeIds = recordIds == null ? new Set<Id>() : new Set<Id>(recordIds);
            Map<Id, Location> loadedRecordsById = LocationDAO.getByIds(safeIds);
            LocationService.deleteRecords(loadedRecordsById.values());
            return true;
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    private static Set<Id> collectIds(List<Location> records) {
        Set<Id> recordIds = new Set<Id>();
        if (records == null) {
            return recordIds;
        }
        for (Location recordItem : records) {
            if (recordItem.Id != null) {
                recordIds.add(recordItem.Id);
            }
        }
        return recordIds;
    }

    private static String getControllerErrorMessage() {
        return String.format(System.Label.Generic_Controller_Request_Failed, new List<String>{ Location.SObjectType.getDescribe().getLabel() });
    }
}
