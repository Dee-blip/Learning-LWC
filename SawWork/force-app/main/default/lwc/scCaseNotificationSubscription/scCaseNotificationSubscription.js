/** Created Date		: 30-Dec-2021
 * Author		: 	jrathod
 * JIRA         :   ESESP-5526
 * Description	:   This component creates SC_CNSOnCase__c records. This is currently displayed on SOCC Case Detail Page.

 Date                    Developer             		JIRA #                      Description
 ------------------------------------------------------------------------------------------------------------------
 30 Dec 2021    		Author				 	    ESESP-5526				  Initial Development
 */

import {LightningElement, api} from 'lwc';
import CNS_ON_CASE from "@salesforce/schema/SC_CNSOnCase__c";
import USER_FIELD from "@salesforce/schema/SC_CNSOnCase__c.User__c";
import CASE_FIELD from "@salesforce/schema/SC_CNSOnCase__c.Case__c";
import LISTEN_TO_EMAIL_COMMS_FIELD from "@salesforce/schema/SC_CNSOnCase__c.ListenEmailComms__c";
import {CloseActionScreenEvent} from "lightning/actions";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import {deleteRecord} from "lightning/uiRecordApi";
import getCaseNotificationSubsOnACase from "@salesforce/apex/SC_CNSUtility.getCaseNotificationSubsOnACase";
export default class ScCaseNotificationSubscription extends LightningElement {

    @api
    recordId;
    userField = USER_FIELD;
    caseField = CASE_FIELD;
    listenToEmailCommsField = LISTEN_TO_EMAIL_COMMS_FIELD;
    activeSections = ['userList'];
    listenToEmailCommsValue = true;
    objectApiName;

    connectedCallback() {
        this.objectApiName = CNS_ON_CASE.objectApiName
        this.fetchExistingSubscribers();
    }

    handleSuccess(){
        this.dispatchEvent(new ShowToastEvent({
            title: "Subscribed!",
            variant: "success"
        }));
        this.hideAddNewSubscriberCard();
        this.fetchExistingSubscribers();
        this.resetFields();
    }

    handleError(e){
        console.error(e);
    }

    subscribers = [];
    showSpinner = false;

    async fetchExistingSubscribers(){
        try{
            this.showSpinner = true;
            console.log(JSON.stringify(this.recordId));
            let subscribers = await getCaseNotificationSubsOnACase({
                caseId: this.recordId
            });
            console.log(subscribers);
            this.subscribers = subscribers;
        }catch (e) {
            console.error(e);
            this.dispatchEvent(new ShowToastEvent({
                title: "Error!",
                message: JSON.stringify(e && e.body)
            }))
        }finally {
            this.showSpinner = false;
        }
    }

    closeModal(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    resetFields(){
        let userField = this.template.querySelector('lightning-input-field[data-id="userField"]');
        if (userField) userField.reset();
    }

    async removeSubscriber(e){
        let {name:userName,id:cnsRecordId} = e.target.dataset;
        console.log(cnsRecordId);
        let confirmed = window.confirm(`Sure to unsubscribe ${userName}?`); // eslint-disable-line no-alert
        if (cnsRecordId && confirmed){
            try{
                this.showSpinner = true;
                await deleteRecord(cnsRecordId);
                await this.fetchExistingSubscribers();
                this.dispatchEvent(new ShowToastEvent({
                    title: "Success",
                    message: userName + " unsubscribed!"
                }));
            }catch (e1) {
                console.error(e1);
                this.dispatchEvent(new ShowToastEvent({
                    title: "Error!",
                    message: JSON.stringify(e && e.body)
                }));
            }finally {
                this.showSpinner = false;
            }
        }
    }

    showNewSubCard = false;

    hideAddNewSubscriberCard(){
        this.showNewSubCard = false;
    }

    showNewSubscriberCard(){
        this.showNewSubCard = !this.showNewSubCard;
    }

    get subscriberListLabel(){
        return Array.isArray(this.subscribers) ? `Subscribed Users (${this.subscribers.length})` : 'Subscribed Users';
    }

    get subscribersExist(){
        return Array.isArray(this.subscribers) && this.subscribers.length > 0;
    }

    get addNewSubLabel() {
        return this.showNewSubCard ? '[-] Add New Subscriber' : '[+] Add New Subscriber';
    }

    get subscribersTransformed(){
        return Array.isArray(this.subscribers) ? this.subscribers.map(sub => ({
            ...sub,
            helpText: `User Email: ${sub.email}\nSubscribed on: ${sub.createdDate} \nSubscription added by: ${sub.createdBy}`
        })): [];
    }


}