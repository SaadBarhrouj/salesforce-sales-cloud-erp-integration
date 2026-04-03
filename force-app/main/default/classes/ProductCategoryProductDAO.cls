/**
 * Data Access Object for ProductCategoryProduct records.
 * Provides query methods to retrieve ProductCategoryProduct data from the database.
 * Uses inherited sharing to respect record-level security.
 */
public inherited sharing class ProductCategoryProductDAO {
    /*
    public static ProductCategoryProduct getById(Id recordId) {
        if (recordId == null) {
            return null;
        }

        List<ProductCategoryProduct> records = [
            SELECT
                Id,
                IsPrimaryCategory,
                ProductCategoryId,
                ProductId,
                ProductCategory.Name,
                Product.Name
            FROM ProductCategoryProduct
            WHERE Id = :recordId
            LIMIT 1
        ];

        return records.isEmpty() ? null : records[0];
    }

    public static Map<Id, ProductCategoryProduct> getByIds(Set<Id> recordIds) {
        if (recordIds == null || recordIds.isEmpty()) {
            return new Map<Id, ProductCategoryProduct>();
        }

        return new Map<Id, ProductCategoryProduct>([
            SELECT
                Id,
                IsPrimaryCategory,
                ProductCategoryId,
                ProductId,
                ProductCategory.Name,
                Product.Name
            FROM ProductCategoryProduct
            WHERE Id IN :recordIds
        ]);
    }


    public static List<ProductCategoryProduct> getAll() {
        return [
            SELECT
                Id,
                IsPrimaryCategory,
                ProductCategoryId,
                ProductId,
                ProductCategory.Name,
                Product.Name
            FROM ProductCategoryProduct
        ];
    }
    */

    /**
     * Retrieves product count for ProductCategory records.
     * Aggregates the number of products in each category using GROUP BY.
     * Returns empty map if the provided categoryIds set is null or empty.
     * 
     * @param categoryIds Set of ProductCategory IDs to count products for
     * @return Map with category IDs as keys and product counts as values
     */
    public static Map<Id, Integer> getProductCountForCategories(Set<Id> categoryIds) {
        Map<Id, Integer> countMap = new Map<Id, Integer>();
        if (categoryIds == null || categoryIds.isEmpty()) {
            return countMap;
        }
        
        for (AggregateResult ar : [
            SELECT ProductCategory.Id catId, COUNT(Id) prodCount 
            FROM ProductCategoryProduct 
            WHERE ProductCategory.Id IN :categoryIds 
            GROUP BY ProductCategory.Id
        ]) {
            countMap.put((Id)ar.get('catId'), (Integer)ar.get('prodCount'));
        }
        
        return countMap;
    }

    public static Map<Id, Integer> getProductCountForCategoriesByPricebook(Set<Id> categoryIds, Id pricebookId) {
        Map<Id, Integer> countMap = new Map<Id, Integer>();
        if (categoryIds == null || categoryIds.isEmpty() || pricebookId == null) {
            return countMap;
        }

        for (AggregateResult ar : [
            SELECT ProductCategoryId catId, COUNT(Id) prodCount
            FROM ProductCategoryProduct
            WHERE ProductCategoryId IN :categoryIds
              AND Product.IsActive = true
              AND ProductId IN (
                  SELECT Product2Id 
                  FROM PricebookEntry 
                  WHERE Pricebook2Id = :pricebookId AND IsActive = true
              )
            GROUP BY ProductCategoryId
        ]) {
            countMap.put((Id)ar.get('catId'), (Integer)ar.get('prodCount'));
        }

        return countMap;
    }
}
