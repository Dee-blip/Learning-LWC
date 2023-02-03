import { LightningElement, api, track } from 'lwc';
import currentShiftDetails from '@salesforce/apex/SC_RCA_TransitionController.getCurrentShiftDetails';
import wakeupTimeMethod from '@salesforce/apex/SC_RCA_TransitionController.wakeUpTimeMethod';
import createNewTransition from '@salesforce/apex/SC_RCA_TransitionController.createTransitionRecord';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
export default class Sc_RCA_NewTransitionReocrd extends LightningElement {
    targetShift;
    @track wakeupTime;
    @track currentShift;
    @track disableTransitionButton;
    @track isIraptUser;
    @api recordId;
    @track buttonDisable;
    @track suggestedBIL;
    @track notes;
    @track caseOwner;
    @track errorMsg;

    connectedCallback(){
        this.isIraptUser = false;
        this.disableTransitionButton = true;
        this.buttonDisable = true;
        this.dispatchEvent(new CustomEvent('showSpinner'));
        currentShiftDetails ( {'caseId':this.recordId} )
            .then(result => {
                this.currentShift = result.currentShift;
                this.disableTransitionButton = (result.caseStatus==='Unassigned') ? true : false;
                this.isIraptUser = result.isIrapt;
                this.caseOwner = result.caseOwner;
                this.errorMsg = 'Only IRAPT user can create Case Transition.';
                this.dispatchEvent(new CustomEvent('hideSpinner'));
                
                
        })
    }

    

    
    
    updateWakeupTime(event){
        this.targetShift = event.target.value;
        if(this.targetShift){
            this.buttonDisable = false;
        } else {
            this.buttonDisable = true;
        }
        this.dispatchEvent(new CustomEvent('showSpinner'));
        wakeupTimeMethod ( {targetShiftTime: this.targetShift} )
            .then(result => {
                this.wakeupTime = result;
                this.dispatchEvent(new CustomEvent('hideSpinner'));
                
        })
        
    }

    get options() {
        return [
            { label: 'US EAST', value: 'US EAST' },
            { label: 'US WEST', value: 'US WEST' },
            { label: 'EMEA', value: 'EMEA' },
            { label: 'APJ', value: 'APJ' },
            { label: 'Transition Now', value: 'Transition Now' }
        ];
    }
    
    
    closeModal() {
        this.dispatchEvent(new CustomEvent('closeTransitionModal'));
    }
    notesUpdate(event){
        this.notes = event.target.value;
    }

    createTransition() {
        if(!this.wakeupTime || !this.targetShift || !this.notes){
            
            this.template.querySelectorAll('lightning-combobox').forEach(element => {
                element.reportValidity();
            });
            this.template.querySelectorAll('lightning-textarea').forEach(element => {
                element.reportValidity();
            });
        } else{
            this.dispatchEvent(new CustomEvent('showSpinner'));
            
            createNewTransition(
                {
                    caseId: this.recordId,
                    nextShift: this.targetShift, 
                    wakeupTime: this.wakeupTime,
                    caseOwner: this.caseOwner,
                    notes: this.notes
                })
                .then( result => {
                    if(!result){
                        this.isModalOpen = false;
                        this.dispatchEvent(new CustomEvent('hideSpinner'));
                        this.dispatchEvent(new CustomEvent('refreshView'));
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Success!!',
                            message: 'Transition Created Successfully!!',
                            variant: 'success'
                        }),);
                        this.dispatchEvent(new CustomEvent('closeTransitionModal'));
                    }
                    
                })
            .catch(error => {
                if (Array.isArray(error.body)) {
                    this.error = error.body.map(e => e.message).join(', ');
                } 
                else if (typeof error.body.message === 'string') {
                    this.error = error.body.message;
                }
                this.dispatchEvent(new CustomEvent('hideSpinner'));
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error!!',
                    message: this.error,
                    variant: 'error'
                }),);
                //this.dispatchEvent(new CustomEvent('closeTransitionModal'));
            });
        }
        
        
    }


}