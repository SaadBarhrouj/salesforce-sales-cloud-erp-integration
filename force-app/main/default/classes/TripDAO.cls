public inherited sharing class TripDAO {
    public static Trip__c getById(Id recordId) {
        if (recordId == null) {
            return null;
        }

        List<Trip__c> records = [
            SELECT
                Id,
                Name,
                Calculation_Detail__c,
                Country_Code__c,
                Departure_Location__c,
                Destination_Location__c,
                Direction__c,
                Distance_Km__c,
                Final_Price__c,
                Is_Price_Overridden__c,
                Opportunity__c,
                Override_Reason__c,
                Price_Before_Conversion__c,
                Rate_Currency__c,
                Status__c,
                System_Price__c,
                Total_Weight_Kg__c,
                Transport_Zone__c,
                Trip_Date__c,
                Trip_Key__c,
                Truck_Type__c,
                Departure_Location__r.Name,
                Destination_Location__r.Name,
                Opportunity__r.Name
            FROM Trip__c
            WHERE Id = :recordId
            LIMIT 1
        ];

        return records.isEmpty() ? null : records[0];
    }

    public static Map<Id, Trip__c> getByIds(Set<Id> recordIds) {
        if (recordIds == null || recordIds.isEmpty()) {
            return new Map<Id, Trip__c>();
        }

        return new Map<Id, Trip__c>([
            SELECT
                Id,
                Name,
                Calculation_Detail__c,
                Country_Code__c,
                Departure_Location__c,
                Destination_Location__c,
                Direction__c,
                Distance_Km__c,
                Final_Price__c,
                Is_Price_Overridden__c,
                Opportunity__c,
                Override_Reason__c,
                Price_Before_Conversion__c,
                Rate_Currency__c,
                Status__c,
                System_Price__c,
                Total_Weight_Kg__c,
                Transport_Zone__c,
                Trip_Date__c,
                Trip_Key__c,
                Truck_Type__c,
                Departure_Location__r.Name,
                Destination_Location__r.Name,
                Opportunity__r.Name
            FROM Trip__c
            WHERE Id IN :recordIds
        ]);
    }


    public static List<Trip__c> getByName(String recordName) {
        if (String.isBlank(recordName)) {
            return new List<Trip__c>();
        }

        return [
            SELECT
                Id,
                Name,
                Calculation_Detail__c,
                Country_Code__c,
                Departure_Location__c,
                Destination_Location__c,
                Direction__c,
                Distance_Km__c,
                Final_Price__c,
                Is_Price_Overridden__c,
                Opportunity__c,
                Override_Reason__c,
                Price_Before_Conversion__c,
                Rate_Currency__c,
                Status__c,
                System_Price__c,
                Total_Weight_Kg__c,
                Transport_Zone__c,
                Trip_Date__c,
                Trip_Key__c,
                Truck_Type__c,
                Departure_Location__r.Name,
                Destination_Location__r.Name,
                Opportunity__r.Name
            FROM Trip__c
            WHERE Name = :recordName
        ];
    }

    public static List<Trip__c> getAll() {
        return [
            SELECT
                Id,
                Name,
                Calculation_Detail__c,
                Country_Code__c,
                Departure_Location__c,
                Destination_Location__c,
                Direction__c,
                Distance_Km__c,
                Final_Price__c,
                Is_Price_Overridden__c,
                Opportunity__c,
                Override_Reason__c,
                Price_Before_Conversion__c,
                Rate_Currency__c,
                Status__c,
                System_Price__c,
                Total_Weight_Kg__c,
                Transport_Zone__c,
                Trip_Date__c,
                Trip_Key__c,
                Truck_Type__c,
                Departure_Location__r.Name,
                Destination_Location__r.Name,
                Opportunity__r.Name
            FROM Trip__c
        ];
    }
}
