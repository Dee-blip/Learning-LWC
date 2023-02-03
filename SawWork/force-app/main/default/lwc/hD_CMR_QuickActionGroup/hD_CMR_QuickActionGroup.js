/* eslint-disable */
import { LightningElement, api, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import { publish, MessageContext } from 'lightning/messageService';
import hdQuickActionClick from '@salesforce/messageChannel/hdQuickActionClick__c';
import submitForApproval from '@salesforce/apex/HD_CMRActions_Controller.submitForApproval';
import getFieldValues from '@salesforce/apex/HD_CMRActions_Controller.getFieldValues';
import changeCMRStatus from '@salesforce/apex/HD_CMRActions_Controller.changeCMRStatus';
import getPIR from '@salesforce/apex/HD_CMRActions_Controller.getPIR';

export default class HD_CMR_QuickActionGroup extends NavigationMixin(LightningElement) {
    @api listofactionsdisplay;
    @api change;
    @api isLoading;
    isOpen = false;
    renderCreateForm = false;
    updatedCMR;
    PIRStatus = 'CLOSED';
    @track wiredResponse;

    @api fireRefresh() {
        refreshApex(this.wiredResponse);
    }

    @wire(MessageContext)
    messageContext;

    performAction(event) {
        let action = event.target.dataset.id;
        
        if (action === "Submit for Approval") {
          this.submitForApproval();
        } else if (action === "Clone") {
            this.clone();
        } else if (action === "Close") {
            this.close('CLOSED');
        } else if (action === "Recall") {
            publish(this.messageContext, hdQuickActionClick, { quickAction: 'Recall' });
           this.isOpen = true;
        } else if (action === "Cancel") {
            this.changeStatusCMR('CANCELLED');
        } else if (action === "InProgress") {
            this.changeStatusCMR('IN PROGRESS');
        } else if (action === "Completed") {
            this.changeStatusCMR('COMPLETED');
        } else if (action === "Change Failed") {
            this.close('CHANGE FAILED');
        }        
    }

    onQuickActionClick() {
        publish(this.messageContext, hdQuickActionClick, { quickAction: 'updateRecords' });
        publish(this.messageContext, hdQuickActionClick, { quickAction: 'updateAndRefreshRecords', change: this.updatedCMR });
    }

    errorMessage(error) {
        let errorMessage = '';
        let errors = error.body;
        for(let temp in errors){
            if (errors[temp]) {
                let temp1 = errors[temp];
                try{
                    errorMessage = errorMessage + ' ' + temp1[0].message;
                }catch(err){
                    continue;
                }
            } 
        }
        return errorMessage;
    }

    submitForApproval(){
        this.isLoading = true;
        submitForApproval({cmrId: this.change.Id, comment: ''})
        .then((result) => {
            if(result !== null) {
                this.updatedCMR = result;
                this.change = this.updatedCMR;

                this.onQuickActionClick();

                this.isLoading = false;
                this.showToast('CMR is submitted for approval successfully.', '', 'success');
                
                eval("$A.get('e.force:refreshView').fire();");
            }
            else {
                this.showToast('Error occurred while submitting for approval', '', 'error');
                this.isLoading = false;
            }
        })
        .catch((error) => {
            this.isLoading = false;
            let errorMessage = this.errorMessage(error);
            this.showToast('Error occurred while submitting for approval.', errorMessage , 'error');
        });
    }

    clone(){
        getFieldValues({currentCMR: this.change})
        .then((result) => {
            let defaultValues;
            defaultValues = encodeDefaultFieldValues(result);

            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: 'BMCServiceDesk__Change_Request__c',
                    actionName: 'new'                
                },
                state : {
                    defaultFieldValues: defaultValues
                }
            });
        })
        .catch((error) => {
            let errorMessage = this.errorMessage(error);
            this.showToast('Error occurred while Cloning' , errorMessage , 'error');
        });
    }

    changeStatusCMR(statusChange){
        this.isLoading = true;
        changeCMRStatus({currentCMR: this.change, status: statusChange})
        .then((result) => {
            if(result !== null) {
                this.updatedCMR = result;
                this.change = this.updatedCMR;
            
                this.onQuickActionClick();

                this.isLoading = false;
                this.showToast('CMR is marked as '+statusChange+' successfully.' , '', 'success');
                
                eval("$A.get('e.force:refreshView').fire();");
            }
            else {
                this.showToast('Error occurred while marking '+statusChange , '', 'error');
                this.isLoading = false;
            }
        })
        .catch((error) => {
            this.isLoading = false;
            let errorMessage = this.errorMessage(error);
            this.showToast('Error occurred while marking '+statusChange , errorMessage , 'error');    
        });
	}

    close(status){
        this.isLoading = true;
        getPIR({currentCMR: this.change})
        .then((result) => {
            if(result !== null) {
                if(result.Post_Implementation_RollUp__c < 1){
                    //If PIR is not present open PIR form and close the CMR
                    this.isLoading = false;
                    publish(this.messageContext, hdQuickActionClick, { quickAction: 'fillPIR', data: JSON.stringify({ pirStatus: status, changeCMR : this.change }) });
                } 
                else{
                    this.closeCMR(result,status);                       
                }
            }
            else {
                this.isLoading = false;
            }
        })
        .catch((error) => {
            let errorMessage = this.errorMessage(error);
            this.showToast('Error occurred while marking '+status , errorMessage , 'error');
            this.isLoading = false;
        });
	}

    closeCMR(resultChange,status){
        changeCMRStatus({currentCMR: resultChange, status: status})
        .then((result) => {
            if(result !== null) {
                this.updatedCMR = result;
                this.change = this.updatedCMR;
            
                this.onQuickActionClick();

                this.isLoading = false;
                this.showToast('CMR is marked as '+status+' successfully.', '', 'success');
                
                eval("$A.get('e.force:refreshView').fire();");
            }
            else {
                this.showToast('Error occurred while marking '+status , '', 'error');
                this.isLoading = false;
            }
        })
        .catch((error) => {
            let errorMessage = this.errorMessage(error);
            this.showToast('Error occurred while marking '+status , errorMessage , 'error');
            this.isLoading = false;   
        });
    }

    showToast(title,message,variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable',
        });
        this.dispatchEvent(event);
    }
}