/**
 * @description       : 
 * @author            : apyati
 * @team              : GSM
 * @last modified on  : 09-29-2021
 * @last modified by  : apyati
 * Modifications Log
 * Ver   Date         Author   Modification
 * 1.0   08-17-2021   apyati   Initial Version
**/
import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const oppFields = {
    "sections": [
        {
            'sectionName': 'Opportunity Information',
            'fields': [
                {
                    'fieldName': 'ZOFF_Status__c',
                    'mode': 'edit'
                },
                {
                    'fieldName': 'Opportunity_Type__c',
                    'mode': 'edit'
                },
                {
                    'fieldName': 'Opt_Out_Reason__c',
                    'mode': 'edit'
                }
            ]
        },
        {
            'sectionName': 'Forecasting Information',
            'fields': [
                {
                    'fieldName': 'MRR__c',
                    'mode': 'view'
                },
                {
                    'fieldName': 'CloseDate',
                    'mode': 'view'
                },
                {
                    'fieldName': 'Non_Traffic_MRR__c',
                    'mode': 'view'
                },
                {
                    'fieldName': 'ForecastCategory',
                    'mode': 'view'
                },

                {
                    'fieldName': 'NRR__c',
                    'mode': 'view'
                },
                {
                    'fieldName': 'Opportunity_Revenue_Impact__c',
                    'mode': 'view'
                },
                {
                    'fieldName': 'CurrencyIsoCode',
                    'mode': 'view'
                },
                {
                    'fieldName': 'EMRI_Comments__c',
                    'mode': 'edit'
                }
            ]
        },
        {
            'sectionName': 'Cancellation And Loss Information',
            'fields': [
                {
                    'fieldName': 'Opportunity_Category__c',
                    'mode': 'edit'
                },
                {
                    'fieldName': 'New_Churn__c',
                    'mode': 'view'
                },
                {
                    'fieldName': 'Loss_Reason__c',
                    'mode': 'edit'
                },
                {
                    'fieldName': 'Aggregation_Partner__c',
                    'mode': 'edit'
                },
                {
                    'fieldName': 'Loss_Cancellation_Description__c',
                    'mode': 'edit'
                },
                {
                    'fieldName': 'Consolidation_Account__c',
                    'mode': 'edit'
                },
                {
                    'fieldName': 'Competitor__c',
                    'mode': 'edit'
                },
                {
                    'fieldName': 'Other_Competitor_Name__c',
                    'mode': 'edit'
                }

            ]
        }
    ]

}
export default class L2qOpportunityDetails extends NavigationMixin(LightningElement) {
    isEdit = false;
    areDetailsVisible = false;
    @api showSpinner;
    @api hasAccess;
    showIcon = false;
    fieldsArray = [];
    fieldsToSave = [];
    inputStyle = "normalText";
    @api recordId12 = '';
    quickSave = false;
    formIsEdited = false;
    firstTime = true;
    oppType;
    loadform;
    connectedCallback() {
        console.log('connectedcallback=> recordId12' + this.recordId12);
        if(this.recordId12){
            this.loadform= true;
        }
        oppFields.sections.forEach(e => {
            let fields = [];
            e.fields.forEach(f => {
                let view = false;
                if (f.mode === 'view') {
                    view = true;
                } else {
                    this.fieldsToSave.push(f.fieldName);
                }
                fields.push({
                    'fieldName': f.fieldName,
                    'mode': view
                });
            });
            this.fieldsArray.push({
                'sectionName': e.sectionName,
                'fields': fields
            });
        })
    }

    editHandler() {
        //enable edit only if user has access
        console.log('editHandler' + this.hasAccess);
        if (this.hasAccess) {
            this.isEdit = true;
        }
    }

    handleLoad(event) {

        this.areDetailsVisible = true;
        let record = event.detail.records;
        if (record && record[this.recordId12]) {
            let fields = record[this.recordId12].fields;
            if (fields && fields.Opportunity_Type__c) {
                this.optyType = fields.Opportunity_Type__c.value;
                console.log('handleLoad optytype' + JSON.stringify(this.optyType));
            }
        }

        const evt = new CustomEvent('hidespinner', { 'detail': this.firstTime });
        this.dispatchEvent(evt);
        this.firstTime = false;

    }

    @api
    handleSubmit() {
        console.log('in hadle submit method');
        this.saveRecordToDatabase();
    }

    handleShowPopover(event) {
        let element = this.template.querySelectorAll('lightning-button-icon[data-id=' + event.target.fieldName + ']');
        element.forEach(e => {
            if (e.dataId === event.target.dataId) {
                e.style.display = 'block';
            }
        });
    }
    hideIcon(event) {
        let element = this.template.querySelectorAll('lightning-button-icon[data-id=' + event.target.fieldName + ']');
        element.forEach(e => {
            if (e.dataId === event.target.dataId) {
                e.style.display = 'none';
            }
        });
    }

    onchangeHandler(event) {
        this.formIsEdited = true;

        console.log('onchangeHandler');
        let element = this.template.querySelectorAll("lightning-input-field");
        if (event.target.name === 'Opportunity_Type__c') {
            const evtOppType = new CustomEvent('setopptype', { 'detail': event.target.value });
            this.dispatchEvent(evtOppType);
        }
        element.forEach(e => {
            if (e.name === event.target.name) {
                e.style.color = "orange";
            }
        });
        const evt = new CustomEvent('enablesave', { 'detail': 'Opportunity' });
        this.dispatchEvent(evt);
    }

    @api
    quickSaveHandler() {
        this.quickSave = true;
        this.saveRecordToDatabase();
    }

    saveRecordToDatabase() {
        const fieldsToSubmitArray = [];

        if (this.formIsEdited) {
            this.fieldsToSave.forEach(e => {
                console.log('fieldToSave', e);
                const fieldRetrieved = this.template.querySelector('lightning-input-field[data-id=' + e + ']');
                if (fieldRetrieved) {
                    let fieldApiName = e;
                    fieldsToSubmitArray.push({ 'fieldApiName': fieldApiName, 'value': fieldRetrieved.value });
                }
            });
        }
        if (fieldsToSubmitArray.length === 0 && this.optyType) {
            fieldsToSubmitArray.push({ 'fieldApiName': 'Opportunity_Type__c', 'value': this.optyType });
        }
        console.log('fieldsToSubmitArray' + JSON.stringify(fieldsToSubmitArray));
        if (fieldsToSubmitArray.length > 0) {
            fieldsToSubmitArray.push({ 'fieldApiName': 'Id', 'value': this.recordId12 });
            const evt = new CustomEvent('oppsave', { 'detail': fieldsToSubmitArray });
            this.dispatchEvent(evt);
        }
        else {
            const evt = new CustomEvent('oppsave', { 'detail': null });
            this.dispatchEvent(evt);
        }
    }

    showToast(title, message, variant, mode, messageData) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                messageData: messageData,
                variant: variant,
                mode: mode
            }),
        );
    }

    @api
    enableViewMode() {
        this.isEdit = false;
    }


}