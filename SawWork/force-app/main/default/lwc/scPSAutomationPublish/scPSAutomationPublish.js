import { LightningElement ,track,api} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import validatePublish from '@salesforce/apex/SC_PSAutomationController.validateToPublishMasterMailer';
import publish from '@salesforce/apex/SC_PSAutomationController.publishMasterMailer';



import { CloseActionScreenEvent } from 'lightning/actions';


export default class ScPSAutomationPublish extends LightningElement {
    @api recordId;
    @track showSpinner = false;

   
        


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

    


    connectedCallback(){
        var returnResult
        this.showSpinner = true;
        validatePublish({recId:this.recordId}) 
        .then(resultRec => {
            returnResult= JSON.parse(resultRec);
            if(!returnResult.isMasterRecord){
                this.showToast('Only Master mailer records can be published.','ERROR','dismissable');
                
                this.dispatchEvent(new CloseActionScreenEvent());
                window.location.reload();
            }else if(returnResult.isPublished){
                this.showToast('Customer Mailer is already published','ERROR','dismissable');
                this.dispatchEvent(new CloseActionScreenEvent());
                window.location.reload();
            }else if(!returnResult.validUserToPublish){
                this.showToast('You are not authoried to publish','ERROR','dismissable');
                this.dispatchEvent(new CloseActionScreenEvent());
                window.location.reload();
            }else{

                publish({recId:this.recordId}) 
                .then(result => {console.log(result);
                    this.showToast('Child mailer would get created and notified','Success','dismissable');
                   window.location.reload();
                }).catch((error) => {
                    console.error("Error in create records", error);
                    this.dispatchEvent(new CloseActionScreenEvent());
                    window.location.reload();
                    this.showSpinner = false;
                });

            }
                
               
                
               
                   
    
            })
            .catch((error) => {
                console.error("Error in create records", error);
                this.dispatchEvent(new CloseActionScreenEvent());
                this.showSpinner = false;
            });
    }

  

}