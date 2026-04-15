/**
 * @description Controller for Opportunity save operations exposed to Lightning Web Components.
 * Delegates business logic to OpportunityService and data access to DAOs.
 * Uses with sharing to enforce record-level security at the boundary.
 */
public with sharing class OpportunityController {

    /**
     * @description Saves an Opportunity with its line items, transport fields, and trips.
     * Replaces all existing line items and upserts trip records.
     *
     * @param opportunityId  The Opportunity ID to save data against.
     * @param lineItems       Line item payloads from the CPQ configurator.
     * @param logistics       Transport configuration and trip data.
     * @return The Opportunity ID on success.
     */
    @AuraEnabled
    public static Id saveOpportunity(Id opportunityId, List<Map<String, Object>> lineItems, Map<String, Object> logistics) {
        try {
            return OpportunityService.saveOpportunityWithLines(opportunityId, lineItems, logistics);
        } catch (OpportunityException e) {
            System.debug(LoggingLevel.ERROR, 'OpportunityController.saveOpportunity: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'OpportunityController.saveOpportunity unexpected error: ' + e.getMessage() + ' | Stack: ' + e.getStackTraceString());
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    /**
     * @description Generates a standardized error message for controller failures.
     * @return Error message string formatted with the Opportunity object label.
     */
    private static String getControllerErrorMessage() {
        return String.format(System.Label.Generic_Controller_Request_Failed, new List<String>{ Opportunity.SObjectType.getDescribe().getLabel() });
    }
}