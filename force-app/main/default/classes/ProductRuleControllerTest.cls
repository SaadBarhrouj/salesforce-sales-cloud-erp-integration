/**
 * @description Test class for ProductRuleController.
 * @author Sales Cloud ERP Integration Team
 */
@IsTest
private class ProductRuleControllerTest {

    @IsTest
    static void evaluateBundleRulesDelegatesToService() {
        Product2 bundle = TestDataFactory.createProduct2(true);
        Product2 optionProduct = TestDataFactory.createProduct2(true);
        Product2 targetProduct = TestDataFactory.createProduct2(true);
        Bundle_Option__c option = TestDataFactory.createBundleOption(
            bundle.Id, optionProduct.Id, null, 'Component', 1, 1, 0, 10, false, false, false, true);
        Bundle_Option__c target = TestDataFactory.createBundleOption(
            bundle.Id, targetProduct.Id, null, 'Related Product', 2, 1, 0, 10, false, false, false, true);

        Product_Rule__c rule = TestDataFactory.createProductRule(
            'Add Target', 'Selection', 'All', null, 1, true, true);
        TestDataFactory.createRuleCondition(
            rule.Id, 'Bundle Option', 'Option_Type__c', 'equals', 'Value', 'Component', 1, true);
        TestDataFactory.createRuleAction(
            rule.Id, 'Add', targetProduct.Id, null, null, null, 1, true);
        TestDataFactory.createBundleRuleAssignment(bundle.Id, rule.Id, true, true);

        Test.startTest();
        Map<String, Object> verdict = ProductRuleController.evaluateBundleRules(
            bundle.Id, null, new List<Id>{ option.Id }, 'Save');
        Test.stopTest();

        Set<String> selected = new Set<String>((List<String>) verdict.get('selectedOptionIds'));
        System.assert(selected.contains(String.valueOf(target.Id)),
            'Controller should return the service verdict with the Selection rule applied');
    }

    @IsTest
    static void evaluateBundleRulesHandlesNullSelection() {
        Product2 bundle = TestDataFactory.createProduct2(true);

        Test.startTest();
        Map<String, Object> verdict = ProductRuleController.evaluateBundleRules(bundle.Id, null, null, 'Save');
        Test.stopTest();

        System.assertNotEquals(null, verdict, 'Verdict should not be null for null selection');
        System.assertEquals(0, ((List<String>) verdict.get('selectedOptionIds')).size(),
            'No options selected should yield an empty selection');
    }

    @IsTest
    static void evaluateLineRulesDelegatesToService() {
        Product2 prod = TestDataFactory.createProduct2(true);
        prod.Family = 'Restricted';
        update prod;

        Product_Rule__c rule = TestDataFactory.createProductRule(
            'Block Restricted', 'Validation', 'All', 'Blocked.', 1, true, true);
        TestDataFactory.createRuleCondition(
            rule.Id, 'Opportunity Line', 'Family', 'equals', 'Value', 'Restricted', 1, true);

        List<Map<String, Object>> lines = new List<Map<String, Object>>{
            new Map<String, Object>{
                'productId' => prod.Id,
                'quantity' => 1,
                'unitPrice' => 10,
                'discountPercent' => 0,
                'isBundle' => false
            }
        };

        Test.startTest();
        Map<String, Object> verdict = ProductRuleController.evaluateLineRules(null, lines, 'Save');
        Test.stopTest();

        System.assertEquals(1, ((List<String>) verdict.get('validationErrors')).size(),
            'Controller should return the line rule verdict');
    }

    @IsTest
    static void evaluateLineRulesHandlesNullLines() {
        Test.startTest();
        Map<String, Object> verdict = ProductRuleController.evaluateLineRules(null, null, 'Save');
        Test.stopTest();

        System.assertNotEquals(null, verdict, 'Verdict should not be null for null lines');
        System.assertEquals(0, ((List<String>) verdict.get('validationErrors')).size(),
            'No rules in the org should yield no validation errors');
    }
}
