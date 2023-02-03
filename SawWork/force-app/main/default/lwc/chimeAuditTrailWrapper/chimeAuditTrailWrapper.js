/**
**/
import { track, api, LightningElement } from 'lwc';
import checkChimeVisiblity from '@salesforce/apex/L2Q_CHIME_AuditTrail.checkChimeVisiblity';

export default class ChimeAuditTrailWrapper extends LightningElement {
    //SFDC-7844 : nadesai
    @track isResponseModalOpen = false;
    @track isFormModalOpen = false;
    // @track isQuestionSet = false;
    // @track isResponseSet = false;
    // @track isChimeIdSet = false;
    @track areRequiredParamsSetForResponse = false;
    @track isInternalUser = false;
    @api question;
    @api response;
    @api chimeid;

    connectedCallback() {
        console.log('Inside connectedCallback for wrapper audit trail');
        // console.log(this.question);
        // console.log(this.response);
        // console.log(this.chimeid);

        checkChimeVisiblity()
            .then((result) => {
                console.log('result of checkChimeVisiblity : ');
                console.log(result);
                if (result === true) {
                    this.isInternalUser = true;
                }
                else {
                    this.isInternalUser = false;
                }
            })
            .catch(error => {
                console.log("Error getting the result");
                console.log(error);
            }
            );
    }

    formatInputDataForModals() {
        //this.question = JSON.parse(JSON.stringify(this.question));
        //this.response = JSON.parse(JSON.stringify(this.response));
        if (this.question !== undefined && this.question !== null) {
            if (this.response !== undefined && this.response !== null) {
                this.areRequiredParamsSetForResponse = true;
            }
            if (this.chimeid !== undefined && this.chimeid !== null) {
                this.areRequiredParamsSetForChime = true;
            }
        }
    }

    openResponseAuditTrailModal() {
        console.log('Hello inside openResponseAuditTrailModal');
        this.formatInputDataForModals();
        this.isResponseModalOpen = true;
    }
    closeResponseAuditTrailModal() {
        this.isResponseModalOpen = false;
    }
    viewCompleteFormHistoryJS() {
        console.log('inside viewCompleteFormHistoryJS');
        this.closeResponseAuditTrailModal();
        this.openFormAuditTrailModal();
    }

    openFormAuditTrailModal() {
        console.log('inside openFormAuditTrailModal');
        this.isFormModalOpen = true;
    }
    closeFormAuditTrailModal() {
        this.isFormModalOpen = false;
    }
}