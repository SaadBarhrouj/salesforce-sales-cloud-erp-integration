/**
 * @description Test class for PricebookController.
 */
@IsTest
private class PricebookControllerTest {

    @IsTest
    static void calculateLinePricesNullReturnsEmptyList() {
        List<PricingResponse> responses = PricebookController.calculateLinePrices(null, null, null);
        System.assertNotEquals(null, responses, 'Should return empty list, not null');
        System.assertEquals(0, responses.size(), 'Should return empty list for null input');
    }

    @IsTest
    static void calculateLinePricesEmptyReturnsEmptyList() {
        List<PricingResponse> responses = PricebookController.calculateLinePrices(new List<Map<String, Object>>(), null, null);
        System.assertNotEquals(null, responses, 'Should return empty list, not null');
        System.assertEquals(0, responses.size(), 'Should return empty list for empty input');
    }

    @IsTest
    static void calculateLinePricesValidPricebookReturnsResponses() {
        Pricebook2 pb = TestDataFactory.createPricebook2('Test PB', true, true);
        Product2 prod = TestDataFactory.createProduct2(true);
        PricebookEntry stdPbe = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = prod.Id, UnitPrice = 100, IsActive = true, UseStandardPrice = false);
        insert stdPbe;
        TestDataFactory.createPricebookEntry(pb.Id, prod.Id, 100, true, true);

        List<Map<String, Object>> lineItems = new List<Map<String, Object>>{
            new Map<String, Object>{ 'productId' => prod.Id, 'quantity' => 1, 'discount' => 0 }
        };

        List<PricingResponse> responses = PricebookController.calculateLinePrices(lineItems, null, pb.Id);

        System.assertEquals(1, responses.size(), 'Should return one response');
        System.assertEquals(true, responses[0].success, 'Response should succeed');
        System.assertEquals(100, responses[0].listPrice, 'List price should match');
    }

    @IsTest
    static void calculateLinePricesInvalidProductIdReturnsErrorResponses() {
        List<Map<String, Object>> lineItems = new List<Map<String, Object>>{
            new Map<String, Object>{ 'productId' => 'invalid-id-string', 'quantity' => 1, 'discount' => 0 }
        };

        List<PricingResponse> responses = PricebookController.calculateLinePrices(lineItems, null, null);

        System.assertEquals(1, responses.size(), 'Should return one error response');
        System.assertEquals(false, responses[0].success, 'Response should indicate failure');
        System.assertNotEquals(null, responses[0].errorMessage, 'Error message should be populated');
    }

    @IsTest
    static void getPricingMethodNullReturnsPricebook() {
        Pricebook2 pb = TestDataFactory.createPricebook2('Test PB', true, true);
        Product2 prod = TestDataFactory.createProduct2(true);
        PricebookEntry stdPbe = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = prod.Id, UnitPrice = 100, IsActive = true, UseStandardPrice = false);
        insert stdPbe;
        TestDataFactory.createPricebookEntry(pb.Id, prod.Id, 100, true, true);

        List<Map<String, Object>> lineItems = new List<Map<String, Object>>{
            new Map<String, Object>{ 'productId' => prod.Id, 'quantity' => 1, 'discount' => 0 }
        };
        List<PricingResponse> responses = PricebookController.calculateLinePrices(lineItems, null, pb.Id);
        System.assertEquals(true, responses[0].success, 'Should use Pricebook method for null offerType');
    }

    @IsTest
    static void getPricingMethodBlankReturnsPricebook() {
        Pricebook2 pb = TestDataFactory.createPricebook2('Test PB', true, true);
        Product2 prod = TestDataFactory.createProduct2(true);
        PricebookEntry stdPbe = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = prod.Id, UnitPrice = 100, IsActive = true, UseStandardPrice = false);
        insert stdPbe;
        TestDataFactory.createPricebookEntry(pb.Id, prod.Id, 100, true, true);

        List<Map<String, Object>> lineItems = new List<Map<String, Object>>{
            new Map<String, Object>{ 'productId' => prod.Id, 'quantity' => 1, 'discount' => 0 }
        };
        List<PricingResponse> responses = PricebookController.calculateLinePrices(lineItems, '', pb.Id);
        System.assertEquals(true, responses[0].success, 'Should use Pricebook method for blank offerType');
    }

    @IsTest
    static void getPricingMethodVolumeCatalogReturnsVolumePricing() {
        Pricebook2 pb = TestDataFactory.createPricebook2('Test PB', true, true);
        Product2 prod = TestDataFactory.createProduct2(true);
        PricebookEntry stdPbe = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = prod.Id, UnitPrice = 100, IsActive = true, UseStandardPrice = false);
        insert stdPbe;

        Volume_Pricing_Schedule__c schedule = TestDataFactory.createVolumePricingSchedule(prod.Id, pb.Id, 'Tiered', true, true);
        TestDataFactory.createVolumePricingTier(schedule.Id, 1, 10, 80, 1, true);

        ProductCatalog catalog = TestDataFactory.createProductCatalog('Rental', true);

        List<Map<String, Object>> lineItems = new List<Map<String, Object>>{
            new Map<String, Object>{ 'productId' => prod.Id, 'quantity' => 5, 'discount' => 0 }
        };

        List<PricingResponse> responses = PricebookController.calculateLinePrices(lineItems, catalog.Id, pb.Id);

        System.assertEquals(1, responses.size(), 'Should return one response');
        System.assertEquals(true, responses[0].success, 'Response should succeed');
        System.assertEquals(80, responses[0].listPrice, 'Volume price should match');
        System.assertEquals('Tiered', responses[0].pricingMethod, 'Method should be VolumePricing Tiered');
    }

    @IsTest
    static void getPricingMethodRegularCatalogReturnsPricebook() {
        Pricebook2 pb = TestDataFactory.createPricebook2('Test PB', true, true);
        Product2 prod = TestDataFactory.createProduct2(true);
        PricebookEntry stdPbe = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = prod.Id, UnitPrice = 100, IsActive = true, UseStandardPrice = false);
        insert stdPbe;
        TestDataFactory.createPricebookEntry(pb.Id, prod.Id, 100, true, true);

        ProductCatalog catalog = TestDataFactory.createProductCatalog('Regular Catalog', true);

        List<Map<String, Object>> lineItems = new List<Map<String, Object>>{
            new Map<String, Object>{ 'productId' => prod.Id, 'quantity' => 1, 'discount' => 0 }
        };

        List<PricingResponse> responses = PricebookController.calculateLinePrices(lineItems, catalog.Id, pb.Id);

        System.assertEquals(1, responses.size(), 'Should return one response');
        System.assertEquals(true, responses[0].success, 'Response should succeed');
        System.assertEquals(100, responses[0].listPrice, 'Pricebook price should match');
        System.assertEquals('Pricebook', responses[0].pricingMethod, 'Method should be Pricebook');
    }
}