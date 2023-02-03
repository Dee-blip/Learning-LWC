/* eslint-disable no-console */
import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import assignTaskShift from '@salesforce/apex/SC_ProvisioningDashboard_Controller.assignTaskShift';
import fetchTaskShift from '@salesforce/apex/SC_ProvisioningDashboard_Controller.fetchTaskShift';


export default class ScProvisioningAssignShift extends LightningElement {
    shiftSelected = '';
    loadSpinner = false;
    disableSave = true;

    @api recordId;

    /*
    get shiftSelectedVal()
    {
        return[
            { label: 'AMER First', value: 'AMER First' },
            { label: 'AMER Second', value: 'AMER Second'},
            { label: 'AMER Third', value: 'AMER Third'}
        ];
    }
    */

    get shiftSelectedVal()
    {
        return[
            { label: 'First', value: 'First' },
            { label: 'Second', value: 'Second'},
            { label: 'Third', value: 'Third'}
        ];
    }

    connectedCallback() 
    {
        fetchTaskShift({taskId:this.recordId}) 
        .then(result => {
            this.shiftSelected = result;
        })
        .catch(error => {
            this.error = error;
        });
    }
    shiftSelectedChanged(event){
        this.shiftSelected = event.detail.value;
        this.disableSave = false;
    }

    saveShift()
    {
        this.loadSpinner = true;
        let assignedShift = (this.shiftSelected).toString();
        if (!assignedShift) {
            const toastEvt = new ShowToastEvent({
                title: "",
                message: "Please select a Shift to assign",
                variant: "warning",
                mode: "dismissible",
                duration: 4000
            });
            this.dispatchEvent(toastEvt);
            this.loadSpinner = false;
            this.disableSave = true;
        }
        assignTaskShift({taskIdList:this.recordId,shift:this.shiftSelected})
        .then(result => {
            console.log('RESULT : '+result);
            
            const toastEvt = new ShowToastEvent({
                title: "",
                message: "Shift Assigned Successfully!",
                variant: "success",
                mode: "dismissible",
                duration: 5000
            });
            this.dispatchEvent(toastEvt);   
            this.loadSpinner = false;   
            this.disableSave = true; 
            // eslint-disable-next-line no-eval
            eval("$A.get('e.force:refreshView').fire();");
        })
        .catch(error => {
            const toastEvt = new ShowToastEvent({
                title: "Error!",
                message: error.body.message,
                variant: "error!",
                mode: "sticky",
                duration: 5000
            });
            this.dispatchEvent(toastEvt);
            this.loadSpinner = false;
            this.disableSave = true;
        })

    }
}