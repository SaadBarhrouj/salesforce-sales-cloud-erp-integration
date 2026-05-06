/**
 * @description Controller for Location records exposed to Lightning Web Components.
 * Handles location lookups for logistics configuration.
 */
public with sharing class LocationController {
    
    /**
     * @description Get all Locations associated with an Account (for delivery/pickup sites)
     * @param accountId The Account ID
     * @return List of Locations formatted for LWC combobox
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getLocationsByAccount(String accountId) {
        try {
            if (String.isBlank(accountId)) {
                return new List<Map<String, Object>>();
            }
            return LocationService.getLocationsByAccountFormatted((Id)accountId);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'LocationController.getLocationsByAccount error: ' + e.getMessage());
            throw new AuraHandledException('Unable to load account locations');
        }
    }
    
    /**
     * @description Get all Agencies (Locations with type = 'Agency')
     * @return List of Agencies formatted for LWC combobox
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getAllAgencies() {
        return LocationService.getAgenciesFormatted();
    }
    
}