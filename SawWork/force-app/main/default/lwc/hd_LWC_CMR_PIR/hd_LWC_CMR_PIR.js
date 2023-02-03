/* eslint-disable no-eval */
import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import changeCMRStatus from '@salesforce/apex/HD_CMRActions_Controller.changeCMRStatus';

export default class Hd_LWC_CMR_PIR extends LightningElement {
    @api parentChange;
    pirstatus;
    changecmr;
    isLoading = true;
    updatedCMR;

    @api set quickActionData(value) {
        this.pirstatus = JSON.parse(value).pirStatus;
        this.changecmr = JSON.parse(value).changeCMR;
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
        this.showToast('Error occurred while creating PIR.', '', 'error');
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
        changeCMRStatus({currentCMR: this.changecmr, status: this.pirstatus})
        .then((result) => {
            this.isLoading = false;
            this.updatedCMR = result;
            this.changecmr = this.updatedCMR;
            this.dispatchEvent(new CustomEvent('closemodal'));
            eval("$A.get('e.force:refreshView').fire();");
            this.showToast('PIR Created. Marking CMR to '+this.pirstatus, '', 'success');
        })
        .catch((error) => {
            this.isLoading = false;
            let errorMessage = '';
            let errors = error.body;
            for(let temp in errors){
                if (errors[temp]) {    
                    let temp1 = errors[temp];
                    try{
                        errorMessage = errorMessage + ' ' + temp1[0].message;
                    }catch(err){
                        continue;
                    }
                }
            }
            this.showToast('Error occurred while changing status to '+this.pirstatus , errorMessage , 'error'); 
        })
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
}