import { LightningElement, api, track } from 'lwc';

export default class L2q_chime_chat_wrapper extends LightningElement {
    @api recordId;
    @track isInternal;
    connectedCallback() {
        console.log("Chime id :"+this.recordId);
        this.isInternal = true;
    }
    handleInternal() {
        this.isInternal = true;
    }
    handleCustomer() {
        this.isInternal = false;
    }
}