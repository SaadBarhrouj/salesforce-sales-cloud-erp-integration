trigger RuleConditionTrigger on Rule_Condition__c (before insert, before update, before delete, after insert, after update, after delete) {
    RuleConditionTriggerHandler.handle(Trigger.isDelete ? null : Trigger.new, Trigger.isInsert ? null : Trigger.oldMap);
}
