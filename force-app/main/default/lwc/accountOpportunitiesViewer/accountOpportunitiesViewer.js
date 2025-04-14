import { LightningElement, api, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getOpportunities from '@salesforce/apex/AccountOpportunitiesController.getOpportunities';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class AccountOpportunitiesViewer extends LightningElement {
    @api recordId;
    @track opportunities;
    @track error = {};
    wiredResult; // on stocke le résultat de la MAJ 


    columns = [
        { label: 'Nom Opportunité', fieldName: 'Name', type: 'text' },
        { label: 'Montant', fieldName: 'Amount', type: 'currency' },
        { label: 'Date de Clôture', fieldName: 'CloseDate', type: 'date' },
        { label: 'Phase', fieldName: 'StageName', type: 'text' }
    ];


    // on créé une méthode pour afficher un message aux utilisateurs pour notifier la mise à jour de l'oppty
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }

    @wire(getOpportunities, { accountId: '$recordId' })
    wiredOpportunities(result) {
        this.wiredResult = result;
        if (result.data) {
            this.opportunities = result.data;
        } else if (result.error) {
            this.error = result.error;
            this.opportunities = undefined;
        }
    }
    
    handleRafraichir() {
        console.log('Rafraîchissement lancé');
        refreshApex(this.wiredResult)
            .then(() => {console.log('Rafraîchissement OK.');
            this.showToast('Succès', 'Données rafraîchies avec succès.', 'success'); // on affiche un message toast
    })
            .catch(error => {console.error('Erreur :', error);
            this.showToast('Erreur', 'Une erreur est survenue lors du rafraîchissement des données.', 'error'); // on affiche un message toast avec erreur 
            });
        }


}