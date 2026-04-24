/**
 * @description Queueable process to calculate distances between Agency and Delivery Site.
 * Implements Lazy Loading with Distance_Cache__c and OpenRouteService integration.
 */
public class DistanceCalculationQueueable implements Queueable, Database.AllowsCallouts {
    
    private Set<Id> opportunityIds;


    public DistanceCalculationQueueable(Set<Id> oppIds) {
        this.opportunityIds = oppIds;
    }

    public void execute(QueueableContext context) {
        System.debug(LoggingLevel.INFO, '=== [DistanceCalculationQueueable] Execution started ===');

        if (this.opportunityIds == null || this.opportunityIds.isEmpty()) {
            return;
        }

        // 1. Retrieve Opportunities via DAO
        List<Opportunity> oppsToProcess = OpportunityDAO.getByIds(this.opportunityIds);

        Set<Id> locationIds = new Set<Id>();
        Set<String> cacheKeys = new Set<String>();
        
        // Map to group Opportunities that share the SAME route
        Map<String, List<Opportunity>> oppsByRouteMap = new Map<String, List<Opportunity>>();

        for (Opportunity opp : oppsToProcess) {
            locationIds.add(opp.Default_Agency__c);
            locationIds.add(opp.Delivery_Site__c);
            
            String cacheKey = String.valueOf(opp.Default_Agency__c) + '_' + String.valueOf(opp.Delivery_Site__c);
            cacheKeys.add(cacheKey);

            if (!oppsByRouteMap.containsKey(cacheKey)) {
                oppsByRouteMap.put(cacheKey, new List<Opportunity>());
            }
            oppsByRouteMap.get(cacheKey).add(opp);
        }

        // 2. Retrieve Cached Distances and Location Data via DAOs
        Map<String, Distance_Cache__c> existingCachesMap = DistanceCacheDAO.getByCacheKeys(cacheKeys);
        Map<Id, Schema.Location> locationsMap = LocationDAO.getByIds(locationIds);

        // 3. Prepare collections for final DML operations
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        Map<String, Distance_Cache__c> cachesToUpsertMap = new Map<String, Distance_Cache__c>();
        List<IntegrationLoggerService.LogCalloutRequest> logsToInsert = new List<IntegrationLoggerService.LogCalloutRequest>();
        
        // Set to store opportunities that couldn't be processed due to API callout limits
        Set<Id> unprocessedOppIds = new Set<Id>();

        // 4. Iterative processing by ROUTE (not by Opportunity to avoid duplicate API calls)
        for (String routeKey : oppsByRouteMap.keySet()) {
            
            Decimal finalDistanceKm = null;
            Integer finalDurationMins = null;

            // SCENARIO A: The route is already in our Salesforce Cache (0 Callout)
            if (existingCachesMap.containsKey(routeKey)) {
                Distance_Cache__c cachedRecord = existingCachesMap.get(routeKey);
                finalDistanceKm = cachedRecord.Distance_Km__c;
            } 
            // SCENARIO B: The route is not cached, we must call OpenRouteService
            else {
                
                // Prevention of Salesforce limit (Max 100 Callouts per transaction)
                // Keep margin of safety by checking against limit - 1
                if (Limits.getCallouts() >= (Limits.getLimitCallouts() - 1)) {
                    System.debug(LoggingLevel.WARN, 'Callout limit near. Storing route for re-queuing: ' + routeKey);
                    
                    // Store opportunities from this route for next Queueable execution
                    for (Opportunity unprocessedOpp : oppsByRouteMap.get(routeKey)) {
                        unprocessedOppIds.add(unprocessedOpp.Id);
                    }
                    continue;
                }

                // Get the first opportunity of this group to have the IDs
                Opportunity referenceOpp = oppsByRouteMap.get(routeKey)[0];
                Schema.Location origin = locationsMap.get(referenceOpp.Default_Agency__c);
                Schema.Location destination = locationsMap.get(referenceOpp.Delivery_Site__c);

                // Security: Verify that both locations have valid GPS coordinates
                if (hasValidCoordinates(origin) && hasValidCoordinates(destination)) {
                    
                    // CALL TO API SERVICE (Returns both result AND prepared log)
                    RouteCalculationService.RouteResult apiResult = RouteCalculationService.callOpenRouteService(origin, destination, referenceOpp.Id);
                    
                    if (apiResult.logRequest != null) {
                        logsToInsert.add(apiResult.logRequest);
                    }

                    if (apiResult.isSuccess && apiResult.distanceKm != null) {
                        finalDistanceKm = apiResult.distanceKm;
                        finalDurationMins = apiResult.durationMinutes;

                        // Prepare creation of new Cache
                        cachesToUpsertMap.put(routeKey, new Distance_Cache__c(
                            Cache_Key__c = routeKey,
                            Origin_Location__c = origin.Id,
                            Destination_Location__c = destination.Id,
                            Distance_Km__c = finalDistanceKm,
                            Duration_Minutes__c = finalDurationMins
                        ));
                    }
                } else {
                    System.debug(LoggingLevel.WARN, 'Missing GPS coordinates for Locations of route: ' + routeKey);
                }
            }

            // 5. Apply the found distance to ALL opportunities of this route
            // Store in Distance_Driving_Route_km__c (actual API-calculated route distance)
            if (finalDistanceKm != null) {
                for (Opportunity oppToUpdate : oppsByRouteMap.get(routeKey)) {
                    oppsToUpdate.add(new Opportunity(
                        Id = oppToUpdate.Id,
                        Distance_Driving_Route_km__c = finalDistanceKm
                    ));
                }
            }
        }

        // 6. Execute DMLs (Bulk and Secure)
        executeDMLs(cachesToUpsertMap.values(), oppsToUpdate, logsToInsert);
        
        // Re-queue unprocessed opportunities if any (Queueable chaining for API limit handling)
        if (!unprocessedOppIds.isEmpty()) {
            System.debug(LoggingLevel.INFO, 'Re-queuing ' + unprocessedOppIds.size() + ' unprocessed opportunities for next transaction.');
            
            // Prevent chaining during test execution (Salesforce testing restriction)
            if (!Test.isRunningTest()) {
                System.enqueueJob(new DistanceCalculationQueueable(unprocessedOppIds));
            }
        }
        
        System.debug(LoggingLevel.INFO, '=== [DistanceCalculationQueueable] Execution finished ===');
    }


    private Boolean hasValidCoordinates(Schema.Location loc) {
        return (loc != null && loc.Latitude != null && loc.Longitude != null);
    }

    private void executeDMLs(List<Distance_Cache__c> caches, List<Opportunity> opps, List<IntegrationLoggerService.LogCalloutRequest> logs) {
        try {
            // Upsert of Cache
            if (!caches.isEmpty()) {
                upsert as system caches Cache_Key__c;
            }

            // Update of Opportunities
            if (!opps.isEmpty()) {
                update as system opps;
                System.debug(LoggingLevel.INFO, opps.size() + ' Opportunity(ies) updated with distance.');
            }

            // Insertion of Integration Logs
            if (!logs.isEmpty()) {
                IntegrationLoggerService.logCallouts(logs);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, ' DML error in Queueable: ' + e.getMessage() + ' | Stack: ' + e.getStackTraceString());
        }
    }
}