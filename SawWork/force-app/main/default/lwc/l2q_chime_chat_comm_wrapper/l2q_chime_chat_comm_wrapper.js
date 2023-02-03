import { LightningElement, track } from 'lwc';
import validateChimeAccess from '@salesforce/apex/ChimeTriggerClass.validateChimeAccess';
export default class L2q_chime_chat_comm_wrapper extends LightningElement {
    @track chimeid;
    @track hasChimeAccess = false;

    connectedCallback() {
        const queryString = window.location.search;
        const urlParams = new URLSearchParams(queryString);
        this.chimeid = urlParams.get('c__chimeId');
        this.checkChimeAccess();
    }

    checkChimeAccess() {
        validateChimeAccess({ chimeId: this.chimeid })
            .then(result => {
                this.hasChimeAccess = result;
            })
            .catch(error => {
                this.error = error;
            });
    }
}