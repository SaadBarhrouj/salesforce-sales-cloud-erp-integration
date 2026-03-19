trigger BundleRuleAssignmentTrigger on Bundle_Rule_Assignment__c (before insert, before update, before delete, after insert, after update, after delete) {
    BundleRuleAssignmentTriggerHandler.handle(Trigger.isDelete ? null : Trigger.new, Trigger.isInsert ? null : Trigger.oldMap);
}
