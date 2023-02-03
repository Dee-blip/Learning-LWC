import { LightningElement,api, track } from 'lwc';
import MESSAGE from '@salesforce/label/c.CPQ_Autonomy_Alert_Message'

export default class Cpq_AutonomyAlertBanner extends LightningElement {
   @track message = 'Welcome to Autonomy'
   
    get getMessage(){
        return this.message;
    }

    set setMessage(message){
        this.message = message;
    }

    renderedCallback(){
        this.setMessage = MESSAGE;
    }

}