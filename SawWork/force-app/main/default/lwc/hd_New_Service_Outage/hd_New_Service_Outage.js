import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Hd_New_Service_Outage extends LightningElement {
    type;
    currentRecordId;
    soValues;
    cloneRecord;
    isLoading = true;
    successMessage = 'Service Outage created successfully.';
    errorMessage = 'Error occured while creating Service Outage';

    @api set quickActionData(value) {
        this.currentRecordId = JSON.parse(value).currentRecordId;
        this.cloneRecord = this.currentRecordId;
        this.soValues = JSON.parse(value).soValues;
        this.type = JSON.parse(value).type;

        if(this.type === 'clone') {
            this.currentRecordId = '';
            for(let eachDiffSO in this.soValues) {
                if(this.soValues) {
                    for(let eachSO in this.soValues[eachDiffSO].soTimeValue) {
                        if(this.soValues[eachDiffSO].soTimeValue[eachSO].soValue.Id === this.cloneRecord){
                            this.soName = this.soValues[eachDiffSO].soTimeValue[eachSO].soValue.Name;
                            this.soDesc = this.soValues[eachDiffSO].soTimeValue[eachSO].soValue.BMCServiceDesk__Description__c;
                            this.soActive = this.soValues[eachDiffSO].soTimeValue[eachSO].soValue.BMCServiceDesk__Inactive__c;
                            this.soDIS = this.soValues[eachDiffSO].soTimeValue[eachSO].soValue.BMCServiceDesk__Display_in_Self_Service__c;
                            this.soStart = this.soValues[eachDiffSO].soTimeValue[eachSO].soValue.BMCServiceDesk__Start_Date__c;
                            this.soEnd = this.soValues[eachDiffSO].soTimeValue[eachSO].soValue.BMCServiceDesk__End_Date__c;
                            this.soService = this.soValues[eachDiffSO].soTimeValue[eachSO].soValue.Affected_Services_Picklist__c;
                            this.soType = this.soValues[eachDiffSO].soTimeValue[eachSO].soValue.Service_Outage_Type__c;
                            this.soBlackout = this.soValues[eachDiffSO].soTimeValue[eachSO].soValue.BMCServiceDesk__Blackout__c;
                            this.soSubServices = this.soValues[eachDiffSO].soTimeValue[eachSO].soValue.Sub_Services_Affected__c;
                            break;
                        }
                    }
                }
            }
        }
        else if(this.type === 'new') {
            this.soType = 'Enhanced Review Period';
        }
        else {
            this.successMessage = 'Service Outage edited successfully.';
            this.errorMessage = 'Error occured while editing Service Outage';
        }
    }

    get quickActionData() {
        return '';
    }

    onFormLoaded() {
        this.isLoading = false;
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('closemodal'));
    }

    onRecordSaveError() {
        this.isLoading = false;
        this.dispatchEvent(new CustomEvent('closemodal'));
        this.showToast(this.errorMessage, '', 'error');
    }

    handleSubmit(event) {
        event.preventDefault();
        const isInputsCorrect = [...this.template.querySelectorAll('lightning-input-field')]
            .reduce((validSoFar, inputField) => {
                return validSoFar && inputField.reportValidity();
            }, true);
        if (isInputsCorrect) {
            this.isLoading = true;
            this.template.querySelector('lightning-record-edit-form').submit();
        }
    }

    onRecordSaved() {
        this.isLoading = false;
        this.dispatchEvent(new CustomEvent('closemodal'));
        this.showToast(this.successMessage, '', 'success');
        this.refreshSO();
    }

    showToast(title,message,variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable',
        });
        this.dispatchEvent(event);
    }

    refreshSO() {
        this.dispatchEvent(new CustomEvent('refreshso', {
            bubbles: true,
            composed: true
        }));
    }

}