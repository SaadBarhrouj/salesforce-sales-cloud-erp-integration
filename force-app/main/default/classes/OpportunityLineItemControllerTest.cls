@IsTest
private class OpportunityLineItemControllerTest {
    @TestSetup
    static void setup() {
        User testUser = TestDataFactory.createUser(true);
        System.runAs(testUser) {
            TestDataFactory.createOpportunityLineItem(true);
        }
    }

    @IsTest
    static void test_getAll_existingData_returnsRecords() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        List<OpportunityLineItem> loadedRecords = new List<OpportunityLineItem>();

        // Act
        System.runAs(testUser) {
            Test.startTest();
            loadedRecords = OpportunityLineItemController.getAll();
            Test.stopTest();
        }

        // Assert
        System.assertEquals(true, loadedRecords.size() > 0, 'The controller should return the records visible to the running user.');
    }

    @IsTest
    static void test_saveRecords_insert_validRecord_returnsSavedRecord() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        OpportunityLineItem recordItem = TestDataFactory.createOpportunityLineItem(false);
        List<OpportunityLineItem> savedRecords = new List<OpportunityLineItem>();

        // Act
        System.runAs(testUser) {
            Test.startTest();
            savedRecords = OpportunityLineItemController.saveRecords(new List<OpportunityLineItem>{ recordItem });
            Test.stopTest();
        }

        // Assert
        System.assertEquals(true, savedRecords[0].Id != null, 'The controller should return the saved record with an Id.');
    }

    @IsTest
    static void test_saveRecords_update_changedRecord_returnsUpdatedRecord() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        OpportunityLineItem recordItem = [SELECT Id FROM OpportunityLineItem LIMIT 1];
        recordItem = OpportunityLineItemDAO.getById(recordItem.Id);
        recordItem.Description = 'Updated line description';
        List<OpportunityLineItem> savedRecords = new List<OpportunityLineItem>();

        // Act
        System.runAs(testUser) {
            Test.startTest();
            savedRecords = OpportunityLineItemController.saveRecords(new List<OpportunityLineItem>{ recordItem });
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
                OpportunityLineItemController.saveRecords(new List<OpportunityLineItem>());
                System.assertEquals('Expected exception', 'No exception', 'The controller should throw when the request is invalid.');
            } catch (AuraHandledException ex) {
                actualMessage = ex.getMessage();
            }
            Test.stopTest();
        }

        // Assert
        System.assertEquals(String.format(System.Label.Generic_Controller_Request_Failed, new List<String>{ OpportunityLineItem.SObjectType.getDescribe().getLabel() }), actualMessage, 'The controller should expose the configured AuraHandledException message.');
    }

    @IsTest
    static void test_deleteRecords_existingRecord_returnsTrue() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        OpportunityLineItem recordItem;
        System.runAs(testUser) {
            recordItem = TestDataFactory.createOpportunityLineItem(true);
        }
        Boolean wasDeleted = false;

        // Act
        System.runAs(testUser) {
            Test.startTest();
            wasDeleted = OpportunityLineItemController.deleteRecords(new List<Id>{ recordItem.Id });
            Test.stopTest();
        }

        // Assert
        System.assertEquals(true, wasDeleted, 'The controller should confirm successful deletion.');
    }
}
