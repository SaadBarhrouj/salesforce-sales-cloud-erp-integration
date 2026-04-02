@IsTest
private class ProductCategoryControllerTest {

    
    @IsTest
    static void testGetSidebarCategoriesByOfferTypeHappyPath() {
        Opportunity opp = TestDataFactory.createOpportunity('Sale', true);
        
        Test.startTest();
        List<Map<String, Object>> result = ProductCategoryController.getSidebarCategoriesByOfferType(opp.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @IsTest
    static void testGetSidebarCategoriesByOfferTypeNullIdThrowsException() {
        Test.startTest();
        try {
            ProductCategoryController.getSidebarCategoriesByOfferType(null);
            System.assert(false, 'Expected AuraHandledException');
        } catch (AuraHandledException ex) {
            System.assertNotEquals(null, ex.getMessage());
        }
        Test.stopTest();
    }


    /*
    @IsTest
    static void test_getAll_existingData_returnsRecords() {
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        List<ProductCategory> loadedRecords = new List<ProductCategory>();
        System.runAs(testUser) {
            Test.startTest();
            loadedRecords = ProductCategoryController.getAll();
            Test.stopTest();
        }
        System.assertEquals(true, loadedRecords.size() > 0,
            'The controller should return the records visible to the running user.');
    }

    @IsTest
    static void test_saveRecords_insert_validRecord_returnsSavedRecord() {
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        ProductCategory recordItem = TestDataFactory.createProductCategory(false);
        List<ProductCategory> savedRecords = new List<ProductCategory>();
        System.runAs(testUser) {
            Test.startTest();
            savedRecords = ProductCategoryController.saveRecords(new List<ProductCategory>{ recordItem });
            Test.stopTest();
        }
        System.assertEquals(true, savedRecords[0].Id != null,
            'The controller should return the saved record with an Id.');
    }

    @IsTest
    static void test_saveRecords_update_changedRecord_returnsUpdatedRecord() {
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        ProductCategory recordItem = [SELECT Id FROM ProductCategory LIMIT 1];
        recordItem = ProductCategoryDAO.getById(recordItem.Id);
        recordItem.Description = 'Updated category description';
        List<ProductCategory> savedRecords = new List<ProductCategory>();
        System.runAs(testUser) {
            Test.startTest();
            savedRecords = ProductCategoryController.saveRecords(new List<ProductCategory>{ recordItem });
            Test.stopTest();
        }
        System.assertEquals(recordItem.Id, savedRecords[0].Id,
            'The controller should return the updated record.');
    }

    @IsTest
    static void test_saveRecords_emptyList_throwsAuraHandledException() {
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        String actualMessage = '';
        System.runAs(testUser) {
            Test.startTest();
            try {
                ProductCategoryController.saveRecords(new List<ProductCategory>());
                System.assertEquals('Expected exception', 'No exception',
                    'The controller should throw when the request is invalid.');
            } catch (AuraHandledException ex) {
                actualMessage = ex.getMessage();
            }
            Test.stopTest();
        }
        System.assertEquals(
            String.format(System.Label.Generic_Controller_Request_Failed,
                new List<String>{ ProductCategory.SObjectType.getDescribe().getLabel() }),
            actualMessage,
            'The controller should expose the configured AuraHandledException message.');
    }

    @IsTest
    static void test_deleteRecords_existingRecord_returnsTrue() {
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        ProductCategory recordItem;
        System.runAs(testUser) {
            recordItem = TestDataFactory.createProductCategory(true);
        }
        Boolean wasDeleted = false;
        System.runAs(testUser) {
            Test.startTest();
            wasDeleted = ProductCategoryController.deleteRecords(new List<Id>{ recordItem.Id });
            Test.stopTest();
        }
        System.assertEquals(true, wasDeleted, 'The controller should confirm successful deletion.');
    }

    @IsTest
    static void test_getById_existingRecord_returnsRecord() {
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        ProductCategory recordItem = [SELECT Id FROM ProductCategory LIMIT 1];
        ProductCategory loadedRecord;
        System.runAs(testUser) {
            Test.startTest();
            loadedRecord = ProductCategoryController.getById(recordItem.Id);
            Test.stopTest();
        }
        System.assertEquals(recordItem.Id, loadedRecord.Id,
            'The controller should return the requested record.');
    }

    @IsTest
    static void test_getByIds_existingRecords_returnsRecords() {
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        List<ProductCategory> existingRecords = [SELECT Id FROM ProductCategory LIMIT 1];
        List<Id> recordIds = new List<Id>{ existingRecords[0].Id };
        List<ProductCategory> loadedRecords;
        System.runAs(testUser) {
            Test.startTest();
            loadedRecords = ProductCategoryController.getByIds(recordIds);
            Test.stopTest();
        }
        System.assertEquals(1, loadedRecords.size(),
            'The controller should return the requested records.');
        System.assertEquals(existingRecords[0].Id, loadedRecords[0].Id,
            'The controller should return the correct record.');
    }
    */
}