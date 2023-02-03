/* eslint-disable no-eval */
/* eslint-disable no-console */
/* eslint-disable no-alert */
import { LightningElement, api} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

/** ScProvisioningTaskPDMapping.search() Apex method */
import apexSearch from '@salesforce/apex/SC_ProvisioningDashboard_Controller.search';
import savePDMappings from '@salesforce/apex/SC_ProvisioningDashboard_Controller.savePDMappings';
import deletePDMappings from '@salesforce/apex/SC_ProvisioningDashboard_Controller.deletePDMappings';
import getPDs from '@salesforce/apex/SC_ProvisioningDashboard_Controller.getPDs';

export default class ScProvisioningTaskPDMapping extends LightningElement {
    // Use alerts instead of toast to notify user
    @api notifyViaAlerts = false;
    @api recordId;

    loadSpinner = false;
    isMultiEntry = true;
    disableSave = true;
    maxSelectionSize = 100;
    initialSelection = [];
    errors = [];
    curTaskRecordId = '';

    connectedCallback() 
    {
        this.curTaskRecordId = this.recordId;
        getPDs({ recordTaskID: this.curTaskRecordId  })
            .then((results) => {
                this.initialSelection = results;
                if(this.initialSelection.length === 0){
                    this.errors.push({ message: 'Please make a selection.' });
                } 
            })
            .catch((error) => {
                this.notifyUser('Error', 'An error occured while searching.', 'error');
                console.error('Lookup error', JSON.stringify(error));
                this.errors = [error];
            });
    }

    handleSearch(event) {
        apexSearch(event.detail)
            .then((results) => {
                this.template.querySelector('c-sc-reusable-multi-select-lookup').setSearchResults(results);
            })
            .catch((error) => {
                this.notifyUser('Error', error.body.message, 'error');
                this.errors = [error];
            });
    }

    handleSelectionAdd() {
        this.disableSave = false;
        this.checkForErrors();
    }
    handleSelectionRemove(){
        this.loadSpinner = true;
        const selection = this.template.querySelector('c-sc-reusable-multi-select-lookup').getSelection();
        let tempArray = [];
        selection.forEach(function(eachRow)
        {
            tempArray.push(eachRow.id);
        });

        //this.checkForErrors();
        deletePDMappings({ policyDomainList: tempArray, recordTaskID: this.curTaskRecordId })
        .then(result => {
            this.loadSpinner = false;
            console.log('RESULT : '+result);
            eval("$A.get('e.force:refreshView').fire();");
            this.notifyUser('Success !', 'Policy Domain removed Successfully', 'success');
        })
        .catch(error => {
            this.loadSpinner = false;
            this.notifyUser('Error !', error.body.message, 'error');
        });

        if (tempArray.length === 0) {
            this.errors.push({ message: 'Please make a selection.' });
        }
    }

    handleSubmit() {
        this.loadSpinner = true;
        const selection = this.template.querySelector('c-sc-reusable-multi-select-lookup').getSelection();
        let tempArray = [];
        selection.forEach(function(eachRow)
        {
            tempArray.push(eachRow.id);
        });

        this.checkForErrors();
        if (this.errors.length === 0) {
            savePDMappings({ policyDomainList: tempArray, recordTaskID: this.curTaskRecordId })
            .then(result => {
                this.loadSpinner = false;
                console.log('RESULT : '+result);
                eval("$A.get('e.force:refreshView').fire();");
                this.notifyUser('Success !', 'Policy Domain addedd Successfully', 'success');
            })
            .catch(error => {
                this.loadSpinner = false;
                this.notifyUser('Error !', error.body.message, 'error');
            });
        }
    }

    checkForErrors() {
        this.errors = [];
        const selection = this.template.querySelector('c-sc-reusable-multi-select-lookup').getSelection();
        // Custom validation rule
        if (this.isMultiEntry && selection.length > this.maxSelectionSize) {
            this.errors.push({ message: `You may only select up to ${this.maxSelectionSize} items.` });
        }
        // Enforcing required field
        if (selection.length === 0) {
            this.errors.push({ message: 'Please make a selection.' });
        }
    }

    notifyUser(title, message, variant) {
        if (this.notifyViaAlerts) {
            // Notify via alert
            alert(`${title}\n${message}`);
        } else {
            // Notify via toast
            const toastEvent = new ShowToastEvent({ title, message, variant });
            this.dispatchEvent(toastEvent);
        }
    }
}