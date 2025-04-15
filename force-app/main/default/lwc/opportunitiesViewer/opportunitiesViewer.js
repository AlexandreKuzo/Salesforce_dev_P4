import { LightningElement, track, wire, api } from 'lwc';
import getLineItems from '@salesforce/apex/OpportunityLineItemViewer.getLineItems';

export default class OpportunitiesViewer extends LightningElement {
    @api recordId;
    @track lineItems;

    columns = [
        { label: 'Nom du produit', fieldName: 'productName' },
        { label: 'Quantité', fieldName: 'quantity', type: 'number' },
        { label: 'Prix unitaire', fieldName: 'unitPrice', type: 'currency' },
        { label: 'Prix total', fieldName: 'totalPrice', type: 'currency' },
        { label: 'Quantité en stock', fieldName: 'productQuantityInStock', type: 'number' }
    ];


    @wire(getLineItems, { opportunityId: '$recordId' })
    wiredLineItems({ error, data }) {
        if (data) {
            this.lineItems = data;
        } else if (error) {
            console.error('Erreur lors de la récupération des lignes de prooduit :', error);
        }
    }

    get hasLineItems() {
        return this.lineItems && this.lineItems.length > 0;
    }
}