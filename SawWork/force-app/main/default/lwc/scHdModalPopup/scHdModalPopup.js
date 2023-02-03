/*
Author          : Harshil Soni
Description     : This is the HD Modal Popup Service Cloud component (child of Create New Incident Service Cloud component) for ACD 2.0, 
                  duplicated from hdModalPopup component.
                  Look for comments starting with //ACD to find minor changes to the original component.
                  Please do not make any changes without consulting SC team.

Date             Developer         JIRA #             Description                                                       
------------------------------------------------------------------------------------------------------------------
9 OCT 2021       Harshil Soni      ACD2-348           Initial Component
------------------------------------------------------------------------------------------------------------------
*/
import { LightningElement, api, track } from 'lwc';

export default class scHdModalPopup extends LightningElement {

    @api name;
    @api styleClass;
    @api title;
    @api hideClose = false;
    @api isLarge = false;
    @track showModal = false;
    @api hideFooter = false;

    //ACD: added new variables to pass from parent
    @api isScreenPop;

    modalClass = 'slds-modal ' + (this.isLarge ? 'slds-modal_large ' : '') + this.styleClass;
    
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
        //ACD: added IF condition to close window
        if(this.isScreenPop === true){
            console.log("in screenpop close")
            window.close();
        }
    }


}