@IsTest
private class OpportunityLineItemServiceTest {
    @TestSetup
    static void setup() {
        TestDataFactory.createOpportunityLineItem(true);
    }

    @IsTest
    static void test_saveRecords_insert_validRecord_persistsRecord() {
        // Arrange
        OpportunityLineItem recordItem = TestDataFactory.createOpportunityLineItem(false);

        // Act
        Test.startTest();
        List<OpportunityLineItem> savedRecords = OpportunityLineItemService.saveRecords(new List<OpportunityLineItem>{ recordItem }, new Map<Id, OpportunityLineItem>());
        Test.stopTest();

        // Assert
        System.assertEquals(true, savedRecords[0].Id != null, 'The service should insert a new record when valid data is provided.');
    }

    @IsTest
    static void test_saveRecords_update_changedRecord_updatesRecord() {
        // Arrange
        OpportunityLineItem recordItem = [SELECT Id FROM OpportunityLineItem LIMIT 1];
        recordItem = OpportunityLineItemDAO.getById(recordItem.Id);
        recordItem.Description = 'Updated line description';
        Object expectedValue = 'Updated line description';
        Map<Id, OpportunityLineItem> persistedRecordsById = OpportunityLineItemDAO.getByIds(new Set<Id>{ recordItem.Id });

        // Act
        Test.startTest();
        OpportunityLineItemService.saveRecords(new List<OpportunityLineItem>{ recordItem }, persistedRecordsById);
        Test.stopTest();

        // Assert
        OpportunityLineItem refreshedRecord = OpportunityLineItemDAO.getById(recordItem.Id);
        System.assertEquals(String.valueOf(expectedValue), String.valueOf(refreshedRecord.get('Description')), 'The service should persist the updated field value.');
    }

    @IsTest
    static void test_saveRecords_emptyList_throwsServiceException() {
        // Arrange
        List<OpportunityLineItem> emptyRecords = new List<OpportunityLineItem>();
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            OpportunityLineItemService.saveRecords(emptyRecords, new Map<Id, OpportunityLineItem>());
            System.assertEquals('Expected exception', 'No exception', 'The service should throw when an empty list is provided.');
        } catch (OpportunityLineItemService.ServiceException ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(String.format(System.Label.Generic_Service_Records_Required, new List<String>{ OpportunityLineItem.SObjectType.getDescribe().getLabel() }), actualMessage, 'The service should return the configured empty-list message.');
    }

    @IsTest
    static void test_saveRecords_missingRequiredField_throwsServiceException() {
        // Arrange
        OpportunityLineItem recordItem = TestDataFactory.createOpportunityLineItem(false);
        recordItem.PricebookEntryId = null;
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            OpportunityLineItemService.saveRecords(new List<OpportunityLineItem>{ recordItem }, new Map<Id, OpportunityLineItem>());
            System.assertEquals('Expected exception', 'No exception', 'The service should throw when required data is missing.');
        } catch (OpportunityLineItemService.ServiceException ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(true, actualMessage.contains(OpportunityLineItem.SObjectType.getDescribe().getLabel()), 'The service should mention the object label in the validation message.');
    }

    @IsTest
    static void test_saveRecords_unchangedRecord_skipsUpdate() {
        // Arrange
        OpportunityLineItem recordItem = [SELECT Id FROM OpportunityLineItem LIMIT 1];
        recordItem = OpportunityLineItemDAO.getById(recordItem.Id);
        String beforeSerialized = JSON.serialize(recordItem);
        Map<Id, OpportunityLineItem> persistedRecordsById = OpportunityLineItemDAO.getByIds(new Set<Id>{ recordItem.Id });

        // Act
        Test.startTest();
        List<OpportunityLineItem> savedRecords = OpportunityLineItemService.saveRecords(new List<OpportunityLineItem>{ recordItem }, persistedRecordsById);
        Test.stopTest();

        // Assert
        System.assertEquals(beforeSerialized, JSON.serialize(savedRecords[0]), 'The service should leave an unchanged record untouched.');
    }

    @IsTest
    static void test_deleteRecords_validRecord_deletesRecord() {
        // Arrange
        OpportunityLineItem recordItem = TestDataFactory.createOpportunityLineItem(true);

        // Act
        Test.startTest();
        OpportunityLineItemService.deleteRecords(new List<OpportunityLineItem>{ recordItem });
        Test.stopTest();

        // Assert
        System.assertEquals(0, [SELECT Count() FROM OpportunityLineItem WHERE Id = :recordItem.Id], 'The service should delete the provided record.');
    }
}
