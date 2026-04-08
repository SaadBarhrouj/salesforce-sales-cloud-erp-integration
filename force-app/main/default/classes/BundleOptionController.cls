/**
 * @description Controller layer for Bundle_Option__c operations exposed to Lightning components.
 * Provides access to bundle configuration data for the bundle configurator LWC.
 * Contains reserved CRUD endpoints for future use when direct option management is needed.
 * @author Sales Cloud ERP Integration Team
 */
public with sharing class BundleOptionController {
    // ============================================================================
    // ACTIVE METHODS - Currently used in bundleConfigure feature
    // ============================================================================

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
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    // ============================================================================
    // HELPER METHODS
    // ============================================================================

    /**
     * @description Generates a standardized error message for controller failures.
     * Formats a system label with the Bundle_Option__c object label.
     * @return Error message string formatted with the object label
     */
    private static String getControllerErrorMessage() {
        return String.format(System.Label.Generic_Controller_Request_Failed, new List<String>{ Bundle_Option__c.SObjectType.getDescribe().getLabel() });
    }

    // ============================================================================
    // RESERVED METHODS FOR FUTURE USE - Uncomment when needed
    // ============================================================================

    // @AuraEnabled(cacheable=true)
    // public static Bundle_Option__c getById(Id recordId) {
        // try {
            // return BundleOptionService.getLoadedRecord(BundleOptionDAO.getById(recordId));
        // } catch (Exception ex) {
            // throw new AuraHandledException(getControllerErrorMessage());
        // }
    // }

    // @AuraEnabled(cacheable=true)
    // public static List<Bundle_Option__c> getByIds(List<Id> recordIds) {
        // try {
            // Set<Id> safeIds = recordIds == null ? new Set<Id>() : new Set<Id>(recordIds);
            // return BundleOptionService.getLoadedRecords(BundleOptionDAO.getByIds(safeIds).values());
        // } catch (Exception ex) {
            // throw new AuraHandledException(getControllerErrorMessage());
        // }
    // }

    // @AuraEnabled(cacheable=true)
    // public static List<Bundle_Option__c> getAll() {
        // try {
            // return BundleOptionService.getLoadedRecords(BundleOptionDAO.getAll());
        // } catch (Exception ex) {
            // throw new AuraHandledException(getControllerErrorMessage());
        // }
    // }

    // @AuraEnabled
    // public static List<Bundle_Option__c> saveRecords(List<Bundle_Option__c> records) {
        // try {
            // Set<Id> recordIds = collectIds(records);
            // Map<Id, Bundle_Option__c> persistedRecordsById = BundleOptionDAO.getByIds(recordIds);
            // List<Bundle_Option__c> savedRecords = BundleOptionService.saveRecords(records, persistedRecordsById);
            // return BundleOptionService.getLoadedRecords(BundleOptionDAO.getByIds(collectIds(savedRecords)).values());
        // } catch (Exception ex) {
            // throw new AuraHandledException(getControllerErrorMessage());
        // }
    // }

    // @AuraEnabled
    // public static Boolean deleteRecords(List<Id> recordIds) {
        // try {
            // Set<Id> safeIds = recordIds == null ? new Set<Id>() : new Set<Id>(recordIds);
            // Map<Id, Bundle_Option__c> loadedRecordsById = BundleOptionDAO.getByIds(safeIds);
            // BundleOptionService.deleteRecords(loadedRecordsById.values());
            // return true;
        // } catch (Exception ex) {
            // throw new AuraHandledException(getControllerErrorMessage());
        // }
    // }

    // private static Set<Id> collectIds(List<Bundle_Option__c> records) {
        // Set<Id> recordIds = new Set<Id>();
        // if (records == null) {
            // return recordIds;
        // }
        // for (Bundle_Option__c recordItem : records) {
            // if (recordItem.Id != null) {
                // recordIds.add(recordItem.Id);
            // }
        // }
        // return recordIds;
    // }
}
