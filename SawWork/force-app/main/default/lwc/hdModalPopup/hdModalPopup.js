import { LightningElement, api, track } from 'lwc';

export default class HdModalPopup extends LightningElement {

    @api name;
    @api styleClass = '';
    @api title;
    @api hideClose = false;
    @api isLarge = false;
    @api showModal = false;
    @api hideFooter = false;
    @track modalClass = 'slds-modal' + (this.isLarge ? 'slds-modal_large ' : '') + this.styleClass;
    @track backdropClass = 'slds-backdrop';

    @api open() {
        this.showModal = true;
        setTimeout(() => {
            this.modalClass = 'slds-modal slds-fade-in-open ' + (this.isLarge ? 'slds-modal_large ' : '') + this.styleClass;
            this.backdropClass = 'slds-backdrop slds-backdrop_open';
        }, 50);
    }

    @api close() {
        this.showModal = false;
        this.modalClass = 'slds-modal ' + (this.isLarge ? 'slds-modal_large ' : '') + this.styleClass;
        this.backdropClass = 'slds-backdrop';
    }
}