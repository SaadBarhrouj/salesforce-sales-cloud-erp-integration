/**
 * Data Access Object for ProductCategory records.
 * Provides query methods to retrieve ProductCategory data from the database.
 * Uses inherited sharing to respect record-level security.
 */
public inherited sharing class ProductCategoryDAO {
    /*
    public static ProductCategory getById(Id recordId) {
        if (recordId == null) {
            return null;
        }

        List<ProductCategory> records = [
            SELECT
                Id,
                CatalogId,
                Description,
                IsNavigational,
                Name,
                ParentCategoryId,
                SortOrder,
                Catalog.Name
            FROM ProductCategory
            WHERE Id = :recordId
            LIMIT 1
        ];

        return records.isEmpty() ? null : records[0];
    }

    public static Map<Id, ProductCategory> getByIds(Set<Id> recordIds) {
        if (recordIds == null || recordIds.isEmpty()) {
            return new Map<Id, ProductCategory>();
        }

        return new Map<Id, ProductCategory>([
            SELECT
                Id,
                CatalogId,
                Description,
                IsNavigational,
                Name,
                ParentCategoryId,
                SortOrder,
                Catalog.Name
            FROM ProductCategory
            WHERE Id IN :recordIds
        ]);
    }


    public static List<ProductCategory> getByName(String recordName) {
        if (String.isBlank(recordName)) {
            return new List<ProductCategory>();
        }

        return [
            SELECT
                Id,
                CatalogId,
                Description,
                IsNavigational,
                Name,
                ParentCategoryId,
                SortOrder,
                Catalog.Name
            FROM ProductCategory
            WHERE Name = :recordName
        ];
    }

    public static List<ProductCategory> getAll() {
        return [
            SELECT
                Id,
                CatalogId,
                Description,
                IsNavigational,
                Name,
                ParentCategoryId,
                SortOrder,
                Catalog.Name
            FROM ProductCategory
        ];
    }
    */

    /**
     * Retrieves ProductCategory records by catalog ID.
     * Returns all categories for the specified catalog, ordered by parent category and sort order.
     * Returns empty list if the provided catalogId is null.
     * 
     * @param catalogId The ProductCatalog ID to filter categories
     * @return List of ProductCategory records ordered by ParentCategoryId and SortOrder
     */
    public static List<ProductCategory> getByCatalogId(Id catalogId) {
        if (catalogId == null) {
            return new List<ProductCategory>();
        }

        return [
            SELECT
                Id,
                CatalogId,
                Description,
                IsNavigational,
                Name,
                ParentCategoryId,
                SortOrder,
                Catalog.Name
            FROM ProductCategory
            WHERE CatalogId = :catalogId
            ORDER BY ParentCategoryId ASC, SortOrder ASC
        ];
    }
}
