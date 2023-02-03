/**
 * @description       : 
 * @author            : mamahaja
 * @team              : GSM
 * @last modified on  : 03-09-2022
 * @last modified by  : apyati
 * Modifications Log
 * Ver   Date         Author   Modification
 * 1.0   12-21-2021   mamahaja   Initial Version
**/
import { LightningElement, api, track, wire } from 'lwc';
//import { getRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';
import getSelectedProductList from '@salesforce/apex/ChimeTriggerClass.getSelectedProducts';
import associateProductWithChime from '@salesforce/apex/ChimeTriggerClass.createChimeProductAssociation';
import disassociateProductWithChime from '@salesforce/apex/ChimeTriggerClass.deleteChimeProductAssociation';
import chimeDetails from '@salesforce/apex/ChimeTriggerClass.getChimeDetails';
import STAGE_FIELD from '@salesforce/schema/CHIME__c.Stage__c';
import ID_FIELD from '@salesforce/schema/CHIME__c.Id';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import stageTransitionCheck from '@salesforce/apex/ChimeTriggerClass.StageTransitionChecknew';
import clearFlag from '@salesforce/apex/ChimeTriggerClass.clearFlag';
import { publish, subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import STAGE_TRANSITION from '@salesforce/messageChannel/L2Q_ChimeStageTransition__c';
import Interaction from '@salesforce/messageChannel/L2Q_InteractHeaderToDetailComp__c';


import LOE_MESSAGE from '@salesforce/messageChannel/l2q_LOERefresh__c';

//ESESP-5366 Changes - Start
import updateChimeImplementationType from '@salesforce/apex/L2Q_ChimeFormLOETabController.updateImplementationModeOnChimeRec';
//ESESP-5366 Changes - End
//import method for CHIME Read only functionality
import checkForReadOnly from '@salesforce/apex/ChimeTriggerClass.checkForReadOnly';
//CHIME P2
import setEnterpriseProductFlagOnChime from '@salesforce/apex/ChimeTriggerClass.setEnterpriseProductFlagOnChime';
import getEnterpriseProductsOnChime from '@salesforce/apex/ChimeTriggerClass.getEnterpriseProductsOnChime';

import checkPreSalesUser from '@salesforce/apex/ChimeTriggerClass.checkPreSalesUser';

export default class L2q_ChimeDetailPage extends LightningElement {
    @wire(MessageContext) messageContext;
    subscription = null;
    subscription1 = null;

    @api chimeId;
    @track showProdSearchResults = false;
    @track selectedProducts = [];
    @track chimedata;
    @track selectedAssociation;
    @track showChat = false;
    @track disableDeleteIcon = false;

    //Vars for Stage transition
    //@track stageGating = false;
    //@track stageScoping = false;
    //@track stageIntegration = false;
    //@track stageClosed = false;
    @track showLOE = false;

    @track currentStage;
    @wire(MessageContext) messageContext;

    checkedProd = '';
    tempId = '';

    listCPA = [];

    //CHIME P2
    ispoc = false;
    //allProductsEnterprise = false;
    hasEnterpriseProducts = 'None';
    @track isPreSalesuser = false;
    @track hideLOETab = false;
    @track hideProductApproval = false;

    archiveForm = false;

    connectedCallback() {
        this.loadSelectedProducts();
        this.loadEnterpriseProducts();
        this.loadChimeDetails();

        //Check Read only access
        this.checkReadOnlyAccess();

        //check if user is preSales user
        this.checkForPreSalesUser();

        //console.log("Chime detail connected callback :: stage :"+this.chimedata);
        this.subscription = subscribe(
            this.messageContext,
            STAGE_TRANSITION,
            (message) => {
                this.handleIntegrationStageTransition(message);
            });

        this.subscription1 = subscribe(
            this.messageContext,
            Interaction,
            (message) => {
                if (message.Interact === true) {
                    this.disableDeleteIcon = false;
                }
                else if (message.Interact === false) {
                    this.disableDeleteIcon = true;
                }
            });
    }

    handleIntegrationStageTransition(message) {
        //this.stageScoping = false;
        //this.stageGating = false;
        //this.stageIntegration = true;
        console.log('messageInDetailPage:', message);
        if (message.readOnly === false) {
            //making content clickable
            /*const divblock = this.template.querySelector('[data-id="chimeDetail"]');
            if(divblock){
                this.template.querySelector('[data-id="chimeDetail"]').className='';
            }*/
            const divblock1 = this.template.querySelector('[data-id="chimeAddProduct"]');
            if (divblock1) {
                this.template.querySelector('[data-id="chimeAddProduct"]').className = '';
            }
            /*const divblock2 = this.template.querySelector('[data-id="chimeDetail1"]');
            if(divblock2){
                this.template.querySelector('[data-id="chimeDetail1"]').className='unclickable';
            }*/
        } else {
            if (this.currentStage != 'Closed') {
                this.currentStage = 'Integration';
            }
            this.makeUnclickable();
        }
    }
    disconnectedCallback() {
        // Unsubscribe from BearListUpdate__c message
        unsubscribe(this.subscription);
        this.subscription = null;

        unsubscribe(this.subscription1);
        this.subscription1 = null;
    }

    makeUnclickable() {
        //console.log('making Unclickable');
        /*const divblock = this.template.querySelector('[data-id="chimeDetail"]');
        if(divblock){
            this.template.querySelector('[data-id="chimeDetail"]').className='unclickable';
        }*/
        const divblock1 = this.template.querySelector('[data-id="chimeAddProduct"]');
        if (divblock1) {
            this.template.querySelector('[data-id="chimeAddProduct"]').className = 'unclickable';
        }
        /*const divblock2 = this.template.querySelector('[data-id="chimeDetail1"]');
        if(divblock2){
            this.template.querySelector('[data-id="chimeDetail1"]').className='unclickable';
        }*/
        this.disableDeleteIcon = true;

    }

    loadChimeDetails() {
        chimeDetails({ chimeId: this.chimeId })
            .then(result => {
                this.chimedata = JSON.parse(JSON.stringify(result));
                console.log('Chimedata:', this.chimedata);
                this.currentStage = JSON.parse(JSON.stringify(this.chimedata)).Stage__c;
                //this.ispoc = JSON.parse(JSON.stringify(this.chimedata)).Is_POC_Demo__c;
                //set the ispoc flag if POC flag is checked and poc type = Standard-POC
                //if flag != Standard-POC then load Full integration questions. 
                if (this.chimedata.Is_POC_Demo__c && this.chimedata.POC_Type__c == 'Standard-POC') {
                    this.ispoc = true;
                } else {
                    this.ispoc = false;
                }
                if (this.chimedata.Is_POC_Demo__c) {
                    this.hideProductApproval = true
                }
                
                if (this.chimedata.Is_POC_Demo__c){
                    if(this.chimedata.POC_Type__c == 'Custom-POC' && (this.hasEnterpriseProducts === 'None' || (this.hasEnterpriseProducts === 'All' && this.chimedata.Implementation_Type__c == 'Managed') || (this.hasEnterpriseProducts === 'Mix'))){
                        this.hideLOETab = false;
                    }else{
                        this.hideLOETab = true;
                    }
                }
                /*if (this.chimedata.Stage__c == 'Gating') {
                    this.stageGating = true;
                } else if (this.chimedata.Stage__c == 'Scoping') {
                    this.stageScoping = true;
                } else if (this.chimedata.Stage__c == 'Integration') {
                    this.stageIntegration = true;
                } else if (this.chimedata.Stage__c == 'Closed') {
                    this.stageClosed = true;
                }*/
                if (this.currentStage === 'Integration' && this.chimedata.Status__c !== 'Reopened') {
                    this.makeUnclickable();
                    setTimeout(() => {
                        /*const message = {
                            transition: false,
                            readOnly: true
                        };*/
                        //publish(this.messageContext, STAGE_TRANSITION, message);
                    }, 2000);

                } else if (this.currentStage === 'Closed') {
                    this.makeUnclickable();
                    setTimeout(() => {
                        /*const message = {
                            transition: false,
                            readOnly: true
                        };*/
                        //publish(this.messageContext, STAGE_TRANSITION, message);
                    }, 2000);
                    this.template.querySelector('[data-id="chimeProgressBar"]').className = 'unclickable';
                }
                this.isloading = false;

                if(this.chimedata.Archive_Hidden__c === true){
                    this.archiveForm = true;
                    this.archiveChimeFrom();
                }
            })
            .catch(error => {
                this.error = error;
                this.isloading = false;
            });
    }
    markSelected() {
        setTimeout(() => {
            //console.log("Marking selected product");
            //console.log(this.template.querySelector('.' + this.tempId));
            this.template.querySelector('.' + this.tempId).classList.add('onProductMouseOver');
        }, 300);
    }
    buildChimeProductRelation() {
        associateProductWithChime({ chimeId: this.chimeId, productId: this.checkedProd })
            .then(result => {
                this.selectedProducts.push(result);
                this.selectedProducts.sort((a, b) => (a.CHIME_Product__r.Product_Name__c.toLowerCase() > b.CHIME_Product__r.Product_Name__c.toLowerCase()) ? 1 : ((b.CHIME_Product__r.Product_Name__c.toLowerCase() > a.CHIME_Product__r.Product_Name__c.toLowerCase()) ? -1 : 0));

                setTimeout(() => {
                    this.template.querySelector('[data-id="' + result.Id + '"]').click();
                    setTimeout(() => {
                        this.checkOnStageChange();
                    }, 1000);
                }, 200);

                //CHIME P2 set the AllEnterpriseProduct Flag
                if (this.chimedata.Is_POC_Demo__c) {
                    getEnterpriseProductsOnChime({ chimeId: this.chimeId, isUpdate: true })
                        .then(result1 => {
                            console.log('result:getEnterpriseProductsOnChime', result1);
                            this.hasEnterpriseProducts = result1;
                            if (this.chimedata.Is_POC_Demo__c &&
                                (this.chimedata.POC_Type__c == 'Standard-POC' || (this.chimedata.POC_Type__c === 'Custom-POC' && this.chimedata.Implementation_Type__c == 'Standard' && this.hasEnterpriseProducts === 'All'))) {
                                this.hideLOETab = true;
                            } else {
                                this.hideLOETab = false;
                            }
                            const message = {
                                refresh: true,
                            };
                            publish(this.messageContext, LOE_MESSAGE, message);
                        })
                        .catch(error => {
                            console.log('error:', error);
                        })
                }
                else{
                    //Vishnu - To refresh header
                    const message = {
                        refresh: true,
                    };
                    publish(this.messageContext, LOE_MESSAGE, message);
                }
            })
            .catch(error => {
                this.error = error;
            });
    }

    loadEnterpriseProducts() {
        getEnterpriseProductsOnChime({ chimeId: this.chimeId, isUpdate: false })
            .then(result1 => {
                console.log('result:getEnterpriseProductsOnChime', result1);
                this.hasEnterpriseProducts = result1;
            })
            .catch(error => {
                console.log('error:', error);
            })
    }

    loadSelectedProducts() {
        //var qproductName;
        getSelectedProductList({ chimeId: this.chimeId })
            .then(result => {
                if (result.length > 0) {
                    this.selectedAssociation = result[0];
                    this.tempId = result[0].Id;
                    this.markSelected();
                    //console.log( 'result', ...result);                
                }
                this.selectedProducts = result;
                this.selectedProducts.sort((a, b) => (a.CHIME_Product__r.Product_Name__c.toLowerCase() > b.CHIME_Product__r.Product_Name__c.toLowerCase()) ? 1 : ((b.CHIME_Product__r.Product_Name__c.toLowerCase() > a.CHIME_Product__r.Product_Name__c.toLowerCase()) ? -1 : 0));


                //Code for questionnaire refresh if user has not seen in real time
                //console.log('result of product association::',result);
                //qproductName='';
                result.forEach(element => {
                    if (element.Questionnaire_Changed__c === true) {
                        const event = new ShowToastEvent({
                            "title": "The questionnaire for " + element.CHIME_Product__r.Product_Name__c + " has been changed.",
                            "message": "Publisher notes: " + element.Publisher_notes__c,
                            "variant": 'warning',
                            "mode": "sticky",

                        });
                        this.dispatchEvent(event);
                    }
                    this.listCPA.push(element.Id)
                }
                );
                //console.log('qproductName::'+ qproductName);
                this.clearChimeProductFlag(this.listCPA);

            })
            .catch(error => {
                this.error = error;
                if (JSON.stringify(error).includes('access')) {
                    const event = new ShowToastEvent({
                        title: 'Error',
                        message: 'Sorry! You do not have access to CHIME',
                        mode: 'sticky',
                        variant: 'warning'
                    });
                    this.dispatchEvent(event);

                }
                else {
                    const event = new ShowToastEvent({
                        title: 'Error',
                        message: 'Some Error occured in loading products',
                        mode: 'sticky',
                        variant: 'warning'
                    });
                    this.dispatchEvent(event);
                    this.isloading = false;
                }
            });
    }
    clearChimeProductFlag(list) {
        //clear the Questionnaire_Changed__c flag on the Chime_Product_Association__c object after notification has been shown
        //console.log('listCPA:'+ JSON.stringify(this.listCPA));
        //console.log("clearChimeProductFlag List", list);
        clearFlag({ cpas: JSON.stringify(this.listCPA) })
            .then(() => {
                //console.log('Success in clearFlag', result);
            })
            .catch(error => {
                console.log('Error in clearFlag', error);
            });
    }

    handleProdSelectionInDetail(event) {
        let selectedProds = this.selectedProducts;
        if (selectedProds.some(selectedProd => selectedProd.CHIME_Product__c === event.detail.record.Id)) {
            if (event.detail.action === 'remove') {
                if (this.selectedProducts.length === 1) {
                    alert('Atleast One Product is Required.');
                    return;
                }
                let index = selectedProds.findIndex(v => v.CHIME_Product__c === event.detail.record.Id);
                disassociateProductWithChime({ associationId: selectedProds[index].Id })
                    .then(result => {
                        //CHIME P2 set the AllEnterpriseProduct Flag
                        if (this.chimedata.Is_POC_Demo__c) {
                            getEnterpriseProductsOnChime({ chimeId: this.chimeId, isUpdate: true })
                                .then(result1 => {
                                    console.log('result:getEnterpriseProductsOnChime', result1);
                                    this.hasEnterpriseProducts = result1;
                                    if (this.chimedata.Is_POC_Demo__c){
                                        if(this.chimedata.POC_Type__c == 'Custom-POC' && (this.hasEnterpriseProducts === 'None' || (this.hasEnterpriseProducts === 'All' && this.chimedata.Implementation_Type__c == 'Managed') || (this.hasEnterpriseProducts === 'Mix'))){
                                            this.hideLOETab = false;
                                        }else{
                                            this.hideLOETab = true;
                                        }
                                    }
                                })
                                .catch(error => {
                                    console.log('error:', error);
                                })
                        }
                    })
                    .catch(error => {
                        this.error = error;
                    });
                selectedProds.splice(index, 1);
                this.selectedProducts = selectedProds;
                this.selectedProducts.sort((a, b) => (a.CHIME_Product__r.Product_Name__c.toLowerCase() > b.CHIME_Product__r.Product_Name__c.toLowerCase()) ? 1 : ((b.CHIME_Product__r.Product_Name__c.toLowerCase() > a.CHIME_Product__r.Product_Name__c.toLowerCase()) ? -1 : 0));

            }
        }
        else {
            if (event.detail.action === 'add') {
                this.checkedProd = event.detail.record.Id;
                this.buildChimeProductRelation();
            }
        }
    }
    onProductSelect(event) {
        this.template.querySelector('lightning-tabset').activeTabValue = 'Questions';
        let prodId = event.target.dataset.id;
        prodId = prodId.split('-')[0];
        let index = this.selectedProducts.findIndex(v => v.Id === prodId);
        this.selectedAssociation = this.selectedProducts[index];
        //console.log("L2q detail page selectedAssociation :"+this.selectedAssociation);
        if (this.template.querySelector('.' + this.tempId) != null)
            this.template.querySelector('.' + this.tempId).classList.remove('onProductMouseOver');
        this.template.querySelector('.' + prodId).classList.add('onProductMouseOver');
        this.tempId = prodId;
        let questionnaireApp = this.template.querySelector('.questionnaire');
        //console.log("questionnaireApp :", questionnaireApp);
        if (questionnaireApp) {
            //console.log("calling handle product");
            //console.log("product id :"+this.selectedAssociation.CHIME_Product__c);
            //console.log("chime stage :"+this.chimedata.Stage__c);
            //console.log("chime id:"+this.chimeId);
            questionnaireApp.handleProductChange(this.selectedAssociation.CHIME_Product__c, this.chimedata.Stage__c, this.chimeId);
        }
    }
    removeProduct(event) {
        let removedProdId = event.target.name;
        let selectedProductId = event.target.title;
        if (this.selectedProducts.length === 1) {
            alert('Atleast One Product is Required.');
            return;
        }
        if (this.selectedProducts.some(selectedProd => selectedProd.Id === selectedProductId)) {
            let index = this.selectedProducts.findIndex(v => v.Id === selectedProductId);
            disassociateProductWithChime({ associationId: this.selectedProducts[index].Id })
                .then(() => {
                    //console.log("removeProduct result", result);
                    if (this.selectedProducts.length > 0) {
                        if (this.template.querySelector('.' + this.tempId) != null)
                            this.template.querySelector('.' + this.tempId).classList.remove('onProductMouseOver');

                        this.tempId = this.selectedProducts[0].Id;
                        this.markSelected();

                        //CHIME P2 set the AllEnterpriseProduct Flag
                        if (this.chimedata.Is_POC_Demo__c) {
                            getEnterpriseProductsOnChime({ chimeId: this.chimeId, isUpdate: true })
                                .then(result1 => {
                                    console.log('result:getEnterpriseProductsOnChime', result1);
                                    this.hasEnterpriseProducts = result1;
                                    if (this.chimedata.Is_POC_Demo__c){
                                        if(this.chimedata.POC_Type__c == 'Custom-POC' && (this.hasEnterpriseProducts === 'None' || (this.hasEnterpriseProducts === 'All' && this.chimedata.Implementation_Type__c == 'Managed') || (this.hasEnterpriseProducts === 'Mix'))){
                                            this.hideLOETab = false;
                                        }else{
                                            this.hideLOETab = true;
                                        }
                                    }
                                })
                                .catch(error => {
                                    console.log('error:', error);
                                })
                        }

                        //Vishnu - To refresh header


                        // ESESP-5366 Change - Vishnu - Start
                        updateChimeImplementationType({ chimeRecId: this.chimeId })
                            .then(updateResult => {
                                //console.log("updateResult",updateResult);
                                //Vishnu - To refresh header
                                const message = {
                                    refresh: true,
                                };
                                publish(this.messageContext, LOE_MESSAGE, message);
                            }).catch(error => {
                                this.error = error;
                            });
                        // ESESP-5366 Change - Vishnu - End  



                        this.selectedAssociation = this.selectedProducts[0];
                        this.template.querySelector('lightning-tabset').activeTabValue = 'Questions';

                        //console.log('all products**'+JSON.stringify(this.selectedProducts[0].CHIME_Product__c));    
                        this.template.querySelector('c-chime-questionnaire').handleProductChange(this.selectedProducts[0].CHIME_Product__c, this.chimedata.Stage__c, this.chimeId);
                    }
                })
                .catch(error => {
                    this.error = error;
                });
            this.selectedProducts.splice(index, 1);
            this.selectedProducts.sort((a, b) => (a.CHIME_Product__r.Product_Name__c.toLowerCase() > b.CHIME_Product__r.Product_Name__c.toLowerCase()) ? 1 : ((b.CHIME_Product__r.Product_Name__c.toLowerCase() > a.CHIME_Product__r.Product_Name__c.toLowerCase()) ? -1 : 0));
            this.template.querySelector("c-l2q_product_search").handleProductRemoval(removedProdId);
        }
    }

    handleScopingClick() {
        ////console.log('in handleScopingClick');
        //this.stageScoping=true;
        //this.stageGating=false;
        if (this.currentStage === "Integration") {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Info',
                message: 'You cannot move to Scoping stage from Integration.',
                variant: 'info'
            }));
        } else {
            this.updateStage('Scoping');
        }
    }
    handleGatingClick() {
        //console.log('in handleGatingClick');
        //this.stageScoping=false;
        //this.stageGating=true;
        //console.log("Gating clicked");
        if (this.currentStage === "Integration") {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Info',
                message: 'You cannot move to Gating stage from Integration.',
                variant: 'info'
            }));
        } else {
            this.updateStage('Gating');
        }
    }

    handleIntegrationClick() {

        console.log( 'allquesn =>' +this.chimedata.Is_All_Qun_Ans_Complete__c);


        if (this.isPreSalesuser && this.chimedata.Is_POC_Demo__c && this.chimedata.Is_All_Qun_Ans_Complete__c) {
            // && this.hasEnterpriseProducts === 'All' && (this.chimedata.POC_Type__c == 'Standard-POC' || (this.chimedata.POC_Type__c === 'Custom-POC' && this.chimedata.Implementation_Type__c == 'Standard'))) {
            this.updateStage('Integration');
        }
        else {
            if (this.currentStage !== "Integration") {
                //console.log("SHow integration toast");
                //alert('You cannot move to Integration manually!');
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Info',
                    message: 'You cannot move to Integration manually!',
                    variant: 'info'
                }));


            }
            let currentStageValue = this.currentStage;
            console.log(" currentStageValue :" + currentStageValue);

            this.currentStage = "DummmyUpdate";
            console.log("Current stage :" + this.currentStage);

            this.currentStage = currentStageValue;
            console.log("Current stage :" + this.currentStage);

        }
    }


    updateStage(stage) {

        // Create the recordInput object

        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.chimeId;
        fields[STAGE_FIELD.fieldApiName] = stage;

        const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
                if (stage === 'Gating') {
                    this.currentStage = 'Gating';
                    //this.stageScoping = false;
                    //this.stageGating = true;
                } else if (stage === 'Scoping') {
                    this.currentStage = 'Scoping';
                    //this.stageScoping = true;
                    //this.stageGating = false;
                }
                else if (stage === 'Integration') {
                    this.currentStage = 'Integration';
                    //this.stageScoping = true;
                    //this.stageGating = false;
                }
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'CHIME Form stage changed to ' + stage,
                        variant: 'success'
                    })
                );
                if (stage === 'Integration') {
                    window.location.reload();
                }
                if (stage == 'Closed') {
                    window.location.reload();
                }
                this.statusvalue = 'Reopened';
                this.chimedata.Stage__c = stage;

                let chimeQuestionnaire = this.template.querySelector('.questionnaire');
                if (chimeQuestionnaire) {
                    chimeQuestionnaire.handleStageChange(stage);
                }
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error Changing stage',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });

    }
    checkOnStageChange() {
        var stage, res;
        //console.log("L2Q_ChimeDetail page :: handle stage change");
        stage = this.chimedata.Stage__c;
        let quesIDs = this.callApexmethod();
        //console.log("L2Q_ChimeDetail page ",this.chimedata.Stage__c);
        stageTransitionCheck({ chimeId: this.chimeId, currentStage: stage, quesList: JSON.stringify(quesIDs) })
            .then(result => {
                console.log('resrfd:', result);

                res = JSON.parse(result);
                const res1 = Object.assign({}, res);
                //console.log('cek:' + res1.moveToNextStage);
                //console.log('res', res1);
                if (res1.moveToNextStage == true) {
                    this.updateStage('Scoping');
                }
                this.refreshChimeDetails();

            })
            .catch(error => {
                console.error("checkOnStageChange error", error);
                //this.error = error;
                //this.isloading = false;
            });

    }

    refreshChimeDetails(){
        console.log('called refreshChimeDetails ');
        chimeDetails({ chimeId: this.chimeId })
        .then(result => {
            this.chimedata = JSON.parse(JSON.stringify(result));
            console.log( 'allquesn =>' +this.chimedata.Is_All_Qun_Ans_Complete__c);
        }).catch(error => {
            this.error = error;
            this.isloading = false;
        });
    }


    stageTransition(nStage) {
        var newstage = nStage;
        if (newstage === 'Gating') {
            this.stageScoping = false;
            this.stageGating = true;
        } else if (newstage == 'Scoping') {
            this.stageScoping = true;
            this.stageGating = false;
        }
    }
    renderedCallback() {

        const styleApplyAll = document.createElement('style');
        styleApplyAll.innerText = `c-l2q-chime-detail-page .applyAllStyle .slds-button_brand{
            
            font-size:15px;
            background-color: rgb(14, 75, 57);
            border:none;
            }`;
        this.template.querySelector('div').appendChild(styleApplyAll);
    }

    handleLOETabActive() {
        this.showLOE = true;
    }
    handleLOETabInActive() {
        this.showLOE = false;
    }

    toggleChat() {
        var divblock, divChatButton, divChatContainer;
        //console.log("show chat clicked");
        //console.log(this.showChat);
        this.showChat = !this.showChat;
        if (this.showChat) {
            divblock = this.template.querySelector('[data-id="chatblock"]');
            if (divblock) {
                ////console.log("Rotate chat");
                this.template.querySelector('[data-id="chatblock"]').className = 'chat-circle rotated';
            }

            divChatButton = this.template.querySelector('[data-id="chatter-button"]');
            if (divChatButton) {
                ////console.log("Rotate chat");
                this.template.querySelector('[data-id="chatter-button"]').className = 'chatter-button-inverted';
            }
            divChatContainer = this.template.querySelector("c-sccommunitycomments_sccommunitycomments");
            //console.log("divChatContainer",divChatContainer);
            if (divChatContainer) {
                //console.log("Rotate chat");
                this.template.querySelector("c-sccommunitycomments_sccommunitycomments").className = 'chat-container';
            }
        } else {
            divblock = this.template.querySelector('[data-id="chatblock"]');
            if (divblock) {
                //console.log("Rotate chat");
                this.template.querySelector('[data-id="chatblock"]').className = 'chat-circle';
            }

            divChatButton = this.template.querySelector('[data-id="chatter-button"]');
            if (divChatButton) {
                //console.log("Rotate chat");
                this.template.querySelector('[data-id="chatter-button"]').className = 'chatter-button';
            }

        }





    }

    handleLOEchange(event) {

        for (var i = 0; i < this.selectedProducts.length; i++) {

            if (this.selectedProducts[i].Id == event.detail.prod) {
                this.selectedProducts[i].Total_LoE__c = event.detail.loe;
            }
        }

    }

    callApexmethod() {
        let quesIds = [];
        let qIds = this.template.querySelector('.questionnaire').fetchQuestionIds();
        quesIds = qIds;
        //console.log('quesIds',quesIds);

        return quesIds;
    }
    responseDisable = false;
    checkReadOnlyAccess() {
        checkForReadOnly()
            .then(result => {
                console.log('result for checkForReadOnly', result);
                if (result == 'Edit' && !this.archiveForm) {
                        this.responseDisable = false;
                } else if (result == 'ReadOnly') {
                    this.responseDisable = true;
                    //this.disableDeleteIcon= true;
                    this.makeUnclickable();
                    this.template.querySelector('[data-id="chimeProgressBar"]').className = 'unclickable';
                }
            })
            .catch(error => {
                console.log('error', error);
            });
    }
    checkForPreSalesUser() {
        checkPreSalesUser()
            .then(result => {
                this.isPreSalesuser = result;
            })
            .catch(error => {
                console.log('error', error);
            });
    }
    handleClosedClick() {
        if (this.isPreSalesuser && this.currentStage === "Integration" && this.chimedata.Is_POC_Demo__c) {
            // && this.hasEnterpriseProducts === 'All' && (this.chimedata.POC_Type__c == 'Standard-POC' || (this.chimedata.POC_Type__c === 'Custom-POC' && this.chimedata.Implementation_Type__c == 'Standard'))) {
            this.updateStage('Closed');
        }
        else {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Info',
                message: 'You cannot move to Closed stage manually!',
                variant: 'info'
            }));
        }
    }

    //Archive Chime Form 
    archiveChimeFrom(){
        this.responseDisable = true;
        this.makeUnclickable();
        this.template.querySelector('[data-id="chimeProgressBar"]').className = 'unclickable';
    }
}