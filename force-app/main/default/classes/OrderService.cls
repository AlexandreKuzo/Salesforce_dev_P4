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

    // Quand une commande est finalisée
    public static void finalizeOrders(List<Order> orders) {
        List<Delivery__c> deliveries = new List<Delivery__c>();

        for (Order o : orders) {
            Account acc = [SELECT Id, TypeClient__c FROM Account WHERE Id = :o.AccountId LIMIT 1];

            // Récupérer le transporteur le plus rapide via TransporterSelector
            Carrier__c fastest = TransporterSelector.getFastestTransporter(acc, o.ShippingCountry);
            
            // Récupérer le prix de livraison pour ce transporteur et ce pays
            DeliveryPrice__c deliveryPrice = null;
            if (fastest != null) {
                deliveryPrice = TransporterSelector.getDeliveryPrice(fastest.Id, o.ShippingCountry);
            }

            // Créer la livraison avec le transporteur et le prix
            Delivery__c delivery = new Delivery__c(
                Order__c = o.Id,
                Status__c = 'En cours', // Utiliser la valeur française de votre picklist
                Country__c = o.ShippingCountry,
                Carrier__c = fastest != null ? fastest.Id : null,
                Price__c = deliveryPrice != null ? deliveryPrice.Price__c : null
            );
            deliveries.add(delivery);
        }

        insert deliveries;
    }


}