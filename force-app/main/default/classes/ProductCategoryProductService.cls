public inherited sharing class ProductCategoryProductService {
    public class ServiceException extends Exception {}

    private static final List<String> TRACKED_FIELDS = new List<String>{
        'Id',
        'IsPrimaryCategory',
        'ProductCategoryId',
        'ProductId'
    };
    private static final List<String> REQUIRED_FIELDS = new List<String>{
        'ProductCategoryId',
        'ProductId'
    };

    public static ProductCategoryProduct getLoadedRecord(ProductCategoryProduct loadedRecord) {
        return loadedRecord;
    }

    public static List<ProductCategoryProduct> getLoadedRecords(List<ProductCategoryProduct> loadedRecords) {
        return loadedRecords == null ? new List<ProductCategoryProduct>() : loadedRecords;
    }

    public static List<ProductCategoryProduct> saveRecords(List<ProductCategoryProduct> records, Map<Id, ProductCategoryProduct> persistedRecordsById) {
        validateCollection(records);

        Map<Id, ProductCategoryProduct> safePersistedRecordsById = persistedRecordsById == null
            ? new Map<Id, ProductCategoryProduct>()
            : persistedRecordsById;
        List<ProductCategoryProduct> recordsToInsert = new List<ProductCategoryProduct>();
        List<ProductCategoryProduct> recordsToUpdate = new List<ProductCategoryProduct>();

        for (ProductCategoryProduct recordItem : records) {
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

    public static void deleteRecords(List<ProductCategoryProduct> records) {
        validateCollection(records);
        for (ProductCategoryProduct recordItem : records) {
            if (recordItem.Id == null) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
        }
        delete records;
    }

    public static void beforeInsert(List<ProductCategoryProduct> newRecords) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }

        for (ProductCategoryProduct recordItem : newRecords) {
            validateRequiredFields(recordItem);
        }
    }

    public static void beforeUpdate(List<ProductCategoryProduct> newRecords, Map<Id, ProductCategoryProduct> oldRecordsById, Map<Id, ProductCategoryProduct> persistedRecordsById) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }

        Map<Id, ProductCategoryProduct> safePersistedRecordsById = persistedRecordsById == null
            ? new Map<Id, ProductCategoryProduct>()
            : persistedRecordsById;

        for (ProductCategoryProduct recordItem : newRecords) {
            if (recordItem.Id == null) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
            if (!safePersistedRecordsById.containsKey(recordItem.Id)) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Not_Found, new List<String>{ getObjectLabel() }));
            }
            validateRequiredFields(recordItem);
        }
    }

    public static void beforeDelete(Map<Id, ProductCategoryProduct> oldRecordsById, Map<Id, ProductCategoryProduct> loadedRecordsById) {
        if (loadedRecordsById == null || loadedRecordsById.isEmpty()) {
            return;
        }

        for (ProductCategoryProduct recordItem : loadedRecordsById.values()) {
            if (recordItem.Id == null) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
        }
    }

    public static void afterInsert(List<ProductCategoryProduct> newRecords) {
        getLoadedRecords(newRecords);
    }

    public static void afterUpdate(List<ProductCategoryProduct> newRecords, Map<Id, ProductCategoryProduct> oldRecordsById, Map<Id, ProductCategoryProduct> persistedRecordsById) {
        getLoadedRecords(newRecords);
    }

    public static void afterDelete(Map<Id, ProductCategoryProduct> oldRecordsById) {
        if (oldRecordsById == null) {
            return;
        }
    }

    private static void validateCollection(List<ProductCategoryProduct> records) {
        if (records == null || records.isEmpty()) {
            throw new ServiceException(formatLabel(System.Label.Generic_Service_Records_Required, new List<String>{ getObjectLabel() }));
        }
    }

    private static void validateRequiredFields(ProductCategoryProduct recordItem) {
        Map<String, Schema.SObjectField> fieldMap = ProductCategoryProduct.SObjectType.getDescribe().fields.getMap();
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

    private static Boolean hasChanges(ProductCategoryProduct currentRecord, ProductCategoryProduct persistedRecord) {
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
        return ProductCategoryProduct.SObjectType.getDescribe().getLabel();
    }

    private static String formatLabel(String labelValue, List<String> tokens) {
        return String.format(labelValue, tokens);
    }
}
