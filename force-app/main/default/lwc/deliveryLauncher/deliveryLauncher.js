import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

// Champs de la commande
import ORDER_ACCOUNT_FIELD from '@salesforce/schema/Order.AccountId';
import ORDER_SHIPPING_COUNTRY_FIELD from '@salesforce/schema/Order.ShippingCountry';
import ORDER_STATUS_FIELD from '@salesforce/schema/Order.Status';

// Méthodes des classes Apex
import getAvailableTransporters from '@salesforce/apex/TransporterSelector.getAvailableTransporters';
import createDelivery from '@salesforce/apex/DeliveryService.createDelivery';

export default class DeliveryLauncher extends NavigationMixin(LightningElement) {
    @api recordId; // ID de la commande
    @track order;
    @track transporters = [];
    @track selectedTransporter;
    @track isLoading = false;
    @track showTransporterModal = false;
    @track deliveryInProgress = false;

    // Données commande
    orderAccountId;
    orderShippingCountry;
    orderStatus;

    @wire(getRecord, { recordId: '$recordId', fields: [ORDER_ACCOUNT_FIELD, ORDER_SHIPPING_COUNTRY_FIELD, ORDER_STATUS_FIELD] })
    wiredOrder({ error, data }) {
        if (data) {
            this.order = data;
            this.orderAccountId = getFieldValue(data, ORDER_ACCOUNT_FIELD);
            this.orderShippingCountry = getFieldValue(data, ORDER_SHIPPING_COUNTRY_FIELD);
            this.orderStatus = getFieldValue(data, ORDER_STATUS_FIELD);
            
            if (this.orderShippingCountry) {
                this.loadTransporters();
            }
        } else if (error) {
            this.showToast('Erreur', 'Impossible de charger la commande', 'error');
        }
    }

    async loadTransporters() {
        if (!this.orderShippingCountry) return;

        this.isLoading = true;
        try {
            this.transporters = await getAvailableTransporters({ country: this.orderShippingCountry });
            
            // Sélectionner automatiquement le transporteur le moins cher
            if (this.transporters.length > 0) {
                this.selectedTransporter = this.transporters[0].Carrier__c;
            }
        } catch (error) {
            this.showToast('Erreur', 'Impossible de charger les transporteurs', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleLaunchDelivery() {
        if (this.orderStatus !== 'Activated') {
            this.showToast('Erreur', 'La commande doit être activée pour lancer une livraison', 'error');
            return;
        }
        
        if (this.transporters.length === 0) {
            this.showToast('Erreur', 'Aucun transporteur disponible pour ce pays', 'error');
            return;
        }

        this.showTransporterModal = true;
    }

    handleTransporterChange(event) {
        this.selectedTransporter = event.detail.value;
    }

    handleCloseModal() {
        this.showTransporterModal = false;
    }

    async handleConfirmDelivery() {
        if (!this.selectedTransporter) {
            this.showToast('Erreur', 'Veuillez sélectionner un transporteur', 'error');
            return;
        }

        this.deliveryInProgress = true;
        try {
            await createDelivery({
                orderId: this.recordId,
                transporterId: this.selectedTransporter
            });

            this.showToast('Succès', 'Livraison créée avec succès', 'success');
            this.showTransporterModal = false;
            
            // Rafraîchir la page pour afficher la nouvelle livraison
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    actionName: 'view'
                }
            });
        } catch (error) {
            this.showToast('Erreur', 'Impossible de créer la livraison', 'error');
        } finally {
            this.deliveryInProgress = false;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }

    // Getters pour l'interface
    get canLaunchDelivery() {
        return !(this.orderStatus === 'Activated' && this.transporters.length > 0);
    }

    get hasTransporters() {
        return this.transporters.length > 0;
    }

    get selectedTransporterDetails() {
        return this.transporters.find(t => t.Carrier__c === this.selectedTransporter);
    }

    get transporterOptions() {
        return this.transporters.map(transporter => ({
            label: `${transporter.Carrier__r.Name__c} - ${transporter.Price__c}€ (${transporter.DeliveryTimePeriod__c} jours)`,
            value: transporter.Carrier__c,
            description: `${transporter.Price__c}€ - ${transporter.DeliveryTimePeriod__c} jours`
        }));
    }

    get fastestTransporter() {
        if (this.transporters.length === 0) return null;
        return this.transporters.reduce((fastest, current) => 
            current.DeliveryTimePeriod__c < fastest.DeliveryTimePeriod__c ? current : fastest
        );
    }

    get cheapestTransporter() {
        if (this.transporters.length === 0) return null;
        return this.transporters.reduce((cheapest, current) => 
            current.Price__c < cheapest.Price__c ? current : cheapest
        );
    }

    get statusBadgeClass() {
        if (this.orderStatus === 'Activated') {
            return 'slds-theme_success';
        } else if (this.orderStatus === 'Draft') {
            return 'slds-theme_warning';
        } else {
            return 'slds-theme_default';
        }
    }
}