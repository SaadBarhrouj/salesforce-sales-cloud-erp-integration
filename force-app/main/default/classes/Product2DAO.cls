/**
 * @description Data access object for Product2 records.
 * Contains all SOQL queries for Product2 CRUD operations.
 */
public inherited sharing class Product2DAO {
    /**
     * @description Retrieves a single Product2 record by ID.
     * @param recordId The ID of the Product2 record to retrieve.
     * @return The Product2 record, or null if not found.
     */
    public static Product2 getById(Id recordId) {
        if (recordId == null) {
            return null;
        }

        List<Product2> records = [
            SELECT
                Id,
                Description,
                Family,
                IsActive,
                Name,
                ProductCode,
                Unit_Weight_Kg__c
            FROM Product2
            WHERE Id = :recordId
            LIMIT 1
        ];

        return records.isEmpty() ? null : records[0];
    }

    /**
     * @description Retrieves multiple Product2 records by their IDs.
     * @param recordIds The set of Product2 record IDs to retrieve.
     * @return Map of Product2 IDs to records.
     */
    public static Map<Id, Product2> getByIds(Set<Id> recordIds) {
        if (recordIds == null || recordIds.isEmpty()) {
            return new Map<Id, Product2>();
        }

        return new Map<Id, Product2>([
            SELECT
                Id,
                Description,
                Family,
                IsActive,
                Name,
                ProductCode,
                Unit_Weight_Kg__c
            FROM Product2
            WHERE Id IN :recordIds
        ]);
    }


    /**
     * @description Retrieves Product2 records by name.
     * @param recordName The name to search for.
     * @return List of Product2 records matching the name.
     */
    public static List<Product2> getByName(String recordName) {
        if (String.isBlank(recordName)) {
            return new List<Product2>();
        }

        return [
            SELECT
                Id,
                Description,
                Family,
                IsActive,
                Name,
                ProductCode,
                Unit_Weight_Kg__c
            FROM Product2
            WHERE Name = :recordName
        ];
    }

    /**
     * @description Retrieves all Product2 records.
     * @return List of all Product2 records.
     */
    public static List<Product2> getAll() {
        return [
            SELECT
                Id,
                Description,
                Family,
                IsActive,
                Name,
                ProductCode,
                Unit_Weight_Kg__c, Width_cm__c, Height_cm__c, Depth_cm__c, (SELECT Id FROM Options__r)
            FROM Product2
        ];
    }

    /**
     * @description Retrieves Product2 records filtered by category ID via ProductCategoryProduct junction.
     * @param categoryId The ProductCategory ID to filter by. If null, returns all products.
     * @return List of Product2 records associated with the category.
     */
    public static List<Product2> getByCategoryId(Id categoryId) {
        
        if (categoryId == null) {
            return getAll();
        }

        SObjectType productCategoryType = Schema.getGlobalDescribe().get('ProductCategoryProduct');
        if (productCategoryType == null) {
            return getAll();
        }

        Set<Id> productIds = new Set<Id>();
        String query = 'SELECT ProductId FROM ProductCategoryProduct WHERE ProductCategoryId = :categoryId';
        for (SObject pcp : Database.query(query)) {
            productIds.add((Id) pcp.get('ProductId'));
        }

        if (productIds.isEmpty()) {
            return new List<Product2>();
        }

        return [
            SELECT
                Id,
                Description,
                Family,
                IsActive,
                Name,
                ProductCode,
                Unit_Weight_Kg__c, Width_cm__c, Height_cm__c, Depth_cm__c, (SELECT Id FROM Options__r)
            FROM Product2
            WHERE Id IN :productIds
        ];
    }

    /**
     * @description Retrieves all active Product2 records constrained by pricebook.
     * Only returns products that have active PricebookEntry records in the specified pricebook.
     * @param pricebookId The Pricebook2 ID to constrain products to. If null, returns all active products.
     * @return List of Product2 records with active pricebook entries.
     */
    public static List<Product2> getAllByPricebook(Id pricebookId) {
        
        if (pricebookId == null) {
            return getAll();
        }

        Set<Id> productIdsInPricebook = new Set<Id>();
        for (PricebookEntry pbe : [
            SELECT Product2Id
            FROM PricebookEntry
            WHERE Pricebook2Id = :pricebookId
            AND IsActive = true
        ]) {
            productIdsInPricebook.add(pbe.Product2Id);
        }

        if (productIdsInPricebook.isEmpty()) {
            return new List<Product2>();
        }

        return [
            SELECT
                Id,
                Description,
                Family,
                IsActive,
                Name,
                ProductCode,
                Unit_Weight_Kg__c, Width_cm__c, Height_cm__c, Depth_cm__c, (SELECT Id FROM Options__r)
            FROM Product2
            WHERE Id IN :productIdsInPricebook
            AND IsActive = true
        ];
    }

    /**
     * @description Returns the subset of the given Product2 IDs whose Family picklist equals 'Service'.
     * Used to exclude intangible / labor lines from BinSolver packing calculations. Family is the
     * standard categorization field in this org (values: Equipment, Service) — Type is system-managed
     * and cannot accept custom values.
     * @param productIds The Product2 IDs to inspect.
     * @return Set of IDs whose Family = 'Service'. Empty set if input is null/empty or no matches.
     */
    public static Set<Id> getServiceIdsFromIds(Set<Id> productIds) {
        Set<Id> serviceIds = new Set<Id>();

        if (productIds == null || productIds.isEmpty()) {
            return serviceIds;
        }

        try {
            for (Product2 p : [
                SELECT Id
                FROM Product2
                WHERE Id IN :productIds
                AND Family = 'Service'
            ]) {
                serviceIds.add(p.Id);
            }
            return serviceIds;
        } catch (QueryException e) {
            System.debug(LoggingLevel.ERROR, 'Product2DAO.getServiceIdsFromIds failed: ' + e.getMessage());
            throw e;
        }
    }

    /**
     * @description Retrieves Product2 records filtered by multiple category IDs, pricebook, and catalog.
     * Intersects products assigned to the specified categories with products having active
     * PricebookEntry records in the given pricebook, constrained to the specified catalog.
     * @param categoryIds Set of ProductCategory IDs to filter by.
     * @param pricebookId The Pricebook2 ID to constrain products to.
     * @param catalogId The ProductCatalog ID to constrain products to.
     * @return List of Product2 records that are both in the categories and have active pricebook entries.
     */
    public static List<Product2> getProductsByCategoriesAndPricebook(Set<Id> categoryIds, Id pricebookId, Id catalogId) {
        if ((categoryIds == null || categoryIds.isEmpty()) && catalogId == null) {
            return getAllByPricebook(pricebookId);
        }

        SObjectType productCategoryType = Schema.getGlobalDescribe().get('ProductCategoryProduct');
        if (productCategoryType == null) {
            return getAllByPricebook(pricebookId);
        }

        Set<Id> effectiveCategoryIds = new Set<Id>();
        if (categoryIds != null && !categoryIds.isEmpty()) {
            effectiveCategoryIds.addAll(categoryIds);
        }

        if (catalogId != null) {
            Set<Id> catalogCategoryIds = new Set<Id>();
            for (ProductCategory cat : [SELECT Id FROM ProductCategory WHERE CatalogId = :catalogId]) {
                catalogCategoryIds.add(cat.Id);
            }
            if (catalogCategoryIds.isEmpty()) {
                return new List<Product2>();
            }
            if (effectiveCategoryIds.isEmpty()) {
                effectiveCategoryIds.addAll(catalogCategoryIds);
            } else {
                effectiveCategoryIds.retainAll(catalogCategoryIds);
            }
        }
        
        if (effectiveCategoryIds.isEmpty()) {
            return new List<Product2>();
        }

        Set<Id> productIdsFromCategories = new Set<Id>();
        String pcpQuery = 'SELECT ProductId FROM ProductCategoryProduct WHERE ProductCategoryId IN :effectiveCategoryIds';
        for (SObject pcp : Database.query(pcpQuery)) {
            productIdsFromCategories.add((Id) pcp.get('ProductId'));
        }

        if (productIdsFromCategories.isEmpty()) {
            return new List<Product2>();
        }

        if (pricebookId == null) {
            return [
                SELECT
                    Id,
                    Description,
                    Family,
                    IsActive,
                    Name,
                    ProductCode,
                    Unit_Weight_Kg__c, Width_cm__c, Height_cm__c, Depth_cm__c, (SELECT Id FROM Options__r)
                FROM Product2
                WHERE Id IN :productIdsFromCategories
                AND IsActive = true
            ];
        }

        Set<Id> productIdsInPricebook = new Set<Id>();
        for (PricebookEntry pbe : [
            SELECT Product2Id
            FROM PricebookEntry
            WHERE Pricebook2Id = :pricebookId
            AND Product2Id IN :productIdsFromCategories
            AND IsActive = true
        ]) {
            productIdsInPricebook.add(pbe.Product2Id);
        }

        if (productIdsInPricebook.isEmpty()) {
            return new List<Product2>();
        }

        return [
            SELECT
                Id,
                Description,
                Family,
                IsActive,
                Name,
                ProductCode,
                Unit_Weight_Kg__c, Width_cm__c, Height_cm__c, Depth_cm__c, (SELECT Id FROM Options__r)
            FROM Product2
            WHERE Id IN :productIdsInPricebook
            AND IsActive = true
        ];
    }
}
