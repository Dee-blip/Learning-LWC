/**
 * @description       : 
 * @author            : apyati
 * @group             : 
 * @last modified on  : 09-21-2021
 * @last modified by  : apyati
 * Modifications Log 
 * Ver   Date         Author   Modification
 * 1.0   07-28-2021   apyati   Initial Version
**/
import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import refreshContractBaseline from '@salesforce/apex/l2qManageProductController.refreshContractBaseline';
import validateRefreshBaseline from '@salesforce/apex/l2qManageProductController.validateRefreshBaseline';

export default class L2qRefreshBaseLine extends LightningElement {

    @api opportunityId;
    @api enableSaveButton;
    showAlert = false;
    isLoading = false;


    @api invoke() {
       // console.log('Invoke Called' + this.opportunityId);
        this.validateEvent();
    }

    connectedCallback() {
        //console.log('connectedCallback Called=>optyid' + this.opportunityId);
        this.validateEvent();
    }

    validateEvent() {


        if (!this.enableSaveButton) {
            let message = 'There are unsaved changes. Please save your changes before refreshing baselines.';
            this.showToast('Error', message, 'error', '', []);
            this.handleClose();
        }
        else {

            validateRefreshBaseline({ opportunityID: this.opportunityId })
                .then(result => {
                    if (!result) {
                        this.showAlert = true;
                    }
                })
                .catch(error => {
                    this.isLoading = false;
                    console.error('validateRefreshBaseline =>error' + JSON.stringify(error));
                    let message = 'Unknown error';
                    if (Array.isArray(error.body)) {
                        message = error.body.map(e => e.message).join(', ');
                    } else if (typeof error.body.message === 'string') {
                        message = error.body.message;
                    }
                    this.showToast('Error', message, 'error', '', []);
                    this.handleClose();
                });
        }
    }
    refereshBaseline() {
        this.showAlert = false
        this.isLoading = true;
        refreshContractBaseline({ opportunityID: this.opportunityId })
            .then(result => {
                this.isLoading = false;
                let message = '';
                this.showToast('Refresh BaseLine Completed',message, 'success', '', []);
                this.dispatchEvent(new CustomEvent('refreshbaseline'));
            })
            .catch(error => {
                let message = 'Unknown error'
                console.log('error===', error);
                if (Array.isArray(error.body)) {
                    message = error.body.map(e => e.message).join(', ');
                } else if (typeof error.body.output === 'object') { //typeof yourVariable === 'object'
                    if (error.body.output.fieldErrors) {
                        for (let property in error.body.output.fieldErrors) {
                            if (Object.prototype.hasOwnProperty.call(error.body.output.fieldErrors, property)) {
                                message = error.body.output.fieldErrors[property][0].errorCode + '- ' + error.body.output.fieldErrors[property][0].message;
                            }
                        }
                    }
                    if (typeof error.body.output.errors === 'object') {
                        message = error.body.output.errors.map(e => e.message).join(', ');
                    }
                } else if (typeof error.body.message === 'string') {

                    message = error.body.message;
                    console.log('message', message);

                    if (message.includes("FIELD_CUSTOM_VALIDATION_EXCEPTION")) {
                        const index = message.indexOf("FIELD_CUSTOM_VALIDATION_EXCEPTION");
                        const lenght = message.length;
                        message = message.substring(index, lenght);
                        message = message.replace("FIELD_CUSTOM_VALIDATION_EXCEPTION,", "");

                    }
                }
                console.log('Error updating opportunity:');
                this.showToast('Error updating opportunity line items',
                    message,
                    'error',
                    'sticky',
                    []);
                this.handleClose();
            });
    }

    handleContinue() {
        this.showAlert = false;
        this.refereshBaseline();
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('closerefreshbaseline'));
    }

    showToast(title, message, variant, mode, messageData) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                messageData: messageData,
                variant: variant,
                mode: mode
            }),
        );
    }

}