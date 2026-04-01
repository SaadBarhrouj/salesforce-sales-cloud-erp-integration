/**
 * @description Business logic layer for Product2 records.
 * Handles validation, field tracking, and orchestration between controller and DAO.
 */
public inherited sharing class Product2Service {

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

    /**
     * @description Custom exception for Product2 service layer errors.
     */
    public class ServiceException extends Exception {}

    /**
     * @description Returns a loaded Product2 record.
     * @param loadedRecord The Product2 record to return.
     * @return The loaded Product2 record.
     */
    public static Product2 getLoadedRecord(Product2 loadedRecord) {
        return loadedRecord;
    }

    /**
     * @description Returns a list of loaded Product2 records.
     * @param loadedRecords The list of Product2 records to return.
     * @return List of loaded Product2 records, or empty list if null.
     */
    public static List<Product2> getLoadedRecords(List<Product2> loadedRecords) {
        return loadedRecords == null ? new List<Product2>() : loadedRecords;
    }

    /**
     * @description Retrieves Product2 records filtered by category ID.
     * @param categoryId The ProductCategory ID to filter by.
     * @return List of Product2 records associated with the category.
     */
    public static List<Product2> getByCategoryId(Id categoryId) {
        return getLoadedRecords(Product2DAO.getByCategoryId(categoryId));
    }

    /**
     * @description Inserts or updates Product2 records after validation.
     * @param records The list of Product2 records to save.
     * @param persistedRecordsById Map of existing persisted records by ID.
     * @return List of saved Product2 records.
     */
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

    /**
     * @description Deletes Product2 records after validation.
     * @param records The list of Product2 records to delete.
     */
    public static void deleteRecords(List<Product2> records) {
        validateCollection(records);
        for (Product2 recordItem : records) {
            if (recordItem.Id == null) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
        }
        delete records;
    }

    /**
     * @description Validates Product2 records before insert.
     * @param newRecords The list of new Product2 records to validate.
     */
    public static void beforeInsert(List<Product2> newRecords) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }

        for (Product2 recordItem : newRecords) {
            validateRequiredFields(recordItem);
        }
    }

    /**
     * @description Validates Product2 records before update.
     * @param newRecords The list of new Product2 records.
     * @param oldRecordsById Map of old Product2 records by ID.
     * @param persistedRecordsById Map of persisted Product2 records by ID.
     */
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

    /**
     * @description Validates Product2 records before delete.
     * @param oldRecordsById Map of old Product2 records by ID.
     * @param loadedRecordsById Map of loaded Product2 records by ID.
     */
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

    /**
     * @description Executes post-insert logic for Product2 records.
     * @param newRecords The list of newly inserted Product2 records.
     */
    public static void afterInsert(List<Product2> newRecords) {
        getLoadedRecords(newRecords);
    }

    /**
     * @description Executes post-update logic for Product2 records.
     * @param newRecords The list of updated Product2 records.
     * @param oldRecordsById Map of old Product2 records by ID.
     * @param persistedRecordsById Map of persisted Product2 records by ID.
     */
    public static void afterUpdate(List<Product2> newRecords, Map<Id, Product2> oldRecordsById, Map<Id, Product2> persistedRecordsById) {
        getLoadedRecords(newRecords);
    }

    /**
     * @description Executes post-delete logic for Product2 records.
     * @param oldRecordsById Map of deleted Product2 records by ID.
     */
    public static void afterDelete(Map<Id, Product2> oldRecordsById) {
        if (oldRecordsById == null) {
            return;
        }
    }

    /**
     * @description Validates that the record collection is not null or empty.
     * @param records The list of Product2 records to validate.
     */
    private static void validateCollection(List<Product2> records) {
        if (records == null || records.isEmpty()) {
            throw new ServiceException(formatLabel(System.Label.Generic_Service_Records_Required, new List<String>{ getObjectLabel() }));
        }
    }

    /**
     * @description Validates that required fields are populated on a Product2 record.
     * @param recordItem The Product2 record to validate.
     */
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

    /**
     * @description Determines whether a Product2 record has changes compared to its persisted state.
     * @param currentRecord The current Product2 record.
     * @param persistedRecord The persisted Product2 record.
     * @return True if any tracked field values differ.
     */
    private static Boolean hasChanges(Product2 currentRecord, Product2 persistedRecord) {
        for (String fieldApiName : TRACKED_FIELDS) {
            if (valuesDiffer(currentRecord.get(fieldApiName), persistedRecord.get(fieldApiName))) {
                return true;
            }
        }
        return false;
    }

    /**
     * @description Compares two values for equality using string representation.
     * @param leftValue The first value to compare.
     * @param rightValue The second value to compare.
     * @return True if the string representations differ.
     */
    private static Boolean valuesDiffer(Object leftValue, Object rightValue) {
        return String.valueOf(leftValue) != String.valueOf(rightValue);
    }

    /**
     * @description Returns the label for the Product2 object.
     * @return The Product2 object label.
     */
    private static String getObjectLabel() {
        return Product2.SObjectType.getDescribe().getLabel();
    }

    /**
     * @description Formats a label string with the provided tokens.
     * @param labelValue The label template string.
     * @param tokens The list of tokens to substitute.
     * @return The formatted label string.
     */
    private static String formatLabel(String labelValue, List<String> tokens) {
        return String.format(labelValue, tokens);
    }
}
