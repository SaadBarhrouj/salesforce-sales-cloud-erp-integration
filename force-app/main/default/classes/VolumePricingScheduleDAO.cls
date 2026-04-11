public inherited sharing class VolumePricingScheduleDAO {
    public static Volume_Pricing_Schedule__c getActiveByProduct(Id productId) {
        List<Volume_Pricing_Schedule__c> schedules = [
            SELECT Id, Product__c, Pricing_Type__c, Pricebook__c
            FROM Volume_Pricing_Schedule__c
            WHERE Product__c = :productId
            AND Is_Active__c = true
            LIMIT 1
        ];
        return schedules.isEmpty() ? null : schedules[0];
    }

    public static Volume_Pricing_Schedule__c getActiveByProductAndPricebook(Id productId, Id pricebookId) {
        String query = 'SELECT Id, Product__c, Pricing_Type__c, Pricebook__c, ' +
            '(SELECT Id, Lower_Bound__c, Upper_Bound__c, Price__c, Sort_Order__c ' +
            'FROM Volume_Pricing_Tiers__r ORDER BY Sort_Order__c ASC) ' +
            'FROM Volume_Pricing_Schedule__c ' +
            'WHERE Product__c = :productId ' +
            'AND Is_Active__c = true ' +
            'AND (Pricebook__c = :pricebookId OR Pricebook__c = null) ' +
            'ORDER BY Pricebook__c DESC LIMIT 1';

        List<Volume_Pricing_Schedule__c> schedules = Database.query(query);
        return schedules.isEmpty() ? null : schedules[0];
    }

    public static List<Volume_Pricing_Tier__c> getTiersByScheduleId(Id scheduleId) {
        return [
            SELECT Id, Lower_Bound__c, Upper_Bound__c, Price__c, Sort_Order__c
            FROM Volume_Pricing_Tier__c
            WHERE Volume_Pricing_Schedule__c = :scheduleId
            ORDER BY Sort_Order__c ASC
        ];
    }
}