/**
 * @description Data Access Object for Bundle_Option__c records.
 * Provides query methods for retrieving bundle option data from Salesforce.
 * @author Sales Cloud ERP Integration Team
 */
public inherited sharing class BundleOptionDAO {

     /**
     * @description Retrieves all Bundle_Option__c records associated with a specific bundle product.
     * PRIMARY method used by BundleOptionService.getBundleData() to load bundle configuration.
     * Includes option product code and description for display purposes.
     * Orders results by Sort_Order__c and Name for consistent presentation.
     * @param bundleProductId The ID of the bundle product (Bundle_Option__c.Bundle_Product__c)
     * @return List of Bundle_Option__c records ordered by sort order and name, or empty list if bundleProductId is null
     */
    public static List<Bundle_Option__c> getByBundleProductId(Id bundleProductId) {
        if (bundleProductId == null) {
            return new List<Bundle_Option__c>();
        }

        try {
            return [
                SELECT
                    Id,
                    Name,
                    Bundle_Product__c,
                    Default_Quantity__c,
                    Feature__c,
                    Is_Required__c,
                    Is_Selected__c,
                    Max_Quantity__c,
                    Min_Quantity__c,
                    Option_Product__c,
                    Option_Type__c,
                    Quantity_Editable__c,
                    Sort_Order__c,
                    Bundle_Product__r.Name,
                    Feature__r.Name,
                    Option_Product__r.Name,
                    Option_Product__r.ProductCode,
                    Option_Product__r.Description
                FROM Bundle_Option__c
                WHERE Bundle_Product__c = :bundleProductId
                ORDER BY Sort_Order__c ASC, Name ASC
            ];
        } catch (QueryException e) {
            System.debug(LoggingLevel.ERROR, 'BundleOptionDAO.getByBundleProductId failed: ' + e.getMessage() + ' | BundleProductId: ' + bundleProductId);
            throw e;
        }
    }


    // ============================================================================
    // RESERVED METHODS FOR FUTURE USE - Uncomment when needed
    // ============================================================================


    /**
     * @description Retrieves a single Bundle_Option__c record by its ID.
     * Includes related bundle product, feature, and option product information.
     * @param recordId The ID of the Bundle_Option__c record
     * @return The Bundle_Option__c record, or null if not found or if recordId is null
     */
   /* public static Bundle_Option__c getById(Id recordId) {
        if (recordId == null) {
            return null;
        }

        try {
            List<Bundle_Option__c> records = [
                SELECT
                    Id,
                    Name,
                    Bundle_Product__c,
                    Default_Quantity__c,
                    Feature__c,
                    Is_Required__c,
                    Is_Selected__c,
                    Max_Quantity__c,
                    Min_Quantity__c,
                    Option_Product__c,
                    Option_Type__c,
                    Quantity_Editable__c,
                    Sort_Order__c,
                    Bundle_Product__r.Name,
                    Feature__r.Name,
                    Option_Product__r.Name
                FROM Bundle_Option__c
                WHERE Id = :recordId
                LIMIT 1
            ];
            return records.isEmpty() ? null : records[0];
        } catch (QueryException e) {
            System.debug(LoggingLevel.ERROR, 'BundleOptionDAO.getById failed: ' + e.getMessage() + ' | RecordId: ' + recordId);
            throw e;
        }
    }
 */
    /**
     * @description Retrieves multiple Bundle_Option__c records by their IDs.
     * Includes related bundle product, feature, and option product information.
     * @param recordIds Set of Bundle_Option__c record IDs to retrieve
     * @return Map of record IDs to Bundle_Option__c records, or empty map if recordIds is null or empty
     */
    /*public static Map<Id, Bundle_Option__c> getByIds(Set<Id> recordIds) {
        if (recordIds == null || recordIds.isEmpty()) {
            return new Map<Id, Bundle_Option__c>();
        }

        try {
            return new Map<Id, Bundle_Option__c>([
                SELECT
                    Id,
                    Name,
                    Bundle_Product__c,
                    Default_Quantity__c,
                    Feature__c,
                    Is_Required__c,
                    Is_Selected__c,
                    Max_Quantity__c,
                    Min_Quantity__c,
                    Option_Product__c,
                    Option_Type__c,
                    Quantity_Editable__c,
                    Sort_Order__c,
                    Bundle_Product__r.Name,
                    Feature__r.Name,
                    Option_Product__r.Name
                FROM Bundle_Option__c
                WHERE Id IN :recordIds
            ]);
        } catch (QueryException e) {
            System.debug(LoggingLevel.ERROR, 'BundleOptionDAO.getByIds failed: ' + e.getMessage());
            throw e;
        }
    }
*/
    /**
     * @description Retrieves all Bundle_Option__c records from the database.
     * Includes related bundle product, feature, and option product information.
     * @return List of all Bundle_Option__c records
     */
    /*public static List<Bundle_Option__c> getAll() {
        try {
            return [
                SELECT
                    Id,
                    Name,
                    Bundle_Product__c,
                    Default_Quantity__c,
                    Feature__c,
                    Is_Required__c,
                    Is_Selected__c,
                    Max_Quantity__c,
                    Min_Quantity__c,
                    Option_Product__c,
                    Option_Type__c,
                    Quantity_Editable__c,
                    Sort_Order__c,
                    Bundle_Product__r.Name,
                    Feature__r.Name,
                    Option_Product__r.Name
                FROM Bundle_Option__c
            ];
        } catch (QueryException e) {
            System.debug(LoggingLevel.ERROR, 'BundleOptionDAO.getAll failed: ' + e.getMessage());
            throw e;
        }
    }
*/
   


    /*
    @description Retrieves Bundle_Option__c records by exact name match.
    Useful for looking up options by their configured name.
    
    public static List<Bundle_Option__c> getByName(String recordName) {
        if (String.isBlank(recordName)) {
            return new List<Bundle_Option__c>();
        }
        return [
            SELECT
                Id,
                Name,
                Bundle_Product__c,
                Default_Quantity__c,
                Feature__c,
                Is_Required__c,
                Is_Selected__c,
                Max_Quantity__c,
                Min_Quantity__c,
                Option_Product__c,
                Option_Type__c,
                Quantity_Editable__c,
                Sort_Order__c,
                Bundle_Product__r.Name,
                Feature__r.Name,
                Option_Product__r.Name
            FROM Bundle_Option__c
            WHERE Name = :recordName
        ];
    }
    */
}
