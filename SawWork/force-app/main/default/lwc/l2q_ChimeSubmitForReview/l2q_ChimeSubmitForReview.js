import { LightningElement,track,api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getProdData from '@salesforce/apex/L2Q_ChimeSubmitForReviewController.getProductData';
//import submitHandle from '@salesforce/apex/L2Q_ChimeSubmitForReviewController.submitProcess';
import submitHandle from '@salesforce/apex/L2Q_LOE_Utility.createUpdate_Review_IntegrationCase';
import sendEmailToReviewer from '@salesforce/apex/L2Q_ChimeSubmitForReviewController.sendSubsequentReviewEmail';
//const columns = [{ label: 'Product', fieldName: 'Label' ,type:'text'}];

export default class L2q_ChimeSubmitForReview extends LightningElement {
    @track priorityValue = '';
    @track reasonValue = '';
    @track priorityOptions = [{value: 'P1', label: 'P1 - SLA 24 hours'},
    {value: 'P2', label: 'P2 - SLA 48 hours'},
    {value: 'P3', label: 'P3 - SLA 72 hours'}];
    @track productsForReview = [];
    @track product = [];
    @track isEmergency = false;
    @track isWorkAtRisk = false;
    @track checked = true;
    @api recordId;
    @track showError;
    @track showSpinner = false;
    @track priorityDisabled = false;
    @track existingReviewCase = '';
    @track reviewerName = '';
    @track reviewerEmail = '';
    @track showUpdateMsg = false;
    
    
  
    connectedCallback(){

        
        getProdData({chimeRecordId:this.recordId})
             .then(result =>{
                 var i=0;
                 var returnResult = JSON.parse(result);
                 if(returnResult.chimeRec.LOE_Review_Status__c == 'Review Completed' || returnResult.chimeRec.Stage__c == 'Integration'){
                    this.showError = true;
                 }else{
                     this.showError = false;
                     this.isEmergency = returnResult.isEmergency;
                     this.isWorkAtRisk = returnResult.isWorkAtRisk;
                     this.product = returnResult.productList;
                     this.reviewerEmail = returnResult.reviewerEmail;
                     this.reviewerName = returnResult.reviewerName;
                     for(i=0;i<this.product.length;i++){
                         if(this.isWorkAtRisk || this.isEmergency || this.product[i].Review_Required__c || this.product[i].Human_Review__c){
                            this.product[i].mandatoryReview = true;
                            this.productsForReview.push(this.product[i].Id);
                         }else{
                            this.product[i].mandatoryReview = false;
                         }
                     }
                     if(returnResult.reveiwCaseId){
                         this.existingReviewCase = returnResult.reveiwCaseId;
                         this.showUpdateMsg = true;
                            if(returnResult.severity ==1 ){
                                this.priorityValue = 'P1';
                            }else if(returnResult.severity ==2 ){
                                this.priorityValue = 'P2';
                            }else if(returnResult.severity ==3 ){
                                this.priorityValue = 'P3';
                            }
                            this.priorityDisabled = true;
                        
                     }else{
                        this.priorityValue = 'P3';
                     }
                 }
                

                /* var prodOptionsList = [];
                    var selectedProducts = [];
                if(returnResult.productList.length > 0){
                    
                    var i =0;
                    for(i =0;i< returnResult.productList.length;i++){
                      

                        prodOptionsList.push({ Label: returnResult.productList[i].CHIME_Product__r.Product_Name__c, value: returnResult.productList[i].Id });
                        if(returnResult.isEmergency){
                            selectedProducts.push(returnResult.productList[i].Id);
                        }else{
                            if(returnResult.productList[i].Review_Required__c){
                                selectedProducts.push(returnResult.productList[i].Id);
                            }
                        }
                    }
                    this.productsForReview = prodOptionsList;
                    this.product = selectedProducts;
                }*/
                }).catch(error => {
                  console.log('error**'+error);
                });  
      
    }

    handleSelectedProductChange(event){
       
        if(event.target.checked == true){
            this.productsForReview.push(event.target.name);
        }else{
            this.productsForReview.pop(event.target.name);
        }
    }
    handleCancel(){
        const cancelEvent = new CustomEvent('cancel',{});
            this.dispatchEvent(cancelEvent);
    }
    handlePriorityChange(event){
        this.priorityValue = event.target.value;
    }

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

    handleCheckboxChange(){
        
    }

    handleReasonChange(event){
        this.reasonValue = event.target.value;
    }

    handleSubmit(){
       
       // alert(this.product);
       // alert('chime id**'+this.recordId);
      // alert(JSON.stringify(this.productsForReview));
       // submitHandle({productIds:this.product,priority : this.priorityValue,reason : this.reasonValue,chimeId :this.recordId})
       if(this.productsForReview.length == 0){
        this.showToast('Please select at least one product for review','Warning','dismissable');
       }else if(this.priorityValue == ''){
        this.showToast('Please select Priority','Warning','dismissable');
       }else{
           this.showSpinner = true;
        submitHandle({ chimeFormID: this.recordId,caseDescription:this.reasonValue,Case_Type:'Review_Case',priority:this.priorityValue,isAutoUpdate:false,selectedProducts : this.productsForReview})
             .then(result =>{
              
                 this.handleCancel();
                 if(this.existingReviewCase != ''){
                    this.showToast('Products are submitted for review successfully and '+result+' is updated','SUCCESS','dismissable');
                    sendEmailToReviewer({ reviewCase: this.existingReviewCase,caseOwnerEmail:this.reviewerEmail,caseOwnerName:this.reviewerName})
                    .then();
                 }else{
                    this.showToast('Products are submitted for review successfully and '+result+' is created','SUCCESS','dismissable');
                 }
                this.showSpinner = false;
                window.setTimeout(function(){ window.location.reload() }, 2000);
                
                }).catch(error => {
                    this.showSpinner = false;
                    console.log(JSON.stringify(error));
                  
                }); 
            }        

    }
}