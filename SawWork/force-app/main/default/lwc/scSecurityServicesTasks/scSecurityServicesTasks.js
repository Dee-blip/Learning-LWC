/* eslint-disable no-console */
/* eslint-disable no-alert */

import { LightningElement,wire,api } from 'lwc';

// apex classes
import getTaskList from '@salesforce/apex/SC_SecurityServices_Ctrlr.getTaskList';
import changeAssignedTo from '@salesforce/apex/SC_SecurityServices_Ctrlr.changeAssignedTo';
import changeStatus from '@salesforce/apex/SC_SecurityServices_Ctrlr.changeStatus';
import deferTasks from '@salesforce/apex/SC_SecurityServices_Ctrlr.deferTasks';

import { ShowToastEvent } from "lightning/platformShowToastEvent";

import { loadStyle } from 'lightning/platformResourceLoader';
import cssStyleSheet from "@salesforce/resourceUrl/SC_S2ET_Stylesheet";

import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import USER_NAME from '@salesforce/schema/User.Name';

import util from 'c/scUtil' ;

const taskColumns = 
[
    {
        label:'AKAM Case ID',
        fieldName:'caseUrl', 
        type: 'url', 
        typeAttributes: 
        { label:{ fieldName: 'relatedCaseAKAMId'},tooltip: 'Go to Case', target: '_blank' },
        sortable: true, 
        initialWidth: 125,
        cellAttributes:{alignment:'left'}
    },
    {
        label:'Account',
        fieldName:'accountUrl', 
        type: 'url', 
        typeAttributes: 
        { label:{ fieldName: 'relatedCaseAccountName'},tooltip: 'Go to Account', target: '_blank'},
        sortable: true, 
        initialWidth: 125,
        cellAttributes:{alignment:'left'},
        wrapText: true
    },
    {
        label:'Subject',
        fieldName:'taskUrl', 
        type: 'url', 
        typeAttributes: 
        { label:{ fieldName: 'subject'},tooltip: 'Go to Task', target: '_blank' },
        sortable: true, 
        cellAttributes:{alignment:'left'},
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
        label:'Assigned To',
        fieldName:'assignedToUrl', 
        type: 'url', 
        typeAttributes: 
        { label:{ fieldName: 'assignedToName'},tooltip: 'Go to User', target: '_blank' },
        sortable: true, 
        initialWidth: 150,
        cellAttributes:{alignment:'left'},
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
        label: 'Due In',
        fieldName: 'dueIn',
        initialWidth: 100,
        type: 'text',
        sortable: true,
        cellAttributes: {class: { fieldName:'taskColour' } }

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


export default class ScSecurityServicesTasks extends NavigationMixin(LightningElement)
{
    error;
    taskData = [];
    taskDataCopy = [];
    displayTask = true;
    taskRecId = '';

    totalTasks = 0;
    taskColumns = taskColumns;
    loadSpinner = false;

    sortBy = 'dueIn';
    sortDirection = 'asc';

    showAssignedToModal = false;
    assignedToSpinner = false;

    showStatusModal = false;
    statusSpinner = false;
    showDeferModal = false;


    taskSearchText = '';

    userName;
    assignedToTaskId = '';
    tasksSelectedCount = 0;
    selectedRows = [];
    selectedTaskIDs = [];
    //showEditTaskModal = false;


    taskStatusSelected = 'Not Started';
    taskDeferSelected = '1';

    myCaseTasks = [];
    myTaskAkamCases = [];
    savedFilter = false;

    get taskStatusVal() {
        return [
            { label: "Not Started", value: "Not Started" },
            { label: "In Progress", value: "In Progress" },
            { label: "Completed", value: "Completed" },
            { label: "Deferred", value: "Deferred" },
            { label: "Cancelled", value: "Cancelled" }
        ];
    }

    get taskDeferVal() {
        return [
            { label: "1", value: "1" },
            { label: "2", value: "2" },
            { label: "4", value: "4" },
            { label: "8", value: "8" },
            { label: "24", value: "24" }
        ];
    }

    taskStatusChange(event)
    {
        this.taskStatusSelected = event.detail.value;
    }

    taskDeferChange(event)
    {
        this.taskDeferSelected = event.detail.value;
    }
    
    // fetch Tasks
    /*
        @wire(getTaskList)
        dataReceived(result) 
        {
            this.refreshTable = result;
            if (result.data) 
            {
                this.taskData = result.data;
                //console.log(this.taskData);
                this.error = undefined;
                this.totalTasks = result.data.length;
                this.loadSpinner = false;
                if(this.totalTasks === 0)
                {
                    this.showData = false;
                }
            } else if (result.error) 
            {
                this.error = result.error;
                this.taskData = undefined;
            }
        }
    */

    /* ******************************* GET LOGGED IN USER DETAILS ******************************* */
    @wire(getRecord, {
        recordId: USER_ID,
        fields: [USER_NAME]
    }) wireuser({
        error,
        data
    }) {
        if(error) 
        {
            console.log('usererror');
            this.userError = error ; 
        } 
        else if (data) 
        {
            this.userName = data.fields.Name.value;
        }
    }

    /* ******************************* CONNECTED CALLBACK ******************************* */
    connectedCallback() 
    {
        this.setMyTasks();
        
    }
    setMyTasks(){
        util.register('enableMyTasks', this.handleMyTaskEvent.bind(this));
    }

    handleMyTaskEvent(myTasks){
        this.calledFromParent(myTasks);
    }

    disconnectedCallback() 
    {
        window.removeEventListener('test', this.handleTest);
    }
    handleTest = () => {};

    /* ******************************* GET TASKS ******************************* */
    /*
        populateTasks()
        {
            getTaskList()
                .then(result => 
                {
                    this.taskData = result;
                    this.taskDataCopy = result;
                    this.error = undefined;
                    this.totalTasks = result.length;
                    this.sortData(this.sortBy, this.sortDirection);
                    if(this.taskSearchText)
                    {
                        this.searchTasks();
                    }

                    let overdue=0;
                    this.taskData.forEach(eachTask => 
                    {
                        if(eachTask.taskColour === 'red')
                        overdue++;
                    });
                    const taskEvent = new CustomEvent("taskevent", 
                    {
                        detail: {overdueCount: overdue}
                    });
                    this.dispatchEvent(taskEvent);
                    this.loadSpinner = false;
                })
                .catch(error => 
                {
                    this.error = error;
                    this.taskData = undefined;
                    this.taskDataCopy = undefined;
                    this.loadSpinner = false;
                });
        }
    */

    /* ******************************* REFRESH DASHBOARD ******************************* */
    refreshTaskTable()
    {
        const taskEvent = new CustomEvent("taskevent", 
        {
        });
        this.dispatchEvent(taskEvent);
    }

    /* ******************************* TASKS RECEIVED FROM HOMESCREEN ******************************* */
    @api
    calledFromParent(taskDataRecd)
    {
        this.loadSpinner = true;
        this.taskData = taskDataRecd;
        this.taskDataCopy = taskDataRecd;
        this.error = undefined;
        this.totalTasks = taskDataRecd.length;

        if(this.taskSearchText)
        {
            this.searchTasks();
        }
        if(this.selectedTaskIDs.length > 0)
            this.selectedRows = this.selectedTaskIDs;

        if(this.template.querySelector('.unassignedBox').checked)
        {
            let tableTaskDataCopy = this.taskSearchText ? this.taskDataCopy : this.taskData;
            let tempArray = [];
            console.log('unassigned');
            tableTaskDataCopy.forEach(function(eachRow)
            {
                if(eachRow.assignedToName === 'Owner Not Assigned')
                {
                    tempArray.push(eachRow);
                }
            });
            this.taskDataCopy = tempArray;
        }
        
        if(this.template.querySelector('.myBox').checked)
        {
            let tableTaskDataCopy = this.taskSearchText ? this.taskDataCopy : this.taskData;
            let tempArray = [];let name = this.userName;
            console.log('my');
            tableTaskDataCopy.forEach(function(eachRow)
            {
                if(eachRow.assignedToName === name)
                {
                    tempArray.push(eachRow);
                }
            });
            this.taskDataCopy = tempArray;
        }

        this.totalTasks = this.taskDataCopy.length;

        this.sortData(this.sortBy,this.sortDirection);
        if(this.taskSearchText)
        {
            this.searchTasks();
        }
        
        console.log('displayTask : ' + this.displayTask);
        if(this.displayTask)
        {
            let x = this.template.querySelector(".panelTask");
            if (this.totalTasks <= 5)
                x.style.height = "35vh";
            else
                x.style.height = "70vh";
        }

        this.loadSpinner = false;
        
        /*
        let shift = String(taskShift);
        let status = String(taskStatus);
        console.log(shift,status);
        let tempArray = [];
        let overdue=0;
        this.taskData.forEach(eachTask => 
        ]
            if((shift.toUpperCase() === 'ALL' || shift.includes(eachTask.assignedShift)) 
            && (status.includes(eachTask.status) || status.toUpperCase() === 'ALL'))
            {
                tempArray.push(eachTask);
                if(eachTask.taskColour === 'red')
                    overdue++;
            }
        });
        
        this.taskDataCopy = tempArray;
        this.taskData = tempArray;

        this.totalTasks = tempArray.length;
        const taskEvent = new CustomEvent("taskevent", 
        {
            detail: {overdueCount: overdue}
        });
        this.dispatchEvent(taskEvent);
        */
    }

    /* ******************************* ROW ACTION ON TASK DATATABLE ******************************* */
    handleRowAction(event) 
    {
        let row = event.detail.row;
        this.taskRecId = row.taskId;
        this.navigateToEditTaskPage();
        //this.showEditTaskModal = true;
    }

    /* ******************************* CHANGE ASSIGNED TO METHODS ******************************* */
    openAssignedToPopup()
    {
        this.showAssignedToModal = true;
    }

    closeAssignedToModal()
    {
        this.showAssignedToModal = false;
    }

    onSubmitAssignedTo(event)
    {
        event.preventDefault();
        this.assignedToSpinner = true;
    }


    handleSubmitAssignedTo(event)
    {
        console.log('entered handleSubmitAssignedTo');
        console.log(JSON.stringify(event.target));
        event.preventDefault();
        this.assignedToSpinner = true;
        let shiftOwnerVal = this.template.querySelector('.shiftOwnerInput').value;
        
        let lstTaskRecs = [];
        let selectedTasks = this.template.querySelector('lightning-datatable').getSelectedRows();
        
        selectedTasks.forEach(function(eachTask)
        {
            //lstTaskRecs.push(eachTask.taskRec);
            lstTaskRecs.push(eachTask.taskId);
        });

        changeAssignedTo({ lstTaskIDs: lstTaskRecs, assignedToId: shiftOwnerVal })
            .then(result => {
                console.log('entered success handleSubmitAssignedTo');
                this.handleSuccessAssignedTo();
            })
            .catch(error => {
                console.log('entered error handleSubmitAssignedTo' + JSON.stringify(error));
                this.handleErrorAssignedTo(error.body);
            });
    }

    handleClearAssignedTo(event)
    {
        console.log('entered handleClearAssignedTo');
        event.preventDefault();
        //this.showShiftOwnerSpinner = true;
        this.assignedToSpinner = true;
        
        let lstTaskRecs = [];
        let selectedTasks = this.template.querySelector('lightning-datatable').getSelectedRows();
        
        selectedTasks.forEach(function(eachTask)
        {
            //lstTaskRecs.push(eachTask.taskRec);
            lstTaskRecs.push(eachTask.taskId);
        });

        changeAssignedTo({ lstTaskIDs: lstTaskRecs, assignedToId: ''})
            .then(result => {
                console.log('entered success handleClearAssignedTo');
                this.handleSuccessAssignedTo();
            })
            .catch(error => 
                {
                    console.log('entered error handleSubmitAssignedTo' + JSON.stringify(error));
                    this.handleErrorAssignedTo(error.body);
            });
    }

    handleSuccessAssignedTo()
    {
        console.log('entered handleSucessShiftOwner');
        this.assignedToSpinner = false;
        this.showAssignedToModal = false;
        this.selectedRows = [];
        let assignedToButton = this.template.querySelector('.changeAssignedToButton');
        let statusButton = this.template.querySelector('.changeStatusButton');
        let deferButton = this.template.querySelector('.deferTaskButton');
        assignedToButton.disabled = true;
        statusButton.disabled = true;
        deferButton.disabled = true;
        const toastEvt = new ShowToastEvent({
            title: "",
            message: "Task Owner updated!",
            variant: "success",
            mode: "dismissible",
            duration: 5000
        });
        this.dispatchEvent(toastEvt);
        this.refreshTaskTable();
    }

    handleErrorAssignedTo(errormessage)
    {
        console.log('entered handleErrorShiftOwner');
        this.assignedToSpinner = false;
        const toastEvt = new ShowToastEvent({
            "title": "Error",
            "message": errormessage.message,
            "variant": "error",
            "mode": "sticky",
            "duration": 10000
        });
        this.dispatchEvent(toastEvt);
        console.log(errormessage.message);
        //this.showAssignedToModal = false;
        //this.selectedRows = [];
        //this.refreshTaskTable();
    }

    /* ******************************* CHANGE STATUS METHODS ******************************* */
    openStatusPopup()
    {
        this.showStatusModal = true;
    }

    closeStatusModal()
    {
        this.showStatusModal = false;
    }

    handleSubmitStatus(event)
    {
        console.log('entered handleSubmitStatus');
        event.preventDefault();
        this.statusSpinner = true;
        let statusVal = this.taskStatusSelected;
        
        let lstTaskRecs = [];
        let selectedTasks = this.template.querySelector('lightning-datatable').getSelectedRows();
        
        selectedTasks.forEach(function(eachTask)
        {
            //lstTaskRecs.push(eachTask.taskRec);
            lstTaskRecs.push(eachTask.taskId);
        });

        changeStatus({ lstTaskIDs: lstTaskRecs, status: statusVal })
            .then(result => {
                console.log('entered success handleSubmitStatus');
                this.handleSuccessStatus();
            })
            .catch(error => {
                console.log('entered error handleSubmitStatus ' + JSON.stringify(error));
                this.handleErrorStatus(error.body);
            });
    }

    handleSuccessStatus()
    {
        console.log('entered handleSuccessStatus');
        this.statusSpinner = false;
        this.showStatusModal = false;
        let assignedToButton = this.template.querySelector('.changeAssignedToButton');
        let statusButton = this.template.querySelector('.changeStatusButton');
        let deferButton = this.template.querySelector('.deferTaskButton');
        assignedToButton.disabled = true;
        statusButton.disabled = true;
        deferButton.disabled = true;
        this.selectedRows = [];
        
        this.refreshTaskTable();
        const toastEvt = new ShowToastEvent({
            title: "",
            message: "Task Status updated!",
            variant: "success",
            mode: "dismissible",
            duration: 5000
        });
        this.dispatchEvent(toastEvt);
    }

    handleErrorStatus(errormessage)
    {
        console.log('entered handleErrorStatus');
        this.statusSpinner = false;
        this.showStatusModal = false;
        const toastEvt = new ShowToastEvent({
            title: "Error!",
            message: errormessage.message,
            variant: "error!",
            mode: "sticky",
            duration: 5000
        });
        this.dispatchEvent(toastEvt);
        //this.selectedRows = [];
        //this.refreshTaskTable();
    }

    /* ******************************* DEFER METHODS ******************************* */
    openDeferPopup()
    {
        this.showDeferModal = true;
    }

    closeDeferModal()
    {
        this.showDeferModal = false;
    }

    handleSubmitDefer(event)
    {
        console.log('entered handleSubmitDefer');
        event.preventDefault();
        this.statusSpinner = true;
        let deferVal = this.taskDeferSelected;
        
        let lstTaskRecs = [];
        let selectedTasks = this.template.querySelector('lightning-datatable').getSelectedRows();
        
        selectedTasks.forEach(function(eachTask)
        {
            //lstTaskRecs.push(eachTask.taskRec);
            lstTaskRecs.push(eachTask.taskId);
        });

        deferTasks({ lstTaskIDs: lstTaskRecs, defer: deferVal })
            .then(result => {
                this.handleSuccessDefer();
            })
            .catch(error => {
                this.handleErrorDefer(error.body);
            });
    }

    handleSuccessDefer()
    {
        console.log('entered handleSuccessDefer');
        this.statusSpinner = false;
        this.showDeferModal = false;
        let assignedToButton = this.template.querySelector('.changeAssignedToButton');
        let statusButton = this.template.querySelector('.changeStatusButton');
        let deferButton = this.template.querySelector('.deferTaskButton');
        assignedToButton.disabled = true;
        statusButton.disabled = true;
        deferButton.disabled = true;
        this.selectedRows = [];
        
        this.refreshTaskTable();
        const toastEvt = new ShowToastEvent({
            title: "",
            message: "Task(s) Deferred!",
            variant: "success",
            mode: "dismissible",
            duration: 5000
        });
        this.dispatchEvent(toastEvt);
    }

    handleErrorDefer(errormessage)
    {
        console.log('entered handleErrorDefer : ' + errormessage);
        this.statusSpinner = false;
        this.showDeferModal = false;
        const toastEvt = new ShowToastEvent({
            title: "Error!",
            message: errormessage.message,
            variant: "error!",
            mode: "sticky",
            duration: 5000
        });
        this.dispatchEvent(toastEvt);
        //this.selectedRows = [];
        //this.refreshTaskTable();
    }
    
    /* ******************************* EDIT TASK ******************************* */
    navigateToEditTaskPage() 
    {
        const toastEvt = new ShowToastEvent({
            title: "Security Due Date Time in UTC",
            message: "Please enter Security Due Date Time in UTC",
            variant: "warning",
            mode: "dismissible",
            duration: 15000
        });
        
        
        this[NavigationMixin.Navigate]({
          type: "standard__recordPage",
          attributes: {
            recordId: this.taskRecId,
            objectApiName: "Task",
            actionName: "edit"
          }
        });
        this.dispatchEvent(toastEvt);

        //let a = this.template.querySelector('.forceActionButton');
        
        //let urlVal = '/lightning/r/Task/' + this.taskRecId + '/edit';
        //window.open(urlVal, '_blank');

        /*
        this[NavigationMixin.GenerateUrl]({
            type: "standard__recordPage",
            attributes: {
                recordId: this.taskRecId,
                objectApiName: "Task",
                actionName: "view"
            }
        })
        .then(url => {
            
            this[NavigationMixin.Navigate]({
                type: "standard__recordPage",
                attributes: {
                  recordId: this.taskRecId,
                  objectApiName: "Task",
                  actionName: "edit"
                }
              });
        });*/
        //.then(result => { console.log(result); window.open(result, '_blank')});
    }

    /* ******************************* TASK SELECTION ******************************* */
    tasksSelected()
    {
        let selectRows = this.template.querySelector('lightning-datatable').getSelectedRows();
        
        let assignedToButton = this.template.querySelector('.changeAssignedToButton');
        let statusButton = this.template.querySelector('.changeStatusButton');
        let deferButton = this.template.querySelector('.deferTaskButton');
        
        if(selectRows.length > 0)
        {
            assignedToButton.disabled = false;
            statusButton.disabled = false;
            deferButton.disabled = false;
            this.assignedToTaskId = selectRows[0].relatedCaseId;
        }
        else
        {
            assignedToButton.disabled = true;
            statusButton.disabled = true;
            deferButton.disabled = true;
        }
    }

    /* ******************************* SORTING METHODS ******************************* */
    updateColumnSorting(event)
    {
        var fieldName = event.detail.fieldName;
        var sortDirection = event.detail.sortDirection;
        this.sortBy = fieldName;
        this.sortDirection = sortDirection;
        
        this.sortData(fieldName, sortDirection);
        //helper.sortData(component, fieldName, sortDirection);
    }

    sortData(fieldname, direction) 
    {
        console.log('In Task Sort : ' + fieldname + ' ' + direction);
        if(fieldname === 'dueIn')
            fieldname = 'dueInMins';
        else if(fieldname === 'lastUpdatedDateTimeString')
            fieldname = 'lastUpdatedMins';
        else if(fieldname === 'caseUrl')
            fieldname = 'relatedCaseAKAMId'
        else if(fieldname === 'accountUrl')
            fieldname = 'relatedCaseAccountName'
        else if(fieldname === 'taskUrl')
            fieldname = 'subject'
        else if(fieldname === 'assignedToUrl')
            fieldname = 'assignedToName'
           
        let parseData = JSON.parse(JSON.stringify(this.taskDataCopy));
        // Return the value stored in the field
        let keyValue = (a) => 
        {
        return a[fieldname];
        };
        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1: -1;
        // sorting data
        parseData.sort((x, y) => 
        {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';
            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });
        this.taskDataCopy = parseData;
    }

    /* ******************************* SEARCH METHODS ******************************* */
    clearSearchInput()
    {
        this.template.querySelector('.labelHidden').value = '';
        this.searchTasks();
    }

    delayedSearch(event) 
    {
        clearTimeout(this.timeoutId); // no-op if invalid id
        this.timeoutId = setTimeout(this.searchTasks.bind(this), 500); // Adjust as necessary
    }

    searchTasks()
    {
        //console.log(event.detail.value);
        let allTaskData = this.taskData;

        //let searchFilter = event.detail.value;
        let searchFilter = this.template.querySelector(".labelHidden").value;
        this.taskSearchText = this.template.querySelector(".labelHidden").value;
        
        searchFilter = searchFilter.toUpperCase();

        //this.caseSearchText = searchFilter;
        
        let tempArray = [];

        //for(let i=0; i < eachRow.length; i++)
        allTaskData.forEach(function(eachRow)
        {
            //console.log(eachRow[i].subject);
            if((eachRow.subject && eachRow.subject.toUpperCase().indexOf(searchFilter) !== -1)    
              || (eachRow.assignedToName && eachRow.assignedToName.toUpperCase().indexOf(searchFilter) !== -1)
              || (eachRow.taskType && eachRow.taskType.toUpperCase().indexOf(searchFilter) !== -1)
              || (eachRow.shiftOwner && eachRow.shiftOwner.toUpperCase().indexOf(searchFilter) !== -1)
              || (eachRow.assignedShift && eachRow.assignedShift.toUpperCase().indexOf(searchFilter) !== -1)
              || (eachRow.relatedCaseAKAMId && eachRow.relatedCaseAKAMId.toUpperCase().indexOf(searchFilter) !== -1)
              || (eachRow.relatedCaseAccountName && eachRow.relatedCaseAccountName.toUpperCase().indexOf(searchFilter) !== -1)
              || (eachRow.status && eachRow.status.toUpperCase().indexOf(searchFilter) !== -1)
              )
            {
                tempArray.push(eachRow);
            }
        });
        
        this.taskDataCopy = tempArray;
        this.totalTasks = tempArray.length;

        if(this.template.querySelector('.unassignedBox').checked)
        {
            let tableTaskDataCopy = this.taskSearchText ? this.taskDataCopy : this.taskData;
            tempArray = [];
            console.log('unassigned');
            tableTaskDataCopy.forEach(function(eachRow)
            {
                if(eachRow.assignedToName === 'Owner Not Assigned')
                {
                    tempArray.push(eachRow);
                }
            });
            this.taskDataCopy = tempArray;
        }
        
        if(this.template.querySelector('.myBox').checked)
        {
            let tableTaskDataCopy = this.taskSearchText ? this.taskDataCopy : this.taskData;
            tempArray = [];let name = this.userName;
            console.log('my');
            tableTaskDataCopy.forEach(function(eachRow)
            {
                if(eachRow.assignedToName === name)
                {
                    tempArray.push(eachRow);
                }
            });
            this.taskDataCopy = tempArray;
        }
        this.totalTasks = this.taskDataCopy.length;
        let x = this.template.querySelector(".panelTask");
        if(this.totalTasks <= 5) 
            x.style.height = "35vh";
        else
            x.style.height = "70vh";

        if(searchFilter === '') 
            this.sortData(this.sortBy,this.sortDirection);
    }

    /* ******************************* TOGGLE TASL DATATABLE ******************************* */
    toggleTaskTable() 
    {
        this.displayTask = !this.displayTask;
    }

    showTaskTable()
    {
        var x = this.template.querySelector(".panelTask");
        //x.style.height = "70vh";
        if(this.totalTasks <= 5) 
            x.style.height = "35vh";
        else
            x.style.height = "70vh";
        this.displayTask = !this.displayTask;
    }

    hideTaskTable()
    {
        var x = this.template.querySelector(".panelTask");
        x.style.height = "0vh";
        this.displayTask = !this.displayTask;
    }

    /* ******************************* MY/OWNER NOT ASSIGNED TASKS TOGGLE ******************************* */
    toggleChecked(event)
    {
        this.loadSpinner = true;
        let tempArray = [];
        
        let tableTaskDataCopy = this.taskData;
        let name = this.userName;

        if(!event.target.checked)
        {
            this.taskDataCopy = this.taskData;
        }
        else
        {
            if(event.target.name === 'unassigned')
            {
                tableTaskDataCopy.forEach(function(eachRow)
                {
                    if(eachRow.assignedToName === 'Owner Not Assigned')
                    {
                        tempArray.push(eachRow);
                    }
                });
                this.template.querySelector('.myBox').checked = false;
            }
            else
            {
                tableTaskDataCopy.forEach(function(eachRow)
                {
                    if(eachRow.assignedToName === name)
                    {
                        tempArray.push(eachRow);
                    }
                });
                this.template.querySelector('.unassignedBox').checked = false;
            }
            this.taskDataCopy = tempArray;
        }
        
        this.sortData(this.sortBy, this.sortDirection);
        if(this.taskSearchText)
        {
            this.searchTasks();
        }
        this.totalTasks = this.taskDataCopy.length;
        let x = this.template.querySelector(".panelTask");
        if(this.totalTasks <= 5) 
            x.style.height = "35vh";
        else
            x.style.height = "70vh";
        this.loadSpinner = false;
    }

    /*
    closeTaskModal()
    {
        this.showEditTaskModal = false;
    }
    */
}