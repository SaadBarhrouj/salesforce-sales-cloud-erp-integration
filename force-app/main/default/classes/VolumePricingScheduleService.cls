public inherited sharing class VolumePricingScheduleService {
    public class ServiceException extends Exception {}

    private static final List<String> TRACKED_FIELDS = new List<String>{
        'Id',
        'Name',
        'Is_Active__c',
        'Overage_Rate__c',
        'Pricebook__c',
        'Pricing_Type__c',
        'Product__c'
    };
    private static final List<String> REQUIRED_FIELDS = new List<String>{
        'Pricing_Type__c',
        'Name',
        'Product__c'
    };

    public static Volume_Pricing_Schedule__c getLoadedRecord(Volume_Pricing_Schedule__c loadedRecord) {
        return loadedRecord;
    }

    public static List<Volume_Pricing_Schedule__c> getLoadedRecords(List<Volume_Pricing_Schedule__c> loadedRecords) {
        return loadedRecords == null ? new List<Volume_Pricing_Schedule__c>() : loadedRecords;
    }

    public static List<Volume_Pricing_Schedule__c> saveRecords(List<Volume_Pricing_Schedule__c> records, Map<Id, Volume_Pricing_Schedule__c> persistedRecordsById) {
        validateCollection(records);

        Map<Id, Volume_Pricing_Schedule__c> safePersistedRecordsById = persistedRecordsById == null
            ? new Map<Id, Volume_Pricing_Schedule__c>()
            : persistedRecordsById;
        List<Volume_Pricing_Schedule__c> recordsToInsert = new List<Volume_Pricing_Schedule__c>();
        List<Volume_Pricing_Schedule__c> recordsToUpdate = new List<Volume_Pricing_Schedule__c>();

        for (Volume_Pricing_Schedule__c recordItem : records) {
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

    public static void deleteRecords(List<Volume_Pricing_Schedule__c> records) {
        validateCollection(records);
        for (Volume_Pricing_Schedule__c recordItem : records) {
            if (recordItem.Id == null) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
        }
        delete records;
    }

    public static void beforeInsert(List<Volume_Pricing_Schedule__c> newRecords) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }

        for (Volume_Pricing_Schedule__c recordItem : newRecords) {
            validateRequiredFields(recordItem);
        }
    }

    public static void beforeUpdate(List<Volume_Pricing_Schedule__c> newRecords, Map<Id, Volume_Pricing_Schedule__c> oldRecordsById, Map<Id, Volume_Pricing_Schedule__c> persistedRecordsById) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }

        Map<Id, Volume_Pricing_Schedule__c> safePersistedRecordsById = persistedRecordsById == null
            ? new Map<Id, Volume_Pricing_Schedule__c>()
            : persistedRecordsById;

        for (Volume_Pricing_Schedule__c recordItem : newRecords) {
            if (recordItem.Id == null) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
            if (!safePersistedRecordsById.containsKey(recordItem.Id)) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Not_Found, new List<String>{ getObjectLabel() }));
            }
            validateRequiredFields(recordItem);
        }
    }

    public static void beforeDelete(Map<Id, Volume_Pricing_Schedule__c> oldRecordsById, Map<Id, Volume_Pricing_Schedule__c> loadedRecordsById) {
        if (loadedRecordsById == null || loadedRecordsById.isEmpty()) {
            return;
        }

        for (Volume_Pricing_Schedule__c recordItem : loadedRecordsById.values()) {
            if (recordItem.Id == null) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
        }
    }

    public static void afterInsert(List<Volume_Pricing_Schedule__c> newRecords) {
        getLoadedRecords(newRecords);
    }

    public static void afterUpdate(List<Volume_Pricing_Schedule__c> newRecords, Map<Id, Volume_Pricing_Schedule__c> oldRecordsById, Map<Id, Volume_Pricing_Schedule__c> persistedRecordsById) {
        getLoadedRecords(newRecords);
    }

    public static void afterDelete(Map<Id, Volume_Pricing_Schedule__c> oldRecordsById) {
        if (oldRecordsById == null) {
            return;
        }
    }

    private static void validateCollection(List<Volume_Pricing_Schedule__c> records) {
        if (records == null || records.isEmpty()) {
            throw new ServiceException(formatLabel(System.Label.Generic_Service_Records_Required, new List<String>{ getObjectLabel() }));
        }
    }

    private static void validateRequiredFields(Volume_Pricing_Schedule__c recordItem) {
        Map<String, Schema.SObjectField> fieldMap = Volume_Pricing_Schedule__c.SObjectType.getDescribe().fields.getMap();
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

    private static Boolean hasChanges(Volume_Pricing_Schedule__c currentRecord, Volume_Pricing_Schedule__c persistedRecord) {
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
        return Volume_Pricing_Schedule__c.SObjectType.getDescribe().getLabel();
    }

    private static String formatLabel(String labelValue, List<String> tokens) {
        return String.format(labelValue, tokens);
    }
}
