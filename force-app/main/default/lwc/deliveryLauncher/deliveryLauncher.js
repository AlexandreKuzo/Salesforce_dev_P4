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
import getDeliveriesForOrder from '@salesforce/apex/DeliveryService.getDeliveriesForOrder';
import getOrderDeliveryStatus from '@salesforce/apex/DeliveryService.getOrderDeliveryStatus';

export default class DeliveryLauncher extends NavigationMixin(LightningElement) {
    @api recordId; // ID de la commande
    @track order;
    @track transporters = [];
    @track selectedTransporter;
    @track isLoading = false;
    @track showTransporterModal = false;
    @track deliveryInProgress = false;
    @track existingDeliveries = [];
    @track orderDeliveryStatus = '';

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
                this.loadExistingDeliveries();
                this.loadOrderDeliveryStatus();
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
        } catch (error) {
            this.showToast('Erreur', 'Impossible de charger les transporteurs', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async loadExistingDeliveries() {
        try {
            this.existingDeliveries = await getDeliveriesForOrder({ orderId: this.recordId });
        } catch (error) {
            console.error('Erreur lors du chargement des livraisons:', error);
        }
    }

    async loadOrderDeliveryStatus() {
        try {
            this.orderDeliveryStatus = await getOrderDeliveryStatus({ orderId: this.recordId });
        } catch (error) {
            console.error('Erreur lors du chargement du statut de livraison:', error);
        }
    }

    handleLaunchDelivery() {
        if (this.orderStatus !== 'Activated') {
            this.showToast('Erreur', 'La commande doit être activée pour lancer une livraison', 'error');
            return;
        }
        
        if (!this.selectedTransporter) {
            this.showToast('Erreur', 'Veuillez sélectionner un transporteur', 'error');
            return;
        }

        // Lancer directement la livraison avec le transporteur sélectionné
        this.handleConfirmDelivery();
    }

    handleTransporterChange(event) {
        this.selectedTransporter = event.detail.value;
    }

    handleTransporterSelect(event) {
        const transporterId = event.currentTarget.dataset.transporterId;
        this.selectedTransporter = transporterId;
        
        // Mettre à jour les classes CSS pour indiquer la sélection
        this.updateTransporterSelection();
    }

    updateTransporterSelection() {
        // Supprimer la classe selected de tous les transporteurs
        const transporterOptions = this.template.querySelectorAll('.transporter-option');
        transporterOptions.forEach(option => {
            option.classList.remove('selected');
        });

        // Ajouter la classe selected au transporteur sélectionné
        if (this.selectedTransporter) {
            const selectedOption = this.template.querySelector(`[data-transporter-id="${this.selectedTransporter}"]`);
            if (selectedOption) {
                selectedOption.classList.add('selected');
            }
        }
    }

    renderedCallback() {
        // Mettre à jour la sélection visuelle après le rendu
        this.updateTransporterSelection();
    }

    handleShowAllTransporters() {
        this.showTransporterModal = true;
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

            this.showToast('Succès', 'Livraison confirmée avec succès', 'success');
            this.showTransporterModal = false;
            
            // Recharger les données
            await this.loadExistingDeliveries();
            await this.loadOrderDeliveryStatus();
            
            // Rafraîchir la page pour afficher la nouvelle livraison
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    actionName: 'view'
                }
            });
        } catch (error) {
            this.showToast('Erreur', error.body?.message || 'Impossible de créer la livraison', 'error');
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
        return !(this.orderStatus === 'Activated' && this.transporters.length > 0 && this.selectedTransporter);
    }

    get hasTransporters() {
        return this.transporters.length > 0;
    }

    get hasExistingDeliveries() {
        return this.existingDeliveries.length > 0;
    }

    get selectedTransporterDetails() {
        return this.transporters.find(t => t.Carrier__c === this.selectedTransporter);
    }

    get transporterOptions() {
        return this.transporters.map(transporter => ({
            label: `${transporter.Carrier__r?.Name__c || 'Transporteur inconnu'} - ${transporter.Price__c || 0}€ (${transporter.DeliveryTimePeriod__c || 0} jours)`,
            value: transporter.Carrier__c,
            description: `${transporter.Price__c || 0}€ - ${transporter.DeliveryTimePeriod__c || 0} jours`
        }));
    }

    get fastestTransporter() {
        if (this.transporters.length === 0) return null;
        const validTransporters = this.transporters.filter(t => 
            t && t.Carrier__r && t.Carrier__r.Name__c && t.DeliveryTimePeriod__c
        );
        if (validTransporters.length === 0) return null;
        return validTransporters.reduce((fastest, current) => 
            current.DeliveryTimePeriod__c < fastest.DeliveryTimePeriod__c ? current : fastest
        );
    }

    get cheapestTransporter() {
        if (this.transporters.length === 0) return null;
        const validTransporters = this.transporters.filter(t => 
            t && t.Carrier__r && t.Carrier__r.Name__c && t.Price__c
        );
        if (validTransporters.length === 0) return null;
        return validTransporters.reduce((cheapest, current) => 
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

    get deliveryStatusBadgeClass() {
        switch (this.orderDeliveryStatus) {
            case 'Livrée':
                return 'slds-theme_success';
            case 'En cours de livraison':
                return 'slds-theme_info';
            case 'Confirmée':
                return 'slds-theme_warning';
            case 'En attente':
                return 'slds-theme_default';
            case 'Annulée':
                return 'slds-theme_error';
            default:
                return 'slds-theme_default';
        }
    }
}
