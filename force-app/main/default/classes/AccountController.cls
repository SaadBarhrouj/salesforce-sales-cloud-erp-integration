public with sharing class AccountController {
    @AuraEnabled(cacheable=true)
    public static Account getById(Id recordId) {
        try {
            return AccountService.getLoadedRecord(AccountDAO.getById(recordId));
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Account> getByIds(List<Id> recordIds) {
        try {
            Set<Id> safeIds = recordIds == null ? new Set<Id>() : new Set<Id>(recordIds);
            return AccountService.getLoadedRecords(AccountDAO.getByIds(safeIds).values());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Account> getAll() {
        try {
            return AccountService.getLoadedRecords(AccountDAO.getAll());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled
    public static List<Account> saveRecords(List<Account> records) {
        try {
            Set<Id> recordIds = collectIds(records);
            Map<Id, Account> persistedRecordsById = AccountDAO.getByIds(recordIds);
            List<Account> savedRecords = AccountService.saveRecords(records, persistedRecordsById);
            return AccountService.getLoadedRecords(AccountDAO.getByIds(collectIds(savedRecords)).values());
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    @AuraEnabled
    public static Boolean deleteRecords(List<Id> recordIds) {
        try {
            Set<Id> safeIds = recordIds == null ? new Set<Id>() : new Set<Id>(recordIds);
            Map<Id, Account> loadedRecordsById = AccountDAO.getByIds(safeIds);
            AccountService.deleteRecords(loadedRecordsById.values());
            return true;
        } catch (Exception ex) {
            throw new AuraHandledException(getControllerErrorMessage());
        }
    }

    private static Set<Id> collectIds(List<Account> records) {
        Set<Id> recordIds = new Set<Id>();
        if (records == null) {
            return recordIds;
        }
        for (Account recordItem : records) {
            if (recordItem.Id != null) {
                recordIds.add(recordItem.Id);
            }
        }
        return recordIds;
    }

    private static String getControllerErrorMessage() {
        return String.format(System.Label.Generic_Controller_Request_Failed, new List<String>{ Account.SObjectType.getDescribe().getLabel() });
    }
}
