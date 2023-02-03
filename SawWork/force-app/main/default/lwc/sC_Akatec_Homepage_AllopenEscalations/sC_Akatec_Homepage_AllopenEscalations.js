/** @Date		:	June 20 2020
* @Author		: 	Sumukh SS 
* @Description	:	Re-write of Akatec all queue cases in LWC
*/

import { LightningElement, wire } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import resourceName from '@salesforce/resourceUrl/SC_Akatec_LightningMigration';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import getAllEscData from '@salesforce/apex/SC_Akatec_Lightning_Homepage_v2.getAllEscalations';
import getonLoadData from '@salesforce/apex/SC_Akatec_Lightning_Homepage_v2.getSavedQueues';
import acceptesctouser from '@salesforce/apex/SC_Akatec_Lightning_Homepage_v2.assignEscalationToUser';
import savequeuesel from '@salesforce/apex/SC_Akatec_Lightning_Homepage_v2.saveEscFilters';

import { ESC_COLS } from './sC_Akatec_Homepage_AllopenEscalations_Const';
import { QUEUE_COLS } from './sC_Akatec_Homepage_AllopenEscalations_Const';

import {
    publish,
    subscribe,
    unsubscribe,
    APPLICATION_SCOPE,
    MessageContext
} from 'lightning/messageService';
import refreshtype from '@salesforce/messageChannel/akatechome__c';
import {getColumnsState, getSortByColumn, storeColumnState, storeSortByColumn} from "c/scStoreDatatableState";

export default class sC_Akatec_Homepage_AllopenEscalations extends NavigationMixin(LightningElement) {

    columns = ESC_COLS;
    data;
    error;
    PollID;
    now;
    displayCase = true;
    TotalCount = 0;
    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    sortedBy = 'Age';
    queryTerm;
    AllDataforstorage;
    showallopenescspinner=false;

    queuecolumns = QUEUE_COLS;
    queuedata;
    QueuesortDirection = 'asc';
    QueuesortedBy = 'queueName';

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

    handleMessage(message) {
        // console.log(message);
    }

    AllEscColvalue = ['2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'];

    get AllEscColOptions() {
        return [
            { label: 'Description', value: '2' },
            { label: 'Support Level', value: '3' },
            { label: 'Geography', value: '4' },
            { label: 'Severity', value: '5' },
            { label: 'SLA', value: '6' },
            { label: 'Target Shift', value: '7' },
            { label: 'Area', value: '8' },
            { label: 'Case Product', value: '9' },
            { label: 'AKAM Case ID', value: '10' },
            { label: 'Case Owner', value: '11' },
            { label: 'Esc Queue', value: '12' }

        ];
    }

    handleAllEscKeyUp(evt) {
        this.queryTerm = evt.target.value;
        clearTimeout(this.timeoutId);
        this.timeoutId = setTimeout(this.searchtable.bind(this), 500);
    }

    searchtable() {
        var searchFilter = this.queryTerm.toUpperCase();
        var allRecords = this.AllDataforstorage;
        var tempArray = [];

        for (var i = 0; i < allRecords.length; i++) {
            if ((allRecords[i].akam_esc_id && allRecords[i].akam_esc_id.toUpperCase().indexOf(searchFilter) != -1) ||
                (allRecords[i].account && allRecords[i].account.toUpperCase().indexOf(searchFilter) != -1) ||
                (allRecords[i].description && allRecords[i].description.toUpperCase().indexOf(searchFilter) != -1) ||
                (allRecords[i].geography && allRecords[i].geography.toUpperCase().indexOf(searchFilter) != -1) ||
                (allRecords[i].support_level && allRecords[i].support_level.toUpperCase().indexOf(searchFilter) != -1) ||
                (allRecords[i].akam_case_id && allRecords[i].akam_case_id.toUpperCase().indexOf(searchFilter) != -1) ||
                (allRecords[i].case_owner && allRecords[i].case_owner.toUpperCase().indexOf(searchFilter) != -1) ||
                (allRecords[i].targetshift && allRecords[i].targetshift.toUpperCase().indexOf(searchFilter) != -1) ||
                (allRecords[i].esc_owner && allRecords[i].esc_owner.toUpperCase().indexOf(searchFilter) != -1) ||
                (allRecords[i].product && allRecords[i].product.toUpperCase().indexOf(searchFilter) != -1)
            ) {
                tempArray.push(allRecords[i]);
            }
        }
        this.data = tempArray;
        this.TotalCount = tempArray.length;
    }

    hideEscTable() {
        var x = this.template.querySelector(".panelEscinQueue");
        x.style.height = "0vh";
        this.displayCase = !this.displayCase;
    }

    showEscTable() {
        let x = this.template.querySelector(".panelEscinQueue");
        if (this.TotalCount <= 7)
            x.style.height = "35vh";
        else
            x.style.height = "50vh";
        this.displayCase = !this.displayCase;
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


    connectedCallback() {
        this.showallopenescspinner=true;

        loadStyle(this, resourceName + '/SC_Akatec_Lightning_Resource/SC_Akatec_Homepage.css');
        this.subscribeToMessageChannel();
        this.initializeSorting();

        //getting saved column selection from cookies

        this.getallEscCookie('allEscCol');
        if (typeof this.allopenesccookieval !== 'undefined') {
            this.allopenesccookieval = this.allopenesccookieval.split(',');
            this.AllEscColvalue = this.allopenesccookieval;

            var allCols = ESC_COLS
            var newcols = [allCols[0]];
            newcols.push(allCols[1]);
            for (var i = 0; i < this.AllEscColvalue.length; i++) {
                var index = this.AllEscColvalue[i];
                newcols = [...newcols, allCols[index]];
            }
            newcols.push(allCols[13]);
            this.columns = newcols;

        }

        getonLoadData({})
            .then(result => {
                this.showallopenescspinner=false;
                this.queuedata = result.escqueue_List;

                if (typeof result.savedQueues !== 'undefined') {
                    this.selectedQueues = result.savedQueues;

                    this.LoadData();
                    this.PollID = setInterval(() => {
                        this.LoadData();
                    }, 300000);

                }
                else {
                    this.showToast('Hey there!', 'warning', 'Please choose atleast 1 escalation queue to view unassigned Escalations!');

                }

            }).catch(error => {
                console.log(JSON.stringify(error));
            });

    }

    disconnectedCallback() {
        window.clearInterval(this.PollID);
        this.unsubscribeToMessageChannel();
    }

    LoadData() {
        getAllEscData({
        })
            .then(result => {
                this.now = Date.now();
                this.AllDataforstorage = result;
                this.TotalCount = result.length;

                let x = this.template.querySelector(".panelEscinQueue");
                if (this.displayCase) {
                    if (this.TotalCount <= 7)
                        x.style.height = "35vh";
                    else
                        x.style.height = "50vh";
                }

                if (this.queryTerm) {
                    this.searchtable();
                    this.onHandleSort();
                }
                else {
                    if (this.sortedBy !== 'Age') {
                        this.onHandleSort();
                    }
                    else{
                        this.data = result;
                    }
                }

            }).catch(error => {
                console.log(JSON.stringify(error));
            });
    }

    saveescFilters() {
        this.showallopenescspinner=true;
        savequeuesel({
            SelectedQueuesFromUser: this.selectedQueues
        }).then(result => {
            this.showallopenescspinner=false;

            this.showToast('Saved!', 'success', 'Queue selection saved!');
            this.LoadData();

        }).catch(error => {
            console.log(JSON.stringify(error));
        });

    }

    choosenesc;
    handleRowActions(event) {
        this.choosenesc = event.detail.row.escURL.substring(1);
        const actionName = event.detail.action.name;
        let recordid = event.detail.row.escURL.substring(1);

        if (actionName === 'accept') {
            let modal = this.template.querySelector('[data-id="' + 'accept-esc' + '"');
            if (modal) {
                modal.classList.remove('slds-hide');
                modal.toggle();
            }
        }

        if (actionName === 'OpenEscURL') {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: recordid,
                    objectApiName: 'Engagement_Request__c',
                    actionName: 'view'
                },
            });

        }

    }

    acceptesc() {
        let modal = this.template.querySelector('[data-id="' + 'accept-esc' + '"');
        if (modal) {
            modal.toggle();
        }
        this.showallopenescspinner=true;
        acceptesctouser({
            techID: this.choosenesc
        }).then(result => {
            this.showallopenescspinner=false;
            if(result==='success'){
            var payload = { refreshtype: 'myopenesc' };
            publish(this.messageContext, refreshtype, payload);
            this.showToast('Accepted!', 'success', 'Escalation accepted! Refreshing data..');
            this.LoadData();
            }
            else
            {
                this.showToast('Oops!', 'error', result);
            }
        }).catch(error => {
            this.showallopenescspinner=false;
            console.log(JSON.stringify(error));
        });
    }

    handleAllEscColChange(e) {
        if (e.detail.value.length > 0) {

            this.AllEscColvalue = e.detail.value;

            var allCols = ESC_COLS
            var newcols = [allCols[0]];
            newcols.push(allCols[1]);
            for (var i = 0; i < e.detail.value.length; i++) {
                var index = e.detail.value[i];
                newcols = [...newcols, allCols[index]];
            }
            newcols.push(allCols[13]);

            this.columns = newcols;

            this.saveAllEscColSelection();

        }
        else {
            this.showToast('Hide everything?', 'error', 'Please select atleast 1 column to display!');
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

        if (sortedBy === 'escURL') { sortedBy = 'akam_esc_id'; }
        if (sortedBy === 'caseURL') { sortedBy = 'akam_case_id'; }

        if (this.queryTerm) {
            const cloneData = [...this.data];
            cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
            this.data = cloneData;

        }

        else {
            const cloneData = [...this.AllDataforstorage];
            cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
            this.data = cloneData;

        }


    }

    onHandleQueueSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;

        const cloneData = [...this.queuedata];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.queuedata = cloneData;
        this.QueuesortDirection = sortDirection;
        this.QueuesortedBy = sortedBy;

    }

    openNewEsc() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Engagement_Request__c',
                actionName: 'new'
            }
            ,
            state: {
                useRecordTypeCheck: true,
            }
        });
    }


    saveAllEscColSelection() {
        var columnschoosen = this.AllEscColvalue;
        this.createAllEscCookie('allEscCol', columnschoosen, 3650);
    }

    createAllEscCookie(name, value, days) {
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

    allopenesccookieval;
    getallEscCookie(name) {
        var cookieString = "; " + document.cookie;
        var parts = cookieString.split("; " + name + "=");
        if (parts.length === 2) {
            this.allopenesccookieval = parts.pop().split(";").shift();
        }
        //console.log(this.cookieval);
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


    tableName = 'datatable_sc_akatec_homepage_allopenescalations';
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
        console.log('transformedColumns called');
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