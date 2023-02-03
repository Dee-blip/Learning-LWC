/* eslint-disable no-console */
import { LightningElement, api, track } from 'lwc';

export default class CpqGenericRecordForm extends LightningElement {
    @api columns;
    @api density;
    @api layoutType;
    @api mode;
    @api objectApiName;
    @api recordId;

    @track recordName;

    /**
     * handleLoad method is triggered when record-form data is loaded
     */
    handleLoad(event) {
        this.recordName = Object.values(event.detail.records)[0].fields.Name.value;
        //console.log('recordName: ', this.recordName);

    }
}