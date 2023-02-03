import { LightningElement ,track , wire, api} from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';



//import getDataDetails from '@salesforce/apex/SC_PSAutomationMultipleAccount.getInitData';
//import getTargetListView from '@salesforce/apex/SC_PSAutomationMultipleAccount.getTargetListViewId';

//apex methods import
import retrieveAccounts from '@salesforce/apex/PS_PODTriggerClass.retrieveAccounts';
import getPODDetail from '@salesforce/apex/PS_PODTriggerClass.getPODDetail';
import assignPODs from '@salesforce/apex/PS_PODTriggerClass.assignPODstoAccOrAccDeptRecords';


import { ShowToastEvent } from 'lightning/platformShowToastEvent';
//import sendEmail from '@salesforce/apex/SC_PSAutomationMultipleAccount.massEmailToCustomers';
//import createRecipientRec from '@salesforce/apex/SC_PSAutomationMultipleAccount.createDLRec';
import { NavigationMixin } from 'lightning/navigation';

const columns = [
    {
        label: 'Select / De-Select',
        fieldName: 'isSelected',
        type: 'checkboxCell',
        typeAttributes: {
        
            isSelected: { fieldName: 'isSelected' },
            MailerName: { fieldName: 'MailerName' },
            areRecipientsPresent : { fieldName: 'areRecipientsPresent' }
            },initialWidth: 160
    },
    {
        label: 'Customer Mailer',
        fieldName: 'MailerURL',
        type: 'url',sortable: true,
        typeAttributes: {label: { fieldName: 'MailerName' }, target: '_blank'}
    }, {
        label: 'Mailer Name',
        fieldName: 'MailerNameText',
        type: 'text',sortable: true,
    },{
        label: 'Master Customer Mailer',
        fieldName: 'MasterMailerURL',sortable: true,
        type: 'url',
        typeAttributes: {label: { fieldName: 'MasterMailerName' }, target: '_blank'}
    },{
        label: 'Account',
        fieldName: 'AccountURL',
        type: 'cellEdit',
        typeAttributes: {
        
            AccountName: { fieldName: 'AccountName' }, AccountURL: { fieldName: 'AccountURL' },areRecipientsPresent: { fieldName: 'areRecipientsPresent' }
            }
       // typeAttributes: {label: { fieldName: 'AccountName' }, target: '_blank'}
    }, {
        label: 'Subject',
        fieldName: 'Subject',
        type: 'text',
    }, {
        label: 'Product',
        fieldName: 'Product',
        type: 'text',
    },
    {label: 'Master Mailer Created Date', fieldName: 'CreatedDate_Text', type: 'text',sortable: true}
];
/*const columns = [
    {
        label:'Name',fieldName:'Name',type:'text'
    }
]*/




export default class ps_PODLoadReport  extends NavigationMixin(LightningElement) {

    dataAssignedPods = [];
    dataUnAssignedPods = [];
    dataAssignedTOPods = [];

    @api recordId;

    podRecord;
    name;
    updatingObject;

    podRecFromController ={};

    podReportId;
    podRecordId;
    podReportLink;
    podrecordIdFromURL;
    pobBatchProcess;
    podActive;

    podToggleLabel;

    currentPageReference = null; 
    urlStateParameters = null;

    loadSpinner = true;
    labelAssigned = 'Assigned POD';




    error;
    set_size = 5;
    perpage = 20;
    @track count;
    @track pageAllIncident = 1;
    @track pagesAllIncident = [];

    @track dataTableData = [];
    @track dataTableDataBackUpForSearch = [];
    @track allIncidents= [];
    @track allIncidentsBackUpForSearch= [];
    @track sortByAllIncidentsSection='MailerURL';
    @track sortDirectionAllIncidentsSection='asc';
    @track searchKeyAllIncidentsSection = '';

   
    @track showTable = true;
    columns = columns;
    @track preSelectedRows = [];
    @track preSelectedRowsName = [];
    @track showDataTable = true;
    @track toCreateAccountName = '';
    @track toCreateAccountURL = '';
    @track showDLCreatePopUp = false;
    @track showIconHelpText = false;
    @track pendingMailerListViewId ;
    @track showConfirmPopup = false;
    @track keyId = 'Id';


    @wire(CurrentPageReference)
    getPageReferenceParameters(currentPageReference) {
       var ref;
       if (currentPageReference) {
        console.log('currentPageReference :: '+ currentPageReference);
        ref = currentPageReference;
        console.log('ref :: ' + ref.attributes.recordId);
        this.podrecordIdFromURL = ref.attributes.recordId;
        console.log('this.podrecordIdFromURL  from wire method:: '+ this.podrecordIdFromURL );
        console.log(JSON.stringify(currentPageReference));
       }
    }


    connectedCallback(){

        this.getPODRecordDetial();

    }


    @track cValue = 'unAssigned';

    get options() {

        return [
            { label: 'Assigned', value: 'assigned' },
            { label: 'Un-Assigned', value: 'unAssigned' },
            { label: this.labelAssigned, value: 'assignedTo' },
        ];
    }

    handleChange(event) {
        this.cValue = event.detail.value;

        if(this.cValue === 'assignedTo' && this.dataAssignedTOPods !== undefined ){

            this.dataTableData = this.dataAssignedTOPods;
            this.showTable = true;
            this.count = this.dataTableData.length;
            this.dataTableDataBackUpForSearch = this.dataTableData;
            this.setPagesAllIncident(this.dataTableData);
            this.pageAllIncident =1 ;
    
            this.loadSpinner = false;



        }else if(this.cValue === 'assigned' && this.dataAssignedPods !== undefined ){

            this.dataTableData = this.dataAssignedPods;
            this.showTable = true;
            this.count = this.dataTableData.length;
            this.dataTableDataBackUpForSearch = this.dataTableData;
            this.setPagesAllIncident(this.dataTableData);
            this.pageAllIncident =1 ;

            this.loadSpinner = false;


        }else if(this.cValue === 'unAssigned' && this.dataUnAssignedPods !== undefined  ){

            this.dataTableData = this.dataUnAssignedPods;
            this.showTable = true;
            this.count = this.dataTableData.length;
            this.dataTableDataBackUpForSearch = this.dataTableData;
            this.setPagesAllIncident(this.dataTableData);
            this.pageAllIncident =1 ;
    
            this.loadSpinner = false;

        }
        else{
            this.dataTableData = [];
            this.dataTableDataBackUpForSearch = [];
            this.showToast('There is no data to display','error','dismissable');
        }

    }



    /********************************* to get POD Record Detial *************************************/

    getPODRecordDetial(){

        this.preSelectedRows = [];
        //this.cValue = this.cValue ;
        getPODDetail({podRecordId : this.podrecordIdFromURL})
         .then(result => {
                this.name           = result.Name;
                this.updatingObject = result.Updating_Object__c;
                this.podReportId    = result.ReportId__c;
                this.podRecordId    = result.Id;
                this.podReportLink  = '/'+ result.ReportId__c;
                this.pobBatchProcess = result.Batch_Process__c;
                this.podActive       = result.Active__c;

                this.labelAssigned = result.Name + " Assigned";

                console.log('this.podReportId from POD Record Detial:: ' + this.podReportId);

                //to get the data of All Accounts to be populated on datatable

                if(!this.pobBatchProcess && this.podActive)
                {   
                    if(this.updatingObject === 'Account'){
                        this.columns = [{
                                            label: 'Select / De-Select',
                                            fieldName: 'isSelected',
                                            type: 'checkboxCell',
                                            typeAttributes: {
                                            
                                                isSelected: { fieldName: 'isSelected' },
                                                accountId: { fieldName: 'accountId' },
                                                accDeptId: {fieldName: 'accDeptId'}
                                                },initialWidth: 160
                                        },
                                        {
                                            label: 'Akam Account Id',
                                            fieldName: 'akamAccountIdLink',
                                            type: 'url',
                                            sortable: true,
                                            cellAttributes: { alignment: 'left' },
                                            typeAttributes: {label: {fieldName: 'akamAccount'}, tooltip:'Go to detail page', target: '_blank'}
                                        },
                                        {
                                            label: 'Account Name',
                                            fieldName: 'accountLink',
                                            type: 'url',
                                            sortable: true,
                                            cellAttributes: { alignment: 'left' },
                                            typeAttributes: {label: {fieldName: 'accountName'}, tooltip:'Go to detail page', target: '_blank'}
                                        },
                                        {
                                            label: 'Account POD Name',
                                            fieldName: 'podLink',
                                            type: 'url',
                                            sortable: true,
                                            cellAttributes: { alignment: 'left' },
                                            typeAttributes: {label: {fieldName: 'accPod'}, tooltip:'Go to detail page', target: '_blank'}
                                        },
                                        {
                                            label: 'Updating Object',
                                            fieldName: 'updateObj',
                                            type: 'string',
                                            sortable: false,
                                            cellAttributes: { alignment: 'left' },
                                        }];

                        this.keyId = 'accountId';              
                    }
                    else if(this.updatingObject === 'Account & Account Dept'){
                        this.columns = [{
                                            label: 'Select / De-Select',
                                            fieldName: 'isSelected',
                                            type: 'checkboxCell',
                                            typeAttributes: {
                                            
                                                isSelected: { fieldName: 'isSelected' },
                                                accountId: { fieldName: 'accountId' },
                                                accDeptId: {fieldName: 'accDeptId'}
                                                },initialWidth: 160
                                        },
                                        {
                                            label: 'Akam Account Id',
                                            fieldName: 'akamAccountIdLink',
                                            type: 'url',
                                            sortable: true,
                                            cellAttributes: { alignment: 'left' },
                                            typeAttributes: {label: {fieldName: 'akamAccount'}, tooltip:'Go to detail page', target: '_blank'}
                                        },
                                        //{ label:'Case Number', fieldName: 'caseLink', type: 'url', sortable:true, typeAttributes: {label: {fieldName: 'CaseNumber'}, tooltip:'Go to detail page', target: '_blank'}},
                                        {
                                            label: 'Account Name',
                                            fieldName: 'accountLink',
                                            type: 'url',
                                            sortable: true,
                                            cellAttributes: { alignment: 'left' },
                                            typeAttributes: {label: {fieldName: 'accountName'}, tooltip:'Go to detail page', target: '_blank'}
                                        },
                                        {
                                            label: 'Account POD Name',
                                            fieldName: 'podLink',
                                            type: 'url',
                                            sortable: true,
                                            cellAttributes: { alignment: 'left' },
                                            typeAttributes: {label: {fieldName: 'accPod'}, tooltip:'Go to detail page', target: '_blank'}
                                        },
                                        {
                                            label: 'Account Dept',
                                            fieldName: 'accDeptLink',
                                            type: 'url',
                                            sortable: true,
                                            cellAttributes: { alignment: 'left' },
                                            typeAttributes: {label: {fieldName: 'accDeptName'}, tooltip:'Go to detail page', target: '_blank'}
                                        },
                                        {
                                            label: 'Account Dept POD Name',
                                            fieldName: 'accDeptPodLink',
                                            type: 'url',
                                            sortable: true,
                                            cellAttributes: { alignment: 'left' },
                                            typeAttributes: {label: {fieldName: 'accDeptPod'}, tooltip:'Go to detail page', target: '_blank'}
                                        },
                                        {
                                            label: 'Updating Object',
                                            fieldName: 'updateObj',
                                            type: 'string',
                                            sortable: false,
                                            cellAttributes: { alignment: 'left' },
                                        }
                                    
                                        ];

                        this.keyId = 'accDeptId';              
                    }
                    else if(this.updatingObject === 'Account Dept'){
                        this.columns = [ 
                                        {
                                            label: 'Select / De-Select',
                                            fieldName: 'isSelected',
                                            type: 'checkboxCell',
                                            typeAttributes: {
                                            
                                                isSelected: { fieldName: 'isSelected' },
                                                accountId: { fieldName: 'accountId' },
                                                accDeptId: {fieldName: 'accDeptId'}
                                                },initialWidth: 160
                                        },
                                        {
                                            label: 'Account Dept',
                                            fieldName: 'accDeptLink',
                                            type: 'url',
                                            sortable: true,
                                            cellAttributes: { alignment: 'left' },
                                            typeAttributes: {label: {fieldName: 'accDeptName'}, tooltip:'Go to detail page', target: '_blank'}
                                        },
                                        {
                                            label: 'Account Name',
                                            fieldName: 'accountLink',
                                            type: 'url',
                                            sortable: true,
                                            cellAttributes: { alignment: 'left' },
                                            typeAttributes: {label: {fieldName: 'accountName'}, tooltip:'Go to detail page', target: '_blank'}
                                        },
                                        {
                                            label: 'Account Dept POD Name',
                                            fieldName: 'accDeptPodLink',
                                            type: 'url',
                                            sortable: true,
                                            cellAttributes: { alignment: 'left' },
                                            typeAttributes: {label: {fieldName: 'accDeptPod'}, tooltip:'Go to detail page', target: '_blank'}
                                        },
                                        {
                                            label: 'Updating Object',
                                            fieldName: 'updateObj',
                                            type: 'string',
                                            sortable: false,
                                            cellAttributes: { alignment: 'left' },
                                        }];
                        this.keyId = 'accDeptId';              
                    }

                    this.getAllAccountsData();
                }
                else if (this.pobBatchProcess){

                    const toastEvt = new ShowToastEvent({
                        title: "Info!",
                        message: 'POD : (' + this.name + ') There is a Batch in process for the POD assignment, please wait for some time & refresh again.',
                        variant: "info",
                        mode: "dismissible",
                        duration: 12000
                    });
                    this.dispatchEvent(toastEvt);
                    this.loadSpinner = false;

                }else if(!this.podActive){

                    const toastEvt = new ShowToastEvent({
                        title: "Info!",
                        message: 'POD : ('+ this.name + ') is inactive and can\'t load the report',
                        variant: "info",
                        mode: "dismissible",
                        duration: 12000
                    });
                    this.dispatchEvent(toastEvt);
                    this.loadSpinner = false;

                }
                

            }).catch(error => {
                this.error = error;
                this.data = undefined;

                const toastEvt = new ShowToastEvent({
                    title: "Error!",
                    message: "Error occured while fetching report data",
                    variant: "error",
                    mode: "dismissible",
                    duration: 8000
                });
                this.dispatchEvent(toastEvt);
                console.log(JSON.stringify(error));
            });
    
    
    }

    /********************************* end of get POD Record Detial *************************************/




    rowCountAssignedPods = 0;
    rowCountAssignedTOPods = 0;
    rowCountUnAssignedPods = 0;
    overallReportRows = 0;

    getAllAccountsData(){

        console.log('this.podReportId :: '+ this.podReportId);
        console.log('this.updatingObject :: '+ this.updatingObject);

        //for default view on the screen - toggle
        //this.podToggle = false;

        retrieveAccounts({reportId : this.podReportId, updatingObj : this.updatingObject, podId : this.podRecordId, podName : this.name })
            .then(result => {
                
                //this.loadSpinner = false;

                if(result.statusOfAsk === "Success"){
                    this.dataAssignedPods       = result.assignedPODs;
                    this.dataUnAssignedPods     = result.unAssignedPODs;
                    this.dataAssignedTOPods     = result.assignedToPODs;

                    this.rowCountAssignedPods   = result.assignedPODs.length;
                    this.rowCountUnAssignedPods = result.unAssignedPODs.length;
                    this.rowCountAssignedTOPods = result.assignedToPODs.length;

                    this.overallReportRows      = result.assignedPODs.length +result.unAssignedPODs.length;
                    this.error = undefined;

                    //console.log('objectInfo :: ' + this.objectInfo.data );


                    if(this.cValue === 'assignedTo'){
                        this.dataTableData = this.dataAssignedTOPods;
                    }else if(this.cValue === 'assigned'){
                        this.dataTableData = this.dataAssignedPods;
                    }else{
                        this.dataTableData = this.dataUnAssignedPods;
                    }
                    
                    this.showTable = true;
                    this.count = this.dataTableData.length;
                    // this.allIncidents = returnResult.incidentList_AllOpenIncidents;  
                    this.dataTableDataBackUpForSearch = this.dataTableData;
                    this.setPagesAllIncident(this.dataTableData);
                    this.pageAllIncident =1 ;


                    //this.podToggleEvent();

                    this.loadSpinner = false;



                }
                else if(result.statusOfAsk === "Failure"){
                    console.log("Failure noticed :: " +  result.errorTrace);
                    this.error                  = result.errorTrace;
                    this.dataAssignedPods       = undefined;
                    this.dataUnAssignedPods     = undefined;
                    this.dataTableData = [];
                    this.dataTableDataBackUpForSearch = [];
                    const toastEvt = new ShowToastEvent({
                            title: "Error while fetching data from the POD Report !",
                            message: result.errorTrace,
                            variant: "error",
                            mode: "dismissible",
                            duration: 8000
                        });
                        this.dispatchEvent(toastEvt);

                        this.loadSpinner = false;
                        //onsole.log(JSON.stringify(error));
                }
        
            }).catch(error => {
                this.error = error;
                this.data = undefined;

                const toastEvt = new ShowToastEvent({
                    title: "Error, no valid response from the server!",
                    message: "Unknown",
                    variant: "error",
                    mode: "dismissible",
                    duration: 8000
                });
                this.dispatchEvent(toastEvt);
                console.log(JSON.stringify(error));
                this.loadSpinner = false;
            });

    }
    /********************************* end of All Accounts Data *************************************/




    /********************************* start of execute Data *************************************/
    getSelectedRec() {

        this.loadSpinner = true;

        if(this.preSelectedRows.length === 0){
            //this.showToast('No Rows selected for Assigning PODs.','Warning','dismissable');

            this.loadSpinner = false;
            const toastEvt = new ShowToastEvent({
                title: "Warning!",
                message: 'No Rows selected for Assigning PODs',
                variant: "Warning",
                mode: "dismissible",
                duration: 8000
            });
            this.dispatchEvent(toastEvt);

           
        }
        else{

            assignPODs({ Ids: this.preSelectedRows, objName: this.updatingObject, podId: this.podRecordId, podName : this.name})
                .then(result => {

                    console.log('from server : '+ JSON.stringify(result));
                    this.loadSpinner = false;

                    if(result === 'Please wait for the email to see success/failures over POD Assignment, a Batch Process is initiated for the same.')
                    {
                        const toastEvt = new ShowToastEvent({
                            title: "Info",
                            message: JSON.stringify(result),
                            variant: "info",
                            mode: "dismissible",
                            duration: 12000
                        });
                        this.dispatchEvent(toastEvt);

                        this.loadSpinner = true;
                    }
                    else{
                        const toastEvt = new ShowToastEvent({
                            title: "Success",
                            message: JSON.stringify(result),
                            variant: "success",
                            mode: "dismissible",
                            duration: 12000
                        });
                        this.dispatchEvent(toastEvt);

                        this.dataAssignedPods = [];
                        this.dataUnAssignedPods = [];

                        this.refresh();
                    }

                    
                    

                }).catch(error => {
                    this.loadSpinner = false;
                    let errorBody = error.body;
                    const toastEvt = new ShowToastEvent({
                        title: "Error!",
                        message: errorBody.message,
                        variant: "error",
                        mode: "dismissible",
                        duration: 12000
                    });
                    this.dispatchEvent(toastEvt);
                    console.log(JSON.stringify(error));

                    this.refresh();
                    
                });
        }
    }
    /********************************* end of execute Data *************************************/



    /********************************* start of  refresh Data *************************************/
    refresh() {
        this.loadSpinner = true;

        this.dataAssignedPods       = null;
        this.dataUnAssignedPods     = null;
        
        //this.cValue = 'unAssigned';

        this.rowCountAssignedPods   = 0;
        this.rowCountUnAssignedPods = 0;
        
        this.getPODRecordDetial();
        //this.getAllAccountsData();
    }


    
    handleToggleChange(event){
        var i =0; 
        var j=0;
        
        this.dataTableData = this.dataTableDataBackUpForSearch;
        if(event.target.checked){
            this.showTable = false;
            this.preSelectedRows = [];
            this.preSelectedRowsName = [];
             for(i=0;i<this.dataTableData.length;i++){
                 //if(this.dataTableData[i].areRecipientsPresent){
                      this.dataTableData[i].isSelected = true;
                      if((this.updatingObject === 'Account & Account Dept' || this.updatingObject === 'Account Dept')){
                        this.preSelectedRows.push(this.dataTableData[i].accDeptId);

                        console.log('in bulk select for Account or Account Dept:: ' + this.dataTableData[i].accDeptId);
                        this.preSelectedRowsName.push(this.dataTableData[i].accDeptId);

                        //accountId: { fieldName: 'accountId' },
                        //accDeptId: {fieldName: 'accDeptId'}
                      }else{
                        this.preSelectedRows.push(this.dataTableData[i].accountId);

                        console.log('in bulk select for Account :: ' + this.dataTableData[i].accountId);
                        this.preSelectedRowsName.push(this.dataTableData[i].accountId);
                      }
                      
                 //}     
                      
            }
            for(j=0;j<this.dataTableDataBackUpForSearch.length;j++){
                //if(this.dataTableDataBackUpForSearch[j].areRecipientsPresent){
                     this.dataTableDataBackUpForSearch[j].isSelected = true;
                     
                //}     
                     
           }
            this.showTable = true;
         }else{
            this.showTable = false;
            for(i=0;i<this.dataTableData.length;i++){
                this.dataTableData[i].isSelected = false;
                
                
            }
            for(j=0;j<this.dataTableDataBackUpForSearch.length;j++){
                this.dataTableDataBackUpForSearch[j].isSelected = false;
                
                
            }
            this.preSelectedRows = [];
            this.preSelectedRowsName = [];
            this.showTable = true;
         }
        // alert(this.preSelectedRows.length);
    }


    handleCheckingRow(event){
        var i =0;
        var j=0;
      //  alert('main comp*'+event.detail);
        for(i=0;i<this.dataTableData.length;i++){
            if(this.dataTableData[i].accountId === event.detail || this.dataTableData[i].accDeptId === event.detail){
                this.dataTableData[i].isSelected = true;
                this.preSelectedRows.push((this.updatingObject === 'Account & Account Dept' || this.updatingObject === 'Account Dept') ? this.dataTableData[i].accDeptId : this.dataTableData[i].accountId);
                this.preSelectedRowsName.push((this.updatingObject === 'Account & Account Dept' || this.updatingObject === 'Account Dept') ? this.dataTableData[i].accDeptId : this.dataTableData[i].accountId);

                break;
            }
        }

        for(j=0;j<this.dataTableDataBackUpForSearch.length;j++){
            if(this.dataTableDataBackUpForSearch[j].accountId === event.detail || this.dataTableDataBackUpForSearch[j].accDeptId === event.detail){
                this.dataTableDataBackUpForSearch[j].isSelected = true;
                
                break;
            }
        }
       // alert(JSON.stringify(this.preSelectedRows));
    }

    handleUnCheckingRow(event){
        var i =0;
        var j=0;
       // var tempArray = [];
      //  alert('main comp*'+event.detail);
        for(i=0;i<this.dataTableData.length;i++){
            if(this.dataTableData[i].accountId === event.detail || this.dataTableData[i].accDeptId === event.detail ){
                this.dataTableData[i].isSelected = false;
                //const index = this.preSelectedRows.indexOf(this.dataTableData[i].Id);
                //changed now
                
                const index = this.preSelectedRows.indexOf((this.updatingObject === 'Account & Account Dept' || this.updatingObject === 'Account Dept') ? this.dataTableData[i].accDeptId : this.dataTableData[i].accountId);
                if(index > -1)
                {
                   // tempArray = this.preSelectedRows;
                  //  tempArray.splice(index,1);
                    this.preSelectedRows.splice(index,1);
                }

                const indexName = this.preSelectedRowsName.indexOf((this.updatingObject === 'Account & Account Dept' || this.updatingObject === 'Account Dept') ? this.dataTableData[i].accDeptId : this.dataTableData[i].accountId);
                if(indexName > -1)
                {
                   // tempArray = this.preSelectedRows;
                  //  tempArray.splice(index,1);
                    this.preSelectedRowsName.splice(indexName,1);
                }
                
                break;
            }
        }

        for(j=0;j< this.dataTableDataBackUpForSearch.length;j++){
            if(this.dataTableData[j].accountId === event.detail || this.dataTableData[j].accDeptId === event.detail){
                this.dataTableDataBackUpForSearch[j].isSelected = false;
            }
        }
      //  alert(JSON.stringify(this.preSelectedRows));
    }


    renderedCallback(){

        if(this.showTable){
               const iconStyle = document.createElement('style');
               iconStyle.innerText = `c-ps_-p-o-d-load-report .slds-button_icon svg{
               fill: red;
               }`;
               this.template.querySelector('lightning-button-icon').appendChild(iconStyle);
        }       
         
      
        if(this.hasPrevAllIncident){
            const prevAllButtonStyle = document.createElement('style');
            prevAllButtonStyle.innerText = `c-ps_-p-o-d-load-report .prevAllIncidentSection .slds-button{
                background-color:#5D94C4;
                border:none;
                color:white;
                }`;
                this.template.querySelector('lightning-button').appendChild(prevAllButtonStyle);
        }
        if(this.arePagesMoreThanOneAllIncidentSection){
            const pageButtonAllStyle = document.createElement('style');
            pageButtonAllStyle.innerText = `c-ps_-p-o-d-load-report .pageButtonsAllIncident .slds-button{
                background-color:#5D94C4;
                border:none;
                color:white;
                }`;
                this.template.querySelector('lightning-button').appendChild(pageButtonAllStyle);
        }
        if(this.hasNextAllIncident){
            const nextAllButtonStyle = document.createElement('style');
            nextAllButtonStyle.innerText = `c-ps_-p-o-d-load-report .nextAllIncident .slds-button{
                background-color:#5D94C4;
                border:none;
                color:white;
                }`;
                this.template.querySelector('lightning-button').appendChild(nextAllButtonStyle);
        }
    }


    updateColumnSortingAllIncidentsSection(event){
        //  this.loadSpinner = true;  
          let fieldName ;
          if(event.detail.fieldName === 'akamAccountIdLink'){
              fieldName = 'akamAccount';
              this.sortByAllIncidentsSection = 'akamAccountIdLink';
          }else if(event.detail.fieldName === 'accountLink'){
           fieldName = 'accountName';
           this.sortByAllIncidentsSection = 'accountLink';
           }
           else if(event.detail.fieldName === 'podLink'){
            fieldName = 'accPod';
            this.sortByAllIncidentsSection = 'podLink';
            }
            else if(event.detail.fieldName === 'accDeptPodLink'){
                fieldName = 'accDeptPod';
                this.sortByAllIncidentsSection = 'accDeptPodLink';
            }
            else if(event.detail.fieldName === 'accDeptLink'){
                fieldName = 'accDeptName';
                this.sortByAllIncidentsSection = 'accDeptLink';
            }else{
                fieldName = event.detail.fieldName;
                this.sortByAllIncidentsSection = event.detail.fieldName;
            }
         
          let sortDirection = event.detail.sortDirection;
          
      
          //assign the values
          
          this.sortDirectionAllIncidentsSection = sortDirection;
          //call the custom sort method.
          this.sortData(fieldName, sortDirection);
          
          
    } 


    //Sorting is performed in this ethod
    sortData(fieldName, sortDirection) {
        let sortResult;
   
        sortResult = Object.assign([], this.dataTableData);
        this.dataTableData = sortResult.sort(function(a,b){
            if(a[fieldName] < b[fieldName]){
                return sortDirection === 'asc' ? -1 : 1;
            }  
            else if(a[fieldName] > b[fieldName]){
                return sortDirection === 'asc' ? 1 : -1;
            } 
            return 0;  
        })
    }


    get arePagesMoreThanOneAllIncidentSection(){
      
        return this.pagesAllIncident.length > 1 ? true :false; 
    }

    get pagesListAllIncident() {
        let mid = Math.floor(this.set_size / 2) + 1;
        if (this.pageAllIncident > mid) {
            return this.pagesAllIncident.slice(this.pageAllIncident - mid, this.pageAllIncident + mid - 1);
        }
        return this.pagesAllIncident.slice(0, this.set_size);
    }


    get currentPageDataAllIncident() {
        return this.pageDataAllIncident();
    }


    pageDataAllIncident = () => {
        let page = this.pageAllIncident;
        let perpage = this.perpage;
        let startIndex = (page * perpage) - perpage;
        let endIndex = (page * perpage);
        let a = this.preSelectedRows;
        this.preSelectedRows = a; 
        return this.dataTableData.slice(startIndex, endIndex);
    }

    setPagesAllIncident = (data) => {
        this.pagesAllIncident = [];
        let numberOfPages = Math.ceil(data.length / this.perpage);
        for (let index = 1; index <= numberOfPages; index++) {
           
            this.pagesAllIncident.push(index);
           
            
        }
        
    }

    get hasPrevAllIncident() {
        return this.pageAllIncident > 1;
    }

    get hasNextAllIncident() {
        return this.pageAllIncident< this.pagesAllIncident.length;
    }

    onNext = (e) => { console.log(e);
        
        ++this.pageAllIncident;
                 
    }

    onPrev = (e) => { console.log(e);
         
        --this.pageAllIncident;
         
    }

    onPageClick = (e) => { console.log(e);
           
         
        //alert(JSON.stringify(this.preSelectedRows));
            
        this.pageAllIncident = parseInt(e.target.label, 10);
             
         
    }




    /************************************ start for search **************************************************/
    keycheck(event){
        if(event.which === 13){
            this.handleSearch(event);
        }
    } 


    //handlig search functionality on blur
    
    
    handleSearch(event){
        var searchString,tempList,allIncidentsList,i;
        let tempRecord;
        // At least 3 characters required for search
        if(event.target.value !== '' && event.target.value.length < 3){
            this.showToast('Please type at least 3 characters for search.','error','dismissable');
            return;
        }
        //this.loadSpinner = true;
        
        
        
        
        if(event.target.value === ''){
            this.dataTableData = this.dataTableDataBackUpForSearch;
        }else{
            
            this.searchKeyAllIncidentsSection = event.target.value;
            searchString = event.target.value.toLowerCase();
            tempList = [];
            allIncidentsList = [];
            allIncidentsList = this.dataTableDataBackUpForSearch;
            
            for(i=0;i<allIncidentsList.length;i++){
                tempRecord = Object.assign({}, allIncidentsList[i]); 
                if(this.updatingObject === 'Account'){
                    if(tempRecord.akamAccount.toLowerCase().includes(searchString) || tempRecord.accountName.toLowerCase().includes(searchString) || tempRecord.accPod.toLowerCase().includes(searchString) ){
                            tempList.push(tempRecord); 
                        }

                }else if(this.updatingObject === 'Account & Account Dept'){

                    if(tempRecord.akamAccount.toLowerCase().includes(searchString) || tempRecord.accountName.toLowerCase().includes(searchString) || tempRecord.accPod.toLowerCase().includes(searchString)  || tempRecord.accDeptName.toLowerCase().includes(searchString) || tempRecord.accDeptPod.toLowerCase().includes(searchString) ){
                            tempList.push(tempRecord); 
                        }

                }else  if(this.updatingObject === 'Account Dept'){

                    if(tempRecord.accDeptName.toLowerCase().includes(searchString) || tempRecord.accountName.toLowerCase().includes(searchString) || tempRecord.accDeptPod.toLowerCase().includes(searchString) ){
                            tempList.push(tempRecord); 
                        }

                }else {
                    console.log('Not matching any of the Updating Object')
                }
            }    
            this.dataTableData = tempList;
            
            
        } 
        this.count = this.dataTableData.length;  
        
        this.setPagesAllIncident(this.dataTableData);
        this.pageAllIncident =1 ;

        //this.loadSpinner = true;
        
    }
    /************************************ end for search ************************/



    // Handling toasts
    showToast(message,variant,mode) {
    // alert('here');
        const evt = new ShowToastEvent({
            
            message: message,
            variant: variant,
            mode: mode
        });

    this.dispatchEvent(evt);
    }

    
}