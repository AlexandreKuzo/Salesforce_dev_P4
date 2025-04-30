import { LightningElement, track, wire, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getLineItems from '@salesforce/apex/OpportunityLineItemViewer.getLineItems';
import deleteLineItem from '@salesforce/apex/OpportunityLineItemViewer.deleteLineItem';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import PROFILE_NAME from '@salesforce/schema/User.Profile.Name';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class OpportunitiesViewer extends NavigationMixin(LightningElement) {
    @api recordId;
    @track lineItems = [];
    @track isAdmin = false;
    @track columns = [
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
                title: 'Supprimer le produit',
                variant: 'brand',
                class: 'slds-m-left_xx-small'
            }
        }
    ];

    connectedCallback() {
        console.log('recordId:', this.recordId);
    }

    @wire(getRecord, {
        recordId: USER_ID,
        fields: [PROFILE_NAME]
    })
    userProfileInfo({ error, data }) {
        if (data) {
            const profile = data.fields.Profile.displayValue || '';
            this.isAdmin = ['System Administrator'].includes(profile);
            console.log('Profil utilisateur:', profile);
            console.log('isAdmin:', this.isAdmin);
            if (this.isAdmin) {
                this.columns.push({
                    label: 'Voir produit',
                    type: 'button',
                    typeAttributes: {
                        label: 'View Product',
                        iconName: 'utility:preview',
                        name: 'view',
                        title: 'Cliquer pour voir',
                        variant: 'brand'
                    }
                });
            }
        } else if (error) {
            console.error('Erreur lors de la récupération du profil :', error);
            this.showToast('Erreur', 'Impossible de récupérer le profil utilisateur', 'error');
        }
    }

    @wire(getLineItems, { opportunityId: '$recordId' })
    wiredLineItems({ error, data }) {
        if (data) {
            console.log('Données reçues:', data);
            this.lineItems = data;
            console.log('lineItems après assignation:', this.lineItems);
            console.log('hasLineItems:', this.hasLineItems);
        } else if (error) {
            console.error('Erreur lors de la récupération des lignes de produit :', error);
            this.showToast('Erreur', error.body.message || 'Impossible de récupérer les lignes de produit', 'error');
            this.lineItems = [];
        }
    }

    get hasLineItems() {
        const result = this.lineItems && this.lineItems.length > 0;
        console.log('Calcul de hasLineItems:', result);
        console.log('lineItems:', this.lineItems);
        return result;
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        
        if (actionName === 'delete') {
            this.handleDelete(row);
        } else if (actionName === 'view') {
            this.handleView(row);
        }
    }

    async handleDelete(row) {
        try {
            await deleteLineItem({ lineItemId: row.id });
            this.showToast('Succès', 'Le produit a été supprimé avec succès', 'success');
            // Rafraîchir les données
            await refreshApex(this.wiredLineItems);
        } catch (error) {
            console.error('Erreur lors de la suppression:', error);
            this.showToast('Erreur', error.body.message || 'Erreur lors de la suppression du produit', 'error');
        }
    }

    handleView(row) {
        // Navigation vers la page du produit
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: row.productId,
                actionName: 'view'
            }
        });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}