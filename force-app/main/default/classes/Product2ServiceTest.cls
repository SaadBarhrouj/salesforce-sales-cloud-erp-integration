@IsTest
private class Product2ServiceTest {
    @TestSetup
    static void setup() {
        TestDataFactory.createProduct2(true);
    }

    @IsTest
    static void test_saveRecords_insert_validRecord_persistsRecord() {
        // Arrange
        Product2 recordItem = TestDataFactory.createProduct2(false);

        // Act
        Test.startTest();
        List<Product2> savedRecords = Product2Service.saveRecords(new List<Product2>{ recordItem }, new Map<Id, Product2>());
        Test.stopTest();

        // Assert
        System.assertEquals(true, savedRecords[0].Id != null, 'The service should insert a new record when valid data is provided.');
    }

    @IsTest
    static void test_saveRecords_update_changedRecord_updatesRecord() {
        // Arrange
        Product2 recordItem = [SELECT Id FROM Product2 LIMIT 1];
        recordItem = Product2DAO.getById(recordItem.Id);
        recordItem.Description = 'Updated product description';
        Object expectedValue = 'Updated product description';
        Map<Id, Product2> persistedRecordsById = Product2DAO.getByIds(new Set<Id>{ recordItem.Id });

        // Act
        Test.startTest();
        Product2Service.saveRecords(new List<Product2>{ recordItem }, persistedRecordsById);
        Test.stopTest();

        // Assert
        Product2 refreshedRecord = Product2DAO.getById(recordItem.Id);
        System.assertEquals(String.valueOf(expectedValue), String.valueOf(refreshedRecord.get('Description')), 'The service should persist the updated field value.');
    }

    @IsTest
    static void test_saveRecords_emptyList_throwsServiceException() {
        // Arrange
        List<Product2> emptyRecords = new List<Product2>();
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            Product2Service.saveRecords(emptyRecords, new Map<Id, Product2>());
            System.assertEquals('Expected exception', 'No exception', 'The service should throw when an empty list is provided.');
        } catch (Product2Service.ServiceException ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(String.format(System.Label.Generic_Service_Records_Required, new List<String>{ Product2.SObjectType.getDescribe().getLabel() }), actualMessage, 'The service should return the configured empty-list message.');
    }

    @IsTest
    static void test_saveRecords_missingRequiredField_throwsServiceException() {
        // Arrange
        Product2 recordItem = TestDataFactory.createProduct2(false);
        recordItem.Name = null;
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            Product2Service.saveRecords(new List<Product2>{ recordItem }, new Map<Id, Product2>());
            System.assertEquals('Expected exception', 'No exception', 'The service should throw when required data is missing.');
        } catch (Product2Service.ServiceException ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(true, actualMessage.contains(Product2.SObjectType.getDescribe().getLabel()), 'The service should mention the object label in the validation message.');
    }

    @IsTest
    static void test_saveRecords_unchangedRecord_skipsUpdate() {
        // Arrange
        Product2 recordItem = [SELECT Id FROM Product2 LIMIT 1];
        recordItem = Product2DAO.getById(recordItem.Id);
        String beforeSerialized = JSON.serialize(recordItem);
        Map<Id, Product2> persistedRecordsById = Product2DAO.getByIds(new Set<Id>{ recordItem.Id });

        // Act
        Test.startTest();
        List<Product2> savedRecords = Product2Service.saveRecords(new List<Product2>{ recordItem }, persistedRecordsById);
        Test.stopTest();

        // Assert
        System.assertEquals(beforeSerialized, JSON.serialize(savedRecords[0]), 'The service should leave an unchanged record untouched.');
    }

    @IsTest
    static void test_deleteRecords_validRecord_deletesRecord() {
        // Arrange
        Product2 recordItem = TestDataFactory.createProduct2(true);

        // Act
        Test.startTest();
        Product2Service.deleteRecords(new List<Product2>{ recordItem });
        Test.stopTest();

        // Assert
        System.assertEquals(0, [SELECT Count() FROM Product2 WHERE Id = :recordItem.Id], 'The service should delete the provided record.');
    }
}
