/* eslint-disable no-console */
import { LightningElement, wire} from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { loadStyle } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import SC_SProvisioning_Stylesheet from '@salesforce/resourceUrl/SC_BOCC_Dashboard_Stylesheet';
import USER_ID from '@salesforce/user/Id';
import USER_NAME from '@salesforce/schema/User.Name';

import fetchCaseList from '@salesforce/apex/SC_BOCCDashboard_Controller.fetchCaseList'
import getSavedFilters from '@salesforce/apex/SC_BOCCDashboard_Controller.saveBOCCFilters'

const caseColumns = [
    {        
        type: 'text',
        wrapText: true,
        initialWidth: 75,
        cellAttributes: { iconName: {fieldName:'hasTransitionText'}, alignment: 'center', width:100, class:'transIconCls'}
    },
    {        
        label: 'AKAM Case ID',
        fieldName: 'caseUrl',
        type: 'url',
        typeAttributes: { label: { fieldName: 'akamCaseId' },tooltip: 'Go to Case', target: '_blank'},
        cellAttributes: { alignment: 'left',class: { fieldName:'caseColour' } },
        initialWidth: 146,
        wrapText: true
    },
    {        
        label: 'Account Name',
        fieldName: 'accountUrl',
        type: 'url',
        typeAttributes: { label: { fieldName: 'accountName' },tooltip: 'Go to Account', target: '_blank'},
        initialWidth: 154,
        wrapText: true
    },
    {        
        label: 'Case Subject',
        fieldName: 'caseSubject',
        type: 'text',
        initialWidth: 176,
        wrapText: true
    },
    {        
        label: 'BOCC Support Type',
        fieldName: 'caseBoccSupportType',
        type: 'text',
        initialWidth: 121,
        wrapText: true
    },
    {        
        label: 'Status',
        fieldName: 'caseStatus',
        type: 'text',
        initialWidth: 108,
        wrapText: true
    },
    {        
        label: 'Work Type',
        fieldName: 'caseWorkType',
        type: 'text',
        initialWidth: 104,
        wrapText: true
    },
    {        
        label: 'Severity',
        fieldName: 'caseSeverity',
        type: 'text',
        initialWidth: 86,
        cellAttributes:{alignment:'center'},
        wrapText: true
    },
    {        
        label: 'Case Owner',
        fieldName: 'caseOwnerNameUrl',
        type: 'url',
        typeAttributes: { label: { fieldName: 'caseOwnerName' },tooltip: 'Go to User', target: '_blank'},
        initialWidth: 147,
        wrapText: true
    },
    {        
        label: 'Case Last Updated',
        fieldName: 'caseLastUpdatedDateTimeString',
        type: 'text',
        initialWidth: 147,
        wrapText: true
    },
    {        
        label: 'Case Last Updated By',
        fieldName: 'caseLastUpdatedByUrl',
        type: 'url',
        typeAttributes: { label: { fieldName: 'caseLastUpdatedBy' },tooltip: 'Go to User', target: '_blank'},
        initialWidth: 147,
        wrapText: true
    },
];

export default class ScBoccDashboard extends LightningElement {
    caseColumns = caseColumns;
    caseSeveritySelected = ['1', '2', '3'];
    caseWorkTypeSelected = ['Reactive', 'Proactive'];

    loadSpinner = true;
    timeoutId;
    userName = '';
    userError = '';

    //Notification Center
    notificationlist = [];
    notificationCenterHeader = "";

    //Summary
    whiteCount = 0;
    yellowCount = 0;
    redCount = 0;
    transitionCount = 0;

    //Case 
    masterCaseList;
    caseDataCopy;
    slicedCaselist;
    totalCases;

    //Pagination 
    currentpage;
    paginationRange;
    offset = 1;
    paginationNumbers;

    //Sort
    sortBy = 'caseSeverity';
    sortDirection = 'asc';

    PollID;

    //GETTER for WORK TYPE filter
    get caseWorkTypeVal(){
        return[
            { label: 'Reactive', value: 'Reactive' },
            { label: 'Proactive', value: 'Proactive' }
        ];
    }
    //GETTER for SEVERITY filter
    get caseSeverityVal(){
        return[
            { label: '1', value: '1' },
            { label: '2', value: '2' },
            { label: '3', value: '3' }
        ];
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

    /* *********************************** CONNECTED CALLBACK *********************************** */
    connectedCallback() 
    {
        this.loadSpinner = true;
        loadStyle(this, SC_SProvisioning_Stylesheet);
        getSavedFilters().then(result => {
            this.caseWorkTypeSelected = result.CaseWorkType;
            this.caseSeveritySelected = result.CaseSeverity;

            this.temp = this.listenForMessage.bind(this);
            window.addEventListener("visibilitychange", this.temp);

            this.populateCase();
        })
        this.loadSpinner = false;
    }

    /* *********************************** DISCONNECTED CALLBACK *********************************** */
    disconnectedCallback()
    {
        window.removeEventListener("visibilitychange", this.temp);
    }

    //WIRE to call apex
    //@wire(fetchCaseList, {caseWorkType: '$caseWorkTypeSelected', caseSeverity: '$caseSeveritySelected'}) 
    //masterCaseList;

    /* *********************************** FETCH CASES FROM APEX *********************************** */
    populateCase(){
        this.loadSpinner = true;
        let workType = (this.caseWorkTypeSelected).toString();
        let sev = (this.caseSeveritySelected).toString();
        fetchCaseList({ caseWorkType: workType, caseSeverity: sev}).then(result =>{
            this.masterCaseList = result;
            this.caseDataCopy = result;
            this.totalCases = this.caseDataCopy.length;
            this.fetchColorCount();
            this.sortData(this.sortBy, this.sortDirection);
            this.loadSpinner = false;
            if(this.caseSearchText)
            {
                this.searchCases();
            }
        })
        .catch(error => {
            this.error = error;
            this.masterCaseList = undefined;
            console.log('populateCase error : ' + JSON.stringify(error));
            this.loadSpinner = false;
        });
    }

    /* *********************************** NOTIFICATION CENTER *********************************** */
    getNavRecords(event){
        let buttonVal = event.target.value;
        let filteredlist = [];
    
        this.notificationCenterHeader = buttonVal === "white" ? "Unassigned Cases":
                                        buttonVal === "yellow" ? "Customer Response Received":
                                        buttonVal === "red" ? "Missed Case Acknowledgement":"Cases In Transition";
        
        for(let i = 0; i < this.masterCaseList.length; i++){
            if(this.masterCaseList[i].caseColour === "white" && buttonVal === "white"){
                let x = {
                    akamId: this.masterCaseList[i].akamCaseId,
                    recUrl: this.masterCaseList[i].caseUrl,
                    Body: "Go to Case " + this.masterCaseList[i].akamCaseId
                };
                filteredlist.push(x);
            }
            if(this.masterCaseList[i].caseColour === "red" && buttonVal === "red"){
                let x = {
                    akamId: this.masterCaseList[i].akamCaseId,
                    recUrl: this.masterCaseList[i].caseUrl,
                    Body: "Go to Case " + this.masterCaseList[i].akamCaseId
                };
                filteredlist.push(x);
            }
            if(this.masterCaseList[i].caseColour === "yellow" && buttonVal === "yellow"){
                let x = {
                    akamId: this.masterCaseList[i].akamCaseId,
                    recUrl: this.masterCaseList[i].caseUrl,
                    Body: "Go to Case " + this.masterCaseList[i].akamCaseId
                };
                filteredlist.push(x);
            }
            if(this.masterCaseList[i].hasTransition === true && buttonVal === "transition"){
                let x = {
                    akamId: this.masterCaseList[i].akamCaseId,
                    recUrl: this.masterCaseList[i].caseUrl,
                    Body: "Go to Case " + this.masterCaseList[i].akamCaseId
                };
                filteredlist.push(x);
            }
        }  
        this.notificationlist = filteredlist;                              
                   
        let sideNav = this.template.querySelector(".sidenav");
        sideNav.style.width = "255px";
    }

    /* *********************************** CLOSE NOTIFICATION CENTER *********************************** */
    closeNav(){
        var x = this.template.querySelector(".sidenav");
        x.style.width = "0px";
    }

    /* *********************************** OPEN CASE FROM NOTIFICATION CENTER *********************************** */
    openNewTab(event) {
        window.open(event.target.value, "_blank");
    }

    /* *********************************** FETCH COLOUR COUNT *********************************** */
    fetchColorCount(){
        let tempCaseList = [];
        let tempArray = [];
        tempCaseList = this.masterCaseList;
        let red = 0; let yellow = 0; let transition = 0; let white = 0;

        tempCaseList.forEach(eachTempCase =>{
            if(eachTempCase.hasTransition === true) transition++;
            if(eachTempCase.caseColour === "white") white++;
            else if(eachTempCase.caseColour === "yellow") yellow++;
            else if(eachTempCase.caseColour === "red") red++;
        });
        this.whiteCount = white;
        this.yellowCount = yellow;
        this.redCount = red;
        this.transitionCount = transition;

        //IF TOGGLE IS CHECKED
        if(this.template.querySelector('.myBox').checked)
        {
            let tableCaseDataCopy = this.caseDataCopy;
            tempArray = [];
            let name = this.userName;
            tableCaseDataCopy.forEach(function(eachRow){
                if(eachRow.caseOwnerName){
                    if(eachRow.caseOwnerName === name){
                        tempArray.push(eachRow);
                    }
                }
            });
            this.caseDataCopy = tempArray;
        }
        if(this.template.querySelector('.unassignedBox').checked)
        {
            let tableCaseDataCopy = this.caseDataCopy;
            tempArray = [];
            tableCaseDataCopy.forEach(function(eachRow){
                if(eachRow.caseStatus){
                    if(eachRow.caseStatus === 'Unassigned'){
                        tempArray.push(eachRow);
                    }
                }
            });
            this.caseDataCopy = tempArray;
        }
        if(this.template.querySelector('.transitionBox').checked)
        {
            let tableCaseDataCopy = this.caseDataCopy;
            tempArray = [];
            tableCaseDataCopy.forEach(function(eachRow){
                if(eachRow.hasTransition){
                    tempArray.push(eachRow);
                }
            });
            this.caseDataCopy = tempArray;
        }

        this.totalCases = this.caseDataCopy.length;
        this.loadSpinner = false;
    }

    /* *********************************** SORT CASES BASED ON COLOUR *********************************** */
    sortData(fieldname,direction){
        let tempCaseList = [];
        let redCases = []; let whiteCases = []; let yellowCases = []; let blueCases = [];
        let sortedWhiteCases = []; let sortedYellowCases = []; let sortedRedCases = []; let sortedBlueCases = [];
        tempCaseList = this.caseDataCopy;

        tempCaseList.forEach(eachTempCase =>{
            if(eachTempCase.caseColour === 'red') redCases.push(eachTempCase);
            else if(eachTempCase.caseColour === 'white') whiteCases.push(eachTempCase);
            else if(eachTempCase.caseColour === 'yellow') yellowCases.push(eachTempCase);
            else blueCases.push(eachTempCase);
        });

        sortedWhiteCases = this.sortColorCases(whiteCases,fieldname,direction);
        sortedYellowCases = this.sortColorCases(yellowCases,fieldname,direction);
        sortedRedCases = this.sortColorCases(redCases,fieldname,direction);
        sortedBlueCases = this.sortColorCases(blueCases,fieldname,direction);

        this.caseDataCopy = [...sortedWhiteCases,...sortedRedCases,...sortedYellowCases,...sortedBlueCases];
        this.calculatecasepaginationlogic();
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
            return (a[fieldname]);
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

    /* *********************************** Method called when WORK TYPE filter is changed *********************************** */
    caseWorkTypeChanged(event){
        if(!event.detail.value.toString()){
            let WTvals = [];
            WTvals.push(this.caseWorkTypeSelected.toString());
            this.caseWorkTypeSelected = WTvals
            const toastEvt = new ShowToastEvent({
                title: "",
                message: "Please select atleast one Work Type value",
                variant: "warning",
                mode: "dismissible",
                duration: 5000
            });
            this.dispatchEvent(toastEvt);
        }
        else{
            this.caseWorkTypeSelected = event.detail.value;
        }
    }

    /* *********************************** Method called when SEVERITY filter is changed *********************************** */
    caseSeverityChanged(event){
        //this.caseSeveritySelected = event.detail.value;
        if(!event.detail.value.toString()){
            let sevVals = [];
            sevVals.push(this.caseSeveritySelected.toString());
            this.caseSeveritySelected = sevVals
            const toastEvt = new ShowToastEvent({
                title: "",
                message: "Please select atleast one Severity value",
                variant: "warning",
                mode: "dismissible",
                duration: 5000
            });
            this.dispatchEvent(toastEvt);
        }
        else{
            this.caseSeveritySelected = event.detail.value;
        }
    }

    /* *********************************** Method to check if all filters are selected and call saveFilter() *********************************** */
    saveAndApply(){
        this.loadSpinner = true;
        let workType = (this.caseWorkTypeSelected).toString();
        let sev = (this.caseSeveritySelected).toString();
        if (!workType) {
            const toastEvt = new ShowToastEvent({
                title: "",
                message: "Please select atleast one Work Type value",
                variant: "warning",
                mode: "dismissible",
                duration: 4000
            });
            this.dispatchEvent(toastEvt);
            this.loadSpinner = false;
        }
        else if (!sev) {
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
        else {
            //this.populateCase();
            this.resetPollerAndRefresh();
            this.saveFilter();
        }
    }

    /* *********************************** SAVE SELECTED FILTERS *********************************** */
    saveFilter(){
        let workType = this.caseWorkTypeSelected.toString();
        let sev = this.caseSeveritySelected.toString();
        let filterString = 'CaseWorkType:'+workType+'&CaseSeverity:'+sev;
        getSavedFilters({filterToSave:filterString})
        .then(result =>{
            console.log('RESULT : '+result);
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
            console.log('ERROR : '+error);
            this.loadSpinner = false;
        });
    }

    /* *********************************** RESET ALL FILTERS *********************************** */
    reset(){
        this.caseWorkTypeSelected = ['Reactive', 'Proactive'];
        this.caseSeveritySelected = ['1', '2', '3'];
        this.resetPollerAndRefresh();
        this.saveFilter();
    }

    /* ******************************* TOGGLE CASES METHODS ******************************* */
    toggleChecked(event){
        let allCaseData = this.masterCaseList;
        let tempArray = [];
        let checkedOption = event.target.name;
        let name = this.userName;

        this.loadSpinner = true;
        if (!event.target.checked) {
            this.caseDataCopy = allCaseData;
            this.totalCases = this.caseDataCopy.length;
            this.sortData(this.sortBy, this.sortDirection);
            //this.calculatecasepaginationlogic();
        }
        else{
            if(checkedOption === 'my'){
                allCaseData.forEach(function(eachRow){
                    if(eachRow.caseOwnerName){
                        if(eachRow.caseOwnerName === name){
                            tempArray.push(eachRow);
                        }
                    }
                });
                this.template.querySelector('.unassignedBox').checked = false;
                this.template.querySelector('.transitionBox').checked = false;
            }
            else if(checkedOption === 'unassigned'){
                allCaseData.forEach(function(eachRow){
                    if(eachRow.caseStatus){
                        if(eachRow.caseStatus === 'Unassigned'){
                            tempArray.push(eachRow);
                        }
                    }
                });
                this.template.querySelector('.myBox').checked = false;
                this.template.querySelector('.transitionBox').checked = false;
            }
            else if(checkedOption === 'transition'){
                allCaseData.forEach(function(eachRow){
                    if(eachRow.hasTransition){
                        tempArray.push(eachRow);
                    }
                });
                this.template.querySelector('.myBox').checked = false;
                this.template.querySelector('.unassignedBox').checked = false;
            }
            this.caseDataCopy = tempArray;
            this.totalCases = this.caseDataCopy.length;
            this.sortData(this.sortBy, this.sortDirection);
        }
        this.loadSpinner = false;

        if(this.caseSearchText)
        {
            this.searchCases();
        }
    }

    /* ******************************* SEARCH CASE DASHBOARD ******************************* */
    delayedSearch(){
        clearTimeout(this.timeoutId); // no-op if invalid id
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.timeoutId = setTimeout(this.searchCases.bind(this), 500); // Adjust as necessary
    }

    /* ******************************* CLEAR SEARCH ******************************* */
    clearSearchInput(){
        this.template.querySelector('.labelHidden').value = '';
        this.searchCases();
    }

    /* ******************************* SEARCH CASE DASHBOARD ******************************* */
    searchCases(){
        let allCaseData = this.masterCaseList;
        let searchFilter = this.template.querySelector('.labelHidden').value;
        this.caseSearchText = searchFilter;
        searchFilter = searchFilter.toUpperCase();

        this.loadSpinner = true;
        let tempArray = [];
        allCaseData.forEach(function(eachRow){
            if((eachRow.akamCaseId && eachRow.akamCaseId.toUpperCase().indexOf(searchFilter) !== -1)
            ||(eachRow.accountName && eachRow.accountName.toUpperCase().indexOf(searchFilter) !== -1)
            ||(eachRow.caseSubject && eachRow.caseSubject.toUpperCase().indexOf(searchFilter) !== -1)
            ||(eachRow.caseBoccSupportType && eachRow.caseBoccSupportType.toUpperCase().indexOf(searchFilter) !== -1)
            ||(eachRow.caseStatus && eachRow.caseStatus.toUpperCase().indexOf(searchFilter) !== -1)
            ||(eachRow.caseOwnerName && eachRow.caseOwnerName.toUpperCase().indexOf(searchFilter) !== -1)
            ||(eachRow.caseLastUpdatedBy && eachRow.caseLastUpdatedBy.toUpperCase().indexOf(searchFilter) !== -1)
            )
            {
                tempArray.push(eachRow);
            }
        });
        this.caseDataCopy = tempArray;
        
        //IF TOGGLE IS CHECKED
        if(this.template.querySelector('.myBox').checked)
        {
            let tableCaseDataCopy = this.caseDataCopy;
            tempArray = [];
            let name = this.userName;
            tableCaseDataCopy.forEach(function(eachRow){
                if(eachRow.caseOwnerName){
                    if(eachRow.caseOwnerName === name){
                        tempArray.push(eachRow);
                    }
                }
            });
            this.caseDataCopy = tempArray;
        }
        if(this.template.querySelector('.unassignedBox').checked)
        {
            let tableCaseDataCopy = this.caseDataCopy;
            tempArray = [];
            tableCaseDataCopy.forEach(function(eachRow){
                if(eachRow.caseStatus){
                    if(eachRow.caseStatus === 'Unassigned'){
                        tempArray.push(eachRow);
                    }
                }
            });
            this.caseDataCopy = tempArray;
        }
        if(this.template.querySelector('.transitionBox').checked)
        {
            let tableCaseDataCopy = this.caseDataCopy;
            tempArray = [];
            tableCaseDataCopy.forEach(function(eachRow){
                if(eachRow.hasTransition){
                    tempArray.push(eachRow);
                }
            });
            this.caseDataCopy = tempArray;
        }

        this.totalCases = this.caseDataCopy.length;
        this.sortData(this.sortBy, this.sortDirection);
        this.calculatecasepaginationlogic();
        this.loadSpinner = false;
    }

    /* ******************************* REFRESH CASES ******************************* */
    refreshCaseTable(){
        this.loadSpinner = true;
        this.populateCase();
    }

    /* ******************************* PAGINATION HANDLING ******************************* */
    handlePaginationClick(event){
        let page = event.target.dataset.item;
        this.offset=page;
        this.slicedCaselist = this.caseDataCopy.slice((this.offset - 1) * 150, this.offset * 150);
        this.currentpage=this.offset+'/'+this.paginationNumbers;
        let x = this.template.querySelector(".panelCase");
        if (this.slicedCaselist.length <= 5)
            x.style.height = "30vh";
        else
            x.style.height = "70vh";
    }
    calculatecasepaginationlogic()
    {
        if(this.totalCases === 0)
        {
            this.paginationNumbers = 1;
        }
        else
        {
            this.paginationNumbers = Math.ceil(this.totalCases / 150);
        }
        if(this.offset>this.paginationNumbers) this.offset=1;
        
        this.currentpage=this.offset+'/'+this.paginationNumbers;
        this.paginationRange = [];
        for (let i = 1; i <= this.paginationNumbers; i++) {
            this.paginationRange.push(i);
        }
        this.slicedCaselist = this.caseDataCopy.slice((this.offset - 1) * 150, this.offset * 150);
        let x = this.template.querySelector(".panelCase");
        if (this.totalCases <= 5)
            x.style.height = "30vh";
        else
            x.style.height = "70vh";
    }

    /* *********************************** RESET + REFRESH *********************************** */
    resetPollerAndRefresh(event) 
    {    
        window.clearInterval(this.PollID);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.PollID = setInterval(() => 
        {
            this.populateCase();
        }, 300000);
        if (typeof (event) != 'undefined') { this.loadSpinner = true; }
        this.populateCase();

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
        if (document.visibilityState !== 'visible') 
        {
            console.log('Away');
            window.clearInterval(this.PollID);
        }
        else 
        {
            console.log('Back');
            this.resetPollerAndRefresh();
        }
    }
}