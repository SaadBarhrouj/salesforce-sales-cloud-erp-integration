/**
 * @description Service layer for Trip business logic.
 * Handles trip calculation, retrieval, and persistence operations.
 */
public inherited sharing class TripService {
    
    /**
     * @description Calculates new trips and replaces the old ones
     * @param opportunityId The Opportunity ID to associate trips with.
     * @param urgency The urgency level for trip calculation.
     * @param totalWeight The total weight for trip calculation.
     * @return List of newly created Trip__c records.
     */
    public static List<Trip__c> calculateAndSaveTrips(Id opportunityId, String urgency, Decimal totalWeight) {
        try {
            if (opportunityId == null) {
                throw new TripException('OpportunityId cannot be null');
            }
            
            // 1. Delete previous trips
            TripDAO.deleteTripsByOpportunity(opportunityId);
            
            // 2. Logic Metier: Calculate distances, select trucks, determine price
            List<Trip__c> newTrips = new List<Trip__c>();
            
            // Simulate a trip based on the agency (departure) and delivery site (destination)
            Decimal baseDistance = 150.0;
            Decimal basePrice = 2000.0;
            if (urgency == 'Urgent') {
                basePrice = basePrice * 1.5;
            }
            
            Trip__c trip = new Trip__c();
            trip.Opportunity__c = opportunityId;
            trip.Truck_Type__c = 'Standard Van - ' + urgency;
            trip.Distance_Km__c = baseDistance;
            trip.System_Price__c = basePrice;
            trip.Final_Price__c = basePrice;
            trip.Direction__c = 'Outbound';
            
            newTrips.add(trip);
            
            // 3. Save new trips
            TripDAO.upsertTrips(newTrips);
            
            return newTrips;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'TripService.calculateAndSaveTrips failed: ' + e.getMessage());
            throw new TripException('Error calculating and saving trips: ' + e.getMessage(), e);
        }
    }
    
    /**
     * @description Gets existing trips for an opportunity
     * @param opportunityId The Opportunity ID to look up trips for.
     * @return List of Trip__c records associated with the opportunity.
     */
    public static List<Trip__c> getExistingTrips(Id opportunityId) {
        try {
            return TripDAO.getTripsByOpportunity(opportunityId);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'TripService.getExistingTrips failed: ' + e.getMessage());
            throw new TripException('Error fetching existing trips: ' + e.getMessage(), e);
        }
    }
    
    /**
     * @description Updates existing trips
     * @param trips List of Trip__c records to upsert.
     */
    public static void updateTrips(List<Trip__c> trips) {
        try {
            TripDAO.upsertTrips(trips);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'TripService.updateTrips failed: ' + e.getMessage());
            throw new TripException('Error updating trips: ' + e.getMessage(), e);
        }
    }
}
