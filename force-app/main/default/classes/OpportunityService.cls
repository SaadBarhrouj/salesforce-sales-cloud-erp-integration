public inherited sharing class OpportunityService {

    public static void beforeInsert(List<Opportunity> newList) {
        System.debug(LoggingLevel.INFO, '=== [OpportunityService] beforeInsert exécuté ===');
    }

    public static void beforeUpdate(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        System.debug(LoggingLevel.INFO, '===[OpportunityService] beforeUpdate exécuté ===');
    }

    public static void beforeDelete(Map<Id, Opportunity> oldMap) {
        System.debug(LoggingLevel.INFO, '=== [OpportunityService] beforeDelete exécuté ===');
    }

    public static void afterInsert(List<Opportunity> newList) {
        System.debug(LoggingLevel.INFO, '=== [OpportunityService] afterInsert exécuté ===');
        
        checkAndEnqueueDistanceCalculation(newList, null);
    }

    public static void afterUpdate(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        System.debug(LoggingLevel.INFO, '=== [OpportunityService] afterUpdate exécuté ===');

        checkAndEnqueueDistanceCalculation(newList, oldMap);
    }

    public static void afterDelete(Map<Id, Opportunity> oldMap) {
        System.debug(LoggingLevel.INFO, '=== [OpportunityService] afterDelete exécuté ===');
    }


    /**
     * @description Checks if an opportunity requires road distance calculation 
     * and enqueues the asynchronous processing (Queueable)
     */
    private static void checkAndEnqueueDistanceCalculation(List<Opportunity> newOpps, Map<Id, Opportunity> oldMap) {
        Set<Id> oppIdsToProcess = new Set<Id>();
        
        for (Opportunity opp : newOpps) {
            if (opp.Default_Agency__c != null && opp.Delivery_Site__c != null) {
                
                if (oldMap == null || 
                    opp.Default_Agency__c != oldMap.get(opp.Id).Default_Agency__c || 
                    opp.Delivery_Site__c != oldMap.get(opp.Id).Delivery_Site__c) {
                    
                    oppIdsToProcess.add(opp.Id);
                }
            }
        }
        
        if (!oppIdsToProcess.isEmpty()) {
            System.enqueueJob(new DistanceCalculationQueueable(oppIdsToProcess));
        }
    }
}
