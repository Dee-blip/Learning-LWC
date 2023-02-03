import {
    LightningElement,
    wire
} from 'lwc';

import fetchEmailDetails from '@salesforce/apex/HD_History_reply_ButtonCtrl.classObject'; //to fetch email details
import submitEmailResponse from '@salesforce/apex/HD_Email_Composer_DockedCtrl.sendEmailmethod'; //to submit the email response

import {
    ShowToastEvent
} from 'lightning/platformShowToastEvent';
 
import {
    subscribe,
    unsubscribe,
    APPLICATION_SCOPE,
    MessageContext
} from 'lightning/messageService';

import hdRecordPageCommunications from '@salesforce/messageChannel/hdRecordPageCommunications__c';

export default class HdEmailComposerDocked extends LightningElement {
    @wire(MessageContext)
    messageContext;
    quickAction;
    minimizeClass = 'slds-docked-composer slds-grid slds-grid_vertical slds-is-open modal-custom-design'; // this class will be used to toggle between minmize/expand actions.
    isEmailComposerOpen = false; // to hide/show the component
    emailComposerMax = false; // to display modal view on click of Maximize button
    isMinimize = false; // this var will be used to toggle between minmize/expand actions
    classForModalViewSection = ''; // classForModalViewSection, classForModalViewDiv1, classForModalViewDiv2 classes will be used to show modal view
    classForModalViewDiv1 = '';
    classForModalViewDiv2 = 'slds-docked_container';
    modalBody = 'slds-docked-composer__body slds-docked-composer__body_custom';
    subject = ''; //stores email subject
    emailBody = '';
    toEmailList = []; //list of 'To email' Recipients.
    ccEmailList = []; //list of 'Cc email' Recipients.
    fromEmail;
    emailData; //email data conatining the from, to, subject and body of the email.
    errorMsg;
    minimizeActionBtnTitle = 'Minimize';


    unsubscribeToMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    handleChange(event) {
        this.myVal = event.target.value;
    }

    // Handler for message received by component
    handleMessage(message) {
        this.quickAction = message.quickAction;
        this.toEmailList = [];  
            this.isEmailComposerOpen = true;
            fetchEmailDetails({
                    actionId: message.tempHistoryId
                }).then(result => {
                    this.emailData = result;
                    this.toEmailList.push(result.action_History.BMCServiceDesk__Client_User__r);
                    this.template.querySelector('c-hd-email-lookup').setToEmailFromParent(result.action_History.BMCServiceDesk__Client_User__r);
                    this.fromEmail = result.ORG_WIDE_EMAIL;
                    this.subject = "RE:" + result.action_History.BMCServiceDesk__description__c;
                    this.emailBody = result.action_History.BMCServiceDesk__RichTextNote__c
                })
                .catch(error => {
                    this.error = error;
                    this.emailData = undefined;
                });   
    }

    connectedCallback() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                hdRecordPageCommunications,
                (message) => this.handleMessage(message), {
                    scope: APPLICATION_SCOPE
                }
            );
        }
    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

    //closes the email docker
    closeEmail() {
        this.isEmailComposerOpen = false;
        this.emailComposerMax = false;
        this.toEmailList = [];
        this.ccEmailList = [];
        this.subject = '';
        this.emailBody = '';
        this.errorMsg = '';
        this.classForModalViewSection = '';
        this.classForModalViewDiv1 = '';
        this.classForModalViewDiv2 = 'slds-docked_container';
        this.modalBody = 'slds-docked-composer__body slds-docked-composer__body_custom';
        this.minimizeClass = 'slds-docked-composer slds-grid slds-grid_vertical slds-is-open modal-custom-design';
    }

    //toggles between modal/docker the email docker
    maximizeAction() {
        this.emailComposerMax = !this.emailComposerMax; //toggles between modal/docker the email docker

        if(this.emailComposerMax){
            /* modal view classes */
            this.classForModalViewSection = 'slds-modal slds-fade-in-open slds-modal_medium slds-docked-composer-modal';
            this.classForModalViewDiv1 = 'slds-modal__container';
            this.classForModalViewDiv2 = 'slds-modal__content';
            this.modalBody = 'slds-docked-composer__body slds-docked-composer__body_custom modal-body';
            this.minimizeClass = 'slds-docked-composer slds-grid slds-grid_vertical slds-is-open';
            this.isMinimize = false;
            this.minimizeActionBtnTitle = 'Minimize';
        }else{/* docker view classes */
            this.classForModalViewSection = '';
            this.classForModalViewDiv1 = '';
            this.classForModalViewDiv2 = 'slds-docked_container';
            this.modalBody = 'slds-docked-composer__body slds-docked-composer__body_custom';
            this.minimizeClass = 'slds-docked-composer slds-grid slds-grid_vertical slds-is-open modal-custom-design';
            this.minimizeActionBtnTitle = 'Minimize';
        }
    }

    //toggles between minimize/expand the email docker
    minimizeAction() {
        this.isMinimize = !this.isMinimize; //set to true if false, false if true.

        if(this.isMinimize){
            this.minimizeClass = 'slds-docked-composer slds-grid slds-grid_vertical slds-is-closed';
            this.classForModalViewSection = '';
            this.classForModalViewDiv1 = '';
            this.classForModalViewDiv2 = 'slds-docked_container';
            this.modalBody = '';
            this.emailComposerMax = false;
            this.minimizeActionBtnTitle = 'Restore';
        }else{
            this.minimizeClass = 'slds-docked-composer slds-grid slds-grid_vertical slds-is-open modal-custom-design';
            this.classForModalViewSection = '';
            this.classForModalViewDiv1 = '';
            this.classForModalViewDiv2 = 'slds-docked_container';
            this.modalBody = 'slds-docked-composer__body slds-docked-composer__body_custom';
            this.emailComposerMax = false;
            this.minimizeActionBtnTitle = 'Minimize';
        }
    }

    validateBeforeSubmit() {
        let toList = this.toEmailList.map(a => a.Email); // 'To Email' array
        let ccList = this.ccEmailList.map(a => a.Email); // 'Cc Email' array

        if ((this.toEmailList).length === 0 && (this.ccEmailList).length === 0) {
            this.errorMsg = 'Add a recipient to send an email.';
        } else if (((this.toEmailList).length !== 0 && this.getInvalidEmails(toList).length !== 0) /* throw error if emails are invalid */
            || 
        ((this.ccEmailList).length !== 0 && this.getInvalidEmails(ccList).length !== 0)) {
            this.errorMsg = 'One or more email addresses are not valid.';
        } else {
            this.errorMsg = '';
            this.submitEmail(toList,ccList,this.subject,this.emailBody);         
        }

    }

    submitEmail(toList,ccList,subject,emailBody){        
        submitEmailResponse({
            toAddresses: toList,
            ccAddresses: ccList,
            subject: subject,
            body: emailBody
        })
        .then(() => {
            this.showNotification('', 'Email sent.', 'success');
            this.closeEmail();
        }).catch(error => {
            this.error = error;
            this.errorMsg = this.error;
        })
    }

    //selected 'To Email' list from child component 'hdCustomLookup'
    handleEmailSelection(event){
        this.errorMsg = '';
        if(event.detail.emailType === 'to'){
            this.toEmailList = [];
            this.toEmailList = event.detail.emailList;
        }else if(event.detail.emailType === 'cc'){
            this.ccEmailList = [];
            this.ccEmailList = event.detail.emailList;
        }
    }

    handleOnChangeOfEmailData(event) {
        if (event.currentTarget.dataset.source === 'emailBody') {
            this.emailBody = event.target.value;
        }else if (event.currentTarget.dataset.source === 'subject') {
            this.subject = event.target.value;
        }
    }

    showNotification(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    handleError(event){
        this.errorMsg = event.detail.errorMsg;
        setTimeout(() => {
            this.errorMsg = '';
        }, 4000);
    }

    getInvalidEmails(emailList) {
        let regex = new RegExp('[a-z0-9]+@[a-z]+.[a-z]{2,3}');
        let invalidEmailArray = [];
        emailList.forEach((address) => {
            if (!regex.test(address)) {
                invalidEmailArray.push(address);
            }

        });
        return invalidEmailArray;
    }

}