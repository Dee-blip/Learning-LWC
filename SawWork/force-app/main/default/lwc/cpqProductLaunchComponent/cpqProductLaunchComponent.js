import { LightningElement, api, wire,track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation'; // for navigation
import { refreshApex } from '@salesforce/apex'; // for refresh
import { ShowToastEvent } from 'lightning/platformShowToastEvent'; // show toast notification
import verifyMarktetingProductId from '@salesforce/apex/CPQ_PM_ApiCalllout.verifyMarktetingProductId'; // verify the valid marketing Ids
import search from '@salesforce/apex/CPQ_Product_Search_Controller.search'; // search the product code and return result
import getProdLaunchList from '@salesforce/apex/CPQ_Product_Launch_Controller.getProdLaunchList'; // call to CPQ launch Management
import launchSelectedProduct from '@salesforce/apex/CPQ_Product_Launch_Controller.launchSelectedProduct'; // launch the products
import unlinkPlm from '@salesforce/apex/CPQ_Product_Launch_Controller.unlinkPlm';

const columns = [
{
label:'Product',fieldName:'Product_Name__c',type:'text',hideDefaultActions: "true",typeAttributes: { name: "productCode", variant: "base" }
},
{
type: "button-icon",initialWidth:20,alternativeText:'View Product', typeAttributes: {
iconName:"action:more" ,
alternativeText:'View Product',
name: 'productCode',
disabled: { fieldName: 'productValidation__c'},
value: 'view',
iconPosition: 'left'
}
},
{
label:'Creation Status',fieldName:'Product_Creation_Status__c',type:'text'
},
{
label:'Version',fieldName:'Version__c',type:'text'
},
{
label:'Reviewed ? ',fieldName:'Product__r_CPQ_Reviewed__c',type:'boolean'
},
{
label :'Product Parent Version', fieldName:'Product_previous_version__r_Name',type: "button",typeAttributes: { label: { fieldName: "Product_previous_version__r_Name" }, name: "productOldCode", variant: "base" }
},
{
label:'Launch status',fieldName:'Product_Launch_Status__c'
},
];

export default class cpqProductLaunchComponent extends NavigationMixin (LightningElement) {
@track state={
selectedRecords :[],
selectedRecordreviewStatus :[],
validplms :[],
launchedplms:[],
isMultiEntry : true,
errors:[],
error:[],
buttonTrue:true,
isModalOpen : false,
selectedids :[],
validateproducts :{
    "validity": false
},
validatedproducts :[],
showPop :false,
inValidProducts :[],
data:[],
showLaunchresults : false,
showNoLaunchresults : false,
showGuide : true,
obj:{
    productId :'',
    productName :'',
    
},
productInfo:[],
prodlist:[],
buttonLabel : 'OK',
selectedLaunch :'',
productType :'',
value :''
}

columns = columns; //
@api notifyViaAlerts = false;
@api releaseId;
@api releaseName;
@api productOfType;
newRecordOptions = [
{ value: 'CPQ_ProductLaunchSetting__c', label: 'New Product' }

];

get options() {
    return [
        { label: 'Carrier', value: 'Carrier' },
        { label: 'Partner', value: 'Partner' },
    ];
}

connectedCallback() {
    this.state.selectedLaunch = this.releaseId;
    this.state.value = this.productOfType;
    if(this.state.selectedLaunch !== undefined) {
        this.state.showGuide = false;
    }
}
// On selection of launch wire  method is called and provide details for launch management
@wire(getProdLaunchList, { launchId:'$state.selectedLaunch' , typeOfProduct:'$state.value'})
wiredGetProdLaunchList(value) {
this.wiredProdLaunchList = value;
const { data, error } = value;
if (data) {
    this.state.data = data;
    this.state.error = undefined;
    this.state.data = data.map(record => ({ ...record,
        Product__r_Name:record.Product__c == null? "":record.Product__r.Name,
        Product__r_CPQ_Reviewed__c:record.Product__c== null ? "":record.Product__r.CPQ_Reviewed__c,
        Product_previous_version__r_Name:record.Product_previous_version__c == null ? "":record.Product_previous_version__r.Name
    }));
    this.state.prodlist = this.state.data;
    this.state.selectedRecords =[];
    if(this.state.prodlist.length>0){
        this.state.showLaunchresults = true;
        this.state.showNoLaunchresults = false;
    }
    else{
        this.state.showNoLaunchresults = true;
        this.state.showLaunchresults = false;
    }
        
} else if (error) {
    this.state.error = error;
    this.state.data = undefined;
}  
}
handleLookupSearch(event) {

 const lookupElement = event.target;
// Call Apex endpoint to search for records and pass results to the lookup
search(event.detail)
    .then((results) => {
        lookupElement.setSearchResults(results);
    })
    .catch((error) => {
        this.notifyUser('Lookup Error', 'An error occured while searching with the lookup field.', 'error');
        
        console.error('Lookup error', JSON.stringify(error));
        this.state.errors = [error];
    });
}
handleLookupSelectionChange(event) {

this.state.selectedids = event.detail;
this.state.buttonTrue = false;
this.state.showPop = false;
this.state.validatedproducts =[];
this.checkForErrors();   
}

handleSubmit() {
this.checkForErrors();
if (this.state.errors.length === 0) {
    this.notifyUser('Success', 'The form was submitted.', 'success');
}
}

handleClear() {
const selection = this.template.querySelector('c-cpq-product-search-component').getClearSelection();
console.log('selection'+ selection);
const searchTerm = this.template.querySelector('c-cpq-product-search-component').getClearSearchTerm();
console.log('searchTerm '+ searchTerm);
//this.selection =[];
this.state.selectedids = [];
this.state.validateproducts ={
    "validity": false
};
this.state.validatedproducts =[];
this.state.showPop = false;
this.state.buttonTrue = true;
this.state.buttonLabel ='OK';
this.state.errors = [];
 
}
handlePillRemoval(){
    this.state.buttonLabel ='OK';  
}

checkForErrors() {
this.state.errors = [];
const selection = this.template.querySelector('c-cpq-product-search-component').getSelection();
// Custom validation rule
// Enforcing required field
if (selection.length === 0) {
    this.state.errors.push({ message: 'Please make a selection.' });
}
}

notifyUser(title, message, variant) {

    // Notify via toast (only works in LEX)
    const toastEvent = new ShowToastEvent({ title, message, variant });
    this.dispatchEvent(toastEvent);

}
openModal(event){
this.state.productType = event.target.name;
this.state.isModalOpen = true;
this.state.value = event.target.name;
}

handleRadioChange(event) {
    this.state.value = event.detail.value;
}

// to close modal set isModalOpen track value as false
closeModal(){

this.state.isModalOpen = false;
//this.selection =[];
this.state.selectedids = [];
this.state.showPop = false;
this.state.buttonTrue = true;
this.state.errors = [];

}
submitDetails(){

    if(this.state.selectedids.length >0){
        this.state.buttonTrue = false;
        console.log('Start Validation');
            this.state.buttonLabel ='Processing' 
            verifyMarktetingProductId({productId : this.state.selectedids })
        
        .then((result)=>{
            this.state.validateproducts = result;
            if(this.state.validateproducts.validity){
                const validatedMarketingId = JSON.parse(this.state.validateproducts.productsInfo);
                let validatedMarketingIds = validatedMarketingId.products;
                if(validatedMarketingIds.length >0 ){
                    for(let key in validatedMarketingIds){
                        if(key){
                    // added to handle name
                    this.state.obj = {productId:validatedMarketingIds[key].marketingProductId,productName:validatedMarketingIds[key].productName};
                    this.state.productInfo.push(this.state.obj);
                    
                     // end handle name
                    if(!this.state.validatedproducts.includes(validatedMarketingIds[key].marketingProductId)){
                    this.state.validatedproducts.push(validatedMarketingIds[key].marketingProductId);
    
}
                        }
                        
                        
                    }
                    console.log('Product Info'+JSON.stringify(this.state.productInfo));
                    console.log('validated products '+ this.state.validatedproducts);
                    this.state.inValidProducts = this.state.selectedids.filter(e=>!this.state.validatedproducts.includes(e));
                    console.log('inValid Products '+this.state.inValidProducts);
                    if(this.state.inValidProducts.length>0){
                        this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message:'Invalid Marketing Ids :- ' +this.state.inValidProducts,
                            variant: 'error',
                            mode: 'sticky'
                        }),
                    );  
                    }
                    else{
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message:'Product fetched Successfully :- ' +this.state.validatedproducts,
                                variant: 'success'
                            }),
                        );
                        let compDefinition = {
                            componentDef: "c:cpqProductSetupComponent",
                            attributes: {
                                productIdsList: this.state.validatedproducts,
                                productInfo : this.state.productInfo,
                                productType : this.state.productType
                            }
                        };
                            let encodedCompDef = btoa(JSON.stringify(compDefinition));
                            this[NavigationMixin.Navigate]({
                                type: 'standard__webPage',
                                attributes: {
                                    url: '/one/one.app#' + encodedCompDef
                                }
                            });
                        }   
                }
                else{
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message:'Invalid Marketing Product Id' ,
                            variant: 'error'
                        }),
                    );
                }
            }
            else {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error - '+this.state.validateproducts.errorResponse.status,
                        message:this.state.validateproducts.errorResponse.detail ,
                        variant: 'error'
                    }),
                );
                this.state.validatedproducts =[];
                this.state.showPop = false;
                this.state.buttonTrue = true;
                this.state.buttonLabel ='OK';
                

            }
            
        })
        .catch((error)=>{
            console.log('error: ', error);
            this.state.errors = error;
        });
    }
    else{
        this.state.buttonTrue = true;
    }
    }

handleSelection(event)
{
this.state.showGuide = false;
this.state.selectedLaunch = event.detail.selectedId;
if(!this.state.value) {
    this.state.value = 'Carrier';
}
window.console.log('selectedLaunch ====> ' + this.state.selectedLaunch);
if(this.releaseId && this.state.prodlist.length>0 )
{
this.state.showLaunchresults = true;
}
}
// This method is called first
handleloadresults(){
window.console.log('release id ====> ' + this.releaseId);
this.state.showNoLaunchresults = false;
return refreshApex(this.wiredProdLaunchList);           
}

handleRemoveresults(){
this.state.showLaunchresults = false;
this.state.prodlist =[]; // to change the release id and handle wire
this.state.selectedLaunch ='';
this.state.showNoLaunchresults = false;
this.state.showGuide = true;
}

handleRowAction(event) {
const id = event.detail.row.Product__c;
console.log('id '+id);
if (event.detail.action.name === "productCode") {
this[NavigationMixin.GenerateUrl]({
    type: "standard__recordPage",
    attributes: {
        recordId: event.detail.row.Product__c,
        actionName: "view"
    }
}).then((url) => {
    window.open(url, "_blank");
});
}
if (event.detail.action.name === "productOldCode") {
this[NavigationMixin.GenerateUrl]({
    type: "standard__recordPage",
    attributes: {
        recordId: event.detail.row.Product_previous_version__c,
        actionName: "view"
    }
}).then((url) => {
    window.open(url, "_blank");
});
}
}
handleLaunch(){
if(this.state.selectedRecords.length>0){
if(this.state.selectedRecordreviewStatus.includes(false)||(this.state.validplms.includes('Failure')||this.state.validplms.includes('Partial Success')||this.state.validplms.includes('In Progress'))){
    this.dispatchEvent(
        new ShowToastEvent({
            title: 'Warning',
            message: 'Only reviewed products and products with success creation status can be launched',
            variant: 'error'
        }),
    );
    // Clearing selected row indexes 
    this.template.querySelector('lightning-datatable').selectedRows = [];
    this.state.selectedRecords=[];
}
else{
    if(this.state.launchedplms.includes('Activated')){
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: 'Selected product is already launched. Kindly check the launch status ',
                variant: 'error'
            }),
        );
        // Clearing selected row indexs 
        this.template.querySelector('lightning-datatable').selectedRows = []; 
    
}
else{
    launchSelectedProduct({ launchManagementIds: this.state.selectedRecords })
        .then(result => {
            window.console.log('result ====> ' + result);
            // showing success message
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success!!',
                    message: ' Launch successfull',
                    variant: 'success'
                }),
            );

            // Clearing selected row indexes 
            this.template.querySelector('lightning-datatable').selectedRows = [];
            this.state.selectedRecords=[];
            // refreshing table data using refresh apex
            return refreshApex(this.wiredProdLaunchList);
        })
        .catch(error => {
            window.console.log(error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error during Launch',
                    message: error.message,
                    variant: 'error'
                }),
            );
        }); 
    }
}
}
else{
this.dispatchEvent(
    new ShowToastEvent({
        title: 'Select a valid product to Launch ',
        variant: 'error'
    }),
);
// Clearing selected row indexes 
    this.template.querySelector('lightning-datatable').selectedRows = [];

}    
}
handleDelete(){
    unlinkPlm({ plmIds: this.state.selectedRecords })
    .then(result => {
        window.console.log('result ====> ' + result);
       
    

        // showing success message
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success!!',
                message: ' Products are deleted.',
                variant: 'success'
            }),
        );

        // Clearing selected row indexs 
        this.template.querySelector('lightning-datatable').selectedRows = [];

        // refreshing table data using refresh apex
        return refreshApex(this.wiredProdLaunchList);   

    })
    .catch(error => {
        window.console.log(error);
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error while deletion',
                message: error.message,
                variant: 'error'
            }),
        );
    });
}
getSelectedRecords(event) {
// getting selected rows
const selectedRows = event.detail.selectedRows;
window.console.log('event.detail ====> ' + JSON.stringify(event.detail));
// this set elements the duplicates if any
let recIds = new Set();
let recReviewStatus =[];
let validplms=[];
let launchedplms =[];
// getting selected record id

    for (let i = 0; i < selectedRows.length; i++) {
        recIds.add(selectedRows[i].Id);
        recReviewStatus.push(selectedRows[i].Product__c==null?false:selectedRows[i].Product__r.CPQ_Reviewed__c);
        validplms.push(selectedRows[i].Product_Creation_Status__c);
        launchedplms.push(selectedRows[i].Product_Launch_Status__c);
    }
    // coverting to array
    this.state.selectedRecords = Array.from(recIds);
    this.state.selectedRecordreviewStatus = recReviewStatus;
    this.state.validplms = validplms;
    this.state.launchedplms = launchedplms;

}

// Handle Refresh
handleRefresh(){

return refreshApex(this.wiredProdLaunchList);

}

get dynamicSize(){
    if(this.state.prodlist.length > 10){
        return 'dynamic';
    }
    return '';
}

onCloseButtonClick(){
    this.state.showGuide = false;
}

}