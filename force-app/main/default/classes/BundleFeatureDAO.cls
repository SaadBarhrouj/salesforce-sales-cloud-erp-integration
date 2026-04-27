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
    }
}
