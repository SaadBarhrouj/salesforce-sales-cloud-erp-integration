/**
 * @description Lightning controller for Trip-related operations.
 * Exposes trip retrieval and calculation methods to LWC components.
 */
public with sharing class TripController {

    /**
     * @description Fetch existing trips for an opportunity
     * @param opportunityId The Opportunity ID to retrieve trips for.
     * @return List of Trip__c records associated with the opportunity.
     */
    @AuraEnabled
    public static List<Trip__c> getTripsByOpportunity(Id opportunityId) {
        try {
            return TripService.getExistingTrips(opportunityId);
        } catch (TripException e) {
            throw new AuraHandledException(e.getMessage());
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description Recalculate and generate new trips when urgency change
     * @param opportunityId The Opportunity ID to calculate trips for.
     * @param urgency The urgency level for trip calculation.
     * @param totalWeight The total weight for trip calculation.
     * @return List of newly calculated Trip__c records.
     */
    @AuraEnabled
    public static List<Trip__c> calculateTrips(Id opportunityId, String urgency, Decimal totalWeight) {
        try {
            return TripService.calculateAndSaveTrips(opportunityId, urgency, totalWeight);
        } catch (TripException e) {
            throw new AuraHandledException(e.getMessage());
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
