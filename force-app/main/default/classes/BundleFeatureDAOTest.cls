/**
 * @description Test class for BundleFeatureDAO.
 * @author Sales Cloud ERP Integration Team
 */
@IsTest
private class BundleFeatureDAOTest {

    @IsTest
    static void testGetByProductIdReturnsFeatures() {
        Product2 bundleProduct = TestDataFactory.createProduct2(true);
        TestDataFactory.createBundleFeature(
            bundleProduct.Id, 'Feature A', 1, 'Help A', 0, 5, true
        );
        TestDataFactory.createBundleFeature(
            bundleProduct.Id, 'Feature B', 2, 'Help B', 1, 3, true
        );

        Test.startTest();
        List<Bundle_Feature__c> results = BundleFeatureDAO.getByProductId(bundleProduct.Id);
        Test.stopTest();

        System.assertEquals(2, results.size(), 'Should return 2 features for the product');
        System.assertEquals('Feature A', results[0].Name, 'Features should be sorted by Sort_Order__c');
        System.assertEquals('Feature B', results[1].Name, 'Second feature should follow sort order');
    }

    @IsTest
    static void testGetByProductIdNullReturnsEmptyList() {
        Test.startTest();
        List<Bundle_Feature__c> results = BundleFeatureDAO.getByProductId(null);
        Test.stopTest();

        System.assertNotEquals(null, results, 'Should return empty list, not null');
        System.assertEquals(0, results.size(), 'Should return empty list for null productId');
    }

    @IsTest
    static void testGetByProductIdNoFeaturesReturnsEmptyList() {
        Product2 bundleProduct = TestDataFactory.createProduct2(true);

        Test.startTest();
        List<Bundle_Feature__c> results = BundleFeatureDAO.getByProductId(bundleProduct.Id);
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Should return empty list when no features exist');
    }

    @IsTest
    static void testGetByProductIdReturnsRelatedProductName() {
        Product2 bundleProduct = TestDataFactory.createProduct2(true);
        TestDataFactory.createBundleFeature(
            bundleProduct.Id, 'Feature A', 1, null, null, null, true
        );

        Test.startTest();
        List<Bundle_Feature__c> results = BundleFeatureDAO.getByProductId(bundleProduct.Id);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return 1 feature');
        System.assertEquals(bundleProduct.Name, results[0].Product__r.Name, 'Should include related product name');
    }
}
