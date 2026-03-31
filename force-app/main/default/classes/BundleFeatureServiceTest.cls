@IsTest
private class BundleFeatureServiceTest {
    @TestSetup
    static void setup() {
        TestDataFactory.createBundleFeature(true);
    }

    @IsTest
    static void test_saveRecords_insert_validRecord_persistsRecord() {
        // Arrange
        Bundle_Feature__c recordItem = TestDataFactory.createBundleFeature(false);

        // Act
        Test.startTest();
        List<Bundle_Feature__c> savedRecords = BundleFeatureService.saveRecords(new List<Bundle_Feature__c>{ recordItem }, new Map<Id, Bundle_Feature__c>());
        Test.stopTest();

        // Assert
        System.assertEquals(true, savedRecords[0].Id != null, 'The service should insert a new record when valid data is provided.');
    }

    @IsTest
    static void test_saveRecords_update_changedRecord_updatesRecord() {
        // Arrange
        Bundle_Feature__c recordItem = [SELECT Id FROM Bundle_Feature__c LIMIT 1];
        recordItem = BundleFeatureDAO.getById(recordItem.Id);
        recordItem.Help_Text__c = 'Updated feature help text';
        Object expectedValue = 'Updated feature help text';
        Map<Id, Bundle_Feature__c> persistedRecordsById = BundleFeatureDAO.getByIds(new Set<Id>{ recordItem.Id });

        // Act
        Test.startTest();
        BundleFeatureService.saveRecords(new List<Bundle_Feature__c>{ recordItem }, persistedRecordsById);
        Test.stopTest();

        // Assert
        Bundle_Feature__c refreshedRecord = BundleFeatureDAO.getById(recordItem.Id);
        System.assertEquals(String.valueOf(expectedValue), String.valueOf(refreshedRecord.get('Help_Text__c')), 'The service should persist the updated field value.');
    }

    @IsTest
    static void test_saveRecords_emptyList_throwsServiceException() {
        // Arrange
        List<Bundle_Feature__c> emptyRecords = new List<Bundle_Feature__c>();
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            BundleFeatureService.saveRecords(emptyRecords, new Map<Id, Bundle_Feature__c>());
            System.assertEquals('Expected exception', 'No exception', 'The service should throw when an empty list is provided.');
        } catch (BundleFeatureService.ServiceException ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(String.format(System.Label.Generic_Service_Records_Required, new List<String>{ Bundle_Feature__c.SObjectType.getDescribe().getLabel() }), actualMessage, 'The service should return the configured empty-list message.');
    }

    @IsTest
    static void test_saveRecords_missingRequiredField_throwsServiceException() {
        // Arrange
        Bundle_Feature__c recordItem = TestDataFactory.createBundleFeature(false);
        recordItem.Sort_Order__c = null;
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            BundleFeatureService.saveRecords(new List<Bundle_Feature__c>{ recordItem }, new Map<Id, Bundle_Feature__c>());
            System.assertEquals('Expected exception', 'No exception', 'The service should throw when required data is missing.');
        } catch (BundleFeatureService.ServiceException ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(true, actualMessage.contains(Bundle_Feature__c.SObjectType.getDescribe().getLabel()), 'The service should mention the object label in the validation message.');
    }

    @IsTest
    static void test_saveRecords_unchangedRecord_skipsUpdate() {
        // Arrange
        Bundle_Feature__c recordItem = [SELECT Id FROM Bundle_Feature__c LIMIT 1];
        recordItem = BundleFeatureDAO.getById(recordItem.Id);
        String beforeSerialized = JSON.serialize(recordItem);
        Map<Id, Bundle_Feature__c> persistedRecordsById = BundleFeatureDAO.getByIds(new Set<Id>{ recordItem.Id });

        // Act
        Test.startTest();
        List<Bundle_Feature__c> savedRecords = BundleFeatureService.saveRecords(new List<Bundle_Feature__c>{ recordItem }, persistedRecordsById);
        Test.stopTest();

        // Assert
        System.assertEquals(beforeSerialized, JSON.serialize(savedRecords[0]), 'The service should leave an unchanged record untouched.');
    }

    @IsTest
    static void test_deleteRecords_validRecord_deletesRecord() {
        // Arrange
        Bundle_Feature__c recordItem = TestDataFactory.createBundleFeature(true);

        // Act
        Test.startTest();
        BundleFeatureService.deleteRecords(new List<Bundle_Feature__c>{ recordItem });
        Test.stopTest();

        // Assert
        System.assertEquals(0, [SELECT Count() FROM Bundle_Feature__c WHERE Id = :recordItem.Id], 'The service should delete the provided record.');
    }
}
