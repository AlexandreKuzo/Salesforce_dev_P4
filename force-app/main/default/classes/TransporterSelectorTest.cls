@isTest
private class TransporterSelectorTest {
    
    @TestSetup
    static void setupTestData() {
        // Créer des transporteurs de test
        List<Carrier__c> carriers = new List<Carrier__c>();
        
        carriers.add(new Carrier__c(
            Name = 'Transporteur Rapide',
            IsActive__c = true,
            Description__c = 'Livraison express'
        ));
        
        carriers.add(new Carrier__c(
            Name = 'Transporteur Économique',
            IsActive__c = true,
            Description__c = 'Livraison économique'
        ));
        
        carriers.add(new Carrier__c(
            Name = 'Transporteur Inactif',
            IsActive__c = false,
            Description__c = 'Transporteur inactif'
        ));
        
        insert carriers;
        
        // Créer les prix de livraison via DeliveryPrice__c
        List<DeliveryPrice__c> deliveryPrices = new List<DeliveryPrice__c>();
        
        // Prix pour le transporteur rapide
        deliveryPrices.add(new DeliveryPrice__c(
            Carrier__c = carriers[0].Id,
            Country__c = 'France',
            DeliveryTimePeriod__c = 1,
            Price__c = 50.00
        ));
        
        deliveryPrices.add(new DeliveryPrice__c(
            Carrier__c = carriers[0].Id,
            Country__c = 'Belgique',
            DeliveryTimePeriod__c = 2,
            Price__c = 45.00
        ));
        
        // Prix pour le transporteur économique
        deliveryPrices.add(new DeliveryPrice__c(
            Carrier__c = carriers[1].Id,
            Country__c = 'France',
            DeliveryTimePeriod__c = 5,
            Price__c = 15.00
        ));
        
        deliveryPrices.add(new DeliveryPrice__c(
            Carrier__c = carriers[1].Id,
            Country__c = 'Belgique',
            DeliveryTimePeriod__c = 6,
            Price__c = 18.00
        ));
        
        deliveryPrices.add(new DeliveryPrice__c(
            Carrier__c = carriers[1].Id,
            Country__c = 'Suisse',
            DeliveryTimePeriod__c = 7,
            Price__c = 25.00
        ));
        
        // Prix pour le transporteur inactif (ne devrait pas être utilisé)
        deliveryPrices.add(new DeliveryPrice__c(
            Carrier__c = carriers[2].Id,
            Country__c = 'France',
            DeliveryTimePeriod__c = 2,
            Price__c = 25.00
        ));
        
        insert deliveryPrices;
    }
    
    @isTest
    static void testGetFastestTransporter() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Test.startTest();
        Carrier__c fastest = TransporterSelector.getFastestTransporter(testAccount, 'France');
        Test.stopTest();
        
        System.assertNotEquals(null, fastest, 'Un transporteur devrait être trouvé');
        System.assertEquals('Transporteur Rapide', fastest.Name__c, 'Le transporteur le plus rapide devrait être sélectionné');
    }
    
    @isTest
    static void testGetCheapestTransporter() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Test.startTest();
        Carrier__c cheapest = TransporterSelector.getCheapestTransporter(testAccount, 'France');
        Test.stopTest();
        
        System.assertNotEquals(null, cheapest, 'Un transporteur devrait être trouvé');
        System.assertEquals('Transporteur Économique', cheapest.Name__c, 'Le transporteur le moins cher devrait être sélectionné');
    }
    
    @isTest
    static void testGetAvailableTransporters() {
        Test.startTest();
        List<DeliveryPrice__c> deliveryPrices = TransporterSelector.getAvailableTransporters('France');
        Test.stopTest();
        
        System.assertEquals(2, deliveryPrices.size(), 'Deux transporteurs actifs devraient être trouvés pour la France');
        
        // Vérifier que les transporteurs inactifs ne sont pas inclus
        for (DeliveryPrice__c dp : deliveryPrices) {
            System.assertNotEquals('Transporteur Inactif', dp.Carrier__r.Name__c, 'Les transporteurs inactifs ne devraient pas être inclus');
        }
    }
    
    @isTest
    static void testGetDeliveryPrice() {
        Carrier__c carrier = [SELECT Id FROM Carrier__c WHERE Name = 'Transporteur Rapide' LIMIT 1];
        
        Test.startTest();
        DeliveryPrice__c deliveryPrice = TransporterSelector.getDeliveryPrice(carrier.Id, 'France');
        Test.stopTest();
        
        System.assertNotEquals(null, deliveryPrice, 'Un prix de livraison devrait être trouvé');
        System.assertEquals(50.00, deliveryPrice.Price__c, 'Le prix devrait être de 50€');
        System.assertEquals(1, deliveryPrice.DeliveryTimePeriod__c, 'Le délai devrait être de 1 jour');
    }
    
    @isTest
    static void testGetCountriesForCarrier() {
        Carrier__c carrier = [SELECT Id FROM Carrier__c WHERE Name = 'Transporteur Économique' LIMIT 1];
        
        Test.startTest();
        List<String> countries = TransporterSelector.getCountriesForCarrier(carrier.Id);
        Test.stopTest();
        
        System.assertEquals(3, countries.size(), 'Trois pays devraient être trouvés pour ce transporteur');
        System.assert(countries.contains('France'), 'La France devrait être dans la liste');
        System.assert(countries.contains('Belgique'), 'La Belgique devrait être dans la liste');
        System.assert(countries.contains('Suisse'), 'La Suisse devrait être dans la liste');
    }
    
    @isTest
    static void testGetTransportersForUnsupportedCountry() {
        Test.startTest();
        List<DeliveryPrice__c> deliveryPrices = TransporterSelector.getAvailableTransporters('Japon');
        Test.stopTest();
        
        System.assertEquals(0, deliveryPrices.size(), 'Aucun transporteur ne devrait être trouvé pour un pays non supporté');
    }
} 