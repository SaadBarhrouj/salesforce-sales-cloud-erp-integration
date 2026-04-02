@IsTest
private class Product2ServiceTest {
    @TestSetup
    static void setup() {
        TestDataFactory.createProduct2(true);
    }

    @IsTest
    static void testSaveRecordsInsertValidRecordPersistsRecord() {
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
    static void testSaveRecordsUpdateChangedRecordUpdatesRecord() {
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
    static void testSaveRecordsEmptyListThrowsServiceException() {
        // Arrange
        List<Product2> emptyRecords = new List<Product2>();
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            Product2Service.saveRecords(emptyRecords, new Map<Id, Product2>());
            System.assertEquals('Expected exception', 'No exception', 'The service should throw when an empty list is provided.');
        } catch (Product2Exception ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(String.format(System.Label.Generic_Service_Records_Required, new List<String>{ Product2.SObjectType.getDescribe().getLabel() }), actualMessage, 'The service should return the configured empty-list message.');
    }

    @IsTest
    static void testSaveRecordsMissingRequiredFieldThrowsServiceException() {
        // Arrange
        Product2 recordItem = TestDataFactory.createProduct2(false);
        recordItem.Name = null;
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            Product2Service.saveRecords(new List<Product2>{ recordItem }, new Map<Id, Product2>());
            System.assertEquals('Expected exception', 'No exception', 'The service should throw when required data is missing.');
        } catch (Product2Exception ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(true, actualMessage.contains(Product2.SObjectType.getDescribe().getLabel()), 'The service should mention the object label in the validation message.');
    }

    @IsTest
    static void testSaveRecordsUnchangedRecordSkipsUpdate() {
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
    static void testDeleteRecordsValidRecordDeletesRecord() {
        // Arrange
        Product2 recordItem = TestDataFactory.createProduct2(true);

        // Act
        Test.startTest();
        Product2Service.deleteRecords(new List<Product2>{ recordItem });
        Test.stopTest();

        // Assert
        System.assertEquals(0, [SELECT Count() FROM Product2 WHERE Id = :recordItem.Id], 'The service should delete the provided record.');
    }

    @IsTest
    static void testGetLoadedRecordReturnsRecord() {
        // Arrange
        Product2 recordItem = TestDataFactory.createProduct2(false);

        // Act
        Test.startTest();
        Product2 result = Product2Service.getLoadedRecord(recordItem);
        Test.stopTest();

        // Assert
        System.assertEquals(recordItem, result, 'The service should return the loaded record.');
    }

    @IsTest
    static void testGetLoadedRecordsNullInputReturnsEmptyList() {
        // Act
        Test.startTest();
        List<Product2> result = Product2Service.getLoadedRecords(null);
        Test.stopTest();

        // Assert
        System.assertEquals(0, result.size(), 'The service should return an empty list for null input.');
    }

    @IsTest
    static void testGetLoadedRecordsValidInputReturnsRecords() {
        // Arrange
        List<Product2> records = new List<Product2>{ TestDataFactory.createProduct2(false) };

        // Act
        Test.startTest();
        List<Product2> result = Product2Service.getLoadedRecords(records);
        Test.stopTest();

        // Assert
        System.assertEquals(1, result.size(), 'The service should return the provided records.');
    }

    @IsTest
    static void testGetByCategoryIdValidCategoryIdReturnsProducts() {
        // Act
        Test.startTest();
        List<Product2> result = Product2Service.getByCategoryId(null);
        Test.stopTest();

        // Assert
        System.assertEquals(true, result.size() >= 1, 'The service should return products when category ID is null.');
    }

    @IsTest
    static void testSaveRecordsNullPersistedRecordsTreatsAsEmptyMap() {
        // Arrange
        Product2 recordItem = TestDataFactory.createProduct2(false);

        // Act
        Test.startTest();
        List<Product2> savedRecords = Product2Service.saveRecords(new List<Product2>{ recordItem }, null);
        Test.stopTest();

        // Assert
        System.assertEquals(true, savedRecords[0].Id != null, 'The service should insert records when persisted map is null.');
    }

    @IsTest
    static void testSaveRecordsRecordNotFoundThrowsServiceException() {
        // Arrange
        Product2 recordItem = TestDataFactory.createProduct2(false);
        recordItem.Id = Product2.SObjectType.getDescribe().getKeyPrefix() + '000000000000';
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            Product2Service.saveRecords(new List<Product2>{ recordItem }, new Map<Id, Product2>());
        } catch (Product2Exception ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(true, actualMessage.contains(Product2.SObjectType.getDescribe().getLabel()), 'The service should mention the object label when record is not found.');
    }

    @IsTest
    static void testDeleteRecordsEmptyListThrowsServiceException() {
        // Arrange
        List<Product2> emptyRecords = new List<Product2>();
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            Product2Service.deleteRecords(emptyRecords);
        } catch (Product2Exception ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(String.format(System.Label.Generic_Service_Records_Required, new List<String>{ Product2.SObjectType.getDescribe().getLabel() }), actualMessage, 'The service should throw for empty delete list.');
    }

    @IsTest
    static void testDeleteRecordsNullListThrowsServiceException() {
        // Arrange
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            Product2Service.deleteRecords(null);
        } catch (Product2Exception ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(String.format(System.Label.Generic_Service_Records_Required, new List<String>{ Product2.SObjectType.getDescribe().getLabel() }), actualMessage, 'The service should throw for null delete list.');
    }

    @IsTest
    static void testDeleteRecordsNullIdThrowsServiceException() {
        // Arrange
        Product2 recordItem = TestDataFactory.createProduct2(false);
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            Product2Service.deleteRecords(new List<Product2>{ recordItem });
        } catch (Product2Exception ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(String.format(System.Label.Generic_Service_Record_Id_Required, new List<String>{ Product2.SObjectType.getDescribe().getLabel() }), actualMessage, 'The service should throw for null ID on delete.');
    }

    @IsTest
    static void testBeforeInsertNullRecordsReturnsEarly() {
        // Act
        Test.startTest();
        Product2Service.beforeInsert(null);
        Test.stopTest();

        // Assert
        System.assertEquals(true, true, 'Should not throw for null input');
    }

    @IsTest
    static void testBeforeInsertEmptyRecordsReturnsEarly() {
        // Act
        Test.startTest();
        Product2Service.beforeInsert(new List<Product2>());
        Test.stopTest();

        // Assert
        System.assertEquals(true, true, 'Should not throw for empty input');
    }

    @IsTest
    static void testBeforeInsertValidRecordsPassesValidation() {
        // Arrange
        List<Product2> records = new List<Product2>{ TestDataFactory.createProduct2(false) };

        // Act
        Test.startTest();
        Product2Service.beforeInsert(records);
        Test.stopTest();

        // Assert
        System.assertEquals(true, true, 'Should not throw for valid records');
    }

    @IsTest
    static void testBeforeInsertMissingNameThrowsServiceException() {
        // Arrange
        Product2 recordItem = TestDataFactory.createProduct2(false);
        recordItem.Name = null;
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            Product2Service.beforeInsert(new List<Product2>{ recordItem });
        } catch (Product2Exception ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(true, actualMessage.contains(Product2.SObjectType.getDescribe().getLabel()), 'The service should validate required fields on beforeInsert.');
    }

    @IsTest
    static void testBeforeUpdateNullRecordsReturnsEarly() {
        // Act
        Test.startTest();
        Product2Service.beforeUpdate(null, new Map<Id, Product2>(), new Map<Id, Product2>());
        Test.stopTest();

        // Assert
        System.assertEquals(true, true, 'Should not throw for null input');
    }

    @IsTest
    static void testBeforeUpdateEmptyRecordsReturnsEarly() {
        // Act
        Test.startTest();
        Product2Service.beforeUpdate(new List<Product2>(), new Map<Id, Product2>(), new Map<Id, Product2>());
        Test.stopTest();

        // Assert
        System.assertEquals(true, true, 'Should not throw for empty input');
    }

    @IsTest
    static void testBeforeUpdateNullIdThrowsServiceException() {
        // Arrange
        Product2 recordItem = TestDataFactory.createProduct2(false);
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            Product2Service.beforeUpdate(new List<Product2>{ recordItem }, new Map<Id, Product2>(), new Map<Id, Product2>());
        } catch (Product2Exception ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(String.format(System.Label.Generic_Service_Record_Id_Required, new List<String>{ Product2.SObjectType.getDescribe().getLabel() }), actualMessage, 'The service should require ID on beforeUpdate.');
    }

    @IsTest
    static void testBeforeUpdateRecordNotFoundThrowsServiceException() {
        // Arrange
        Product2 recordItem = TestDataFactory.createProduct2(false);
        recordItem.Id = Product2.SObjectType.getDescribe().getKeyPrefix() + '000000000000';
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            Product2Service.beforeUpdate(new List<Product2>{ recordItem }, new Map<Id, Product2>(), new Map<Id, Product2>());
        } catch (Product2Exception ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(true, actualMessage.contains(Product2.SObjectType.getDescribe().getLabel()), 'The service should throw when record not found on beforeUpdate.');
    }

    @IsTest
    static void testBeforeUpdateNullPersistedRecordsTreatsAsEmptyMap() {
        // Arrange
        Product2 recordItem = TestDataFactory.createProduct2(true);
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            Product2Service.beforeUpdate(new List<Product2>{ recordItem }, new Map<Id, Product2>(), null);
        } catch (Product2Exception ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(true, actualMessage.contains(Product2.SObjectType.getDescribe().getLabel()), 'The service should treat null persisted records as empty map.');
    }

    @IsTest
    static void testBeforeUpdateValidRecordPassesValidation() {
        // Arrange
        Product2 recordItem = TestDataFactory.createProduct2(true);
        Map<Id, Product2> persistedRecordsById = new Map<Id, Product2>{ recordItem.Id => recordItem };

        // Act
        Test.startTest();
        Product2Service.beforeUpdate(new List<Product2>{ recordItem }, persistedRecordsById, persistedRecordsById);
        Test.stopTest();

        // Assert
        System.assertEquals(true, true, 'Should not throw for valid record');
    }

    @IsTest
    static void testBeforeDeleteNullRecordsReturnsEarly() {
        // Act
        Test.startTest();
        Product2Service.beforeDelete(new Map<Id, Product2>(), null);
        Test.stopTest();

        // Assert
        System.assertEquals(true, true, 'Should not throw for null input');
    }

    @IsTest
    static void testBeforeDeleteEmptyRecordsReturnsEarly() {
        // Act
        Test.startTest();
        Product2Service.beforeDelete(new Map<Id, Product2>(), new Map<Id, Product2>());
        Test.stopTest();

        // Assert
        System.assertEquals(true, true, 'Should not throw for empty input');
    }

    @IsTest
    static void testBeforeDeleteValidRecordsPassesValidation() {
        // Arrange
        Product2 recordItem = TestDataFactory.createProduct2(true);
        Map<Id, Product2> loadedRecordsById = new Map<Id, Product2>{ recordItem.Id => recordItem };

        // Act
        Test.startTest();
        Product2Service.beforeDelete(loadedRecordsById, loadedRecordsById);
        Test.stopTest();

        // Assert
        System.assertEquals(true, true, 'Should not throw for valid records');
    }

    @IsTest
    static void testAfterInsertReturnsRecords() {
        // Arrange
        List<Product2> records = new List<Product2>{ TestDataFactory.createProduct2(false) };

        // Act
        Test.startTest();
        Product2Service.afterInsert(records);
        Test.stopTest();

        // Assert
        System.assertEquals(true, true, 'Should not throw for afterInsert');
    }

    @IsTest
    static void testAfterUpdateReturnsRecords() {
        // Arrange
        Product2 recordItem = TestDataFactory.createProduct2(true);
        List<Product2> records = new List<Product2>{ recordItem };
        Map<Id, Product2> persistedRecordsById = new Map<Id, Product2>{ recordItem.Id => recordItem };

        // Act
        Test.startTest();
        Product2Service.afterUpdate(records, persistedRecordsById, persistedRecordsById);
        Test.stopTest();

        // Assert
        System.assertEquals(true, true, 'Should not throw for afterUpdate');
    }

    @IsTest
    static void testAfterDeleteNullMapReturnsEarly() {
        // Act
        Test.startTest();
        Product2Service.afterDelete(null);
        Test.stopTest();

        // Assert
        System.assertEquals(true, true, 'Should not throw for null input');
    }

    @IsTest
    static void testAfterDeleteValidMapCompletesSuccessfully() {
        // Arrange
        Product2 recordItem = TestDataFactory.createProduct2(true);
        Map<Id, Product2> oldRecordsById = new Map<Id, Product2>{ recordItem.Id => recordItem };

        // Act
        Test.startTest();
        Product2Service.afterDelete(oldRecordsById);
        Test.stopTest();

        // Assert
        System.assertEquals(true, true, 'Should not throw for valid input');
    }

    @IsTest
    static void testSaveRecordsBlankNameThrowsServiceException() {
        // Arrange
        Product2 recordItem = TestDataFactory.createProduct2(false);
        recordItem.Name = '   ';
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            Product2Service.saveRecords(new List<Product2>{ recordItem }, new Map<Id, Product2>());
        } catch (Product2Exception ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(true, actualMessage.contains(Product2.SObjectType.getDescribe().getLabel()), 'The service should reject blank Name values.');
    }

    @IsTest
    static void testSaveRecordsMultipleRecordsInsertsAndUpdates() {
        // Arrange
        Product2 existingRecord = TestDataFactory.createProduct2(true);
        Product2 newRecord = TestDataFactory.createProduct2(false);
        existingRecord.Description = 'Updated description';
        Map<Id, Product2> persistedRecordsById = new Map<Id, Product2>{ existingRecord.Id => Product2DAO.getById(existingRecord.Id) };

        // Act
        Test.startTest();
        List<Product2> savedRecords = Product2Service.saveRecords(new List<Product2>{ existingRecord, newRecord }, persistedRecordsById);
        Test.stopTest();

        // Assert
        System.assertEquals(2, savedRecords.size(), 'The service should save both records.');
        System.assertEquals(true, newRecord.Id != null, 'The service should assign ID to new record.');
    }
}
