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
    }
}
