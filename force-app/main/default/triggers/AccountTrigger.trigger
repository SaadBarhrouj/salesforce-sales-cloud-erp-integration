trigger AccountTrigger on Account (before insert, before update, before delete, after insert, after update, after delete) {
    AccountTriggerHandler.handle(Trigger.isDelete ? null : Trigger.new, Trigger.isInsert ? null : Trigger.oldMap);
}
