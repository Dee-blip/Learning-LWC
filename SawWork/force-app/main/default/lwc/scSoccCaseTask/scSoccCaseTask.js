import { LightningElement, api, wire, track } from 'lwc'; 
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getTaskData from '@salesforce/apex/SC_SOCC_Case_LightningUtility.getTaskData';
import assignTask from '@salesforce/apex/SC_SOCC_Case_LightningUtility.assignTask';
import deferTask from '@salesforce/apex/SC_SOCC_Case_LightningUtility.deferTask';
import completeTask from '@salesforce/apex/SC_SOCC_Case_LightningUtility.completeTask';
import createTicketPushTask from '@salesforce/apex/SC_SOCC_Case_LightningUtility.createTicketPushTask';

const ACTIONS = [ 
     // { label: 'View', name: 'View' },
     { label: 'Edit', name: 'Edit' },
     { label: 'Assign To Me', name: 'Assign_To_Me' },
     { label: 'Defer', name: 'Defer' },
     { label: 'Close', name: 'Close' },
     { label: 'Close and Create', name: 'Close_and_Create' }
 ];

const COLUMNS = [
     //{label: 'Subject', fieldName: 'idUrl', type: 'url', typeAttributes: {label: { fieldName: 'subject' }, target: '_self'} },
     {label: 'Type', fieldName: 'type' },
     {label: 'Assigned To', fieldName: 'assignedToName' },
     //{label: 'Status', fieldName: 'status', cellAttributes: { class: { fieldName: 'cellColorStyle' } } },
     {label: 'Status', fieldName: 'idUrl', type: 'url', typeAttributes: {label: { fieldName: 'status' }, target: '_blank'}, cellAttributes: { class: { fieldName: 'cellColorStyle' } } },
     {type: 'action', typeAttributes: { rowActions: ACTIONS }}
];

const DEFER_OPTIONS = [
     { value: "4", label: "4" },
     { value: "8", label: "8" },
     { value: "12", label: "12" },
     { value: "24", label: "24" },
     { value: "48", label: "48" },
     { value: "72", label: "72" }  
];

const TICKETPUSH_OPTIONS = [
     { value: "24 Hours",lablel: "24hr"},
     { value: "72 Hours",label: "72hr"},
];

export default class ScSoccCaseTask extends NavigationMixin(LightningElement) {
     @api recordId; //case record id
     @track columns = COLUMNS; //table columns
     @track lTask; //List of tasks to be displayed
     @track isFocused = true; //To check if the component is focused
     @track statusFilter = 'All'; //filter value on Status field
     @track typeFilter = 'All'; //filter value on Type field
     @track isShowDeferModal = false; //To display/hide defer modal
     @track deferValue = "4"; //default defer value
     @track deferOptions = DEFER_OPTIONS;
     @track selectedTaskId;
     @track isDeferButtonDisable = false; //Enable/disbale Defer button on the modal

     @track channelName = '/topic/TaskUpdates'; //channel name
     @track minRefreshTime = 2000;
     @track refreshHandler; 
     
     //stores object which is returned from the promise when subscribed. Used to Unsubscribe it later.
     subscription = {};

     //Ticket Push Modal changes

     @track isTicketPushModal = false;
     @track ticketPushOptions = TICKETPUSH_OPTIONS;
     @track ticketPushHr = '';
     loadSpinner = false;
     @track taskMessage;

     //Init method
     connectedCallback(){
          //Added a event listener on load which listen on window/tab events
          this.getTableData();
          this.handleSubscribe();
          window.addEventListener("visibilitychange", this.listenForMessage.bind(this));
          
     }

     //Window/tab event listener clears the poller by checking if the tab is focused or not
     listenForMessage(message) {
          if (document.hidden || document.webkitHidden || document.msHidden || document.mozHidden) {
               this.isFocused = false;
          }
          else {
              console.log('User came back! Home refresh');
              this.manualRefreshTable();
              this.isFocused = true;
          }
      }

     //Get table data
     getTableData(){
          console.log("inside getTableData");
          getTaskData({
               caseId : this.recordId,
               statusFilter : this.statusFilter,
               typeFilter : this.typeFilter
          }).then(result => {
               this.lTask = result;
          }).catch(error =>{
               this.showToast("Error occured while loading the task table data!", error.body.message, "error");
          });
     }

     get statusFilterOptions() {
          return [
               { value: "All", label: "All" },
               { value: "Not Started", label: "Not Started" },
               { value: "In Progress", label: "In Progress" },
               { value: "Completed", label: "Completed" },
               { value: "Waiting on someone else", label: "Waiting on someone else" },
               { value: "Deferred", label: "Deferred" },
               { value: "Completed Important", label: "Completed Important" }   
          ];
     }
     get typeFilterOptions() {
          return [
               { value: "All", label: "All" },
               { value: "Alert Follow-up", label: "Alert Follow-up" },
               { value: "Attack", label: "Attack" },
               { value: "Call", label: "Call" },
               { value: "Conference Call", label: "Conference Call" },
               { value: "Manager Review", label: "Manager Review" },
               { value: "Peer Review", label: "Peer Review" },
               { value: "Post-Activation Check", label: "Post-Activation Check" },
               { value: "Research", label: "Research" },
               { value: "Task", label: "Task" },
               { value: "Triage", label: "Triage" },
               { value: "Initial Analysis - Kona", label: "Initial Analysis - Kona" },
               { value: "Security After Action Report - KONA", label: "Security After Action Report - KONA" },
               { value: "Periodic Review", label: "Periodic Review" },
               { value: "Security Config Change - KONA", label: "Security Config Change - KONA" },
               { value: "Runbook Updates", label: "Runbook Updates" },
               { value: "Attack Report – PLX", label: "Attack Report – PLX"},
               { value: "AME  Conference call", label: "AME  Conference call"},
               { value: "Customer Follow-Up", label: "Customer Follow-Up"},
               { value: "SVC Conference call", label: "SVC Conference call"}   
          ];
     }

     handleStatusFilterChange(e) {
          this.statusFilter = e.detail.value;
          this.manualRefreshTable();
     }
     handleTypeFilterChange(e) {
          this.typeFilter = e.detail.value;
          this.manualRefreshTable();
     }
     handleDeferValueChange(e) {
          this.deferValue = e.target.value;
     }

     //refresh table data
     manualRefreshTable(){
          console.log("inside refreshTable");
          if(this.refreshHandler){
               console.log("inside if refreshTable");
               clearTimeout(this.refreshHandler);
               this.refreshHandler = null;
          }
          this.getTableData();
     }

     // Handles subscribe button click
     handleSubscribe() {
          // Callback invoked whenever a new event message is received
          const messageCallback = (response) => {
               // Response contains the payload of the new message received
               console.log('New message received : ', JSON.stringify(response));
               let whatId = response["data"]["sobject"]["WhatId"];
               console.log('This What id : ' + whatId);
               console.log('This recordId id : ' + this.recordId); 
               if(whatId == this.recordId)
                    this.dynamicRefreshTableData();
               console.log("After dynamicRefreshTableData");
          };

          // Invoke subscribe method of empApi. Pass reference to messageCallback
          subscribe(this.channelName, -1, messageCallback).then(response => {
               // Response contains the subscription information on successful subscribe call
               console.log('Successfully subscribed to : ', JSON.stringify(response.channel));
               this.subscription = response;
               console.log(JSON.stringify(response));
          });
     }

     //Refresh table data - queueing all the refresh events and refreshing only once in 1 ms
     dynamicRefreshTableData() {
          console.log('refreshHandler : ' + this.refreshHandler);
          if(!this.refreshHandler && this.isFocused){
               this.refreshHandler = setTimeout(() => {
                    console.log('Under dynamicRefreshTableData method.');
                    this.getTableData();
                    this.refreshHandler = null;
               }, this.minRefreshTime);
               
          }
     }

     //Row actions
     handleRowActions(event) {
          if (event.detail.action.name === 'View'){
               let currentTaskId = event.detail.row.id;
               this.viewTask(currentTaskId);
          }
          else if (event.detail.action.name === 'Edit'){
               let currentTaskId = event.detail.row.id;
               this.editTask(currentTaskId);
          }
          else if (event.detail.action.name === 'Assign_To_Me'){
               let currentTaskId = event.detail.row.id;
               this.assignTaskToMe(currentTaskId);
          }
          else if (event.detail.action.name === 'Defer'){
               this.selectedTaskId = event.detail.row.id;
               this.deferValue = "4";
               this.isDeferButtonDisable = false;
               this.isShowDeferModal = true;
          }
          else if (event.detail.action.name === 'Close'){
               let currentTaskId = event.detail.row.id;
               this.closeAndCreateTask(currentTaskId, false);
          }
          else if (event.detail.action.name === 'Close_and_Create'){
               let currentTaskId = event.detail.row.id;
               this.closeAndCreateTask(currentTaskId, true);
          }
     }

     //Create New Task page
     createTask(){
          //default values
          const defaultValues = encodeDefaultFieldValues({
               WhatId: this.recordId
          });

          //navigate to create record in new tab
          this[NavigationMixin.GenerateUrl]({
               type: 'standard__objectPage',
               attributes: {
                   objectApiName: 'Task',
                   actionName: 'new'
               },
               state: {
                    defaultFieldValues: defaultValues
                    //recordTypeId: '012G00000010iIGIAY',
               }
          }).then(url => {
               window.open(url);
          });
     }

     //View Task in new tab
     viewTask(currentTaskId) {
          //navigate to edit record
          this[NavigationMixin.GenerateUrl]({
               type: 'standard__recordPage',
               attributes: {
                    recordId: currentTaskId,
                    actionName: 'view'
               }
          }).then(url => {
               window.open(url);
          });
     }

     //Create New Task page
     editTask(currentTaskId) {
          //navigate to edit record
          this[NavigationMixin.Navigate]({
               type: 'standard__recordPage',
               attributes: {
                    recordId: currentTaskId,
                    actionName: 'edit'
               }
          });
     }

     //Assign task to the logged-in user
     assignTaskToMe(currentTaskId) {
          assignTask({
               taskId : currentTaskId
          }).then(result => {
               this.showToast("HURRAY!!", "The task is successfully assigned to you!", "success");
               this.manualRefreshTable();

          }).catch(error =>{
               this.showToast(error.body.message, "", "error");
          });
     }

     //Defer Task
     saveDeferredTask() {
          console.log("Selected Defer value " + this.deferValue);
          this.isDeferButtonDisable = true;
          deferTask({
               taskId : this.selectedTaskId,
               deferValue : this.deferValue
          }).then(result => {
               this.showToast("HURRAY!!", "The task is successfully deferred!", "success");
               this.isShowDeferModal = false;
               this.isDeferButtonDisable = false;
               this.manualRefreshTable();

          }).catch(error =>{
               this.showToast(error.body.message, "", "error");
               this.isDeferButtonDisable = false;
          });
     }

     //Close Defer Modal
     closeDeferModal() {
          this.isShowDeferModal = false;
          this.isDeferButtonDisable = false;
     }

     //Close Task or mark complete
     closeAndCreateTask(currentTaskId, needCreate) {
          completeTask({
               taskId : currentTaskId
          }).then(result => {
               this.showToast("HURRAY!!", "The task is successfully marked complete!", "success");
               if(needCreate){
                    this.createTask();
               }
               this.manualRefreshTable();
               
          }).catch(error =>{
               this.showToast(error.body.message, "", "error");
          });
     }

     //Show Toast message
     showToast(title, message, variant) {
          const event = new ShowToastEvent({
               title: title,
               message: message,
               variant: variant
          });
          this.dispatchEvent(event);
     }

     initiateTicketPush(event){
          this.loadSpinner = true;
          this.ticketPushHr = event.target.value;
          console.log("The selected hour is " + this.ticketPushHr);
          console.log("The case Id is "+this.recordId);
          
          createTicketPushTask({
               taskHr : this.ticketPushHr,
               caseIdStr : this.recordId
          }).then(result => {
               this.taskMessage = result;
               if(this.taskMessage==='The ticket push task is created and email sent successfully')
               {
                    this.showToast("HURRAY!!", this.taskMessage, "success");
               }
               else{
                    this.showToast(this.taskMessage, "", "error");
               }
               
               this.manualRefreshTable();
               this.loadSpinner = false;
              
          }).catch(error =>{
               this.showToast(error.body.message, "", "error");
               this.loadSpinner = false;
          });
          this.isTicketPushModal = false;
     }
}