/**
 * @description Test class for LocationDAO.
 */
@IsTest
private class LocationDAOTest {

    @IsTest
    static void getLocationsByAccountIdNullReturnsEmptyList() {
        List<Schema.Location> result = LocationDAO.getLocationsByAccountId(null);
        System.assertNotEquals(null, result, 'Should return empty list, not null');
        System.assertEquals(0, result.size(), 'Should return empty list for null accountId');
    }

    @IsTest
    static void getLocationsByAccountIdWithLocationsReturnsLocations() {
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
            ActiveFrom = Date.today(),
            ActiveTo = Date.today().addYears(1)
        );
        insert assoc;

        Test.startTest();
        List<Schema.Location> result = LocationDAO.getLocationsByAccountId(acc.Id);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should return one location');
        System.assertEquals(loc.Id, result[0].Id, 'Location Id should match');
    }

    @IsTest
    static void getLocationsByAccountIdNoLocationsReturnsEmptyList() {
        Account acc = TestDataFactory.createAccount(true);

        Test.startTest();
        List<Schema.Location> result = LocationDAO.getLocationsByAccountId(acc.Id);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Should return empty list when no locations');
    }

    @IsTest
    static void getLocationsByAccountIdFiltersByActiveDate() {
        Account acc = TestDataFactory.createAccount(true);
        Schema.Location loc = new Schema.Location(
            Name = 'Active Location',
            LocationType = 'Warehouse',
            Country_Code__c = 'US'
        );
        insert loc;
        
        AssociatedLocation assoc = new AssociatedLocation(
            ParentRecordId = acc.Id,
            LocationId = loc.Id,
            ActiveFrom = Date.today().addDays(-30),
            ActiveTo = Date.today().addDays(-1)
        );
        insert assoc;

        Test.startTest();
        List<Schema.Location> result = LocationDAO.getLocationsByAccountId(acc.Id);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Should not return expired locations');
    }

    @IsTest
    static void getLocationsByTypeNullReturnsEmptyList() {
        List<Schema.Location> result = LocationDAO.getLocationsByType(null);
        System.assertNotEquals(null, result, 'Should return empty list, not null');
        System.assertEquals(0, result.size(), 'Should return empty list for null locationType');
    }

    @IsTest
    static void getLocationsByTypeWithLocationsReturnsLocations() {
        Schema.Location loc1 = new Schema.Location(
            Name = 'Warehouse A',
            LocationType = 'Warehouse',
            Country_Code__c = 'US'
        );
        insert loc1;
        
        Schema.Location loc2 = new Schema.Location(
            Name = 'Warehouse B',
            LocationType = 'Warehouse',
            Country_Code__c = 'FR'
        );
        insert loc2;

        Test.startTest();
        List<Schema.Location> result = LocationDAO.getLocationsByType('Warehouse');
        Test.stopTest();

        System.assertEquals(2, result.size(), 'Should return two warehouses');
        System.assertEquals('Warehouse A', result[0].Name, 'Should be sorted by name');
    }

    @IsTest
    static void getLocationsByTypeNoMatchReturnsEmptyList() {
        Schema.Location loc = new Schema.Location(
            Name = 'Site Location',
            LocationType = 'Site',
            Country_Code__c = 'US'
        );
        insert loc;

        Test.startTest();
        List<Schema.Location> result = LocationDAO.getLocationsByType('Warehouse');
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Should return empty list when no matching type');
    }

    @IsTest
    static void getLocationsByTypeReturnsSortedByName() {
        Schema.Location loc1 = new Schema.Location(
            Name = 'Zebra Warehouse',
            LocationType = 'Warehouse',
            Country_Code__c = 'US'
        );
        insert loc1;
        
        Schema.Location loc2 = new Schema.Location(
            Name = 'Alpha Warehouse',
            LocationType = 'Warehouse',
            Country_Code__c = 'FR'
        );
        insert loc2;

        Test.startTest();
        List<Schema.Location> result = LocationDAO.getLocationsByType('Warehouse');
        Test.stopTest();

        System.assertEquals(2, result.size(), 'Should return both locations');
        System.assertEquals('Alpha Warehouse', result[0].Name, 'First should be Alpha (sorted ASC)');
        System.assertEquals('Zebra Warehouse', result[1].Name, 'Second should be Zebra');
    }

    @IsTest
    static void getLocationsByAccountIdIncludesLocationFields() {
        Account acc = TestDataFactory.createAccount(true);
        Schema.Location loc = new Schema.Location(
            Name = 'Test Location',
            LocationType = 'Warehouse',
            Country_Code__c = 'US',
            Latitude = 40.7128,
            Longitude = -74.0060,
            TimeZone = 'America/New_York'
        );
        insert loc;
        
        AssociatedLocation assoc = new AssociatedLocation(
            ParentRecordId = acc.Id,
            LocationId = loc.Id,
            ActiveFrom = Date.today()
        );
        insert assoc;

        Test.startTest();
        List<Schema.Location> result = LocationDAO.getLocationsByAccountId(acc.Id);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should return location');
        System.assertEquals('Warehouse', result[0].LocationType, 'LocationType should be included');
        System.assertEquals(40.7128, result[0].Latitude, 'Latitude should be included');
        System.assertEquals(-74.0060, result[0].Longitude, 'Longitude should be included');
    }
}