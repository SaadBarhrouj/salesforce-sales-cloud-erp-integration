@IsTest
private class ProductCategoryProductControllerTest {
    @TestSetup
    static void setup() {
        User testUser = TestDataFactory.createUser(true);
        System.runAs(testUser) {
            TestDataFactory.createProductCategoryProduct(true);
        }
    }

    @IsTest
    static void test_getAll_existingData_returnsRecords() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        List<ProductCategoryProduct> loadedRecords = new List<ProductCategoryProduct>();

        // Act
        System.runAs(testUser) {
            Test.startTest();
            loadedRecords = ProductCategoryProductController.getAll();
            Test.stopTest();
        }

        // Assert
        System.assertEquals(true, loadedRecords.size() > 0, 'The controller should return the records visible to the running user.');
    }

    @IsTest
    static void test_saveRecords_insert_validRecord_returnsSavedRecord() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        ProductCategoryProduct recordItem = TestDataFactory.createProductCategoryProduct(false);
        List<ProductCategoryProduct> savedRecords = new List<ProductCategoryProduct>();

        // Act
        System.runAs(testUser) {
            Test.startTest();
            savedRecords = ProductCategoryProductController.saveRecords(new List<ProductCategoryProduct>{ recordItem });
            Test.stopTest();
        }

        // Assert
        System.assertEquals(true, savedRecords[0].Id != null, 'The controller should return the saved record with an Id.');
    }

    @IsTest
    static void test_saveRecords_update_changedRecord_returnsUpdatedRecord() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        ProductCategoryProduct recordItem = [SELECT Id FROM ProductCategoryProduct LIMIT 1];
        recordItem = ProductCategoryProductDAO.getById(recordItem.Id);
        recordItem.IsPrimaryCategory = true;
        List<ProductCategoryProduct> savedRecords = new List<ProductCategoryProduct>();

        // Act
        System.runAs(testUser) {
            Test.startTest();
            savedRecords = ProductCategoryProductController.saveRecords(new List<ProductCategoryProduct>{ recordItem });
            Test.stopTest();
        }

        // Assert
        System.assertEquals(recordItem.Id, savedRecords[0].Id, 'The controller should return the updated record.');
    }

    @IsTest
    static void test_saveRecords_emptyList_throwsAuraHandledException() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        String actualMessage = '';

        // Act
        System.runAs(testUser) {
            Test.startTest();
            try {
                ProductCategoryProductController.saveRecords(new List<ProductCategoryProduct>());
                System.assertEquals('Expected exception', 'No exception', 'The controller should throw when the request is invalid.');
            } catch (AuraHandledException ex) {
                actualMessage = ex.getMessage();
            }
            Test.stopTest();
        }

        // Assert
        System.assertEquals(String.format(System.Label.Generic_Controller_Request_Failed, new List<String>{ ProductCategoryProduct.SObjectType.getDescribe().getLabel() }), actualMessage, 'The controller should expose the configured AuraHandledException message.');
    }

    @IsTest
    static void test_deleteRecords_existingRecord_returnsTrue() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        ProductCategoryProduct recordItem;
        System.runAs(testUser) {
            recordItem = TestDataFactory.createProductCategoryProduct(true);
        }
        Boolean wasDeleted = false;

        // Act
        System.runAs(testUser) {
            Test.startTest();
            wasDeleted = ProductCategoryProductController.deleteRecords(new List<Id>{ recordItem.Id });
            Test.stopTest();
        }

        // Assert
        System.assertEquals(true, wasDeleted, 'The controller should confirm successful deletion.');
    }
}
