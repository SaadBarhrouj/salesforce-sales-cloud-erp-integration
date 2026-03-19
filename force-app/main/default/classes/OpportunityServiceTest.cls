@IsTest
private class OpportunityServiceTest {
    @TestSetup
    static void setup() {
        TestDataFactory.createOpportunity(true);
    }

    @IsTest
    static void test_saveRecords_insert_validRecord_persistsRecord() {
        // Arrange
        Opportunity recordItem = TestDataFactory.createOpportunity(false);

        // Act
        Test.startTest();
        List<Opportunity> savedRecords = OpportunityService.saveRecords(new List<Opportunity>{ recordItem }, new Map<Id, Opportunity>());
        Test.stopTest();

        // Assert
        System.assertEquals(true, savedRecords[0].Id != null, 'The service should insert a new record when valid data is provided.');
    }

    @IsTest
    static void test_saveRecords_update_changedRecord_updatesRecord() {
        // Arrange
        Opportunity recordItem = [SELECT Id FROM Opportunity LIMIT 1];
        recordItem = OpportunityDAO.getById(recordItem.Id);
        recordItem.Description = 'Updated opportunity description';
        Object expectedValue = 'Updated opportunity description';
        Map<Id, Opportunity> persistedRecordsById = OpportunityDAO.getByIds(new Set<Id>{ recordItem.Id });

        // Act
        Test.startTest();
        OpportunityService.saveRecords(new List<Opportunity>{ recordItem }, persistedRecordsById);
        Test.stopTest();

        // Assert
        Opportunity refreshedRecord = OpportunityDAO.getById(recordItem.Id);
        System.assertEquals(String.valueOf(expectedValue), String.valueOf(refreshedRecord.get('Description')), 'The service should persist the updated field value.');
    }

    @IsTest
    static void test_saveRecords_emptyList_throwsServiceException() {
        // Arrange
        List<Opportunity> emptyRecords = new List<Opportunity>();
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            OpportunityService.saveRecords(emptyRecords, new Map<Id, Opportunity>());
            System.assertEquals('Expected exception', 'No exception', 'The service should throw when an empty list is provided.');
        } catch (OpportunityService.ServiceException ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(String.format(System.Label.Generic_Service_Records_Required, new List<String>{ Opportunity.SObjectType.getDescribe().getLabel() }), actualMessage, 'The service should return the configured empty-list message.');
    }

    @IsTest
    static void test_saveRecords_missingRequiredField_throwsServiceException() {
        // Arrange
        Opportunity recordItem = TestDataFactory.createOpportunity(false);
        recordItem.StageName = null;
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            OpportunityService.saveRecords(new List<Opportunity>{ recordItem }, new Map<Id, Opportunity>());
            System.assertEquals('Expected exception', 'No exception', 'The service should throw when required data is missing.');
        } catch (OpportunityService.ServiceException ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(true, actualMessage.contains(Opportunity.SObjectType.getDescribe().getLabel()), 'The service should mention the object label in the validation message.');
    }

    @IsTest
    static void test_saveRecords_unchangedRecord_skipsUpdate() {
        // Arrange
        Opportunity recordItem = [SELECT Id FROM Opportunity LIMIT 1];
        recordItem = OpportunityDAO.getById(recordItem.Id);
        String beforeSerialized = JSON.serialize(recordItem);
        Map<Id, Opportunity> persistedRecordsById = OpportunityDAO.getByIds(new Set<Id>{ recordItem.Id });

        // Act
        Test.startTest();
        List<Opportunity> savedRecords = OpportunityService.saveRecords(new List<Opportunity>{ recordItem }, persistedRecordsById);
        Test.stopTest();

        // Assert
        System.assertEquals(beforeSerialized, JSON.serialize(savedRecords[0]), 'The service should leave an unchanged record untouched.');
    }

    @IsTest
    static void test_deleteRecords_validRecord_deletesRecord() {
        // Arrange
        Opportunity recordItem = TestDataFactory.createOpportunity(true);

        // Act
        Test.startTest();
        OpportunityService.deleteRecords(new List<Opportunity>{ recordItem });
        Test.stopTest();

        // Assert
        System.assertEquals(0, [SELECT Count() FROM Opportunity WHERE Id = :recordItem.Id], 'The service should delete the provided record.');
    }
}
