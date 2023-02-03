import { LightningElement, api, track } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import modalcss from '@salesforce/resourceUrl/modal'


const CSS_CLASS = 'slds-hide';

export default class Modal extends LightningElement {

    @api variant;

    @api isVisible() {
        return this.template.querySelector('.c-modal-container').classList.contains('c-on');
    }

    @api show() {
        this.template.querySelector('.c-modal-container').classList.add('c-on');
    }

    @api hide() {
        if(this.isVisible()) {
            let mcont = this.template.querySelector('.c-modal-container');
            mcont.classList.add('c-out');
            
            setTimeout(() => {
                    console.log('remove on');

                    mcont.classList.remove('c-on');
                    mcont.classList.remove('c-out');
                }, 500);
        }
    }

    @api toggle() {
       
        let mcont = this.template.querySelector('.c-modal-container');


         if(mcont.classList.contains('c-on')) {
             mcont.classList.toggle('c-out');
             
             if(mcont.classList.contains('c-out')) {
                setTimeout(() => {
                        console.log('remove on');

                        mcont.classList.remove('c-on');
                        mcont.classList.remove('c-out');
                    }, 500);
             }


        } else {
             mcont.classList.add('c-on');
        }

        // supcont
        // modal-container
    }

    handleDialogClose() {
        this.toggle();
       // this.hide();
    }

    handleSlotTaglineChange() {
        const taglineEl = this.template.querySelector('p');
        taglineEl.classList.remove(CSS_CLASS);
    }

    handleSlotFooterChange() {
        const footerEl = this.template.querySelector('footer');
        footerEl.classList.remove(CSS_CLASS);
    }
    get css() {
        let size = this.variant || 'medium'; 
        return 'slds-modal slds-fade-in-open slds-modal_' + size;
    }
    set css(value) {
        this._css = value;
    }


    connectedCallback() {
        loadStyle(this, modalcss);
    }
}