/**
 * @description       : 
 * @author            : apyati
 * @group             : GSM
 * @last modified on  : 09-08-2021
 * @last modified by  : apyati
 * Modifications Log 
 * Ver   Date         Author   Modification
 * 1.0   07-15-2021   apyati   Initial Version
**/
import { LightningElement, wire, api } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import ACCOUNT_ID from '@salesforce/schema/Opportunity.AccountId';
import OPP_ID from '@salesforce/schema/Opportunity.Id';

import ACCOUNT_NAME from '@salesforce/schema/Opportunity.Account.Name';
import CLOSE_DATE from '@salesforce/schema/Opportunity.CloseDate';
import FORECAST_CATEGORY from '@salesforce/schema/Opportunity.Forecast_Category__c';
import CURRENCY_ISO_CODE from '@salesforce/schema/Opportunity.CurrencyIsoCode';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import NAME from '@salesforce/schema/Opportunity.Name';
//import saveProductHandler from '@salesforce/apex/l2qManageProductController.saveProductHandler';
import saveOpptyAndProductHandler from '@salesforce/apex/l2qManageProductController.saveOpptyAndProductHandler';
import getCurrencyConversionRates from '@salesforce/apex/l2qManageProductController.getCurrencyConversionRates';
import checkRefreshBaselineWarning from '@salesforce/apex/l2qManageProductController.checkRefreshBaselineWarning';

import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation'
import { updateRecord } from 'lightning/uiRecordApi';
import hasEditAccess from '@salesforce/apex/l2qManageProductController.hasEditAccess';

const FIELDS = [ACCOUNT_ID, NAME, ACCOUNT_NAME, FORECAST_CATEGORY, CLOSE_DATE, CURRENCY_ISO_CODE, OPP_ID];


export default class L2qManageProductsOnOpp extends NavigationMixin(LightningElement) {
    @api recordId12;
    accountId;
    accountName;
    oppName;
    oppRecord;
    oppCurrency;
    oppClosedate;
    enableSaveButton = true;
    isParentDataLoaded = false;
    showAddRemoveContracts = false;
    showAddProducts = false;
    showChangeCurrency = false;
    showRefreshBaseline = false;
    showSpinnerParent = false;
    fieldsToSubmitArray = [];
    finalSave = false;
    isProductChange = false;
    isOppChange = false;
    selectedProducts = [];
    currencyRates = [];
    enableActions = true;
    hasAccess = false;
    oppLineItems = [];
    opportunityType;
    refreshContractBaselineFlag = false;

    connectedCallback() {
        console.log('recordId12 =>', this.recordId12);
        checkRefreshBaselineWarning({OpptyId : this.recordId12})
        .then(result => {
            this.refreshContractBaselineFlag = result;
            console.log('Result:'+result);
        })
        .catch(error => {
            this.refreshContractBaselineFlag = false;
            console.log('error:'+error);
        });
    }

    @wire(getRecord, { recordId: '$recordId12', fields : FIELDS})
    wiredRecord({ error, data }) {
        if (data) {
            this.oppRecord = data;
            this.oppName = this.oppRecord.fields.Name.value;
            this.accountId = this.oppRecord.fields.AccountId.value;
            this.accountName = this.oppRecord.fields.Account.value.fields.Name.value;
            this.oppCurrency = this.oppRecord.fields.CurrencyIsoCode.value;
            this.oppClosedate = this.oppRecord.fields.CloseDate.value;
            this.isParentDataLoaded = true;

            hasEditAccess({ recordId: this.recordId12 })
                .then(res => {
                    console.log('user has access' + res);
                    if (res) {
                        this.enableActions = false;
                        this.hasAccess = true;

                    }
                    getCurrencyConversionRates({ closedate: this.oppClosedate })
                        .then(result => {
                            this.currencyRates = JSON.parse(JSON.stringify(result));
                        })
                        .catch(error1 => {
                            console.log('error', ...error1);
                            let message = 'Unknown error';
                            if (Array.isArray(error1.body)) {
                                message = error1.body.map(e => e.message).join(', ');
                            } else if (typeof error1.body.message === 'string') {
                                message = error1.body.message;
                            }
                            this.showToast('Error loading opportunity',
                                message,
                                'error',
                                'sticky',
                                []);
                        });
                })
                .catch(err => {
                    console.log('error', ...err);
                    let message = 'Unknown error';
                    if (Array.isArray(err.body)) {
                        message = err.body.map(e => e.message).join(', ');
                    } else if (typeof err.body.message === 'string') {
                        message = err.body.message;
                    }
                    this.showToast('Error loading opportunity',
                        message,
                        'error',
                        'sticky',
                        []);
                })


        }
        else if (error) {
            console.log('error', ...error);
            let message = 'Unknown error';
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
            this.showToast('Error loading opportunity',
                message,
                'error',
                'sticky',
                []);
        }
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

    handleCancel() {
        setTimeout(()=>{
            var w = window;
            w.eval("$A.get('e.force:refreshView').fire();");   
        },3000);
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId12,
                objectApiName: 'Opportunity',
                actionName: 'view'
            },
        });
    }

    saveHandler() {
        console.log('saveHandler method');
        console.log('this.isOppChange', this.isOppChange);
        console.log('this.isProductChange', this.isProductChange);
        this.showSpinnerParent = true;
        this.finalSave = true;
        if (this.isOppChange || this.isProductChange) {
            this.template.querySelector('c-l-2q-opportunity-details').quickSaveHandler();
        }
    }

    quickSaveHandler() {
        this.showSpinnerParent = true;
        console.log('quick saveHandler method');
        console.log('this.isOppChange', this.isOppChange);
        console.log('this.isProductChange', this.isProductChange);
        if (this.isOppChange || this.isProductChange) {
            this.template.querySelector('c-l-2q-opportunity-details').quickSaveHandler();
        }
    }

    enableSaveButtons(event) {
        this.enableSaveButton = false;
        if (event.detail === 'Product') {
            this.isProductChange = true;
        }
        if (event.detail === 'Opportunity') {
            this.isOppChange = true;
        }
    }


    handleAddProductsButton() {
        this.showAddProducts = true;
    }

    handleAddProducts(event) {
        this.showAddProducts = false;
        this.template.querySelector('c-l-2q-product-details').addProducts(event.detail);
    }

    handleCloseAddProducts() {
        this.showAddProducts = false;
    }

    handleAddContractsButton() {
        this.showAddRemoveContracts = true;
    }

    handleAddContracts(event) {
        this.showAddRemoveContracts = false;
        this.template.querySelector('c-l-2q-product-details').addOrRemoveContracts(event.detail);
    }

    handleCloseAddContracts() {
        this.showAddRemoveContracts = false;
    }

    handleSelectedProducts(event) {
        this.selectedProducts = event.detail;
    }

    handleChangeCurrencyButton() {
        this.showChangeCurrency = true;
    }

    handleChangeCurrency() {
        this.showChangeCurrency = false;
        getRecordNotifyChange([{ recordId: this.recordId12 }]);
        this.template.querySelector('c-l-2q-product-details').queryOppProducts();

    }

    handleCloseChangeCurrency() {
        this.showChangeCurrency = false;
    }


    handleRefreshBaselineButton() {
        this.showRefreshBaseline = true;
    }

    handleRefreshBaseline() {
        this.showRefreshBaseline = false;
        this.refreshContractBaselineFlag = false;
        getRecordNotifyChange([{ recordId: this.recordId12 }]);
        this.template.querySelector('c-l-2q-product-details').queryOppProducts();
    }

    handleCloseRefreshBaseline() {
        this.showRefreshBaseline = false;
    }




    oppSaveHandler(event) {
        let isFinalSave = this.finalSave;
        this.showSpinnerParent = true;
        if (event.detail) {
            const fields = {};
            this.fieldsToSubmitArray = event.detail;
            this.fieldsToSubmitArray.forEach(f => {
                fields[f.fieldApiName] = f.value;
            });
            if (!this.isProductChange) {
                const recordInput = { fields };
                console.log('calling updateRecord');
                updateRecord(recordInput)
                    .then(() => {
                        getRecordNotifyChange([{ recordId: this.recordId12 }]);
                        this.enableSaveButton = true;
                        this.template.querySelector('c-l-2q-opportunity-details').enableViewMode();
                        this.showToast('Success',
                            'Record updated successfully',
                            'success',
                            '',
                            []);
                        if (isFinalSave) {
                            this.handleCancel(); // go back to main page
                        }
                        this.isOppChange = false;
                        this.showSpinnerParent = false;
                    })
                    .catch(error => {
                        console.log('error===', error);
                        let message = 'Unknown error';
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
                            if (Array.isArray(error.body.output.errors) && error.body.output.errors.length > 0) {
                                message = error.body.output.errors.map(e => e.message).join(', ');
                            }
                        }
                        else if (typeof error.body.message === 'string') {
                            message = error.body.message;
                            console.log('message', message);
                        
                            if (message.includes("FIELD_CUSTOM_VALIDATION_EXCEPTION")) {
                                const index = message.indexOf("FIELD_CUSTOM_VALIDATION_EXCEPTION,");
                                const lenght = message.length;
                                message = message.substring(index, lenght);
                                message = message.replace("FIELD_CUSTOM_VALIDATION_EXCEPTION,", "");

                            }

                        }
                        this.showToast('Error Updating opportunity',
                            message,
                            'error',
                            'sticky',
                            []);
                        this.showSpinnerParent = false;
                    });

            } else {
                this.template.querySelector('c-l-2q-product-details').quickSaveHandler();
            }
        }
    }


    setOpportunityType(event) {
        this.opportunityType = event.detail;
    }


    productSaveHandler(event) {
        this.oppLineItems = event.detail.oliRecords;
        let isFinalSave = this.finalSave;
        this.showSpinnerParent = true;

        if(this.oppLineItems){
            const fields = {};
            this.fieldsToSubmitArray.forEach(f => {
                fields[f.fieldApiName] = f.value;
            });

            if (fields.Opportunity_Type__c === 'Auto-Renewal') {
                fields.Opportunity_Type__c = 'Renewal';
            }
            fields.Validation_Override__c = true;

            console.log ('fields'+ JSON.stringify(fields));

            console.log('calling saveOpptyAndProductHandler');
            saveOpptyAndProductHandler({ oppty: JSON.stringify(fields), opptyProducts: JSON.stringify(this.oppLineItems) })
                .then(() => {
                    this.enableSaveButton = true;
                    getRecordNotifyChange([{ recordId: this.recordId12 }]);
                    this.template.querySelector('c-l-2q-opportunity-details').enableViewMode();
                    this.template.querySelector('c-l-2q-product-details').queryOppProducts();
                    this.template.querySelector('c-l-2q-product-details').enableViewMode();
                    this.showToast('Success',
                        'Record updated successfully',
                        'success',
                        '',
                        []);
                    this.showSpinnerParent = false;
                    if (isFinalSave) {
                        this.handleCancel(); // go back to main page
                    }
                    this.isProductChange = false;
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
                    this.showSpinnerParent = false;
                });
        }
    }

    hideSpinner(event) {
        if (event.detail === undefined || event.detail === null || event.detail === true) { // check if it is first time or not
            this.showSpinnerParent = false;
        }
    }

    showConfirmationDialogue = false;

    handleResetToBaseline() {
        this.showConfirmationDialogue = true;
    }

    churnCancelContract() {
        this.template.querySelector('c-l-2q-product-details').churnCancelContract();
    }
    resetToBaseLineHandlerOnChild() {
        this.template.querySelector('c-l-2q-product-details').resetToBaseLine();
        this.showConfirmationDialogue = false;
    }
    hideConfirmationDialogue() {
        this.showConfirmationDialogue = false;
    }
    validateOpportunityType(total) {
        let message;
        if (total < 0 && this.opportunityType === 'Non-Renewal: Add-On') {
            message = 'Non-Renewal: Add-On Opportunity cannot have LMRR';
        }
        else if (total < 0 && this.opportunityType === 'New Logo') {
            message = 'New Logo Opportunity cannot have LMRR';
        }
        else if (total > 0 && this.opportunityType === 'Non-Renewal: Downgrade') {
            message = 'Non-Renewal: Downgrade Opportunity cannot have GMRR';
        }
        else if (total > 0 && this.opportunityType === 'Churn') {
            message = 'Churn Opportunity cannot have GMRR';
        }
        else if (total === 0 && this.opportunityType === 'Auto-Renewal') {
            message = 'Auto-Renewal Opportunity Cannot have LMRR or GMRR , must be flat';
        }
        return message;
    }
    onSelectedContractsHandler(event) {
        this.selectedProducts = event.detail;
    }
}