@IsTest
private class BundleRuleAssignmentServiceTest {
    @TestSetup
    static void setup() {
        TestDataFactory.createBundleRuleAssignment(true);
    }

    @IsTest
    static void test_saveRecords_insert_validRecord_persistsRecord() {
        // Arrange
        Bundle_Rule_Assignment__c recordItem = TestDataFactory.createBundleRuleAssignment(false);

        // Act
        Test.startTest();
        List<Bundle_Rule_Assignment__c> savedRecords = BundleRuleAssignmentService.saveRecords(new List<Bundle_Rule_Assignment__c>{ recordItem }, new Map<Id, Bundle_Rule_Assignment__c>());
        Test.stopTest();

        // Assert
        System.assertEquals(true, savedRecords[0].Id != null, 'The service should insert a new record when valid data is provided.');
    }

    @IsTest
    static void test_saveRecords_update_changedRecord_updatesRecord() {
        // Arrange
        Bundle_Rule_Assignment__c recordItem = [SELECT Id FROM Bundle_Rule_Assignment__c LIMIT 1];
        recordItem = BundleRuleAssignmentDAO.getById(recordItem.Id);
        recordItem.Is_Active__c = false;
        Object expectedValue = false;
        Map<Id, Bundle_Rule_Assignment__c> persistedRecordsById = BundleRuleAssignmentDAO.getByIds(new Set<Id>{ recordItem.Id });

        // Act
        Test.startTest();
        BundleRuleAssignmentService.saveRecords(new List<Bundle_Rule_Assignment__c>{ recordItem }, persistedRecordsById);
        Test.stopTest();

        // Assert
        Bundle_Rule_Assignment__c refreshedRecord = BundleRuleAssignmentDAO.getById(recordItem.Id);
        System.assertEquals(String.valueOf(expectedValue), String.valueOf(refreshedRecord.get('Is_Active__c')), 'The service should persist the updated field value.');
    }

    @IsTest
    static void test_saveRecords_emptyList_throwsServiceException() {
        // Arrange
        List<Bundle_Rule_Assignment__c> emptyRecords = new List<Bundle_Rule_Assignment__c>();
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            BundleRuleAssignmentService.saveRecords(emptyRecords, new Map<Id, Bundle_Rule_Assignment__c>());
            System.assertEquals('Expected exception', 'No exception', 'The service should throw when an empty list is provided.');
        } catch (BundleRuleAssignmentService.ServiceException ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(String.format(System.Label.Generic_Service_Records_Required, new List<String>{ Bundle_Rule_Assignment__c.SObjectType.getDescribe().getLabel() }), actualMessage, 'The service should return the configured empty-list message.');
    }

    @IsTest
    static void test_saveRecords_missingRequiredField_throwsServiceException() {
        // Arrange
        Bundle_Rule_Assignment__c recordItem = TestDataFactory.createBundleRuleAssignment(false);
        recordItem.Bundle_Product__c = null;
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            BundleRuleAssignmentService.saveRecords(new List<Bundle_Rule_Assignment__c>{ recordItem }, new Map<Id, Bundle_Rule_Assignment__c>());
            System.assertEquals('Expected exception', 'No exception', 'The service should throw when required data is missing.');
        } catch (BundleRuleAssignmentService.ServiceException ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(true, actualMessage.contains(Bundle_Rule_Assignment__c.SObjectType.getDescribe().getLabel()), 'The service should mention the object label in the validation message.');
    }

    @IsTest
    static void test_saveRecords_unchangedRecord_skipsUpdate() {
        // Arrange
        Bundle_Rule_Assignment__c recordItem = [SELECT Id FROM Bundle_Rule_Assignment__c LIMIT 1];
        recordItem = BundleRuleAssignmentDAO.getById(recordItem.Id);
        String beforeSerialized = JSON.serialize(recordItem);
        Map<Id, Bundle_Rule_Assignment__c> persistedRecordsById = BundleRuleAssignmentDAO.getByIds(new Set<Id>{ recordItem.Id });

        // Act
        Test.startTest();
        List<Bundle_Rule_Assignment__c> savedRecords = BundleRuleAssignmentService.saveRecords(new List<Bundle_Rule_Assignment__c>{ recordItem }, persistedRecordsById);
        Test.stopTest();

        // Assert
        System.assertEquals(beforeSerialized, JSON.serialize(savedRecords[0]), 'The service should leave an unchanged record untouched.');
    }

    @IsTest
    static void test_deleteRecords_validRecord_deletesRecord() {
        // Arrange
        Bundle_Rule_Assignment__c recordItem = TestDataFactory.createBundleRuleAssignment(true);

        // Act
        Test.startTest();
        BundleRuleAssignmentService.deleteRecords(new List<Bundle_Rule_Assignment__c>{ recordItem });
        Test.stopTest();

        // Assert
        System.assertEquals(0, [SELECT Count() FROM Bundle_Rule_Assignment__c WHERE Id = :recordItem.Id], 'The service should delete the provided record.');
    }
}
