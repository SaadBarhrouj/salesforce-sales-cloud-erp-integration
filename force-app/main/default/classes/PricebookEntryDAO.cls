public inherited sharing class PricebookEntryDAO {
    @TestVisible
    private static Map<String, PricebookEntry> cache = new Map<String, PricebookEntry>();

    public static void clearCache() {
        cache.clear();
    }

    @AuraEnabled(cacheable=true)
    public static PricebookEntry getByProductAndPricebook(Id productId, Id pricebookId) {
        String cacheKey = productId + ':' + pricebookId;
        if (cache.containsKey(cacheKey)) {
            return cache.get(cacheKey);
        }

        List<PricebookEntry> entries = [
            SELECT Id, Product2Id, UnitPrice, Pricebook2Id
            FROM PricebookEntry
            WHERE Product2Id = :productId
            AND Pricebook2Id = :pricebookId
            AND IsActive = true
            LIMIT 1
        ];

        if (entries.isEmpty()) {
            return null;
        }

        cache.put(cacheKey, entries[0]);
        return entries[0];
    }

    public static Map<Id, PricebookEntry> getByProductsAndPricebook(Set<Id> productIds, Id pricebookId) {
        if (productIds == null || productIds.isEmpty() || pricebookId == null) {
            return new Map<Id, PricebookEntry>();
        }

        Map<Id, PricebookEntry> results = new Map<Id, PricebookEntry>();
        List<PricebookEntry> entries = [
            SELECT Id, Product2Id, UnitPrice, Pricebook2Id
            FROM PricebookEntry
            WHERE Product2Id IN :productIds
            AND Pricebook2Id = :pricebookId
            AND IsActive = true
        ];

        for (PricebookEntry entry : entries) {
            results.put(entry.Product2Id, entry);
        }

        return results;
    }
}