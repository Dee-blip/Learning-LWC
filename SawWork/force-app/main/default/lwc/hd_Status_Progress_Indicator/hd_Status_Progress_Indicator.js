import { LightningElement, wire, api, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { getRecord } from 'lightning/uiRecordApi';
import getAllStatuses from '@salesforce/apex/HD_IncidentHeaderController.getAllStatuses';
import APPROVAL_STATUS_FIELD from '@salesforce/schema/BMCServiceDesk__Incident__c.HD_Approval_Status__c';
export default class Hd_Status_Progress_Indicator extends LightningElement {
    statuses = [];
    displayTooltip;
    showProgressIndicator = true;
    @api recordId;
    @api currentStatus;
    @track wiredResponse;

    @api fireRefresh() {
        refreshApex(this.wiredResponse);
    }

    @wire(getRecord, { recordId: '$recordId', fields: [APPROVAL_STATUS_FIELD] })
    getIncidentCallback(result) {
        this.wiredResponse = result;
        if (result.data) {
            this.showProgressIndicator = result.data.fields.HD_Approval_Status__c.value === 'Approved';
        }
    }

    @wire(getAllStatuses, { incidentId: '$recordId' })
    getStatusesCallback(result) {
        if (result.data) {
            let parsedData = JSON.parse(result.data);
            let counter = 1;
            let temp = [];
            parsedData.forEach(status => {
                if (this.isValidValue(status.OldValue, temp)) {
                    temp.push({ label: status.OldValue, value: counter++ });
                }
                if (this.isValidValue(status.NewValue, temp)) {
                    temp.push({ label: status.NewValue, value: counter++ });
                }
            });
            this.statuses = temp;
        }
    }

    get currentStep() {
        return this.statuses.length;
    }
    get displayFooter() {
        return this.statuses.length > 0;
    }
    isValidValue(status, statuses) {
        return status && !status.startsWith('a6b') && (statuses.length === 0 || statuses[statuses.length - 1].label !== status);
    }
    onMouseOverAdditionalInfo() {
        this.displayTooltip = true;
    }

    onCloseButtonClick() {
        this.displayTooltip = false;
    }
}