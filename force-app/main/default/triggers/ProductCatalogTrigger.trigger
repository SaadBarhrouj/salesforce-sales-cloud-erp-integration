trigger ProductCatalogTrigger on ProductCatalog (before insert, before update, before delete, after insert, after update, after delete) {
    ProductCatalogTriggerHandler.handle(Trigger.isDelete ? null : Trigger.new, Trigger.isInsert ? null : Trigger.oldMap);
}
