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
                DisplayUrl,
                ExternalDataSourceId,
                ExternalId,
                Family,
                IsActive,
                Name,
                ProductCode,
                QuantityUnitOfMeasure,
                SellerId,
                SourceProductId,
                StockKeepingUnit,
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
                DisplayUrl,
                ExternalDataSourceId,
                ExternalId,
                Family,
                IsActive,
                Name,
                ProductCode,
                QuantityUnitOfMeasure,
                SellerId,
                SourceProductId,
                StockKeepingUnit,
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
                DisplayUrl,
                ExternalDataSourceId,
                ExternalId,
                Family,
                IsActive,
                Name,
                ProductCode,
                QuantityUnitOfMeasure,
                SellerId,
                SourceProductId,
                StockKeepingUnit,
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
                DisplayUrl,
                ExternalDataSourceId,
                ExternalId,
                Family,
                IsActive,
                Name,
                ProductCode,
                QuantityUnitOfMeasure,
                SellerId,
                SourceProductId,
                StockKeepingUnit,
                Unit_Weight_Kg__c,
                (SELECT Id FROM Options__r)
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

        if (!Schema.getGlobalDescribe().containsKey('ProductCategoryProduct')) {
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
                DisplayUrl,
                ExternalDataSourceId,
                ExternalId,
                Family,
                IsActive,
                Name,
                ProductCode,
                QuantityUnitOfMeasure,
                SellerId,
                SourceProductId,
                StockKeepingUnit,
                Unit_Weight_Kg__c,
                (SELECT Id FROM Options__r)
            FROM Product2
            WHERE Id IN :productIds
        ];
    }
}
