import { LightningElement,api } from 'lwc';
// import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import alsoNotifyCheck from '@salesforce/apex/SC_Jarvis_Create_Case_Controller.alsoNotifyCheck';
import updateCaseRecord from '@salesforce/apex/SC_Jarvis_Create_Case_Controller.updateCaseRecord';

import {LABELS}  from "./scJarvisUpdateCaseLabel"
export default class ScJarvisUpdateCase extends LightningElement 
{
    
    
        @api caserecordid;
    
        labels = LABELS;
        loadSpinner = false;
        disableSubmit = true;
        caseRecord;
        noChange = true;
        validEmailMessage;
        warningMessage='';
        alternateEmailMessage='';

        recordEditForm = '';
        showConfirmClass = 'hidden';
        recordEditFormHeader = 'slds-text-heading_medium slds-hyphenate';
        showConfirmClassHeader = 'slds-text-heading_medium slds-hyphenate hidden';
        recordEditFormButtonCancel= 'slds-button slds-button_neutral';
        recordEditFormButtonConfirm = 'slds-button slds-button_brand';
        showConfirmClassbuttonCancel = 'slds-button slds-button_neutral hidden';
        showConfirmClassbuttonConfirm = 'slds-button slds-button_brand hidden';

        get modalClass ()
        {
            return !this.showConfirmClass? "slds-modal slds-modal_small slds-fade-in-open" : "slds-modal slds-modal_medium slds-fade-in-open";
        }
        get showValidation()
        {
            return this.validEmailMessage? true: false;
        }
        get showAlternateEmailValidation()
        {
            return this.alternateEmailMessage? true: false;
        }
        checkIfDuplicateExists(arrayToCheck){
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
            if(event.target.dataset.field === "Jarvis_Also_Notify__c")
            {  
                event.target.classList.remove('slds-has-error');
                this.validEmailMessage = "";
            }      
            else if(event.target.dataset.field === "Alternate_Contact_Email__c")
            {
                event.target.classList.remove('slds-has-error');
                this.alternateEmailMessage = "";

            }
    
        }
        validateForm()
        {                
                this.disableSubmit = false;
                let toastHeader;
                this.validEmailMessage = "";
                this.alternateEmailMessage = "";
                const re = /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
                //console.log('here!!! in Submit:'+this.disableSubmit);
                let alternateEmail = this.template.querySelector(".Alternate_Contact_Email__c");
                
                if(alternateEmail.value && !re.test(String(alternateEmail.value).toLowerCase()))
                {
                    toastHeader = this.labels.TOAST_INVALID;
                    this.alternateEmailMessage = this.labels.TOAST_INVALID_MESSAGE;   
                    alternateEmail.classList.add('slds-has-error');       
                    this.showToast('error',this.alternateEmailMessage,toastHeader,'dismissible');    
                }

                let alsoNotify = this.template.querySelector(".Jarvis_Also_Notify__c");
                let validEmail = true;
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
                        //console.log('validEmail:' + validEmail);
            
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
            
            //console.log('this.disableSubmit: ' + this.disableSubmit);
            if(!this.disableSubmit)
            {
                let key;
                for (key in event.detail.fields)
                {
                    if(event.detail.fields[key])
                    {
                        this.caseRecord[key] = event.detail.fields[key];
                    }
                    else
                    {
                        this.caseRecord[key] = event.detail.fields[key];
                    }
                }   
       
            }            
            this.caseRecord.Id = this.caserecordid;
            //console.log("this.caseRecord: " + JSON.stringify(this.caseRecord));
            this.loadSpinner = true;      
            let accountid = this.template.querySelector(".Account").value;
            
            //console.log('accountId' + accountid);
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
                        this.callUpdate();
                    }
                    else if(result.startsWith("500"))
                    {
                        let toastMessage = this.labels.TOAST_SUCCESS_MESSAGE;
                        this.showToast('success',toastMessage,this.labels.TOAST_SUCCESS,'dismissible');
                        //this.navigateToRecord(); 
                        window.location.reload();
    
                    }
                    else
                    {
                        //console.log('WANRMG' + result);
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
                              
                //console.log('result: ' + result);
                if(result.startsWith('500'))
                {
                    let toastMessage = this.labels.TOAST_SUCCESS_MESSAGE;
                    this.showToast('success',toastMessage,this.labels.TOAST_SUCCESS,'dismissible');
                    this.closeModal();
                    window.location.reload();
        
                }
                else
                {
                    this.loadSpinner = false;
                    this.currentStep = 'createCase';
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
    
        closeModal()
        {        
            const closeEvent = new CustomEvent('closecreateevent', {
                detail: {
                    close: true
                }
            });
            this.dispatchEvent(closeEvent);        
                
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
            this.recordEditFormButtonCancel= 'slds-button slds-button_neutral';
            this.recordEditFormButtonConfirm = 'slds-button slds-button_brand';
            this.showConfirmClassbuttonCancel = 'slds-button slds-button_neutral hidden';
            this.showConfirmClassbuttonConfirm = 'slds-button slds-button_brand hidden';
            this.recordEditFormHeader = 'slds-text-heading_medium slds-hyphenate';
            this.showConfirmClassHeader = 'slds-text-heading_medium slds-hyphenate hidden';
    
        }

        showConfirm()
        {
            this.recordEditForm = 'hidden';
            this.showConfirmClass = '';
            this.recordEditFormButtonCancel= 'slds-button slds-button_neutral hidden';
            this.recordEditFormButtonConfirm = 'slds-button slds-button_brand hidden';
            this.showConfirmClassbuttonCancel = 'slds-button slds-button_neutral';
            this.showConfirmClassbuttonConfirm = 'slds-button slds-button_brand';
            this.recordEditFormHeader = 'slds-text-heading_medium slds-hyphenate hidden';
            this.showConfirmClassHeader = 'slds-text-heading_medium slds-hyphenate';
    
               
        }
        
}