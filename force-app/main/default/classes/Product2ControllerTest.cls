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
    static void testGetByIdNullIdThrowsAuraHandledException() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        Boolean exceptionThrown = false;

        // Act
        System.runAs(testUser) {
            Test.startTest();
            try {
                Product2Controller.getById(null);
            } catch (AuraHandledException e) {
                exceptionThrown = true;
            }
            Test.stopTest();
        }

        // Assert
        System.assertEquals(true, exceptionThrown, 'Should throw exception when ID is null.');
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
    static void testGetByIdsNullListThrowsAuraHandledException() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        Boolean exceptionThrown = false;

        // Act
        System.runAs(testUser) {
            Test.startTest();
            try {
                Product2Controller.getByIds(null);
            } catch (AuraHandledException e) {
                exceptionThrown = true;
            }
            Test.stopTest();
        }

        // Assert
        System.assertEquals(true, exceptionThrown, 'Should throw exception when list is null.');
    }

    @IsTest
    static void testGetByIdsEmptyListThrowsAuraHandledException() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        Boolean exceptionThrown = false;

        // Act
        System.runAs(testUser) {
            Test.startTest();
            try {
                Product2Controller.getByIds(new List<Id>());
            } catch (AuraHandledException e) {
                exceptionThrown = true;
            }
            Test.stopTest();
        }

        // Assert
        System.assertEquals(true, exceptionThrown, 'The controller should throw for empty ID list.');
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
            } catch (AuraHandledException e) {
                exceptionThrown = true;
            }
            Test.stopTest();
        }

        // Assert
        System.assertEquals(true, exceptionThrown, 'Should throw exception when list is null.');
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
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];
        Boolean exceptionThrown = false;

        // Act
        System.runAs(testUser) {
            Test.startTest();
            try {
                Product2Controller.getAllByCategory(testProduct.Id);
            } catch (AuraHandledException e) {
                exceptionThrown = true;
            }
            Test.stopTest();
        }

        // Assert
        System.assertEquals(true, exceptionThrown, 'The controller should throw for invalid category ID type.');
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
            }
            Test.stopTest();
        }

        // Assert
        System.assertEquals(true, exceptionThrown, 'The controller should throw an exception when deleting a non-existent record.');
    }

    @IsTest
    static void testSaveRecordsMissingRequiredFieldShowsValidationMessage() {
        // Arrange
        User testUser = TestDataFactory.createUser(true);
        Product2 invalidRecord = new Product2();
        Boolean exceptionThrown = false;

        // Act
        System.runAs(testUser) {
            Test.startTest();
            try {
                Product2Controller.saveRecords(new List<Product2>{ invalidRecord });
            } catch (AuraHandledException e) {
                exceptionThrown = true;
            }
            Test.stopTest();
        }

        // Assert
        System.assertEquals(true, exceptionThrown, 'Should throw AuraHandledException');
    }

    @IsTest
    static void testGetByIdNonExistentRecordReturnsNull() {
        // Arrange
        User testUser = TestDataFactory.createUser(true);
        Id fakeId = Product2.SObjectType.getDescribe().getKeyPrefix() + '000000000000';
        Product2 result = null;

        // Act
        System.runAs(testUser) {
            Test.startTest();
            result = Product2Controller.getById(fakeId);
            Test.stopTest();
        }

        // Assert
        System.assertEquals(null, result, 'Should return null for non-existent record');
    }

    @IsTest
    static void testGetAllByPricebookNullReturnsAllProducts() {
        // Arrange
        User testUser = TestDataFactory.createUser(true);
        List<Product2> result = new List<Product2>();

        // Act
        System.runAs(testUser) {
            Test.startTest();
            result = Product2Controller.getAllByPricebook(null);
            Test.stopTest();
        }

        // Assert
        System.assertEquals(true, result.size() >= 1, 'Should return all products when pricebook is null.');
    }

    @IsTest
    static void testGetAllByPricebookBlankReturnsAllProducts() {
        // Arrange
        User testUser = TestDataFactory.createUser(true);
        List<Product2> result = new List<Product2>();

        // Act
        System.runAs(testUser) {
            Test.startTest();
            result = Product2Controller.getAllByPricebook('');
            Test.stopTest();
        }

        // Assert
        System.assertEquals(true, result.size() >= 1, 'Should return all products when pricebook is blank.');
    }

    @IsTest
    static void testGetAllByPricebookValidPricebookReturnsFilteredProducts() {
        // Arrange
        User testUser = TestDataFactory.createUser(true);
        Id standardPricebookId;
        Product2 product1;
        System.runAs(testUser) {
            product1 = TestDataFactory.createProduct2(true);
            standardPricebookId = Test.getStandardPricebookId();
            TestDataFactory.createPricebookEntry(standardPricebookId, product1.Id, 50.00, true, true);
        }
        List<Product2> result = new List<Product2>();

        // Act
        System.runAs(testUser) {
            Test.startTest();
            result = Product2Controller.getAllByPricebook(standardPricebookId);
            Test.stopTest();
        }

        // Assert
        System.assertEquals(1, result.size(), 'Should return only products in the specified pricebook.');
        System.assertEquals(product1.Id, result[0].Id, 'Returned product should match the one in the pricebook.');
    }

    @IsTest
    static void testGetProductsByCategoryAndPricebookNullPricebookAndCatalogReturnsEmpty() {
        // Arrange
        User testUser = TestDataFactory.createUser(true);
        List<Product2> result = new List<Product2>();

        // Act
        System.runAs(testUser) {
            Test.startTest();
            result = Product2Controller.getProductsByCategoryAndPricebook(null, null, null);
            Test.stopTest();
        }

        // Assert
        System.assertEquals(0, result.size(), 'Missing Pricebook/Catalog must produce an empty list.');
    }

    @IsTest
    static void testGetProductsByCategoryAndPricebookBlankPricebookAndCatalogReturnsEmpty() {
        // Arrange
        User testUser = TestDataFactory.createUser(true);
        List<Product2> result = new List<Product2>();

        // Act
        System.runAs(testUser) {
            Test.startTest();
            result = Product2Controller.getProductsByCategoryAndPricebook('', '   ', '   ');
            Test.stopTest();
        }

        // Assert
        System.assertEquals(0, result.size(), 'Blank Pricebook/Catalog must produce an empty list.');
    }

    @IsTest
    static void testGetProductsByCategoryAndPricebookValidCategoryAndPricebookReturnsProducts() {
        // Arrange
        User testUser = TestDataFactory.createUser(true);
        Product2 product1;
        ProductCategory category;
        ProductCatalog catalog;
        Id standardPricebookId;
        System.runAs(testUser) {
            product1 = TestDataFactory.createProduct2(true);
            catalog = TestDataFactory.createProductCatalog('Test Catalog', true);
            category = TestDataFactory.createProductCategory(catalog.Id, null, 'Test Cat', true, true);
            TestDataFactory.createProductCategoryProduct(category.Id, product1.Id, true);
            standardPricebookId = Test.getStandardPricebookId();
            TestDataFactory.createPricebookEntry(standardPricebookId, product1.Id, 50.00, true, true);
        }
        List<Product2> result = new List<Product2>();

        // Act
        System.runAs(testUser) {
            Test.startTest();
            result = Product2Controller.getProductsByCategoryAndPricebook(category.Id, standardPricebookId, catalog.Id);
            Test.stopTest();
        }

        // Assert
        System.assertEquals(true, result.size() >= 1, 'Should return products in both category and pricebook.');
        Boolean foundProduct = false;
        for (Product2 p : result) {
            if (p.Id == product1.Id) {
                foundProduct = true;
                break;
            }
        }
        System.assertEquals(true, foundProduct, 'Result should include the product linked to both category and pricebook.');
    }

}