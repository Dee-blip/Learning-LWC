import { LightningElement, api, track } from 'lwc';

export default class L2q_chime_chat_wrapper extends LightningElement {
    @api recordId;
    @track isInternal;

    connectedCallback() {
        this.isInternal = true;
    }
    handleInternal() {
        this.isInternal = true;
    }
    handleCustomer() {
        this.isInternal = false;
    }
}