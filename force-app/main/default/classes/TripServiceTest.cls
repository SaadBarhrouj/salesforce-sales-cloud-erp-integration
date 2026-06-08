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

    private static Map<String, BinPackingAPI.BinRequest> binMap() {
        BinPackingAPI.BinRequest b = new BinPackingAPI.BinRequest();
        b.id = 'TRUCK_A';
        b.w = 240; b.h = 240; b.d = 600;
        b.max_wg = 10000; b.q = 5;
        return new Map<String, BinPackingAPI.BinRequest>{ 'TRUCK_A' => b };
    }

    @isTest
    static void priceSolution_mapsBinDataToTrip() {
        String json = '{"response":{"bins_packed":[{'
            + '"bin_data":{"id":"TRUCK_A","used_weight":1200,"weight":8000},'
            + '"image_complete":"https://eu.api.3dbinpacking.com/images/abc.svg"}]}}';

        Test.startTest();
        TripService.PricedSolution sol = TripService.priceSolution(
            json, rateMap(), binMap(), 100, zone(), FAKE_OPP_ID, 'Delivery');
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
            json, rateMap(), binMap(), 100, zone(), FAKE_OPP_ID, 'Delivery');
        Test.stopTest();

        Assert.isNotNull(sol, 'Partial packs remain valid (permissive parity)');
        Assert.areEqual(1, sol.trips.size(), 'not_packed_items must not block pricing');
    }

    @isTest
    static void priceSolution_emptyBins_returnsNull() {
        String json = '{"response":{"bins_packed":[]}}';

        Test.startTest();
        TripService.PricedSolution sol = TripService.priceSolution(
            json, rateMap(), binMap(), 100, zone(), FAKE_OPP_ID, 'Delivery');
        Test.stopTest();

        Assert.isNull(sol, 'No packed bins -> no priceable solution');
    }

    @isTest
    static void priceSolution_unknownTruck_returnsNull() {
        String json = '{"response":{"bins_packed":[{"bin_data":{"id":"TRUCK_UNKNOWN","used_weight":1}}]}}';

        Test.startTest();
        TripService.PricedSolution sol = TripService.priceSolution(
            json, rateMap(), binMap(), 100, zone(), FAKE_OPP_ID, 'Delivery');
        Test.stopTest();

        Assert.isNull(sol, 'A bin whose truck has no rate makes the whole scenario unpriceable');
    }

    @isTest
    static void priceSolution_capturesPackingGeometry() {
        String responseJson = '{"response":{"bins_packed":[{'
            + '"bin_data":{"id":"TRUCK_A","used_weight":500,"used_space":33.3},'
            + '"items":[{"id":"Palette","coordinates":{"x1":0,"y1":0,"z1":0,"x2":120,"y2":100,"z2":80}}]'
            + '}]}}';

        Test.startTest();
        TripService.PricedSolution sol = TripService.priceSolution(
            responseJson, rateMap(), binMap(), 100, zone(), FAKE_OPP_ID, 'Delivery');
        Test.stopTest();

        Assert.isNotNull(sol, 'A packed bin with items should price');
        Trip__c t = sol.trips[0];
        Assert.isNotNull(t.Packing_Geometry__c, 'Geometry JSON should be captured for the viewer');

        Map<String, Object> geo = (Map<String, Object>) JSON.deserializeUntyped(t.Packing_Geometry__c);
        Map<String, Object> bd = (Map<String, Object>) geo.get('bin_data');
        Assert.areEqual('TRUCK_A', (String) bd.get('id'), 'bin id captured');
        Assert.areEqual('240', String.valueOf(bd.get('w')), 'bin width comes from the truck template');
        List<Object> items = (List<Object>) geo.get('items');
        Assert.areEqual(1, items.size(), 'One packed item captured with coordinates');
    }

    @isTest
    static void priceSolution_noItems_geometryIsNull() {
        String json = '{"response":{"bins_packed":[{"bin_data":{"id":"TRUCK_A","used_weight":500}}]}}';

        Test.startTest();
        TripService.PricedSolution sol = TripService.priceSolution(
            json, rateMap(), binMap(), 100, zone(), FAKE_OPP_ID, 'Delivery');
        Test.stopTest();

        Assert.isNotNull(sol, 'Still priceable without geometry');
        Assert.isNull(sol.trips[0].Packing_Geometry__c, 'No items -> no geometry stored');
    }
}
