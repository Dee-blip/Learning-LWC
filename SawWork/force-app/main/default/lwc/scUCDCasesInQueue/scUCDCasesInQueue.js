/** @Date		:	Aug 05 2020
* @Author		: 	Sumukh SS 
* @Description	:	Cases in Queue functionality for Unified Case Dashboard

Date                    Developer             		JIRA #                      Description                                                       
------------------------------------------------------------------------------------------------------------------
24 Aug 2020				Author				 	    ESESP-3829				  Initial Development
28 Nov 2020           	Sumukh SS	                  21.1                    Cases in Queue Enhancements for full launch
28 Feb 2022             Vandhana                    FFPSA-1921                Add fields to Cases in Queue table, sort, search, hide/show them
*/

import { LightningElement, wire, api, track } from 'lwc';

import { loadStyle } from 'lightning/platformResourceLoader';
import cssStyleSheet from "@salesforce/resourceUrl/SC_UCD_Stylesheet";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import getMyCaseData from '@salesforce/apex/SC_UCD_HomePage.getCasesinQueue';
import getOnLoadData from '@salesforce/apex/SC_UCD_HomePage.getOnLoadValues';
import saveQueueSelection from '@salesforce/apex/SC_UCD_HomePage.saveSelectedFilters';
import DeleteFilterMapping from '@salesforce/apex/SC_UCD_HomePage.DeleteFilterMapping';
import ApplyFilter from '@salesforce/apex/SC_UCD_HomePage.ApplyFilterMapping';
import savePendingReason from '@salesforce/apex/SC_UCD_HomePage.assignPendingReasonToCase'
import assignCasetoUser from '@salesforce/apex/SC_UCD_HomePage.changeCaseOwnerQueue'
import EditFilterMapping from '@salesforce/apex/SC_UCD_HomePage.editSelectedFilter'

import { MY_OPEN_COLS } from './scUCDCasesInQueue_Const';
import { TERR_COLS } from './scUCDCasesInQueue_Const';
import { QUEUE_COLS } from './scUCDCasesInQueue_Const';
import {
    publish,
    subscribe,
    unsubscribe,
    APPLICATION_SCOPE,
    MessageContext
} from 'lightning/messageService';
import caseViewVal from '@salesforce/messageChannel/ucdMessageChannel__c';

const columns = [];
const terrcolumns = [];
const queuecolumns = [];
const ALL_FILTERS_TAB = 'savedfilters';
const QUEUE_SELECTION_TAB = 'Queue';
const ERROR_DUPLICATE_FILTER_NAME = 'Filter with this name already exists.';

export default class ScUCDCasesInQueue extends LightningElement {

    //-------------------Lightning Messaging Service -----------------------------
    @wire(MessageContext)
    messageContext;

    subscription = null;

    // Encapsulate logic for Lightning message service subscribe and unsubsubscribe
    subscribeToMessageChannel() {
        if (!this.subscription) {
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

    handleMessage(message) {
        let view = message.caseView;
        if (view === 'TSC') {
            this.showCasesinQueue = false;
            window.clearInterval(this.PollID);
        }
        else {
            this.showCasesinQueue = true;
            this.ClearPollerAndRefreshTable();
        }
    }
    //------------------------------------------------------------------

    @api query = 'Select QueueId,Queue.Name from QueueSobject where SobjectType = \'Case\' and Queue.DeveloperName like ';
    //All Datatables column definition
    columns = columns;
    terrcolumns = terrcolumns;
    queuecolumns = queuecolumns;
    showCasesinQueue = false;

    //Datatable track variables
    data;
    alldataforstorage;
    terrdata;
    queuedata;

    Queuenow;
    displayCase = true;
    TotalCount = 0;
    choosenFilterName = 'No';
    showspinner = false;
    currentRecord = {};

    filtername;
    showChangeOwnerModal = false;
    PollID;
    showNewFilterCreation = false;
    showNewFilterButton = false;

    onloadresult;
    offset = 1;
    maxoffset;
    defaultSortDirection = 'asc';

    sortDirection = 'asc';
    sortedBy = 'Age';

    TerrsortDirection = 'asc';
    TerrsortedBy = 'geography';

    QueuesortDirection = 'asc';
    QueuesortedBy = 'queueName';

    SavedFilters = [];

    getPendingCasevalue = '';
    othersreason = '';
    currentrecordid;
    showPendingReasonModal = false;
    showPendingCaseOthersReason = false;
    showFilterFooter = false;
    maxnumofdgratrecs;

    get getPendingCaseoptions() {
        return [
            { label: 'Incomplete eRSS', value: 'Incomplete eRSS' },
            { label: 'Missing eRSS', value: 'Missing eRSS' },
            { label: 'BED is in past', value: 'BED is in past' },
            { label: 'Incorrect CLI on Order form', value: 'Incorrect CLI on Order form' },
            { label: 'Missing IW information', value: 'Missing IW information' },
            { label: 'Opportunity is not Closed Won', value: 'Opportunity is not Closed Won' },
            { label: 'Awaiting IAT response', value: 'Awaiting IAT response' },
            { label: 'Awaiting customer response', value: 'Awaiting customer response' },
            { label: 'Customer requested delay', value: 'Customer requested delay' },
            { label: 'Internal engineering escalation', value: 'Internal engineering escalation' },
            { label: 'Others', value: 'Others' },
        ];
    }

    handlePendingCaseChange(event) {

        this.getPendingCasevalue = event.detail.value;
        if (event.detail.value === 'Others') {
            this.showPendingCaseOthersReason = true;
        }
        else {
            this.showPendingCaseOthersReason = false;
        }
    }

    get SevOptions() {
        return [
            { label: '1', value: '1' },
            { label: '2', value: '2' },
            { label: '3', value: '3' },
            { label: '4', value: '4' }
        ];
    }
    Sevvalue = ['1', '2', '3', '4'];

    get StatusOptions() {
        return [
            { label: 'Unassigned', value: 'Unassigned' },
            { label: 'Assigned', value: 'Assigned' },
            { label: 'Reopened', value: 'Reopened' },
            { label: 'Pending', value: 'Pending' },
            { label: 'Work in Progress', value: 'Work in Progress' }
        ];
    }

    Statusvalue = ['Unassigned', 'Assigned', 'Reopened', 'Pending', 'Work in Progress'];

    get CasestoSearchOptions() {
        return [
            { label: 'All', value: 'All' },
            { label: 'AKAM Case ID', value: 'akamCaseId' },
            { label: 'Account', value: 'accountName' },
            { label: 'Subject', value: 'subject' },
            { label: 'Service', value: 'Service' },
            { label: 'Request Type', value: 'ReqType' },
            { label: 'Product', value: 'caseProductName' },           
            { label: 'Owner', value: 'caseOwner' },
            { label: 'Creator', value: 'caseCreator'},
            { label: 'Project', value: 'Project'},
            { label: 'Origin', value: 'caseOrigin'},
            { label: 'Status', value: 'status' }
        ];
    }


    handleActiveTab(e) {
        this.showFilterFooter = e.target.value !== ALL_FILTERS_TAB;
        this.filtersActiveTab = e.target.value;
    }

    searchColVal = 'All';

    handleCasestoSearch(event) {
        let searchcol = event.detail.value.toString();
        let prevSearchCols = this.searchColVal;

        if (!searchcol) {
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
            if (!prevSearchCols.includes('All') && searchcol.includes('All')) {
                this.searchColVal = 'All';
            }
            else if (prevSearchCols.includes('All') && searchcol.includes('All')) {
                searchcol = searchcol.replace('All', '');
                this.searchColVal = searchcol.split(',');;
            }
            else {
                this.searchColVal = event.detail.value;
            }
        }
    }

    queryTerm;
    handleKeyUp(evt) {
        this.queryTerm = evt.target.value;
        clearTimeout(this.timeoutId);
        this.timeoutId = setTimeout(this.searchtable.bind(this), 500);
    }

    searchtable() 
    {
        var i=0;
        var searchFilter = this.queryTerm.toUpperCase();
        var allRecords = this.alldataforstorage;
        var tempArray = [];
        var caseIdSet = new Set();

        if (searchFilter.length > 0) 
        {
            if (this.searchColVal.includes('All')) 
            {
                for (i = 0; i < allRecords.length; i++) 
                {
                    if ((allRecords[i].akamCaseId && allRecords[i].akamCaseId.toUpperCase().indexOf(searchFilter) !== -1) ||
                        (allRecords[i].accountName && allRecords[i].accountName.toUpperCase().indexOf(searchFilter) !== -1) ||
                        (allRecords[i].subject && allRecords[i].subject.toUpperCase().indexOf(searchFilter) !== -1) ||
                        (allRecords[i].Service && allRecords[i].Service.toUpperCase().indexOf(searchFilter) !== -1) ||
                        (allRecords[i].ReqType && allRecords[i].ReqType.toUpperCase().indexOf(searchFilter) !== -1) ||
                        (allRecords[i].caseProductName && allRecords[i].caseProductName.toUpperCase().indexOf(searchFilter) !== -1) ||
                        (allRecords[i].caseCreator && allRecords[i].caseCreator.toUpperCase().indexOf(searchFilter) !== -1) ||
                        (allRecords[i].caseOwner && allRecords[i].caseOwner.toUpperCase().indexOf(searchFilter) !== -1) ||
                        (allRecords[i].caseOrigin && allRecords[i].caseOrigin.toUpperCase().indexOf(searchFilter) !== -1) ||
                        (allRecords[i].Project && allRecords[i].Project.toUpperCase().indexOf(searchFilter) !== -1) ||
                        (allRecords[i].status && allRecords[i].status.toUpperCase().indexOf(searchFilter) !== -1)
                    ) 
                    {
                        tempArray.push(allRecords[i]);
                    }
                }
            }
            else {
                let searchcols = this.searchColVal.toString().split(',');
                allRecords.forEach(eachCase => {
                    searchcols.forEach(eachCol => {
                        if (eachCase[eachCol] && eachCase[eachCol].toUpperCase().indexOf(searchFilter) !== -1) 
                        {
                            if (!caseIdSet.has(eachCase.caseRecId)) 
                            {
                                caseIdSet.add(eachCase.caseRecId);
                                tempArray.push(eachCase);
                            }
                        }
                    });
                });
            }
            var x = this.template.querySelector('.casesinQDatatable');
            x.enableInfiniteLoading = false;
            this.data = tempArray;
            this.TotalCount = tempArray.length;
        }
        else {
            this.offset = 1;
            var x = this.template.querySelector('.casesinQDatatable');
            x.enableInfiniteLoading = true;
            this.data = this.alldataforstorage.slice(0, 50);
            this.TotalCount = this.alldataforstorage.length;
        }
    }

    handleValueChange(event) {
        this.filtername = event.target.value;
        let filterNameField = this.template.querySelector("[data-id='filterName']");
        filterNameField.setCustomValidity("");
        filterNameField.reportValidity();
    }


    handlePendingReasonCaseChange(event) {
        this.othersreason = event.target.value;
    }

    //Logic to handle dynamic column selection

    AllOpenCasesColvalue = ['1', '2', '3', '4', '5', '6','7', '8', '10','11', '12', '13', '14', '15'];

    get AllOpenCasesColOptions() {
        return [
            { label: 'Severity', value: '1' },
            { label: 'Account', value: '2' },
            { label: 'Subject', value: '3' },
            { label: 'Service', value: '4' },
            { label: 'Request Type', value: '5' },
            { label: 'Product', value: '6' },
            { label: 'Age', value: '7' },
            { label: 'Requested Completion Date', value: '8' },
            { label: 'Owner', value: '10' },
            { label: 'Creator', value: '11' },
            { label: 'Origin', value: '12' },
            { label: 'LOE', value: '13' },
            { label: 'Project', value: '14' },
            { label: 'Status', value: '15' }
        ];
    }

    handleallopenColChange(e) 
    {
        this.AllOpenCasesColvalue = e.detail.value;
        var breakpoint = true;
        var allCols = MY_OPEN_COLS;
        var newcols = [allCols[0]];
        for (var i = 0; i < e.detail.value.length; i++) 
        {
            var index = e.detail.value[i];
            console.log('INDEX :: ' + index);
            if(index > 8 && breakpoint) 
            {
                newcols = [...newcols, allCols[9]];
                breakpoint=false;
            }
            newcols = [...newcols, allCols[index]];
        }
        this.columns = newcols;
    }

    connectedCallback() {
        this.subscribeToMessageChannel();
        loadStyle(this, cssStyleSheet);
        this.getFilterValues();

        this.columns = MY_OPEN_COLS;
        this.terrcolumns = TERR_COLS;
        this.queuecolumns = QUEUE_COLS;

    }

    disconnectedCallback() {
        console.log('Killing Poller All Cases');
        window.clearInterval(this.PollID);
        this.unsubscribeToMessageChannel();
    }

    ClearPollerAndRefreshTable() {
        window.clearInterval(this.PollID);
        this.PollID = setInterval(() => {
            //console.log('running poller : ' + this.PollID);
            this.getCasesData();
        }, 300000);
        this.getCasesData();
    }
    
    selectedRowsfromFilter = [];
    displaymessage;

    getFilterValues() {
        this.showspinner = true;
        getOnLoadData({})
            .then(result => {
                this.showspinner = false;

                var payload = { caseView: result.DashboardView };
                publish(this.messageContext, caseViewVal, payload);

                if (result.DashboardView === 'GS2') {
                    this.onloadresult = result;
                    this.terrdata = result.Terr_Mapping_List;
                    this.queuedata = result.psqueue_List;
                    this.SavedFilters = [];
                    this.maxnumofdgratrecs = result.territoryList;

                    if (typeof result.FilterNames !== 'undefined') {
                        const items = [];
                        for (let i = 0; i < result.FilterNames.length; i++) {

                            if (result.choosenFilter === result.FilterNames[i]) {
                                items.push({
                                    label: result.FilterNames[i] + ' ⭐',
                                    value: result.FilterNames[i]
                                });
                            }
                            else {
                                items.push({
                                    label: result.FilterNames[i],
                                    value: result.FilterNames[i]
                                });
                            }
                        }
                        this.SavedFilters.push(...items);

                        this.showNewFilterCreation = false;
                        if (result.FilterNames.length > 4) {
                            this.showNewFilterButton = false;
                        }
                        else {
                            this.showNewFilterButton = true;
                        }

                        this.choosenFilterName = result.choosenFilter;
                        this.displaymessage = '\'' + this.choosenFilterName + '\' filter currently applied';
                        this.selectedQueues = result.filtername_selectedQueueids[result.choosenFilter];
                        this.Statusvalue = result.filtername_selectedStatus[result.choosenFilter];
                        this.Sevvalue = result.filtername_selectedSeverity[result.choosenFilter];

                        if (result.filtername_selectedTerritories[result.choosenFilter].length > 0) {
                            this.selectedRowsfromFilter = result.filtername_selectedTerritories[result.choosenFilter];
                        }
                        else {
                            this.selectedRowsfromFilter = result.territoryList;
                        }
                    }
                    else {
                        this.showToast('Warning', 'To view unassigned cases, please choose atleast one PS Queue.');
                        this.selectedRowsfromFilter = result.territoryList;
                        this.showNewFilterButton = true;

                    }
                }
            }).catch(error => {
                this.showspinner = false;
                console.log(JSON.stringify(error));
            });
    }

    newFilter() {
        this.showNewFilterButton = false;
        this.showNewFilterCreation = true;
        this.selectedQueues = [];
        this.Statusvalue = ['Unassigned', 'Assigned', 'Reopened', 'Pending', 'Work in Progress'];
        this.Sevvalue = ['1', '2', '3', '4'];
        this.selectedRowsfromFilter = this.maxnumofdgratrecs;
        this.displaymessage = 'Creating new filter';
        this.showToast('Success', 'Queue choices have been cleared. Please choose the PS queues you want to view in the new filter.');
    }

    infloadqueryselector;

    getCasesData() {
        this.showspinner = true;
        getMyCaseData({})
            .then(result => {
                this.showspinner = false
                this.alldataforstorage = result;

                this.Queuenow = Date.now();
                this.TotalCount = result.length;

                let table = this.template.querySelector(".panelCasesInQueue");
                this.infloadqueryselector = this.template.querySelector('.casesinQDatatable');

                if (this.TotalCount <= 10)
                    table.style.height = "35vh";
                else
                    table.style.height = "65vh";

                this.maxoffset = Math.ceil(this.TotalCount / 50);

                if (this.queryTerm) {
                    this.searchtable();
                    this.onHandleSort();
                }
                else {

                    if (this.sortedBy !== 'ageDays') {
                        this.onHandleSort();
                    }
                    else {
                        if (result.length < 50) {
                            this.data = result;
                        }
                        else {
                            this.data = this.alldataforstorage.slice(0, this.offset * 50);
                            this.infloadqueryselector.enableInfiniteLoading = true;
                        }
                    }
                }

            }).catch(error => {
                this.showspinner = false;
                console.log(JSON.stringify(error));
            });

    }
    //----------------------------------------DATATABLE CODE------------------------

    loadMoreData(e) {
        console.log('load more');
        if (this.TotalCount < 50) {   //console.log('less than 50');
            e.target.enableInfiniteLoading = false;
        }
        else if (this.maxoffset === this.offset) {
            // console.log('max reached');
            e.target.enableInfiniteLoading = false;
        }
        else {
            this.offset++;
            this.data = this.alldataforstorage.slice(0, this.offset * 50);
        }
    }
    
    showStatusWarning=false;

    handleRowActions(event) {

        let caseId = event.detail.row.caseUrl.substring(1);
        this.currentrecordid = caseId;

        const actionName = event.detail.action.name;
        let modal = this.template.querySelector('[data-id="' + actionName + '"');
        if (modal) {
            modal.classList.remove('slds-hide');
            modal.toggle();
        }

        if (actionName === 'OpenDescription') {
            const wrapRec = this.data.find(el => ('/' + caseId) === el.caseUrl);
            this.currentRecord = wrapRec;
        }
        else if (actionName === 'open-pending-reason') {
            const wrapRec = this.data.find(el => ('/' + caseId) === el.caseUrl);
            this.getPendingCasevalue = wrapRec.pendingCaseReason;
            this.othersreason = wrapRec.livingSummaryTop3;
            this.showPendingReasonModal = true;
            
            this.showStatusWarning = wrapRec.status!='Pending' ? true : false;

            this.showPendingCaseOthersReason = this.getPendingCasevalue === 'Others' ? true : false;
            
        }
    }

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
        };

    }

    onHandleSort(event) {
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
        else if (sortedBy === 'ProjectURL') { sortedBy = 'Project'; }
        else if (sortedBy === 'reqCompletionDate') { sortedBy = 'reqCompletionDateVal'; }


        if (this.queryTerm) {
            const cloneData = [...this.data];
            cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
            this.data = cloneData;
        }
        else {
            const cloneData = [...this.alldataforstorage];
            cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
            this.alldataforstorage = cloneData;

            if (event) {
                this.offset = 1;

                this.infloadqueryselector.enableInfiniteLoading = false;
                setTimeout(this.setInfiniteloading.bind(this), 500);
                this.data = cloneData.slice(0, 50);
            }
            else {
                this.infloadqueryselector.enableInfiniteLoading = true;
                this.data = cloneData.slice(0, this.offset * 50);
            }
        }
    }

    setInfiniteloading() {
        this.infloadqueryselector.enableInfiniteLoading = true;
    }

    onHandleTerritorySort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;

        const cloneData = [...this.terrdata];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.terrdata = cloneData;
        this.TerrsortDirection = sortDirection;
        this.TerrsortedBy = sortedBy;
    }

    onHandleQueueSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;

        const cloneData = [...this.queuedata];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.queuedata = cloneData;
        this.QueuesortDirection = sortDirection;
        this.QueuesortedBy = sortedBy;

    }

    selectedcasefromqueue = [];
    getSelectedCaseIds(event) {
        this.selectedcasefromqueue = [];
        const selectedRows = event.detail.selectedRows;
        var changeowner = this.template.querySelector('.changeOwnerButton');

        if (selectedRows.length > 0) {
            for (let i = 0; i < selectedRows.length; i++) {
                this.selectedcasefromqueue.push(selectedRows[i].caseRecId);
                changeowner.disabled = false;
            }
            if (selectedRows.length > 49) {
                const toastEvt = new ShowToastEvent({
                    title: "",
                    message: "A maximum of 50 records can be selected at a time",
                    variant: "warning",
                    mode: "dismissible",
                    duration: 5000
                });
                this.dispatchEvent(toastEvt);
            }
        }
        else {
            this.selectedcasefromqueue = [];
            changeowner.disabled = true;
        }
    }

    getSelectedTerritories(event) {
        this.selectedRowsfromFilter=[];
        const selectedRows = event.detail.selectedRows;
        // Display that fieldName of the selected rows
        for (let i = 0; i < selectedRows.length; i++) {
            this.selectedRowsfromFilter.push(selectedRows[i].territory);
        }
        //console.log(this.selectedRowsfromFilter.length);
    }

    selectedQueues = [];

    getSelectedQueues(event) {
        this.selectedQueues = [];
        const selectedRows = event.detail.selectedRows;
        // Display that fieldName of the selected rows
        for (let i = 0; i < selectedRows.length; i++) {
            this.selectedQueues.push(selectedRows[i].queueId);
        }
    }
    //---------------------------------------------------------------------------

    handleSevChange(event) {
        this.Sevvalue = event.detail.value;

    }

    handleStatusChange(event) {
        this.Statusvalue = event.detail.value;
    }

    editFilter() {

        if (this.showNewFilterCreation) {
            this.handleQueueSave();
        }

        else {

            var chosendgratvalues;
             if (this.selectedRowsfromFilter.length === this.maxnumofdgratrecs.length) {
                chosendgratvalues = [];
            }
            else
            {
                chosendgratvalues= this.selectedRowsfromFilter;
            }

            EditFilterMapping({
                SelectedQueueValues: this.selectedQueues,
                SelectedSevValues: this.Sevvalue,
                SelectedStatusValues: this.Statusvalue,
                SelectedDGRAT: chosendgratvalues,
                FilterName: this.choosenFilterName
            }).then(result => {

                this.showspinner = true;
                this.getFilterValues();
                
                this.ClearPollerAndRefreshTable();
                this.showToast('Success', 'You\'re filter changes have been saved!');
                this.setFiltersActiveTab(ALL_FILTERS_TAB);
            }).catch(error => {
                this.showspinner = false;
                console.log(JSON.stringify(error));
            });

       }
    }

    handleQueueSave() {
        if (typeof this.filtername === 'undefined') {
            this.showToast('Error', 'Please provide a name to the new filter.');

        }
        else if (this.selectedQueues.length < 1 || this.Sevvalue.length < 1 || this.Statusvalue.length < 1) {
            this.showToast('Error', 'Please select all filter values in the Queue tab.');
        }
        else {

            var chosendgratvalues;
            //console.log(this.selectedRowsfromFilter.length); 
            //console.log(this.maxnumofdgratrecs.length);
            if (this.selectedRowsfromFilter.length === this.maxnumofdgratrecs.length) {
                chosendgratvalues = [];
            }
            else
            {
                chosendgratvalues= this.selectedRowsfromFilter;
            }

            saveQueueSelection({
                SelectedQueueValues: this.selectedQueues,
                SelectedSevValues: this.Sevvalue,
                SelectedStatusValues: this.Statusvalue,
                SelectedDGRAT: chosendgratvalues,
                FilterName: this.filtername
            }).then(result => {
                var x = this.template.querySelector(".filternamefield");
                x.value = '';

                this.showspinner = true;
                this.getFilterValues();
                this.ClearPollerAndRefreshTable();
                this.showToast('Success', 'New filter selection created! Refreshing data..');
                this.setFiltersActiveTab(ALL_FILTERS_TAB);
            }).catch(error => {
                this.showspinner = false;
                console.log(JSON.stringify(error));
            });
        }
    }

    deleteFilter(event) {
        if (this.choosenFilterName === event.target.value) {
            this.showToast('error', 'You cannot delete an active filter.');
        }

        else {
            DeleteFilterMapping({
                FilterName: event.target.value
            }).then(result => {
                //this.showspinner = true;
                this.getFilterValues();
                this.showToast('Success', result);
            }).catch(error => {
                console.log(JSON.stringify(error));
            });
        }
    }


    previewFilter(event) {
        this.showspinner = true;

        let filter = event.target.value;
        this.choosenFilterName = filter;
        this.selectedQueues = this.onloadresult.filtername_selectedQueueids[filter];
        this.Statusvalue = this.onloadresult.filtername_selectedStatus[filter];
        this.Sevvalue = this.onloadresult.filtername_selectedSeverity[filter];
        var allfiltervalues = this.onloadresult.FilterNames;
        this.displaymessage = '\'' + this.choosenFilterName + '\' filter currently applied';

        this.selectedRowsfromFilter =  this.onloadresult.filtername_selectedTerritories[filter].length>0 ?  this.onloadresult.filtername_selectedTerritories[filter] : this.maxnumofdgratrecs;
        
        var chosendgratvalues = this.selectedRowsfromFilter.length === this.maxnumofdgratrecs.length ? [] : this.selectedRowsfromFilter;
       
        ApplyFilter({
            SelectedQueueValues: this.selectedQueues,
            SelectedSevValues: this.Sevvalue,
            SelectedStatusValues: this.Statusvalue,
            SelectedDGRAT: chosendgratvalues,
            filtername: filter
        }).then(result => {
            this.SavedFilters = [];
            const items = [];
            for (let i = 0; i < allfiltervalues.length; i++) {

                if (filter === allfiltervalues[i]) {
                    items.push({
                        label: allfiltervalues[i] + ' ⭐',
                        value: allfiltervalues[i]
                    });
                }
                else {
                    items.push({
                        label: allfiltervalues[i],
                        value: allfiltervalues[i]
                    });
                }
            }
            this.SavedFilters.push(...items);

            this.showToast('Success', result);
            this.ClearPollerAndRefreshTable();
        }).catch(error => {
            this.showspinner = false;
            console.log(JSON.stringify(error));
        });
    }


    assignReasontoCase() {

        if(typeof this.getPendingCasevalue == 'undefined')
        {
            this.showToast('Error', 'Please choose a pending case reason!');
        }

        else if (this.getPendingCasevalue === 'Others' && typeof this.othersreason == 'undefined') {
            this.showToast('Error', 'Please fill up the necessary fields!');
        }
        else {
            this.showPendingReasonModal = false;
            this.showspinner = true;
            savePendingReason({
                isCaseStatusChange : this.showStatusWarning,
                pendingcaseoption: this.getPendingCasevalue,
                CaseID: this.currentrecordid,
                othersreason: this.othersreason
            }).then(result => {
                this.showspinner = false;
                this.showToast('Success', 'Changes saved!');
                this.ClearPollerAndRefreshTable();
            }).catch(error => {
                this.showspinner = false;
                console.log(JSON.stringify(error));
            });
        }

    }

    updateCaseOwner() {
        this.showChangeOwnerModal = false;
        if (this.showUserOwner) {
            var ownerField = this.template.querySelector(`[data-id="OwnerId"]`).value;
        }
        else {
            var ownerField = this.selectedQueueforChange;
        }
        this.showspinner = true;
        assignCasetoUser({
            setCaseIds: this.selectedcasefromqueue,
            newCaseOwner: ownerField
        }).then(result => {
            this.showToast('Success', 'Owner has been succesfully changed for the selected cases.');
            this.ClearPollerAndRefreshTable();
            this.selectedcasefromqueue = [];
            var payload = { caseView: 'refresh' };
            publish(this.messageContext, caseViewVal, payload);

        }).catch(error => {
            this.showspinner = false;
            console.log(JSON.stringify(error));
        });
    }

    //-----------------Modal / Toast related functions---------------------
    showUserOwner = true;
    showQueueOwner = false;
    handleOnselect(e) {
        if (e.detail.value === 'People') {
            this.showUserOwner = true;
            this.showQueueOwner = false;
        }
        else {
            this.showQueueOwner = true;
            this.showUserOwner = false;
        }

    }

    selectedQueueforChange;
    onQueueSelection(e) {
        this.selectedQueueforChange = e.detail.selectedRecordId;
    }

    hidemyopencasesTable() {
        var x = this.template.querySelector(".panelCasesInQueue");
        x.style.height = "0vh";
        this.displayCase = !this.displayCase;
    }

    showmyopencasesTable() {
        let x = this.template.querySelector(".panelCasesInQueue");
        if (this.TotalCount <= 5)
            x.style.height = "35vh";
        else
            x.style.height = "65vh";
        this.displayCase = !this.displayCase;
    }

    showToast(type, msg) {
        const event = new ShowToastEvent({
            "title": "",
            "message": msg,
            "variant": type,
            "mode": "dismissable"

        });
        this.dispatchEvent(event);

    }
    openModal() {
        this.showChangeOwnerModal = true;
    }

    closeChangeOwnerModal() {
        this.showChangeOwnerModal = false;
        this.showPendingReasonModal = false;
    }


    filterVisibility = false;

    toggleFilterVisibility(){
        this.filterVisibility = !this.filterVisibility;
    }

    onBackdropClick(event){
        let id = event.currentTarget.dataset.id;
        if(id === 'filters'){
            this.filterVisibility = false;
        }
    }

    @track
    filtersActiveTab = ALL_FILTERS_TAB;

    setFiltersActiveTab(tabId){
        if(this.filtersActiveTab !== tabId){
            this.filtersActiveTab = tabId;
            let tabSet = this.template.querySelector("lightning-tabset[data-id='filters-tabset']");
            if(tabSet) tabSet.activeTabValue = tabId;
        }
    }

    onFilterCreationCancel(){
        this.showNewFilterCreation = false;
        this.showNewFilterButton = true;
        //Restore previosly selected filter selections
        let filter = this.choosenFilterName;
        this.selectedQueues = this.onloadresult.filtername_selectedQueueids[filter];
        this.Statusvalue = this.onloadresult.filtername_selectedStatus[filter];
        this.Sevvalue = this.onloadresult.filtername_selectedSeverity[filter];
        this.selectedRowsfromFilter =  this.onloadresult.filtername_selectedTerritories[filter].length>0 ?  this.onloadresult.filtername_selectedTerritories[filter] : this.maxnumofdgratrecs;
        this.displaymessage = `'${this.choosenFilterName}' filter currently applied`;
        this.setFiltersActiveTab(ALL_FILTERS_TAB);
    }

    onNextFilterTabClick(){
        let filterNameField = this.template.querySelector("[data-id='filterName']");
        if(!filterNameField.checkValidity()){
            filterNameField.reportValidity();
        }else{
            let nameAlreadyExists = this.onloadresult && Array.isArray(this.onloadresult.FilterNames) && this.onloadresult.FilterNames.includes(filterNameField.value);
            if(nameAlreadyExists){
                filterNameField.setCustomValidity(ERROR_DUPLICATE_FILTER_NAME);
                filterNameField.reportValidity();
            }else{
                this.setFiltersActiveTab(QUEUE_SELECTION_TAB);
            }
        }
    }
}