import { LightningElement, track, api } from 'lwc';
// import LOCALE from '@salesforce/i18n/locale';
import CURRENCY from '@salesforce/i18n/currency';

const LOCALE = "en-US";
export default class InputCurrency extends LightningElement {
    @api label;
    @api precision = 2;
    @api variant; //label-inline, label-hidden
    @api placeholder;
    @api required;
    @api currency;
    @api step;

    @track displayType = 'text'; // number / text
    @api value;
    // @track textValue;
    get textValue() {
        return this.value ? this.numberFormat.format(this.value): '';
    }

    get displayValue() {
        return this.displayType === 'text' ? this.textValue : this.value;
    }

    get formattedPlaceholder() {
        let formattedStr = this.numberFormat.formatToParts()[0].value + this.placeholder;
        return formattedStr;
    }

    get numberFormat() {
        return new Intl.NumberFormat(LOCALE, {
            style: 'currency' ,
            currency: this.currency || CURRENCY,
            currencyDisplay: 'symbol'
        });
    }
 
    handleFocus(ev) {
        this.displayType = 'number';
    } 

    handleChange(ev) {

        this.value = ev.target.value;
        // Create change event
        let changeEv = new CustomEvent('valuechange', { detail: { value: this.value } });
        // Dispatches "change" event.
        this.dispatchEvent(changeEv);   
    }


    handleBlur(ev) {
        this.displayType = 'text';
        this.reportValidity();
    }

    @api checkValidity() {
        return this.value || !this.required;
    }

    @api reportValidity() {

        if(this.checkValidity()) {
            this.inpErrorMsg  = '';
            this.inpCss =  'slds-form-element__control';
            return true;
        }
        this.inpCss = 'slds-form-element__control slds-has-error';
        this.inpErrorMsg = 'Complete this field.'
        return false;
    }
    @track inpCss = 'slds-form-element__control';

    get fromCss() {
        if(this.variant === 'label-inline') {
            return 'slds-form-element slds-form-element_horizontal';
        }
        else if(this.variant === 'label-stacked') {
            return 'slds-form-element slds-form-element_stacked';
        }
        return 'slds-form-element';
    }
}