/**
 * @description Test class for PricebookService.
 */
@IsTest
private class PricebookServiceTest {

    @IsTest
    static void calculatePricesPricebookMethodReturnsResponses() {
        Pricebook2 pb = TestDataFactory.createPricebook2('Test PB', true, true);
        Product2 prod1 = TestDataFactory.createProduct2(true);
        Product2 prod2 = TestDataFactory.createProduct2(true);
        PricebookEntry stdPbe1 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = prod1.Id, UnitPrice = 100, IsActive = true, UseStandardPrice = false);
        insert stdPbe1;
        PricebookEntry stdPbe2 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = prod2.Id, UnitPrice = 100, IsActive = true, UseStandardPrice = false);
        insert stdPbe2;
        TestDataFactory.createPricebookEntry(pb.Id, prod1.Id, 100, true, true);
        TestDataFactory.createPricebookEntry(pb.Id, prod2.Id, 200, true, true);

        List<Map<String, Object>> lineItems = new List<Map<String, Object>>{
            new Map<String, Object>{ 'productId' => prod1.Id, 'quantity' => 2, 'discount' => 10 },
            new Map<String, Object>{ 'productId' => prod2.Id, 'quantity' => 1, 'discount' => 0 }
        };

        List<PricingResponse> responses = PricebookService.calculatePrices(lineItems, 'Pricebook', pb.Id);

        System.assertEquals(2, responses.size(), 'Should return two responses');
        System.assertEquals(true, responses[0].success, 'First response should succeed');
        System.assertEquals(100, responses[0].listPrice, 'First listPrice should match');
        System.assertEquals(180.00, responses[0].totalPrice, 'First totalPrice should be 90 * 2');
        System.assertEquals(true, responses[1].success, 'Second response should succeed');
        System.assertEquals(200, responses[1].listPrice, 'Second listPrice should match');
    }

    @IsTest
    static void calculatePricesVolumePricingMethodReturnsResponses() {
        Pricebook2 pb = TestDataFactory.createPricebook2('Test PB', true, true);
        Product2 prod = TestDataFactory.createProduct2(true);
        PricebookEntry stdPbe = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = prod.Id, UnitPrice = 100, IsActive = true, UseStandardPrice = false);
        insert stdPbe;

        Volume_Pricing_Schedule__c schedule = TestDataFactory.createVolumePricingSchedule(prod.Id, pb.Id, 'Tiered', true, true);
        TestDataFactory.createVolumePricingTier(schedule.Id, 1, 10, 80, 1, true);

        List<Map<String, Object>> lineItems = new List<Map<String, Object>>{
            new Map<String, Object>{ 'productId' => prod.Id, 'quantity' => 5, 'discount' => 0 }
        };

        List<PricingResponse> responses = PricebookService.calculatePrices(lineItems, 'VolumePricing', pb.Id);

        System.assertEquals(1, responses.size(), 'Should return one response');
        System.assertEquals(true, responses[0].success, 'Response should succeed');
        System.assertEquals(80, responses[0].listPrice, 'Tier price should match');
        System.assertEquals('Tiered', responses[0].pricingMethod, 'Method should be Tiered');
    }

    @IsTest
    static void calculateByPricebookValidReturnsSuccess() {
        Pricebook2 pb = TestDataFactory.createPricebook2('Test PB', true, true);
        Product2 prod = TestDataFactory.createProduct2(true);
        PricebookEntry stdPbe = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = prod.Id, UnitPrice = 100, IsActive = true, UseStandardPrice = false);
        insert stdPbe;
        TestDataFactory.createPricebookEntry(pb.Id, prod.Id, 100, true, true);

        PricingResponse response = PricebookService.calculateByPricebook(prod.Id, pb.Id, 2, 10);

        System.assertEquals(true, response.success, 'Should succeed');
        System.assertEquals(100, response.listPrice, 'List price should match');
        System.assertEquals(90.00, response.netPrice, 'Net price should be 100 * 0.9');
        System.assertEquals(180.00, response.totalPrice, 'Total price should be 90 * 2');
        System.assertEquals('Pricebook', response.pricingMethod, 'Method should be Pricebook');
    }

    @IsTest
    static void calculateByPricebookNullEntryReturnsError() {
        Pricebook2 pb = TestDataFactory.createPricebook2('Test PB', true, true);
        Product2 prod = TestDataFactory.createProduct2(true);

        PricingResponse response = PricebookService.calculateByPricebook(prod.Id, pb.Id, 1, 0);

        System.assertEquals(false, response.success, 'Should fail');
        System.assert(response.errorMessage.contains('Pricebook entry not found'), 'Error should indicate missing entry');
    }

    @IsTest
    static void calculateByPricebookInvalidDiscountReturnsError() {
        PricingResponse response = PricebookService.calculateByPricebook(null, null, 1, 101);

        System.assertEquals(false, response.success, 'Should fail');
        System.assert(response.errorMessage.contains('Discount must be between 0 and 100'), 'Error should indicate invalid discount');
    }

    @IsTest
    static void calculateByPricebookInvalidQuantityReturnsError() {
        PricingResponse response = PricebookService.calculateByPricebook(null, null, 0, 0);

        System.assertEquals(false, response.success, 'Should fail');
        System.assert(response.errorMessage.contains('Quantity must be at least 1'), 'Error should indicate invalid quantity');
    }

    @IsTest
    static void calculateByVolumePricingTieredReturnsSuccess() {
        Pricebook2 pb = TestDataFactory.createPricebook2('Test PB', true, true);
        Product2 prod = TestDataFactory.createProduct2(true);
        PricebookEntry stdPbe = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = prod.Id, UnitPrice = 100, IsActive = true, UseStandardPrice = false);
        insert stdPbe;

        Volume_Pricing_Schedule__c schedule = TestDataFactory.createVolumePricingSchedule(prod.Id, pb.Id, 'Tiered', true, true);
        TestDataFactory.createVolumePricingTier(schedule.Id, 1, 10, 80, 1, true);

        PricingResponse response = PricebookService.calculateByVolumePricing(prod.Id, pb.Id, 5, 5);

        System.assertEquals(true, response.success, 'Should succeed');
        System.assertEquals(80, response.listPrice, 'Tier price should match');
        System.assertEquals(76.00, response.netPrice, 'Net price should be 80 * 0.95');
        System.assertEquals(380.00, response.totalPrice, 'Total price should be 76 * 5');
        System.assertEquals('Tiered', response.pricingMethod, 'Method should be Tiered');
    }

    @IsTest
    static void calculateByVolumePricingBlockReturnsSuccess() {
        Pricebook2 pb = TestDataFactory.createPricebook2('Test PB', true, true);
        Product2 prod = TestDataFactory.createProduct2(true);
        PricebookEntry stdPbe = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = prod.Id, UnitPrice = 100, IsActive = true, UseStandardPrice = false);
        insert stdPbe;

        Volume_Pricing_Schedule__c schedule = TestDataFactory.createVolumePricingSchedule(prod.Id, pb.Id, 'Block', true, true);
        TestDataFactory.createVolumePricingTier(schedule.Id, 1, 10, 500, 1, true);

        PricingResponse response = PricebookService.calculateByVolumePricing(prod.Id, pb.Id, 5, 0);

        System.assertEquals(true, response.success, 'Should succeed');
        System.assertEquals(500, response.listPrice, 'Tier price should match');
        System.assertEquals(500, response.totalPrice, 'Block total should equal netPrice');
        System.assertEquals('Block', response.pricingMethod, 'Method should be Block');
    }

    @IsTest
    static void calculateByVolumePricingNullScheduleReturnsError() {
        Pricebook2 pb = TestDataFactory.createPricebook2('Test PB', true, true);
        Product2 prod = TestDataFactory.createProduct2(true);

        PricingResponse response = PricebookService.calculateByVolumePricing(prod.Id, pb.Id, 1, 0);

        System.assertEquals(false, response.success, 'Should fail');
        System.assert(response.errorMessage.contains('Volume pricing schedule not found'), 'Error should indicate missing schedule');
    }

    @IsTest
    static void calculateByVolumePricingEmptyTiersReturnsError() {
        Pricebook2 pb = TestDataFactory.createPricebook2('Test PB', true, true);
        Product2 prod = TestDataFactory.createProduct2(true);
        PricebookEntry stdPbe = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = prod.Id, UnitPrice = 100, IsActive = true, UseStandardPrice = false);
        insert stdPbe;

        TestDataFactory.createVolumePricingSchedule(prod.Id, pb.Id, 'Tiered', true, true);

        PricingResponse response = PricebookService.calculateByVolumePricing(prod.Id, pb.Id, 1, 0);

        System.assertEquals(false, response.success, 'Should fail');
        System.assert(response.errorMessage.contains('No volume pricing tiers defined'), 'Error should indicate empty tiers');
    }

    @IsTest
    static void calculateByVolumePricingNoMatchNoOverageReturnsError() {
        Pricebook2 pb = TestDataFactory.createPricebook2('Test PB', true, true);
        Product2 prod = TestDataFactory.createProduct2(true);
        PricebookEntry stdPbe = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = prod.Id, UnitPrice = 100, IsActive = true, UseStandardPrice = false);
        insert stdPbe;

        Volume_Pricing_Schedule__c schedule = TestDataFactory.createVolumePricingSchedule(prod.Id, pb.Id, 'Tiered', true, true);
        TestDataFactory.createVolumePricingTier(schedule.Id, 1, 5, 80, 1, true);

        PricingResponse response = PricebookService.calculateByVolumePricing(prod.Id, pb.Id, 10, 0);

        System.assertEquals(false, response.success, 'Should fail');
        System.assert(response.errorMessage.contains('No matching tier for quantity'), 'Error should indicate no matching tier');
    }

    @IsTest
    static void calculateByVolumePricingNoMatchWithOverageReturnsSuccess() {
        Pricebook2 pb = TestDataFactory.createPricebook2('Test PB', true, true);
        Product2 prod = TestDataFactory.createProduct2(true);
        PricebookEntry stdPbe = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = prod.Id, UnitPrice = 100, IsActive = true, UseStandardPrice = false);
        insert stdPbe;

        Volume_Pricing_Schedule__c schedule = TestDataFactory.createVolumePricingSchedule(prod.Id, pb.Id, 'Tiered', true, true);
        schedule.Overage_Rate__c = 50;
        update schedule;
        TestDataFactory.createVolumePricingTier(schedule.Id, 1, 5, 80, 1, true);

        PricingResponse response = PricebookService.calculateByVolumePricing(prod.Id, pb.Id, 10, 0);

        System.assertEquals(true, response.success, 'Should succeed using overage rate');
        System.assertEquals(50, response.listPrice, 'Overage rate should be used');
    }

    @IsTest
    static void calculateByVolumePricingInvalidDiscountReturnsError() {
        PricingResponse response = PricebookService.calculateByVolumePricing(null, null, 1, -1);

        System.assertEquals(false, response.success, 'Should fail');
        System.assert(response.errorMessage.contains('Discount must be between 0 and 100'), 'Error should indicate invalid discount');
    }

    @IsTest
    static void calculateByVolumePricingInvalidQuantityReturnsError() {
        PricingResponse response = PricebookService.calculateByVolumePricing(null, null, 0, 0);

        System.assertEquals(false, response.success, 'Should fail');
        System.assert(response.errorMessage.contains('Quantity must be at least 1'), 'Error should indicate invalid quantity');
    }
}
