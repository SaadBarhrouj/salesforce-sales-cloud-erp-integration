trigger BundleOptionTrigger on Bundle_Option__c (before insert, before update, before delete, after insert, after update, after delete) {
    BundleOptionTriggerHandler.handle(Trigger.isDelete ? null : Trigger.new, Trigger.isInsert ? null : Trigger.oldMap);
}
