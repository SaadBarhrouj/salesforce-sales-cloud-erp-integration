/**
 * @description Test class for PricebookEntryDAO.
 */
@IsTest
private class PricebookEntryDAOTest {

    @IsTest
    static void getByProductAndPricebook_Valid_ReturnsEntry() {
        Pricebook2 pb = TestDataFactory.createPricebook2('Test PB', true, true);
        Product2 prod = TestDataFactory.createProduct2(true);
        PricebookEntry stdPbe = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = prod.Id, UnitPrice = 100, IsActive = true, UseStandardPrice = false);
        insert stdPbe;
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(pb.Id, prod.Id, 150, true, true);

        PricebookEntry result = PricebookEntryDAO.getByProductAndPricebook(prod.Id, pb.Id);

        System.assertNotEquals(null, result, 'Should return the pricebook entry');
        System.assertEquals(pbe.Id, result.Id, 'Ids should match');
        System.assertEquals(150, result.UnitPrice, 'UnitPrice should match');
    }

    @IsTest
    static void getByProductAndPricebook_Inactive_ReturnsNull() {
        Pricebook2 pb = TestDataFactory.createPricebook2('Test PB', true, true);
        Product2 prod = TestDataFactory.createProduct2(true);
        PricebookEntry stdPbe = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = prod.Id, UnitPrice = 100, IsActive = true, UseStandardPrice = false);
        insert stdPbe;
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(pb.Id, prod.Id, 150, false, true);

        PricebookEntry result = PricebookEntryDAO.getByProductAndPricebook(prod.Id, pb.Id);

        System.assertEquals(null, result, 'Should return null for inactive entry');
    }

    @IsTest
    static void getByProductsAndPricebook_NullSet_ReturnsEmptyMap() {
        Map<Id, PricebookEntry> result = PricebookEntryDAO.getByProductsAndPricebook(null, null);
        System.assertNotEquals(null, result, 'Should return empty map, not null');
        System.assertEquals(0, result.size(), 'Should return empty map for null set');
    }

    @IsTest
    static void getByProductsAndPricebook_EmptySet_ReturnsEmptyMap() {
        Map<Id, PricebookEntry> result = PricebookEntryDAO.getByProductsAndPricebook(new Set<Id>(), null);
        System.assertNotEquals(null, result, 'Should return empty map, not null');
        System.assertEquals(0, result.size(), 'Should return empty map for empty set');
    }

    @IsTest
    static void getByProductsAndPricebook_Valid_ReturnsMap() {
        Pricebook2 pb = TestDataFactory.createPricebook2('Test PB', true, true);
        Product2 prod1 = TestDataFactory.createProduct2(true);
        Product2 prod2 = TestDataFactory.createProduct2(true);
        PricebookEntry stdPbe1 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = prod1.Id, UnitPrice = 100, IsActive = true, UseStandardPrice = false);
        insert stdPbe1;
        PricebookEntry stdPbe2 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = prod2.Id, UnitPrice = 100, IsActive = true, UseStandardPrice = false);
        insert stdPbe2;
        PricebookEntry pbe1 = TestDataFactory.createPricebookEntry(pb.Id, prod1.Id, 150, true, true);
        PricebookEntry pbe2 = TestDataFactory.createPricebookEntry(pb.Id, prod2.Id, 200, true, true);

        Map<Id, PricebookEntry> result = PricebookEntryDAO.getByProductsAndPricebook(new Set<Id>{ prod1.Id, prod2.Id }, pb.Id);

        System.assertEquals(2, result.size(), 'Should return two entries');
        System.assertEquals(true, result.containsKey(prod1.Id), 'Should contain prod1');
        System.assertEquals(true, result.containsKey(prod2.Id), 'Should contain prod2');
    }
}
