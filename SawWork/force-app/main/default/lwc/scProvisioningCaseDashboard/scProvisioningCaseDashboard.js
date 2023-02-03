/* eslint-disable no-console */
/* eslint-disable no-alert */

import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord } from 'lightning/uiRecordApi';

import CASE_OBJECT from '@salesforce/schema/Case';
import USER_ID from '@salesforce/user/Id';
import USER_NAME from '@salesforce/schema/User.Name';

// apex classes
import changeShiftOwner from '@salesforce/apex/SC_ProvisioningDashboard_Controller.changeShiftOwner'
import getEscalationRecs from '@salesforce/apex/SC_ProvisioningDashboard_Controller.getEscalationRecs';
import returnRecTypeId from '@salesforce/apex/SC_ProvisioningDashboard_Controller.returnRecTypeId';
import getOwnerNotAssignedId from '@salesforce/apex/SC_ProvisioningDashboard_Controller.returnONAId';
import getAllTaskRecs from '@salesforce/apex/SC_ProvisioningDashboard_Controller.getAllTaskRecs';
import changeCaseOwner from '@salesforce/apex/SC_ProvisioningDashboard_Controller.changeCaseOwner'

// row actions
    const actions = 
    [
        { label: 'Edit Case', name: 'edit'}, 
        { label: 'New Task', name: 'newTask'},
        { label: 'New Escalation', name: 'newEsc'},
        { label: 'View Tasks', name: 'viewTask'}
    ];

    const caseColumns = 
    [
        {
            label: '',
            fieldName: 'hotCustomer',
            type: 'text',
            sortable: true,
            initialWidth: 73,
            cellAttributes: { alignment: 'right',class: 'hotCustomerIcon' }
        },
        {
            label: 'AKAM Case ID',
            fieldName: 'caseUrl',
            type: 'url', 
            typeAttributes: { label: { fieldName: 'akamCaseId' },tooltip: 'Go to Case', target: '_blank'},
            sortable: true,
            initialWidth: 125,
            cellAttributes: { alignment: 'left',class: { fieldName:'caseColour' } }
        },
        {
            label: 'Account',
            fieldName: 'accountUrl',
            type: 'url',
            typeAttributes: { label: { fieldName: 'accountName' },tooltip: 'Go to Account', target: '_blank'},
            sortable: true,
            initialWidth: 115,
            cellAttributes: { alignment: 'left' },
            wrapText: true
        },
        {
            label: 'Geography',
            fieldName: 'Geography',
            type: 'text',
            sortable: true,
            /*initialWidth: 98,*/
            wrapText: true
        },
        {
            label: 'Account Tier',
            fieldName: 'accountTier',
            type: 'text',
            sortable: true,
            /*initialWidth: 98,*/
            wrapText: true
        },
       
        {
            label: 'Subject',
            fieldName: 'subject',
            type: 'text',
            sortable: true,
            /*initialWidth: 100,*/
            wrapText: true
        },
        {
            label: 'Sev',
            fieldName: 'severity',
            type: 'text',
            sortable: true,
            initialWidth: 75,
            cellAttributes: { alignment: 'center'}
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
            label: 'Request Completion Date',
            fieldName: 'requestCompletionDate',
            type: 'date',
            sortable: true,
            initialWidth: 100,
            cellAttributes: { alignment: 'left', class:{fieldName: 'completionDateColour'} }
        },
        {
            label: 'Shift Owner',
            fieldName: 'shiftOwnerUrl',
            type: 'url',
            typeAttributes: { label: { fieldName: 'shiftOwner' },tooltip: 'Go to Shift Owner', target: '_blank'},
            sortable: true,
            initialWidth: 100,
            cellAttributes: { alignment: 'left' },
            wrapText: true
        },
        {
            label: 'Sub Type',
            fieldName: 'subType',
            type: 'text',
            sortable: true,
            initialWidth: 100,
            wrapText: true
        },
        {
            label: 'Case Product',
            fieldName: 'caseProduct',
            type: 'text',
            sortable: true,
            initialWidth: 100,
            wrapText: true
        },
        {
            label: 'Project',
            fieldName: 'projectUrl',
            type: 'url',
            typeAttributes: { label: { fieldName: 'projectName' },tooltip: 'Go to Project', target: '_blank'},
            sortable: true,
            initialWidth: 85,
            cellAttributes: { alignment: 'left' },
            wrapText: true
        },
        {
            label: 'Eng',
            fieldName: 'escCount',
            type: 'button',
            typeAttributes: 
            {
                label: { fieldName: 'escCount' },
                variant:'base',
                name:'escCount'
            },
            sortable: true,
            initialWidth: 50,
            cellAttributes: { alignment: 'center', class: 'escBlueText' }
        },
        {
            label: 'Pending Tasks',
            fieldName: 'pendingTasksCount',
            type: 'number',
            sortable: true,
            initialWidth: 80,
            cellAttributes: { alignment: 'center',class:{fieldName: 'pendingTaskColour'} }
        },
        {
            label: 'Last Updated',
            fieldName: 'lastUpdatedDateTimeString',
            type: 'text',
            sortable: true,
            initialWidth: 110,
            wrapText: true
        },
        {
            label: 'Last Updated By',
            fieldName: 'lastUpdatedByUrl',
            type: 'url',
            typeAttributes: 
            { 
                label: { fieldName: 'lastUpdatedBy'},tooltip: 'Go to Last Updated By', target: '_blank',
            },
            sortable: true,
            initialWidth: 110,
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
            wrapText: true,
            typeAttributes: { label: { fieldName: 'escID' } }
        },
        {
            label: 'Subject',
            fieldName: 'escSubjectURL',
            type: 'url',
            wrapText: true,
            initialWidth: 125,
            typeAttributes: { label: { fieldName: 'escSubject' } }
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
            sortable: true, 
            cellAttributes:{alignment:'left'},
            wrapText: true
        },
        {
            label: 'Status',
            fieldName: 'status',
            type: 'text',
            wrapText: true,
            initialWidth: 155,
            cellAttributes: {class: { fieldName:'taskStatusColour' } }
        },
        {
            label: 'Comments',
            fieldName: 'taskDescription',
            type: 'text',
            wrapText: true,
            initialWidth: 500
        },
        {
            label: 'Assigned To',
            fieldName: 'assignedToName',
            type: 'text',
            wrapText: true,
            initialWidth: 180
        },
        {
            label: 'Shift',
            fieldName: 'assignedShift',
            type: 'text',
            wrapText: true,
            initialWidth: 120
        },
        {
            label: 'Due In/Completed DateTime',
            fieldName: 'dueIn',
            type: 'text',
            sortable: true,
            initialWidth: 180,
            cellAttributes: {class: { fieldName:'taskColour' } }
        },  
    ];


export default class ScProvisioningCaseDashboard extends NavigationMixin(LightningElement)
{
    caseColumns = caseColumns;
    loadSpinner = true;
    displayCase = true;
    loadModalSpinner = false;
    totalCases = 0;
    allCases = [];
    caseDataCopy = [];
    error;
    caseSearchText = '';
    sortBy = 'severity';
    sortDirection = 'asc';
    selectedRows = [];
    selectedCaseIDs = [];

    escData = [];
    taskData = [];
    caseAKAMId = '';
    escColumns = escColumns;
    taskColumns = taskColumns;
    showEditModal = false;
    //showNewTaskModal = false;
    showNewEscModal = false;
    showEscModal = false;
    showViewTaskModal = false;

    shiftOwnerCaseId = '';
    showShiftOwnerSpinner = false;
    showShiftOwnerModal = false;

    caseOwnerCaseId = '';
    showCaseOwnerSpinner = false;
    showCaseOwnerModal = false;

    objectInfo;
    caseRecordTypeId ='';
    taskRecordTypeId = '';
    extTeamRecTypeId = '';

    showUnassigned;
    showMy;
    userName = '';
    userError = '';

    onaUserId;
    timeoutId;

    @api caseDataRecd = []

    //wiring case object to get object info
    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    objectInfo;

    /* ******************************* GET PS RECORD TYPE ID ******************************* */
    get recordTypeId() 
    {
        const recTypeMapInfo = this.objectInfo.data.recordTypeInfos;
        this.caseRecordTypeId = Object.keys(recTypeMapInfo).find(rti => recTypeMapInfo[rti].name === 'Professional Services');
        return this.caseRecordTypeId;
    }

    /* ******************************* LOGGED IN USER DETAILS ******************************* */
    @wire(getRecord, {
        recordId: USER_ID,
        fields: [USER_NAME]
    }) wireuser({
        error,
        data
    }) 
    {
        if(error) {
            this.userError = error ; 
        } 
        else if (data) {
            this.userName = data.fields.Name.value;
        }
    }

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

    // CONNECTED CALLBACK
    /*connectedCallback() 
    {
        //window.addEventListener('test', this.handleTest);
        //loadStyle(this, SC_SProvisioning_Stylesheet);
        //this.populateTasks();
    }*/

    /* ******************************* OWNER NOT ASSIGNED ID ******************************* */
    @api
    calledFromParent(caseDataRecd){
        var t1=performance.now();

        this.allCases = caseDataRecd;
        this.caseDataCopy = caseDataRecd;
        this.totalCases = caseDataRecd.length;
        this.loadSpinner = true;

        if(this.totalCases === 0)
        {
            this.displayCase = false;
        }

        //if(this.selectedCaseIDs.size > 0)
            //this.selectedRows = this.selectedCaseIDs;

        this.plxTaskRecTypeId();
        this.extTeamEscRecTypeId();
       
       //var t0 = performance.now();

        if(this.template.querySelector('.unassignedBox').checked)
        {
            let tableCaseDataCopy = this.caseSearchText ? this.caseDataCopy : this.allCases;
            let tempArray = [];
            tableCaseDataCopy.forEach(function(eachRow)
            {
                if(!eachRow.shiftOwner)
                {
                    tempArray.push(eachRow);
                }
            });
            this.caseDataCopy = tempArray;
        }
       // var t1 = performance.now();
       // console.log("------------>query selector took " + (t1 - t0) + " milliseconds to execute.")

        if(this.template.querySelector('.myBox').checked)
        {
            let tableCaseDataCopy = this.caseSearchText ? this.caseDataCopy : this.allCases;
            let tempArray = [];let name = this.userName;
            tableCaseDataCopy.forEach(function(eachRow)
            {
                if(eachRow.shiftOwner)
                {
                    if(eachRow.shiftOwner === name)
                    {
                        tempArray.push(eachRow);
                    }
                }
            });
            this.caseDataCopy = tempArray;
        }
        this.totalCases = this.caseDataCopy.length;

        this.sortData(this.sortBy,this.sortDirection);
        if(this.caseSearchText){
            this.searchCases();
        }
        
        if(this.displayCase)
        {
            let x = this.template.querySelector(".panelCase");
            if (this.totalCases <= 5)
                x.style.height = "35vh";
            else
                x.style.height = "70vh";
            //this.displayCase = true;
        }

        this.loadSpinner = false;
        var t2=performance.now();
console.log('total case time : '+(t2-t1));
    }

    /* ******************************* GET PROVISIONING ACTIVITY TASK RECORD TYPE ID ******************************* */
    plxTaskRecTypeId() 
    {
        returnRecTypeId({ sObjName: 'Task', recTypeName: 'Provisioning Activity'})
        .then(result => {
                this.taskRecordTypeId = result;
            })
            .catch(error => {
                this.error = error;
            });
    }

    /* ******************************* GET EXTERNAL TEAM ESCALATION RECORD TYPE ID ******************************* */
    extTeamEscRecTypeId() 
    {
        returnRecTypeId({ sObjName: 'Engagement_Request__c', recTypeName: 'External Team'})
        .then(result => {
                this.extTeamRecTypeId = result;
            })
            .catch(error => {
                this.error = error;
            });
    }

    /* ******************************* TOGGLE CASE TABLE METHODS ******************************* */
    toggleCaseTable() 
    {
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

    /* ******************************* SEARCH CASE DASHBOARD ******************************* */
    delayedSearch() 
    {
        clearTimeout(this.timeoutId); // no-op if invalid id
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.timeoutId = setTimeout(this.searchCases.bind(this), 500); // Adjust as necessary
    }
    searchCases()
    {
        let allCaseData = this.allCases;
        let searchFilter = this.template.querySelector('.labelHidden').value;
        this.caseSearchText = searchFilter;
        
        searchFilter = searchFilter.toUpperCase();

        //search the dashboard
        let tempArray = [];
        allCaseData.forEach(function(eachRow)
        {
            //console.log(eachRow[i].subject);
            if((eachRow.akamCaseId && eachRow.akamCaseId.toUpperCase().indexOf(searchFilter) !== -1)
            || (eachRow.accountName && eachRow.accountName.toUpperCase().indexOf(searchFilter) !== -1)
            || (eachRow.accountTier && eachRow.accountTier.toUpperCase().indexOf(searchFilter) !== -1)
            || (eachRow.subject && eachRow.subject.toUpperCase().indexOf(searchFilter) !== -1)
            || (eachRow.shiftOwner && eachRow.shiftOwner.toUpperCase().indexOf(searchFilter) !== -1)
            || (eachRow.subType && eachRow.subType.toUpperCase().indexOf(searchFilter) !== -1)
            || (eachRow.lastUpdatedBy && eachRow.lastUpdatedBy.toUpperCase().indexOf(searchFilter) !== -1)
            || (eachRow.projectName && eachRow.projectName.toUpperCase().indexOf(searchFilter) !== -1)
            || (eachRow.caseProduct && eachRow.caseProduct.toUpperCase().indexOf(searchFilter) !== -1)
            )
            {
                tempArray.push(eachRow);
            }
        });
        
        this.caseDataCopy = tempArray;
        this.totalCases = tempArray.length;

        //IF UNASSIGNED TOGGLE IS CHECKED
        if(this.template.querySelector('.unassignedBox').checked)
        {
            let tableCaseDataCopy = this.caseDataCopy;
            tempArray = [];
            tableCaseDataCopy.forEach(function(eachRow)
            {
                if(!eachRow.shiftOwner)
                {
                    tempArray.push(eachRow);
                }
            });
            this.caseDataCopy = tempArray;
        }
        
        //IF MY CASES TOGGLE IS CHECKED
        if(this.template.querySelector('.myBox').checked)
        {
            let tableCaseDataCopy = this.caseDataCopy;
            tempArray = [];
            let name = this.userName;
            tableCaseDataCopy.forEach(function(eachRow)
            {
                if(eachRow.shiftOwner)
                {
                    if(eachRow.shiftOwner === name)
                    {
                        tempArray.push(eachRow);
                    }
                }
            });
            this.caseDataCopy = tempArray;
        }
        this.totalCases = this.caseDataCopy.length;

        this.calculatecasepaginationlogic();
        

        let x = this.template.querySelector(".panelCase");
        if (this.totalCases <= 5)
            x.style.height = "35vh";
        else
            x.style.height = "70vh";

        //SEARCH IS BLANK then SORT
        if(searchFilter === '') 
            this.sortData(this.sortBy,this.sortDirection);


        //KEEP THE CHECKBOX unchanged
        //if(this.selectedCaseIDs.size > 0)
            //this.selectedRows = this.selectedCaseIDs;
    }

    /* ******************************* CLEAR SEARCH ******************************* */
    clearSearchInput()
    {
        this.template.querySelector('.labelHidden').value = '';
        this.searchCases();
    }

    /* ******************************* REFRESH CASE DASHBOARD ******************************* */
    refreshCaseTable()
    {
        const caseEvent = new CustomEvent("caseevent",{});
        this.dispatchEvent(caseEvent);
    }

    /* ******************************* SORT METHODS ******************************* */
    updateColumnSorting(event)
    {
        var fieldName = event.detail.fieldName;
        var sortDirection = event.detail.sortDirection;

        this.sortBy = fieldName;
        this.sortDirection = sortDirection;
        
        this.sortData(fieldName, sortDirection); 
    }

    sortData(fieldname, direction) 
    {
        var t1=performance.now();

        if(fieldname === 'lastUpdatedDateTimeString')
            fieldname = 'lastUpdatedMins';
        else if(fieldname === 'hotCustomer')
            fieldname = 'casePriorityNum';
        else if(fieldname === 'caseUrl')
            fieldname = 'akamCaseId';
        else if(fieldname === 'accountUrl')
            fieldname = 'accountName';
        else if(fieldname === 'shiftOwnerUrl')
            fieldname = 'shiftOwner';
        else if(fieldname === 'lastUpdatedByUrl')
            fieldname = 'lastUpdatedBy';
            
        let whiteCases = [];
        let redCases = [];
        let yellowCases = [];
        let blueCases = [];
        let sortedWhiteCases = [];
        let sortedRedCases = [];
        let sortedYellowCases = [];
        let sortedBlueCases = [];
        this.caseDataCopy.forEach(function(eachRow)
        {
            if(eachRow.caseColour === 'white'){
                whiteCases.push(eachRow);
            }
            else if(eachRow.caseColour === 'red'){
                redCases.push(eachRow);
            }
            else if(eachRow.caseColour === 'yellow'){
                yellowCases.push(eachRow);
            }
            else{
                blueCases.push(eachRow);
            }
        });

        sortedWhiteCases = this.sortColorCases(whiteCases,fieldname,direction);
        sortedYellowCases = this.sortColorCases(yellowCases,fieldname,direction);
        sortedRedCases = this.sortColorCases(redCases,fieldname,direction);
        sortedBlueCases = this.sortColorCases(blueCases,fieldname,direction);
        

        this.caseDataCopy = [...sortedWhiteCases,...sortedYellowCases,...sortedRedCases,...sortedBlueCases];
        
        this.calculatecasepaginationlogic();
        
        let parseData = JSON.parse(JSON.stringify(this.caseDataCopy));
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
        let isReverse = direction === 'asc' ? 1: -1;
        // sorting data
        parseData.sort((x, y) => 
        {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';
            //alert(typeof x);
            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });

        var t2=performance.now();
        console.log('time taken for sort : '+(t2-t1));
    }

    sortColorCases(colorCases,fieldname, direction)
    {
        let parseData = JSON.parse(JSON.stringify(colorCases));
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
        let isReverse = direction === 'asc' ? 1: -1;
        // sorting data
        parseData.sort((x, y) => 
        {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';
            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });
        colorCases = parseData;
        return colorCases;
    }
    /* ******************************* ON CASE SELECTION ******************************* */
    casesSelected()
    {
        let selectRows = this.template.querySelector('lightning-datatable').getSelectedRows();
        let shiftOwnerButton = this.template.querySelector('.changeOwnerButton');
        let caseOwnerButton = this.template.querySelector('.changeCaseOwnerButton');

        if(selectRows.length > 0)
        {
            shiftOwnerButton.disabled = false;
            caseOwnerButton.disabled = false;
            this.shiftOwnerCaseId = selectRows[0].caseId;
            this.caseOwnerCaseId = selectRows[0].caseId;
            this.curTaskRecordId = selectRows[0].caseId;

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

            /*selectRows.forEach(element => 
            {
                this.selectedCaseIDs.add(element.caseId);
            });*/
        }
        else{
            shiftOwnerButton.disabled = true;
            caseOwnerButton.disabled = true;
        }   
    }

    /* ******************************* OPEN SHIFT OWNER CHANGE ******************************* */
    openShiftOwnerPopup()
    {
        this.showShiftOwnerModal = true;
    }

    /* ******************************* CLOSE SHIFT OWNER CHANGE ******************************* */
    closeShiftOwnerModal()
    {
        this.showShiftOwnerModal = false;
    }

    /* ******************************* OPEN CASE OWNER CHANGE ******************************* */
    openCaseOwnerPopup()
    {
        this.showCaseOwnerModal = true;
    }

    /* ******************************* CLOSE SHIFT OWNER CHANGE ******************************* */
    closeCaseOwnerModal()
    {
        this.showCaseOwnerModal = false;
    }
    
    onSubmitCaseOwner(event){
        event.preventDefault();
        this.showCaseOwnerSpinner = true;
    }

    handleSuccess(successMessage){
        let caseOwnerButton = this.template.querySelector('.changeCaseOwnerButton');
        caseOwnerButton.disabled = true;
        let shiftOwnerButton = this.template.querySelector('.changeOwnerButton');
        shiftOwnerButton.disabled = true;
        this.selectedRows = [];

        const toastEvt = new ShowToastEvent({
            title: "",
            message: successMessage,
            variant: "success",
            mode: "dismissible",
            duration: 5000
        });
        this.dispatchEvent(toastEvt);
    }

    handleError(errorMessage){
        const toastEvt = new ShowToastEvent({
            title: "Error!",
            message: errorMessage,
            variant: "error",
            mode: "dismissible",
            duration: 5000
        });
        this.dispatchEvent(toastEvt);
    }

    /* ******************************* CASE OWNER UPDATE ******************************* */
    handleSubmitCaseOwner(event)
    {
        event.preventDefault();
        this.showCaseOwnerSpinner = true;
        let newCaseOwner = this.template.querySelector('.caseOwnerInput').value;
        let lstCaseRecs = [];
        let selectRows = this.template.querySelector('lightning-datatable').getSelectedRows();

        selectRows.forEach(function(eachCase)
        {
            //lstCaseRecs.push(eachCase.caseRec)
            lstCaseRecs.push(eachCase.caseId);
        })

        changeCaseOwner({lstCaseIDs: lstCaseRecs,caseOwnerId:newCaseOwner })
        .then(result => {
            console.log('CASE OWNER CHANGED : '+result);
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
                this.handleSuccess('Case Owner Updated');
                this.selectedRows = [];
            }
            this.refreshCaseTable();
            this.showCaseOwnerSpinner = false;
            this.showCaseOwnerModal = false;
        })
        .catch(error => {
            console.log('Case OWNER CHANGE ERROR: '+error);
            this.showCaseOwnerSpinner = false;
            this.showCaseOwnerModal = false;

            let errorMessage = 'An Error Occurred While Updating : ';
            errorMessage+=error.body.message;

            /*if(error.body.pageErrors[0] !== undefined && error.body.pageErrors[0].message !== undefined){
                errorMessage =  error.body.pageErrors[0].message
            }*/
            this.handleError(errorMessage); 
            this.refreshCaseTable();
        })
    }

    /* ******************************* CASE OWNER UPDATE TO QUEUE ******************************* */
    handleSubmitCaseOwnerQueue(event)
    {
        event.preventDefault();
        this.showCaseOwnerSpinner = true;
        this.template.querySelector('.caseOwnerInput').value = '';
        let lstCaseRecs = [];
        let selectRows = this.template.querySelector('lightning-datatable').getSelectedRows();

        selectRows.forEach(function(eachCase)
        {
            //lstCaseRecs.push(eachCase.caseRec)
            lstCaseRecs.push(eachCase.caseId);
        })

        changeCaseOwner({lstCaseIDs: lstCaseRecs,caseOwnerId:''})
        .then(result => {
            console.log('CASE OWNER CHANGE TO QUEUE: '+result);
            let resMssg; let resErrorRows = [];
            
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
                this.handleSuccess('Case(s) Assigned to Queue');
                this.selectedRows = [];
            }      
            this.refreshCaseTable();    
            this.showCaseOwnerSpinner = false;
            this.showCaseOwnerModal = false;
            
            
        })
        .catch(error => {
            console.log('CASE OWNER CHANGE TO QUEUE ERROR: '+error);
            this.showCaseOwnerSpinner = false;
            this.showCaseOwnerModal = false;

            let errorMessage = 'An Error Occurred while updating : ';
            errorMessage+=error.body.message;

            /*if(error.body.pageErrors[0] !== undefined && error.body.pageErrors[0].message !== undefined){
                errorMessage =  error.body.pageErrors[0].message
            }*/
            this.handleError(errorMessage); 
            this.refreshCaseTable();
        })
    }

    /* ******************************* SHIFT OWNER UPDATE ******************************* */
    handleSubmitShiftOwner(event)
    {
        event.preventDefault();
        this.showShiftOwnerSpinner = true;
        let newShiftOwner = this.template.querySelector('.shiftOwnerInput').value;
        let lstCaseRecs = [];
        let selectRows = this.template.querySelector('lightning-datatable').getSelectedRows();

        selectRows.forEach(function(eachCase)
        {
            //lstCaseRecs.push(eachCase.caseRec)
            lstCaseRecs.push(eachCase.caseId);
        })

        changeShiftOwner({lstCaseIDs: lstCaseRecs,shiftOwnerId:newShiftOwner })
        .then(result => {
            console.log('SHIFT OWNER CHANGED : '+result);
            this.showShiftOwnerSpinner = false;
            this.showShiftOwnerModal = false;
            this.handleSuccess('Shift Owner Updated');
            this.refreshCaseTable();
        })
        .catch(error => {
            console.log('SHIFT OWNER CHANGE ERROR: '+error);
            this.showShiftOwnerSpinner = false;
            this.showShiftOwnerModal = false;

            let errorMessage = 'An Error Occurred While Updating : ';
            errorMessage+=error.body.message;

            /*if(error.body.pageErrors[0] !== undefined && error.body.pageErrors[0].message !== undefined){
                errorMessage =  error.body.pageErrors[0].message
            }*/
            this.handleError(errorMessage); 
            this.refreshCaseTable();
        })
    }

    /* ******************************* CLEAR SHIFT OWNER UPDATE ******************************* */
    handleClearShiftOwner(event)
    {
        event.preventDefault();
        this.showShiftOwnerSpinner = true;
        this.template.querySelector('.shiftOwnerInput').value = '';
        let selectRows = this.template.querySelector('lightning-datatable').getSelectedRows();
        let lstCaseRecs = [];
        selectRows.forEach(function(eachCase){
            //lstCaseRecs.push(eachCase.caseRec)
            lstCaseRecs.push(eachCase.caseId)
        })

        changeShiftOwner({lstCaseIDs: lstCaseRecs,shiftOwnerId: ''})
        .then(result => {
            console.log('SHIFT OWNER CLEARED : '+result);
            this.showShiftOwnerSpinner = false;
            this.showShiftOwnerModal = false;
            this.handleSuccess('Shift Owner Cleared');
            this.refreshCaseTable();
        })
        .catch(error => {
            console.log('SHIFT OWNER CLEAR ERROR: '+error.value);
            this.showShiftOwnerSpinner = false;
            this.showShiftOwnerModal = false;

            let errorMessage = 'An Error Occurred While Updating : ';
            errorMessage+=error.body.message;

            /*if(error.body.pageErrors[0] !== undefined && error.body.pageErrors[0].message !== undefined){
                errorMessage =  error.body.pageErrors[0].message
            }*/
            this.handleError(errorMessage); 
            this.refreshCaseTable();
        })
    }

    /* ******************************* DATATABLE ROW ACTIONS ******************************* */
    handleRowAction(event)
    {
        let actionName = event.detail.action.name;
        let row = event.detail.row;
        this.caseRecordId = row.caseId;
        this.caseAKAMId = row.akamCaseId;

        if(actionName === 'edit')
        {
            this.showEditModal = true;
        }
        else if(actionName === 'newTask')
        {
            this.navigateToNewTaskPage();
        }
        else if(actionName === 'newEsc')
        {
            this.showNewEscModal = true;
        }
        else if(actionName === 'escCount')
        {
            this.showEscModal = true;
            getEscalationRecs() 
            {
                getEscalationRecs({ caseId: this.caseRecordId })
                    .then(result => {
                        this.escData = result;
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
    }

    /* ******************************* EDIT CASE MODAL MEYHODS******************************* */
    closeCaseEditModal() {
        this.showEditModal = false;
    }
    handleCaseEditSubmit(){
        this.loadModalSpinner = true;
    }
    handleCaseEditSuccess(){
        this.loadModalSpinner = false;
        this.closeCaseEditModal();
        this.refreshCaseTable();
    }
    handleCaseEditError(){
        this.loadModalSpinner = false;
    }

    /* ******************************* NEW TASK ROW ACTION ******************************* */
    navigateToNewTaskPage() 
    {
        let setFields =
        "WhatId=" + this.caseRecordId + ",OwnerId=" + this.onaUserId;
        this[NavigationMixin.Navigate]({
            type: "standard__objectPage",
            attributes: {
                objectApiName: "Task",
                actionName: "new"
            },
            state: {
                /*nooverride: 1,
                useRecordTypeCheck: 1,
                navigationLocation: "Provisioning_Dashboard",
                backgroundContext: "/lightning/n/Provisioning_Dashboard",*/
                recordTypeId: this.taskRecordTypeId,
                defaultFieldValues: setFields
            }
        });
    }

    /* ******************************* VIEW + CREATE ESCALATION METHODS ******************************* */

    closeNewEscModal()
    {
        this.showNewEscModal = false;
    }

    handleSubmitEsc()
    {        
        this.loadEscSpinner = true;
    }

    handleErrorEsc()
    {
        this.loadEscSpinner = false;
    }

    handleSuccessEsc()
    {
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
    
    /* ******************************* MY/UNASSIGNED CASES METHODS ******************************* */
    toggleChecked(event)
    {
        let tempArray = [];
        this.loadSpinner = true;

        let tableCaseDataCopy = this.allCases;
        let name = this.userName;
        if(!event.target.checked)
        {
            this.caseDataCopy = this.allCases;
        }
        else
        {
            if(event.target.name === 'unassigned')
            {
                tableCaseDataCopy.forEach(function(eachRow)
                {
                    if(!eachRow.shiftOwner)
                    {
                        tempArray.push(eachRow);
                    }
                });
                this.template.querySelector('.myBox').checked = false;
            }
            else
            {
                tableCaseDataCopy.forEach(function(eachRow)
                {
                    if(eachRow.shiftOwner)
                    {
                        if(eachRow.shiftOwner === name)
                        {
                            tempArray.push(eachRow);
                        }
                    }
                });
                this.template.querySelector('.unassignedBox').checked = false;
            }
            this.caseDataCopy = tempArray;
        }
        if(this.caseSearchText)
        {
            this.searchCases();
        }
        this.totalCases = this.caseDataCopy.length;
        this.sortData(this.sortBy, this.sortDirection);

        let x = this.template.querySelector(".panelCase");
        if (this.totalCases <= 5)
            x.style.height = "35vh";
        else
            x.style.height = "70vh";
        this.loadSpinner = false;
    }

    offset = 1;
    paginationNumbers;
    SlicedDatalist;
    currentpage;

    handlePaginationClick(event) {
        //var t0 = performance.now();
         let page = event.target.dataset.item;
         this.offset=page;
         this.SlicedDatalist = this.caseDataCopy.slice((this.offset - 1) * 50, this.offset * 50);
         this.currentpage=this.offset+'/'+this.paginationNumbers;
 
         //var t1 = performance.now();
         //console.log("------------>Pagination took " + (t1 - t0) + " milliseconds to execute.")
     }

    calculatecasepaginationlogic()
    {
        if(this.totalCases === 0)
        {
            this.paginationNumbers = 1;
        }
        else
        {
            this.paginationNumbers = Math.ceil(this.totalCases / 50);
        }
        if(this.offset>this.paginationNumbers) this.offset=1;
        
        this.currentpage=this.offset+'/'+this.paginationNumbers;
        this.paginationRange = [];
        for (var i = 1; i <= this.paginationNumbers; i++) {
            this.paginationRange.push(i);
        }
        this.SlicedDatalist = this.caseDataCopy.slice((this.offset - 1) * 50, this.offset * 50);
    }
}