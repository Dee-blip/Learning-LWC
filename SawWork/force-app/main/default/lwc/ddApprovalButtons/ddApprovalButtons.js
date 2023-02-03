import { LightningElement, api, track, wire } from 'lwc';
import getEntitledActions from "@salesforce/apex/SC_DD_ApprovalCompCont.getEntitledActions";
import performAction from "@salesforce/apex/SC_DD_ApprovalCompCont.performAction";
import { refreshApex } from '@salesforce/apex';

import { getRecord } from 'lightning/uiRecordApi';
import { serverCallError } from 'c/scUtil';

const DEAL_FIELDS = ['SC_DD_Deal__c.Id','SC_DD_Deal__c.EPS_Zone__c', 
    'SC_DD_Deal__c.ESR_Zone__c',  'SC_DD_Deal__c.Deal_Zone__c', 'SC_DD_Deal__c.GSS_Product__c',
    'SC_DD_Deal__c.Account__c', 'SC_DD_Deal__c.Approval_Stage__c', 'SC_DD_Deal__c.GSS_Product_Name__c' ];
 
const ERR_MSGS = {
        ERR_PERMS_FETCH : {
            title: 'Error fetching permissions',
            variant: 'error'
        },
        ERR_DEAL_FETCH: {
            title: 'Error fetching deal',
            variant: 'error'
        },
        ERR_PERFORM_ACTION: {
            title: 'Error saving deal',
            variant: 'error'
        }
    };
export default class approvalButtons extends LightningElement {
    @api approvalLogicClassName;
    
    @api cssClass;

    @api recordId;
    @api record;
    @api comments;

    @track displayApproveButton = false;
    @track displayRejectButton = false;
    @track displayEscalateButton = false;
    @track displaySendToDDA = false;

    @track getRecResult;

    get commentsLabel() {
        return this.action + ' Comments';
    }


    @wire(getRecord, { recordId: '$recordId', fields: DEAL_FIELDS })  //layoutTypes: "Full" })    
    getRecord(result ) {
        this.getRecResult = result;
        let { data, error } = result;
        let dataRec = {};

        if (error) {
            serverCallError(this, error, ERR_MSGS.ERR_DEAL_FETCH);
        }
        if (data) {

            for(let [fName, fValue] of Object.entries(data.fields)) {
                dataRec[fName] = fValue.value;
            }
            dataRec.sobjectType = data.apiName;
            
            this.record = dataRec;
        }
    }


    approverType;    
    @wire(getEntitledActions, {deal: '$record' })
    apprPremissions({ data, error }) {
        this.displayApproveButton = false;
        this.displayRejectButton = false;
        this.displayEscalateButton = false;
        this.displaySendToDDA = false;
        if (error) {                      
            if(JSON.stringify(error).includes('Error: newValue cannot be undefined.')) {
                return;
            }
            serverCallError(this, error,ERR_MSGS.ERR_PERMS_FETCH);
        }
        if (data && data.approverType && data.entitlesdActions.length > 0) {
            this.approverType = data.approverType;
            this.displayApproveButton = data.entitlesdActions.includes('Approve');
            this.displayRejectButton = data.entitlesdActions.includes('Reject');
            this.displayEscalateButton = data.entitlesdActions.includes('Escalate');
            this.displaySendToDDA = data.entitlesdActions.includes('Send To DDA');
        }
    }


    //String approvalClass, String record, String comments


    get hasAccess() {
        return this.displayApproveButton || this.displayRejectButton || this.displayEscalateButton;
    }


    toggleComments(ev) {
        let custModal = this.template.querySelector('.comments');
        custModal.classList.remove('slds-hide');
        custModal.toggle();
    }

    @track action;


    handleAction(ev) {

        this.action = ev.target.getAttribute('data-id');
        this.toggleComments();
    }

    handleCancel() {
        this.toggleComments();
    }
    handleDone() {
        this.comments = this.template.querySelector("[data-id='comments']").value;

        let unHandledEvent = this.dispatchEvent(new CustomEvent('action', { detail: {action: this.action, approverType: this.approverType, comments: this.comments}, cancelable: true }));

        this.toggleComments();
        if (!unHandledEvent) {
            return;
        }

        performAction({
            deal: this.record, actionName: this.action, comments: this.comments
        }).then((el) => {
            refreshApex(this.getRecResult);
        }).catch((error) => {
            serverCallError(this, error, ERR_MSGS.ERR_PERFORM_ACTION);
        });

    }
}