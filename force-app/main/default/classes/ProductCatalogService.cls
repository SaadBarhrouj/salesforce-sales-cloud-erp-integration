public inherited sharing class ProductCatalogService {
    public class ServiceException extends Exception {}

    private static final List<String> TRACKED_FIELDS = new List<String>{
        'Id',
        'Name',
        'OwnerId'
    };
    private static final List<String> REQUIRED_FIELDS = new List<String>{
        'Name'
    };

    public static ProductCatalog getLoadedRecord(ProductCatalog loadedRecord) {
        return loadedRecord;
    }

    public static List<ProductCatalog> getLoadedRecords(List<ProductCatalog> loadedRecords) {
        return loadedRecords == null ? new List<ProductCatalog>() : loadedRecords;
    }

    public static List<ProductCatalog> saveRecords(List<ProductCatalog> records, Map<Id, ProductCatalog> persistedRecordsById) {
        validateCollection(records);

        Map<Id, ProductCatalog> safePersistedRecordsById = persistedRecordsById == null
            ? new Map<Id, ProductCatalog>()
            : persistedRecordsById;
        List<ProductCatalog> recordsToInsert = new List<ProductCatalog>();
        List<ProductCatalog> recordsToUpdate = new List<ProductCatalog>();

        for (ProductCatalog recordItem : records) {
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

    public static void deleteRecords(List<ProductCatalog> records) {
        validateCollection(records);
        for (ProductCatalog recordItem : records) {
            if (recordItem.Id == null) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
        }
        delete records;
    }

    public static void beforeInsert(List<ProductCatalog> newRecords) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }

        for (ProductCatalog recordItem : newRecords) {
            validateRequiredFields(recordItem);
        }
    }

    public static void beforeUpdate(List<ProductCatalog> newRecords, Map<Id, ProductCatalog> oldRecordsById, Map<Id, ProductCatalog> persistedRecordsById) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }

        Map<Id, ProductCatalog> safePersistedRecordsById = persistedRecordsById == null
            ? new Map<Id, ProductCatalog>()
            : persistedRecordsById;

        for (ProductCatalog recordItem : newRecords) {
            if (recordItem.Id == null) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
            if (!safePersistedRecordsById.containsKey(recordItem.Id)) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Not_Found, new List<String>{ getObjectLabel() }));
            }
            validateRequiredFields(recordItem);
        }
    }

    public static void beforeDelete(Map<Id, ProductCatalog> oldRecordsById, Map<Id, ProductCatalog> loadedRecordsById) {
        if (loadedRecordsById == null || loadedRecordsById.isEmpty()) {
            return;
        }

        for (ProductCatalog recordItem : loadedRecordsById.values()) {
            if (recordItem.Id == null) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
        }
    }

    public static void afterInsert(List<ProductCatalog> newRecords) {
        getLoadedRecords(newRecords);
    }

    public static void afterUpdate(List<ProductCatalog> newRecords, Map<Id, ProductCatalog> oldRecordsById, Map<Id, ProductCatalog> persistedRecordsById) {
        getLoadedRecords(newRecords);
    }

    public static void afterDelete(Map<Id, ProductCatalog> oldRecordsById) {
        if (oldRecordsById == null) {
            return;
        }
    }

    private static void validateCollection(List<ProductCatalog> records) {
        if (records == null || records.isEmpty()) {
            throw new ServiceException(formatLabel(System.Label.Generic_Service_Records_Required, new List<String>{ getObjectLabel() }));
        }
    }

    private static void validateRequiredFields(ProductCatalog recordItem) {
        Map<String, Schema.SObjectField> fieldMap = ProductCatalog.SObjectType.getDescribe().fields.getMap();
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

    private static Boolean hasChanges(ProductCatalog currentRecord, ProductCatalog persistedRecord) {
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
        return ProductCatalog.SObjectType.getDescribe().getLabel();
    }

    private static String formatLabel(String labelValue, List<String> tokens) {
        return String.format(labelValue, tokens);
    }
}
