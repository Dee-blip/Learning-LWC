/*
 */
import { api, LightningElement } from 'lwc';



export default class ChimeAuditTrailDataTable extends LightningElement {
    @api columns;
    @api audittrails;
    connectedCallback() {
        //this.audittrails = JSON.parse(JSON.stringify(this.audittrails));
        console.log(this.audittrails);
    }
}