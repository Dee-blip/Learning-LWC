import { LightningElement, api } from 'lwc';

export default class HdKAViewer extends LightningElement {
    @api recordId;
    @api fields;
    @api objectApiName;
    get getFormFields() {
        return this.fields.split(',');
    }
}