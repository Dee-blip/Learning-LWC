import { LightningElement,api,wire } from 'lwc';
import checktoNotifyTimecardHoursConsumed from '@salesforce/apex/PSA_TimecardHoursThreshold_Validation.checktoNotifyTimecardHoursConsumed'

export default class PSATimecardHoursThresholdComponent extends LightningElement {
    @api recordId;
    @wire(checktoNotifyTimecardHoursConsumed,{recordId :'$recordId' }) 
    result;
}