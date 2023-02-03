/**
 * @description       : 
 * @author            : Vishnu Vardhan
 * @group             : 
 * @last modified on  : 02-22-2022
 * @last modified by  : Vishnu Vardhan
 * Modifications Log
 * Ver   Date         Author           Modification
 * 1.0   12-22-2021   Vishnu Vardhan   Initial Version
**/
import { LightningElement, api } from 'lwc';

const CSS_CLASS = 'slds-hide';

export default class ScModal extends LightningElement {

    @api variant;

    @api isVisible() {
        return this.template.querySelector('.c-modal-container').classList.contains('c-on');
    }

    @api show() {
        const container = this.template.querySelector('.c-modal-container');
        container.classList.add('c-on');
        container.focus();
    }

    @api hide() {
        if(this.isVisible()) {
            let mcont = this.template.querySelector('.c-modal-container');
            mcont.classList.add('c-out');
            
            setTimeout(() => {  // eslint-disable-line @lwc/lwc/no-async-operation
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
                setTimeout(() => { // eslint-disable-line @lwc/lwc/no-async-operation
                        mcont.classList.remove('c-on');
                        mcont.classList.remove('c-out');
                    }, 500);
             }


        } else {
            this.show();
        }
    }

    handleDialogClose() {
        this.toggle();
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
        // loadStyle(this, modalcss);
    }

    handleEscape(ev) {
        if (ev.keyCode === 27) {
            this.hide();
        }
    }
}