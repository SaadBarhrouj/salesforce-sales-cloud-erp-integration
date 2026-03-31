trigger RuleActionTrigger on Rule_Action__c (before insert, before update, before delete, after insert, after update, after delete) {
    RuleActionTriggerHandler.handle(Trigger.isDelete ? null : Trigger.new, Trigger.isInsert ? null : Trigger.oldMap);
}
