@IsTest
private class ProductCategoryServiceTest {

    @TestSetup
    static void setup() {
        // Main catalog with hierarchy
        ProductCatalog catalog = TestDataFactory.createProductCatalog('Sale', true);

        ProductCategory rootCat = TestDataFactory.createProductCategory(
            catalog.Id, null, 'Root Category', true, true
        );
        ProductCategory subCat = TestDataFactory.createProductCategory(
            catalog.Id, rootCat.Id, 'Sub Category', true, true
        );
        TestDataFactory.createProductCategory(
            catalog.Id, null, 'Non Nav Category', false, true
        );

        Product2 prod1 = TestDataFactory.createProduct2(true);
        Product2 prod2 = TestDataFactory.createProduct2(true);

        TestDataFactory.createProductCategoryProduct(rootCat.Id, prod1.Id, true);
        TestDataFactory.createProductCategoryProduct(subCat.Id, prod2.Id, true);

        TestDataFactory.createOpportunity('Sale', true);

        // Empty catalog (no categories)
        TestDataFactory.createProductCatalog('Rental and Services', true);
        TestDataFactory.createOpportunity('Rental_and_Services', true);
    }


    @IsTest
    static void testBuildSidebarHierarchyByOfferTypeValidDataReturnsHierarchy() {
        // Arrange
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Offer_Type__c = 'Sale' LIMIT 1];

        // Act
        Test.startTest();
        List<Map<String, Object>> result =
            ProductCategoryService.buildSidebarHierarchyByOfferType(opp.Id);
        Test.stopTest();

        // Assert — structure
        System.assertNotEquals(null, result, 'Result should not be null.');
        System.assertEquals(1, result.size(),
            'Only one navigational root should be returned (Non Nav Category filtered).');

        Map<String, Object> root = result[0];
        System.assertEquals('Root Category', root.get('label'), 'Root label should match.');

        // Assert — recursive product count: 1 direct + 1 from child = 2
        System.assertEquals(2, (Integer) root.get('value'),
            'Root value should sum its own products plus all descendants.');

        // Assert — children
        List<Map<String, Object>> children = (List<Map<String, Object>>) root.get('children');
        System.assertNotEquals(null, children, 'Root should have a children list.');
        System.assertEquals(1, children.size(), 'Root should have exactly one child.');
        System.assertEquals('Sub Category', children[0].get('label'), 'Child label should match.');
        System.assertEquals(1, (Integer) children[0].get('value'),
            'Child should report its 1 direct product.');
        System.assertEquals(null, children[0].get('children'),
            'Leaf category should not carry a children key.');
    }

    // ──────────────────────────────────────────────
    //  Blank Offer_Type__c → early return, empty list
    // ──────────────────────────────────────────────
    @IsTest
    static void testBuildSidebarHierarchyByOfferTypeBlankOfferTypeReturnsEmpty() {
        // Arrange
        Opportunity opp = TestDataFactory.createOpportunity(true);

        // Act
        Test.startTest();
        List<Map<String, Object>> result =
            ProductCategoryService.buildSidebarHierarchyByOfferType(opp.Id);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, result, 'Result should not be null.');
        System.assertEquals(0, result.size(),
            'Service should return empty list when Offer_Type__c is blank.');
    }

    // ──────────────────────────────────────────────
    //  No matching catalog → empty list
    // ──────────────────────────────────────────────
    @IsTest
    static void testBuildSidebarHierarchyByOfferTypeNoMatchingCatalogReturnsEmpty() {
        // Arrange
        delete [SELECT Id FROM ProductCatalog];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Offer_Type__c = 'Sale' LIMIT 1];

        // Act
        Test.startTest();
        List<Map<String, Object>> result =
            ProductCategoryService.buildSidebarHierarchyByOfferType(opp.Id);
        Test.stopTest();

        // Assert
        System.assertEquals(0, result.size(),
            'Service should return empty list when no ProductCatalog matches.');
    }

    // ──────────────────────────────────────────────
    //  Catalog exists but has zero categories → empty
    // ──────────────────────────────────────────────
    @IsTest
    static void testBuildSidebarHierarchyByOfferTypeEmptyCatalogReturnsEmpty() {
        // Arrange
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Offer_Type__c = 'Rental_and_Services' LIMIT 1];

        // Act
        Test.startTest();
        List<Map<String, Object>> result =
            ProductCategoryService.buildSidebarHierarchyByOfferType(opp.Id);
        Test.stopTest();

        // Assert
        System.assertEquals(0, result.size(),
            'Service should return empty list when catalog has no categories.');
    }

    // ──────────────────────────────────────────────
    //  Non-existent Opportunity → null opp → empty
    // ──────────────────────────────────────────────
    @IsTest
    static void testBuildSidebarHierarchyByOfferTypeDeletedOpportunityReturnsEmpty() {
        // Arrange — create then delete so we have a valid-format Id that no longer exists
        Opportunity opp = TestDataFactory.createOpportunity(true);
        Id deletedOppId = opp.Id;
        delete opp;

        // Act
        Test.startTest();
        List<Map<String, Object>> result =
            ProductCategoryService.buildSidebarHierarchyByOfferType(deletedOppId);
        Test.stopTest();

        // Assert
        System.assertEquals(0, result.size(),
            'Service should return empty list when the Opportunity does not exist.');
    }

    /*
    @IsTest
    static void test_saveRecords_insert_validRecord_persistsRecord() {
        ProductCategory recordItem = TestDataFactory.createProductCategory(false);
        Test.startTest();
        List<ProductCategory> savedRecords = ProductCategoryService.saveRecords(
            new List<ProductCategory>{ recordItem }, new Map<Id, ProductCategory>());
        Test.stopTest();
        System.assertEquals(true, savedRecords[0].Id != null,
            'The service should insert a new record when valid data is provided.');
    }

    @IsTest
    static void test_saveRecords_update_changedRecord_updatesRecord() {
        ProductCategory recordItem = [SELECT Id FROM ProductCategory LIMIT 1];
        recordItem = ProductCategoryDAO.getById(recordItem.Id);
        recordItem.Description = 'Updated category description';
        Object expectedValue = 'Updated category description';
        Map<Id, ProductCategory> persistedRecordsById =
            ProductCategoryDAO.getByIds(new Set<Id>{ recordItem.Id });
        Test.startTest();
        ProductCategoryService.saveRecords(
            new List<ProductCategory>{ recordItem }, persistedRecordsById);
        Test.stopTest();
        ProductCategory refreshedRecord = ProductCategoryDAO.getById(recordItem.Id);
        System.assertEquals(String.valueOf(expectedValue),
            String.valueOf(refreshedRecord.get('Description')),
            'The service should persist the updated field value.');
    }

    @IsTest
    static void test_saveRecords_emptyList_throwsServiceException() {
        List<ProductCategory> emptyRecords = new List<ProductCategory>();
        String actualMessage = '';
        Test.startTest();
        try {
            ProductCategoryService.saveRecords(emptyRecords, new Map<Id, ProductCategory>());
            System.assertEquals('Expected exception', 'No exception',
                'The service should throw when an empty list is provided.');
        } catch (ProductCategoryService.ServiceException ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();
        System.assertEquals(
            String.format(System.Label.Generic_Service_Records_Required,
                new List<String>{ ProductCategory.SObjectType.getDescribe().getLabel() }),
            actualMessage,
            'The service should return the configured empty-list message.');
    }

    @IsTest
    static void test_saveRecords_missingRequiredField_throwsServiceException() {
        ProductCategory recordItem = TestDataFactory.createProductCategory(false);
        recordItem.CatalogId = null;
        String actualMessage = '';
        Test.startTest();
        try {
            ProductCategoryService.saveRecords(
                new List<ProductCategory>{ recordItem }, new Map<Id, ProductCategory>());
            System.assertEquals('Expected exception', 'No exception',
                'The service should throw when required data is missing.');
        } catch (ProductCategoryService.ServiceException ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();
        System.assertEquals(true,
            actualMessage.contains(ProductCategory.SObjectType.getDescribe().getLabel()),
            'The service should mention the object label in the validation message.');
    }

    @IsTest
    static void test_saveRecords_unchangedRecord_skipsUpdate() {
        ProductCategory recordItem = [SELECT Id FROM ProductCategory LIMIT 1];
        recordItem = ProductCategoryDAO.getById(recordItem.Id);
        String beforeSerialized = JSON.serialize(recordItem);
        Map<Id, ProductCategory> persistedRecordsById =
            ProductCategoryDAO.getByIds(new Set<Id>{ recordItem.Id });
        Test.startTest();
        List<ProductCategory> savedRecords = ProductCategoryService.saveRecords(
            new List<ProductCategory>{ recordItem }, persistedRecordsById);
        Test.stopTest();
        System.assertEquals(beforeSerialized, JSON.serialize(savedRecords[0]),
            'The service should leave an unchanged record untouched.');
    }

    @IsTest
    static void test_deleteRecords_validRecord_deletesRecord() {
        ProductCategory recordItem = TestDataFactory.createProductCategory(true);
        Test.startTest();
        ProductCategoryService.deleteRecords(new List<ProductCategory>{ recordItem });
        Test.stopTest();
        System.assertEquals(0,
            [SELECT Count() FROM ProductCategory WHERE Id = :recordItem.Id],
            'The service should delete the provided record.');
    }
    */
}