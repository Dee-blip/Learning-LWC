/**
 * @description       : 
 * @author            : apyati
 * @team              : GSM
 * @last modified on  : 02-15-2022
 * @last modified by  : apyati
 * Modifications Log
 * Ver   Date         Author   Modification
 * 1.0   09-15-2021   apyati   SFDC-8036 added partner account
**/
import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSelectedProductList from '@salesforce/apex/ChimeTriggerClass.getSelectedProductsForChime';
import getParentObjDetails from '@salesforce/apex/ChimeTriggerClass.getObjectDetails';
import createChimeForm from '@salesforce/apex/ChimeTriggerClass.createChime';
import getSuccessCriteria from '@salesforce/apex/ChimeTriggerClass.getSuccCri';
import getProductIdByName from '@salesforce/apex/ChimeTriggerClass.getProductIdByName';
import setEnterpriseProductFlagOnChime from '@salesforce/apex/ChimeTriggerClass.setEnterpriseProductFlagOnChime';
import getEnterpriseProductsOnChime from '@salesforce/apex/ChimeTriggerClass.getEnterpriseProductsOnChime';
import getAssociatedChimePOCDSRs from '@salesforce/apex/ChimeDSRController.getAssociatedChimePOCDSRs';
import { updateRecord } from 'lightning/uiRecordApi';
import DSR_ID from '@salesforce/schema/Deal_Support_Request__c.Id';
import CHIME_FIELD from '@salesforce/schema/Deal_Support_Request__c.CHIME__c';



export default class L2Q_CreateChimeForm extends NavigationMixin(LightningElement) {

    @api iscreate = false;
    @api implementatonType = 'Standard';
    @api chimeFormName = '';
    @api isEmergency = false;
    @api chimeId = '';
    @api parentrecid = '';

    @track opportunityid;
    @track accountid;
    @track selectedProducts = [];
    @track isStandard = true;
    @track successcriteria;
    @track whereclause = '';
    @track createEditCSS = '';
    @track showScopePopUp = false;
    @track scopeModalproductName = '';
    @track scopeModalText = '';

    @api partneraccountid ;
    @api partneraccountname ;
    opportunity_name = '';
    account_name = '';
    errors = [];
    isloading = false;

    //Chime P1 changes
    @api ispoc = false;
    showisPoc=false;
    @api isEmergencyDisabled=false;
    @api isPOCDisabled=false;

    parentObject='';

    //Chime P2 changes
    DSRRequestType='';
    DSRRecordType='';
    DSRProduct='';
    //@api showpoctypes=false;
    @api pocTypeValue='';
    disableImplementationType = false;
    DSRId;
    pocTypeDisabled=false;
    opportunityDisabled =false;

    @api isWorkAtRisk = false;
    @api isWorkAtRiskDisabled = false;
    

    connectedCallback() {

        this.isStandard = (this.implementatonType === 'Standard') ? true : false;
        this.isloading = true;
        this.loadObjectDetails();
        if (!this.iscreate) {
            this.loadSuccessCriteria();
            this.loadSelectedProducts();
            if(this.ispoc){
            this.checkDSRsAssociation();
            }
            this.createEditCSS = 'slds-col slds-size_4-of-12';
        }
        else {
            this.createEditCSS = 'slds-col slds-size_4-of-12';
        }
       

    }
    loadSuccessCriteria() {
        getSuccessCriteria()
            .then(result => {
                this.successcriteria = result;
            })
            .catch(error => {
                this.error = error;
                this.isloading = false;
            });
    }
    loadObjectDetails() {
        getParentObjDetails({ recId: this.parentrecid })
            .then(result => {
                let objdetails = JSON.parse(JSON.stringify(result));
                console.log('getParentObjDetails',objdetails);
                for (let key in result.ObjectRecordWrap){
                    this.parentObject=key;
                    if(key === 'Opportunity'){
                        let obj = result.ObjectRecordWrap[key];

                        this.opportunityid = obj.Id;
                        this.opportunity_name = obj.Name;
                        this.accountid = obj.AccountId;
                        this.account_name = obj.Account.Name;
                    
                        if (Object.prototype.hasOwnProperty.call(obj, "Partner_Involved__c") && !this.partneraccountid && this.iscreate) {
                            this.partneraccountid = obj.Partner_Involved__c;
                            this.partneraccountname = obj.Partner_Involved__r.Name;
                        }
                        
                        this.showisPoc=true;
                    }else if(key === 'Account'){
                        let obj = result.ObjectRecordWrap[key];

                        this.accountid = obj.Id;
                        this.account_name = obj.Name;
                        this.showisPoc=false;
                    }else if(key === 'Deal Support Request'){
                        let obj = result.ObjectRecordWrap[key];

                        this.opportunityid = obj.Opportunity__c;
                        this.opportunity_name = obj.Opportunity__r.Name;
                        this.accountid = obj.Account__c;
                        this.account_name = obj.Account__r.Name;
                        this.showisPoc=true;
                        this.DSRId = obj.Id;
                        console.log('DSR Id'+this.DSRId);
                        
                        //CHIME P2 changes
                        this.ispoc=true;
                        this.isEmergencyDisabled =true;
                        this.isWorkAtRiskDisabled = true;
                        this.opportunityDisabled =true;
                        this.DSRRequestType=obj.Request_Type__c;
                        this.DSRRecordType=obj.RecordType.DeveloperName;
                        if (Object.prototype.hasOwnProperty.call(obj, "Product__c")) {
                            this.DSRProduct = obj.Product__c;
                            //alert('Product:'+ this.DSRProduct);
                            getProductIdByName({ productName: this.DSRProduct })
                                .then(resultInner => {
                                    console.log('getProductIdByName::',resultInner);
                                    setTimeout(() => {
                                        this.template.querySelector('c-l2q_product_search').handleProductAddition(resultInner.Id);  
                                    }, 200);

                                })
                                .catch(error =>{
                                    console.log('error:',error);
                                })
                                
                        }
                    }
                    //hide the poc checkbox if form is not poc chime form.
                    if(!this.ispoc && !this.iscreate){
                        this.showisPoc = false;
                    }
                    if(this.showisPoc && !this.iscreate){
                        this.pocTypeDisabled = true;
                        this.isPOCDisabled = true;
                    }
                }
                //commented as part of P1 changes
                /*if (Object.prototype.hasOwnProperty.call(objdetails, "AccountId")) {
                    this.opportunityid = objdetails.Id;
                    this.opportunity_name = objdetails.Name;
                    this.accountid = objdetails.AccountId;
                    this.account_name = objdetails.Account.Name;
                }
                else {
                    this.accountid = objdetails.Id;
                    this.account_name = objdetails.Name;
                }*/
                this.whereclause = " and AccountId = '" + this.accountid + "'";
                this.isloading = false;
            })
            .catch(error => {
                this.error = error;
                this.isloading = false;
                if(JSON.stringify(error).includes('access')){  
                    const closeQA = new CustomEvent('close');
                    this.dispatchEvent(closeQA);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error!',
                            message: 'Sorry! You do not have access to CHIME.',
                            variant: 'error'
                        })
                    );
                }  
            });
    }
    loadSelectedProducts() {
        getSelectedProductList({ chimeId: this.chimeId })
            .then(result => {
                let selectedProds = JSON.parse(JSON.stringify(result));
                let selectedProdsFormatted = new Array();
                for(let product of selectedProds){
                    product.Id = product.CHIME_Product__c;
                    product.Product_Name__c = product.CHIME_Product__r.Product_Name__c;
                    product.Default_LOE_Standard__c = product.CHIME_Product__r.Default_LOE_Standard__c;
                    product.Default_LOE_Managed__c = product.CHIME_Product__r.Default_LOE_Managed__c;
                    product.Scope_of_work_Standard__c = product.CHIME_Product__r.Scope_of_work_Standard__c;
                    product.Scope_of_work_Managed__c = product.CHIME_Product__r.Scope_of_work_Managed__c; 
                    product.showScope = true;
                    if(this.isStandard){
                        if(product.Scope_of_work_Standard__c == null){
                            product.showScope = false;
                        }
                    }
                    else{
                        if(product.Scope_of_work_Managed__c == null){
                            product.showScope = false;
                        }
                    }   
                    selectedProdsFormatted.push(product);
                }
                this.selectedProducts = selectedProdsFormatted;
            })
            .catch(error => {
                this.error = error;
                this.isloading = false;
            });
    }
    createNewChime() {
        createChimeForm({ chimeId: this.chimeId, opportunityId: this.opportunityid, partneraccountId:this.partneraccountid, chimeName: this.chimeFormName, accountId: this.accountid, impType: this.implementatonType, isEmer: this.isEmergency, selectedProdIds: this.selectedProducts, isPOC : this.ispoc, pocType : this.pocTypeValue, isWorkAt: this.isWorkAtRisk})
            .then(result => {
                this.chimeId = result;
                //update Chime__C on DSR
                if(this.DSRId){
                    const fields = {};
                    fields[DSR_ID.fieldApiName] = this.DSRId;
                    fields[CHIME_FIELD.fieldApiName] = this.chimeId;
                    const recordInput = { fields };

                    updateRecord(recordInput)
                    .then(() => {
                        console.log('DSR Marked with CHIME.')
                    })
                    .catch(error => {
                            console.log("Error marked excluded : ",error.message);
                    })
                }
                //Set enterprise products flag
                
                //setEnterpriseProductFlagOnChime({chimeId : result})
                getEnterpriseProductsOnChime({ chimeId: this.chimeId, isUpdate: true })
                .then(result2 => {
                    console.log('result:setEnterpriseProductFlagOnChime',result2);
                })
                .catch(error => {
                    console.log('error:',error);
                })

                
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: this.chimeId,
                        objectApiName: 'CHIME__c',
                        actionName: 'view'
                    },
                });
                this.isloading = false;
            })
            .catch(error => {
                if (error.body) {
                    let message = error.body.message;
                    if (message.includes('DUPLICATE_VALUE')) {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Duplicate Error!',
                                message: 'CHIME Name should be unique.',
                                variant: 'error'
                            })
                        );
                    }
                }
                this.error = error;
                this.isloading = false;
            });
    }


    checkDSRsAssociation(){

        getAssociatedChimePOCDSRs({chimeId: this.chimeId})
        .then( result => {
            if(result && result.length >0 ){
                this.opportunityDisabled =true;
            }
        })
        .catch(error => {
            this.error = error;
            this.isloading = false;

        });


    }


    get options() {
            return [
                { label: 'Standard', value: 'Standard' },
                { label: 'Managed', value: 'Managed' },
            ];
        
    }
    handleSave() {
        this.isloading = true;
        if (this.selectedProducts.length === 0 && this.chimeId === '') {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error!',
                    message: 'Product is Mandatory.',
                    variant: 'error'
                })
            );
            this.isloading = false;
            return;
        }
        if (this.chimeFormName === '') {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error!',
                    message: 'CHIME Name is Mandatory.',
                    variant: 'error'
                })
            );
            this.isloading = false;
            return;
        }
        //Chime P2
        if(this.parentObject == 'Deal Support Request' && this.ispoc == false){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error!',
                    message: 'Only POC CHIME form can be created from DSR.',
                    variant: 'error'
                })
            );
            this.isloading = false;
            return;
        }
        if((this.parentObject == 'Deal Support Request' && this.DSRRecordType!='Pre_Sales_Engagement') ||(this.parentObject == 'Deal Support Request' && this.DSRRequestType!='POC')){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error!',
                    message: 'You cannot create a POC CHIME form for the selected request type.',
                    variant: 'error'
                })
            );
            this.isloading = false;
            return;
        }
        if(this.ispoc && (!this.opportunityid || !this.accountid)){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error!',
                    message: 'Account and Opportunity is mandatory if CHIME form is POC.',
                    variant: 'error'
                })
            );
            this.isloading = false;
            return;
        }
        if(this.ispoc && this.pocTypeValue ==='' ){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error!',
                    message: 'POC type needs to be selected if POC flag is checked.',
                    variant: 'error'
                })
            );
            this.isloading = false;
            return;
        }
        if(this.ispoc && this.pocTypeValue ==='Custom-POC' && this.implementatonType === ''){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error!',
                    message: 'Implementation type needs to be selected when POC type is Custom-POC.',
                    variant: 'error'
                })
            );
            this.isloading = false;
            return;
        }
        this.createNewChime();
    }
    handleIsEmergencyChange(event) {
        this.isEmergency = event.target.checked;
        if(this.isEmergency === true){
            this.isPOCDisabled = true;
        }
        else{
            this.isPOCDisabled = false;
        }
        
    }
    handleIsPOCChange(event) {
        this.ispoc = event.target.checked;
        if(this.ispoc == true){
            this.isEmergency =false;
            this.isWorkAtRisk = false
            //CHIME P2 change for poc types
            //this.showpoctypes=true;
        }
        if(this.ispoc === true){
        this.isEmergencyDisabled = true;
        this.isWorkAtRiskDisabled = true;
        }
        else{
            this.isEmergencyDisabled = false;
            this.isWorkAtRiskDisabled = false;
            //CHIME P2 change for poc types
            //this.showpoctypes=false;
            this.disableImplementationType = false;
        }
        this.pocTypeValue='';
    }
    handleImplementationTypeChange(event) {
        this.isStandard = (event.detail.value === 'Standard') ? true : false;
        this.implementatonType = event.detail.value;
    }
    handleChimeNameChange(event) {
        this.chimeFormName = event.detail.value;
    }
    handleCancel() {
        const closeQA = new CustomEvent('close');
        this.dispatchEvent(closeQA);
    }
    getOpportunityId(event) {
        let oppId = event.detail.recordId;
        this.opportunityid = oppId;
    }
    getPartnerAccountId(event) {
        let accId = event.detail.recordId;
        console.log('accId'+ accId);
        this.partneraccountid = accId;
        console.log('accId'+ this.partneraccountid);
    }
    handleProdSelection(event) {
        let selectedProds = this.selectedProducts;
        if (selectedProds.some(selectedProd => selectedProd.Id === event.detail.record.Id)) {
            if (event.detail.action === 'remove') {
                let index = selectedProds.findIndex(v => v.Id === event.detail.record.Id);
                selectedProds.splice(index, 1);
            }
        }
        else {
            if (event.detail.action === 'add') {
                let prod = event.detail.record;
                prod.showScope = true;
                if(this.isStandard){
                    if(prod.Scope_of_work_Standard__c == null){
                        prod.showScope = false;
                    }
                }
                else{
                    if(prod.Scope_of_work_Managed__c == null){
                        prod.showScope = false;
                    }
                } 
                selectedProds.push(prod);
            }
        }
        this.selectedProducts = selectedProds;
    }
    handleProductclick(event){
        this.scopeModalproductName = event.target.dataset.name;
        this.scopeModalText = event.target.dataset.scope;
        this.showScopePopUp = true;
    }
    handleCloseScope(){
        this.scopeModalproductName = '';
        this.scopeModalText = '';
        this.showScopePopUp = false;
    }

    //CHIME P2 changes
    get poctypeoptions() {
        return [
            { label: 'Standard-POC', value: 'Standard-POC' },
            { label: 'Custom-POC', value: 'Custom-POC' },
        ];
    }

    handlePOCTypeChange(event){
        this.pocTypeValue = event.detail.value;
        if(event.detail.value == 'Standard-POC'){
            this.isStandard = true;
            this.disableImplementationType = true;
            this.implementatonType='Standard';
        }else{
            this.disableImplementationType = false;
        }
    }

    handleisWorkAtRiskChange(event){
        this.isWorkAtRisk = event.target.checked;
        if(this.isWorkAtRisk === true){
            this.isPOCDisabled = true;
        }
        else{
            this.isPOCDisabled = false;
        }
    }

}