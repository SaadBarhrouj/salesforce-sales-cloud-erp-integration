/**
 * @description Controller for Product2 CRUD operations exposed to Lightning Web Components.
 * Delegates business logic to Product2Service and data access to Product2DAO.
 * @author Sales Cloud ERP Integration Team
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
            if (recordId == null) {
                throw new Product2Exception('Product ID cannot be null');
            }
            return Product2Service.getLoadedRecord(Product2DAO.getById(recordId));
        } catch (Product2Exception e) {
            System.debug(LoggingLevel.ERROR, 'Product2Controller.getById: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
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
            if (recordIds == null || recordIds.isEmpty()) {
                throw new Product2Exception('Product IDs list cannot be null or empty');
            }
            Set<Id> safeIds = new Set<Id>(recordIds);
            return Product2Service.getLoadedRecords(Product2DAO.getByIds(safeIds).values());
        } catch (Product2Exception e) {
            System.debug(LoggingLevel.ERROR, 'Product2Controller.getByIds: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
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
        } catch (Product2Exception e) {
            System.debug(LoggingLevel.ERROR, 'Product2Controller.getAll: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
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
            if (safeCategoryId != null && !String.valueOf(safeCategoryId).startsWith('0ZG')) {
                throw new Product2Exception('Invalid Category ID');
            }
            return Product2Service.getByCategoryId(safeCategoryId);
        } catch (Product2Exception e) {
            System.debug(LoggingLevel.ERROR, 'Product2Controller.getAllByCategory: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description Retrieves all active Product2 records constrained by pricebook.
     * Only returns products that have active PricebookEntry records in the specified pricebook.
     * @param pricebookId The Pricebook2 ID to constrain products to. Pass null for no filtering.
     * @return List of Product2 records with active pricebook entries.
     */
    @AuraEnabled(cacheable=true)
    public static List<Product2> getAllByPricebook(String pricebookId) {
        try {
            Id safePricebookId = String.isBlank(pricebookId) ? null : (Id) pricebookId;
            if (safePricebookId != null && !String.valueOf(safePricebookId).startsWith('01s')) {
                throw new Product2Exception('Invalid Pricebook ID');
            }
            return Product2Service.getAllByPricebook(safePricebookId);
        } catch (Product2Exception e) {
            System.debug(LoggingLevel.ERROR, 'Product2Controller.getAllByPricebook: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description Retrieves Product2 records filtered by category hierarchy, pricebook, and catalog.
     * Resolves all descendant categories and constrains products to those with active
     * PricebookEntry records in the specified pricebook, limited to the given catalog.
     * @param categoryId The ProductCategory ID to filter by. Pass null or empty for all products.
     * @param pricebookId The Pricebook2 ID to constrain products to. Pass null for no pricebook filtering.
     * @param catalogId The ProductCatalog ID to constrain products to. Pass null for no catalog filtering.
     * @return List of Product2 records in the category hierarchy with active pricebook entries.
     */
    @AuraEnabled(cacheable=true)
    public static List<Product2> getProductsByCategoryAndPricebook(String categoryId, String pricebookId, String catalogId) {
        try {
            Id safeCategoryId = String.isBlank(categoryId) ? null : (Id) categoryId;
            Id safePricebookId = String.isBlank(pricebookId) ? null : (Id) pricebookId;
            Id safeCatalogId = String.isBlank(catalogId) ? null : (Id) catalogId;
            if (safeCategoryId != null && !String.valueOf(safeCategoryId).startsWith('0ZG')) {
                throw new Product2Exception('Invalid Category ID');
            }
            if (safePricebookId != null && !String.valueOf(safePricebookId).startsWith('01s')) {
                throw new Product2Exception('Invalid Pricebook ID');
            }
            return Product2Service.getProductsByCategoryAndPricebook(safeCategoryId, safePricebookId, safeCatalogId);
        } catch (Product2Exception e) {
            System.debug(LoggingLevel.ERROR, 'Product2Controller.getProductsByCategoryAndPricebook: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
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
            if (records == null || records.isEmpty()) {
                throw new Product2Exception('Records list cannot be null or empty');
            }
            Set<Id> recordIds = collectIds(records);
            Map<Id, Product2> persistedRecordsById = Product2DAO.getByIds(recordIds);
            List<Product2> savedRecords = Product2Service.saveRecords(records, persistedRecordsById);
            return Product2Service.getLoadedRecords(Product2DAO.getByIds(collectIds(savedRecords)).values());
        } catch (Product2Exception e) {
            System.debug(LoggingLevel.ERROR, 'Product2Controller.saveRecords: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
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
            if (recordIds == null || recordIds.isEmpty()) {
                throw new Product2Exception('Record IDs list cannot be null or empty');
            }
            Set<Id> safeIds = new Set<Id>(recordIds);
            Map<Id, Product2> loadedRecordsById = Product2DAO.getByIds(safeIds);
            Product2Service.deleteRecords(loadedRecordsById.values());
            return true;
        } catch (Product2Exception e) {
            System.debug(LoggingLevel.ERROR, 'Product2Controller.deleteRecords: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
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
}
