/**
 * Dispatches Opportunity trigger events to the appropriate OpportunityService methods.
 */
public inherited sharing class OpportunityTriggerHandler {

    /**
     * Routes the current trigger context to the matching service handler.
     * @param newList The list of records in their new state.
     * @param oldMap The map of records in their old state, keyed by record Id.
     */
    public static void handle(List<SObject> newList, Map<Id, SObject> oldMap) {
        if (Trigger.isBefore) {
            if (Trigger.isInsert) {
                beforeInsert(newList);
            } else if (Trigger.isUpdate) {
                beforeUpdate(newList, oldMap);
            } else if (Trigger.isDelete) {
                beforeDelete(oldMap);
            }
        } else if (Trigger.isAfter) {
            if (Trigger.isInsert) {
                afterInsert(newList);
            } else if (Trigger.isUpdate) {
                afterUpdate(newList, oldMap);
            } else if (Trigger.isDelete) {
                afterDelete(oldMap);
            }
        }
    }

    private static void beforeInsert(List<SObject> newList) {
        OpportunityService.beforeInsert(castNewList(newList));
    }

    private static void beforeUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        OpportunityService.beforeUpdate(castNewList(newList), castOldMap(oldMap));
    }

    private static void beforeDelete(Map<Id, SObject> oldMap) {
        OpportunityService.beforeDelete(castOldMap(oldMap));
    }

    private static void afterInsert(List<SObject> newList) {
        List<Opportunity> typedNewList = castNewList(newList);
        OpportunityService.afterInsert(typedNewList);
    }

    private static void afterUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<Opportunity> typedNewList = castNewList(newList);
        Map<Id, Opportunity> typedOldMap = castOldMap(oldMap);
        OpportunityService.afterUpdate(typedNewList, typedOldMap);
    }

    private static void afterDelete(Map<Id, SObject> oldMap) {
        OpportunityService.afterDelete(castOldMap(oldMap));
    }

    // ==========================================
    // UTILITY METHODS (CASTING)
    // ==========================================

    private static List<Opportunity> castNewList(List<SObject> rawRecords) {
        List<Opportunity> typedRecords = new List<Opportunity>();
        if (rawRecords == null) {
            return typedRecords;
        }
        
        for (SObject rawRecord : rawRecords) {
            typedRecords.add((Opportunity) rawRecord);
        }
        return typedRecords;
    }

    private static Map<Id, Opportunity> castOldMap(Map<Id, SObject> rawRecordsById) {
        Map<Id, Opportunity> typedRecordsById = new Map<Id, Opportunity>();
        if (rawRecordsById == null) {
            return typedRecordsById;
        }
        
        for (Id recordId : rawRecordsById.keySet()) {
            typedRecordsById.put(recordId, (Opportunity) rawRecordsById.get(recordId));
        }
        return typedRecordsById;
    }
}