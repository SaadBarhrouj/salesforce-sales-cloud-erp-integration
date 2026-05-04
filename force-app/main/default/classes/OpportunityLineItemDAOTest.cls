/**
 * @description Test class for OpportunityLineItemDAO.
 */
@IsTest
private class OpportunityLineItemDAOTest {

    @IsTest
    static void getByOpportunityIdNullReturnsEmptyList() {
        List<OpportunityLineItem> result = OpportunityLineItemDAO.getByOpportunityId(null);
        System.assertNotEquals(null, result, 'Should return empty list, not null');
        System.assertEquals(0, result.size(), 'Should return empty list for null Id');
    }

    @IsTest
    static void getByOpportunityIdWithItemsReturnsItems() {
        Account acc = TestDataFactory.createAccount(true);
        Pricebook2 pb = TestDataFactory.createPricebook2('Test PB', true, true);
        Product2 prod = TestDataFactory.createProduct2(true);
        PricebookEntry stdPbe = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = prod.Id, UnitPrice = 100, IsActive = true, UseStandardPrice = false);
        insert stdPbe;
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(pb.Id, prod.Id, 100, true, true);

        Opportunity opp = new Opportunity(Name = 'Test Opp', AccountId = acc.Id, StageName = 'Prospecting', CloseDate = Date.today().addDays(30), Pricebook2Id = pb.Id);
        insert opp;

        OpportunityLineItem item = new OpportunityLineItem(OpportunityId = opp.Id, PricebookEntryId = pbe.Id, Quantity = 1, UnitPrice = 100);
        insert item;

        List<OpportunityLineItem> result = OpportunityLineItemDAO.getByOpportunityId(opp.Id);

        System.assertEquals(1, result.size(), 'Should return one line item');
        System.assertEquals(item.Id, result[0].Id, 'Ids should match');
    }

    @IsTest
    static void deleteByOpportunityIdNullDoesNothing() {
        Test.startTest();
        OpportunityLineItemDAO.deleteByOpportunityId(null);
        Test.stopTest();
        System.assert(true, 'No exception expected for null Id');
    }

    @IsTest
    static void deleteByOpportunityIdWithItemsDeletesItems() {
        Account acc = TestDataFactory.createAccount(true);
        Pricebook2 pb = TestDataFactory.createPricebook2('Test PB', true, true);
        Product2 prod = TestDataFactory.createProduct2(true);
        PricebookEntry stdPbe = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = prod.Id, UnitPrice = 100, IsActive = true, UseStandardPrice = false);
        insert stdPbe;
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(pb.Id, prod.Id, 100, true, true);

        Opportunity opp = new Opportunity(Name = 'Test Opp', AccountId = acc.Id, StageName = 'Prospecting', CloseDate = Date.today().addDays(30), Pricebook2Id = pb.Id);
        insert opp;

        OpportunityLineItem item = new OpportunityLineItem(OpportunityId = opp.Id, PricebookEntryId = pbe.Id, Quantity = 1, UnitPrice = 100);
        insert item;

        Test.startTest();
        OpportunityLineItemDAO.deleteByOpportunityId(opp.Id);
        Test.stopTest();

        List<OpportunityLineItem> remaining = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :opp.Id];
        System.assertEquals(0, remaining.size(), 'All line items should be deleted');
    }

    @IsTest
    static void insertLineItemsNullReturnsNull() {
        List<OpportunityLineItem> result = OpportunityLineItemDAO.insertLineItems(null);
        System.assertEquals(null, result, 'Should return null for null input');
    }

    @IsTest
    static void insertLineItemsEmptyReturnsEmpty() {
        List<OpportunityLineItem> result = OpportunityLineItemDAO.insertLineItems(new List<OpportunityLineItem>());
        System.assertNotEquals(null, result, 'Should return empty list, not null');
        System.assertEquals(0, result.size(), 'Should return empty list');
    }

    @IsTest
    static void insertLineItemsValidInsertsAndReturnsIds() {
        Account acc = TestDataFactory.createAccount(true);
        Pricebook2 pb = TestDataFactory.createPricebook2('Test PB', true, true);
        Product2 prod = TestDataFactory.createProduct2(true);
        PricebookEntry stdPbe = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = prod.Id, UnitPrice = 100, IsActive = true, UseStandardPrice = false);
        insert stdPbe;
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(pb.Id, prod.Id, 100, true, true);

        Opportunity opp = new Opportunity(Name = 'Test Opp', AccountId = acc.Id, StageName = 'Prospecting', CloseDate = Date.today().addDays(30), Pricebook2Id = pb.Id);
        insert opp;

        List<OpportunityLineItem> items = new List<OpportunityLineItem>{
            new OpportunityLineItem(OpportunityId = opp.Id, PricebookEntryId = pbe.Id, Quantity = 2, UnitPrice = 100)
        };

        List<OpportunityLineItem> result = OpportunityLineItemDAO.insertLineItems(items);

        System.assertEquals(1, result.size(), 'Should return one item');
        System.assertNotEquals(null, result[0].Id, 'Item should have an Id after insert');
    }
}