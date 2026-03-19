public inherited sharing class OpportunityLineItemService {
    public class ServiceException extends Exception {}

    private static final List<String> TRACKED_FIELDS = new List<String>{
        'Id',
        'Bundle_Group__c',
        'Delivery_Date__c',
        'Departure_Agency__c',
        'Description',
        'Discount',
        'Is_Bundle_Product__c',
        'ListPrice',
        'Name',
        'OpportunityId',
        'Pickup_Date__c',
        'Product2Id',
        'ProductCode',
        'Quantity',
        'Rental_End_Date__c',
        'Rental_Start_Date__c',
        'ServiceDate',
        'Subtotal',
        'TotalPrice',
        'Trip_Delivery__c',
        'Trip_Pickup__c',
        'UnitPrice',
        'PricebookEntryId'
    };
    private static final List<String> REQUIRED_FIELDS = new List<String>{
        'OpportunityId',
        'PricebookEntryId',
        'Quantity',
        'UnitPrice'
    };

    public static OpportunityLineItem getLoadedRecord(OpportunityLineItem loadedRecord) {
        return loadedRecord;
    }

    public static List<OpportunityLineItem> getLoadedRecords(List<OpportunityLineItem> loadedRecords) {
        return loadedRecords == null ? new List<OpportunityLineItem>() : loadedRecords;
    }

    public static List<OpportunityLineItem> saveRecords(List<OpportunityLineItem> records, Map<Id, OpportunityLineItem> persistedRecordsById) {
        validateCollection(records);

        Map<Id, OpportunityLineItem> safePersistedRecordsById = persistedRecordsById == null
            ? new Map<Id, OpportunityLineItem>()
            : persistedRecordsById;
        List<OpportunityLineItem> recordsToInsert = new List<OpportunityLineItem>();
        List<OpportunityLineItem> recordsToUpdate = new List<OpportunityLineItem>();

        for (OpportunityLineItem recordItem : records) {
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

    public static void deleteRecords(List<OpportunityLineItem> records) {
        validateCollection(records);
        for (OpportunityLineItem recordItem : records) {
            if (recordItem.Id == null) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
        }
        delete records;
    }

    public static void beforeInsert(List<OpportunityLineItem> newRecords) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }

        for (OpportunityLineItem recordItem : newRecords) {
            validateRequiredFields(recordItem);
        }
    }

    public static void beforeUpdate(List<OpportunityLineItem> newRecords, Map<Id, OpportunityLineItem> oldRecordsById, Map<Id, OpportunityLineItem> persistedRecordsById) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }

        Map<Id, OpportunityLineItem> safePersistedRecordsById = persistedRecordsById == null
            ? new Map<Id, OpportunityLineItem>()
            : persistedRecordsById;

        for (OpportunityLineItem recordItem : newRecords) {
            if (recordItem.Id == null) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
            if (!safePersistedRecordsById.containsKey(recordItem.Id)) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Not_Found, new List<String>{ getObjectLabel() }));
            }
            validateRequiredFields(recordItem);
        }
    }

    public static void beforeDelete(Map<Id, OpportunityLineItem> oldRecordsById, Map<Id, OpportunityLineItem> loadedRecordsById) {
        if (loadedRecordsById == null || loadedRecordsById.isEmpty()) {
            return;
        }

        for (OpportunityLineItem recordItem : loadedRecordsById.values()) {
            if (recordItem.Id == null) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
        }
    }

    public static void afterInsert(List<OpportunityLineItem> newRecords) {
        getLoadedRecords(newRecords);
    }

    public static void afterUpdate(List<OpportunityLineItem> newRecords, Map<Id, OpportunityLineItem> oldRecordsById, Map<Id, OpportunityLineItem> persistedRecordsById) {
        getLoadedRecords(newRecords);
    }

    public static void afterDelete(Map<Id, OpportunityLineItem> oldRecordsById) {
        if (oldRecordsById == null) {
            return;
        }
    }

    private static void validateCollection(List<OpportunityLineItem> records) {
        if (records == null || records.isEmpty()) {
            throw new ServiceException(formatLabel(System.Label.Generic_Service_Records_Required, new List<String>{ getObjectLabel() }));
        }
    }

    private static void validateRequiredFields(OpportunityLineItem recordItem) {
        Map<String, Schema.SObjectField> fieldMap = OpportunityLineItem.SObjectType.getDescribe().fields.getMap();
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

    private static Boolean hasChanges(OpportunityLineItem currentRecord, OpportunityLineItem persistedRecord) {
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
        return OpportunityLineItem.SObjectType.getDescribe().getLabel();
    }

    private static String formatLabel(String labelValue, List<String> tokens) {
        return String.format(labelValue, tokens);
    }
}
