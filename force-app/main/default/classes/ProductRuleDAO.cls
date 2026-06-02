/**
 * @description Data Access Object for Product Rule evaluation.
 * Loads the Selection rules assigned to a bundle (configurator) and the global
 * Validation / Alert rules (line editor), and resolves Opportunity field values.
 * @author Sales Cloud ERP Integration Team
 */
public inherited sharing class ProductRuleDAO {

    private static final Pattern FIELD_PATH_PATTERN =
        Pattern.compile('^[A-Za-z0-9_]+(\\.[A-Za-z0-9_]+)*$');

    /**
     * @description Returns the active Selection rules assigned to a bundle, with their
     * conditions and actions, ordered for deterministic evaluation in the configurator.
     * @param bundleProductId The bundle Product2 Id.
     * @return List of Product_Rule__c ordered by Evaluation_Order__c, or empty when input is null.
     */
    public static List<Product_Rule__c> getActiveBundleRules(Id bundleProductId) {
        if (bundleProductId == null) {
            return new List<Product_Rule__c>();
        }
        Set<Id> ruleIds = new Set<Id>();
        for (Bundle_Rule_Assignment__c assignment : [
            SELECT Product_Rule__c
            FROM Bundle_Rule_Assignment__c
            WHERE Bundle_Product__c = :bundleProductId
              AND Is_Active__c = true
              AND Product_Rule__c != null
        ]) {
            ruleIds.add(assignment.Product_Rule__c);
        }
        if (ruleIds.isEmpty()) {
            return new List<Product_Rule__c>();
        }
        return [
            SELECT Id, Name, Type__c, Conditions_Met__c, Advanced_Condition__c,
                   Evaluation_Order__c, Message__c,
                   (SELECT Id, Tested_Object__c, Tested_Field__c, Operator__c,
                           Filter_Type__c, Filter_Value__c, Index__c
                    FROM Rule_Conditions__r),
                   (SELECT Id, Type__c, Target_Product__c, Filter_Field__c,
                           Filter_Operator__c, Filter_Value__c, Sort_Order__c
                    FROM Rule_Actions__r
                    ORDER BY Sort_Order__c ASC NULLS LAST)
            FROM Product_Rule__c
            WHERE Id IN :ruleIds
              AND Is_Active__c = true
              AND Type__c = 'Selection'
            ORDER BY Evaluation_Order__c ASC NULLS LAST, Name ASC
        ];
    }

    /**
     * @description Returns all active Validation and Alert rules, with their conditions,
     * for evaluation against the whole set of line items on the Line Editor.
     * @return List of Product_Rule__c ordered by Evaluation_Order__c.
     */
    public static List<Product_Rule__c> getActiveLineRules() {
        return [
            SELECT Id, Name, Type__c, Conditions_Met__c, Advanced_Condition__c,
                   Evaluation_Order__c, Message__c,
                   (SELECT Id, Tested_Object__c, Tested_Field__c, Operator__c,
                           Filter_Type__c, Filter_Value__c, Index__c
                    FROM Rule_Conditions__r)
            FROM Product_Rule__c
            WHERE Is_Active__c = true
              AND Type__c IN ('Validation', 'Alert')
            ORDER BY Evaluation_Order__c ASC NULLS LAST, Name ASC
        ];
    }

    /**
     * @description Dynamically queries a single Opportunity, selecting only the given field paths.
     * Field paths are sanitized against a strict pattern to prevent SOQL injection; invalid paths are skipped.
     * @param opportunityId The Opportunity Id to load.
     * @param fieldPaths The set of field API names / relationship paths to select.
     * @return The Opportunity record, or null when input is null/empty or no valid fields requested.
     */
    public static Opportunity getOpportunityForRules(Id opportunityId, Set<String> fieldPaths) {
        if (opportunityId == null || fieldPaths == null || fieldPaths.isEmpty()) {
            return null;
        }
        Set<String> selectFields = new Set<String>{ 'Id' };
        for (String path : fieldPaths) {
            if (String.isNotBlank(path) && FIELD_PATH_PATTERN.matcher(path.trim()).matches()) {
                selectFields.add(path.trim());
            }
        }
        if (selectFields.size() == 1) {
            return null;
        }
        String soql = 'SELECT ' + String.join(new List<String>(selectFields), ', ')
                     + ' FROM Opportunity WHERE Id = :opportunityId LIMIT 1';
        List<Opportunity> records = Database.query(soql);
        return records.isEmpty() ? null : records[0];
    }
}
