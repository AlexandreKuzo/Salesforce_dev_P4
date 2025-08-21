public with sharing class DeliveryService {
    
    /**
     * Crée une livraison pour une commande
     */
    @AuraEnabled
    public static Delivery__c createDelivery(Id orderId, Id transporterId) {
        Order order = [SELECT Id, ShippingCountry FROM Order WHERE Id = :orderId LIMIT 1];
        DeliveryPrice__c deliveryPrice = [SELECT Id, Price__c FROM DeliveryPrice__c 
                                         WHERE Carrier__c = :transporterId 
                                         AND Country__c = :order.ShippingCountry 
                                         LIMIT 1];
        
        Delivery__c delivery = new Delivery__c(
            Order__c = orderId,
            Status__c = 'Livrée', // Utiliser la valeur française de votre picklist
            Country__c = order.ShippingCountry,
            Carrier__c = transporterId,
            Price__c = deliveryPrice.Price__c
        );
        
        insert delivery;
        return delivery;
    }
    
    /**
     * Met à jour le statut d'une livraison
     */
    public static void updateDeliveryStatus(Id deliveryId, String newStatus) {
        Delivery__c delivery = [SELECT Id, Status__c FROM Delivery__c WHERE Id = :deliveryId LIMIT 1];
        delivery.Status__c = newStatus;
        update delivery;
    }
    
    /**
     * Récupère les livraisons d'une commande
     */
    public static List<Delivery__c> getDeliveriesForOrder(Id orderId) {
        return [
            SELECT Id, Name, Status__c, Country__c, Price__c, 
                   Carrier__r.Name
            FROM Delivery__c 
            WHERE Order__c = :orderId 
            ORDER BY CreatedDate DESC
        ];
    }
    
    /**
     * Confirme une livraison avec un transporteur spécifique
     */
    @AuraEnabled
    public static void confirmDelivery(Id deliveryId, Id transporterId) {
        Delivery__c delivery = [SELECT Id, Status__c FROM Delivery__c WHERE Id = :deliveryId LIMIT 1];
        DeliveryPrice__c deliveryPrice = [SELECT Id, Price__c FROM DeliveryPrice__c 
                                         WHERE Carrier__c = :transporterId 
                                         AND Country__c = :delivery.Country__c 
                                         LIMIT 1];
        
        delivery.Status__c = 'Confirmée';
        delivery.Carrier__c = transporterId;
        delivery.Price__c = deliveryPrice.Price__c;
        
        update delivery;
    }
    
    /**
     * Récupère les statistiques de livraison
     */
    public static Map<String, Integer> getDeliveryStatistics() {
        Map<String, Integer> stats = new Map<String, Integer>();
        
        List<AggregateResult> results = [
            SELECT Status__c, COUNT(Id) total
            FROM Delivery__c 
            GROUP BY Status__c
        ];
        
        for (AggregateResult ar : results) {
            String status = (String) ar.get('Status__c');
            Integer total = (Integer) ar.get('total');
            stats.put(status, total);
        }
        
        return stats;
    }
} 