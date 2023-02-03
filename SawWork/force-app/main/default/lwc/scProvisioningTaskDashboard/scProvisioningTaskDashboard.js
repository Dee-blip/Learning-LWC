/* eslint-disable no-console */
/* eslint-disable no-alert */
/*eslint(@lwc/lwc/no-async-operation)*/

import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import USER_ID from '@salesforce/user/Id';
import USER_NAME from '@salesforce/schema/User.Name';

// apex classes
import changeTaskAssignedTo from '@salesforce/apex/SC_ProvisioningDashboard_Controller.changeTaskAssignedTo';
import assignShiftToTask from '@salesforce/apex/SC_ProvisioningDashboard_Controller.assignTaskShift';
import changeStatus from '@salesforce/apex/SC_ProvisioningDashboard_Controller.changeStatus';

const taskColumns =
    [
        {
            label: 'AKAM Case ID',
            fieldName: 'caseUrl',
            type: 'url',
            typeAttributes:
                { label: { fieldName: 'relatedCaseAKAMId' }, tooltip: 'Go to Case', target: '_blank' },
            sortable: true,
            initialWidth: 125,
            cellAttributes: { alignment: 'left' }
        },
        {
            label: 'Account',
            fieldName: 'accountUrl',
            type: 'url',
            typeAttributes:
                { label: { fieldName: 'relatedCaseAccountName' }, tooltip: 'Go to Account', target: '_blank' },
            sortable: true,
            initialWidth: 125,
            cellAttributes: { alignment: 'left' },
            wrapText: true
        },
        {
            label: 'Subject',
            fieldName: 'taskUrl',
            type: 'url',
            typeAttributes:
                { label: { fieldName: 'subject' }, tooltip: 'Go to Task', target: '_blank' },
            sortable: true,
            cellAttributes: { alignment: 'left' },
            wrapText: true
        },
        {
            label: 'Type',
            fieldName: 'taskType',
            type: 'text',
            initialWidth: 150,
            sortable: true
        },
        {
            label: 'Assigned To',
            fieldName: 'assignedToUrl',
            type: 'url',
            typeAttributes:
                { label: { fieldName: 'assignedToName' }, tooltip: 'Go to User', target: '_blank' },
            sortable: true,
            initialWidth: 150,
            cellAttributes: { alignment: 'left' },
            wrapText: true
        },
        {
            label: 'Assigned Shift',
            fieldName: 'assignedShift',
            type: 'text',
            initialWidth: 150,
            sortable: true
        },
        {
            label: 'Status',
            fieldName: 'status',
            type: 'text',
            initialWidth: 125,
            sortable: true
        },
        {
            label: 'Priority',
            fieldName: 'taskPriority',
            type: 'text',
            initialWidth: 125,
            sortable: true
        },
        {
            label: 'Due In',
            fieldName: 'dueIn',
            initialWidth: 100,
            type: 'text',
            sortable: true,
            cellAttributes: { class: { fieldName: 'taskColour' } }

        },
        {
            label: 'Last Updated',
            fieldName: 'lastUpdatedDateTimeString',
            type: 'text',
            sortable: true,
            initialWidth: 150,
            wrapText: true
        },
        {
            type: 'button-icon',
            typeAttributes: {
                iconName: 'utility:edit',
                name: 'edit',
                title: 'Edit',
                variant: 'container',
                alternativeText: 'Edit',
                disabled: false
            },
            initialWidth: 10
        }
    ];

export default class ScProvisioningTaskDashboard extends NavigationMixin(LightningElement)
{
    error;
    userName;

    allTasks = [];
    taskDataCopy = [];
    selectedRows = [];

    displayTask = true;
    showAssignedToModal = false;
    showAssignShiftModal = false;
    showStatusModal = false;
    assignedToSpinner = false;
    assignShiftSpinner = false;
    statusSpinner = false;
    loadSpinner = true;

    taskAssignedToId = '';
    taskRecId = '';
    taskSearchText = '';
    totalTasks = 0;
    taskColumns = taskColumns;

    sortBy = 'dueIn';
    sortDirection = 'asc';

    taskSearchText = '';
    timeoutId;

    /*
    assignShiftSelected = 'AMER First';
    get assignShiftVal() {
        return [
            { label: 'AMER First', value: 'AMER First' },
            { label: 'AMER Second', value: 'AMER Second' },
            { label: 'AMER Third', value: 'AMER Third' }
        ];
    }
    */

   assignShiftSelected = 'First';
   get assignShiftVal() {
       return [
           { label: 'First', value: 'First' },
           { label: 'Second', value: 'Second' },
           { label: 'Third', value: 'Third' }
       ];
   }

    assignShiftChange(event) {
        this.assignShiftSelected = event.detail.value;
    }

    taskStatusSelected = 'Not Started';
    get taskStatusVal() {
        return [
            { label: 'Unassigned', value: 'Unassigned' },
            { label: 'Not Started', value: 'Not Started' },
            { label: 'In Progress', value: 'In Progress' },
            { label: 'Deferred', value: 'Deferred' },
            { label: "Completed", value: "Completed" },
            { label: 'Not Applicable', value: 'Not Applicable' },
            { label: "Failed", value: "Failed" },
        ];
    }

    taskStatusChange(event) {
        this.taskStatusSelected = event.detail.value;
    }

    /* ******************************* GET LOGGED IN USER DETAILS ******************************* */
    @wire(getRecord, {
        recordId: USER_ID,
        fields: [USER_NAME]
    }) wireuser({
        error,
        data
    }) {
        if (error) {
            console.log('USER ERROR : ' + this.userError)
            this.userError = error;
        }
        else if (data) {
            this.userName = data.fields.Name.value;
        }
    }

    /* ******************************* CONNECTED CALLBACK ******************************* */
    /*connectedCallback() 
    {
        //window.addEventListener('test', this.handleTest);
        //loadStyle(this, SC_SProvisioning_Stylesheet);
        //this.populateTasks();
    }
    disconnectedCallback() 
    {
        //window.removeEventListener('test', this.handleTest);
    }*/

    /* ******************************* TASKS RECEIVED FROM HOMESCREEN ******************************* */
    @api
    calledFromParent(taskDataRecd) {
        this.loadSpinner = true;
        this.allTasks = taskDataRecd;
        this.taskDataCopy = taskDataRecd;
        this.error = undefined;
        this.totalTasks = taskDataRecd.length;

        /*if(this.selectedTaskIDs.size > 0){
            this.selectedRows = this.selectedTaskIDs;
        }*/

        if (this.totalTasks === 0) {
            this.displayTask = false;
        }

        if (this.template.querySelector('.unassignedBox').checked) {
            let tableTaskDataCopy = this.taskSearchText ? this.taskDataCopy : this.allTasks;
            let tempArray = [];
            tableTaskDataCopy.forEach(function (eachRow) {
                if (eachRow.assignedToName === 'Owner Not Assigned') {
                    tempArray.push(eachRow);
                }
            });
            this.taskDataCopy = tempArray;
        }

        if (this.template.querySelector('.myBox').checked) {
            let tableTaskDataCopy = this.taskSearchText ? this.taskDataCopy : this.allTasks;
            let tempArray = []; let name = this.userName;
            tableTaskDataCopy.forEach(function (eachRow) {
                if (eachRow.assignedToName === name) {
                    tempArray.push(eachRow);
                }
            });
            this.taskDataCopy = tempArray;
        }
        this.totalTasks = this.taskDataCopy.length;

        this.sortData(this.sortBy, this.sortDirection);
        if (this.taskSearchText) {
            this.searchTasks();
        }

        if (this.displayTask) {
            this.displayTask = true;
            let x = this.template.querySelector(".panelTask");
            if (this.totalTasks <= 5)
                x.style.height = "35vh";
            else
                x.style.height = "70vh";
        }

        this.loadSpinner = false;
    }

    /* ******************************* TOGGLE TASK DATATABLE ******************************* */
    toggleTaskTable() {
        this.displayTask = !this.displayTask;
    }

    showTaskTable() {
        var x = this.template.querySelector(".panelTask");
        //x.style.height = "70vh";
        
        if(this.totalTasks <= 5)
            x.style.height = "35vh";
        else
            x.style.height = "70vh";
        
        this.displayTask = !this.displayTask;
    }

    hideTaskTable() {
        var x = this.template.querySelector(".panelTask");
        x.style.height = "0vh";
        this.displayTask = !this.displayTask;
    }

    /* ******************************* SEARCH TASK DATATABLE ******************************* */
    delayedSearch() {
        clearTimeout(this.timeoutId); // no-op if invalid id
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.timeoutId = setTimeout(this.searchTasks.bind(this), 500); // Adjust as necessary
    }

    searchTasks() {
        let allTaskData = this.allTasks;
        let searchFilter = this.template.querySelector('.labelHidden').value;
        this.taskSearchText = this.template.querySelector('.labelHidden').value;

        searchFilter = searchFilter.toUpperCase();

        let tempArray = [];
        allTaskData.forEach(function (eachRow) {
            if ((eachRow.subject && eachRow.subject.toUpperCase().indexOf(searchFilter) !== -1)
                || (eachRow.assignedToName && eachRow.assignedToName.toUpperCase().indexOf(searchFilter) !== -1)
                || (eachRow.taskType && eachRow.taskType.toUpperCase().indexOf(searchFilter) !== -1)
                || (eachRow.shiftOwner && eachRow.shiftOwner.toUpperCase().indexOf(searchFilter) !== -1)
                || (eachRow.assignedShift && eachRow.assignedShift.toUpperCase().indexOf(searchFilter) !== -1)
                || (eachRow.relatedCaseAKAMId && eachRow.relatedCaseAKAMId.toUpperCase().indexOf(searchFilter) !== -1)
                || (eachRow.relatedCaseAccountName && eachRow.relatedCaseAccountName.toUpperCase().indexOf(searchFilter) !== -1)
                || (eachRow.status && eachRow.status.toUpperCase().indexOf(searchFilter) !== -1)
                || (eachRow.taskPriority && eachRow.taskPriority.toUpperCase().indexOf(searchFilter) !== -1)
            ) {
                tempArray.push(eachRow);
            }
        });

        this.taskDataCopy = tempArray;
        this.totalTasks = tempArray.length;

        if (this.template.querySelector('.unassignedBox').checked) 
        {
            //let tableTaskDataCopy = this.taskSearchText ? this.taskDataCopy : this.taskData;
            let tableTaskDataCopy = this.taskDataCopy;
            tempArray = [];
            tableTaskDataCopy.forEach(function (eachRow) {
                if (eachRow.assignedToName === 'Owner Not Assigned') {
                    tempArray.push(eachRow);
                }
            });
            this.taskDataCopy = tempArray;
        }

        if (this.template.querySelector('.myBox').checked) {
            //let tableTaskDataCopy = this.taskSearchText ? this.taskDataCopy : this.taskData;
            let tableTaskDataCopy = this.taskDataCopy;
            tempArray = []; let name = this.userName;
            tableTaskDataCopy.forEach(function (eachRow) {
                if (eachRow.assignedToName === name) {
                    tempArray.push(eachRow);
                }
            });
            this.taskDataCopy = tempArray;
        }
        this.totalTasks = this.taskDataCopy.length;
        this.calculatetaskpaginationlogic();
        let x = this.template.querySelector(".panelTask");
        if(this.totalTasks <= 5) 
            x.style.height = "35vh";
        else
            x.style.height = "70vh";
        if (searchFilter === '')
            this.sortData(this.sortBy, this.sortDirection);
    }

    /* ******************************* CLEAR SEARCH METHOD ******************************* */
    clearSearchInput() {
        this.template.querySelector('.labelHidden').value = '';
        this.searchTasks();
    }

    /* ******************************* REFRESH DASHBOARD ******************************* */
    refreshTaskTable() {
        const taskEvent = new CustomEvent("taskevent", {});
        this.dispatchEvent(taskEvent);
    }

    /* ******************************* SORTING METHODS ******************************* */
    updateColumnSorting(event) {
        var fieldName = event.detail.fieldName;
        var sortDirection = event.detail.sortDirection;
        this.sortBy = fieldName;
        this.sortDirection = sortDirection;
        this.sortData(fieldName, sortDirection);
    }

    sortData(fieldname, direction) {
        if (fieldname === 'dueIn')
            fieldname = 'dueInMins';
        else if (fieldname === 'lastUpdatedDateTimeString')
            fieldname = 'lastUpdatedMins';
        else if (fieldname === 'caseUrl')
            fieldname = 'relatedCaseAKAMId'
        else if (fieldname === 'accountUrl')
            fieldname = 'relatedCaseAccountName'
        else if (fieldname === 'taskUrl')
            fieldname = 'subject'
        else if (fieldname === 'assignedToUrl')
            fieldname = 'assignedToName'

        let parseData = JSON.parse(JSON.stringify(this.taskDataCopy));
        // Return the value stored in the field
        let keyValue = (a) => 
        {
            if(typeof a[fieldname] === 'string')
            {
                return (a[fieldname].toLowerCase());
            }
            else 
            {
                return (a[fieldname]);
            }
        };
        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1 : -1;
        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';
            // sorting values based on direction
            //return isReverse *  ((x > y) - (y > x))
            let r;
            if (fieldname === 'dueInMins') {
                if (isReverse === 1) {
                    r = (y === '') - (x === '') || ((x > y) - (y > x));
                }
                if (isReverse === -1) {
                    r = (y === '') - (x === '') || ((y > x) - (x > y));
                }
            }
            else {
                r = isReverse * ((x > y) - (y > x))
            }
            return r;
        });
        this.taskDataCopy = parseData;
        this.calculatetaskpaginationlogic();
    }

    /* ******************************* TASK SELECTION ******************************* */
    tasksSelected() {
        let selectRows = this.template.querySelector('lightning-datatable').getSelectedRows();
        let taskOwnerButton = this.template.querySelector('.changeOwnerButton');
        let assignShiftButton = this.template.querySelector('.assignShiftButton');
        let taskStatusButton = this.template.querySelector('.changeStatusButton');

        if (selectRows.length > 0) {
            taskOwnerButton.disabled = false;
            assignShiftButton.disabled = false;
            taskStatusButton.disabled = false;
            this.taskAssignedToId = selectRows[0].relatedCaseId;

            if(selectRows.length === 50)
            {
                console.log('Max Records');
                const toastEvt = new ShowToastEvent({
                    title: "",
                    message: "You have reached the maximum selection of 50 records",
                    variant: "warning",
                    mode: "dismissible",
                    duration: 5000
                });
                this.dispatchEvent(toastEvt);
            }
        }
        else {
            taskOwnerButton.disabled = true;
            assignShiftButton.disabled = true;
            taskStatusButton.disabled = true;
        }
    }

    /* ******************************* OPEN/CLOSE MODALS ******************************* */
    openAssignedToPopup() {
        this.showAssignedToModal = true;
    }
    openAssignShiftPopup() {
        this.showAssignShiftModal = true;
    }
    openStatusPopup() {
        this.showStatusModal = true;
    }

    closeAssignedToModal() {
        this.showAssignedToModal = false;
    }
    closeAssignShiftPopup() {
        this.showAssignShiftModal = false;
    }
    closeStatusModal() {
        this.showStatusModal = false;
    }

    onSubmitAssignedTo(event) {
        event.preventDefault();
        this.assignedToSpinner = true;
    }

    handleSuccess(successMessage) {
        let taskOwnerButton = this.template.querySelector('.changeOwnerButton');
        let assignShiftButton = this.template.querySelector('.assignShiftButton');
        let taskStatusButton = this.template.querySelector('.changeStatusButton');
        taskOwnerButton.disabled = true;
        assignShiftButton.disabled = true;
        taskStatusButton.disabled = true;


        const toastEvt = new ShowToastEvent({
            title: "",
            message: successMessage,
            variant: "success",
            mode: "dismissible",
            duration: 5000
        });
        this.dispatchEvent(toastEvt);
    }

    handleError(errorMessage) {
        const toastEvt = new ShowToastEvent({
            title: "Error!",
            message: errorMessage,
            variant: "error",
            mode: "dismissible",
            duration: 5000
        });
        this.dispatchEvent(toastEvt);
    }

    /* ******************************* CHANGE TASK STATUS METHODS ******************************* */
    handleSubmitStatus(event) {
        event.preventDefault();
        this.statusSpinner = true;
        let statusVal = this.taskStatusSelected;

        let lstTaskRecs = [];
        let selectedTasks = this.template.querySelector('lightning-datatable').getSelectedRows();

        selectedTasks.forEach(function (eachTask) {
            lstTaskRecs.push(eachTask.taskId);
        });

        changeStatus({ lstTaskIDs: lstTaskRecs, status: statusVal })
            .then(result => {
                console.log('RESULT : ' + result);
                this.statusSpinner = false;
                this.showStatusModal = false;

                this.selectedRows = [];
                this.handleSuccess('Task Status updated');
                this.refreshTaskTable();
            })
            .catch(error => {
                console.log('ERROR : ' + error);
                let customError = 'An Error Occurred While Updating : ';
                customError += error.body.message;

                /*if(error.body.pageErrors[0] !== undefined && error.body.pageErrors[0].message !== undefined){
                    customError =  error.body.pageErrors[0].message
                }*/

                this.error = error;
                this.statusSpinner = false;
                this.showStatusModal = false;

                //this.selectedRows = [];
                this.handleError(customError);
                this.refreshTaskTable();
            });
    }

    /* ******************************* CHANGE ASSIGNED TO METHODS ******************************* */
    handleSubmitAssignedTo(event) {
        event.preventDefault();
        this.assignedToSpinner = true;
        let newAssignedTo = this.template.querySelector('.assignedToInput').value;
        let selectRows = this.template.querySelector('lightning-datatable').getSelectedRows();
        let lstTaskRecs = [];
        selectRows.forEach(function (eachTask) {
            lstTaskRecs.push(eachTask.taskId)
        })

        changeTaskAssignedTo({ lstTaskIDs: lstTaskRecs, assignedToId: newAssignedTo })
            .then(result => {
                console.log('RESULT : ' + result);

                let resMssg; let resErrorRows = [];
                console.log(typeof result);
                if(result !== '')
                {
                    resMssg = JSON.parse(result);
                    console.log(resMssg);
                    console.log(resMssg.mssg);
                    //this.handleError('The rows selected have errored. ' + resMssg.mssg); 
                    let msg = 'The rows selected have errored. ' + resMssg.mssg;
                    const toastEvt = new ShowToastEvent({
                        title: "Error!",
                        message: msg,
                        variant: "error",
                        mode: "dismissible",
                        duration: 10000
                    });
                    this.dispatchEvent(toastEvt);
                    resErrorRows = JSON.parse(resMssg.set);
                    this.selectedRows = resErrorRows;
                    console.log(resErrorRows.length);
                }   
                else
                {
                    this.selectedRows = [];
                    this.handleSuccess('Assigned To updated');
                }
                this.refreshTaskTable();
                this.assignedToSpinner = false;
                this.showAssignedToModal = false;
            })
            .catch(error => {
                console.log('ERROR : ' + error);
                let customError = 'An Error Occurred While Updating : ';
                customError += error.body.message;

                /*if(error.body.pageErrors[0] !== undefined && error.body.pageErrors[0].message !== undefined){
                    customError =  error.body.pageErrors[0].message
                }*/

                this.error = error;
                this.assignedToSpinner = false;
                this.showAssignedToModal = false;

                //this.selectedRows = [];
                this.handleError(customError);
                this.refreshTaskTable();
            })
    }

    /* ******************************* CLEAR ASSIGNED TO METHODS ******************************* */
    handleClearAssignedTo(event) {
        event.preventDefault();
        this.assignedToSpinner = true;
        let selectRows = this.template.querySelector('lightning-datatable').getSelectedRows();
        let lstTaskRecs = [];
        selectRows.forEach(function (eachTask) {
            lstTaskRecs.push(eachTask.taskId)
        })

        changeTaskAssignedTo({ lstTaskIDs: lstTaskRecs, assignedToId: '' })
            .then(result => {
                console.log('RESULT : ' + result);

                let resMssg; let resErrorRows = [];
                console.log(typeof result);
                if(result !== '')
                {
                    resMssg = JSON.parse(result);
                    console.log(resMssg);
                    console.log(resMssg.mssg);
                    //this.handleError('The rows selected have errored. ' + resMssg.mssg); 
                    let msg = 'The rows selected have errored. ' + resMssg.mssg;
                    const toastEvt = new ShowToastEvent({
                        title: "Error!",
                        message: msg,
                        variant: "error",
                        mode: "dismissible",
                        duration: 10000
                    });
                    this.dispatchEvent(toastEvt);
                    resErrorRows = JSON.parse(resMssg.set);
                    this.selectedRows = resErrorRows;
                    console.log(resErrorRows.length);
                }   
                else
                {
                    this.selectedRows = [];
                    this.handleSuccess('Assigned To updated');
                }
                this.refreshTaskTable();
                this.assignedToSpinner = false;
                this.showAssignedToModal = false;
            })
            .catch(error => {
                console.log('ERROR : ' + error);
                let customError = 'An Error Occurred While Updating : ';
                customError += error.body.message;

                /*if(error.body.pageErrors[0] !== undefined && error.body.pageErrors[0].message !== undefined){
                    customError =  error.body.pageErrors[0].message
                }*/

                this.error = error;
                this.assignedToSpinner = false;
                this.showAssignedToModal = false;

                //this.selectedRows = [];
                this.handleError(customError);
                this.refreshTaskTable();
            })
    }

    /* ******************************* ASSIGN SHIFT METHODS ******************************* */
    handleAssignShiftSubmit(event) {
        event.preventDefault();
        this.assignShiftSpinner = true;
        let newAssignedTo = this.assignShiftSelected;
        let selectRows = this.template.querySelector('lightning-datatable').getSelectedRows();
        let lstTaskRecs = [];
        selectRows.forEach(function (eachTask) {
            lstTaskRecs.push(eachTask.taskId)
        })

        assignShiftToTask({ taskIdList: lstTaskRecs, shift: newAssignedTo })
            .then(result => {
                console.log('RESULT : ' + result);
                this.assignShiftSpinner = false;
                this.showAssignShiftModal = false;

                this.selectedRows = [];
                this.handleSuccess('Assigned Shift updated');
                this.refreshTaskTable();
            })
            .catch(error => {
                console.log('ERROR : ' + error);
                let customError = 'An Error Occurred While Updating : ';
                customError += error.body.message;

                /*if(error.body.pageErrors[0] !== undefined && error.body.pageErrors[0].message !== undefined){
                    customError =  error.body.pageErrors[0].message
                }*/

                this.error = error;
                this.assignShiftSpinner = false;
                this.showAssignShiftModal = false;

                //this.selectedRows = [];
                this.handleError(customError);
                this.refreshTaskTable();
            })
    }

    /* ******************************* ROW ACTION ON TASK DATATABLE ******************************* */
    handleRowAction(event) {
        let row = event.detail.row;
        this.taskRecId = row.taskId;
        this.navigateToEditTaskPage();
        this.refreshTaskTable();
    }

    /* ******************************* EDIT TASK ******************************* */
    navigateToEditTaskPage() {
        this[NavigationMixin.Navigate]({
            type: "standard__objectPage",
            attributes: {
                recordId: this.taskRecId,
                objectApiName: "Task",
                actionName: "edit"
            }
        });
    }

    /* ******************************* MY/OWNER NOT ASSIGNED TASKS TOGGLE ******************************* */
    toggleChecked(event) {
        this.loadSpinner = true;
        let tempArray = [];

        let tableTaskDataCopy = this.allTasks;
        let name = this.userName;

        if (!event.target.checked) {
            this.taskDataCopy = this.allTasks;
        }
        else {
            if (event.target.name === 'unassigned') {
                tableTaskDataCopy.forEach(function (eachRow) {
                    if (eachRow.assignedToName === 'Owner Not Assigned') {
                        tempArray.push(eachRow);
                    }
                });
                this.template.querySelector('.myBox').checked = false;
            }
            else {
                tableTaskDataCopy.forEach(function (eachRow) {
                    if (eachRow.assignedToName === name) {
                        tempArray.push(eachRow);
                    }
                });
                this.template.querySelector('.unassignedBox').checked = false;
            }
            this.taskDataCopy = tempArray;
        }
        this.totalTasks = this.taskDataCopy.length;

        this.sortData(this.sortBy, this.sortDirection);
        if (this.taskSearchText) {
            this.searchTasks();
        }
        let x = this.template.querySelector(".panelTask");
        if (this.totalTasks <= 5)
            x.style.height = "35vh";
        else
            x.style.height = "70vh";
        this.loadSpinner = false;
    }

    offset = 1;
    paginationNumbers;
    SlicedDatalist;
    currentpage;

    handlePaginationClick(event) 
    {
        var t0 = performance.now();
        let page = event.target.dataset.item;
        this.offset=page;
        this.SlicedDatalist = this.taskDataCopy.slice((this.offset - 1) * 50, this.offset * 50);
        this.currentpage=this.offset+'/'+this.paginationNumbers;

        var t1 = performance.now();
        console.log("------------>Pagination took " + (t1 - t0) + " milliseconds to execute.")
     }

    calculatetaskpaginationlogic()
    {
        if(this.totalTasks === 0)
        {
            this.paginationNumbers = 1;
        }
        else
        {
            this.paginationNumbers = Math.ceil(this.totalTasks / 50);
        }
        
        if(this.offset>this.paginationNumbers) this.offset=1;
        
        this.currentpage=this.offset+'/'+this.paginationNumbers;
        this.paginationRange = [];
        for (var i = 1; i <= this.paginationNumbers; i++) {
            this.paginationRange.push(i);
        }
        this.SlicedDatalist = this.taskDataCopy.slice((this.offset - 1) * 50, this.offset * 50);
    }
}