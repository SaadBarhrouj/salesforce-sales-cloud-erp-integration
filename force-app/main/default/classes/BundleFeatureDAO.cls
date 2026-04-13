/**
 * @description Data Access Object for Bundle_Feature__c records.
 * Provides query methods for retrieving bundle feature data from Salesforce.
 * @author Sales Cloud ERP Integration Team
 */
public inherited sharing class BundleFeatureDAO {

    /**
     * @description Retrieves a list of Bundle_Feature__c records associated with a specific product.
     * PRIMARY method used by BundleOptionService.getBundleData() to load feature definitions.
     * Orders results by Sort_Order__c and Name for consistent display.
     * @param productId The ID of the product (Bundle_Feature__c.Product__c)
     * @return List of Bundle_Feature__c records ordered by sort order and name, or empty list if productId is null
     */
    public static List<Bundle_Feature__c> getByProductId(Id productId) {
        if (productId == null) {
            return new List<Bundle_Feature__c>();
        }

        try {
            return [
                SELECT
                    Id,
                    Name,
                    Help_Text__c,
                    Max_Options__c,
                    Min_Options__c,
                    Product__c,
                    Sort_Order__c,
                    Product__r.Name
                FROM Bundle_Feature__c
                WHERE Product__c = :productId
                ORDER BY Sort_Order__c ASC, Name ASC
            ];
        } catch (QueryException e) {
            System.debug(LoggingLevel.ERROR, 'BundleFeatureDAO.getByProductId failed: ' + e.getMessage() + ' | ProductId: ' + productId);
            throw e;
        }
    }

    // ============================================================================
    // RESERVED METHODS FOR FUTURE USE
    // ============================================================================

    /*
    @description Retrieves a single Bundle_Feature__c record by its ID.
    Includes related product information for display purposes.
    
    public static Bundle_Feature__c getById(Id recordId) {
        if (recordId == null) {
            return null;
        }
        List<Bundle_Feature__c> records = [
            SELECT
                Id,
                Name,
                Help_Text__c,
                Max_Options__c,
                Min_Options__c,
                Product__c,
                Sort_Order__c,
                Product__r.Name
            FROM Bundle_Feature__c
            WHERE Id = :recordId
            LIMIT 1
        ];
        return records.isEmpty() ? null : records[0];
    }
    */

    /*
    @description Retrieves multiple Bundle_Feature__c records by their IDs.
    Includes related product information for display purposes.
    
    public static Map<Id, Bundle_Feature__c> getByIds(Set<Id> recordIds) {
        if (recordIds == null || recordIds.isEmpty()) {
            return new Map<Id, Bundle_Feature__c>();
        }
        return new Map<Id, Bundle_Feature__c>([
            SELECT
                Id,
                Name,
                Help_Text__c,
                Max_Options__c,
                Min_Options__c,
                Product__c,
                Sort_Order__c,
                Product__r.Name
            FROM Bundle_Feature__c
            WHERE Id IN :recordIds
        ]);
    }
    */

    /*
    @description Retrieves Bundle_Feature__c records by exact name match.
    Useful for looking up features by their configured name.
    
    public static List<Bundle_Feature__c> getByName(String recordName) {
        if (String.isBlank(recordName)) {
            return new List<Bundle_Feature__c>();
        }
        return [
            SELECT
                Id,
                Name,
                Help_Text__c,
                Max_Options__c,
                Min_Options__c,
                Product__c,
                Sort_Order__c,
                Product__r.Name
            FROM Bundle_Feature__c
            WHERE Name = :recordName
        ];
    }
    */

    /*
    @description Retrieves all Bundle_Feature__c records from the database.
    Useful for list pages or comprehensive data retrieval scenarios.
    
    public static List<Bundle_Feature__c> getAll() {
        return [
            SELECT
                Id,
                Name,
                Help_Text__c,
                Max_Options__c,
                Min_Options__c,
                Product__c,
                Sort_Order__c,
                Product__r.Name
            FROM Bundle_Feature__c
        ];
    }
    */
}