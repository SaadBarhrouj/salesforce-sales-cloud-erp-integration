@IsTest
private class ProductCategoryServiceTest {
    @TestSetup
    static void setup() {
        TestDataFactory.createProductCategory(true);
    }

    @IsTest
    static void test_saveRecords_insert_validRecord_persistsRecord() {
        // Arrange
        ProductCategory recordItem = TestDataFactory.createProductCategory(false);

        // Act
        Test.startTest();
        List<ProductCategory> savedRecords = ProductCategoryService.saveRecords(new List<ProductCategory>{ recordItem }, new Map<Id, ProductCategory>());
        Test.stopTest();

        // Assert
        System.assertEquals(true, savedRecords[0].Id != null, 'The service should insert a new record when valid data is provided.');
    }

    @IsTest
    static void test_saveRecords_update_changedRecord_updatesRecord() {
        // Arrange
        ProductCategory recordItem = [SELECT Id FROM ProductCategory LIMIT 1];
        recordItem = ProductCategoryDAO.getById(recordItem.Id);
        recordItem.Description = 'Updated category description';
        Object expectedValue = 'Updated category description';
        Map<Id, ProductCategory> persistedRecordsById = ProductCategoryDAO.getByIds(new Set<Id>{ recordItem.Id });

        // Act
        Test.startTest();
        ProductCategoryService.saveRecords(new List<ProductCategory>{ recordItem }, persistedRecordsById);
        Test.stopTest();

        // Assert
        ProductCategory refreshedRecord = ProductCategoryDAO.getById(recordItem.Id);
        System.assertEquals(String.valueOf(expectedValue), String.valueOf(refreshedRecord.get('Description')), 'The service should persist the updated field value.');
    }

    @IsTest
    static void test_saveRecords_emptyList_throwsServiceException() {
        // Arrange
        List<ProductCategory> emptyRecords = new List<ProductCategory>();
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            ProductCategoryService.saveRecords(emptyRecords, new Map<Id, ProductCategory>());
            System.assertEquals('Expected exception', 'No exception', 'The service should throw when an empty list is provided.');
        } catch (ProductCategoryService.ServiceException ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(String.format(System.Label.Generic_Service_Records_Required, new List<String>{ ProductCategory.SObjectType.getDescribe().getLabel() }), actualMessage, 'The service should return the configured empty-list message.');
    }

    @IsTest
    static void test_saveRecords_missingRequiredField_throwsServiceException() {
        // Arrange
        ProductCategory recordItem = TestDataFactory.createProductCategory(false);
        recordItem.CatalogId = null;
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            ProductCategoryService.saveRecords(new List<ProductCategory>{ recordItem }, new Map<Id, ProductCategory>());
            System.assertEquals('Expected exception', 'No exception', 'The service should throw when required data is missing.');
        } catch (ProductCategoryService.ServiceException ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(true, actualMessage.contains(ProductCategory.SObjectType.getDescribe().getLabel()), 'The service should mention the object label in the validation message.');
    }

    @IsTest
    static void test_saveRecords_unchangedRecord_skipsUpdate() {
        // Arrange
        ProductCategory recordItem = [SELECT Id FROM ProductCategory LIMIT 1];
        recordItem = ProductCategoryDAO.getById(recordItem.Id);
        String beforeSerialized = JSON.serialize(recordItem);
        Map<Id, ProductCategory> persistedRecordsById = ProductCategoryDAO.getByIds(new Set<Id>{ recordItem.Id });

        // Act
        Test.startTest();
        List<ProductCategory> savedRecords = ProductCategoryService.saveRecords(new List<ProductCategory>{ recordItem }, persistedRecordsById);
        Test.stopTest();

        // Assert
        System.assertEquals(beforeSerialized, JSON.serialize(savedRecords[0]), 'The service should leave an unchanged record untouched.');
    }

    @IsTest
    static void test_deleteRecords_validRecord_deletesRecord() {
        // Arrange
        ProductCategory recordItem = TestDataFactory.createProductCategory(true);

        // Act
        Test.startTest();
        ProductCategoryService.deleteRecords(new List<ProductCategory>{ recordItem });
        Test.stopTest();

        // Assert
        System.assertEquals(0, [SELECT Count() FROM ProductCategory WHERE Id = :recordItem.Id], 'The service should delete the provided record.');
    }
}
