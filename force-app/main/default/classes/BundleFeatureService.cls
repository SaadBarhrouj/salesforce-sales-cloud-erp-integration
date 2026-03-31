public inherited sharing class BundleFeatureService {
    public class ServiceException extends Exception {}

    private static final List<String> TRACKED_FIELDS = new List<String>{
        'Id',
        'Name',
        'Help_Text__c',
        'Max_Options__c',
        'Min_Options__c',
        'Product__c',
        'Sort_Order__c'
    };
    private static final List<String> REQUIRED_FIELDS = new List<String>{
        'Sort_Order__c',
        'Name'
    };

    public static Bundle_Feature__c getLoadedRecord(Bundle_Feature__c loadedRecord) {
        return loadedRecord;
    }

    public static List<Bundle_Feature__c> getLoadedRecords(List<Bundle_Feature__c> loadedRecords) {
        return loadedRecords == null ? new List<Bundle_Feature__c>() : loadedRecords;
    }

    public static List<Bundle_Feature__c> saveRecords(List<Bundle_Feature__c> records, Map<Id, Bundle_Feature__c> persistedRecordsById) {
        validateCollection(records);

        Map<Id, Bundle_Feature__c> safePersistedRecordsById = persistedRecordsById == null
            ? new Map<Id, Bundle_Feature__c>()
            : persistedRecordsById;
        List<Bundle_Feature__c> recordsToInsert = new List<Bundle_Feature__c>();
        List<Bundle_Feature__c> recordsToUpdate = new List<Bundle_Feature__c>();

        for (Bundle_Feature__c recordItem : records) {
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

    public static void deleteRecords(List<Bundle_Feature__c> records) {
        validateCollection(records);
        for (Bundle_Feature__c recordItem : records) {
            if (recordItem.Id == null) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
        }
        delete records;
    }

    public static void beforeInsert(List<Bundle_Feature__c> newRecords) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }

        for (Bundle_Feature__c recordItem : newRecords) {
            validateRequiredFields(recordItem);
        }
    }

    public static void beforeUpdate(List<Bundle_Feature__c> newRecords, Map<Id, Bundle_Feature__c> oldRecordsById, Map<Id, Bundle_Feature__c> persistedRecordsById) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }

        Map<Id, Bundle_Feature__c> safePersistedRecordsById = persistedRecordsById == null
            ? new Map<Id, Bundle_Feature__c>()
            : persistedRecordsById;

        for (Bundle_Feature__c recordItem : newRecords) {
            if (recordItem.Id == null) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
            if (!safePersistedRecordsById.containsKey(recordItem.Id)) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Not_Found, new List<String>{ getObjectLabel() }));
            }
            validateRequiredFields(recordItem);
        }
    }

    public static void beforeDelete(Map<Id, Bundle_Feature__c> oldRecordsById, Map<Id, Bundle_Feature__c> loadedRecordsById) {
        if (loadedRecordsById == null || loadedRecordsById.isEmpty()) {
            return;
        }

        for (Bundle_Feature__c recordItem : loadedRecordsById.values()) {
            if (recordItem.Id == null) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
        }
    }

    public static void afterInsert(List<Bundle_Feature__c> newRecords) {
        getLoadedRecords(newRecords);
    }

    public static void afterUpdate(List<Bundle_Feature__c> newRecords, Map<Id, Bundle_Feature__c> oldRecordsById, Map<Id, Bundle_Feature__c> persistedRecordsById) {
        getLoadedRecords(newRecords);
    }

    public static void afterDelete(Map<Id, Bundle_Feature__c> oldRecordsById) {
        if (oldRecordsById == null) {
            return;
        }
    }

    private static void validateCollection(List<Bundle_Feature__c> records) {
        if (records == null || records.isEmpty()) {
            throw new ServiceException(formatLabel(System.Label.Generic_Service_Records_Required, new List<String>{ getObjectLabel() }));
        }
    }

    private static void validateRequiredFields(Bundle_Feature__c recordItem) {
        Map<String, Schema.SObjectField> fieldMap = Bundle_Feature__c.SObjectType.getDescribe().fields.getMap();
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

    private static Boolean hasChanges(Bundle_Feature__c currentRecord, Bundle_Feature__c persistedRecord) {
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
        return Bundle_Feature__c.SObjectType.getDescribe().getLabel();
    }

    private static String formatLabel(String labelValue, List<String> tokens) {
        return String.format(labelValue, tokens);
    }
}
