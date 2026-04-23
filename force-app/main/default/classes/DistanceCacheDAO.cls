/**
 * @description Data Access Object for Distance_Cache__c records.
 * Provides query methods to retrieve cached distance data.
 */
public inherited sharing class DistanceCacheDAO {
    
    /**
     * @description Get Distance Cache records by their cache keys.
     * @param cacheKeys Set of cache key strings (format: 'originId_destinationId')
     * @return Map of Cache Key to Distance_Cache__c record
     */
    public static Map<String, Distance_Cache__c> getByCacheKeys(Set<String> cacheKeys) {
        if (cacheKeys == null || cacheKeys.isEmpty()) {
            return new Map<String, Distance_Cache__c>();
        }

        try {
            Map<String, Distance_Cache__c> result = new Map<String, Distance_Cache__c>();
            for (Distance_Cache__c cache : [
                SELECT 
                    Id, 
                    Cache_Key__c, 
                    Origin_Location__c,
                    Destination_Location__c,
                    Distance_Km__c, 
                    Duration_Minutes__c 
                FROM Distance_Cache__c 
                WHERE Cache_Key__c IN :cacheKeys
            ]) {
                result.put(cache.Cache_Key__c, cache);
            }
            return result;
        } catch (QueryException qe) {
            System.debug(LoggingLevel.ERROR, 'QueryException in getByCacheKeys: ' + qe.getMessage());
            throw qe;
        }
    }

    /**
     * @description Upsert Distance Cache records by Cache Key external ID.
     * @param caches List of Distance_Cache__c records to upsert
     */
    public static void upsertByKey(List<Distance_Cache__c> caches) {
        if (caches == null || caches.isEmpty()) {
            return;
        }

        try {
            upsert as system caches Cache_Key__c;
            System.debug(LoggingLevel.INFO, 'DistanceCacheDAO: ' + caches.size() + ' cache record(s) upserted successfully.');
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Exception in upsertByKey: ' + e.getMessage());
            throw e;
        }
    }
}
