trigger VolumePricingTierTrigger on Volume_Pricing_Tier__c (before insert, before update, before delete, after insert, after update, after delete) {
    VolumePricingTierTriggerHandler.handle(Trigger.isDelete ? null : Trigger.new, Trigger.isInsert ? null : Trigger.oldMap);
}
