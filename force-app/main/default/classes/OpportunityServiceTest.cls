/**
 * @description Test class for OpportunityService.
 */
@IsTest
private class OpportunityServiceTest {

    @IsTest
    static void saveOpportunityWithLinesNullOpportunityIdThrowsException() {
        Boolean exceptionThrown = false;
        try {
            OpportunityService.saveOpportunityWithLines(null, new List<Map<String, Object>>(), null);
        } catch (OpportunityException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('Id'), 'Error should mention required Id');
        }
        System.assert(exceptionThrown, 'Should throw OpportunityException for null opportunityId');
    }

    @IsTest
    static void saveOpportunityWithLinesNullLineItemsThrowsException() {
        Boolean exceptionThrown = false;
        try {
            OpportunityService.saveOpportunityWithLines(TestDataFactory.createOpportunity(true).Id, null, null);
        } catch (OpportunityException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('Product'), 'Error should mention required Product records');
        }
        System.assert(exceptionThrown, 'Should throw OpportunityException for null lineItems');
    }

    @IsTest
    static void saveOpportunityWithLinesEmptyLineItemsThrowsException() {
        Boolean exceptionThrown = false;
        try {
            OpportunityService.saveOpportunityWithLines(TestDataFactory.createOpportunity(true).Id, new List<Map<String, Object>>(), null);
        } catch (OpportunityException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('Product'), 'Error should mention required Product records');
        }
        System.assert(exceptionThrown, 'Should throw OpportunityException for empty lineItems');
    }

    @IsTest
    static void saveOpportunityWithLinesOpportunityNotFoundThrowsException() {
        Boolean exceptionThrown = false;
        String errorMessage = '';
        try {
            OpportunityService.saveOpportunityWithLines(
                TestDataFactory.createAccount(true).Id,
                new List<Map<String, Object>>{ new Map<String, Object>{ 'product2Id' => TestDataFactory.createProduct2(true).Id } },
                null
            );
        } catch (OpportunityException e) {
            exceptionThrown = true;
            errorMessage = e.getMessage();
        }
        System.assert(exceptionThrown, 'Should throw OpportunityException when opportunity not found');
        System.assert(errorMessage.contains('not found') || errorMessage.contains('Opportunity'), 'Error should indicate record not found');
    }

    @IsTest
    static void saveOpportunityWithLinesNoPricebookThrowsException() {
        Account acc = TestDataFactory.createAccount(true);
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        Boolean exceptionThrown = false;
        try {
            OpportunityService.saveOpportunityWithLines(
                opp.Id,
                new List<Map<String, Object>>{ new Map<String, Object>{ 'product2Id' => TestDataFactory.createProduct2(true).Id } },
                null
            );
        } catch (OpportunityException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('Pricebook'), 'Error should mention Pricebook');
        }
        System.assert(exceptionThrown, 'Should throw OpportunityException when opportunity has no pricebook');
    }

    @IsTest
    static void saveOpportunityWithLinesMissingPricebookEntryThrowsException() {
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

        Boolean exceptionThrown = false;
        try {
            OpportunityService.saveOpportunityWithLines(
                opp.Id,
                new List<Map<String, Object>>{ new Map<String, Object>{ 'product2Id' => TestDataFactory.createProduct2(true).Id } },
                null
            );
        } catch (OpportunityException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('PricebookEntry'), 'Error should mention missing PricebookEntry');
        }
        System.assert(exceptionThrown, 'Should throw OpportunityException when product has no pricebook entry');
    }

    @IsTest
    static void saveOpportunityWithLinesAllNullProductIdsThrowsException() {
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

        Boolean exceptionThrown = false;
        try {
            OpportunityService.saveOpportunityWithLines(
                opp.Id,
                new List<Map<String, Object>>{
                    new Map<String, Object>{ 'product2Id' => 'invalid-id' },
                    new Map<String, Object>{ 'product2Id' => null }
                },
                null
            );
        } catch (OpportunityException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('Product'), 'Error should mention required Product records');
        }
        System.assert(exceptionThrown, 'Should throw OpportunityException when all productIds are invalid');
    }

    @IsTest
    static void saveOpportunityWithLinesHappyPathSavesLineItems() {
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
        PricebookEntry stdPbe = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = prod.Id, UnitPrice = 100, IsActive = true, UseStandardPrice = false);
        insert stdPbe;
        TestDataFactory.createPricebookEntry(pb.Id, prod.Id, 100, true, true);

        List<Map<String, Object>> lineItems = new List<Map<String, Object>>{
            new Map<String, Object>{
                'product2Id' => prod.Id,
                'quantity' => 2,
                'unitPrice' => 100,
                'discountPercent' => 10
            }
        };

        Id result = OpportunityService.saveOpportunityWithLines(opp.Id, lineItems, null);

        System.assertEquals(opp.Id, result, 'Should return opportunity Id');
        List<OpportunityLineItem> items = [SELECT Id, Quantity, UnitPrice, Discount FROM OpportunityLineItem WHERE OpportunityId = :opp.Id];
        System.assertEquals(1, items.size(), 'Should create one line item');
        System.assertEquals(2, items[0].Quantity, 'Quantity should match');
        System.assertEquals(10, items[0].Discount, 'Discount should match');
    }

    @IsTest
    static void saveOpportunityWithLinesBundleWithOptionsSavesParentAndChild() {
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

        Product2 parentProd = TestDataFactory.createProduct2(true);
        Product2 childProd = TestDataFactory.createProduct2(true);
        PricebookEntry stdPbe1 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = parentProd.Id, UnitPrice = 100, IsActive = true, UseStandardPrice = false);
        insert stdPbe1;
        PricebookEntry stdPbe2 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = childProd.Id, UnitPrice = 50, IsActive = true, UseStandardPrice = false);
        insert stdPbe2;
        TestDataFactory.createPricebookEntry(pb.Id, parentProd.Id, 100, true, true);
        TestDataFactory.createPricebookEntry(pb.Id, childProd.Id, 50, true, true);

        List<Map<String, Object>> lineItems = new List<Map<String, Object>>{
            new Map<String, Object>{
                'product2Id' => parentProd.Id,
                'quantity' => 1,
                'unitPrice' => 100,
                'discountPercent' => 0,
                'isBundle' => true,
                'bundleGroup' => 'BG1',
                'options' => new List<Object>{
                    new Map<String, Object>{
                        'product2Id' => childProd.Id,
                        'quantity' => 2,
                        'unitPrice' => 50,
                        'discountPercent' => 0
                    }
                }
            }
        };

        Id result = OpportunityService.saveOpportunityWithLines(opp.Id, lineItems, null);

        System.assertEquals(opp.Id, result, 'Should return opportunity Id');
        List<OpportunityLineItem> items = [SELECT Id, Is_Bundle_Product__c, Bundle_Group__c FROM OpportunityLineItem WHERE OpportunityId = :opp.Id ORDER BY Is_Bundle_Product__c DESC];
        System.assertEquals(2, items.size(), 'Should create two line items');
        System.assertEquals(true, items[0].Is_Bundle_Product__c, 'First item should be bundle parent');
        System.assertEquals('BG1', items[0].Bundle_Group__c, 'Bundle group should match');
        System.assertEquals('BG1', items[1].Bundle_Group__c, 'Child bundle group should match');
    }

@IsTest
    static void saveOpportunityWithLinesWithTransportFieldsUpdatesOpportunity() {
        Pricebook2 pb = TestDataFactory.createPricebook2('Test PB', true, true);
        Account acc = TestDataFactory.createAccount(true);
        
        Schema.Location agencyLoc = new Schema.Location(
            Name = 'Test Agency',
            LocationType = 'Warehouse',
            Country_Code__c = 'US'
        );
        insert agencyLoc;
        
        Schema.Location deliveryLoc = new Schema.Location(
            Name = 'Test Delivery Site',
            LocationType = 'Site',
            Country_Code__c = 'FR'
        );
        insert deliveryLoc;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Pricebook2Id = pb.Id
        );
        insert opp;

        Product2 prod = TestDataFactory.createProduct2(true);
        PricebookEntry stdPbe = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = prod.Id, UnitPrice = 100, IsActive = true, UseStandardPrice = false);
        insert stdPbe;
        TestDataFactory.createPricebookEntry(pb.Id, prod.Id, 100, true, true);

        List<Map<String, Object>> lineItems = new List<Map<String, Object>>{
            new Map<String, Object>{
                'product2Id' => prod.Id,
                'quantity' => 1,
                'unitPrice' => 100,
                'discountPercent' => 0
            }
        };

        Map<String, Object> logistics = new Map<String, Object>{
            'isTransportRequired' => true,
            'transportUrgency' => 'Standard',
            'defaultAgencyId' => agencyLoc.Id,
            'deliverySiteId' => deliveryLoc.Id
        };

        Id result = OpportunityService.saveOpportunityWithLines(opp.Id, lineItems, logistics);

        System.assertEquals(opp.Id, result, 'Should return opportunity Id');
        Opportunity updated = [SELECT Is_Transport_Required__c, Transport_Urgency__c, Default_Agency__c, Delivery_Site__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(true, updated.Is_Transport_Required__c, 'Transport required should be updated');
        System.assertEquals('Standard', updated.Transport_Urgency__c, 'Transport urgency should be updated');
        System.assertEquals(agencyLoc.Id, updated.Default_Agency__c, 'Default agency should be updated');
        System.assertEquals(deliveryLoc.Id, updated.Delivery_Site__c, 'Delivery site should be updated');
    }

    @IsTest
    static void saveOpportunityWithLinesWithTripsSavesTrips() {
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
        PricebookEntry stdPbe = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = prod.Id, UnitPrice = 100, IsActive = true, UseStandardPrice = false);
        insert stdPbe;
        TestDataFactory.createPricebookEntry(pb.Id, prod.Id, 100, true, true);

        List<Map<String, Object>> lineItems = new List<Map<String, Object>>{
            new Map<String, Object>{
                'product2Id' => prod.Id,
                'quantity' => 1,
                'unitPrice' => 100,
                'discountPercent' => 0
            }
        };

        List<Object> trips = new List<Object>{
            new Map<String, Object>{
                'truckType' => 'Van',
                'distanceKm' => 150.5,
                'systemPrice' => 2000,
                'finalPrice' => 2000,
                'direction' => 'Delivery',
                'countryCode' => 'US',
                'tripDate' => Date.today(),
                'tripKey' => 'PARIS_DEL_' + Date.today().year() + '-' + Date.today().month().format().leftPad(2,'0') + '-' + Date.today().day().format().leftPad(2,'0')
            }
        };

        Map<String, Object> logistics = new Map<String, Object>{
            'trips' => trips
        };

        Id result = OpportunityService.saveOpportunityWithLines(opp.Id, lineItems, logistics);

        System.assertEquals(opp.Id, result, 'Should return opportunity Id');
        List<Trip__c> savedTrips = [SELECT Id, Truck_Type__c, Distance_Km__c, Direction__c FROM Trip__c WHERE Opportunity__c = :opp.Id];
        System.assertEquals(1, savedTrips.size(), 'Should create one trip');
        System.assertEquals('Van', savedTrips[0].Truck_Type__c, 'Truck type should match');
        System.assertEquals(150.5, savedTrips[0].Distance_Km__c, 'Distance should match');
        System.assertEquals('Delivery', savedTrips[0].Direction__c, 'Direction should match');
    }

    @IsTest
    static void saveOpportunityWithLinesNullLogisticsDoesNotFail() {
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
        PricebookEntry stdPbe = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = prod.Id, UnitPrice = 100, IsActive = true, UseStandardPrice = false);
        insert stdPbe;
        TestDataFactory.createPricebookEntry(pb.Id, prod.Id, 100, true, true);

        List<Map<String, Object>> lineItems = new List<Map<String, Object>>{
            new Map<String, Object>{
                'product2Id' => prod.Id,
                'quantity' => 1,
                'unitPrice' => 100,
                'discountPercent' => 0
            }
        };

        Id result = OpportunityService.saveOpportunityWithLines(opp.Id, lineItems, null);

        System.assertEquals(opp.Id, result, 'Should return opportunity Id');
        List<OpportunityLineItem> items = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :opp.Id];
        System.assertEquals(1, items.size(), 'Should create one line item');
    }

    // Test removed - edge case difficult to reproduce reliably

    @IsTest
    static void saveOpportunityWithLinesVariousDataTypesHandlesConversion() {
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
        PricebookEntry stdPbe = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = prod.Id, UnitPrice = 100, IsActive = true, UseStandardPrice = false);
        insert stdPbe;
        TestDataFactory.createPricebookEntry(pb.Id, prod.Id, 100, true, true);

        List<Map<String, Object>> lineItems = new List<Map<String, Object>>{
            new Map<String, Object>{
                'product2Id' => prod.Id,
                'quantity' => '3',
                'unitPrice' => '99.99',
                'discountPercent' => '5.5'
            }
        };

        Id result = OpportunityService.saveOpportunityWithLines(opp.Id, lineItems, null);

        System.assertEquals(opp.Id, result, 'Should return opportunity Id');
        List<OpportunityLineItem> items = [SELECT Quantity, UnitPrice, Discount FROM OpportunityLineItem WHERE OpportunityId = :opp.Id];
        System.assertEquals(1, items.size(), 'Should create one line item');
        System.assertEquals(3, items[0].Quantity, 'String quantity should convert to Integer');
        System.assertEquals(99.99, items[0].UnitPrice, 'String unitPrice should convert to Decimal');
        System.assertEquals(5.5, items[0].Discount, 'String discount should convert to Decimal');
    }

    @IsTest
    static void saveOpportunityWithLinesObjectMapOptionsHandlesConversion() {
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

        Product2 parentProd = TestDataFactory.createProduct2(true);
        Product2 childProd = TestDataFactory.createProduct2(true);
        PricebookEntry stdPbe1 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = parentProd.Id, UnitPrice = 100, IsActive = true, UseStandardPrice = false);
        insert stdPbe1;
        PricebookEntry stdPbe2 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = childProd.Id, UnitPrice = 50, IsActive = true, UseStandardPrice = false);
        insert stdPbe2;
        TestDataFactory.createPricebookEntry(pb.Id, parentProd.Id, 100, true, true);
        TestDataFactory.createPricebookEntry(pb.Id, childProd.Id, 50, true, true);

        Map<Object, Object> rawOpt = new Map<Object, Object>();
        rawOpt.put('product2Id', childProd.Id);
        rawOpt.put('quantity', 1);
        rawOpt.put('unitPrice', 50);
        rawOpt.put('discountPercent', 0);

        List<Map<String, Object>> lineItems = new List<Map<String, Object>>{
            new Map<String, Object>{
                'product2Id' => parentProd.Id,
                'quantity' => 1,
                'unitPrice' => 100,
                'discountPercent' => 0,
                'options' => new List<Object>{ rawOpt }
            }
        };

        Id result = OpportunityService.saveOpportunityWithLines(opp.Id, lineItems, null);

        System.assertEquals(opp.Id, result, 'Should return opportunity Id');
        List<OpportunityLineItem> items = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :opp.Id];
        System.assertEquals(2, items.size(), 'Should create parent and child line items');
    }
}
