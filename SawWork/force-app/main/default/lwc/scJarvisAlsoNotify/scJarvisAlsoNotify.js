import { LightningElement,api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import alsoNotifyCheck from '@salesforce/apex/SC_Jarvis_Create_Case_Controller.alsoNotifyCheck';
import updateCaseRecord from '@salesforce/apex/SC_Jarvis_Create_Case_Controller.updateCaseRecord';

import {LABELS}  from "./scJarvisAlsoNotifyLabel"
export default class ScJarvisUpdateCase extends LightningElement 
{
    
    
        @api recordId;
    
        labels = LABELS;
        loadSpinner = false;
        disableSubmit = true;
        caseRecord;
        noChange = true;
        validEmailMessage;
        warningMessage='';
        recordEditForm = '';
        showConfirmClass = 'hidden';
        recordEditFormButton = 'slds-button slds-button_brand';
        showConfirmClassbuttonCancel = 'slds-button slds-button_neutral hidden';
        showConfirmClassbuttonConfirm = 'slds-button slds-button_brand hidden';

        get showValidation()
        {
            return this.validEmailMessage? true: false;
        }
        checkIfDuplicateExists(arrayToCheck)
        {
            return new Set(arrayToCheck).size !== arrayToCheck.length;
        }
    
        showToast(variant,message,title,mode)
        {
            const event = new ShowToastEvent({
                "title": title,
                "message": message,
                "mode" : mode,
                "variant" : variant,
                "duration": 5000
            });
            this.dispatchEvent(event);        
        }
    
        onFieldChange(event)
        {
                this.noChange = false;
                event.target.classList.remove('slds-has-error');
                this.validEmailMessage = "";
        }
        validateForm()
        {          
                console.log('recordId:' + this.recordId);      
                this.disableSubmit = false;
                let toastHeader;
                this.validEmailMessage = "";
                this.alternateEmailMessage = "";
                const re = /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;

                let alsoNotify = this.template.querySelector(".Jarvis_Also_Notify__c");
                let validEmail = true;
                console.log('alsoNotify: ' + alsoNotify);
                if(alsoNotify.value && alsoNotify !== this.existingAlsoNotify)
                {
                    let arrayToCheck = alsoNotify.value.split(/[,;\s\n]+/);                    
                    if(arrayToCheck.length > 10)
                    {
                        toastHeader = this.labels.TOAST_LIMIT;
                        this.validEmailMessage = this.labels.TOAST_LIMIT_MESSAGE;
                        validEmail = false;
                    }
                    else if(this.checkIfDuplicateExists(arrayToCheck))
                    {
                        this.validEmailMessage = this.labels.TOAST_DUPLICATE_MESSAGE;
                        toastHeader = this.labels.TOAST_DUPLICATE;
                        validEmail = false;
                    }
                    else
                    {
                        validEmail = arrayToCheck.reduce(
                            function(valid,cur)
                            { 
                                return valid && re.test(String(cur).toLowerCase()); 
                            },
                            true
                        )
                        if(!validEmail)
                        {
                            toastHeader = this.labels.TOAST_INVALID;
                            this.validEmailMessage = this.labels.TOAST_INVALID_MESSAGE;   
                        }
                        console.log('validEmail:' + validEmail);
            
                    }
                    if(!validEmail)
                    {
                        this.showToast('error',this.validEmailMessage,toastHeader,'dismissible');
                        alsoNotify.classList.add('slds-has-error');        
                    }       
                }
                
                if(!toastHeader && this.noChange)
                {
                    toastHeader = this.labels.TOAST_NO_CHANGES;                    
                    this.showToast('info',this.labels.TOAST_NO_CHANGES_MESSAGE,toastHeader,'dismissible');    
                }
                else if(!toastHeader)
                { 
                    const btn = this.template.querySelector( ".hiddenButton" );
                    btn.click();
                }
        }
    
        submitMethod(event)
        {
            event.preventDefault();
            this.caseRecord = {};
            console.log('this.disableSubmit: ' + this.disableSubmit);
            if(!this.disableSubmit)
            {
                this.caseRecord.Jarvis_Also_Notify__c = this.template.querySelector(".Jarvis_Also_Notify__c").value;
            }
            this.caseRecord.Id = this.recordId;
            console.log("this.caseRecord: " + this.caseRecord);
            this.loadSpinner = true;      
            let accountid = this.template.querySelector(".Account").value;
            
            console.log('accountId' + accountid);
            let alsoNotify = this.caseRecord.Jarvis_Also_Notify__c;            
            if(alsoNotify && alsoNotify !== this.existingAlsoNotify)
            {
                alsoNotifyCheck({
                    "accountIdString" : accountid,
                    "emailString":this.caseRecord.Jarvis_Also_Notify__c,
                    'updateRecord' : JSON.stringify(this.caseRecord)
                }).then(result => {
                    if(result === "Success")
                    {
                        console.log('result' + result);
                        this.callUpdate();
                    }
                    else if(result.startsWith("500"))
                    {
                        let toastMessage = this.labels.TOAST_SUCCESS_MESSAGE;
                        this.showToast('success',toastMessage,this.labels.TOAST_SUCCESS,'dismissible');
                        this.closeConfirmModal();    
                        this.loadSpinner = false;
                    }
                    else
                    {
                        this.showConfirm();                
                        this.loadSpinner = false;               
                        this.warningMessage=this.labels.MODAL_ERROR1 + result;
                        this.warningMessage+=this.labels.MODAL_ERROR2;
                        
                    }
                    
                })
                .catch(error => {
                    this.loadSpinner = false;               
                    //this.showToast('error',JSON.stringify(error),'Error!','dismissible');
                    console.log('The error: ' + error +  JSON.stringify(error)) ;
                });        
    
            }
            else
            {
                this.callUpdate();   
            }

        }
    
        callUpdate()
        {
            this.loadSpinner = true;               
            updateCaseRecord({'updateRecord' : JSON.stringify(this.caseRecord)})
            .then(result => {
                this.loadSpinner = false;              
                console.log('result: ' + result);
                if(result.startsWith('500'))
                {
                    let toastMessage = this.labels.TOAST_SUCCESS_MESSAGE;
                    this.showToast('success',toastMessage,this.labels.TOAST_SUCCESS,'dismissible');
                    this.closeConfirmModal();
                }
                else
                {
                    this.showToast('error',result,this.labels.TOAST_ERROR,'dismissible');
                }
            })
            .catch(error => {
                this.loadSpinner = false;
                //this.showToast('error',JSON.stringify(error),'Error!','dismissible');
                console.log('The error: ' + error +  JSON.stringify(error)) ;
            });        

        }
        handleSucess()
        {
            console.log('success');
        }
    
        handleError(event)
        {
            this.disableSubmit = true;
            this.loadSpinner = false;               
            let errorVar = event.detail.output.fieldErrors? event.detail.output.fieldErrors : event.detail.error;
    
            //this.showToast('error',errorVar,'Error!','dismissible');
            console.log('errorVar: ', errorVar);     
        }
    
    
        // showToast(variant,message,title,mode)
        // {
        //     const event = new ShowToastEvent({
        //         "title": title,
        //         "message": message,
        //         "mode" : mode,
        //         "variant" : variant
        //     });
        //     this.dispatchEvent(event);        
        // }

        closeConfirmModal()
        {
            this.recordEditForm = '';
            this.showConfirmClass = 'hidden';
            this.recordEditFormButton = 'slds-button slds-button_brand';
            this.showConfirmClassbuttonCancel = 'slds-button slds-button_neutral hidden';
            this.showConfirmClassbuttonConfirm = 'slds-button slds-button_brand hidden';
        }

        showConfirm()
        {
            this.recordEditForm = 'hidden';
            this.showConfirmClass = '';
            this.recordEditFormButton = 'slds-button slds-button_brand hidden';
            this.showConfirmClassbuttonCancel = 'slds-button slds-button_neutral';
            this.showConfirmClassbuttonConfirm = 'slds-button slds-button_brand';
               
        }
}