/**
 * @description Data access helper for volume pricing schedules and tiers.
 */
public inherited sharing class VolumePricingScheduleDAO {

    /**
     * @description Returns the active volume pricing schedule for a product and pricebook.
     * @param productId Product Id to search for.
     * @param pricebookId Pricebook Id to search in.
     * @return Matching schedule or null.
     */
    public static Volume_Pricing_Schedule__c getActiveByProductAndPricebook(Id productId, Id pricebookId) {
        List<Volume_Pricing_Schedule__c> schedules = [
            SELECT Id, Product__c, Pricing_Type__c, Pricebook__c, Overage_Rate__c,
                (SELECT Id, Lower_Bound__c, Upper_Bound__c, Price__c, Sort_Order__c
                 FROM Volume_Pricing_Tiers__r
                 ORDER BY Sort_Order__c ASC)
            FROM Volume_Pricing_Schedule__c
            WHERE Product__c = :productId
            AND Is_Active__c = true
            AND (Pricebook__c = :pricebookId OR Pricebook__c = null)
            ORDER BY Pricebook__c DESC NULLS LAST
            LIMIT 1
        ];
        return schedules.isEmpty() ? null : schedules[0];
    }
}