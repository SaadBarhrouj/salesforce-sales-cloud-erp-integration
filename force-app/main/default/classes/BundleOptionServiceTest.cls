/**
 * @description Test class for BundleOptionService.
 * Tests the getBundleData method and its associated functionality.
 * @author Sales Cloud ERP Integration Team
 */
@IsTest
private class BundleOptionServiceTest {

    // Test data IDs
    private static Id bundleProductId;
    private static Id featureId1;
    private static Id featureId2;
    private static Id optionProduct1Id;
    private static Id optionProduct2Id;
    private static Id optionProduct3Id;

    /**
     * @description Setup method to create test data for bundle options tests.
     * Creates a bundle product with features and options in various configurations.
     * Uses TestDataFactory for consistent test data creation.
     */
    @TestSetup
    static void setup() {
        // Create bundle product using TestDataFactory
        Product2 bundleProduct = TestDataFactory.createProduct2(true);
        bundleProductId = bundleProduct.Id;

        // Create 2 features for the bundle using TestDataFactory
        Bundle_Feature__c feature1 = TestDataFactory.createBundleFeature(
            bundleProduct.Id,
            'Storage Options',
            1,
            'Choose your storage configuration',
            1,
            3,
            true
        );
        featureId1 = feature1.Id;

        Bundle_Feature__c feature2 = TestDataFactory.createBundleFeature(
            bundleProduct.Id,
            'Color Options',
            2,
            'Select your preferred color',
            0,
            1,
            true
        );
        featureId2 = feature2.Id;

        // Create 3 option products using TestDataFactory
        Product2 optionProduct1 = TestDataFactory.createProduct2(true);
        optionProduct1Id = optionProduct1.Id;

        Product2 optionProduct2 = TestDataFactory.createProduct2(true);
        optionProduct2Id = optionProduct2.Id;

        Product2 optionProduct3 = TestDataFactory.createProduct2(true);
        optionProduct3Id = optionProduct3.Id;

        // Create bundle options using TestDataFactory
        // Option 1: assigned to feature1
        TestDataFactory.createBundleOption(
            bundleProduct.Id,
            optionProduct1.Id,
            feature1.Id,
            'Component',
            1,
            0,
            0,
            1,
            false,
            false,
            false,
            true
        );

        // Option 2: assigned to feature1
        TestDataFactory.createBundleOption(
            bundleProduct.Id,
            optionProduct2.Id,
            feature1.Id,
            'Component',
            2,
            1,
            0,
            1,
            false,
            true,
            true,
            true
        );

        // Option 3: assigned to feature2
        TestDataFactory.createBundleOption(
            bundleProduct.Id,
            optionProduct3.Id,
            feature2.Id,
            'Component',
            3,
            0,
            0,
            1,
            true,
            false,
            false,
            true
        );

        // Option 4: NOT assigned to any feature (will go to "Other")
        TestDataFactory.createBundleOption(
            bundleProduct.Id,
            optionProduct1.Id,
            null,
            'Related Product',
            4,
            0,
            0,
            1,
            false,
            false,
            false,
            true
        );
    }

    /**
     * @description Tests that getBundleData returns null when bundleId is null.
     * Verifies proper exception handling for null input.
     */
    @IsTest
    static void testGetBundleDataNullBundleIdThrowsException() {
        Test.startTest();
        try {
            BundleOptionService.getBundleData(null);
            System.assert(false, 'Expected BundleOptionException for null bundleId');
        } catch (BundleOptionException ex) {
            System.assertEquals('Bundle ID is required.', ex.getMessage(),
                'Exception message should indicate bundle ID is required');
        }
        Test.stopTest();
    }

    /**
     * @description Tests that getBundleData throws exception when bundle product is not found.
     * Verifies proper exception handling for invalid bundleId.
     */
    @IsTest
    static void testGetBundleDataBundleNotFoundThrowsException() {
        // Use a fake ID that doesn't correspond to any product
        Id fakeId = '01t00000000000AAA';

        Test.startTest();
        try {
            BundleOptionService.getBundleData(fakeId);
            System.assert(false, 'Expected BundleOptionException when bundle not found');
        } catch (BundleOptionException ex) {
            System.assertEquals('Bundle not found for the provided ID.', ex.getMessage(),
                'Exception message should indicate bundle was not found');
        }
        Test.stopTest();
    }

    /**
     * @description Tests the happy path: bundle with features and options assigned to features.
     * Verifies correct data structure and mapping of options to features.
     */
    @IsTest
    static void testGetBundleDataWithFeaturesAndOptions() {
        // Arrange
        Product2 bundleProduct = [SELECT Id FROM Product2 LIMIT 1];

        // Act
        Test.startTest();
        Map<String, Object> result = BundleOptionService.getBundleData(bundleProduct.Id);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.containsKey('features'), 'Result should contain "features" key');

        List<Map<String, Object>> features = (List<Map<String, Object>>) result.get('features');
        System.assertNotEquals(null, features, 'Features list should not be null');
        System.assertEquals(3, features.size(), 
            'Should have 3 features: 2 created + 1 "Other" feature');

        // Verify first feature (Storage Options)
        Map<String, Object> feature1 = features[0];
        System.assertEquals('Storage Options', feature1.get('Name'),
            'First feature should be "Storage Options"');
        System.assertEquals(2, ((List<Map<String, Object>>) feature1.get('options')).size(),
            'First feature should have 2 options');
        System.assertEquals(1, ((Integer) feature1.get('minOptions')),
            'First feature minOptions should be 1');
        System.assertEquals(3, ((Integer) feature1.get('maxOptions')),
            'First feature maxOptions should be 3');

        // Verify second feature (Color Options)
        Map<String, Object> feature2 = features[1];
        System.assertEquals('Color Options', feature2.get('Name'),
            'Second feature should be "Color Options"');
        System.assertEquals(1, ((List<Map<String, Object>>) feature2.get('options')).size(),
            'Second feature should have 1 option');

        // Verify "Other" feature
        Map<String, Object> otherFeature = features[2];
        System.assertEquals('Other', otherFeature.get('Name'),
            'Third feature should be "Other"');
        System.assertEquals('feature_other', otherFeature.get('Id'),
            'Other feature ID should be "feature_other"');
        System.assertEquals(1, ((List<Map<String, Object>>) otherFeature.get('options')).size(),
            'Other feature should contain 1 unassigned option');
    }

    /**
     * @description Tests bundle with no features but has options.
     * All options should be placed in the "Other" feature.
     */
    @IsTest
    static void testGetBundleDataNoFeaturesAllOptionsGoToOther() {
        // Arrange
        Product2 bundleProduct = TestDataFactory.createProduct2(true);
        Product2 optionProduct = TestDataFactory.createProduct2(true);

        // Create option without any feature using TestDataFactory
        TestDataFactory.createBundleOption(
            bundleProduct.Id,
            optionProduct.Id,
            null,
            'Component',
            1,
            0,
            0,
            1,
            false,
            false,
            false,
            true
        );

        // Act
        Test.startTest();
        Map<String, Object> result = BundleOptionService.getBundleData(bundleProduct.Id);
        Test.stopTest();

        // Assert
        List<Map<String, Object>> features = (List<Map<String, Object>>) result.get('features');
        System.assertEquals(1, features.size(), 'Should have only "Other" feature');

        Map<String, Object> otherFeature = features[0];
        System.assertEquals('Other', otherFeature.get('Name'),
            'Only feature should be "Other"');
        System.assertEquals(1, ((List<Map<String, Object>>) otherFeature.get('options')).size(),
            'Other feature should contain the option');
    }

    /**
     * @description Tests bundle with features but no options.
     * Should return features list without "Other" feature.
     */
    @IsTest
    static void testGetBundleDataWithFeaturesButNoOptions() {
        // Arrange
        Product2 bundleProduct = TestDataFactory.createProduct2(true);

        // Create feature using TestDataFactory
        TestDataFactory.createBundleFeature(
            bundleProduct.Id,
            'Test Feature',
            1,
            'Test help text',
            0,
            5,
            true
        );

        // Act
        Test.startTest();
        Map<String, Object> result = BundleOptionService.getBundleData(bundleProduct.Id);
        Test.stopTest();

        // Assert
        List<Map<String, Object>> features = (List<Map<String, Object>>) result.get('features');
        System.assertEquals(1, features.size(), 'Should have only the created feature');

        Map<String, Object> feature1 = features[0];
        System.assertEquals('Test Feature', feature1.get('Name'),
            'Feature name should match');
        System.assertEquals(0, ((List<Map<String, Object>>) feature1.get('options')).size(),
            'Feature should have no options');
        System.assertEquals(null, feature1.get('helpText'),
            'Help text should be null when not provided');
    }

    /**
     * @description Tests bundle with no features and no options.
     * Should return empty features list.
     */
    @IsTest
    static void testGetBundleDataEmptyBundle() {
        // Arrange
        Product2 bundleProduct = TestDataFactory.createProduct2(true);

        // Act
        Test.startTest();
        Map<String, Object> result = BundleOptionService.getBundleData(bundleProduct.Id);
        Test.stopTest();

        // Assert
        List<Map<String, Object>> features = (List<Map<String, Object>>) result.get('features');
        System.assertEquals(0, features.size(), 'Should have no features');
    }

    /**
     * @description Tests the option payload structure within features.
     * Verifies all required fields are correctly populated in option payloads.
     */
    @IsTest
    static void testGetBundleDataOptionPayloadStructure() {
        // Arrange
        Product2 bundleProduct = [SELECT Id FROM Product2 LIMIT 1];

        // Act
        Test.startTest();
        Map<String, Object> result = BundleOptionService.getBundleData(bundleProduct.Id);
        Test.stopTest();

        // Assert
        List<Map<String, Object>> features = (List<Map<String, Object>>) result.get('features');
        System.assertEquals(3, features.size(), 'Should have 3 features');

        // Get first feature and its options
        Map<String, Object> feature1 = features[0];
        List<Map<String, Object>> options = (List<Map<String, Object>>) feature1.get('options');
        System.assertEquals(2, options.size(), 'First feature should have 2 options');

        // Verify option payload structure
        Map<String, Object> option = options[0];
        System.assert(option.containsKey('Id'), 'Option should have Id');
        System.assert(option.containsKey('Name'), 'Option should have Name');
        System.assert(option.containsKey('productCode'), 'Option should have productCode');
        System.assert(option.containsKey('productName'), 'Option should have productName');
        System.assert(option.containsKey('description'), 'Option should have description');
        System.assert(option.containsKey('defaultQuantity'), 'Option should have defaultQuantity');
        System.assert(option.containsKey('minQuantity'), 'Option should have minQuantity');
        System.assert(option.containsKey('maxQuantity'), 'Option should have maxQuantity');
        System.assert(option.containsKey('quantityEditable'), 'Option should have quantityEditable');
        System.assert(option.containsKey('isRequired'), 'Option should have isRequired');
        System.assert(option.containsKey('isSelected'), 'Option should have isSelected');
        System.assert(option.containsKey('optionType'), 'Option should have optionType');

        // Verify second option has correct attribute values
        Map<String, Object> option2 = options[1];
        System.assertEquals('SSD Storage 512GB', option2.get('Name'),
            'Second option name should match');
        System.assertEquals(1, ((Integer) option2.get('defaultQuantity')),
            'Second option defaultQuantity should be 1');
        System.assertEquals(true, ((Boolean) option2.get('isRequired')),
            'Second option isRequired should be true');
        System.assertEquals(true, ((Boolean) option2.get('isSelected')),
            'Second option isSelected should be true');
    }

    /**
     * @description Tests that feature payload structure is correct.
     * Verifies all required feature fields are present and properly formatted.
     */
    @IsTest
    static void testGetBundleDataFeaturePayloadStructure() {
        // Arrange
        Product2 bundleProduct = [SELECT Id FROM Product2 LIMIT 1];

        // Act
        Test.startTest();
        Map<String, Object> result = BundleOptionService.getBundleData(bundleProduct.Id);
        Test.stopTest();

        // Assert
        List<Map<String, Object>> features = (List<Map<String, Object>>) result.get('features');
        System.assertEquals(3, features.size(), 'Should have 3 features');

        Map<String, Object> feature = features[0];
        System.assert(feature.containsKey('Id'), 'Feature should have Id');
        System.assert(feature.containsKey('Name'), 'Feature should have Name');
        System.assert(feature.containsKey('helpText'), 'Feature should have helpText');
        System.assert(feature.containsKey('minOptions'), 'Feature should have minOptions');
        System.assert(feature.containsKey('maxOptions'), 'Feature should have maxOptions');
        System.assert(feature.containsKey('options'), 'Feature should have options list');
    }

    /**
     * @description Tests feature defaults when Min_Options__c and Max_Options__c are null.
     * Verifies that defaults are properly applied (minOptions=0, maxOptions=999).
     */
    @IsTest
    static void testGetBundleDataFeatureDefaultValues() {
        // Arrange
        Product2 bundleProduct = TestDataFactory.createProduct2(true);

        // Create feature with null min/max options using TestDataFactory
        TestDataFactory.createBundleFeature(
            bundleProduct.Id,
            'Default Feature',
            1,
            null,
            null,
            null,
            true
        );

        // Act
        Test.startTest();
        Map<String, Object> result = BundleOptionService.getBundleData(bundleProduct.Id);
        Test.stopTest();

        // Assert
        List<Map<String, Object>> features = (List<Map<String, Object>>) result.get('features');
        Map<String, Object> feature1 = features[0];

        System.assertEquals(0, ((Integer) feature1.get('minOptions')),
            'Default minOptions should be 0 when null');
        System.assertEquals(999, ((Integer) feature1.get('maxOptions')),
            'Default maxOptions should be 999 when null');
        System.assertEquals(null, feature1.get('helpText'),
            'helpText should be null when not provided');
    }

    /**
     * @description Tests option quantity defaults when numeric fields are null.
     * Verifies that default values are correctly applied to options.
     */
    @IsTest
    static void testGetBundleDataOptionDefaultQuantityValues() {
        // Arrange
        Product2 bundleProduct = TestDataFactory.createProduct2(true);
        Product2 optionProduct = TestDataFactory.createProduct2(true);

        // Create option with null quantity fields using TestDataFactory
        TestDataFactory.createBundleOption(
            bundleProduct.Id,
            optionProduct.Id,
            null,
            'Component',
            1,
            null,
            null,
            null,
            false,
            false,
            false,
            true
        );

        // Act
        Test.startTest();
        Map<String, Object> result = BundleOptionService.getBundleData(bundleProduct.Id);
        Test.stopTest();

        // Assert
        List<Map<String, Object>> features = (List<Map<String, Object>>) result.get('features');
        Map<String, Object> otherFeature = features[0];
        List<Map<String, Object>> options = (List<Map<String, Object>>) otherFeature.get('options');
        Map<String, Object> optionPayload = options[0];

        System.assertEquals(0, ((Integer) optionPayload.get('defaultQuantity')),
            'Default defaultQuantity should be 0 when null');
        System.assertEquals(0, ((Integer) optionPayload.get('minQuantity')),
            'Default minQuantity should be 0 when null');
        System.assertEquals(999, ((Integer) optionPayload.get('maxQuantity')),
            'Default maxQuantity should be 999 when null');
    }

    /**
     * @description Tests the sorting of options within features.
     * Verifies that options are returned in Sort_Order__c order.
     */
    @IsTest
    static void testGetBundleDataOptionSorting() {
        // Arrange
        Product2 bundleProduct = [SELECT Id FROM Product2 LIMIT 1];

        // Act
        Test.startTest();
        Map<String, Object> result = BundleOptionService.getBundleData(bundleProduct.Id);
        Test.stopTest();

        // Assert
        List<Map<String, Object>> features = (List<Map<String, Object>>) result.get('features');
        Map<String, Object> feature1 = features[0];
        List<Map<String, Object>> options = (List<Map<String, Object>>) feature1.get('options');

        // Verify options are in sort order (option1 before option2)
        System.assertEquals('SSD Storage 256GB', options[0].get('Name'),
            'First option should have lowest sort order');
        System.assertEquals('SSD Storage 512GB', options[1].get('Name'),
            'Second option should have higher sort order');
    }

    /**
     * @description Tests product relationship data in option payloads.
     * Verifies that product code, name, and description are correctly populated.
     */
    @IsTest
    static void testGetBundleDataOptionProductRelationshipData() {
        // Arrange
        Product2 bundleProduct = [SELECT Id FROM Product2 LIMIT 1];

        // Get the option product and set its ProductCode
        Product2 optionProduct = [SELECT Id, Name, ProductCode FROM Product2
                                  WHERE Id != :bundleProduct.Id LIMIT 1];
        optionProduct.ProductCode = 'TEST-CODE-123';
        update optionProduct;

        // Act
        Test.startTest();
        Map<String, Object> result = BundleOptionService.getBundleData(bundleProduct.Id);
        Test.stopTest();

        // Assert
        List<Map<String, Object>> features = (List<Map<String, Object>>) result.get('features');
        Map<String, Object> feature1 = features[0];
        List<Map<String, Object>> options = (List<Map<String, Object>>) feature1.get('options');
        Map<String, Object> option = options[0];

        // Verify product data is populated with the related product's values
        System.assertEquals('TEST-CODE-123', option.get('productCode'),
            'Option should use the related product code');
        System.assertEquals(optionProduct.Name, option.get('productName'),
            'Option should use the related product name');
        System.assert(option.containsKey('description'), 'Option should have description');
    }
}
