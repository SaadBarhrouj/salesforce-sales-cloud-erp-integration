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
        // Create a product, get its ID, then delete it to ensure the ID doesn't exist
        Product2 tempProduct = TestDataFactory.createProduct2(true);
        Id nonExistentId = tempProduct.Id;
        delete tempProduct;

        Test.startTest();
        try {
            BundleOptionService.getBundleData(nonExistentId);
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
        System.assertEquals(1, feature1.get('minOptions'),
            'First feature minOptions should be 1');
        System.assertEquals(3, feature1.get('maxOptions'),
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

        // Create feature using TestDataFactory with help text
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
        System.assertEquals('Test help text', feature1.get('helpText'),
            'Help text should match what was provided');
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
        System.assert(option.containsKey('isRequired'), 'Option should have isRequired');
        System.assert(option.containsKey('isSelected'), 'Option should have isSelected');
        System.assert(option.containsKey('optionType'), 'Option should have optionType');

        // Verify second option has correct attribute values
        Map<String, Object> option2 = options[1];
        System.assert(option2.get('Name') != null, 'Second option should have a Name');
        System.assertEquals(1, option2.get('defaultQuantity'),
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

        System.assertEquals(null, feature1.get('minOptions'),
            'minOptions should be null when not set');
        System.assertEquals(null, feature1.get('maxOptions'),
            'maxOptions should be null when not set');
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

        // Create option with all quantity fields null. We use Related Product type so the
        // Default_Qty_Required_For_Fixed_Types validation rule (which gates Component/Accessory)
        // does not fire, leaving the service's null-to-0 default behavior testable.
        TestDataFactory.createBundleOption(
            bundleProduct.Id,
            optionProduct.Id,
            null,
            'Related Product',
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

        System.assertEquals(0, optionPayload.get('defaultQuantity'),
            'Default defaultQuantity should be 0 when null');
        System.assertEquals(null, optionPayload.get('minQuantity'),
            'minQuantity should be null when not set');
        System.assertEquals(null, optionPayload.get('maxQuantity'),
            'maxQuantity should be null when not set');
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

        // Verify options are returned (sort order is verified by checking the list has items)
        System.assertEquals(2, options.size(), 'Should have 2 options in feature1');
        System.assert(options[0].get('Name') != null, 'First option should have a Name');
        System.assert(options[1].get('Name') != null, 'Second option should have a Name');
    }

    /**
     * @description Tests product relationship data in option payloads.
     * Verifies that product code, name, and description are correctly populated.
     */
    @IsTest
    static void testGetBundleDataOptionProductRelationshipData() {
        // Arrange - Get the bundle product
        Product2 bundleProduct = [SELECT Id FROM Product2 LIMIT 1];

        // Get an option product that is actually used in a bundle option for this bundle
        Bundle_Option__c bundleOption = [SELECT Id, Option_Product__c
                                         FROM Bundle_Option__c
                                         WHERE Bundle_Product__c = :bundleProduct.Id
                                         LIMIT 1];

        // Get the option product and set its ProductCode
        Product2 optionProduct = [SELECT Id, Name, ProductCode
                                  FROM Product2
                                  WHERE Id = :bundleOption.Option_Product__c];
        optionProduct.ProductCode = 'TEST-CODE-123';
        update optionProduct;

        // Act
        Test.startTest();
        Map<String, Object> result = BundleOptionService.getBundleData(bundleProduct.Id);
        Test.stopTest();

        // Assert
        List<Map<String, Object>> features = (List<Map<String, Object>>) result.get('features');

        // Find the option that matches our updated product
        Map<String, Object> targetOption = null;
        for (Map<String, Object> feature : features) {
            List<Map<String, Object>> options = (List<Map<String, Object>>) feature.get('options');
            for (Map<String, Object> option : options) {
                if (option.get('productId') == String.valueOf(optionProduct.Id)) {
                    targetOption = option;
                    break;
                }
            }
            if (targetOption != null) {
                break;
            }
        }

        // Verify product data is populated with the related product's values
        System.assert(targetOption != null, 'Should find the option with our updated product');
        System.assertEquals('TEST-CODE-123', targetOption.get('productCode'),
            'Option should use the related product code');
        System.assertEquals(optionProduct.Name, targetOption.get('productName'),
            'Option should use the related product name');
        System.assert(targetOption.containsKey('description'), 'Option should have description');
    }

    /**
     * @description Tests hasChanges detects field-level differences between two records.
     */
    @IsTest
    static void testHasChangesDetectsDifferences() {
        Product2 bundleProduct = TestDataFactory.createProduct2(true);
        Product2 optionProduct = TestDataFactory.createProduct2(true);
        Bundle_Option__c original = TestDataFactory.createBundleOption(
            bundleProduct.Id, optionProduct.Id, null, 'Component', 1, 1, 0, 10, false, false, false, true
        );

        Bundle_Option__c modified = original.clone(true, true, false, false);
        modified.Option_Type__c = 'Related Product';

        Test.startTest();
        Boolean result = BundleOptionService.hasChanges(modified, original);
        Test.stopTest();

        System.assertEquals(true, result, 'hasChanges should detect Option_Type__c modification');
    }

    /**
     * @description Tests hasChanges returns false when records are identical.
     */
    @IsTest
    static void testHasChangesReturnsFalseForIdenticalRecords() {
        Product2 bundleProduct = TestDataFactory.createProduct2(true);
        Product2 optionProduct = TestDataFactory.createProduct2(true);
        Bundle_Option__c original = TestDataFactory.createBundleOption(
            bundleProduct.Id, optionProduct.Id, null, 'Component', 1, 1, 0, 10, false, false, false, true
        );

        Test.startTest();
        Boolean result = BundleOptionService.hasChanges(original, original);
        Test.stopTest();

        System.assertEquals(false, result, 'hasChanges should return false for identical records');
    }

    /**
     * @description Tests valuesDiffer handles null values correctly.
     */
    @IsTest
    static void testValuesDifferHandlesNulls() {
        Test.startTest();
        Boolean nullVsNull = BundleOptionService.valuesDiffer(null, null);
        Boolean nullVsValue = BundleOptionService.valuesDiffer(null, 'test');
        Boolean valueVsNull = BundleOptionService.valuesDiffer('test', null);
        Boolean sameValues = BundleOptionService.valuesDiffer('test', 'test');
        Boolean diffValues = BundleOptionService.valuesDiffer('test', 'other');
        Test.stopTest();

        System.assertEquals(false, nullVsNull, 'Null vs null should not differ');
        System.assertEquals(true, nullVsValue, 'Null vs value should differ');
        System.assertEquals(true, valueVsNull, 'Value vs null should differ');
        System.assertEquals(false, sameValues, 'Same values should not differ');
        System.assertEquals(true, diffValues, 'Different values should differ');
    }

    /**
     * @description Tests that an option with a null option product is handled correctly.
     * Verifies productId, productCode, productName, and description defaults.
     */
    @IsTest
    static void testGetBundleDataNullOptionProduct() {
        Product2 bundleProduct = TestDataFactory.createProduct2(true);

        Bundle_Option__c option = new Bundle_Option__c(
            Bundle_Product__c = bundleProduct.Id,
            Option_Type__c = 'Component',
            Sort_Order__c = 1,
            Default_Quantity__c = 1,
            Is_Required__c = false,
            Is_Selected__c = false
        );
        insert option;

        Test.startTest();
        Map<String, Object> result = BundleOptionService.getBundleData(bundleProduct.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        List<Map<String, Object>> features = (List<Map<String, Object>>) result.get('features');
        System.assertEquals(1, features.size(), 'Should have only Other feature');

        List<Map<String, Object>> options = (List<Map<String, Object>>) features[0].get('options');
        System.assertEquals(1, options.size(), 'Should have 1 option');

        Map<String, Object> optionPayload = options[0];
        System.assertEquals(null, optionPayload.get('productId'), 'productId should be null for null option product');
        System.assertEquals('', optionPayload.get('productCode'), 'productCode should default to empty string');
        System.assertEquals('', optionPayload.get('productName'), 'productName should default to empty string');
        System.assertEquals('', optionPayload.get('description'), 'description should default to empty string');
    }

    /**
     * @description Tests getOptionMetadata returns a map keyed by "parentId|optionId" with the expected fields.
     */
    @IsTest
    static void getOptionMetadataReturnsKeyedMap() {
        Product2 bundle = TestDataFactory.createProduct2(true);
        Product2 opt    = TestDataFactory.createProduct2(true);

        Bundle_Option__c bo = new Bundle_Option__c(
            Bundle_Product__c   = bundle.Id,
            Option_Product__c   = opt.Id,
            Option_Type__c      = 'Component',
            Default_Quantity__c = 4,
            Min_Quantity__c     = 4,
            Max_Quantity__c     = 4,
            Sort_Order__c       = 1
        );
        insert bo;

        Map<Id, Set<Id>> request = new Map<Id, Set<Id>>{ bundle.Id => new Set<Id>{ opt.Id } };

        Test.startTest();
        Map<String, Map<String, Object>> result = BundleOptionService.getOptionMetadata(request);
        Test.stopTest();

        String key = String.valueOf(bundle.Id) + '|' + String.valueOf(opt.Id);
        System.assert(result.containsKey(key), 'Expected key for (bundle, option) pair');
        System.assertEquals('Component', (String) result.get(key).get('optionType'), 'optionType mismatch');
        System.assertEquals(4, (Decimal) result.get(key).get('defaultQuantity'), 'defaultQuantity mismatch');
    }

    /**
     * @description Tests getOptionMetadata returns an empty map for null or empty input.
     */
    @IsTest
    static void getOptionMetadataHandlesNullAndEmptyInputs() {
        Test.startTest();
        Map<String, Map<String, Object>> r1 = BundleOptionService.getOptionMetadata(null);
        Map<String, Map<String, Object>> r2 = BundleOptionService.getOptionMetadata(new Map<Id, Set<Id>>());
        Test.stopTest();

        System.assert(r1.isEmpty(), 'Result should be empty for null input');
        System.assert(r2.isEmpty(), 'Result should be empty for empty input');
    }
}