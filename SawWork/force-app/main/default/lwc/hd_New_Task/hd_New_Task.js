import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, updateRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';
import strUserId from '@salesforce/user/Id';
import INCIDENT_CATEGORY_FIELD from '@salesforce/schema/BMCServiceDesk__Incident__c.BMCServiceDesk__FKCategory__c';
import INCIDENT_PRIORITY_FIELD from '@salesforce/schema/BMCServiceDesk__Incident__c.BMCServiceDesk__FKPriority__c';
import INCIDENT_IMPACT_FIELD from '@salesforce/schema/BMCServiceDesk__Incident__c.BMCServiceDesk__FKImpact__c';
import INCIDENT_URGENCY_FIELD from '@salesforce/schema/BMCServiceDesk__Incident__c.BMCServiceDesk__FKUrgency__c';
import INCIDENT_DUEDATE_FIELD from '@salesforce/schema/BMCServiceDesk__Incident__c.BMCServiceDesk__dueDateTime__c';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import logErrorRecord from '@salesforce/apex/HD_UX_Exception_LoggerCls.logErrorRecord';

const INCIDENT_FIELDS = [INCIDENT_CATEGORY_FIELD, INCIDENT_DUEDATE_FIELD, INCIDENT_PRIORITY_FIELD, INCIDENT_IMPACT_FIELD, INCIDENT_URGENCY_FIELD];

export default class Hd_New_Task extends LightningElement {
    defaultCategory;
    defaultDueDate;
    todaysDate = new Date().toISOString();
    loggedInClient = strUserId;
    isLoading = true;
    @api parentIncident;
    @track supportedObjects = [
        { label: "User", value: "User", objectIcon: "standard:user", additionalFilters: "IsActive=true", recordRetrieveLimit: 20, searchField: 'Name' },
        { label: "Queue", value: "QueueSobject", objectIcon: "standard:orders", additionalFilters: "SobjectType = 'BMCServiceDesk__Task__c'", searchField: 'Queue.Name', metadataFields: 'QueueId, SobjectType' }
    ];

    @wire(getRecord, { recordId: '$parentIncident', fields: INCIDENT_FIELDS })
    getIncidentCallback(result) {
        if (result.data) {
            this.defaultCategory = result.data.fields.BMCServiceDesk__FKCategory__c.value;
            this.defaultDueDate = result.data.fields.BMCServiceDesk__dueDateTime__c.value;
            this.dueDate = result.data.fields.BMCServiceDesk__dueDateTime__c.value;
            this.template.querySelector('[data-id="priority"]').value = result.data.fields.BMCServiceDesk__FKPriority__c?.value;
            this.template.querySelector('[data-id="urgency"]').value = result.data.fields.BMCServiceDesk__FKUrgency__c?.value;
            this.template.querySelector('[data-id="impact"]').value = result.data.fields.BMCServiceDesk__FKImpact__c?.value;
        }
    }

    onFormLoaded() {
        this.isLoading = false;
    }

    onRecordSaved(event) {
        const fields = {};
        fields.Id = event.detail.id;
        let lookup = this.template.querySelector("[data-id='assignedTo']");
        if (lookup?.selectedRecord) {
            /* eslint-disable-next-line */
            fields.OwnerId = ('QueueId' in lookup.selectedRecord) ? lookup.selectedRecord['QueueId'] : lookup.selectedRecord.Id;
        }
        else {
            fields.OwnerId = this.loggedInClient;
        }
        const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
                this.isLoading = false;
                this.dispatchEvent(new CustomEvent('closemodal'));
                this.displayToast('Success', 'Task created successfully', 'success');
                getRecordNotifyChange([{ recordId: this.parentIncident }]);
            })
            .catch(error => {
                this.isLoading = false;
                this.displayToast('Error', error.body.message, 'error');
                this.logError(JSON.stringify(error));
            });
    }

    onRecordSaveError() {
        this.isLoading = false;
    }

    handleSubmit(event) {
        event.preventDefault();
        const isInputsCorrect = [...this.template.querySelectorAll('lightning-input-field'), this.template.querySelector('c-hd-lookup')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.reportValidity();
            }, true);
        if (isInputsCorrect) {
            this.isLoading = true;
            this.template.querySelector('lightning-record-edit-form').submit();
        }
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('closemodal'));
    }

    displayToast(title, message, varient) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: varient,
        });
        this.dispatchEvent(evt);
    }

    logError(error) {
        logErrorRecord({
            ErrorMsg: error,
            Stacktrace: null,
            IncidentId: null
        });
    }
}