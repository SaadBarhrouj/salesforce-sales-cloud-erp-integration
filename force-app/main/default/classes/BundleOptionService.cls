public inherited sharing class BundleOptionService {
    public class ServiceException extends Exception {}

    private static final List<String> TRACKED_FIELDS = new List<String>{
        'Id',
        'Name',
        'Bundle_Product__c',
        'Default_Quantity__c',
        'Feature__c',
        'Is_Required__c',
        'Is_Selected__c',
        'Max_Quantity__c',
        'Min_Quantity__c',
        'Option_Product__c',
        'Option_Type__c',
        'Quantity_Editable__c',
        'Sort_Order__c'
    };
    private static final List<String> REQUIRED_FIELDS = new List<String>{
        'Option_Type__c',
        'Sort_Order__c'
    };

    public static Bundle_Option__c getLoadedRecord(Bundle_Option__c loadedRecord) {
        return loadedRecord;
    }

    public static List<Bundle_Option__c> getLoadedRecords(List<Bundle_Option__c> loadedRecords) {
        return loadedRecords == null ? new List<Bundle_Option__c>() : loadedRecords;
    }

    public static List<Bundle_Option__c> saveRecords(List<Bundle_Option__c> records, Map<Id, Bundle_Option__c> persistedRecordsById) {
        validateCollection(records);

        Map<Id, Bundle_Option__c> safePersistedRecordsById = persistedRecordsById == null
            ? new Map<Id, Bundle_Option__c>()
            : persistedRecordsById;
        List<Bundle_Option__c> recordsToInsert = new List<Bundle_Option__c>();
        List<Bundle_Option__c> recordsToUpdate = new List<Bundle_Option__c>();

        for (Bundle_Option__c recordItem : records) {
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

    public static void deleteRecords(List<Bundle_Option__c> records) {
        validateCollection(records);
        for (Bundle_Option__c recordItem : records) {
            if (recordItem.Id == null) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
        }
        delete records;
    }

    public static void beforeInsert(List<Bundle_Option__c> newRecords) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }

        for (Bundle_Option__c recordItem : newRecords) {
            validateRequiredFields(recordItem);
        }
    }

    public static void beforeUpdate(List<Bundle_Option__c> newRecords, Map<Id, Bundle_Option__c> oldRecordsById, Map<Id, Bundle_Option__c> persistedRecordsById) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }

        Map<Id, Bundle_Option__c> safePersistedRecordsById = persistedRecordsById == null
            ? new Map<Id, Bundle_Option__c>()
            : persistedRecordsById;

        for (Bundle_Option__c recordItem : newRecords) {
            if (recordItem.Id == null) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
            if (!safePersistedRecordsById.containsKey(recordItem.Id)) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Not_Found, new List<String>{ getObjectLabel() }));
            }
            validateRequiredFields(recordItem);
        }
    }

    public static void beforeDelete(Map<Id, Bundle_Option__c> oldRecordsById, Map<Id, Bundle_Option__c> loadedRecordsById) {
        if (loadedRecordsById == null || loadedRecordsById.isEmpty()) {
            return;
        }

        for (Bundle_Option__c recordItem : loadedRecordsById.values()) {
            if (recordItem.Id == null) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
        }
    }

    public static void afterInsert(List<Bundle_Option__c> newRecords) {
        getLoadedRecords(newRecords);
    }

    public static void afterUpdate(List<Bundle_Option__c> newRecords, Map<Id, Bundle_Option__c> oldRecordsById, Map<Id, Bundle_Option__c> persistedRecordsById) {
        getLoadedRecords(newRecords);
    }

    public static void afterDelete(Map<Id, Bundle_Option__c> oldRecordsById) {
        if (oldRecordsById == null) {
            return;
        }
    }

    private static void validateCollection(List<Bundle_Option__c> records) {
        if (records == null || records.isEmpty()) {
            throw new ServiceException(formatLabel(System.Label.Generic_Service_Records_Required, new List<String>{ getObjectLabel() }));
        }
    }

    private static void validateRequiredFields(Bundle_Option__c recordItem) {
        Map<String, Schema.SObjectField> fieldMap = Bundle_Option__c.SObjectType.getDescribe().fields.getMap();
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

    private static Boolean hasChanges(Bundle_Option__c currentRecord, Bundle_Option__c persistedRecord) {
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
        return Bundle_Option__c.SObjectType.getDescribe().getLabel();
    }

    private static String formatLabel(String labelValue, List<String> tokens) {
        return String.format(labelValue, tokens);
    }
}
