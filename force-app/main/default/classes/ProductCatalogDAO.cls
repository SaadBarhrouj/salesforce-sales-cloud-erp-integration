/**
 * @description Data Access Object for ProductCatalog records.
 * Data Access Object for ProductCatalog records.
 * Provides query methods to retrieve ProductCatalog data from the database.
 * Uses inherited sharing to respect record-level security.
 */
public inherited sharing class ProductCatalogDAO {
    /**
     * @description Returns a ProductCatalog by Id.
     * @param recordId ProductCatalog Id.
     * @return Matching ProductCatalog or null.
     */
    public static ProductCatalog getById(Id recordId) {
        if (recordId == null) {
            return null;
        }

        List<ProductCatalog> records = [
            SELECT
                Id,
                Name
            FROM ProductCatalog
            WHERE Id = :recordId
            LIMIT 1
        ];

        return records.isEmpty() ? null : records[0];
    }

    /**
     * @description Returns ProductCatalog records keyed by Id.
     * @param recordIds Set of ProductCatalog Ids.
     * @return Map of Id to ProductCatalog.
     */
    public static Map<Id, ProductCatalog> getByIds(Set<Id> recordIds) {
        if (recordIds == null || recordIds.isEmpty()) {
            return new Map<Id, ProductCatalog>();
        }

        return new Map<Id, ProductCatalog>([
            SELECT
                Id,
                Name
            FROM ProductCatalog
            WHERE Id IN :recordIds
        ]);
    }


    /**
     * Retrieves ProductCatalog records by catalog name.
     * Returns empty list if the provided name is blank or no records are found.
     * 
     * @param recordName The catalog name to search for
     * @return List of ProductCatalog records matching the name
     */
   
     /**public static List<ProductCatalog> getByName(String recordName) {
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
    }*/

    /*
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
    */
}
