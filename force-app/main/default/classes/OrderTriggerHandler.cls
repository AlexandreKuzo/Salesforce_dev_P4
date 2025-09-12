public with sharing class OrderTriggerHandler {
    
    /**
     * before insert et before update
     */
    public static void handleBeforeEvents(List<Order> newOrders, Map<Id, Order> oldMap) {
        // Validation des commandes
        for (Order order : newOrders) {
            OrderService.validateOrder(order);
        }
    }
    
    /**
     * after update
     */
    public static void handleAfterUpdate(List<Order> newOrders, Map<Id, Order> oldMap) {
        List<Order> activatedOrders = new List<Order>();
        
        // Identifier les commandes qui viennent d'être activées
        for (Order newOrder : newOrders) {
            Order oldOrder = oldMap.get(newOrder.Id);
            
            if (newOrder.Status == 'Activated' && oldOrder.Status != 'Activated') {
                activatedOrders.add(newOrder);
            }
        }
        
        // Traiter les commandes activées
        if (!activatedOrders.isEmpty()) {
            OrderService.finalizeOrders(activatedOrders);
        }
    }
}
