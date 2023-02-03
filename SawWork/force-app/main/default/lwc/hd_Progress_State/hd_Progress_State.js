/* eslint-disable no-eval */
import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord , getFieldValue } from 'lightning/uiRecordApi';
import STATUS_FIELD from '@salesforce/schema/BMCServiceDesk__Incident__c.BMCServiceDesk__Status_ID__c';
import METADATAID from '@salesforce/label/c.HD_progress';
import getStatusId from '@salesforce/apex/HD_lwcUtilityClass.getStatusId';

const METADATA_FIELDS = ['HD_Instance__mdt.MasterLabel', 'HD_Instance__mdt.SettingValue__c'];
const INCIDENT_FIELD = [STATUS_FIELD];

export default class Hd_Progress_State extends LightningElement {
    
    @api recordId;

    statusValue = '';
    isButtonDisabled = true;
    displaySpinner;
    newsetOfStatus = [];
    newCombo = [];

    @wire(getRecord, { recordId: '$recordId', fields: INCIDENT_FIELD })
    incident;

    @wire(getRecord, { recordId: METADATAID, fields: METADATA_FIELDS })
    metadataRecord({data, error}) {
        if(data) {
            this.newsetOfStatus = data.fields.SettingValue__c.value.split(';');
        }
        else if (error) {
            console.log('errorMetadata===>'+JSON.stringify(error));
        }
    }

    @wire(getStatusId, { statusList: '$newsetOfStatus' })
    statusIds({data,error}) {
        if(data){
            let temp = [];
            data.forEach(element => {
                if(element.Name !== getFieldValue(this.incident.data, STATUS_FIELD))
                temp.push({label: element.Name, value: element.Id});
            });
            this.newCombo = temp;
        }
        else if(error) {
            console.log('errorApex===>'+JSON.stringify(error));
        }
    }
    
    get options() {
        return this.newCombo;
    }

    handleChange(event) {
        this.statusValue = event.detail.value;
        this.isButtonDisabled = false;
    }

    showToast(title,message,variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

    inProgress(event){
        this.displaySpinner = true;
        const incidentFields = event.detail.fields;
        incidentFields.BMCServiceDesk__FKStatus__c = this.template.querySelector('[data-id="progressStatus"]').value;
        this.template.querySelector('lightning-record-edit-form').submit(incidentFields);
    }

    handleSuccess(){
        this.displaySpinner = false;
        this.showToast('Status changed successfully !','','success');
        this.isButtonDisabled = true;
        this.statusValue = '';
        this.template.querySelector('[data-id="progressStatus"]').value = '';
        this.template.querySelector('[data-id="progressStatus"]').placeholder = '-None-';
        eval("$A.get('e.force:refreshView').fire();");
    }

    handleError(event){
        this.displaySpinner = false;
        this.showToast('Status not changed !',event.detail.detail,'error');
    }

}