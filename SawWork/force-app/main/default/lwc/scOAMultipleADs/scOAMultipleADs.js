import { LightningElement,wire,api,track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';

import fetchApprovalDetails from '@salesforce/apex/SC_OrderApprovals_LightningCtrl.fetchApprovalDetails';
import saveToCase from '@salesforce/apex/SC_OrderApprovals_LightningCtrl.saveToCase';

import {ShowToastEvent} from 'lightning/platformShowToastEvent';

export default class ScOAMultipleADs extends NavigationMixin (LightningElement) {
    allADs;
    @api recordId;

    disableCopy = true;
    activeSections = [];

    ADSize = 0;
    selectedADs = [];
    loadSpinner = false;
    showConfirmModal = false;
    showADList = false;
    isDD = false;
    wiredADList;

    @wire(fetchApprovalDetails, { caseId: '$recordId'}) 
    ADList(result) {
        this.wiredADList = result;
        if (result.data) {
            if(result.data.length > 0){
                this.ADSize = result.data.length;
                this.allADs = result.data;
                this.showADList = true;
            }
            if(result.data[0].ADRec.Related_To__r.RecordType.Name == 'Order Approval-Deal Desk' || result.data[0].ADRec.Related_To__r.RecordType.Name == 'Order Approval-Escalations'){
                this.isDD = true; 
            }
        }
        else if (result.error) {
            let customError = 'An Error Occurred While Loading Approval Details : ';
            let errorMessage = result.error.body.message;
            if(errorMessage.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
                errorMessage = errorMessage.split('FIELD_CUSTOM_VALIDATION_EXCEPTION')[1];
            }
            customError += errorMessage;
            //customError += result.error.body.message;

            const toastEvt = new ShowToastEvent({
                title: "Error!",
                message: customError,
                variant: "error",
                mode: "dismissible",
                duration: 5000
            });
            this.dispatchEvent(toastEvt);
        }
    }

    //Called on click of refresh icon
    refreshADs(){
        if(this.wiredADList.data.length > 0){
            refreshApex(this.wiredADList);
            if(this.wiredADList.data[0].ADRec.Related_To__r.RecordType.Name == 'Order Approval-Deal Desk' || this.wiredADList.data[0].ADRec.Related_To__r.RecordType.Name == 'Order Approval-Escalations'){
                this.isDD = true;
            }
        }
        else{
            window.location.reload();
            /*fetchApprovalDetails({caseId:this.recordId}) 
            .then(result => {
                this.ADSize = result.length;
                this.allADs = result;
                if(this.ADSize > 0){
                    this.showADList = true;
                    if(result[0].ADRec.Related_To__r.RecordType.Name == 'Order Approval-Deal Desk' || result[0].ADRec.Related_To__r.RecordType.Name == 'Order Approval-Escalations'){
                        this.isDD = true;
                    }
                }
            })
            .catch(error => {
                let customError = 'An Error Occurred While Loading Approval Details : ';
                let errorMessage = error.message;
                if(errorMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
                    errorMessage = errorMessage.split('FIELD_CUSTOM_VALIDATION_EXCEPTION')[1];
                }
                customError += errorMessage;

                const toastEvt = new ShowToastEvent({
                    title: "Error!",
                    message: customError,
                    variant: "error",
                    mode: "dismissible",
                    duration: 5000
                });
                this.dispatchEvent(toastEvt);
            });*/
        }
    }
    
    connectedCallback() 
    {
        /*fetchApprovalDetails({caseId:this.recordId}) 
        .then(result => {
            this.ADSize = result.length;
            this.allADs = result;
            if(this.ADSize > 0){
                this.showADList = true;
            }
            if(result[0].ADRec.Related_To__r.RecordType.Name== 'Order Approval-Deal Desk' || result[0].ADRec.Related_To__r.RecordType.Name == 'Order Approval-Escalations'){
                this.isDD = true;
            }
        })
        .catch(error => {
            let customError = 'An Error Occurred While Loading Approval Details : ';
            customError += error.body.message;

            const toastEvt = new ShowToastEvent({
                title: "Error!",
                message: customError,
                variant: "error",
                mode: "dismissible",
                duration: 5000
            });
            this.dispatchEvent(toastEvt);
        });*/
    }

    /*Navigate to AD detail page*/
    navigateToDetail(event){
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.target.id.substring(0,18),
                objectApiName: 'Approval_Details__c', // objectApiName is optional
                actionName: 'view'
            }
        });
    }

    /*Navigate to AD edit page*/
    navigateToEdit(event){
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.target.id.substring(0,18),
                objectApiName: 'Approval_Details__c', // objectApiName is optional
                actionName: 'edit'
            }
        });
    }

    /* Expand all accordian section */
    expandAll(){
        this.activeSections = this.allADs.map(allADs=>allADs.ADRec.Name);
    }

    /* Collapse all accordian section */
    collapseAll(){
        this.activeSections = [];
    }

    /* Onselect of each master checkbox */
    allSelected(event){
        let selectedRows = this.template.querySelectorAll('lightning-input');
        this.selectedADs = [];
        for(let i = 0; i < selectedRows.length; i++) {
            if(selectedRows[i].type === 'checkbox') {
                this.disableCopy = false;
                selectedRows[i].checked = event.target.checked;
                if(selectedRows[i].checked === true){
                    if(i < this.allADs.length)
                        this.selectedADs.push(this.allADs[i].ADRec.Id);
                }
                else{
                    this.disableCopy = true;
                    this.selectedADs = [];
                }
            }
        }
    }

    /* Onselect of each checkbox */
    rowSelChangeEvent(event){
        if(event.target.checked){
            this.disableCopy = false;
            this.selectedADs.push(event.target.value);
        }
        else{
            this.disableCopy = true;
            if(this.selectedADs.indexOf(event.target.value) > -1)
                this.selectedADs.splice(this.selectedADs.indexOf(event.target.value),1)
        }
    }

    /* Copy all approver notes to case */
    copyToCase(){
        this.loadSpinner = true;
        saveToCase({caseId:this.recordId,adList:this.selectedADs}) 
        .then(result => {
            this.loadSpinner = false;
            const toastEvt = new ShowToastEvent({
                title: "",
                message: "Successfully Copied To Case",
                variant: "success",
                mode: "dismissible",
                duration: 5000
            });
            this.dispatchEvent(toastEvt);
            this.showConfirmModal = false;
            window.location.reload();
        })
        .catch(error => {
            let customError = 'An Error Occurred While Copying : ';
            let errorMessage = error.body.message;
            if(errorMessage.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
                errorMessage = errorMessage.split('FIELD_CUSTOM_VALIDATION_EXCEPTION')[1];
            }
            customError += errorMessage;

            const toastEvt = new ShowToastEvent({
                title: "Error!",
                message: customError,
                variant: "error",
                mode: "dismissible",
                duration: 5000
            });
            this.dispatchEvent(toastEvt);
            this.loadSpinner = false;
        });
    }

    /* Show Conformation window */
    showCopyToCase(){
        this.showConfirmModal = true;
    }

    /* Close Conformation window */
    closeConfirmModal(){
        this.showConfirmModal = false;
    }

    
}