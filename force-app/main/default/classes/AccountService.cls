public inherited sharing class AccountService {
    public class ServiceException extends Exception {}

    private static final List<String> TRACKED_FIELDS = new List<String>{
        'Id',
        'AccountNumber',
        'AccountSource',
        'Active__c',
        'AnnualRevenue',
        'BillingAddress',
        'ChannelProgramLevelName',
        'ChannelProgramName',
        'CleanStatus',
        'CustomerPriority__c',
        'DandbCompanyId',
        'Description',
        'DunsNumber',
        'Fax',
        'Industry',
        'IsCustomerPortal',
        'IsPartner',
        'Jigsaw',
        'NaicsCode',
        'NaicsDesc',
        'Name',
        'NumberOfEmployees',
        'NumberofLocations__c',
        'OperatingHoursId',
        'OwnerId',
        'Ownership',
        'ParentId',
        'Phone',
        'Rating',
        'SLAExpirationDate__c',
        'SLASerialNumber__c',
        'SLA__c',
        'ShippingAddress',
        'Sic',
        'SicDesc',
        'Site',
        'TickerSymbol',
        'Tier',
        'Tradestyle',
        'Type',
        'UpsellOpportunity__c',
        'Website',
        'YearStarted'
    };
    private static final List<String> REQUIRED_FIELDS = new List<String>{
        'Name'
    };

    public static Account getLoadedRecord(Account loadedRecord) {
        return loadedRecord;
    }

    public static List<Account> getLoadedRecords(List<Account> loadedRecords) {
        return loadedRecords == null ? new List<Account>() : loadedRecords;
    }

    public static List<Account> saveRecords(List<Account> records, Map<Id, Account> persistedRecordsById) {
        validateCollection(records);

        Map<Id, Account> safePersistedRecordsById = persistedRecordsById == null
            ? new Map<Id, Account>()
            : persistedRecordsById;
        List<Account> recordsToInsert = new List<Account>();
        List<Account> recordsToUpdate = new List<Account>();

        for (Account recordItem : records) {
            validateRequiredFields(recordItem);
            if (recordItem.Id == null) {
                recordsToInsert.add(recordItem);
                continue;
            }

            if (!safePersistedRecordsById.containsKey(recordItem.Id)) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Not_Found, new List<String>{ getObjectLabel() }));
            }

            if (hasChanges(recordItem, safePersistedRecordsById.get(recordItem.Id))) {
                recordsToUpdate.add(recordItem);
            }
        }

        if (!recordsToInsert.isEmpty()) {
            insert recordsToInsert;
        }
        if (!recordsToUpdate.isEmpty()) {
            update recordsToUpdate;
        }

        return records;
    }

    public static void deleteRecords(List<Account> records) {
        validateCollection(records);
        for (Account recordItem : records) {
            if (recordItem.Id == null) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
        }
        delete records;
    }

    public static void beforeInsert(List<Account> newRecords) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }

        for (Account recordItem : newRecords) {
            validateRequiredFields(recordItem);
        }
    }

    public static void beforeUpdate(List<Account> newRecords, Map<Id, Account> oldRecordsById, Map<Id, Account> persistedRecordsById) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }

        Map<Id, Account> safePersistedRecordsById = persistedRecordsById == null
            ? new Map<Id, Account>()
            : persistedRecordsById;

        for (Account recordItem : newRecords) {
            if (recordItem.Id == null) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
            if (!safePersistedRecordsById.containsKey(recordItem.Id)) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Not_Found, new List<String>{ getObjectLabel() }));
            }
            validateRequiredFields(recordItem);
        }
    }

    public static void beforeDelete(Map<Id, Account> oldRecordsById, Map<Id, Account> loadedRecordsById) {
        if (loadedRecordsById == null || loadedRecordsById.isEmpty()) {
            return;
        }

        for (Account recordItem : loadedRecordsById.values()) {
            if (recordItem.Id == null) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
        }
    }

    public static void afterInsert(List<Account> newRecords) {
        getLoadedRecords(newRecords);
    }

    public static void afterUpdate(List<Account> newRecords, Map<Id, Account> oldRecordsById, Map<Id, Account> persistedRecordsById) {
        getLoadedRecords(newRecords);
    }

    public static void afterDelete(Map<Id, Account> oldRecordsById) {
        if (oldRecordsById == null) {
            return;
        }
    }

    private static void validateCollection(List<Account> records) {
        if (records == null || records.isEmpty()) {
            throw new ServiceException(formatLabel(System.Label.Generic_Service_Records_Required, new List<String>{ getObjectLabel() }));
        }
    }

    private static void validateRequiredFields(Account recordItem) {
        Map<String, Schema.SObjectField> fieldMap = Account.SObjectType.getDescribe().fields.getMap();
        for (String fieldApiName : REQUIRED_FIELDS) {
            Object rawValue = recordItem.get(fieldApiName);
            Boolean isMissing = rawValue == null;
            if (rawValue instanceof String) {
                isMissing = String.isBlank((String) rawValue);
            }
            if (isMissing) {
                String fieldLabel = fieldMap.containsKey(fieldApiName)
                    ? fieldMap.get(fieldApiName).getDescribe().getLabel()
                    : fieldApiName;
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Field_Required, new List<String>{ fieldLabel, getObjectLabel() }));
            }
        }
    }

    private static Boolean hasChanges(Account currentRecord, Account persistedRecord) {
        for (String fieldApiName : TRACKED_FIELDS) {
            if (valuesDiffer(currentRecord.get(fieldApiName), persistedRecord.get(fieldApiName))) {
                return true;
            }
        }
        return false;
    }

    private static Boolean valuesDiffer(Object leftValue, Object rightValue) {
        return String.valueOf(leftValue) != String.valueOf(rightValue);
    }

    private static String getObjectLabel() {
        return Account.SObjectType.getDescribe().getLabel();
    }

    private static String formatLabel(String labelValue, List<String> tokens) {
        return String.format(labelValue, tokens);
    }
}
