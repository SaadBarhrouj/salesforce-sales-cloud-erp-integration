/**
 * @description Test class for OpportunityDAO.
 */
@IsTest
private class OpportunityDAOTest {

    @IsTest
    static void getByIdNullReturnsNull() {
        Opportunity result = OpportunityDAO.getById(null);
        System.assertEquals(null, result, 'Should return null for null Id');
    }

    @IsTest
    static void getByIdValidIdReturnsRecord() {
        Account acc = TestDataFactory.createAccount(true);
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        Opportunity result = OpportunityDAO.getById(opp.Id);

        System.assertNotEquals(null, result, 'Should return the opportunity');
        System.assertEquals(opp.Id, result.Id, 'Ids should match');
        System.assertEquals(acc.Id, result.AccountId, 'AccountId should match');
    }

    @IsTest
    static void updateOpportunityNullDoesNothing() {
        Test.startTest();
        OpportunityDAO.updateRecord(null);
        Test.stopTest();
        System.assert(true, 'No exception expected for null input');
    }

    @IsTest
    static void updateOpportunityNullIdDoesNothing() {
        Test.startTest();
        OpportunityDAO.updateRecord(new Opportunity());
        Test.stopTest();
        System.assert(true, 'No exception expected for null Id');
    }

    @IsTest
    static void updateOpportunityValidUpdatesFields() {
        Account acc = TestDataFactory.createAccount(true);
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        opp.Description = 'Updated Description';
        Test.startTest();
        OpportunityDAO.updateRecord(opp);
        Test.stopTest();

        Opportunity updated = [SELECT Description FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Updated Description', updated.Description, 'Description should be updated');
    }
}