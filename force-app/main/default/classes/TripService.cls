public inherited sharing class TripService {
    public class ServiceException extends Exception {}

    private static final List<String> TRACKED_FIELDS = new List<String>{
        'Id',
        'Name',
        'Calculation_Detail__c',
        'Country_Code__c',
        'Departure_Location__c',
        'Destination_Location__c',
        'Direction__c',
        'Distance_Km__c',
        'Final_Price__c',
        'Is_Price_Overridden__c',
        'Opportunity__c',
        'Override_Reason__c',
        'Price_Before_Conversion__c',
        'Rate_Currency__c',
        'Status__c',
        'System_Price__c',
        'Total_Weight_Kg__c',
        'Transport_Zone__c',
        'Trip_Date__c',
        'Trip_Key__c',
        'Truck_Type__c'
    };
    private static final List<String> REQUIRED_FIELDS = new List<String>{
        'Country_Code__c',
        'Direction__c',
        'Opportunity__c',
        'Status__c',
        'Trip_Date__c',
        'Trip_Key__c'
    };

    public static Trip__c getLoadedRecord(Trip__c loadedRecord) {
        return loadedRecord;
    }

    public static List<Trip__c> getLoadedRecords(List<Trip__c> loadedRecords) {
        return loadedRecords == null ? new List<Trip__c>() : loadedRecords;
    }

    public static List<Trip__c> saveRecords(List<Trip__c> records, Map<Id, Trip__c> persistedRecordsById) {
        validateCollection(records);

        Map<Id, Trip__c> safePersistedRecordsById = persistedRecordsById == null
            ? new Map<Id, Trip__c>()
            : persistedRecordsById;
        List<Trip__c> recordsToInsert = new List<Trip__c>();
        List<Trip__c> recordsToUpdate = new List<Trip__c>();

        for (Trip__c recordItem : records) {
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

    public static void deleteRecords(List<Trip__c> records) {
        validateCollection(records);
        for (Trip__c recordItem : records) {
            if (recordItem.Id == null) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
        }
        delete records;
    }

    public static void beforeInsert(List<Trip__c> newRecords) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }

        for (Trip__c recordItem : newRecords) {
            validateRequiredFields(recordItem);
        }
    }

    public static void beforeUpdate(List<Trip__c> newRecords, Map<Id, Trip__c> oldRecordsById, Map<Id, Trip__c> persistedRecordsById) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }

        Map<Id, Trip__c> safePersistedRecordsById = persistedRecordsById == null
            ? new Map<Id, Trip__c>()
            : persistedRecordsById;

        for (Trip__c recordItem : newRecords) {
            if (recordItem.Id == null) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
            if (!safePersistedRecordsById.containsKey(recordItem.Id)) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Not_Found, new List<String>{ getObjectLabel() }));
            }
            validateRequiredFields(recordItem);
        }
    }

    public static void beforeDelete(Map<Id, Trip__c> oldRecordsById, Map<Id, Trip__c> loadedRecordsById) {
        if (loadedRecordsById == null || loadedRecordsById.isEmpty()) {
            return;
        }

        for (Trip__c recordItem : loadedRecordsById.values()) {
            if (recordItem.Id == null) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
        }
    }

    public static void afterInsert(List<Trip__c> newRecords) {
        getLoadedRecords(newRecords);
    }

    public static void afterUpdate(List<Trip__c> newRecords, Map<Id, Trip__c> oldRecordsById, Map<Id, Trip__c> persistedRecordsById) {
        getLoadedRecords(newRecords);
    }

    public static void afterDelete(Map<Id, Trip__c> oldRecordsById) {
        if (oldRecordsById == null) {
            return;
        }
    }

    private static void validateCollection(List<Trip__c> records) {
        if (records == null || records.isEmpty()) {
            throw new ServiceException(formatLabel(System.Label.Generic_Service_Records_Required, new List<String>{ getObjectLabel() }));
        }
    }

    private static void validateRequiredFields(Trip__c recordItem) {
        Map<String, Schema.SObjectField> fieldMap = Trip__c.SObjectType.getDescribe().fields.getMap();
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

    private static Boolean hasChanges(Trip__c currentRecord, Trip__c persistedRecord) {
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
        return Trip__c.SObjectType.getDescribe().getLabel();
    }

    private static String formatLabel(String labelValue, List<String> tokens) {
        return String.format(labelValue, tokens);
    }
}
