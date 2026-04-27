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
}
