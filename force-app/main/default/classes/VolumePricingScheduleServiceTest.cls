@IsTest
private class VolumePricingScheduleServiceTest {
    @TestSetup
    static void setup() {
        TestDataFactory.createVolumePricingSchedule(true);
    }

    @IsTest
    static void test_saveRecords_insert_validRecord_persistsRecord() {
        // Arrange
        Volume_Pricing_Schedule__c recordItem = TestDataFactory.createVolumePricingSchedule(false);

        // Act
        Test.startTest();
        List<Volume_Pricing_Schedule__c> savedRecords = VolumePricingScheduleService.saveRecords(new List<Volume_Pricing_Schedule__c>{ recordItem }, new Map<Id, Volume_Pricing_Schedule__c>());
        Test.stopTest();

        // Assert
        System.assertEquals(true, savedRecords[0].Id != null, 'The service should insert a new record when valid data is provided.');
    }

    @IsTest
    static void test_saveRecords_update_changedRecord_updatesRecord() {
        // Arrange
        Volume_Pricing_Schedule__c recordItem = [SELECT Id FROM Volume_Pricing_Schedule__c LIMIT 1];
        recordItem = VolumePricingScheduleDAO.getById(recordItem.Id);
        recordItem.Overage_Rate__c = 15;
        Object expectedValue = 15;
        Map<Id, Volume_Pricing_Schedule__c> persistedRecordsById = VolumePricingScheduleDAO.getByIds(new Set<Id>{ recordItem.Id });

        // Act
        Test.startTest();
        VolumePricingScheduleService.saveRecords(new List<Volume_Pricing_Schedule__c>{ recordItem }, persistedRecordsById);
        Test.stopTest();

        // Assert
        Volume_Pricing_Schedule__c refreshedRecord = VolumePricingScheduleDAO.getById(recordItem.Id);
        System.assertEquals(String.valueOf(expectedValue), String.valueOf(refreshedRecord.get('Overage_Rate__c')), 'The service should persist the updated field value.');
    }

    @IsTest
    static void test_saveRecords_emptyList_throwsServiceException() {
        // Arrange
        List<Volume_Pricing_Schedule__c> emptyRecords = new List<Volume_Pricing_Schedule__c>();
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            VolumePricingScheduleService.saveRecords(emptyRecords, new Map<Id, Volume_Pricing_Schedule__c>());
            System.assertEquals('Expected exception', 'No exception', 'The service should throw when an empty list is provided.');
        } catch (VolumePricingScheduleService.ServiceException ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(String.format(System.Label.Generic_Service_Records_Required, new List<String>{ Volume_Pricing_Schedule__c.SObjectType.getDescribe().getLabel() }), actualMessage, 'The service should return the configured empty-list message.');
    }

    @IsTest
    static void test_saveRecords_missingRequiredField_throwsServiceException() {
        // Arrange
        Volume_Pricing_Schedule__c recordItem = TestDataFactory.createVolumePricingSchedule(false);
        recordItem.Product__c = null;
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            VolumePricingScheduleService.saveRecords(new List<Volume_Pricing_Schedule__c>{ recordItem }, new Map<Id, Volume_Pricing_Schedule__c>());
            System.assertEquals('Expected exception', 'No exception', 'The service should throw when required data is missing.');
        } catch (VolumePricingScheduleService.ServiceException ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(true, actualMessage.contains(Volume_Pricing_Schedule__c.SObjectType.getDescribe().getLabel()), 'The service should mention the object label in the validation message.');
    }

    @IsTest
    static void test_saveRecords_unchangedRecord_skipsUpdate() {
        // Arrange
        Volume_Pricing_Schedule__c recordItem = [SELECT Id FROM Volume_Pricing_Schedule__c LIMIT 1];
        recordItem = VolumePricingScheduleDAO.getById(recordItem.Id);
        String beforeSerialized = JSON.serialize(recordItem);
        Map<Id, Volume_Pricing_Schedule__c> persistedRecordsById = VolumePricingScheduleDAO.getByIds(new Set<Id>{ recordItem.Id });

        // Act
        Test.startTest();
        List<Volume_Pricing_Schedule__c> savedRecords = VolumePricingScheduleService.saveRecords(new List<Volume_Pricing_Schedule__c>{ recordItem }, persistedRecordsById);
        Test.stopTest();

        // Assert
        System.assertEquals(beforeSerialized, JSON.serialize(savedRecords[0]), 'The service should leave an unchanged record untouched.');
    }

    @IsTest
    static void test_deleteRecords_validRecord_deletesRecord() {
        // Arrange
        Volume_Pricing_Schedule__c recordItem = TestDataFactory.createVolumePricingSchedule(true);

        // Act
        Test.startTest();
        VolumePricingScheduleService.deleteRecords(new List<Volume_Pricing_Schedule__c>{ recordItem });
        Test.stopTest();

        // Assert
        System.assertEquals(0, [SELECT Count() FROM Volume_Pricing_Schedule__c WHERE Id = :recordItem.Id], 'The service should delete the provided record.');
    }
}
