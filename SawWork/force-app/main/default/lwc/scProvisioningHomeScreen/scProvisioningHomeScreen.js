/* eslint-disable no-console */
/* eslint-disable no-alert */
/* eslint(@lwc/lwc/no-async-operation) */

import { LightningElement} from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import SC_SProvisioning_Stylesheet from '@salesforce/resourceUrl/SC_Provisioning_Stylesheet';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getCaseList from '@salesforce/apex/SC_ProvisioningDashboard_Controller.getCaseList';
import getTaskList from '@salesforce/apex/SC_ProvisioningDashboard_Controller.getTaskList';
import getSavedFilters from '@salesforce/apex/SC_ProvisioningDashboard_Controller.savePlxFilters';
import emailReport from '@salesforce/apex/SC_ProvisioningDashboard_Controller.emailShiftHandoverReport';

export default class ScProvisioningHomeScreen extends LightningElement 
{
    caseSeveritySelected = ['1', '2', '3','4'];
    colorCategorySelected = ['blue', 'white', 'red', 'yellow'];
    priorityCustomerSelected = 'All';
    caseFundTypeSelected = 'All';
    caseLogoTypeSelected = 'All';
    caseSubTypeSelected = 'All';
    GeographiesSelected = ['Americas','EMEA','AP','Japan','Others'];
    taskStatusSelected = 'All';
    
    caseData = [];//to pass the cases to case dashboard
    masterCaseData = [];//to filter
    taskData = [];//to pass the tasks to task dashboard
    masterTaskData = [];//to filter
    error;
    temp;

    redCount=0;
    yellowCount=0;
    overdueCount=0;
    whiteCount=0;

    displayFilter = true;
    loadSpinner = true;

    notificationlist = [];//Notification Center
    notificationCenterHeader = "";//Notification Center

    PollID;

    get caseSeverityVal() 
    {
        return [
            { label: '1', value: '1' },
            { label: '2', value: '2' },
            { label: '3', value: '3' },
            { label: '4', value: '4' }
        ];
    }

    get colorCategoryVal(){
        return[
            { label: 'B', value: 'blue' },
            { label: 'W', value: 'white' },
            { label: 'R', value: 'red' },
            { label: 'Y', value: 'yellow' }
        ];
    }

    get priorityCustomerSelectedVal(){
        return[
            { label: 'All', value: 'All' },
            { label: 'Hot Customer', value: 'Hot Customer'},
            //{ label: 'White Glove Treatment', value: 'White Glove Treatment'},
            //{ label: 'High Alert Customer', value: 'High Alert Customer'},
            { label: "Special Instructions", value: "Special Instructions" },
            { label: "High Alert Case/Task", value: "High Alert Case/Task" }
        ];
    }
    get caseFundTypeVal() {
        return [
            { label: 'All', value: 'All' },
            { label: 'Security Bucket', value: 'Security Bucket' },
            { label: 'IW', value: 'IW' },
            { label: 'NNR (One-time)', value: 'NNR (One-time)' },
            { label: 'Other Bucket', value: 'Other Bucket' }
        ];
    }

    get caseLogoTypeVal() {
        return [
            { label: 'All', value: 'All' },
            { label: 'New', value: 'New' },
            { label: 'Special', value: 'Special' }
        ];
    }

    get caseSubTypeVal() {
        return [
            { label: 'All', value: 'All' },
            { label: 'Managed Integration', value: 'Managed Integration' },
            { label: 'Change', value: 'Change' },
            { label: 'Deprovision', value: 'Deprovision' }
        ];
    }

    /*
    get taskShiftNameVal() {
        return [
            { label: 'All', value: 'All' },
            { label: 'AMER First', value: 'AMER First' },
            { label: 'AMER Second', value: 'AMER Second' },
            { label: 'AMER Third', value: 'AMER Third' }
        ];
    }
    */

   get GeographiesVal() 
   {
        return [
            { label: 'Americas', value: 'Americas' },
            { label: 'EMEA', value: 'EMEA' },
            { label: 'AP', value: 'AP' },
            { label: 'Japan', value: 'Japan' },
            { label: 'Others', value: 'Others' }
        ];
    }
    
    get taskStatusVal() {
        return [
            { label: 'All', value: 'All' },
            { label: 'Unassigned', value: 'Unassigned' },
            { label: 'Not Started', value: 'Not Started' },
            { label: 'In Progress', value: 'In Progress' },
            { label: 'Deferred', value: 'Deferred' }
        ];
    }

    /* *********************************** CONNECTED CALLBACK *********************************** */
    connectedCallback() 
    {
        //window.addEventListener('test', this.handleTest);
        loadStyle(this, SC_SProvisioning_Stylesheet);

        getSavedFilters() 
            .then(result => {
                this.caseSeveritySelected = result.CaseSeverity;
                this.colorCategorySelected = result.ColorCategory;
                this.priorityCustomerSelected = result.CasePriority;
                this.caseFundTypeSelected = result.CaseFundType;
                this.caseLogoTypeSelected = result.CaseLogoType;
                this.caseSubTypeSelected = result.CaseSubType;
                this.GeographiesSelected = result.Geo;
                this.taskStatusSelected = result.TaskStatus;

                this.temp = this.listenForMessage.bind(this);
                window.addEventListener("visibilitychange", this.temp);

                this.populateData();

                // eslint-disable-next-line @lwc/lwc/no-async-operation
                this.PollID = setInterval(() => {
                    this.populateData();
                    console.log('Polled Main');
                }, 300000);
            })
            .catch(error => {
                this.error = error;
            });
    }

    /* *********************************** DISCONNECTED CALLBACK *********************************** */
    disconnectedCallback()
    {
        window.removeEventListener("visibilitychange", this.temp);
    }

    /* *********************************** Listen the state of doc *********************************** */
    listenForMessage(message) {
        console.log('MESSAGE  : '+message);
        if (document.hidden) { 
            console.log('Doc Hidden');
        }
        if (document.webkitHidden) { 
            console.log('Doc webkitHidden'); 
        }
        if (document.msHidden) { 
            console.log('Doc msHidden'); 
        }
        if (document.mozHidden) { 
            console.log('Doc mozHidden'); 
        }

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
        window.clearInterval(this.PollID);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.PollID = setInterval(() => 
        {
            this.populateData();
        }, 300000);
        if (typeof (event) != 'undefined') { this.loadSpinner = true; }
        this.populateData();

    }

    /* *********************************** Populate Data on dashboard *********************************** */
    populateData() {
        this.loadSpinner = true;
        this.populateTasks();
    }

    /* *********************************** Method to call Apex to Populate Tasks *********************************** */
    populateTasks(){
        let sev = (this.caseSeveritySelected).toString();
        let col = (this.colorCategorySelected).toString();
        let geo = this.GeographiesSelected.toString();
        if (!sev) 
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
        else if(!col)
        {
            const toastEvt = new ShowToastEvent({
                title: "",
                message: "Please select atleast one Color Category value",
                variant: "warning",
                mode: "dismissible",
                duration: 5000
            });
            this.dispatchEvent(toastEvt);
            this.loadSpinner = false;
        }
        else 
        {
            getTaskList({ taskStatus: this.taskStatusSelected, 
                caseSeverity: sev, casePriority: this.priorityCustomerSelected, 
                caseFundType: this.caseFundTypeSelected, caseLogoType:this.caseLogoTypeSelected, 
                caseSubType: this.caseSubTypeSelected, colorCategory: col, geos : geo})
            .then(result => {
                this.masterTaskData = result;
                this.populateCases();
            })
            .catch(error => {
                this.error = error;
                this.masterTaskData = undefined;
                this.loadSpinner = false;
            });
        }
    }

    /* *********************************** Method to call Apex to Populate Cases *********************************** */
    populateCases(){
        let sev = (this.caseSeveritySelected).toString();
        let col = (this.colorCategorySelected).toString();
        let geo= this.GeographiesSelected.toString();
        getCaseList({
            caseSeverity:sev,
            casePriority:this.priorityCustomerSelected,
            caseFundType:this.caseFundTypeSelected,
            caseLogoType:this.caseLogoTypeSelected,
            caseSubType:this.caseSubTypeSelected,
            colorCategory:col,
            geos:geo
        })
        .then(result => {
            this.masterCaseData = result;
            this.applyFilter();            
        })
        .catch(error => {
            this.error = error;
            this.masterCaseData = undefined;
            this.masterCaseData = undefined;
            this.loadSpinner = false;
        })
    }

    /* *********************************** Method called when CASE SEVERITY filter is changed *********************************** */
    caseSeverityChanged(event){
        if(!event.detail.value.toString())
        {
            let sevVals = []; 
            sevVals.push(this.caseSeveritySelected.toString());
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

    /* *********************************** Method called when COLOR CATEGORY filter is changed *********************************** */
    colorCategoryChanged(event){
        if(!event.detail.value.toString())
        {
            let sevVals = []; 
            sevVals.push(this.colorCategorySelected.toString());
            this.colorCategorySelected = sevVals;
            const toastEvt = new ShowToastEvent({
                title: "",
                message: "Please select atleast one Color Category value",
                variant: "warning",
                mode: "dismissible",
                duration: 5000
            });
            this.dispatchEvent(toastEvt);
        }
        else
        {
            this.colorCategorySelected = event.detail.value;
        }
    }

    /* *********************************** Method called when PRIORITY CUSTOMER filter is changed *********************************** */
    priorityCustomerSelectedChanged(event){
        this.priorityCustomerSelected = event.detail.value;
    }

    /* *********************************** Method called when FUND TYPE filter is changed *********************************** */
    caseFundTypeChanged(event){
        this.caseFundTypeSelected = event.detail.value;
    }

    /* *********************************** Method called when LOGO TYPE filter is changed *********************************** */
    caseLogoTypeChanged(event){
        this.caseLogoTypeSelected = event.detail.value;
    }

    /* *********************************** Method called when SUB TYPE filter is changed *********************************** */
    caseSubTypeChanged(event){
        this.caseSubTypeSelected = event.detail.value;
    }

    /* *********************************** Method called when GEOGRAPHY filter is changed *********************************** */
    GeographiesChanged(event){
        this.GeographiesSelected = event.detail.value;
    }

    /* *********************************** Method called when TASK STATUS filter is changed *********************************** */
    taskStatusChanged(event){
        this.taskStatusSelected = event.detail.value;
    }

    /* *********************************** Method to check if all filters are selected and call saveFilter() *********************************** */
    saveAndApply()
    {
        this.loadSpinner = true;
        let sev = (this.caseSeveritySelected).toString();
        let col = (this.colorCategorySelected).toString();
        let geo = (this.GeographiesSelected).toString();
        if (!sev) {
            const toastEvt = new ShowToastEvent({
                title: "",
                message: "Please select atleast one Case Severity value",
                variant: "warning",
                mode: "dismissible",
                duration: 4000
            });
            this.dispatchEvent(toastEvt);
            this.loadSpinner = false;
        }
        else if(!col){
            const toastEvt = new ShowToastEvent({
                title: "",
                message: "Please select atleast one Color Category value",
                variant: "warning",
                mode: "dismissible",
                duration: 4000
            });
            this.dispatchEvent(toastEvt);
            this.loadSpinner = false;
        }
        else if(!geo)
        {
            const toastEvt = new ShowToastEvent({
                title: "",
                message: "Please select atleast one Geography value",
                variant: "warning",
                mode: "dismissible",
                duration: 4000
            });
            this.dispatchEvent(toastEvt);
            this.loadSpinner = false;

        }
        else {
            this.resetPollerAndRefresh();
            this.saveFilter();
        }
    }

    /* *********************************** Method to pass the selected filters to apex *********************************** */
    saveFilter(){
        let sev = String(this.caseSeveritySelected);
        let color = String(this.colorCategorySelected);
        let casePriority = String(this.priorityCustomerSelected);
        let caseFundType = String(this.caseFundTypeSelected);
        let caseLogoType = String(this.caseLogoTypeSelected);
        let caseSubType = String(this.caseSubTypeSelected);
        let Geos = String(this.GeographiesSelected);
        let taskStatus = String(this.taskStatusSelected);

        this.filterStringToSave =
            "CaseSeverity:" +
            sev +
            "&ColorCategory:"+
            color +
            "&CasePriority:" +
            casePriority +
            "&CaseFundType:" +
            caseFundType +
            "&CaseLogoType:" +
            caseLogoType +
            "&CaseSubType:" +
            caseSubType +
            "&Geo:" +
            Geos +
            "&TaskStatus:" +
            taskStatus;

        if (sev && color && casePriority && caseFundType && caseLogoType && caseSubType && Geos && taskStatus) {
            getSavedFilters({ filterToSave: this.filterStringToSave })
                .then(result => {
                    console.log('RESULT : '+result);
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
                    console.log('ERRPR : '+error);
                    this.error = error;
                    this.loadSpinner = false;
                });
        }
    }

    /* *********************************** Method to apply filters to the case and task records *********************************** */
    applyFilter() {
        let tempCaseArray = [];
        let tempCaseIdArray = [];
        let tempWhatIdArray = [];
        this.caseData = [];
        this.taskData = [];

        //let shift = String(this.taskShiftNameSelected);
        let status = String(this.taskStatusSelected);

        let red = 0; let yellow = 0; let overdue = 0; let white = 0;

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
            || (status === 'All'))
            {
                this.caseData.push(eachTempCase);
                if (eachTempCase.caseColour === "red") red++;
                else if (eachTempCase.caseColour === "yellow") yellow++;
                else if(eachTempCase.caseColour === "white") white++;
            }
        });

        this.redCount = red;
        this.yellowCount = yellow;
        this.overdueCount = overdue;
        this.whiteCount = white;

        this.template.querySelector("c-sc-provisioning-case-dashboard").calledFromParent(this.caseData);
        this.template.querySelector("c-sc-provisioning-task-dashboard").calledFromParent(this.taskData);
        this.loadSpinner = false;
        //console.log('after load :' + performance.now() / 1000);
        console.log(Math.ceil(window.performance.memory.usedJSHeapSize / 1000000));
    }

    /* *********************************** Method to reset all the filters *********************************** */
    reset()
    {
        this.caseSeveritySelected = ['1', '2', '3','4'];
        this.colorCategorySelected = ['blue', 'white', 'red', 'yellow'];
        this.priorityCustomerSelected = 'All';
        this.caseFundTypeSelected = 'All';
        this.caseLogoTypeSelected = 'All';
        this.caseSubTypeSelected = 'All';
        this.GeographiesSelected = ['Americas','EMEA','AP','Japan','Others'];
        this.taskStatusSelected = 'All';
    }

    /* ********************************************* TOGGLE FILTER ********************************************* */

    showFilter() {
        //var x = this.template.querySelector(".filterDiv");
        this.displayFilter = !this.displayFilter;
    }

    hideFilter() {
        //var x = this.template.querySelector(".filterDiv");
        this.displayFilter = !this.displayFilter;
    }

    /* *************************************** NOTIFICATION CENTER **************************************** */

    getNavRecords(event) {
        //var t0 = performance.now();
        let buttonVal = event.target.value;
        var filteredlist = [];
        this.notificationCenterHeader =
            buttonVal === "red"
                ? "Missed Case Acknowledgement"
                : buttonVal === "yellow"
                    ? "Customer Response Received"
                    : buttonVal === "white"
                    ? "Unassigned Cases"
                    : "Passed Duedate";
                    
        if (buttonVal === "red" || buttonVal === "yellow" || buttonVal === "white") {
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
                else if 
                (this.caseData[i].caseColour === "white" && buttonVal === "white") {
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
        let shiftC = this.template.querySelector(".shiftCls");
        shiftC.querySelector("lightning-icon").style.display = 'none';
        //shiftC.style.display = 'none';
        //let statusC = this.template.querySelector(".statusCls");
        //statusC.style.display = 'none';
        // var t1 = performance.now();
        //console.log("------------>Refresh values took " + (t1 - t0) + " milliseconds to execute.")
    }

    closeNav() {
        var x = this.template.querySelector(".sidenav");
        x.style.width = "0px";
        //let shiftC = this.template.querySelector(".shiftCls");
        //shiftC.style.display = 'block';
        //let statusC = this.template.querySelector(".statusCls");
        //statusC.style.display = 'block';
    }

    openNewTab(event) {
        window.open(event.target.value, "_blank");
    }

    /* *********************************** Method to navigate to shift handover report *********************************** */
    
    navigateToHandoverReport() {
        this.loadSpinner = true;
        emailReport({ })
            .then(result => {
                console.log('RESULT : '+result);
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
                console.log('ERROR : '+error);
                this.error = error;
                this.loadSpinner = false;
            });
    } 
}