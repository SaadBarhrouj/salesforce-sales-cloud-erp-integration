trigger OpportunityLineItemTrigger on OpportunityLineItem (before insert, before update, before delete, after insert, after update, after delete) {
    OpportunityLineItemTriggerHandler.handle(Trigger.isDelete ? null : Trigger.new, Trigger.isInsert ? null : Trigger.oldMap);
}
