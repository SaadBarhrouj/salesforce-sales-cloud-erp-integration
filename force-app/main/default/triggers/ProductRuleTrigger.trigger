trigger ProductRuleTrigger on Product_Rule__c (before insert, before update, before delete, after insert, after update, after delete) {
    ProductRuleTriggerHandler.handle(Trigger.isDelete ? null : Trigger.new, Trigger.isInsert ? null : Trigger.oldMap);
}
