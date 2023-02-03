import { LightningElement,api } from 'lwc';

import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

import fetchAccountId from '@salesforce/apex/SC_Case_LightningUtility.queryParentAccountId';
import createElevation from '@salesforce/apex/SC_Case_LightningUtility.createElevation';

export default class ScNewElevationOnCase extends NavigationMixin(LightningElement)
{
    @api recordId;
    accountId;
    error;
    loadSpinner = true;
    firstInvoke = false;
    elevationValues = new Map();
    
    connectedCallback()
    {
        console.log('connected===============');
        console.log(this.recordId);
    }

    renderedCallback() 
    {
        console.log('rendered------------');
        console.log(this.recordId);
        if(typeof(this.recordId) !== "undefined" && !this.firstInvoke)
        {
            fetchAccountId({ idOftheCase: this.recordId })
            .then(result => 
            {
                console.log('Called get Accid : ' + result);
                this.accountId = result;
                //this.elevationValues.set('Account__c',result);
                this.elevationValues.Account__c = result;
                this.firstInvoke = true;
            })
            .catch(error => 
            {
                this.error = error;
                console.log(JSON.stringify(error));
            });
        }
    }

    handleOnChange(event)
    {
        var value;
        if(event.target.type === 'checkbox' || event.target.type === 'checkbox-button' || event.target.type === 'toggle')
        {
            value = event.target.checked;
        }
        else
        {
            value = event.target.value;
        }
        this.elevationValues[event.target.name] = value;
        //this.elevationValues.set(event.target.name,value);
    }

    handleLoad()
    {
        this.loadSpinner = false;
    }
    
    closeAction()
    {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    saveElevation()
    {
        var errorsPresent = false;
        this.loadSpinner = true;

        this.template.querySelectorAll('.newRecordForm').forEach(element => 
        {
            if (!element.reportValidity()) 
            {
                errorsPresent = true;
            }
        });

        if(errorsPresent)
        {
            this.loadSpinner = false;
            const toastEvt = new ShowToastEvent({
                title: "Error!",
                message: "Please ensure you fill in all the required fields with valid values",
                variant: "error",
                mode: "dismissible",
                duration: 5000
            });
            this.dispatchEvent(toastEvt);
        }
        else
        {
            console.log(this.elevationValues);
            createElevation({elevationParam : JSON.stringify(this.elevationValues), caseId : this.recordId})
            .then(result =>
            {
                this.closeAction();
                const toastEvt = new ShowToastEvent({
                    title: "Success!",
                    message: "Elevation Record created, redirecting...",
                    variant: "success",
                    mode: "dismissible",
                    duration: 5000
                });
                this.dispatchEvent(toastEvt);
                this.loadSpinner = false;
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: result,
                        objectApiName: 'Elevation__c',
                        actionName: 'view'
                    }
                });
                //this.handleRecordClick(result); 
            })
            .catch(error =>
            {
                console.log(JSON.stringify(error));
                this.loadSpinner = false;
                let errorBody = error.body;
                const toastEvt = new ShowToastEvent({
                    title: "Error!",
                    message: errorBody.message,
                    variant: "error",
                    mode: "dismissible",
                    duration: 7000
                });
                this.dispatchEvent(toastEvt);
            });
        }
    }


    handleRecordClick(elevId) 
    {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: elevId,
                actionName: 'view',
            },
        }).then(url => {
            const event = new ShowToastEvent({
                title: "Success!",
                message: "Record {0} created! See it {1}!",
                variant: "success",
                mode: "dismissible",
                duration: 5000,
                "messageData": [
                    'Salesforce',
                    {
                        url,
                        label: 'here'
                    }
                ]
            });
            this.dispatchEvent(event);
        });
    }

}