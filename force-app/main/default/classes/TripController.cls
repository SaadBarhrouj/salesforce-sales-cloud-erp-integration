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
     * @description Returns the 3D loading geometry for a record as a JSON array string ready
     * to feed the binPacking3dViewerGl component. On an Opportunity the array holds every
     * trip's bin (fleet view); on a Trip it holds that single bin. Records without geometry
     * are skipped; an empty array is returned when there is nothing to render.
     * @param recordId The Trip or Opportunity record Id from the Lightning record page
     * @param objectApiName The hosting object's API name ('Trip__c' or 'Opportunity')
     * @return a JSON array string of bin geometries (e.g. "[{...},{...}]")
     */
    @AuraEnabled(cacheable=true)
    public static String getPackingGeometry(Id recordId, String objectApiName) {
        try {
            List<Trip__c> trips;
            if (objectApiName == 'Trip__c') {
                trips = TripDAO.getTripById(recordId);
            } else {
                trips = TripDAO.getTripsByOpportunity(recordId);
            }

            List<String> geometries = new List<String>();
            for (Trip__c trip : trips) {
                if (String.isNotBlank(trip.Packing_Geometry__c)) {
                    geometries.add(trip.Packing_Geometry__c);
                }
            }
            return '[' + String.join(geometries, ',') + ']';
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