import { LightningElement,api,track,wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi'
import { NavigationMixin } from 'lightning/navigation'
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import USER_ID from '@salesforce/user/Id';

import INCIDENT from "@salesforce/schema/BMCServiceDesk__Incident__c";

export default class Hd_incident_creator extends NavigationMixin(LightningElement) {

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
  activeSections = ['INCIDENT_DETAILS','OTHER_DETAILS'];
  get userClient(){
    return USER_ID;
  }

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

  handleChangeSBI = (event) =>{
      this.state.serviceBasedIncident = event.target.value;
      if(event.target.value === false){
        this.state.notifyDlEis = event.target.value;
      }

  }

  handlePicklistChange = (event) => {
    if(event.target.value == "1"){
      this.state.pageSupport = true;
    }
    else{
      this.state.pageSupport = false;
    }
  }
  
  handleChangeEIS = (event) =>{
      this.state.notifyDlEis = event.target.checked;
  }

  handleSubmitForm = (event) =>{
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
    this.template.querySelector('c-hd-file-uploader').uploadHelper(event.detail.id)
    .then(result =>{
      this.state.showSpinner = false;
      this.closeModal();
      this.navigateToRecordViewPage(event.detail.id)
      this.displayToast("Incident Created ","Please Navigate to detail page to take more actions","success");
    })
    .catch(error =>{
      this.state.showSpinner = false;
      this.closeModal();
      this.navigateToRecordViewPage(event.detail.id);
      this.displayToast("Failed to attach files", "Please Navigate to detail page to retry","warning");
    });
    

  }//

  handleError(event){
    event.preventDefault();
    this.state.showSpinner = false;
    let button = this.template.querySelector('[data-id="submitButton"]');
    button.disabled = false;
    let errorMessage = event.detail.detail;
    this.createErrorEvent(errorMessage);
    //this.displayToast("An error occurred","Please check the Inputs and try again","error");
  }

  createErrorEvent(errorMessage){
    let toastMessage = "An error occurred while trying to save the record. Please check the inputs and try again."
    var errorEvent = new CustomEvent("error", { detail :{ error:errorMessage, toast: toastMessage } });
    this.dispatchEvent(errorEvent);

  }

  navigateToRecordViewPage(id) {
    // View a custom object record.
    this[NavigationMixin.GenerateUrl]({
        type: 'standard__recordPage',
        attributes: {
            recordId: id,
            actionName: 'view',
        },
    })
    .then(recordUrl =>{
        window.open(recordUrl);
    });
  }

  displayToast(title,message,varient){
    const evt = new ShowToastEvent({
      title: title,
      message: message,
      variant: varient,
  });
  this.dispatchEvent(evt);
  }

  handleCancel(){
    this.template.querySelector('c-hd-Modal-Popup').close();
  }

  @api showModal(){
    this.state.objectApiName = '';
    this.state.objectApiName = INCIDENT.objectApiName;
    this.template.querySelector('c-hd-Modal-Popup').open();
  }

  @api closeModal(){
    this.template.querySelector('c-hd-Modal-Popup').close();
  }


}