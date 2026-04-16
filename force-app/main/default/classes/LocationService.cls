/**
 * @description Service layer for Location business logic.
 * Calls DAO layer and formats data for UI consumption.
 */
public inherited sharing class LocationService {
    
    /**
     * @description Get all Locations for an Account, formatted for LWC
     * @param accountId The Account ID
     * @return List of Locations formatted for LWC combobox
     */
    public static List<Map<String, Object>> getLocationsByAccountFormatted(Id accountId) {
        try {
            List<Schema.Location> locations = LocationDAO.getLocationsByAccountId(accountId);
            return formatLocationsForUI(locations);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'LocationService.getLocationsByAccountFormatted error: ' + e.getMessage());
            throw e;
        }
    }
    
    /**
     * @description Get all Agencies, formatted for LWC
     * @return List of Agencies formatted for LWC combobox
     */
    public static List<Map<String, Object>> getAgenciesFormatted() {
        try {
            List<Schema.Location> agencies = LocationDAO.getLocationsByType('Warehouse');
            return formatLocationsForUI(agencies);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'LocationService.getAgenciesFormatted error: ' + e.getMessage());
            throw e;
        }
    }
    
    /**
     * @description Convert Location records to map format for LWC combobox/display
     * Format: {value, Name, Latitude, Longitude, LocationType, TimeZone}
     * @param locations List of Location records
     * @return List of Maps formatted for LWC display
     */
    private static List<Map<String, Object>> formatLocationsForUI(List<Schema.Location> locations) {
        List<Map<String, Object>> formattedLocations = new List<Map<String, Object>>();
        
        if (locations == null) {
            return formattedLocations;
        }
        
        for (Schema.Location loc : locations) {
            Map<String, Object> locMap = new Map<String, Object>();
            locMap.put('value', loc.Id);
            locMap.put('label', loc.Name);
            locMap.put('Name', loc.Name);
            locMap.put('Latitude', loc.Latitude);
            locMap.put('Longitude', loc.Longitude);
            locMap.put('LocationType', loc.LocationType);
            locMap.put('TimeZone', loc.TimeZone);
            
            formattedLocations.add(locMap);
        }
        
        return formattedLocations;
    }

}
