/** @Date		:	June 20 2020
* @Author		: 	Sumukh SS 
* @Description	:	Re-write of Akatec all queue cases in LWC
*/

import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { loadStyle } from 'lightning/platformResourceLoader';
import resourceName from '@salesforce/resourceUrl/SC_Akatec_LightningMigration';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import getMyCaseData from '@salesforce/apex/SC_Akatec_Lightning_Homepage_v2.getMyopenCases';
import getOnLoadValues from '@salesforce/apex/SC_Akatec_Lightning_Homepage_v2.getMyOpenCasesOnloadvalues';
import clearrecentupdate from '@salesforce/apex/SC_Akatec_Lightning_Homepage_v2.suppressCaseUpdate';
import getAkachatDetails from '@salesforce/apex/SC_Akatec_Lightning_Homepage_v2.getAkaChatTranscript';
import createTaskLOE from '@salesforce/apex/SC_Akatec_Lightning_Homepage_v2.createTaskLOE';

import { MY_TEAM_COLS } from './sC_Akatec_Homepage_MyopenCases_Const';
import { MY_OPEN_COLS } from './sC_Akatec_Homepage_MyopenCases_Const';

const columns = [
];

import {
    subscribe,
    APPLICATION_SCOPE,
    MessageContext
} from 'lightning/messageService';
import refreshtype from '@salesforce/messageChannel/akatechome__c';
import {getColumnsState, getSortByColumn, storeColumnState, storeSortByColumn} from "c/scStoreDatatableState";


export default class SC_Akatec_Homepage_MyopenCases extends NavigationMixin(LightningElement)
{

    columns = columns;
    data;
    showspinner = true;
    TotalCount = 0;
    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    sortedBy = 'Age';
    queryTerm;
    displayCase = true;
    nowMyopenCases;
    AllDataforstorage;
    querytype = 'MyOpenCases';
    isManager = false;
    MyOpenCasesColvalue = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11','12'];
    offset = 1;
    maxoffset;

    showAkachatModal = false;
    showrecordeditspinner = false;
    showEditModal = false;
    showCaseClosureModal = false;
    caseRecordId;
    akachatdetails;
    showsupervisortranscript;
    akamcaseid;
    caseRecordtypeid;

    tasktypevalues;
    choosentasktypevalue;
    subjectchangevalue;//Added by aditi for ESESP-5339
    LOEchangevalue;//Added by aditi for ESESP-5339
    visibilityvalue;
    myopencasessize = 12;
    sidenavsize = 3;
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
                (message) => this.handleCaseMessage(message),
                { scope: APPLICATION_SCOPE }
            );
        }
    }


    handleCaseMessage(message) {
        //console.log(JSON.stringify(message));
        let view = message.refreshtype;
        if (view === 'myopencases')
            this.getMyOpenCasesData();
    }


    get MyOpenCasesColOptions() {
        return [
            { label: 'Account', value: '1' },
            { label: 'Subject', value: '2' },
            { label: 'Geography', value: '3' },
            { label: 'Country', value: '4' },
            { label: 'LOE', value: '5' },
            { label: 'Work Type', value: '6' },
            { label: 'Age', value: '7' },
            { label: 'Status', value: '8' },
            { label: 'Severity', value: '9' },
            { label: 'Support Level', value: '10' },
            { label: 'Next Action', value: '11' },
            { label: 'AKAM Modified Date', value: '12' }
        ];
    }

    get Statusoptions() {
        return [
            { label: 'Assigned', value: 'Assigned' },
            { label: 'Work in Progress', value: 'Work in Progress' },
            { label: 'Mitigated', value: 'Mitigated / Solution Provided' }
        ];
    }

    Statusvalue = ['Assigned', 'Work in Progress', 'Mitigated / Solution Provided']


    handlestatusChange(e) {
        this.Statusvalue = e.detail.value;
    }

    tasktypechange() {
        this.choosentasktypevalue = this.template.querySelector('[data-name="taskType"]');//Changed by aditi for ESESP-5339
    }

    //Aditi - added below two handler methods for ESESP-5339
    handleSubjectChange(){
        this.subjectchangevalue = this.template.querySelector('[data-name="taskSubject"]');
    }

    handleLOEChange(){
        this.LOEchangevalue = this.template.querySelector('[data-name="taskloe"]');
    }

    get TaskVisibilityoptions() {
        return [
            { label: 'Customer', value: 'Customer' },
            { label: 'Internal Only', value: 'Internal Only' },
            { label: 'Partner Only', value: 'Partner Only' }
        ];
    }

    taskvisibilitychange() {
        this.visibilityvalue = this.template.querySelector('[data-name="taskVisibility"]');//Changed by aditi for ESESP-5339
    }

    get worktypeoptions() {
        return [
            { label: 'Reactive', value: 'Reactive' },
            { label: 'Proactive', value: 'Proactive' },
        ];
    }

    CaseWorktypevalue = ['Reactive', 'Proactive'];

    handleworktypeChange(e) {
    
        this.CaseWorktypevalue = e.detail.value;

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

        this.severityvalue = e.detail.value;

    }

    handlecColChange(e) {
        if (e.detail.value.length > 0) {
            this.MyOpenCasesColvalue = e.detail.value;

            var allCols = MY_OPEN_COLS
            var newcols = [allCols[0]];

            for (var i = 0; i < this.MyOpenCasesColvalue.length; i++) {
                var index = this.MyOpenCasesColvalue[i];
                newcols = [...newcols, allCols[index]];
            }
            newcols = [...newcols, allCols[13]];

            const option = {
                type: 'action',
                typeAttributes: {
                    rowActions: this.getRowActions,
                    menuAlignment: 'right'
                }
            }
            this.columns = [...newcols, option];
            this.saveColSelection();
        }
        else {
            this.showToast('error', 'Hide everything?', 'Please select atleast 1 column to display!');
        }
    }

    setMyopenCols() {
        const option = {
            type: 'action',
            typeAttributes: {
                rowActions: this.getRowActions,
                menuAlignment: 'right'
            }
        }
        this.columns = [...MY_OPEN_COLS, option];

    }

    getRowActions(row, doneCallback) {
        const actions = [];
        actions.push({ label: 'Edit Case', name: 'Inline Edit' });
        actions.push({ label: 'Portal', name: 'Portal' });
        actions.push({ label: 'New Task (LOE)', name: 'new_task' });
        if (row.casestatus === 'Mitigated / Solution Provided') {
            actions.push({ label: 'Close Case', name: 'close_case' });
        }
        if (typeof row.LiveChatId !== 'undefined') {
            actions.push({ label: 'View Chat Transcript', name: 'View chat transcript' });
        }
        doneCallback(actions);
    }


    handletoggleChecked(e) {
        this.showspinner = true;
        if (e.target.checked) {
            this.querytype = 'MyTeamCases';
            this.columns = MY_TEAM_COLS;
           // this.setInfiniteloading();
        }
        else {
            this.querytype = 'MyOpenCases';
            this.setMyopenCols();
        }
        this.getMyOpenCasesData();
    }

    handleKeyUp(evt) {
        this.queryTerm = evt.target.value;
        clearTimeout(this.timeoutId);
        this.timeoutId = setTimeout(this.searchtable.bind(this), 500);
    }

    searchtable() {
        var searchFilter = this.queryTerm.toUpperCase();
        var allRecords = this.AllDataforstorage;
        var tempArray = [];
        if (searchFilter.length > 0) {

            for (var i = 0; i < allRecords.length; i++) {
                if ((allRecords[i].akamcaseid && allRecords[i].akamcaseid.toUpperCase().indexOf(searchFilter) != -1) ||
                    (allRecords[i].AccountName && allRecords[i].AccountName.toUpperCase().indexOf(searchFilter) != -1) ||
                    (allRecords[i].Subject && allRecords[i].Subject.toUpperCase().indexOf(searchFilter) != -1) ||
                    (allRecords[i].Geography && allRecords[i].Geography.toUpperCase().indexOf(searchFilter) != -1) ||
                    (allRecords[i].Country && allRecords[i].Country.toUpperCase().indexOf(searchFilter) != -1) ||
                    (allRecords[i].WorkType && allRecords[i].WorkType.toUpperCase().indexOf(searchFilter) != -1) ||
                    (allRecords[i].casestatus && allRecords[i].casestatus.toUpperCase().indexOf(searchFilter) != -1) ||
                    (allRecords[i].SupportLevel && allRecords[i].SupportLevel.toUpperCase().indexOf(searchFilter) != -1) ||
                    (allRecords[i].CaseOwner && allRecords[i].CaseOwner.toUpperCase().indexOf(searchFilter) != -1)
                ) {
                    tempArray.push(allRecords[i]);
                }
            }
            var x = this.template.querySelector('.MycasesDatatable');
            x.enableInfiniteLoading = false;
            this.data = tempArray;
            this.TotalCount=tempArray.length;
        }
        else {
            this.offset = 1;
            var x = this.template.querySelector('.MycasesDatatable');
            x.enableInfiniteLoading = true;
            this.data = this.AllDataforstorage.slice(0, 50);
            this.TotalCount=this.AllDataforstorage.length;

        }
    }

    hidemycasesTable() {
        var x = this.template.querySelector(".panelmyOpenCases");
        x.style.height = "0vh";
        this.displayCase = !this.displayCase;
    }

    showmycasesTable() {
        let x = this.template.querySelector(".panelmyOpenCases");
        if (this.TotalCount <= 8)
            x.style.height = "35vh";
        else
            x.style.height = "50vh";
        this.displayCase = !this.displayCase;
    }

    connectedCallback() {
        loadStyle(this, resourceName + '/SC_Akatec_Lightning_Resource/SC_Akatec_Homepage.css')
        this.subscribeToMessageChannel();
        this.initializeSorting();
        //getting saved column selection from cookies
        this.getCookie('myOpenCasesCol');
        if (typeof this.cookieval !== 'undefined') {
            this.cookieval = this.cookieval.split(',');
            this.MyOpenCasesColvalue = this.cookieval;

            var allCols = MY_OPEN_COLS
            var newcols = [allCols[0]];

            for (var i = 0; i < this.MyOpenCasesColvalue.length; i++) {
                var index = this.MyOpenCasesColvalue[i];
                newcols = [...newcols, allCols[index]];
            }
            newcols = [...newcols, allCols[13]];

            const option = {
                type: 'action',
                typeAttributes: {
                    rowActions: this.getRowActions,
                    menuAlignment: 'right'
                }
            }
            this.columns = [...newcols, option];

        }
        else {
            this.setMyopenCols();
        }

        this.showspinner = true;
        getOnLoadValues({})
            .then(result => {
                console.log('isManager');
                console.log(result.isManager);
                this.isManager = result.isManager;
                this.caseRecordId = result.techrectypeid;
                this.tasktypevalues = [];
                const items = [];
                for (let i = 0; i < result.tasktypevalues.length; i++) {
                    items.push({
                        label: result.tasktypevalues[i],
                        value: result.tasktypevalues[i]
                    });
                }
                this.tasktypevalues.push(...items);
                this.getMyOpenCasesData();
            }).catch(error => {
                console.log(JSON.stringify(error));
            });
    }

    getMyOpenCasesData() {

        if (this.CaseWorktypevalue.length < 1 || this.severityvalue.length < 1 || this.Statusvalue.length < 1) {
            this.showToast('error', 'An Empty Table?', 'Please select all filters!');
        }
        else {
            this.showspinner = true;
            getMyCaseData({
                QueryType: this.querytype,
                worktype: this.CaseWorktypevalue,
                sev: this.severityvalue,
                statusval: this.Statusvalue
            })
                .then(result => {
                    this.nowMyopenCases = Date.now();
                    this.showspinner = false;
                    this.AllDataforstorage = result;
                    this.TotalCount = result.length;
                    this.maxoffset = Math.ceil(this.TotalCount / 50);

                    if (this.queryTerm) {
                        this.searchtable();
                        this.onHandleSort();
                    }

                    else {
                        if (result.length < 50) {
                            if (this.sortedBy !== 'Age') {
                                this.onHandleSort();
                            }
                            else
                                this.data = result;
                        }
                        else {

                            if (this.sortedBy !== 'Age') {
                                this.onHandleSort();
                            }
                            else {

                                this.data = this.AllDataforstorage.slice(0, this.offset * 50);
                                var x = this.template.querySelector('.MycasesDatatable');
                                x.enableInfiniteLoading = true;
                            }
                        }
                    }

                    if (this.displayCase) {
                        let x = this.template.querySelector(".panelmyOpenCases");
                        if (this.TotalCount <= 8)
                            x.style.height = "35vh";
                        else
                            x.style.height = "50vh";
                    }
                })
                .catch(error => {
                    this.showspinner = false;
                    console.log(error);
                });
        }
    }

    saveColSelection() {
        var columnschoosen = this.MyOpenCasesColvalue;

        this.createCookie('myOpenCasesCol', columnschoosen, 3650);

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
        console.log(value);
        document.cookie = name + "=" + value + expires + "; path=/";
    }

    cookieval;
    getCookie(name) {
        var cookieString = "; " + document.cookie;
        var parts = cookieString.split("; " + name + "=");
        if (parts.length === 2) {
            this.cookieval = parts.pop().split(";").shift();
        }
        //console.log(this.cookieval);
    }

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
            this.data = this.AllDataforstorage.slice(0, this.offset * 50);
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

        storeSortByColumn(this.tableName,sortedBy,sortDirection);

        if (sortedBy === 'AkamCaseIDURL') 
        {   sortedBy = 'akamcaseid';}

        //Added by Aditi for - ESESP-5370, sorting was not working correctly for this field
        if (sortedBy === 'akamModifiedDate') 
        {   sortedBy = 'akamModifiedDateVal';}
        
        if (this.queryTerm) {
            const cloneData = [...this.data];
            cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
            this.data = cloneData;
        }
        
        else {

        const cloneData = [...this.AllDataforstorage];
        if (sortedBy == 'SLA') {
            cloneData.sort(this.sortBy('SLAinminutes', sortDirection === 'asc' ? 1 : -1));
          
        }
        else {
            cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        }

        this.AllDataforstorage=cloneData;

        if(event)
        {
            this.offset=1;
            var x = this.template.querySelector('.MycasesDatatable');
            x.enableInfiniteLoading = false;
            setTimeout(this.setInfiniteloading.bind(this) , 500);
            this.data = cloneData.slice(0, 50);
        }
        else
        {
            this.data = cloneData.slice(0, this.offset * 50);
        }
    }
    }

    setInfiniteloading()
    {
        var x = this.template.querySelector('.MycasesDatatable');
        x.enableInfiniteLoading = true;
    }


    handleRowActions(event) {
        let actionName = event.detail.action.name;
        let caseid = event.detail.row.AkamCaseIDURL.substring(1);

        if (actionName === 'OpenCaseURL') {
            if (typeof event.detail.row.RecentUpdateColor !== 'undefined' && this.querytype === 'MyOpenCases') {

                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: caseid,
                        objectApiName: 'Case',
                        actionName: 'view'
                    },
                });

                clearrecentupdate({
                    CaseID: caseid
                })
                    .then(result => {
                        this.getMyOpenCasesData();
                    }).catch(error => {
                        console.log(JSON.stringify(error));
                    });

            }
            else {
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: caseid,
                        objectApiName: 'Case',
                        actionName: 'view'
                    },
                });
            }
        }

        if (actionName === 'Inline Edit') {
            this.showEditModal = true;
            this.showrecordeditspinner = true;
            this.caseRecordId = caseid;
            this.akamcaseid = event.detail.row.akamcaseid;

        }

        if (actionName === 'Portal') {
            const wrapRec = this.AllDataforstorage.find(el => ('/' + caseid) === el.AkamCaseIDURL);
            var akamacctid = wrapRec.akamacctid;
            window.open('https://control.akamai.com/apps/home-page#/manage-account?accountId=' + akamacctid, '_blank');
        }
        if (actionName === 'View chat transcript') {
            this.showspinner = true;
            const wrapRec = this.data.find(el => ('/' + caseid) === el.AkamCaseIDURL);
            //console.log(wrapRec.LiveChatId);
            getAkachatDetails({
                AkachatID: wrapRec.LiveChatId
            }).then(result => {
                this.showspinner = false;
                this.akachatdetails = result;
                if (result.SupervisorTranscriptBody) { this.showsupervisortranscript = true; }
                else { this.showsupervisortranscript = false; }
                this.showAkachatModal = true;

            }).catch(error => {
                console.log(JSON.stringify(error));
            });
        }
        if (actionName === 'close_case') {
            this.caseRecordId = caseid;
            this.showCaseClosureModal = true;
            this.showrecordeditspinner = true;
            this.akamcaseid = event.detail.row.akamcaseid;
        }
        if (actionName === 'new_task') {
            this.caseRecordId = caseid;
            this.akamcaseid = event.detail.row.akamcaseid;

            if (this.isManager) {
                var header = this.template.querySelector(".managerwotablecondensed");
                header.style.marginLeft = '31.5%';
            }
            else {
                var header = this.template.querySelector(".nmwotablecondensed");
                header.style.marginLeft = '43.5%';
            }

            var x = this.template.querySelector(".sidenavslot");
            x.style.height = '57vh';
            x.classList.toggle("slds-hidden");
            this.myopencasessize = 9;
        }

    }

    closeNav() {
        if (this.isManager) {
            var header = this.template.querySelector(".managerwotablecondensed");
            header.style.marginLeft = '34.5%';
        }
        else {
            var header = this.template.querySelector(".nmwotablecondensed");
            header.style.marginLeft = '46.5%';
        }

        var x = this.template.querySelector(".sidenavslot");
        x.style.height = 0;
        x.classList.toggle("slds-hidden");
        this.myopencasessize = 12;
    }

    closeCaseEditModal() {
        this.showEditModal = false;
        this.showAkachatModal = false;
        this.showCaseClosureModal = false;
    }

    handleCaseEditSuccess() {
        this.showrecordeditspinner = false;
        this.showEditModal = false;
        this.showToast('success', 'Saved!', 'Your changes have been saved!');

    }

    handleCaseSubmit() {
        this.showrecordeditspinner = true;

    }
    handleCaseLoad() {
        this.showrecordeditspinner = false;
    }
    handleCaseError() {
        this.showrecordeditspinner = false;
    }

    handleCaseCloseSuccess() {
        this.showrecordeditspinner = false;
        this.showCaseClosureModal = false;
        this.showToast('success', 'Closed!', 'Case has been successfully closed!');
        this.getMyOpenCasesData();

    }

    showToast(type, title, msg) {
        const event = new ShowToastEvent({
            "title": title,
            "message": msg,
            "variant": type,
            "mode": "dismissable"

        });
        this.dispatchEvent(event);

    }

    createNewTaskLOE() {

        //Aditi - updated this method for ESESP-5339 - added querySelector checks and made the values empty for vars in the .then success of createTaskLOE
        //Added by aditi for ESESP-5339 - below all null checks are added to ensure if value is there on the UI we add them in the references
        if(!this.choosentasktypevalue.value){
            this.choosentasktypevalue = this.template.querySelector('[data-name="taskType"]');
        }
        if(!this.subjectchangevalue.value){
            this.subjectchangevalue = this.template.querySelector('[data-name="taskSubject"]');
        }
        if(!this.LOEchangevalue.value){
            this.LOEchangevalue = this.template.querySelector('[data-name="taskloe"]');
        }
        if(!this.visibilityvalue.value){
            this.visibilityvalue = this.template.querySelector('[data-name="taskVisibility"]');
        }
        
        console.log('taskloe ::'+this.LOEchangevalue.value+'  tasksubject ::'+this.subjectchangevalue.value+'  visibility ::'+this.visibilityvalue.value+'  tasktype ::'+this.choosentasktypevalue.value);

        if (!this.choosentasktypevalue.value || !this.subjectchangevalue.value || !this.visibilityvalue.value || !this.LOEchangevalue.value) { this.showToast('warning', 'Oops!', 'Please complete all fields to create a new task!'); }
        else {

            this.closeNav();
            this.showspinner = true;

            createTaskLOE({
                CaseID: this.caseRecordId,
                tasktype: this.choosentasktypevalue.value,
                tasksubject: this.subjectchangevalue.value,
                loe: this.LOEchangevalue.value,
                visibility: this.visibilityvalue.value
            }).then(result => {
                this.showspinner = false;
                if (result === 'success') {
                    this.showToast('success', 'Created!', 'Task has been created successfully!');
                    this.getMyOpenCasesData();

                    //Changed by aditi for ESESP-5339 - making the value of reference of the query selector as empty(reset) for next transaction
                    this.visibilityvalue.value = null;
                    this.choosentasktypevalue.value = null;
                    this.LOEchangevalue.value = '';
                    this.subjectchangevalue.value = '';
                }
                else {
                    this.showToast('error', 'Oops!', result);
                }
            }).catch(error => {
                this.showspinner = false;
                console.log(JSON.stringify(error));
                // this.showToast('error', 'Oops!', JSON.stringify(error));
            });
        }
    }

    tableName = 'datatable_sc_akatec_homepage_myopencases';
    keyField = 'fieldName';

    onColumnWidthResize(event){
        let {columnWidths,isUserTriggered} = event.detail;
        if (!isUserTriggered) return;
        this.columns.forEach((col,index) => {
            col.initialWidth = columnWidths[index];
        });
        storeColumnState(this.tableName,this.columns,this.keyField,['initialWidth']);
    }

    get transformedColumns(){
        let columnState = getColumnsState(this.tableName);
        return this.columns.map(col =>({
            ...col,
            initialWidth: (columnState[col[this.keyField]] && columnState[col[this.keyField]].initialWidth) || col.initialWidth
        }));
    }

    initializeSorting(){
        let info = getSortByColumn(this.tableName);
        this.sortedBy = info.sortedBy || this.sortedBy;
        this.sortDirection = info.sortDirection || this.sortDirection;
    }
}