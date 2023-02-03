import {
    LightningElement,
    track,
    api
} from 'lwc';
import {
    ShowToastEvent
} from 'lightning/platformShowToastEvent';
import getInitDetails from '@salesforce/apex/SC_PSAutomationControllerForSC.getExternalMailInitDetail';
import validate from '@salesforce/apex/SC_PSAutomationControllerForSC.validateUser';
import getDL from '@salesforce/apex/SC_PSAutomationController.getDLList';
import sendEmailSC from '@salesforce/apex/SC_PSAutomationControllerForSC.sendEmailControllerForSC';
//import { getRecord,getFieldValue } from 'lightning/uiRecordApi';
//import ACCOUNT_FIELD from '@salesforce/schema/PS_Customer_Mailers__c.Account__c';
//const fields = [ACCOUNT_FIELD];

export default class ScPSAutomationforSecurityConsultant extends LightningElement {
    @api defaultRecipients = [];
    @api defaultMap = new Map();
    
    @track showToField = false;

    @track body;
    @track masterMailer;
    @track showConfirmPopUp = false;
    @track subject;
    @track instructions;
    @api recordId;
    @track dlList = [];
    @track contacts = [];
    @track attachListFromParent = [];
    @track attachNames = [];
    @track toAddress = [];

    @track isMailSent;
    @track showError;

    @track showSpinner = false;
    //contactsMap={};

    // @wire(getRecord, { recordId: '$recordId', fields })
    //customerMailerRec;

    handleCcAddressChange(event) {
        this.toAddress = event.detail.selectedValues;
    }

    handleManageRecipients() {
        window.open('/lightning/o/PS_Automation_Admin_DL__c/list?filterName=All', '_blank');
    }

    connectedCallback() {
        var i = 0;
        var result;
        this.showSpinner = true;
        
        // alert(this.recordId);
        validate({
                recId: this.recordId
            })
            .then(resultValidate => {
                
                if (resultValidate === true) {
                    this.showError = false;
                    getInitDetails({
                            recId: this.recordId
                        })
                        .then(resultRec => {
                            result= JSON.parse(resultRec);
                            //  alert(JSON.stringify(result));
                            this.masterMailer = result.masterMailerRec;
                            if (result.masterMailerRec.Email_forwarded_to_Contacts_On__c === null || result.masterMailerRec.Email_forwarded_to_Contacts_On__c === '' || result.masterMailerRec.Email_forwarded_to_Contacts_On__c === undefined) {
                                this.isMailSent = false;
                            } else {
                                this.isMailSent = true;
                            }
                            this.body = result.masterMailerRec.Parent_PS_Customer_Mailer__r.Content__c;
                            this.subject = result.masterMailerRec.Parent_PS_Customer_Mailer__r.Subject__c;
                            this.instructions = result.masterMailerRec.Parent_PS_Customer_Mailer__r.Instructions__c;




                        }).catch(error => {
                            this.showSpinner = false;

                            console.log(JSON.stringify(error));

                        });



                    getDL({
                            type: 'External',
                            recId: this.recordId
                        })
                        .then(resultDL => {
                            for (i = 0; i < resultDL.length; i++) {
                                this.dlList.push(resultDL[i]);
                                // alert(JSON.stringify(this.dlList));
                            }
                            this.showSpinner = false;
                            // this.showOtherRecipients = true;
                        }).catch((error) => {
                            this.showSpinner = false;
                            console.error("Error in handleApplicableAccountsShow:", error);
                        });


                } else {
                    this.showError = true;
                    this.showSpinner = false;
                }
            }).catch(error => {
                this.showSpinner = false;

                console.log(JSON.stringify(error));

            });




    }


    handleFileRemove(event) {
        // alert(event.target.name);
        var i = 0;
        for (i = 0; i < this.attachNames.length; i++) {
            if (this.attachNames[i] === event.target.name) {
                this.attachNames.splice(i, 1);
                break;
            }
        }
        for (i = 0; i < this.attachListFromParent.length; i++) {
            if (this.attachListFromParent[i].label === event.target.name) {
                this.attachListFromParent.splice(i, 1);
                break;
            }
        }
    }

    handleBodyChange(event) {
        this.body = event.target.value;
    }


    handleConfirm() {
        this.showConfirmPopUp = true;
    }

    handleSend() {
        this.showSpinner = true;
        this.showConfirmPopUp = false;
        // alert(JSON.stringify(this.contacts));

        sendEmailSC({
                subject: this.subject,
                body: this.body,
              //  toAddresses: JSON.stringify(this.dlList),
                whatId: this.recordId,
                attachNames: this.attachNames
            })

            .then(() => {
                this.showToast('Mails have been sent to all recipients', 'success', 'dismissable');
                this.showSpinner = false;
                window.open('/' + this.recordId, '_self');



            }).catch(error => {
                this.showSpinner = false;
                console.log(JSON.stringify(error));

            });
    }

    handleCancel() {
        this.showConfirmPopUp = false;
    }

    handleSubjectChange(event) {
        this.subject = event.detail.value;
    }

    // Handling toasts
    showToast(message, variant, mode) {
        // alert('here');
        const evt = new ShowToastEvent({

            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }


}