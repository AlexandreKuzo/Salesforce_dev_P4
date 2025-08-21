public with sharing class TransporterSelector {
    
    /**
     * Récupère le transporteur le plus rapide pour un compte et un pays donné
     * via DeliveryPrice__c
     */
    public static Carrier__c getFastestTransporter(Account account, String country) {
        List<DeliveryPrice__c> deliveryPrices = [
            SELECT Id, Carrier__c, Carrier__r.Name, DeliveryTimePeriod__c, Price__c, Country__c
            FROM DeliveryPrice__c 
            WHERE Country__c = :country

            ORDER BY DeliveryTimePeriod__c ASC
            LIMIT 1
        ];
        
        return deliveryPrices.isEmpty() ? null : deliveryPrices[0].Carrier__r;
    }
    
    /**
     * Récupère le transporteur le moins cher pour un compte et un pays donné
     * via DeliveryPrice__c
     */
    public static Carrier__c getCheapestTransporter(Account account, String country) {
        List<DeliveryPrice__c> deliveryPrices = [
            SELECT Id, Carrier__c, Carrier__r.Name, DeliveryTimePeriod__c, Price__c, Country__c
            FROM DeliveryPrice__c 
            WHERE Country__c = :country
            ORDER BY Price__c ASC
            LIMIT 1
        ];
        
        return deliveryPrices.isEmpty() ? null : deliveryPrices[0].Carrier__r;
    }
    
    /**
     * Récupère tous les transporteurs disponibles pour un pays donné
     * avec leurs prix et délais via DeliveryPrice__c
     */
    @AuraEnabled
    public static List<DeliveryPrice__c> getAvailableTransporters(String country) {
        return [
            SELECT Id, Carrier__c, Carrier__r.Name__c, 
                   DeliveryTimePeriod__c, Price__c, Country__c
            FROM DeliveryPrice__c 
            WHERE Country__c = :country
            ORDER BY Price__c ASC
        ];
    }
    
    /**
     * Récupère le prix de livraison pour un transporteur et un pays donné
     */
    @AuraEnabled
    public static DeliveryPrice__c getDeliveryPrice(Id carrierId, String country) {
        List<DeliveryPrice__c> deliveryPrices = [
            SELECT Id, Carrier__c, Carrier__r.Name__c, DeliveryTimePeriod__c, Price__c, Country__c
            FROM DeliveryPrice__c 
            WHERE Carrier__c = :carrierId
            AND Country__c = :country
            LIMIT 1
        ];
        
        return deliveryPrices.isEmpty() ? null : deliveryPrices[0];
    }
    
    /**
     * Récupère tous les pays disponibles pour un transporteur donné
     */
    public static List<String> getCountriesForCarrier(Id carrierId) {
        List<DeliveryPrice__c> deliveryPrices = [
            SELECT Country__c
            FROM DeliveryPrice__c 
            WHERE Carrier__c = :carrierId
            ORDER BY Country__c ASC
        ];
        
        List<String> countries = new List<String>();
        for (DeliveryPrice__c dp : deliveryPrices) {
            countries.add(dp.Country__c);
        }
        
        return countries;
    }
}