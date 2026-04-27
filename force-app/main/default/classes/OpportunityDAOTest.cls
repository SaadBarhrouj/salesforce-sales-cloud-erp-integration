/**
 * @description Test class for OpportunityDAO.
 */
@IsTest
private class OpportunityDAOTest {

    @IsTest
    static void getById_Null_ReturnsNull() {
        Opportunity result = OpportunityDAO.getById(null);
        System.assertEquals(null, result, 'Should return null for null Id');
    }

    @IsTest
    static void getById_ValidId_ReturnsRecord() {
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
    static void updateOpportunity_Null_DoesNothing() {
        Test.startTest();
        OpportunityDAO.updateOpportunity(null);
        Test.stopTest();
        System.assert(true, 'No exception expected for null input');
    }

    @IsTest
    static void updateOpportunity_NullId_DoesNothing() {
        Test.startTest();
        OpportunityDAO.updateOpportunity(new Opportunity());
        Test.stopTest();
        System.assert(true, 'No exception expected for null Id');
    }

    @IsTest
    static void updateOpportunity_Valid_UpdatesFields() {
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
        OpportunityDAO.updateOpportunity(opp);
        Test.stopTest();

        Opportunity updated = [SELECT Description FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Updated Description', updated.Description, 'Description should be updated');
    }
}
