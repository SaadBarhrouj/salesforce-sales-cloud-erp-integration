/**
 * @description Test class for ProductRuleService.
 * Covers configurator Selection rules (evaluateBundleRules) and Line Editor
 * Validation / Alert rules (evaluateLineRules).
 * @author Sales Cloud ERP Integration Team
 */
@IsTest
private class ProductRuleServiceTest {

    /**
     * @description Builds a bundle with three options and returns the key Ids.
     */
    private static Map<String, Id> buildBundle() {
        Product2 bundle = TestDataFactory.createProduct2(true);
        Product2 prodComponent = TestDataFactory.createProduct2(true);
        Product2 prodRelated = TestDataFactory.createProduct2(true);
        Product2 prodAccessory = TestDataFactory.createProduct2(true);
        prodComponent.Family = 'Power';
        prodRelated.Family = 'Battery';
        prodAccessory.Family = 'Safety';
        update new List<Product2>{ prodComponent, prodRelated, prodAccessory };

        Bundle_Option__c optComponent = TestDataFactory.createBundleOption(
            bundle.Id, prodComponent.Id, null, 'Component', 1, 1, 0, 10, false, false, false, true);
        Bundle_Option__c optRelated = TestDataFactory.createBundleOption(
            bundle.Id, prodRelated.Id, null, 'Related Product', 2, 1, 0, 10, false, false, false, true);
        Bundle_Option__c optAccessory = TestDataFactory.createBundleOption(
            bundle.Id, prodAccessory.Id, null, 'Accessory', 3, 1, 0, 10, false, false, false, true);

        return new Map<String, Id>{
            'bundleId' => bundle.Id,
            'optComponentId' => optComponent.Id,
            'optRelatedId' => optRelated.Id,
            'optAccessoryId' => optAccessory.Id,
            'prodComponentId' => prodComponent.Id,
            'prodRelatedId' => prodRelated.Id,
            'prodAccessoryId' => prodAccessory.Id
        };
    }

    private static List<Map<String, Object>> lineFor(Id productId) {
        return new List<Map<String, Object>>{
            new Map<String, Object>{
                'productId' => productId,
                'quantity' => 1,
                'unitPrice' => 10,
                'discountPercent' => 0,
                'isBundle' => false
            }
        };
    }

    // ===== Configurator: Selection rules =====

    @IsTest
    static void noRulesReturnsSelectionUnchanged() {
        Map<String, Id> ids = buildBundle();

        Test.startTest();
        Map<String, Object> verdict = ProductRuleService.evaluateBundleRules(
            ids.get('bundleId'), null, new Set<Id>{ ids.get('optComponentId') });
        Test.stopTest();

        List<String> selected = (List<String>) verdict.get('selectedOptionIds');
        System.assertEquals(1, selected.size(), 'Selection should be unchanged with no rules');
        System.assertEquals(String.valueOf(ids.get('optComponentId')), selected[0], 'Wrong option selected');
    }

    @IsTest
    static void selectionRuleAutoAddsTargetProduct() {
        Map<String, Id> ids = buildBundle();
        Product_Rule__c rule = TestDataFactory.createProductRule(
            'Add Battery', 'Selection', 'All', null, 1, true, true);
        TestDataFactory.createRuleCondition(
            rule.Id, 'Bundle Option', 'Option_Type__c', 'equals', 'Value', 'Component', 1, true);
        TestDataFactory.createRuleAction(
            rule.Id, 'Add', ids.get('prodRelatedId'), null, null, null, 1, true);
        TestDataFactory.createBundleRuleAssignment(ids.get('bundleId'), rule.Id, true, true);

        Test.startTest();
        Map<String, Object> verdict = ProductRuleService.evaluateBundleRules(
            ids.get('bundleId'), null, new Set<Id>{ ids.get('optComponentId') });
        Test.stopTest();

        Set<String> selected = new Set<String>((List<String>) verdict.get('selectedOptionIds'));
        System.assert(selected.contains(String.valueOf(ids.get('optComponentId'))), 'Component stays selected');
        System.assert(selected.contains(String.valueOf(ids.get('optRelatedId'))), 'Related must be auto-added');
    }

    @IsTest
    static void selectionRuleRemovesByFilterField() {
        Map<String, Id> ids = buildBundle();
        Product_Rule__c rule = TestDataFactory.createProductRule(
            'Remove Accessory', 'Selection', 'All', null, 1, true, true);
        TestDataFactory.createRuleCondition(
            rule.Id, 'Bundle Option', 'Option_Type__c', 'equals', 'Value', 'Component', 1, true);
        TestDataFactory.createRuleAction(
            rule.Id, 'Remove', null, 'Option_Type__c', 'equals', 'Accessory', 1, true);
        TestDataFactory.createBundleRuleAssignment(ids.get('bundleId'), rule.Id, true, true);

        Test.startTest();
        Map<String, Object> verdict = ProductRuleService.evaluateBundleRules(
            ids.get('bundleId'), null,
            new Set<Id>{ ids.get('optComponentId'), ids.get('optAccessoryId') });
        Test.stopTest();

        Set<String> selected = new Set<String>((List<String>) verdict.get('selectedOptionIds'));
        System.assert(selected.contains(String.valueOf(ids.get('optComponentId'))), 'Component stays');
        System.assert(!selected.contains(String.valueOf(ids.get('optAccessoryId'))), 'Accessory must be removed');
    }

    @IsTest
    static void selectionRuleHidesAndDisablesOptions() {
        Map<String, Id> ids = buildBundle();
        Product_Rule__c rule = TestDataFactory.createProductRule(
            'Hide and Disable', 'Selection', 'All', null, 1, true, true);
        TestDataFactory.createRuleCondition(
            rule.Id, 'Bundle Option', 'Option_Type__c', 'equals', 'Value', 'Component', 1, true);
        TestDataFactory.createRuleAction(
            rule.Id, 'Hide', ids.get('prodAccessoryId'), null, null, null, 1, true);
        TestDataFactory.createRuleAction(
            rule.Id, 'Disable', ids.get('prodRelatedId'), null, null, null, 2, true);
        TestDataFactory.createBundleRuleAssignment(ids.get('bundleId'), rule.Id, true, true);

        Test.startTest();
        Map<String, Object> verdict = ProductRuleService.evaluateBundleRules(
            ids.get('bundleId'), null, new Set<Id>{ ids.get('optComponentId') });
        Test.stopTest();

        Set<String> hidden = new Set<String>((List<String>) verdict.get('hiddenOptionIds'));
        Set<String> locked = new Set<String>((List<String>) verdict.get('lockedOptionIds'));
        System.assert(hidden.contains(String.valueOf(ids.get('optAccessoryId'))), 'Accessory must be hidden');
        System.assert(locked.contains(String.valueOf(ids.get('optRelatedId'))), 'Related must be locked');
    }

    @IsTest
    static void conditionsMetAllRequiresEveryCondition() {
        Map<String, Id> ids = buildBundle();
        Product_Rule__c rule = TestDataFactory.createProductRule(
            'All Conditions', 'Selection', 'All', null, 1, true, true);
        TestDataFactory.createRuleCondition(
            rule.Id, 'Bundle Option', 'Option_Type__c', 'equals', 'Value', 'Component', 1, true);
        TestDataFactory.createRuleCondition(
            rule.Id, 'Bundle Option', 'Option_Type__c', 'equals', 'Value', 'Accessory', 2, true);
        TestDataFactory.createRuleAction(
            rule.Id, 'Add', ids.get('prodRelatedId'), null, null, null, 1, true);
        TestDataFactory.createBundleRuleAssignment(ids.get('bundleId'), rule.Id, true, true);

        Test.startTest();
        Map<String, Object> onlyOne = ProductRuleService.evaluateBundleRules(
            ids.get('bundleId'), null, new Set<Id>{ ids.get('optComponentId') });
        Map<String, Object> both = ProductRuleService.evaluateBundleRules(
            ids.get('bundleId'), null,
            new Set<Id>{ ids.get('optComponentId'), ids.get('optAccessoryId') });
        Test.stopTest();

        Set<String> selectedOne = new Set<String>((List<String>) onlyOne.get('selectedOptionIds'));
        Set<String> selectedBoth = new Set<String>((List<String>) both.get('selectedOptionIds'));
        System.assert(!selectedOne.contains(String.valueOf(ids.get('optRelatedId'))),
            'All-mode rule must not fire when one condition fails');
        System.assert(selectedBoth.contains(String.valueOf(ids.get('optRelatedId'))),
            'All-mode rule must fire when every condition passes');
    }

    @IsTest
    static void customConditionsMetFiresWhenFormulaTrue() {
        Map<String, Id> ids = buildBundle();
        Product_Rule__c rule = TestDataFactory.createProductRule(
            'Custom Rule', 'Selection', 'Custom', null, 1, true, true);
        rule.Advanced_Condition__c = '1 OR 2';
        update rule;
        TestDataFactory.createRuleCondition(
            rule.Id, 'Bundle Option', 'Option_Type__c', 'equals', 'Value', 'Component', 1, true);
        TestDataFactory.createRuleCondition(
            rule.Id, 'Bundle Option', 'Option_Type__c', 'equals', 'Value', 'ImpossibleType', 2, true);
        TestDataFactory.createRuleAction(
            rule.Id, 'Add', ids.get('prodRelatedId'), null, null, null, 1, true);
        TestDataFactory.createBundleRuleAssignment(ids.get('bundleId'), rule.Id, true, true);

        Test.startTest();
        Map<String, Object> verdict = ProductRuleService.evaluateBundleRules(
            ids.get('bundleId'), null, new Set<Id>{ ids.get('optComponentId') });
        Test.stopTest();

        Set<String> selected = new Set<String>((List<String>) verdict.get('selectedOptionIds'));
        System.assert(selected.contains(String.valueOf(ids.get('optRelatedId'))),
            'Custom rule with formula "1 OR 2" must fire when condition 1 passes');
    }

    @IsTest
    static void customConditionsMetSkipsWhenFormulaFalse() {
        Map<String, Id> ids = buildBundle();
        Product_Rule__c rule = TestDataFactory.createProductRule(
            'Custom AND Rule', 'Selection', 'Custom', null, 1, true, true);
        rule.Advanced_Condition__c = '1 AND 2';
        update rule;
        TestDataFactory.createRuleCondition(
            rule.Id, 'Bundle Option', 'Option_Type__c', 'equals', 'Value', 'Component', 1, true);
        TestDataFactory.createRuleCondition(
            rule.Id, 'Bundle Option', 'Option_Type__c', 'equals', 'Value', 'ImpossibleType', 2, true);
        TestDataFactory.createRuleAction(
            rule.Id, 'Add', ids.get('prodRelatedId'), null, null, null, 1, true);
        TestDataFactory.createBundleRuleAssignment(ids.get('bundleId'), rule.Id, true, true);

        Test.startTest();
        Map<String, Object> verdict = ProductRuleService.evaluateBundleRules(
            ids.get('bundleId'), null, new Set<Id>{ ids.get('optComponentId') });
        Test.stopTest();

        Set<String> selected = new Set<String>((List<String>) verdict.get('selectedOptionIds'));
        System.assert(!selected.contains(String.valueOf(ids.get('optRelatedId'))),
            'Custom rule with formula "1 AND 2" must NOT fire when condition 2 fails');
    }

    @IsTest
    static void customConditionsMetWithMalformedFormulaDoesNotFireAndDoesNotThrow() {
        Map<String, Id> ids = buildBundle();
        Product_Rule__c rule = TestDataFactory.createProductRule(
            'Malformed Custom Rule', 'Selection', 'Custom', null, 1, true, true);
        rule.Advanced_Condition__c = '((1 AND 2';
        update rule;
        TestDataFactory.createRuleCondition(
            rule.Id, 'Bundle Option', 'Option_Type__c', 'equals', 'Value', 'Component', 1, true);
        TestDataFactory.createRuleAction(
            rule.Id, 'Add', ids.get('prodRelatedId'), null, null, null, 1, true);
        TestDataFactory.createBundleRuleAssignment(ids.get('bundleId'), rule.Id, true, true);

        Test.startTest();
        Map<String, Object> verdict = ProductRuleService.evaluateBundleRules(
            ids.get('bundleId'), null, new Set<Id>{ ids.get('optComponentId') });
        Test.stopTest();

        Set<String> selected = new Set<String>((List<String>) verdict.get('selectedOptionIds'));
        System.assert(!selected.contains(String.valueOf(ids.get('optRelatedId'))),
            'Malformed Advanced_Condition must defensively no-op the rule');
    }

    // ===== Line Editor: Validation + Alert rules =====

    @IsTest
    static void lineValidationRuleProducesError() {
        Product2 prod = TestDataFactory.createProduct2(true);
        prod.Family = 'Restricted';
        update prod;

        Product_Rule__c rule = TestDataFactory.createProductRule(
            'Block Restricted', 'Validation', 'All', 'Restricted family is not allowed.', 1, true, true);
        TestDataFactory.createRuleCondition(
            rule.Id, 'Opportunity Line', 'Family', 'equals', 'Value', 'Restricted', 1, true);

        Test.startTest();
        Map<String, Object> verdict = ProductRuleService.evaluateLineRules(null, lineFor(prod.Id));
        Test.stopTest();

        List<String> errors = (List<String>) verdict.get('validationErrors');
        System.assertEquals(1, errors.size(), 'Validation rule should fire');
        System.assertEquals('Restricted family is not allowed.', errors[0], 'Message mismatch');
    }

    @IsTest
    static void lineAlertRuleProducesAlert() {
        Product2 prod = TestDataFactory.createProduct2(true);
        prod.Family = 'Premium';
        update prod;

        Product_Rule__c rule = TestDataFactory.createProductRule(
            'Premium Notice', 'Alert', 'Any', 'Premium item on the quote.', 1, true, true);
        TestDataFactory.createRuleCondition(
            rule.Id, 'Opportunity Line', 'Family', 'equals', 'Value', 'Premium', 1, true);

        Test.startTest();
        Map<String, Object> verdict = ProductRuleService.evaluateLineRules(null, lineFor(prod.Id));
        Test.stopTest();

        System.assertEquals(1, ((List<String>) verdict.get('alerts')).size(), 'Alert rule should fire');
    }

    @IsTest
    static void lineRuleDoesNotFireWhenConditionsUnmet() {
        Product2 prod = TestDataFactory.createProduct2(true);
        prod.Family = 'Standard';
        update prod;

        Product_Rule__c rule = TestDataFactory.createProductRule(
            'Block Restricted', 'Validation', 'All', 'Restricted family is not allowed.', 1, true, true);
        TestDataFactory.createRuleCondition(
            rule.Id, 'Opportunity Line', 'Family', 'equals', 'Value', 'Restricted', 1, true);

        Test.startTest();
        Map<String, Object> verdict = ProductRuleService.evaluateLineRules(null, lineFor(prod.Id));
        Test.stopTest();

        System.assertEquals(0, ((List<String>) verdict.get('validationErrors')).size(),
            'Rule must not fire when no line matches');
    }

    @IsTest
    static void lineRuleEvaluatesOpportunityCondition() {
        Opportunity opp = TestDataFactory.createOpportunity(true);
        Product2 prod = TestDataFactory.createProduct2(true);

        Product_Rule__c rule = TestDataFactory.createProductRule(
            'Stage Rule', 'Alert', 'All', 'Opportunity is in Prospecting.', 1, true, true);
        TestDataFactory.createRuleCondition(
            rule.Id, 'Opportunity', 'StageName', 'equals', 'Value', 'Prospecting', 1, true);

        Test.startTest();
        Map<String, Object> verdict = ProductRuleService.evaluateLineRules(opp.Id, lineFor(prod.Id));
        Test.stopTest();

        System.assertEquals(1, ((List<String>) verdict.get('alerts')).size(),
            'Opportunity-tested line rule should evaluate against the Opportunity');
    }

    @IsTest
    static void evaluateLineRulesReturnsEmptyWhenNoRules() {
        Product2 prod = TestDataFactory.createProduct2(true);

        Test.startTest();
        Map<String, Object> verdict = ProductRuleService.evaluateLineRules(null, lineFor(prod.Id));
        Test.stopTest();

        System.assertEquals(0, ((List<String>) verdict.get('validationErrors')).size(), 'No errors expected');
        System.assertEquals(0, ((List<String>) verdict.get('alerts')).size(), 'No alerts expected');
    }

    @IsTest
    static void compareValuesCoversOperators() {
        Test.startTest();
        System.assertEquals(true, ProductRuleService.compareValues(5, 'greater than', '3'), 'numeric gt');
        System.assertEquals(true, ProductRuleService.compareValues(2, 'less than', '3'), 'numeric lt');
        System.assertEquals(true, ProductRuleService.compareValues('Component', 'equals', 'component'), 'ci equals');
        System.assertEquals(true, ProductRuleService.compareValues('Heavy Duty', 'contains', 'duty'), 'contains');
        System.assertEquals(true, ProductRuleService.compareValues('AB-100', 'starts with', 'ab'), 'starts with');
        System.assertEquals(true, ProductRuleService.compareValues('AB-100', 'ends with', '100'), 'ends with');
        System.assertEquals(true, ProductRuleService.compareValues('X', 'not equals', 'Y'), 'not equals');
        System.assertEquals(false, ProductRuleService.compareValues(null, 'equals', 'Y'), 'null vs value');
        Test.stopTest();
    }
}
