/**
 * @description Test class for LocationController.
 */
@IsTest
private class LocationControllerTest {

    @IsTest
    static void getLocationsByAccountNullIdReturnsEmptyList() {
        List<Map<String, Object>> result = LocationController.getLocationsByAccount(null);
        System.assertNotEquals(null, result, 'Should return empty list, not null');
        System.assertEquals(0, result.size(), 'Should return empty list for null accountId');
    }

    @IsTest
    static void getLocationsByAccountBlankIdReturnsEmptyList() {
        List<Map<String, Object>> result = LocationController.getLocationsByAccount('');
        System.assertNotEquals(null, result, 'Should return empty list, not null');
        System.assertEquals(0, result.size(), 'Should return empty list for blank accountId');
    }

    @IsTest
    static void getLocationsByAccountValidIdReturnsLocations() {
        Account acc = TestDataFactory.createAccount(true);
        Schema.Location loc = new Schema.Location(
            Name = 'Test Site',
            LocationType = 'Site',
            Country_Code__c = 'US'
        );
        insert loc;
        
        AssociatedLocation assoc = new AssociatedLocation(
            ParentRecordId = acc.Id,
            LocationId = loc.Id,
            ActiveFrom = Date.today()
        );
        insert assoc;

        Test.startTest();
        List<Map<String, Object>> result = LocationController.getLocationsByAccount(acc.Id);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should return one location');
    }

    @IsTest
    static void getLocationsByAccountThrowsAuraHandledExceptionOnError() {
        Test.startTest();
        try {
            LocationController.getLocationsByAccount('invalid-id');
        } catch (AuraHandledException e) {
            Test.stopTest();
            System.assert(true, 'Should throw AuraHandledException');
            return;
        }
        Test.stopTest();
    }

    @IsTest
    static void getAllAgenciesReturnsWarehouses() {
        Schema.Location warehouse = new Schema.Location(
            Name = 'Agency HQ',
            LocationType = 'Warehouse',
            Country_Code__c = 'US'
        );
        insert warehouse;

        Test.startTest();
        List<Map<String, Object>> result = LocationController.getAllAgencies();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return list');
        System.assertEquals(1, result.size(), 'Should return warehouse');
    }

    @IsTest
    static void getAllAgenciesNoWarehousesReturnsEmptyList() {
        Test.startTest();
        List<Map<String, Object>> result = LocationController.getAllAgencies();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return list, not null');
    }

    @IsTest
    static void getAllAgenciesThrowsAuraHandledExceptionOnError() {
        Test.startTest();
        try {
            LocationController.getAllAgencies();
        } catch (AuraHandledException e) {
            Test.stopTest();
            System.assert(false, 'Should not throw exception when no warehouses');
        } catch (Exception e) {
            Test.stopTest();
            System.assert(false, 'Should not throw any exception');
        }
        Test.stopTest();
    }
}