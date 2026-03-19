public inherited sharing class RuleActionService {
    public class ServiceException extends Exception {}

    private static final List<String> TRACKED_FIELDS = new List<String>{
        'Id',
        'Name',
        'Filter_Field__c',
        'Filter_Operator__c',
        'Filter_Value__c',
        'Product_Rule__c',
        'Sort_Order__c',
        'Target_Product__c',
        'Type__c'
    };
    private static final List<String> REQUIRED_FIELDS = new List<String>{
        'Product_Rule__c',
        'Type__c'
    };

    public static Rule_Action__c getLoadedRecord(Rule_Action__c loadedRecord) {
        return loadedRecord;
    }

    public static List<Rule_Action__c> getLoadedRecords(List<Rule_Action__c> loadedRecords) {
        return loadedRecords == null ? new List<Rule_Action__c>() : loadedRecords;
    }

    public static List<Rule_Action__c> saveRecords(List<Rule_Action__c> records, Map<Id, Rule_Action__c> persistedRecordsById) {
        validateCollection(records);

        Map<Id, Rule_Action__c> safePersistedRecordsById = persistedRecordsById == null
            ? new Map<Id, Rule_Action__c>()
            : persistedRecordsById;
        List<Rule_Action__c> recordsToInsert = new List<Rule_Action__c>();
        List<Rule_Action__c> recordsToUpdate = new List<Rule_Action__c>();

        for (Rule_Action__c recordItem : records) {
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

    public static void deleteRecords(List<Rule_Action__c> records) {
        validateCollection(records);
        for (Rule_Action__c recordItem : records) {
            if (recordItem.Id == null) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
        }
        delete records;
    }

    public static void beforeInsert(List<Rule_Action__c> newRecords) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }

        for (Rule_Action__c recordItem : newRecords) {
            validateRequiredFields(recordItem);
        }
    }

    public static void beforeUpdate(List<Rule_Action__c> newRecords, Map<Id, Rule_Action__c> oldRecordsById, Map<Id, Rule_Action__c> persistedRecordsById) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }

        Map<Id, Rule_Action__c> safePersistedRecordsById = persistedRecordsById == null
            ? new Map<Id, Rule_Action__c>()
            : persistedRecordsById;

        for (Rule_Action__c recordItem : newRecords) {
            if (recordItem.Id == null) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
            if (!safePersistedRecordsById.containsKey(recordItem.Id)) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Not_Found, new List<String>{ getObjectLabel() }));
            }
            validateRequiredFields(recordItem);
        }
    }

    public static void beforeDelete(Map<Id, Rule_Action__c> oldRecordsById, Map<Id, Rule_Action__c> loadedRecordsById) {
        if (loadedRecordsById == null || loadedRecordsById.isEmpty()) {
            return;
        }

        for (Rule_Action__c recordItem : loadedRecordsById.values()) {
            if (recordItem.Id == null) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
        }
    }

    public static void afterInsert(List<Rule_Action__c> newRecords) {
        getLoadedRecords(newRecords);
    }

    public static void afterUpdate(List<Rule_Action__c> newRecords, Map<Id, Rule_Action__c> oldRecordsById, Map<Id, Rule_Action__c> persistedRecordsById) {
        getLoadedRecords(newRecords);
    }

    public static void afterDelete(Map<Id, Rule_Action__c> oldRecordsById) {
        if (oldRecordsById == null) {
            return;
        }
    }

    private static void validateCollection(List<Rule_Action__c> records) {
        if (records == null || records.isEmpty()) {
            throw new ServiceException(formatLabel(System.Label.Generic_Service_Records_Required, new List<String>{ getObjectLabel() }));
        }
    }

    private static void validateRequiredFields(Rule_Action__c recordItem) {
        Map<String, Schema.SObjectField> fieldMap = Rule_Action__c.SObjectType.getDescribe().fields.getMap();
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

    private static Boolean hasChanges(Rule_Action__c currentRecord, Rule_Action__c persistedRecord) {
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
        return Rule_Action__c.SObjectType.getDescribe().getLabel();
    }

    private static String formatLabel(String labelValue, List<String> tokens) {
        return String.format(labelValue, tokens);
    }
}
