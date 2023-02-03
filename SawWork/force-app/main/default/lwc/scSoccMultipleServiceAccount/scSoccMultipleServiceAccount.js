/* 
Created By : Tejaswini
Jira       : ESESP-4953
Purpose    : Component to link Multiple service account to Pd
Date       : 09-April-2020
*/
import { LightningElement,api} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getServiceAccounts from '@salesforce/apex/SC_SOCC_MultipleServiceAccountCtrl.getServiceAccounts';
import apexSearch from '@salesforce/apex/SC_SOCC_MultipleServiceAccountCtrl.search';
import saveServiceAccountMappings from '@salesforce/apex/SC_SOCC_MultipleServiceAccountCtrl.saveServiceAccountMappings';
import deleteServiceAccountMappings from '@salesforce/apex/SC_SOCC_MultipleServiceAccountCtrl.deleteServiceAccountMappings';
import util from 'c/scUtil'; 

export default class ScSoccMultipleServiceAccount extends LightningElement {
    @api notifyViaAlerts = false;
    @api recordId;

    loadSpinner = false;
    isMultiEntry = true;
    disableSave = true;
    maxSelectionSize = 100;
    initialSelection = [];
    errors = [];
    //curTaskRecordId = '';
    curObjRecordId = '';

    connectedCallback() 
    {
       
        this.curObjRecordId = this.recordId;
        getServiceAccounts({ recordPdID: this.curObjRecordId  })
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
        //this.notifyUser('Success !', 'Hi ', 'success');
        console.log(tempArray);
        
        //this.checkForErrors();
        deleteServiceAccountMappings({ accountList: tempArray, recordPdID: this.curObjRecordId })
        .then(result => {
            this.loadSpinner = false;
            console.log('RESULT : '+result);
            eval("$A.get('e.force:refreshView').fire();");
            this.notifyUser('Success !', 'Service Account removed Successfully', 'success');
            //util.fire('refreshPIs', this.recordId);
            util.fire('refreshAuthContact');
        })
        .catch(error => {
            this.loadSpinner = false;
            console.log('error :'+ error.body.pageErrors[0].message);
            let errorMsg=error.body.message;

                console.log('error :'+ error.body.pageErrors[0].message);

                if(error.body.pageErrors[0].message==='Insufficient Privileges')
                {
                    errorMsg=error.body.pageErrors[0].message+', Only SSPs are allowed to make changes';
                    
                }
                
            this.notifyUser('Error !', errorMsg, 'error');
            this.connectedCallback();
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
            saveServiceAccountMappings({ accountList: tempArray, recordPdID: this.curObjRecordId })
            .then(result => {
                this.loadSpinner = false;
                console.log('RESULT : '+result);
                eval("$A.get('e.force:refreshView').fire();");
                this.notifyUser('Success !', 'Service Account added Successfully', 'success');
            })
            .catch(error => {
                this.loadSpinner = false;
                
                let errorMsg=error.body.message;

                console.log('error :'+ error.body.pageErrors[0].message);

                if(error.body.pageErrors[0].message==='Insufficient Privileges')
                {
                    errorMsg=error.body.pageErrors[0].message+', Only SSPs are allowed to make changes';
                    
                }
                
                this.notifyUser('Error !', errorMsg, 'error');
                    
                this.connectedCallback();
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
        /*if (this.notifyViaAlerts) {
            // Notify via alert
            alert(`${title}\n${message}`);
        } else {*/
            // Notify via toast
            const toastEvent = new ShowToastEvent({ title, message, variant });
            this.dispatchEvent(toastEvent);
        
    }
}