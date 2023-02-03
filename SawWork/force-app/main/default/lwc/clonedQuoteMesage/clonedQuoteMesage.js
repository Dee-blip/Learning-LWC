/**
 * kimishra 18-FEB-2021 CPQ-674 added akamai-led integration products alert
 */
import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import pacDowntimeCheck from '@salesforce/apex/CPQSettings.getValue';
import pacPricingErrorLabel from '@salesforce/label/c.CPQ_pac_pricing_error';
import integrationAlertMessageLabel from '@salesforce/label/c.CPQ_Integration_Alert_Message';

import EXP_FIELD from '@salesforce/schema/SBQQ__Quote__c.CPQ_IsClonedQuote__c';
import PAC_PRICING_ERROR_FIELD from '@salesforce/schema/SBQQ__Quote__c.CPQ_PAC_pricing_error__c';
import INT_PRODUCTS_COUNT from '@salesforce/schema/SBQQ__Quote__c.CPQ_Integration_Products__c';
import INTEGRATION_TYPE from '@salesforce/schema/SBQQ__Quote__c.CPQ_Integration_Type__c';

const fields = [EXP_FIELD, PAC_PRICING_ERROR_FIELD, INT_PRODUCTS_COUNT, INTEGRATION_TYPE];

export default class ClonedQuoteMesage extends LightningElement {
    label = {
        pacPricingErrorLabel
    };
    @api recordId;
    quote;
    isClonedQuote;
    pricingError;

    @wire(getRecord, { recordId: '$recordId', fields })
    wiredRecord({ error, data }) {
        if (data) {
            console.log('entered wiredRecord');
            this.quote = data;
            this.isClonedQuote = this.quote.fields.CPQ_IsClonedQuote__c.value;
            this.pricingError = this.quote.fields.CPQ_PAC_pricing_error__c.value;


            if (this.quote.fields.CPQ_Integration_Products__c.value > 0  && this.quote.fields.CPQ_Integration_Type__c.value !== 'Akamai-Led') { // kimishra CPQ-674

                this.showToast('',
                    integrationAlertMessageLabel,
                    'warning',
                    'sticky',
                    [this.quote.fields.CPQ_Integration_Type__c.value]);

            }

        }
        else if (error) {
            let message = 'Unknown error';
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
            this.showToast('Error loading quote',
                message,
                error,
                '',
                []);
        }
    }

    @wire(pacDowntimeCheck, { settingName: 'PACdowntime' })
    wiredDowntimeCheck({ error, data }) {
        if (data) {
            console.log('data: ', data);
            this.showToast('Warning!', data, 'warning', 'sticky');

        } else if (error) {
            console.log('Error occurred:');
            console.log(error);
        }
    }

    get cloneDetail() {
        // return getFieldValue(this.quote.data, EXP_FIELD);
        return this.isClonedQuote;
    }

    get pacPricingError() {
        // return getFieldValue(this.quote.data, PAC_PRICING_ERROR_FIELD);
        return this.pricingError;
    }

    handleClick() {
        let record = {
            fields: {
                Id: this.recordId,
                CPQ_IsClonedQuote__c: false
            },
        };
        updateRecord(record)
            // eslint-disable-next-line no-unused-vars
            .then(() => {
                this.showToast('Success', '', 'success');

            })
            .catch(error => {
                this.showToast('Error on data save', error.message.body, 'error');

            });
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