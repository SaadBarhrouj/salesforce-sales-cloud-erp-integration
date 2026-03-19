trigger LocationTrigger on Location (before insert, before update, before delete, after insert, after update, after delete) {
    LocationTriggerHandler.handle(Trigger.isDelete ? null : Trigger.new, Trigger.isInsert ? null : Trigger.oldMap);
}
