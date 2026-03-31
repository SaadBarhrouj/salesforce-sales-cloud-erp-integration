@IsTest
private class ProductCatalogControllerTest {
    @TestSetup
    static void setup() {
        User testUser = TestDataFactory.createUser(true);
        System.runAs(testUser) {
            TestDataFactory.createProductCatalog(true);
        }
    }

    @IsTest
    static void test_getAll_existingData_returnsRecords() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        List<ProductCatalog> loadedRecords = new List<ProductCatalog>();

        // Act
        System.runAs(testUser) {
            Test.startTest();
            loadedRecords = ProductCatalogController.getAll();
            Test.stopTest();
        }

        // Assert
        System.assertEquals(true, loadedRecords.size() > 0, 'The controller should return the records visible to the running user.');
    }

    @IsTest
    static void test_saveRecords_insert_validRecord_returnsSavedRecord() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        ProductCatalog recordItem = TestDataFactory.createProductCatalog(false);
        List<ProductCatalog> savedRecords = new List<ProductCatalog>();

        // Act
        System.runAs(testUser) {
            Test.startTest();
            savedRecords = ProductCatalogController.saveRecords(new List<ProductCatalog>{ recordItem });
            Test.stopTest();
        }

        // Assert
        System.assertEquals(true, savedRecords[0].Id != null, 'The controller should return the saved record with an Id.');
    }

    @IsTest
    static void test_saveRecords_update_changedRecord_returnsUpdatedRecord() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        ProductCatalog recordItem = [SELECT Id FROM ProductCatalog LIMIT 1];
        recordItem = ProductCatalogDAO.getById(recordItem.Id);
        recordItem.Name = 'Updated Catalog';
        List<ProductCatalog> savedRecords = new List<ProductCatalog>();

        // Act
        System.runAs(testUser) {
            Test.startTest();
            savedRecords = ProductCatalogController.saveRecords(new List<ProductCatalog>{ recordItem });
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
                ProductCatalogController.saveRecords(new List<ProductCatalog>());
                System.assertEquals('Expected exception', 'No exception', 'The controller should throw when the request is invalid.');
            } catch (AuraHandledException ex) {
                actualMessage = ex.getMessage();
            }
            Test.stopTest();
        }

        // Assert
        System.assertEquals(String.format(System.Label.Generic_Controller_Request_Failed, new List<String>{ ProductCatalog.SObjectType.getDescribe().getLabel() }), actualMessage, 'The controller should expose the configured AuraHandledException message.');
    }

    @IsTest
    static void test_deleteRecords_existingRecord_returnsTrue() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        ProductCatalog recordItem;
        System.runAs(testUser) {
            recordItem = TestDataFactory.createProductCatalog(true);
        }
        Boolean wasDeleted = false;

        // Act
        System.runAs(testUser) {
            Test.startTest();
            wasDeleted = ProductCatalogController.deleteRecords(new List<Id>{ recordItem.Id });
            Test.stopTest();
        }

        // Assert
        System.assertEquals(true, wasDeleted, 'The controller should confirm successful deletion.');
    }
}
