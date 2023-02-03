/*
Author          : Harshil Soni
Description     : This is the Create New Incident Service Cloud component for ACD 2.0, duplicated from hdCreateNewIncident component.
                  Look for comments starting with //ACD to find minor changes to the original component.
                  Please do not make any changes without consulting SC team.

Date             Developer         JIRA #             Description                                                       
------------------------------------------------------------------------------------------------------------------
9 OCT 2021       Harshil Soni      ACD2-348           Initial Component
------------------------------------------------------------------------------------------------------------------
*/

import { LightningElement,api,track,wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi'
import { NavigationMixin } from 'lightning/navigation'
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import INCIDENT from "@salesforce/schema/BMCServiceDesk__Incident__c";

export default class Sc_incident_creator extends NavigationMixin(LightningElement) {

  @track state = {
    recordTypeId : "012G0000000yTCBIA2",
    showSpinner: false,
    pageSupport : false,
    notifyDlEis: false,
    serviceBasedIncident: false,
    fileLimit: 1,
    fileSizeLimit: 1000000,
    objectApiName: 'BMCServiceDesk__Incident__c',
    spinnerMessage: 'Loading'
  }

  //ACD: added new variables to pass from caller
  @api isScreenPop;
  @api selectedUserId;
  
  //ACD: added variables to support custom toast in Lightning out 
  @track successToastVisible = false;
  @track errorToastVisible = false;
  @track warningToastVisible = false;
  @track submitMessage = '';



  get notifyDlEis(){
      return this.state.notifyDlEis;
  }

  get serviceBasedIncident(){
      return this.state.serviceBasedIncident;
  }

  get pageSupport(){
    return this.state.pageSupport;
  }

  get showSpinner(){
    return this.state.showSpinner;
  }

  get fileLimit(){
    return this.state.fileLimit;
  }

  get recordTypeId(){
    return this.state.recordTypeId;
  }

  set objectApiName(name){
      this.state.objectApiName = name;
  }

  get objectApiName(){
    return this.state.objectApiName;
  }

  set spinnerMessage(message){
    this.state.spinnerMessage = message;
  }

  get spinnerMessage(){
    return this.state.spinnerMessage;
  }

  get fileSizeLimit(){
    return this.state.fileSizeLimit;
  }

  //ACD: change to open Modal on render
  renderedCallback(){
    this.template.querySelector('c-sc-hd-modal-popup').open();
  }

  handleChangeSBI = (event) =>{
      this.state.serviceBasedIncident = event.target.value;
      if(event.target.value === false){
        this.state.notifyDlEis = event.target.value;
      }

  }

  handlePicklistChange = (event) => {
    if(event.target.value === "1"){
      this.state.pageSupport = true;
    }
    else{
      this.state.pageSupport = false;
    }
  }
  
  handleChangeEIS = (event) =>{
      this.state.notifyDlEis = event.target.checked;
  }

  handleSubmitForm = () =>{
    const allValid = [...this.template.querySelectorAll('lightning-input-field')]
    .reduce((validSoFar, inputCmp) => {
      return validSoFar && inputCmp.reportValidity();
    }, true);
    if (allValid) {
      this.state.showSpinner = true;
      let button = this.template.querySelector('[data-id="submitButton"]');
      button.disabled = true;
      let element = this.template.querySelector('[data-id="newIncident"]');
      element.submit();
    }
  }


   @wire(getObjectInfo, { objectApiName: INCIDENT.objectApiName })
   wiredObjectInfo({data, error}) {
    if (data) {
        let rtis = data.recordTypeInfos;
        this.state.recordTypeId = Object.keys(rtis).find(rti => rtis[rti].name === 'Helpdesk');
    } else if (error) {
        this.state.recordTypeId = "012G0000000yTCBIA2";
        }
    }

  handleSuccess(event) {
    //ACD
    console.log('id' + event.detail.id);
    this.template.querySelector('c-hd-file-uploader').uploadHelper(event.detail.id)
    .then(() =>{
      //ACD: Added condition to navigate and display custom toast
      if(!this.isScreenPop){
        this.state.showSpinner = false;
        //this.closeModal();
        this.navigateToRecordViewPage(event.detail.id)
        this.displayToast("Incident Created ","Please Navigate to detail page to take more actions","success");
      }
      else{
      this.successToastVisible = true;
      this.submitMessage = "Incident Created! Navigating to Record Page."
      setTimeout(() => { this.navigateToRecordViewPage(event.detail.id); }, 1000);
      }
    })
    .catch(() =>{
      this.state.showSpinner = false;
      //ACD: Added condition to navigate and display custom toast
      if(!this.isScreenPop){
        //this.closeModal();
        this.navigateToRecordViewPage(event.detail.id)
        this.displayToast("Incident Created. Failed to attach files", "Please Navigate to detail page to retry","warning");
      }
      else{
      this.warningToastVisible = true;
      this.submitMessage = "Incident Created, but failed to attach files. Navigating to Record Page."
      setTimeout(() => { this.navigateToRecordViewPage(event.detail.id); }, 2000);
      }
    });

  }

  handleError(event){
    event.preventDefault();
    this.state.showSpinner = false;
    let button = this.template.querySelector('[data-id="submitButton"]');
    button.disabled = false;
    let errorMessage = event.detail.detail;
    //ACD: Added condition to navigate and display custom toast
    if(!this.isScreenPop){
      this.createErrorEvent(errorMessage);
    }
    else{
    this.errorToastVisible = true;
    this.submitMessage = "Failed to Create Incident! " + errorMessage;
    setTimeout(() => { this.errorToastVisible = false; }, 2000);
    }
    //this.displayToast("An error occurred","Please check the Inputs and try again","error");
  }

  createErrorEvent(errorMessage){
    let toastMessage = "An error occurred while trying to save the record. Please check the inputs and try again."
    var errorEvent = new CustomEvent("error", { detail :{ error:errorMessage, toast: toastMessage } });
    this.dispatchEvent(errorEvent);

  }

  navigateToRecordViewPage(id) {
    // View a custom object record.
    //ACD: IF statement to check if running in lightning or classic context
    // if(document.referrer.indexOf(".lightning.force.com") > 0){
    // this[NavigationMixin.GenerateUrl]({
    //     type: 'standard__recordPage',
    //     attributes: {
    //         recordId: id,
    //         actionName: 'view',
    //     },
    // })
    // .then(recordUrl =>{
    //   //ACD
    //   console.log(recordUrl);
    //     //window.open(recordUrl);
    // });
    // }
    // else{
    //   window.location.assign('/'+id);
    // }
    this.warningToastVisible = false;
    this.errorToastVisible = false;
    this.successToastVisible = false;
    window.location.assign('/'+id);
  }

  displayToast(title,message,varient){
    const evt = new ShowToastEvent({
      title: title,
      message: message,
      variant: varient,
  });
  this.dispatchEvent(evt);
  console.log("event dispatched");
  }

  handleCancel(){
    //ACD: changed child component markup
    this.template.querySelector('c-sc-hd-Modal-Popup').close();
  }

  @api showModal(){
    this.state.objectApiName = '';
    this.state.objectApiName = INCIDENT.objectApiName;
    //ACD: changed child component markup
    this.template.querySelector('c-sc-hd-Modal-Popup').open();
  }

  @api closeModal(){
    //ACD: changed child component markup
    this.template.querySelector('c-sc-hd-Modal-Popup').close();
  }


}