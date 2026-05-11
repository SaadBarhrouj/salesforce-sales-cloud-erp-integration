/**
 * @description Data Access Object for Opportunity records.
 * Provides query methods to retrieve Opportunity data from the database.
 * Uses inherited sharing to respect record-level security.
 */
public inherited sharing class OpportunityDAO {
    /**
     * @description Retrieves a single Opportunity by ID with all relevant fields.
     * @param recordId The Opportunity record ID
     * @return Opportunity record with all field values, or null if not found
     */
    public static Opportunity getById(Id recordId) {
        if (recordId == null) {
            return null;
        }

        List<Opportunity> records = [
            SELECT
                Id,
                AccountId,
                Amount,
                CampaignId,
                CloseDate,
                ContractId,
                CurrentGenerators__c,
                Default_Agency__c,
                DeliveryInstallationStatus__c,
                Delivery_Site__c,
                Description,
                ExpectedRevenue,
                IqScore,
                IsPrivate,
                Is_Transport_Required__c,
                LeadSource,
                MainCompetitors__c,
                Name,
                NextStep,
                Offer_Type__c,
                OrderNumber__c,
                OwnerId,
                Pricebook2Id,
                Probability,
                StageName,
                TotalOpportunityQuantity,
                Total_Transport_Cost__c,
                TrackingNumber__c,
                Transport_Urgency__c,
                Type,
                Account.Name,
                Campaign.Name,
                Contract.ContractNumber,
                Default_Agency__r.Name,
                Delivery_Site__r.Name,
                Offer_Type__r.Name,
                Owner.Name,
                Pricebook2.Name
            FROM Opportunity
            WHERE Id = :recordId
            LIMIT 1
        ];

        return records.isEmpty() ? null : records[0];
    }

    /**
     * @description Retrieves Opportunities by IDs with location fields for distance calculation.
     * @param opportunityIds Set of Opportunity IDs
     * @return List of Opportunity records with location fields
     */
    public static List<Opportunity> getByIds(Set<Id> opportunityIds) {
        if (opportunityIds == null || opportunityIds.isEmpty()) {
            return new List<Opportunity>();
        }

        try {
            return [
                SELECT Id, Default_Agency__c, Delivery_Site__c
                FROM Opportunity
                WHERE Id IN :opportunityIds
            ];
        } catch (QueryException qe) {
            System.debug(LoggingLevel.ERROR, 'QueryException in getByIdsWithLocations: ' + qe.getMessage());
            throw qe;
        }
    }


    /**
     * @description Updates a single Opportunity record. Performs a partial-update friendly DML.
     * @param record The Opportunity to update. Must include Id.
     */
    public static void updateRecord(Opportunity record) {
        if (record == null || record.Id == null) {
            return;
        }
        try {
            update record;
        } catch (DmlException e) {
            System.debug(LoggingLevel.ERROR, 'OpportunityDAO.updateRecord failed: ' + e.getMessage() + ' | Id: ' + record.Id);
            throw e;
        }
    }


    //     if (recordIds == null || recordIds.isEmpty()) {
    //         return new Map<Id, Opportunity>();
    //     }
    //
    //     return new Map<Id, Opportunity>([
    //         SELECT Id, AccountId, Amount, CampaignId, CloseDate, ContractId, CurrentGenerators__c,
    //             Default_Agency__c, DeliveryInstallationStatus__c, Delivery_Site__c, Description,
    //             ExpectedRevenue, IqScore, IsPrivate, Is_Transport_Required__c, LeadSource,
    //             MainCompetitors__c, Name, NextStep, Offer_Type__c, OrderNumber__c, OwnerId,
    //             Pricebook2Id, Probability, StageName, TotalOpportunityQuantity,
    //             Total_Transport_Cost__c, TrackingNumber__c, Transport_Urgency__c, Type,
    //             Account.Name, Campaign.Name, Contract.ContractNumber, Default_Agency__r.Name,
    //             Delivery_Site__r.Name, Owner.Name, Pricebook2.Name
    //         FROM Opportunity
    //         WHERE Id IN :recordIds
    //     ]);
    // }

    // public static List<Opportunity> getByName(String recordName) {
    //     if (String.isBlank(recordName)) {
    //         return new List<Opportunity>();
    //     }
    //
    //     return [
    //         SELECT Id, AccountId, Amount, CampaignId, CloseDate, ContractId, CurrentGenerators__c,
    //             Default_Agency__c, DeliveryInstallationStatus__c, Delivery_Site__c, Description,
    //             ExpectedRevenue, IqScore, IsPrivate, Is_Transport_Required__c, LeadSource,
    //             MainCompetitors__c, Name, NextStep, Offer_Type__c, OrderNumber__c, OwnerId,
    //             Pricebook2Id, Probability, StageName, TotalOpportunityQuantity,
    //             Total_Transport_Cost__c, TrackingNumber__c, Transport_Urgency__c, Type,
    //             Account.Name, Campaign.Name, Contract.ContractNumber, Default_Agency__r.Name,
    //             Delivery_Site__r.Name, Owner.Name, Pricebook2.Name
    //         FROM Opportunity
    //         WHERE Name = :recordName
    //     ];
    // }

    // public static List<Opportunity> getAll() {
    //     return [
    //         SELECT Id, AccountId, Amount, CampaignId, CloseDate, ContractId, CurrentGenerators__c,
    //             Default_Agency__c, DeliveryInstallationStatus__c, Delivery_Site__c, Description,
    //             ExpectedRevenue, IqScore, IsPrivate, Is_Transport_Required__c, LeadSource,
    //             MainCompetitors__c, Name, NextStep, Offer_Type__c, OrderNumber__c, OwnerId,
    //             Pricebook2Id, Probability, StageName, TotalOpportunityQuantity,
    //             Total_Transport_Cost__c, TrackingNumber__c, Transport_Urgency__c, Type,
    //             Account.Name, Campaign.Name, Contract.ContractNumber, Default_Agency__r.Name,
    //             Delivery_Site__r.Name, Owner.Name, Pricebook2.Name
    //         FROM Opportunity
    //     ];
    // }
}
