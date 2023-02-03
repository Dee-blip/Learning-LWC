import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';


import { loadStyle } from 'lightning/platformResourceLoader';
import cssStyleSheet from "@salesforce/resourceUrl/SC_UCD_Stylesheet";
import getMyCaseData from '@salesforce/apex/SC_UCD_HomePage.getMyCases';

import fetchMilestonesAndProducts from '@salesforce/apex/SC_UCD_HomePage.fetchProjectMilestonesAndProducts';
import updateCaseLivingSumm from '@salesforce/apex/SC_UCD_HomePage.updateCaseLivingSummaryAndTimecard';
//import fetchFilters from '@salesforce/apex/SC_UCD_HomePage.fetchCaseFilters';
import updateCaseLOE from '@salesforce/apex/SC_UCD_HomePage.updateCaseLOE';
//import getPSRecTypeId from '@salesforce/apex/SC_UCD_HomePage.getPSCaseRecTypeId';
import getOnLoadWrapperVals from '@salesforce/apex/SC_UCD_HomePage.myCasesOnLoadWrap';
//import cloneSingleCase from '@salesforce/apex/SC_UCD_HomePage.cloneSingleCase';
import acknowledgeCase from '@salesforce/apex/SC_UCD_HomePage.acknowledgeCase';
import fetchCaseLivingSummary from '@salesforce/apex/SC_UCD_HomePage.fetchCaseLivingSummary';
import globalSearchCase from '@salesforce/apex/SC_UCD_HomePage.globalSearchAndRecentlyViewed';
import bulkCloseCases from '@salesforce/apex/SC_UCD_HomePage.bulkCloseCases';
import accountOption from '@salesforce/apex/SC_UCD_HomePage.accountOption';
import cloneMultiCase from '@salesforce/apex/SC_UCD_HomePage.cloneMultiCase';
import fetchSavedAccountForMultiClone from '@salesforce/apex/SC_UCD_HomePage.fetchSavedAccountForMultiClone';

import fetchAccountActiveProjects from '@salesforce/apex/SC_UCD_HomePage.fetchAccountActiveProjects';

import { MY_OPEN_COLS } from './scUCDMyOpenCases_Const_MyOpen';
import { MY_OPEN_COLS_GS2 } from './scUCDMyOpenCases_Const_MyOpen';
import { MY_CREATED_COLS } from './scUCDMyOpenCases_Const_MyOpen';
import { MY_TEAM_COLS } from './scUCDMyOpenCases_Const_MyOpen';

import { ShowToastEvent } from "lightning/platformShowToastEvent";

import {
    subscribe,
    unsubscribe,
    APPLICATION_SCOPE,
    MessageContext
} from 'lightning/messageService';

import caseViewVal from '@salesforce/messageChannel/ucdMessageChannel__c';

const columns = [];

export default class ScUCDMyOpenCases extends NavigationMixin(LightningElement)
{
    columns = columns;
    data;
    now;
    lastUpdated;
    displayCase = true;
    casesCount = 0;

    globalSearchCase;
    globalSearchColumns;

    selectedCases = [];
    closeCaseButtonRef;

    likeStateFilled = false;
    filterState;

    sideNavDiv;
    caseUpdateDiv;
    headerButtonDiv;
    closeMultiCaseButtonDiv;
    caseTableDiv; caseUpdateBodyDiv;
    selectedRows = [];
    bulkCloseCases = [];
    maxRowSelVal = 20;

    allFetchedCases;
    caseListToShow;

    myCreatedToggle = false;

    offset = 1;
    maxoffset;

    sortDirection = 'asc';
    sortedBy = 'ageDays';
    defaultSortDirection = 'asc';

    caseIdToUpdate; akamCaseId; caseRecId;
    caseProject; projSelected;
    recordTypeId;

    caseTimecard;
    activityDate;
    filterValsMap = new Map();
    filterStringToSave = '';

    livingSummaryMap = new Map();
    livingSummaryToShow = '';

    caseMilestone;
    milestoneOptions = [];
    selectedMilestone;
    productOptions = [];
    selectedProduct;
    onlyAccountProj = false;
    selectedAccProj;
    accProjOptions = [];

    todayDate; tomorrowDate;

    caseRemLOEVal; caseHowLongVal; caseWhatWorkVal;

    caseProjectRef;
    selectedMilestoneRef;
    selectedProductRef;
    caseRemLOERef;
    caseHowLongRef;
    caseWhatWorkRef;
    caseNextActDateRef;
    caseLogWorkForRef;
    projToShowRef;

    pollID;

    showLOEModal = false;
    showChangeReason = false;
    newLOE; loeReason; loeComments;
    caseLOEVal;
    caseLOESpinner = false;

    caseRCD;
    showRCDModal = false;
    showRCDSpinner = false;

    showCloseCaseModal = false;
    loadCloseCaseSpinner = false;

    showBulkCloseCaseModal = false;
    loadBulkCloseCaseSpinner = false;

    caseRow;
    showCloneCaseModal = false;
    loadCloneCaseSpinner = false;
    showMultiCloneCaseModal = false;
    loadMultiCloneCaseSpinner = false;
    accountList = [];
    selectedAccounts = []; selectedAccMap = new Map();
    selectedAccSet = new Set();

    showAckCaseModal = false;
    loadAckCaseSpinner = false;

    showEditCaseModal = false;
    loadEditCaseSpinner = false;

    globalSearchEnabled = false;
    tscView = true;
    searchPlaceholderString = 'Search Cases...';
    searchString = '';

    caseIdRowMap = new Map();

    casesDatatableCustomRef;
    panelmyOpenCasesDivRef;
    sideNavOpen = false;

    loeRemaining = 0;
    remLOECalcValRef;

    myCasesViewVal = 'myopen';
    oldViewVal = 'myopen';
    oldViewArray = [];
    caseViewChanged = false;

    myCasesViewOptions = [
        { label: 'My Open Cases', value: 'myopen' },
        { label: 'My Created Cases', value: 'mycreated' },
        { label: 'My Team\'s Cases', value: 'myteam' }
    ];

    headingLabel = 'My Open Cases';

    months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    showSpinner = false;
    showSidePaneSpinner = false;

    sevValue = ['1', '2', '3', '4'];
    sevOptions = [
        { label: '1', value: '1' },
        { label: '2', value: '2' },
        { label: '3', value: '3' },
        { label: '4', value: '4' }
    ];

    utilizedHoursOptions = [
        { label: 'All', value: 'all' },
        { label: '🔴', value: 'red' },
        { label: '🟡', value: 'yellow' }
    ];

    utilizedHoursValue = ['all', 'red', 'yellow'];

    allChecked = true;
    redChecked = true;
    yellowChecked = true;

    reqCompDateVal = false;
    nextActDateVal = false;
    reqCompDateValRef;
    nextActDateValRef;

    searchColVal = 'all';

    myCasesColumnsVal = ['2', '3', '4', '5', '6', '7', '8', '9', '10', '11'];

    loeChangeOptions = [
        { label: 'Additional scope for current product', value: 'Additional scope for current product' },
        { label: 'Wrong product', value: 'Wrong product' },
        { label: 'Customer infrastructure/technology issue', value: 'Customer infrastructure/technology issue' },
        { label: 'Customer unresponsive', value: 'Customer unresponsive' },
        { label: 'Akamai internal issue', value: 'Akamai internal issue' },
        { label: 'Others', value: 'Others' }
    ];

    recentlySearchedMap = new Map();
    recentlySearchedList = [];


    get myCasesViewOptions() {
        return [
            { label: 'My Open Cases', value: 'myopen' },
            { label: 'My Created Cases', value: 'mycreated' },
            { label: 'My Team\'s Cases', value: 'myteam' }
        ];
    }

    get searchCols() {
        return [
            {label: 'All', value: 'all'},
            {label: 'Id', value: 'akamCaseId'},
            {label: (this.myCasesViewVal === 'mycreated' || this.myCasesViewVal === 'myteam') ? 'Owner' : 'Creator', value: 'userNameRole'},
            {label: 'Account', value: 'accountName'},
            {label: 'Subject', value: 'subject'},
            {label: 'LOE', value: 'caseloe'},
            {label: 'Requested Completion Date', value: 'reqCompletionDate'},
            {label: 'Next Planned Activity Date', value: 'nextPlannedActivityDate'},
            {label: 'Status', value: 'status'}
        ];
    }

    get myCasesColumnsValOptions() {
        if (this.myCasesViewVal === 'mycreated' || this.myCasesViewVal === 'myteam') {
            return [
                { label: 'Severity', value: '2' },
                { label: 'Account', value: '3' },
                { label: 'Subject', value: '4' },
                { label: 'LOE', value: '5' },
                { label: 'Requested Completion Date', value: '6' },
                { label: 'Age', value: '7' },
                { label: 'Utilized Hours', value: '8' },
                { label: 'Next Planned Activity Date', value: '9' },
                { label: 'Living Summary', value: '10' },
                { label: 'Status', value: '11' }
            ];
        }
        else if (this.myCasesViewVal === 'myopen') {
            return [
                { label: 'Severity', value: '3' },
                { label: 'Account', value: '4' },
                { label: 'Subject', value: '5' },
                { label: 'LOE', value: '6' },
                { label: 'Requested Completion Date', value: '7' },
                { label: 'Age', value: '8' },
                { label: 'Utilized Hours', value: '9' },
                { label: 'Next Planned Activity Date', value: '10' },
                { label: 'Living Summary', value: '11' },
                { label: 'Status', value: '12' },
            ];
        }
    }


    // **************************************************** FUNCTIONS ****************************************************

    @wire(MessageContext)
    messageContext;

    subscription = null;
    caseViewValue = 'TSC';

    // Encapsulate logic for Lightning message service subscribe and unsubsubscribe
    subscribeToMessageChannel() 
    {
        if (!this.subscription) 
        {
            this.subscription = subscribe(
                this.messageContext,
                caseViewVal,
                (message) => this.handleMessage(message),
                { scope: APPLICATION_SCOPE }
            );
        }
    }

    unsubscribeToMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    headerLabelRef;
    newCaseButtonRef;
    // Handler for message received by component
    handleMessage(message) {
        if (message.caseView.includes('GS2') || message.caseView.includes('TSC')) 
        { this.caseViewValue = message.caseView; }

        if (!this.headerLabelRef) 
        {
            this.headerLabelRef = this.template.querySelector('.headerLabel');
        }
        if (!this.newCaseButtonRef) 
        {
            this.newCaseButtonRef = this.template.querySelector('.newCaseButtonRef');
        }
        if (!this.searchInputDivRef) 
        {
            this.searchInputDivRef = this.template.querySelector('.searchInputDiv');
        }

        if (this.caseViewValue === 'TSC') 
        {
            this.tscView = true;
            this.myCasesViewVal = 'myopen';
            this.sortedBy = 'ageDays';
            this.columns = MY_OPEN_COLS;
        }
        else if (this.caseViewValue === 'GS2') 
        {
            this.tscView = false;
            this.columns = MY_OPEN_COLS_GS2;
            this.headingLabel = 'My Open Cases';
            this.myCasesViewVal = 'myopen';
            this.myCasesColumnsVal = ['2', '3', '4', '5', '6', '7', '8', '9', '10', '11'];
            this.sortedBy = 'reqCompletionDate';
        }

        if (this.sideNavOpen) {
            this.closeCaseSidenav();
        }

        this.refresh();
    }

    constructor() 
    {
        super();
    }

    // ***************************************** CONNECTED CALLBACK *****************************************
    connectedCallback() 
    {
        this.showSpinner = true;

        this.subscribeToMessageChannel();

        loadStyle(this, cssStyleSheet);

        //window.addEventListener("visibilitychange", this.listenForMessage.bind(this));

        getOnLoadWrapperVals({})
        .then(result => {
            this.recordTypeId = result.psRecordTypeId;
            this.recentlySearchedList = result.lastSearchedCases;
            result.lastSearchedCases.forEach(element => {
                this.prevCases.set(element.akamCaseId, element);
            });
            //console.log(this.prevCases.size);
        })
        .catch(error => {
            console.log(JSON.stringify(error));
        });

        var today = new Date();
        var dd = String(today.getDate()).padStart(2, '0') ;
        var mm = String(today.getMonth() + 1).padStart(2, '0'); //January is 0!
        var yyyy = today.getFullYear();
        this.todayDate = yyyy + '-' + mm + '-' + dd;

        var dd = String(today.getDate() + 1).padStart(2, '0');
        var mm = String(today.getMonth() + 1).padStart(2, '0'); //January is 0!
        var yyyy = today.getFullYear();
        this.tomorrowDate = yyyy + '-' + mm + '-' + dd;

        this.filterValsMap['utilizedHoursValue'] = 'allredyellow';

        // POPULATE CASES
        this.pollID = setInterval(() => 
        {
            this.getCases();
        }, 300000);
    }

    /*
    listenForMessage(message) 
    {
        if (document.hidden || document.webkitHidden || document.msHidden || document.mozHidden) {
            window.clearInterval(this.pollID);
        }
        else {
            this.refresh();
        }
    }
    */

    // ***************************************** DISCONNECTED CALLBACK *****************************************
    disconnectedCallback() 
    {
        window.clearInterval(this.pollID);
        this.unsubscribeToMessageChannel();
    }

    // ***************************************** REFRESH *****************************************
    refresh() {
        this.showSpinner = true;
        window.clearInterval(this.pollID);

        this.pollID = setInterval(() => {
            this.getCases();
        }, 300000);

        this.getCases();
    }

    // ***************************************** GET CASES DATA *****************************************

    getCases() 
    {
        //console.log('my cases called ' + JSON.stringify(this.filterValsMap));
        let toSortAgain = false;

        getMyCaseData({ view: this.myCasesViewVal, filter: this.filterValsMap, userView: this.caseViewValue })
        .then(result => 
            {
            this.allFetchedCases = result;
            this.caseListToShow = result;
            if (this.caseViewValue && this.caseViewValue === 'TSC') 
            {
                this.columns = MY_OPEN_COLS;
                if (this.sortedBy !== 'ageDays') 
                { toSortAgain = true; }
            }
            else if (this.caseViewValue && this.caseViewValue === 'GS2') 
            {
                if (this.myCasesViewVal === 'mycreated') 
                { this.columns = MY_CREATED_COLS; }
                else 
                {
                    this.columns = MY_OPEN_COLS_GS2;
                    if (this.myCasesViewVal === 'myteam') 
                    { this.columns = MY_TEAM_COLS; }
                }
                if (this.sortedBy !== 'reqCompletionDate') 
                { toSortAgain = true; }
            }

            this.casesCount = this.caseListToShow.length;

            if (this.searchString && !this.globalSearchEnabled) 
            { this.searchCases(); }

            if (toSortAgain) 
            { this.onHandleSort(); }

            if(this.caseViewValue === 'GS2')
            {
                if(this.caseViewChanged)
                {   this.rehideColumnsOnViewChange(); }
                else if(this.myCasesColumnsVal.length !== 10)
                {   this.handleMyCasesColChange(); }
            }

            this.offset = 1;
            this.spliceData();
            this.lastUpdated = Date.now();

            this.showSpinner = false;
        }).catch(error => 
        {
            this.showSpinner = false;
            console.log(JSON.stringify(error));
        });

        getOnLoadWrapperVals({})
            .then(result => {
                this.recentlySearchedList = result.lastSearchedCases;
                result.lastSearchedCases.forEach(element => {
                    this.prevCases.set(element.akamCaseId, element);
                });
            })
            .catch(error => {
                console.log(JSON.stringify(error));
            });
    }


    // ***************************************** LOAD MORE AND SPLICE *****************************************

    loadMoreData(event) {
        //console.log('load more called');
        if (this.casesCount < 50) {   //console.log('less than 50');
            event.target.enableInfiniteLoading = false;
        }
        else if (this.maxoffset === this.offset) {
            // console.log('max reached');
            event.target.enableInfiniteLoading = false;
        }
        else {
            this.offset++;
            this.data = this.caseListToShow.slice(0, this.offset * 50);
        }
    }

    spliceData() 
    {
        //console.log('splice data called ' + this.casesCount);
        this.data = [];
        if (!this.casesDatatableCustomRef) {
            this.casesDatatableCustomRef = this.template.querySelector('.casesDatatableCustom');
        }

        this.maxoffset = Math.ceil(this.casesCount / 50);
        if (this.casesCount < 50) {
            this.data = this.caseListToShow;
            this.casesDatatableCustomRef.enableInfiniteLoading = false;
        }
        else {
            //console.log('OFFSET : ' + this.offset);
            this.data = this.caseListToShow.slice(0, this.offset * 50);
            this.casesDatatableCustomRef.enableInfiniteLoading = true;
        }

        /*
        if (!this.globalSearchEnabled)
        {
            if(this.casesCount <= 5 && !this.sideNavOpen) 
            {
                if(this.caseViewValue === 'TSC')
                    this.panelmyOpenCasesDivRef.style.height = "50vh";
                else
                    this.panelmyOpenCasesDivRef.style.height = "35vh";
            }
            else {this.panelmyOpenCasesDivRef.style.height = "65vh";}
        }
        */
    }

    // ***************************************** INLINE ROW ACTIONS *****************************************

    handleRowAction(event) 
    {
        let actionName = event.detail.action.name;
        let row = event.detail.row;
        this.caseRow = event.detail.row;
        this.caseRecId = row.caseRecId;
        this.akamCaseId = row.akamCaseId;
        let rowSel = [];
        let accountId;

        if (actionName === 'caseTimecardUpdate') 
        {
            if (this.sideNavOpen) {
                this.closeCaseSidenav();
            }
            else 
            {
                if (row.accountName || row.Project) 
                {
                    if (row.accountName) 
                    {
                        accountId = row.accountUrl.replace('/', '');
                        fetchAccountActiveProjects({ accId: accountId })
                            .then(result => {
                                this.accProjOptions = result;
                                if (result.length === 0) {
                                    const toastEvt = new ShowToastEvent(
                                        {
                                            title: "No Active Projects!",
                                            message: 'There are no active Projects under this Account',
                                            variant: "error",
                                            mode: "dismissible",
                                            duration: 5000
                                        });
                                    this.dispatchEvent(toastEvt);
                                    if(!row.Project)
                                    {   this.projSelected = null; }
                                    //console.log('NO ACTIVE PROJ ' + this.projSelected);
                                }
                            })
                            .catch(error => {
                                let body = error.body;
                                const toastEvt = new ShowToastEvent(
                                    {
                                        title: "Error fetching Active Projects!",
                                        message: body.message,
                                        variant: "error",
                                        mode: "dismissible",
                                        duration: 5000
                                    });
                                this.dispatchEvent(toastEvt);
                                this.projSelected = null;
                                //console.log('ERROR FETCHING ACTIVE ' + this.projSelected);
                            });
                    }
                    if (row.Project) 
                    {
                        this.caseProject = row.Project;
                        this.projSelected = row.Project;
                        this.selectedAccProj = row.Project;
                        if (row.milestone) { this.selectedMilestone = row.milestone; }
                        if (row.projectProduct) { this.selectedProduct = row.projectProduct; }
                        //console.log('ROW HAS PROJECT ' + this.projSelected);
                    }
                    else { this.projSelected = null; }
                }
                else { this.projSelected = null; }

                this.caseProjChange();
                //console.log('AFTER  caseProjChange CALLED' + this.projSelected);


                /*
                if(this.caseRow.caseloe && this.caseRow.billableHours)
                    this.loeRemaining = this.caseRow.caseloe - this.caseRow.billableHours;
                else if(this.caseRow.caseloe)
                    this.loeRemaining = this.caseRow.caseloe;

                if(!this.remLOECalcValRef)
                {
                    this.remLOECalcValRef = this.template.querySelector('.remLOECalcVal');
                }
                this.colourLOERemainingDiv();
                */

                rowSel.push(row.caseRecId);
                this.selectedRows = rowSel;

                this.activityDate = this.tomorrowDate;
                this.livingSummaryMap['caseLogWorkFor'] = false;
                this.livingSummaryMap['caseNextActDate'] = this.tomorrowDate;

                this.openCaseUpdateNav();
                this.casesDatatableCustomRef.hideCheckboxColumn = true;
            }
        }
        else if (actionName === 'livingSummaryConcat') 
        {
            fetchCaseLivingSummary({ caseRecId: this.caseRecId })
                .then(result => {
                    this.livingSummaryToShow = result;

                    let modal = this.template.querySelector('[data-id="' + actionName + '"');
                    if (modal) {
                        modal.classList.remove('slds-hide');
                        modal.toggle();
                    }

                }).catch(error => {
                    console.log(JSON.stringify(error));
                });
        }
        else if (actionName === 'caseloe') 
        {
            this.caseLOEVal = row.caseloe;
            this.newLOE = row.caseloe;
            this.showLOEModal = true;
        }
        else if (actionName === 'closecase') 
        {
            this.showCloseCaseModal = true;
            this.loadCloseCaseSpinner = true;
        }
        else if (actionName === 'clonecase') 
        {
            this.showCloneCaseModal = true;
        }
        else if (actionName === 'multiclonecase') 
        {
            this.showMultiCloneCaseModal = true;
            this.loadSavedMultiCloneAccounts();
            this.loadMultiCloneCaseSpinner = true;
        }
        else if (actionName === 'ackcase') 
        {
            this.showAckCaseModal = true;
        }
        else if (actionName === 'editcase') 
        {
            this.showEditCaseModal = true;
            this.loadEditCaseSpinner = true;
        }
        else if (actionName === 'relatedcase') 
        {
            this.newPSRelatedCase();
        }
        else if(actionName === 'reqCompletionDate')
        {
            this.showRCDSpinner = true;
            this.showRCDModal = true;
        }
    }

    // ***************************************** ON CASE ROW SELECTION *****************************************

    casesSelected(event) {
        let selectRows = this.template.querySelector('.casesDatatableCustom').getSelectedRows();

        if (this.caseViewValue === 'GS2') {
            if (!this.closeCaseButtonRef) {
                this.closeCaseButtonRef = this.template.querySelector('.closeMultiCaseButton');
                //console.log('button initialised');
            }
            //console.log(JSON.stringify(this.closeCaseButton));

            if (selectRows.length > 0) {
                this.closeCaseButtonRef.disabled = false;

                if (selectRows.length === this.maxRowSelVal) {
                    const toastEvt = new ShowToastEvent({
                        title: "",
                        message: "A maximum of " + this.maxRowSelVal + " records can be selected at a time",
                        variant: "warning",
                        mode: "dismissible",
                        duration: 5000
                    });
                    this.dispatchEvent(toastEvt);
                }
            }
            else {
                this.closeCaseButtonRef.disabled = true;
            }
        }
    }

    // ***************************************** TOGGLE CASE TABLE VIEW *****************************************


    hidemyopencasesTable() {
        var x = this.template.querySelector(".panelmyOpenCases");
        x.style.height = "0vh";
        this.displayCase = !this.displayCase;
    }

    showmyopencasesTable() {
        let x = this.template.querySelector(".panelmyOpenCases");
        x.style.height = "65vh";
        if (this.casesCount <= 5 && !this.globalSearchEnabled)
            x.style.height = "50vh";
        this.displayCase = !this.displayCase;
    }



    // ***************************************** CASE AND TIMECARD UPDATE SIDENAV + SAVE *****************************************
    openCaseUpdateNav(event) {
        this.sideNavOpen = true;
        if (!this.caseUpdateDiv || !this.caseTableDiv || !this.caseUpdateBodyDiv) {
            this.caseUpdateDiv = this.template.querySelector(".caseUpdateDiv");
            this.caseTableDiv = this.template.querySelector(".caseTableDiv");
            this.caseUpdateBodyDiv = this.template.querySelector(".caseUpdateNav");
        }

        this.caseTableDiv.classList.toggle('slds-size_4-of-5');
        this.caseTableDiv.classList.toggle('crunchRightPadding');
        this.caseTableDiv.classList.toggle('slds-size_5-of-5');
        this.caseUpdateDiv.classList.toggle('slds-hide');
        this.caseUpdateDiv.style.leftPadding = 0;

        if (this.caseViewValue === 'GS2') {
            if (!this.headerButtonDiv) {
                this.headerButtonDiv = this.template.querySelector(".customiseColumnsButton");
            }
            if (this.headerButtonDiv) { this.headerButtonDiv.classList.add('slds-size_1-of-9'); }
            //this.headerButtonDiv.classList.remove('slds-size_1-of-8');
            this.closeMultiCaseButtonDiv = this.template.querySelector(".closeMultiCaseButtonDiv");
            // this.closeMultiCaseButtonDiv.classList.add('slds-size_1-of-8');
            this.closeMultiCaseButtonDiv.classList.remove('slds-size_1-of-4');
        }
        else {
            this.closeMultiCaseButtonDiv = this.template.querySelector(".newCaseButtonRef");
            this.closeMultiCaseButtonDiv.classList.add('slds-size_1-of-3');
            this.closeMultiCaseButtonDiv.classList.remove('slds-size_1-of-2');
        }
    }

    closeCaseSidenav() 
    {
        this.sideNavOpen = false;
        this.caseProject = '';
        this.selectedAccProj = '';
        if (!this.caseUpdateDiv || !this.caseTableDiv || !this.caseUpdateBodyDiv) {
            this.caseUpdateDiv = this.template.querySelector(".caseUpdateDiv");
            this.caseTableDiv = this.template.querySelector(".caseTableDiv");
            this.caseUpdateBodyDiv = this.template.querySelector(".caseUpdateNav");
        }
        this.caseTableDiv.classList.toggle('slds-size_4-of-5');
        this.caseTableDiv.classList.toggle('crunchRightPadding');
        this.caseTableDiv.classList.toggle('slds-size_5-of-5');
        this.caseUpdateDiv.classList.toggle('slds-hide');

        if (this.caseViewValue === 'GS2') 
        {
            if (this.headerButtonDiv) { this.headerButtonDiv.classList.remove('slds-size_1-of-9'); }
            //this.headerButtonDiv.classList.add('slds-size_1-of-8');
            this.closeMultiCaseButtonDiv.classList.remove('slds-size_1-of-8');
            this.closeMultiCaseButtonDiv.classList.add('slds-size_1-of-4');
        }
        else 
        {
            this.closeMultiCaseButtonDiv = this.template.querySelector(".newCaseButtonRef");
            this.closeMultiCaseButtonDiv.classList.remove('slds-size_1-of-3');
            this.closeMultiCaseButtonDiv.classList.add('slds-size_1-of-2');
        }

        /*
        this.template.querySelector('.caseUpdateDiv').scrollTop = 0;
        this.template.querySelector('.caseUpdateNav').scrollTop = 0;
        this.template.querySelector('.caseUpdateBodyDiv').scrollTop = 0;
        console.log(this.template.querySelector('.caseUpdateDiv').scrollTop);
        console.log(this.template.querySelector('.caseUpdateNav').scrollTop);
        console.log(this.template.querySelector('.caseUpdateBodyDiv').scrollTop);
        */

        this.selectedRows = [];
        this.casesDatatableCustomRef.hideCheckboxColumn = false;
        this.clearSideNavFields();
    }

    clearSideNavFields() 
    {
        if (!this.caseProjectRef) 
        {
            this.caseProjectRef = this.template.querySelector(".caseProject");
        }
        /*
        if (!this.selectedMilestoneRef) {
            this.selectedMilestoneRef = this.template.querySelector(".selectedMilestone");
        }
        if (!this.selectedProductRef) {
            this.selectedProductRef = this.template.querySelector(".selectedProduct");
        }
        */

        if (!this.caseWhatWorkRef) {
            this.caseWhatWorkRef = this.template.querySelector(".caseWhatWork");
        }
        if (!this.caseHowLongRef) {
            this.caseHowLongRef = this.template.querySelector(".caseHowLong");
        }
        if (!this.caseRemLOERef) {
            this.caseRemLOERef = this.template.querySelector(".caseRemLOE");
        }
        if (!this.caseNextActDateRef) {
            this.caseNextActDateRef = this.template.querySelector(".caseNextActDate");
        }
        if (!this.caseLogWorkForRef) {
            this.caseLogWorkForRef = this.template.querySelector(".caseLogWorkFor");
        }

        if (!this.projToShowRef) 
        {
            this.projToShowRef = this.template.querySelector(".projToShow");
        }

        //this.caseProjectRef.value = null;
        //this.selectedMilestoneRef.value = null;
        //this.selectedProductRef.value = null;
        this.caseWhatWorkRef.value = null;
        this.caseHowLongRef.value = null;
        this.caseRemLOERef.value = null;
        this.caseNextActDateRef.value = this.tomorrowDate;
        this.caseLogWorkForRef.checked = false;
        this.projToShowRef.checked = false;
        this.onlyAccountProj = false;
    }

    reqCompDateChange(event) {
        this.filterValsMap[event.target.name] = event.target.checked;
        if (!this.reqCompDateValRef) {
            this.reqCompDateValRef = this.template.querySelector('.reqCompDateVal');
        }
    }

    nextActDateChange(event) {
        this.filterValsMap[event.target.name] = event.target.checked;
        if (!this.nextActDateValRef) {
            this.nextActDateValRef = this.template.querySelector('.nextActDateVal');
        }
        this.template.querySelector('.caseUpdateDiv').scrollTop = 0;
        this.template.querySelector('.caseUpdateNav').scrollTop = 0;
        this.template.querySelector('.caseUpdateBodyDiv').scrollTop = 0;
    }

    livingSummaryFieldChange(event) {
        this.livingSummaryMap[event.target.name] = event.target.value;
        //console.log(event.target.name);

        if (!this.remLOECalcValRef) {
            this.remLOECalcValRef = this.template.querySelector('.remLOECalcVal');
        }

        /*
        if(event.target.name === 'caseHowLong')
        {
            if(this.caseRow.caseloe && this.caseRow.billableHours)
                this.loeRemaining = this.caseRow.caseloe - this.caseRow.billableHours - event.target.value;
            else if(this.caseRow.caseloe)
                this.loeRemaining = this.caseRow.caseloe - event.target.value;
            
            this.colourLOERemainingDiv();
        }
        */
    }

    logWorkTodayChange(event) 
    {
        this.livingSummaryMap[event.target.name] = event.target.checked;
        if (event.target.checked) 
        {
            this.activityDate = this.todayDate;
            this.livingSummaryMap['caseNextActDate'] = this.todayDate;
        }
        else if (!event.target.checked) 
        {
            this.activityDate = this.tomorrowDate;
            this.livingSummaryMap['caseNextActDate'] = this.tomorrowDate;
        }
    }

    projToShowChange(event) 
    {
        this.onlyAccountProj = event.target.checked;
        //this.selectedMilestone = null;this.milestoneOptions = [];
        //this.selectedProduct = null;this.productOptions = [];
    }

    saveCaseAndTimecard() 
    {
        this.showSidePaneSpinner = true;
        /* GENERATE LIVING SUMMARY STRING */
        let livingSummaryString = new Map();

        var now = new Date();
        var thisMonth = this.months[now.getMonth()];
        var errorsPresent = false;

        this.template.querySelectorAll('.sideNavFields').forEach(element => 
        {
            if (!element.reportValidity()) 
            {
                errorsPresent = true;
            }
        });

        if (!this.livingSummaryMap.caseWhatWork
            || !this.livingSummaryMap.caseHowLong
            || !this.livingSummaryMap.caseRemLOE
            || !this.livingSummaryMap.caseNextActDate
            || !this.projSelected
            || !this.selectedMilestone
            || !this.selectedProduct) 
        {
            errorsPresent = true;
        }

        if(errorsPresent)
        {
            this.showSidePaneSpinner = false;
            const toastEvt = new ShowToastEvent({
                title: "Error!",
                message: "Please ensure you fill in all the required fields with valid values",
                variant: "error",
                mode: "dismissible",
                duration: 5000
            });
            this.dispatchEvent(toastEvt);
        }
        else if(!errorsPresent) 
        {
            livingSummaryString = ': '
                + this.livingSummaryMap.caseWhatWork + ' | '
                + 'Time Spent: ' + this.livingSummaryMap.caseHowLong + ' | '
                + 'LOE Needed: ' + this.livingSummaryMap.caseRemLOE;

            updateCaseLivingSumm({ caseLivingSummaryInbound: livingSummaryString, caseId: this.caseRecId, akamCaseId: this.akamCaseId, logForYesterday: this.livingSummaryMap['caseLogWorkFor'], projId: this.projSelected, milestoneId: this.selectedMilestone, productId: this.selectedProduct, caseWhatWork: this.livingSummaryMap.caseWhatWork, caseHowLong: this.livingSummaryMap.caseHowLong, caseNextActDate: this.livingSummaryMap.caseNextActDate, bestGuess: this.livingSummaryMap.caseRemLOE })
                .then(result => {
                    let str;
                    //console.log('MESSAGE : ' + JSON.stringify(result));
                    this.showSidePaneSpinner = false;
                    str = result;
                    const toastEvt = new ShowToastEvent({
                        title: "Success!",
                        message: str,
                        variant: "success",
                        mode: "dismissible",
                        duration: 8000
                    });
                    this.dispatchEvent(toastEvt);
                    this.closeCaseSidenav();
                    this.refresh();

                }).catch(error => 
                {
                    this.showSidePaneSpinner = false;
                    console.log(JSON.stringify(error));
                    let errorBody = error.body;
                    const toastEvt = new ShowToastEvent({
                        title: "Error!",
                        message: errorBody.message,
                        variant: "error",
                        mode: "dismissible",
                        duration: 7000
                    });
                    this.dispatchEvent(toastEvt);
                    
                });
        }
    }

    // ***************************************** FILTER *****************************************
    filterMenuRef;
    /*
    openFilterMenu(event) {
        console.log('Open Menu Clicked');
        if (!this.filterMenuRef) {
            this.filterMenuRef = this.template.querySelector('.caseFilterMenu');
        }
    }
    */

    utilHourChange(event) {
        let str;

        str = this.filterValsMap['utilizedHoursValue'];
        if (event.detail.checked && !str.includes(event.target.name)) {
            this.filterValsMap['utilizedHoursValue'] = str + event.target.name;
        }
        else
            if (!event.detail.checked && str.includes(event.target.name)) {
                this.filterValsMap['utilizedHoursValue'] = str.replace(event.target.name, '');
            }
        //console.log(this.filterValsMap['utilizedHoursValue']);
    }

    resetFilter() {
        this.filterValsMap['sevValue'] = '1,2,3,4';
        this.sevValue = ['1', '2', '3', '4'];

        this.filterValsMap['utilizedHoursValue'] = 'allredyellow';
        this.utilizedHoursValue = ['all', 'red', 'yellow'];

        let ref = this.template.querySelector('.allChecked');
        ref.checked = true;
        ref = this.template.querySelector('.redChecked');
        ref.checked = true;
        ref = this.template.querySelector('.yellowChecked');
        ref.checked = true;

        this.nextActDateValRef = this.template.querySelector('.nextActDateVal');
        this.nextActDateValRef.checked = false;
        this.reqCompDateValRef = this.template.querySelector('.reqCompDateVal');
        this.reqCompDateValRef.checked = false;
    }

    applyFilter(event) 
    {
        this.showSpinner = true;
        //console.log(JSON.stringify(this.filterValsMap));
        if (!this.filterMenuRef) {
            this.filterMenuRef = this.template.querySelector('.caseFilterMenu');
        }

        getMyCaseData({ view: this.myCasesViewVal, filter: this.filterValsMap, userView: this.caseViewValue })
            .then(result => {
                this.caseListToShow = result;
                this.allFetchedCases = result;
                this.casesCount = result.length;

                if (this.searchString && !this.globalSearchEnabled) 
                { this.searchCases(); }

                this.onHandleSort();

                this.spliceData();
                //setTimeout(this.closeFilterMenu.bind(this), 500);
                //setTimeout(this.closeFilterMenu.bind(this), 500);
                this.showSpinner = false;
            }).catch(error => {
                this.showSpinner = false;
                console.log(JSON.stringify(error));
            });
    }

    /*
    closeFilterMenu()
    {
        this.filterMenuRef.classList.remove('slds-is-open');   
    }
    */

    filterChange(event) {
        if (!event.detail.value.toString()) {
            const toastEvt = new ShowToastEvent({
                title: "",
                message: "Please select atleast one value",
                variant: "warning",
                mode: "dismissible",
                duration: 5000
            });
            this.dispatchEvent(toastEvt);
        }
        else {
            this.filterValsMap[event.target.name] = event.target.value.toString();
        }
    }


    // ***************************************** PICK PROJECT/MILESTONE/PRODUCT IN SIDENAV *****************************************
    milestoneChange(event) {
        //console.log(event.target.value);
        this.selectedMilestone = event.target.value;
    }

    productChange(event) {
        //console.log(event.target.value);
        this.selectedProduct = event.target.value;
    }

    accProjChange(event) 
    {
        this.selectedAccProj = event.target.value;
        this.caseProject = event.target.value;
        this.projSelected = event.target.value;
        //console.log(this.projSelected);
        this.caseProjChange();
    }

    caseProjChange(event) 
    {
        //console.log('caseProjChange called');
        if (event) { this.projSelected = event.target.value; }

        //console.log(this.projSelected);

        if(this.projSelected) 
        {
            fetchMilestonesAndProducts({ projId: this.projSelected })
                .then(result => {
                    this.milestoneOptions = result.milestones;
                    this.productOptions = result.products;
                }).catch(error => {
                    let body = error.body;
                    const toastEvt = new ShowToastEvent(
                        {
                            title: "Invalid Project!",
                            message: body.message,
                            variant: "error",
                            mode: "dismissible",
                            duration: 10000
                        });
                    this.dispatchEvent(toastEvt);
                    this.selectedMilestone = null; this.milestoneOptions = [];
                    this.selectedProduct = null; this.productOptions = [];
                });
        }
        else 
        {
            this.milestoneOptions = [];
            this.productOptions = [];
        }
    }

    // ***************************************** SORT *****************************************

    sortBy(field, reverse, primer) {
        const key = primer
            ? function (x) {
                if (typeof x[field] === 'string') { return primer(x[field].toLowerCase()); }
                else { return primer(x[field]); }
            }
            : function (x) {
                if (typeof x[field] === 'string') { return x[field].toLowerCase(); }
                else { return x[field]; }
            };

        return function (a, b) {
            if (key(a) === null || typeof key(a) === 'undefined') {
                return 1;
            }
            else if (key(b) === null || typeof key(b) === 'undefined') {
                return -1;
            }
            else {
                a = key(a);
                b = key(b);
                return reverse * ((a > b) - (b > a));
            }
        }
    }

    onHandleSort(event) {
        //this.offset = 1;
        let sortedBy;
        let sortDirection;

        if (event) {
            sortedBy = event.detail.fieldName;
            sortDirection = event.detail.sortDirection;
            this.sortDirection = sortDirection;
            this.sortedBy = sortedBy;
        }
        else {
            sortedBy = this.sortedBy;
            sortDirection = this.sortDirection;
        }

        if (sortedBy === 'accountUrl') { sortedBy = 'accountName'; }
        else if (sortedBy === 'caseloe') { sortedBy = 'caseloeval'; }
        else if (sortedBy === 'akamCaseIdText') { sortedBy = 'userNameRole'; }
        else if (sortedBy === 'nextPlannedActivityDate') { sortedBy = 'nextPlannedActivityDateVal'; }
        else if (sortedBy === 'reqCompletionDate') { sortedBy = 'reqCompletionDateVal'; }
        else if(sortedBy === 'caseUrl') {sortedBy = 'akamCaseId'}
        else if(sortedBy === 'userNameRoleUrl') {sortedBy = 'userNameRole'}

        const cloneData = [...this.caseListToShow];
        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.caseListToShow = cloneData;

        if (event) {
            this.offset = 1;
            if (!this.casesDatatableCustomRef) {
                this.casesDatatableCustomRef = this.template.querySelector('.casesDatatableCustom');
            }
            this.casesDatatableCustomRef.enableInfiniteLoading = false;
            setTimeout(this.setInfiniteloading.bind(this), 500);
            this.data = cloneData.slice(0, 50);
        }
        else {
            this.data = cloneData.slice(0, this.offset * 50);
        }
    }


    setInfiniteloading() {
        if (!this.casesDatatableCustomRef) {
            this.casesDatatableCustomRef = this.template.querySelector('.casesDatatableCustom');
        }
        this.casesDatatableCustomRef.enableInfiniteLoading = true;
    }

    // ***************************************** LOE UPDATE *****************************************
    loeValChange(event) 
    {
        this.newLOE = Math.floor(event.target.value);
    }

    loeReasonChange(event) {
        this.loeReason = event.target.value;
        if (event.target.value === 'Others') { this.showChangeReason = true; }
        else { this.showChangeReason = false; this.loeComments = ''; }
    }

    loeCommentsChange(event) {
        this.loeComments = event.target.value;
    }

    saveLOE() 
    {
        this.caseLOESpinner = true;

        if (!this.newLOE || !this.loeReason || !this.template.querySelector('.newLOE').reportValidity()) 
        {
            const toastEvt = new ShowToastEvent({
                title: "",
                message: "Please set LOE Hours and Reason fields",
                variant: "error",
                mode: "dismissible",
                duration: 5000
            });
            this.dispatchEvent(toastEvt);
            this.caseLOESpinner = false;
        }
        else if (this.loeReason === 'Others' && !this.loeComments) {
            const toastEvt = new ShowToastEvent({
                title: "",
                message: "Please fill in LOE change comments",
                variant: "error",
                mode: "dismissible",
                duration: 5000
            });
            this.dispatchEvent(toastEvt);
            this.caseLOESpinner = false;
        }
        else 
        {
            if (this.loeComments) 
            {
                this.loeReason = this.loeReason + '-' + this.loeComments;
            }

            updateCaseLOE({ caseId: this.caseRecId, newLOE: this.newLOE, loeReason: this.loeReason })
                .then(result => {
                    const toastEvt = new ShowToastEvent({
                        title: "",
                        message: "Case LOE updated!",
                        variant: "success",
                        mode: "dismissible",
                        duration: 5000
                    });
                    this.dispatchEvent(toastEvt);
                    this.closeLOEModal();
                    this.caseLOESpinner = false;
                    this.refresh();

                }).catch(error => {
                    this.showSpinner = false;
                    let errorBody = error.body;
                    const toastEvt = new ShowToastEvent({
                        title: "Error!",
                        message: errorBody.message,
                        variant: "error",
                        mode: "dismissible",
                        duration: 8000
                    });
                    this.dispatchEvent(toastEvt);
                    console.log(JSON.stringify(error));
                });
        }
    }

    closeLOEModal() {
        this.showLOEModal = false
        this.showChangeReason = false;
        this.loeComments = '';
        this.loeReason = null;
    }

    // ***************************************** RCD UPDATE *****************************************

    handleLoadRCDCase()
    {
        this.showRCDSpinner = false;
    }

    handleSubmitRCDCase() 
    {
        this.showRCDSpinner = true;
    }
    
    handleSuccessRCDCase() 
    {
        //console.log('entered handleSuccessEditCase');
        const toastEvt = new ShowToastEvent({
            title: "",
            message: "The Requested Completion Date for Case " + this.akamCaseId + " successfully updated!",
            variant: "success",
            mode: "dismissible",
            duration: 5000
        });
        this.dispatchEvent(toastEvt);
        this.showRCDSpinner = false;
        this.hideRCDCaseModal();
        this.refresh();
    }

    hideRCDCaseModal() 
    {
        this.showRCDModal = false;
    }

    handleErrorRCDCase() 
    {
        this.showRCDSpinner = false;
    }

    // ***************************************** INLINE EDIT CASE *****************************************

    handleSubmitEditCase() {
        this.loadEditCaseSpinner = true;
    }

    handleSuccessEditCase() {
        //console.log('entered handleSuccessEditCase');
        const toastEvt = new ShowToastEvent({
            title: "Case Updated",
            message: 'Case ' + this.akamCaseId + ' successfully updated!',
            variant: "success",
            mode: "dismissible",
            duration: 5000
        });
        this.dispatchEvent(toastEvt);
        this.loadEditCaseSpinner = false;
        this.hideEditCaseModal();
        this.refresh();
    }

    handleErrorEditCase() {
        //console.log('entered handleErrorEditCase');
        this.loadEditCaseSpinner = false;
    }

    hideEditCaseModal() {
        this.showEditCaseModal = false;
    }

    handleLoadEditCase() {
        this.loadEditCaseSpinner = false;
    }

    // ***************************************** INLINE CLOSE CASE *****************************************
    handleSubmitCloseCase() {
        this.loadCloseCaseSpinner = true;
    }

    handleSuccessCloseCase() {
        //console.log('entered handleSuccessCloseCase');
        const toastEvt = new ShowToastEvent({
            title: "Case Closed",
            message: 'Case ' + this.akamCaseId + ' successfully closed!',
            variant: "success",
            mode: "dismissible",
            duration: 5000
        });
        this.dispatchEvent(toastEvt);
        this.loadCloseCaseSpinner = false;
        this.hideCloseCaseModal();
        this.refresh();
    }

    handleErrorCloseCase() {
        //console.log('entered handleErrorCloseCase');
        this.loadCloseCaseSpinner = false;
    }

    hideCloseCaseModal() {
        this.showCloseCaseModal = false;
    }

    handleLoadCloseCase() {
        this.loadCloseCaseSpinner = false;
    }

    // ***************************************** BULK CLOSE CASE *****************************************
    bulkCloseCaseNum;
    handleBulkCloseCase() {
        this.bulkCloseCaseNum = 0;
        this.showBulkCloseCaseModal = true;
        this.loadBulkCloseCaseSpinner = true;
        this.bulkCloseCases = this.template.querySelector('.casesDatatableCustom').getSelectedRows();
        //console.log(this.selectedRows);
    }

    handleBulkCloseModalLoad() {
        this.bulkCloseCaseNum++;
        if (this.bulkCloseCaseNum === this.bulkCloseCases.length) { this.loadBulkCloseCaseSpinner = false; }
    }

    hideBulkCloseCaseModal() {
        this.bulkCloseCases = [];
        this.selectedRows = [];
        this.showBulkCloseCaseModal = false;
    }

    handleBulkCloseCaseSave() {
        this.loadBulkCloseCaseSpinner = true;
        let mapCasesToClose = new Map();
        let closeCodeSolSummMap = new Map();
        for (let i = 0; i < this.bulkCloseCases.length; i++) {
            let lwcEditForm = this.template.querySelectorAll('[data-id="' + this.bulkCloseCases[i] + '"]');

            for (let j = 0; j < lwcEditForm.length; j++) {
                if (lwcEditForm[j].fieldName === 'Close_Code__c' && !lwcEditForm[j].value) {
                    const evt = new ShowToastEvent({
                        title: 'Incomplete fields!',
                        message: "Please ensure Close Code is filled on all the Cases",
                        variant: 'Error',
                        mode: 'dismissable',
                        duration: 7000
                    });
                    this.dispatchEvent(evt);

                    this.loadBulkCloseCaseSpinner = false;
                    this.template.querySelectorAll('lightning-input-field').forEach(element => {
                        element.reportValidity();
                    });
                    return false;
                }
                if (lwcEditForm[j].fieldName === 'Close_Code__c') {
                    closeCodeSolSummMap['closeCode'] = lwcEditForm[j].value;
                }
                else if (lwcEditForm[j].fieldName === 'Solution_Summary__c') {
                    closeCodeSolSummMap['solutionSummary'] = lwcEditForm[j].value;
                }
            }
            mapCasesToClose[this.bulkCloseCases[i].caseRecId] = closeCodeSolSummMap;
        }

        bulkCloseCases({ mapCasesToClose: mapCasesToClose })
            .then(result => {
                const toastEvt = new ShowToastEvent({
                    title: "Case(s) closed!",
                    message: "Refreshing view...",
                    variant: "success",
                    mode: "dismissible",
                    duration: 5000
                });
                this.dispatchEvent(toastEvt);
                this.loadBulkCloseCaseSpinner = false;
                this.hideBulkCloseCaseModal();
                this.refresh();
            }).catch(error => {
                this.loadBulkCloseCaseSpinner = false;
                console.log(JSON.stringify(error));
                let body = error.body;
                const toastEvt = new ShowToastEvent({
                    title: "Error!",
                    message: body.message,
                    variant: "error",
                    mode: "dismissible",
                    duration: 5000
                });
                this.dispatchEvent(toastEvt);
            });
    }

    // ***************************************** CLONE CASE *****************************************
    cloneSingleCaseMethod() {
        this.hideCloneCaseModal();

        //this.loadCloneCaseSpinner = true;
        /*
        cloneSingleCase({ caseId: this.caseRecId})
        .then(result => 
        {
            const toastEvt = new ShowToastEvent({
                title: "Case cloned!",
                message: "Case has been successfully cloned!",
                variant: "success",
                mode: "dismissible",
                duration: 5000
            });
            this.dispatchEvent(toastEvt);
            this.loadCloneCaseSpinner = false;
            this.hideCloneCaseModal();
            this.refresh();
        }).catch(error => 
        {
            this.loadCloneCaseSpinner = false;
            console.log(JSON.stringify(error));
        });
        */
        let accountId = this.caseRow.accountUrl.replace('/', '');
        let caseloe = this.caseRow.caseloeval ? this.caseRow.caseloeval : null;

        const defaultValues = encodeDefaultFieldValues({
            Service__c: this.caseRow.Service,
            Request_Type__c: this.caseRow.ReqType,
            Severity__c: this.caseRow.severity,
            AccountId: accountId,
            Subject: this.caseRow.subject,
            Description: this.caseRow.livingSummary,
            Status: this.caseRow.status,
            Requested_Completion_Date_UTC__c: this.caseRow.reqCompletionDateVal,
            Case_Product__c: this.caseRow.caseProductId,
            OwnerId: this.caseRow.ownerId,
            LOE_Hours__c: caseloe
        });

        this[NavigationMixin.Navigate](
            {
                type: 'standard__objectPage',
                attributes:
                {
                    objectApiName: 'Case',
                    actionName: 'new'
                },
                state:
                {
                    recordTypeId: this.recordTypeId,
                    defaultFieldValues: defaultValues,
                    nooverride: '1'
                }
            });
    }

    hideCloneCaseModal() {
        this.showCloneCaseModal = false;
    }


    // ***************************************** MULTI CLONE CASE *****************************************

    loadSavedMultiCloneAccounts() {
        this.loadMultiCloneCaseSpinner = true;
        fetchSavedAccountForMultiClone({})
            .then(result => {
                this.accountList = result;

            }).catch(error => {
                this.loadMultiCloneCaseSpinner = false;
                console.log(JSON.stringify(error));
            });
    }

    cloneMultiCaseMethod() {
        this.loadMultiCloneCaseSpinner = true;

        cloneMultiCase({ caseId: this.caseRecId, lstAccId: this.selectedAccounts })
            .then(result => {
                const toastEvt = new ShowToastEvent({
                    title: "Case cloned!",
                    message: "Case has been successfully cloned on chosen Account(s)!",
                    variant: "success",
                    mode: "dismissible",
                    duration: 5000
                });
                this.dispatchEvent(toastEvt);
                this.loadMultiCloneCaseSpinner = true;
                this.hideMultiCloneCaseModal();
                this.refresh();
            }).catch(error => {
                this.loadMultiCloneCaseSpinner = false;
                console.log(JSON.stringify(error));
                let body = error.body;
                const toastEvt = new ShowToastEvent({
                    title: "Error!",
                    message: body.message,
                    variant: "error",
                    mode: "dismissible",
                    duration: 10000
                });
                this.dispatchEvent(toastEvt);
            });

    }

    get min() {
        return 1;
    }

    get max() {
        return 50;
    }

    hideMultiCloneCaseModal() {
        this.selectedAccounts = []; this.selectedAccMap = new Map();
        this.accountList = [];
        this.selectedAccSet = new Set();
        this.showMultiCloneCaseModal = false;
    }

    handleLoadMultiCloneCase() {
        this.loadMultiCloneCaseSpinner = false;
    }

    addAccountToList(event) {
        event.preventDefault();
        let selAcc = [];
        let selAccSet = new Set();
        if (this.selectedAccSet.length > 0) { selAccSet = this.selectedAccSet; }

        let str = this.selectedAccounts.toString();
        //console.log(str);

        if (!str.includes(event.detail.fields.AccountId)) {
            let accChosen = event.detail.fields.AccountId;
            selAccSet.add(event.detail.fields.AccountId);
            selAcc = this.selectedAccounts;

            let availAcc = [...this.accountList];

            accountOption({ accountId: accChosen })
                .then(result => {
                    result.forEach(element => {
                        selAcc.push(element.value);
                        availAcc.push({ 'label': element.label, 'value': element.value });
                    });
                    this.accountList = availAcc;
                    this.selectedAccounts = selAcc;
                    this.selectedAccSet = selAccSet;
                    //console.log(JSON.stringify(this.accountList));
                })
                .catch(error => {
                    console.log(JSON.stringify(error));
                });
        }
    }

    handleAccountChange(event) {
        this.selectedAccounts = event.detail.value;
    }

    // ***************************************** ACKNOWLEDGE CASE *****************************************
    ackCaseMethod() {
        this.hideAckCaseModal();
        this.showSpinner = true;

        //this.caseRow.disableCaseAckButton = true;
        //this.caseRow.caseAckButtonIcon = 'utility:check';

        acknowledgeCase({ caseId: this.caseRecId })
            .then(result => {
                const toastEvt = new ShowToastEvent({
                    title: "Case acknowledged!",
                    message: "Acknowledgement email has been sent on the Case. Refreshing view...",
                    variant: "success",
                    mode: "dismissible",
                    duration: 5000
                });
                this.dispatchEvent(toastEvt);
                this.refresh();
            }).catch(error => {
                this.showSpinner = false;
                console.log(JSON.stringify(error));
                let body = error.body;
                const toastEvt = new ShowToastEvent({
                    title: "Error!",
                    message: body.message,
                    variant: "error",
                    mode: "dismissible",
                    duration: 5000
                });
                this.dispatchEvent(toastEvt);
            });
    }

    hideAckCaseModal() {
        this.showAckCaseModal = false;
    }

    // ***************************************** NEW CASE *****************************************
    newPSCase() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Case',
                actionName: 'new'
            },
            state: {
                recordTypeId: this.recordTypeId
            }
        });
    }

    // ***************************************** NEW RELATED CASE *****************************************
    newPSRelatedCase() {
        let defaultValues = encodeDefaultFieldValues({
            ParentId: this.caseRecId
        });

        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Case',
                actionName: 'new'
            },
            state: {
                nooverride: '1',
                recordTypeId: this.recordTypeId,
                defaultFieldValues: defaultValues
            }
        });
    }


    // ***************************************** SEARCH *****************************************
    timeoutId;
    delayedSearch(event) {
        this.searchString = event.detail.value.toUpperCase();

        if (!this.globalSearchEnabled) {
            clearTimeout(this.timeoutId); // no-op if invalid id
            this.timeoutId = setTimeout(this.searchCases.bind(this), 300);
        }
    }

    allSearchChange() { }

    searchColChange(event) {
        let searchcol = event.detail.value.toString();
        let prevSearchCols = this.searchColVal;

        if (!searchcol) {
            let searchColVals = [];
            //searchColVals.push(this.searchColVal.toString());
            this.searchColVal = prevSearchCols;
            const toastEvt = new ShowToastEvent({
                title: "Please select atleast one field!",
                message: "",
                variant: "warning",
                mode: "dismissible",
                duration: 5000
            });
            this.dispatchEvent(toastEvt);
        }
        else {
            if (!prevSearchCols.includes('all') && searchcol.includes('all')) {
                this.searchColVal = 'all';
            }
            else if (prevSearchCols.includes('all') && searchcol.includes('all')) {
                searchcol = searchcol.replace('all', '');
                this.searchColVal = searchcol.split(',');
            }
            else {
                this.searchColVal = event.detail.value;
            }
            //this.searchColVal = event.detail.value;
        }
        //console.log(this.searchColVal);
    }

    globalCasesToSearch;
    globalSearchString;
    i;
    searchCases() {
        var searchString = this.searchString.trim();
        var casesToSearch = this.allFetchedCases;
        var tempArray = []; var caseIdSet = new Set();

        if (!this.casesDatatableCustomRef) {
            this.casesDatatableCustomRef = this.template.querySelector('.casesDatatableCustom');
        }

        if (searchString.length > 0) {
            if (this.searchColVal.includes('all')) {
                for (var i = 0; i < casesToSearch.length; i++) {
                    if ((casesToSearch[i].akamCaseId && casesToSearch[i].akamCaseId.toUpperCase().indexOf(searchString) !== -1) ||
                        (casesToSearch[i].userNameRole && casesToSearch[i].userNameRole.toUpperCase().indexOf(searchString) !== -1) ||
                        (casesToSearch[i].accountName && casesToSearch[i].accountName.toUpperCase().indexOf(searchString) !== -1) ||
                        (casesToSearch[i].subject && casesToSearch[i].subject.toUpperCase().indexOf(searchString) !== -1) ||
                        (casesToSearch[i].caseloe && casesToSearch[i].caseloe.toString().indexOf(searchString) !== -1) ||
                        (casesToSearch[i].reqCompletionDate && casesToSearch[i].reqCompletionDate.toString().indexOf(searchString) !== -1) ||
                        (casesToSearch[i].ageDays && casesToSearch[i].ageDays.toString().indexOf(searchString) !== -1) ||
                        (casesToSearch[i].nextPlannedActivityDate && casesToSearch[i].nextPlannedActivityDate.toString().indexOf(searchString) !== -1) ||
                        (casesToSearch[i].status && casesToSearch[i].status.toUpperCase().indexOf(searchString) !== -1)
                    ) {
                        tempArray.push(casesToSearch[i]);
                    }
                }
            }
            else {
                let searchcols = this.searchColVal.toString().split(',');
                casesToSearch.forEach(eachCase => {
                    searchcols.forEach(eachCol => {
                        if (eachCase[eachCol] && eachCase[eachCol].toUpperCase().indexOf(searchString) !== -1) {
                            if (!caseIdSet.has(eachCase.caseRecId)) {
                                caseIdSet.add(eachCase.caseRecId);
                                tempArray.push(eachCase);
                            }
                        }
                    });
                });
            }
            //this.casesDatatableCustomRef.enableInfiniteLoading = false;
            this.caseListToShow = tempArray;
        }
        else {
            //this.casesDatatableCustomRef.enableInfiniteLoading = true;
            this.caseListToShow = this.allFetchedCases;
        }
        this.casesCount = this.caseListToShow.length;
        this.offset = 1;
        this.spliceData();
        //let searchFilter = this.caseSearchText.toUpperCase();
        //let columnSearch = this.columnToSearch;
    }

    // ***************************************** GLOBAL SEARCH *****************************************
    searchInputBoxRef;
    searchInputDivRef;
    isSelected = false;

    globalSearchToggle(event) 
    {
        this.globalSearchEnabled = event.target.checked;

        if (this.sideNavOpen) {
            this.closeCaseSidenav();
        }

        if (!this.searchInputBoxRef) {
            this.searchInputBoxRef = this.template.querySelector('.searchInput');
        }
        if (!this.searchInputDivRef) {
            this.searchInputDivRef = this.template.querySelector('.searchInputDiv');
            this.searchInputDivRef.classList.add('slds-size_1-of-6');
            this.searchInputDivRef.classList.remove('slds-size_1-of-7');
        }
        if (!this.headerLabelRef) {
            this.headerLabelRef = this.template.querySelector('.headerLabel');
        }

        // -------------------- GLOBAL SEARCH ON --------------------
        if (this.globalSearchEnabled) 
        {
            this.searchPlaceholderString = 'Search AKAM Case ID';
            this.globalSearchColumns = MY_OPEN_COLS;
            /*
            this.headerLabelRef.classList.remove('slds-size_1-of-6');
            this.headerLabelRef.classList.add('slds-size_3-of-5');
            this.searchInputDivRef.classList.add('slds-size_1-of-6');
            this.searchInputDivRef.classList.remove('slds-size_1-of-7');
            */
        }
        else
        // -------------------- GLOBAL SEARCH OFF --------------------
        {
            if (this.sideNavOpen) { this.closeCaseSidenav(); }

            this.searchInputBoxRef.value = '';
            this.searchString = '';
            
            this.globalSearchCase = [];
            this.searchPlaceholderString = 'Search Cases...';

            this.prevCasesList = [...this.prevCases.values()];
            this.recentlySearchedList = this.prevCasesList;

            /*
            for (const [key, value] of this.prevCases) 
            {
                this.prevCasesList.unshift(value);
            }
            */

            /*
            this.headerLabelRef.classList.add('slds-size_1-of-6');
            this.headerLabelRef.classList.remove('slds-size_3-of-5');
            this.searchInputDivRef.classList.remove('slds-size_1-of-6');
            this.searchInputDivRef.classList.add('slds-size_1-of-7');
            */
            this.offset = 1;
            this.spliceData();
        }

    }

    prevCases = new Map();
    prevCasesList = [];

    globalSearchCaseMethod() {
        let tempMap = new Map();
        let fullMap;

        this.globalSearchCase = [];

        if (!this.searchString.trim()) {
            const toastEvt = new ShowToastEvent({
                title: "Search string empty!",
                message: "",
                variant: "warning",
                mode: "dismissible",
                duration: 5000
            });
            this.dispatchEvent(toastEvt);
        }
        else {
            this.showSpinner = true;

            this.prevCasesList = [];


            globalSearchCase({ akamCaseId: this.searchString.trim(), saveString: true })
                .then(result => {
                    if (result && result.length > 0) {
                        this.globalSearchCase = result;
                        let searchedCase = result[0];
                        if (this.prevCases.has(searchedCase.akamCaseId)) { this.prevCases.delete(searchedCase.akamCaseId); }
                        this.prevCasesList = [...this.prevCases.values()];
                        this.recentlySearchedList = this.prevCasesList;

                        result.forEach(element => {
                            tempMap.set(element.akamCaseId, element);
                        });

                        fullMap = new Map([...tempMap, ...this.prevCases]);
                        this.prevCases = fullMap;
                    }
                    else {
                        this.globalSearchCase = null;
                        this.prevCasesList = [...this.prevCases.values()];
                        this.recentlySearchedList = this.prevCasesList;

                        const toastEvt = new ShowToastEvent({
                            title: "No Case found!",
                            message: "",
                            variant: "info",
                            mode: "dismissible",
                            duration: 3000
                        });
                        this.dispatchEvent(toastEvt);
                    }
                    this.showSpinner = false;
                })
                .catch(error => {
                    this.showSpinner = false;
                    console.log(JSON.stringify(error));
                });
        }
    }


    // **************************************************** CASE VIEW CHANGE ****************************************************
    viewChange(event) 
    {
        this.oldViewVal = this.myCasesViewVal;
        this.caseViewChanged = true;

        this.myCasesViewVal = event.detail.value;

        this.headingLabel = event.target.options.find(opt => opt.value === event.detail.value).label;

        this.showSpinner = true;
        if (this.sideNavOpen) 
        { this.closeCaseSidenav(); }

        this.getCases();
    }

    rehideColumnsOnViewChange()
    {
        this.caseViewChanged = false;
        if (this.myCasesColumnsVal.length !== 10) 
        {
            let newCasesColVals = [];

            if(this.oldViewVal === 'myopen')
            {
                for (var i = 0; i < this.myCasesColumnsVal.length; i++) 
                {
                    newCasesColVals.push((parseInt(this.myCasesColumnsVal[i]) - 1).toString());
                }
                this.myCasesColumnsVal = newCasesColVals;
            }
            else if(this.myCasesViewVal === 'myopen')
            {
                for (var i = 0; i < this.myCasesColumnsVal.length; i++) 
                {
                    newCasesColVals.push((parseInt(this.myCasesColumnsVal[i]) + 1).toString());
                }
                this.myCasesColumnsVal = newCasesColVals;
            }
            
            this.template.querySelector('.myCasesColumnsVal').value = this.myCasesColumnsVal;

            this.handleMyCasesColChange();
        }
        else 
        {
            //console.log('reset view values');
            if (this.myCasesViewVal === 'myopen') 
            {
                this.myCasesColumnsVal = ['3', '4', '5', '6', '7', '8', '9', '10', '11', '12'];
            }
            else 
            {
                this.myCasesColumnsVal = ['2', '3', '4', '5', '6', '7', '8', '9', '10', '11'];
            }
        }
    }

    handleMyCasesColChange(event) 
    {
        if (this.caseViewValue === 'GS2') 
        {
            if(event)
            {   
                this.myCasesColumnsVal = event.detail.value;
            }

            var newcols = [];

            if (this.myCasesViewVal === 'mycreated')
            {
                let allCols = MY_CREATED_COLS;
                newcols = [allCols[0],allCols[1],...this.myCasesColumnsVal.map(index=>allCols[index]),allCols[allCols.length-2],[allCols.length-1]]
            } else if (this.myCasesViewVal === 'myteam') {
                let allCols = MY_TEAM_COLS;
                newcols = [allCols[0],allCols[1],...this.myCasesColumnsVal.map(index => allCols[index])];
            } else if (this.myCasesViewVal === 'myopen') {
                let allCols = MY_OPEN_COLS_GS2;
                newcols = [allCols[0],allCols[1],allCols[2],...this.myCasesColumnsVal.map(index => allCols[index]),allCols[allCols.length - 2], allCols[allCols.length - 1]];
            }
            this.columns = [...newcols];
        }
    }

    /*
    toggleFilter(e) 
    {
        var str = e.target.id;
        console.log(str);
        if(str.includes("sevFilter"))
        {
        var modal = this.template.querySelector('.sevFilter');
        }
        else if(str.includes("utilHoursFilter"))
        {
        var modal = this.template.querySelector('.utilHoursFilter');
        }
        else if(str.includes("reqCompDateFilter"))
        {
        var modal = this.template.querySelector('.reqCompDateFilter');
        }
        modal.classList.toggle('slds-is-open');
    }
    
    closeNav() {
        this.likeStateFilled = false;
        this.caseTableDiv.classList.toggle('slds-size_4-of-5');
        this.caseTableDiv.classList.toggle('crunchRightPadding');
        this.caseTableDiv.classList.toggle('slds-size_5-of-5');
        this.sideNavDiv.classList.toggle('slds-hide');
        //var y= this.template.querySelector(".FullTableClass");
        //y.style.width = "100%";
    }
    
    toggleMyCreated(event) {
        this.myCreatedToggle = event.target.checked;

        // SHOW MY CREATED CASES
        if (this.myCreatedToggle) {
            this.columns = MY_CREATED_COLS;
            this.caseListToShow = this.allFetchedCases.mycreated;
            this.headingLabel = 'My Created Cases';
        }
        // SHOW MY OPEN CASES
        else {
            this.columns = MY_OPEN_COLS;
            this.caseListToShow = this.allFetchedCases.myopen;
            this.headingLabel = 'My Open Cases';
        }
        this.casesCount = this.caseListToShow.length;
        this.spliceData();
    }

    openFilters(event) {
        if (!this.sideNavDiv || !this.caseTableDiv) {
            this.sideNavDiv = this.template.querySelector(".sideNavDiv");
            this.caseTableDiv = this.template.querySelector(".caseTableDiv");
        }

        this.caseTableDiv.classList.toggle('slds-size_4-of-5');
        this.caseTableDiv.classList.toggle('crunchRightPadding');
        this.sideNavDiv.classList.toggle('slds-hide');
        this.sideNavDiv.style.leftPadding = 0;

        //x.style.width = "310px";
        //var y = this.template.querySelector(".FullTableClass");
        //y.style.width = "82%";
        this.likeStateFilled = !this.likeStateFilled;
    }

    */


    /*
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
    */


    /*
    handleBulkCloseCaseSave() 
    {
        this.loadBulkCloseCaseSpinner = true;
        let mapCasesToClose = new Map();
        let closeCodeSolSummMap = new Map();
        let validityVal = true;

        this.template.querySelectorAll('.closeCodeClass').forEach(element => 
        {
            validityVal = element.reportValidity();
        });
        console.log(validityVal);
        if(!validityVal)
        {
            const evt = new ShowToastEvent({
                title: 'Incomplete fields!',
                message: "Please ensure Close Code is filled",
                variant: 'Error',
                mode: 'dismissable',
                duration: 7000
            });
            this.dispatchEvent(evt);

            this.loadBulkCloseCaseSpinner = false;
            return false;
        }
        else
        
        /*
        if (lwcEditForm[j].fieldName === 'Close_Code__c' && !lwcEditForm[j].value) 
        {
            
        }
        */

    /*
    {
        for (let i = 0; i < this.bulkCloseCases.length; i++) 
        {    
            let lwcEditForm = this.template.querySelectorAll('[data-id="' + this.bulkCloseCases[i] + '"]');

            for (let j = 0; j < lwcEditForm.length; j++) 
            {
                if (lwcEditForm[j].fieldName === 'Close_Code__c') 
                {
                    closeCodeSolSummMap['closeCode'] = lwcEditForm[j].value;
                }
                else if (lwcEditForm[j].fieldName === 'Solution_Summary__c') {
                    closeCodeSolSummMap['solutionSummary'] = lwcEditForm[j].value;
                }
            }
            mapCasesToClose[this.bulkCloseCases[i].caseRecId] = closeCodeSolSummMap;
        }
        bulkCloseCases({ mapCasesToClose: mapCasesToClose })
        .then(result => {
            const toastEvt = new ShowToastEvent({
                title: "Case(s) closed!",
                message: "Refreshing view...",
                variant: "success",
                mode: "dismissible",
                duration: 5000
            });
            this.dispatchEvent(toastEvt);
            this.loadBulkCloseCaseSpinner = false;
            this.hideBulkCloseCaseModal();
            this.refresh();
        }).catch(error => {
            this.loadBulkCloseCaseSpinner = false;
            console.log(JSON.stringify(error));
            let body = error.body;
            const toastEvt = new ShowToastEvent({
                title: "Error!",
                message: body.message,
                variant: "error",
                mode: "dismissible",
                duration: 5000
            });
            this.dispatchEvent(toastEvt);
        });
    }
}
*/

    /*
    colourLOERemainingDiv()
    {
        if(this.loeRemaining < 0)
        {
            this.remLOECalcValRef.classList.add('negativeLOE');
            this.remLOECalcValRef.classList.remove('nearingLOE');
        }
        else if(this.caseRow.caseloe && this.loeRemaining >=0 && this.loeRemaining <= (0.2 * this.caseRow.caseloe))
        {
            this.remLOECalcValRef.classList.remove('negativeLOE');
            this.remLOECalcValRef.classList.add('nearingLOE');
        }
        else
        {
            this.remLOECalcValRef.classList.remove('negativeLOE');
            this.remLOECalcValRef.classList.remove('nearingLOE');
        }
    }
    */

}