public inherited sharing class OpportunityService {
    public class ServiceException extends Exception {}

    private static final List<String> TRACKED_FIELDS = new List<String>{
        'Id',
        'AccountId',
        'Amount',
        'CampaignId',
        'CloseDate',
        'ContractId',
        'CurrentGenerators__c',
        'Default_Agency__c',
        'DeliveryInstallationStatus__c',
        'Delivery_Site__c',
        'Description',
        'ExpectedRevenue',
        'IqScore',
        'IsPrivate',
        'Is_Transport_Required__c',
        'LeadSource',
        'MainCompetitors__c',
        'Name',
        'NextStep',
        'Offer_Type__c',
        'OrderNumber__c',
        'OwnerId',
        'Pricebook2Id',
        'Probability',
        'StageName',
        'TotalOpportunityQuantity',
        'Total_Transport_Cost__c',
        'TrackingNumber__c',
        'Transport_Urgency__c',
        'Type'
    };
    private static final List<String> REQUIRED_FIELDS = new List<String>{
        'Name',
        'StageName',
        'CloseDate',
        'AccountId'
    };

    public static Opportunity getLoadedRecord(Opportunity loadedRecord) {
        return loadedRecord;
    }

    public static List<Opportunity> getLoadedRecords(List<Opportunity> loadedRecords) {
        return loadedRecords == null ? new List<Opportunity>() : loadedRecords;
    }

    public static List<Opportunity> saveRecords(List<Opportunity> records, Map<Id, Opportunity> persistedRecordsById) {
        validateCollection(records);

        Map<Id, Opportunity> safePersistedRecordsById = persistedRecordsById == null
            ? new Map<Id, Opportunity>()
            : persistedRecordsById;
        List<Opportunity> recordsToInsert = new List<Opportunity>();
        List<Opportunity> recordsToUpdate = new List<Opportunity>();

        for (Opportunity recordItem : records) {
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

    public static void deleteRecords(List<Opportunity> records) {
        validateCollection(records);
        for (Opportunity recordItem : records) {
            if (recordItem.Id == null) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
        }
        delete records;
    }

    public static void beforeInsert(List<Opportunity> newRecords) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }

        for (Opportunity recordItem : newRecords) {
            validateRequiredFields(recordItem);
        }
    }

    public static void beforeUpdate(List<Opportunity> newRecords, Map<Id, Opportunity> oldRecordsById, Map<Id, Opportunity> persistedRecordsById) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }

        Map<Id, Opportunity> safePersistedRecordsById = persistedRecordsById == null
            ? new Map<Id, Opportunity>()
            : persistedRecordsById;

        for (Opportunity recordItem : newRecords) {
            if (recordItem.Id == null) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
            if (!safePersistedRecordsById.containsKey(recordItem.Id)) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Not_Found, new List<String>{ getObjectLabel() }));
            }
            validateRequiredFields(recordItem);
        }
    }

    public static void beforeDelete(Map<Id, Opportunity> oldRecordsById, Map<Id, Opportunity> loadedRecordsById) {
        if (loadedRecordsById == null || loadedRecordsById.isEmpty()) {
            return;
        }

        for (Opportunity recordItem : loadedRecordsById.values()) {
            if (recordItem.Id == null) {
                throw new ServiceException(formatLabel(System.Label.Generic_Service_Record_Id_Required, new List<String>{ getObjectLabel() }));
            }
        }
    }

    public static void afterInsert(List<Opportunity> newRecords) {
        getLoadedRecords(newRecords);
    }

    public static void afterUpdate(List<Opportunity> newRecords, Map<Id, Opportunity> oldRecordsById, Map<Id, Opportunity> persistedRecordsById) {
        getLoadedRecords(newRecords);
    }

    public static void afterDelete(Map<Id, Opportunity> oldRecordsById) {
        if (oldRecordsById == null) {
            return;
        }
    }

    private static void validateCollection(List<Opportunity> records) {
        if (records == null || records.isEmpty()) {
            throw new ServiceException(formatLabel(System.Label.Generic_Service_Records_Required, new List<String>{ getObjectLabel() }));
        }
    }

    private static void validateRequiredFields(Opportunity recordItem) {
        Map<String, Schema.SObjectField> fieldMap = Opportunity.SObjectType.getDescribe().fields.getMap();
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

    private static Boolean hasChanges(Opportunity currentRecord, Opportunity persistedRecord) {
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
        return Opportunity.SObjectType.getDescribe().getLabel();
    }

    private static String formatLabel(String labelValue, List<String> tokens) {
        return String.format(labelValue, tokens);
    }
}
