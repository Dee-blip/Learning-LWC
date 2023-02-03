/** @Date		:	June 20 2020
* @Author		: 	Sumukh SS 
* @Description	:	Re-write of Akatec all queue cases in LWC
*/

import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import { loadStyle } from 'lightning/platformResourceLoader';
import resourceName from '@salesforce/resourceUrl/SC_Akatec_LightningMigration';

import applyFilters from '@salesforce/apex/SC_Akatec_Lightning_Homepage_v2.getMyFilteredEscalations';
import {
    subscribe,
    unsubscribe,
    APPLICATION_SCOPE,
    MessageContext
} from 'lightning/messageService';
import refreshtype from '@salesforce/messageChannel/akatechome__c';

//import { getObjectInfo } from 'lightning/uiObjectInfoApi';
//import ESC_OBJECT from '@salesforce/schema/Engagement_Request__c';

import { ESC_COLS } from './sC_Akatec_Homepage_MyopenEscalations_Const';
import {getColumnsState, getSortByColumn, storeColumnState, storeSortByColumn} from "c/scStoreDatatableState";

export default class SC_Akatec_Homepage_MyopenEsc extends NavigationMixin(LightningElement) {

    columns = ESC_COLS;
    data;
    showspinner = true;
    TotalCount = 0;
    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    sortedBy = 'Age';
    queryTerm;
    displayCase = true;
    AllDataforstorage;
    showExternalTeamModal = false;
    caserecid = '';

    /* objectInfo
     @wire(getObjectInfo, { objectApiName: ESC_OBJECT })
     objectInfo;*/

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
        let view = message.refreshtype;
        if (view === 'myopenesc')
            this.applyFilters();
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

        if (e.detail.value.length < 1) {
            this.showToast('error', 'An Empty Table? You need to select atleast 1 severity!');
        }
        else
            this.severityvalue = e.detail.value;

    }

    get geooptions() {
        return [
            { label: 'NORTHAM', value: 'NORTHAM' },
            { label: 'APJ', value: 'APJ' },
            { label: 'EMEA', value: 'EMEA' },
            { label: 'LATAM', value: 'LATAM' }

        ];
    }

    geovalue = ['NORTHAM', 'EMEA', 'APJ', 'LATAM'];

    handlegeoChange(e) {

        if (e.detail.value.length < 1) {
            this.showToast('error', 'Oops!', 'An Empty Table? You need to select atleast 1 geography!');
        }
        else
            this.geovalue = e.detail.value
    }

    get statusoptions() {
        return [
            { label: 'Accepted', value: 'Accepted' },
            { label: 'Pending', value: 'Pending' },
            { label: 'Reopened', value: 'Reopened' }
        ];
    }

    statusvalue = ['Accepted', 'Pending', 'Reopened'];

    handlestatusChange(e) {

        if (e.detail.value.length < 1) {
            this.showToast('error', 'An Empty Table? You need to select atleast 1 status!');
        }
        else
            this.statusvalue = e.detail.value;

    }


    MyOpenEscColvalue = ['2', '3', '4', '5', '6', '7', '8', '9', '10', '11'];

    get MyOpenEscColOptions() {
        return [
            { label: 'Description', value: '2' },
            { label: 'Status', value: '3' },
            { label: 'Support Level', value: '4' },
            { label: 'Geography', value: '5' },
            { label: 'Severity', value: '6' },
            { label: 'Age', value: '7' },
            { label: 'Area', value: '8' },
            { label: 'AKAM Case ID', value: '9' },
            { label: 'Case Owner', value: '10' },
            { label: 'Case Status', value: '11' }

        ];
    }

    handleMyEscColChange(e) {

        if (e.detail.value.length > 0) {

            this.MyOpenEscColvalue = e.detail.value;

            var allCols = ESC_COLS
            var newcols = [allCols[0]];
            newcols.push(allCols[1]);
            for (var i = 0; i < e.detail.value.length; i++) {
                var index = e.detail.value[i];
                newcols = [...newcols, allCols[index]];
            }
            newcols.push(allCols[12]);

            this.columns = newcols;

            this.saveOpenEscColSelection();
        }
        else {
            this.showToast('error', 'Hide everything? Please select atleast 1 column to display!');
        }
    }


    connectedCallback() {
        loadStyle(this, resourceName + '/SC_Akatec_Lightning_Resource/SC_Akatec_Homepage.css')
        this.subscribeToMessageChannel();
        this.initializeSorting();

        //getting saved column selection from cookies
        this.getopenEscCookie('myOpenEscCol');
        if (typeof this.myopenesccookieval !== 'undefined') {
            this.myopenesccookieval = this.myopenesccookieval.split(',');

            this.MyOpenEscColvalue = this.myopenesccookieval;

            var allCols = ESC_COLS
            var newcols = [allCols[0]];
            newcols.push(allCols[1]);
            for (var i = 0; i < this.MyOpenEscColvalue.length; i++) {
                var index = this.MyOpenEscColvalue[i];
                newcols = [...newcols, allCols[index]];
            }
            newcols.push(allCols[12]);

            this.columns = newcols;

        }
        //Getting data from server
        this.applyFilters();
    }

    handleEscKeyUp(evt) {
        this.queryTerm = evt.target.value;
        clearTimeout(this.timeoutId);
        this.timeoutId = setTimeout(this.searchOpenEsctable.bind(this), 500);
    }

    searchOpenEsctable() {
        var searchstring = this.queryTerm.toUpperCase();
        var allRecords = this.AllDataforstorage;
        var tempArray = [];
        for (var i = 0; i < allRecords.length; i++) {
            if ((allRecords[i].akam_esc_id && allRecords[i].akam_esc_id.toUpperCase().indexOf(searchstring) != -1) ||
                (allRecords[i].account && allRecords[i].account.toUpperCase().indexOf(searchstring) != -1) ||
                (allRecords[i].geography && allRecords[i].geography.toUpperCase().indexOf(searchstring) != -1) ||
                (allRecords[i].support_level && allRecords[i].support_level.toUpperCase().indexOf(searchstring) != -1) ||
                (allRecords[i].akam_case_id && allRecords[i].akam_case_id.toUpperCase().indexOf(searchstring) != -1) ||
                (allRecords[i].case_owner && allRecords[i].case_owner.toUpperCase().indexOf(searchstring) != -1)
            ) {
                tempArray.push(allRecords[i]);
            }
        }
        this.data = tempArray;
        this.TotalCount = tempArray.length;

    }

    hideOpenEscTable() {
        var x = this.template.querySelector(".panelOpenEsc");
        x.style.height = "0vh";
        this.displayCase = !this.displayCase;
    }

    showOpenEscTable() {
        let x = this.template.querySelector(".panelOpenEsc");
        if (this.TotalCount <= 7)
            x.style.height = "35vh";
        else
            x.style.height = "50vh";
        this.displayCase = !this.displayCase;
    }


    applyFilters() {
        this.showspinner = true;
        applyFilters({
            SelSeverity: this.severityvalue,
            selGeos: this.geovalue,
            selStatus: this.statusvalue
        })
            .then(result => {
                this.MyOpenEscnow = Date.now();
                this.showspinner = false;
                this.AllDataforstorage = result;
                this.TotalCount = result.length;
                if (this.displayCase) {
                    let x = this.template.querySelector(".panelOpenEsc");
                    if (this.TotalCount <= 7)
                        x.style.height = "35vh";
                    else
                        x.style.height = "50vh";
                }
                if (this.queryTerm) {
                    this.searchOpenEsctable();
                    this.onHandleSort();
                }
                else {

                    if (this.sortedBy != 'Age') {
                        this.onHandleSort();
                    }
                    else {
                        this.data = result;
                    }
                }

            }).catch(error => {
                this.showspinner = false;

                console.log(JSON.stringify(error));
            });

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

    handleEscRowActions(event) {
        let actionName = event.detail.action.name;
        let caseid = event.detail.row.caseURL.substring(1);
        let recordid = event.detail.row.escURL.substring(1);
        if (actionName === 'add_loe') {
            const defaultValues = encodeDefaultFieldValues({
                WhatId: caseid,
                RecordTypeId: '012G0000000z117IAA'
            });

            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: 'Task',
                    actionName: 'new'
                },
                state: {
                    defaultFieldValues: defaultValues
                }
            });

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

        if (actionName === 'new_ext_team') {
            this.showExternalTeamModal = true;
            this.caserecid = caseid;

        }
    }

    closeExternalTeamModal() { this.showExternalTeamModal = false; }

    //Cookie related 

    saveOpenEscColSelection() {
        var columnschoosen = this.MyOpenEscColvalue;
        this.createOpenEscCookie('myOpenEscCol', columnschoosen, 3650);
    }

    createOpenEscCookie(name, value, days) {
        var expires;
        if (days) {
            const date = new Date();
            date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000));
            expires = "; expires=" + date.toGMTString();
        }
        else {
            expires = "";
        }
        // console.log(value);
        document.cookie = name + "=" + value + expires + "; path=/";
    }

    myopenesccookieval;
    getopenEscCookie(name) {
        var cookieString = "; " + document.cookie;
        var parts = cookieString.split("; " + name + "=");
        if (parts.length === 2) {
            this.myopenesccookieval = parts.pop().split(";").shift();
        }
        //console.log(this.cookieval);
    }


    showToast(type, msg) {
        const event = new ShowToastEvent({
            "title": "Oops!",
            "message": msg,
            "variant": type,
            "mode": "dismissable"

        });
        this.dispatchEvent(event);

    }

    /* get recordTypeId() {
         // Returns a map of record type Ids 
         const rtis = this.objectInfo.data.recordTypeInfos;
         return Object.keys(rtis).find(rti => rtis[rti].name === 'External Team');
     }*/

    tableName = 'datatable_sc_akatec_homepage_myopenescalations';
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