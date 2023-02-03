import { LightningElement, api, track } from 'lwc';

export default class CustomToast extends LightningElement {

    @track type;
    @track message;
    @track titleMsg;
    @track showToastBar = false;
    //@api autoCloseTime = 5000;

    @api
    showToast(type, message, titleMsg) {
        this.type = type;
        this.message = message.split(';');
        this.titleMsg = titleMsg;
        this.showToastBar = true;
        setTimeout(() => {
            this.closeModel();
        }, 8000);
        /*if(this.autoCloseTime !== undefined){
            setTimeout(() => {
                this.closeModel();
            }, this.autoCloseTime);
        }*/
        /*setTimeout(function(){
            this.closeModel();
        }.bind(this), this.autoCloseTime);*/
    }

    closeModel() {
        this.showToastBar = false;
        this.type = '';
        this.message = '';
        this.titleMsg = '';
	}

    get getIconName() {
        return 'utility:' + this.type;
    }

    get innerClass() {
        return 'slds-icon_container slds-icon-utility-' + this.type + ' slds-icon-utility-success slds-m-right_small slds-no-flex slds-align-top';
    }

    get outerClass() {
        return 'slds-notify slds-notify_toast slds-theme_' + this.type;
    }
}