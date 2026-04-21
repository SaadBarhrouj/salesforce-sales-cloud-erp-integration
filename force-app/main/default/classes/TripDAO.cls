public inherited sharing class TripDAO {
    
    /**
     * @description Retrieve Trips related to a specific Opportunity
     * @param opportunityId The ID of the Opportunity
     * @return List of Trip__c records
     */
    public static List<Trip__c> getTripsByOpportunity(Id opportunityId) {
        try {
            return [
                SELECT Id, System_Price__c, Final_Price__c, 
                       Override_Reason__c, Is_Price_Overridden__c, Truck_Type__c, 
                       Direction__c, Trip_Key__c, Transport_Zone__c, Total_Weight_Kg__c, Status__c
                FROM Trip__c
                WHERE Opportunity__c = :opportunityId
            ];
        } catch (QueryException e) {
            System.debug(LoggingLevel.ERROR, 'TripDAO.getTripsByOpportunity failed: ' + e.getMessage() + ' | OpportunityId: ' + opportunityId);
            throw e;
        }
    }
    
    /**
     * @description Delete existing trips for an opportunity
     * @param opportunityId The ID of the Opportunity
     */
    public static void deleteTripsByOpportunity(Id opportunityId) {
        List<Trip__c> trips = getTripsByOpportunity(opportunityId);
        if (!trips.isEmpty()) {
            try {
                delete as system trips;
            } catch (DmlException e) {
                System.debug(LoggingLevel.ERROR, 'TripDAO.deleteTripsByOpportunity failed: ' + e.getMessage());
                throw e;
            }
        }
    }
    
    /**
     * @description Insert or update trips
     * @param trips List of Trips
     */
    public static void upsertTrips(List<Trip__c> trips) {
        if (!trips.isEmpty()) {
            try {
                upsert as system trips;
            } catch (DmlException e) {
                System.debug(LoggingLevel.ERROR, 'TripDAO.upsertTrips failed: ' + e.getMessage());
                throw e;
            }
        }
    }

}
