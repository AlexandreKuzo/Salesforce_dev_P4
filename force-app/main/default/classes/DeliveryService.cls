public with sharing class DeliveryService {
    
    // Statuts de livraison
    public static final String PENDING = 'En attente';
    public static final String CONFIRMED = 'Confirmée';
    public static final String SHIPPED = 'Expédiée';
    public static final String DELIVERED = 'Livrée';
    public static final String CANCELLED = 'Annulée';
    
    /**
     * Crée une livraison pour une commande avec un transporteur spécifique
     * Cette méthode est appelée depuis le composant deliveryLauncher
    
     */
    @AuraEnabled
    public static Delivery__c createDelivery(Id orderId, Id transporterId) {
        // Vérifier qu'il n'y a pas déjà une livraison active pour cette commande
        List<Delivery__c> existingDeliveries = [
            SELECT Id, Status__c 
            FROM Delivery__c 
            WHERE Order__c = :orderId 
            AND Status__c IN (:PENDING, :CONFIRMED, :SHIPPED)
        ];
        
        if (!existingDeliveries.isEmpty()) {
            throw new AuraHandledException('Une livraison est déjà en cours pour cette commande.');
        }
        
        Order order = [SELECT Id, ShippingCountry FROM Order WHERE Id = :orderId LIMIT 1];
        DeliveryPrice__c deliveryPrice = [SELECT Id, Price__c FROM DeliveryPrice__c 
                                         WHERE Carrier__c = :transporterId 
                                         AND Country__c = :order.ShippingCountry 
                                         LIMIT 1];
        
        Delivery__c delivery = new Delivery__c(
            Order__c = orderId,
            Status__c = CONFIRMED, // Livraison confirmée avec le transporteur choisi
            Country__c = order.ShippingCountry
            // Carrier__c = transporterId,
            // Price__c = deliveryPrice.Price__c
        );
        
        insert delivery;
        
        // Note: On ne modifie plus le statut de l'Order
        // Le statut reste "Activated" et les détails de livraison sont gérés via Delivery__c
        
        return delivery;
    }
    
    /**
     * Met à jour le statut d'une livraison
     */
    public static void updateDeliveryStatus(Id deliveryId, String newStatus) {
        Delivery__c delivery = [SELECT Id, Status__c, Order__c FROM Delivery__c WHERE Id = :deliveryId LIMIT 1];
        delivery.Status__c = newStatus;
        update delivery;
        
        // Si la livraison est marquée comme livrée, on peut déclencher des actions
        // mais on ne modifie plus le statut de l'Order
        if (newStatus == DELIVERED) {
            handleDeliveryCompletion(delivery.Order__c);
        }
    }
    
    /**
     * Gère les actions post-livraison (notifications, rapports, etc.)
     * L'Order reste en statut "Activated"
     */
    private static void handleDeliveryCompletion(Id orderId) {
        List<Delivery__c> allDeliveries = [
            SELECT Id, Status__c 
            FROM Delivery__c 
            WHERE Order__c = :orderId
        ];
        
        Boolean allDelivered = true;
        for (Delivery__c delivery : allDeliveries) {
            if (delivery.Status__c != DELIVERED && delivery.Status__c != CANCELLED) {
                allDelivered = false;
                break;
            }
        }
        
        // Si toutes les livraisons sont terminées, on peut déclencher des actions
        // comme des notifications, des rapports, etc.
        // Mais l'Order reste en statut "Activated"
        if (allDelivered && !allDeliveries.isEmpty()) {
            // Ici on pourrait ajouter des actions post-livraison :
            // - Envoyer une notification au client
            // - Générer un rapport de livraison
            // - Déclencher un processus de satisfaction client
            // etc.
        }
    }
    
    /**
     * Récupère les livraisons d'une commande
     * TO DO : changer la relation avec le transporteur
     */
    @AuraEnabled
    public static List<Delivery__c> getDeliveriesForOrder(Id orderId) {
        return [
            SELECT Id, Name, Status__c, Country__c, Price__c, 
                   Carrier__r.Name__c, CreatedDate
            FROM Delivery__c 
            WHERE Order__c = :orderId 
            ORDER BY CreatedDate DESC
        ];
    }
    
    /**
     * Récupère le statut global d'une commande basé sur ses livraisons
     */
    @AuraEnabled
    public static String getOrderDeliveryStatus(Id orderId) {
        List<Delivery__c> deliveries = getDeliveriesForOrder(orderId);
        
        if (deliveries.isEmpty()) {
            return 'Aucune livraison';
        }
        
        Boolean hasPending = false;
        Boolean hasConfirmed = false;
        Boolean hasShipped = false;
        Boolean hasDelivered = false;
        Boolean hasCancelled = false;
        
        for (Delivery__c delivery : deliveries) {
            if (delivery.Status__c == PENDING) {
                hasPending = true;
            } else if (delivery.Status__c == CONFIRMED) {
                hasConfirmed = true;
            } else if (delivery.Status__c == SHIPPED) {
                hasShipped = true;
            } else if (delivery.Status__c == DELIVERED) {
                hasDelivered = true;
            } else if (delivery.Status__c == CANCELLED) {
                hasCancelled = true;
            }
        }
        
        // Logique de priorité pour déterminer le statut global
        if (hasDelivered && !hasPending && !hasConfirmed && !hasShipped) {
            return 'Livrée';
        } else if (hasShipped) {
            return 'En cours de livraison';
        } else if (hasConfirmed) {
            return 'Confirmée';
        } else if (hasPending) {
            return 'En attente';
        } else if (hasCancelled) {
            return 'Annulée';
        }
        
        return 'Statut inconnu';
    }
    
    /**
     * Confirme une livraison avec un transporteur spécifique
     * Cette méthode peut être utilisée pour changer de transporteur
     */
    @AuraEnabled
    public static void confirmDelivery(Id deliveryId, Id transporterId) {
        Delivery__c delivery = [SELECT Id, Status__c, Country__c FROM Delivery__c WHERE Id = :deliveryId LIMIT 1];
        
        DeliveryPrice__c deliveryPrice = [SELECT Id, Price__c FROM DeliveryPrice__c 
                                         WHERE Carrier__c = :transporterId 
                                         AND Country__c = :delivery.Country__c 
                                         LIMIT 1];
        
        delivery.Status__c = CONFIRMED;
        delivery.Carrier__c = transporterId;
        delivery.Price__c = deliveryPrice.Price__c;
        
        update delivery;
    }
    
    /**
     * Annule une livraison
     */
    @AuraEnabled
    public static void cancelDelivery(Id deliveryId) {
        Delivery__c delivery = [SELECT Id, Status__c FROM Delivery__c WHERE Id = :deliveryId LIMIT 1];
        
        if (delivery.Status__c == DELIVERED) {
            throw new AuraHandledException('Impossible d\'annuler une livraison déjà livrée.');
        }
        
        delivery.Status__c = CANCELLED;
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
