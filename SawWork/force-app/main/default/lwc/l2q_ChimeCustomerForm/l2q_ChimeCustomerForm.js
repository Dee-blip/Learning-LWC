import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import chimeDetails from '@salesforce/apex/ChimeTriggerClass.getChimeDetails';
import validateChimeAccess from '@salesforce/apex/ChimeTriggerClass.validateChimeAccess';
import getSelectedProductList from '@salesforce/apex/ChimeTriggerClass.getSelectedProducts';
import STAGE_FIELD from '@salesforce/schema/CHIME__c.Stage__c';
import ID_FIELD from '@salesforce/schema/CHIME__c.Id';
import SignOff_FIELD from '@salesforce/schema/CHIME__c.Sign_Off__c';
import { updateRecord } from 'lightning/uiRecordApi';
import stageTransitionCheck from '@salesforce/apex/ChimeTriggerClass.StageTransitionChecknew';
export default class L2q_ChimeCustomerForm extends LightningElement {
    @api chimeId;
    @api chimeName;
    @track chimedata;
    @track selectedAssociation;
    @track selectedProducts = [];
    @track showSuccessCriteriaPopUp = false;
    @track disableQuestionnaireCSS = '';
    @track hasChimeAccess = false;
    @track noAccessMessage = '';

    isloading = false;
    prevSelectedProduct = '';

    //CHIME P2
    ispoc = false;
    
    connectedCallback() {
        this.isloading = true;
    }

    @wire(CurrentPageReference)
    setCurrentPageRef(pageRef) {
        this.chimeId = pageRef.state.c__chimeId;
        let str = pageRef.state.c__chimeName;
        if (str !== undefined) {
            str = decodeURIComponent((str + '').replace(/\+/g, '%20'));
            this.chimeName = str;
        }
        if (this.chimeId !== undefined) {
            this.checkChimeAccess();
        }
    }

    checkChimeAccess() {
        validateChimeAccess({ chimeId: this.chimeId })
            .then(result => {
                this.hasChimeAccess = result;
                if (this.hasChimeAccess) {
                    this.loadSelectedProducts();
                    this.loadChimeDetails();
                }
                else {
                    this.noAccessMessage = 'You do not have sufficient access to view this document.';
                }
            })
            .catch(error => {
                this.error = error;
            });
    }

    checkOnStageChange() {
        var stage = this.chimedata.Stage__c;
        var res;
        console.log("L2Q_ChimeDetail page :: handle stage change");
        console.log("L2Q_ChimeDetail page ", this.chimedata.Stage__c);

        let quesIDs = this.callApexmethod();
        
        stageTransitionCheck({ chimeId: this.chimeId, currentStage: stage, quesList : JSON.stringify(quesIDs) })
            .then(result => {
                console.log('resrfd:', result);

                res = JSON.parse(result);
                const res1 = Object.assign({}, res);
                console.log('cek:' + res1.moveToNextStage);
                console.log('res', res1);
                if (res1.moveToNextStage == true) {
                    //this.updateStage('Scoping');
                    this.chimedata.Stage__c = 'Scoping';
                }
            })
            .catch(error => {
                //this.error = error;
                //this.isloading = false;
                console.log('error inside checkOnStageChange', error);
            });
    }

    updateStage(stage) {

        // Create the recordInput object

        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.chimeId;
        fields[STAGE_FIELD.fieldApiName] = stage;

        const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
                this.chimedata.Stage__c=stage;
                /*this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'CHIME Form stage changed to ' + stage,
                        variant: 'success'
                    })
                );*/
                
            })
            .catch(error => {
                console.log('error inside updateStage', error);
                /*this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error Changing stage',
                        message: error.body.message,
                        variant: 'error'
                    })
                );*/
            });

    }

    loadChimeDetails() {
        chimeDetails({ chimeId: this.chimeId })
            .then(result => {
                this.chimedata = JSON.parse(JSON.stringify(result));
                if (this.chimedata.Is_POC_Demo__c && this.chimedata.POC_Type__c == 'Standard-POC') {
                    this.ispoc = true;
                } else {
                    this.ispoc = false;
                }
                if (this.chimedata.Stage__c === 'Closed' || (this.chimedata.Stage__c === 'Integration' && this.chimedata.Status__c !== 'Reopened'))
                    this.disableQuestionnaireCSS = 'pointer-events: none';
                else
                    this.disableQuestionnaireCSS = '';
                this.isloading = false;
            })
            .catch(error => {
                this.error = error;
                this.isloading = false;
            });
    }
    loadSelectedProducts() {
        getSelectedProductList({ chimeId: this.chimeId })
            .then(result => {
                if (result.length > 0) {
                    this.selectedAssociation = result[0];
                    this.prevSelectedProduct = result[0].Id;
                }
                this.selectedProducts = result;
                this.markSelected();
            })
            .catch(error => {
                this.error = error;
            });
    }
    markSelected() {
        setTimeout(() => {
            this.template.querySelector('.' + this.prevSelectedProduct).classList.add('onProductMouseOver');
        }, 300);
    }
    onProductSelect(event) {
        let prodId = event.target.id;
        prodId = prodId.split('-')[0];
        let index = this.selectedProducts.findIndex(v => v.Id === prodId);
        this.selectedAssociation = this.selectedProducts[index];
        if (this.template.querySelector('.' + this.prevSelectedProduct) != null)
            this.template.querySelector('.' + this.prevSelectedProduct).classList.remove('onProductMouseOver');
        this.template.querySelector('.' + prodId).classList.add('onProductMouseOver');
        this.prevSelectedProduct = prodId;
        let questionnaireApp = this.template.querySelector('.questionnaire');
        console.log("questionnaireApp :", questionnaireApp);
        if (questionnaireApp) {
            console.log("calling handle product");
            console.log("product id :" + this.selectedAssociation.CHIME_Product__c);
            console.log("chime stage :" + this.chimedata.Stage__c);
            console.log("chime id:" + this.chimeId);
            questionnaireApp.handleProductChange(this.selectedAssociation.CHIME_Product__c, 'Gating,Scoping', this.chimeId);
        }
    }

    handleOpenSuccessCriteria() {
        this.showSuccessCriteriaPopUp = true;
    }
    handleCloseSuccessCriteria() {
        this.showSuccessCriteriaPopUp = false;
       // window.location.href = '/'+ this.recordId;
    }
    saveSignOff(event){
        const fields = {};
            fields[ID_FIELD.fieldApiName] = this.chimeId;
            fields[SignOff_FIELD.fieldApiName] = event.target.checked;

            const recordInput = { fields };
            updateRecord(recordInput)
            .then(result => {
                console.log("Sign Off field updated Successfull", result);
            })
            .catch(error => {
                console.log("Sign Off field not updated", error);
            })
    }

    callApexmethod(){
        let quesIds=[];
        let qIds = this.template.querySelector('.questionnaire').fetchQuestionIds();
        quesIds = qIds;
        //console.log('quesIds',quesIds);
         
        return quesIds;
    }
}