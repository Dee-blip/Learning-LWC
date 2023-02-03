/* eslint-disable no-console */
/* eslint-disable no-alert */

import { LightningElement, api, track } from "lwc";
import { NavigationMixin } from "lightning/navigation";

import returnRecTypeId from "@salesforce/apex/SC_SecurityServices_Ctrlr.returnRecTypeId";
import systemMapRecords from "@salesforce/apex/SC_SecurityServices_Ctrlr.systemAreaMappingRecords";
import getEscalationRec from "@salesforce/apex/SC_SecurityServices_Ctrlr.returnEscalationRec";

import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class ScExternalTeamEscalation extends NavigationMixin(LightningElement) 
{
    @api escRecordId;
    @api caseRecId;
    @api newInline = false;
    @api existingRec = false;

    @api isConsole = false;

    isJIRASystem = false;
    isOtherSystem = false;
    loadSpinner = true;
    extTeamRecTypeId;
    loaded = false;

    escRec;

    systemAreaMapVal = new Map();
    systemURLMapVal = new Map();

    systemOptionVals = [];
    systemValues = [];
    areaValues = [];

    testing = true;

    systemVal = '';
    areaVal = '';

    connectedCallback() 
    {
        console.log('ESC Record Id : ' + this.escRecordId);
        this.extTeamEscRecTypeId();
        this.getServiceMappingRecords();

        if(this.escRecordId)
        {
            this.existingRec = true;
            getEscalationRec({escId : this.escRecordId})
            .then(result => 
            {
                console.log(result.System__c + ' :: ' + result.Area__c);
                this.escRec = result;
                this.newInline = false;
                this.systemVal = result.System__c;
                this.areaVal = result.Area__c;
                if(this.systemVal === 'JIRA')
                    this.isJIRASystem = true;
                else if(this.systemVal === 'Other')
                    this.isOtherSystem = true;
                this.caseRecId = result.Case__c;
            })
            .catch(error => 
            {

            });
        }
        console.log(this.caseRecId);
    }

    get systemOptions() 
    {
        let sysOp = [];
        if (this.systemOptionVals) 
        {
            for (let i = 0; i < this.systemOptionVals.length; i++) 
            {
                let option = 
                {
                    label: this.systemOptionVals[i],
                    value: this.systemOptionVals[i]
                };
                sysOp.push(option);
            }
        }
        return sysOp;
    }

    get areaOptions() 
    {   
        let areaOp = [];
        if (this.systemOptionVals && this.systemAreaMapVal.has(this.systemVal)) 
        {
            let areaVals = this.systemAreaMapVal.get(this.systemVal).split("\n");
            for (let i = 0; i < areaVals.length; i++) 
            {
                let option = {
                label: areaVals[i].trim(),
                value: areaVals[i].trim()
                };
                areaOp.push(option);
            }
        }
        return areaOp;
    }

    extTeamEscRecTypeId() 
    {
        this.loadSpinner = true;
        returnRecTypeId({
        sObjName: "Engagement_Request__c",
        recTypeName: "External Team"
        })
        .then(result => {
            this.extTeamRecTypeId = result;
            console.log(this.extTeamRecTypeId);
            this.loadSpinner = false;
        })
        .catch(error => {
            this.error = error;
        });
    }

    getServiceMappingRecords() 
    {
        this.loadSpinner = true;
        systemMapRecords()
        .then(result => {
            for (let i = 0; i < result.length; i++) {
            this.systemOptionVals.push(result[i].System__c);
            this.systemAreaMapVal.set(result[i].System__c, result[i].Area__c);
            this.systemURLMapVal.set(
                result[i].System__c,
                result[i].System_URL__c
            );
            }
            this.loaded = true;
            this.loadSpinner = false;
        })
        .catch(error => {
            this.error = error;
            console.log("error : " + error);
            this.loadSpinner = false;
        });
    }

    systemChange(event) 
    {
        console.log('System Change Called');
        this.areaValues = [];
        this.systemVal = event.detail.value;

        if (event.detail.value === "JIRA" || !event.detail.value) 
        {
            this.isJIRASystem = true;
        } 
        else 
            this.isJIRASystem = false;
        if (event.detail.value === "Other" || !event.detail.value) 
        {
            this.isOtherSystem = true;
        } 
        else 
            this.isOtherSystem = false;
        
        this.areachangeMethod();
    }

    areachangeMethod()
    {
        if (this.systemAreaMapVal.has(this.systemVal)) 
        {
            let areaVals = this.systemAreaMapVal.get(this.systemVal).split("\n");
            for (let i = 0; i < areaVals.length; i++) 
            {
                let option = {
                label: areaVals[i].trim(),
                value: areaVals[i].trim()
                };
                this.areaValues.push(option);
            }
        }
    }

    areaChange(event) 
    {
        console.log('Area Change Called');
        this.areaVal = event.detail.value;
    }

    handleSave(event)
    {
        this.loadSpinner = true;
        event.preventDefault();
    }    

    handleSubmit(event) 
    {
        this.loadSpinner = true;
        event.preventDefault();
        const fields = event.detail.fields;
        console.log(fields);
        fields.System__c = this.systemVal;
        fields.Area__c = this.areaVal;
        if(this.newInline)
        {
            fields.System__c = 'JIRA';
            fields.Area__c = 'Engineering Other';
        }

        if ((!this.systemVal || !this.areaVal) && !this.newInline) 
        {
            this.showErrorToast("Please fill out all mandatory fields");
            this.loadSpinner = false;
        } 
        else
            this.template.querySelector(".newRecordForm").submit(fields);
    }

    handleSuccess(event) 
    {
        const updatedRecord = event.detail.id;
        let baseURL = window.location.origin + '/lightning/r/Engagement_Request__c/' + updatedRecord + '/view';
        if(this.newInline){
            window.open(baseURL, '_blank');
        }
        else{
            //Aditi - added check for console and non-console for different behaviours in each ( in console opens as subtab/closes subtab while in non-console open in new tab/change whole url)
            if(this.isConsole){
                const sendDataEvent = new CustomEvent('gettingtheurl',{
                    detail: {baseURL}
                });
                this.dispatchEvent(sendDataEvent);//Aditi - first event to pass the url to aura

                this.dispatchEvent(new CustomEvent('closeSubTab', {bubbles:true, composed:true})); //second event to go to the url and close the existing tab
            }
            else{
                window.open(baseURL, '_self');
            }
        }
    }

    handleError() 
    {
        this.loadSpinner = false;
    }

    handleCancelNew(event)
    {
        //Aditi - Added below code for ESESP-5423 resolving cancel button issue
        console.log("console value in lwc is =="+this.isConsole);
        if(!this.isConsole){
            event.preventDefault();
            event.stopPropagation();
            this.loadSpinner = false;
            let baseURL = window.location.origin + '/lightning/o/Engagement_Request__c/home';
            window.open(baseURL, '_self');
        }
        else{
            this.dispatchEvent(new CustomEvent('closeSubTab', {bubbles:true, composed:true}));
        }
        return null;
    }

    showErrorToast(mssg) 
    {
        const evt = new ShowToastEvent({
        title: "Error!",
        message: mssg,
        variant: "error",
        mode: "dismissable"
        });
        this.dispatchEvent(evt);
    }
}