/* eslint-disable no-console */
/* eslint-disable no-alert */

import { LightningElement, wire, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord } from 'lightning/uiRecordApi';

import CASE_OBJECT from '@salesforce/schema/Case';

import USER_ID from '@salesforce/user/Id';
import USER_NAME from '@salesforce/schema/User.Name';

import { loadStyle } from 'lightning/platformResourceLoader';
import cssStyleSheet from "@salesforce/resourceUrl/SC_S2ET_Stylesheet";

// apex classes
import getCaseList from '@salesforce/apex/SC_SecurityServices_Ctrlr.getCaseList';
import returnRecTypeId from '@salesforce/apex/SC_SecurityServices_Ctrlr.returnRecTypeId';
import getEscalationRecs from '@salesforce/apex/SC_SecurityServices_Ctrlr.getEscalationRecs';
import changeShiftOwner from '@salesforce/apex/SC_SecurityServices_Ctrlr.changeShiftOwner';
import getOwnerNotAssignedId from '@salesforce/apex/SC_SecurityServices_Ctrlr.returnONAId';
import getAllTaskRecs from '@salesforce/apex/SC_SecurityServices_Ctrlr.getAllTaskRecs';

import { ShowToastEvent } from "lightning/platformShowToastEvent";

import util from 'c/scUtil'; 

// row actions

//Added by Aditi for ESESP-3947 -added the ACC button, just like LUNA button
const actions =
    [
        { label: 'Edit Case', name: 'edit' },
        { label: 'New Task', name: 'newTask' },
        { label: 'New Escalation', name: 'newEsc' },
        { label: 'View Tasks', name: 'viewTask'},
        { label: 'ACC', name: 'accAction'}
    ];

const caseColumns =
    [
        {
            label: '',
            fieldName: 'hotCustomer',
            type: 'text',
            sortable: true,
            initialWidth: 10,
            cellAttributes: { alignment: 'center', class: 'hotCustomerIcon' }
        },
        {
            label: 'AKAM Case ID',
            fieldName: 'caseUrl',
            type: 'url',
            typeAttributes: { label: { fieldName: 'akamCaseId' }, tooltip: 'Go to Case', target: '_blank' },
            sortable: true,
            initialWidth: 125,
            cellAttributes: { alignment: 'left', class: { fieldName: 'caseColour' } }
        },
        {
            label: 'Parent Case',
            fieldName: 'parentCaseUrl',
            type: 'url',
            typeAttributes: { label: { fieldName: 'parentCaseAKAMId' }, tooltip: 'Go to Parent Case', target: '_blank' },
            initialWidth: 110,
            sortable: true,
            cellAttributes: { alignment: 'left' }
            //,cellAttributes: { iconName: 'utility:event', iconAlternativeText: 'Close Date' }
        },
        {
            label: 'Eng',
            fieldName: 'escCount',
            type: 'button',
            typeAttributes:
            {
                label: { fieldName: 'escCount' },
                variant: 'base',
                name: 'escCount'
            },
            sortable: true,
            initialWidth: 50,
            cellAttributes: { alignment: 'center', class: 'escBlueText' }
        },
        {
            label: 'Account',
            fieldName: 'accountUrl',
            type: 'url',
            typeAttributes: { label: { fieldName: 'accountName' }, tooltip: 'Go to Account', target: '_blank' },
            sortable: true,
            initialWidth: 180,
            cellAttributes: { alignment: 'left' },
            wrapText: true
        },
        {
            label: 'Subject',
            fieldName: 'subject',
            type: 'text',
            sortable: true,
            wrapText: true
        },
        {
            label: 'Status',
            fieldName: 'caseStatus',
            type: 'text',
            sortable: true,
            initialWidth: 100
        },
        {
            label: 'Sev',
            fieldName: 'severity',
            type: 'text',
            sortable: true,
            initialWidth: 60,
            cellAttributes: { alignment: 'center' }
        },
        {
            label: 'Age(d)',
            fieldName: 'ageDays',
            type: 'number',
            sortable: true,
            initialWidth: 80,
            cellAttributes: { alignment: 'left' }
        },
        {
            label: 'Shift Owner',
            fieldName: 'shiftOwnerUrl',
            type: 'url',
            typeAttributes: { label: { fieldName: 'shiftOwner' }, tooltip: 'Go to Shift Owner', target: '_blank' },
            sortable: true,
            initialWidth: 120,
            cellAttributes: { alignment: 'left' },
            wrapText: true
        },
        {
            label: 'Service',
            fieldName: 'service',
            type: 'text',
            sortable: true,
            initialWidth: 130,
            wrapText: true
        },
        {
            label: 'Pending Tasks',
            fieldName: 'pendingTasksCount',
            type: 'number',
            sortable: true,
            initialWidth: 110,
            cellAttributes: { alignment: 'center', class: { fieldName: 'pendingTaskColour' } }
        },
        {
            label: 'Last Updated',
            fieldName: 'lastUpdatedDateTimeString',
            type: 'text',
            sortable: true,
            initialWidth: 80,
            wrapText: true
        },
        {
            label: 'Last Updated By',
            fieldName: 'lastUpdatedByUrl',
            type: 'url',
            typeAttributes:
            {
                label: { fieldName: 'lastUpdatedBy' }, tooltip: 'Go to Last Updated By', target: '_blank'
            },
            sortable: true,
            initialWidth: 80,
            cellAttributes: { alignment: 'left' },
            wrapText: true
        },
        {
            type: 'action',
            typeAttributes: {
                rowActions: actions,
                menuAlignment: 'right'
            }
        }
    ];

const escColumns =
    [
        {
            label: 'ID',
            fieldName: 'escIDUrl',
            type: 'url',
            title: 'highPriority',
            wrapText: true,
            typeAttributes: { label: { fieldName: 'escID' }, target: '_blank' }
        },
        {
            label: 'Subject',
            fieldName: 'escSubjectURL',
            type: 'url',
            wrapText: true,
            initialWidth: 200,
            typeAttributes: { label: { fieldName: 'escSubject' }, tooltip: 'Go to Escalation Record', target: '_blank' }
        },
        {
            label: 'Status',
            fieldName: 'escStatus',
            type: 'text',
            wrapText: true
        },
        {
            label: 'Severity',
            fieldName: 'escSeverity',
            type: 'text',
            wrapText: true
        },
        {
            label: 'Owner',
            fieldName: 'escOwnerName',
            type: 'text',
            wrapText: true
        },
        {
            label: 'Created',
            fieldName: 'escCreated',
            type: 'text',
            wrapText: true
        },
        {
            label: 'Closed',
            fieldName: 'escClosed',
            type: 'text',
            wrapText: true
        },

    ];

const taskColumns = 
[
    {
        label:'Subject',
        fieldName:'taskUrl', 
        type: 'url', 
        typeAttributes: 
        { label:{ fieldName: 'subject'},tooltip: 'Go to Task', target: '_blank' },
        cellAttributes:{alignment:'left'},
        wrapText: true,
        initialWidth: 200
    },
    {
        label: 'Status',
        fieldName: 'status',
        type: 'text',
        wrapText: true,
        hideDefaultActions: true,
        initialWidth: 155,
        cellAttributes: {class: { fieldName:'taskStatusColour' } }
    },
    {
        label: 'Comments',
        fieldName: 'taskDescription',
        type: 'text',
        wrapText: true
        //,initialWidth: 500
    },
    {
        label: 'Assigned To',
        fieldName: 'assignedToName',
        type: 'text',
        wrapText: true,
        hideDefaultActions: true,
        initialWidth: 180
    },
    {
        label: 'Shift',
        fieldName: 'assignedShift',
        type: 'text',
        wrapText: true,
        hideDefaultActions: true,
        initialWidth: 120
    },
    {
        label: 'Due In/Completed DateTime',
        fieldName: 'dueIn',
        type: 'text',
        wrapText: true,
        initialWidth: 180,
        cellAttributes: {class: { fieldName:'taskColour' } }
    }, 
];



export default class ScSecurityServicesCases extends NavigationMixin(LightningElement)
{
    // VARIABLES
    caseColumns = caseColumns;
    displayCase = true;
    savedFilter = false;

    caseData = [];
    allTaskData = [];
    allTaskDataCopy = [];
    caseDataCopy = [];
    caseDataToUse = [];

    @api caseDataRecd = [];

    selectedRecords = [];
    error;
    placeholderText = 'Loading Cases! Hang tight...';

    showEditModal = false;
    showNewTaskModal = false;
    showEscModal = false;
    showNewEscModal = false;
    showShiftOwnerSpinner = false;
    showViewTaskModal = false;

    totalCases = 0;
    caseRecordId;
    caseRecordTypeId = '';
    taskRecordTypeId = '';
    extTeamRecTypeId = '';

    caseSearchText = '';

    loadEscSpinner = false;
    loadSpinner = false;
    loadModalSpinner = false;

    escData = []; escDataCount = true;
    escColumns = escColumns;
    escCaseAKAMId = '';
    caseAKAMId = '';
    accountAKAMId = '';//Added by Aditi for ESESP-3947

    taskData = [];
    taskColumns = taskColumns;

    shiftOwnerCaseId = '';
    showShiftOwnerModal = false;
    selectedRows = [];
    selectedCaseIDs = new Set();

    sortBy = 'caseUrl';
    sortDirection = 'asc';

    @api recordId;
    @api objectApiName;

    // incoming parameters
    sevSelected;
    prioritySelected;

    casesSelectedCount = 0;

    userName = '';
    userError = '';

    myCases = false;
    unassignedCases = false;

    showUnassigned;
    showMy;

    timeoutId;

    objectInfo;

    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    objectInfo;

    onaUserId;

    /*
        @wire(getRecord, { recordId: 'm122f0000004CRH', fields: ['SC_Utility__mdt.MasterLabel', 'SC_Utility__mdt.DeveloperName', 'SC_Utility__mdt.Value_Text__c'] })
        metadatarecord({error, data}) 
        {
            if(data) 
            {
                let currentData = data.fields;
                this.onaUserId = currentData.Value_Text__c.value;
                console.log('ONA : ' + this.onaUserId);
            } 
            else if(error) {
                window.console.log('error ====> '+JSON.stringify(error))
            } 
        }
    */

    /* ******************************* OWNER NOT ASSIGNED ID ******************************* */
    @wire(getOwnerNotAssignedId)
    getOwnerId({ error, data }) {
        if (data) {
            this.onaUserId = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.onaUserId = undefined;
        }
    }

    /* ******************************* LOGGED IN USER DETAILS ******************************* */
    @wire(getRecord, {
        recordId: USER_ID,
        fields: [USER_NAME]
    }) wireuser({
        error,
        data
    }) {
        if (error) {
            console.log('usererror');
            this.userError = error;
        }
        else if (data) {
            this.userName = data.fields.Name.value;
        }
    }

    /* ******************************* CONNECTED CALLBACK ******************************* */
    
    /*connectedCallback() 
    {
    }
    
    disconnectedCallback() 
    {
        window.removeEventListener('test', this.handleTest);
    }

    handleTest = () => {};
    */

    /* ******************************* CASES RECEIVED FROM HOMESCREEN ******************************* */

    @api
    calledFromParent(caseDataRecd,taskDataRecd) {
        //this.loadSpinner = true;
        this.caseData = caseDataRecd;
        this.allTaskData = taskDataRecd;
        this.allTaskDataCopy = taskDataRecd;
        this.caseDataCopy = caseDataRecd;
        this.caseDataToUse = caseDataRecd;
        let myCaseIdArray = [];

        this.totalCases = caseDataRecd.length;
        if (this.totalCases === 0) {
            this.showData = false;
        }

        console.log('CURRENT selectedCaseIDs : ' + this.selectedCaseIDs.size);

        /*
        this.selectedCaseIDs = [];
        let selectedCaseRows = this.template.querySelector('lightning-datatable').getSelectedRows();
        selectedCaseRows.forEach(element => 
        {   
            this.selectedRows.push(element.caseId);
        });
        */
        if (this.selectedCaseIDs.size > 0)
            this.selectedRows = this.selectedCaseIDs;

        this.secServTaskRecTypeId();
        this.extTeamEscRecTypeId();

        if (this.template.querySelector('.unassignedBox').checked) {
            let tableCaseDataCopy = this.caseSearchText ? this.caseDataCopy : this.caseData;
            let tempArray = [];
            console.log('unassigned');
            tableCaseDataCopy.forEach(function (eachRow) {
                if (!eachRow.shiftOwner) {
                    tempArray.push(eachRow);
                }
            });
            this.caseDataCopy = tempArray;
        }

        if (this.template.querySelector('.myBox').checked) {
            let tableCaseDataCopy = this.caseSearchText ? this.caseDataCopy : this.caseData;
            let tempArray = []; let name = this.userName;let tempTaskArray = [];
            console.log('my');
            tableCaseDataCopy.forEach(function (eachRow) {
                if (eachRow.shiftOwner) {
                    if (eachRow.shiftOwner === name) {
                        myCaseIdArray.push(eachRow.akamCaseId);
                        tempArray.push(eachRow);
                    }
                }
            });

            this.allTaskData.forEach(function(eachTaskRow){ 
                myCaseIdArray.forEach(function(eachCaseAKAMId) { 
                    if(eachCaseAKAMId === eachTaskRow.relatedCaseAKAMId){
                        tempTaskArray.push(eachTaskRow);
                    }
                });
            });
            this.allTaskDataCopy = tempTaskArray;
            this.caseDataCopy = tempArray;
        }
        util.fire('enableMyTasks', this.allTaskDataCopy);
        this.totalCases = this.caseDataCopy.length;
        this.sortData(this.sortBy, this.sortDirection);
        if (this.caseSearchText) {
            this.searchCases();
        }

        console.log('displayCase : ' + this.displayCase);

        let x = this.template.querySelector(".panelCase");
        if(this.displayCase)
        {
            if (this.totalCases <= 5)
                x.style.height = "35vh";
            else
                x.style.height = "70vh";
        }
        
        this.loadSpinner = false;
        /*
            let sev = String(caseSev);
            let priority = String(casePriority);
            
            let tempArray = [];
            let red = 0; let yellow = 0;

            this.caseData.forEach(eachCase => 
            {
                if(sev.includes(eachCase.severity) && (priority.includes(eachCase.priorityType) || priority.toUpperCase() === 'ALL'))
                {
                    tempArray.push(eachCase);
                    if(eachCase.caseColour === 'red')
                        red++;
                    else if(eachCase.caseColour === 'yellow')
                        yellow++;
                }
            });
            
            this.caseDataCopy = tempArray;
            this.totalCases = tempArray.length;
            const caseEvent = new CustomEvent("caseevent", 
            {
                detail: {redCount: red, yellowCount: yellow}
            });
            this.dispatchEvent(caseEvent);
        */

    }

    /* ******************************* POPULATE CASES ******************************* */
    /*
        populateCases()
        {
            getCaseList()
                .then(result => 
                {
                    console.log('getCaseList');
                    this.caseData = result;
                    this.caseDataCopy = result;
                    this.caseDataToUse = result;

                    this.error = undefined;
                    this.totalCases = result.length;
                    if(this.totalCases === 0)
                    {
                        this.showData = false;
                    }
                    this.sortData(this.sortBy, this.sortDirection);
                    if(this.caseSearchText)
                    {
                        this.searchCases();
                    }
                    if(this.selectedCaseIDs.length > 0)
                        this.selectedRows = this.selectedCaseIDs;

                })
                .catch(error => 
                {
                    this.error = error;
                    this.caseData = undefined;
                    this.caseDataCopy = undefined;
                    this.caseDataToUse = undefined;
                    this.loadSpinner = false;
                });
        }
    */


    /* ******************************* REFRESH DASHBOARD ******************************* */
    refreshCaseTable() {
        //this.loadSpinner = true;
        //this.populateCases();
        const caseEvent = new CustomEvent("caseevent", {});
        this.dispatchEvent(caseEvent);
    }

    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    objectInfo;

    /* ******************************* GET PS RECORD TYPE ID ******************************* */
    get recordTypeId() {
        const recTypeMapInfo = this.objectInfo.data.recordTypeInfos;
        this.caseRecordTypeId = Object.keys(recTypeMapInfo).find(rti => recTypeMapInfo[rti].name === 'Professional Services');
        return this.caseRecordTypeId;
    }

    /* ******************************* GET S2ET ACTIVITY TASK RECORD TYPE ID ******************************* */
    secServTaskRecTypeId() {
        returnRecTypeId({ sObjName: 'Task', recTypeName: '24PS' })
            .then(result => {
                this.taskRecordTypeId = result;
            })
            .catch(error => {
                this.error = error;
            });
    }

    /* ******************************* GET EXTERNAL TEAM ESCALATION RECORD TYPE ID ******************************* */
    extTeamEscRecTypeId() {
        returnRecTypeId({ sObjName: 'Engagement_Request__c', recTypeName: 'External Team' })
            .then(result => {
                this.extTeamRecTypeId = result;
            })
            .catch(error => {
                this.error = error;
            });
    }

    /*
        newCasePage() 
        {
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: 'Case',
                    actionName: 'new'
                },
            });
        }
    */

    /* ******************************* DATATABLE ROW ACTIONS ******************************* */

    handleRowAction(event) {
        let actionName = event.detail.action.name;
        let row = event.detail.row;
        this.caseRecordId = row.caseId;
        this.caseAKAMId = row.akamCaseId;
        this.accountAKAMId = row.accountAKAMId;//Added by Aditi for ESESP-3947

        if (actionName === 'edit') {
            this.openModal();
        }
        else if (actionName === 'newTask') {
            //this.showNewTaskModal = true;
            this.navigateToNewTaskPage();
        }
        else if (actionName === 'newEsc') {
            this.showNewEscModal = true;
            //this.navigateToNewEscPage();
        }
        else if (actionName === 'escCount') {
            //this.showEscModal = true;
            this.escCaseAKAMId = this.caseAKAMId;
            this.openEscModal();
            getEscalationRecs()
            {
                getEscalationRecs({ caseId: this.caseRecordId })
                    .then(result => {
                        this.escData = result;
                        this.escDataCount = result.length > 0 ? true : false;
                        this.error = undefined;
                    })
                    .catch(error => {
                        this.error = error;
                        this.escData = undefined;
                    });
            }
        }
        else if(actionName === 'viewTask')
        {
            this.showViewTaskModal = true;
            getAllTaskRecs() 
            {
                getAllTaskRecs({ caseId: this.caseRecordId })
                    .then(result => {
                        this.taskData = result;
                        this.error = undefined;
                    })
                    .catch(error => {
                        this.error = error;
                        this.taskData = undefined;
                    });
            }
        }
        else if (actionName === 'accAction') { //Added by Aditi for ESESP-3947 -added this block to perform action on ACC button click in the cases section on dashboard
            //this.showNewTaskModal = true;
            this.navigateToLUNASite();
        }
        //alert(actionName + ' : ' + this.editModal);
    }

    handleSubmit() {
        this.loadModalSpinner = true;
        //this.loadSpinner = true;
    }

    handleSuccess() {
        console.log('enter handleSucess');
        const toastEvt = new ShowToastEvent({
            title: "",
            message: "Case updated!",
            variant: "success",
            mode: "dismissible",
            duration: 5000
        });
        this.dispatchEvent(toastEvt);
        this.loadModalSpinner = false;
        this.closeModal();
        this.refreshCaseTable();
    }

    handleError() {
        console.log('enter handleError');
        this.loadModalSpinner = false;
    }

    /* ******************************* CHANGE SHIFT OWNER METHODS ******************************* */

    handleSubmitShiftOwner(event) {
        console.log('entered handleSubmitShiftOwner');
        event.preventDefault();
        this.showShiftOwnerSpinner = true;
        let shiftOwnerVal = this.template.querySelector('.shiftOwnerInput').value;

        let lstCaseRecs = [];
        let selectedCases = this.template.querySelector('lightning-datatable').getSelectedRows();

        selectedCases.forEach(function (eachCase) {
            //lstCaseRecs.push(eachCase.caseRec);
            lstCaseRecs.push(eachCase.caseId);
            //this.selectedCaseIDs.push(eachCase.caseId);
        });

        changeShiftOwner({ lstCaseIDs: lstCaseRecs, shiftOwnerId: shiftOwnerVal })
            .then(result => {
                console.log('entered success changeShiftOwner');
                this.handleSucessShiftOwner();
            })
            .catch(error => {
                console.log('entered error changeShiftOwner : ' + JSON.stringify(error));
                this.handleErrorShiftOwner(error.body);
            });
    }

    handleClearShiftOwner(event) {
        console.log('entered handleClearShiftOwner');
        event.preventDefault();
        this.showShiftOwnerSpinner = true;

        let lstCaseRecs = [];
        let selectedCases = this.template.querySelector('lightning-datatable').getSelectedRows();

        selectedCases.forEach(function (eachCase) {
            //lstCaseRecs.push(eachCase.caseRec);
            lstCaseRecs.push(eachCase.caseId);
        });

        changeShiftOwner({ lstCaseIDs: lstCaseRecs, shiftOwnerId: '' })
            .then(result => {
                console.log('entered success changeShiftOwner');
                this.handleSucessShiftOwner();
            })
            .catch(error => {
                console.log('entered error changeShiftOwner : ' + JSON.stringify(error));
                this.handleErrorShiftOwner(error.body);
            });
    }

    handleSucessShiftOwner() {
        console.log('entered handleSucessShiftOwner');
        this.showShiftOwnerSpinner = false;
        this.showShiftOwnerModal = false;
        this.selectedRows = [];
        let shiftOwnerButton = this.template.querySelector('.changeOwnerButton');
        shiftOwnerButton.disabled = true;
        const toastEvt = new ShowToastEvent({
            title: "",
            message: "Shift Owner updated!",
            variant: "success",
            mode: "dismissible",
            duration: 5000
        });
        this.dispatchEvent(toastEvt);
        this.refreshCaseTable();
    }

    handleErrorShiftOwner(errormessage) {
        //console.log('entered handleErrorShiftOwner' + event.detail.message);
        this.showShiftOwnerSpinner = false;
        //this.showShiftOwnerModal = false;
        const toastEvt = new ShowToastEvent({
            "title": "Error",
            "message": errormessage.message,
            "variant": "error",
            "mode": "sticky",
            "duration": 10000
        });
        this.dispatchEvent(toastEvt);
        console.log(errormessage.message);
        //this.selectedRows = [];
        //this.refreshCaseTable();
    }

    closeShiftOwnerModal() {
        this.showShiftOwnerModal = false;
    }

    openShiftOwnerPopup() {
        this.showShiftOwnerModal = true;
    }

    /* ******************************* CASE INLINE EDIT METHODS ******************************* */

    openModal() {
        this.showEditModal = true;
    }

    closeModal() {
        this.showEditModal = false;
    }

    /* ******************************* VIEW + CREATE ESCALATION METHODS ******************************* */

    closeNewEscModal() {
        this.showNewEscModal = false;
    }

    handleSubmitEsc() {
        this.loadEscSpinner = true;
    }

    handleErrorEsc() {
        this.loadEscSpinner = false;
    }

    handleSuccessEsc() {
        this.showNewEscModal = false;
        this.loadEscSpinner = false;
        this.refreshCaseTable();
    }

    closeEscModal() {
        this.escData = [];
        this.showEscModal = false;
        this.escDataCount = true;
    }

    closeViewTaskModal() {
        this.taskData = [];
        this.showViewTaskModal = false;
    }

    /* ******************************* SEARCH METHODS ******************************* */
    clearSearchInput() {
        this.template.querySelector('.labelHidden').value = '';
        this.searchCases();
    }

    delayedSearch(event) {
        clearTimeout(this.timeoutId); // no-op if invalid id
        this.timeoutId = setTimeout(this.searchCases.bind(this), 500); // Adjust as necessary
    }

    searchCases() {
        //console.log(event.detail.value);
        let allCaseData = this.caseData;
        let myCaseIdArray = [];
        //let searchFilter = event.detail.value;
        let searchFilter = this.template.querySelector('.labelHidden').value;
        this.caseSearchText = this.template.querySelector('.labelHidden').value;

        searchFilter = searchFilter.toUpperCase();

        //this.caseSearchText = searchFilter;

        let tempArray = [];
        let tempTaskArray = [];
        allCaseData.forEach(function (eachRow) {
            //console.log(eachRow[i].subject);
            if ((eachRow.subject && eachRow.subject.toUpperCase().indexOf(searchFilter) !== -1)
                || (eachRow.accountName && eachRow.accountName.toUpperCase().indexOf(searchFilter) !== -1)
                || (eachRow.service && eachRow.service.toUpperCase().indexOf(searchFilter) !== -1)
                || (eachRow.shiftOwner && eachRow.shiftOwner.toUpperCase().indexOf(searchFilter) !== -1)
                || (eachRow.lastUpdatedBy && eachRow.lastUpdatedBy.toUpperCase().indexOf(searchFilter) !== -1)
                || (eachRow.akamCaseId && eachRow.akamCaseId.toUpperCase().indexOf(searchFilter) !== -1)
                || (eachRow.parentCaseAKAMId && eachRow.parentCaseAKAMId.toUpperCase().indexOf(searchFilter) !== -1)
                || (eachRow.caseStatus && eachRow.caseStatus.toUpperCase().indexOf(searchFilter) !== -1)
            ) {
                tempArray.push(eachRow);
            }
        });

        this.caseDataCopy = tempArray;
        this.totalCases = tempArray.length;
        console.log('Post Search Length : ' + this.totalCases);

        if (this.template.querySelector('.unassignedBox').checked) {
            let tableCaseDataCopy = this.caseDataCopy;
            tempArray = [];
            console.log('unassigned');
            tableCaseDataCopy.forEach(function (eachRow) {
                if (!eachRow.shiftOwner) {
                    tempArray.push(eachRow);
                }
            });
            this.caseDataCopy = tempArray;
        }

        if (this.template.querySelector('.myBox').checked) {
            let tableCaseDataCopy = this.caseDataCopy;
            tempArray = []; let name = this.userName;
            console.log('my');
            tableCaseDataCopy.forEach(function (eachRow) {
                if (eachRow.shiftOwner) {
                    if (eachRow.shiftOwner === name) {
                        tempArray.push(eachRow);
                        myCaseIdArray.push(eachRow.akamCaseId);
                    }
                }
            });
            this.allTaskData.forEach(function(eachTaskRow){ 
                myCaseIdArray.forEach(function(eachCaseAKAMId) { 
                    if(eachCaseAKAMId === eachTaskRow.relatedCaseAKAMId){
                        tempTaskArray.push(eachTaskRow);
                    }
                });
            });
            this.allTaskDataCopy = tempTaskArray;
            this.caseDataCopy = tempArray;
        }
        util.fire('enableMyTasks', this.allTaskDataCopy);
        this.totalCases = this.caseDataCopy.length;

        let x = this.template.querySelector(".panelCase");
        if (this.totalCases <= 5)
            x.style.height = "35vh";
        else
            x.style.height = "70vh";

        if (searchFilter === '')
            this.sortData(this.sortBy, this.sortDirection);

        console.log('In Search : ' + this.selectedCaseIDs.length);
        if (this.selectedCaseIDs.size > 0)
            this.selectedRows = this.selectedCaseIDs;
    }


    /* ******************************* DATATABLE ROW SELECTION ******************************* */
    casesSelected() {
        let selectRows = this.template.querySelector('lightning-datatable').getSelectedRows();

        let shiftOwnerButton = this.template.querySelector('.changeOwnerButton');
        if (selectRows.length > 0) {
            shiftOwnerButton.disabled = false;
            this.shiftOwnerCaseId = selectRows[0].caseId;
            selectRows.forEach(element => {
                this.selectedCaseIDs.add(element.caseId);
            });
        }
        else
            shiftOwnerButton.disabled = true;
        console.log('Selected Cases : ' + this.selectedCaseIDs.size);
    }

    /* ******************************* NEW TASK METHODS ******************************* */
    openNewTaskModal() {
        this.showEditModal = true;
    }

    closeNewTaskModal() {
        this.showEditModal = false;
    }

    openEscModal() {
        this.showEscModal = true;
    }

    /* ******************************* SORTING METHODS ******************************* */
    updateColumnSorting(event) {
        var fieldName = event.detail.fieldName;
        var sortDirection = event.detail.sortDirection;

        this.sortBy = fieldName;
        this.sortDirection = sortDirection;

        this.sortData(fieldName, sortDirection);
        //helper.sortData(component, fieldName, sortDirection);
    }

    sortData(fieldname, direction) {
        console.log('In Sort : ' + fieldname + ' ' + direction);
        if (fieldname === 'lastUpdatedDateTimeString')
            fieldname = 'lastUpdatedMins';
        else if (fieldname === 'hotCustomer')
            fieldname = 'casePriorityNum';
        else if (fieldname === 'caseUrl')
            fieldname = 'caseColourNum';
        else if (fieldname === 'parentCaseUrl')
            fieldname = 'parentCaseAKAMId';
        else if (fieldname === 'accountUrl')
            fieldname = 'accountName';
        else if (fieldname === 'shiftOwnerUrl')
            fieldname = 'shiftOwner';
        else if (fieldname === 'lastUpdatedByUrl')
            fieldname = 'lastUpdatedBy';


        let parseData = JSON.parse(JSON.stringify(this.caseDataCopy));
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
        this.caseDataCopy = parseData;
    }

    /*
        copyToClipboard()
        {
            console.log('HELLO');
            let tableText = this.template.querySelector('.datatableStyle');
            //let objString = JSON.parse(JSON.stringify(tableText));
            //console.log(objString);
            //let tableText = document.getElementById('#dt');
            console.log(tableText);
            tableText.select();
            tableText.setSelectionRange(0,999999);
            document.execCommand('copy');
        }
    */

    /* ******************************* TOGGLE CASE TABLE METHODS ******************************* */
    toggleCaseTable() {
        this.displayCase = !this.displayCase;
    }

    showCaseTable() {
        let x = this.template.querySelector(".panelCase");
        if (this.totalCases <= 5)
            x.style.height = "35vh";
        else
            x.style.height = "70vh";
        //x.style.height = "70vh";
        this.displayCase = !this.displayCase;
    }

    hideCaseTable() {
        var x = this.template.querySelector(".panelCase");
        x.style.height = "0vh";
        this.displayCase = !this.displayCase;
    }

    /* ******************************* NEW TASK METHODS ******************************* */
    recordPageUrl;

    navigateToNewTaskPage() 
    {
        const toastEvt = new ShowToastEvent({
            title: "Security Due Date Time in UTC",
            message: "Please enter Security Due Date Time in UTC",
            variant: "warning",
            mode: "dismissible",
            duration: 15000
        });
        
        let setFields = "WhatId=" + this.caseRecordId + ',OwnerId=' + this.onaUserId;
        this[NavigationMixin.Navigate]({
            type: "standard__objectPage",
            attributes: {
                objectApiName: "Task",
                actionName: "new"
            },
            state: {
                recordTypeId: this.taskRecordTypeId,
                defaultFieldValues: setFields
            }
        });
        this.dispatchEvent(toastEvt);
        
        //this.timeoutId = setTimeout(this.test.bind(this), 3000);

        /*
        this[NavigationMixin.GenerateUrl]({
            type: "standard__objectPage",
            attributes: {
                objectApiName: "Task",
                actionName: "new"
            },
            state: {
                recordTypeId: this.taskRecordTypeId,
                defaultFieldValues: setFields
            }
        })
            .then(url => {
                window.open(url, '_blank');
            });
        */
    }
    /*

    callback(mutationList, observer) 
    {
        console.log('REMOVED!');
    }
    
    test()
    {
        let targetNode = this.template.querySelector(".uiModal");
        console.log('TARET : ' + targetNode);
        let observerOptions = {
          childList: true,
          attributes: true,
          subtree: true //Omit or set to false to observe only changes to the parent node.
        }
        
        let observer = new MutationObserver(this.callback);
        observer.observe(targetNode, observerOptions);
    }
    */

    /* ******************************* NEW ESCALATION METHOD ******************************* */
    navigateToNewEscPage() {
        //let setFields = "CaseId=" + this.caseRecordId;
        this[NavigationMixin.Navigate]({
            type: "standard__objectPage",
            attributes: {
                objectApiName: "Engagement_Request__c",
                actionName: "new"
            },
            state: {
                recordTypeId: this.extTeamRecTypeId,
                //defaultFieldValues: setFields
            }
        });
    }

    /* ******************************* MY/UNASSIGNED CASES METHODS ******************************* */
    toggleChecked(event) {
        let tempArray = [];
        let tempTaskArray = [];
        let myCaseIdArray = [];

        this.loadSpinner = true;

        let tableCaseDataCopy = this.caseSearchText ? this.caseDataCopy : this.caseData;//this.caseData;
        let name = this.userName;
        console.log('Detail Name : ' + JSON.stringify(event.target) + '::' + event.detail.checked);

        if (!event.target.checked) {
            this.caseDataCopy = this.caseData;
            if (event.target.name === 'my') {
                tableCaseDataCopy.forEach(function (eachRow) {
                    myCaseIdArray.push(eachRow.akamCaseId);
                });
                this.allTaskDataCopy = this.allTaskData;
            }
        }
        else {
            if (event.target.name === 'unassigned') {
                tableCaseDataCopy.forEach(function (eachRow) {
                    if (!eachRow.shiftOwner) {
                        tempArray.push(eachRow);
                    }
                });
                this.allTaskDataCopy = this.allTaskData;
                console.log('temp length : ' + tempArray.length);
                this.template.querySelector('.myBox').checked = false;
            }
            else {
                tableCaseDataCopy.forEach(function (eachRow) {
                    if (eachRow.shiftOwner) {
                        if (eachRow.shiftOwner === name) {
                            tempArray.push(eachRow);
                            myCaseIdArray.push(eachRow.akamCaseId);
                        }
                    }
                });
                this.allTaskData.forEach(function(eachTaskRow){ 
                    myCaseIdArray.forEach(function(eachCaseAKAMId) { 
                        if(eachCaseAKAMId === eachTaskRow.relatedCaseAKAMId){
                            tempTaskArray.push(eachTaskRow);
                        }
                    });
                });
                this.allTaskDataCopy = tempTaskArray;
                console.log('temp length : ' + tempArray.length);
                this.template.querySelector('.unassignedBox').checked = false;
            }
            this.caseDataCopy = tempArray;
        }
        util.fire('enableMyTasks', this.allTaskDataCopy);
        this.sortData(this.sortBy, this.sortDirection);
        if (this.caseSearchText) {
            this.searchCases();
        }

        this.totalCases = this.caseDataCopy.length;
        let x = this.template.querySelector(".panelCase");
        if (this.totalCases <= 5)
            x.style.height = "35vh";
        else
            x.style.height = "70vh";
        this.loadSpinner = false;
    }

    //Added by Aditi for ESESP-3947 - method to navigate to url when ACC button is clicked on cases section on the dashboard, just like LUNA button of Cases
    navigateToLUNASite() {
        var url = 'https://control.akamai.com/apps/securitycenter/#/web-security-analytics?accountId='+this.accountAKAMId+'&startTime=-1h';//for prod and uat
        //var url = 'https://control.cloud-sqa-shared.akamai.com/apps/securitycenter/#/web-security-analytics?accountId='+this.accountAKAMId+'&startTime=-1h';//for QA
        window.open(url, "_blank");
    }

}