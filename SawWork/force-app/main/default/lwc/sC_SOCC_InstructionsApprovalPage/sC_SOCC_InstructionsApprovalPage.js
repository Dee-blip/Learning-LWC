/* 
Date                 Developer                  JIRA #          Description                                                       
-----------------------------------------------------------------------------------------------------------------
14 Dec 2020         Tejaswini                   ESESP-3732      Giving permission to SSP's to view instructions created by others
18 feb 2021         Tejaswini                   ESESP-4822      Runbooks Phase 2: Streamline Runbooks Approval Process
*/
import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
//import { refreshApex } from "@salesforce/apex";
import getLInstructions from '@salesforce/apex/SC_SOCC_Instruction_Manager.getLInstructions';
import getData from '@salesforce/apex/SC_SOCC_Instruction_Manager.getData';
import approveInstruction from '@salesforce/apex/SC_SOCC_Instruction_Manager.approveInstruction';
import rejectInstruction from '@salesforce/apex/SC_SOCC_Instruction_Manager.rejectInstruction';
import saveEditedInstruction from '@salesforce/apex/SC_SOCC_Instruction_Manager.saveEditedInstruction';
import revokeInstruction from '@salesforce/apex/SC_SOCC_Instruction_Manager.revokeInstruction';
import getChangedBulkInstructions from '@salesforce/apex/SC_SOCC_Instruction_Manager.getChangedBulkInstructions';
import bulkApproveInstruction from '@salesforce/apex/SC_SOCC_Instruction_Manager.bulkApproveInstruction';
import bulkRejectInstruction from '@salesforce/apex/SC_SOCC_Instruction_Manager.bulkRejectInstruction';
import bulkRevokeInstruction from '@salesforce/apex/SC_SOCC_Instruction_Manager.bulkRevokeInstruction';

const APPROVE_REJECT_ACTIONS = { label: 'Actions', type: 'scSoccActionInstruction', initialWidth: 75, typeAttributes: { insId: { fieldName: 'id' } } };

const REVOKE_EDIT_ACTIONS = { label: 'Actions', type: 'scSoccRevokeInstruction', initialWidth: 75, typeAttributes: { insId: { fieldName: 'id' } } };

const OTHER_COLUMNS = [
     { label: 'Name', type: 'scSoccViewInstruction', typeAttributes: { insId: { fieldName: 'id' }, insName: { fieldName: 'name' } } },
     {label: 'Akam Case Id', fieldName: 'caseId', type: 'url', typeAttributes: {label: { fieldName: 'akamCaseId' }, target: '_self'}},
     { label: 'Instruction Type', fieldName: 'instructionsType' },
     {label: 'Object Name', fieldName: 'objectId', type: 'url', typeAttributes: {label: { fieldName: 'objectName' }, target: '_self'}},
     { label: 'Object Type', fieldName: 'objectType' },
     { label: 'Submitted By', fieldName: 'createdBy'}

];

export default class SC_SOCC_InstructionsApprovalPage extends LightningElement {
     //Reactive properties
     @track isShiftManager = false; //Is logged in user a shift manager
     @track isSSP = false; //Is logged in user a SSP or not
     @track lInstructions; //List of pending instructions
     @track error; //Error message
     @track columns; //Column list for table
     @track curInstruction; //Current Instruction to be approved/rejected/revoked
     @track isShowApprovalRecModal = false; //to show modal
     @track isCancel = false;
     @track isApprove = false;
     @track isReject = false;
     @track isRevoke = false;
     @track isSave = false;

     //for bulk actions
     @track recordsCount = 0; //To show selected records' count
     @track isShowBulkConfModal = false;
     @track isBulkApprove = false;
     @track isBulkReject = false;
     @track isBulkRevoke = false;
     @track hasBulkInstructionsUpdated = false;
     @track lUpdatedBulkInstructions; // List of instructions which are updated before the bulk action

     //Non-reactive properties
     selectedRecords = []; //List of selected records

     //PD Record Id
     @api recordId;
     @track pdId = '';
     
     @track approvedComment='';
     @track escalationDetails='';
     @track variant='warning';
     
     @track count;
     
     //Init method
     connectedCallback(){
          if(this.recordId)
               this.pdId = this.recordId;
          
     }



     @wire(getData, {pdId: '$pdId'}) wireGetGata(returnData) {
          let { data, error } = returnData;
          console.log(returnData);

          if (data) {
               this.isShiftManager = data.isShiftManager;
               this.isSSP=data.isSSP;
               //this.isShiftManager = false;
               this.lInstructions = data.lInstructions;
               
               
               let columns = []
               if (this.isShiftManager)
                    columns.push(APPROVE_REJECT_ACTIONS);
               else
                    columns.push(REVOKE_EDIT_ACTIONS);

               //push elements from OTHER_COLUMNS to columns array
               Array.prototype.push.apply(columns, OTHER_COLUMNS);
               this.columns = columns;

               //this.curInstruction = data[0];
               this.error = undefined;
          }
          else if (error) {
               this.lInstructions = undefined;
               this.error = error;
          }

     }

     //Show single rec view modal
     showViewModal(event) {
          this.isCancel = false;
          this.isApprove = true;
          this.isReject = true;
          this.isRevoke = true;
          this.isSave = false;

          this.showModal(event);
     }

     //Show single rec approval modal
     showApproveModal(event) {
          this.isCancel = true;
          this.isApprove = true;
          this.isReject = false;
          this.isRevoke = false;
          this.isSave = false;
          
          //this.showCustomNotice();
          this.showModal(event);
          
     }

     //Show single rec reject modal
     showRejectModal(event) {
          this.isCancel = true;
          this.isApprove = false;
          this.isReject = true;
          this.isRevoke = false;
          this.isSave = false;

          this.showModal(event);
     }

     //Show single rec revoke modal
     showRevokeModal(event) {
          this.isCancel = true;
          this.isApprove = false;
          this.isReject = false;
          this.isRevoke = true;
          this.isSave = false;

          this.showModal(event);
     }

     //Show single rec Edit modal
     showEditModal(event) {
          this.isCancel = true;
          this.isApprove = false;
          this.isReject = false;
          this.isRevoke = false;
          this.isSave = true;

          this.showModal(event);
     }

     //show modal and set the current record value
     showModal(event) {
          
          this.isShowApprovalRecModal = true;
          let curInstructionId = event.detail;

          let lInstructions = this.lInstructions;
          for (let eachInstruction of lInstructions) {
               if (eachInstruction.id === curInstructionId)
                    this.curInstruction = JSON.parse(JSON.stringify(eachInstruction));
          }
          
     }
     
     //Close Modal which shows Instruction approval record
     closeApprovalRecModal() {
          this.isShowApprovalRecModal = false;
          this.approvedComment='';
     }
     //Get the comment
     captureComment(event){
          this.approvedComment = event.target.value; 
          
     }
     //Approve record
     approveRecord() {
          this.isShowApprovalRecModal = false;
          
          approveInstruction({
               pdId : this.pdId,
               instructionRecJSON: JSON.stringify(this.curInstruction),
               isShiftManager: JSON.stringify(this.isShiftManager),
               isSSP: JSON.stringify(this.isSSP),
               comment: this.approvedComment
          })
               .then(result => {
                    this.lInstructions = result;
                    this.showToast("HURRAY!!", "The instruction is approved successfully!", "success");
               })
               .catch(error => {
                    console.log(error);
                    this.showToast(error.body.message, "", "error");
               });
          this.approvedComment='';
     }

     //Reject record  
     rejectRecord() {
          this.isShowApprovalRecModal = false;
          rejectInstruction({
               pdId : this.pdId,
               instructionRecJSON: JSON.stringify(this.curInstruction),
               isShiftManager: JSON.stringify(this.isShiftManager),
               isSSP: JSON.stringify(this.isSSP),
               comment: this.approvedComment
          })
               .then(result => {
                    this.lInstructions = result;
                    this.showToast("HURRAY!!", "The instruction is rejected successfully!", "success");
               })
               .catch(error => {
                    console.log(error);
                    this.showToast(error.body.message, "", "error");
               });
          this.approvedComment='';
     }

     //Save Edited Record
     saveRecord(){
          let pendingInsValue = this.template.querySelector('[data-id="pendingInsValue"]');

          //Field length validations
          if(!pendingInsValue.value)
               this.showToast("Error: Please provide an input!", "", "error");
          else if(pendingInsValue.value.length > 32767)
               this.showToast("Error: Max input length is 32767!", "", "error");
          else{
               this.isShowApprovalRecModal = false;
               this.curInstruction.value = pendingInsValue.value;
               if (this.curInstruction.isOwner)
               {
               saveEditedInstruction({
                    pdId : this.pdId,
                    instructionRecJSON: JSON.stringify(this.curInstruction),
                    isShiftManager: JSON.stringify(this.isShiftManager),
                    isSSP: JSON.stringify(this.isSSP)
               })
                    .then(result => {
                         this.lInstructions = result;
                         this.showToast("HURRAY!!", "The instruction is saved successfully!", "success");
                    })
                    .catch(error => {
                         this.showToast(error.body.message, "", "error");
                    });
               }
               else
                    this.showToast("You can't edit the  records created by others", " ","error");
               }
          }
     

     //Revoke Record
     revokeRecord() {
          this.isShowApprovalRecModal = false;
          if(this.curInstruction.isOwner)
          {
               revokeInstruction({
                    pdId : this.pdId,
                    instructionRecJSON: JSON.stringify(this.curInstruction),
                    isShiftManager: JSON.stringify(this.isShiftManager),
                    isSSP:JSON.stringify(this.isSSP)
               })
                    .then(result => {
                         this.lInstructions = result;
                         this.showToast("HURRAY!!", "The instruction is revoked successfully!", "success");
                    })
                    .catch(error => {
                         console.log(error);
                         this.showToast(error.body.message, "", "error");
                    });
          }
          else{
               this.showToast("You can't revoke the instructions submitted by others", "", "error");
          }
     }

     //Get latest selected rows
     getSelectedRecords(event) {
          // getting selected rows
          //const selectedRows = event.detail.selectedRows;
          this.selectedRecords = event.detail.selectedRows;
          console.log(this.selectedRecords);
          this.recordsCount = event.detail.selectedRows.length;
     }

     //Show bulk approval modal
     showBulkApproveConfModal() {
          if (this.selectedRecords.length > 0) {
               //Checking if any of the selected instruction is already updated
               //this.template.querySelector('c-lwc-custom-toast-event').showCustomNotice();
               let selectedRecords = this.selectedRecords;
               //let escalationDetails1='';
               let recCount=0;
               for (let eachSelectedRecord of selectedRecords) {
                    
                    if(eachSelectedRecord.handler!=null && eachSelectedRecord.escListId==null) {    
                    //escalationDetails1+='Handler: ' + eachSelectedRecord.handlerName;
                    recCount++;
                    }
               }
               this.count=recCount;

               
               getChangedBulkInstructions({
                    lInstructionRecJSON: JSON.stringify(this.selectedRecords)
               })
               .then(result => {
                    if(result.length>0){
                         this.hasBulkInstructionsUpdated = true;
                         this.lUpdatedBulkInstructions = result;
                    }
                    else
                         this.hasBulkInstructionsUpdated = false;
               })
               .catch(error => {
                    this.showToast(error.body.message, "", "error");
               });
     
               this.isShowBulkConfModal = true;
               this.isBulkApprove = true;
               this.isBulkReject = false;
               this.isBulkRevoke = false;
          }
          else
               this.showToast("Please select at least 1 row!", '', "error");
     }

     //Show bulk reject modal
     showBulkRejectConfModal() {
          if (this.selectedRecords.length > 0) {
               let selectedRecords = this.selectedRecords;
               //let escalationDetails1='';
               let recCount=0;
               for (let eachSelectedRecord of selectedRecords) {
                    if(eachSelectedRecord.handler!=null && eachSelectedRecord.escListId==null) {    
                         //escalationDetails1+=' Handler: ' + eachSelectedRecord.handlerName;
                         recCount++;
                         }
                    }
               
               this.count=recCount;
               
               //Checking if any of the selected instruction is already updated
               getChangedBulkInstructions({
                    lInstructionRecJSON: JSON.stringify(this.selectedRecords)
               })
               .then(result => {
                    if(result.length>0){
                         this.hasBulkInstructionsUpdated = true;
                         this.lUpdatedBulkInstructions = result;
                    }
                    else
                         this.hasBulkInstructionsUpdated = false;
               })
               .catch(error => {
                    this.showToast(error.body.message, "", "error");
               });
               this.isShowBulkConfModal = true;
               this.isBulkApprove = false;
               this.isBulkReject = true;
               this.isBulkRevoke = false;
          }
          else
               this.showToast("Please select at least 1 row!", '', "error");
     }

     //Show bulk revoke modal
     showBulkRevokeConfModal() {
          if (this.selectedRecords.length > 0) {
               //Checking if any of the selected instruction is already updated
               getChangedBulkInstructions({
                    lInstructionRecJSON: JSON.stringify(this.selectedRecords)
               })
               .then(result => {
                    if(result.length>0){
                         this.hasBulkInstructionsUpdated = true;
                         this.lUpdatedBulkInstructions = result;
                    }
                    else
                         this.hasBulkInstructionsUpdated = false;
               })
               .catch(error => {
                    this.showToast(error.body.message, "", "error");
               });
               this.isShowBulkConfModal = true;
               this.isBulkApprove = false;
               this.isBulkReject = false;
               this.isBulkRevoke = true;
          }
          else
               this.showToast("Please select at least 1 row!", '', "error");
     }

     //Hide bulk modal
     closeBulkConfModal() {
          this.isShowBulkConfModal = false;
          this.approvedComment='';
     }

     //Bulk Approve
     bulkApproveRecord() {
          this.isShowBulkConfModal = false;
          bulkApproveInstruction({
               pdId : this.pdId,
               lInstructionRecJSON: JSON.stringify(this.selectedRecords),
               isShiftManager: JSON.stringify(this.isShiftManager),
               isSSP: JSON.stringify(this.isSSP),
               comment: this.approvedComment
          })
               .then(result => {
                    this.lInstructions = result;
                    this.showToast("HURRAY!!", "The instructions are approved successfully!", "success");
               })
               .catch(error => {
                    console.log(error);
                    this.showToast(error.body.message, "", "error");
               });
          this.approvedComment='';
     }

     //Bulk Reject
     bulkRejectRecord() {
          this.isShowBulkConfModal = false;
          
          bulkRejectInstruction({
               pdId : this.pdId,
               lInstructionRecJSON: JSON.stringify(this.selectedRecords),
               isShiftManager: JSON.stringify(this.isShiftManager),
               isSSP: JSON.stringify(this.isSSP),
               comment: this.approvedComment
          })
               .then(result => {
               this.lInstructions = result;
               this.showToast("HURRAY!!", "The instructions are rejected successfully!", "success");
               })
               .catch(error => {
               console.log(error);
               this.showToast(error.body.message, "", "error");
               });
          this.approvedComment='';

     }

     ///Bulk Revoke
     bulkRevokeRecord() {
          this.isShowBulkConfModal = false;
          let checkOwner=false;
          this.selectedRecords.forEach(element => {
               if(!element.isOwner)
                    checkOwner=true;
          });
          if(!checkOwner)
          {
               bulkRevokeInstruction({
                    pdId : this.pdId,
                    lInstructionRecJSON: JSON.stringify(this.selectedRecords),
                    isShiftManager: JSON.stringify(this.isShiftManager),
                    isSSP: JSON.stringify(this.isSSP)
               })
                    .then(result => {
                         this.lInstructions = result;
                         this.showToast("HURRAY!!", "The instructions are revoked successfully!", "success");
                    })
                    .catch(error => {
                         console.log(error);
                         this.showToast(error.body.message, "", "error");
                    });
          }
          else{
               this.showToast("You can't revoke the instructions submitted by others", "", "error");
          }
     }

     //Refresh table records
     refreshData(){
          getLInstructions({
               pdId : this.pdId,
               isShiftManager: JSON.stringify(this.isShiftManager),
               isSSP: JSON.stringify(this.isSSP)
          })
               .then(result => {
                    this.lInstructions = result;
               })
               .catch(error => {
                    console.log(error);
                    this.showToast(error.body.message, "", "error");
               });
     }

     //For ObjectType field
     //To check if Object is Handler or not
     get isObjectHandler() {
          return this.curInstruction.objectType == "Handler" ? true : false;
     }
     //To check if Object is Policy Domain or not
     get isObjectPD() {
          return this.curInstruction.objectType == "Policy Domain" ? true : false;
     }
     //To check if Object is Escalation List or not
     get isObjectEL() {
          return this.curInstruction.objectType == "Escalation List" ? true : false;
     }

     //For Instruction field
     //To check if Situation Instruction
     get isSituationInstruction() {
          return this.curInstruction.instructionsType == "Situation Instruction" ? true : false;
     }
     //To check if Ignore Condition 
     get isIgnoreCondition() {
          return this.curInstruction.instructionsType == "Ignore Condition" ? true : false;
     }
     //To check if Policy Domain Instruction 
     get isPDInstruction() {
          return this.curInstruction.instructionsType == "Policy Domain Instruction" ? true : false;
     }
     //To check if Escalation List Instruction
     get isELInstruction() {
          return this.curInstruction.instructionsType == "Escalation List Instruction" ? true : false;
     }
     //To check if Escalation List Instruction
     get isShowCancelButton() {
          return !(this.isShiftManager && !this.isCancel);
     }
     //To check if Escalation List id Present for Handler or not
     get isEsclListPresent(){
          //alert(this.curInstruction.escListId);
          if(this.curInstruction.escListId == null){
               return true;
          }
          return false;
     }
     get isEsclPresentinBulk()
     {
          if(this.count!==0){
               return true;
          }
          
          return false;
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
    
     

     get mainDivClass() { 
          return 'slds-notify slds-notify_toast slds-theme_'+this.variant;
     }

     get messageDivClass() { 
          return 'slds-icon_container slds-icon-utility-'+this.variant+' slds-icon-utility-success slds-m-right_small slds-no-flex slds-align-top';
     }

     closeModel() {
          const toastModel = this.template.querySelector('[data-id="toastModel"]');
          toastModel.className = 'slds-hide';
     }

     
}