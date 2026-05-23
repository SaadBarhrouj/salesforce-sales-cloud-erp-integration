/**
 * @description Controller layer exposing the Product Rule evaluation engine to Lightning components.
 * @author Sales Cloud ERP Integration Team
 */
public with sharing class ProductRuleController {

    /**
     * @description Evaluates the active Selection rules for a bundle configuration.
     * @param bundleProductId The bundle Product2 Id being configured.
     * @param opportunityId The Opportunity Id (context for Opportunity-tested conditions; may be null).
     * @param selectedOptionIds The Bundle_Option__c Ids currently selected by the rep.
     * @return Map with keys selectedOptionIds, hiddenOptionIds, lockedOptionIds.
     */
    @AuraEnabled
    public static Map<String, Object> evaluateBundleRules(
        Id bundleProductId,
        Id opportunityId,
        List<Id> selectedOptionIds
    ) {
        try {
            Set<Id> selected = selectedOptionIds == null
                ? new Set<Id>()
                : new Set<Id>(selectedOptionIds);
            return ProductRuleService.evaluateBundleRules(bundleProductId, opportunityId, selected);
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * @description Evaluates the active Validation and Alert rules against the line items.
     * @param opportunityId The Opportunity Id (context for Opportunity-tested conditions; may be null).
     * @param lines Line item maps (productId, quantity, unitPrice, discountPercent, isBundle).
     * @return Map with keys validationErrors and alerts (lists of messages).
     */
    @AuraEnabled
    public static Map<String, Object> evaluateLineRules(
        Id opportunityId,
        List<Map<String, Object>> lines
    ) {
        try {
            return ProductRuleService.evaluateLineRules(opportunityId, lines);
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
}
