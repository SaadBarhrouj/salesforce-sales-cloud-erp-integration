/**
 * @description Controller layer for Bundle_Option__c operations exposed to Lightning components.
 * Provides access to bundle configuration data for the bundle configurator LWC.
 * @author Sales Cloud ERP Integration Team
 */
public with sharing class BundleOptionController {

    /**
     * @description Retrieves complete bundle configuration data including all features and options.
     * Decorated with @AuraEnabled(cacheable=true) for optimal performance in LWC.
     * Bundle name is fetched separately via LDS getRecord in LWC.
     * @param bundleId The ID of the bundle product to retrieve configuration for
     * @return Map containing organized feature/option hierarchy
     * @throws AuraHandledException If bundle not found or service error occurs
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getBundleData(Id bundleId) {
        try {
            return BundleOptionService.getBundleData(bundleId);
        } catch (BundleOptionException ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * @description Resolves Bundle_Option__c metadata for a set of (parentProductId, optionProductId) pairs.
     * Used by cpqStepLineEditor on reload to enrich saved option rows when the configurator payload
     * does not carry optionType / defaultQuantity.
     * @param parentToOptionIds Map of parent bundle Product2 Id to the list of option Product2 Ids.
     * @return Map keyed by "parentId|optionId" pointing to the metadata payload.
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Map<String, Object>> getOptionMetadata(Map<Id, List<Id>> parentToOptionIds) {
        if (parentToOptionIds == null) {
            return new Map<String, Map<String, Object>>();
        }
        Map<Id, Set<Id>> normalized = new Map<Id, Set<Id>>();
        for (Id parentId : parentToOptionIds.keySet()) {
            normalized.put(parentId, new Set<Id>(parentToOptionIds.get(parentId)));
        }
        return BundleOptionService.getOptionMetadata(normalized);
    }
}