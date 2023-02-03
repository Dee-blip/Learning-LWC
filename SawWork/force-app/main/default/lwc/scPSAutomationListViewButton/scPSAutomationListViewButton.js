import { LightningElement ,track} from 'lwc';
import getDataDetails from '@salesforce/apex/SC_PSAutomationMultipleAccount.getInitData';
import getTargetListView from '@salesforce/apex/SC_PSAutomationMultipleAccount.getTargetListViewId';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import sendEmail from '@salesforce/apex/SC_PSAutomationMultipleAccount.massEmailToCustomers';
import createRecipientRec from '@salesforce/apex/SC_PSAutomationMultipleAccount.createDLRec';
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

export default class ScPSAutomationListViewButton  extends NavigationMixin(LightningElement) {

  //  @track error;
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

   
    @track showTable = false;
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


   

    handleCancel(){
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'PS_Customer_Mailers__c',
                actionName: 'list'
            },
            state: {
                // 'filterName' is a property on 'state'
                // and identifies the target list view.
                // It may also be an 18 character list view id.
                // or by 18 char '00BT0000002TONQMA4'
                filterName: this.pendingMailerListViewId 
            }
        });
    }

    handleCreateDL(){
        var i=0;
        var j =0;
        var emails = this.template.querySelector(".recipients").value;
        var recname = this.template.querySelector(".name").value;
        if(emails === '' || emails === undefined || recname === '' || recname === undefined){
            this.showToast('Please fill all required fields.','error','dismissable');
        }else{
            createRecipientRec({accId:this.toCreateAccountURL,recName:recname,recipients:emails})
            .then(resultRec =>{
              if(resultRec === ''){
                this.showTable = false;
                for(i=0;i<this.dataTableData.length;i++){
                    if(this.dataTableData[i].AccountURL === this.toCreateAccountURL){
                        this.dataTableData[i].areRecipientsPresent = true;  
                    }
                    
                }
                for(j=0;j<this.dataTableDataBackUpForSearch.length;j++){
                    if(this.dataTableDataBackUpForSearch[j].AccountURL === this.toCreateAccountURL){
                        this.dataTableDataBackUpForSearch[j].areRecipientsPresent = true;  
                    }
                    
                }
                this.showToast('PS Automation Manage Recipient record has been created.','success','dismissable');
                this.showDLCreatePopUp = false;
                this.showTable = true;
                
              }else{
                this.showToast(resultRec,'error','dismissable'); 
              }
            }).catch(error => {
               
                console.log(JSON.stringify(error));
              
            });
        }
    }

    handleOpenAcc(){
        window.open(this.toCreateAccountURL);
    }

    handleCreateDLRec(event){
        this.toCreateAccountName = event.detail.data.accname;
        this.toCreateAccountURL = event.detail.data.accurl;
        this.showDLCreatePopUp = true;
    }

    handleCreatePopUpCancel(){
        this.showDLCreatePopUp = false; 
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
                 if(this.dataTableData[i].areRecipientsPresent){
                      this.dataTableData[i].isSelected = true;
                      this.preSelectedRows.push(this.dataTableData[i].Id);
                      this.preSelectedRowsName.push(this.dataTableData[i].MailerName);
                 }     
                      
            }
            for(j=0;j<this.dataTableDataBackUpForSearch.length;j++){
                if(this.dataTableDataBackUpForSearch[j].areRecipientsPresent){
                     this.dataTableDataBackUpForSearch[j].isSelected = true;
                     
                }     
                     
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
            if(this.dataTableData[i].MailerName === event.detail){
                this.dataTableData[i].isSelected = true;
                this.preSelectedRows.push(this.dataTableData[i].Id);
                this.preSelectedRowsName.push(this.dataTableData[i].MailerName);

                break;
            }
        }

        for(j=0;j<this.dataTableDataBackUpForSearch.length;j++){
            if(this.dataTableDataBackUpForSearch[j].MailerName === event.detail){
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
            if(this.dataTableData[i].MailerName === event.detail){
                this.dataTableData[i].isSelected = false;
                const index = this.preSelectedRows.indexOf(this.dataTableData[i].Id);
                if(index > -1)
                {
                   // tempArray = this.preSelectedRows;
                  //  tempArray.splice(index,1);
                    this.preSelectedRows.splice(index,1);
                }

                const indexName = this.preSelectedRowsName.indexOf(this.dataTableData[i].MailerName);
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
            if(this.dataTableDataBackUpForSearch[j].MailerName === event.detail){
                this.dataTableDataBackUpForSearch[j].isSelected = false;
            }
        }
      //  alert(JSON.stringify(this.preSelectedRows));
    }
    renderedCallback(){


        
        if(this.showTable){
               const iconStyle = document.createElement('style');
               iconStyle.innerText = `c-sc-p-s-automation-list-view-button .slds-button_icon svg{
               fill: red;
               }`;
               this.template.querySelector('lightning-button-icon').appendChild(iconStyle);
        }       
         
      
        if(this.hasPrevAllIncident){
            const prevAllButtonStyle = document.createElement('style');
            prevAllButtonStyle.innerText = `c-sc-p-s-automation-list-view-button .prevAllIncidentSection .slds-button{
                background-color:#5D94C4;
                border:none;
                color:white;
                }`;
                this.template.querySelector('lightning-button').appendChild(prevAllButtonStyle);
        }
        if(this.arePagesMoreThanOneAllIncidentSection){
            const pageButtonAllStyle = document.createElement('style');
            pageButtonAllStyle.innerText = `c-sc-p-s-automation-list-view-button .pageButtonsAllIncident .slds-button{
                background-color:#5D94C4;
                border:none;
                color:white;
                }`;
                this.template.querySelector('lightning-button').appendChild(pageButtonAllStyle);
        }
        if(this.hasNextAllIncident){
            const nextAllButtonStyle = document.createElement('style');
            nextAllButtonStyle.innerText = `c-sc-p-s-automation-list-view-button .nextAllIncident .slds-button{
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
          if(event.detail.fieldName === 'CreatedDate_Text'){
              fieldName = 'CreatedDate';
              this.sortByAllIncidentsSection = 'CreatedDate_Text';
          }else if(event.detail.fieldName === 'MailerURL'){
           fieldName = 'MailerName';
           this.sortByAllIncidentsSection = 'MailerURL';
           }
           else if(event.detail.fieldName === 'MasterMailerURL'){
            fieldName = 'MasterMailerName';
            this.sortByAllIncidentsSection = 'MasterMailerURL';
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
        var resturnVal = 0;
   
        sortResult = Object.assign([], this.dataTableData);
        this.dataTableData = sortResult.sort(function(a,b){
            if(a[fieldName] < b[fieldName]){
                if(sortDirection === 'asc'){
                    resturnVal = -1;
                }else{
                    resturnVal = 1;
                }
            }
           // return sortDirection === 'asc' ? -1 : 1;
            else if(a[fieldName] > b[fieldName]){
                if(sortDirection === 'asc'){
                    resturnVal = 1;
                }else{
                    resturnVal = -1;
                }
            }
          //  return sortDirection === 'asc' ? 1 : -1;
            else{
                resturnVal = 0;
            }
            return resturnVal;
            
        })
    }


    connectedCallback(){
        var i=0;
        var result;
        getTargetListView()
        .then(listviewid =>{
            this.pendingMailerListViewId = listviewid;
        }).catch(error => {
               
            console.log(JSON.stringify(error));
          
        }); 
        
       // alert('here');
        getDataDetails()
        .then(resultRec =>{
          //  alert('here1');
            result = JSON.parse(resultRec);
            
           // alert(JSON.stringify(result));
            
           // let tempDataList = []; 
           // var tempRec;
            for(i=0;i<result.length;i++){
                this.dataTableData.push({Id:result[i].mailerRec.Id,MailerURL:'/' + result[i].mailerRec.Id,MailerName:result[i].mailerRec.Name,MasterMailerURL:'/'+result[i].mailerRec.Parent_PS_Customer_Mailer__c,MasterMailerName:result[i].mailerRec.Parent_PS_Customer_Mailer__r.Name,MailerNameText:result[i].mailerRec.PS_Customer_Mailer_Name__c,AccountURL:'/'+result[i].mailerRec.Account__c,AccountName:result[i].mailerRec.Account__r.Name,Subject:result[i].mailerRec.Subject__c,Product:result[i].mailerRec.Product_Name__c,CreatedDate:result[i].mailerRec.Parent_PS_Customer_Mailer__r.CreatedDate,CreatedDate_Text:result[i].CreatedDate_Text,isSelected:false,areRecipientsPresent:result[i].areRecipientsPresent});
               //this.dataTableData.push({id:i,mailerNameText:'ddsfds',accountName:'dsc'});
              
                
            }
           // alert(JSON.stringify(this.dataTableData));
           // this.dataTableData.push({id:'1',Name:'Vishnu'});
            this.showTable = true;
            this.count = this.dataTableData.length;
           // this.allIncidents = returnResult.incidentList_AllOpenIncidents;  
            this.dataTableDataBackUpForSearch = this.dataTableData;
            this.setPagesAllIncident(result);
           // this.showButtonsAllIncident = true;
            
           // this.dataTableData = tempDataList;
        }).catch(error => {
               
            console.log(JSON.stringify(error));
          
        }); 

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

    onNext = (e) => {
        console.log(e);
                 ++this.pageAllIncident;
                 
     }
     onPrev = (e) => {
            console.log(e);
             --this.pageAllIncident;
         
     }
     onPageClick = (e) => {
           
         
         //   alert(JSON.stringify(this.preSelectedRows));
            
             this.pageAllIncident = parseInt(e.target.label,10);
             
         
     }

     keycheck(event){
        if(event.which === 13){
            this.handleSearch(event);
        }
    } 

    //handlig search functionality on blur
   handleSearch(event){
    var searchString = event.target.value.toLowerCase();
    var tempList = [];
    var allIncidentsList = [];
    let tempRecord;
    var i;
    // At least 3 characters required for search
    if(event.target.value !== '' && event.target.value.length < 3){
        this.showToast('Please type at least 3 characters for search.','error','dismissable');
        return;
    }
    this.loadSpinner = true;
    
      
    
    
     if(event.target.value === ''){
         this.dataTableData = this.dataTableDataBackUpForSearch;
     }else{
         
         this.searchKeyAllIncidentsSection = event.target.value;
         
         allIncidentsList = this.dataTableDataBackUpForSearch;
         
         for(i=0;i<allIncidentsList.length;i++){
             tempRecord = Object.assign({}, allIncidentsList[i]); 
             if(tempRecord.MailerName.toLowerCase().includes(searchString) || tempRecord.MasterMailerName.toLowerCase().includes(searchString) || tempRecord.MailerNameText.toLowerCase().includes(searchString) || (tempRecord.AccountName !== '' && tempRecord.AccountName.toLowerCase().includes(searchString))){
            // if(tempRecord.MailerName.toLowerCase().includes(searchString) || tempRecord.MasterMailerName.toLowerCase().includes(searchString) || tempRecord.MailerNameText.toLowerCase().includes(searchString) ||  tempRecord.AccountName.toLowerCase().includes(searchString) ||  tempRecord.Subject.toLowerCase().includes(searchString) ){
             //if(tempRecord.Incident_ID.includes(this.searchKeyAllIncidentsSection) || tempRecord.Title.includes(this.searchKeyAllIncidentsSection) || tempRecord.Status.includes(this.searchKeyAllIncidentsSection) || tempRecord.Impact.includes(this.searchKeyAllIncidentsSection) || tempRecord.OwnerName.includes(this.searchKeyAllIncidentsSection) || tempRecord.Incident_Requested_By.includes(this.searchKeyAllIncidentsSection) || tempRecord.TIM.includes(this.searchKeyAllIncidentsSection)){
                 tempList.push(tempRecord); 
             }
         }    
        this.dataTableData = tempList;
        
         
     } 
     this.count = this.dataTableData.length;  
    
     this.setPagesAllIncident(this.dataTableData);
     this.pageAllIncident =1 ;
        
        
      
    

    this.loadSpinner = true;
    
}

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
/*getSelectedName(event){
   // this.preSelectedRows = [];
    const selectedRows = event.detail.selectedRows;
        // Display that fieldName of the selected rows
        for (let i = 0; i < selectedRows.length; i++) {
            this.preSelectedRows.push(selectedRows[i].Id);
           // alert('You selected: ' + selectedRows[i].opportunityName);
        }

       
    
}*/

handSendEmailConfirmation(){
    if(this.preSelectedRows.length === 0){
        this.showToast('No rows selected.','error','dismissable');

       
    }else{
    this.showConfirmPopup = true;
    }
}

handleCancelForConfirm(){
    this.showConfirmPopup = false; 
}

handleSendEmail(){
    if(this.preSelectedRows.length === 0){
        this.showToast('No rows selected.','error','dismissable');

       
    }
    else{
        sendEmail({recs:JSON.stringify(this.preSelectedRows)}) 
                .then(result => {console.log(result);
                    this.showToast('Emails are being sent for selected rows','Success','dismissable');

                    this[NavigationMixin.Navigate]({
                        type: 'standard__objectPage',
                        attributes: {
                            objectApiName: 'PS_Customer_Mailers__c',
                            actionName: 'list'
                        },
                        state: {
                            // 'filterName' is a property on 'state'
                            // and identifies the target list view.
                            // It may also be an 18 character list view id.
                            // or by 18 char '00BT0000002TONQMA4'
                            filterName:this.pendingMailerListViewId
                        }
                    });
                 //  window.location.reload();
                }).catch((error) => {
                    console.error("Error in create records", error);
                  //  this.dispatchEvent(new CloseActionScreenEvent());
                 //   window.location.reload();
                 //   this.showSpinner = false;
                });
    }
}

get getSendButtonTitle(){
    return 'Send Emails ('+this.preSelectedRows.length+')';
} 
    
}