@IsTest
private class AccountServiceTest {
    @TestSetup
    static void setup() {
        TestDataFactory.createAccount(true);
    }

    @IsTest
    static void test_saveRecords_insert_validRecord_persistsRecord() {
        // Arrange
        Account recordItem = TestDataFactory.createAccount(false);

        // Act
        Test.startTest();
        List<Account> savedRecords = AccountService.saveRecords(new List<Account>{ recordItem }, new Map<Id, Account>());
        Test.stopTest();

        // Assert
        System.assertEquals(true, savedRecords[0].Id != null, 'The service should insert a new record when valid data is provided.');
    }

    @IsTest
    static void test_saveRecords_update_changedRecord_updatesRecord() {
        // Arrange
        Account recordItem = [SELECT Id FROM Account LIMIT 1];
        recordItem = AccountDAO.getById(recordItem.Id);
        recordItem.Description = 'Updated account description';
        Object expectedValue = 'Updated account description';
        Map<Id, Account> persistedRecordsById = AccountDAO.getByIds(new Set<Id>{ recordItem.Id });

        // Act
        Test.startTest();
        AccountService.saveRecords(new List<Account>{ recordItem }, persistedRecordsById);
        Test.stopTest();

        // Assert
        Account refreshedRecord = AccountDAO.getById(recordItem.Id);
        System.assertEquals(String.valueOf(expectedValue), String.valueOf(refreshedRecord.get('Description')), 'The service should persist the updated field value.');
    }

    @IsTest
    static void test_saveRecords_emptyList_throwsServiceException() {
        // Arrange
        List<Account> emptyRecords = new List<Account>();
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            AccountService.saveRecords(emptyRecords, new Map<Id, Account>());
            System.assertEquals('Expected exception', 'No exception', 'The service should throw when an empty list is provided.');
        } catch (AccountService.ServiceException ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(String.format(System.Label.Generic_Service_Records_Required, new List<String>{ Account.SObjectType.getDescribe().getLabel() }), actualMessage, 'The service should return the configured empty-list message.');
    }

    @IsTest
    static void test_saveRecords_missingRequiredField_throwsServiceException() {
        // Arrange
        Account recordItem = TestDataFactory.createAccount(false);
        recordItem.Name = null;
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            AccountService.saveRecords(new List<Account>{ recordItem }, new Map<Id, Account>());
            System.assertEquals('Expected exception', 'No exception', 'The service should throw when required data is missing.');
        } catch (AccountService.ServiceException ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(true, actualMessage.contains(Account.SObjectType.getDescribe().getLabel()), 'The service should mention the object label in the validation message.');
    }

    @IsTest
    static void test_saveRecords_unchangedRecord_skipsUpdate() {
        // Arrange
        Account recordItem = [SELECT Id FROM Account LIMIT 1];
        recordItem = AccountDAO.getById(recordItem.Id);
        String beforeSerialized = JSON.serialize(recordItem);
        Map<Id, Account> persistedRecordsById = AccountDAO.getByIds(new Set<Id>{ recordItem.Id });

        // Act
        Test.startTest();
        List<Account> savedRecords = AccountService.saveRecords(new List<Account>{ recordItem }, persistedRecordsById);
        Test.stopTest();

        // Assert
        System.assertEquals(beforeSerialized, JSON.serialize(savedRecords[0]), 'The service should leave an unchanged record untouched.');
    }

    @IsTest
    static void test_deleteRecords_validRecord_deletesRecord() {
        // Arrange
        Account recordItem = TestDataFactory.createAccount(true);

        // Act
        Test.startTest();
        AccountService.deleteRecords(new List<Account>{ recordItem });
        Test.stopTest();

        // Assert
        System.assertEquals(0, [SELECT Count() FROM Account WHERE Id = :recordItem.Id], 'The service should delete the provided record.');
    }
}
