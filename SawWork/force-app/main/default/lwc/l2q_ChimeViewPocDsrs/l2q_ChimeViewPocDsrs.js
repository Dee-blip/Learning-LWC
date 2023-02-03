/**
 * @description       : CHIME Mnage DSRS
 * @author            : apyati
 * @team              : GSM
 * @last modified on  : 02-04-2022
 * @last modified by  : apyati
 * Modifications Log
 * Ver   Date         Author   Modification
 * 1.0   11-14-2021   apyati   SFDC-8653 Initial Version
**/

import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
import getUnAssociatedChimePOCDSRs from '@salesforce/apex/ChimeDSRController.getUnAssociatedChimePOCDSRs';
import getAssociatedChimePOCDSRs from '@salesforce/apex/ChimeDSRController.getAssociatedChimePOCDSRs';
import associateChimePOCDSRs from '@salesforce/apex/ChimeDSRController.associateChimePOCDSRs';
import disassociateChimePOCDSRs from '@salesforce/apex/ChimeDSRController.disassociateChimePOCDSRs';

import { getObjectInfo } from 'lightning/uiObjectInfoApi';

const ASSIGNED = "Assigned";
const UNASSIGNED = "Unassigned";

const TABS = [
    {
        tab: ASSIGNED,
        helpText: "",
    },
    {
        tab: UNASSIGNED,
        helpText: "",
    }
];

export default class L2q_ChimeViewPocDsrs extends NavigationMixin(LightningElement) {

    @api chimeId;
    @api opptyId;
    @api accId;
    @api disableActions;
    @track isLoading;
    @track showErrorMessage;
    @track NoDataAfterRendering;
    @track showCreateForm;
    @track selectedRecordsList;
    @track defaultTabOnInitialization;
    @track columns;
    @track data;
    @track recordsToDisplay;
    @track currentTabValue;
    @track tabs = TABS;
    @track displayDataTableFooter;
    @track displayAddBTN;
    @track displayRemoveBTN;
    @track selectedRow;

    COLUMNS_ASSIGNED = [
        {
            label: 'DSR',
            fieldName: 'DSRURL',
            type: "url",
            typeAttributes: {
                label: { fieldName: 'DSRName' },
                target: "_blank"
            },
            sortable: true,
        },
        {
            label: 'Product ',
            fieldName: 'Product__c',
            sortable: true,
        },
        {
            label: 'Status',
            fieldName: 'POC_Status__c',
            sortable: true,
        },
        {
            label: 'Start Date',
            fieldName: 'Start_Date__c',
            type: 'date-local',
            typeAttributes: {
                day: "numeric",
                month: "numeric",
                year: "numeric"
            },
            sortable: true,
        },
        {
            label: 'Success Criteria',
            fieldName: 'Success_Criteria__c',
            sortable: true,
        },
    ];

    COLUMNS_UNASSIGNED = [
        {
            label: 'DSR',
            fieldName: 'DSRURL',
            type: "url",
            typeAttributes: {
                label: { fieldName: 'DSRName' },
                target: "_blank"
            },
            sortable: true,
        },
        {
            label: 'Product ',
            fieldName: 'Product__c',
            sortable: true,
        },
        {
            label: 'Status',
            fieldName: 'POC_Status__c',
            sortable: true,
        },
        {
            label: 'Start Date',
            fieldName: 'Start_Date__c',
            type: 'date-local',
            typeAttributes: {
                day: "numeric",
                month: "numeric",
                year: "numeric"
            },
            sortable: true,
        },
        {
            label: 'Success Criteria',
            fieldName: 'Success_Criteria__c',
            sortable: true,
        },
        /*
        {
            label: 'Account',
            fieldName: 'AccountURL',
            type: "url",
            typeAttributes: {
                label: { fieldName: 'AccountName' },
                target: "_self"
            },

        },
        {
            label: 'Opportunity',
            fieldName: 'OpportunityURL',
            type: "url",
            typeAttributes: {
                label: { fieldName: 'OpportunityName' },
                target: "_self"
            },

        },
        {
            label: 'CHIME',
            fieldName: 'CHIMEURL',
            type: "url",
            typeAttributes: {
                label: { fieldName: 'CHIMEName' },
                target: "_self"
            },

        },
        {
            label: 'Request Type ',
            fieldName: 'Request_Type__c',
        },
        {
            label: 'Approval Status',
            fieldName: 'Approval_Status__c',
        },
        {
            label: 'Notes ',
            fieldName: 'Notes__c',
        },*/
    ];



    connectedCallback() {

        console.log('this.chime' + this.chimeId);
        console.log('this.opty' + this.opptyId);

        this.isLoading = true;
        this.defaultTabOnInitialization = ASSIGNED;
        this.currentTabValue = ASSIGNED;
        this.handleLoad();
        this.isLoading = false;

    }


    @wire(getObjectInfo, { objectApiName: 'Deal_Support_Request__c' })
    objectdata({ data, error }) {
        if (data) {
            console.log('recordtypeifos' + JSON.stringify(data.recordTypeInfos));
            let rectypes = data.recordTypeInfos;
            Object.keys(rectypes).forEach(key => {
                if (rectypes[key].name === 'Pre-Sales Request') {
                    this.presalesrequestrectype = rectypes[key].recordTypeId;
                }
            });
            console.log('presalesrequestrectype' + this.presalesrequestrectype);
        } else if (error) {
            console.log('error', error);
        }
    };


    //handle tab selection
    handleActiveTab(event) {
        this.currentTabValue = event.target.value;
        //  console.log('handleActiveTab' + this.currentTabValue);
        this.handleLoad();
    }

    handleIconRefresh(){
        this.handleLoad();
    }


    handleLoad() {
        console.log('handleLoad called');
        this.NoDataAfterRendering = false;
        this.displayDataTableFooter = false;
        this.displayAddBTN = false;
        this.displayRemoveBTN = false;
        this.showErrorMessage = undefined;
        this.selectedRecordsList = [];
        this.selectedRow = [];

        if (this.currentTabValue === ASSIGNED) {
            this.data = undefined;
            this.columns= this.COLUMNS_ASSIGNED;
            console.log('parent', this.chimeId);
            this.isLoading = true;
            getAssociatedChimePOCDSRs({ chimeId: this.chimeId })
                .then((result) => {
                    let tempdata = JSON.parse(JSON.stringify(result));
                    if (tempdata && tempdata.length > 0) {
                        for (let i = 0; i < tempdata.length; i++) {

                            tempdata[i].DSRURL = '/' + tempdata[i].Id;
                            tempdata[i].DSRName = tempdata[i].Name;

                            /*
                            if (Object.prototype.hasOwnProperty.call(tempdata[i], "Account__r")) {
                                tempdata[i].AccountURL = '/' + tempdata[i].Account__r.Id;
                                tempdata[i].AccountName = tempdata[i].Account__r.Name;
                            }
                            if (Object.prototype.hasOwnProperty.call(tempdata[i], "Opportunity__r")) {
                                tempdata[i].OpportunityURL = '/' + tempdata[i].Opportunity__r.Id;
                                tempdata[i].OpportunityName = tempdata[i].Opportunity__r.Name;
                            }*/
                        }
                        this.data = JSON.parse(JSON.stringify(tempdata));


                    } else {
                        this.NoDataAfterRendering = true;
                        this.data = undefined;
                    }

                    this.isLoading = false;

                }).catch((error) => {
                    console.log(`save error --> ${JSON.stringify(error)}`);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: "Error occurred :",
                            message: error.body.message,
                            variant: "error"
                        })
                    );
                    this.isLoading = false;
                });
        }
        else if (this.currentTabValue === UNASSIGNED) {
            this.data = undefined;
            this.columns = this.COLUMNS_UNASSIGNED
            this.isLoading = true;

            getUnAssociatedChimePOCDSRs({ chimeId: this.chimeId, opportunityId: this.opptyId })
                .then((result) => {
                    let tempdata = JSON.parse(JSON.stringify(result));

                    if (tempdata && tempdata.length > 0) {
                        for (let i = 0; i < tempdata.length; i++) {

                            tempdata[i].DSRURL = '/' + tempdata[i].Id;
                            tempdata[i].DSRName = tempdata[i].Name;
                            /*
                            if (Object.prototype.hasOwnProperty.call(tempdata[i], "Account__r")) {
                                tempdata[i].AccountURL = '/' + tempdata[i].Account__r.Id;
                                tempdata[i].AccountName = tempdata[i].Account__r.Name;
                            }
                            if (Object.prototype.hasOwnProperty.call(tempdata[i], "Opportunity__r")) {
                                tempdata[i].OpportunityURL = '/' + tempdata[i].Opportunity__r.Id;
                                tempdata[i].OpportunityName = tempdata[i].Opportunity__r.Name;
                            }
                            if (Object.prototype.hasOwnProperty.call(tempdata[i], "CHIME__r")) {
                                tempdata[i].CHIMEURL = '/' + tempdata[i].CHIME__r.Id;
                                tempdata[i].CHIMEName = tempdata[i].CHIME__r.Name;
                            }*/
                        }
                        this.data = JSON.parse(JSON.stringify(tempdata));

                    } else {
                        this.NoDataAfterRendering = true;
                        this.data = undefined;
                    }

                    this.isLoading = false;

                }).catch((error) => {
                    console.log('save error --> ', error);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: "Error occurred :",
                            //message: error.body,
                            variant: "error"
                        })
                    );
                    this.isLoading = false;
                });
        }

    }


 

    //handle row selected
    handleRowSelected(event) {
    
        const selectedRows = event.detail.selectedRows;
        this.selectedRecordsList = JSON.parse(JSON.stringify(selectedRows));
        //console.log(`SelectedRows --> ${JSON.stringify(selectedRows)}`);
        this.selectedRow = [];
        for (let i = 0; i < selectedRows.length; i++) {
            this.selectedRow.push({ Id: selectedRows[i].Id });
        }

        if (this.selectedRow.length > 0) {
            this.displayDataTableFooter = true;
            if (this.currentTabValue === UNASSIGNED) {
                this.displayAddBTN = true;
                this.displayRemoveBTN = false;
            } else {
                this.displayAddBTN = false;
                this.displayRemoveBTN = true;
            }
            // console.log('currentTabValue',this.currentTabValue);
            // console.log('displayDataTableFooter',this.displayDataTableFooter);
            // console.log('displayAddBTN',this.displayAddBTN);
            // console.log('displayRemoveBTN',this.displayRemoveBTN);

            this.showErrorMessage = undefined;
        }
    }

    //handler to remove CHIME Contacts from CHIME
    handleRemove(event) {
        const chimeDSRs = this.selectedRecordsList;

        if (chimeDSRs !== undefined && chimeDSRs.length > 0) {
            this.isLoading = true;
            disassociateChimePOCDSRs({ chimeDSRs: chimeDSRs })
                .then((result) => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: "Success",
                            message: result,
                            variant: "success"
                        })
                    );

                    this.isLoading = false;
                    return this.handleLoad();
                })
                .catch((error) => {
                    console.log(`save error --> ${JSON.stringify(error)}`);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: "Error occurred :",
                            message: error.body.message,
                            variant: "error"
                        })
                    );
                    this.isLoading = false;
                })
        } else {
            this.showErrorMessage = "Please select a DSR to remove from the CHIME";
        }
    }

    handleAdd() {

        const chimeDSRs = this.selectedRecordsList;

        if (chimeDSRs !== undefined && chimeDSRs.length > 0) {
            this.isLoading = true;
            associateChimePOCDSRs({ selectedDSRs: chimeDSRs, chimeId: this.chimeId })
                .then((result) => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: "Success",
                            message: result,
                            variant: "success"
                        })
                    );
         
                    this.isLoading = false;
                    this.template.querySelector('lightning-tabset').activeTabValue = ASSIGNED;
                    return this.handleLoad();
                })
                .catch((error) => {
                    console.log(`Add error --> ${JSON.stringify(error)}`);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: "Error occurred :",
                            message: error.body.message,
                            variant: "error"
                        })
                    );
                    this.isLoading = false;
                })
        }
        else {
            this.showErrorMessage = "Please select a DSR to associate to CHIME";
        }
    }



    handleClose() {
        const cancelEvent = new CustomEvent('cancel', {});
        this.dispatchEvent(cancelEvent);
    }

    ShowCreateFormModal() {
        this.showCreateForm = true;
    }

    HideCreateFormModal() {
        this.showCreateForm = false;
    }


    handlePaginatorChange(event) {
        this.recordsToDisplay = JSON.parse(JSON.stringify(event.detail));
        
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


    doSorting(event) {

        var fname = event.detail.fieldName;
        if (fname.includes('URL')) {
            fname = fname.replace('URL', 'Name')
        }
        console.log('doSorting-->fname' + fname);
        this.sortBy = fname;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
        this.sortBy = event.detail.fieldName;

    }


    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.recordsToDisplay));
        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };
        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1 : -1;
        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';
            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });
        this.recordsToDisplay = parseData;
    }

}