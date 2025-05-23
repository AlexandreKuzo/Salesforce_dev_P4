import { LightningElement, track, wire, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getLineItems from '@salesforce/apex/OpportunityLineItemViewer.getLineItems';
import deleteLineItem from '@salesforce/apex/OpportunityLineItemViewer.deleteLineItem';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import PROFILE_NAME from '@salesforce/schema/User.Profile.Name';
import { RefreshEvent } from 'lightning/refresh';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import Delete from '@salesforce/label/c.Delete';
import No_OpportunityLineItem from '@salesforce/label/c.No_OpportunityLineItem';
import Opportunity_products from '@salesforce/label/c.Opportunity_products';
import Product_Name from '@salesforce/label/c.Product_Name';
import Quantity from '@salesforce/label/c.Quantity';
import Quantity_in_Stock from '@salesforce/label/c.Quantity_in_Stock';
import Quantity_Problem from '@salesforce/label/c.Quantity_Problem';
import See_Product from '@salesforce/label/c.See_Product';
import Total_Price from '@salesforce/label/c.Total_Price';
import Unit_Price from '@salesforce/label/c.Unit_Price';
import Update_Error from '@salesforce/label/c.Update_Error';


export default class OpportunitiesViewer extends NavigationMixin(LightningElement) {
    @api recordId;
    @track lineItems = [];
    @track isAdmin = false;
    @track columns = [
        { label: Product_Name, fieldName: 'productName' },
        { label: Quantity, fieldName: 'quantity', type: 'number' },
        { label: Unit_Price, fieldName: 'unitPrice', type: 'currency' },
        { label: Total_Price, fieldName: 'totalPrice', type: 'currency' },
        {
            label: Delete,
            type: 'button-icon',
            typeAttributes: {
                iconName: 'utility:delete',
                label: Delete,
                name: 'delete',
                title: 'Supprimer le produit',
                variant: 'brand',
                class: 'slds-m-left_xx-small'
            }
        },
        {
            label: See_Product,
            type: 'button',
            typeAttributes: {
                label: See_Product,
                iconName: 'utility:preview',
                name: 'view',
                title: 'Cliquer pour voir',
                variant: 'brand'
            }
        }
    ];
    @track stockQuantityError = false;

    custom_labels = {
        No_OpportunityLineItem: No_OpportunityLineItem,
        Opportunity_products: Opportunity_products,
        Update_Error: Update_Error,
        Quantity_in_Stock: Quantity_in_Stock,
        Quantity_Problem: Quantity_Problem
    }

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
            
            // Mettre à jour les colonnes en fonction du profil
            this.updateColumns();
        } else if (error) {
            console.error('Erreur lors de la récupération du profil :', error);
            this.showToast('Erreur', 'Impossible de récupérer le profil utilisateur', 'error');
        }
    }

    updateColumns() {
        // Si l'utilisateur n'est pas admin, masquer la colonne "Voir produit"
        if (!this.isAdmin) {
            this.columns = this.columns.filter(col => col.label !== 'Voir produit');
        }
    }

    @wire(getLineItems, { opportunityId: '$recordId' })
    wiredLineItems({ error, data }) {
        if (data) {
            console.log('Données reçues:', data);
            this.lineItems = data;
            // Vérifier les quantités en stock
            this.checkStockQuantities();
            console.log('lineItems après assignation:', this.lineItems);
            console.log('hasLineItems:', this.hasLineItems);
            this.dispatchEvent(new RefreshEvent());
        } else if (error) {
            console.error('Erreur lors de la récupération des lignes de produit :', error);
            this.showToast('Erreur', error.body.message || 'Impossible de récupérer les lignes de produit', 'error');
            this.lineItems = [];
        }
    }

    checkStockQuantities() {
        if (!this.lineItems || this.lineItems.length === 0) {
            this.stockQuantityError = false;
            return;
        }
    
        // Grouper les quantités demandées par produit
        const productQuantityMap = new Map();
    
        for (const item of this.lineItems) {
            const productId = item.productId;
            const quantity = item.quantity || 0;
            const stock = item.productQuantityInStock || 0;
    
            if (!productQuantityMap.has(productId)) {
                productQuantityMap.set(productId, { total: 0, stock });
            }
    
            const productData = productQuantityMap.get(productId);
            productData.total += quantity;
            productQuantityMap.set(productId, productData);
        }
    
        // Vérifier si une somme dépasse le stock
        let hasStockIssue = false;
        for (const [productId, { total, stock }] of productQuantityMap.entries()) {
            console.log(`Produit ${productId} | Total demandé: ${total} | Stock: ${stock}`);
            if (total > stock) {
                hasStockIssue = true;
                break;
            }
        }
    
        this.stockQuantityError = hasStockIssue;
        console.log('Stock quantity error detected:', hasStockIssue);
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
            this.dispatchEvent(new RefreshEvent());
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