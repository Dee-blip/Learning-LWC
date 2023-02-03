import {
    LightningElement,
    wire,
    track
  } from 'lwc';
  import { ShowToastEvent } from 'lightning/platformShowToastEvent';
  import getSupportTeamsList from '@salesforce/apex/SC_STM_HomePageController.getSupportTeamsHome';
  import getSupportTeamDetails from '@salesforce/apex/SC_STM_HomePageController.getSupportTeamAccountsAndMembersHome';
  import deleteSelectedRecord from '@salesforce/apex/SC_STM_HomePageController.deleteSelectedRecord';
  import getModalDetails from '@salesforce/apex/SC_STM_HomePageController.getModalDetails';
  import { NavigationMixin } from 'lightning/navigation';

  const actionCol =  {
    type: 'action',
    typeAttributes: {
        rowActions: [
            { 
                label: 'Edit',
                name: 'Edit'
            },
            {
                label: 'Delete',
                name: 'Delete'
            }
        ]
        
    }
  }

  const actionColDel =  {
    type: 'action',
    typeAttributes: {
        rowActions: [
            {
                label: 'Delete',
                name: 'Delete'
            }
        ] 
    }
  }

  export default class ScSTMSupportTeams extends NavigationMixin(LightningElement) {
  
    @track error;
    @track sortBy='teamName';
    @track sortDirection='asc';
    @track loadSpinner= true;
    @track supportTeams = [];
    @track filteredList = [];
    @track searchTeamKey='';
    @track teamAndRole = [];  
    @track teamAccountList = [];
    @track teamMembersList = [];
    @track showSubTable = false;
    @track selectedTeam = '';
    @track selectedTeamName = '';
    set_size = 5;
    @track pageMainTable = 1;
    perpage_MainTable = 15;
    @track pages = [];
    @track recordId = '';
    @track isDeleteModalOpen = false;
    @track isCrEditModalOpen = false;
    @track isModalOpen = false;
    @track selectedObject = '';
    @track modalMessage = '';
    @track objectLabel = '';
    @track sections = [];
    @track isManager = false;
    numberOfPages = '';
    deleteId = '';

    @track mainTableColumns = [
      {
        label: 'Team Name',
        fieldName: 'teamName',
        type: 'cellEdit',
        typeAttributes: {
            context: { fieldName: 'Id' },
            team: { fieldName: 'teamName' }
        }
      },
      {
          label: 'Team Type',
          fieldName: 'teamType',
          type: 'text',
          sortable: true,
          cellAttributes : {class:'slds-theme_shade slds-theme_alert-texture'}
      },
      {
          label: '# Accounts',
          fieldName: 'noAccounts',
          type: 'text'
      },
    ];

  @track memberTableColumns = [
      {
          label: 'Alias',
          fieldName: 'Team_Member_Alias__c',
          type: 'text'
      },
      {
          label: 'Team Member',
          fieldName: 'Team_Member_URL__c',
          type: 'url',
          typeAttributes: {
              label: { fieldName: 'Team_Member_Name__c' },
              target: "_blank"
          },
          cellAttributes : {class:'slds-theme_shade slds-theme_alert-texture'}
      },
      {
          label: 'Role',
          fieldName: 'Role__c',
          type: 'text'
      },
      {
          label: 'Support Team Skill',
          fieldName: 'SC_STM_Support_Team_Skill__c',
          type: 'text',
          cellAttributes : {class:'slds-theme_shade slds-theme_alert-texture'}
      },
  ];
  @track accountTableColumns = [
      {
          label: 'Team Account',
          fieldName: 'Team_Account_URL__c',
          type: 'url',
          typeAttributes: {
              label: { fieldName: 'Team_Account_Name__c' },
              target: "_blank"
          },
          initialWidth: 300
      },
      {
          label: 'Account ERC',
          fieldName: 'Team_Account_ERC__c',
          type: 'text',
          cellAttributes : {class:'slds-theme_shade slds-theme_alert-texture'}
      },
      {
          label: 'AKAM Account ID',
          fieldName: 'Team_AKAM_Account_ID__c',
          type: 'text'
      },
      {
          label: 'Support Level',
          fieldName: 'Team_Account_Support_Level__c',
          type: 'text',
          cellAttributes : {class:'slds-theme_shade slds-theme_alert-texture'}
      },
      {
          label: 'Customer Tier',
          fieldName: 'Team_Account_Customer_Tier__c',
          type: 'text'
      },
      {
          label: 'Geography',
          fieldName: 'Team_Account_Geography__c',
          type: 'text',
          cellAttributes : {class:'slds-theme_shade slds-theme_alert-texture'}
      },
  ];
  
    constructor() {
      super();
      // this.loadSpinner = true;
      this.getMainTableData();
    }

    renderedCallback(){
      

        if(this.showSubTable){
            const style1 = document.createElement('style');
            style1.innerText = `c-sc-s-t-m-support-teams .expander .slds-button{
                width:10px;
                height:755px;
                font-size:24px;
            }`;
            this.template.querySelector('lightning-button').appendChild(style1);

            
        }

        const searchBoxStyle = document.createElement('style');
        searchBoxStyle.innerText = `c-sc-s-t-m-support-teams .searchText .slds-input{
                margin-top:-12px;
            }`;
            this.template.querySelector('lightning-input').appendChild(searchBoxStyle);

            const dataTableFontStyle = document.createElement('style');
            dataTableFontStyle.innerText = `c-sc-s-t-m-support-teams .slds-table{
           font-size:15px;
           
           
        }`;
    }
  
    get pagesList() {
      let mid = Math.floor(this.set_size / 2) + 1;
      if (this.pageMainTable > mid) {
        return this.pages.slice(this.pageMainTable - mid, this.pageMainTable + mid - 1);
      }
      return this.pages.slice(0, this.set_size);
    }
  
  
  
    get arePagesMoreThanOneMainTable() {
      return this.pages.length > 1 ? true : false;
    }
  
    get currentPageData() {
        return this.pageData();
    }
  
    pageData = () => {
      let page = this.pageMainTable;
      let perpage = this.perpage_MainTable;
      let startIndex = (page * perpage) - perpage;
      let endIndex = (page * perpage);
      return this.filteredList.slice(startIndex, endIndex);
    }
  
    setPages = (data, source) => {
      this.pages = [];
      let numberOfPages = Math.ceil(data.length / this.perpage_MainTable);
      console.log(numberOfPages);
      this.numberOfPages = numberOfPages;
      for (let index = 1; index <= numberOfPages; index++) {
        if (source == 'mainTable') {
          this.pages.push(index);
        }
      }
    }
  
    get hasPrev() {
      return this.pageMainTable > 1;
    }
  
    get hasNext() {
      return this.pageMainTable < this.pages.length;
    }

    onFirst = (e) => {
        if(e.target.name == 'firstMainTable'){
            this.pageMainTable = 1;
        }
    }

    onLast = (e) => {
        if(e.target.name == 'lastMainTable'){
            this.pageMainTable = this.numberOfPages;
        }
    }
  
    onNext = (e) => {
      if (e.target.name == 'nextMainTable') {
        ++this.pageMainTable;
      }
  
    }
    onPrev = (e) => {
      if (e.target.name == 'prevMainTable') {
        --this.pageMainTable;
      }
    }

    onPageClick = (e) => {
      if (e.target.name == 'mainTablePageButton') {
        this.pageMainTable = parseInt(e.target.label, 10);
      }
    }

    refresh(){
      //this.loadSpinner = true;
      this.searchTeamKey = '';
      this.supportTeams = [];
      this.filteredList = [];
      this.pageMainTable = 1;
      this.pages = [];
      this.handleExpansion();
      this.getMainTableData();
     // this.pageMainTable = 1;
      //this.loadSpinner = false;
      
    }
    
    getMainTableData() {
        this.loadSpinner = true;
        getSupportTeamsList()
        .then(result => {
          this.error = undefined;
  
          result = JSON.parse(result);
          console.log(JSON.stringify(result));
          console.log('result manager' + result.isManager);
          this.isManager = result.isManager;
          if(this.isManager){
              if(!(this.mainTableColumns.some(col => col.type === 'action'))){
                this.mainTableColumns = [...this.mainTableColumns, actionCol];
                this.accountTableColumns = [...this.accountTableColumns, actionColDel]
                this.memberTableColumns = [...this.memberTableColumns, actionCol]
              }
              console.log(JSON.stringify(this.memberTableColumns));
          }
          this.supportTeams = result.teams;

          if(this.searchTeamKey != "" && this.searchTeamKey != null && this.searchTeamKey != undefined){
              this.searchData(this.supportTeams,false);
          } else{
            this.filteredList = result.teams;
            console.log('maintabledata length' + this.filteredList.length);
            this.sortData('teamName', 'asc');
            this.setPages(this.filteredList, 'mainTable');
          }
          this.loadSpinner = false;
  
        })
        .catch(error => {
            console.log(error);
          this.error = error;
          this.supportTeams = undefined;
           this.loadSpinner = false;
        });
    }
  
    handleRowAction(event) {
      let action = event.detail.action.name;  
      let row = event.detail.row;
      switch (action) {
          case 'Edit':
                this.selectedObject = 'TS_Support_Team__c';
                this.recordId = row.Id;
                this.modalMessage = 'Edit Support Team';
                this.objectLabel = 'Support Team';
                this.getModalDetails();
              break;
          case 'Delete':
                this.modalMessage = 'Delete Support Team';
                this.objectLabel = 'Support Team';
                this.deleteId = row.Id;
                this.selectedObject = 'TS_Support_Team__c';
                this.isModalOpen = true;
                this.isDeleteModalOpen = true;
              break;
          default:
                this.selectedTeam = row.Id;
                this.selectedTeamName = row.teamName;
                this.getDetailsForTeam();
              break;
      }  
    }

    handleShowTeamDetails(event){
        let dataRecieved = event.detail.data;
        this.selectedTeam = dataRecieved.recordId;
        this.selectedTeamName = dataRecieved.TeamName;
        this.getDetailsForTeam();
    }

    getDetailsForTeam(){
        getSupportTeamDetails({
            teamId: this.selectedTeam
            })
            .then(result => {
    
            this.error = undefined;
            result = JSON.parse(result);
            console.log(JSON.stringify(result));
            this.teamAccountList = result.accounts;
            this.teamMembersList = result.members;
            this.handleShowTeams();
            
            })
            .catch(error => {
    
            this.error = error;
            this.teamAccountList = [];
            this.teamMembersList = [];
    
            });
    }
    
    handleAccountRowAction(event){
        let action = event.detail.action.name;
        let row = event.detail.row;
        switch (action) {
            case 'Delete':
                  this.modalMessage = 'Delete Support Team Account';
                  this.objectLabel = 'Support Team Account';
                  this.deleteId = row.Id;
                  this.selectedObject = 'TS_TeamAccount__c';
                  this.isModalOpen = true;
                  this.isDeleteModalOpen = true;
                break;
            default:
        }
    }

    handleMemberRowAction(event){
        let action = event.detail.action.name;
        let row = event.detail.row;
        switch (action) {
            case 'Edit':
                this.selectedObject = 'TS_TeamMember__c';
                this.recordId = row.Id;
                this.modalMessage = 'Edit Support Team Member';
                this.objectLabel = 'Support Team Member';
                this.getModalDetails();
                break;
            case 'Delete':
                  this.modalMessage = 'Delete Support Team Member';
                  this.objectLabel = 'Support Team Member';
                  this.deleteId = row.Id;
                  this.selectedObject = 'TS_TeamMember__c';
                  this.isModalOpen = true;
                  this.isDeleteModalOpen = true;
                break;
            default:
        } 
    }

    deleteRecord(Id){
        this.loadSpinner = true;
        deleteSelectedRecord({
            recordId: Id
        }).then(result => {
            this.loadSpinner = false
            if(result === 'success'){
                this.showToast(this.objectLabel + ' deleted Successfully!', 'success', 'dismissable');
                this.getMainTableData();
                if(this.selectedObject == 'TS_Support_Team__c' && this.selectedTeam == Id){
                    this.handleExpansion();
                }
                this.getDetailsForTeam();
            }
            else{
                this.showToast(result, 'error', 'dismissable');
            }
        }).catch(error => {
            this.loadSpinner = false;
            console.log(JSON.stringify(error));
        });
    }
    
    handleShowTeams() {
      var divblock = this.template.querySelector('[data-id="mainTableDiv"]');
      if (divblock) {
       this.template.querySelector('[data-id="mainTableDiv"]').className = 'reducedWidth1';
        this.showSubTable = true;
      }
    }
  
    handleExpansion() {
      this.showSubTable = false;
      var divblock = this.template.querySelector('[data-id="mainTableDiv"]');
      if (divblock) {
        this.template.querySelector('[data-id="mainTableDiv"]').className = '';
      }
      this.teamAndRole = [];
      this.teamAccountList = [];
      this.selectedTeam = '';
      this.selectedTeamname ='';

  
    }

    handleSearch(event){
        // At least 3 characters required for search
        if(event.target.value != '' && event.target.value.length < 3){
            this.showToast('Please type at least 3 characters for search.','error','dismissable');
            return;
        }
         if(event.target.name=='searchTeam'){
            
            this.searchTeamKey = event.target.value;
            console.log('key' + this.searchTeamKey);
        }
        this.searchData(this.supportTeams,true);
    }


    searchData(allTeamsData, resetPages){
        this.filteredList = [];
        if(this.searchTeamKey != "" && this.searchTeamKey != null && this.searchTeamKey != undefined){
            console.log('searchdata length' + allTeamsData.length);
            console.log('key' + this.searchTeamKey);
            for(var i=0;i<allTeamsData.length;i++){
                if(allTeamsData[i].teamName.toLowerCase().includes(this.searchTeamKey.toLowerCase()) || allTeamsData[i].teamType.toLowerCase().includes(this.searchTeamKey.toLowerCase())){
                    this.filteredList.push(allTeamsData[i]);
                }
                
            }
        }else{
            this.sortData('teamName','asc');
            this.filteredList = allTeamsData; 
        }
        if(this.filteredList.length > 0){
            this.sortData('teamName','asc');
            this.setPages(this.filteredList,"mainTable");
        }else{
            this.setPages(this.filteredList,"mainTable")
        }
        if(resetPages){
            this.pageMainTable = 1;
        }
    }

     // Handling toasts
     showToast(message,variant,mode) {
        const evt = new ShowToastEvent({
            
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }

     updateColumnSorting(event){
        this.loadSpinner = true;
        let fieldName = event.detail.fieldName;
        if(fieldName == 'createdByUrl'){
            fieldName = 'createdBy';
        }
        else if(fieldName == 'modifiedByUrl'){
            fieldName = 'modifiedBy';
        }
        if(fieldName == undefined){
            fieldName = 'teamName';
        }
        console.log('sort field ' + event.detail.fieldName);
        let sortDirection = event.detail.sortDirection;
        console.log('direction ' + sortDirection);
        //assign the values
        this.sortBy = fieldName;
        this.sortDirection = sortDirection;
        //call the custom sort method.
        this.sortData(fieldName, sortDirection);
        this.sortBy = event.detail.fieldName;
        this.loadSpinner = false;
    } 

    sortData(fieldName, sortDirection) {
        let sortResult;
            
            sortResult = Object.assign([], this.filteredList);
            this.filteredList = sortResult.sort(function(a,b){
                if(a[fieldName] < b[fieldName])
                return sortDirection === 'asc' ? -1 : 1;
                else if(a[fieldName] > b[fieldName])
                return sortDirection === 'asc' ? 1 : -1;
                else
                return 0;
            })    
    }

    get paginationButtonClass(){
     return 'slds-button slds-button_neutral';
    }



handleNewTeam(){    
    this.modalMessage = 'Create Support Team';
    this.objectLabel = 'Support Team';
    this.selectedObject = 'TS_Support_Team__c';
    this.recordId = '';
    this.getModalDetails();
}

handleSuccess(event){
    if(this.modalMessage.includes('Create')){
        this.showToast(this.objectLabel + ' created Successfully!', 'success', 'dismissable');
    }
    else{
        this.showToast(this.objectLabel + ' Edited Successfully!', 'success', 'dismissable');
    }
    this.isDeleteModalOpen = false;
    this.isModalOpen = false;
    this.isCrEditModalOpen = false;
    this.getMainTableData();
    this.getDetailsForTeam();
    if(this.selectedObject == 'TS_Support_Team__c' && this.modalMessage.includes('Create')){
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: event.detail.id,
                    objectApiName: 'TS_Support_Team__c',
                    actionName: 'view'
                },
            });
        
    }
}

handleError(event){
    console.log(event.detail.detail);
    console.log(event.detail.output);
    console.log(event.detail.output.fieldErrors);
    console.log(event.detail.output.errors);
    this.showToast(event.detail.detail, 'error', 'dismissable');
    this.isDeleteModalOpen = false;
    this.isModalOpen = false;
    this.isCrEditModalOpen = false;
}

handleNewAccount(){
    this.modalMessage = 'Create Support Team Account';
    this.objectLabel = 'Support Team Account';
    this.selectedObject = 'TS_TeamAccount__c';
    this.recordId = '';
    this.getModalDetails();
}


handleNewMember(){
    this.modalMessage = 'Create Support Team Member';
    this.objectLabel = 'Support Team Member';
    this.selectedObject = 'TS_TeamMember__c';
    this.recordId = '';
    this.getModalDetails();
}


closeModal(){
    this.isDeleteModalOpen = false;
    this.isModalOpen = false;
    this.isCrEditModalOpen = false;
}

confirmDelete(){
    console.log(this.deleteId);
    console.log(this.selectedObject);
    this.deleteRecord(this.deleteId);
    this.isDeleteModalOpen = false;
    this.isModalOpen = false;
    this.isCrEditModalOpen = false;
}

getModalDetails(){
    getModalDetails({
        objName: this.selectedObject
    })
    .then(result => {
        this.error = undefined;
        result = JSON.parse(result);
        this.sections = result;
        console.log(JSON.stringify(this.sections));
        this.isModalOpen = true;
        this.isCrEditModalOpen = true;
    })
    .catch(error => {
        console.log(error);
        this.error = error;
    })
}

get modalClass(){
    return this.isDeleteModalOpen ? 'slds-modal slds-fade-in-open' : 'slds-modal slds-fade-in-open slds-modal_small';
}

keycheck(event){
  if(event.which == 13){
      this.handleSearch(event);
  }
} 

}