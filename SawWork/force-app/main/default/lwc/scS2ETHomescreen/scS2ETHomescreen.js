/* eslint-disable no-unused-vars */
/* eslint-disable no-console */
/* eslint-disable no-alert */

import { LightningElement, api } from "lwc";

import { loadStyle } from "lightning/platformResourceLoader";
import cssStyleSheet from "@salesforce/resourceUrl/SC_S2ET_Stylesheet";

import { NavigationMixin } from "lightning/navigation";
import emailReport from "@salesforce/apex/SC_SecurityServices_Ctrlr.emailShiftHandoverReport";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

// apex classes
import getSavedFilters from "@salesforce/apex/SC_SecurityServices_Ctrlr.saveS2ETFilters";
import getCaseList from "@salesforce/apex/SC_SecurityServices_Ctrlr.getCaseList";
import getTaskList from "@salesforce/apex/SC_SecurityServices_Ctrlr.getTaskList";

export default class ScS2ETHomescreen extends NavigationMixin(LightningElement)
{
    redCount = 0;
    yellowCount = 0;
    overdueCount = 0;

    displayFilter = true;

    masterCaseData = [];
    masterTaskData = [];

    caseData = [];
    taskData = [];

    summaryValueSelected = "Default";
    caseSeveritySelected = ["1", "2", "3", "4"];
    casePrioritySelected = "All";
    taskShiftSelected = "All";
    taskStatusSelected = "All";

    loadSpinner = true;
    loadSpinner1 = true;

    @api caseSevVal;

    PollID;

    /* *********************************** SET + RETRIEVE + TRACK FILTER VALUES *********************************** */
    get summaryVal() {
        return [
            { label: "Default", value: "Default" },
            { label: "Case Severity", value: "Case Severity" },
            { label: "Case Priority", value: "Case Priority" },
            { label: "Case Status", value: "Case Status" },
            { label: "Task Shift", value: "Task Shift" },
            { label: "Task Status", value: "Task Status" }
        ];
    }

    get caseSeverityVal() {
        return [
            { label: "1", value: "1" },
            { label: "2", value: "2" },
            { label: "3", value: "3" },
            { label: "4", value: "4" }
        ];
    }

    get casePriorityVal() {
        return [
            { label: "All", value: "All" },
            { label: "Hot Customer", value: "Hot Customer" },
            //{ label: "White Glove Treatment", value: "White Glove Treatment" },
            //{ label: "High Alert Customer", value: "High Alert Customer" },
            { label: "Special Instructions", value: "Special Instructions" },
            { label: "High Alert Case/Task", value: "High Alert Case/Task" }
            
        ];
    }

    get taskShiftVal() {
        return [
            { label: "All", value: "All" },
            { label: "AMER East", value: "AMER East" },
            { label: "AMER West", value: "AMER West" },
            { label: "APJ", value: "APJ" },
            { label: "EMEA", value: "EMEA" }
        ];
    }

    get taskStatusVal() {
        return [
            { label: "All", value: "All" },
            { label: "Not Started", value: "Not Started" },
            { label: "In Progress", value: "In Progress" },
            { label: "Deferred", value: "Deferred" }
        ];
    }

    caseSevChange(event) 
    {
        if(!event.detail.value.toString())
        {
            console.log('PREV : ' + this.caseSeveritySelected);
            let sevVals = []; sevVals.push(this.caseSeveritySelected.toString());
            console.log(sevVals);
            this.caseSeveritySelected = sevVals;
            const toastEvt = new ShowToastEvent({
                title: "",
                message: "Please select atleast one Case Severity value",
                variant: "warning",
                mode: "dismissible",
                duration: 5000
            });
            this.dispatchEvent(toastEvt);
        }
        else
        {
            this.caseSeveritySelected = event.detail.value;
        }

    }

    casePriorityChange(event) {
        this.casePrioritySelected = event.detail.value;
    }

    taskShiftChange(event) {
        this.taskShiftSelected = event.detail.value;
    }

    taskStatusChange(event) {
        this.taskStatusSelected = event.detail.value;
    }

    reset() {
        this.caseSeveritySelected = ["1", "2", "3", "4"];
        this.casePrioritySelected = "All";
        this.taskShiftSelected = "All";
        this.taskStatusSelected = "All";
    }

    /* *********************************** POPULATE CASES *********************************** */
    populateCases() {
        console.log('Pop Cases');
        let sev = (this.caseSeveritySelected).toString();
        getCaseList({ caseSeverity: sev, casePriority: this.casePrioritySelected })
            .then(result => {
                //console.log('CASES : ' + result.length);
                this.masterCaseData = result;
                this.applyFilter();
            })
            .catch(error => {
                console.log('getCaseList Error : ' + JSON.stringify(error));
                this.error = error;
                this.masterCaseData = undefined;
                this.loadSpinner = false;
            });
    }

    /* *********************************** POPULATE TASKS *********************************** */
    populateTasks() {
        //console.log(this.taskShiftSelected + this.taskStatusSelected + this.caseSeveritySelected + this.casePrioritySelected);
        console.log('Pop Tasks');
        let sev = (this.caseSeveritySelected).toString();

        if (sev) 
        {
            getTaskList({ taskShift: this.taskShiftSelected, taskStatus: this.taskStatusSelected, caseSeverity: sev, casePriority: this.casePrioritySelected })
                .then(result => {
                    //console.log('TASKS : ' + result.length);
                    this.masterTaskData = result;
                    this.populateCases();
                })
                .catch(error => {
                    this.error = error;
                    this.masterTaskData = undefined;
                    console.log('getTaskList error : ' + JSON.stringify(error));
                    this.loadSpinner = false;
                });
        }
        else 
        {
            const toastEvt = new ShowToastEvent({
                title: "",
                message: "Please select atleast one Case Severity value",
                variant: "warning",
                mode: "dismissible",
                duration: 5000
            });
            this.dispatchEvent(toastEvt);
            this.loadSpinner = false;
        }
    }

    /* *********************************** POPULATE DATA IN DASHBOARD *********************************** */
    populateData() {
        this.loadSpinner = true;
        this.populateTasks();
    }

    /* *********************************** CONNECTED CALLBACK *********************************** */
    temp;
    connectedCallback() 
    {
        console.log('Connected Callback : ' + performance.now() / 1000);
        window.addEventListener("test", this.handleTest);

        getSavedFilters()
            .then(result => {
                //console.log("Filter Values");
                this.caseSeveritySelected = result.CaseSeverity;
                this.casePrioritySelected = result.CasePriority;
                this.taskShiftSelected = result.TaskShift;
                this.taskStatusSelected = result.TaskStatus;

                //console.log('TEMP : ' + this.temp.toString());
                //window.addEventListener("visibilitychange", this.listenForMessage.bind(this));
                
                this.temp = this.listenForMessage.bind(this);
                window.addEventListener("visibilitychange", this.temp);

                //window.addEventListener("hashchange", this.testing);

                this.populateData();

                this.PollID = setInterval(() => {
                    //console.log('running poller : ' + this.PollID);
                    this.populateData();
                    console.log('Polled Main');
                }, 300000);
                //console.log('poller ID : ' + this.PollID);
            })
            .catch(error => {
                console.log('getFilter error : ' + JSON.stringify(error));
                this.error = error;
            });

        loadStyle(this, cssStyleSheet);
    }

    testing()
    {
        console.log('HELLOW');
    }

    disconnectedCallback()
    {
        //console.log('disconnected called');
        //console.log('VAL : ' + this.i);
        //window.removeEventListener("visibilitychange", this.listenForMessage.bind(this));
        //let a = this.listenForMessage.bind(this).toString();
        window.removeEventListener("visibilitychange", this.temp);
    }


    listenForMessage(message) {
        if (document.hidden) { console.log('Doc Hidden'); }
        if (document.webkitHidden) { console.log('Doc webkitHidden'); }
        if (document.msHidden) { console.log('Doc msHidden'); }
        if (document.mozHidden) { console.log('Doc mozHidden'); }

        //if (document.hidden || document.webkitHidden || document.msHidden || document.mozHidden) 
        if (document.visibilityState !== 'visible') 
        {
            console.log('Away');
            window.clearInterval(this.PollID);
            //window.removeEventListener("visibilitychange", this.temp);
        }
        else 
        {
            console.log('Back');
            this.resetPollerAndRefresh();
        }
    }

    /* *********************************** RESET + REFRESH *********************************** */
    resetPollerAndRefresh(event) 
    {
        console.log('poller cleared and reset');
        
        //this.temp = this.listenForMessage.bind(this);
        //window.addEventListener("visibilitychange", this.temp);

        window.clearInterval(this.PollID);
        this.PollID = setInterval(() => 
        {
            //console.log('running poller : ' + this.PollID);
            this.populateData();
        }, 300000);
        //console.log('poller ID : ' + this.PollID);
        if (typeof (event) != 'undefined') { this.loadSpinner = true; }
        this.populateData();

    }

    /* *********************************** SAVE + APPLY *********************************** */
    saveAndApply() {
        console.log('Save And Apply Start : ' + performance.now() / 1000);
        this.loadSpinner = true;
        let sev = (this.caseSeveritySelected).toString();
        if (!sev) {
            const toastEvt = new ShowToastEvent({
                title: "",
                message: "Please select atleast one Case Severity value",
                variant: "warning",
                mode: "dismissible",
                duration: 4000
            });
            this.dispatchEvent(toastEvt);
            //this.loadSpinner = false;
        }
        else {
            this.resetPollerAndRefresh();
            //this.applyFilter();
            //this.populateData();
            this.saveFilter();
        }
    }

    /* *********************************** APPLY FILTER *********************************** */
    applyFilter() {
        console.log("Apply Filter");
        let tempCaseArray = [];
        let tempCaseIdArray = [];
        let tempWhatIdArray = [];
        //let myCaseIdArray = [];
        this.caseData = [];
        this.taskData = [];

        let shift = String(this.taskShiftSelected);
        let status = String(this.taskStatusSelected);

        let red = 0; let yellow = 0; let overdue = 0;

        /*
            this.masterCaseData.forEach(eachCase => {
                if (
                    sev.includes(eachCase.severity) &&
                    (priority.includes(eachCase.priorityType) ||
                        priority.toUpperCase() === "ALL")
                ) {
                    tempCaseArray.push(eachCase);
                    tempCaseIdArray.push(eachCase.caseId);
                }
            });
            

            this.masterTaskData.forEach(eachTask => {
                if (
                    (shift.toUpperCase() === "ALL" ||
                        shift.includes(eachTask.assignedShift)) &&
                    (status.includes(eachTask.status) || status.toUpperCase() === "ALL") &&
                    tempCaseIdArray.includes(eachTask.relatedCaseId)
                ) {
                    tempTaskArray.push(eachTask);
                    tempWhatIdArray.push(eachTask.relatedCaseId);
                    if (eachTask.taskColour === "red") overdue++;
                }
            });
        */

        this.masterCaseData.forEach(eachCase => {
            tempCaseIdArray.push(eachCase.caseId);
        });

        tempCaseArray = this.masterCaseData;

        this.masterTaskData.forEach(eachTask => {
            this.taskData.push(eachTask);
            tempWhatIdArray.push(eachTask.relatedCaseId);
            if (eachTask.taskColour === "red") overdue++;
        });
        tempCaseArray.forEach(eachTempCase => 
        {
            if (tempWhatIdArray.includes(eachTempCase.caseId)
            || (shift === 'All' && status === 'All'))
            {
                this.caseData.push(eachTempCase);
                if (eachTempCase.caseColour === "red") red++;
                else if (eachTempCase.caseColour === "yellow") yellow++;
            }
        });
        
        this.redCount = red;
        this.yellowCount = yellow;
        this.overdueCount = overdue;

        this.template.querySelector("c-sc-security-services-cases").calledFromParent(this.caseData,this.taskData);
        //this.template.querySelector("c-sc-security-services-tasks").calledFromParent(this.taskData);
        this.loadSpinner = false;
        console.log('after load :' + performance.now() / 1000);
        //console.log(Math.ceil(window.performance.memory.usedJSHeapSize / 1000000));
    }

    /* *********************************** SAVE FILTER *********************************** */
    saveFilter() {
        console.log("Save Filter");
        let sev = String(this.caseSeveritySelected);
        let priority = String(this.casePrioritySelected);
        let shift = String(this.taskShiftSelected);
        let status = String(this.taskStatusSelected);
        this.filterStringToSave =
            "CaseSeverity:" +
            sev +
            "&CasePriority:" +
            priority +
            "&TaskShift:" +
            shift +
            "&TaskStatus:" +
            status;

        if (sev && priority && shift && status) {
            getSavedFilters({ filterToSave: this.filterStringToSave })
                .then(result => {
                    //this.resetPollerAndRefresh();
                    this.loadSpinner = false;
                    const toastEvt = new ShowToastEvent({
                        title: "",
                        message: "Filter saved! Loading results...",
                        variant: "success",
                        mode: "dismissible",
                        duration: 7000
                    });
                    this.dispatchEvent(toastEvt);
                })
                .catch(error => {
                    this.loadSpinner = false;
                });
        }
    }


    /* *********************************** OPEN REPORT *********************************** */
    navigateToHandoverReport(event) {
        //window.open('/apex/SC_S2ET_Report', '_blank');
        let shiftInfo = event.target.value;
        this.loadSpinner = true;
        emailReport({ shiftInfo: event.target.value })
            .then(result => {
                this.loadSpinner = false;
                const toastEvt = new ShowToastEvent({
                    title: "Report Sent!",
                    message: "The Shift Handover Report has been mailed to you!",
                    variant: "success",
                    mode: "dismissible",
                    duration: 10000
                });
                this.dispatchEvent(toastEvt);
            })
            .catch(error => {
                this.loadSpinner = false;
            });
    }

    /* ********************************************* TOGGLE FILTER ********************************************* */

    showFilter() {
        var x = this.template.querySelector(".filterDiv");
        this.displayFilter = !this.displayFilter;
    }

    hideFilter() {
        var x = this.template.querySelector(".filterDiv");
        this.displayFilter = !this.displayFilter;
    }

    /* *************************************** NOTIFICATION CENTER **************************************** */

    notificationlist = [];
    notificationCenterHeader = "";

    getNavRecords(event) {
        //var t0 = performance.now();
        let buttonVal = event.target.value;
        var filteredlist = [];
        this.notificationCenterHeader =
            buttonVal === "red"
                ? "Missed Case Acknowledgement"
                : buttonVal === "yellow"
                    ? "Customer Response Received"
                    : "Passed Duedate";

        if (buttonVal === "red" || buttonVal === "yellow") {
            for (let i = 0; i < this.caseData.length; i++) {
                if (this.caseData[i].caseColour === "red" && buttonVal === "red") {
                    let x = {
                        akamId: this.caseData[i].akamCaseId,
                        recUrl: this.caseData[i].caseUrl,
                        Body: "Go to Case " + this.caseData[i].akamCaseId
                    };
                    filteredlist.push(x);
                }
                else if
                    (this.caseData[i].caseColour === "yellow" && buttonVal === "yellow") {
                    let x = {
                        akamId: this.caseData[i].akamCaseId,
                        recUrl: this.caseData[i].caseUrl,
                        Body: "Go to Case " + this.caseData[i].akamCaseId
                    };
                    filteredlist.push(x);
                }
            }
        }
        else if (buttonVal === "overdue") {
            for (let i = 0; i < this.taskData.length; i++) {
                if (this.taskData[i].taskColour === "red") {
                    let x = {
                        akamId: this.taskData[i].subject,
                        recUrl: this.taskData[i].taskUrl,
                        Body:
                            this.taskData[i].subject +
                            " on " +
                            this.taskData[i].relatedCaseAKAMId +
                            " is overdue"
                    };
                    filteredlist.push(x);
                }
            }
        }

        this.notificationlist = filteredlist;
        let sideNav = this.template.querySelector(".sidenav");
        sideNav.style.width = "250px";
        // var t1 = performance.now();
        //console.log("------------>Refresh values took " + (t1 - t0) + " milliseconds to execute.")
    }

    closeNav(event) {
        var x = this.template.querySelector(".sidenav");
        x.style.width = "0px";
    }

    openNewTab(event) {
        window.open(event.target.value, "_blank");
    }
}