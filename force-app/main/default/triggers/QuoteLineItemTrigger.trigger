trigger QuoteLineItemTrigger on QuoteLineItem (before insert, before update) {
    QuoteLineItemTriggerHandler.handleBefore(Trigger.new, Trigger.oldMap);
}