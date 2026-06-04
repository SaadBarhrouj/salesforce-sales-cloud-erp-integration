// Cleanup: delete duplicate Volume_Pricing_Tier__c.
// Keeps the oldest tier per (Schedule, Lower_Bound) and deletes the others.
Savepoint sp = Database.setSavepoint();
try {
    Map<String, Volume_Pricing_Tier__c> keepers = new Map<String, Volume_Pricing_Tier__c>();
    List<Volume_Pricing_Tier__c> toDelete = new List<Volume_Pricing_Tier__c>();
    for (Volume_Pricing_Tier__c t : [
        SELECT Id, Volume_Pricing_Schedule__c, Lower_Bound__c, CreatedDate
        FROM Volume_Pricing_Tier__c
        ORDER BY CreatedDate ASC
    ]) {
        String key = String.valueOf(t.Volume_Pricing_Schedule__c) + '|' + String.valueOf(t.Lower_Bound__c);
        if (keepers.containsKey(key)) {
            toDelete.add(t);
        } else {
            keepers.put(key, t);
        }
    }
    System.debug('Tiers kept: ' + keepers.size());
    System.debug('Tiers to delete: ' + toDelete.size());
    if (!toDelete.isEmpty()) {
        delete toDelete;
    }
    System.debug('CLEANUP OK');
} catch (Exception e) {
    Database.rollback(sp);
    System.debug(LoggingLevel.ERROR, 'CLEANUP ROLLBACK: ' + e.getMessage());
    throw e;
}
