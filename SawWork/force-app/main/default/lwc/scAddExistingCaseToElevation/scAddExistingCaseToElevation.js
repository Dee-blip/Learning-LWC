import { LightningElement,api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import updateRecord from  "@salesforce/apex/SC_Case_LightningUtility.addExistingRecordToElevation";

import { ShowToastEvent } from "lightning/platformShowToastEvent";


export default class ScAddExistingCaseToElevation extends NavigationMixin(LightningElement)
{

    @api recordId;
    @api objectType;

    recId = null;
    loadSpinner = true;

    caseType = false;
    escType = false;
    siType = false;
    elevType = false;
    header;
    objectName = 'Case';
    saveLabel = 'Add Case';

    currentPageReference = null; 

    /*
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) 
    {
       if (currentPageReference) 
       {
          this.urlStateParameters = currentPageReference.state;
          this.setParametersBasedOnUrl();
       }
    }

    setParametersBasedOnUrl() 
    {
        var input = JSON.stringify(this.urlStateParameters);
        var start = input.indexOf("Elevation__c/") + 13;
        var recId = input.substring(start, input.indexOf("/view"));
        this.recordId = recId;
    }  
    */

    //Method executed before the page is rendered
    connectedCallback()
    {
        console.log('connected callback : ' + this.recordId + '::' + this.objectType);
        
        if(this.objectType !== undefined)
        {
            if(this.objectType === 'case')
                this.caseType = true;
            else if(this.objectType === 'escalation')
            {
                this.escType = true;
                this.objectName = 'Escalation';
                this.saveLabel = 'Add ' + this.objectName;
            }
            else if(this.objectType === 'serviceincident')
            {
                this.siType = true;
                this.objectName = 'Service Incident';
                this.saveLabel = 'Add ' + this.objectName;
            }
            else if(this.objectType === 'elevation')
            {
                this.elevType = true;
                this.objectName = 'Elevation';
                this.saveLabel = 'Add ' + this.objectName;
            }
        }
        this.header = this.objectName === 'Elevation' ? 'Add Existing ' + this.objectName + ' to Service Incident' : 'Add Existing ' + this.objectName + ' to Elevation';
    } 

    handleLoad()
    {
        console.log('onload');
        this.loadSpinner = false;
    }


    //Method fired when Update Cases button is clicked
    handleUpdate()
    {
        
    }

    relatedCaseChange(event)
    {
        this.recId = event.target.value;
    }

    handleSubmit(event)
    {
        event.preventDefault();
        console.log('handleSubmit called');
        this.loadSpinner = true;
        console.log(this.recId);
        console.log(this.recordId);
        if(!this.recId)
        {
            this.loadSpinner = false;
            const toastEvt = new ShowToastEvent({
            "title": "Please select a record to add",
            "message": "",
            "variant": "error",
            "mode": "dismissible",
            "duration": 5000
            });
            this.dispatchEvent(toastEvt);
        }
        else
        {
            updateRecord({
            objRecId: this.recId,
            objType: this.objectType,
            elevationRecId : this.recordId
            })
            .then(result => 
            {
                console.log('entered success ' + result);//window.location.reload(true);
                this.handleSuccess();
            }).catch(error => {
                console.log('entered error : ' + JSON.stringify(error));
                this.handleError(error.body);
            });
        }
    }

    handleSuccess()
    {
        console.log('entered handlesuccess');
        this.loadSpinner = false;
        const toastEvt = new ShowToastEvent({
            title: "Success!",
            message: this.objectName + " added to the Elevation!",
            variant: "success",
            mode: "dismissible",
            duration: 5000
        });
        this.dispatchEvent(toastEvt);
        this.handleReset();
    }

    handleReset() 
    {
        const inputFields = this.template.querySelectorAll(
            'lightning-input-field'
        );
        if (inputFields) {
            inputFields.forEach(field => {
                field.reset();
            });
        }
     }

    handleError(errormessage)
    {
        this.loadSpinner = false;
        const toastEvt = new ShowToastEvent({
            "title": "Error!",
            "message": errormessage.message,
            "variant": "error",
            "mode": "dismissible",
            "duration": 7000
        });
        this.dispatchEvent(toastEvt);
    }


    closeTab()
    {
       this.dispatchEvent(new CustomEvent('closeSubTab', {bubbles:true, composed:true}));
    }

    returnToElevation()
    {
        this.closeTab();
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Elevation__c',
                actionName: 'view'
            }
        });
    }

    disconnectedCallback()
    {
        console.log('called here');
    }


}