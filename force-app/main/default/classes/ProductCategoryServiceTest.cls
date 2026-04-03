@IsTest
private class ProductCategoryServiceTest {

    @TestSetup
    static void setup() {
        Id standardPricebookId = Test.getStandardPricebookId();
        
        ProductCatalog saleCatalog = TestDataFactory.createProductCatalog('Sale', true);

        ProductCategory rootCat = TestDataFactory.createProductCategory(
            saleCatalog.Id, null, 'Root Category', true, true
        );
        ProductCategory subCat = TestDataFactory.createProductCategory(
            saleCatalog.Id, rootCat.Id, 'Sub Category', true, true
        );
        TestDataFactory.createProductCategory(
            catalog.Id, null, 'Empty Category', true, true
        );
        TestDataFactory.createProductCategory(
            saleCatalog.Id, null, 'Non Nav Category', false, true
        );

        Product2 prod1 = TestDataFactory.createProduct2(true);
        Product2 prod2 = TestDataFactory.createProduct2(true);
        Product2 prod3 = TestDataFactory.createProduct2(true);

        TestDataFactory.createStandardPricebookEntry(prod1.Id, standardPricebookId);
        TestDataFactory.createStandardPricebookEntry(prod2.Id, standardPricebookId);
        TestDataFactory.createStandardPricebookEntry(prod3.Id, standardPricebookId);

        TestDataFactory.createProductCategoryProduct(rootCat.Id, prod1.Id, true);
        TestDataFactory.createProductCategoryProduct(subCat.Id, prod2.Id, true);

        // Create opportunity with pricebook
        Opportunity opp = TestDataFactory.createOpportunity(catalog.Id, true);
        opp.Pricebook2Id = standardPricebookId;
        update opp;

        // Empty catalog (no categories)
        ProductCatalog rentalCatalog = TestDataFactory.createProductCatalog('Rental and Services', true);
        Opportunity rentalOpp = TestDataFactory.createOpportunity(rentalCatalog.Id, true);
        rentalOpp.Pricebook2Id = standardPricebookId;
        update rentalOpp;
    }


    @IsTest
    static void testBuildSidebarHierarchyByOfferTypeValidDataReturnsHierarchy() {
        // Arrange
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Offer_Type__r.Name = 'Sale' LIMIT 1];

        Test.startTest();
        List<Map<String, Object>> result =
            ProductCategoryService.buildSidebarHierarchyByOfferType(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null.');
        System.assertEquals(1, result.size(),
            'Only one navigational root should be returned (Non Nav Category filtered).');

        Map<String, Object> root = result[0];
        System.assertEquals('Root Category', root.get('label'), 'Root label should match.');

        System.assertEquals(2, (Integer) root.get('value'),
            'Root value should sum its own products plus all descendants.');

        List<Map<String, Object>> children = (List<Map<String, Object>>) root.get('children');
        System.assertNotEquals(null, children, 'Root should have a children list.');
        System.assertEquals(1, children.size(), 'Root should have exactly one child.');
        System.assertEquals('Sub Category', children[0].get('label'), 'Child label should match.');
        System.assertEquals(1, (Integer) children[0].get('value'),
            'Child should report its 1 direct product.');
        System.assertEquals(null, children[0].get('children'),
            'Leaf category should not carry a children key.');
    }

    @IsTest
    static void testBuildSidebarHierarchyByOfferTypeNoPricebookReturnsEmpty() {
        // Arrange
        ProductCatalog catalog = [SELECT Id FROM ProductCatalog WHERE Name = 'Sale' LIMIT 1];
        Opportunity opp = TestDataFactory.createOpportunity(catalog.Id, true);
        
        Test.startTest();
        List<Map<String, Object>> result =
            ProductCategoryService.buildSidebarHierarchyByOfferType(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null.');
        System.assertEquals(0, result.size(),
            'Service should return empty list when Pricebook2Id is not set.');
    }

    @IsTest
    static void testBuildSidebarHierarchyByOfferTypeNoMatchingCatalogReturnsEmpty() {
        // Arrange
        Opportunity opp = [SELECT Id, Offer_Type__c FROM Opportunity WHERE Offer_Type__r.Name = 'Sale' LIMIT 1];
        delete [SELECT Id FROM ProductCatalog WHERE Id = :opp.Offer_Type__c];

        Test.startTest();
        List<Map<String, Object>> result =
            ProductCategoryService.buildSidebarHierarchyByOfferType(opp.Id);
        Test.stopTest();

        System.assertEquals(0, result.size(),
            'Service should return empty list when no ProductCatalog matches.');
    }

    @IsTest
    static void testBuildSidebarHierarchyByOfferTypeEmptyCatalogReturnsEmpty() {
        // Arrange
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Offer_Type__r.Name = 'Rental and Services' LIMIT 1];

        Test.startTest();
        List<Map<String, Object>> result =
            ProductCategoryService.buildSidebarHierarchyByOfferType(opp.Id);
        Test.stopTest();

        System.assertEquals(0, result.size(),
            'Service should return empty list when catalog has no categories.');
    }

    @IsTest
    static void testBuildSidebarHierarchyByOfferTypeDeletedOpportunityReturnsEmpty() {
        Opportunity opp = TestDataFactory.createOpportunity(true);
        Id deletedOppId = opp.Id;
        delete opp;

        Test.startTest();
        List<Map<String, Object>> result =
            ProductCategoryService.buildSidebarHierarchyByOfferType(deletedOppId);
        Test.stopTest();

        System.assertEquals(0, result.size(),
            'Service should return empty list when the Opportunity does not exist.');
    }

    // ──────────────────────────────────────────────
    //  Null Offer_Type__c (Id null) → early return, empty list
    // ──────────────────────────────────────────────
    @IsTest
    static void testBuildSidebarHierarchyByOfferTypeNullOfferTypeReturnsEmpty() {
        // Arrange
        Id standardPricebookId = Test.getStandardPricebookId();
        Opportunity opp = TestDataFactory.createOpportunity(true);
        opp.Pricebook2Id = standardPricebookId;
        opp.Offer_Type__c = null;
        update opp;

        // Act
        Test.startTest();
        List<Map<String, Object>> result =
            ProductCategoryService.buildSidebarHierarchyByOfferType(opp.Id);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, result, 'Result should not be null.');
        System.assertEquals(0, result.size(),
            'Service should return empty list when Offer_Type__c is null.');
    }

    // ──────────────────────────────────────────────
    //  Category with zero products in pricebook → exclude from hierarchy
    // ──────────────────────────────────────────────
    @IsTest
    static void testBuildSidebarHierarchyByOfferTypeCategoryWithZeroProductsFiltered() {
        // Arrange
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Offer_Type__r.Name = 'Sale' LIMIT 1];
        // Verify empty category exists but should be filtered from results (PMD: prevents unused variable warning)
        List<ProductCategory> emptyCategoriesList = [SELECT Id, Name FROM ProductCategory WHERE Name = 'Empty Category' LIMIT 1];

        // Act
        Test.startTest();
        List<Map<String, Object>> result =
            ProductCategoryService.buildSidebarHierarchyByOfferType(opp.Id);
        Test.stopTest();

        System.assertEquals(1, result.size(),
            'Only categories with products in pricebook should be returned.');
        System.assertEquals('Root Category', result[0].get('label'),
            'Root category should be returned as it has products.');
        System.assertNotEquals(null, emptyCategoriesList,
            'Empty category should exist in database but be filtered from results.');
        
        for (Map<String, Object> item : result) {
            System.assertNotEquals('Empty Category', item.get('label'),
                'Empty categories with zero products should be filtered out.');
        }
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
    */

    // ──────────────────────────────────────────────
    //  Category Hierarchy Resolution Tests
    // ──────────────────────────────────────────────

    @IsTest
    static void testGetCategoryIdsWithDescendantsIncludesAllDescendants() {
        ProductCatalog catalog = TestDataFactory.createProductCatalog('Sale', true);
        ProductCategory rootCat = TestDataFactory.createProductCategory(
            catalog.Id, null, 'Root', true, true
        );
        ProductCategory subCat1 = TestDataFactory.createProductCategory(
            catalog.Id, rootCat.Id, 'Sub1', true, true
        );
        ProductCategory subCat2 = TestDataFactory.createProductCategory(
            catalog.Id, rootCat.Id, 'Sub2', true, true
        );
        ProductCategory leafCat = TestDataFactory.createProductCategory(
            catalog.Id, subCat1.Id, 'Leaf', true, true
        );

        Test.startTest();
        Set<Id> result = ProductCategoryDAO.getCategoryIdsWithDescendants(rootCat.Id);
        Test.stopTest();

        System.assertEquals(4, result.size(), 'Should include root and all descendants.');
        System.assert(result.contains(rootCat.Id), 'Should include root category.');
        System.assert(result.contains(subCat1.Id), 'Should include Sub1.');
        System.assert(result.contains(subCat2.Id), 'Should include Sub2.');
        System.assert(result.contains(leafCat.Id), 'Should include Leaf.');
    }

    @IsTest
    static void testGetCategoryIdsWithDescendantsLeafCategoryReturnsOnlyItself() {
        ProductCatalog catalog = TestDataFactory.createProductCatalog('Sale', true);
        ProductCategory leafCat = TestDataFactory.createProductCategory(
            catalog.Id, null, 'Leaf Only', true, true
        );

        Test.startTest();
        Set<Id> result = ProductCategoryDAO.getCategoryIdsWithDescendants(leafCat.Id);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Leaf category should return only itself.');
        System.assert(result.contains(leafCat.Id), 'Should include the leaf category.');
    }

    @IsTest
    static void testGetCategoryIdsWithDescendantsNullIdReturnsEmptySet() {
        Test.startTest();
        Set<Id> result = ProductCategoryDAO.getCategoryIdsWithDescendants(null);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Null category ID should return empty set.');
    }
}