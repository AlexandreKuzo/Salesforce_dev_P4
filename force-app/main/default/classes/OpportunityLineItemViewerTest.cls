@isTest
private class OpportunityLineItemViewerTest {
    @TestSetup
    static void makeData(){
        // Créer un compte
        Account testAccount = new Account(
            Name = 'Test Account 2'
        );
        insert testAccount;

        // Créer une opportunité
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpportunity;

        // Créer un produit
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            QuantityInStock__c = 10
        );
        insert testProduct;

        // Créer un prix standard
        Id standardPricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert standardPrice;

        // Créer une ligne de produit
        OpportunityLineItem testLineItem = new OpportunityLineItem(
            OpportunityId = testOpportunity.Id,
            PricebookEntryId = standardPrice.Id,
            Quantity = 5,
            UnitPrice = 100
        );
        insert testLineItem;
    }

    @isTest
    static void testGetLineItems() {
        // Récupérer l'opportunité de test
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        List<OpportunityLineItemViewer.OpportunityLineItemWrapper> result = 
            OpportunityLineItemViewer.getLineItems(testOpp.Id);
        Test.stopTest();

        // Vérifications
        System.assertEquals(1, result.size(), 'Devrait retourner une ligne de produit');
        System.assertEquals('Test Product', result[0].productName, 'Le nom du produit devrait correspondre');
        System.assertEquals(5, result[0].quantity, 'La quantité devrait être 5');
        System.assertEquals(100, result[0].unitPrice, 'Le prix unitaire devrait être 100');
        System.assertEquals(500, result[0].totalPrice, 'Le prix total devrait être 500');
    }

    @isTest
    static void testDeleteLineItem() {
        // Récupérer la ligne de produit de test
        OpportunityLineItem testLineItem = [SELECT Id FROM OpportunityLineItem LIMIT 1];
        
        Test.startTest();
        OpportunityLineItemViewer.deleteLineItem(testLineItem.Id);
        Test.stopTest();

        // Vérifier que la ligne a été supprimée
        List<OpportunityLineItem> remainingItems = [
            SELECT Id 
            FROM OpportunityLineItem 
            WHERE Id = :testLineItem.Id
        ];
        System.assertEquals(0, remainingItems.size(), 'La ligne de produit devrait être supprimée');
    }

    @isTest
    static void testGetLineItemsWithNoAccess() {
        // Créer un utilisateur avec un profil limité
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
        String uniqueUsername = 'testuser' + System.currentTimeMillis() + '@testorg.com';
        User testUser = new User(
            Alias = 'tuser',
            Email = 'testuser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = uniqueUsername
        );
        insert testUser;

        // Récupérer l'opportunité de test
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];

        System.runAs(testUser) {
            Test.startTest();
            try {
                OpportunityLineItemViewer.getLineItems(testOpp.Id);
                System.assert(false, 'Devrait lever une exception');
            } catch (AuraHandledException e) {
                System.assert(e.getMessage().contains('permissions'), 'Le message d\'erreur devrait mentionner les permissions');
            }
            Test.stopTest();
        }
    }
} 