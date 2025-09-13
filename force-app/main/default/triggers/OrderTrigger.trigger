trigger OrderTrigger on Order (before insert, before update, after update) {
    
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        OrderTriggerHandler.handleBeforeEvents(Trigger.new, Trigger.oldMap);
    }
    
    if (Trigger.isAfter && Trigger.isUpdate) {
        OrderTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}
