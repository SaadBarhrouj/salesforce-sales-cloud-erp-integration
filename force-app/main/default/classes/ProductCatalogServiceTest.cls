@IsTest
private class ProductCatalogServiceTest {
    @TestSetup
    static void setup() {
        TestDataFactory.createProductCatalog(true);
    }

    @IsTest
    static void test_saveRecords_insert_validRecord_persistsRecord() {
        // Arrange
        ProductCatalog recordItem = TestDataFactory.createProductCatalog(false);

        // Act
        Test.startTest();
        List<ProductCatalog> savedRecords = ProductCatalogService.saveRecords(new List<ProductCatalog>{ recordItem }, new Map<Id, ProductCatalog>());
        Test.stopTest();

        // Assert
        System.assertEquals(true, savedRecords[0].Id != null, 'The service should insert a new record when valid data is provided.');
    }

    @IsTest
    static void test_saveRecords_update_changedRecord_updatesRecord() {
        // Arrange
        ProductCatalog recordItem = [SELECT Id FROM ProductCatalog LIMIT 1];
        recordItem = ProductCatalogDAO.getById(recordItem.Id);
        recordItem.Name = 'Updated Catalog';
        Object expectedValue = 'Updated Catalog';
        Map<Id, ProductCatalog> persistedRecordsById = ProductCatalogDAO.getByIds(new Set<Id>{ recordItem.Id });

        // Act
        Test.startTest();
        ProductCatalogService.saveRecords(new List<ProductCatalog>{ recordItem }, persistedRecordsById);
        Test.stopTest();

        // Assert
        ProductCatalog refreshedRecord = ProductCatalogDAO.getById(recordItem.Id);
        System.assertEquals(String.valueOf(expectedValue), String.valueOf(refreshedRecord.get('Name')), 'The service should persist the updated field value.');
    }

    @IsTest
    static void test_saveRecords_emptyList_throwsServiceException() {
        // Arrange
        List<ProductCatalog> emptyRecords = new List<ProductCatalog>();
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            ProductCatalogService.saveRecords(emptyRecords, new Map<Id, ProductCatalog>());
            System.assertEquals('Expected exception', 'No exception', 'The service should throw when an empty list is provided.');
        } catch (ProductCatalogService.ServiceException ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(String.format(System.Label.Generic_Service_Records_Required, new List<String>{ ProductCatalog.SObjectType.getDescribe().getLabel() }), actualMessage, 'The service should return the configured empty-list message.');
    }

    @IsTest
    static void test_saveRecords_missingRequiredField_throwsServiceException() {
        // Arrange
        ProductCatalog recordItem = TestDataFactory.createProductCatalog(false);
        recordItem.Name = null;
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            ProductCatalogService.saveRecords(new List<ProductCatalog>{ recordItem }, new Map<Id, ProductCatalog>());
            System.assertEquals('Expected exception', 'No exception', 'The service should throw when required data is missing.');
        } catch (ProductCatalogService.ServiceException ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(true, actualMessage.contains(ProductCatalog.SObjectType.getDescribe().getLabel()), 'The service should mention the object label in the validation message.');
    }

    @IsTest
    static void test_saveRecords_unchangedRecord_skipsUpdate() {
        // Arrange
        ProductCatalog recordItem = [SELECT Id FROM ProductCatalog LIMIT 1];
        recordItem = ProductCatalogDAO.getById(recordItem.Id);
        String beforeSerialized = JSON.serialize(recordItem);
        Map<Id, ProductCatalog> persistedRecordsById = ProductCatalogDAO.getByIds(new Set<Id>{ recordItem.Id });

        // Act
        Test.startTest();
        List<ProductCatalog> savedRecords = ProductCatalogService.saveRecords(new List<ProductCatalog>{ recordItem }, persistedRecordsById);
        Test.stopTest();

        // Assert
        System.assertEquals(beforeSerialized, JSON.serialize(savedRecords[0]), 'The service should leave an unchanged record untouched.');
    }

    @IsTest
    static void test_deleteRecords_validRecord_deletesRecord() {
        // Arrange
        ProductCatalog recordItem = TestDataFactory.createProductCatalog(true);

        // Act
        Test.startTest();
        ProductCatalogService.deleteRecords(new List<ProductCatalog>{ recordItem });
        Test.stopTest();

        // Assert
        System.assertEquals(0, [SELECT Count() FROM ProductCatalog WHERE Id = :recordItem.Id], 'The service should delete the provided record.');
    }
}
