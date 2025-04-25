import { LightningElement, track, wire, api } from 'lwc';
import getLineItems from '@salesforce/apex/OpportunityLineItemViewer.getLineItems';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import PROFILE_NAME from '@salesforce/schema/User.Profile.Name';

export default class OpportunitiesViewer extends LightningElement {
    @api recordId;
    @track lineItems;
    @track isAdmin = false;

    @wire(getRecord, {
        recordId: USER_ID,
        fields: [PROFILE_NAME]
    })
    userProfileInfo({ error, data }) {
        if (data) {
            const profile = data.fields.Profile.displayValue || '';
            this.isAdmin = ['System Administrator'].includes(profile);
        } else if (error) {
            console.error('Erreur lors de la récupération du profil :', error);
        }
    }

    get columns() {
        let columns = [
            { label: 'Nom du produit', fieldName: 'productName' },
            { label: 'Quantité', fieldName: 'quantity', type: 'number' },
            { label: 'Prix unitaire', fieldName: 'unitPrice', type: 'currency' },
            { label: 'Prix total', fieldName: 'totalPrice', type: 'currency' }, 
            {
                label: 'Supprimer',
                type: 'button-icon',
                typeAttributes: {
                    iconName: 'utility:delete',
                    label: 'Supprimer',
                    name: 'delete',
                    title: 'Cliquer pour agir',
                    variant: 'brand',
                    class: 'slds-m-left_xx-small'
                }
            }
        ];
    
        if (this.isAdmin) {
            columns.push(
                {
                label: 'Voir produit',
                type: 'button',
                typeAttributes: {
                    label: 'View Product',
                    iconName: 'utility:preview',
                    name: 'delete',
                    title: 'Cliquer pour agir',
                    variant: 'brand'
                }
            }
        
        );
        }
    
        return columns;
    }
   

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