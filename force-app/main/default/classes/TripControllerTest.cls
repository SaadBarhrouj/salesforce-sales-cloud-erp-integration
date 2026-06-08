@isTest
private class TripControllerTest {

    private static final String GEOMETRY_JSON =
        '{"bin_data":{"id":"Van","w":180,"h":180,"d":300},"items":[{"id":"Palette","coordinates":{"x1":0,"y1":0,"z1":0,"x2":120,"y2":100,"z2":80}}]}';

    private static Id seedOpportunityWithTrip() {
        Pricebook2 pb = TestDataFactory.createPricebook2('Test PB', true, true);
        Account acc = TestDataFactory.createAccount(true);
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Pricebook2Id = pb.Id
        );
        insert opp;

        Product2 prod = TestDataFactory.createProduct2(true);
        PricebookEntry stdPbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(), Product2Id = prod.Id,
            UnitPrice = 100, IsActive = true, UseStandardPrice = false
        );
        insert stdPbe;
        TestDataFactory.createPricebookEntry(pb.Id, prod.Id, 100, true, true);

        List<Map<String, Object>> lineItems = new List<Map<String, Object>>{
            new Map<String, Object>{ 'product2Id' => prod.Id, 'quantity' => 1, 'unitPrice' => 100, 'discountPercent' => 0 }
        };
        Map<String, Object> logistics = new Map<String, Object>{
            'trips' => new List<Object>{
                new Map<String, Object>{
                    'truckType' => 'Van', 'distanceKm' => 150.5, 'systemPrice' => 2000,
                    'finalPrice' => 2000, 'direction' => 'Delivery', 'tripDate' => Date.today(),
                    'packingGeometry' => GEOMETRY_JSON
                }
            }
        };
        OpportunityService.saveOpportunityWithLines(opp.Id, lineItems, logistics);
        return opp.Id;
    }

    @isTest
    static void getPackingGeometry_opportunity_returnsFleetArray() {
        Id oppId = seedOpportunityWithTrip();

        Test.startTest();
        String result = TripController.getPackingGeometry(oppId, 'Opportunity');
        Test.stopTest();

        Assert.areEqual('[' + GEOMETRY_JSON + ']', result, 'Opportunity context returns each trip geometry in an array');
    }

    @isTest
    static void getPackingGeometry_trip_returnsSingleArray() {
        Id oppId = seedOpportunityWithTrip();
        Trip__c trip = [SELECT Id FROM Trip__c WHERE Opportunity__c = :oppId LIMIT 1];

        Test.startTest();
        String result = TripController.getPackingGeometry(trip.Id, 'Trip__c');
        Test.stopTest();

        Assert.areEqual('[' + GEOMETRY_JSON + ']', result, 'Trip context returns that single trip geometry in an array');
    }

    @isTest
    static void getPackingGeometry_noGeometry_returnsEmptyArray() {
        Pricebook2 pb = TestDataFactory.createPricebook2('Test PB', true, true);
        Account acc = TestDataFactory.createAccount(true);
        Opportunity opp = new Opportunity(
            Name = 'Empty Opp', AccountId = acc.Id, StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30), Pricebook2Id = pb.Id
        );
        insert opp;

        Test.startTest();
        String result = TripController.getPackingGeometry(opp.Id, 'Opportunity');
        Test.stopTest();

        Assert.areEqual('[]', result, 'An opportunity with no trips returns an empty array');
    }
}
