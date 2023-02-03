import {
    LightningElement,
    wire,
    track
  } from 'lwc';
  import currentUserId from '@salesforce/user/Id';
  import { ShowToastEvent } from 'lightning/platformShowToastEvent';
  import getSuportTeamByEmployee from '@salesforce/apex/SC_STM_HomePageController.getSupportTeamByEmployeeList';
  import getSupportTeamDetails from '@salesforce/apex/SC_STM_HomePageController.getSupportTeams';
  import getAssociatedAccountDetails from '@salesforce/apex/SC_STM_HomePageController.getAssociatedAccounts';
  import saveSupportTeamSkill from '@salesforce/apex/SC_STM_HomePageController.saveSupportTeamSkill';
  import checkUserProfile from '@salesforce/apex/SC_STM_HomePageController.checkIsManager';
  
  export default class ScSTMEmpBubbles extends LightningElement {
  
    @track error;
    @track sortBy='UserUrl';
    @track sortDirection='asc';
    @track loadSpinner= true;
    @track supportTeamByEmployees = [];
    @track filteredList = [];
    @track searchEmployeeKey='';
    @track teamAndRole = [];  
    @track teamAccountList = [];  
    @track showSubTable = false;
    @track showTeamsTable = false;
    @track showEditPicklist = false;
    @track showAccountTable = false;
    @track selectedEmployee = '';
    @track selectedEmployeeName = '';
    @track selectedTeam = '';
    @track selectedTeamName = '';
    set_size = 5;
    @track pageMainTable = 1;
    perpage_MainTable = 14;
    @track pages = [];
    @track recordId;
    @track hideSave = true;
    @track toggleChecked = false;
    @track isManager = false;
    @track selectedSkills = [];
    @track skillsToSave = '';
    numberOfPages = '';

    serveroptions = [
      {label: 'Web Experience', value: 'Web Experience'},
      {label: 'Media', value: 'Media'},
      {label: 'Enterprise', value: 'Enterprise'},
    ];
    
    @track mainTableColumns = [
      {
        label: 'Login',
        fieldName: 'alias',
        type: 'cellEdit',
        typeAttributes: {
            context: { fieldName: 'UserID' },
            firstName: { fieldName: 'firstName' },
            lastName: { fieldName: 'lastName' },
            login: {fieldName: 'alias'}
        }
      },
      {
        label: 'First Name', fieldName: 'UserUrl', type: 'url',sortable: true,
        typeAttributes: { label: { fieldName: "firstName" }, target: "_blank"},cellAttributes : {class:'slds-theme_shade slds-theme_alert-texture'}
      }, 
      {
        label: 'Last Name',
        fieldName: 'lastName',sortable: true,
        type: 'text'
      },
      {
        label: 'Email',
        fieldName: 'email',
        type: 'email',
        cellAttributes : {class:'slds-theme_shade slds-theme_alert-texture'}
      },
      {
        label: 'Manager',
        fieldName: 'managerName',sortable: true,
        type: 'text'
      },
      {
        label: 'Office Location',
        fieldName: 'officeLocation',sortable: true,
        type: 'text',
        cellAttributes : {class:'slds-theme_shade slds-theme_alert-texture'}
        
      },
      {
        label: 'Owner Shift',
        fieldName: 'ownerShift',sortable: true,
        type: 'text'
      },
      {
        label: 'Support Team Skills',
        fieldName: 'supportTeamSkill',
        type: 'text',sortable: true,
        cellAttributes : {class:'slds-theme_shade slds-theme_alert-texture'}
      },
      {
        label: 'Account Assignments',
        fieldName: 'supportTeam_PrimaryCount',
        type: 'empBubbles',
        typeAttributes: {
          teamsPrimary: { fieldName: 'supportTeam_PrimaryCount' },
          teamsSecondary: { fieldName: 'supportTeam_SecondaryCount' },
          teamsOthers: { fieldName: 'supportTeam_OtherCount' },
          accountsPrimary: { fieldName: 'accountTeam_PrimaryCount' },
          accountsSecondary: { fieldName: 'accountTeam_SecondaryCount' }
        },
      initialWidth: 182 
      },
    ];
  
    @track subTableColumns = [
      {
        label: 'Team Name',
        fieldName: 'Support_Team_Name__c',
        type: 'cellEdit',
        typeAttributes: {
            context: { fieldName: 'TS_Support_Team__c' },
            team: { fieldName: 'Support_Team_Name__c' }
        }
      },
      {
        label: 'Team Type',
        fieldName: 'Support_Team_Type__c',
        type: 'text',
        cellAttributes : {class:'slds-theme_shade slds-theme_alert-texture'}
      },
      {
        label: 'Role',
        fieldName: 'Role__c',
        type: 'text'
      }
    ];

    @track mainTableColumnsManager = [
    {
      label: 'Login',
      fieldName: 'alias',
      type: 'cellEdit',
      typeAttributes: {
          context: { fieldName: 'UserID' },
          firstName: { fieldName: 'firstName' },
          lastName: { fieldName: 'lastName' },
          login: {fieldName: 'alias'}
      },
    },
    {label: 'First Name', fieldName: 'UserUrl', type: 'url',sortable: true,
      typeAttributes: { label: { fieldName: "firstName" }, target: "_blank"},cellAttributes : {class:'slds-theme_shade slds-theme_alert-texture'},
    },
    {
      label: 'Last Name',
      fieldName: 'lastName',sortable: true,
      type: 'text',
    },
    {
      label: 'Email',
      fieldName: 'email',
      type: 'email',
      cellAttributes : {class:'slds-theme_shade slds-theme_alert-texture'},
    },
    {
      label: 'Manager',
      fieldName: 'managerName',sortable: true,
      type: 'text',
    },
    {
      label: 'Office Location',
      fieldName: 'officeLocation',sortable: true,
      type: 'text',
      cellAttributes : {class:'slds-theme_shade slds-theme_alert-texture'},
    },
    {
      label: 'Owner Shift',
      fieldName: 'ownerShift',sortable: true,
      type: 'text',
    },
    {
      label: 'Support Team Skills',
      fieldName: 'supportTeamSkill',
      type: 'cellEdit',
      cellAttributes : {class:'slds-theme_shade slds-theme_alert-texture'},
      typeAttributes: {
          supportTeamSkill: { fieldName: 'supportTeamSkill' },
          context: { fieldName: 'UserID' },
          firstName: { fieldName: 'firstName' },
          lastName: { fieldName: 'lastName' }
      },
    },
    {
      label: 'Account Assignments',
      fieldName: 'supportTeam_PrimaryCount',
      type: 'empBubbles',
      typeAttributes: {
        teamsPrimary: { fieldName: 'supportTeam_PrimaryCount' },
        teamsSecondary: { fieldName: 'supportTeam_SecondaryCount' },
        teamsOthers: { fieldName: 'supportTeam_OtherCount' },
        accountsPrimary: { fieldName: 'accountTeam_PrimaryCount' },
        accountsSecondary: { fieldName: 'accountTeam_SecondaryCount' }
      },
      initialWidth: 182
    },
  ];

    @track accountTableColumns = [
      {label: 'Account', fieldName: 'Team_Account_URL__c', type: 'url',
      typeAttributes: { label: { fieldName: "Team_Account_Name__c" }, target: "_blank"}},
      {
        label: 'ERC',
        fieldName: 'Team_Account_ERC__c',
        type: 'text',
        cellAttributes : {class:'slds-theme_shade slds-theme_alert-texture'},
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
            style1.innerText = `c-sc-s-t-m-emp-bubbles .expander .slds-button{
                width:10px;
                height:755px;
                font-size:24px;
            }`;
            this.template.querySelector('lightning-button').appendChild(style1);
        }

        const searchBoxStyle = document.createElement('style');
        searchBoxStyle.innerText = `c-sc-s-t-m-emp-bubbles .searchText .slds-input{
                margin-top:-12px;
            }`;
            this.template.querySelector('lightning-input').appendChild(searchBoxStyle);

            const dataTableFontStyle = document.createElement('style');
            dataTableFontStyle.innerText = `c-sc-s-t-m-emp-bubbles .slds-table{
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
      this.searchEmployeeKey = '';
      //this.supportTeamByEmployees = [];
      //this.filteredList = [];
      this.pageMainTable = 1;
      this.pages = [];
      this.handleExpansion();
      this.toggleChecked ? this.getManagerData() : this.getMainTableData();
     // this.pageMainTable = 1;
      //this.loadSpinner = false;
      
    }
    
    getMainTableData() {
        this.loadSpinner = true;
        console.log("In Main table: Manager ID: " + currentUserId);
      getSuportTeamByEmployee( {ManagerId: currentUserId} )
        .then(result => {
          this.error = undefined;
          result = JSON.parse(result);
          //console.log(JSON.stringify(result));
          // result.employees.forEach(resultRec => {

          //     resultRec.UserUrl = '/' + resultRec.UserID;
            
          // });
          this.isManager = result.isManager;
          this.supportTeamByEmployees = result.employees;

          if(this.searchEmployeeKey != "" && this.searchEmployeeKey != null && this.searchEmployeeKey != undefined){
            this.searchData(this.supportTeamByEmployees,false);
          } else{
            this.filteredList = result.employees;
            console.log('maintabledata length' + this.filteredList.length);
            this.sortData('firstName', 'asc');
            this.setPages(this.filteredList, 'mainTable');
          }
          this.loadSpinner = false;
  
        })
        .catch(error => {
          this.error = error;
          console.log(this.error);
          this.supportTeamByEmployees = undefined;
           this.loadSpinner = false;
        });
    }
  
    handleRowAction(event) {
      this.teamAccountList = [];
      this.showAccountTable = false;
      this.showEditPicklist = false;
      let row = event.detail.row;
      this.selectedEmployee = row.UserID;
      this.selectedEmployeeName = row.firstName + ' '+row.lastName;
      getSupportTeamDetails({
          userId: this.selectedEmployee
        })
        .then(result => {
  
          this.error = undefined;
          result = JSON.parse(result);
          console.log(JSON.stringify(result));
          this.teamAndRole = result;
          
          this.handleShowTeams();
          this.showTeamsTable = true;
        })
        .catch(error => {
  
          this.error = error;
          this.teamAndRole = [];
  
        });
    }
    
    handleRowActionForTeamTable(event){
      this.teamAccountList = [];
      
      let row = event.detail.row;
      this.selectedTeam = row.TS_Support_Team__c;
      this.selectedTeamName = row.teamName;
      getAssociatedAccountDetails({
        teamId: this.selectedTeam
      })
      .then(result => {
        this.showAccountTable = true;
        this.error = undefined;
        result = JSON.parse(result);
        console.log(JSON.stringify(result));
        this.teamAccountList = result;
      })
      .catch(error => {

        this.error = error;
        this.teamAccountList = [];

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
      this.showAccountTable = false;
      this.showEditPicklist = false;
      var divblock = this.template.querySelector('[data-id="mainTableDiv"]');
      if (divblock) {
        this.template.querySelector('[data-id="mainTableDiv"]').className = '';
      }
      this.teamAndRole = [];
      this.teamAccountList = [];
      this.selectedEmployee = '';
      this.selectedEmployeeName = '';
      this.selectedTeam = '';
      this.selectedTeamname ='';

  
    }

    handleSearch(event){
        // At least 3 characters required for search
        if(event.target.value != '' && event.target.value.length < 3){
            this.showToast('Please type at least 3 characters for search.','error','dismissable');
            return;
        }
         if(event.target.name=='searchEmployee'){
            
            this.searchEmployeeKey = event.target.value;
            
        }
        this.searchData(this.supportTeamByEmployees, true);

      }

      searchData(allEmployeeData, resetPages){
        this.filteredList = [];
        if(this.searchEmployeeKey != "" && this.searchEmployeeKey != null && this.searchEmployeeKey != undefined){
            var i=0;
            for(var i=0;i<allEmployeeData.length;i++){
              if(allEmployeeData[i].alias.toLowerCase().includes(this.searchEmployeeKey.toLowerCase()) || allEmployeeData[i].firstName.toLowerCase().includes(this.searchEmployeeKey.toLowerCase()) ||  allEmployeeData[i].lastName.toLowerCase().includes(this.searchEmployeeKey.toLowerCase()) ||  (allEmployeeData[i].firstName.toLowerCase() + ' ' + allEmployeeData[i].lastName.toLowerCase()).includes(this.searchEmployeeKey.toLowerCase()) ||  allEmployeeData[i].managerName.toLowerCase().includes(this.searchEmployeeKey.toLowerCase())){
                    
                    this.filteredList.push(allEmployeeData[i]);
                    console.log('list**'+JSON.stringify(this.filteredList));
                }
            }
        }else{
            this.sortData('firstName', 'asc');
            this.filteredList = allEmployeeData; 
        }
        if(this.filteredList.length > 0){
            this.sortData('firstName', 'asc');
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
        let fieldName = event.detail.fieldName == 'UserUrl' ? 'firstName' : event.detail.fieldName;
       
        let sortDirection = event.detail.sortDirection;
        
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


    handleShowDetails(event){
      this.teamAccountList = [];
      this.showAccountTable = false;
      this.showEditPicklist = false;
      let dataRecieved = event.detail.data;
      console.log(JSON.stringify(dataRecieved));
      this.selectedEmployee = dataRecieved.recordId

      this.selectedEmployeeName = dataRecieved.FirstName + ' ' +dataRecieved.LastName;
      getSupportTeamDetails({
          userId: this.selectedEmployee
        })
        .then(result => {
  
          this.error = undefined;
          result = JSON.parse(result);
          console.log(JSON.stringify(result));
          this.teamAndRole = result;
          
          this.handleShowTeams();
          this.showTeamsTable = true;
        })
        .catch(error => {
  
          this.error = error;
          this.teamAndRole = [];
  
        });
    }

    handleShowAccountDetails(event){
      this.teamAccountList = [];
      
      let dataRecieved = event.detail.data;
      this.selectedTeam = dataRecieved.recordId;
      this.selectedTeamName = dataRecieved.TeamName;
      getAssociatedAccountDetails({
        teamId: this.selectedTeam
      })
      .then(result => {
        this.showAccountTable = true;
        this.error = undefined;
        result = JSON.parse(result);
        console.log(JSON.stringify(result));
        this.teamAccountList = result;
      })
      .catch(error => {

        this.error = error;
        this.teamAccountList = [];

      });

    }
    
    handleSkillChange(event){
      this.skillsToSave = event.detail.value;
      this.hideSave = false;
    }
    
    handleEditSkill(event){
      this.showTeamsTable = false;
      this.showAccountTable = false;
      event.stopPropagation();
      let dataRecieved = event.detail.data;
      console.log(JSON.stringify(dataRecieved));
      this.recordId = dataRecieved.recordId;
      console.log(this.recordId);
      this.hideSave = true;
      this.selectedSkills = [];
      this.selectedEmployeeName = dataRecieved.FirstName + ' '+dataRecieved.LastName;
      if(dataRecieved.SupportTeamSkill){
          dataRecieved.SupportTeamSkill.split(";").forEach(skill => {
            console.log('in loop skill' + skill);
            this.selectedSkills.push(skill);
          });
          console.log('end edit' + JSON.stringify(this.selectedSkills));
      }
      //this.picklistOptions = options;

      this.handleShowTeams();
      this.showEditPicklist = true;
  }

  handleSave(){
    var skillsToSave = this.skillsToSave.join(";");
    console.log("save" + skillsToSave);
    this.loadSpinner = true;
    saveSupportTeamSkill({
        UserId: this.recordId,
        skills: skillsToSave,
    }).then(result => {
        if(result === 'success'){
            this.loadSpinner = false;
            this.showToast('Support Team Skill updated Successfully!', 'success', 'dismissable');
            this.supportTeamByEmployees.find(emp => emp.UserID === this.recordId).supportTeamSkill = skillsToSave;
            this.hideSave=true;
            this.toggleChecked ? this.getManagerData() : this.getMainTableData();
            //this.currentSkillValue = updatedValues;
        }
        else{
            this.showToast(result, 'error', 'dismissable');
        }
    }).catch(error => {
        this.loadSpinner = false;
        console.log(JSON.stringify(error));
    });
    //this.handleExpansion();
}


getManagerData(){
  console.log("In Manager");
  this.loadSpinner = true;
  setTimeout(() => {
    this.loadSpinner = false;
  }, 400);
  this.filteredList = [];
  let managerReportees = Object.assign([], this.supportTeamByEmployees);
  //console.log(JSON.stringify(managerReportees));
  managerReportees.forEach(rep => {
    //console.log(JSON.stringify(rep));
    this.filteredList = rep.ManagerId == currentUserId ? [...this.filteredList, JSON.parse(JSON.stringify(rep))] : this.filteredList;
  })
  this.supportTeamByEmployees = this.filteredList;

  if(this.searchEmployeeKey != "" && this.searchEmployeeKey != null && this.searchEmployeeKey != undefined){
    this.searchData(this.supportTeamByEmployees,false)
  }
  else{
    this.sortData('firstName', 'asc');
    this.setPages(this.filteredList, 'mainTable');
  }
}

changeToggle(event){
  //this.loadSpinner = true;
  this.toggleChecked = !this.toggleChecked;
  this.searchEmployeeKey = '';
  // this.filteredList = [];
  this.pageMainTable = 1;
  this.pages = [];
  this.handleExpansion();
  this.toggleChecked ? this.getManagerData() : this.getMainTableData();
    //this.getMainTableData(currentUserId);
  //this.loadSpinner=false;
}

checkProfile(){
  checkUserProfile({
    UserId: currentUserId
  }).then(result => {
    console.log("Result: " + result);
    if(result === 'Manager'){
      this.isManager = true;
    }
    else{
      this.isManager = false;
    }
  }).catch(error => {
    console.log(JSON.stringify(error));
  })
}

keycheck(event){
  if(event.which == 13){
      this.handleSearch(event);
  }
}  
}