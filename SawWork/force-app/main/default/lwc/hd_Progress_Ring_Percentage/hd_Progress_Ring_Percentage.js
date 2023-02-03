import { LightningElement, api } from 'lwc';

export default class Hd_Progress_Ring_Percentage extends LightningElement {
    @api value;
    @api variant;
    @api styling;
    @api progress;
}