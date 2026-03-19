@IsTest
private class ProductRuleServiceTest {
    @TestSetup
    static void setup() {
        TestDataFactory.createProductRule(true);
    }

    @IsTest
    static void test_saveRecords_insert_validRecord_persistsRecord() {
        // Arrange
        Product_Rule__c recordItem = TestDataFactory.createProductRule(false);

        // Act
        Test.startTest();
        List<Product_Rule__c> savedRecords = ProductRuleService.saveRecords(new List<Product_Rule__c>{ recordItem }, new Map<Id, Product_Rule__c>());
        Test.stopTest();

        // Assert
        System.assertEquals(true, savedRecords[0].Id != null, 'The service should insert a new record when valid data is provided.');
    }

    @IsTest
    static void test_saveRecords_update_changedRecord_updatesRecord() {
        // Arrange
        Product_Rule__c recordItem = [SELECT Id FROM Product_Rule__c LIMIT 1];
        recordItem = ProductRuleDAO.getById(recordItem.Id);
        recordItem.Message__c = 'Updated rule message';
        Object expectedValue = 'Updated rule message';
        Map<Id, Product_Rule__c> persistedRecordsById = ProductRuleDAO.getByIds(new Set<Id>{ recordItem.Id });

        // Act
        Test.startTest();
        ProductRuleService.saveRecords(new List<Product_Rule__c>{ recordItem }, persistedRecordsById);
        Test.stopTest();

        // Assert
        Product_Rule__c refreshedRecord = ProductRuleDAO.getById(recordItem.Id);
        System.assertEquals(String.valueOf(expectedValue), String.valueOf(refreshedRecord.get('Message__c')), 'The service should persist the updated field value.');
    }

    @IsTest
    static void test_saveRecords_emptyList_throwsServiceException() {
        // Arrange
        List<Product_Rule__c> emptyRecords = new List<Product_Rule__c>();
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            ProductRuleService.saveRecords(emptyRecords, new Map<Id, Product_Rule__c>());
            System.assertEquals('Expected exception', 'No exception', 'The service should throw when an empty list is provided.');
        } catch (ProductRuleService.ServiceException ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(String.format(System.Label.Generic_Service_Records_Required, new List<String>{ Product_Rule__c.SObjectType.getDescribe().getLabel() }), actualMessage, 'The service should return the configured empty-list message.');
    }

    @IsTest
    static void test_saveRecords_missingRequiredField_throwsServiceException() {
        // Arrange
        Product_Rule__c recordItem = TestDataFactory.createProductRule(false);
        recordItem.Type__c = null;
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            ProductRuleService.saveRecords(new List<Product_Rule__c>{ recordItem }, new Map<Id, Product_Rule__c>());
            System.assertEquals('Expected exception', 'No exception', 'The service should throw when required data is missing.');
        } catch (ProductRuleService.ServiceException ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(true, actualMessage.contains(Product_Rule__c.SObjectType.getDescribe().getLabel()), 'The service should mention the object label in the validation message.');
    }

    @IsTest
    static void test_saveRecords_unchangedRecord_skipsUpdate() {
        // Arrange
        Product_Rule__c recordItem = [SELECT Id FROM Product_Rule__c LIMIT 1];
        recordItem = ProductRuleDAO.getById(recordItem.Id);
        String beforeSerialized = JSON.serialize(recordItem);
        Map<Id, Product_Rule__c> persistedRecordsById = ProductRuleDAO.getByIds(new Set<Id>{ recordItem.Id });

        // Act
        Test.startTest();
        List<Product_Rule__c> savedRecords = ProductRuleService.saveRecords(new List<Product_Rule__c>{ recordItem }, persistedRecordsById);
        Test.stopTest();

        // Assert
        System.assertEquals(beforeSerialized, JSON.serialize(savedRecords[0]), 'The service should leave an unchanged record untouched.');
    }

    @IsTest
    static void test_deleteRecords_validRecord_deletesRecord() {
        // Arrange
        Product_Rule__c recordItem = TestDataFactory.createProductRule(true);

        // Act
        Test.startTest();
        ProductRuleService.deleteRecords(new List<Product_Rule__c>{ recordItem });
        Test.stopTest();

        // Assert
        System.assertEquals(0, [SELECT Count() FROM Product_Rule__c WHERE Id = :recordItem.Id], 'The service should delete the provided record.');
    }
}
