import { LightningElement, api, track, wire } from 'lwc';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import getCommentsData from "@salesforce/apex/SC_DD_FieldTracker.getHistory";
const HIST_FIELDS = ['Comments__c', 'Commented_By__c', 'Evaluation_Action__c', 'Deal_Zone__c', 'Approval_Stage__c', 'Auto_Escalated__c'];
export default class HistoryLens extends LightningElement {

    @track comments;
    @api recordId;
    
    timezone = TIME_ZONE;
    prevChange;
    noTrackingOnCommentedBy;
    @wire(getCommentsData, { sobjectName: 'SC_DD_Deal__c', sobjFields: HIST_FIELDS, recordId: '$recordId' })
    processComments({ data, error }) {

        this.prevChange = {};

        if (data) {
            this.comments = JSON.parse(JSON.stringify(data));

            this.comments.forEach(el => {

                // If Auto Escalated is unchanged, get value from previous change
                el.Auto_Escalated__c = this.getValue(el.Auto_Escalated__c, 'Auto_Escalated__c');

                if (el.Auto_Escalated__c === true) {
                    el.Evaluation_Action__c = 'Auto Escalated';
                    el.CreatedBy = '';
                }

                // If Commented By is unchanged, get value from previous change Approval Stage
                el.Commented_By__c = el.Commented_By__c || this.prevChange.Approval_Stage__c;

                // If Approval Stage is unchanged, get value from previous change
                el.Approval_Stage__c = this.getValue(el.Approval_Stage__c, 'Approval_Stage__c');

                // If Comments is unchanged, get value from previous change
                el.Comments__c = this.getValue(el.Comments__c, 'Comments__c');

                // If Evaluation Action is unchanged, get value from previous change
                el.Evaluation_Action__c = this.getValue(el.Evaluation_Action__c, 'Evaluation_Action__c');

                el.CreatedByUrl = '/' + el.CreatedById;
            });
            // fix for old deals, as history tracking is not enabled on Commented_By__c field
            if (this.comments[1] && this.comments[1].Commented_By__c === 'SLM/SLD') {
                this.comments[0].Commented_By__c = 'DDA';
            }

        } else if (error) {
            console.error('error fetching comments data ', error);
        }
    }

    getValue(fldValue, fldName) {
        if (fldValue !== undefined) {
            this.prevChange[fldName] = fldValue;
        }
        return this.prevChange[fldName];
    }
}