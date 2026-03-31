@IsTest
private class LocationServiceTest {
    @TestSetup
    static void setup() {
        TestDataFactory.createLocation(true);
    }

    @IsTest
    static void test_saveRecords_insert_validRecord_persistsRecord() {
        // Arrange
        Location recordItem = TestDataFactory.createLocation(false);

        // Act
        Test.startTest();
        List<Location> savedRecords = LocationService.saveRecords(new List<Location>{ recordItem }, new Map<Id, Location>());
        Test.stopTest();

        // Assert
        System.assertEquals(true, savedRecords[0].Id != null, 'The service should insert a new record when valid data is provided.');
    }

    @IsTest
    static void test_saveRecords_update_changedRecord_updatesRecord() {
        // Arrange
        Location recordItem = [SELECT Id FROM Location LIMIT 1];
        recordItem = LocationDAO.getById(recordItem.Id);
        recordItem.Description = 'Updated location description';
        Object expectedValue = 'Updated location description';
        Map<Id, Location> persistedRecordsById = LocationDAO.getByIds(new Set<Id>{ recordItem.Id });

        // Act
        Test.startTest();
        LocationService.saveRecords(new List<Location>{ recordItem }, persistedRecordsById);
        Test.stopTest();

        // Assert
        Location refreshedRecord = LocationDAO.getById(recordItem.Id);
        System.assertEquals(String.valueOf(expectedValue), String.valueOf(refreshedRecord.get('Description')), 'The service should persist the updated field value.');
    }

    @IsTest
    static void test_saveRecords_emptyList_throwsServiceException() {
        // Arrange
        List<Location> emptyRecords = new List<Location>();
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            LocationService.saveRecords(emptyRecords, new Map<Id, Location>());
            System.assertEquals('Expected exception', 'No exception', 'The service should throw when an empty list is provided.');
        } catch (LocationService.ServiceException ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(String.format(System.Label.Generic_Service_Records_Required, new List<String>{ Location.SObjectType.getDescribe().getLabel() }), actualMessage, 'The service should return the configured empty-list message.');
    }

    @IsTest
    static void test_saveRecords_missingRequiredField_throwsServiceException() {
        // Arrange
        Location recordItem = TestDataFactory.createLocation(false);
        recordItem.Country_Code__c = null;
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            LocationService.saveRecords(new List<Location>{ recordItem }, new Map<Id, Location>());
            System.assertEquals('Expected exception', 'No exception', 'The service should throw when required data is missing.');
        } catch (LocationService.ServiceException ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(true, actualMessage.contains(Location.SObjectType.getDescribe().getLabel()), 'The service should mention the object label in the validation message.');
    }

    @IsTest
    static void test_saveRecords_unchangedRecord_skipsUpdate() {
        // Arrange
        Location recordItem = [SELECT Id FROM Location LIMIT 1];
        recordItem = LocationDAO.getById(recordItem.Id);
        String beforeSerialized = JSON.serialize(recordItem);
        Map<Id, Location> persistedRecordsById = LocationDAO.getByIds(new Set<Id>{ recordItem.Id });

        // Act
        Test.startTest();
        List<Location> savedRecords = LocationService.saveRecords(new List<Location>{ recordItem }, persistedRecordsById);
        Test.stopTest();

        // Assert
        System.assertEquals(beforeSerialized, JSON.serialize(savedRecords[0]), 'The service should leave an unchanged record untouched.');
    }

    @IsTest
    static void test_deleteRecords_validRecord_deletesRecord() {
        // Arrange
        Location recordItem = TestDataFactory.createLocation(true);

        // Act
        Test.startTest();
        LocationService.deleteRecords(new List<Location>{ recordItem });
        Test.stopTest();

        // Assert
        System.assertEquals(0, [SELECT Count() FROM Location WHERE Id = :recordItem.Id], 'The service should delete the provided record.');
    }
}
