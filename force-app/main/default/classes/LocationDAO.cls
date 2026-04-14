/**
 * @description Data Access Object for Location records.
 * Provides query methods to retrieve Location data and their associations with Accounts.
 */
public inherited sharing class LocationDAO {
    
    /**
     * @description Get all Locations associated with an Account via AssociatedLocation junction.
     * @param accountId The Account ID
     * @return List of Locations associated with the account
     */
    public static List<Schema.Location> getLocationsByAccountId(Id accountId) {
        if (accountId == null) {
            return new List<Schema.Location>();
        }
        
    try {
        return [
            SELECT 
                Id,
                Name,
                LocationType,
                Latitude,
                Longitude,
                TimeZone
            FROM Location
            WHERE Id IN (
                SELECT LocationId 
                FROM AssociatedLocation 
                WHERE ParentRecordId = :accountId 
                AND (ActiveFrom = null OR ActiveFrom <= TODAY)
                AND (ActiveTo = null OR ActiveTo >= TODAY)
            )
            ORDER BY Name ASC
        ];
    } catch (QueryException qe) {
        System.debug(LoggingLevel.ERROR, 'QueryException in getLocationsByAccountId: ' + qe.getMessage());
        throw  qe;
    }
}
    
    /**
     * @description Get all Locations with a specific type (Agency, Warehouse, etc).
     * @param locationType The Location Type (e.g., 'Agency', 'Warehouse')
     * @return List of Locations of that type
     */
    public static List<Schema.Location> getLocationsByType(String locationType) {
        if (locationType == null) {
            return new List<Schema.Location>();
        }
        
        try {
            return  [
                SELECT 
                    Id,
                    Name,
                    LocationType,
                    Latitude,
                    Longitude,
                    TimeZone
                FROM Location
                WHERE LocationType = :locationType
                ORDER BY Name ASC
            ];
        } catch (QueryException qe) {
            System.debug(LoggingLevel.ERROR, 'QueryException in getLocationsByType: ' + qe.getMessage());
            throw  qe;
        }
    }
    
}