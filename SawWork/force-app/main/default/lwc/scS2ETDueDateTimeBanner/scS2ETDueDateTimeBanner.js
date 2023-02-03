// wireFunction.js
import { LightningElement, api } from "lwc";

export default class ScS2ETDueDateTimeBanner extends LightningElement 
{
    @api taskRecordType;
    isPlxTask = false;
    connectedCallback() 
    {
        this.isPlxTask = this.taskRecordType === 'Provisioning' ? true : false;
    }
}