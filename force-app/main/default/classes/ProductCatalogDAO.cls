public inherited sharing class ProductCatalogDAO {
    public static ProductCatalog getById(Id recordId) {
        if (recordId == null) {
            return null;
        }

        List<ProductCatalog> records = [
            SELECT
                Id,
                Name,
                OwnerId,
                Owner.Name
            FROM ProductCatalog
            WHERE Id = :recordId
            LIMIT 1
        ];

        return records.isEmpty() ? null : records[0];
    }

    public static Map<Id, ProductCatalog> getByIds(Set<Id> recordIds) {
        if (recordIds == null || recordIds.isEmpty()) {
            return new Map<Id, ProductCatalog>();
        }

        return new Map<Id, ProductCatalog>([
            SELECT
                Id,
                Name,
                OwnerId,
                Owner.Name
            FROM ProductCatalog
            WHERE Id IN :recordIds
        ]);
    }


    public static List<ProductCatalog> getByName(String recordName) {
        if (String.isBlank(recordName)) {
            return new List<ProductCatalog>();
        }

        return [
            SELECT
                Id,
                Name,
                OwnerId,
                Owner.Name
            FROM ProductCatalog
            WHERE Name = :recordName
        ];
    }

    public static List<ProductCatalog> getAll() {
        return [
            SELECT
                Id,
                Name,
                OwnerId,
                Owner.Name
            FROM ProductCatalog
        ];
    }
}
