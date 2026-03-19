@IsTest
private class RuleActionServiceTest {
    @TestSetup
    static void setup() {
        TestDataFactory.createRuleAction(true);
    }

    @IsTest
    static void test_saveRecords_insert_validRecord_persistsRecord() {
        // Arrange
        Rule_Action__c recordItem = TestDataFactory.createRuleAction(false);

        // Act
        Test.startTest();
        List<Rule_Action__c> savedRecords = RuleActionService.saveRecords(new List<Rule_Action__c>{ recordItem }, new Map<Id, Rule_Action__c>());
        Test.stopTest();

        // Assert
        System.assertEquals(true, savedRecords[0].Id != null, 'The service should insert a new record when valid data is provided.');
    }

    @IsTest
    static void test_saveRecords_update_changedRecord_updatesRecord() {
        // Arrange
        Rule_Action__c recordItem = [SELECT Id FROM Rule_Action__c LIMIT 1];
        recordItem = RuleActionDAO.getById(recordItem.Id);
        recordItem.Sort_Order__c = 20;
        Object expectedValue = 20;
        Map<Id, Rule_Action__c> persistedRecordsById = RuleActionDAO.getByIds(new Set<Id>{ recordItem.Id });

        // Act
        Test.startTest();
        RuleActionService.saveRecords(new List<Rule_Action__c>{ recordItem }, persistedRecordsById);
        Test.stopTest();

        // Assert
        Rule_Action__c refreshedRecord = RuleActionDAO.getById(recordItem.Id);
        System.assertEquals(String.valueOf(expectedValue), String.valueOf(refreshedRecord.get('Sort_Order__c')), 'The service should persist the updated field value.');
    }

    @IsTest
    static void test_saveRecords_emptyList_throwsServiceException() {
        // Arrange
        List<Rule_Action__c> emptyRecords = new List<Rule_Action__c>();
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            RuleActionService.saveRecords(emptyRecords, new Map<Id, Rule_Action__c>());
            System.assertEquals('Expected exception', 'No exception', 'The service should throw when an empty list is provided.');
        } catch (RuleActionService.ServiceException ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(String.format(System.Label.Generic_Service_Records_Required, new List<String>{ Rule_Action__c.SObjectType.getDescribe().getLabel() }), actualMessage, 'The service should return the configured empty-list message.');
    }

    @IsTest
    static void test_saveRecords_missingRequiredField_throwsServiceException() {
        // Arrange
        Rule_Action__c recordItem = TestDataFactory.createRuleAction(false);
        recordItem.Type__c = null;
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            RuleActionService.saveRecords(new List<Rule_Action__c>{ recordItem }, new Map<Id, Rule_Action__c>());
            System.assertEquals('Expected exception', 'No exception', 'The service should throw when required data is missing.');
        } catch (RuleActionService.ServiceException ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(true, actualMessage.contains(Rule_Action__c.SObjectType.getDescribe().getLabel()), 'The service should mention the object label in the validation message.');
    }

    @IsTest
    static void test_saveRecords_unchangedRecord_skipsUpdate() {
        // Arrange
        Rule_Action__c recordItem = [SELECT Id FROM Rule_Action__c LIMIT 1];
        recordItem = RuleActionDAO.getById(recordItem.Id);
        String beforeSerialized = JSON.serialize(recordItem);
        Map<Id, Rule_Action__c> persistedRecordsById = RuleActionDAO.getByIds(new Set<Id>{ recordItem.Id });

        // Act
        Test.startTest();
        List<Rule_Action__c> savedRecords = RuleActionService.saveRecords(new List<Rule_Action__c>{ recordItem }, persistedRecordsById);
        Test.stopTest();

        // Assert
        System.assertEquals(beforeSerialized, JSON.serialize(savedRecords[0]), 'The service should leave an unchanged record untouched.');
    }

    @IsTest
    static void test_deleteRecords_validRecord_deletesRecord() {
        // Arrange
        Rule_Action__c recordItem = TestDataFactory.createRuleAction(true);

        // Act
        Test.startTest();
        RuleActionService.deleteRecords(new List<Rule_Action__c>{ recordItem });
        Test.stopTest();

        // Assert
        System.assertEquals(0, [SELECT Count() FROM Rule_Action__c WHERE Id = :recordItem.Id], 'The service should delete the provided record.');
    }
}
