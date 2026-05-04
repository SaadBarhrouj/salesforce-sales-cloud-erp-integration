/**
 * @description Test class for BundleOptionDAO.
 * Validates query behavior for bundle option retrieval under real data scenarios.
 * @author Sales Cloud ERP Integration Team
 */
@IsTest
private class BundleOptionDAOTest {

    /**
     * @description Tests that getByBundleProductId returns options sorted by Sort_Order__c and Name.
     */
    @IsTest
    static void testGetByBundleProductIdReturnsSortedOptions() {
        Product2 bundleProduct = TestDataFactory.createProduct2(true);
        Product2 optionProduct1 = TestDataFactory.createProduct2(true);
        optionProduct1.ProductCode = 'PROD-001';
        update optionProduct1;
        Product2 optionProduct2 = TestDataFactory.createProduct2(true);
        optionProduct2.ProductCode = 'PROD-002';
        update optionProduct2;

        Bundle_Option__c option1 = TestDataFactory.createBundleOption(
            bundleProduct.Id, optionProduct1.Id, null, 'Component', 2,
            1, 0, 10, false, false, false, true
        );
        Bundle_Option__c option2 = TestDataFactory.createBundleOption(
            bundleProduct.Id, optionProduct2.Id, null, 'Related Product', 1,
            1, 0, 10, false, false, false, true
        );

        Test.startTest();
        List<Bundle_Option__c> results = BundleOptionDAO.getByBundleProductId(bundleProduct.Id);
        Test.stopTest();

        System.assertEquals(2, results.size(), 'Should return 2 options for the bundle');
        System.assertEquals(option2.Id, results[0].Id, 'Should be sorted by Sort_Order__c ascending');
        System.assertEquals(option1.Id, results[1].Id, 'Second option should follow sort order');
        System.assertNotEquals(null, results[0].Option_Product__r.Name, 'Should include related product name');
        System.assertEquals('PROD-002', results[0].Option_Product__r.ProductCode, 'Should include related product code');
    }

    /**
     * @description Tests that getByBundleProductId returns an empty list when bundleProductId is null.
     */
    @IsTest
    static void testGetByBundleProductIdNullReturnsEmptyList() {
        Test.startTest();
        List<Bundle_Option__c> results = BundleOptionDAO.getByBundleProductId(null);
        Test.stopTest();

        System.assertNotEquals(null, results, 'Should return empty list, not null');
        System.assertEquals(0, results.size(), 'Should return empty list for null bundleProductId');
    }

    /**
     * @description Tests that getByBundleProductId returns an empty list when no options exist.
     */
    @IsTest
    static void testGetByBundleProductIdNoOptionsReturnsEmptyList() {
        Product2 bundleProduct = TestDataFactory.createProduct2(true);

        Test.startTest();
        List<Bundle_Option__c> results = BundleOptionDAO.getByBundleProductId(bundleProduct.Id);
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Should return empty list when no options exist');
    }

    /**
     * @description Tests that getByBundleProductId returns options with null option product.
     */
    @IsTest
    static void testGetByBundleProductIdWithNullOptionProduct() {
        Product2 bundleProduct = TestDataFactory.createProduct2(true);

        Bundle_Option__c option = new Bundle_Option__c(
            Bundle_Product__c = bundleProduct.Id,
            Option_Type__c = 'Component',
            Sort_Order__c = 1
        );
        insert option;

        Test.startTest();
        List<Bundle_Option__c> results = BundleOptionDAO.getByBundleProductId(bundleProduct.Id);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return the option');
        System.assertEquals(null, results[0].Option_Product__c, 'Option product should be null');
        System.assertEquals(null, results[0].Option_Product__r, 'Related product should be null for null option product');
    }
}