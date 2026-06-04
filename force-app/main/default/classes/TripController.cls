/**
 * @description Lightning controller for Trip-related operations.
 * Exposes trip retrieval and calculation methods to LWC components.
 */
public with sharing class TripController {

    /**
     * @description Retrieve existing trips for an Opportunity
     * @param opportunityId The Opportunity ID
     * @return List of Trip__c records
     */
    @AuraEnabled(cacheable=true)
    public static List<Trip__c> getTripsByOpportunity(Id opportunityId) {
        try {
            return TripDAO.getTripsByOpportunity(opportunityId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description Recalculate and generate trips with cost-optimized truck allocation.
     * @param opportunityId The Opportunity ID
     * @param agencyId Departure agency Location Id (current LWC selection)
     * @param deliverySiteId Delivery Location Id (current LWC selection)
     * @param urgency Transport urgency level
     * @param cpqItemsJson JSON serialized array of CPQ items with dimensions and weight
     * @param directionMode Optional 'Delivery' (default), 'Pickup', or 'Both'. Used for rental opportunities
     *        where the wizard asks whether to generate delivery, pickup, or both sets of trips.
     * @return List of calculated Trip records
     */
    @AuraEnabled
    public static List<Trip__c> calculateTripsWithCPQItems(
        Id opportunityId,
        Id agencyId,
        Id deliverySiteId,
        String urgency,
        String cpqItemsJson,
        String directionMode
    ) {
        try {
            return TripService.calculateTripsWithCPQItems(opportunityId, agencyId, deliverySiteId, urgency, cpqItemsJson, directionMode);
        } catch (TripService.TripException e) {
            throw new AuraHandledException(e.getMessage());
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}