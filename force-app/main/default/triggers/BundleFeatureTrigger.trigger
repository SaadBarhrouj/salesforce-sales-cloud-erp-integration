trigger BundleFeatureTrigger on Bundle_Feature__c (before insert, before update, before delete, after insert, after update, after delete) {
    BundleFeatureTriggerHandler.handle(Trigger.isDelete ? null : Trigger.new, Trigger.isInsert ? null : Trigger.oldMap);
}
