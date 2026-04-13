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
     * @description Counts active products per category for a given pricebook.
     * @param categoryIds Category Ids to aggregate.
     * @param pricebookId Pricebook Id used to filter active products.
     * @return Map of category Id to product count.
     */
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
