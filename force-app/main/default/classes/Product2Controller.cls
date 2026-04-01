/**
 * @description Controller for Product2 CRUD operations exposed to Lightning Web Components.
 * Delegates business logic to Product2Service and data access to Product2DAO.
 */
public with sharing class Product2Controller {
    /**
     * @description Retrieves a single Product2 record by ID.
     * @param recordId The ID of the Product2 record to retrieve.
     * @return The Product2 record with loaded related data.
     */
    @AuraEnabled(cacheable=true)
    public static Product2 getById(Id recordId) {
        try {
            return Product2Service.getLoadedRecord(Product2DAO.getById(recordId));
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    /**
     * @description Retrieves multiple Product2 records by their IDs.
     * @param recordIds The list of Product2 record IDs to retrieve.
     * @return List of Product2 records with loaded related data.
     */
    @AuraEnabled(cacheable=true)
    public static List<Product2> getByIds(List<Id> recordIds) {
        try {
            Set<Id> safeIds = recordIds == null ? new Set<Id>() : new Set<Id>(recordIds);
            return Product2Service.getLoadedRecords(Product2DAO.getByIds(safeIds).values());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    /**
     * @description Retrieves all active Product2 records.
     * @return List of all Product2 records with loaded related data.
     */
    @AuraEnabled(cacheable=true)
    public static List<Product2> getAll() {
        try {
            return Product2Service.getLoadedRecords(Product2DAO.getAll());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    /**
     * @description Retrieves Product2 records filtered by category ID.
     * @param categoryId The ProductCategory ID to filter by. Pass null or empty for all products.
     * @return List of Product2 records associated with the specified category.
     */
    @AuraEnabled(cacheable=true)
    public static List<Product2> getAllByCategory(String categoryId) {
        try {
            Id safeCategoryId = String.isBlank(categoryId) ? null : (Id) categoryId;
            return Product2Service.getByCategoryId(safeCategoryId);
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    /**
     * @description Inserts or updates Product2 records.
     * @param records The list of Product2 records to save.
     * @return List of saved Product2 records with loaded related data.
     */
    @AuraEnabled
    public static List<Product2> saveRecords(List<Product2> records) {
        try {
            Set<Id> recordIds = collectIds(records);
            Map<Id, Product2> persistedRecordsById = Product2DAO.getByIds(recordIds);
            List<Product2> savedRecords = Product2Service.saveRecords(records, persistedRecordsById);
            return Product2Service.getLoadedRecords(Product2DAO.getByIds(collectIds(savedRecords)).values());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    /**
     * @description Deletes Product2 records by their IDs.
     * @param recordIds The list of Product2 record IDs to delete.
     * @return True if deletion was successful.
     */
    @AuraEnabled
    public static Boolean deleteRecords(List<Id> recordIds) {
        try {
            Set<Id> safeIds = recordIds == null ? new Set<Id>() : new Set<Id>(recordIds);
            Map<Id, Product2> loadedRecordsById = Product2DAO.getByIds(safeIds);
            Product2Service.deleteRecords(loadedRecordsById.values());
            return true;
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    /**
     * @description Extracts non-null IDs from a list of Product2 records.
     * @param records The list of Product2 records to extract IDs from.
     * @return Set of non-null record IDs.
     */
    private static Set<Id> collectIds(List<Product2> records) {
        Set<Id> recordIds = new Set<Id>();
        if (records == null) {
            return recordIds;
        }
        for (Product2 recordItem : records) {
            if (recordItem.Id != null) {
                recordIds.add(recordItem.Id);
            }
        }
        return recordIds;
    }

    /**
     * @description Returns the formatted error message for controller exceptions.
     * @return The formatted error message string.
     */
    private static String getControllerErrorMessage() {
        return String.format(System.Label.Generic_Controller_Request_Failed, new List<String>{ Product2.SObjectType.getDescribe().getLabel() });
    }
}
