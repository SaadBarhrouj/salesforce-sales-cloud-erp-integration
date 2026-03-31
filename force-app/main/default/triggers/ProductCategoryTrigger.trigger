trigger ProductCategoryTrigger on ProductCategory (before insert, before update, before delete, after insert, after update, after delete) {
    ProductCategoryTriggerHandler.handle(Trigger.isDelete ? null : Trigger.new, Trigger.isInsert ? null : Trigger.oldMap);
}
