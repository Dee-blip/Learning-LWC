import { LightningElement, wire, api, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getGroupedUnifiedHistoryByDate from '@salesforce/apex/HDUnifiedHistoryLightningEdition.getGroupedUnifiedHistoryByDate';
import logErrorRecord from '@salesforce/apex/HD_UX_Exception_LoggerCls.logErrorRecord';
import { getRecord } from 'lightning/uiRecordApi';
import INCIDENT_STAGE_FIELD from '@salesforce/schema/BMCServiceDesk__Incident__c.BMCServiceDesk__FKStatus__r.BMCServiceDesk__Stage__c';

export default class Hd_Activity_Timeline extends LightningElement {
    @api recordId;
    @track wiredResponse;
    @track allActivities = [];
    @track firstFewActivites = [];
    isLoading = true;
    isExpandCollapseAll = false;
    isError;
    errorMessage;
    loadIncrement = 5;
    isTicketClosed;

    //get the incident record details w.r.t stage field
    @wire(getRecord, { recordId: '$recordId', fields: [INCIDENT_STAGE_FIELD] })
    incidentRecord({data, error}) {
        if (data) {
            this.isTicketClosed = data.fields.BMCServiceDesk__FKStatus__r.value.fields.BMCServiceDesk__Stage__c.value === 'Closed' ? true : false;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.data = undefined;
        }
    }

    @api refreshTimeline() {
        this.isLoading = true;
        refreshApex(this.wiredResponse);
    }

    @wire(getGroupedUnifiedHistoryByDate, {
        targetObjectIdvalue: '$recordId',
        rowCount: '5000'
    })
    callback(result) {
        this.wiredResponse = result;
        if (result.data) {
            this.processResponseFromApex(result.data);
            this.isLoading = false;
        }
        else if (result.error) {
            this.isLoading = false;
            this.isError = true;
            this.errorMessage = result.error.body.message;
            this.logError(JSON.stringify(result.error));
        }
    }

    processResponseFromApex(data) {
        let temp = [];
        let resultMap = new Map(Object.entries(data));
        let sortedResult = new Map([...resultMap.entries()].sort(
            function (a, b) {
                var keyA = new Date(a[0]),
                    keyB = new Date(b[0]);
                // Compare the 2 dates
                if (keyA > keyB) return -1;
                if (keyA < keyB) return 1;
                return 0;
            }));
        for (const [item, value] of sortedResult) {
            if (value.History && value.History.length > 0) {
                temp.push({ when: item, activity: value, isHistoryActivity: true, isExpanded: false });
            }
            if (value['Action History'] && value['Action History'].length > 0) {
                temp.push({ when: item, activity: value, isActionHistoryActivity: true, isExpanded: false });
            }
            if (value['Approval History'] && value['Approval History'].length > 0) {
                temp.push({ when: item, activity: value, isApprovalHistoryActivity: true, isExpanded: false });
            }
            if (value.Snote && value.Snote.length > 0) {
                temp.push({ when: item, activity: value, isSNoteActivity: true, isExpanded: false });
            }
        }
        this.allActivities = temp;
        this.allActivities.slice(0, this.loadIncrement).forEach(activity => {
            activity.isExpanded = true;
        });
        this.firstFewActivites = this.allActivities.slice(0, this.loadIncrement);
    }

    get displayTimeline() {
        return (this.firstFewActivites) ? true : false;
    }

    logError(error) {
        logErrorRecord({
            ErrorMsg: error,
            Stacktrace: null,
            IncidentId: this.recordId
        });
    }

    handleErrorFromChild(event) {
        this.logError(event.detail);
    }

    onRefreshClicked() {
        this.isLoading = true;
        getGroupedUnifiedHistoryByDate({
            targetObjectIdvalue: this.recordId,
            rowCount: '5000'
        })
            .then(result => {
                this.processResponseFromApex(result);
                this.isLoading = false;
            })
            .catch(error => {
                this.isLoading = false;
                this.isError = true;
                this.errorMessage = error.body.message;
                this.logError(JSON.stringify(error));
            })
    }

    onExpandCollapseAllClicked() {
        this.isExpandCollapseAll = !this.isExpandCollapseAll;
        this.template.querySelectorAll("[data-id='timelineItem']").forEach(history => {
            history.isExpanded = this.isExpandCollapseAll;
        });
    }

    get isAllItemsLoaded() {
        return this.firstFewActivites.length === this.allActivities.length;
    }

    onViewMoreClicked() {
        let startIndex = this.firstFewActivites.length;
        let endIndex = (this.firstFewActivites.length + this.loadIncrement <= this.allActivities.length) ? this.firstFewActivites.length + this.loadIncrement : this.allActivities.length;
        let temp = [];
        temp = [...this.firstFewActivites, ...this.allActivities.slice(startIndex, endIndex)];
        temp.forEach(history => {
            if (this.isExpandCollapseAll) {
                history.isExpanded = true;
            }
        });

        this.firstFewActivites = temp;
    }

    onViewAllClicked() {
        let startIndex = this.firstFewActivites.length;
        let temp = [];
        temp = [...this.firstFewActivites, ...this.allActivities.slice(startIndex, this.allActivities.length)];
        temp.forEach(history => {
            if (this.isExpandCollapseAll) {
                history.isExpanded = true;
            }
        });
        this.firstFewActivites = temp;
    }

    get pendingActivities() {
        return this.allActivities.length - this.firstFewActivites.length;
    }
}