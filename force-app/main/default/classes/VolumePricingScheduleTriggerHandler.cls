public class VolumePricingScheduleTriggerHandler {
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
        VolumePricingScheduleService.beforeInsert(castNewList(newList));
    }

    private static void beforeUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<Volume_Pricing_Schedule__c> typedNewList = castNewList(newList);
        Map<Id, Volume_Pricing_Schedule__c> typedOldMap = castOldMap(oldMap);
        VolumePricingScheduleService.beforeUpdate(typedNewList, typedOldMap, VolumePricingScheduleDAO.getByIds(typedOldMap.keySet()));
    }

    private static void beforeDelete(Map<Id, SObject> oldMap) {
        Map<Id, Volume_Pricing_Schedule__c> typedOldMap = castOldMap(oldMap);
        VolumePricingScheduleService.beforeDelete(typedOldMap, VolumePricingScheduleDAO.getByIds(typedOldMap.keySet()));
    }

    private static void afterInsert(List<SObject> newList) {
        List<Volume_Pricing_Schedule__c> typedNewList = castNewList(newList);
        VolumePricingScheduleService.afterInsert(VolumePricingScheduleDAO.getByIds(collectIds(typedNewList)).values());
    }

    private static void afterUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<Volume_Pricing_Schedule__c> typedNewList = castNewList(newList);
        Map<Id, Volume_Pricing_Schedule__c> typedOldMap = castOldMap(oldMap);
        VolumePricingScheduleService.afterUpdate(VolumePricingScheduleDAO.getByIds(collectIds(typedNewList)).values(), typedOldMap, VolumePricingScheduleDAO.getByIds(typedOldMap.keySet()));
    }

    private static void afterDelete(Map<Id, SObject> oldMap) {
        VolumePricingScheduleService.afterDelete(castOldMap(oldMap));
    }

    private static List<Volume_Pricing_Schedule__c> castNewList(List<SObject> rawRecords) {
        List<Volume_Pricing_Schedule__c> typedRecords = new List<Volume_Pricing_Schedule__c>();
        if (rawRecords == null) {
            return typedRecords;
        }
        for (SObject rawRecord : rawRecords) {
            typedRecords.add((Volume_Pricing_Schedule__c) rawRecord);
        }
        return typedRecords;
    }

    private static Map<Id, Volume_Pricing_Schedule__c> castOldMap(Map<Id, SObject> rawRecordsById) {
        Map<Id, Volume_Pricing_Schedule__c> typedRecordsById = new Map<Id, Volume_Pricing_Schedule__c>();
        if (rawRecordsById == null) {
            return typedRecordsById;
        }
        for (Id recordId : rawRecordsById.keySet()) {
            typedRecordsById.put(recordId, (Volume_Pricing_Schedule__c) rawRecordsById.get(recordId));
        }
        return typedRecordsById;
    }

    private static Set<Id> collectIds(List<Volume_Pricing_Schedule__c> records) {
        Set<Id> recordIds = new Set<Id>();
        for (Volume_Pricing_Schedule__c recordItem : records) {
            if (recordItem.Id != null) {
                recordIds.add(recordItem.Id);
            }
        }
        return recordIds;
    }
}
