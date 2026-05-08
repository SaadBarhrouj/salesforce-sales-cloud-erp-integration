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
        // Tier brackets days 1-10 at $80/day.
        TestDataFactory.createVolumePricingTier(schedule.Id, 1, 10, 80, 1, true);

        Date startDate = Date.newInstance(2026, 6, 1);
        Date endDate = Date.newInstance(2026, 6, 5); // 5 days inclusive
        List<Map<String, Object>> lineItems = new List<Map<String, Object>>{
            new Map<String, Object>{
                'productId' => prod.Id,
                'quantity' => 5,
                'discount' => 0,
                'serviceStartDate' => startDate,
                'serviceEndDate' => endDate
            }
        };

        List<PricingResponse> responses = PricebookService.calculatePrices(lineItems, 'VolumePricing', pb.Id);

        System.assertEquals(1, responses.size(), 'Should return one response');
        System.assertEquals(true, responses[0].success, 'Response should succeed');
        System.assertEquals(80, responses[0].dailyRate, 'Daily rate snapshots tier price');
        System.assertEquals(5, responses[0].serviceDays, 'Inclusive day count');
        System.assertEquals(400, responses[0].listPrice, 'listPrice = dailyRate * days = 80 * 5');
        System.assertEquals(2000, responses[0].totalPrice, 'Tiered total = listPrice * qty = 400 * 5');
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
        // Tier brackets 1-10 days at $80/day.
        TestDataFactory.createVolumePricingTier(schedule.Id, 1, 10, 80, 1, true);

        Date s = Date.newInstance(2026, 6, 1);
        Date e = Date.newInstance(2026, 6, 5); // 5 days inclusive
        PricingResponse response = PricebookService.calculateByVolumePricing(prod.Id, pb.Id, 5, 5, s, e);

        System.assertEquals(true, response.success, 'Should succeed');
        System.assertEquals(80, response.dailyRate, 'Daily rate snapshots tier price');
        System.assertEquals(5, response.serviceDays, 'Inclusive day count');
        System.assertEquals(400, response.listPrice, 'listPrice = dailyRate * days = 80 * 5');
        System.assertEquals(380.00, response.netPrice, 'Net = 400 * (1 - 0.05)');
        System.assertEquals(1900.00, response.totalPrice, 'Total = 380 * qty(5)');
        System.assertEquals('Tiered', response.pricingMethod, 'Method should be Tiered');
    }

    @IsTest
    static void calculateByVolumePricingBlockReturnsSuccess() {
        Pricebook2 pb = TestDataFactory.createPricebook2('Test PB', true, true);
        Product2 prod = TestDataFactory.createProduct2(true);
        PricebookEntry stdPbe = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = prod.Id, UnitPrice = 100, IsActive = true, UseStandardPrice = false);
        insert stdPbe;

        Volume_Pricing_Schedule__c schedule = TestDataFactory.createVolumePricingSchedule(prod.Id, pb.Id, 'Block', true, true);
        // Block tier brackets 1-10 days at $500/day flat-per-period.
        TestDataFactory.createVolumePricingTier(schedule.Id, 1, 10, 500, 1, true);

        Date s = Date.newInstance(2026, 6, 1);
        Date e = Date.newInstance(2026, 6, 5); // 5 days inclusive
        PricingResponse response = PricebookService.calculateByVolumePricing(prod.Id, pb.Id, 5, 0, s, e);

        System.assertEquals(true, response.success, 'Should succeed');
        System.assertEquals(500, response.dailyRate, 'Daily rate snapshots tier price');
        System.assertEquals(2500, response.listPrice, 'listPrice = dailyRate * days = 500 * 5');
        System.assertEquals(2500, response.totalPrice, 'Block total is qty-agnostic, scales with days only');
        System.assertEquals('Block', response.pricingMethod, 'Method should be Block');
    }

    @IsTest
    static void calculateByVolumePricingNullScheduleReturnsError() {
        Pricebook2 pb = TestDataFactory.createPricebook2('Test PB', true, true);
        Product2 prod = TestDataFactory.createProduct2(true);

        Date s = Date.newInstance(2026, 6, 1);
        Date e = Date.newInstance(2026, 6, 1);
        PricingResponse response = PricebookService.calculateByVolumePricing(prod.Id, pb.Id, 1, 0, s, e);

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

        Date s = Date.newInstance(2026, 6, 1);
        Date e = Date.newInstance(2026, 6, 1);
        PricingResponse response = PricebookService.calculateByVolumePricing(prod.Id, pb.Id, 1, 0, s, e);

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
        // Tier brackets 1-5 days; the requested 10-day service period falls outside.
        TestDataFactory.createVolumePricingTier(schedule.Id, 1, 5, 80, 1, true);

        Date s = Date.newInstance(2026, 6, 1);
        Date e = Date.newInstance(2026, 6, 10); // 10 days
        PricingResponse response = PricebookService.calculateByVolumePricing(prod.Id, pb.Id, 1, 0, s, e);

        System.assertEquals(false, response.success, 'Should fail');
        System.assert(response.errorMessage.contains('No matching tier for service days'), 'Error should indicate no matching day-tier');
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

        Date s = Date.newInstance(2026, 6, 1);
        Date e = Date.newInstance(2026, 6, 10); // 10 days, beyond the 1-5 tier
        PricingResponse response = PricebookService.calculateByVolumePricing(prod.Id, pb.Id, 1, 0, s, e);

        System.assertEquals(true, response.success, 'Should succeed using overage rate');
        System.assertEquals(50, response.dailyRate, 'Overage rate is the per-day fallback');
        System.assertEquals(500, response.listPrice, 'listPrice = overageRate * days = 50 * 10');
    }

    @IsTest
    static void calculateByVolumePricingInvalidDiscountReturnsError() {
        Date s = Date.today();
        PricingResponse response = PricebookService.calculateByVolumePricing(null, null, 1, -1, s, s);

        System.assertEquals(false, response.success, 'Should fail');
        System.assert(response.errorMessage.contains('Discount must be between 0 and 100'), 'Error should indicate invalid discount');
    }

    @IsTest
    static void calculateByVolumePricingInvalidQuantityReturnsError() {
        Date s = Date.today();
        PricingResponse response = PricebookService.calculateByVolumePricing(null, null, 0, 0, s, s);

        System.assertEquals(false, response.success, 'Should fail');
        System.assert(response.errorMessage.contains('Quantity must be at least 1'), 'Error should indicate invalid quantity');
    }

    @IsTest
    static void calculateByVolumePricingFailsWhenDatesMissing() {
        Pricebook2 pb = TestDataFactory.createPricebook2('PB-NoDates', true, true);
        Product2 prod = TestDataFactory.createProduct2(true);
        PricebookEntry stdPbe = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = prod.Id, UnitPrice = 100, IsActive = true, UseStandardPrice = false);
        insert stdPbe;

        Volume_Pricing_Schedule__c schedule = TestDataFactory.createVolumePricingSchedule(prod.Id, pb.Id, 'Tiered', true, true);
        TestDataFactory.createVolumePricingTier(schedule.Id, 1, 10, 80, 1, true);

        PricingResponse response = PricebookService.calculateByVolumePricing(prod.Id, pb.Id, 1, 0, null, null);

        System.assertEquals(false, response.success, 'Should fail when dates missing');
        System.assert(response.errorMessage.contains('required'), 'Error should mention required dates');
    }

    @IsTest
    static void calculateByVolumePricingFailsWhenEndBeforeStart() {
        Pricebook2 pb = TestDataFactory.createPricebook2('PB-Inv', true, true);
        Product2 prod = TestDataFactory.createProduct2(true);
        PricebookEntry stdPbe = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = prod.Id, UnitPrice = 100, IsActive = true, UseStandardPrice = false);
        insert stdPbe;

        Volume_Pricing_Schedule__c schedule = TestDataFactory.createVolumePricingSchedule(prod.Id, pb.Id, 'Tiered', true, true);
        TestDataFactory.createVolumePricingTier(schedule.Id, 1, 10, 80, 1, true);

        Date s = Date.today();
        Date e = s.addDays(-1);
        PricingResponse response = PricebookService.calculateByVolumePricing(prod.Id, pb.Id, 1, 0, s, e);

        System.assertEquals(false, response.success, 'Should fail when end < start');
        System.assert(response.errorMessage.contains('on or after'), 'Error should indicate date order');
    }

}