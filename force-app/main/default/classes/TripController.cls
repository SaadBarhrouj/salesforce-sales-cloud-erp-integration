public with sharing class TripController {

    /**
     * @description Fetch existing trips for an opportunity
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
