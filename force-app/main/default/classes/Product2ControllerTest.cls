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
        Boolean exceptionThrown = false;

        // Act
        System.runAs(testUser) {
            Test.startTest();
            try {
                Product2Controller.saveRecords(new List<Product2>());
            } catch (Exception ex) {
                exceptionThrown = true;
            }
            Test.stopTest();
        }

        // Assert
        System.assertEquals(true, exceptionThrown, 'The controller should throw an exception when the request is invalid.');
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

    @IsTest
    static void testGetByIdValidIdReturnsRecord() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        Product2 existingRecord = [SELECT Id FROM Product2 LIMIT 1];
        Product2 result = null;

        // Act
        System.runAs(testUser) {
            Test.startTest();
            result = Product2Controller.getById(existingRecord.Id);
            Test.stopTest();
        }

        // Assert
        System.assertEquals(existingRecord.Id, result.Id, 'The controller should return the requested record.');
    }

    @IsTest
    static void testGetByIdNullIdReturnsNull() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        Product2 result = null;

        // Act
        System.runAs(testUser) {
            Test.startTest();
            result = Product2Controller.getById(null);
            Test.stopTest();
        }

        // Assert
        System.assertEquals(null, result, 'The controller should return null for null ID.');
    }

    @IsTest
    static void testGetByIdsValidIdsReturnsRecords() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        Product2 existingRecord = [SELECT Id FROM Product2 LIMIT 1];
        List<Product2> result = new List<Product2>();

        // Act
        System.runAs(testUser) {
            Test.startTest();
            result = Product2Controller.getByIds(new List<Id>{ existingRecord.Id });
            Test.stopTest();
        }

        // Assert
        System.assertEquals(1, result.size(), 'The controller should return the requested records.');
    }

    @IsTest
    static void testGetByIdsNullListReturnsEmptyList() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        List<Product2> result = new List<Product2>();

        // Act
        System.runAs(testUser) {
            Test.startTest();
            result = Product2Controller.getByIds(null);
            Test.stopTest();
        }

        // Assert
        System.assertEquals(0, result.size(), 'The controller should return an empty list for null IDs.');
    }

    @IsTest
    static void testGetByIdsEmptyListReturnsEmptyList() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        List<Product2> result = new List<Product2>();

        // Act
        System.runAs(testUser) {
            Test.startTest();
            result = Product2Controller.getByIds(new List<Id>());
            Test.stopTest();
        }

        // Assert
        System.assertEquals(0, result.size(), 'The controller should return an empty list for empty IDs.');
    }

    @IsTest
    static void testGetAllByCategoryNullCategoryReturnsAllProducts() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        List<Product2> result = new List<Product2>();

        // Act
        System.runAs(testUser) {
            Test.startTest();
            result = Product2Controller.getAllByCategory(null);
            Test.stopTest();
        }

        // Assert
        System.assertEquals(true, result.size() >= 1, 'The controller should return all products for null category.');
    }

    @IsTest
    static void testGetAllByCategoryEmptyCategoryReturnsAllProducts() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        List<Product2> result = new List<Product2>();

        // Act
        System.runAs(testUser) {
            Test.startTest();
            result = Product2Controller.getAllByCategory('');
            Test.stopTest();
        }

        // Assert
        System.assertEquals(true, result.size() >= 1, 'The controller should return all products for empty category.');
    }

    @IsTest
    static void testGetAllByCategoryBlankCategoryReturnsAllProducts() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        List<Product2> result = new List<Product2>();

        // Act
        System.runAs(testUser) {
            Test.startTest();
            result = Product2Controller.getAllByCategory('   ');
            Test.stopTest();
        }

        // Assert
        System.assertEquals(true, result.size() >= 1, 'The controller should return all products for blank category.');
    }

    @IsTest
    static void testDeleteRecordsNullListThrowsAuraHandledException() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        Boolean exceptionThrown = false;

        // Act
        System.runAs(testUser) {
            Test.startTest();
            try {
                Product2Controller.deleteRecords(null);
            } catch (Exception ex) {
                exceptionThrown = true;
            }
            Test.stopTest();
        }

        // Assert
        System.assertEquals(true, exceptionThrown, 'The controller should throw for null ID list.');
    }

    @IsTest
    static void testDeleteRecordsEmptyListThrowsAuraHandledException() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        Boolean exceptionThrown = false;

        // Act
        System.runAs(testUser) {
            Test.startTest();
            try {
                Product2Controller.deleteRecords(new List<Id>());
            } catch (Exception ex) {
                exceptionThrown = true;
            }
            Test.stopTest();
        }

        // Assert
        System.assertEquals(true, exceptionThrown, 'The controller should throw for empty ID list.');
    }

    @IsTest
    static void testSaveRecordsNullListThrowsAuraHandledException() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        Boolean exceptionThrown = false;

        // Act
        System.runAs(testUser) {
            Test.startTest();
            try {
                Product2Controller.saveRecords(null);
            } catch (Exception ex) {
                exceptionThrown = true;
            }
            Test.stopTest();
        }

        // Assert
        System.assertEquals(true, exceptionThrown, 'The controller should throw for null records list.');
    }

    @IsTest
    static void testSaveRecordsMissingNameThrowsAuraHandledException() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        Product2 recordItem = TestDataFactory.createProduct2(false);
        recordItem.Name = null;
        Boolean exceptionThrown = false;

        // Act
        System.runAs(testUser) {
            Test.startTest();
            try {
                Product2Controller.saveRecords(new List<Product2>{ recordItem });
            } catch (Exception ex) {
                exceptionThrown = true;
            }
            Test.stopTest();
        }

        // Assert
        System.assertEquals(true, exceptionThrown, 'The controller should throw for missing required fields.');
    }

    @IsTest
    static void testGetAllByCategoryInvalidIdThrowsAuraHandledException() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        Boolean exceptionThrown = false;

        // Act
        System.runAs(testUser) {
            Test.startTest();
            try {
                Product2Controller.getAllByCategory('not-a-valid-salesforce-id');
            } catch (Exception ex) {
                exceptionThrown = true;
            }
            Test.stopTest();
        }

        // Assert
        System.assertEquals(true, exceptionThrown, 'The controller should throw for invalid category ID.');
    }

    @IsTest
    static void testSaveRecordsUpdateNonExistentRecordThrowsAuraHandledException() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        Product2 nonExistentRecord = new Product2(
            Id = Product2.SObjectType.getDescribe().getKeyPrefix() + '000000000000',
            Name = 'NonExistentProduct'
        );
        Boolean exceptionThrown = false;

        // Act
        System.runAs(testUser) {
            Test.startTest();
            try {
                Product2Controller.saveRecords(new List<Product2>{ nonExistentRecord });
            } catch (Exception ex) {
                exceptionThrown = true;
                System.assert(ex.getMessage().contains('Product'), 'Exception message should mention Product');
            }
            Test.stopTest();
        }

        // Assert
        System.assertEquals(true, exceptionThrown, 'The controller should throw an exception when updating a non-existent record.');
    }

    @IsTest
    static void testDeleteRecordsNonExistentRecordThrowsAuraHandledException() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        Id nonExistentId = Product2.SObjectType.getDescribe().getKeyPrefix() + '000000000001';
        Boolean exceptionThrown = false;

        // Act
        System.runAs(testUser) {
            Test.startTest();
            try {
                Product2Controller.deleteRecords(new List<Id>{ nonExistentId });
            } catch (Exception ex) {
                exceptionThrown = true;
                System.assert(ex.getMessage().contains('Product'), 'Exception message should mention Product');
            }
            Test.stopTest();
        }

        // Assert
        System.assertEquals(true, exceptionThrown, 'The controller should throw an exception when deleting a non-existent record.');
    }
}
