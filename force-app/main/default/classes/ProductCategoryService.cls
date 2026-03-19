public inherited sharing class ProductCategoryService {
    public class ServiceException extends Exception {}

    private static final List<String> TRACKED_FIELDS = new List<String>{
        'Id',
        'CatalogId',
        'Description',
        'IsNavigational',
        'Name',
        'ParentCategoryId',
        'SortOrder'
    };
    private static final List<String> REQUIRED_FIELDS = new List<String>{
        'CatalogId',
        'Name'
    };

    public static ProductCategory getLoadedRecord(ProductCategory loadedRecord) {
        return loadedRecord;
    }

    public static List<ProductCategory> getLoadedRecords(List<ProductCategory> loadedRecords) {
        return loadedRecords == null ? new List<ProductCategory>() : loadedRecords;
    }

    public static List<ProductCategory> saveRecords(List<ProductCategory> records, Map<Id, ProductCategory> persistedRecordsById) {
        validateCollection(records);

        Map<Id, ProductCategory> safePersistedRecordsById = persistedRecordsById == null
            ? new Map<Id, ProductCategory>()
            : persistedRecordsById;
        List<ProductCategory> recordsToInsert = new List<ProductCategory>();
        List<ProductCategory> recordsToUpdate = new List<ProductCategory>();

        for (ProductCategory recordItem : records) {
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

    public static void deleteRecords(List<ProductCategory> records) {
        validateCollection(records);
        for (ProductCategory recordItem : records) {
            if (recordItem.Id == null) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
        }
        delete records;
    }

    public static void beforeInsert(List<ProductCategory> newRecords) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }

        for (ProductCategory recordItem : newRecords) {
            validateRequiredFields(recordItem);
        }
    }

    public static void beforeUpdate(List<ProductCategory> newRecords, Map<Id, ProductCategory> oldRecordsById, Map<Id, ProductCategory> persistedRecordsById) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }

        Map<Id, ProductCategory> safePersistedRecordsById = persistedRecordsById == null
            ? new Map<Id, ProductCategory>()
            : persistedRecordsById;

        for (ProductCategory recordItem : newRecords) {
            if (recordItem.Id == null) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
            if (!safePersistedRecordsById.containsKey(recordItem.Id)) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Not_Found, new List<String>{ getObjectLabel() }));
            }
            validateRequiredFields(recordItem);
        }
    }

    public static void beforeDelete(Map<Id, ProductCategory> oldRecordsById, Map<Id, ProductCategory> loadedRecordsById) {
        if (loadedRecordsById == null || loadedRecordsById.isEmpty()) {
            return;
        }

        for (ProductCategory recordItem : loadedRecordsById.values()) {
            if (recordItem.Id == null) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
        }
    }

    public static void afterInsert(List<ProductCategory> newRecords) {
        getLoadedRecords(newRecords);
    }

    public static void afterUpdate(List<ProductCategory> newRecords, Map<Id, ProductCategory> oldRecordsById, Map<Id, ProductCategory> persistedRecordsById) {
        getLoadedRecords(newRecords);
    }

    public static void afterDelete(Map<Id, ProductCategory> oldRecordsById) {
        if (oldRecordsById == null) {
            return;
        }
    }

    private static void validateCollection(List<ProductCategory> records) {
        if (records == null || records.isEmpty()) {
            throw new ServiceException(formatLabel(System.Label.Generic_Service_Records_Required, new List<String>{ getObjectLabel() }));
        }
    }

    private static void validateRequiredFields(ProductCategory recordItem) {
        Map<String, Schema.SObjectField> fieldMap = ProductCategory.SObjectType.getDescribe().fields.getMap();
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

    private static Boolean hasChanges(ProductCategory currentRecord, ProductCategory persistedRecord) {
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
        return ProductCategory.SObjectType.getDescribe().getLabel();
    }

    private static String formatLabel(String labelValue, List<String> tokens) {
        return String.format(labelValue, tokens);
    }
}
