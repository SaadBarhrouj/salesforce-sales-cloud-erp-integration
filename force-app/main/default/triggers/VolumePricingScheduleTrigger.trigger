trigger VolumePricingScheduleTrigger on Volume_Pricing_Schedule__c (before insert, before update, before delete, after insert, after update, after delete) {
    VolumePricingScheduleTriggerHandler.handle(Trigger.isDelete ? null : Trigger.new, Trigger.isInsert ? null : Trigger.oldMap);
}
