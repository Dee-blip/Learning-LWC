/** @Date		:	June 20 2020
* @Author		: 	Sumukh SS 
* @Description	:	Re-write of Akatec all queue cases in LWC
*/

import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { loadStyle } from 'lightning/platformResourceLoader';
import resourceName from '@salesforce/resourceUrl/SC_Akatec_LightningMigration';

import getAllData from '@salesforce/apex/SC_Akatec_Lightning_Homepage_v2.getCases';
import assigncase from '@salesforce/apex/SC_Akatec_Lightning_Homepage_v2.assignCaseToUser';
import getSavedGeo from '@salesforce/apex/SC_Akatec_Lightning_Homepage_v2.getSavedGeo';
import savegeofilters from '@salesforce/apex/SC_Akatec_Lightning_Homepage_v2.saveSelectedFilters';
import reporteedetails from '@salesforce/apex/SC_Akatec_Lightning_Homepage_v2.getDirectReporteeCount';
import tsedetails from '@salesforce/apex/SC_Akatec_Lightning_Homepage_v2.getAccountTeamDetails';

import { QUEUE_COLS } from './sC_Akatec_Homepage_AllopenCases_Const';
import {getMasterTableColumns, getSortingInfo, saveMasterTableColumnState, saveSortingInfo} from "./localstorageHelper";

import {
    publish,
    subscribe,
    unsubscribe,
    APPLICATION_SCOPE,
    MessageContext
} from 'lightning/messageService';
import refreshtype from '@salesforce/messageChannel/akatechome__c';

export default class AllOpenCases extends NavigationMixin(LightningElement) {

    now;
    columns = [];
    queuecolumns = QUEUE_COLS;


    data;
    queuedata;

    showspinner;
    TotalCount = 0;

    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    sortedBy = 'Age';
    QueuesortDirection = 'asc';
    QueuesortedBy = 'queueName';
    offset = 1;
    queryTerm;
    AllDataforstorage;
    checkboxvalue = [];
    PollID;

    currentRecord = {};
    IsManager;
    timeoutId;
    displayCase = true;
    maxoffset;
    reporteelist = [];
    TSElist;
    currentrecordid;

    //-------------------Lightning Messaging Service -----------------------------
    @wire(MessageContext)
    messageContext;

    subscription = null;

    // Encapsulate logic for Lightning message service subscribe and unsubsubscribe
    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                refreshtype,
                (message) => this.handleMessage(message),
                { scope: APPLICATION_SCOPE }
            );
        }
    }

    unsubscribeToMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    handleMessage() {

    }

    get severityoptions() {
        return [
            { label: '1', value: '1' },
            { label: '2', value: '2' },
            { label: '3', value: '3' }
        ];
    }

    severityvalue = ['1', '2', '3'];

    handlesevChange(e) {

        /* if (e.detail.value.length < 1) {
             this.showToast('Oops!', 'error', 'An Empty Table? You need to select atleast 1 severity!');
         }
         else*/
        this.severityvalue = e.detail.value;
    }

    get suppDelTypeOptions() {
        return [
            { label: 'Geo', value: 'Geo' },
            { label: 'Global', value: 'Global' }
        ];
    }

    suppDelTypeValue = ['Geo','Global'];

    handleSuppDelTypeChange(e) {

        /* if (e.detail.value.length < 1) {
             this.showToast('Oops!', 'error', 'An Empty Table? You need to select atleast 1 severity!');
         }
         else*/
        this.suppDelTypeValue = e.detail.value;
    }

    get Checkboxoptions() {
        return [
            { label: 'NORTHAM', value: 'NORTHAM' },
            { label: 'APJ', value: 'APJ' },
            { label: 'EMEA', value: 'EMEA' },
            { label: 'LATAM', value: 'LATAM' }
        ];
    }
    handlecheckboxChange(e) {
        /* if (e.detail.value.length < 1) {
             this.showToast('Oops!', 'error', 'An Empty Table? You need to select atleast 1 geography!');
         }
         else*/
        this.checkboxvalue = e.detail.value;
    }
    handleKeyUp(evt) {
        this.queryTerm = evt.target.value;
        clearTimeout(this.timeoutId);
        this.timeoutId = setTimeout(this.searchtable.bind(this), 500);
    }

    searchtable() {
        //let p0 = performance.now();
        var searchFilter = this.queryTerm.toUpperCase();
        var allRecords = this.AllDataforstorage;
        var tempArray = [];
        if (searchFilter.length > 0) {
            for (let i = 0; i < allRecords.length; i++) {
                //Aditi - added search for caseProd - ESESP-5717
                if ((allRecords[i].akamcaseid && allRecords[i].akamcaseid.toUpperCase().indexOf(searchFilter) !== -1) ||
                    (allRecords[i].AccountName && allRecords[i].AccountName.toUpperCase().indexOf(searchFilter) !== -1) ||
                    (allRecords[i].Country && allRecords[i].Country.toUpperCase().indexOf(searchFilter) !== -1) ||
                    (allRecords[i].WorkType && allRecords[i].WorkType.toUpperCase().indexOf(searchFilter) !== -1) ||
                    (allRecords[i].Geography && allRecords[i].Geography.toUpperCase().indexOf(searchFilter) !== -1) ||
                    (allRecords[i].CaseOwner && allRecords[i].CaseOwner.toUpperCase().indexOf(searchFilter) !== -1) ||
                    (allRecords[i].SupportLevel && allRecords[i].SupportLevel.toUpperCase().indexOf(searchFilter) !== -1) ||
                    (allRecords[i].Subject && allRecords[i].Subject.toUpperCase().indexOf(searchFilter) !== -1) ||
                    (allRecords[i].caseProd && allRecords[i].caseProd.toUpperCase().indexOf(searchFilter) !== -1)
                ) {
                    tempArray.push(allRecords[i]);
                }
            }

            let x = this.template.querySelector('.AllcasesDatatable');
            x.enableInfiniteLoading = false;
            this.data = tempArray;
            this.TotalCount = tempArray.length;

        }
        else {
            this.offset = 1;
            let x = this.template.querySelector('.AllcasesDatatable');
            x.enableInfiniteLoading = true;
            this.data = this.AllDataforstorage.slice(0, 50);
            this.TotalCount = this.AllDataforstorage.length;
        }
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

    AllOpenCasesColvalue = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10','11','12','13'];

    get AllOpenCasesColOptions() {
        return [
            { label: 'Account', value: '1' },
            { label: 'Severity', value: '2' },
            { label: 'Geography', value: '3' },
            { label: 'TSE', value: '4' },
            { label: 'Subject', value: '5' },
            { label: 'Case Product', value: '6' },//Added by Aditi
            { label: 'Country', value: '7' },
            { label: 'Industry', value: '8' },
            { label: 'Region', value: '9' },
            { label: 'Territory', value: '10' },
            { label: 'WorkType', value: '11' },
            { label: 'Age', value: '12' },
            { label: 'Support Level', value: '13' },
            { label: 'Owner', value: '14' }
        ];
    }

    handleallopenColChange(e) 
    {
        if (e.detail.value.length > 0) 
        {
            this.AllOpenCasesColvalue = e.detail.value;

            let allCols = getMasterTableColumns();
            let newcols = [allCols[0]];
            for (let i = 0; i < e.detail.value.length; i++) {
                let index = e.detail.value[i];
                newcols = [...newcols, allCols[index]];
            }
            newcols = [...newcols, allCols[15]];//Updated by Aditi - 14 to 15
            newcols = [...newcols, allCols[16]];//Updated by Aditi - 15 to 16
            this.columns = newcols;

            this.saveColSelection();
        }
        else {
            this.showToast('error', 'Hide everything?', 'Please select atleast 1 column to display!');
        }
    }

    connectedCallback() {
        let allColumns = getMasterTableColumns();
        this.columns = allColumns;
        loadStyle(this, resourceName + '/SC_Akatec_Lightning_Resource/SC_Akatec_Homepage.css');
        this.subscribeToMessageChannel();
        window.addEventListener("visibilitychange", this.listenForMessageCasesinQueue.bind(this));

        //getting saved column selection from cookies
        this.getCookie('allOpenCasesCol');
        if (typeof this.allcookieval !== 'undefined') {
            this.allcookieval = this.allcookieval.split(',');
            this.AllOpenCasesColvalue = this.allcookieval;

            let allCols = allColumns;
            let newcols = [allCols[0]];
            for (let i = 0; i < this.AllOpenCasesColvalue.length; i++) {
                let index = this.AllOpenCasesColvalue[i];
                newcols = [...newcols, allCols[index]];
            }
            newcols = [...newcols, allCols[15]];//Updated by Aditi - 11 to 12
            newcols = [...newcols, allCols[16]];//Updated by Aditi - 12 to 13
            this.columns = newcols;

        }
        this.showspinner=true;
        //Getting saved filters
        getSavedGeo({})
            .then(result => {
                this.showspinner=false;
                this.IsManager = result.IsManager;
                this.queuedata = result.akatecqueue_List;
                this.selectedQueues = result.savedQueues;
                if (typeof result.savedGeo !== 'undefined') {
                    this.showspinner = true;
                    this.checkboxvalue = result.savedGeo;
                    this.severityvalue = result.savedSev;
                    this.suppDelTypeValue = result.savedSuppDelType;

                    this.getCasesdata();
                    this.PollID = setInterval(() => {
                        this.getCasesdata();
                    }, 100000);

                }
                else {
                    this.checkboxvalue = ['NORTHAM', 'LATAM', 'EMEA', 'APJ'];
                    this.showToast('Hey there!', 'warning', 'Please choose atleast 1 technical queue to view unassigned Cases!');
                }

            })
            .catch(error => {
                this.showspinner=false;
                console.log(JSON.stringify(error));
            });
        let sortingInfo = getSortingInfo();
        if (sortingInfo){
            this.sortedBy = sortingInfo.sortedBy;
            this.sortDirection = sortingInfo.sortDirection;
        }

    }

    listenForMessageCasesinQueue() {
        if (document.hidden || document.webkitHidden || document.msHidden || document.mozHidden) {
            console.log('Clearing poller as user left!');
            window.clearInterval(this.PollID);
        }
        else {
            console.log('User came back!');
            this.showspinner = true;
            this.ClearPollerAndRefreshTable();

        }
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
            this.getCasesdata();
        }, 100000);
        this.getCasesdata();
    }

    hideCaseTable() {
        var x = this.template.querySelector(".panelCasesinQueue");
        x.style.height = "0vh";
        this.displayCase = !this.displayCase;
    }

    showCaseTable() {
        let x = this.template.querySelector(".panelCasesinQueue");
        if (this.TotalCount <= 8)
            x.style.height = "35vh";
        else
            x.style.height = "50vh";
        this.displayCase = !this.displayCase;
    }

    getCasesdata() {
        getAllData({
        }).then(result => {
            this.now = Date.now();
            this.showspinner = false;
            this.AllDataforstorage = result;
            this.TotalCount = result.length;
            this.maxoffset = Math.ceil(this.TotalCount / 50);

            if (this.queryTerm) {
                this.searchtable();
                this.onHandleSort();
            }else{
                this.onHandleSort();
                if (result.length >= 50){
                    this.data = result.slice(0, this.offset * 50);
                    let x = this.template.querySelector('.AllcasesDatatable');
                    x.enableInfiniteLoading = true;
                }
            }

            if (this.displayCase) {
                let x = this.template.querySelector(".panelCasesinQueue");
                if (this.TotalCount <= 8)
                    x.style.height = "35vh";
                else
                    x.style.height = "50vh";
            }
        })
            .catch(error => {
                this.showspinner=false;
                console.log(JSON.stringify(error));
            });
    }

    saveFilters() 
    {
        if (this.checkboxvalue.length < 1 || this.severityvalue.length < 1 || this.selectedQueues.length < 1 || this.suppDelTypeValue.length < 1) 
        {
            this.showToast('An Empty Table?', 'error', 'Please select all filters!');
        }
        else {
            this.showspinner = true;
            savegeofilters({
                SelectedGeoFromUser: this.checkboxvalue,
                SelectedQueuesFromUser: this.selectedQueues,
                selectedSev: this.severityvalue,
                selectedSuppDelType: this.suppDelTypeValue
            })
                .then(() => {
                    this.showToast('Saved!', 'success', 'Filter selection saved! Refreshing data..');
                    this.ClearPollerAndRefreshTable();
                }).catch(error => {
                    this.showspinner = false;
                    console.log(JSON.stringify(error));
                });
        }
    }

    saveColSelection() {
        var columnschoosen = this.AllOpenCasesColvalue;
        this.createCookie('allOpenCasesCol', columnschoosen, 3650);
    }

    createCookie(name, value, days) {
        var expires;
        if (days) {
            const date = new Date();
            date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000));
            expires = "; expires=" + date.toGMTString();
        }
        else {
            expires = "";
        }
        document.cookie = name + "=" + value + expires + "; path=/";
    }

    allcookieval;
    getCookie(name) {
        var cookieString = "; " + document.cookie;
        var parts = cookieString.split("; " + name + "=");
        if (parts.length === 2) {
            this.allcookieval = parts.pop().split(";").shift();
        }
    }


    //--------------------------SORTING----------------------------


    sortBy(field, reverse, primer) {
        const key = primer
            ? function (x) {
                if (typeof x[field] === 'string') { return primer(x[field].toLowerCase()); }
                // eslint-disable-next-line no-else-return
                else { return primer(x[field]); }
            }
            : function (x) {
                if (typeof x[field] === 'string') { return x[field].toLowerCase(); }
                // eslint-disable-next-line no-else-return
                else { return x[field]; }
            };

        return function (a, b) {

            if (key(a) === null || typeof key(a) === 'undefined') {
                return 1;
            }
            // eslint-disable-next-line no-else-return
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
            saveSortingInfo(sortedBy,sortDirection);
        }
        else {
            sortedBy = this.sortedBy;
            sortDirection = this.sortDirection;
        }
        if (sortedBy === 'AkamCaseIDURL') { sortedBy = 'akamcaseid'; }

        if (this.queryTerm) {
            const cloneData = [...this.data];
            cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
            this.data = cloneData;
        }

        else {

            const cloneData = [...this.AllDataforstorage];
            if (sortedBy === 'SLA') {
                cloneData.sort(this.sortBy('SLAinminutes', sortDirection === 'asc' ? 1 : -1));

            }
            else {
                cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
            }

            this.AllDataforstorage = cloneData;

            if (event) {
                this.offset = 1;
                let x = this.template.querySelector('.AllcasesDatatable');
                x.enableInfiniteLoading = false;
                setTimeout(this.setInfiniteloading.bind(this), 500);
                this.data = cloneData.slice(0, 50);
            }
            else {
                this.data = cloneData.slice(0, this.offset * 50);
            }
        }
    }

    setInfiniteloading() {
        var x = this.template.querySelector('.AllcasesDatatable');
        x.enableInfiniteLoading = true;
    }

    onHandleQueueSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.queuedata];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.queuedata = cloneData;
        this.QueuesortDirection = sortDirection;
        this.QueuesortedBy = sortedBy;

    }

    loadMoreData(e) {
        console.log('load more');
        if (this.TotalCount < 50) {   //console.log('less than 50');
            e.target.enableInfiniteLoading = false;
        }
        else if (this.maxoffset === this.offset) {
            e.target.enableInfiniteLoading = false;

        }
        else {
            this.offset++;
            this.data = this.AllDataforstorage.slice(0, this.offset * 50);
        }
    }

    //--------------------------ROW ACTIONS----------------------------

    tseexists = true;

    handleRowActions(event) {

        let caseId = event.detail.row.AkamCaseIDURL.substring(1);
        this.currentrecordid = caseId;
        const actionName = event.detail.action.name;

        let modal = this.template.querySelector('[data-id="' + actionName + '"');
        if (modal) {
            modal.classList.remove('slds-hide');
            modal.toggle();
        }

        if (actionName === 'OpenCaseURL') {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: caseId,
                    objectApiName: 'Case',
                    actionName: 'view'
                }
            });

        }

        if (actionName === 'case-details') {
            const wrapRec = this.data.find(el => ('/' + caseId) === el.AkamCaseIDURL);
            this.currentRecord = wrapRec;
        }
        if (actionName === 'assign-case' && this.IsManager) {
            this.showspinner = true;
            reporteedetails({})
                .then(result => {
                    this.reporteelist = result;
                    this.showspinner = false;
                })
                .catch(error => {
                    console.log(JSON.stringify(error));
                });
        }
        if (actionName === 'viewTSE') {
            this.showspinner = true;
            this.TSElist = [];

            tsedetails({
                caseid: caseId
            }).then(result => {
                this.showspinner = false;
                let i=0;
                // eslint-disable-next-line guard-for-in
                for (let key in result) {
                        i++;
                        this.TSElist.push({ value: result[key], key: key });
                    }
                    console.log(i);
                    if (i>0) {

                    this.tseexists = true;
                }
                else {
                    this.tseexists = false;
                }
            })
                .catch(error => {
                    console.log(JSON.stringify(error));
                });
        }

    }


    assignCasetoUser() {
        this.showspinner = true;
        // eslint-disable-next-line	no-useless-concat
        let modal = this.template.querySelector('[data-id="' + 'assign-case' + '"');
        if (modal) {
            modal.toggle();
        }
        assigncase({
            username: null,
            CaseID: this.currentrecordid
        })
            .then(result => {
                this.showspinner = false;

                if (result === 'success') {
                    let payload = { refreshtype: 'myopencases' };
                    publish(this.messageContext, refreshtype, payload);
                    this.showToast('Completed!', 'success', 'Case has been assigned to you.');
                    this.ClearPollerAndRefreshTable();
                }
                else
                    this.showToast('Error', 'error', result);

            })
            .catch(error => {
                this.showspinner = false;
                console.log(JSON.stringify(error));
            });
    }

    assigncasetoreportee(e) {
        this.showspinner = true;
        // eslint-disable-next-line	no-useless-concat
        let modal = this.template.querySelector('[data-id="' + 'assign-case' + '"');
        if (modal) {
            modal.toggle();
        }
        assigncase({
            userid: e.target.value,
            CaseID: this.currentrecordid
        })
            .then(result => {
                this.showspinner = false;

                if (result === 'success') {

                    let payload = { refreshtype: 'myopencases' };
                    publish(this.messageContext, refreshtype, payload);
                    this.showToast('Done!', 'success', 'Case has been assigned!');
                    this.ClearPollerAndRefreshTable();
                }
                else
                    this.showToast('Error', 'error', result);
            })
            .catch(error => {
                this.showspinner = false;
                console.log(JSON.stringify(error));
            });
    }

    openNewCase() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Case',
                actionName: 'new'
            }
            ,
            state: {
                useRecordTypeCheck: true,
            }
        });
    }

    showToast(title, type, msg) {
        const event = new ShowToastEvent({
            "title": title,
            "message": msg,
            "variant": type,
            "mode": "dismissable"

        });
        this.dispatchEvent(event);

    }

    closeAssignModal() {
        // eslint-disable-next-line	no-useless-concat
        let modal = this.template.querySelector('[data-id="' + 'assign-case' + '"');
        if (modal) {
            modal.toggle();
        }
    }


    async onMasterTableColumnResize(event){
        let {columnWidths,isUserTriggered} = event.detail;
        if (!isUserTriggered) return;
        this.columns.forEach((col,index) => {
            col.initialWidth = columnWidths[index];
        });
        saveMasterTableColumnState(this.columns);
    }

}