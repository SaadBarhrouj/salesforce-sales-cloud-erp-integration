@IsTest
private class Product2DAOTest {

    @TestSetup
    static void setup() {
        User testUser = TestDataFactory.createUser(true);
        System.runAs(testUser) {
            Product2 product1 = TestDataFactory.createProduct2(true);
            Product2 product2 = TestDataFactory.createProduct2(true);

            ProductCatalog catalog = TestDataFactory.createProductCatalog('Test Catalog', true);
            ProductCategory category = TestDataFactory.createProductCategory(catalog.Id, null, 'Test Category', true, true);

            TestDataFactory.createProductCategoryProduct(category.Id, product1.Id, true);

            Id standardPricebookId = Test.getStandardPricebookId();
            TestDataFactory.createPricebookEntry(standardPricebookId, product1.Id, 50.00, true, true);
            TestDataFactory.createPricebookEntry(standardPricebookId, product2.Id, 75.00, true, true);
        }
    }

    @IsTest
    static void testGetByIdValidIdReturnsRecord() {
        Product2 existingProduct = [SELECT Id FROM Product2 LIMIT 1];

        Test.startTest();
        Product2 result = Product2DAO.getById(existingProduct.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return a record for a valid ID.');
        System.assertEquals(existingProduct.Id, result.Id, 'The returned record ID should match the requested ID.');
    }

    @IsTest
    static void testGetByIdNullIdReturnsNull() {
        Test.startTest();
        Product2 result = Product2DAO.getById(null);
        Test.stopTest();

        System.assertEquals(null, result, 'Should return null for a null ID.');
    }

    @IsTest
    static void testGetByIdNonExistentIdReturnsNull() {
        Id fakeId = Product2.SObjectType.getDescribe().getKeyPrefix() + '000000000000';

        Test.startTest();
        Product2 result = Product2DAO.getById(fakeId);
        Test.stopTest();

        System.assertEquals(null, result, 'Should return null for a non-existent ID.');
    }

    @IsTest
    static void testGetByIdsValidIdsReturnsMap() {
        List<Product2> products = [SELECT Id FROM Product2 LIMIT 2];
        Set<Id> productIds = new Set<Id>();
        for (Product2 p : products) {
            productIds.add(p.Id);
        }

        Test.startTest();
        Map<Id, Product2> result = Product2DAO.getByIds(productIds);
        Test.stopTest();

        System.assertEquals(2, result.size(), 'Should return a map with two records.');
        System.assertEquals(true, result.containsKey(products[0].Id), 'Map should contain the first product ID.');
        System.assertEquals(true, result.containsKey(products[1].Id), 'Map should contain the second product ID.');
    }

    @IsTest
    static void testGetByIdsNullSetReturnsEmptyMap() {
        Test.startTest();
        Map<Id, Product2> result = Product2DAO.getByIds(null);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Should return an empty map for null input.');
    }

    @IsTest
    static void testGetByIdsEmptySetReturnsEmptyMap() {
        Test.startTest();
        Map<Id, Product2> result = Product2DAO.getByIds(new Set<Id>());
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Should return an empty map for empty set.');
    }

    @IsTest
    static void testGetByNameValidNameReturnsRecords() {
        Product2 existingProduct = [SELECT Id, Name FROM Product2 LIMIT 1];

        Test.startTest();
        List<Product2> result = Product2DAO.getByName(existingProduct.Name);
        Test.stopTest();

        System.assertEquals(true, result.size() >= 1, 'Should return at least one record for a valid name.');
        System.assertEquals(existingProduct.Name, result[0].Name, 'The returned record name should match the search name.');
    }

    @IsTest
    static void testGetByNameNullNameReturnsEmptyList() {
        Test.startTest();
        List<Product2> result = Product2DAO.getByName(null);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Should return an empty list for null name.');
    }

    @IsTest
    static void testGetByNameBlankNameReturnsEmptyList() {
        Test.startTest();
        List<Product2> result = Product2DAO.getByName('   ');
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Should return an empty list for blank name.');
    }

    @IsTest
    static void testGetByNameNonExistentNameReturnsEmptyList() {
        Test.startTest();
        List<Product2> result = Product2DAO.getByName('NonExistentProductName');
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Should return an empty list for a non-existent name.');
    }

    @IsTest
    static void testGetAllReturnsAllRecords() {
        Test.startTest();
        List<Product2> result = Product2DAO.getAll();
        Test.stopTest();

        System.assertEquals(true, result.size() >= 2, 'Should return all Product2 records.');
    }

    @IsTest
    static void testGetByCategoryIdNullReturnsAllProducts() {
        Test.startTest();
        List<Product2> result = Product2DAO.getByCategoryId(null);
        Test.stopTest();

        System.assertEquals(true, result.size() >= 2, 'Should return all products when category ID is null.');
    }

    @IsTest
    static void testGetByCategoryIdValidCategoryReturnsFilteredProducts() {
        ProductCategoryProduct pcp = [SELECT ProductId FROM ProductCategoryProduct LIMIT 1];

        ProductCategory category = [SELECT Id FROM ProductCategory LIMIT 1];

        Test.startTest();
        List<Product2> result = Product2DAO.getByCategoryId(category.Id);
        Test.stopTest();

        System.assertEquals(true, result.size() >= 1, 'Should return products assigned to the category.');
        Boolean foundProduct = false;
        for (Product2 p : result) {
            if (p.Id == pcp.ProductId) {
                foundProduct = true;
                break;
            }
        }
        System.assertEquals(true, foundProduct, 'Result should include the product linked to the category.');
    }

    @IsTest
    static void testGetByCategoryIdNonExistentCategoryReturnsEmptyList() {
        Id fakeCategoryId = ProductCategory.SObjectType.getDescribe().getKeyPrefix() + '000000000000';

        Test.startTest();
        List<Product2> result = Product2DAO.getByCategoryId(fakeCategoryId);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Should return an empty list for a non-existent category ID.');
    }

    @IsTest
    static void testGetAllByPricebookNullReturnsAllProducts() {
        Test.startTest();
        List<Product2> result = Product2DAO.getAllByPricebook(null);
        Test.stopTest();

        System.assertEquals(true, result.size() >= 2, 'Should return all products when pricebook ID is null.');
    }

    @IsTest
    static void testGetAllByPricebookValidPricebookReturnsFilteredProducts() {
        Id standardPricebookId = Test.getStandardPricebookId();

        Test.startTest();
        List<Product2> result = Product2DAO.getAllByPricebook(standardPricebookId);
        Test.stopTest();

        System.assertEquals(true, result.size() >= 1, 'Should return products in the specified pricebook.');
        for (Product2 p : result) {
            System.assertEquals(true, p.IsActive, 'All returned products should be active.');
        }
    }

    @IsTest
    static void testGetAllByPricebookEmptyPricebookReturnsEmptyList() {
        Pricebook2 emptyPricebook = TestDataFactory.createPricebook2('Empty Pricebook', true, true);

        Test.startTest();
        List<Product2> result = Product2DAO.getAllByPricebook(emptyPricebook.Id);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Should return an empty list for a pricebook with no products.');
    }

    @IsTest
    static void testGetProductsByCategoriesAndPricebookNullCategoryIdsReturnsAll() {
        // Arrange
        Test.startTest();
        List<Product2> result = Product2DAO.getProductsByCategoriesAndPricebook(null, null, null);
        Test.stopTest();

        // Assert
        System.assertEquals(true, result.size() >= 2, 'Should return all products when category IDs are null.');
    }

    @IsTest
    static void testGetProductsByCategoriesAndPricebookEmptyCategoryIdsReturnsAll() {
        // Arrange
        Test.startTest();
        List<Product2> result = Product2DAO.getProductsByCategoriesAndPricebook(new Set<Id>(), null, null);
        Test.stopTest();

        // Assert
        System.assertEquals(true, result.size() >= 2, 'Should return all products when category IDs are empty.');
    }

    @IsTest
    static void testGetProductsByCategoriesAndPricebookValidCategoryNullPricebookReturnsProducts() {
        // Arrange
        ProductCategory category = [SELECT Id FROM ProductCategory LIMIT 1];
        Set<Id> categoryIds = new Set<Id>{ category.Id };

        Test.startTest();
        List<Product2> result = Product2DAO.getProductsByCategoriesAndPricebook(categoryIds, null, null);
        Test.stopTest();

        // Assert
        System.assertEquals(true, result.size() >= 1, 'Should return products in the category when pricebook is null.');
    }

    @IsTest
    static void testGetProductsByCategoriesAndPricebookValidCategoryAndPricebookReturnsProducts() {
        ProductCategory category = [SELECT Id FROM ProductCategory LIMIT 1];
        ProductCategoryProduct pcp = [SELECT ProductId FROM ProductCategoryProduct WHERE ProductCategoryId = :category.Id LIMIT 1];
        Id standardPricebookId = Test.getStandardPricebookId();
        Set<Id> categoryIds = new Set<Id>{ category.Id };

        Test.startTest();
        List<Product2> result = Product2DAO.getProductsByCategoriesAndPricebook(categoryIds, standardPricebookId, null);
        Test.stopTest();

        System.assertEquals(true, result.size() >= 1, 'Should return products in both the category and pricebook.');
        Boolean foundProduct = false;
        for (Product2 p : result) {
            if (p.Id == pcp.ProductId) {
                foundProduct = true;
                break;
            }
        }
        System.assertEquals(true, foundProduct, 'Result should include the product linked to both category and pricebook.');
    }

    @IsTest
    static void testGetProductsByCategoriesAndPricebookCategoryWithNoPricebookEntryReturnsEmptyList() {
        ProductCatalog catalog = TestDataFactory.createProductCatalog('Isolated Catalog', true);
        ProductCategory isolatedCategory = TestDataFactory.createProductCategory(catalog.Id, null, 'Isolated Category', true, true);
        Product2 isolatedProduct = TestDataFactory.createProduct2(true);
        TestDataFactory.createProductCategoryProduct(isolatedCategory.Id, isolatedProduct.Id, true);

        // This product is not in Standard PB
        Id standardPricebookId = Test.getStandardPricebookId();
        Set<Id> categoryIds = new Set<Id>{ isolatedCategory.Id };

        Test.startTest();
        List<Product2> result = Product2DAO.getProductsByCategoriesAndPricebook(categoryIds, standardPricebookId, null);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Should return an empty list when category products have no pricebook entries.');
    }

    @IsTest
    static void testGetServiceIdsFromIdsReturnsServiceMatchesOnly() {
        Product2 service = TestDataFactory.createProduct2(false);
        service.Family = 'Service';
        insert service;
        Product2 good = [SELECT Id FROM Product2 WHERE Id != :service.Id LIMIT 1];

        Set<Id> input = new Set<Id>{ service.Id, good.Id };

        Test.startTest();
        Set<Id> result = Product2DAO.getServiceIdsFromIds(input);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Only the Service-family product should be returned.');
        System.assertEquals(true, result.contains(service.Id), 'Service product Id should be present in the result.');
        System.assertEquals(false, result.contains(good.Id), 'Non-service product Id must not be present.');
    }

    @IsTest
    static void testGetServiceIdsFromIdsNullInputReturnsEmptySet() {
        Test.startTest();
        Set<Id> result = Product2DAO.getServiceIdsFromIds(null);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Null input should return an empty set.');
    }

    @IsTest
    static void testGetServiceIdsFromIdsEmptyInputReturnsEmptySet() {
        Test.startTest();
        Set<Id> result = Product2DAO.getServiceIdsFromIds(new Set<Id>());
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Empty input should return an empty set.');
    }

    @IsTest
    static void testGetProductsByCategoriesAndPricebookNonExistentCategoryReturnsEmptyList() {
        // Arrange
        Id fakeCategoryId = ProductCategory.SObjectType.getDescribe().getKeyPrefix() + '000000000000';
        Set<Id> categoryIds = new Set<Id>{ fakeCategoryId };

        Test.startTest();
        List<Product2> result = Product2DAO.getProductsByCategoriesAndPricebook(categoryIds, null, null);
        Test.stopTest();

        // Assert
        System.assertEquals(0, result.size(), 'Should return an empty list for a non-existent category ID.');
    }
}
