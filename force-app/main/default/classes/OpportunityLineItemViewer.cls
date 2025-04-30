public with sharing class OpportunityLineItemViewer {
    @AuraEnabled(cacheable=true)
    public static List<OpportunityLineItemWrapper> getLineItems(String opportunityId) {
        try {
            
            if (!Schema.sObjectType.Opportunity.isAccessible()) { //  L'utilisateur a accès à l'opportunité ?
                throw new AuraHandledException('Vous n\'avez pas les permissions nécessaires pour accéder aux opportunités.');
            }

            Opportunity opp = [
                SELECT Id, Name,
                    (SELECT Id, Product2Id, Product2.Name, Product2.QuantityInStock__c, Quantity, UnitPrice, TotalPrice 
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

    @AuraEnabled
    public static void deleteLineItem(String lineItemId) {
        try {
            if (!Schema.sObjectType.OpportunityLineItem.isDeletable()) {
                throw new AuraHandledException('Vous n\'avez pas les permissions nécessaires pour supprimer les lignes de produit.');
            }

            OpportunityLineItem oli = [
                SELECT Id 
                FROM OpportunityLineItem 
                WHERE Id = :lineItemId
                WITH SECURITY_ENFORCED // règles de sécurité
            ];

            delete oli;
        } catch (Exception e) {
            throw new AuraHandledException('Erreur lors de la suppression de la ligne de produit : ' + e.getMessage());
        }
    }

    public class OpportunityLineItemWrapper {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String productId { get; set; }
        @AuraEnabled public String productName { get; set; }
        @AuraEnabled public Decimal productQuantityInStock { get; set; }
        @AuraEnabled public Decimal quantity { get; set; }
        @AuraEnabled public Decimal unitPrice { get; set; }
        @AuraEnabled public Decimal totalPrice { get; set; }

        public OpportunityLineItemWrapper(OpportunityLineItem oli) {
            this.id = oli.Id;
            this.productId = oli.Product2Id;
            this.productName = oli.Product2 != null ? oli.Product2.Name : '';
            this.productQuantityInStock = oli.Product2 != null ? oli.Product2.QuantityInStock__c : 0;
            this.quantity = oli.Quantity;
            this.unitPrice = oli.UnitPrice;
            this.totalPrice = oli.TotalPrice;
        }
    }
}
