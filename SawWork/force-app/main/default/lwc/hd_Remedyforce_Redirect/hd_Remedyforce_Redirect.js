import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getRedirectURL from '@salesforce/apex/HD_Self_Service_Redifect_Controller.getRedirectURL';

export default class Hd_Remedyforce_Redirect extends LightningElement {
    // export default class Hd_Remedyforce_Redirect extends NavigationMixin(LightningElement) {
    @wire(getRedirectURL)
    redirectURLCallback(result) {
        if(result.data) {
            // this[NavigationMixin.Navigate]({
            //     type: 'standard__webPage',
            //     attributes: {
            //         url: result.data
            //     }
            // });
            window.location.href = result.data;
        }
    }
}