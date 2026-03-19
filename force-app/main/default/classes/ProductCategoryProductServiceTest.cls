@IsTest
private class ProductCategoryProductServiceTest {
    @TestSetup
    static void setup() {
        TestDataFactory.createProductCategoryProduct(true);
    }

    @IsTest
    static void test_saveRecords_insert_validRecord_persistsRecord() {
        // Arrange
        ProductCategoryProduct recordItem = TestDataFactory.createProductCategoryProduct(false);

        // Act
        Test.startTest();
        List<ProductCategoryProduct> savedRecords = ProductCategoryProductService.saveRecords(new List<ProductCategoryProduct>{ recordItem }, new Map<Id, ProductCategoryProduct>());
        Test.stopTest();

        // Assert
        System.assertEquals(true, savedRecords[0].Id != null, 'The service should insert a new record when valid data is provided.');
    }

    @IsTest
    static void test_saveRecords_update_changedRecord_updatesRecord() {
        // Arrange
        ProductCategoryProduct recordItem = [SELECT Id FROM ProductCategoryProduct LIMIT 1];
        recordItem = ProductCategoryProductDAO.getById(recordItem.Id);
        recordItem.IsPrimaryCategory = true;
        Object expectedValue = true;
        Map<Id, ProductCategoryProduct> persistedRecordsById = ProductCategoryProductDAO.getByIds(new Set<Id>{ recordItem.Id });

        // Act
        Test.startTest();
        ProductCategoryProductService.saveRecords(new List<ProductCategoryProduct>{ recordItem }, persistedRecordsById);
        Test.stopTest();

        // Assert
        ProductCategoryProduct refreshedRecord = ProductCategoryProductDAO.getById(recordItem.Id);
        System.assertEquals(String.valueOf(expectedValue), String.valueOf(refreshedRecord.get('IsPrimaryCategory')), 'The service should persist the updated field value.');
    }

    @IsTest
    static void test_saveRecords_emptyList_throwsServiceException() {
        // Arrange
        List<ProductCategoryProduct> emptyRecords = new List<ProductCategoryProduct>();
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            ProductCategoryProductService.saveRecords(emptyRecords, new Map<Id, ProductCategoryProduct>());
            System.assertEquals('Expected exception', 'No exception', 'The service should throw when an empty list is provided.');
        } catch (ProductCategoryProductService.ServiceException ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(String.format(System.Label.Generic_Service_Records_Required, new List<String>{ ProductCategoryProduct.SObjectType.getDescribe().getLabel() }), actualMessage, 'The service should return the configured empty-list message.');
    }

    @IsTest
    static void test_saveRecords_missingRequiredField_throwsServiceException() {
        // Arrange
        ProductCategoryProduct recordItem = TestDataFactory.createProductCategoryProduct(false);
        recordItem.ProductId = null;
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            ProductCategoryProductService.saveRecords(new List<ProductCategoryProduct>{ recordItem }, new Map<Id, ProductCategoryProduct>());
            System.assertEquals('Expected exception', 'No exception', 'The service should throw when required data is missing.');
        } catch (ProductCategoryProductService.ServiceException ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(true, actualMessage.contains(ProductCategoryProduct.SObjectType.getDescribe().getLabel()), 'The service should mention the object label in the validation message.');
    }

    @IsTest
    static void test_saveRecords_unchangedRecord_skipsUpdate() {
        // Arrange
        ProductCategoryProduct recordItem = [SELECT Id FROM ProductCategoryProduct LIMIT 1];
        recordItem = ProductCategoryProductDAO.getById(recordItem.Id);
        String beforeSerialized = JSON.serialize(recordItem);
        Map<Id, ProductCategoryProduct> persistedRecordsById = ProductCategoryProductDAO.getByIds(new Set<Id>{ recordItem.Id });

        // Act
        Test.startTest();
        List<ProductCategoryProduct> savedRecords = ProductCategoryProductService.saveRecords(new List<ProductCategoryProduct>{ recordItem }, persistedRecordsById);
        Test.stopTest();

        // Assert
        System.assertEquals(beforeSerialized, JSON.serialize(savedRecords[0]), 'The service should leave an unchanged record untouched.');
    }

    @IsTest
    static void test_deleteRecords_validRecord_deletesRecord() {
        // Arrange
        ProductCategoryProduct recordItem = TestDataFactory.createProductCategoryProduct(true);

        // Act
        Test.startTest();
        ProductCategoryProductService.deleteRecords(new List<ProductCategoryProduct>{ recordItem });
        Test.stopTest();

        // Assert
        System.assertEquals(0, [SELECT Count() FROM ProductCategoryProduct WHERE Id = :recordItem.Id], 'The service should delete the provided record.');
    }
}
