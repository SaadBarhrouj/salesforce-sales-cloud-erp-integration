@IsTest
private class BundleOptionServiceTest {
    @TestSetup
    static void setup() {
        TestDataFactory.createBundleOption(true);
    }

    @IsTest
    static void test_saveRecords_insert_validRecord_persistsRecord() {
        // Arrange
        Bundle_Option__c recordItem = TestDataFactory.createBundleOption(false);

        // Act
        Test.startTest();
        List<Bundle_Option__c> savedRecords = BundleOptionService.saveRecords(new List<Bundle_Option__c>{ recordItem }, new Map<Id, Bundle_Option__c>());
        Test.stopTest();

        // Assert
        System.assertEquals(true, savedRecords[0].Id != null, 'The service should insert a new record when valid data is provided.');
    }

    @IsTest
    static void test_saveRecords_update_changedRecord_updatesRecord() {
        // Arrange
        Bundle_Option__c recordItem = [SELECT Id FROM Bundle_Option__c LIMIT 1];
        recordItem = BundleOptionDAO.getById(recordItem.Id);
        recordItem.Default_Quantity__c = 3;
        Object expectedValue = 3;
        Map<Id, Bundle_Option__c> persistedRecordsById = BundleOptionDAO.getByIds(new Set<Id>{ recordItem.Id });

        // Act
        Test.startTest();
        BundleOptionService.saveRecords(new List<Bundle_Option__c>{ recordItem }, persistedRecordsById);
        Test.stopTest();

        // Assert
        Bundle_Option__c refreshedRecord = BundleOptionDAO.getById(recordItem.Id);
        System.assertEquals(String.valueOf(expectedValue), String.valueOf(refreshedRecord.get('Default_Quantity__c')), 'The service should persist the updated field value.');
    }

    @IsTest
    static void test_saveRecords_emptyList_throwsServiceException() {
        // Arrange
        List<Bundle_Option__c> emptyRecords = new List<Bundle_Option__c>();
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            BundleOptionService.saveRecords(emptyRecords, new Map<Id, Bundle_Option__c>());
            System.assertEquals('Expected exception', 'No exception', 'The service should throw when an empty list is provided.');
        } catch (BundleOptionService.ServiceException ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(String.format(System.Label.Generic_Service_Records_Required, new List<String>{ Bundle_Option__c.SObjectType.getDescribe().getLabel() }), actualMessage, 'The service should return the configured empty-list message.');
    }

    @IsTest
    static void test_saveRecords_missingRequiredField_throwsServiceException() {
        // Arrange
        Bundle_Option__c recordItem = TestDataFactory.createBundleOption(false);
        recordItem.Option_Type__c = null;
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            BundleOptionService.saveRecords(new List<Bundle_Option__c>{ recordItem }, new Map<Id, Bundle_Option__c>());
            System.assertEquals('Expected exception', 'No exception', 'The service should throw when required data is missing.');
        } catch (BundleOptionService.ServiceException ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(true, actualMessage.contains(Bundle_Option__c.SObjectType.getDescribe().getLabel()), 'The service should mention the object label in the validation message.');
    }

    @IsTest
    static void test_saveRecords_unchangedRecord_skipsUpdate() {
        // Arrange
        Bundle_Option__c recordItem = [SELECT Id FROM Bundle_Option__c LIMIT 1];
        recordItem = BundleOptionDAO.getById(recordItem.Id);
        String beforeSerialized = JSON.serialize(recordItem);
        Map<Id, Bundle_Option__c> persistedRecordsById = BundleOptionDAO.getByIds(new Set<Id>{ recordItem.Id });

        // Act
        Test.startTest();
        List<Bundle_Option__c> savedRecords = BundleOptionService.saveRecords(new List<Bundle_Option__c>{ recordItem }, persistedRecordsById);
        Test.stopTest();

        // Assert
        System.assertEquals(beforeSerialized, JSON.serialize(savedRecords[0]), 'The service should leave an unchanged record untouched.');
    }

    @IsTest
    static void test_deleteRecords_validRecord_deletesRecord() {
        // Arrange
        Bundle_Option__c recordItem = TestDataFactory.createBundleOption(true);

        // Act
        Test.startTest();
        BundleOptionService.deleteRecords(new List<Bundle_Option__c>{ recordItem });
        Test.stopTest();

        // Assert
        System.assertEquals(0, [SELECT Count() FROM Bundle_Option__c WHERE Id = :recordItem.Id], 'The service should delete the provided record.');
    }
}
