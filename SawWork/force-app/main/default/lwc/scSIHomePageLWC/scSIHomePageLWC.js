import { LightningElement, wire,track } from 'lwc';
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';



import updateOwner from '@salesforce/apex/SC_SI_HomePageControllor.updateOwner';

import getDataForFirstLoad from '@salesforce/apex/SC_SI_HomePageControllor.getHomePageData';
import getFilterData from '@salesforce/apex/SC_SI_HomePageControllor.getFilterData';
import saveFilterData from '@salesforce/apex/SC_SI_HomePageControllor.saveFilterData';
import { NavigationMixin } from 'lightning/navigation';
import USER_ID from '@salesforce/user/Id';
 
import NAME_FIELD from '@salesforce/schema/User.SC_SI_IRAPT_User__c';
import TooltipJS from '@salesforce/resourceUrl/TooltipJS';





export default class ScSIHomePageLWC extends NavigationMixin(LightningElement) {
   // channelName = '/event/ServiceIncidentEvent__e';
   channelName = '/data/SC_SI_Service_Incident__ChangeEvent';
   subscription = {};

   @track activeSectionDefault = ["myOpenIncidents","incidentsInQueue"];
   @track titlePopUpValue = '';
   @track showTitlePopUp = false;

   /*************** Variables used for pagination**********/
   @track pageMyIncident = 1;
   @track pageQueue = 1;
   @track pageAllIncident = 1;
   perpage_myIncident = 5;
   perpage = 10;
   @track pages = [];
   @track pagesQueue = [];
   @track pagesAllIncident = [];
   set_size = 5;
   @track showDataTableQueue = false;
   @track showButtons = false;
   @track showDataTableAllIncident = false;
   @track showButtonsAllIncident = false;


   @track isIRAPTUser;
   @track loadSpinner= false;
   @track openAssignPopUp = false;
   @track openNotesPopUp = false;
   @track toBeAssignedId = '';
   @track suggestedBIL = '';
   @track notes = '';
  

   /*************My Incident Section Variables */
   @track myIncidentSectionExpanded = false;
   @track myIncidents =[];
   @track myIncidentsBackUpForSearch =[];
   @track error;
   @track sortBy='SI_recordLink';
   @track sortDirection='desc';
   @track noOfMyIncidentsLabel = 'My Open Incidents';
   @track searchKeyMyIncidentsSection = '';
   @track statusvalueMyIncident = [];
   @track impactvalueMyIncident = [];
   @track StatusoptionsMyIncident = [];
   @track ImpactoptionsMyIncident = [];
   
   
  

    /**************Incident Queue section variables********** */
    @track queueSectionExpanded = false;
    @track allIncidentsInQueue = [];
    @track allIncidentsInQueueBackUpForSearch = [];
    @track sortByQueueSection='SI_recordLink';
    @track sortDirectionQueueSection='desc';
    @track noOfQueueIncidentsLabel = ' Incidents In Queue';
    @track searchKeyQueueSection = '';
    @track statusvalueQueue = [];
    @track impactvalueQueue = [];
    @track StatusoptionsQueue = [];
    @track ImpactoptionsQueue = [];
    @track queueOptions = [];
    @track queuevalueQueue = [];
        // JSON variables to be used for saving filters in queue sections
    @track statusBackUpForJSON;
    @track impactBackUpForJSON;
    @track queueBackUpForJSON;
   
    

   /**************All Incident section variables********** */
   @track allIncidentSectionExpanded = false;
   @track allIncidents= [];
   @track allIncidentsBackUpForSearch= [];
   @track sortByAllIncidentsSection='SI_recordLink';
   @track sortDirectionAllIncidentsSection='asc';
   @track noOfAllIncidentsLabel = ' All Open Incidents';
   @track searchKeyAllIncidentsSection = '';
   @track statusvalueAllIncident = [];
   @track impactvalueAllIncident = [];
   @track StatusoptionsAllIncident = [];
   @track ImpactoptionsAllIncident = [];
   

   // Columns for My Incidents Section
   @track columns = [
       {
           type: 'button-icon',    
           typeAttributes: {
               iconName: 'utility:edit',
               name: 'edit', 
               title: 'Edit',
               variant: 'container',
               
               alternativeText: 'Edit',
               disabled: {fieldName:'hideEditAccess'}
           },
           initialWidth: 5
           
       },
       {label: 'Incident ID', fieldName: 'SI_recordLink', type: 'url',sortable: true,initialWidth: 120,
       typeAttributes: { label: { fieldName: "Incident_ID" }, target: "_blank"},cellAttributes : {class:'slds-m-left_small slds-m-top_small'}},
       {label: 'Title',fieldName: 'Title', type: 'cellEdit',typeAttributes: {
        title: { fieldName: 'Title' }
        },initialWidth:265,cellAttributes : {class:'slds-theme_shade slds-theme_alert-texture'}},
       {label: 'Status', fieldName: 'Status', type: 'text',initialWidth: 150},
       {label: 'Severity', fieldName: 'Impact', type: 'text',initialWidth: 105,cellAttributes : {class:{fieldName: 'ImpactClass'}}},
       {label: 'Owner', fieldName: 'OwnerName', type: 'text'},
       {label: 'Incident Requested By', fieldName: 'Incident_Requested_By', type: 'text',cellAttributes : {class:'slds-theme_shade slds-theme_alert-texture'}},
       {label: 'TIM', fieldName: 'TIM', type: 'text'},
       {label: 'Created Date', fieldName: 'CreatedDate_Text', type: 'text',sortable: true,cellAttributes : {class:'slds-theme_shade slds-theme_alert-texture'}}
    ];

   // Columns for Incidents in Queue Section for logged-in user IRAPT
   @track columnsQueueSection = [

      
       {label: 'Incident ID', fieldName: 'SI_recordLink', type: 'url',sortable: true,initialWidth: 120,
       typeAttributes: { label: { fieldName: "Incident_ID" }, target: "_blank"},cellAttributes : {class:'slds-m-left_small slds-m-top_small'}},
       {   label:'Transition Flag',
           type: 'button-icon',    
           typeAttributes: {
               iconName: 'utility:priority',
               name: 'Notes', 
               title: 'Notes',
               class:{fieldName: 'transitionFlagVisible'},
               variant: 'container',
               alternativeText: 'Edit',
           },
           initialWidth: 5,
           initialHeight:10
       }, 
       
       {
           label: 'Assign', 
           fieldName:"hand",
           type: 'button',
           fixedWidth: 65, 
           variant: 'container',
           typeAttributes: 
           {
               name: 'Assign',
               label: '✋🏼',
               variant: 'base',
               title: 'Assign',
               alternativeText: 'Assign'
           },
           cellAttributes:{class:'hand slds-align_absolute-center'}
       },
       {label: 'Title', fieldName: 'Title', type: 'cellEdit',typeAttributes: {
        
        title: { fieldName: 'Title' }
        },
        initialWidth:265,cellAttributes : {class:'slds-theme_shade slds-theme_alert-texture'}},
       {label: 'Status', fieldName: 'Status', type: 'text',initialWidth: 150},
       {label: 'Severity', fieldName: 'Impact', type: 'text',initialWidth: 105,cellAttributes : {class:{fieldName: 'ImpactClass'}}},
       {label: 'Owner', fieldName: 'OwnerName', type: 'text',initialWidth: 126},
       {label: 'Incident Requested By', fieldName: 'Incident_Requested_By', type: 'text',cellAttributes : {class:'slds-theme_shade slds-theme_alert-texture'}},
       {label: 'TIM', fieldName: 'TIM', type: 'text'},
       {label: 'Target Shift', fieldName: 'targetShift', type: 'text',cellAttributes : {class:'slds-theme_shade slds-theme_alert-texture'}},
       {label: 'Wakeup Time', fieldName: 'wakeUpTime', type: 'text'},
       {label: 'Q Age(dd:hh)', fieldName: 'Age', type: 'text',cellAttributes : {class:'slds-theme_shade slds-theme_alert-texture'}},
       {label: 'Created Date', fieldName: 'CreatedDate_Text', type: 'text',sortable: true},
    ];

   // Columns for Incidents in Queue Section for logged-in user non-IRAPT
   @track columnsQueueSectionNonIrapt = [

      
       {label: 'Incident ID', fieldName: 'SI_recordLink', type: 'url',sortable: true,initialWidth: 120,
       typeAttributes: { label: { fieldName: "Incident_ID" }, target: "_blank"},cellAttributes : {class:'slds-m-left_small slds-m-top_small'}},
       
       {label: 'Title', fieldName: 'Title', type: 'cellEdit',typeAttributes: {
        
        title: { fieldName: 'Title' }
        },cellAttributes : {class:'slds-theme_shade slds-theme_alert-texture'}},
       {label: 'Status', fieldName: 'Status', type: 'text',initialWidth: 150},
       {label: 'Severity', fieldName: 'Impact', type: 'text',initialWidth: 105,cellAttributes : {class:{fieldName: 'ImpactClass'}}},
       {label: 'Owner', fieldName: 'OwnerName', type: 'text'},
       {label: 'Incident Requested By', fieldName: 'Incident_Requested_By', type: 'text',cellAttributes : {class:'slds-theme_shade slds-theme_alert-texture'}},
       {label: 'TIM', fieldName: 'TIM', type: 'text'}, 
       {label: 'Q Age(dd : hh)', fieldName: 'Age', type: 'text',cellAttributes : {class:'slds-theme_shade slds-theme_alert-texture'}}, 
       {label: 'Created Date', fieldName: 'CreatedDate_Text', type: 'text',sortable: true}
    ];

   // Columns for All Open Incidents section
   @track columnsAllIncidents = [
       
       {label: 'Incident ID', fieldName: 'SI_recordLink', type: 'url',sortable: true,initialWidth: 120,
       typeAttributes: { label: { fieldName: "Incident_ID" }, target: "_blank"},cellAttributes : {class:'slds-m-left_small slds-m-top_small'}},
       {label: 'Title', fieldName: 'Title', type: 'cellEdit',typeAttributes: {
        
        title: { fieldName: 'Title' }
        },cellAttributes : {class:'slds-theme_shade slds-theme_alert-texture'}},
       {label: 'Status', fieldName: 'Status', type: 'text',initialWidth: 150},
       {label: 'Severity', fieldName: 'Impact', type: 'text',initialWidth: 105,cellAttributes : {class:{fieldName: 'ImpactClass'}}},
       {label: 'Owner', fieldName: 'OwnerName', type: 'text'},
       {label: 'Incident Requested By', fieldName: 'Incident_Requested_By', type: 'text',cellAttributes : {class:'slds-theme_shade slds-theme_alert-texture'}},
       {label: 'TIM', fieldName: 'TIM', type: 'text'},
       {label: 'Created Date', fieldName: 'CreatedDate_Text', type: 'text',sortable: true,cellAttributes : {class:'slds-theme_shade slds-theme_alert-texture'}}
      
   ];

   get pagesList() {
       let mid = Math.floor(this.set_size / 2) + 1;
       if (this.pageMyIncident > mid) {
           return this.pages.slice(this.pageMyIncident - mid, this.pageMyIncident + mid - 1);
       }
       return this.pages.slice(0, this.set_size);
   }

   get arePagesMoreThanOneMyIncidentSection(){
      
       return this.pages.length > 1 ? true :false; 
   }

   get arePagesMoreThanOneQueueSection(){
      
       return this.pagesQueue.length > 1 ? true :false; 
   }

   get arePagesMoreThanOneAllIncidentSection(){
      
       return this.pagesAllIncident.length > 1 ? true :false; 
   }

   get pagesListQueue() {
       let mid = Math.floor(this.set_size / 2) + 1;
       
       if (this.pageQueue > mid) {
           return this.pagesQueue.slice(this.pageQueue - mid, this.pageQueue + mid - 1);
       }
       return this.pagesQueue.slice(0, this.set_size);
   }

   get pagesListAllIncident() {
       let mid = Math.floor(this.set_size / 2) + 1;
       if (this.pageAllIncident > mid) {
           return this.pagesAllIncident.slice(this.pageAllIncident - mid, this.pageAllIncident + mid - 1);
       }
       return this.pagesAllIncident.slice(0, this.set_size);
   }
  
   get currentPageData() {
       return this.pageData();
       
       
   }

   pageData = () => {
       let page = this.pageMyIncident;
       let perpage = this.perpage_myIncident;
       let startIndex = (page * perpage) - perpage;
       let endIndex = (page * perpage);
       return this.myIncidents.slice(startIndex, endIndex);
   }

   get currentPageDataQueue() {
       return this.pageDataQueue();
   }
   pageDataQueue = () => {
       let page = this.pageQueue;
       let perpage = this.perpage;
       let startIndex = (page * perpage) - perpage;
       let endIndex = (page * perpage);
       return this.allIncidentsInQueue.slice(startIndex, endIndex);
   }

   get currentPageDataAllIncident() {
       return this.pageDataAllIncident();
   }
   pageDataAllIncident = () => {
       let page = this.pageAllIncident;
       let perpage = this.perpage;
       let startIndex = (page * perpage) - perpage;
       let endIndex = (page * perpage);
       return this.allIncidents.slice(startIndex, endIndex);
   }

   
  

   setPages = (data,source) => {
       this.pages =[];
       let numberOfPages = Math.ceil(data.length / this.perpage_myIncident);
       for (let index = 1; index <= numberOfPages; index++) {
           if(source == 'myIncident'){
           this.pages.push(index);
          
           }/*else if(source == 'queue'){
               this.pagesQueue.push(index);
               
           }    */
       }
       
   }
   setPagesQueue = (data,source) => {
       this.pagesQueue = [];
       let numberOfPages = Math.ceil(data.length / this.perpage);
       for (let index = 1; index <= numberOfPages; index++) {
           if(source == 'Queue'){
           this.pagesQueue.push(index);
          
           }
       }
       
   }
   setPagesAllIncident = (data,source) => {
       this.pagesAllIncident = [];
       let numberOfPages = Math.ceil(data.length / this.perpage);
       for (let index = 1; index <= numberOfPages; index++) {
           if(source == 'AllIncident'){
           this.pagesAllIncident.push(index);
          
           }
       }
       
   }
   get hasPrev() {
       return this.pageMyIncident > 1;
   }
   get hasPrevQueue() {
       return this.pageQueue > 1;
   }
   get hasPrevAllIncident() {
       return this.pageAllIncident > 1;
   }
   get hasNext() {
       return this.pageMyIncident < this.pages.length;
   }
   get hasNextQueue() {
       return this.pageQueue < this.pagesQueue.length;
   }
   get hasNextAllIncident() {
       return this.pageAllIncident< this.pagesAllIncident.length;
   }
   onNext = (e) => {
      // alert(e.target.class);
       if(e.target.name == 'nextMyIncident'){
       ++this.pageMyIncident;
       }
       else if(e.target.name == 'nextQueue'){
           ++this.pageQueue;
           }
           else if(e.target.name == 'nextAllIncident'){
               ++this.pageAllIncident;
               }
   }
   onPrev = (e) => {
       if(e.target.name == 'prevMyIncident'){
           --this.pageMyIncident;
       }else if(e.target.name == 'prevQueue'){
           --this.pageQueue;
       }else if(e.target.name == 'prevAllIncident'){
           --this.pageAllIncident;
       }
   }
   onPageClick = (e) => {
       
       if(e.target.name == 'myIncidentPageButton'){
          
       this.pageMyIncident = parseInt(e.target.label);
       }else if(e.target.name == 'queuePageButton'){
          
           this.pageQueue = parseInt(e.target.label);
       }else if(e.target.name == 'allIncidentPageButton'){
          
           this.pageAllIncident = parseInt(e.target.label);
       }
   }


  

   //Constrauctor for loading my incidents section by default
   constructor() {
      super();
      
     
       this.loadSpinner = true;

        getDataForFirstLoad({isFirstTimeLoad:true,sectionName:''})
           .then(result =>{
               var returnResult = JSON.parse(result);
               this.statusBackUpForJSON = returnResult.FilterStatus_SelectedvalueWrp;
               this.impactBackUpForJSON = returnResult.FilterSeverity_SelectedvalueWrp;
               this.queueBackUpForJSON = returnResult.FilterQueue_SelectedvalueWrp;
                this.isIRAPTUser = returnResult.isIRAPTUser;
               if(this.isIRAPTUser){
                    this.myIncidentSectionExpanded = true;
                    this.queueSectionExpanded = true;
                    // Setting options for Status
                    for(var i=0;i<returnResult.FilterStatus_SelectedvalueWrp.length;i++){
                        this.StatusoptionsMyIncident.push({label: returnResult.FilterStatus_SelectedvalueWrp[i].UI_Value,value:returnResult.FilterStatus_SelectedvalueWrp[i].UI_Value});
                        this.StatusoptionsQueue.push({label: returnResult.FilterStatus_SelectedvalueWrp[i].UI_Value,value:returnResult.FilterStatus_SelectedvalueWrp[i].UI_Value});
                        this.statusvalueMyIncident.push(returnResult.FilterStatus_SelectedvalueWrp[i].UI_Value);
                        if(returnResult.FilterStatus_SelectedvalueWrp[i].isEnabled)
                            this.statusvalueQueue.push(returnResult.FilterStatus_SelectedvalueWrp[i].UI_Value);
                    }

                    // Setting options for Severity
                    for(var i=0;i<returnResult.FilterSeverity_SelectedvalueWrp.length;i++){
                        this.ImpactoptionsMyIncident.push({label: returnResult.FilterSeverity_SelectedvalueWrp[i].UI_Value,value:returnResult.FilterSeverity_SelectedvalueWrp[i].UI_Value});
                        this.ImpactoptionsQueue.push({label: returnResult.FilterSeverity_SelectedvalueWrp[i].UI_Value,value:returnResult.FilterSeverity_SelectedvalueWrp[i].UI_Value});
                        this.impactvalueMyIncident.push(returnResult.FilterSeverity_SelectedvalueWrp[i].UI_Value);
                        if(returnResult.FilterSeverity_SelectedvalueWrp[i].isEnabled)
                            this.impactvalueQueue.push(returnResult.FilterSeverity_SelectedvalueWrp[i].UI_Value);
                    }

                    // Setting options for Queue
                    for(var i=0;i<returnResult.FilterQueue_SelectedvalueWrp.length;i++){
                        this.queueOptions.push({label: returnResult.FilterQueue_SelectedvalueWrp[i].UI_Value,value:returnResult.FilterQueue_SelectedvalueWrp[i].UI_Value});
                        if(returnResult.FilterQueue_SelectedvalueWrp[i].isEnabled)
                            this.queuevalueQueue.push(returnResult.FilterQueue_SelectedvalueWrp[i].UI_Value);
                    }

                        if(!this.isIRAPTUser){
                        this.noOfMyIncidentsLabel =  ' Incidents Requested  ('+returnResult.incidentList_myOpenIncidents.length+')';
                        }else{
                        this.noOfMyIncidentsLabel =  ' My Open Incidents  ('+returnResult.incidentList_myOpenIncidents.length+')';
                        }
                       
                        this.myIncidents = returnResult.incidentList_myOpenIncidents; 
                        this.myIncidentsBackUpForSearch = this.myIncidents; 
                        this.setPages(returnResult.incidentList_myOpenIncidents,'myIncident');
                        this.noOfQueueIncidentsLabel = ' Incidents In Queue  ('+returnResult.incidentList_IncidentsInQueue.length+')';
                        this.allIncidentsInQueue = returnResult.incidentList_IncidentsInQueue;
                        this.allIncidentsInQueueBackUpForSearch = this.allIncidentsInQueue;
                        this.setPagesQueue(returnResult.incidentList_IncidentsInQueue,'Queue');

                    
               }else{
                    this.myIncidentSectionExpanded = true; 
                    // Setting options for Status
                    for(var i=0;i<returnResult.FilterStatus_SelectedvalueWrp.length;i++){
                        this.StatusoptionsMyIncident.push({label: returnResult.FilterStatus_SelectedvalueWrp[i].UI_Value,value:returnResult.FilterStatus_SelectedvalueWrp[i].UI_Value});
                        this.statusvalueMyIncident.push(returnResult.FilterStatus_SelectedvalueWrp[i].UI_Value);
                    }
                    // Setting options for Severity
                    for(var i=0;i<returnResult.FilterSeverity_SelectedvalueWrp.length;i++){
                        this.ImpactoptionsMyIncident.push({label: returnResult.FilterSeverity_SelectedvalueWrp[i].UI_Value,value:returnResult.FilterSeverity_SelectedvalueWrp[i].UI_Value});
                        this.impactvalueMyIncident.push(returnResult.FilterSeverity_SelectedvalueWrp[i].UI_Value);
                    }
                        if(!this.isIRAPTUser){
                        this.noOfMyIncidentsLabel =  ' Incidents Requested  ('+returnResult.incidentList_myOpenIncidents.length+')';
                        }else{
                        this.noOfMyIncidentsLabel =  ' My Open Incidents  ('+returnResult.incidentList_myOpenIncidents.length+')';
                        }
                       
                        this.myIncidents = returnResult.incidentList_myOpenIncidents; 
                        this.myIncidentsBackUpForSearch = this.myIncidents; 
                        this.setPages(returnResult.incidentList_myOpenIncidents,'myIncident');
                        

               } 
               
              this.loadSpinner =false;
               
               
              
            }).catch(error => {
                this.error = error;
                this.loadSpinner = false;
            });
      
       
       this.handleSubscribe();
   }

   handleSubscribe() {
       // Callback invoked whenever a new event message is received
       const messageCallback = function(response) {
        
        
        
        if(response.data.payload.ChangeEventHeader.changeType == 'CREATE' || (response.data.payload.ChangeEventHeader.changeType == 'UPDATE' && (response.data.payload.ChangeEventHeader.changedFields.includes('Status__c') || response.data.payload.ChangeEventHeader.changedFields.includes('Severity__c') || response.data.payload.ChangeEventHeader.changedFields.includes('OwnerId') || response.data.payload.ChangeEventHeader.changedFields.includes('TIM_IC__c')))){
          
                if(this.queueSectionExpanded){
                 getFilterData({isIRAPTUser:this.isIRAPTUser,SectionName:'Incidents In Queue',allSelectedStatus:this.statusvalueQueue,allSelectedSeverity:this.impactvalueQueue,allSelectedQueue:this.queuevalueQueue})
                 .then(result =>{
                     var returnResult = JSON.parse(result);
                      
                     
                          this.noOfQueueIncidentsLabel = ' Incidents In Queue  ('+returnResult.incidentList_IncidentsInQueue.length+')';
                          this.allIncidentsInQueue = returnResult.incidentList_IncidentsInQueue;
                          this.allIncidentsInQueueBackUpForSearch = this.allIncidentsInQueue;
                          this.setPagesQueue(returnResult.incidentList_IncidentsInQueue,'Queue');
                          
                          
                          
                      
                 }) .catch(error => {
                  this.error = error;
                  
                  
              });
                }
        }
        
        
    }.bind(this);

       // Invoke subscribe method of empApi. Pass reference to messageCallback
       subscribe(this.channelName, -1, messageCallback).then(response => {
           // Response contains the subscription information on subscribe call
          
           this.subscription = response;
           
           //this.toggleSubscribeButton(true);
       });
   }

   

   // handling custom style on page rendering
   renderedCallback() {
       const style = document.createElement('style');
       style.innerText = `c-sc-s-i-home-page-l-w-c .btn .slds-button_icon svg{
       fill: #F56243;
       }`;
       this.template.querySelector('lightning-button-icon').appendChild(style);

       if(this.myIncidentSectionExpanded || this.queueSectionExpanded || this.allIncidentSectionExpanded){

        const cardHeaderStyle = document.createElement('style');
        cardHeaderStyle.innerText = `c-sc-s-i-home-page-l-w-c .slds-card .slds-card__header{
        padding:0;
        margin:0;    
        }`;
        this.template.querySelector('lightning-card').appendChild(cardHeaderStyle);

        const cardBodyStyle = document.createElement('style');
        cardBodyStyle.innerText = `c-sc-s-i-home-page-l-w-c .slds-card .slds-card__body{
        
        margin-top:0px;    
        }`;
        this.template.querySelector('lightning-card').appendChild(cardBodyStyle);

        const sev1Style = document.createElement('style');
        sev1Style.innerText = `c-sc-s-i-home-page-l-w-c c-sc-s-i-cell-edit-custom-datatype .Sev1{
        color: #F54343;
        }`;
        this.template.querySelector('c-sc-s-i-cell-edit-custom-datatype').appendChild(sev1Style);

        const sev2Style = document.createElement('style');
        sev2Style.innerText = `c-sc-s-i-home-page-l-w-c .Sev2{
        color: #F59943;
        }`;
        this.template.querySelector('c-sc-s-i-cell-edit-custom-datatype').appendChild(sev2Style);

        const sev3Style = document.createElement('style');
        sev3Style.innerText = `c-sc-s-i-home-page-l-w-c .Sev3{
        color: #7ac13b;
        }`;
        this.template.querySelector('c-sc-s-i-cell-edit-custom-datatype').appendChild(sev3Style);

        const sev4Style = document.createElement('style');
        sev4Style.innerText = `c-sc-s-i-home-page-l-w-c .Sev4{
        color: #4d9900;
        }`;
        this.template.querySelector('c-sc-s-i-cell-edit-custom-datatype').appendChild(sev4Style);

            const saveHeight = document.createElement('style');
            saveHeight.innerText = `c-sc-s-i-home-page-l-w-c .applyAllStyle .slds-button_icon svg{
            
            fill: white;
            }`;
            this.template.querySelector('lightning-button-icon').appendChild(saveHeight);

            const style3 = document.createElement('style');
            style3.innerText = `c-sc-s-i-home-page-l-w-c .custom .slds-button{
            
            color:white;
            background-color:#1D5873;
            
            font-size:15px;
            padding-left:10px;
            padding-right:10px;
            }`;
            this.template.querySelector('lightning-button-menu').appendChild(style3);

            const styleForCustomBtn = document.createElement('style');
            styleForCustomBtn.innerText = `c-sc-s-i-home-page-l-w-c .customStatus .slds-button{
            
            color:white;
            background-color:#5D94C4;
            font-size:15px;
            
            padding-left:10px;
            padding-right:10px;
            border:none;
            }`;
            this.template.querySelector('lightning-button-menu').appendChild(styleForCustomBtn);

            const styleApplyAll = document.createElement('style');
            styleApplyAll.innerText = `c-sc-s-i-home-page-l-w-c .applyAllStyle .slds-button{
            
            font-size:15px;
            background-color:#8686CC;
            border:none;
            }`;
            this.template.querySelector('lightning-button').appendChild(styleApplyAll);

            const refreshButtonStyle = document.createElement('style');
            refreshButtonStyle.innerText = `c-sc-s-i-home-page-l-w-c .refresh .slds-button{
            
            border-radius:100px;
            height:35px;
            width:35px;
            background-color:#54698D;
            
            border:none;
            }`;
            this.template.querySelector('lightning-button').appendChild(refreshButtonStyle);

            const style2 = document.createElement('style');
            style2.innerText = `c-sc-s-i-home-page-l-w-c .custom .slds-dropdown_left{
            width:115px;
            background-color:#EEF7F7;
            padding-left:10px;
            font-size:20px;
            
            }`;
             this.template.querySelector('lightning-button-menu').appendChild(style2);

             const styleForStatus = document.createElement('style');
            styleForStatus.innerText = `c-sc-s-i-home-page-l-w-c .customStatus .slds-dropdown_left{
            width:170px;
            background-color:#EEF7F7;
            padding-left:10px;
            font-size:20px;
            
            }`;

            this.template.querySelector('lightning-button-menu').appendChild(styleForStatus);

            const queueDropDownStyle = document.createElement('style');
            queueDropDownStyle.innerText = `c-sc-s-i-home-page-l-w-c .queueDropdown .slds-dropdown_left{
            width:180px;
            background-color:#EEF7F7;
            padding-left:10px;
            font-size:20px;
            
            }`;

            this.template.querySelector('lightning-button-menu').appendChild(queueDropDownStyle);

            const style9 = document.createElement('style');
            style9.innerText = `c-sc-s-i-home-page-l-w-c .iconStyle .slds-button__icon{
                margin-left:5px;
            }`;
            this.template.querySelector('lightning-button-menu').appendChild(style9);
        }

        if(this.hasPrev){
            const prevButtonStyle = document.createElement('style');
            prevButtonStyle.innerText = `c-sc-s-i-home-page-l-w-c .prev .slds-button{
                background-color:#5D94C4;
                border:none;
                color:white;
                }`;
                this.template.querySelector('lightning-button').appendChild(prevButtonStyle);
        }
        if(this.arePagesMoreThanOneMyIncidentSection){
            const pageButtonStyle = document.createElement('style');
            pageButtonStyle.innerText = `c-sc-s-i-home-page-l-w-c .pageButtons .slds-button{
                background-color:#5D94C4;
                border:none;
                color:white;
                }`;
                this.template.querySelector('lightning-button').appendChild(pageButtonStyle);
        }
        if(this.hasNext){
            const nextButtonStyle = document.createElement('style');
            nextButtonStyle.innerText = `c-sc-s-i-home-page-l-w-c .next .slds-button{
                background-color:#5D94C4;
                border:none;
                color:white;
                }`;
                this.template.querySelector('lightning-button').appendChild(nextButtonStyle);
        }
        if(this.hasPrevQueue){
            const prevQueueButtonStyle = document.createElement('style');
            prevQueueButtonStyle.innerText = `c-sc-s-i-home-page-l-w-c .prevQueue .slds-button{
                background-color:#5D94C4;
                border:none;
                color:white;
                }`;
                this.template.querySelector('lightning-button').appendChild(prevQueueButtonStyle);
        }
        if(this.arePagesMoreThanOneQueueSection){
            const pageButtonQueueStyle = document.createElement('style');
            pageButtonQueueStyle.innerText = `c-sc-s-i-home-page-l-w-c .pageButtonsQueue .slds-button{
                background-color:#5D94C4;
                border:none;
                color:white;
                }`;
                this.template.querySelector('lightning-button').appendChild(pageButtonQueueStyle);
        }
        if(this.hasNextQueue){
            const nextButtonQueueStyle = document.createElement('style');
            nextButtonQueueStyle.innerText = `c-sc-s-i-home-page-l-w-c .nextQueue .slds-button{
                background-color:#5D94C4;
                border:none;
                color:white;
                }`;
                this.template.querySelector('lightning-button').appendChild(nextButtonQueueStyle);
        }
        if(this.hasPrevAllIncident){
            const prevAllButtonStyle = document.createElement('style');
            prevAllButtonStyle.innerText = `c-sc-s-i-home-page-l-w-c .prevAllIncidentSection .slds-button{
                background-color:#5D94C4;
                border:none;
                color:white;
                }`;
                this.template.querySelector('lightning-button').appendChild(prevAllButtonStyle);
        }
        if(this.arePagesMoreThanOneAllIncidentSection){
            const pageButtonAllStyle = document.createElement('style');
            pageButtonAllStyle.innerText = `c-sc-s-i-home-page-l-w-c .pageButtonsAllIncident .slds-button{
                background-color:#5D94C4;
                border:none;
                color:white;
                }`;
                this.template.querySelector('lightning-button').appendChild(pageButtonAllStyle);
        }
        if(this.hasNextAllIncident){
            const nextAllButtonStyle = document.createElement('style');
            nextAllButtonStyle.innerText = `c-sc-s-i-home-page-l-w-c .nextAllIncident .slds-button{
                background-color:#5D94C4;
                border:none;
                color:white;
                }`;
                this.template.querySelector('lightning-button').appendChild(nextAllButtonStyle);
        }

       

      

       
       if(this.allIncidentSectionExpanded || (this.queueSectionView && this.isIRAPTUser == false)){
       const style11 = document.createElement('style');
       style11.innerText = `c-sc-s-i-home-page-l-w-c .allIncidents .slds-table tr td{
       
          padding:10px;
          
       }`;
       this.template.querySelector('c-sc-s-i-cell-edit-custom-datatype').appendChild(style11);
        }

       const style12 = document.createElement('style');
       style12.innerText = `c-sc-s-i-home-page-l-w-c .slds-table {
          font-size:15px;
          
          
       }`;
      // this.template.querySelector('lightning-datatable').appendChild(style12);

       if(this.queueSectionExpanded && this.isIRAPTUser){
        const style13 = document.createElement('style');
        style13.innerText = `c-sc-s-i-home-page-l-w-c .hand .slds-button{
          font-size:20px !important;
          
          
        }`;
        this.template.querySelector('lightning-button').appendChild(style13);
     }

       
       

       

      

       
   }
  
//handlig search functionality on blur
   handleSearch(event){
       // At least 3 characters required for search
       if(event.target.value != '' && event.target.value.length < 3){
           this.showToast('Please type at least 3 characters for search.','error','dismissable');
           return;
       }
       this.loadSpinner = true;
       //search variable setting based on section
       if(event.target.name=='searchMyIncidents'){
            if(event.target.value == ''){
                this.myIncidents = this.myIncidentsBackUpForSearch;
            }else{
                this.searchKeyMyIncidentsSection = event.target.value;
                var searchString = event.target.value.toLowerCase();
                var tempList = [];
                var myIncidentsList = [];
                
                myIncidentsList = this.myIncidentsBackUpForSearch;
                
                for(var i=0;i<myIncidentsList.length;i++){
                let tempRecord = Object.assign({}, myIncidentsList[i]); 
                if(tempRecord.Incident_ID.toLowerCase().includes(searchString) || tempRecord.Title.toLowerCase().includes(searchString) || tempRecord.Status.toLowerCase().includes(searchString) || (tempRecord.Impact != '' && tempRecord.Impact != undefined && tempRecord.Impact.toLowerCase().includes(searchString)) || tempRecord.OwnerName.toLowerCase().includes(searchString) || (tempRecord.Incident_Requested_By != '' && tempRecord.Incident_Requested_By != undefined && tempRecord.Incident_Requested_By.toLowerCase().includes(searchString)) || (tempRecord.TIM != '' && tempRecord.TIM != undefined && tempRecord.TIM.toLowerCase().includes(searchString)) ){
                    //if(tempRecord.Incident_ID.includes(this.searchKeyMyIncidentsSection) || tempRecord.Title.includes(this.searchKeyMyIncidentsSection) || tempRecord.Status.includes(this.searchKeyMyIncidentsSection) || tempRecord.Impact.includes(this.searchKeyMyIncidentsSection) || tempRecord.OwnerName.includes(this.searchKeyMyIncidentsSection) || tempRecord.Incident_Requested_By.includes(this.searchKeyMyIncidentsSection) || tempRecord.TIM.includes(this.searchKeyMyIncidentsSection)){
                        tempList.push(tempRecord); 
                    } 
                }
               this.myIncidents = tempList;
            }   
           
           if(!this.isIRAPTUser){
            this.noOfMyIncidentsLabel =  ' Incidents Requested  ('+this.myIncidents.length+')';
            }else{
            this.noOfMyIncidentsLabel =  ' My Open Incidents  ('+this.myIncidents.length+')';
            }
           this.setPages(this.myIncidents,'myIncident');
           this.pageMyIncident = 1;
        

          
       }
       else if(event.target.name=='searchQueue'){
        if(event.target.value == ''){
            this.allIncidentsInQueue = this.allIncidentsInQueueBackUpForSearch;
        }else{
            this.searchKeyQueueSection = event.target.value;
            var searchString = event.target.value.toLowerCase();
            var tempList = [];
            var incidentsInQueueList = [];
            incidentsInQueueList = this.allIncidentsInQueueBackUpForSearch;
            for(var i=0;i<incidentsInQueueList.length;i++){
                let tempRecord = Object.assign({}, incidentsInQueueList[i]);
              //  if(tempRecord.Incident_ID.includes(this.searchKeyQueueSection) || tempRecord.Title.includes(this.searchKeyQueueSection) || tempRecord.Impact.includes(this.searchKeyQueueSection)){
                if(tempRecord.Incident_ID.toLowerCase().includes(searchString) || tempRecord.Title.toLowerCase().includes(searchString) || tempRecord.Status.toLowerCase().includes(searchString) || (tempRecord.Impact != '' && tempRecord.Impact != undefined && tempRecord.Impact.toLowerCase().includes(searchString)) || tempRecord.OwnerName.toLowerCase().includes(searchString) || (tempRecord.Incident_Requested_By != '' && tempRecord.Incident_Requested_By != undefined && tempRecord.Incident_Requested_By.toLowerCase().includes(searchString)) || (tempRecord.TIM != '' && tempRecord.TIM != undefined && tempRecord.TIM.toLowerCase().includes(searchString)) ){
                    tempList.push(tempRecord); 
                } 
            }    
           this.allIncidentsInQueue = tempList;
        }   
        this.noOfQueueIncidentsLabel = ' Incidents In Queue  ('+this.allIncidentsInQueue.length+')';
        this.setPagesQueue(this.allIncidentsInQueue,'Queue');
        this.pageQueue = 1;
           
        }   
         
       
       else if(event.target.name=='searchAllIncidents'){
        if(event.target.value == ''){
            this.allIncidents = this.allIncidentsBackUpForSearch;
        }else{
            this.searchKeyAllIncidentsSection = event.target.value;
            var searchString = event.target.value.toLowerCase();
            var tempList = [];
            var allIncidentsList = [];
            allIncidentsList = this.allIncidentsBackUpForSearch;
            for(var i=0;i<allIncidentsList.length;i++){
                let tempRecord = Object.assign({}, allIncidentsList[i]); 
                if(tempRecord.Incident_ID.toLowerCase().includes(searchString) || tempRecord.Title.toLowerCase().includes(searchString) || tempRecord.Status.toLowerCase().includes(searchString) || (tempRecord.Impact != '' && tempRecord.Impact != undefined && tempRecord.Impact.toLowerCase().includes(searchString)) || tempRecord.OwnerName.toLowerCase().includes(searchString) || (tempRecord.Incident_Requested_By != '' && tempRecord.Incident_Requested_By != undefined && tempRecord.Incident_Requested_By.toLowerCase().includes(searchString)) || (tempRecord.TIM != '' && tempRecord.TIM != undefined && tempRecord.TIM.toLowerCase().includes(searchString)) ){
                //if(tempRecord.Incident_ID.includes(this.searchKeyAllIncidentsSection) || tempRecord.Title.includes(this.searchKeyAllIncidentsSection) || tempRecord.Status.includes(this.searchKeyAllIncidentsSection) || tempRecord.Impact.includes(this.searchKeyAllIncidentsSection) || tempRecord.OwnerName.includes(this.searchKeyAllIncidentsSection) || tempRecord.Incident_Requested_By.includes(this.searchKeyAllIncidentsSection) || tempRecord.TIM.includes(this.searchKeyAllIncidentsSection)){
                    tempList.push(tempRecord); 
                } 
            }    
           this.allIncidents = tempList;
        }   
        this.noOfAllIncidentsLabel = ' All Open Incidents  ('+this.allIncidents.length+')';
        this.setPagesAllIncident(this.allIncidents,'AllIncident');
        this.pageAllIncident =1 ;
           
           
         
       }
       this.loadSpinner = false;
   }

   // My Incidents section data load
   handleMyIncidentsLoad(){
       this.loadSpinner = true;
       // Showing error if no status/severity selected
     
   
       var isFirstTimeLoad = false;
       
       getDataForFirstLoad({isFirstTimeLoad:isFirstTimeLoad,sectionName:'My Open Incidents'})
          .then(result =>{
              var returnResult = JSON.parse(result);
              

               
              if(!this.isIRAPTUser){
                this.noOfMyIncidentsLabel =  ' Incidents Requested  ('+returnResult.incidentList_myOpenIncidents.length+')';
                }else{
                this.noOfMyIncidentsLabel =  ' My Open Incidents  ('+returnResult.incidentList_myOpenIncidents.length+')';
            }
              this.myIncidents = returnResult.incidentList_myOpenIncidents;
              
              this.myIncidentsBackUpForSearch = this.myIncidents;
              this.setPages(returnResult.incidentList_myOpenIncidents,'myIncident');
              this.pageMyIncident = 1;
              this.loadSpinner =false;
              }
          ).catch(error => {
            this.error = error;
            this.loadSpinner =false;
        });
   }   

   // Apply and Save filter
   handleSaveFilter(event){
    this.loadSpinner = true;
   /* this.statusBackUpForJSON = returnResult.FilterStatus_SelectedvalueWrp;
    this.impactBackUpForJSON = returnResult.FilterSeverity_SelectedvalueWrp;
    this.queueBackUpForJSON = returnResult.FilterQ*/
    for(var i=0;i<this.statusBackUpForJSON.length;i++){
        if(this.statusvalueQueue.includes(this.statusBackUpForJSON[i].UI_Value)){
            this.statusBackUpForJSON[i].isEnabled = true;
        }else{
            this.statusBackUpForJSON[i].isEnabled = false;
        }
    }
    for(var i=0;i<this.impactBackUpForJSON.length;i++){
        if(this.impactvalueQueue.includes(this.impactBackUpForJSON[i].UI_Value)){
            this.impactBackUpForJSON[i].isEnabled = true;
        }else{
            this.impactBackUpForJSON[i].isEnabled = false;
        }
    }
    for(var i=0;i<this.queueBackUpForJSON.length;i++){
        if(this.queuevalueQueue.includes(this.queueBackUpForJSON[i].UI_Value)){
            this.queueBackUpForJSON[i].isEnabled = true;
        }else{
            this.queueBackUpForJSON[i].isEnabled = false;
        }
    }

   saveFilterData({isIRAPTUser:this.isIRAPTUser,allSelectedStatus:this.statusvalueQueue,allSelectedSeverity:this.impactvalueQueue,allSelectedQueue:this.queuevalueQueue,json_status:JSON.stringify(this.statusBackUpForJSON),json_severity:JSON.stringify(this.impactBackUpForJSON),json_queue:JSON.stringify(this.queueBackUpForJSON)})
   
    .then(result =>{
        var returnResult = JSON.parse(result);
        this.noOfQueueIncidentsLabel = ' Incidents In Queue  ('+returnResult.incidentList_IncidentsInQueue.length+')';
        this.allIncidentsInQueue = returnResult.incidentList_IncidentsInQueue;
        this.allIncidentsInQueueBackUpForSearch = this.allIncidentsInQueue;
        this.setPagesQueue(returnResult.incidentList_IncidentsInQueue,'Queue');
        this.pageQueue = 1;
        this.loadSpinner = false;

    }).catch(error => {
        this.error = error;
        this.loadSpinner = false;
    });

   }
   
   // Handling Apply All button click
   handleApplyAll(event){
    this.loadSpinner = true;
       var sectionName = '';
       var selectedStatusList = [];
       var selectedSeverityList = [];
       var selectedQueueList = [];
        if(event.target.name == 'Apply All' || event.target.name == 'refreshMyIncidents'){
            

           if(this.statusvalueMyIncident.length == 0 || this.impactvalueMyIncident.length == 0){
                this.showToast('Please select at least one Status and Severity.','error','dismissable');
                this.loadSpinner = false;
                return;
            }
            sectionName = 'My Open Incidents';
            selectedStatusList = this.statusvalueMyIncident;
            selectedSeverityList = this.impactvalueMyIncident;
        }
        else if(event.target.name == 'Apply AllQueue' || event.target.name == 'refreshQueue'){
            if(this.statusvalueQueue.length == 0 || this.impactvalueQueue.length == 0){
                this.showToast('Please select at least one Status and Severity.','error','dismissable');
                this.loadSpinner = false;
                return;
            }
            sectionName = 'Incidents In Queue';
            selectedStatusList = this.statusvalueQueue;
            selectedSeverityList = this.impactvalueQueue;
            selectedQueueList = this.queuevalueQueue;
        }
        else if(event.target.name == 'Apply AllallIncidents' || event.target.name == 'refreshAllIncidents'){
            if(this.statusvalueAllIncident.length == 0 || this.impactvalueAllIncident.length == 0){
                this.showToast('Please select at least one Status and Severity.','error','dismissable');
                this.loadSpinner = false;
                return;
            }
            sectionName = 'All Open Incidents';
            selectedStatusList = this.statusvalueAllIncident;
            selectedSeverityList = this.impactvalueAllIncident;
        }

        getFilterData({isIRAPTUser:this.isIRAPTUser,SectionName:sectionName,allSelectedStatus:selectedStatusList,allSelectedSeverity:selectedSeverityList,allSelectedQueue:selectedQueueList})
           .then(result =>{
               var returnResult = JSON.parse(result);
               if(sectionName == 'My Open Incidents'){
                    if(!this.isIRAPTUser){
                        this.noOfMyIncidentsLabel =  ' Incidents Requested  ('+returnResult.incidentList_myOpenIncidents.length+')';
                        }else{
                        this.noOfMyIncidentsLabel =  ' My Open Incidents  ('+returnResult.incidentList_myOpenIncidents.length+')';
                    }
                    this.myIncidents = returnResult.incidentList_myOpenIncidents;  
                    this.myIncidentsBackUpForSearch = this.myIncidents;
                    this.setPages(returnResult.incidentList_myOpenIncidents,'myIncident');
                    this.pageMyIncident = 1;
                } 
                else if(sectionName == 'Incidents In Queue'){
                    this.noOfQueueIncidentsLabel = ' Incidents In Queue  ('+returnResult.incidentList_IncidentsInQueue.length+')';
                    this.allIncidentsInQueue = returnResult.incidentList_IncidentsInQueue;
                    this.allIncidentsInQueueBackUpForSearch = this.allIncidentsInQueue;
                    this.setPagesQueue(returnResult.incidentList_IncidentsInQueue,'Queue');
                    this.pageQueue = 1;
                }
                else if(sectionName == 'All Open Incidents'){
                    this.noOfAllIncidentsLabel = ' All Open Incidents  ('+returnResult.incidentList_AllOpenIncidents.length+')';
                    this.allIncidents = returnResult.incidentList_AllOpenIncidents;  
                    this.allIncidentsBackUpForSearch = this.allIncidents;
                    this.setPagesAllIncident(returnResult.incidentList_AllOpenIncidents,'AllIncident');
                    this.showButtonsAllIncident = true;
                    this.pageAllIncident = 1;
                }
                this.loadSpinner = false;
           }) .catch(error => {
            this.error = error;
            this.loadSpinner = false;
            
            
        });
    }   
  

    // Common method for any checkbox changes
    handleCheckboxChange(event){
     
   
    if(event.target.name == 'statusCheckboxGroupMyIncident'){
        if(!event.target.value.includes('All') && this.statusvalueMyIncident.includes('All')){
            this.statusvalueMyIncident = [];
        }
        else if( (event.target.value.includes('All') && !this.statusvalueMyIncident.includes('All')) || (!event.target.value.includes('All') && event.target.value.length == 4) ){
            this.statusvalueMyIncident = ['All','Incident Request','In Progress','Mitigated','Resolved'];
        }else{
            this.statusvalueMyIncident = event.detail.value;
            if(this.statusvalueMyIncident.includes('All') && this.statusvalueMyIncident.length != 5){
                this.statusvalueMyIncident.splice(this.statusvalueMyIncident.indexOf('All'),1);
            }
        }
    }
    else if(event.target.name == 'statusCheckboxGroupQueue'){
        if(!event.target.value.includes('All') && this.statusvalueQueue.includes('All')){
            this.statusvalueQueue = [];
        }
        else if( (event.target.value.includes('All') && !this.statusvalueQueue.includes('All')) || (!event.target.value.includes('All') && event.target.value.length == 4) ){
            this.statusvalueQueue = ['All','Incident Request','In Progress','Mitigated','Resolved'];
        }else{
            this.statusvalueQueue = event.detail.value;
            if(this.statusvalueQueue.includes('All') && this.statusvalueQueue.length != 5){
                this.statusvalueQueue.splice(this.statusvalueQueue.indexOf('All'),1);
            }
        }
    }
    else if(event.target.name == 'statusCheckboxGroupAllIncident' ){
        if(!event.target.value.includes('All') && this.statusvalueAllIncident.includes('All')){
            this.statusvalueAllIncident = [];
        }
        else if( (event.target.value.includes('All') && !this.statusvalueAllIncident.includes('All')) ||  (!event.target.value.includes('All') && event.target.value.length == 3)){
            this.statusvalueAllIncident = ['All','In Progress','Mitigated','Resolved'];
        }else{
            this.statusvalueAllIncident = event.detail.value;
            if(this.statusvalueAllIncident.includes('All') && this.statusvalueAllIncident.length != 4){
                this.statusvalueAllIncident.splice(this.statusvalueAllIncident.indexOf('All'),1);
            }
        }
    }
    else if(event.target.name == 'impactCheckboxGroupMyIncident'){
        if(!event.target.value.includes('All') && this.impactvalueMyIncident.includes('All')){
            this.impactvalueMyIncident = [];
        }
        else if( (event.target.value.includes('All') && !this.impactvalueMyIncident.includes('All')) || (!event.target.value.includes('All') && event.target.value.length == 4) ){
            this.impactvalueMyIncident = ['All','Sev1','Sev2','Sev3','Sev4'];
        }else{
            this.impactvalueMyIncident = event.detail.value;
            if(this.impactvalueMyIncident.includes('All') && this.impactvalueMyIncident.length != 5){
                this.impactvalueMyIncident.splice(this.impactvalueMyIncident.indexOf('All'),1);
            }
        } 

    }
    else if(event.target.name == 'impactCheckboxGroupQueue'){
        if(!event.target.value.includes('All') && this.impactvalueQueue.includes('All')){
            this.impactvalueQueue = [];
        }
        else if( (event.target.value.includes('All') && !this.impactvalueQueue.includes('All')) || (!event.target.value.includes('All') && event.target.value.length == 4) ){
            this.impactvalueQueue = ['All','Sev1','Sev2','Sev3','Sev4'];
        }else{
            this.impactvalueQueue = event.detail.value;
            if(this.impactvalueQueue.includes('All') && this.impactvalueQueue.length != 5){
                this.impactvalueQueue.splice(this.impactvalueQueue.indexOf('All'),1);
            }
        }    
    }   
    else if(event.target.name == 'impactCheckboxGroupAllIncident'){
        if(!event.target.value.includes('All') && this.impactvalueAllIncident.includes('All')){
            this.impactvalueAllIncident = [];
        }
        else if( (event.target.value.includes('All') && !this.impactvalueAllIncident.includes('All')) || (!event.target.value.includes('All') && event.target.value.length == 4) ){
            this.impactvalueAllIncident = ['All','Sev1','Sev2','Sev3','Sev4'];
        }else{
            this.impactvalueAllIncident = event.detail.value;
            if(this.impactvalueAllIncident.includes('All') && this.impactvalueAllIncident.length != 5){
                this.impactvalueAllIncident.splice(this.impactvalueAllIncident.indexOf('All'),1);
            }
        }    
    }
    else if(event.target.name == 'queueCheckboxGroupQueue'){
        if(!event.target.value.includes('All Queues') && this.queuevalueQueue.includes('All Queues')){
            this.queuevalueQueue = [];
        }
        else if( (event.target.value.includes('All Queues') && !this.queuevalueQueue.includes('All Queues')) || (!event.target.value.includes('All Queues') && event.target.value.length == 2) ){
            this.queuevalueQueue = ['All Queues','Incidents in Queue','Transition Queue'];
        }else{
            this.queuevalueQueue = event.detail.value;
            if(this.queuevalueQueue.includes('All Queues') && this.queuevalueQueue.length != 3){
                this.queuevalueQueue.splice(this.queuevalueQueue.indexOf('All Queues'),1);
            }
        }    
    }
    
    


   
}
   

   
   //Handling sorting for My Incidents section
   updateColumnSorting(event){
      // this.loadSpinner = true;
       let fieldName ;
       if(event.detail.fieldName == 'CreatedDate_Text'){
           fieldName = 'Createddate';
           this.sortBy = 'CreatedDate_Text';
       }else if(event.detail.fieldName == 'SI_recordLink'){
           fieldName = 'Incident_ID';
           this.sortBy = 'SI_recordLink';
       }
       //let fieldName = event.detail.fieldName == 'Etherpad_Link__c' ? CreatedDate : event.detail.fieldName;
       let sortDirection = event.detail.sortDirection;
       let section = 'My Incidents';
       //assign the values
       
      
       this.sortDirection = sortDirection;
       //call the custom sort method.
       this.sortData(fieldName, sortDirection,section);
      
       this.loadSpinner = false;
   } 

   //Handling sorting for All Open Incidents section
   updateColumnSortingAllIncidentsSection(event){
     //  this.loadSpinner = true;  
       let fieldName ;
       if(event.detail.fieldName == 'CreatedDate_Text'){
           fieldName = 'Createddate';
           this.sortByAllIncidentsSection = 'CreatedDate_Text';
       }else if(event.detail.fieldName == 'SI_recordLink'){
        fieldName = 'Incident_ID';
        this.sortByAllIncidentsSection = 'SI_recordLink';
        }
      // let fieldName = event.detail.fieldName == 'Etherpad_Link__c' ? CreatedDate : event.detail.fieldName;
       let sortDirection = event.detail.sortDirection;
       let section = 'All Incidents';
   
       //assign the values
       
       this.sortDirectionAllIncidentsSection = sortDirection;
       //call the custom sort method.
       this.sortData(fieldName, sortDirection,section);
       
       this.loadSpinner = false;
   } 

   //Handling sorting for Incidents In Queue section
   updateColumnSortingIncidentsInQueueSection(event){
      // this.loadSpinner = true;  
       let fieldName ;
       if(event.detail.fieldName == 'CreatedDate_Text'){
           fieldName = 'Createddate';
           this.sortByQueueSection = 'CreatedDate_Text';
       }else if(event.detail.fieldName == 'SI_recordLink'){
        fieldName = 'Incident_ID';
        this.sortByQueueSection = 'SI_recordLink';
        }
       //let fieldName = event.detail.fieldName == 'Etherpad_Link__c' ? CreatedDate : event.detail.fieldName;
       let sortDirection = event.detail.sortDirection;
       let section = 'Incidents In Queue';
   
       //assign the values
       
       this.sortDirectionQueueSection = sortDirection;
       //call the custom sort method.
       this.sortData(fieldName, sortDirection,section);
       this.loadSpinner = false;
   }
       
   //Sorting is performed in this ethod
   sortData(fieldName, sortDirection,section) {
       let sortResult;
       if(section == 'My Incidents'){
           sortResult = Object.assign([], this.myIncidents);
           this.myIncidents = sortResult.sort(function(a,b){
               if(a[fieldName] < b[fieldName])
               return sortDirection === 'asc' ? -1 : 1;
               else if(a[fieldName] > b[fieldName])
               return sortDirection === 'asc' ? 1 : -1;
               else
               return 0;
           })
       }else if(section == 'Incidents In Queue'){
           sortResult = Object.assign([], this.allIncidentsInQueue);
           this.allIncidentsInQueue = sortResult.sort(function(a,b){
               
               if(a[fieldName] < b[fieldName])
               return sortDirection === 'asc' ? -1 : 1;
               else if(a[fieldName] > b[fieldName])
               return sortDirection === 'asc' ? 1 : -1;
               else
               return 0;
               
           })
       }else{
           sortResult = Object.assign([], this.allIncidents);
           this.allIncidents = sortResult.sort(function(a,b){
               if(a[fieldName] < b[fieldName])
               return sortDirection === 'asc' ? -1 : 1;
               else if(a[fieldName] > b[fieldName])
               return sortDirection === 'asc' ? 1 : -1;
               else
               return 0;
           })
       }
       
   }

   // Handling edit functionality for My Incidents section
   handleRowAction(event) 
   {
       let row = event.detail.row;
       this.incidentRecId = row.Id;
       
       this.navigateToEditIncidentPage();
   
   }

   //Handling Notes view / Assignment functionality for Incidents in Queue sectionm
   handleAssignment(event) 
   {   this.toBeAssignedId = event.detail.row.Id;
       if(event.detail.action.name == 'Assign'){
           this.openAssignPopUp= true;
           
           }else{
               this.openNotesPopUp = true;
              // let row = event.detail.row;
              // this.incidentRecId = row.Id;
               //incId = event.detail.row.Id;
               for(var i=0;i<this.allIncidentsInQueue.length;i++){
               
                   if(this.allIncidentsInQueue[i].Id == this.toBeAssignedId){
                    this.notes =  this.allIncidentsInQueue[i].transitionDescription;
                    this.suggestedBIL = this.allIncidentsInQueue[i].suggestedBIL;
                      
                      
                   }
               }

       }
   }

   // Close pop-up
   handlePopUpCancel(){
       this.openAssignPopUp = false; 
       this.toBeAssignedId = '';
       
       this.suggestedBIL = '';
       this.openNotesPopUp = false;
       
       
   }

   

   //Assignment to be performed on clicking continue in Queue Section
   handlePopUpContinue(event){
       
       this.loadSpinner = true;
       //let row = event.detail.row;
       updateOwner({incidentToAssign:this.toBeAssignedId})
       .then(result => {
       
           this.error = undefined;
           if(result == 'Success'){
              
              getFilterData({isIRAPTUser:this.isIRAPTUser,SectionName:'Incidents In Queue',allSelectedStatus:this.statusvalueQueue,allSelectedSeverity:this.impactvalueQueue,allSelectedQueue:this.queuevalueQueue})
              .then(result =>{
                  var returnResult = JSON.parse(result);
                   
                  
                       this.noOfQueueIncidentsLabel = ' Incidents In Queue  ('+returnResult.incidentList_IncidentsInQueue.length+')';
                       this.allIncidentsInQueue = returnResult.incidentList_IncidentsInQueue;
                       this.allIncidentsInQueueBackUpForSearch = this.allIncidentsInQueue;
                       this.setPagesQueue(returnResult.incidentList_IncidentsInQueue,'Queue');
                       
                       if(this.myIncidentSectionExpanded){
                        this.handleMyIncidentsLoad();
                       }
                   
              }) .catch(error => {
               this.error = error;
               
               
           });
               this.showToast('You are now assigned to this Service Incident','success','dismissable');
               
           } 
           this.toBeAssignedId = '';
           this.loadSpinner = false;
           
   
       
       
       })
       .catch(error => {
           this.toBeAssignedId = '';
           this.error = error;
           this.loadSpinner = false;
           
       });
       this.openAssignPopUp = false; 
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

   // Show edit screen
   navigateToEditIncidentPage() 
   {
       
       
       
       this[NavigationMixin.Navigate]({
           type: "standard__recordPage",
           attributes: {
           recordId: this.incidentRecId,
           objectApiName: "SC_SI_Service_Incident__c",
           actionName: "edit"
           }
       });

   }   

  

   // Data load for all Incidents section  
   loadDataForAllIncidents(){
       this.loadSpinner = true;  
       

       getDataForFirstLoad({isFirstTimeLoad:false,sectionName:'All Open Incidents'})
       .then(result =>{
           var returnResult = JSON.parse(result);
           // Setting options for Status
           for(var i=0;i<returnResult.FilterStatus_SelectedvalueWrp.length;i++){
               if(returnResult.FilterStatus_SelectedvalueWrp[i].UI_Value != 'Incident Request'){
                this.StatusoptionsAllIncident.push({label: returnResult.FilterStatus_SelectedvalueWrp[i].UI_Value,value:returnResult.FilterStatus_SelectedvalueWrp[i].UI_Value});
                this.statusvalueAllIncident.push(returnResult.FilterStatus_SelectedvalueWrp[i].UI_Value);
               }
            }

            // Setting options for Severity
            for(var i=0;i<returnResult.FilterSeverity_SelectedvalueWrp.length;i++){
                this.ImpactoptionsAllIncident.push({label: returnResult.FilterSeverity_SelectedvalueWrp[i].UI_Value,value:returnResult.FilterSeverity_SelectedvalueWrp[i].UI_Value});
                this.impactvalueAllIncident.push(returnResult.FilterSeverity_SelectedvalueWrp[i].UI_Value);
            }
            this.noOfAllIncidentsLabel = ' All Open Incidents  ('+returnResult.incidentList_AllOpenIncidents.length+')';
            this.allIncidents = returnResult.incidentList_AllOpenIncidents;  
            this.allIncidentsBackUpForSearch = this.allIncidents;
            this.setPagesAllIncident(returnResult.incidentList_AllOpenIncidents,'AllIncident');
            this.showButtonsAllIncident = true;
            this.loadSpinner = false;
            }
            
            
       ).catch(error => {
        this.error = error;
        this.loadSpinner = false;
        });
      
   }


    
   // Data load for Queue section    
   loadDataForQueueSection(){
       this.loadSpinner = true;
       
       
      
       var isFirstTimeLoad = false;
       
        getDataForFirstLoad({isFirstTimeLoad:isFirstTimeLoad,sectionName:'Incidents In Queue'})
           .then(result =>{
               var returnResult = JSON.parse(result);
               //Loading backUp variables for JSON
                this.statusBackUpForJSON = returnResult.FilterStatus_SelectedvalueWrp;
                this.impactBackUpForJSON = returnResult.FilterSeverity_SelectedvalueWrp;
                this.queueBackUpForJSON = returnResult.FilterQueue_SelectedvalueWrp;
               // Setting options for Status
               for(var i=0;i<returnResult.FilterStatus_SelectedvalueWrp.length;i++){
                   this.StatusoptionsQueue.push({label: returnResult.FilterStatus_SelectedvalueWrp[i].UI_Value,value:returnResult.FilterStatus_SelectedvalueWrp[i].UI_Value});
                   if(returnResult.FilterStatus_SelectedvalueWrp[i].isEnabled) 
                   this.statusvalueQueue.push(returnResult.FilterStatus_SelectedvalueWrp[i].UI_Value);
                }

                // Setting options for Severity
                for(var i=0;i<returnResult.FilterSeverity_SelectedvalueWrp.length;i++){
                    this.ImpactoptionsQueue.push({label: returnResult.FilterSeverity_SelectedvalueWrp[i].UI_Value,value:returnResult.FilterSeverity_SelectedvalueWrp[i].UI_Value});
                    if(returnResult.FilterSeverity_SelectedvalueWrp[i].isEnabled)
                    this.impactvalueQueue.push(returnResult.FilterSeverity_SelectedvalueWrp[i].UI_Value);
                }
                // Setting options for Queue
               for(var i=0;i<returnResult.FilterQueue_SelectedvalueWrp.length;i++){
                this.queueOptions.push({label: returnResult.FilterQueue_SelectedvalueWrp[i].UI_Value,value:returnResult.FilterQueue_SelectedvalueWrp[i].UI_Value});
                if(returnResult.FilterQueue_SelectedvalueWrp[i].isEnabled)
                this.queuevalueQueue.push(returnResult.FilterQueue_SelectedvalueWrp[i].UI_Value);
                }
               this.isIRAPTUser = returnResult.isIRAPTUser;
               this.noOfQueueIncidentsLabel = ' Incidents In Queue  ('+returnResult.incidentList_IncidentsInQueue.length+')';
               this.allIncidentsInQueue = returnResult.incidentList_IncidentsInQueue;
               this.allIncidentsInQueueBackUpForSearch = this.allIncidentsInQueue;
               this.setPagesQueue(returnResult.incidentList_IncidentsInQueue,'Queue');
               this.loadSpinner = false;
               }
           ).catch(error => {
            this.error = error;
            this.loadSpinner = false;
        });
      
       }

      

       
           
       keycheck(event){
           if(event.which == 13){
               this.handleSearch(event);
           }
       }   
       
       myIncidentSectionView(event){
           if(this.myIncidentSectionExpanded){
               this.myIncidentSectionExpanded = false;
           }else{
               this.myIncidentSectionExpanded = true;
           }
       }

       queueSectionView(event){
            if(this.queueSectionExpanded){
                this.queueSectionExpanded = false;
            }else{
                this.queueSectionExpanded = true;
                if(this.allIncidentsInQueue.length == 0){
                    this.loadDataForQueueSection();
                }
            }
        }

        allIncidentSectionView(event){
            if(this.allIncidentSectionExpanded){
                this.allIncidentSectionExpanded = false;
            }else{
                this.allIncidentSectionExpanded = true;
                if(this.allIncidents.length == 0){
                    this.loadDataForAllIncidents();
                }
            }
        }

        handleShowTitlePopup(event){
            
            this.showTitlePopUp = true;
            this.titlePopUpValue = event.detail.data.title;
 
        }

        handleTitlePopUpCancel(event){
            this.showTitlePopUp = false;
            this.titlePopUpValue = '';
        }
           

       
  }