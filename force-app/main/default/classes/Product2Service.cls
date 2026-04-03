/**
 * @description Business logic layer for Product2 records.
 * Handles validation, field tracking, and orchestration between controller and DAO.
 */
public inherited sharing class Product2Service {

    private static final List<String> TRACKED_FIELDS = new List<String>{
        'Id',
        'Description',
        'Family',
        'IsActive',
        'Name',
        'ProductCode',
        'Unit_Weight_Kg__c'
    };
    private static final List<String> REQUIRED_FIELDS = new List<String>{
        'Name'
    };

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
     * @description Retrieves all active Product2 records constrained by pricebook.
     * Only returns products that have active PricebookEntry records in the specified pricebook.
     * @param pricebookId The Pricebook2 ID to constrain products to.
     * @return List of Product2 records with active pricebook entries.
     */
    public static List<Product2> getAllByPricebook(Id pricebookId) {
        return getLoadedRecords(Product2DAO.getAllByPricebook(pricebookId));
    }

    /**
     * @description Retrieves Product2 records filtered by category hierarchy and pricebook.
     * Resolves all descendant category IDs, then intersects with products having active
     * PricebookEntry records in the specified pricebook.
     * @param categoryId The root ProductCategory ID to filter by.
     * @param pricebookId The Pricebook2 ID to constrain products to.
     * @return List of Product2 records in the category hierarchy with active pricebook entries.
     */
    public static List<Product2> getProductsByCategoryAndPricebook(Id categoryId, Id pricebookId) {
        Set<Id> categoryIds = ProductCategoryDAO.getCategoryIdsWithDescendants(categoryId);
        return getLoadedRecords(Product2DAO.getProductsByCategoriesAndPricebook(categoryIds, pricebookId));
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
                System.debug(LoggingLevel.ERROR, 'Product2Service.saveRecords: Record not found - ' + recordItem.Id);
                throw new Product2Exception(formatLabel(System.Label.Generic_Service_Record_Not_Found, new List<String>{ getObjectLabel() }));
            }

            if (hasChanges(recordItem, safePersistedRecordsById.get(recordItem.Id))) {
                recordsToUpdate.add(recordItem);
            }
        }

        if (!recordsToInsert.isEmpty()) {
            try {
                insert recordsToInsert;
            } catch (DmlException e) {
                System.debug(LoggingLevel.ERROR, 'Product2Service.saveRecords insert failed: ' + e.getMessage());
                throw e;
            }
        }
        if (!recordsToUpdate.isEmpty()) {
            try {
                update recordsToUpdate;
            } catch (DmlException e) {
                System.debug(LoggingLevel.ERROR, 'Product2Service.saveRecords update failed: ' + e.getMessage());
                throw e;
            }
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
                System.debug(LoggingLevel.ERROR, 'Product2Service.deleteRecords: Record ID is required');
                throw new Product2Exception(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
        }
        try {
            delete records;
        } catch (DmlException e) {
            System.debug(LoggingLevel.ERROR, 'Product2Service.deleteRecords failed: ' + e.getMessage());
            throw e;
        }
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
                System.debug(LoggingLevel.ERROR, 'Product2Service.beforeUpdate: Record ID is required');
                throw new Product2Exception(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
            if (!safePersistedRecordsById.containsKey(recordItem.Id)) {
                System.debug(LoggingLevel.ERROR, 'Product2Service.beforeUpdate: Record not found - ' + recordItem.Id);
                throw new Product2Exception(formatLabel(System.Label.Generic_Service_Record_Not_Found, new List<String>{ getObjectLabel() }));
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
                System.debug(LoggingLevel.ERROR, 'Product2Service.beforeDelete: Record ID is required');
                throw new Product2Exception(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
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
            System.debug(LoggingLevel.ERROR, 'Product2Service.validateCollection: Empty collection provided');
            throw new Product2Exception(formatLabel(System.Label.Generic_Service_Records_Required, new List<String>{ getObjectLabel() }));
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
                System.debug(LoggingLevel.ERROR, 'Product2Service.validateRequiredFields: ' + fieldLabel + ' is required');
                throw new Product2Exception(formatLabel(System.Label.Generic_Service_Field_Required, new List<String>{ fieldLabel, getObjectLabel() }));
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
