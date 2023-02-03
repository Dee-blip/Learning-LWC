import { LightningElement,api } from 'lwc';
import getCanInstruct from '@salesforce/apex/SC_Jarvis_Create_Case_Controller.getCanInstruct';
export default class ScJarvisCanInstruct extends LightningElement 
{
    @api recordId;
    loadSpinner = false;
    canInstruct = '';


    connectedCallback()
    {
        this.loadSpinner = true; 
        getCanInstruct({
            "caseRecordId" : this.recordId
        })
        .then(result => {
            this.loadSpinner = false; 
            this.canInstruct = result? "The Primary Contact has the Instruct flag": 
            "The Primary Contact does not have the Instruct flag";
        })
        .catch(error => {
            this.loadSpinner = false;               
            console.log('The error: ' + error +  JSON.stringify(error)) ;
        });        
    
    }

}