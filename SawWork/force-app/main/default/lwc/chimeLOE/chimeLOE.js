import { LightningElement,track,api,wire} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getLOETabData from '@salesforce/apex/L2Q_ChimeFormLOETabController.getFeatureLOEData';
import updateLOEData from '@salesforce/apex/L2Q_ChimeFormLOETabController.updateFeatureLOEData';
import reviewCheck from '@salesforce/apex/L2Q_ChimeFormLOETabController.getReviewChecks';
import updateProductImplementation from '@salesforce/apex/L2Q_ChimeFormLOETabController.updateProductImplementationType';
import fetchOldImplementationType from '@salesforce/apex/L2Q_ChimeFormLOETabController.getProductImplementationType';
import updateManualFill from '@salesforce/apex/L2Q_ChimeFormLOETabController.updateManualLoE';
import createNewChimeFeature from '@salesforce/apex/L2Q_ChimeFormLOETabController.updateChimeFeatureLOEs';
import updateLOEOnProdRestore from '@salesforce/apex/L2Q_ChimeFormLOETabController.updateTotalLOEOnProd';
import userId from '@salesforce/user/Id';
import getLOEAdminsId from '@salesforce/apex/L2Q_LOE_Utility.getAdminsId';
import getChimeDetails from '@salesforce/apex/L2Q_ChimeFormLOETabController.getChimeStatus';
import { publish, subscribe, MessageContext } from 'lightning/messageService';
import STAGE_TRANSITION from '@salesforce/messageChannel/L2Q_ChimeStageTransition__c';
import LOE_MESSAGE from '@salesforce/messageChannel/l2q_LOERefresh__c';
//import Community_Customer_TechSquare from '@salesforce/resourceUrl/Community_Customer_TechSquare';

export default class ChimeLOE extends LightningElement {
    @api product;
    @api chimeid;
    @track featureList = [];
    @track featureListBackUp = [];
    @track showReviewers = false;
    @track searchKey;
    @track isChecked = false;
    @track mode;
    @track showSelectedModules = false;
    @track showTriggersForReview = false;
    @track searchKey = '';
    @track showConfirm = false;
    @track selectedModulesLOE  = 0;
    @track tpmLOE  = 0;
    @track techOverheadLOE  = 0;
    @track total  = 0;
    @track showFeatureDetails = false;
    @track selectedFeatureId ;
    @track featureDescription = '';
    @track featureScope = '';
    @track moduleName = '';
    @track productImplementationType = '';
    @track productImplementationTypeBackend = '';
    @track currentUserIsReviewer = false;
    @track lockScreen = false;
    @track disableFields = false;
    @track disableLOEManualFields = false;
    @track showReasonForFrozen = false;
    @track caseOwner = '';
    @track adminsId = [];
    @track disableUnitChanges = false;
    @track showSpinner = false;
    
    @track showLOETable = true;
    @track hideConfirm = false;
    @track autoRefresh = false;
    @track isRestore = false;
    @track columnClassHide = false;
    @wire(MessageContext) messageContext;
    @api readOnlyUser = false; 
    
    subscription = null;
   
    get productImplementationOptions() {
        return [
            { label: 'Standard', value: 'Standard' },
            { label: 'Managed', value: 'Managed' }
        ];
    }

    handleProductImplementationChange(event){
       
        this.productImplementationType = event.target.value;
    }

    handleProductImplementationUpdate(){
        updateProductImplementation({prodId:this.product,mode:this.productImplementationType})
             .then(result =>{
                let res = result;
                this.autoRefresh = true;
                this.connectedCallback();
                 this.productImplementationTypeBackend = this.productImplementationType;
                 const message = {
                    refresh: true,
                 
                };
                publish(this.messageContext, LOE_MESSAGE, message);
                
                
                this.showToast('Product Implementaion Type has been updated !!','success','dismissable');
                window.location.reload();

                }).catch(
                    error => {
                        this.error = error;
                        this.isloading = false;
                    }  
                ); 
    }

    handleSaveManualLoE(){
        updateManualFill({chimeProdAssociation:this.product,LoEVal:this.total})
        .then(result =>{
            let res = result;
            this.showToast('LoE value has been saved !!','success','dismissable');
           

           }).catch(
            error => {
                this.error = error;
                this.isloading = false;
            }    
           ); 
    }

    handleFeatureLinkClick(event){
        
        window.open('/'+event.target.title);

    }
  

    connectedCallback(){
        
        if(this.readOnlyUser){
            this.disableFields = true;
            this.hideConfirm = true;
            this.makeUnclickable();
        } 
        console.log('***'+this.product);
        this.showConfirm = false;
        this.revisedReviewCheck();
        this.loadLoETabTableData();
        this.getOldImplementationType();
        this.getChimeInfo();
        this.subscription = subscribe(
            this.messageContext,
            STAGE_TRANSITION,
            (message) => {
                this.handleIntegrationStageTransition(message);
            });
    } 

    handleIntegrationStageTransition(message){
        //this.stageScoping = false;
        //this.stageGating = false;
        //this.stageIntegration = true;
        console.log('messageInDetailPage:',message);
        if(message.readOnly== false){
            //making content clickable
            this.revisedReviewCheck();
            this.loadLoETabTableData();
            this.getOldImplementationType();
            this.getChimeInfo();
            this.disableFields = false;
            this.hideConfirm = false;
                 const divblock = this.template.querySelector('[data-id="loeDataTable"]');
                 if(divblock){
                     this.template.querySelector('[data-id="loeDataTable"]').className='slds-scrollable_y';
                 }
                 const divblock1 = this.template.querySelector('[data-id="loeDataTableActions"]');
                 if(divblock1){
                     this.template.querySelector('[data-id="loeDataTableActions"]').className='';
                 }

            
        }else{
            this.revisedReviewCheck();
            this.loadLoETabTableData();
            this.getOldImplementationType();
            this.getChimeInfo();
            
    
        }
    }

    makeUnclickable(){
       /* const divblock = this.template.querySelector('[data-id="loeDataTable"]');
        if(divblock){
            this.template.querySelector('[data-id="loeDataTable"]').className='slds-scrollable_y unclickable';
        }*/
        const divblock2 = this.template.querySelectorAll('td');
        if(divblock2){
          //  this.template.querySelector('[data-id="loeDataTableColumn"]').className='unclickable';
          //this.template.querySelectorAll('td').className='unclickable';
          this.columnClassHide = true;
        }
        const divblock1 = this.template.querySelector('[data-id="loeDataTableActions"]');
        if(divblock1){
            this.template.querySelector('[data-id="loeDataTableActions"]').className='unclickable';
        }
    }

    getChimeInfo(){
        getChimeDetails({productId:this.product})
        .then(result =>{
            if((result.CHIME__r.Status__c != 'Reopened' && result.CHIME__r.Stage__c == 'Integration') || result.CHIME__r.Stage__c == 'Closed'){
                this.disableFields = true;
                this.hideConfirm = true;
                this.makeUnclickable();
            }
           

           }).catch(
            error => {
                this.error = error;
                this.isloading = false;
            }    
           ); 
    }
    handleRestore(){
       
        this.showSpinner = true;
        this.featureList = [];
        this.featureListBackUp = [];
        
        
        createNewChimeFeature({prodId:this.product})
        .then(result =>{
            let res = result;
            updateLOEOnProdRestore({prodId:this.product})
            .then(resultLOERestore =>{  
                let res1 = resultLOERestore;
               // this.loadLoETabTableData();
               
               
               this.autoRefresh = true;
               this.isRestore = true;
               this.connectedCallback();
              
               this.showToast('Modules are restored to default.','success','dismissable');
           
               
               const message = {
                   refresh: true,
                
               };
               publish(this.messageContext, LOE_MESSAGE, message);
               
               
          //  this.mode = 'Baseline'; 
                this.showSpinner = false;
            })
            
           }).catch(error => {
            console.log('error**'+error);   
            this.showToast('Something went wrong.','error','dismissable');
            this.showSpinner = false;
           }); 
    }

    revisedReviewCheck(){
        
        reviewCheck({productId:this.product})
        .then(result =>{
            
            var returnResult = JSON.parse(result);
           // console.log('***'+JSON.stringify(returnResult));
           if(returnResult.reviewerName != null && returnResult.reviewerName != ''){
               this.caseOwner = returnResult.reviewerName;
           }
          

           if(returnResult.chimeReviewStatus == 'Being Reviewed' && userId == returnResult.reviewer && returnResult.productHumanReview && this.showLOETable){
            this.currentUserIsReviewer = true;
            }
            
            if(userId != returnResult.reviewer){
                this.disableLOEManualFields = true;
            }

            if(userId != returnResult.reviewer && returnResult.chimeReviewStatus =='Being Reviewed'){
                this.showReasonForFrozen = true;
            }

            getLOEAdminsId()
            .then(resultAdminsId => {
                this.adminsId = resultAdminsId;
                if(returnResult.chimeReviewStatus =='Being Reviewed' && (userId !=  returnResult.reviewer || (this.adminsId.length > 0 && !this.adminsId.includes(UserId) ))){
                    this.disableUnitChanges = true;
                }
               
            })
            .catch(error => {
                this.error = error;
                this.isloading = false;
            });

            if( returnResult.chimeReviewStatus =='Being Reviewed' && 
                (
                    (userId == returnResult.reviewer && 
                        (
                            (returnResult.productHumanReview == false) 
                        ) 
                    ) || this.currentUserIsReviewer ||
                    (userId != returnResult.reviewer)
                )
            ){
                this.lockScreen = true;
                this.disableFields = true;
                }

               
              

           /* if(this.lockScreen || this.currentUserIsReviewer){
                this.disableFields = true;
            }*/
          
           
            

           }).catch(error => {
             console.log('error**'+error);
           }); 
    }
    loadLoETabTableData(){
        getLOETabData({productId:this.product})
        .then(result =>{
            var returnResult = JSON.parse(result);
           
           // console.log('***'+JSON.stringify(returnResult));
           
           if(returnResult.chimeReviewStatus != 'Review Not Required' && userId == returnResult.reviewer && returnResult.productHumanReview){
                this.currentUserIsReviewer = true;
           }
           if(returnResult.chimeReviewStatus != 'Review Not Required' && !returnResult.productHumanReview){
            this.lockScreen = true;
            }

           
            this.featureList = returnResult;
            this.featureListBackUp = returnResult;
            
            
            if(returnResult.length > 0 && returnResult[0].feature !== null && returnResult[0].feature !== undefined){
               // this.showLOETable = true;
            this.mode = returnResult[0].feature.Chime_Product__r.LOE_Implementation_Mode__c ;
                
            
        
                fetchOldImplementationType({prodId:this.product})
                .then(result1 =>{
                   
                   this.productImplementationType = result1;
                   this.productImplementationTypeBackend = result1;
                   this.updateFinalLOEValues();
        
                   }).catch(); 
            
           
            }
            else
            { this.showLOETable = false;
                this.total = returnResult[0].productLoEVal;
            }    
            

           }).catch(error => {
             console.log('error**'+error);
           }); 
    }

    getOldImplementationType(){
        
        fetchOldImplementationType({prodId:this.product})
        .then(result =>{
           
           this.productImplementationType = result;
           this.productImplementationTypeBackend = result;
        

           }).catch(); 
    }

   
    handleDetailsShow(event){
        var features = this.featureListBackUp;
        var i;
        this.selectedFeatureId = event.target.name;
        this.showFeatureDetails = true;
        this.moduleName = event.target.value;
        
        for(i =0 ; i<features.length ; i++){
            if(this.selectedFeatureId == features[i].feature.Id){
                this.featureDescription = features[i].feature.Feature__r.Description__c;
                this.featureScope = features[i].feature.Feature__r.Scope_of_Work__c;
                break;
            }
        }
    }

    handleDetailsHide(){
        this.featureScope = '';
        this.featureDescription = '';
        this.selectedFeatureId = '';
        this.moduleName = '';
        this.showFeatureDetails = false;

    }

    // handling custom style on page rendering
   renderedCallback() {
       
    if(this.showLOETable){   
        const style = document.createElement('style');
        style.innerText = `c-chime-l-o-e .search .slds-input{
        fill: #F56243;
        border-radius:25px;
        }`;
        this.template.querySelector('lightning-input').appendChild(style);

        if(this.template.querySelector('lightning-combobox') != null){
            const dropdownstyle = document.createElement('style');
            dropdownstyle.innerText = `c-chime-l-o-e .dropdown .slds-combobox{
            margin-top:-20px;
            }`;
            this.template.querySelector('lightning-combobox').appendChild(dropdownstyle);
        }


        const noOfUnitsStyle = document.createElement('style');
        noOfUnitsStyle.innerText = `c-chime-l-o-e .noOfUnits .slds-input{
        width:80px;
        background-color:beige;
        }`;
        this.template.querySelector('lightning-input').appendChild(noOfUnitsStyle);

        const selectedStyle = document.createElement('style');
        selectedStyle.innerText = `c-chime-l-o-e .selected .slds-checkbox__label .slds-form-element__label{
        font-size: 15px;
        
        font-weight: 800;
        }`;
        this.template.querySelector('lightning-input').appendChild(selectedStyle);

        const triggerStyle = document.createElement('style');
        triggerStyle.innerText = `c-chime-l-o-e .trigger .slds-checkbox__label .slds-form-element__label{
        font-size: 15px;
    
        font-weight: 800;
        }`;
        this.template.querySelector('lightning-input').appendChild(triggerStyle);


        if(this.showConfirm){
            const confirmButtonStyle = document.createElement('style');
            confirmButtonStyle.innerText = `c-chime-l-o-e  .confirm .slds-button{
            width:140px;
            }`;
            this.template.querySelector('lightning-button').appendChild(confirmButtonStyle);
        }
    
        const warningBadgeClass = document.createElement('style');
        warningBadgeClass.innerText = `c-chime-l-o-e  .slds-theme_warning{
        background-color:darkgrey;
        }`;
        this.template.querySelector('div').appendChild(warningBadgeClass);
    }

   
    }

    showReviwersList(){
        this.showReviewers = true;
    }

    hideReviewersList(){
        this.showReviewers = false;
    }

    keycheck(event){
        if(event.which === 13){
            this.handleSearch(event);
        }
    } 

    //handlig search functionality on blur
    handleSearch(event){
        var searchString;
        var tempList = [];
        var featuresList = [];
        var i = 0;
        // At least 3 characters required for search
        if(event.target.value !== '' && event.target.value.length < 3){
            this.showToast('Please type at least 3 characters for search.','error','dismissable');
            return;
        }
    
        //search variable setting based on section
        this.searchKey = event.target.value;
         if(event.target.value === ''){
             this.featureList = this.featureListBackUp;
             this.showSelectedModules = false;
             this.showTriggersForReview = false;
         }else{
             this.searchKey = event.target.value;
            // var searchString = event.target.value.toLowerCase();
             searchString = event.target.value.toLowerCase();
            //  var tempList = [];
            //  var featuresList = [];
             
             featuresList = this.featureListBackUp;
             
             for(i=0;i<featuresList.length;i++){
             let tempRecord = Object.assign({}, featuresList[i]); 
             if(tempRecord.feature.Feature__r.Feature_Name__c.toLowerCase().includes(searchString)){
                 //if(tempRecord.Incident_ID.includes(this.searchKeyMyIncidentsSection) || tempRecord.Title.includes(this.searchKeyMyIncidentsSection) || tempRecord.Status.includes(this.searchKeyMyIncidentsSection) || tempRecord.Impact.includes(this.searchKeyMyIncidentsSection) || tempRecord.OwnerName.includes(this.searchKeyMyIncidentsSection) || tempRecord.Incident_Requested_By.includes(this.searchKeyMyIncidentsSection) || tempRecord.TIM.includes(this.searchKeyMyIncidentsSection)){
                     tempList.push(tempRecord); 
                 } 
             }
            this.featureList = tempList;
         }  
         const warningBadgeClass = document.createElement('style');
         warningBadgeClass.innerText = `c-chime-l-o-e  .slds-theme_warning{
         background-color:darkgrey;
         }`;
         this.template.querySelector('lightning-button-icon').appendChild(warningBadgeClass); 
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

handleSelection(event){
    var changedFeatureId;
    //var newValue;
    var i=0;
    if(this.mode != 'Custom')
    this.mode = 'Custom';
    changedFeatureId = event.target.name;
    //newValue = event.target.checked;
    
    for(i=0;i<this.featureListBackUp.length;i++){
        if(changedFeatureId == this.featureListBackUp[i].feature.Id){
            this.featureListBackUp[i].feature.Is_Selected__c = event.target.checked;
            this.featureListBackUp[i].feature.Units__c = 1;
            this.featureListBackUp[i].feature.LoE__c = this.featureListBackUp[i].feature.Parent_Feature_First_Unit_LoE__c;
            break;
        }

    }
    for(i=0;i<this.featureList.length;i++){
        if(changedFeatureId == this.featureList[i].feature.Id){
            this.featureList[i].feature.Is_Selected__c  = event.target.checked;
            this.featureList[i].feature.Units__c = 1;
            this.featureList[i].feature.LoE__c = this.featureList[i].feature.Parent_Feature_First_Unit_LoE__c;
            break;
        }

    }
    this.updateFinalLOEValues();
    this.showConfirm = true;

}
handleUnitsChange(event){
    var changedFeatureId;
    var newValue;
    var i=0;
    if(event.target.value.includes('-')){
        event.target.value = '';
        this.showToast('Negative values are not allowed.','success','dismissable');
        return;
    }else if(event.target.value.includes('.')){
        event.target.value = '';
        this.showToast('Decimal values are not allowed.','success','dismissable');
        return;
    }
    if(this.mode != 'Custom')
    this.mode = 'Custom';
    changedFeatureId = event.target.name;
    newValue = event.target.value;
    
   
   
    for(i=0;i<this.featureListBackUp.length;i++){
        if(changedFeatureId == this.featureListBackUp[i].feature.Id){
           
            this.featureListBackUp[i].feature.Units__c = event.target.value;
           
            break;
        }

    }
    for(i=0;i<this.featureList.length;i++){
        if(changedFeatureId == this.featureList[i].feature.Id){
            this.featureList[i].feature.Units__c = event.target.value;
            break;
        }

    }

    this.updateFeatureLOE(changedFeatureId,newValue);
    this.showConfirm = true;


}

handleLoEValueChange(event){
    var changedFeatureId = event.target.name;
    var newValue = event.target.value;
    var i=0;
    var j=0;
    //ESESP-6189 start
    if(event.target.value.includes('-')){
        event.target.value = '';
        this.showToast('Negative values are not allowed.','success','dismissable');
        return;
    }else if(event.target.value.includes('.')){
        event.target.value = '';
        this.showToast('Decimal values are not allowed.','success','dismissable');
        return;
    }
    //ESESP-6189 end
    for(i=0;i<this.featureListBackUp.length;i++){
        if(changedFeatureId == this.featureListBackUp[i].feature.Id){
        
            this.featureListBackUp[i].feature.LoE__c = newValue;
        
            break;
        }

    }

    for(j=0;j<this.featureList.length;j++){
        if(changedFeatureId == this.featureList[j].feature.Id){
            this.featureList[j].feature.LoE__c = newValue;
            break;
        }

    }
    this.showConfirm = true;
    this.updateFinalLOEValues();

}

updateFeatureLOE(changedFeatureId,newValue){
    var i=0;
    if(newValue != ''){
        
        for(i=0;i<this.featureListBackUp.length;i++){
            if(changedFeatureId == this.featureListBackUp[i].feature.Id){
            
                this.featureListBackUp[i].feature.LoE__c = this.featureListBackUp[i].feature.Parent_Feature_First_Unit_LoE__c + (newValue-1)*(this.featureListBackUp[i].feature.Parent_Feature_Additional_Unit_LoE__c);
            
                break;
            }

        }

        for(i=0;i<this.featureList.length;i++){
            if(changedFeatureId == this.featureList[i].feature.Id){
                this.featureList[i].feature.LoE__c = this.featureList[i].feature.Parent_Feature_First_Unit_LoE__c + (newValue-1)*(this.featureList[i].feature.Parent_Feature_Additional_Unit_LoE__c);
                break;
            }

        }
        this.updateFinalLOEValues();
    }
    

}

updateFinalLOEValues(){
    var paramToPass;
    var i=0;
    var calculatedTPM;
    this.selectedModulesLOE = 0;
    this.techOverheadLOE = 0;
    this.tpmLOE = 0;
    this.total = 0;
    
    
    for(i=0;i<this.featureListBackUp.length;i++){
        if(this.featureListBackUp[i].feature.Is_Selected__c){
            this.selectedModulesLOE = this.selectedModulesLOE + parseFloat(this.featureListBackUp[i].feature.LoE__c);
        }
    }
    
    if(this.featureListBackUp[0].feature.Feature__r.Product__r.Tech_Overhead_Exempt__c){
        this.techOverheadLOE = 0;
    }else{
        this.techOverheadLOE = this.featureListBackUp[0].feature.Feature__r.Product__r.Technical_Overhead__c;
    }
    
    if(this.productImplementationTypeBackend == 'Managed'){
        calculatedTPM = (((this.selectedModulesLOE) * (this.featureListBackUp[0].feature.Feature__r.Product__r.Percentage_TPM_hours_in__c)) / 100);
        if(calculatedTPM < this.featureListBackUp[0].feature.Feature__r.Product__r.Minimum_TPM__c){
            this.tpmLOE = this.featureListBackUp[0].feature.Feature__r.Product__r.Minimum_TPM__c;
        }else{
            this.tpmLOE = calculatedTPM;
        }
    }

    this.total = this.selectedModulesLOE + this.techOverheadLOE;
    if(this.productImplementationTypeBackend == 'Managed'){
        this.total  = this.total + this.tpmLOE;
    }

    if(this.autoRefresh){
        paramToPass= {prod:this.product, loe:this.total};

        const selectEvent = new CustomEvent('refreshproduct', {
            detail: paramToPass
           
        });
        this.dispatchEvent(selectEvent);
        this.autoRefresh = false;
    }

    if(this.isRestore){
        this.mode = 'Baseline';
        this.isRestore = false;
    }

    
}

handleShowSelectedModules(event){
    var i=0;
    var selectedFeatures = [];
    var reviewRequiredFeatures = [];
    var j=0;
    this.showSelectedModules = event.target.checked;
    if(event.target.checked){
        
        for(i=0;i<this.featureList.length;i++){
            if(this.featureList[i].feature.Is_Selected__c ){
                selectedFeatures.push(this.featureList[i]);
            }
        }
        this.featureList = selectedFeatures;
    }else{
        this.searchKey = '';
        if(this.showTriggersForReview ){
            
            for(j=0;j<this.featureListBackUp.length;j++){
                if(this.featureListBackUp[j].feature.Feature__r.Review_Required__c){
                    reviewRequiredFeatures.push(this.featureListBackUp[j]);
                }
            }
            this.featureList = reviewRequiredFeatures;
        }else{
        this.featureList = this.featureListBackUp;
        }
    }
}

handleShowTriggersForReview(event){
    var reviewRequiredFeatures = [];
    var i=0;
    var j=0;
    var selectedFeatures = [];
    this.showTriggersForReview = event.target.checked;
    if(event.target.checked){
        //var i=0;
        
        for(i=0;i<this.featureList.length;i++){
            if(this.featureList[i].feature.Feature__r.Review_Required__c){
                reviewRequiredFeatures.push(this.featureList[i]);
            }
        }
        this.featureList = reviewRequiredFeatures;
    }else{
        this.searchKey = '';
        if(this.showSelectedModules){
            
            
            for(j=0;j<this.featureListBackUp.length;j++){
                if(this.featureListBackUp[j].feature.Is_Selected__c ){
                    selectedFeatures.push(this.featureListBackUp[j]);
                }
            }
            this.featureList = selectedFeatures;
        }else{
        this.featureList = this.featureListBackUp;
        }
    }
}

handleManualLoEChange(event){
    this.total = event.target.value;
}




handleSave(){
    var i=0;
    var selectedFeatures = 0;
    this.showSpinner = true;
    
    for(i=0;i< this.featureListBackUp.length;i++){
        if(this.featureListBackUp[i].feature.Is_Selected__c ){
            selectedFeatures = selectedFeatures +1;
        }
        if(this.featureListBackUp[i].feature.Is_Selected__c && (this.featureListBackUp[i].feature.LoE__c == 0 || this.featureListBackUp[i].feature.LoE__c == '' || this.featureListBackUp[i].feature.LoE__c == null) ){
            this.showToast('Selected Modules can not have 0 LOE hours.','error','dismissable');
            this.showSpinner = false;
            return;
        }
       
        if(this.featureListBackUp[i].feature.Is_Selected__c && (this.featureListBackUp[i].feature.Units__c == 0 || this.featureListBackUp[i].feature.Units__c == '' || this.featureListBackUp[i].feature.Units__c == null || this.featureListBackUp[i].feature.Units__c.toString().includes('-')) ){
        
            this.showToast('Selected Modules should have valid units.','error','dismissable');
            this.showSpinner = false;
            return;
        }
    }
    if(selectedFeatures == 0){
        this.showToast('At least 1 module should be selected.','error','dismissable');
        this.showSpinner = false;
        return;
    }
    
    updateLOEData({featureLOEData: JSON.stringify(this.featureListBackUp),loeImplementationMode:this.mode,totalLoE:this.total})
    .then(result =>{
        let res = result;
        var paramToPass;
        const message = {
            refresh: true,
         
        };
        publish(this.messageContext, LOE_MESSAGE, message);
        paramToPass= {prod:this.product, loe:this.total};

        const selectEvent = new CustomEvent('refreshproduct', {
            detail: paramToPass
           
        });
        this.dispatchEvent(selectEvent);

        this.showToast('LOE data has been updated successfully.','success','dismissable');
        this.showSpinner = false;
       }).catch(error => {
        console.log('error**'+error);   
        this.showToast('Something went wrong.','error','dismissable');
        this.showSpinner = false;
       });  
}

get baseLineClass(){
    var returnClassName = '';
    if(this.mode == 'Baseline'){
        returnClassName = "slds-p-horizontal_large slds-p-vertical_small slds-theme_success";
    }else if(this.mode == 'Custom'){
        returnClassName =  "slds-p-horizontal_large slds-p-vertical_small slds-theme_warning";
    }
    return returnClassName;
}

get customClass(){
    var returnClassName = '';
    if(this.mode === 'Baseline'){
        returnClassName = "slds-p-horizontal_large slds-p-vertical_small slds-theme_warning";
    }else if(this.mode === 'Custom'){
        returnClassName =  "slds-p-horizontal_large slds-p-vertical_small slds-theme_success";
    }
    return returnClassName;
    
}

get modulesCheckboxLabel(){
    var label = 'Show Selected Modules';
    if(this.showSelectedModules){
       label = label + ' ('+this.featureList.length+')'; 
    }
    return label;
    
}

get reviewCheckboxLabel(){
    var label = 'Show Triggers for Review';
    if(this.showTriggersForReview){
        label = label + ' ('+this.featureList.length+')'; 
     }
    return label;
    
}


     

       
    
                 

}