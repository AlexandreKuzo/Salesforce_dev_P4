public with sharing class OrderService {

    // Méthode pour valider les commandes
    public static void validateOrder(List<Order> orders) {
        if (orders.isEmpty()) return;

        // boucle for pour récupérer les accountIds des orders
        Set<Id> accountIds = new Set<Id>();
        for (Order order : orders) {
            if (order.AccountId != null) {
                accountIds.add(order.AccountId);
            }
        }

        Map<Id, Account> accountsMap = new Map<Id, Account>([SELECT Id, TypeClient__c FROM Account WHERE Id IN :accountIds]) ;

    
        for (Order order : orders) {
            // Validation basée sur le type de client et le nombre de produits
            Account acc = accountsMap.get(order.AccountId);
            if (acc.TypeClient__c == 'Particulier' && order.NumberProducts__c < 3) {
                order.addError('Un particulier doit commander au moins 3 produits.');
            }
            if (acc.TypeClient__c == 'Professionnel' && order.NumberProducts__c < 5) {
                order.addError('Un professionnel doit commander au moins 5 produits.');
            }
        }
    }

    // Quand une commande est activée, créer une livraison en attente (optimisé)
    public static void finalizeOrders(List<Order> orders) {
        if (orders.isEmpty()) return;

        List<Delivery__c> deliveries = new List<Delivery__c>();

        // Récupérer tous les AccountIds en une seule requête
        Set<Id> accountIds = new Set<Id>();
        for (Order order : orders) {
            if (order.AccountId != null) {
                accountIds.add(order.AccountId);
            }
        }

        // Récupérer tous les comptes en une seule requête
        Map<Id, Account> accountsMap = new Map<Id, Account>([
            SELECT Id, TypeClient__c 
            FROM Account 
            WHERE Id IN :accountIds
        ]);

        for (Order o : orders) {
            Account acc = accountsMap.get(o.AccountId);
            if (acc == null) continue;

            // Récupérer le transporteur le plus rapide pour ce pays
            Carrier__c fastest = TransporterSelector.getFastestTransporter(acc, o.ShippingCountry);
            
            // Récupérer le DeliveryPrice correspondant
            DeliveryPrice__c deliveryPrice = null;
            if (fastest != null) {
                deliveryPrice = TransporterSelector.getDeliveryPrice(fastest.Id, o.ShippingCountry);
            }

            // Créer une livraison en attente avec le DeliveryPrice
            Delivery__c delivery = new Delivery__c(
                Order__c = o.Id,
                Status__c = 'En attente',
                DeliveryPrice__c = deliveryPrice != null ? deliveryPrice.Id : null
            );
            deliveries.add(delivery);
        }

        if (!deliveries.isEmpty()) {
            insert deliveries;
        }
    }
}
