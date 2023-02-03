/* eslint-disable no-eval */
import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import APPROVER1_FIELD from '@salesforce/schema/BMCServiceDesk__Incident__c.Approver__c';
import APPROVER2_FIELD from '@salesforce/schema/BMCServiceDesk__Incident__c.Approver_II__c';
import APPROVAL_STATUS_FIELD from '@salesforce/schema/BMCServiceDesk__Incident__c.HD_Approval_Status__c';
import submitForApproval from '@salesforce/apex/HD_IncidentDetailController.submitForApproval';
import recallForApproval from '@salesforce/apex/HD_IncidentDetailController.recallForApproval';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import addActionAudit from '@salesforce/apex/HD_ActionAudit.addActionAudit';
import logErrorRecord from '@salesforce/apex/HD_UX_Exception_LoggerCls.logErrorRecord';


export default class Hd_Approval_Actions extends LightningElement {
    @api recordId;
    isReadOnly = true;
    isLoading;
    fields = [APPROVER1_FIELD, APPROVER2_FIELD];
    @wire(getRecord, { recordId: '$recordId', fields: [APPROVAL_STATUS_FIELD] })
    incident;


    handleCheckboxChange(event) {
        // this.isLoading = true;
        this.isReadOnly = !event.target.checked;
    }

    onSubmitClicked(event) {
        this.isLoading = true;
        let editForm = this.template.querySelector('lightning-record-edit-form');
        if (editForm) {
            editForm.submit(event.detail.fields);
        }
        else {
            this.handleSubmission();
        }
    }

    onRecallClicked() {
        this.isLoading = true;
        recallForApproval({ incidentId: this.recordId, comment: '' })
            .then(() => {
                this.showToast("Approval recalled successfully", "Success", "success");
                eval('$A.get("e.force:refreshView").fire();');
                this.setActionAudit('Approval recalled successfully', 'SUCCESS');
                this.isLoading = false;
            })
            .catch(error => {
                this.showToast("Error while recalling approval", "Recalling error", "error");
                this.setActionAudit('Error while recalling approval', 'ERROR');
                this.isLoading = false;
                this.logError(JSON.stringify(error));
            });
    }

    onFormLoaded() {
        // this.isLoading = false;
    }

    handleSuccess() {
        this.handleSubmission();
    }

    handleSubmission() {
        submitForApproval({ incidentId: this.recordId, comment: 'Submitted' })
            .then(result => {
                let ticketDetails = "Action: Submit Approval | Incident : " + this.recordId;
                if (result.search('ALREADY_IN_PROCESS') >= 0) {
                    this.setActionAudit('Ticket already submitted for approval', 'ERROR');
                    this.logError(ticketDetails + " -->Ticket already submitted");
                    this.showToast("Ticket already submitted for approval", "Warning", "warning");
                }
                else if (result.search("Process failed") >= 0) {
                    this.setActionAudit('No Applicable Approval process found', 'ERROR');
                    this.logError(ticketDetails + " -->No Approval Process Found");
                    this.showToast("No Applicable Approval process found", "Error", "error");
                }
                else {
                    this.isReadOnly = true;
                    let toggleButton = this.template.querySelector('[data-id="toggleButton"]');
                    if (toggleButton) {
                        toggleButton.checked = false;
                    }
                    this.showToast("Ticket submitted for approval successfully", "Success", "success");
                    eval('$A.get("e.force:refreshView").fire();');
                    this.setActionAudit('Ticket submitted for approval', 'SUCCESS');
                }
                this.isLoading = false;
            })
            .catch(error => {
                this.isLoading = false;
                this.showToast("Error while submitting for approval", "Submission error", "error");
                this.setActionAudit('Error on approval process submission', 'ERROR');
                this.logError(JSON.stringify(error));
            });
    }

    setActionAudit(actionName, state) {
        addActionAudit({
            recordId: this.recordId,
            actionName: actionName,
            startTime: null,
            endTime: null,
            idleTime: null,
            status: state
        });
    }

    logError(error) {
        logErrorRecord({
            ErrorMsg: error,
            Stacktrace: null,
            IncidentId: this.recordId
        });
    }

    showToast(message, title, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    get isSubmitDisabled() {
        return getFieldValue(this.incident.data, APPROVAL_STATUS_FIELD) === 'Approval Pending';
    }

    get isRecallDisabled() {
        return getFieldValue(this.incident.data, APPROVAL_STATUS_FIELD) !== 'Approval Pending';
    }

    get helpText() {
        let helptext;
        let isPendingApproval = getFieldValue(this.incident.data, APPROVAL_STATUS_FIELD) === 'Approval Pending';
        if (this.isReadOnly) {
            if (!isPendingApproval) {
                helptext = 'Either click "Submit for Approval" or Click on override default approval and enter approvers if you want to override the default approval process and send it to approval for the entered approvers';
            }
            else {
                helptext = 'Click on "Recall Approval" to be able to override the default approval as the record is locked for editing';
            }
        }
        else if (!this.isReadOnly) {
            if (!isPendingApproval) {
                helptext = 'Click on "Subit for Approval" to send it to approval to the default process or provide approvers below to override the default process';
            }
            else {
                helptext = 'Click on "Recall Approval" to be able to override the default approval as the record is locked for editing';
            }
        }
        return helptext;
    }
}