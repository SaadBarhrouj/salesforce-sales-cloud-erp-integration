/**
 * @description Test class for QuoteController, QuoteService, and QuoteDAO.
 * Covers quote PDF data assembly, empty states, transport, and formatting.
 */
@IsTest
private class QuoteControllerTest {

    private static Pricebook2 createTestPricebook() {
        Pricebook2 pb = new Pricebook2(
            Name = 'Test PB ' + DateTime.now().getTime(),
            IsActive = true
        );
        insert pb;
        return pb;
    }

    private static Product2 createTestProduct(String suffix) {
        Product2 prod = new Product2(
            Name = 'Test Product ' + suffix,
            IsActive = true
        );
        insert prod;
        return prod;
    }

    private static PricebookEntry createTestEntry(Id pbId, Id prodId) {
        Id stdPbId = Test.getStandardPricebookId();
        PricebookEntry stdPbe = new PricebookEntry(
            Pricebook2Id = stdPbId,
            Product2Id = prodId,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false
        );
        insert stdPbe;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pbId,
            Product2Id = prodId,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false
        );
        insert pbe;
        return pbe;
    }

    private static Opportunity createTestOpportunity(Id pbId) {
        Account acc = new Account(Name = 'Test Account ' + DateTime.now().getTime());
        insert acc;

        ProductCatalog catalog = new ProductCatalog(Name = 'Test Catalog ' + DateTime.now().getTime());
        insert catalog;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp ' + DateTime.now().getTime(),
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Offer_Type__c = catalog.Id,
            Pricebook2Id = pbId,
            Is_Transport_Required__c = false
        );
        insert opp;
        return opp;
    }

    private static Quote createTestQuote(Id oppId, Id pbId) {
        Quote q = new Quote(
            Name = 'Test Quote ' + DateTime.now().getTime(),
            OpportunityId = oppId,
            Pricebook2Id = pbId,
            ExpirationDate = Date.today().addDays(30)
        );
        insert q;
        return q;
    }

    /**
     * @description Tests that the controller loads successfully with a valid quote having line items.
     */
    @IsTest
    static void testQuotePDFWithLineItems() {
        Pricebook2 pb = createTestPricebook();
        Product2 prod = createTestProduct('A');
        PricebookEntry pbe = createTestEntry(pb.Id, prod.Id);
        Opportunity opp = createTestOpportunity(pb.Id);
        Quote q = createTestQuote(opp.Id, pb.Id);

        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = q.Id,
            PricebookEntryId = pbe.Id,
            Product2Id = prod.Id,
            Quantity = 2,
            UnitPrice = 100.00
        );
        insert qli;

        Test.startTest();
        PageReference pageRef = Page.QuotePDF;
        pageRef.getParameters().put('id', q.Id);
        Test.setCurrentPage(pageRef);

        ApexPages.StandardController sc = new ApexPages.StandardController(q);
        QuoteController ctrl = new QuoteController(sc);

        System.assertNotEquals(null, ctrl.pdfData, 'PDF data should not be null');
        System.assert(ctrl.hasLineItems, 'Should have line items');
        System.assertEquals(false, ctrl.hasTransport, 'Should not have transport');
        System.assertEquals(1, ctrl.pdfData.lineItems.size(), 'Should have 1 line item');
        System.assertEquals(2, ctrl.pdfData.lineItems[0].quantity, 'Quantity should be 2');
        System.assertEquals(100.00, ctrl.pdfData.lineItems[0].unitPrice, 'Unit price should be 100');
        System.assertEquals(false, ctrl.pdfData.lineItems[0].isBundle, 'Should not be a bundle');
        System.assertEquals(200.00, ctrl.pdfData.lineItemsSubtotal, 'Subtotal should be 200');
        System.assertEquals(200.00, ctrl.pdfData.grandTotal, 'Grand total should be 200');
        Test.stopTest();
    }

    /**
     * @description Tests that the controller handles a quote with no line items gracefully.
     */
    @IsTest
    static void testQuotePDFEmptyLineItems() {
        Pricebook2 pb = createTestPricebook();
        Opportunity opp = createTestOpportunity(pb.Id);
        Quote q = createTestQuote(opp.Id, pb.Id);

        Test.startTest();
        PageReference pageRef = Page.QuotePDF;
        pageRef.getParameters().put('id', q.Id);
        Test.setCurrentPage(pageRef);

        ApexPages.StandardController sc = new ApexPages.StandardController(q);
        QuoteController ctrl = new QuoteController(sc);

        System.assertNotEquals(null, ctrl.pdfData, 'PDF data should not be null');
        System.assertEquals(false, ctrl.hasLineItems, 'Should not have line items');
        System.assertEquals(0, ctrl.pdfData.lineItems.size(), 'Line items should be empty');
        System.assertEquals(0, ctrl.pdfData.lineItemsSubtotal, 'Subtotal should be 0');
        System.assertEquals(0, ctrl.pdfData.grandTotal, 'Grand total should be 0');
        Test.stopTest();
    }

    /**
     * @description Tests currency and percentage formatting methods.
     */
    @IsTest
    static void testFormattingMethods() {
        Pricebook2 pb = createTestPricebook();
        Opportunity opp = createTestOpportunity(pb.Id);
        Quote q = createTestQuote(opp.Id, pb.Id);

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(q);
        QuoteController ctrl = new QuoteController(sc);

        System.assertEquals('$1,234.56', ctrl.formatCurrency(1234.56), 'Currency format incorrect');
        System.assertEquals('$0.00', ctrl.formatCurrency(null), 'Null currency should be $0.00');

        System.assertEquals('10.5%', ctrl.formatPercent(10.50), 'Percent format incorrect');
        System.assertEquals('0%', ctrl.formatPercent(null), 'Null percent should be 0%');

        System.assertEquals('—', ctrl.formatDate(null), 'Null date should be dash');

        System.assertEquals('0 - 300', ctrl.formatTierRange(0, 300), 'Tier range incorrect');
        System.assertEquals('300+', ctrl.formatTierRange(300, null), 'Unlimited upper bound incorrect');
        Test.stopTest();
    }

    /**
     * @description Tests that QuoteService throws exception for null quote ID.
     */
    @IsTest
    static void testQuoteServiceNullId() {
        Boolean caught = false;
        try {
            QuoteService.buildQuotePDFData(null);
        } catch (QuoteException e) {
            caught = true;
            System.assert(e.getMessage().contains('required'), 'Message should mention required');
        }
        System.assert(caught, 'Should have thrown QuoteException');
    }

    /**
     * @description Tests that QuoteService throws exception for invalid quote ID.
     */
    @IsTest
    static void testQuoteServiceInvalidId() {
        Boolean caught = false;
        try {
            QuoteService.buildQuotePDFData(Quote.SObjectType.getDescribe().getKeyPrefix() + '000000000000');
        } catch (Exception e) {
            caught = true;
        }
        System.assert(caught, 'Should have thrown exception for invalid ID');
    }

    /**
     * @description Tests that savePDF creates a QuoteDocument and returns its name.
     */
    @IsTest
    static void testSavePDF() {
        Pricebook2 pb = createTestPricebook();
        Product2 prod = createTestProduct('D');
        createTestEntry(pb.Id, prod.Id);
        Opportunity opp = createTestOpportunity(pb.Id);
        Quote q = createTestQuote(opp.Id, pb.Id);

        QuoteController.mockPdfBlob = Blob.valueOf('Test PDF Content');
        Test.startTest();
        String savedName = QuoteController.savePDF(q.Id);
        Test.stopTest();

        System.assertNotEquals(null, savedName, 'Returned name should not be null');
        System.assert(savedName.contains('.pdf'), 'Name should contain .pdf, got: ' + savedName);

        List<QuoteDocument> docs = [
            SELECT Id, Name, QuoteId, Document
            FROM QuoteDocument
            WHERE QuoteId = :q.Id
        ];
        System.assertEquals(1, docs.size(), 'Should have created one QuoteDocument');
        System.assertEquals(savedName, docs[0].Name, 'Returned name should match stored name');
        System.assertNotEquals(null, docs[0].Document, 'Document blob should not be null');
    }

    /**
     * @description Tests that sequential saves produce distinct QuoteDocuments.
     */
    @IsTest
    static void testSavePDFMultiple() {
        Pricebook2 pb = createTestPricebook();
        Product2 prod = createTestProduct('E');
        createTestEntry(pb.Id, prod.Id);
        Opportunity opp = createTestOpportunity(pb.Id);
        Quote q = createTestQuote(opp.Id, pb.Id);

        QuoteController.mockPdfBlob = Blob.valueOf('Test PDF Content');
        Test.startTest();
        QuoteController.savePDF(q.Id);
        QuoteController.savePDF(q.Id);
        Test.stopTest();

        List<QuoteDocument> docs = [
            SELECT Id, Name
            FROM QuoteDocument
            WHERE QuoteId = :q.Id
        ];
        System.assertEquals(2, docs.size(), 'Should have created two QuoteDocuments');
    }

    /**
     * @description Tests that savePDF throws exception for null quote ID.
     */
    @IsTest
    static void testSavePDFNullId() {
        Boolean caught = false;
        try {
            QuoteController.savePDF(null);
        } catch (QuoteException e) {
            caught = true;
            System.assert(e.getMessage().contains('required'), 'Message should mention required');
        }
        System.assert(caught, 'Should have thrown QuoteException');
    }
}