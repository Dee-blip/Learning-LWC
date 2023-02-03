import { LightningElement,api,track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import fetchSectionDetails from '@salesforce/apex/CPQ_Product_Search_Controller.fetchSectionDetails';
import consumeSectionInfo from '@salesforce/apex/CPQ_PM_ApiCalllout.consumeSectionInfo';
import createProductSettings from '@salesforce/apex/CPQ_Product_Search_Controller.createProductSettings';

const sectionColumns = [
{
label: 'Ranking', fieldName: 'ranking', type: 'number', sortable: true
},
{
label: 'Section Name', fieldName: 'name', type: 'text', sortable: true
}
];

export default class CpqProductSetupComponent extends NavigationMixin (LightningElement) {
@track state={
createButtonDisable:false,
label: 'Create Product',
releaseId :'',
releaseName:'',
billInfo :'',
billingModelValue :[],
allSectionInfo :[],
prodDetails:'',
preSelectedRows: [],
sectionDetails:'',
sectionData:[],
selectedSectionId:'',
error:'',
selectedIds:[],
showUsageAndBillingDetails:false,
removeRequired:false,
obj:{
productId :'',
billingModels :'',
usage :'',
name :'',
fetchSection:'',
}
}
//@api productIdsList =['M-LC-84827','M-LC-107281','M-LC-162043'];
//@api productInfo=[{'M-LC-84827':'Ion','M-LC-107281':'GTM','M-LC-162043':'WAP'}]
@api productIdsList;
@api productInfo;
@api productType;
@track sectionColumns = sectionColumns;

get billingModelOptions() {
return [
{ label: 'Usage Commitment', value: 'Usage Commitment' },
{ label: 'Straight Line Commitment', value: 'Straight Line Commitment' },    
];
}
get selectedBillingModelValues() {
return this.state.billInfo.join(',');
}

connectedCallback() {
    if(this.productType ==='Partner'){
        this.state.showUsageAndBillingDetails = true;
        this.state.removeRequired = true; 
     }
this.consumeSectionInfo();



}
consumeSectionInfo(){
    consumeSectionInfo({
        productIds: this.productIdsList
        })
        .then(result => {
            this.state.fetchSection = result;
            console.log(typeof this.state.fetchSection, ' :fetchSection: ', JSON.stringify(this.state.fetchSection)) 
            this.loadSectionDetails();  
        })
        .catch(error => {
            console.log('Error' + error);
            this.state.error = error; 
            
        })        
}
loadSectionDetails() {
fetchSectionDetails({
productIds: this.productIdsList,
sectionData : this.state.fetchSection
})
.then(result => {
    this.state.sectionDetails = result;
    console.log(typeof this.state.sectionDetails, ' :sectionDetails: ', this.state.sectionDetails)
    if(this.state.sectionDetails){
        for(let key in this.state.sectionDetails )
        {
            if(key){
                let productName = this.productInfo.filter(obj => obj.productId === key).map(obj => obj.productName)
                let productNameSet = [...new Set(productName)];
                let filter = JSON.parse(this.state.sectionDetails[key].sectionData);
    for(let f=0;f<filter.length;f++)
                    {
    filter[f].key=key; 
                    }
            this.state.sectionData.push({value:filter.filter(function (section){return section.name !== 'End of sale' && section.name.toLowerCase().indexOf('netstorage') === -1;}),
            key:key,productName:productNameSet,available:this.state.sectionDetails[key].available?this.state.sectionDetails[key].available:'',preselect:this.state.sectionDetails[key].preSelected?this.state.sectionDetails[key].preSelected:[0],
            billingModelValue:this.state.sectionDetails[key].billingInfo?this.state.sectionDetails[key].billingInfo:'',});
            
            this.state.obj={productId :key,billingModels : this.state.sectionDetails[key].billingInfo,usage:parseInt(this.state.sectionDetails[key].preSelected, 10),name:productNameSet.toString()};
            this.state.allSectionInfo.push(this.state.obj);
                        
        }
            }
            console.log(' allSectionInfo'+JSON.stringify(this.state.allSectionInfo));
        
    }
        
})
.catch(error => {
    console.log('Error' + error);
    this.state.error = error; 
    
})        
}
handleBillingModelChange(event) {

this.state.billInfo = event.detail.value; 
let key = event.target.name;
const index = this.state.allSectionInfo.findIndex((e) => e.productId === key); 
this.state.allSectionInfo[index].billingModels = this.state.billInfo;
this.state.allSectionInfo[index].billingModels = this.state.allSectionInfo[index].billingModels.toString();
console.log(' allSectionInfo after selection billing'+JSON.stringify(this.state.allSectionInfo));  
}

handleSelection(event){
this.state.releaseId = event.detail.selectedId;
this.state.releaseName = event.detail.selectedName;
}

getSelectedSectionId(event) {
const selectedRows = event.detail.selectedRows;
console.log('selectedRows', selectedRows);

//since we have limited the selection to 1 
this.state.selectedSectionId = selectedRows[0].id;

let key = selectedRows[0].key;
const index = this.state.allSectionInfo.findIndex((e) => e.productId === key); 
this.state.allSectionInfo[index].usage = this.state.selectedSectionId
console.log(' allSectionInfo after selection usage'+JSON.stringify(this.state.allSectionInfo));

}
handleCreateProduct(){

if(this.state.releaseId){
    let selectedUsage = this.state.allSectionInfo.map(a => a.usage);
        if(selectedUsage.includes(NaN) && this.productType==='Partner'){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Validation',
                    message: 'Please select an option in the usage section',
                    variant: 'error'
                }),
            ); 
        }
        else{
            console.log('Coming in create product');
            this.state.createButtonDisable = true;
            this.state.label='Creation in process';
            createProductSettings({
                    releaseId :this.state.releaseId,
                    productSettings : JSON.stringify(this.state.allSectionInfo),
                    typeOfProduct : this.productType
                    })
                    .then(result => {           
                    console.log(typeof result, ' :result: ',result );
                    if(!result.isDuplicate){
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Product Creation in process!!',
                                message: ' Refresh the Launch page to see updates',
                                variant: 'info'
                            }),
                        );
                        let compDefinition = {
                            componentDef: "c:cpqProductLaunchComponent",
                            attributes: {
                                releaseName: this.state.releaseName,
                                releaseId : this.state.releaseId,
                                productOfType : this.productType
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
                    else{
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Duplicates Found '+result.duplicateProductCodeNames,
                                message: 'These product are already associated with the selected launch. Kindly choose a different launch month ',
                                variant: 'Warning'
                            }),
                        );
                        this.state.createButtonDisable = false;
                        this.state.label='Create Product';
                    }
                    
                })
                .catch(error => {
                    console.log(error);
                    this.state.error = error;
                });

        }
        

}
else{
this.dispatchEvent(
    new ShowToastEvent({
        title: 'Missing Launch',
        message: 'Please select the Launch',
        variant: 'error'
    }),
);
}
}
}