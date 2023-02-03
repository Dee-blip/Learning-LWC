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
import { LightningElement, wire, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'

import fetchOpportunity from '@salesforce/apex/SF1_ChangeCurrencyController.fetchOpportunity';
import loadCurrencyPicklist from '@salesforce/apex/SF1_ChangeCurrencyController.loadCurrencyPicklist';
import checkErrors from '@salesforce/apex/SF1_ChangeCurrencyController.checkErrors';
import convertCurrency from '@salesforce/apex/SF1_ChangeCurrencyController.convertCurrency';



export default class L2qChangeCurrency extends LightningElement {
    @api opportunityId ;
    @api opportunityCurrency;
    @api enableSaveButton;
    showCurrency = false;
    currencyOptions =[];
    opptyObject;
    @track isLoading =false;
    selectedCurrency;

    /*
    @wire(getObjectInfo, { objectApiName: OPPORTUNITY_OBJECT })
    opportunityObjectInfo;

    @wire(getRecord, { recordId: '$opportunityId', fields: [OPPORTUNITY_CURRENCY_FIELD] })
    getWiredRecord({ data, error }) {
        if (data) {
            console.log('data>>>', { ...data });
            this.opptyCurrency = getFieldValue(data, OPPORTUNITY_CURRENCY_FIELD);
            this.showCurrency = true;
        }
        else if (error) {
            console.log('error>>>', { ...error });
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$opportunityObjectInfo.data.defaultRecordTypeId', fieldApiName: '$currencyFieldApi' })
    getCurrencyValues({ error, data }) {
        if (error) {
            console.log('error>>>', { ...error });
        } else if (data) {
            console.log('data>>>', { ...data });
            this.currencyValues = data;
        }
    }
  */


    connectedCallback() {
        console.log('connectedCallback' + this.opportunityId);
        this.validateEvent();
    }

    @wire(fetchOpportunity, { oppId: '$opportunityId' })
    wiredRecord({ error, data }) {
        if (error) {
            console.log('error>>>', { ...error });
        } else if (data) {
            console.log('data wiredRecord>>>', { ...data });
            this.opptyObject = JSON.parse(JSON.stringify(data));
        }
    }

    @wire(loadCurrencyPicklist, { sobjectName: "Opportunity", picklistFieldName: "CurrencyIsoCode" })
    wiredValues({ error, data }) {
        if (error) {
            console.log('error>>>', { ...error });
        } else if (data) {
            console.log('data wiredValues>>>'+JSON.stringify(data));
            let temp_data = JSON.parse(JSON.stringify(data));
            let options =[];
            temp_data.forEach(iso => {
                let option= {
                    label : iso,
                    value :iso
                }
                options.push(option);
            });
            this.currencyOptions = [...options];
            this.selectedCurrency = this.opportunityCurrency;
            console.log('data currencyValues>>>'+ JSON.stringify(this.currencyOptions));
        }
    }

    validateChangeCurrency() {
        console.log('validateCurrency');
        this.isLoading = true;
        checkErrors({ pageObject: this.opptyObject })
            .then(result => {
                this.isLoading = false;
                let message = result;
                if (message === 'Success') {
                    console.log('validateCurrency success');
                    this.changeCurrency();
                } else {
                    this.showToast('Validation Error Change Curreny', message, 'error', '', []);
                    this.handleClose();
                }
            })
            .catch(error => {
                this.isLoading = false;
                console.error('Change Currency =>error' + JSON.stringify(error));
                let message = 'Unknown error';
                if (Array.isArray(error.body)) {
                    message = error.body.map(e => e.message).join(', ');
                } else if (typeof error.body.message === 'string') {
                    message = error.body.message;
                }
                this.showToast('Error Change Curreny fetchOpportunity', message, 'error', '', []);
                this.handleClose();
            });

    }


    changeCurrency() {
        this.isLoading = true;
        console.log('change currency' + this.opptyObject.CurrencyIsoCode);
        convertCurrency({ pageObject: this.opptyObject })
            .then(result => {
                let message = result;
                if (message === 'Success') {
                    this.isLoading = false;
                    message = 'Currency updated Successfully'
                    this.showToast(' Change Curreny', message, 'Success', '', []);
                    this.dispatchEvent(new CustomEvent('changecurrency'));
                } else {
                    this.isLoading = false;
                    this.showToast(' Error Change Curreny', message, 'error', '', []);
                    this.handleClose();
                }
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


    handleSave() {
        this.opptyObject.CurrencyIsoCode = this.selectedCurrency;
        this.validateChangeCurrency();
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('closechangecurrency'));
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

    validateEvent() {
        console.log('validateEvent Called =>enablesave' + this.enableSaveButton);
        if (!this.enableSaveButton) {
            let message = 'There are unsaved changes. Please save your changes before changing the currency.';
            this.showToast('Error Change Currency', message, 'error', '', []);
            this.handleClose();
        }
        else {
            this.showCurrency = true;
        }
    }
    handleChange(event){
        this.selectedCurrency = event.detail.value;
    }

}