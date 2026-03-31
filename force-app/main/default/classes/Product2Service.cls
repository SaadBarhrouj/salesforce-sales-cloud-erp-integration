public inherited sharing class Product2Service {
    public class ServiceException extends Exception {}

    private static final List<String> TRACKED_FIELDS = new List<String>{
        'Id',
        'Description',
        'DisplayUrl',
        'ExternalDataSourceId',
        'ExternalId',
        'Family',
        'IsActive',
        'Name',
        'ProductCode',
        'QuantityUnitOfMeasure',
        'SellerId',
        'SourceProductId',
        'StockKeepingUnit',
        'Unit_Weight_Kg__c'
    };
    private static final List<String> REQUIRED_FIELDS = new List<String>{
        'Name'
    };

    public static Product2 getLoadedRecord(Product2 loadedRecord) {
        return loadedRecord;
    }

    public static List<Product2> getLoadedRecords(List<Product2> loadedRecords) {
        return loadedRecords == null ? new List<Product2>() : loadedRecords;
    }

    public static List<Product2> saveRecords(List<Product2> records, Map<Id, Product2> persistedRecordsById) {
        validateCollection(records);

        Map<Id, Product2> safePersistedRecordsById = persistedRecordsById == null
            ? new Map<Id, Product2>()
            : persistedRecordsById;
        List<Product2> recordsToInsert = new List<Product2>();
        List<Product2> recordsToUpdate = new List<Product2>();

        for (Product2 recordItem : records) {
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

    public static void deleteRecords(List<Product2> records) {
        validateCollection(records);
        for (Product2 recordItem : records) {
            if (recordItem.Id == null) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
        }
        delete records;
    }

    public static void beforeInsert(List<Product2> newRecords) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }

        for (Product2 recordItem : newRecords) {
            validateRequiredFields(recordItem);
        }
    }

    public static void beforeUpdate(List<Product2> newRecords, Map<Id, Product2> oldRecordsById, Map<Id, Product2> persistedRecordsById) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }

        Map<Id, Product2> safePersistedRecordsById = persistedRecordsById == null
            ? new Map<Id, Product2>()
            : persistedRecordsById;

        for (Product2 recordItem : newRecords) {
            if (recordItem.Id == null) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
            if (!safePersistedRecordsById.containsKey(recordItem.Id)) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Not_Found, new List<String>{ getObjectLabel() }));
            }
            validateRequiredFields(recordItem);
        }
    }

    public static void beforeDelete(Map<Id, Product2> oldRecordsById, Map<Id, Product2> loadedRecordsById) {
        if (loadedRecordsById == null || loadedRecordsById.isEmpty()) {
            return;
        }

        for (Product2 recordItem : loadedRecordsById.values()) {
            if (recordItem.Id == null) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
        }
    }

    public static void afterInsert(List<Product2> newRecords) {
        getLoadedRecords(newRecords);
    }

    public static void afterUpdate(List<Product2> newRecords, Map<Id, Product2> oldRecordsById, Map<Id, Product2> persistedRecordsById) {
        getLoadedRecords(newRecords);
    }

    public static void afterDelete(Map<Id, Product2> oldRecordsById) {
        if (oldRecordsById == null) {
            return;
        }
    }

    private static void validateCollection(List<Product2> records) {
        if (records == null || records.isEmpty()) {
            throw new ServiceException(formatLabel(System.Label.Generic_Service_Records_Required, new List<String>{ getObjectLabel() }));
        }
    }

    private static void validateRequiredFields(Product2 recordItem) {
        Map<String, Schema.SObjectField> fieldMap = Product2.SObjectType.getDescribe().fields.getMap();
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

    private static Boolean hasChanges(Product2 currentRecord, Product2 persistedRecord) {
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
        return Product2.SObjectType.getDescribe().getLabel();
    }

    private static String formatLabel(String labelValue, List<String> tokens) {
        return String.format(labelValue, tokens);
    }
}
