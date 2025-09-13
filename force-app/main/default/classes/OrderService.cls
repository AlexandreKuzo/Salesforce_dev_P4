public with sharing class OrderService {

    // Méthode pour valider les commandes
    public static void validateOrder(Order orderToValidate) {
        if (orderToValidate.AccountId == null) return;

        Account acc = [SELECT Id, TypeClient__c FROM Account WHERE Id = :orderToValidate.AccountId LIMIT 1];

        Integer nbProduits = 0;
        if (orderToValidate.Id != null) {
            nbProduits = [
                SELECT COUNT() 
                FROM OrderItem 
                WHERE OrderId = :orderToValidate.Id
            ];
        }

        orderToValidate.NumberOfProducts__c = nbProduits;

        if (acc.TypeClient__c == 'Particulier' && nbProduits < 3) {
            orderToValidate.addError('Un particulier doit commander au moins 3 produits.');
        }
        if (acc.TypeClient__c == 'Professionnel' && nbProduits < 5) {
            orderToValidate.addError('Un professionnel doit commander au moins 5 produits.');
        }
    }

    // Quand une commande est activée, créer une livraison en attente
    public static void finalizeOrders(List<Order> orders) {
        List<Delivery__c> deliveries = new List<Delivery__c>();

        for (Order o : orders) {
            // Créer une livraison en attente (sans transporteur assigné)
            // L'utilisateur devra choisir le transporteur via le composant deliveryLauncher
            Delivery__c delivery = new Delivery__c(
                Order__c = o.Id,
                Status__c = 'En attente', 
                Country__c = o.ShippingCountry
            
            );
            deliveries.add(delivery);
        }

        insert deliveries;
    }
}
