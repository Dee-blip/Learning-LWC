/* eslint-disable no-console */
import { LightningElement,api,track } from 'lwc';

export default class CaseClosureForm extends LightningElement {
    @api showPopup;
    @api recId;
    @api recTypeIdAMG;
    @track evFeilds;
    @track showSpinner = true;


    handleSubmit(event){
        event.preventDefault();
        console.log('onsubmit: '+ JSON.stringify(event.detail.fields));
        let fields = event.detail.fields
        const formFields = new CustomEvent('submitForm', {
            detail: { fields },
        });
        // Fire the custom event
        this.dispatchEvent(formFields);
    }

    closeModal(){
        let sp = false
        const closePopupEvent = new CustomEvent('closePopup', {
            detail: { sp },
        });
        // Fire the custom event
        this.dispatchEvent(closePopupEvent);
 
    }

    handleLoad(){
      /*  const inputFields = this.template.querySelectorAll(
            'lightning-input-field'
        );
        if (inputFields) {
            inputFields.forEach(field => {
                field.reset();
            });
        }*/
        console.log('+++'+this.recId);
        this.showSpinner = false;
    }

    
}