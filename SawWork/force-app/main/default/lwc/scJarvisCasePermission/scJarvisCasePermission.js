import { LightningElement,api } from 'lwc';
import getCaseContactAccess from '@salesforce/apex/SC_Jarvis_Create_Case_Controller.getCaseContactAccess';
export default class ScJarvisCasePermission extends LightningElement 
{
    @api recordId;
    loadSpinner = false;
    canInstruct = '';


    connectedCallback()
    {
        this.loadSpinner = true; 
        getCaseContactAccess({
            "recordId" : this.recordId
        })
        .then(result => {
            this.loadSpinner = false; 
            //console.log('result: ' + result);
            //console.log('this.recordId: ' + this.recordId);
            switch(result)
            {
                case "None":
                    this.canInstruct = "The Primary Contact cannot access the Case";
                break;
                case "Read":
                    this.canInstruct = "The Primary Contact can View the Case";
                break;
                case "Edit":
                    this.canInstruct = "The Primary Contact can Edit the Case";
                break;
                default:
                    console.log('Default use case');
            }
        })
        .catch(error => {
            this.loadSpinner = false;               
            this.canInstruct = "The Primary Contact cannot access the Case";
            console.log('The error: ' + error +  JSON.stringify(error)) ;
        });        
    
    }

}