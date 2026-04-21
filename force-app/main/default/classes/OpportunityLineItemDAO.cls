/**
 * @description Data Access Object for OpportunityLineItem records.
 * Provides query and DML methods for line items related to an Opportunity.
 * Uses inherited sharing to respect record-level security.
 */
public inherited sharing class OpportunityLineItemDAO {

    /**
     * @description Retrieves all OpportunityLineItem records for a given Opportunity.
     * @param opportunityId The Opportunity ID to query line items for.
     * @return List of OpportunityLineItem records, or empty list if none found.
     */
    public static List<OpportunityLineItem> getByOpportunityId(Id opportunityId) {
        if (opportunityId == null) {
            return new List<OpportunityLineItem>();
        }

    try {
            return [
                SELECT Id, OpportunityId, PricebookEntryId, Product2Id,
                       Quantity, UnitPrice, ListPrice, Discount, TotalPrice,
                       Is_Bundle_Product__c, Bundle_Group__c,
                       Departure_Agency__c, Delivery_Date__c,
                       Pickup_Date__c, Rental_Start_Date__c, Rental_End_Date__c,
                       Trip_Delivery__c, Trip_Pickup__c
                FROM OpportunityLineItem
                WHERE OpportunityId = :opportunityId
            ];
        } catch (QueryException e) {
            System.debug(LoggingLevel.ERROR, 'OpportunityLineItemDAO.getByOpportunityId failed: ' + e.getMessage());
            throw e;
        }
    }

    /**
     * @description Deletes all OpportunityLineItem records for a given Opportunity.
     * @param opportunityId The Opportunity ID whose line items should be deleted.
     */
    public static void deleteByOpportunityId(Id opportunityId) {
        List<OpportunityLineItem> items = getByOpportunityId(opportunityId);
        if (!items.isEmpty()) {
            try {
                delete as system items;
            } catch (DmlException e) {
                System.debug(LoggingLevel.ERROR, 'OpportunityLineItemDAO.deleteByOpportunityId failed: ' + e.getMessage());
                throw e;
            }
        }
    }

    /**
     * @description Inserts a list of OpportunityLineItem records.
     * @param items The list of OpportunityLineItem records to insert.
     * @return The inserted OpportunityLineItem records with IDs populated.
     */
    public static List<OpportunityLineItem> insertLineItems(List<OpportunityLineItem> items) {
        if (items == null || items.isEmpty()) {
            return items;
        }

        try {
            insert as system items;
            return items;
        } catch (DmlException e) {
            System.debug(LoggingLevel.ERROR, 'OpportunityLineItemDAO.insertLineItems failed: ' + e.getMessage());
            throw e;
        }
    }
}