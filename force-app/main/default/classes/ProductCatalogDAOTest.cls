/**
 * @description Test class for ProductCatalogDAO.
 */
@IsTest
private class ProductCatalogDAOTest {

    @IsTest
    static void getByIdNullReturnsNull() {
        ProductCatalog result = ProductCatalogDAO.getById(null);
        System.assertEquals(null, result, 'Should return null for null Id');
    }

    @IsTest
    static void getByIdValidIdReturnsRecord() {
        ProductCatalog catalog = TestDataFactory.createProductCatalog('Test Catalog', true);

        Test.startTest();
        ProductCatalog result = ProductCatalogDAO.getById(catalog.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return the catalog');
        System.assertEquals(catalog.Id, result.Id, 'Id should match');
        System.assertEquals('Test Catalog', result.Name, 'Name should match');
    }

    @IsTest
    static void getByIdNotFoundReturnsNull() {
        ProductCatalog catalog = TestDataFactory.createProductCatalog('To Delete', true);
        Id catalogId = catalog.Id;
        delete catalog;

        Test.startTest();
        ProductCatalog result = ProductCatalogDAO.getById(catalogId);
        Test.stopTest();

        System.assertEquals(null, result, 'Should return null when record not found');
    }

    @IsTest
    static void getByIdsNullReturnsEmptyMap() {
        Map<Id, ProductCatalog> result = ProductCatalogDAO.getByIds(null);
        System.assertNotEquals(null, result, 'Should return empty map, not null');
        System.assertEquals(0, result.size(), 'Should return empty map for null input');
    }

    @IsTest
    static void getByIdsEmptySetReturnsEmptyMap() {
        Map<Id, ProductCatalog> result = ProductCatalogDAO.getByIds(new Set<Id>());
        System.assertNotEquals(null, result, 'Should return empty map, not null');
        System.assertEquals(0, result.size(), 'Should return empty map for empty set');
    }

    @IsTest
    static void getByIdsValidIdsReturnsMap() {
        ProductCatalog cat1 = TestDataFactory.createProductCatalog('Catalog 1', true);
        ProductCatalog cat2 = TestDataFactory.createProductCatalog('Catalog 2', true);
        Set<Id> ids = new Set<Id>{ cat1.Id, cat2.Id };

        Test.startTest();
        Map<Id, ProductCatalog> result = ProductCatalogDAO.getByIds(ids);
        Test.stopTest();

        System.assertEquals(2, result.size(), 'Should return 2 catalogs');
        System.assertEquals(true, result.containsKey(cat1.Id), 'Should contain first catalog');
        System.assertEquals(true, result.containsKey(cat2.Id), 'Should contain second catalog');
    }

    @IsTest
    static void getByIdsOnlyExistingIdsReturned() {
        ProductCatalog cat1 = TestDataFactory.createProductCatalog('Existing', true);
        Id nonExistentId = ProductCatalog.SObjectType.getDescribe().getKeyPrefix() + '000000000000';
        Set<Id> ids = new Set<Id>{ cat1.Id, nonExistentId };

        Test.startTest();
        Map<Id, ProductCatalog> result = ProductCatalogDAO.getByIds(ids);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should return only existing catalog');
        System.assertEquals(true, result.containsKey(cat1.Id), 'Should contain only existing');
    }

    @IsTest
    static void getByIdQueryReturnsExpectedFields() {
        ProductCatalog catalog = TestDataFactory.createProductCatalog('Fields Test', true);

        Test.startTest();
        ProductCatalog result = ProductCatalogDAO.getById(catalog.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return catalog');
        System.assertEquals(catalog.Id, result.Id, 'Id field should be present');
        System.assertEquals('Fields Test', result.Name, 'Name field should be present');
    }

    @IsTest
    static void getByIdsQueryReturnsExpectedFields() {
        ProductCatalog catalog = TestDataFactory.createProductCatalog('Multi Fields', true);
        Set<Id> ids = new Set<Id>{ catalog.Id };

        Test.startTest();
        Map<Id, ProductCatalog> result = ProductCatalogDAO.getByIds(ids);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should return catalog');
        System.assertEquals('Multi Fields', result.get(catalog.Id).Name, 'Name should be present');
    }

    @IsTest
    static void getByIdSingleRecordLimit() {
        ProductCatalog cat1 = TestDataFactory.createProductCatalog('First', true);
        ProductCatalog cat2 = TestDataFactory.createProductCatalog('Second', true);

        Test.startTest();
        ProductCatalog result = ProductCatalogDAO.getById(cat1.Id);
        Test.stopTest();

        System.assertEquals(cat1.Id, result.Id, 'Should return correct record');
    }

    @IsTest
    static void getByIdsMultipleBatchesHandled() {
        List<ProductCatalog> catalogs = new List<ProductCatalog>();
        for (Integer i = 0; i < 5; i++) {
            catalogs.add(TestDataFactory.createProductCatalog('Batch ' + i, true));
        }
        
        Set<Id> ids = new Set<Id>();
        for (ProductCatalog cat : catalogs) {
            ids.add(cat.Id);
        }

        Test.startTest();
        Map<Id, ProductCatalog> result = ProductCatalogDAO.getByIds(ids);
        Test.stopTest();

        System.assertEquals(5, result.size(), 'Should return all 5 catalogs');
    }
}