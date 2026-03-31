@IsTest
private class RuleConditionServiceTest {
    @TestSetup
    static void setup() {
        TestDataFactory.createRuleCondition(true);
    }

    @IsTest
    static void test_saveRecords_insert_validRecord_persistsRecord() {
        // Arrange
        Rule_Condition__c recordItem = TestDataFactory.createRuleCondition(false);

        // Act
        Test.startTest();
        List<Rule_Condition__c> savedRecords = RuleConditionService.saveRecords(new List<Rule_Condition__c>{ recordItem }, new Map<Id, Rule_Condition__c>());
        Test.stopTest();

        // Assert
        System.assertEquals(true, savedRecords[0].Id != null, 'The service should insert a new record when valid data is provided.');
    }

    @IsTest
    static void test_saveRecords_update_changedRecord_updatesRecord() {
        // Arrange
        Rule_Condition__c recordItem = [SELECT Id FROM Rule_Condition__c LIMIT 1];
        recordItem = RuleConditionDAO.getById(recordItem.Id);
        recordItem.Filter_Value__c = 'UpdatedValue';
        Object expectedValue = 'UpdatedValue';
        Map<Id, Rule_Condition__c> persistedRecordsById = RuleConditionDAO.getByIds(new Set<Id>{ recordItem.Id });

        // Act
        Test.startTest();
        RuleConditionService.saveRecords(new List<Rule_Condition__c>{ recordItem }, persistedRecordsById);
        Test.stopTest();

        // Assert
        Rule_Condition__c refreshedRecord = RuleConditionDAO.getById(recordItem.Id);
        System.assertEquals(String.valueOf(expectedValue), String.valueOf(refreshedRecord.get('Filter_Value__c')), 'The service should persist the updated field value.');
    }

    @IsTest
    static void test_saveRecords_emptyList_throwsServiceException() {
        // Arrange
        List<Rule_Condition__c> emptyRecords = new List<Rule_Condition__c>();
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            RuleConditionService.saveRecords(emptyRecords, new Map<Id, Rule_Condition__c>());
            System.assertEquals('Expected exception', 'No exception', 'The service should throw when an empty list is provided.');
        } catch (RuleConditionService.ServiceException ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(String.format(System.Label.Generic_Service_Records_Required, new List<String>{ Rule_Condition__c.SObjectType.getDescribe().getLabel() }), actualMessage, 'The service should return the configured empty-list message.');
    }

    @IsTest
    static void test_saveRecords_missingRequiredField_throwsServiceException() {
        // Arrange
        Rule_Condition__c recordItem = TestDataFactory.createRuleCondition(false);
        recordItem.Filter_Value__c = null;
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            RuleConditionService.saveRecords(new List<Rule_Condition__c>{ recordItem }, new Map<Id, Rule_Condition__c>());
            System.assertEquals('Expected exception', 'No exception', 'The service should throw when required data is missing.');
        } catch (RuleConditionService.ServiceException ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(true, actualMessage.contains(Rule_Condition__c.SObjectType.getDescribe().getLabel()), 'The service should mention the object label in the validation message.');
    }

    @IsTest
    static void test_saveRecords_unchangedRecord_skipsUpdate() {
        // Arrange
        Rule_Condition__c recordItem = [SELECT Id FROM Rule_Condition__c LIMIT 1];
        recordItem = RuleConditionDAO.getById(recordItem.Id);
        String beforeSerialized = JSON.serialize(recordItem);
        Map<Id, Rule_Condition__c> persistedRecordsById = RuleConditionDAO.getByIds(new Set<Id>{ recordItem.Id });

        // Act
        Test.startTest();
        List<Rule_Condition__c> savedRecords = RuleConditionService.saveRecords(new List<Rule_Condition__c>{ recordItem }, persistedRecordsById);
        Test.stopTest();

        // Assert
        System.assertEquals(beforeSerialized, JSON.serialize(savedRecords[0]), 'The service should leave an unchanged record untouched.');
    }

    @IsTest
    static void test_deleteRecords_validRecord_deletesRecord() {
        // Arrange
        Rule_Condition__c recordItem = TestDataFactory.createRuleCondition(true);

        // Act
        Test.startTest();
        RuleConditionService.deleteRecords(new List<Rule_Condition__c>{ recordItem });
        Test.stopTest();

        // Assert
        System.assertEquals(0, [SELECT Count() FROM Rule_Condition__c WHERE Id = :recordItem.Id], 'The service should delete the provided record.');
    }
}
