@IsTest
private class Product2ControllerTest {
    @TestSetup
    static void setup() {
        User testUser = TestDataFactory.createUser(true);
        System.runAs(testUser) {
            TestDataFactory.createProduct2(true);
        }
    }

    @IsTest
    static void testGetAllExistingDataReturnsRecords() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        List<Product2> loadedRecords = new List<Product2>();

        // Act
        System.runAs(testUser) {
            Test.startTest();
            loadedRecords = Product2Controller.getAll();
            Test.stopTest();
        }

        // Assert
        System.assertEquals(true, loadedRecords.size() > 0, 'The controller should return the records visible to the running user.');
    }

    @IsTest
    static void testSaveRecordsInsertValidRecordReturnsSavedRecord() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        Product2 recordItem = TestDataFactory.createProduct2(false);
        List<Product2> savedRecords = new List<Product2>();

        // Act
        System.runAs(testUser) {
            Test.startTest();
            savedRecords = Product2Controller.saveRecords(new List<Product2>{ recordItem });
            Test.stopTest();
        }

        // Assert
        System.assertEquals(true, savedRecords[0].Id != null, 'The controller should return the saved record with an Id.');
    }

    @IsTest
    static void testSaveRecordsUpdateChangedRecordReturnsUpdatedRecord() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        Product2 recordItem = [SELECT Id FROM Product2 LIMIT 1];
        recordItem = Product2DAO.getById(recordItem.Id);
        recordItem.Description = 'Updated product description';
        List<Product2> savedRecords = new List<Product2>();

        // Act
        System.runAs(testUser) {
            Test.startTest();
            savedRecords = Product2Controller.saveRecords(new List<Product2>{ recordItem });
            Test.stopTest();
        }

        // Assert
        System.assertEquals(recordItem.Id, savedRecords[0].Id, 'The controller should return the updated record.');
    }

    @IsTest
    static void testSaveRecordsEmptyListThrowsAuraHandledException() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        String actualMessage = '';
        Boolean exceptionThrown = false;

        // Act
        System.runAs(testUser) {
            Test.startTest();
            try {
                Product2Controller.saveRecords(new List<Product2>());
            } catch (AuraHandledException ex) {
                actualMessage = ex.getMessage();
                exceptionThrown = true;
            }
            Test.stopTest();
        }

        // Assert
        System.assertEquals(true, exceptionThrown, 'The controller should throw an AuraHandledException when the request is invalid.');
        System.assertEquals(true, String.isNotBlank(actualMessage), 'The exception message should not be empty.');
    }

    @IsTest
    static void testDeleteRecordsExistingRecordReturnsTrue() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        Product2 recordItem;
        System.runAs(testUser) {
            recordItem = TestDataFactory.createProduct2(true);
        }
        Boolean wasDeleted = false;

        // Act
        System.runAs(testUser) {
            Test.startTest();
            wasDeleted = Product2Controller.deleteRecords(new List<Id>{ recordItem.Id });
            Test.stopTest();
        }

        // Assert
        System.assertEquals(true, wasDeleted, 'The controller should confirm successful deletion.');
    }
}
