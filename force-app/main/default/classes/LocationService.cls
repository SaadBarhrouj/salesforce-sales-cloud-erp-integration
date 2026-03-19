public inherited sharing class LocationService {
    public class ServiceException extends Exception {}

    private static final List<String> TRACKED_FIELDS = new List<String>{
        'Id',
        'CloseDate',
        'ConstructionEndDate',
        'ConstructionStartDate',
        'Country_Code__c',
        'Description',
        'DrivingDirections',
        'EarliestPickupTimeOffset',
        'Email',
        'ExternalReference',
        'Fax',
        'IsEligibleForPickup',
        'IsInventoryLocation',
        'IsMobile',
        'LatestPickupTimeOffset',
        'Location',
        'LocationLevel',
        'LocationType',
        'LogoId',
        'Mobile',
        'Name',
        'OpenDate',
        'OwnerId',
        'ParentLocationId',
        'Phone',
        'PickupProcessingTime',
        'PickupProcessingTimeUnit',
        'PossessionDate',
        'RemodelEndDate',
        'RemodelStartDate',
        'RootLocationId',
        'ShouldSyncWithOci',
        'Site_Access__c',
        'TimeZone',
        'VisitorAddressId'
    };
    private static final List<String> REQUIRED_FIELDS = new List<String>{
        'Country_Code__c',
        'Name'
    };

    public static Location getLoadedRecord(Location loadedRecord) {
        return loadedRecord;
    }

    public static List<Location> getLoadedRecords(List<Location> loadedRecords) {
        return loadedRecords == null ? new List<Location>() : loadedRecords;
    }

    public static List<Location> saveRecords(List<Location> records, Map<Id, Location> persistedRecordsById) {
        validateCollection(records);

        Map<Id, Location> safePersistedRecordsById = persistedRecordsById == null
            ? new Map<Id, Location>()
            : persistedRecordsById;
        List<Location> recordsToInsert = new List<Location>();
        List<Location> recordsToUpdate = new List<Location>();

        for (Location recordItem : records) {
            validateRequiredFields(recordItem);
            if (recordItem.Id == null) {
                recordsToInsert.add(recordItem);
                continue;
            }

            if (!safePersistedRecordsById.containsKey(recordItem.Id)) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Not_Found, new List<String>{ getObjectLabel() }));
            }

            if (hasChanges(recordItem, safePersistedRecordsById.get(recordItem.Id))) {
                recordsToUpdate.add(recordItem);
            }
        }

        if (!recordsToInsert.isEmpty()) {
            insert recordsToInsert;
        }
        if (!recordsToUpdate.isEmpty()) {
            update recordsToUpdate;
        }

        return records;
    }

    public static void deleteRecords(List<Location> records) {
        validateCollection(records);
        for (Location recordItem : records) {
            if (recordItem.Id == null) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
        }
        delete records;
    }

    public static void beforeInsert(List<Location> newRecords) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }

        for (Location recordItem : newRecords) {
            validateRequiredFields(recordItem);
        }
    }

    public static void beforeUpdate(List<Location> newRecords, Map<Id, Location> oldRecordsById, Map<Id, Location> persistedRecordsById) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }

        Map<Id, Location> safePersistedRecordsById = persistedRecordsById == null
            ? new Map<Id, Location>()
            : persistedRecordsById;

        for (Location recordItem : newRecords) {
            if (recordItem.Id == null) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
            if (!safePersistedRecordsById.containsKey(recordItem.Id)) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Not_Found, new List<String>{ getObjectLabel() }));
            }
            validateRequiredFields(recordItem);
        }
    }

    public static void beforeDelete(Map<Id, Location> oldRecordsById, Map<Id, Location> loadedRecordsById) {
        if (loadedRecordsById == null || loadedRecordsById.isEmpty()) {
            return;
        }

        for (Location recordItem : loadedRecordsById.values()) {
            if (recordItem.Id == null) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
        }
    }

    public static void afterInsert(List<Location> newRecords) {
        getLoadedRecords(newRecords);
    }

    public static void afterUpdate(List<Location> newRecords, Map<Id, Location> oldRecordsById, Map<Id, Location> persistedRecordsById) {
        getLoadedRecords(newRecords);
    }

    public static void afterDelete(Map<Id, Location> oldRecordsById) {
        if (oldRecordsById == null) {
            return;
        }
    }

    private static void validateCollection(List<Location> records) {
        if (records == null || records.isEmpty()) {
            throw new ServiceException(formatLabel(System.Label.Generic_Service_Records_Required, new List<String>{ getObjectLabel() }));
        }
    }

    private static void validateRequiredFields(Location recordItem) {
        Map<String, Schema.SObjectField> fieldMap = Location.SObjectType.getDescribe().fields.getMap();
        for (String fieldApiName : REQUIRED_FIELDS) {
            Object rawValue = recordItem.get(fieldApiName);
            Boolean isMissing = rawValue == null;
            if (rawValue instanceof String) {
                isMissing = String.isBlank((String) rawValue);
            }
            if (isMissing) {
                String fieldLabel = fieldMap.containsKey(fieldApiName)
                    ? fieldMap.get(fieldApiName).getDescribe().getLabel()
                    : fieldApiName;
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Field_Required, new List<String>{ fieldLabel, getObjectLabel() }));
            }
        }
    }

    private static Boolean hasChanges(Location currentRecord, Location persistedRecord) {
        for (String fieldApiName : TRACKED_FIELDS) {
            if (valuesDiffer(currentRecord.get(fieldApiName), persistedRecord.get(fieldApiName))) {
                return true;
            }
        }
        return false;
    }

    private static Boolean valuesDiffer(Object leftValue, Object rightValue) {
        return String.valueOf(leftValue) != String.valueOf(rightValue);
    }

    private static String getObjectLabel() {
        return Location.SObjectType.getDescribe().getLabel();
    }

    private static String formatLabel(String labelValue, List<String> tokens) {
        return String.format(labelValue, tokens);
    }
}
