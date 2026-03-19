public class AccountTriggerHandler {
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
        AccountService.beforeInsert(castNewList(newList));
    }

    private static void beforeUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<Account> typedNewList = castNewList(newList);
        Map<Id, Account> typedOldMap = castOldMap(oldMap);
        AccountService.beforeUpdate(typedNewList, typedOldMap, AccountDAO.getByIds(typedOldMap.keySet()));
    }

    private static void beforeDelete(Map<Id, SObject> oldMap) {
        Map<Id, Account> typedOldMap = castOldMap(oldMap);
        AccountService.beforeDelete(typedOldMap, AccountDAO.getByIds(typedOldMap.keySet()));
    }

    private static void afterInsert(List<SObject> newList) {
        List<Account> typedNewList = castNewList(newList);
        AccountService.afterInsert(AccountDAO.getByIds(collectIds(typedNewList)).values());
    }

    private static void afterUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        List<Account> typedNewList = castNewList(newList);
        Map<Id, Account> typedOldMap = castOldMap(oldMap);
        AccountService.afterUpdate(AccountDAO.getByIds(collectIds(typedNewList)).values(), typedOldMap, AccountDAO.getByIds(typedOldMap.keySet()));
    }

    private static void afterDelete(Map<Id, SObject> oldMap) {
        AccountService.afterDelete(castOldMap(oldMap));
    }

    private static List<Account> castNewList(List<SObject> rawRecords) {
        List<Account> typedRecords = new List<Account>();
        if (rawRecords == null) {
            return typedRecords;
        }
        for (SObject rawRecord : rawRecords) {
            typedRecords.add((Account) rawRecord);
        }
        return typedRecords;
    }

    private static Map<Id, Account> castOldMap(Map<Id, SObject> rawRecordsById) {
        Map<Id, Account> typedRecordsById = new Map<Id, Account>();
        if (rawRecordsById == null) {
            return typedRecordsById;
        }
        for (Id recordId : rawRecordsById.keySet()) {
            typedRecordsById.put(recordId, (Account) rawRecordsById.get(recordId));
        }
        return typedRecordsById;
    }

    private static Set<Id> collectIds(List<Account> records) {
        Set<Id> recordIds = new Set<Id>();
        for (Account recordItem : records) {
            if (recordItem.Id != null) {
                recordIds.add(recordItem.Id);
            }
        }
        return recordIds;
    }
}
