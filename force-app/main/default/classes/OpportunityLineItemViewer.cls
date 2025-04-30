public with sharing class OpportunityLineItemViewer {
    @AuraEnabled(cacheable=true)
    public static List<OpportunityLineItemWrapper> getLineItems(String opportunityId) {
        try {
            
            if (!Schema.sObjectType.Opportunity.isAccessible()) { //  L'utilisateur a accès à l'opportunité ?
                throw new AuraHandledException('Vous n\'avez pas les permissions nécessaires pour accéder aux opportunités.');
            }

            Opportunity opp = [
                SELECT Id, Name,
                    (SELECT Id, Product2.Name, Product2.QuantityInStock__c, Quantity, UnitPrice, TotalPrice 
                     FROM OpportunityLineItems)
                FROM Opportunity
                WHERE Id = :opportunityId
                WITH SECURITY_ENFORCED // règles de sécurité
            ];

            List<OpportunityLineItemWrapper> lineItems = new List<OpportunityLineItemWrapper>();

            for (OpportunityLineItem olitem : opp.OpportunityLineItems) {
                lineItems.add(new OpportunityLineItemWrapper(olitem));
            }

            return lineItems;
        } catch (Exception e) {
            throw new AuraHandledException('Erreur lors de la récupération des lignes de produit : ' + e.getMessage());
        }
    }

    public class OpportunityLineItemWrapper {
        @AuraEnabled public String productName { get; set; }
        @AuraEnabled public Decimal productQuantityInStock { get; set; }
        @AuraEnabled public Decimal quantity { get; set; }
        @AuraEnabled public Decimal unitPrice { get; set; }
        @AuraEnabled public Decimal totalPrice { get; set; }

        public OpportunityLineItemWrapper(OpportunityLineItem oli) {
            productName = oli.Product2 != null ? oli.Product2.Name : '';
            productQuantityInStock = oli.Product2 != null ? oli.Product2.QuantityInStock__c : 0;
            quantity = oli.Quantity;
            unitPrice = oli.UnitPrice;
            totalPrice = oli.TotalPrice;
        }
    }
}
