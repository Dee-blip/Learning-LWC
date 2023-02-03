import { LightningElement, api, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from "lightning/platformShowToastEvent"
import { NavigationMixin } from 'lightning/navigation';
import fetchAllRelatedCases from '@salesforce/apex/SC_SI_PageLayoutButton_Controllor.fetchAllRelatedCases';
import delinkSIRecords from '@salesforce/apex/SC_SI_PageLayoutButton_Controllor.deLinkSIRecords';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import  NAME_FIELD from '@salesforce/schema/SC_SI_Service_Incident__c.Name';
import timezoneNameUser from '@salesforce/i18n/timeZone';


export default class Sc_SI_AllRelatedCasesView extends NavigationMixin(LightningElement) {
    @api caseList;
    @api siRecordId;
    caseList;
    error;
    showSpinner;
    wiredCases;
    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    sortedBy;
   // siName;

    // Delink Menu Action
    @track actions = [
        { label: 'Delink', name: 'Delink' }
    ];

    // Columns for Datatable
    @track columns = [{
        label: 'Akam Case Id',
        fieldName: 'AKAM_Case_Id',
        type: 'url',
        typeAttributes: { label: { fieldName: 'AKAM_Case_ID__c' }, target: '_blank' },
        sortable: true
    },
    {
        label: 'Account Name',
        fieldName: 'AccountId',
        type: 'url',
        typeAttributes: { label: { fieldName: 'AccountName' }, target: '_blank' },
        sortable: true
    },
    {
        label: 'Support Level',
        fieldName: 'Support_Level__c',
        type: 'text',
        sortable: true
    },
    {
        label: 'Customer Tier',
        fieldName: 'Customer_Tier__c',
        type: 'text',
        sortable: true
    },
    {
        label: 'Case Product',
        fieldName: 'Case_Prod_Name',
        type: 'url',
        typeAttributes: { label: { fieldName: 'Case_Prod_Name__c' }, target: '_blank' },
        sortable: true
    },
    {
        label: 'Subject',
        fieldName: 'Subject',
        type: 'text',
        sortable: true
    },
    {
        label: 'Akam Created Date',
        fieldName: 'AKAM_Created_Date__c',
        type: 'date',
        sortable: true,typeAttributes: {  
            day: 'numeric',  
            month: 'short',  
            year: 'numeric',  
            hour: '2-digit',  
            minute: '2-digit',  
            hour12: true,
            timeZone: timezoneNameUser 
            
        }
    },
    {
        label: 'Status',
        fieldName: 'Status',
        type: 'text',
        sortable: true
    },
    {
        label: 'Owner Name',
        fieldName: 'Case_Owner',
        type: 'url',
        typeAttributes: { label: { fieldName: 'Case_Owner_Name__c' }, target: '_blank' },
        sortable: true
    },
    {
        label: 'Case Linked Date',
        fieldName: 'Case_Linked_Date__c',
        type: 'date',
        sortable: true
    },
    {
        type: 'action',
        typeAttributes: {
            rowActions: [
                { label: 'Delink', name: 'Delink' }],
            menuAlignment: 'right'
        }
    }
    ];

    // Fetching Incident Name
    @wire(getRecord, { recordId: '$siRecordId', fields: [NAME_FIELD] })
    record;
    
    get name() {
        return getFieldValue(this.record.data, NAME_FIELD);
    }

    // Fetching Case Data
    @wire(fetchAllRelatedCases, { SIrecordId: '$siRecordId' })
    caseData(value) {

        this.wiredCases = value; // track the provisioned value
        const { data, error } = value;
        if (data) {
            let caseRecords = JSON.parse(data);
            var tempCaseList = [];
            caseRecords.forEach(record => {
                let tempRecord = Object.assign({}, record); //cloning object  
                tempRecord.AKAM_Case_Id = "/" + tempRecord.Id;

                if (tempRecord.hasOwnProperty("AccountId") && tempRecord.AccountId !== "undefined" && tempRecord.AccountId.length > 0) {
                    tempRecord.AccountId = "/" + tempRecord.AccountId;
                    tempRecord.AccountName = tempRecord.Account.Name;
                }

                if (tempRecord.hasOwnProperty("Case_Product__c") && tempRecord.Case_Product__c !== "undefined" && tempRecord.Case_Product__c.length > 0) {
                    tempRecord.Case_Prod_Name = "/" + tempRecord.Case_Product__c;
                    tempRecord.Case_Prod_Name__c = tempRecord.Case_Prod_Name__c;
                }

                tempRecord.Case_Owner = "/" + tempRecord.OwnerId;
                tempCaseList.push(tempRecord);
            });
            this.caseList = tempCaseList;
           // this.siName = this.caseList[0].Service_Incident__r.Name;
        } else if (error) {
            this.error = error;
            console.log('error//' + JSON.stringify(error));
        }
    }

    handleRowAction(event) {
        let actionName = event.detail.action.name;
        let row = event.detail.row;
        this.showSpinner = true;
        let caseId = row.Id
        delinkSIRecords({ CaserecordId: caseId })
            .then(result => {
                if (result === 'Success') {
                    this.showSpinner = false;
                    const toastEvt = new ShowToastEvent({
                        title: "Success",
                        message: "Case is delinked.",
                        variant: "Success",
                        mode: "dismissible",
                        duration: 5000
                    });
                    this.dispatchEvent(toastEvt);
                    // refreshing the case data
                    return refreshApex(this.wiredCases);
                }
                else {
                    this.showSpinner = false;
                    const toastEvt = new ShowToastEvent({
                        title: "Error",
                        message: result,
                        variant: "Error",
                        mode: "dismissible",
                        duration: 5000
                    });
                    this.dispatchEvent(toastEvt);
                }
            })
            .catch(error => {
                this.showSpinner = false;
                console.log("error//" + JSON.stringify(error));
            })

    }
    sortBy(field, reverse, primer) {
        const key = primer
            ? function (x) {
                return primer(x[field]);
            }
            : function (x) {
                return x[field];
            };

        return function (a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    }
    onHandleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.caseList];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.caseList = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

    // Navigate to SI record
    handleSIClick() {
        // Navigate to the Service Incdent object home page.
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'SC_SI_Service_Incident__c',
                actionName: 'home'
            }
        });
    }

    // Navigate to SI Home
    handleRecClick() {
        // View Service Incident record.
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.siRecordId,
                objectApiName: 'SC_SI_Service_Incident__c',
                actionName: 'view'
            }
        });
    }

}