/* eslint-disable no-eval */
import { LightningElement, api, wire} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import saveActionNote from '@salesforce/apex/HD_IncidentDetailController.saveActionNote';
import isAccessibleRecord from '@salesforce/apex/HD_ActionMenu_Provider.isAccessibleRecord';

export default class HD_LWC_Add_Note extends LightningElement {
    
    @api recordId;
    
    remainingChars = 2000;
    timeSpent = 0;
    isButtonDisabled = true;
    txt = '';
    time = '';
    hasAccess;
    displaySpinner;
    minTime = 1;
    maxTime = 60;

    @wire(isAccessibleRecord, {recordID: '$recordId'})
    hasAccess

    displaySaveButton(){
        if(this.timeSpent >= this.minTime && this.txt.length > 3 && this.timeSpent <= this.maxTime){
            this.isButtonDisabled = false;
        }
        else{
            this.isButtonDisabled = true;
        }
    }

    setTimeSpent(){
        this.validateTime();
        if(this.timeSpent >= this.minTime && this.timeSpent < 10){
            this.timeSpent = this.timeSpent * 1;
            this.time = '00:0' + this.timeSpent;
        }
        else if(this.timeSpent >= 10 && this.timeSpent !== this.maxTime){
            this.time = '00:' + this.timeSpent;
        }
        else if(this.timeSpent === this.maxTime){
            this.time = '01:00';
        }
    }

    validateTime(){
        var inputCmp = this.template.querySelector('[data-id="timeMin"]');
        if (this.timeSpent > this.maxTime) {
            inputCmp.setCustomValidity('Value must be less than or equal to 60');
        } else {
            inputCmp.setCustomValidity('');
        }
        inputCmp.reportValidity();
    }

    changeTimeSpent(event){
        this.timeSpent = event.target.value;
        this.displaySaveButton();
        this.setTimeSpent();
    }

    decrementMinute(){
        if(this.timeSpent >= this.minTime){
            this.timeSpent = parseInt(this.timeSpent,10) - parseInt(this.minTime,10);
            this.displaySaveButton();
        }
        this.setTimeSpent();
    }

    incrementMinute(){
        if(this.timeSpent < this.maxTime){
            this.timeSpent = parseInt(this.timeSpent,10) + parseInt(this.minTime,10);
            this.displaySaveButton();
        }
        this.setTimeSpent();
    }

    countnotechar(event){
        this.remainingChars = 2000 - event.target.value.trim().length;
        this.txt = event.target.value.trim();
        this.displaySaveButton();
    }

    showToast(title,message,variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

    saveNote(){
        this.displaySpinner = true;
        saveActionNote({incidentId: this.recordId, txt: this.txt, timespent: this.time})
        .then((result) => {
            this.displaySpinner = false;
            if(result.indexOf('SUCCESS') > -1){
                this.showToast('Internal Note saved successfully !','','success');
                this.remainingChars = 2000;
                this.isButtonDisabled = true;
                this.template.querySelector('[data-id="txtNote"]').value = '';
                this.txt = '';
                this.timeSpent = 0;

                eval("$A.get('e.force:refreshView').fire();");
            }
        })
        .catch((error) => {
            this.displaySpinner = false;
            this.showToast('Status not changed !',error.body.message,'error');
        });
    }
}