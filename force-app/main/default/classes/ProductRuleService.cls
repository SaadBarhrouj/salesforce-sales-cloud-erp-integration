/**
 * @description Evaluation engine for Product Rules.
 * Selection rules are evaluated for a bundle in the configurator (evaluateBundleRules);
 * Validation and Alert rules are evaluated against all line items on the Line Editor
 * and at opportunity save (evaluateLineRules). The rule Type determines where it runs.
 * @author Sales Cloud ERP Integration Team
 */
public inherited sharing class ProductRuleService {

    private static final String TYPE_VALIDATION = 'Validation';
    private static final String TYPE_ALERT = 'Alert';
    private static final String OBJ_BUNDLE_OPTION = 'Bundle Option';
    private static final String OBJ_OPPORTUNITY = 'Opportunity';
    private static final String OBJ_OPPORTUNITY_LINE = 'Opportunity Line';
    private static final String COND_ALL = 'All';
    private static final String COND_ANY = 'Any';
    private static final String FILTER_TYPE_FIELD = 'Field';

    /**
     * @description Mutable working state for one Bundle_Option__c during a configurator pass.
     */
    private class OptionState {
        Bundle_Option__c record;
        Boolean selected;
        Boolean hidden;
        Boolean locked;
        OptionState(Bundle_Option__c record, Boolean selected) {
            this.record = record;
            this.selected = selected;
            this.hidden = false;
            this.locked = false;
        }
    }

    /**
     * @description Evaluates the active Selection rules assigned to a bundle and returns the
     * resulting selected / hidden / locked option sets.
     * @param bundleProductId The bundle Product2 Id.
     * @param opportunityId The Opportunity Id (used only by Opportunity-tested conditions; may be null).
     * @param selectedOptionIds The Bundle_Option__c Ids the rep currently has selected.
     * @return Map with keys selectedOptionIds, hiddenOptionIds, lockedOptionIds.
     */
    public static Map<String, Object> evaluateBundleRules(
        Id bundleProductId,
        Id opportunityId,
        Set<Id> selectedOptionIds
    ) {
        Set<Id> selected = selectedOptionIds == null ? new Set<Id>() : selectedOptionIds;

        Map<Id, OptionState> optionById = new Map<Id, OptionState>();
        for (Bundle_Option__c bo : BundleOptionDAO.getByBundleProductId(bundleProductId)) {
            optionById.put(bo.Id, new OptionState(bo, selected.contains(bo.Id)));
        }

        List<Product_Rule__c> rules = ProductRuleDAO.getActiveBundleRules(bundleProductId);
        Opportunity opp = loadOpportunityIfNeeded(rules, opportunityId);

        for (Product_Rule__c rule : rules) {
            if (rule.Conditions_Met__c != COND_ALL && rule.Conditions_Met__c != COND_ANY) {
                continue;
            }
            if (isRuleFired(rule, optionById, opp)) {
                applyActions(rule, optionById);
            }
        }

        List<String> selectedOut = new List<String>();
        List<String> hiddenOut = new List<String>();
        List<String> lockedOut = new List<String>();
        for (Id boId : optionById.keySet()) {
            OptionState state = optionById.get(boId);
            if (state.selected) { selectedOut.add(String.valueOf(boId)); }
            if (state.hidden)   { hiddenOut.add(String.valueOf(boId)); }
            if (state.locked)   { lockedOut.add(String.valueOf(boId)); }
        }

        return new Map<String, Object>{
            'selectedOptionIds' => selectedOut,
            'hiddenOptionIds' => hiddenOut,
            'lockedOptionIds' => lockedOut
        };
    }

    /**
     * @description Evaluates all active Validation and Alert rules against the supplied line items.
     * @param opportunityId The Opportunity Id (used only by Opportunity-tested conditions; may be null).
     * @param lines Line item maps; each carries at least productId, quantity, unitPrice,
     *              discountPercent, isBundle. Product code / name / family are resolved here.
     * @return Map with keys validationErrors and alerts (lists of messages).
     */
    public static Map<String, Object> evaluateLineRules(
        Id opportunityId,
        List<Map<String, Object>> lines
    ) {
        List<String> validationErrors = new List<String>();
        List<String> alerts = new List<String>();

        List<Product_Rule__c> rules = ProductRuleDAO.getActiveLineRules();
        if (rules.isEmpty()) {
            return new Map<String, Object>{
                'validationErrors' => validationErrors,
                'alerts' => alerts
            };
        }

        List<Map<String, Object>> enriched = enrichLines(lines);
        Opportunity opp = loadOpportunityIfNeeded(rules, opportunityId);

        for (Product_Rule__c rule : rules) {
            if (rule.Conditions_Met__c != COND_ALL && rule.Conditions_Met__c != COND_ANY) {
                continue;
            }
            if (!isLineRuleFired(rule, enriched, opp)) {
                continue;
            }
            if (rule.Type__c == TYPE_VALIDATION) {
                validationErrors.add(messageFor(rule));
            } else if (rule.Type__c == TYPE_ALERT) {
                alerts.add(messageFor(rule));
            }
        }

        return new Map<String, Object>{
            'validationErrors' => validationErrors,
            'alerts' => alerts
        };
    }

    private static List<Map<String, Object>> enrichLines(List<Map<String, Object>> lines) {
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        if (lines == null || lines.isEmpty()) {
            return result;
        }
        Set<Id> productIds = new Set<Id>();
        for (Map<String, Object> line : lines) {
            Id pid = toId(line.get('productId'));
            if (pid != null) {
                productIds.add(pid);
            }
        }
        Map<Id, Product2> productById = new Map<Id, Product2>(
            [SELECT Id, Name, ProductCode, Family FROM Product2 WHERE Id IN :productIds]
        );
        for (Map<String, Object> line : lines) {
            Id pid = toId(line.get('productId'));
            Product2 p = pid == null ? null : productById.get(pid);
            result.add(new Map<String, Object>{
                'productId' => pid,
                'productCode' => p == null ? '' : p.ProductCode,
                'productName' => p == null ? '' : p.Name,
                'family' => p == null ? '' : p.Family,
                'quantity' => line.get('quantity'),
                'unitPrice' => line.get('unitPrice'),
                'discountPercent' => line.get('discountPercent'),
                'isBundle' => line.get('isBundle')
            });
        }
        return result;
    }

    private static Opportunity loadOpportunityIfNeeded(List<Product_Rule__c> rules, Id opportunityId) {
        Set<String> oppFields = new Set<String>();
        for (Product_Rule__c rule : rules) {
            for (Rule_Condition__c c : rule.Rule_Conditions__r) {
                if (c.Tested_Object__c != OBJ_OPPORTUNITY) { continue; }
                if (String.isNotBlank(c.Tested_Field__c)) {
                    oppFields.add(c.Tested_Field__c.trim());
                }
                if (c.Filter_Type__c == FILTER_TYPE_FIELD && String.isNotBlank(c.Filter_Value__c)) {
                    oppFields.add(c.Filter_Value__c.trim());
                }
            }
        }
        if (oppFields.isEmpty()) {
            return null;
        }
        return ProductRuleDAO.getOpportunityForRules(opportunityId, oppFields);
    }

    private static Boolean isRuleFired(
        Product_Rule__c rule, Map<Id, OptionState> optionById, Opportunity opp
    ) {
        List<Boolean> results = new List<Boolean>();
        for (Rule_Condition__c c : rule.Rule_Conditions__r) {
            if (c.Tested_Object__c == OBJ_BUNDLE_OPTION) {
                results.add(anySelectedOptionMatches(c, optionById));
            } else if (c.Tested_Object__c == OBJ_OPPORTUNITY && opp != null) {
                results.add(recordMatches(c, opp, opp));
            }
        }
        return aggregate(results, rule.Conditions_Met__c);
    }

    private static Boolean isLineRuleFired(
        Product_Rule__c rule, List<Map<String, Object>> lines, Opportunity opp
    ) {
        List<Boolean> results = new List<Boolean>();
        for (Rule_Condition__c c : rule.Rule_Conditions__r) {
            if (c.Tested_Object__c == OBJ_OPPORTUNITY_LINE) {
                results.add(anyLineMatches(c, lines));
            } else if (c.Tested_Object__c == OBJ_OPPORTUNITY && opp != null) {
                results.add(recordMatches(c, opp, opp));
            }
        }
        return aggregate(results, rule.Conditions_Met__c);
    }

    private static Boolean aggregate(List<Boolean> results, String conditionsMet) {
        if (results.isEmpty()) {
            return false;
        }
        if (conditionsMet == COND_ANY) {
            for (Boolean r : results) { if (r) { return true; } }
            return false;
        }
        for (Boolean r : results) { if (!r) { return false; } }
        return true;
    }

    private static Boolean anySelectedOptionMatches(
        Rule_Condition__c c, Map<Id, OptionState> optionById
    ) {
        for (OptionState state : optionById.values()) {
            if (state.selected && recordMatches(c, state.record, state.record)) {
                return true;
            }
        }
        return false;
    }

    private static Boolean anyLineMatches(Rule_Condition__c c, List<Map<String, Object>> lines) {
        for (Map<String, Object> line : lines) {
            Object fieldValue = resolveLineField(line, c.Tested_Field__c);
            String compareTo;
            if (c.Filter_Type__c == FILTER_TYPE_FIELD) {
                Object other = resolveLineField(line, c.Filter_Value__c);
                compareTo = other == null ? null : String.valueOf(other);
            } else {
                compareTo = c.Filter_Value__c;
            }
            if (compareValues(fieldValue, c.Operator__c, compareTo)) {
                return true;
            }
        }
        return false;
    }

    /**
     * @description Resolves the tested field and filter value against the given records and compares them.
     */
    private static Boolean recordMatches(
        Rule_Condition__c c, SObject testedRecord, SObject filterRecord
    ) {
        Object fieldValue = resolveField(testedRecord, c.Tested_Field__c);
        String compareTo;
        if (c.Filter_Type__c == FILTER_TYPE_FIELD) {
            Object other = resolveField(filterRecord, c.Filter_Value__c);
            compareTo = other == null ? null : String.valueOf(other);
        } else {
            compareTo = c.Filter_Value__c;
        }
        return compareValues(fieldValue, c.Operator__c, compareTo);
    }

    /**
     * @description Resolves a logical line-item field name against a line map.
     * Returns null when the name is not a recognized line field.
     */
    private static Object resolveLineField(Map<String, Object> line, String fieldName) {
        if (line == null || String.isBlank(fieldName)) {
            return null;
        }
        String key = fieldName.trim().toLowerCase();
        if (key == 'productcode' || key == 'code') { return line.get('productCode'); }
        if (key == 'productname' || key == 'name') { return line.get('productName'); }
        if (key == 'family' || key == 'productfamily') { return line.get('family'); }
        if (key == 'quantity' || key == 'qty') { return line.get('quantity'); }
        if (key == 'unitprice' || key == 'price') { return line.get('unitPrice'); }
        if (key == 'discount' || key == 'discountpercent') { return line.get('discountPercent'); }
        if (key == 'isbundle' || key == 'bundle') { return line.get('isBundle'); }
        return null;
    }

    /**
     * @description Resolves a field path (optionally one relationship hop, e.g. Option_Product__r.Family)
     * against an SObject. Returns null when the path cannot be resolved.
     */
    private static Object resolveField(SObject record, String fieldPath) {
        if (record == null || String.isBlank(fieldPath)) {
            return null;
        }
        try {
            String path = fieldPath.trim();
            if (path.contains('.')) {
                Integer dot = path.indexOf('.');
                SObject parent = record.getSObject(path.substring(0, dot));
                return parent == null ? null : parent.get(path.substring(dot + 1));
            }
            return record.get(path);
        } catch (Exception ex) {
            return null;
        }
    }

    /**
     * @description Compares a resolved field value against a filter value using the given operator.
     * Numeric comparison is used when both sides parse as numbers; otherwise case-insensitive string comparison.
     */
    @TestVisible
    private static Boolean compareValues(Object fieldValue, String operator, String filterValue) {
        String left = fieldValue == null ? '' : String.valueOf(fieldValue);
        String right = filterValue == null ? '' : filterValue;
        Decimal leftNum = tryParseDecimal(left);
        Decimal rightNum = tryParseDecimal(right);
        Boolean numeric = leftNum != null && rightNum != null;

        if (operator == 'equals') {
            return numeric ? leftNum == rightNum : left.equalsIgnoreCase(right);
        }
        if (operator == 'not equals') {
            return numeric ? leftNum != rightNum : !left.equalsIgnoreCase(right);
        }
        if (operator == 'greater than') {
            return numeric ? leftNum > rightNum : left.compareTo(right) > 0;
        }
        if (operator == 'less than') {
            return numeric ? leftNum < rightNum : left.compareTo(right) < 0;
        }
        if (operator == 'contains') {
            return left.toLowerCase().contains(right.toLowerCase());
        }
        if (operator == 'starts with') {
            return left.toLowerCase().startsWith(right.toLowerCase());
        }
        if (operator == 'ends with') {
            return left.toLowerCase().endsWith(right.toLowerCase());
        }
        return false;
    }

    private static Decimal tryParseDecimal(String value) {
        if (String.isBlank(value)) { return null; }
        try {
            return Decimal.valueOf(value.trim());
        } catch (Exception ex) {
            return null;
        }
    }

    private static Id toId(Object value) {
        if (value == null) { return null; }
        if (value instanceof Id) { return (Id) value; }
        try {
            return Id.valueOf(String.valueOf(value));
        } catch (Exception ex) {
            return null;
        }
    }

    private static void applyActions(Product_Rule__c rule, Map<Id, OptionState> optionById) {
        for (Rule_Action__c action : rule.Rule_Actions__r) {
            for (OptionState state : resolveTargets(action, optionById)) {
                applyAction(action.Type__c, state);
            }
        }
    }

    private static List<OptionState> resolveTargets(
        Rule_Action__c action, Map<Id, OptionState> optionById
    ) {
        List<OptionState> targets = new List<OptionState>();
        for (OptionState state : optionById.values()) {
            if (action.Target_Product__c != null) {
                if (state.record.Option_Product__c == action.Target_Product__c) {
                    targets.add(state);
                }
            } else if (String.isNotBlank(action.Filter_Field__c)) {
                Object fieldValue = resolveField(state.record, action.Filter_Field__c);
                if (compareValues(fieldValue, action.Filter_Operator__c, action.Filter_Value__c)) {
                    targets.add(state);
                }
            }
        }
        return targets;
    }

    private static void applyAction(String actionType, OptionState state) {
        if (actionType == 'Add') { state.selected = true; }
        else if (actionType == 'Remove') { state.selected = false; }
        else if (actionType == 'Hide') { state.hidden = true; }
        else if (actionType == 'Show') { state.hidden = false; }
        else if (actionType == 'Disable') { state.locked = true; }
        else if (actionType == 'Enable') { state.locked = false; }
    }

    private static String messageFor(Product_Rule__c rule) {
        return String.isNotBlank(rule.Message__c)
            ? rule.Message__c
            : 'Rule "' + rule.Name + '" was triggered.';
    }
}
