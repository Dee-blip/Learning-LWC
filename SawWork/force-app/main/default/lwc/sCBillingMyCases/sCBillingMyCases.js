//Importing the Lightning element, track, api and navigation elements
import { LightningElement, track,api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

//Importing all the class methods
import getCases from '@salesforce/apex/SC_BillingLightningUtility.getCases';
import assignCaseToUser from '@salesforce/apex/SC_BillingLightningUtility.assignCaseToUser';
import getSummary from '@salesforce/apex/SC_BillingLightningUtility.getSummary';
import getNotificationDetails from '@salesforce/apex/SC_BillingLightningUtility.getNotificationDetails';
import updateCases from '@salesforce/apex/SC_BillingLightningUtility.updateCases';
import getRecordTypes from '@salesforce/apex/SC_BillingLightningUtility.getRecordTypes';
import getExternalDependancyList from '@salesforce/apex/SC_BillingLightningUtility.getExternalDependancyList';

//Import toast
import { ShowToastEvent } from "lightning/platformShowToastEvent";

//Import the platform event
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';

//import the static resource
import { loadStyle } from 'lightning/platformResourceLoader';
import staticStyleSheet from "@salesforce/resourceUrl/SC_Billing_Styesheet";


//Columns for the My Case view
const myCaseColumns = [
    {
        label: 'Id',
        fieldName: 'caseUrl',
        sortable: true,
        type: 'url',    
        initialWidth: 120,
        typeAttributes: { label: { fieldName: 'akamCaseId' }, target: '_self',tooltip : 'Go to Case' },
        cellAttributes: { alignment: 'left' }
    }
    ,
    {
        label: 'Account',
        fieldName: 'accountUrl',
        sortable: true,
        initialWidth: 170,
        type: 'url', 
        typeAttributes: { label: { fieldName: 'accountName' }, target: '_self',tooltip : 'Go to Account' },
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Subject',
        fieldName: 'subjectUrl',
        sortable: true,    
        type: 'url', 
        typeAttributes: { label: { fieldName: 'subject' }, target: '_self' ,tooltip : 'Go to Case'},
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Status',
        fieldName: 'status', 
        sortable: true,
        initialWidth: 90,
        type: 'text',
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Age',
        fieldName: 'age',
        sortable: true,
        initialWidth: 80,
        type: 'number',
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Origin',
        fieldName: 'origin', 
        sortable: true,
        initialWidth: 120,
        type: 'text',
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Service',
        fieldName: 'service', 
        sortable: true,
        initialWidth: 120,
        type: 'text',
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Request Type',
        fieldName: 'requestType', 
        sortable: true,
        initialWidth: 120,
        type: 'text',
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Initial Response SLA',
        fieldName: 'initialResponseSla',
        sortable: true,
        initialWidth: 120,
        type: 'text',
        cellAttributes: { class: {fieldName : 'initialResponseClass'} , alignment: 'center'}
    },
    {
        label: 'Resolution SLA',
        fieldName: 'resolutionSla',
        sortable: true,
        initialWidth: 140,
        type: 'text',
        cellAttributes: { class: {fieldName : 'resolutionClass'} , alignment: 'center'}
    },
    {
        label: 'External Dependencies',
        fieldName: 'externalDependancies',
        sortable: true,
        initialWidth: 120,
        cellAttributes: { alignment: 'center' , text_decoration: 'underline' } ,
        type: 'button',
        typeAttributes:
        {
            label: { fieldName: 'externalDependancies' },
            variant: 'base',
            name: 'externalDependancies'
        }
    }
];

//Columns for All cases view
const allCaseColumns = [   
   {    
        label: 'Id',
        fieldName: 'caseUrl',
        sortable: true,
        type: 'url', 
        initialWidth: 130,
        typeAttributes: { label: { fieldName: 'akamCaseId' }, target: '_self',tooltip : 'Go to Case' },
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Account',
        fieldName: 'accountUrl',
        sortable: true,
        type: 'url', 
        initialWidth: 240,
        typeAttributes: { label: { fieldName: 'accountName' }, target: '_self',tooltip : 'Go to Account' },
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Subject',
        fieldName: 'subjectUrl',
        sortable: true,
        type: 'url', 
        initialWidth: 440,
        typeAttributes: { label: { fieldName: 'subject' }, target: '_self',tooltip : 'Go to Case' },
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Contact Name',
        fieldName: 'contactName', 
        sortable: true,
        type: 'text',
        initialWidth: 260,
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Age',
        fieldName: 'age',
        sortable: true,
        type: 'number',
        initialWidth: 80,
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Created Date',
        fieldName: 'createdDate', 
        sortable: true,
        type: 'date',
        cellAttributes: { alignment: 'left' },
        typeAttributes: {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
            hour12: true
        }
    }
];

//Columns for the External Dependency View
const externalDependancyColumns = [
    {    
        label: 'Name',
        fieldName: 'url',
        type: 'url', 
        initialWidth: 130,
        typeAttributes: { label: { fieldName: 'name' }, target: '_self' ,tooltip : 'Go to External Dependency'},
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Case',
        fieldName: 'caseUrl',
        sortable: true,
        type: 'url', 
        initialWidth: 120,
        typeAttributes: { label: { fieldName: 'akamCaseId' }, target: '_self',tooltip : 'Go to Case' },
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Id',
        fieldName: 'typeId', 
        sortable: true,
        type: 'text',
        initialWidth: 150,
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Type',
        fieldName: 'type', 
        sortable: true,
        type: 'text',
        initialWidth: 260,
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Comments',
        fieldName: 'comments',
        sortable: true,
        type: 'text',
        initialWidth: 315,
        cellAttributes: { alignment: 'left' }
    }
];

//All the case columns for My Cases
const myCaseOptions = [
    { label: 'All', value: 'all' },
    { label: 'Id', value: 'akamCaseId' },
    { label: 'Account', value: 'accountName' },
    { label: 'Subject', value: 'subject' },
    { label: 'Status', value: 'status' },
    { label: 'Age', value: 'age' },
    { label: 'Origin', value: 'Origin' },
    { label: 'IR SLA', value: 'initialResponseSla' },
    { label: 'Res SLA', value: 'resolutionSla' }
];

//All the case columns for All Cases
const allCaseOptions = [
    { label: 'All', value: 'all' },
    { label: 'Id', value: 'akamCaseId' },
    { label: 'Account', value: 'accountName' },
    { label: 'Subject', value: 'subject' },
    { label: 'Contact', value: 'contactName' },
    { label: 'Age', value: 'age' },
    { label: 'Created Date', value: 'createdDate' }
];

//The date filters
const dateFilters = [
    { label: 'This Month', value: 'Month' },
    { label: 'This Quarter', value: 'Quarter' },
    { label: 'This Year', value: 'Year' },
];

export default class SCBillingMyCases extends NavigationMixin(LightningElement) {    

    //Columns
    @track columns;
    //Case records
    @track cases;
    //Searched cases
    @track searchedCases = [];
    //For lazy loading
    @track enableLoading = true;
    @track offset = 1;
    @track sortSearchConfirm = false;
    @track sortSearchOperation;
    //Stores the laoded data based on the offset
    @track pageData = [];
    //Search text
    @track caseSearchText = '';
    //Column filter
    @track columnToSearch = 'all';
    //Title of the Table
    @track tableTitle;
    //options based on the view
    @track options;
    //all date filter options for Summary
    @track dateFiltersOptions = dateFilters;
    //Modal title based on diff actions
    @track modalTitle;
    //Toggle Value depends on current view
    @track toggleValue = true;
    //from refresh for spinner
    @track fromRefresh = false;
    //Modal visiblity
    @track isModalOpen = false;
    //Confirm modal for Assign
    @track confirmModal = true;
    //Modal for Updates
    @track editForm = false;
    //Button Action label
    @track actionLabel = 'Assign!'

    //Load the spinner
    @track loadSpinner = false;
    //Spinner for Summary
    @track loadHeaderSpinner = false;
    //External Dependency columns
    @track edColumns = externalDependancyColumns;
    //Ed records
    @track externalDependancies;
    //Default modal class
    @track modalClass = 'slds-modal__container';
    //set of cases to be assigned
    caseToBeAssigned = '';

    //Billing record type
    @track billingRecordTypeId = '';

    //Sorting variables
    @track defaultSortDirection = 'asc';
    @track sortDirection = 'asc';
    @track sortedBy='age';

    //Number of cases
    @track casesSize;
    //table height
    @track tableHeight = 'tableHeight';
    
    //Poller Id
    pollerId = '';
    //for recursive platform event check
    platformEventFired = false;
    //visibility handler
    visibilityHandler = '';
    
    //to check for console tab change event
    initialPageLoad = true;

    //selected case ids
    @track selectedAkamCaseId;
    //selected rows
    @track selectedRows = [];

    // //current page
    // @track page = 1;
    //Limits record per page
    perpage = 30;
    // //Pages array
    // @track pages = [];
    // //Number of pages visible
    // set_size = 5;    

    //For the platform event
    channelName = '/event/Billing_Cases__e';
    //subscribe
    subscription= '';

    //Summary dashboard variables
    @track iQCount = 0;
    @track iQ24Count = 0;
    @track openCount = 0;
    @track iRCount = 0;
    @track resCount = 0;
    @track closedCount = 0;
    @track summaryFilter = 'Month'
    
    //To not start the main table spinner
    noHeaderSpinner = false;

    //For the Notification panel
    notificationlist = [];
    notificationCenterHeader = "";

    //selected case ids
    selectedCaseIds=[];
    
    //For the Console tab change event. fired from parent aura
    @api 
    get tabFocus() 
    {
        return this._tabFocus;
    }
    
    //Setter
    set tabFocus (value) 
    {
        this._tabFocus = value;
        if(!this.initialPageLoad)
        {
            this.handleValueChange(value);
        }
        this.initialPageLoad = false;
    }

    //if console tab not in focus, unsubscribe and stop poller
    handleValueChange(value) 
    {
        console.log('tabFocus: ' + value);
        if(value === 'false' || value === false)
        {
            this.handleUnsubscribe();
    
        }
        else
        {
            this.setupPage();
        }

    }

    //Change the table view
    toggleView()
    {
        //Changes for ESESP-4534: adding the refresh check
        this.sortSearchConfirm = false;
        if(this.selectedRows.length != 0)
        {
            console.log('View Change Check!!!');
            this.sortSearchOperation = 'viewChange';
            this.sortSearchConfirm = true;
            return;
        }
        //End of changes for ESESP-4534
        this.offset = 1;
        this.toggleValue = !this.toggleValue;
        this.loadSpinner = true;
        this.caseSearchText = '';
        this.getContents();
    }

    //refresh case table 
    refreshView(event)
    {
        this.fromRefresh = true;
        //Changes for ESESP-4534: adding the refresh check
        this.sortSearchConfirm = false;
        if(this.selectedRows.length != 0)
        {
            console.log('Refresh View Check!!!');
            this.sortSearchOperation = 'refresh';
            this.sortSearchConfirm = true;
            return;
        }
        //End of changes for ESESP-4534
        this.getContents();
    }

    //Do page setup -> refresh all tables
    setupPage()
    {

        this.getContents();
        this.getSummaryData();
        this.handleSubscribe();        
    }


    //Called on page load
    connectedCallback() 
    {        
        console.log('this.toggleValue: ' + this.toggleValue);
        loadStyle(this, staticStyleSheet);        
        
        this.visibilityHandler = this.listenForMessage.bind(this);
        window.addEventListener("visibilitychange", this.visibilityHandler);

        this.setupPage();
        this.registerErrorListener(); 
    }

    //rerender method to change the pagenation buttons
    // renderedCallback() 
    // {
    //     this.renderButtons();
    // }
    
    //Start of Pagenation methods
    // renderButtons = () => {
    //     this.template.querySelectorAll('.pagenationButton').forEach((but) => {
    //         but.style.backgroundColor = this.page === parseInt(but.dataset.id, 10) ? 'dodgerblue' : 'white';
    //         but.style.color = this.page === parseInt(but.dataset.id, 10) ? 'white' : 'black';
    //     });
    // }

    // get pagesList() {
    //     let mid = Math.floor(this.set_size / 2) + 1;
    //     if (this.page > mid) {
    //         return this.pages.slice(this.page - mid, this.page + mid - 1);
    //     }
    //     return this.pages.slice(0, this.set_size);
    // }


    // pageData = () => {
    //     let page = this.page;
    //     let perpage = this.perpage;
    //     let startIndex = (page * perpage) - perpage;
    //     let endIndex = (page * perpage);
    //     return this.searchedCases.slice(startIndex, endIndex);
    // }


    setPages = () => 
    {
        this.enableLoading = this.searchedCases.length <= 30 
        || this.offset * this.perpage >= this.searchedCases.length? false: true;

        let endIndex = this.offset * this.perpage > this.searchedCases.length?
        this.searchedCases.length : this.offset * this.perpage;

        this.pageData = this.searchedCases.slice(0, endIndex);
        console.log('this.enableLoading: ' + this.enableLoading);
        console.log('this.offset: ' + this.offset);
        console.log('this.searchedCases.length: ' + this.searchedCases.length);
        console.log('this.pageData.length: ' + this.pageData.length);
        // this.page = 1;
        // this.pages = [];
        // let numberOfPages = Math.ceil(data.length / this.perpage);
        // if(numberOfPages > 1)
        // {
        //     for (let index = 1; index <= numberOfPages; index++) 
        //     {
        //         this.pages.push(index);
        //     }
        // }
        // console.log('this.pages: ' + this.pages);
    }


    // get hasPrev() {
    //     return this.page > 1;
    // }


    // get hasNext() {
    //     return this.page < this.pages.length
    // }


    // onNext = () => {
    //     ++this.page;
    // }


    // onPrev = () => {
    //     --this.page;
    // }
    
    // onPageClick = (e) => {
    //     this.page = parseInt(e.target.dataset.id, 10);
    // }

    // get currentPageData() {
    //     return this.pageData();
    // }
    
    //End of Pagenation methods


    closeSortSearchConfirm(eent)
    {
        this.sortSearchConfirm = false;
    }   

    discardSortSearchConfirm()
    {
        console.log('Inside discardSortSearchConfirm');
        console.log('this.sortSearchConfirm: ' + this.sortSearchConfirm);
        this.selectedRows = [];
        this.sortSearchConfirm = false;
        console.log('this.sortSearchConfirm: ' + this.sortSearchConfirm);
        if(this.sortSearchOperation === 'search')
        {
            this.sortSearchOperation = '';
            this.searchCases();
        }
        else if(this.sortSearchOperation === 'sort')
        {
            this.sortSearchOperation = '';
            this.sort(this.sortedBy, this.sortDirection);
        }
        //Changes for ESESP-4534: Checks for Refresh and View changes
        else if(this.sortSearchOperation === 'refresh')
        {
            this.sortSearchOperation = '';
            this.refreshView();
        }
        else if(this.sortSearchOperation === 'viewChange')
        {
            this.sortSearchOperation = '';
            this.toggleView();
        }
        //End of changes for ESESP-4534
    }
    
    loadMoreData(event)
    {

        this.offset++;
        this.setPages();
    }
    //get Case data
    getContents()
    {   
        this.toggleSpinner(true);
        console.log('this.toggleValue: ' + this.toggleValue);
        console.log('this.loadSpinner: ' + this.loadSpinner);
        
        let currentView = '';
        
        if(this.toggleValue)
        {
            this.columns = myCaseColumns;
            this.options = myCaseOptions;
            this.tableTitle = 'My Open Cases';
            currentView = 'MyView';
        }   
        else
        {
            this.columns = allCaseColumns;
            this.options = allCaseOptions;
            this.tableTitle = 'Billing Support Queue';
            currentView = 'AllCases';
        }
        //Call server method to get case data
        getCases({'viewType' : currentView})
        .then(result => {
            this.cases = result;
            this.searchedCases = result;            
            this.searchCases();
            //this.setPages(this.searchedCases);
            this.toggleSpinner(false);
            if(this.fromRefresh)
            {                    
                this.showToast('','Refreshed!','success','dismissible',6000);    
                this.fromRefresh = false;
            }
            console.log('Success!: ') ;
            this.casesSize = this.searchedCases.length;
            if(this.toggleValue)
            {
                this.tableTitle = 'My Open Cases';
            }
            else
            {
                this.tableTitle = 'Billing Support Queue';
            }
            this.tableTitle += ' (' + this.casesSize + ')';            
            
        })
        .catch(error => {
            this.toggleSpinner(false);
            console.log('The error: ' + error +  JSON.stringify(error)) ;
        });

    }

    //Method to set the table height
    setTableHeight()
    {
        if(this.searchedCases)
        {
            if (this.searchedCases.length <= 5)
            {
                this.tableHeight = 'smallTableHeight';
            }                    
            else if (this.searchedCases.length > 5)
            {
                this.tableHeight = 'veryBigTableHeight';
            }
            // else if (this.searchedCases.length > 30)
            // {
            //     this.tableHeight = 'veryBigTableHeight';
            // }
                
        }
    }
    
    //Open New Case method    
    openNewCase(event) 
    {
        
        console.log('Billing: '  + this.billingRecordTypeId);
        this[NavigationMixin.Navigate]({
            type:'standard__objectPage',
            attributes:{
                "objectApiName":"Case",
                "actionName": "new"        
            },
            state:{
                useRecordTypeCheck  : true,
            }
        });
    }

    //method called to perform action. open the Modal only if there are cases selected
    performAction(event)
    {
        console.log('here!!!');
        this.selectedCaseIds = [];
        let selectedCases = this.template.querySelector('lightning-datatable').getSelectedRows();
        var selectedCaseIdsTemp = [];
        //get all the selected rows
        selectedCases.forEach(function (eachCase) {
            selectedCaseIdsTemp.push(eachCase.Id);
        });

        if(selectedCaseIdsTemp.length === 0)
        {
            this.showToast('','No Cases Selected!','info','dismissible',5000);            
        }
        else
        {
            if(this.billingRecordTypeId === '')
            {
                this.getRecordTypesFromClass();
            }
                
            console.log('selectedCaseIdsTemp: '+ selectedCaseIdsTemp);
            this.selectedCaseIds = selectedCaseIdsTemp;
            //console.log('selectedCaseIdsTemp: ' + selectedCaseIdsTemp.length + ': this.selectedCaseIds: ' + this.selectedCaseIds.length);
            this.editForm = true;
            if(this.toggleValue)
            {
                this.actionLabel = 'Update!';
                this.modalTitle = 'Update Cases';            
            }
            else
            {
                this.actionLabel = 'Assign!';
                this.modalTitle = 'Assign!';            
            }
            this.modalClass = 'slds-modal__container';            
            this.confirmModal = true;

            this.toggleModal();
    
        }

    }

    //Submit method from record edit form. Prevent default
    dummySubmit(event)
    {
        event.preventDefault();
        console.log('HERE: ' );        
        var fields = event.detail.fields;
        console.log('fields: ' + JSON.stringify(fields));

    }

    //On Click of Cash App Owner assignment button
    cashAppsOwner()
    {
        this.toggleModal();
        var jsonObject = {};
        jsonObject['OwnerId'] = 'Cash Apps';
        
        jsonObject = JSON.stringify(jsonObject);   
        this.callServerForUpdate(jsonObject);        
    }

    //Check for empty fields, show warning. Call the server method to update
    updateRecord(event)
    {
        
        //var allInputs = this.template.querySelectorAll(".recordFormInput");
        var fields=[];
        if(this.toggleValue)
        {
            fields = ['AccountId','Service__c','Request_Type__c','Solution_Summary__c','Origin','Status'];
            
            let serviceField = this.template.querySelector(`[data-id="Service__c"]`).value;
            let requestField = this.template.querySelector(`[data-id="Request_Type__c"]`).value;
            if(serviceField && !requestField)
            {
                console.log('serviceField: ' + serviceField + ' requestField: ' + requestField);
                this.showToast('','Please select a Request Type!','error','dismissible',6000);   
                return; 
            }
        }
        else
        {
            fields = ['OwnerId'];
            let ownerField = this.template.querySelector(`[data-id="OwnerId"]`).value;
            if(!ownerField)
            {
                this.showToast('','Please Select a User!','error','dismissible',6000);   
                return; 
            }            
        }
        var jsonObject = {};
        console.log('fields' + fields);
        var valueSet = false;
        for(var index = 0; index < fields.length; index++)
        {
            console.log('Inside for: ' );
            let target = this.template.querySelector(`[data-id="${fields[index]}"]`);
            if(target.value)
            {
                valueSet = true;
            }
            console.log('Inside target: ' + target.value );
            jsonObject[fields[index]] = target.value;
            //console.log('jsonObject: ' + jsonObject);    
        }
        if(!valueSet)
        {
            this.showToast('','Nothing to Update!','error','dismissible',6000);   
            return; 
        }
        this.toggleModal();
        jsonObject = JSON.stringify(jsonObject);    
        this.callServerForUpdate(jsonObject);        

    }


    //The server method to update cases. Refresh all views after the update
    callServerForUpdate(jsonObject)
    {
        this.toggleSpinner(true);
        console.log('this.selectedCaseIds: ' + this.selectedCaseIds.length);
        updateCases({'caseIds' : this.selectedCaseIds.join(','),'jsonBody' : jsonObject})
        .then(result => {
            this.toggleSpinner(false);
            var parsedResult = JSON.parse(result);
            var errorString = parsedResult['error'];

            if(errorString === '')
            {
                this.selectedRows = [];
                this.showToast('','Success!','success','dismissible',6000);    
                this.getContents();
                //this.noHeaderSpinner = true;
                this.getSummaryData();
            }
            else
            {
                this.selectedRows = JSON.parse(parsedResult['failedIds']);
                this.showToast('',errorString,'error','sticky',6000);    
            }
            
            console.log('Success!: ' + this.loadSpinner) ;
        })
        .catch(error => {
            this.toggleSpinner(false);
            this.showToast('',error,'error','sticky',6000);    
        });


        console.log('have to update ' + this.selectedCaseIds);
        console.log('Seever call' );
    }

    //Generic toast message method
    showToast(titleParam,messageParam,variantParam,modeParam,durationParam)
    {
        console.log('TOAST!!');
        const toastEvt = new ShowToastEvent({
            title: titleParam,
            message: messageParam,
            variant: variantParam,
            mode: modeParam,
            duration: durationParam
        });
        this.dispatchEvent(toastEvt);
    }

    //Assign case logic
    assignCase()
    {
        this.toggleModal();
        this.toggleSpinner(true);
        assignCaseToUser({'caseId' : this.caseToBeAssigned})
        .then(result => {
            this.toggleSpinner(false);
            if(result === 'true')
            {
                this.showToast('','Assigned!','success','dismissible',6000);    
            }
            else
            {
                this.showToast('',result,'error','sticky',6000);    
            }
            
            console.log('Success!: ' + this.loadSpinner) ;
        })
        .catch(error => {
            this.toggleSpinner(false);
            this.showToast('',error,'error','sticky',6000);    
        });
    }

    //Method called on click of the External Dependency/Assign case
    handleRowAction(event) 
    {

        let actionName = event.detail.action.name;
        console.log('actionName!!!!:' + actionName);
        var row = event.detail.row;        
        this.caseToBeAssigned = row.caseUrl.substring(1, row.caseUrl.length);
        this.selectedAkamCaseId = row.akamCaseId;
        console.log('caseToBeAssigned!!!!:' + this.caseToBeAssigned);
        if(actionName === 'assignCase')
        {
            this.modalTitle = 'Confirm';            
            this.modalClass = 'slds-modal__container';            
            this.confirmModal = true;
            this.toggleModal();
        }
        else if(actionName === 'externalDependancies')
        {      
            if(parseInt(row.externalDependancies) === 0)
            {
                
                this.showToast('','There are no External Dependencies!','info','dismissible',6000);    
                return;
            }
            this.modalTitle = 'External Dependencies';
            console.log('HERE in ED!!' );
            this.modalClass = 'slds-modal__container modalSizeClass';
            this.editForm = false;
            this.confirmModal = false;
            this.getExternalDependancies();            
        }
    }

    //Show/hide spinner
    toggleSpinner(toggleVal)
    {
        this.loadSpinner = toggleVal;        
    }

    //Show/Hide Modal
    toggleModal()
    {
        this.isModalOpen = !this.isModalOpen;
    }

    //Get ED records
    getExternalDependancies()
    {
        this.toggleSpinner(true);
        getExternalDependancyList({'caseId' : this.caseToBeAssigned})
        .then(result => {
            console.log('Success!: ' + this.caseToBeAssigned) ;
            this.toggleSpinner(false);
            this.externalDependancies = result;
            this.toggleModal();
            console.log('Success!: ' + JSON.stringify(result) + result) ;
        })
        .catch(error => {
            this.toggleSpinner(false);
            this.showToast('',error,'error','sticky',6000);    
        });

    }

    //Search column change
    handleChange()
    {
        console.log('Inside the column change');

        this.columnToSearch = '' + this.template.querySelector('.columnToSearch').value;
        console.log('Inside the column change' + this.columnToSearch);

        this.searchCases();

    }

    //on search text change
    searchCaseEvent(event)
    {        
        clearTimeout(this.timeoutId); 
        this.offset = 1;        
        this.timeoutId = setTimeout(this.searchCases.bind(this), 500); 
    }

    //Search cases
    searchCases() 
    {
        this.sortSearchConfirm = false;
        
        if(this.selectedRows.length != 0)
        {
            console.log('Inside Selected Arrays!!!');
            this.sortSearchOperation = 'search';
            this.sortSearchConfirm = true;
            return;
        }
        console.log('Inside the search option');

        this.caseSearchText = this.template.querySelector('.caseSearchText').value;
        
        if(!this.caseSearchText)
        {
            this.searchedCases = this.cases;
        }
        else
        {
            console.log('this.columnToSearch:' + this.columnToSearch);
            let searchFilter = this.caseSearchText.toUpperCase();
            let columnSearch = this.columnToSearch;
            let tempArray = [];

            this.cases.forEach(function(eachRow) 
            {
                if 
                (
                    (
                        columnSearch != 'all' && eachRow[columnSearch] && 
                        JSON.stringify(eachRow[columnSearch]).toUpperCase().indexOf(searchFilter) !== -1
                    ) 
                    ||
                    (
                        columnSearch === 'all' &&
                        JSON.stringify(eachRow).toUpperCase().indexOf(searchFilter) !== -1
                    )
                )
                {   
                    console.log('Inside Loop');             
                    tempArray.push(eachRow);
                    //console.log('tempArray: ' + JSON.stringify(tempArray)); 
                }
            });
        
            this.searchedCases = tempArray;

        }

        this.sort(this.sortedBy, this.sortDirection);
        console.log('Searched SIZE: ' + this.searchedCases.length);
        //this.setPages();
        this.setTableHeight();
        //console.log('this.searchedCases: ' + this.searchedCases);
    }

    //Sort Algorithm
    sortBy(field, reverse) 
    {
        const key = function(x) {
                return x[field];
            };

        return function(a, b) {
            a = key(a);
            b = key(b);
            a = a != undefined ? a: '';
            b = b != undefined ? b: '';
            return reverse * ((a > b) - (b > a));
        };
    }

    //on change of sort column/direction
    onHandleSort(event) 
    {
        this.offset = 1;
        const { fieldName: sortedBy, sortDirection } = event.detail;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;        
        this.sort(sortedBy, sortDirection);
        console.log('sortedBy, sortDirection: ' + sortedBy +  sortDirection);
    }
    
    //Sort method called from handleSort
    sort(sortedBy, sortDirection)
    {
        this.sortSearchConfirm = false;
        if(this.selectedRows.length != 0)
        {
            console.log('Inside Selected Arrays!!!');
            this.sortSearchOperation = 'sort';
            this.sortSearchConfirm = true;
            return;
        }        
        //console.log('this.searchedCases: BEFORE SORT' + JSON.stringify(this.searchedCases));
        const cloneData = [...this.searchedCases];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));

        this.searchedCases = cloneData;
        this.setPages();

    }
    
    //Called when component is destroyed
    disconnectedCallback()
    {
        console.log('CALLING disconnectedCallback');
        //this.resetPoller(true,false); 
        window.removeEventListener("visibilitychange", this.visibilityHandler);        
        this.handleUnsubscribe();
    }


    //Visibility handler
    listenForMessage(message) 
    {

        if (document.visibilityState !== 'visible') 
        {
            console.log('document.visibilityState : ' + document.visibilityState);
            this.handleUnsubscribe();
        }
        else 
        {
            console.log('document.visibilityState : ' + document.visibilityState);
            this.setupPage();
        }
    }

    
    handleSubscribe() 
    {
        //define the poller. The poller is used to handle multiple refreshes
        if(!this.pollerId)
        {
            this.pollerId = setInterval(() => {
                //console.log('running poller : ' + this.PollID);
                if(this.platformEventFired)
                {
                    console.log('Calling the getContents!!');
                    this.getContents();
                    this.getSummaryData();
                    this.platformEventFired = false;
                }
            }, 20000);            
            console.log('Poller: ' + this.pollerId);

        }
        //Define callback on message
        const messageCallback = response => {

            console.log('New message received: ', JSON.stringify(response));
            this.platformEventFired = true;
            // Response contains the payload of the new message received
        };

        // Invoke subscribe method of empApi. Pass reference to messageCallback
        if(!this.subscription)
        {
            subscribe(this.channelName, -1, messageCallback).then(response => {
                // Response contains the subscription information on subscribe call
                console.log('Subscription request sent to: ', JSON.stringify(response.channel));
                this.subscription = response;
            });
        }
    }

    // Handles unsubscribe button click
    handleUnsubscribe() 
    {

        console.log('Inside handleUnsubscribe');
        // Invoke unsubscribe method of empApi
        // window.removeEventListener("visibilitychange", this.visibilityHandler);       
        unsubscribe(this.subscription, response => {
            console.log('unsubscribe() response: ', JSON.stringify(response));
            this.subscription = undefined;
            // Response is true for successful unsubscribe
        });

        window.clearInterval(this.pollerId);
        console.log('Cleared Poller' );
        this.pollerId = undefined;
    }

    //If event cannot be subscribed
    registerErrorListener() 
    {
        // Invoke onError empApi method
        onError(error => {
            console.log('Received error from server: ', JSON.stringify(error));
            // Error contains the server-side error
        });
    }
    
    
    //Get the Summary data 
    getSummaryData()
    {   
        console.log('inside summary');
        if(!this.noHeaderSpinner)
        {
            this.loadHeaderSpinner = true;    
        }        
        this.noHeaderSpinner = false;
        getSummary({'dateFilter' : this.summaryFilter})
        .then(result => {

            //console.log('result: ' + JSON.stringify(result));
            this.iQCount = result.inQueue;
            this.iQ24Count =result.inQueue24;
            this.openCount = result.open;
            this.iRCount = result.irMiss;
            this.resCount = result.resMiss;
            this.closedCount = result.closed;
        
            this.loadHeaderSpinner = false;
        })
        .catch(error => {
            this.loadHeaderSpinner = false;
            console.log('The error: ' + error +  JSON.stringify(error)) ;
        });

    }

    //On Summary filter change
    summaryFilterClick(event)
    {

        this.summaryFilter = '' + this.template.querySelector('.dateFilterOption').value;
        this.getSummaryData();
    }

    //get the records to show
    getNavRecords(event) 
    {
        let buttonVal = event.target.value;

        switch(buttonVal) 
        {
            case "unassigned":
                this.notificationCenterHeader = "Unassigned Cases";
                break;
            case "unassigned24":
                this.notificationCenterHeader = "Unassigned Cases > 24 Hours";
                 break;
            case "IR":
                this.notificationCenterHeader = "IR Violation Cases";
                break;
            default:
                this.notificationCenterHeader = "Resolution Violation Cases";
        }

        if(!this.noHeaderSpinner)
        {
            this.loadHeaderSpinner = true;    
        }        
       
        this.noHeaderSpinner = false;
        getNotificationDetails({'dateFilter' : this.summaryFilter, 'viewName' : buttonVal})
        .then(result => {
            this.notificationlist = result;
            this.loadHeaderSpinner = false;
            let sideNav = this.template.querySelector(".sidenav");
            sideNav.style.width = "250px";
    
        })
        .catch(error => {
            this.loadHeaderSpinner = false;
            console.log('The error: ' + error +  JSON.stringify(error)) ;
        });


    }

    //Close the nav bar
    closeNav(event) 
    {        
        var x = this.template.querySelector(".sidenav");
        x.style.width = "0px";
        this.notificationlist = [];
    }

    //Open record in new tab
    openNewTab(event) 
    {
        //window.open(event.target.value, "_blank");
        this.fireUrlEvent(event.target.value);
    }
        
    //navigate to list view based on nav topic open
    navigateToCaseListView(event) 
    {
        let buttonVal = event && event.target  && event.target.value ? event.target.value : 
                        this.notificationCenterHeader.includes('Unassigned')? 'Unassigned' : 'Miss';
        var listView;
        this.notificationCenterHeader
        switch(buttonVal) 
        {
            case "open":
                listView = "My_Open_Cases_change";
                break;
            case "closed":
                listView = "My_Closed_Cases_change";
                 break;
            case "Unassigned":
                listView = "Billing_Queue";
                break;
            default:
                listView = "My_Open_Cases_change";
        }
        var url = "/lightning/o/Case/list?filterName=" + listView;

        this.fireUrlEvent(url);
    }

    //fire an event to parent aura
    fireUrlEvent(url)
    {
        const urlChangeEvent = new CustomEvent("urlchange", {
            detail: { url }
          });
          // Fire the custom event
        console.log('the URL: ' + url);
        this.dispatchEvent(urlChangeEvent);
    }

    //Called when a record is selected. Put a limit on the selection
    onSelection(event)
    {

        let selectedCases = this.template.querySelector('lightning-datatable').getSelectedRows();
        //get all the selected rows
        var selectedCaseIdsTemp = [];
        selectedCases.forEach(function (eachCase) {
            selectedCaseIdsTemp.push(eachCase.Id);
        });

        this.selectedRows = selectedCaseIdsTemp;
        if(selectedCases.length == 50)
        {
            this.showToast('','You have reached the Maximum Selection of 50 Records!','warning','dismissible',6000);    
        }
    }

    //get billing record type from server
    getRecordTypesFromClass()
    {
        this.toggleSpinner(true);
        getRecordTypes()
        .then(result => {

            for(var index = 0 ; index < result.length; index++)
            {
                if(result[index].label === 'Billing')
                {
                    this.billingRecordTypeId = result[index].value;
                    break;
                }   
            }
            this.toggleSpinner(false);
            
            //console.log('result: ' + JSON.stringify(result));
        })
        .catch(error => {
            console.log('The error: ' + error +  JSON.stringify(error)) ;
            this.toggleSpinner(false);

        });
    }

}