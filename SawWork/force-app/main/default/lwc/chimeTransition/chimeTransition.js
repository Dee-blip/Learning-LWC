import { LightningElement,api,track,wire } from 'lwc';
import {ShowToastEvent} from  'lightning/platformShowToastEvent';
import REASON_FIELD from '@salesforce/schema/CHIME__c.Reopen_Reason__c';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import CHIME__OBJECT from '@salesforce/schema/CHIME__c';
import NOTIFY_FIELD from '@salesforce/schema/CHIME__c.Notify_Opportuntiy_Team__c';
import NOTES_FIELD from '@salesforce/schema/CHIME__c.Notes__c';
import ID_FIELD from '@salesforce/schema/CHIME__c.Id';
import STATUS_FIELD from '@salesforce/schema/CHIME__c.Status__c';
import { updateRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';
import checkPermission from '@salesforce/apex/ChimeTriggerClass.checkPermissionToAcceptChime';
import StageTransitionCheck from '@salesforce/apex/ChimeTriggerClass.StageTransitionCheck';
import notifyOppTeam from '@salesforce/apex/ChimeTriggerClass.notifyOppTeam';
import { publish, MessageContext } from 'lightning/messageService';
import STAGE_TRANSITION from '@salesforce/messageChannel/L2Q_ChimeStageTransition__c';
import Interaction from '@salesforce/messageChannel/L2Q_InteractHeaderToDetailComp__c';

export default class ChimeTransition extends LightningElement {

    @api statusvalue;
    @api chimeid;
    @api stage;
    @api userpermission;

    @track showAcceptReopen = false;
    @track    showAccept=false;
    @track    showReopen= false;

    @track showAcceptPopup=false;
    @track showReopenPopup=false;
    @track checkboxoptions=[];
    @track originValues;
    @track checkboxvalue;

    value=[];
    textareavalue='';
    notifyopp=false;

    @wire(MessageContext) messageContext;

    get options() {
        let alist = [];
        this.checkboxoptions.forEach(function(element) {
          alist.push({ label: element["label"], value: element["value"] });
        });
        return alist;
    }
    handleChange(e) {
        this.value = e.detail.value;
        ////console.log('Value::',this.value);
    }

    @wire(getObjectInfo, { objectApiName:  CHIME__OBJECT})
    objectInfo;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: REASON_FIELD})
    picklistvals({error, data}){
        if(data){
            ////console.log('pickvals::',data);
            this.checkboxoptions = data.values;
            //console.log('originVals:',this.checkboxoptions);
        }
    }

    
    get selectedValues() {
        return this.checkboxvalue.join(',');
    }
    handleCheckboxChange(e) {
        this.checkboxvalue = e.detail.value;
    }

    connectedCallback(){
        ////console.log('statusValue'+this.statusvalue);
        ////console.log('userpermission'+this.userpermission);
        ////console.log('stage:'+this.stage);
        if(this.stage=='Integration'){
            if(this.statusvalue == 'Not Accepted' && this.userpermission == 'true'){
                this.showAcceptReopen = true;
                this.showAccept = true;
                this.showReopen = true;
            } else
            if(this.statusvalue == 'Reopened' && this.userpermission == 'true'){
                ////console.log('inside here');
                this.showAccept = true;
                this.showReopen = false;
            }
            else if((this.statusvalue == 'Accepted') && this.userpermission == 'true'){
                ////console.log('inside here Accepted');
                this.showAccept = false;
                this.showReopen = true;
            }
            else if(this.userpermission == 'ShowReopenForSE' && this.statusvalue != 'Reopened'){
                this.showAcceptReopen = false;
                this.showAccept = false;
                this.showReopen = true;
            }
        }
    }

    handleTextAreaChange(event){
        this.textareavalue =  event.detail.value;
    }

    handleNotifyOpp(event){
        ////console.log('checked'+ event.target.checked);
        this.notifyopp = event.target.checked;
        ////console.log('notify::'+ this.notifyopp);
    }

    @api
    callFromParent(permission){
        ////console.log('permission'+permission);
        this.userpermission = permission;
        ////console.log('userpermission'+this.userpermission);
        if(this.stage=='Integration'){
            if(this.statusvalue == 'Not Accepted' && this.userpermission == 'true'){
                this.showAcceptReopen = true;
                this.showAccept = true;
                this.showReopen = true;
            } 
            else if(this.statusvalue == 'Reopened' && this.userpermission == 'true'){
                //console.log('inside here');
                this.showAcceptReopen = false;
                this.showAccept = true;
                this.showReopen = false;
            }
            else if((this.statusvalue == 'Accepted') && this.userpermission == 'true'){
                //console.log('inside here Accepted');
                this.showAcceptReopen = false;
                this.showAccept = false;
                this.showReopen = true;
            }
            else if(this.userpermission == 'ShowReopenForSE' && this.statusvalue != 'Reopened'){
                this.showAcceptReopen = false;
                this.showAccept = false;
                this.showReopen = true;
            }
            if(this.userpermission == 'false' || (this.userpermission == 'ShowReopenForSE' && this.statusvalue == 'Reopened')){
                //console.log('inside permission false');
                this.showAcceptReopen = false;
                this.showAccept = false;
                this.showReopen = false;
            }
        }
    }
    handleAccept(){
        this.showAcceptPopup=true;
        //just testing
        //this.checkOnStageChange('Gating');
    }

    handleAcceptClick(){
        this.showAcceptPopup=true;
        //Code to check if everything is done will go here!!!

        const fields = {};
            fields[ID_FIELD.fieldApiName] = this.chimeid;
            fields[STATUS_FIELD.fieldApiName] = 'Accepted';

            const recordInput = { fields };

            updateRecord(recordInput)
                .then(() => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success!',
                            message: 'CHIME form has been accepted.',
                            variant: 'success'
                        })
                    );
                    this.statusvalue = 'Accepted';
                    //Closing and clearing the Modal Popup.
                    this.handleAcceptClose();
                    //this.showReopen=true;
                    //this.showAccept=false;
                    getRecordNotifyChange([{recordId: this.chimeid}]);
                    this.checkPermissionofUser('Accept');
                    //this.callFromParent(this.userpermission);
                    
                    this.notifyParentOnUpdate('Accepted');
                    //Set the questionnaire from Editable to Readonly
                    const message = {
                        transition: false,
                        readOnly: true
                    };
                    publish(this.messageContext, STAGE_TRANSITION, message);
                    this.dispatchEvent(new CustomEvent('acceptedform'));

                    const interactWithDetailPage = {
                        Interact: false,
                    };
                    publish(this.messageContext, Interaction, interactWithDetailPage);


                    //Notify the team on form Accept
                    notifyOppTeam({ chimeId: this.chimeid, operation : 'Accepted' })
                            .then(result => {
                                let res = result;
                                //console.log('Opp team notified on Accept');
                            })
                            .catch(error => {
                                console.log('error'+error);
                            });
                })
                .catch(error => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error creating record',
                            message: error.body.message,
                            variant: 'error'
                        })
                    );
                });
    }
        /*const event = new ShowToastEvent({
            "title": "Success!",
            "variant": "success",
            "message": "CHIME form has been accepted.",
        });
        this.dispatchEvent(event);*/


    handleReopen(){
        //console.log('inside handleReopen');
        this.showReopenPopup=true;
    }
    handleAcceptClose(){
        this.showAcceptPopup=false;
        this.showReopenPopup=false;
        //this.dispatchEvent(new CustomEvent('close'));
        this.clearReopen();
    }

    clearReopen(){
        this.value='';
        this.notifyopp=false;
        this.textareavalue='';
    }
    handleReopenClick(){
        //console.log('Reopened');
        this.updateCHIME();
    }

    notifyParentOnUpdate(operation){
        //console.log('parentUpdate'+operation);
        const custEvent = new CustomEvent(
            'update', {
                detail: operation
            });
        this.dispatchEvent(custEvent);
    }

    checkPermissionofUser(action){
        checkPermission({ operation: action })
            .then(result => {
                var res = result; 
                this.permission = result;
                //console.log('result Value::calling method in child'+res);
                this.callFromParent(result);
            })
            .catch(error => {
                console.log('error'+error);
            });
    }

    //Code to update the Chime once it is Reopened
    updateCHIME() {
        const allValid = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputFields) => {
                inputFields.reportValidity();
                return validSoFar && inputFields.checkValidity();
            }, true);
        var checkboxMandate= false;
        if(this.value.length!=0){
            checkboxMandate= true;
        }
        /*if(this.value=='' || this.value == undefined){
            checkboxMandate= false;
        }    else{
            checkboxMandate= true;
        }*/

        if (allValid && checkboxMandate) {
            // Create the recordInput object
            let reasons='';
            this.value.forEach(function(element) {
                if(reasons==''){
                    reasons = element;
                }else{
                reasons = reasons + ';' +element;
                }
              });
              if(reasons.includes('Other') && (!this.textareavalue)){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Fill Notes.',
                        message: 'Please fill Notes if Other is selected.',
                        variant: 'error'
                    })
                 );
              }else{
                //console.log('reasons:'+ reasons);
                const fields = {};
                fields[ID_FIELD.fieldApiName] = this.chimeid;
                fields[NOTIFY_FIELD.fieldApiName] = this.notifyopp;
                fields[NOTES_FIELD.fieldApiName] = this.template.querySelector("[data-field='Notes']").value;
                fields[REASON_FIELD.fieldApiName] = reasons;
                fields[STATUS_FIELD.fieldApiName] = 'Reopened';

                const recordInput = { fields };

                updateRecord(recordInput)
                    .then(() => {
                        var notesvalue = this.template.querySelector("[data-field='Notes']").value;
                        var tooltip;
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: 'CHIME Form Reopend.',
                                variant: 'success'
                            })
                        );
                        this.statusvalue = 'Reopened';
                        
                        //this.showReopen=false;
                        //this.showAccept=true;
                        //below line for checking if Accept/Reopen button has to be shown.
                        getRecordNotifyChange([{recordId: this.chimeid}]);
                        this.checkPermissionofUser('Accept');
                        //this.callFromParent(this.userpermission);
                        
                        this.notifyParentOnUpdate('Reopened');
                        let reopenresason = reasons.replaceAll(';',', ');
                        //set the reopen text on header                    
                        if(notesvalue == undefined || notesvalue=='' || notesvalue == null){
                            tooltip ={reasons : reopenresason, notes: '-NA-' };
                        }else{
                            tooltip ={reasons : reopenresason, notes: notesvalue};
                        }
                        this.dispatchEvent(new CustomEvent('reopenform', { detail: tooltip }));
                        //Set the questionnaire from Readonly to Editable
                        //this.dispatchEvent(new CustomEvent('editablequestionnaire'));
                        //console.log('before notifying');
                        //code to send notification if notify opp is selected
                        //console.log('notifyopp'+this.notifyopp);
                        if(this.notifyopp == true){
                            //console.log('notifyopp Reopen inside');
                            notifyOppTeam({ chimeId: this.chimeid, operation : 'Reopened' })
                                .then(result => {
                                    var res= result;
                                    //console.log('Opp team notified on Reopen');
                                })
                                .catch(error => {
                                    console.log('error'+error);
                                });
                        }

                        //Set the questionnaire from Readonly to Editable 
                        const message = {
                            transition: false,
                            readOnly: false
                        };
                        publish(this.messageContext, STAGE_TRANSITION, message);

                        const interactWithDetailPage = {
                            Interact: true,
                        };
                        publish(this.messageContext, Interaction, interactWithDetailPage);

                        //Closing and clearing the Modal Popup.
                        this.handleAcceptClose();
                    })
                    .catch(error => {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error creating record',
                                message: error.body.message,
                                variant: 'error'
                            })
                        );
                    });
            }
        }    
        else {
            // The form is not valid
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Something is wrong',
                    message: 'Check your input and try again.',
                    variant: 'error'
                })
             );
        }
    }

    checkOnStageChange(stage){
    StageTransitionCheck({ chimeId: this.chimeid , currentStage: stage })
            .then(result => {
                //console.log('resrfd:',result);
                var res = JSON.parse(result);
                const res1 = Object.assign({}, res);
                //console.log('cek:'+res1.moveToNextStage);
                //console.log('res',res1);
            })
            .catch(error => {
                console.log('error'+error);
                //this.error = error;
                //this.isloading = false;
            });
    }
}