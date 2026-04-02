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
                Owner.Name,
                Pricebook2.Name
            FROM Opportunity
            WHERE Id = :recordId
            LIMIT 1
        ];

        return records.isEmpty() ? null : records[0];
    }



    //
    // public static Map<Id, Opportunity> getByIds(Set<Id> recordIds) {
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
