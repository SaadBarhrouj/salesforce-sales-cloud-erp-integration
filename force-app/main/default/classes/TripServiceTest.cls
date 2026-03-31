@IsTest
private class TripServiceTest {
    @TestSetup
    static void setup() {
        TestDataFactory.createTrip(true);
    }

    @IsTest
    static void test_saveRecords_insert_validRecord_persistsRecord() {
        // Arrange
        Trip__c recordItem = TestDataFactory.createTrip(false);

        // Act
        Test.startTest();
        List<Trip__c> savedRecords = TripService.saveRecords(new List<Trip__c>{ recordItem }, new Map<Id, Trip__c>());
        Test.stopTest();

        // Assert
        System.assertEquals(true, savedRecords[0].Id != null, 'The service should insert a new record when valid data is provided.');
    }

    @IsTest
    static void test_saveRecords_update_changedRecord_updatesRecord() {
        // Arrange
        Trip__c recordItem = [SELECT Id FROM Trip__c LIMIT 1];
        recordItem = TripDAO.getById(recordItem.Id);
        recordItem.Status__c = 'Confirmed';
        Object expectedValue = 'Confirmed';
        Map<Id, Trip__c> persistedRecordsById = TripDAO.getByIds(new Set<Id>{ recordItem.Id });

        // Act
        Test.startTest();
        TripService.saveRecords(new List<Trip__c>{ recordItem }, persistedRecordsById);
        Test.stopTest();

        // Assert
        Trip__c refreshedRecord = TripDAO.getById(recordItem.Id);
        System.assertEquals(String.valueOf(expectedValue), String.valueOf(refreshedRecord.get('Status__c')), 'The service should persist the updated field value.');
    }

    @IsTest
    static void test_saveRecords_emptyList_throwsServiceException() {
        // Arrange
        List<Trip__c> emptyRecords = new List<Trip__c>();
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            TripService.saveRecords(emptyRecords, new Map<Id, Trip__c>());
            System.assertEquals('Expected exception', 'No exception', 'The service should throw when an empty list is provided.');
        } catch (TripService.ServiceException ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(String.format(System.Label.Generic_Service_Records_Required, new List<String>{ Trip__c.SObjectType.getDescribe().getLabel() }), actualMessage, 'The service should return the configured empty-list message.');
    }

    @IsTest
    static void test_saveRecords_missingRequiredField_throwsServiceException() {
        // Arrange
        Trip__c recordItem = TestDataFactory.createTrip(false);
        recordItem.Trip_Date__c = null;
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            TripService.saveRecords(new List<Trip__c>{ recordItem }, new Map<Id, Trip__c>());
            System.assertEquals('Expected exception', 'No exception', 'The service should throw when required data is missing.');
        } catch (TripService.ServiceException ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(true, actualMessage.contains(Trip__c.SObjectType.getDescribe().getLabel()), 'The service should mention the object label in the validation message.');
    }

    @IsTest
    static void test_saveRecords_unchangedRecord_skipsUpdate() {
        // Arrange
        Trip__c recordItem = [SELECT Id FROM Trip__c LIMIT 1];
        recordItem = TripDAO.getById(recordItem.Id);
        String beforeSerialized = JSON.serialize(recordItem);
        Map<Id, Trip__c> persistedRecordsById = TripDAO.getByIds(new Set<Id>{ recordItem.Id });

        // Act
        Test.startTest();
        List<Trip__c> savedRecords = TripService.saveRecords(new List<Trip__c>{ recordItem }, persistedRecordsById);
        Test.stopTest();

        // Assert
        System.assertEquals(beforeSerialized, JSON.serialize(savedRecords[0]), 'The service should leave an unchanged record untouched.');
    }

    @IsTest
    static void test_deleteRecords_validRecord_deletesRecord() {
        // Arrange
        Trip__c recordItem = TestDataFactory.createTrip(true);

        // Act
        Test.startTest();
        TripService.deleteRecords(new List<Trip__c>{ recordItem });
        Test.stopTest();

        // Assert
        System.assertEquals(0, [SELECT Count() FROM Trip__c WHERE Id = :recordItem.Id], 'The service should delete the provided record.');
    }
}
