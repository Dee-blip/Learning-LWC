/* 
Created By : Tejaswini
Jira       : ESESP-6008
Purpose    : Component to associate a case to incident
Date       : 15-November-2021
*/
import { LightningElement,track,api} from 'lwc';
import { wire} from 'lwc';
import { loadStyle } from "lightning/platformResourceLoader";
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAllCaseRecs from '@salesforce/apex/SC_BigPanda_Case_Modal_Ctrl.getAllCaseRecs';
import createLogObjectRec from '@salesforce/apex/SC_BigPanda_Case_Modal_Ctrl.createLogObjectRec';
import getAccountIdFromLogObject from '@salesforce/apex/SC_BigPanda_Case_Modal_Ctrl.getAccountIdFromLogObject';
import getStatusOfLogRecord from '@salesforce/apex/SC_BigPanda_Case_Modal_Ctrl.getStatusOfLogRecord';

import cssStyleSheet from "@salesforce/resourceUrl/SC_BpShowCaseModal";

const caseColumns = 
[
    {
        label:'AKAM Case ID',
        fieldName:'caseUrl',
        type: 'url',
        typeAttributes: 
        { 
            label: { fieldName: 'akamCaseId'},
            tooltip: 'Go to Case', 
            target: '_blank'
        },
        wrapText: true,
        sortable : "true"
    },
    {
        label:'Policy Domain',
        fieldName:'pdUrl',
        type: 'url',
        typeAttributes: 
        { 
            label: { fieldName: 'policyDomain' },
            tooltip: 'Go to Policy DOmain', 
            target: '_blank'
        },
        wrapText: true,
        sortable : "true"
    },
    /*{
        label:'Subject',
        fieldName:'caseUrl',
        type: 'url',
        typeAttributes: 
        { 
            label: {fieldName: 'subject'},
            tooltip: 'Go to Case', 
            target: '_blank'
        },
        //wrapText: true,
        sortable : "true"
    },*/
    {
        label:'Subject',
        fieldName:'subject',
        type: 'text',
        //wrapText: true,
        sortable : "true"
    },
    {
        label: 'Problem',
        fieldName: 'problem',
        type: 'text',
        wrapText: true,
        sortable : "true"
    },
    {
        label: 'Severity',
        fieldName: 'severity',
        type: 'text',
        wrapText: true,
        sortable : "true"
    },
    
    {
        label:'ACCOUNT NAME',
        fieldName:'accountUrl',
        type: 'url',
        typeAttributes: 
        { 
            label: { fieldName: 'accountName' },
            tooltip: 'Go to Account', 
            target: '_blank'
        },
        wrapText: true,
        sortable : "true"
    },
    {
        label: 'Last Updated',
        fieldName: 'lastUpdated',
        type: 'Datetime',
        wrapText: true,
        sortable : "true"
    },
    {
        label: 'Last Updated By',
        fieldName: 'lastUpdatedBy',
        type: 'text',
        wrapText: true,
        sortable : "true"
    },
    {
        type: "button", 
        typeAttributes: 
        {  
            label: 'Associate',  
            name: 'Associate Case',  
            title: 'Associate Case',  
            disabled: false,  
            value: 'Associate Case',
            variant: "brand"
        },
        cellAttributes: { alignment: 'center' }
    },
    /*{
        type: 'button-icon',
        typeAttributes: {
            iconName: 'utility:link',
            name: 'Associate Case', 
            title: 'Associate Case',
            variant: 'container',
            alternativeText: 'Associate Case',
            disabled: false
        },
        initialWidth: 10
    }*/
     
];

const recordsPerPage = [15,25,50];

export default class ScBpShowCaseModal extends LightningElement {
    @track columns=caseColumns;
    @track recordid='F-AC-4907235';
    @track incidentId='618e4141c1cde551f56eb4a6';
    @track pageSize=15;
    @api pageSizeOptions = recordsPerPage; 
    @track selectedId = [];
    @track SlicedDatalistId=[];
    @track status;

    sortBy = 'akamCaseId';
    sortDirection = 'asc';

    records=[];
    totalCases=0;
    caseDataCopy = [];
    paginationNumbers;
    SlicedDatalist;
    currentpage;
    offset = 1;
    caseSearchText = '';
    accountId;
    currentPageReference = null; 
    urlStateParameters = null;
    urlTypeParameters = null;
 
    /* Params from Url */
    urlAccIdComma = null;
    urlAccId=null;
    urlIncidentId = null;
    caseSpinner = true;
    showTable=true;
    showFilters =true;
    showHeaderFooter = true;
    message = 'NO CASES TO DISPLAY';
    PollID;
    PollerId;
    logRecId;
    apiOperation;
    recStatus;
    akamCaseId;

    caseSeveritySelected = ['1', '2', '3', '4'];
    caseProblemSelected = "All";

    get caseSeverityVal() {
        return [
            { label: '1', value: '1' },
            { label: '2', value: '2' },
            { label: '3', value: '3' },
            { label: '4', value: '4' }
        ];
    }

    get caseProblemVal() {
        return [
            {label: 'All', value: 'All'},
            { label: 'Technicians', value: 'Technicians'},
            { label: 'Specialist', value: 'Specialist'},
            { label: 'S2ET', value: 'S2ET'},
            { label: 'NetOps', value: 'NetOps'}        
        ];
    }

    
    caseSevChange(event){
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

    caseProblemChange(event){
        this.caseProblemSelected = event.detail.value;
    }

    applyFilter() {
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
            this.showTable = true;
            this.caseSpinner = true;
            this.getAllCaseRecs();
            //this.searchCases();   
            //this.delayedSearch();         
        }
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
       if (currentPageReference) {
        this.urlTypeParameters = currentPageReference.type;
        console.log('the url state parameters: '+this.urlTypeParameters)
        this.urlStateParameters = currentPageReference.state;
        console.log('the url state parameters: '+this.urlStateParameters);
        this.setParametersBasedOnUrl();
       }
    }
 
    setParametersBasedOnUrl() {

       var accountIdVar = Object.prototype.hasOwnProperty.call(this.urlStateParameters, "c__accountId");
       var incidentIdVar = Object.prototype.hasOwnProperty.call(this.urlStateParameters, "c__incidentId");
       //if(!(this.urlStateParameters).hasOwnProperty('c__accountId') && !(this.urlStateParameters).hasOwnProperty('c__incidentId'))
       if(!accountIdVar && !incidentIdVar)
       {
        this.urlAccId = null;
        this.urlIncidentId = null;
       }
       else{
            
            /*this.urlAccIdComma = (this.urlStateParameters.c__accountId).replace(',','')|| null;
            console.log('the url account id comma is: '+this.urlAccIdComma);
            if(this.urlAccIdComma!=null)
            {
                this.urlAccId = (this.urlAccIdComma).substring(0,(this.urlAccIdComma).length-1);
            }
            else
                this.urlAccId=this.urlAccIdComma;*/

            console.log('The url account parameter is: '+this.urlStateParameters.c__accountId);
            const array= (this.urlStateParameters.c__accountId).split(',');
            console.log('the array: '+array);
            console.log('the array length is: '+array.length);
            if(array.length===1)
            {
                this.urlAccId = null;
            }
            if(array.length>1)
            {
                console.log('the array of data is: '+array[1]);
                this.urlAccId = array[1];
            }
            //this.urlAccId = (this.urlStateParameters.c__accountId).replace(',','') || null;
            this.urlIncidentId = (this.urlStateParameters.c__incidentId).replace(',','') || null;
       }
       
       console.log('the url account id is: '+this.urlAccId);
       console.log('the url incident id is: '+this.urlIncidentId);
    }

    connectedCallback() {
        console.log('Inside connected call back');
        console.log('the url account id is: '+this.urlAccId);
        console.log('the url incident id is: '+this.urlIncidentId);
        loadStyle(this, cssStyleSheet);

        if(this.urlAccId==null && this.urlIncidentId==null)
        {
            this.message='SOMETHING WENT WRONG, PLEASE RETRY THE REQUEST';
            this.caseSpinner=false;
            this.showTable = false;
            this.showFilters = false;
            this.showHeaderFooter = false;
        }

        else if(this.urlAccId!=null && this.urlIncidentId!=null)
        {
            this.getAllCaseRecs();
            //this.testFutureCallout();
            //should call future method too..and use pollers

        }
        else if(this.urlAccId==null && this.urlIncidentId!=null)
        {
           //call the poller and method
            console.log('test test test');
            this.apiOperation ='Get Incident';
            this.createLogObjectRec();
            console.log('the logobject record id is: '+this.logRecId);
            console.log('test test test 1');
            console.log('the value of apioperation variable in connectedCallback() is: '+this.apiOperation);
            /*if(this.apiOperation == 'Get Incident')
            {
                this.PollID = setInterval(() => {
                    console.log('test test test 2');
                    console.log('Polled Main');
                    this.getAccountIdFromLogObject();
            }, 10000);
            this.PollID=null;
            }*/
            
        }
       
    }

    createLogObjectRec()
    {
        //console.log('the method name: '+methodName);
        console.log('Inside createLogObjectRec method');
        console.log('the incident id is: '+this.urlIncidentId);
        console.log('the API operation is: '+this.apiOperation);
        createLogObjectRec({incidentId:this.urlIncidentId,operation:this.apiOperation,caseId:this.akamCaseId})
        .then( result=>{
            this.logRecId=result;
            this.error = undefined;
            console.log('the logobject record id inside createLogObjectRec() is: '+this.logRecId);

            if(this.apiOperation === 'Get Incident'){
                this.PollID = setInterval(() => {
                    console.log('Polled getAccountIdFromLogObject');
                    this.getAccountIdFromLogObject();
                    //methodName;
                }, 10000);
            }
            else if(this.apiOperation === 'Update Incident Tags')
            {
                this.PollerId = setInterval(() => {
                    console.log('Polled associateCaseToIncident');
                    this.getStatusOfLogRecord();
                }, 10000);
            }
        })
        .catch(error => {
            this.caseSpinner=false;
            this.error = error;
            this.records = undefined;
        });

    }

    getAccountIdFromLogObject()
    {
        console.log('Inside getAccountIdFromLogObject method');
        console.log('the logobject record id is: '+this.logRecId);
        getAccountIdFromLogObject /*getLogObjectRecord*/({recordId:this.logRecId})
        .then( result=>{

            /*let objResult = result;
            console.log('the objResult is: '+objResult);
            if(objResult.Response_Status_Code__c == 200 && objResult.Status__c=='Success')
            {
                let body= objResult.Response_Body__c;
                const results = new Map();
                results = JSON.deserializeUntyped(body);
                //Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(body);
                this.urlAccId = results.get('akam_account_id');
            }
            else if(objResult.Response_Status_Code__c != 200 ){
                this.urlAccId ='SOMETHING WENT WRONG, PLEASE RETRY THE REQUEST';
            }*/
            this.urlAccId=result;
            this.error = undefined;
            console.log('the account id inside getAccountIdFromLogObject() is '+this.urlAccId);
            if(this.urlAccId!=null)
            {
                console.log('inside if block');
                if(this.urlAccId ==='SOMETHING WENT WRONG, PLEASE RETRY THE REQUEST')
                {
                    this.message =this.urlAccId;
                    this.urlAccId ='';
                    this.showTable = false;
                    this.showHeaderFooter =false;
                    this.caseSpinner=false;
                    this.showFilters = false;
                }
                else{
                    this.getAllCaseRecs();
                }
                console.log('the message is: '+this.message);
                console.log('the urlAccId is: '+this.urlAccId);
               
                clearInterval(this.PollID);
            }
            
        })
        .catch(error => {
            this.caseSpinner=false;
            this.error = error;
            this.records = undefined;
        });

    }

    reset() {
        this.caseSeveritySelected = ["1", "2", "3", "4"];
        this.caseProblemSelected = "All";
        this.showTable = true;
        this.caseSpinner = true;
        this.getAllCaseRecs();
    }
    
    getAllCaseRecs()
    {
        //const cloneData=[];
        console.log('the account id is '+this.urlAccId);
        //console.log('the account id is '+this.accountId);
        //getAllCaseRecs({ akamAccountId: this.recordid })
        if(this.urlAccId ===''|| this.urlAccId ===null)
        {
            console.log('inside getAllCaseRecs() if block');
            this.message = 'NO CASES TO DISPLAY';
            this.showTable = false;
            //this.showFilters = false;
            this.caseSpinner=false;
        }
        else{
            console.log('inside getAllCaseRecs() else block');
            let sev = (this.caseSeveritySelected).toString();
            console.log('the severity is: '+sev);
            console.log('the problem is: '+this.caseProblemSelected);
            getAllCaseRecs({ akamAccountId: this.urlAccId , caseSeverity: sev, caseProblem: this.caseProblemSelected })
            .then(result => {
                this.records = result;
                this.error = undefined; 
                
                this.totalCases=this.records.length;
                if(this.totalCases<1)
                {
                    this.showTable = false;
                    //this.showFilters = false;
                }
                this.caseDataCopy=this.records;
                
                console.log('The caseDataCopy are'+this.caseDataCopy);
                /*const cloneData = [...this.caseDataCopy];
                cloneData.sort(this.sortBy(this.sortedBy, this.sortDirection === 'asc' ? 1 : -1));
                this.caseDataCopy=cloneData;*/
                this.sortData(this.sortBy, this.sortDirection);
                console.log('The 2nd caseDataCopy are'+this.caseDataCopy);
                this.calculatepaginationlogic();
                this.caseSpinner=false;
                console.log('the value of showTable is: '+this.showTable);
                if(this.caseSearchText!=='')
                {
                    this.searchCases();
                }
                
            })
            .catch(error => {
                this.caseSpinner=false;
                this.error = error;
                this.records = undefined;
            });
        }
        

    }
    disableEnableActions() {
        let buttons = this.template.querySelectorAll("lightning-button");
        console.log('the buttons : '+buttons);
        console.log('the offset is: '+this.offset);
        console.log('the paginationNumbers is: '+this.paginationNumbers);
        buttons.forEach(bun => {
            if (bun.label === "First") {
                bun.disabled = this.offset === 1 ? true : false;
            } else if (bun.label === "Previous") {
                bun.disabled = this.offset === 1 ? true : false;
            } else if (bun.label === "Next") {
                bun.disabled = this.offset === this.paginationNumbers ? true : false;
            } else if (bun.label === "Last") {
                bun.disabled = this.offset === this.paginationNumbers ? true : false;
            }
        });
    }

   calculatepaginationlogic()
    {
        var i ;
        console.log('Inside calculatepaginationlogic');       
        if(!this.pageSize)
            this.pageSize = this.totalCases;
        console.log('The pageSize are: '+this.pageSize);
        console.log('The totalCases are: '+this.totalCases);
        
        if(this.totalCases === 0)
        {
            this.paginationNumbers = 1;
            this.showTable = false;
        }
        else
        {
            this.paginationNumbers = Math.ceil(this.totalCases / this.pageSize);
        }
        if(this.offset>this.paginationNumbers) this.offset=1;
        this.currentpage=this.offset+'/'+this.paginationNumbers;
        this.paginationRange = [];
        for (i = 1; i <= this.paginationNumbers; i++) {
            this.paginationRange.push(i);
        }
        console.log('The paginationNumbers are: '+this.paginationNumbers);
        console.log('The offset are: '+this.offset);

        this.SlicedDatalist = this.caseDataCopy.slice((this.offset - 1) * this.pageSize, this.offset * this.pageSize);
        console.log('The SlicedDatalist are'+this.SlicedDatalist);
        
        this.disableEnableActions();

        const tempArrayId=[];
        this.SlicedDatalist.forEach(row =>{
            //this.SlicedDatalistId.push(row.Id);
            tempArrayId.push(row.Id);
        });
        this.SlicedDatalistId=[...tempArrayId];
        console.log('The SlicedDatalistId are'+this.SlicedDatalistId);

        const tempArray=[];
        this.SlicedDatalist.forEach(row => {
            if(this.selectedId.includes(row.Id))
            {
                tempArray.push(row.Id);
            }
        });

        this.selectedRows=[...tempArray];
        console.log('The rows are'+this.selectedRows);

    }

    handleClick(event) {
        let label = event.target.label;
        if (label === "First") {
            this.handleFirst();
        } else if (label === "Previous") {
            this.handlePrevious();
        } else if (label === "Next") {
            this.handleNext();
        } else if (label === "Last") {
            this.handleLast();
        }
    }

    handleFirst() {
        this.offset=1;
        this.calculatepaginationlogic();
    }

    handlePrevious() {
        this.offset -= 1;
        this.calculatepaginationlogic();
    }

    handleNext() {
        this.offset += 1;
        this.calculatepaginationlogic();
    }

    handleLast() {
        this.offset=this.paginationNumbers;
        this.calculatepaginationlogic();
    }

    associateCaseToIncident(event){

        console.log('we are on row selection');
        const dataRow = event.detail.row;
        console.log('the dataRow');
        console.log(dataRow);
        this.caseSpinner = true;
        /*const rowId=event.detail.row.akamCaseId;
        console.log('the row id is');
        console.log(rowId);*/

        this.akamCaseId=event.detail.row.akamCaseId;
        console.log('the row id is');
        console.log(this.akamCaseId);

        this.apiOperation ='Update Incident Tags';
        this.logRecId = null;
        this.createLogObjectRec();
        console.log('the logobject record id for Update Incident Tags is: '+this.logRecId);
        console.log('the value of apioperation variable in associateCaseToIncident() is: '+this.apiOperation);
    }

    getStatusOfLogRecord()
    {
        console.log('Inside getStatusOfLogRecord method');
        console.log('the logobject record id is: '+this.logRecId);
        getStatusOfLogRecord({recordId:this.logRecId/*,caseId:this.akamCaseId,incidentId:this.urlIncidentId*/})
        .then( result=>{
            this.recStatus=result;
            this.error = undefined;
            console.log('the log record status is: '+this.recStatus);
            
            if(this.recStatus!=null)
            {
                if(this.recStatus==='Success')
                {
                    this.notifyUser('Success !', 'The case: '+this.akamCaseId+ ' got associated to incident: '+this.urlIncidentId+'!!', 'success','dismissable');
                    this.clearSelections();
                    this.caseSpinner = false;
                    console.log('the value of case spinner is: '+this.caseSpinner);
                }
                else if(this.recStatus==='Failed')
                {
                    this.notifyUser('Error !', 'Something went wrong, Please retry the request', 'error','dismissable');
                    this.caseSpinner = false;
                }
                clearInterval(this.PollerId);
            }
            
        })
        .catch(error => {
            this.caseSpinner=false;
            this.error = error;
            this.records = undefined;
        });

    }
    
    notifyUser(title, message, variant,mode) {
        const toastEvent = new ShowToastEvent({ title, message, variant,mode });
        this.dispatchEvent(toastEvent);
    }

    clearSelections(){
        this.template.querySelector('lightning-datatable').selectedRows=[];
        this.selectedId=[];
    }

    delayedSearch() 
    {
        clearTimeout(this.timeoutId); 
        this.caseSpinner = true;
        this.showTable = true;
        this.timeoutId = setTimeout(this.searchCases.bind(this), 500); 
    }

    searchCases()
    {
        //this.sortDirection='asc';
        let allCaseData = this.records;
        let searchFilter = this.template.querySelector('.labelHidden').value;
        this.caseSearchText = searchFilter;
        searchFilter = searchFilter.toUpperCase();
        console.log('the search text is:  '+searchFilter);

        //search the dashboard
        let tempArray = [];
        allCaseData.forEach(function(eachRow)
        {
            //console.log(eachRow[i].subject);
            if((eachRow.akamCaseId && eachRow.akamCaseId.toUpperCase().indexOf(searchFilter) !== -1)
            || (eachRow.policyDomain && eachRow.policyDomain.toUpperCase().indexOf(searchFilter) !== -1)
            || (eachRow.subject && eachRow.subject.toUpperCase().indexOf(searchFilter) !== -1)
            || (eachRow.problem && eachRow.problem.toUpperCase().indexOf(searchFilter) !== -1)
            || (eachRow.severity && eachRow.severity.toUpperCase().indexOf(searchFilter) !== -1)
            || (eachRow.lastUpdatedBy && eachRow.lastUpdatedBy.toUpperCase().indexOf(searchFilter) !== -1)
            || (eachRow.accountName && eachRow.accountName.toUpperCase().indexOf(searchFilter) !== -1)            
            )
            {
                tempArray.push(eachRow);
            }
        });
        
        this.caseDataCopy = tempArray;
        this.totalCases = tempArray.length;

        //this.records=tempArray;
        this.totalCases = this.caseDataCopy.length;
        
        this.calculatepaginationlogic();
        //this.sortData('akamCaseId','asc');        
        console.log('the sortby data is: '+this.sortBy);
        console.log('the sort direction data is: '+this.sortDirection);
        this.sortData(this.sortBy, this.sortDirection);

        if(searchFilter === '') {
            console.log('the sortby is: '+this.sortBy);
            console.log('the sort direction is: '+this.sortDirection);
            this.sortData(this.sortBy, this.sortDirection);
        }
        this.caseSpinner = false;
    }

    updateColumnSorting(event) {
        var fieldName = event.detail.fieldName;
        var sortDirection = event.detail.sortDirection;
        this.sortBy = fieldName;
        this.sortDirection = sortDirection;
        this.sortData(fieldName, sortDirection);

    }

    sortData(fieldname, direction) {
        console.log('In Sort : ' + fieldname + ' ' + direction);
        if(fieldname==='caseUrl')
            fieldname='akamCaseId';
        else if(fieldname==='pdUrl')
            fieldname='policyDomain';
        else if(fieldname==='accountUrl')
            fieldname='accountName'; 

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
        this.totalCases=this.caseDataCopy.length;
        this.calculatepaginationlogic();
    }

    handleRecordsPerPage(event){
        this.pageSize = event.target.value;
        this.calculatepaginationlogic();
        
    }
    clearSearchInput(){
        //let searchFilter = this.template.querySelector('.labelHidden').value;
        this.showTable = true;
        /*if(searchFilter != '')
        {
            this.template.querySelector('.labelHidden').value = '';
            this.caseSpinner = true;
            this.getAllCaseRecs();
        }
        else if(searchFilter ==''){
            this.template.querySelector('.labelHidden').value = '';
            this.caseSpinner = true;
            this.getAllCaseRecs();
        }*/
        this.template.querySelector('.labelHidden').value = '';
        this.caseSpinner = true;
        this.getAllCaseRecs();
        
    }

}