public inherited sharing class LocationDAO {
    public static Location getById(Id recordId) {
        if (recordId == null) {
            return null;
        }

        List<Location> records = [
            SELECT
                Id,
                CloseDate,
                ConstructionEndDate,
                ConstructionStartDate,
                Country_Code__c,
                Description,
                DrivingDirections,
                EarliestPickupTimeOffset,
                Email,
                ExternalReference,
                Fax,
                IsEligibleForPickup,
                IsInventoryLocation,
                IsMobile,
                LatestPickupTimeOffset,
                Location,
                LocationLevel,
                LocationType,
                LogoId,
                Mobile,
                Name,
                OpenDate,
                OwnerId,
                ParentLocationId,
                Phone,
                PickupProcessingTime,
                PickupProcessingTimeUnit,
                PossessionDate,
                RemodelEndDate,
                RemodelStartDate,
                RootLocationId,
                ShouldSyncWithOci,
                Site_Access__c,
                TimeZone,
                VisitorAddressId,
                Owner.Name
            FROM Location
            WHERE Id = :recordId
            LIMIT 1
        ];

        return records.isEmpty() ? null : records[0];
    }

    public static Map<Id, Location> getByIds(Set<Id> recordIds) {
        if (recordIds == null || recordIds.isEmpty()) {
            return new Map<Id, Location>();
        }

        return new Map<Id, Location>([
            SELECT
                Id,
                CloseDate,
                ConstructionEndDate,
                ConstructionStartDate,
                Country_Code__c,
                Description,
                DrivingDirections,
                EarliestPickupTimeOffset,
                Email,
                ExternalReference,
                Fax,
                IsEligibleForPickup,
                IsInventoryLocation,
                IsMobile,
                LatestPickupTimeOffset,
                Location,
                LocationLevel,
                LocationType,
                LogoId,
                Mobile,
                Name,
                OpenDate,
                OwnerId,
                ParentLocationId,
                Phone,
                PickupProcessingTime,
                PickupProcessingTimeUnit,
                PossessionDate,
                RemodelEndDate,
                RemodelStartDate,
                RootLocationId,
                ShouldSyncWithOci,
                Site_Access__c,
                TimeZone,
                VisitorAddressId,
                Owner.Name
            FROM Location
            WHERE Id IN :recordIds
        ]);
    }


    public static List<Location> getByName(String recordName) {
        if (String.isBlank(recordName)) {
            return new List<Location>();
        }

        return [
            SELECT
                Id,
                CloseDate,
                ConstructionEndDate,
                ConstructionStartDate,
                Country_Code__c,
                Description,
                DrivingDirections,
                EarliestPickupTimeOffset,
                Email,
                ExternalReference,
                Fax,
                IsEligibleForPickup,
                IsInventoryLocation,
                IsMobile,
                LatestPickupTimeOffset,
                Location,
                LocationLevel,
                LocationType,
                LogoId,
                Mobile,
                Name,
                OpenDate,
                OwnerId,
                ParentLocationId,
                Phone,
                PickupProcessingTime,
                PickupProcessingTimeUnit,
                PossessionDate,
                RemodelEndDate,
                RemodelStartDate,
                RootLocationId,
                ShouldSyncWithOci,
                Site_Access__c,
                TimeZone,
                VisitorAddressId,
                Owner.Name
            FROM Location
            WHERE Name = :recordName
        ];
    }

    public static List<Location> getAll() {
        return [
            SELECT
                Id,
                CloseDate,
                ConstructionEndDate,
                ConstructionStartDate,
                Country_Code__c,
                Description,
                DrivingDirections,
                EarliestPickupTimeOffset,
                Email,
                ExternalReference,
                Fax,
                IsEligibleForPickup,
                IsInventoryLocation,
                IsMobile,
                LatestPickupTimeOffset,
                Location,
                LocationLevel,
                LocationType,
                LogoId,
                Mobile,
                Name,
                OpenDate,
                OwnerId,
                ParentLocationId,
                Phone,
                PickupProcessingTime,
                PickupProcessingTimeUnit,
                PossessionDate,
                RemodelEndDate,
                RemodelStartDate,
                RootLocationId,
                ShouldSyncWithOci,
                Site_Access__c,
                TimeZone,
                VisitorAddressId,
                Owner.Name
            FROM Location
        ];
    }
}
