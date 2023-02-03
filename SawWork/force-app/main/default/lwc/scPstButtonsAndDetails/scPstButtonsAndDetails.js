import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import { getObjectInfos } from 'lightning/uiObjectInfoApi';

import {extractRecordTypeIdFromObjInfo, getPageReference} from './util';
import isPartnerFeedbackMissing from '@salesforce/apex/SC_PSTCaseHandler.isPartnerFeedbackMissing';
import PFEEDBACK_OBJECT from '@salesforce/schema/SC_Partner_Support_Feedback__c';
import PERF_OBJECT from '@salesforce/schema/SC_Performance_Metrics__c';

import { PARTNER_FEEDBACK_RECORDTYPE, 
        PERF_DETAIL_REQ_TYPES, 
        PARTNER_FEEDBACK_REQ_TYPES} from './constants';

export default class ScPstButtonsAndDetails extends NavigationMixin(LightningElement) {

    @api recordId;
    @track oppRecord = {};
    @track caseRecord = {};
    @track objectInfos = {};
    @track isPartnerFbkMissing;

    fields = ['Case.Opportunity__r.Name', 'Case.Opportunity__r.MRR__c', 'Case.Opportunity__r.Amount', 
                'Case.Opportunity__r.StageName', 'Case.Request_Type__c', 'Case.Status'];
    @wire(getRecord, { recordId: '$recordId', fields: '$fields', modes: 'View'})
    processFieldInfo({data}) {
        if(data){
            let opp = data.fields.Opportunity__r.value;
            this.oppRecord.Name = opp && opp.fields.Name.value;
            this.oppRecord.MRR__c = opp && opp.fields.MRR__c.displayValue;
            this.oppRecord.Amount = opp && opp.fields.Amount.displayValue;
            this.oppRecord.StageName = opp && opp.fields.StageName.displayValue;

            this.caseRecord = {};
            Object.entries(data.fields).forEach(([fName, fDetails]) =>{
                this.caseRecord[fName] = fDetails.value;
            });
        } 
    }
    
    @track objectNames  =[PFEEDBACK_OBJECT, PERF_OBJECT];
    @wire(getObjectInfos, { objectApiNames:  '$objectNames' })
    processObjectInfos({data}) {
        if(data) {
            data.results.forEach(({statusCode, result}) => {
                if(statusCode === 200) {
                    this.objectInfos[result.apiName] = result;
                }
            });
        }
    }

    @wire(isPartnerFeedbackMissing, {caseId: '$recordId'})
    pFeedback({data}) {
        this.isPartnerFbkMissing = data;
    }

    get showCreatePartnerFeedbackButton() {
        const partnerFeedbackInfo =  this.objectInfos[PFEEDBACK_OBJECT.objectApiName];
        const isPartFeedbackNeeded = this.caseRecord.Status !== 'Closed' && PARTNER_FEEDBACK_REQ_TYPES.includes(this.caseRecord.Request_Type__c) && this.isPartnerFbkMissing;
        return partnerFeedbackInfo && partnerFeedbackInfo.createable && isPartFeedbackNeeded;
    }

    get showCreatePerfDetailsButton() {
        const perfDetailInfo =  this.objectInfos[PERF_OBJECT.objectApiName];
        const isPerfDetailNeeded = this.caseRecord.Status !== 'Closed' && PERF_DETAIL_REQ_TYPES.includes(this.caseRecord.Request_Type__c);
        return perfDetailInfo && perfDetailInfo.createable && isPerfDetailNeeded;
    }

    get showButtons() {
        return this.showCreatePartnerFeedbackButton || this.showCreatePerfDetailsButton;
    }

    openPartnerFeedbackCreatePage() {
        let partnerFbkObjInfo = this.objectInfos[PFEEDBACK_OBJECT.objectApiName];
        let partnerFbkRecordTypeName = PARTNER_FEEDBACK_RECORDTYPE[this.caseRecord.Request_Type__c];
        let partnerFbkRecordTypeId = extractRecordTypeIdFromObjInfo(partnerFbkObjInfo, partnerFbkRecordTypeName);
        const partnerFeedbackPage = getPageReference(this, PFEEDBACK_OBJECT.objectApiName, partnerFbkRecordTypeId);
        this[NavigationMixin.Navigate](partnerFeedbackPage);
    }

    openPerfDetailCreatePage() {
        const partnerFeedbackPage = getPageReference(this, PERF_OBJECT.objectApiName);
        this[NavigationMixin.Navigate](partnerFeedbackPage);
    }
}