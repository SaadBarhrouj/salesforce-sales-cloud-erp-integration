@IsTest
private class VolumePricingTierServiceTest {
    @TestSetup
    static void setup() {
        TestDataFactory.createVolumePricingTier(true);
    }

    @IsTest
    static void test_saveRecords_insert_validRecord_persistsRecord() {
        // Arrange
        Volume_Pricing_Tier__c recordItem = TestDataFactory.createVolumePricingTier(false);

        // Act
        Test.startTest();
        List<Volume_Pricing_Tier__c> savedRecords = VolumePricingTierService.saveRecords(new List<Volume_Pricing_Tier__c>{ recordItem }, new Map<Id, Volume_Pricing_Tier__c>());
        Test.stopTest();

        // Assert
        System.assertEquals(true, savedRecords[0].Id != null, 'The service should insert a new record when valid data is provided.');
    }

    @IsTest
    static void test_saveRecords_update_changedRecord_updatesRecord() {
        // Arrange
        Volume_Pricing_Tier__c recordItem = [SELECT Id FROM Volume_Pricing_Tier__c LIMIT 1];
        recordItem = VolumePricingTierDAO.getById(recordItem.Id);
        recordItem.Upper_Bound__c = 25;
        Object expectedValue = 25;
        Map<Id, Volume_Pricing_Tier__c> persistedRecordsById = VolumePricingTierDAO.getByIds(new Set<Id>{ recordItem.Id });

        // Act
        Test.startTest();
        VolumePricingTierService.saveRecords(new List<Volume_Pricing_Tier__c>{ recordItem }, persistedRecordsById);
        Test.stopTest();

        // Assert
        Volume_Pricing_Tier__c refreshedRecord = VolumePricingTierDAO.getById(recordItem.Id);
        System.assertEquals(String.valueOf(expectedValue), String.valueOf(refreshedRecord.get('Upper_Bound__c')), 'The service should persist the updated field value.');
    }

    @IsTest
    static void test_saveRecords_emptyList_throwsServiceException() {
        // Arrange
        List<Volume_Pricing_Tier__c> emptyRecords = new List<Volume_Pricing_Tier__c>();
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            VolumePricingTierService.saveRecords(emptyRecords, new Map<Id, Volume_Pricing_Tier__c>());
            System.assertEquals('Expected exception', 'No exception', 'The service should throw when an empty list is provided.');
        } catch (VolumePricingTierService.ServiceException ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(String.format(System.Label.Generic_Service_Records_Required, new List<String>{ Volume_Pricing_Tier__c.SObjectType.getDescribe().getLabel() }), actualMessage, 'The service should return the configured empty-list message.');
    }

    @IsTest
    static void test_saveRecords_missingRequiredField_throwsServiceException() {
        // Arrange
        Volume_Pricing_Tier__c recordItem = TestDataFactory.createVolumePricingTier(false);
        recordItem.Price__c = null;
        String actualMessage = '';

        // Act
        Test.startTest();
        try {
            VolumePricingTierService.saveRecords(new List<Volume_Pricing_Tier__c>{ recordItem }, new Map<Id, Volume_Pricing_Tier__c>());
            System.assertEquals('Expected exception', 'No exception', 'The service should throw when required data is missing.');
        } catch (VolumePricingTierService.ServiceException ex) {
            actualMessage = ex.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(true, actualMessage.contains(Volume_Pricing_Tier__c.SObjectType.getDescribe().getLabel()), 'The service should mention the object label in the validation message.');
    }

    @IsTest
    static void test_saveRecords_unchangedRecord_skipsUpdate() {
        // Arrange
        Volume_Pricing_Tier__c recordItem = [SELECT Id FROM Volume_Pricing_Tier__c LIMIT 1];
        recordItem = VolumePricingTierDAO.getById(recordItem.Id);
        String beforeSerialized = JSON.serialize(recordItem);
        Map<Id, Volume_Pricing_Tier__c> persistedRecordsById = VolumePricingTierDAO.getByIds(new Set<Id>{ recordItem.Id });

        // Act
        Test.startTest();
        List<Volume_Pricing_Tier__c> savedRecords = VolumePricingTierService.saveRecords(new List<Volume_Pricing_Tier__c>{ recordItem }, persistedRecordsById);
        Test.stopTest();

        // Assert
        System.assertEquals(beforeSerialized, JSON.serialize(savedRecords[0]), 'The service should leave an unchanged record untouched.');
    }

    @IsTest
    static void test_deleteRecords_validRecord_deletesRecord() {
        // Arrange
        Volume_Pricing_Tier__c recordItem = TestDataFactory.createVolumePricingTier(true);

        // Act
        Test.startTest();
        VolumePricingTierService.deleteRecords(new List<Volume_Pricing_Tier__c>{ recordItem });
        Test.stopTest();

        // Assert
        System.assertEquals(0, [SELECT Count() FROM Volume_Pricing_Tier__c WHERE Id = :recordItem.Id], 'The service should delete the provided record.');
    }
}
