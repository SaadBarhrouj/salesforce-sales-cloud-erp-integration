public inherited sharing class Product2DAO {
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
                Unit_Weight_Kg__c
            FROM Product2
        ];
    }
}
