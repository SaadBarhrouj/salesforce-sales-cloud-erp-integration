/**
 * @description Data access helper for PricebookEntry records.
 */
public inherited sharing class PricebookEntryDAO {
    /**
     * @description Returns the active PricebookEntry for a single product and pricebook.
     * @param productId Product to search for.
     * @param pricebookId Pricebook to search in.
     * @return Matching PricebookEntry or null.
     */
    @AuraEnabled(cacheable=true)
    public static PricebookEntry getByProductAndPricebook(Id productId, Id pricebookId) {
        List<PricebookEntry> entries = [
            SELECT Id, Product2Id, UnitPrice, Pricebook2Id
            FROM PricebookEntry
            WHERE Product2Id = :productId
            AND Pricebook2Id = :pricebookId
            AND IsActive = true
            LIMIT 1
        ];

        return entries.isEmpty() ? null : entries[0];
    }

    /**
     * @description Returns active PricebookEntry records keyed by product Id.
     * @param productIds Product Ids to search for.
     * @param pricebookId Pricebook to search in.
     * @return Map of Product2Id to PricebookEntry.
     */
    public static Map<Id, PricebookEntry> getByProductsAndPricebook(Set<Id> productIds, Id pricebookId) {
        if (productIds == null || productIds.isEmpty() || pricebookId == null) {
            return new Map<Id, PricebookEntry>();
        }

        Map<Id, PricebookEntry> results = new Map<Id, PricebookEntry>();
        List<PricebookEntry> entries = [
            SELECT Id, Product2Id, Product2.Name, UnitPrice, Pricebook2Id
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