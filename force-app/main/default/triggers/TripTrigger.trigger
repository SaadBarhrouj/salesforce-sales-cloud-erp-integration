trigger TripTrigger on Trip__c (before insert, before update, before delete, after insert, after update, after delete) {
    TripTriggerHandler.handle(Trigger.isDelete ? null : Trigger.new, Trigger.isInsert ? null : Trigger.oldMap);
}
