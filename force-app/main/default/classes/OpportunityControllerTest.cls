/**
 * @description Test class for OpportunityController.
 */
@IsTest
private class OpportunityControllerTest {

    @IsTest
    static void saveOpportunityNullOpportunityIdThrowsAuraHandledException() {
        Boolean exceptionThrown = false;
        try {
            OpportunityController.saveOpportunity(null, new List<Map<String, Object>>(), null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'Should throw AuraHandledException for null opportunityId');
    }

    @IsTest
    static void saveOpportunityNullLineItemsThrowsAuraHandledException() {
        Boolean exceptionThrown = false;
        try {
            OpportunityController.saveOpportunity(TestDataFactory.createOpportunity(true).Id, null, null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'Should throw AuraHandledException for null lineItems');
    }

    @IsTest
    static void saveOpportunityEmptyLineItemsThrowsAuraHandledException() {
        Boolean exceptionThrown = false;
        try {
            OpportunityController.saveOpportunity(TestDataFactory.createOpportunity(true).Id, new List<Map<String, Object>>(), null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'Should throw AuraHandledException for empty lineItems');
    }

    @IsTest
    static void saveOpportunityHappyPathReturnsOpportunityId() {
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

        Id result = OpportunityController.saveOpportunity(opp.Id, lineItems, null);

        System.assertEquals(opp.Id, result, 'Should return the opportunity Id');
        List<OpportunityLineItem> items = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :opp.Id];
        System.assertEquals(1, items.size(), 'Should create one line item');
    }
}