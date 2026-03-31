trigger ProductCategoryProductTrigger on ProductCategoryProduct (before insert, before update, before delete, after insert, after update, after delete) {
    ProductCategoryProductTriggerHandler.handle(Trigger.isDelete ? null : Trigger.new, Trigger.isInsert ? null : Trigger.oldMap);
}
