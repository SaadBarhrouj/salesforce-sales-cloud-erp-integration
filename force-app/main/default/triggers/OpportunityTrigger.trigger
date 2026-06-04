trigger OpportunityTrigger on Opportunity (
    before insert, before update, before delete, 
    after insert, after update, after delete
) {
    OpportunityTriggerHandler.handle(Trigger.new, Trigger.oldMap);
}
