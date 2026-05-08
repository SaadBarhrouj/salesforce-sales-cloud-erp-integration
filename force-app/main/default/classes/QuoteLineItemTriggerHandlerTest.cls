/**
 * @description Test class for QuoteLineItemTriggerHandler.
 */
@IsTest
private class QuoteLineItemTriggerHandlerTest {

    @IsTest
    static void handleBeforeCopiesServiceFieldsFromOLI() {
        ProductCatalog rentalCatalog = TestDataFactory.createProductCatalog('Rental', true);
        Product2 product = TestDataFactory.createProduct2(true);
        Pricebook2 pb = TestDataFactory.createPricebook2('PB-Rental-QLI', true, true);
        PricebookEntry std = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = product.Id,
            UnitPrice = 100, IsActive = true, UseStandardPrice = false
        );
        insert std;
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(pb.Id, product.Id, 50, true, true);
        Opportunity opp = TestDataFactory.createOpportunityWithPricebook(rentalCatalog.Id, pb.Id, true);

        Date startDate = Date.newInstance(2026, 6, 1);
        Date endDate = Date.newInstance(2026, 6, 5);
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 250,
            Service_Start_Date__c = startDate,
            Service_End_Date__c = endDate,
            Daily_Rate__c = 50
        );
        insert oli;

        Quote q = new Quote(Name = 'Test Quote', OpportunityId = opp.Id, Pricebook2Id = pb.Id);
        insert q;

        Test.startTest();
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = q.Id,
            OpportunityLineItemId = oli.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 250
        );
        insert qli;
        Test.stopTest();

        QuoteLineItem reloaded = [
            SELECT Service_Start_Date__c, Service_End_Date__c, Daily_Rate__c, Service_Days__c
            FROM QuoteLineItem WHERE Id = :qli.Id
        ];
        System.assertEquals(startDate, reloaded.Service_Start_Date__c, 'Start should be copied from OLI');
        System.assertEquals(endDate, reloaded.Service_End_Date__c, 'End should be copied from OLI');
        System.assertEquals(50, reloaded.Daily_Rate__c, 'Daily rate should be copied from OLI');
        System.assertEquals(5, reloaded.Service_Days__c, 'Formula computes inclusive days');
    }

    @IsTest
    static void handleBeforePreservesExistingValues() {
        ProductCatalog rentalCatalog = TestDataFactory.createProductCatalog('Rental', true);
        Product2 product = TestDataFactory.createProduct2(true);
        Pricebook2 pb = TestDataFactory.createPricebook2('PB-Rental-Pres', true, true);
        PricebookEntry std = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = product.Id,
            UnitPrice = 100, IsActive = true, UseStandardPrice = false
        );
        insert std;
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(pb.Id, product.Id, 50, true, true);
        Opportunity opp = TestDataFactory.createOpportunityWithPricebook(rentalCatalog.Id, pb.Id, true);

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 250,
            Service_Start_Date__c = Date.newInstance(2026, 6, 1),
            Service_End_Date__c = Date.newInstance(2026, 6, 5),
            Daily_Rate__c = 50
        );
        insert oli;

        Quote q = new Quote(Name = 'Test Quote', OpportunityId = opp.Id, Pricebook2Id = pb.Id);
        insert q;

        Date overrideStart = Date.newInstance(2026, 7, 1);
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = q.Id,
            OpportunityLineItemId = oli.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 250,
            Service_Start_Date__c = overrideStart
        );
        insert qli;

        QuoteLineItem reloaded = [
            SELECT Service_Start_Date__c, Service_End_Date__c
            FROM QuoteLineItem WHERE Id = :qli.Id
        ];
        System.assertEquals(overrideStart, reloaded.Service_Start_Date__c, 'Manual start override should be preserved');
        System.assertEquals(Date.newInstance(2026, 6, 5), reloaded.Service_End_Date__c, 'Blank end should be filled from OLI');
    }
}