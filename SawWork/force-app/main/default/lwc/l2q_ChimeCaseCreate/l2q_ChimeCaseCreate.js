import { LightningElement,api,track,wire } from 'lwc';
//import createUpdateCase from '@salesforce/apex/L2Q_LOE_Utility.create_updateCase';
import createUpdateCase from '@salesforce/apex/L2Q_LOE_Utility.createUpdate_Review_IntegrationCase';
//import getLinkedCase from '@salesforce/apex/L2Q_LOE_Utility.fetchLinkedCase';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import CHIMESTAGE_FIELD from '@salesforce/schema/CHIME__c.Stage__c';
import CHIMEID_FIELD from '@salesforce/schema/CHIME__c.Id';
import { publish, MessageContext } from 'lightning/messageService';
import STAGE_TRANSITION from '@salesforce/messageChannel/L2Q_ChimeStageTransition__c';
import checkCasePermission from '@salesforce/apex/L2Q_LOE_Utility.isCaseButtonEnable';
import checkchimeformType from '@salesforce/apex/L2Q_LOE_Utility.chimeFormType';

export default class L2q_ChimeCaseCreate extends LightningElement {
    @api description = '';
    @api chimeId;
    @api headerLabel = 'Create Case';
    @api buttonLabel = 'Create Case';
    @track showSpinner = false;
    @track showError = true;
    @track pocchimeform = false ;
    
    @wire(MessageContext) messageContext;
    

    connectedCallback(){
        this.showSpinner = true;
            checkCasePermission({ chimeFormID: this.chimeId })
                .then(result => {
                    this.showError = !result;
                    this.showSpinner = false;


                    


                })
                .catch(error => {
                    this.error = error;
                    this.isloading = false;
                    this.showSpinner = false;
                });

        checkchimeformType({ chimeFormID: this.chimeId })
            .then(result => {
                console.log(' what vall :' , result );
                if(result === 'custompoc')
                {
                    console.log(' nen : ');
                    this.pocchimeform = true
                }
                this.showSpinner = false;
            })
            .catch(error => {
                this.error = error;
                this.isloading = false;
                this.showSpinner = false;
            });

            
            
        
       /* alert('loading');
        getLinkedCase({ chimeRecId: this.chimeId }) 
            .then(result => {
               // var casedata = result));
               if(result.caseId != ''){
                   this.headerLabel = 'Update Case';
                   this.buttonLabel = 'Update Case';
                   this.description = result.Description;
               }

                
            })
            .catch(error => {
                console.log('err**'+error);
            });*/
    }

    handleCancel(){
        const cancelEvent = new CustomEvent('cancel',{});
        this.dispatchEvent(cancelEvent);
    }

    submitCase(){
        this.showSpinner = true;
   
        createUpdateCase({ chimeFormID: this.chimeId,caseDescription:this.description,Case_Type:'Integration_Case',priority:null,isAutoUpdate:false})
        .then(result => {
           // alert(result);
           const fields = {};
           fields[CHIMEID_FIELD.fieldApiName] = this.chimeId;
           fields[CHIMESTAGE_FIELD.fieldApiName] = 'Integration';
            const recordInput = { fields };

            updateRecord(recordInput)
                .then(() => {
                   // fire event
                   this.showSpinner = false;
                   const message = {
                    transition: true
                };
                publish(this.messageContext, STAGE_TRANSITION, message);
               
                })
                .catch(error => {
                  console.log('error**'+error);
                });

            this.showToast(result+' is created/updated.','success','dismissable');
            this.handleCancel();
            window.setTimeout(function(){ window.location.reload() }, 2000);
            

            
        })
        .catch(error => {
            console.log('err**'+error);
            this.showSpinner = false;
        }); 
    
    }

    handleDescriptionChange(event){
        this.description = event.target.value;
    }

     // Handling toasts
     showToast(message,variant,mode) {
        // alert('here');
        const evt = new ShowToastEvent({
            
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }   
}