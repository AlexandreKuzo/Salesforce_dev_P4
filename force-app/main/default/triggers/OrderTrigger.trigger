trigger OrderTrigger on Order (before insert, before update, after update) {
    
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        for (Order o : Trigger.new) {
            OrderService.validateOrder(o);
        }
    }

    // Validation de commande
    if (Trigger.isAfter && Trigger.isUpdate) {
        List<Order> finalizedOrders = new List<Order>();
        for (Order o : Trigger.new) {
            Order oldOrder = Trigger.oldMap.get(o.Id);
            if (o.Status == 'Activated' && oldOrder.Status != 'Activated') {
                finalizedOrders.add(o);
            }
        }
        if (!finalizedOrders.isEmpty()) {
            OrderService.finalizeOrders(finalizedOrders);
        }
    }
}
