/**
 * @description Test class for ProductRuleDAO.
 * @author Sales Cloud ERP Integration Team
 */
@IsTest
private class ProductRuleDAOTest {

    @IsTest
    static void getActiveBundleRulesReturnsEmptyForNull() {
        Test.startTest();
        List<Product_Rule__c> rules = ProductRuleDAO.getActiveBundleRules(null);
        Test.stopTest();
        System.assertEquals(0, rules.size(), 'Null bundle should yield no rules');
    }

    @IsTest
    static void getActiveBundleRulesReturnsAssignedSelectionRules() {
        Product2 bundle = TestDataFactory.createProduct2(true);

        Product_Rule__c selectionRule = TestDataFactory.createProductRule(
            'Selection Rule', 'Selection', 'All', 'msg', 1, true, true);
        Product_Rule__c inactiveRule = TestDataFactory.createProductRule(
            'Inactive Selection', 'Selection', 'All', 'msg', 2, false, true);
        Product_Rule__c validationRule = TestDataFactory.createProductRule(
            'Validation Rule', 'Validation', 'All', 'msg', 3, true, true);

        TestDataFactory.createRuleCondition(
            selectionRule.Id, 'Bundle Option', 'Option_Type__c', 'equals', 'Value', 'Component', 1, true);
        TestDataFactory.createRuleAction(
            selectionRule.Id, 'Add', null, 'Option_Type__c', 'equals', 'Accessory', 1, true);

        TestDataFactory.createBundleRuleAssignment(bundle.Id, selectionRule.Id, true, true);
        TestDataFactory.createBundleRuleAssignment(bundle.Id, inactiveRule.Id, true, true);
        TestDataFactory.createBundleRuleAssignment(bundle.Id, validationRule.Id, true, true);

        Test.startTest();
        List<Product_Rule__c> rules = ProductRuleDAO.getActiveBundleRules(bundle.Id);
        Test.stopTest();

        System.assertEquals(1, rules.size(), 'Only the active Selection rule should load');
        System.assertEquals('Selection Rule', rules[0].Name, 'Wrong rule returned');
        System.assertEquals(1, rules[0].Rule_Conditions__r.size(), 'Condition subquery missing');
        System.assertEquals(1, rules[0].Rule_Actions__r.size(), 'Action subquery missing');
    }

    @IsTest
    static void getActiveBundleRulesIgnoresInactiveAssignments() {
        Product2 bundle = TestDataFactory.createProduct2(true);
        Product_Rule__c rule = TestDataFactory.createProductRule(
            'Selection Rule', 'Selection', 'Any', 'msg', 1, true, true);
        TestDataFactory.createBundleRuleAssignment(bundle.Id, rule.Id, false, true);

        Test.startTest();
        List<Product_Rule__c> rules = ProductRuleDAO.getActiveBundleRules(bundle.Id);
        Test.stopTest();

        System.assertEquals(0, rules.size(), 'Inactive assignment must be ignored');
    }

    @IsTest
    static void getActiveLineRulesReturnsValidationAndAlertRules() {
        Product_Rule__c validationRule = TestDataFactory.createProductRule(
            'Validation Rule', 'Validation', 'All', 'msg', 1, true, true);
        Product_Rule__c alertRule = TestDataFactory.createProductRule(
            'Alert Rule', 'Alert', 'Any', 'msg', 2, true, true);
        TestDataFactory.createProductRule(
            'Selection Rule', 'Selection', 'All', 'msg', 3, true, true);
        TestDataFactory.createProductRule(
            'Inactive Validation', 'Validation', 'All', 'msg', 4, false, true);

        TestDataFactory.createRuleCondition(
            validationRule.Id, 'Opportunity Line', 'Family', 'equals', 'Value', 'Equipment', 1, true);

        Test.startTest();
        List<Product_Rule__c> rules = ProductRuleDAO.getActiveLineRules();
        Test.stopTest();

        Set<String> names = new Set<String>();
        for (Product_Rule__c r : rules) { names.add(r.Name); }
        System.assertEquals(2, rules.size(), 'Only active Validation/Alert rules should load');
        System.assert(names.contains('Validation Rule'), 'Validation rule should load');
        System.assert(names.contains('Alert Rule'), 'Alert rule should load');
        System.assert(!names.contains('Selection Rule'), 'Selection rule must be excluded');
        System.assert(!names.contains('Inactive Validation'), 'Inactive rule must be excluded');
    }

    @IsTest
    static void getOpportunityForRulesReturnsRequestedFields() {
        Opportunity opp = TestDataFactory.createOpportunity(true);

        Test.startTest();
        Opportunity loaded = ProductRuleDAO.getOpportunityForRules(
            opp.Id, new Set<String>{ 'Name', 'StageName' });
        Test.stopTest();

        System.assertNotEquals(null, loaded, 'Opportunity should load');
        System.assertEquals(opp.Id, loaded.Id, 'Wrong Opportunity returned');
    }

    @IsTest
    static void getOpportunityForRulesRejectsInjectionAndNulls() {
        Opportunity opp = TestDataFactory.createOpportunity(true);

        Test.startTest();
        Opportunity nullId = ProductRuleDAO.getOpportunityForRules(null, new Set<String>{ 'Name' });
        Opportunity noFields = ProductRuleDAO.getOpportunityForRules(opp.Id, new Set<String>());
        Opportunity badField = ProductRuleDAO.getOpportunityForRules(
            opp.Id, new Set<String>{ 'Name FROM Opportunity WHERE Id != null --' });
        Test.stopTest();

        System.assertEquals(null, nullId, 'Null Id should yield null');
        System.assertEquals(null, noFields, 'Empty field set should yield null');
        System.assertEquals(null, badField, 'Injection-shaped field should be rejected, yielding null');
    }
}
