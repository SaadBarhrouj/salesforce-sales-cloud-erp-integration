/**
 * @description Test class for VolumePricingScheduleDAO.
 * @author Sales Cloud ERP Integration Team
 */
@IsTest
private class VolumePricingScheduleDAOTest {

    @IsTest
    static void testGetActiveByProductAndPricebookReturnsScheduleWithTiers() {
        Product2 product = TestDataFactory.createProduct2(true);
        Pricebook2 pricebook = TestDataFactory.createPricebook2('Test Pricebook', true, true);

        Volume_Pricing_Schedule__c schedule = TestDataFactory.createVolumePricingSchedule(
            product.Id, pricebook.Id, 'Tiered', true, true
        );

        TestDataFactory.createVolumePricingTier(schedule.Id, 1, 10, 100, 10, true);
        TestDataFactory.createVolumePricingTier(schedule.Id, 11, 20, 90, 20, true);
        TestDataFactory.createVolumePricingTier(schedule.Id, 21, null, 80, 30, true);

        Test.startTest();
        Volume_Pricing_Schedule__c result = VolumePricingScheduleDAO.getActiveByProductAndPricebook(product.Id, pricebook.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return a schedule');
        System.assertEquals(schedule.Id, result.Id, 'Should return the correct schedule');
        System.assertEquals('Tiered', result.Pricing_Type__c, 'Pricing type should match');
        System.assertNotEquals(null, result.Volume_Pricing_Tiers__r, 'Should include child tiers');
        System.assertEquals(3, result.Volume_Pricing_Tiers__r.size(), 'Should return all 3 tiers in order');

        System.assertEquals(1, result.Volume_Pricing_Tiers__r[0].Lower_Bound__c, 'First tier lower bound should be 1');
        System.assertEquals(10, result.Volume_Pricing_Tiers__r[0].Sort_Order__c, 'First tier sort order should be 10');
    }

    @IsTest
    static void testGetActiveByProductAndPricebookReturnsNullWhenNoMatch() {
        Product2 product = TestDataFactory.createProduct2(true);
        Pricebook2 pricebook = TestDataFactory.createPricebook2('Test Pricebook', true, true);

        Test.startTest();
        Volume_Pricing_Schedule__c result = VolumePricingScheduleDAO.getActiveByProductAndPricebook(product.Id, pricebook.Id);
        Test.stopTest();

        System.assertEquals(null, result, 'Should return null when no schedule exists');
    }

    @IsTest
    static void testGetActiveByProductAndPricebookPrefersSpecificPricebookOverGlobal() {
        Product2 product = TestDataFactory.createProduct2(true);
        Pricebook2 specificPricebook = TestDataFactory.createPricebook2('Specific Pricebook', true, true);

        TestDataFactory.createVolumePricingSchedule(
            product.Id, null, 'Block', true, true
        );
        Volume_Pricing_Schedule__c specificSchedule = TestDataFactory.createVolumePricingSchedule(
            product.Id, specificPricebook.Id, 'Tiered', true, true
        );

        Test.startTest();
        Volume_Pricing_Schedule__c result = VolumePricingScheduleDAO.getActiveByProductAndPricebook(product.Id, specificPricebook.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return a schedule');
        System.assertEquals(specificSchedule.Id, result.Id, 'Should prefer the pricebook-specific schedule');
    }

    @IsTest
    static void testGetActiveByProductAndPricebookFallsBackToGlobal() {
        Product2 product = TestDataFactory.createProduct2(true);
        Pricebook2 specificPricebook = TestDataFactory.createPricebook2('Specific Pricebook', true, true);

        Volume_Pricing_Schedule__c globalSchedule = TestDataFactory.createVolumePricingSchedule(
            product.Id, null, 'Block', true, true
        );

        Test.startTest();
        Volume_Pricing_Schedule__c result = VolumePricingScheduleDAO.getActiveByProductAndPricebook(product.Id, specificPricebook.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return global schedule when no pricebook-specific one exists');
        System.assertEquals(globalSchedule.Id, result.Id, 'Should return the global schedule');
    }

    @IsTest
    static void testGetActiveByProductAndPricebookIgnoresInactive() {
        Product2 product = TestDataFactory.createProduct2(true);
        Pricebook2 pricebook = TestDataFactory.createPricebook2('Test Pricebook', true, true);

        TestDataFactory.createVolumePricingSchedule(
            product.Id, pricebook.Id, 'Tiered', false, true
        );

        Test.startTest();
        Volume_Pricing_Schedule__c result = VolumePricingScheduleDAO.getActiveByProductAndPricebook(product.Id, pricebook.Id);
        Test.stopTest();

        System.assertEquals(null, result, 'Should not return inactive schedules');
    }
}