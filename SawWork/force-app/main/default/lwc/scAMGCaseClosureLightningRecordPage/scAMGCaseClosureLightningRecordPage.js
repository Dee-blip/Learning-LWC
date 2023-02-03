/* eslint-disable no-console */
/* eslint-disable no-alert */
import { LightningElement, api, track} from 'lwc';
import updateClosedCases from '@salesforce/apex/SC_AMG_Lightning.updateClosedCases';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import escapeChars from '@salesforce/label/c.Sc_AMG_escapCharacters';


export default class ScAMGCaseClosureLightningRecordPage extends LightningElement {
    @api lCaseId = [];
    @api recTypeAMG;
    lOfCases = [];
    @track showSpinner = true;
    @track spinner = false;
  
   
    connectedCallback() {
        console.log('lCaseId ' + this.lCaseId);
       
    }
    
    handleSubmitAction(event){
        event.preventDefault();
        var specialChars = escapeChars;
        console.log('spinerrrr//'+this.showSpinner);
        this.showSpinner = true;
        console.log('spinerrrr22222//'+this.showSpinner);
        this.spinner = true;
        let lCasesToClose = [];
        let caseToAdd = '[{';
        for( let i=0; i<this.lCaseId.length; i++){
            let lwcEditForm = this.template.querySelectorAll('[data-id="'+this.lCaseId[i]+'"]');
            
            for(let j=0; j<lwcEditForm.length;j++){
                
                if((lwcEditForm[j].fieldName === 'Request_Type__c' && !lwcEditForm[j].value) || (lwcEditForm[j].fieldName === 'Request_Sub_Type__c' && !lwcEditForm[j].value) || (lwcEditForm[j].fieldName === 'Service__c' && (!lwcEditForm[j].value || lwcEditForm[j].value === '--None--')) || (lwcEditForm[j].fieldName === 'Resolution_Field__c' && !lwcEditForm[j].value) || (lwcEditForm[j].fieldName === 'LOE_Hours__c' && !lwcEditForm[j].value && !(lwcEditForm[j].value ===0)) || (lwcEditForm[j].fieldName === 'LOE_Minutes__c' && !lwcEditForm[j].value && !(lwcEditForm[j].value ===0)) || (lwcEditForm[j].fieldName === 'Solution_Summary__c' && !lwcEditForm[j].value) ){
                    const evt = new ShowToastEvent({
                        title: 'Error',
                        message: "These required fields must be completed: Service,Request Type,Request Sub-Type,Action Taken, LOE Minutes, LOE Hours, Solution Summary",
                        variant: 'Error',
                        mode: 'dismissable'
                    });
                    //this.dispatchEvent(evt);
                    
                    this.showSpinner = false;
                    this.spinner = false;
                    this.template.querySelectorAll('lightning-input-field').forEach(element => {
                        element.reportValidity();
                    });
                    return false;
                } else if(lwcEditForm[j].fieldName === 'Subject'){
                    
                    for(let k = 0; k < specialChars.length;k++){
                        if(lwcEditForm[j].value.indexOf(specialChars[k]) > -1){
                            if(specialChars[k] === "\"")
                            lwcEditForm[j].value = lwcEditForm[j].value.replaceAll(specialChars[k],"'");
                            else 
                                lwcEditForm[j].value = lwcEditForm[j].value.replaceAll(specialChars[k],' ');
                        }
                    }
                }
                caseToAdd += '"' + lwcEditForm[j].fieldName.replace('__c','') + '" : "' + lwcEditForm[j].value + '",';
                if(j===0){
                    caseToAdd += '"Id": "' + this.lCaseId[i] + '",';
                }
                if(j === lwcEditForm.length -1){
                    caseToAdd = caseToAdd.slice(0,-1);
                    caseToAdd += '},{';
                }
                
                
            }
            if(this.lCaseId.length-1 === i){
                caseToAdd = caseToAdd.slice(0,-2);
                caseToAdd += ']';
                lCasesToClose = caseToAdd;
            }

        }
        updateClosedCases({
            caseDetails : caseToAdd
        }).then((response) => {
            this.showSpinner = false;
            this.spinner = false;

            
            let resp = JSON.parse(response);
           
            
            if(resp.erroredCaseCount === 0 ){

                const evt = new ShowToastEvent({
                    title: 'Record Update',
                    message: resp.closedCaseCount > 1 ? "All records were updated successfully!" : "Record updated successfully!",
                    variant: 'success',
                    mode: 'dismissable'
                });
                this.dispatchEvent(evt);

                this.handleCancelAction();
          
            }
         
                

            
            if(resp.erroredCaseCount !== 0){

                const evt = new ShowToastEvent({
                    title: 'Record Update',
                    message: resp.closedCaseCount > 1 ? resp.closedCaseCount + " records updated successfully and " + resp.erroredCaseCount + " failed !" :
                    resp.closedCaseCount + " record updated successfully and " + resp.erroredCaseCount + " failed !",
                    variant: 'info',
                    mode: 'dismissible',
                    duration: 20000
                });
                this.dispatchEvent(evt);

                const toastEvt = new ShowToastEvent({
                    title: 'Error',
                    message: resp.errorMessage,
                    variant: 'Error',
                    mode: 'dismissible',
                    duration: 20000
                });
                this.dispatchEvent(toastEvt);
           
            }
            if(!(resp.closedCaseCount == 0 && resp.erroredCaseCount ==0)){
                this.lCaseId = [...resp.failedSet];
                console.log('lCaseId for errored cases//'+this.lCaseId);
            }
            const refreshDataEvent = new CustomEvent('refreshData', {});
            // Fire the custom event
            this.dispatchEvent(refreshDataEvent);
           


        })
        .catch((error) => {
            console.log('error//'+JSON.stringify(error));
        });
    }

    handleCancelAction(){
        console.log('Tadaaa in handle close');
        const closeTabEvent = new CustomEvent('closeTab', {
        });
        // Fire the custom event
        this.dispatchEvent(closeTabEvent);
 
    }
    handleLoad(){
          this.showSpinner = false;
      }
}