/**
 * @description Test class for BundleOptionController.
 * Validates exception handling and service delegation for the bundle configurator LWC.
 * @author Sales Cloud ERP Integration Team
 */
@IsTest
private class BundleOptionControllerTest {

    /**
     * @description Setup method to create test data for bundle controller tests.
     * Creates a bundle product with features and options in various configurations.
     */
    @TestSetup
    static void setup() {
        User testUser = TestDataFactory.createUser(true);
        System.runAs(testUser) {
            Product2 bundleProduct = TestDataFactory.createProduct2(true);
            Product2 optionProduct = TestDataFactory.createProduct2(true);
            Bundle_Feature__c feature = TestDataFactory.createBundleFeature(
                bundleProduct.Id, 'Test Feature', 1, 'Help text', 0, 5, true
            );
            TestDataFactory.createBundleOption(
                bundleProduct.Id, optionProduct.Id, feature.Id, 'Component', 1,
                1, 0, 10, false, false, false, true
            );
        }
    }

    /**
     * @description Tests that getBundleData successfully returns bundle data for a valid bundle.
     */
    @IsTest
    static void testGetBundleDataReturnsBundleData() {
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        Product2 bundleProduct = [SELECT Id FROM Product2 WHERE Name LIKE 'Test Product%' LIMIT 1];
        Map<String, Object> result;

        System.runAs(testUser) {
            Test.startTest();
            result = BundleOptionController.getBundleData(bundleProduct.Id);
            Test.stopTest();
        }

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.containsKey('features'), 'Result should contain features key');
        List<Map<String, Object>> features = (List<Map<String, Object>>) result.get('features');
        System.assertEquals(1, features.size(), 'Should return 1 feature');
    }

    /**
     * @description Tests that getBundleData throws AuraHandledException when bundleId is null.
     */
    @IsTest
    static void testGetBundleDataNullIdThrowsAuraHandledException() {
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        Boolean exceptionThrown = false;

        System.runAs(testUser) {
            Test.startTest();
            try {
                BundleOptionController.getBundleData(null);
            } catch (AuraHandledException ex) {
                exceptionThrown = true;
            }
            Test.stopTest();
        }

        System.assertEquals(true, exceptionThrown, 'Should throw AuraHandledException for null bundleId');
    }

    /**
     * @description Tests that getBundleData throws AuraHandledException when bundle is not found.
     */
    @IsTest
    static void testGetBundleDataBundleNotFoundThrowsAuraHandledException() {
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        Id fakeProductId = Product2.SObjectType.getDescribe().getKeyPrefix() + '000000000000';
        Boolean exceptionThrown = false;

        System.runAs(testUser) {
            Test.startTest();
            try {
                BundleOptionController.getBundleData(fakeProductId);
            } catch (AuraHandledException ex) {
                exceptionThrown = true;
            }
            Test.stopTest();
        }

        System.assertEquals(true, exceptionThrown, 'Should throw AuraHandledException when bundle not found');
    }

    /**
     * @description Tests that getBundleData returns empty features for a bundle with no data.
     */
    @IsTest
    static void testGetBundleDataEmptyBundle() {
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        Product2 emptyBundle = TestDataFactory.createProduct2(true);
        Map<String, Object> result;

        System.runAs(testUser) {
            Test.startTest();
            result = BundleOptionController.getBundleData(emptyBundle.Id);
            Test.stopTest();
        }

        System.assertNotEquals(null, result, 'Result should not be null');
        List<Map<String, Object>> features = (List<Map<String, Object>>) result.get('features');
        System.assertEquals(0, features.size(), 'Should have no features for empty bundle');
    }
}