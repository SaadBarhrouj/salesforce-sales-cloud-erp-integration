/**
 * @description Propagates service fields from parent OpportunityLineItem onto QuoteLineItem.
 * Runs before insert and before update, only filling fields that are blank on the QLI,
 * so manual overrides on the QLI are preserved.
 */
public inherited sharing class QuoteLineItemTriggerHandler {

    /**
     * @description Routes before-insert and before-update events.
     * @param newList The list of new QuoteLineItem records.
     * @param oldMap Map of old QuoteLineItem records by ID (null on insert).
     */
    public static void handleBefore(List<QuoteLineItem> newList, Map<Id, QuoteLineItem> oldMap) {
        Set<Id> oliIds = new Set<Id>();
        for (QuoteLineItem qli : newList) {
            if (qli.OpportunityLineItemId != null) {
                oliIds.add(qli.OpportunityLineItemId);
            }
        }
        if (oliIds.isEmpty()) {
            return;
        }

        Map<Id, OpportunityLineItem> oliById = new Map<Id, OpportunityLineItem>([
            SELECT Id, Service_Start_Date__c, Service_End_Date__c, Daily_Rate__c
            FROM OpportunityLineItem
            WHERE Id IN :oliIds
        ]);

        for (QuoteLineItem qli : newList) {
            if (qli.OpportunityLineItemId == null) {
                continue;
            }
            OpportunityLineItem parent = oliById.get(qli.OpportunityLineItemId);
            if (parent == null) {
                continue;
            }
            if (qli.Service_Start_Date__c == null) {
                qli.Service_Start_Date__c = parent.Service_Start_Date__c;
            }
            if (qli.Service_End_Date__c == null) {
                qli.Service_End_Date__c = parent.Service_End_Date__c;
            }
            if (qli.Daily_Rate__c == null) {
                qli.Daily_Rate__c = parent.Daily_Rate__c;
            }
            // Service_Days__c on QLI is a formula - no copy needed.
        }
    }
}