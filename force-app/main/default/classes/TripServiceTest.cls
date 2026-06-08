@isTest
private class TripServiceTest {

    private static final Id FAKE_OPP_ID = '006000000000001AAA';

    private static Map<String, Transport_Rate__mdt> rateMap() {
        Transport_Rate__mdt rate = new Transport_Rate__mdt(
            Truck_Code__c         = 'TRUCK_A',
            Country_Code__c       = 'MA',
            Zone_Code__c          = 'Z1',
            Base_Price__c         = 100,
            Included_Km__c        = 50,
            Price_Per_Extra_Km__c = 2,
            Minimum_Price__c      = 80,
            Currency_Code__c      = 'MAD'
        );
        return new Map<String, Transport_Rate__mdt>{ 'TRUCK_A' => rate };
    }

    private static Transport_Zone__mdt zone() {
        return new Transport_Zone__mdt(Zone_Code__c = 'Z1', Country_Code__c = 'MA');
    }

    @isTest
    static void priceSolution_mapsBinDataToTrip() {
        String json = '{"response":{"bins_packed":[{'
            + '"bin_data":{"id":"TRUCK_A","used_weight":1200,"weight":8000},'
            + '"image_complete":"https://eu.api.3dbinpacking.com/images/abc.svg"}]}}';

        Test.startTest();
        TripService.PricedSolution sol = TripService.priceSolution(
            json, rateMap(), 100, zone(), FAKE_OPP_ID, 'Delivery');
        Test.stopTest();

        Assert.isNotNull(sol, 'A packed bin with a known rate should price');
        Assert.areEqual(1, sol.trips.size(), 'One packed bin -> one trip');
        Trip__c t = sol.trips[0];
        Assert.areEqual('TRUCK_A', t.Truck_Type__c, 'bin_data.id maps to truck code');
        Assert.areEqual(8000, t.Total_Weight_Kg__c, 'weight (total packed-item weight) maps to loaded weight');
        Assert.areEqual('https://eu.api.3dbinpacking.com/images/abc.svg', t.Bin_Visualization_URL__c,
            'image_complete maps to the visualization URL');
        Assert.areEqual(200, t.System_Price__c, 'Price uses base + extra-km over the included distance');
        Assert.areEqual('Delivery', t.Direction__c, 'Direction is stamped through');
    }

    @isTest
    static void priceSolution_partialPack_isStillPriced() {
        String json = '{"response":{"bins_packed":[{"bin_data":{"id":"TRUCK_A","used_weight":500}}],'
            + '"not_packed_items":[{"id":"ITEM_X"}]}}';

        Test.startTest();
        TripService.PricedSolution sol = TripService.priceSolution(
            json, rateMap(), 100, zone(), FAKE_OPP_ID, 'Delivery');
        Test.stopTest();

        Assert.isNotNull(sol, 'Partial packs remain valid (permissive parity)');
        Assert.areEqual(1, sol.trips.size(), 'not_packed_items must not block pricing');
    }

    @isTest
    static void priceSolution_emptyBins_returnsNull() {
        String json = '{"response":{"bins_packed":[]}}';

        Test.startTest();
        TripService.PricedSolution sol = TripService.priceSolution(
            json, rateMap(), 100, zone(), FAKE_OPP_ID, 'Delivery');
        Test.stopTest();

        Assert.isNull(sol, 'No packed bins -> no priceable solution');
    }

    @isTest
    static void priceSolution_unknownTruck_returnsNull() {
        String json = '{"response":{"bins_packed":[{"bin_data":{"id":"TRUCK_UNKNOWN","used_weight":1}}]}}';

        Test.startTest();
        TripService.PricedSolution sol = TripService.priceSolution(
            json, rateMap(), 100, zone(), FAKE_OPP_ID, 'Delivery');
        Test.stopTest();

        Assert.isNull(sol, 'A bin whose truck has no rate makes the whole scenario unpriceable');
    }
}
