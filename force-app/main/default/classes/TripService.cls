public inherited sharing class TripService {
    
    /**
     * @description Calculates new trips using BinSolver without saving
     */
    public static List<Trip__c> calculateAndSaveTrips(Id opportunityId, String urgency, Decimal totalWeight) {
        try {
            if (opportunityId == null) {
                throw new TripException('OpportunityId cannot be null');
            }
            
            // 1. Fetch Opportunity details
            Opportunity opp = [SELECT Id, Distance_Delivery_Agency_km__c, Total_Weight_Kg__c 
                               FROM Opportunity 
                               WHERE Id = :opportunityId 
                               LIMIT 1];
                               
            Decimal distance = opp.Distance_Delivery_Agency_km__c != null ? opp.Distance_Delivery_Agency_km__c : 0;
            if (distance == 0) {
                 throw new TripException('La distance de livraison doit être calculée avant d\'estimer le coût.');
            }

            // 2. Fetch Opp Line Items (Products)
            List<OpportunityLineItem> olis = [SELECT Id, Quantity, Product2.Weight__c, Product2.Unit_Weight_Kg__c, 
                                              Product2.Height_cm__c, Product2.Width_cm__c, Product2.Depth_cm__c 
                                              FROM OpportunityLineItem 
                                              WHERE OpportunityId = :opportunityId AND Product2.Name != null];
            
            if (olis.isEmpty()) {
                throw new TripException('L\'opportunité ne contient aucun produit à expédier.');
            }

            // 3. Prepare BinSolver Items
            List<Map<String, Object>> items = new List<Map<String, Object>>();
            for (OpportunityLineItem oli : olis) {
                if (oli.Product2.Height_cm__c == null || oli.Product2.Width_cm__c == null || oli.Product2.Depth_cm__c == null) {
                    continue; // Skip items without dimensions
                }
                Map<String, Object> itemMap = new Map<String, Object>();
                itemMap.put('id', String.valueOf(oli.Id));
                itemMap.put('w', oli.Product2.Width_cm__c);
                itemMap.put('h', oli.Product2.Height_cm__c);
                itemMap.put('d', oli.Product2.Depth_cm__c);
                itemMap.put('quantity', Integer.valueOf(oli.Quantity));
                if (oli.Product2.Unit_Weight_Kg__c != null) {
                    itemMap.put('weight', oli.Product2.Unit_Weight_Kg__c);
                }
                items.add(itemMap);
            }
            if (items.isEmpty()) {
                throw new TripException('Aucun produit n\'a de dimensions valides pour le calcul du transport.');
            }

            // 4. Fetch Trucks & Prepare Bins
            List<Truck_Type__mdt> allTrucks = [SELECT MasterLabel, Truck_Code__c, Width_cm__c, Height_cm__c, Depth_cm__c, Max_Weight_Kg__c, Quantity__c 
                                               FROM Truck_Type__mdt];
            
            List<Map<String, Object>> bins = new List<Map<String, Object>>();
            for (Truck_Type__mdt t : allTrucks) {
                Map<String, Object> binMap = new Map<String, Object>();
                binMap.put('id', t.Truck_Code__c);
                binMap.put('w', t.Width_cm__c);
                binMap.put('h', t.Height_cm__c);
                binMap.put('d', t.Depth_cm__c);
                if (t.Max_Weight_Kg__c != null) {
                    binMap.put('maxWeight', t.Max_Weight_Kg__c);
                }
                binMap.put('quantity', t.Quantity__c != null ? Integer.valueOf(t.Quantity__c) : 5);
                bins.add(binMap);
            }

            // 5. Fetch Transport Metadata (Zones & Rates)
            List<Transport_Zone__mdt> zones = [SELECT Zone_Code__c, Min_Distance_Km__c, Max_Distance_Km__c 
                                               FROM Transport_Zone__mdt];
            String determineZone = 'Unknown';
            for (Transport_Zone__mdt z : zones) {
                if (distance >= z.Min_Distance_Km__c && distance <= z.Max_Distance_Km__c) {
                    determineZone = z.Zone_Code__c;
                    break;
                }
            }
            
            List<Transport_Rate__mdt> ratesList = [SELECT Truck_Code__c, Zone_Code__c, Base_Price__c, Price_Per_Extra_Km__c, Included_Km__c 
                                                   FROM Transport_Rate__mdt];
                                                   
            Map<String, Transport_Rate__mdt> ratesMap = new Map<String, Transport_Rate__mdt>();
            for (Transport_Rate__mdt r : ratesList) {
                ratesMap.put(r.Zone_Code__c + '_' + r.Truck_Code__c, r);
            }

            // 6. Two BinSolver calls
            String responseMinBins = BinSolverAPI.packItems('minBins', items, bins, opportunityId);
            String responseMinWaste = BinSolverAPI.packItems('minWaste', items, bins, opportunityId);
            
            // 7. Parse Responses & Calculate Costs
            List<Trip__c> minBinsTrips = calculateTripsForResponse(responseMinBins, determineZone, distance, opportunityId, ratesMap);
            List<Trip__c> minWasteTrips = calculateTripsForResponse(responseMinWaste, determineZone, distance, opportunityId, ratesMap);
            
            Decimal costMinBins = getTotalCost(minBinsTrips);
            Decimal costMinWaste = getTotalCost(minWasteTrips);
            
            // 8. Return least expensive scenario WITHOUT inserting to DB
            if (costMinBins <= costMinWaste) {
                return minBinsTrips;
            } else {
                return minWasteTrips;
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'TripService.calculateAndSaveTrips failed: ' + e.getMessage() + '\n' + e.getStackTraceString());
            throw new TripException('Error calculating trips: ' + e.getMessage(), e);
        }
    }

    private static Decimal getTotalCost(List<Trip__c> trips) {
        Decimal total = 0;
        if(trips != null) {
            for(Trip__c t : trips) {
                total += (t.System_Price__c != null ? t.System_Price__c : 0);
            }
        }
        return total;
    }

    private static List<Trip__c> calculateTripsForResponse(String jsonResponse, String zoneCode, Decimal distance, Id opportunityId, Map<String, Transport_Rate__mdt> ratesMap) {
        List<Trip__c> trips = new List<Trip__c>();
        Map<String, Object> parseRes = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
        
        List<Object> packedBins = (List<Object>) parseRes.get('bins');
        if (packedBins != null) {
            for (Object o : packedBins) {
                Map<String, Object> b = (Map<String, Object>) o;
                String truckCode = (String) b.get('id');
                
                Decimal price = 0;
                String key = zoneCode + '_' + truckCode;
                if (ratesMap.containsKey(key)) {
                    Transport_Rate__mdt r = ratesMap.get(key);
                    price = r.Base_Price__c != null ? r.Base_Price__c : 0;
                    if (r.Price_Per_Extra_Km__c != null && r.Included_Km__c != null && distance > r.Included_Km__c) {
                        price += (distance - r.Included_Km__c) * r.Price_Per_Extra_Km__c;
                    }
                }
                
                Trip__c trip = new Trip__c();
                trip.Opportunity__c = opportunityId;
                trip.Truck_Type__c = truckCode; // Must match picklist/reference
                trip.System_Price__c = price;
                trip.Final_Price__c = price;
                trip.Direction__c = 'Outbound';
                trip.Transport_Zone__c = zoneCode;
                trips.add(trip);
            }
        }
        return trips;
    }
    
    /**
     * @description Gets existing trips for an opportunity
     */
    public static List<Trip__c> getExistingTrips(Id opportunityId) {
        try {
            return TripDAO.getTripsByOpportunity(opportunityId);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'TripService.getExistingTrips failed: ' + e.getMessage());
            throw new TripException('Error fetching existing trips: ' + e.getMessage(), e);
        }
    }
    
    /**
     * @description Updates existing trips
     */
    public static void updateTrips(List<Trip__c> trips) {
        try {
            TripDAO.upsertTrips(trips);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'TripService.updateTrips failed: ' + e.getMessage());
            throw new TripException('Error updating trips: ' + e.getMessage(), e);
        }
    }
}
