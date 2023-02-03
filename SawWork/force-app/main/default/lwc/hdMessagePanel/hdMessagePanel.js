import { LightningElement, api, track } from 'lwc';

export default class HdMessagePanel extends LightningElement {
    /** Generic / user-friendly message */
    @api friendlyMessage = 'Error retrieving data';

    @track viewDetails = false;

    @api iconName;

    /** Single or array of LDS errors */
    @api errors;

    handleCheckboxChange(event) {
        this.viewDetails = event.target.checked;
    }
}