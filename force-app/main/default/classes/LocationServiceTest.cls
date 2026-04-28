/**
 * @description Test class for LocationService.
 */
@IsTest
private class LocationServiceTest {

    @IsTest
    static void getLocationsByAccountFormattedNullIdReturnsEmptyList() {
        List<Map<String, Object>> result = LocationService.getLocationsByAccountFormatted(null);
        System.assertNotEquals(null, result, 'Should return empty list, not null');
        System.assertEquals(0, result.size(), 'Should return empty list for null accountId');
    }

    @IsTest
    static void getLocationsByAccountFormattedReturnsFormattedLocations() {
        Account acc = TestDataFactory.createAccount(true);
        Schema.Location loc = new Schema.Location(
            Name = 'Test Location',
            LocationType = 'Warehouse',
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
        List<Map<String, Object>> result = LocationService.getLocationsByAccountFormatted(acc.Id);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should return one location');
        Map<String, Object> formatted = result[0];
        System.assertEquals(loc.Id, formatted.get('value'), 'Value should be location Id');
        System.assertEquals('Test Location', formatted.get('label'), 'Label should be location name');
        System.assertEquals('Test Location', formatted.get('Name'), 'Name field should be included');
    }

    @IsTest
    static void getLocationsByAccountFormattedIncludesGeoData() {
        Account acc = TestDataFactory.createAccount(true);
        Schema.Location loc = new Schema.Location(
            Name = 'Geo Location',
            LocationType = 'Site',
            Country_Code__c = 'FR',
            Latitude = 48.8566,
            Longitude = 2.3522,
            TimeZone = 'Europe/Paris'
        );
        insert loc;
        
        AssociatedLocation assoc = new AssociatedLocation(
            ParentRecordId = acc.Id,
            LocationId = loc.Id,
            ActiveFrom = Date.today()
        );
        insert assoc;

        Test.startTest();
        List<Map<String, Object>> result = LocationService.getLocationsByAccountFormatted(acc.Id);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should return location');
        Map<String, Object> formatted = result[0];
        System.assertEquals(48.8566, formatted.get('Latitude'), 'Latitude should be included');
        System.assertEquals(2.3522, formatted.get('Longitude'), 'Longitude should be included');
        System.assertEquals('Site', formatted.get('LocationType'), 'LocationType should be included');
        System.assertEquals('Europe/Paris', formatted.get('TimeZone'), 'TimeZone should be included');
    }

    @IsTest
    static void getLocationsByAccountFormattedNoLocationsReturnsEmptyList() {
        Account acc = TestDataFactory.createAccount(true);

        Test.startTest();
        List<Map<String, Object>> result = LocationService.getLocationsByAccountFormatted(acc.Id);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Should return empty list');
    }

    @IsTest
    static void getAgenciesFormattedReturnsAgencies() {
        Schema.Location warehouse = new Schema.Location(
            Name = 'Test Warehouse',
            LocationType = 'Warehouse',
            Country_Code__c = 'US'
        );
        insert warehouse;

        Test.startTest();
        List<Map<String, Object>> result = LocationService.getAgenciesFormatted();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return list');
        System.assertEquals(1, result.size(), 'Should return one warehouse');
    }

    @IsTest
    static void getAgenciesFormattedNoWarehousesReturnsEmptyList() {
        Test.startTest();
        List<Map<String, Object>> result = LocationService.getAgenciesFormatted();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return list, not null');
    }

    @IsTest
    static void formatLocationsForUINullInputReturnsEmptyList() {
        Test.startTest();
        List<Map<String, Object>> result = LocationService.getLocationsByAccountFormatted(null);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return empty list for null input');
        System.assertEquals(0, result.size(), 'Should be empty');
    }

    @IsTest
    static void formatLocationsForUIMultipleLocationsSorted() {
        Account acc = TestDataFactory.createAccount(true);
        
        Schema.Location loc1 = new Schema.Location(
            Name = 'Zebra Site',
            LocationType = 'Site',
            Country_Code__c = 'US'
        );
        insert loc1;
        
        Schema.Location loc2 = new Schema.Location(
            Name = 'Alpha Site',
            LocationType = 'Site',
            Country_Code__c = 'FR'
        );
        insert loc2;

        AssociatedLocation assoc1 = new AssociatedLocation(
            ParentRecordId = acc.Id,
            LocationId = loc1.Id,
            ActiveFrom = Date.today()
        );
        insert assoc1;
        
        AssociatedLocation assoc2 = new AssociatedLocation(
            ParentRecordId = acc.Id,
            LocationId = loc2.Id,
            ActiveFrom = Date.today()
        );
        insert assoc2;

        Test.startTest();
        List<Map<String, Object>> result = LocationService.getLocationsByAccountFormatted(acc.Id);
        Test.stopTest();

        System.assertEquals(2, result.size(), 'Should return two locations');
        System.assertEquals('Alpha Site', result[0].get('label'), 'Should be sorted by name ASC');
        System.assertEquals('Zebra Site', result[1].get('label'), 'Second should be Zebra');
    }

    @IsTest
    static void getLocationsByAccountWithExpiredLocationExcluded() {
        Account acc = TestDataFactory.createAccount(true);
        Schema.Location loc = new Schema.Location(
            Name = 'Expired Location',
            LocationType = 'Warehouse',
            Country_Code__c = 'US'
        );
        insert loc;
        
        AssociatedLocation assoc = new AssociatedLocation(
            ParentRecordId = acc.Id,
            LocationId = loc.Id,
            ActiveFrom = Date.today().addDays(-365),
            ActiveTo = Date.today().addDays(-1)
        );
        insert assoc;

        Test.startTest();
        List<Map<String, Object>> result = LocationService.getLocationsByAccountFormatted(acc.Id);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Expired locations should be excluded');
    }

    @IsTest
    static void getLocationsByAccountWithFutureStartDateExcluded() {
        Account acc = TestDataFactory.createAccount(true);
        Schema.Location loc = new Schema.Location(
            Name = 'Future Location',
            LocationType = 'Warehouse',
            Country_Code__c = 'US'
        );
        insert loc;
        
        AssociatedLocation assoc = new AssociatedLocation(
            ParentRecordId = acc.Id,
            LocationId = loc.Id,
            ActiveFrom = Date.today().addDays(30),
            ActiveTo = null
        );
        insert assoc;

        Test.startTest();
        List<Map<String, Object>> result = LocationService.getLocationsByAccountFormatted(acc.Id);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Future start date locations should be excluded');
    }

    @IsTest
    static void getLocationsByAccountWithActiveFromNullIncludesLocation() {
        Account acc = TestDataFactory.createAccount(true);
        Schema.Location loc = new Schema.Location(
            Name = 'No Date Location',
            LocationType = 'Warehouse',
            Country_Code__c = 'US'
        );
        insert loc;
        
        AssociatedLocation assoc = new AssociatedLocation(
            ParentRecordId = acc.Id,
            LocationId = loc.Id,
            ActiveFrom = null,
            ActiveTo = null
        );
        insert assoc;

        Test.startTest();
        List<Map<String, Object>> result = LocationService.getLocationsByAccountFormatted(acc.Id);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Null ActiveFrom should include location');
    }

    @IsTest
    static void getAgenciesFormattedFiltersByWarehouseType() {
        Schema.Location warehouse = new Schema.Location(
            Name = 'Agency Warehouse',
            LocationType = 'Warehouse',
            Country_Code__c = 'US'
        );
        insert warehouse;
        
        Schema.Location site = new Schema.Location(
            Name = 'Site Location',
            LocationType = 'Site',
            Country_Code__c = 'US'
        );
        insert site;

        Test.startTest();
        List<Map<String, Object>> result = LocationService.getAgenciesFormatted();
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should return only warehouses');
        System.assertEquals('Warehouse', result[0].get('LocationType'), 'Should be warehouse type');
    }
}