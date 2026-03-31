trigger Product2Trigger on Product2 (before insert, before update, before delete, after insert, after update, after delete) {
    Product2TriggerHandler.handle(Trigger.isDelete ? null : Trigger.new, Trigger.isInsert ? null : Trigger.oldMap);
}
