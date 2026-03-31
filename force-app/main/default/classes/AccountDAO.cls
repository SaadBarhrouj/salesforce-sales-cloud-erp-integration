public inherited sharing class AccountDAO {
    public static Account getById(Id recordId) {
        if (recordId == null) {
            return null;
        }

        List<Account> records = [
            SELECT
                Id,
                AccountNumber,
                AccountSource,
                Active__c,
                AnnualRevenue,
                BillingAddress,
                ChannelProgramLevelName,
                ChannelProgramName,
                CleanStatus,
                CustomerPriority__c,
                DandbCompanyId,
                Description,
                DunsNumber,
                Fax,
                Industry,
                IsCustomerPortal,
                IsPartner,
                Jigsaw,
                NaicsCode,
                NaicsDesc,
                Name,
                NumberOfEmployees,
                NumberofLocations__c,
                OperatingHoursId,
                OwnerId,
                Ownership,
                ParentId,
                Phone,
                Rating,
                SLAExpirationDate__c,
                SLASerialNumber__c,
                SLA__c,
                ShippingAddress,
                Sic,
                SicDesc,
                Site,
                TickerSymbol,
                Tier,
                Tradestyle,
                Type,
                UpsellOpportunity__c,
                Website,
                YearStarted,
                OperatingHours.Name,
                Owner.Name,
                Parent.Name
            FROM Account
            WHERE Id = :recordId
            LIMIT 1
        ];

        return records.isEmpty() ? null : records[0];
    }

    public static Map<Id, Account> getByIds(Set<Id> recordIds) {
        if (recordIds == null || recordIds.isEmpty()) {
            return new Map<Id, Account>();
        }

        return new Map<Id, Account>([
            SELECT
                Id,
                AccountNumber,
                AccountSource,
                Active__c,
                AnnualRevenue,
                BillingAddress,
                ChannelProgramLevelName,
                ChannelProgramName,
                CleanStatus,
                CustomerPriority__c,
                DandbCompanyId,
                Description,
                DunsNumber,
                Fax,
                Industry,
                IsCustomerPortal,
                IsPartner,
                Jigsaw,
                NaicsCode,
                NaicsDesc,
                Name,
                NumberOfEmployees,
                NumberofLocations__c,
                OperatingHoursId,
                OwnerId,
                Ownership,
                ParentId,
                Phone,
                Rating,
                SLAExpirationDate__c,
                SLASerialNumber__c,
                SLA__c,
                ShippingAddress,
                Sic,
                SicDesc,
                Site,
                TickerSymbol,
                Tier,
                Tradestyle,
                Type,
                UpsellOpportunity__c,
                Website,
                YearStarted,
                OperatingHours.Name,
                Owner.Name,
                Parent.Name
            FROM Account
            WHERE Id IN :recordIds
        ]);
    }


    public static List<Account> getByName(String recordName) {
        if (String.isBlank(recordName)) {
            return new List<Account>();
        }

        return [
            SELECT
                Id,
                AccountNumber,
                AccountSource,
                Active__c,
                AnnualRevenue,
                BillingAddress,
                ChannelProgramLevelName,
                ChannelProgramName,
                CleanStatus,
                CustomerPriority__c,
                DandbCompanyId,
                Description,
                DunsNumber,
                Fax,
                Industry,
                IsCustomerPortal,
                IsPartner,
                Jigsaw,
                NaicsCode,
                NaicsDesc,
                Name,
                NumberOfEmployees,
                NumberofLocations__c,
                OperatingHoursId,
                OwnerId,
                Ownership,
                ParentId,
                Phone,
                Rating,
                SLAExpirationDate__c,
                SLASerialNumber__c,
                SLA__c,
                ShippingAddress,
                Sic,
                SicDesc,
                Site,
                TickerSymbol,
                Tier,
                Tradestyle,
                Type,
                UpsellOpportunity__c,
                Website,
                YearStarted,
                OperatingHours.Name,
                Owner.Name,
                Parent.Name
            FROM Account
            WHERE Name = :recordName
        ];
    }

    public static List<Account> getAll() {
        return [
            SELECT
                Id,
                AccountNumber,
                AccountSource,
                Active__c,
                AnnualRevenue,
                BillingAddress,
                ChannelProgramLevelName,
                ChannelProgramName,
                CleanStatus,
                CustomerPriority__c,
                DandbCompanyId,
                Description,
                DunsNumber,
                Fax,
                Industry,
                IsCustomerPortal,
                IsPartner,
                Jigsaw,
                NaicsCode,
                NaicsDesc,
                Name,
                NumberOfEmployees,
                NumberofLocations__c,
                OperatingHoursId,
                OwnerId,
                Ownership,
                ParentId,
                Phone,
                Rating,
                SLAExpirationDate__c,
                SLASerialNumber__c,
                SLA__c,
                ShippingAddress,
                Sic,
                SicDesc,
                Site,
                TickerSymbol,
                Tier,
                Tradestyle,
                Type,
                UpsellOpportunity__c,
                Website,
                YearStarted,
                OperatingHours.Name,
                Owner.Name,
                Parent.Name
            FROM Account
        ];
    }
}
