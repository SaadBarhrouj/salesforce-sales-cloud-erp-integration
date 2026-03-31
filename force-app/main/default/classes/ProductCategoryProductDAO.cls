public inherited sharing class ProductCategoryProductDAO {
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
}
