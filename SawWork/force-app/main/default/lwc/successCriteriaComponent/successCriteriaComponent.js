import { LightningElement,track,api} from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import getAllSuccessCriteria from '@salesforce/apex/ChimeTriggerClass.getAllSuccessCriteria';
import SuccessCriteria_FIELD from '@salesforce/schema/CHIME__c.Business_Goals__c';
import ID_FIELD from '@salesforce/schema/CHIME__c.Id';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const COLS=[  
    {label:'Business Goal', fieldName: 'business_goal',type:'text',fixedWidth: 350},  
    {label:'Description', fieldName: 'business_goal_helpText', type:'text', wrapText: true},
  ];

export default class SuccessCriteriaComponent extends LightningElement {
    @api recordId;
    @track successCriteriaList = [];
    @track preSelectedRows = [];
    chimeStatus;
    cols=COLS;

    @api disableSave=false;

    connectedCallback(){
        getAllSuccessCriteria({ chimeId: this.recordId })
        .then((result) => {
            let successCriteriaLists = [];
            if(result){
                this.chimeStatus = result.chimeStatus;
                console.log("this.chimeStatus:",this.chimeStatus)
                for (let key in result.allSuccessCriteria){
                    if(key){
                        let prepareTable = {};
                        prepareTable.business_goal = key;
                        prepareTable.business_goal_helpText = result.allSuccessCriteria[key];
                        successCriteriaLists.push(prepareTable);
                    }
                }
                this.successCriteriaList = successCriteriaLists;
                if(result.selectedSuccessCriteria){
                    this.preSelectedRows = result.selectedSuccessCriteria.split(";");
                    console.log("preSelectedRows:", this.preSelectedRows);
                }
            }
        })
        .catch((error) => {
            this.error = error;
            console.log("Error:", error);
        });
    }

    saveRecord(){
        var multiSelectedValues, selectedRecords, multiSelect;
        if(this.chimeStatus === 'Closed'){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'You cannot modify Business Goal as the Form Stage is Closed',
                    variant: 'error',
                    mode: 'pester'
                })
            );
        }
        else{
            multiSelectedValues = [];
            selectedRecords = this.template.querySelector("lightning-datatable").getSelectedRows();
            //console.log("Selected:"+selectedRecords);
            for (let i = 0; i < selectedRecords.length; i++){
                //alert("You selected: " + selectedRecords[i].business_goal);
                multiSelectedValues.push(selectedRecords[i].business_goal);
            }
            multiSelect = multiSelectedValues.join(';');
            console.log(multiSelect);

            const fields = {};
            fields[ID_FIELD.fieldApiName] = this.recordId;
            fields[SuccessCriteria_FIELD.fieldApiName] = multiSelect;

            const recordInput = { fields };

            updateRecord(recordInput)
            .then(result => {
                console.log("Result:", result);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Successfully Saved',
                        variant: 'success',
                        mode: 'pester'
                    })
                );
                this.dispatchEvent(new CustomEvent('close'));

            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Something went wrong',
                        variant: 'error',
                        mode: 'pester'
                    }),
                );
                console.log("Error:", error);
            });
        }

    }

    handleCloseSuccessCriteria(){
        this.dispatchEvent(new CustomEvent('close'));
    }

}