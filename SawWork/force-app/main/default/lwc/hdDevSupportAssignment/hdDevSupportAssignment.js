import { LightningElement,api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import STATUS_FIELD from '@salesforce/schema/BMCServiceDesk__Incident__c.BMCServiceDesk__Status_ID__c';
import SUPPORT_TYPE_FIELD from '@salesforce/schema/BMCServiceDesk__Incident__c.Support_Type__c';
import INCIDENT_GROUP_FIELD from '@salesforce/schema/BMCServiceDesk__Incident__c.HD_Incident_Group__c';
import getUser from '@salesforce/apex/HD_DevSupportAssignmentController.getUser';
import shouldSendEmail from '@salesforce/apex/HD_DevSupportAssignmentController.shouldSendEmail';

const INCIDENT_FIELDS = [STATUS_FIELD, SUPPORT_TYPE_FIELD, INCIDENT_GROUP_FIELD];
export default class HdDevSupportAssignment extends LightningElement {
    @api recordId;
    devResourceId;
    devResource;
    @track state = {
        displaySpinner : true,
        isEdit : false,
        isDevResourceVisible : false,
        supportLevel :null,
        isJIRAFieldVisible: false,
        hasAccess : true
    };

    @wire(getRecord, { recordId: '$recordId', INCIDENT_FIELDS })
    incident;

    @wire(getUser, { recordId: '$devResourceId'})
    getUserDataCallback({error, data}) {
        if(data) {
            this.devResource = data;
        }
        this.state.displaySpinner = false;
    }

    @wire(shouldSendEmail, { recordId: '$recordId'})
    isEmailRequired;

    get isEditAllowed() {
        return getFieldValue(this.incident.data, STATUS_FIELD) !== 'CLOSED' && getFieldValue(this.incident.data, STATUS_FIELD) !== 'RESOLVED' && this.state.hasAccess;
    }

    get isRecordEdit() {
        return getFieldValue(this.incident.data, STATUS_FIELD) !== 'CLOSED' && this.state.isEdit;
    }

    handleSubmit(event){
        event.preventDefault(); 
        this.state.displaySpinner = true;
        let jiraPattern = /^[A-Za-z]+-[0-9]+$/i;
        const incidentFields = event.detail.fields;
        incidentFields.Dev_Resource__c = (!incidentFields.Support_Type__c || incidentFields.Support_Type__c === 'L1') ? null : incidentFields.Dev_Resource__c;
        incidentFields.JIRA_Link__c = (!incidentFields.Support_Type__c) ? null : incidentFields.JIRA_Link__c;
        if(incidentFields.Dev_Resource__c) {
            if(this.devResource && this.devResource.hasOwnProperty('Email')) {
                incidentFields.Cc__c = this.devResource.Email;
            }
        }
        else {
            incidentFields.Cc__c = null;
        }
        incidentFields.JIRA_Link__c = jiraPattern.test(incidentFields.JIRA_Link__c) ? 'https://gsd.akamai.com/jira/browse/'+incidentFields.JIRA_Link__c :  incidentFields.JIRA_Link__c;
        this.template.querySelector('lightning-record-edit-form').submit(incidentFields);
    }

    handleSucess(){
        this.state.displaySpinner = false;
        this.toggleState();
    }

    handleError(){
        this.state.displaySpinner = false;
    }

    onFormLoaded(event) {
        if(event.detail.records && event.detail.records.hasOwnProperty(this.recordId) && this.hasRecordAccess(event.detail.records[this.recordId])) {
            let support = this.template.querySelector('[data-id="supportLevel"]').value;
            this.state.displaySpinner = false;
            if(!this.state.isEdit) {
                this.state.supportLevel = (support) ? support : getFieldValue(this.incident.data, SUPPORT_TYPE_FIELD);
            }
            else {
                this.state.isDevResourceVisible = support !== 'L1' && support !== '';
                this.state.isJIRAFieldVisible = support !== '';
            }
        }
        else {
            this.state.displaySpinner = false;
            this.state.hasAccess = false;
        }
    }

    hasRecordAccess(recordData) {
        return recordData.fields.hasOwnProperty('JIRA_Link__c') || recordData.fields.hasOwnProperty('Dev_Resource__c') || recordData.fields.hasOwnProperty('Support_Type__c');
    }

    toggleState() {
        this.state.isEdit = !this.state.isEdit;
        this.state.displaySpinner = true;
    }

    handleSupportTypeChange() {
        let support = this.template.querySelector('[data-id="supportLevel"]').value;
        this.state.isDevResourceVisible = support !== 'L1' && support !== '';
        this.state.supportLevel = support;
        this.state.isJIRAFieldVisible = support !== '';
    }

    handleDevResourceChange(event) {
        if(this.isEmailRequired.data) {
            this.state.displaySpinner = true;
            this.devResourceId = event.target.value;
        }
    }
}