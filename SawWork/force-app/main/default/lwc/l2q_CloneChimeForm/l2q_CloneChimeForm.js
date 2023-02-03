/**

**/
import { LightningElement,api,track } from 'lwc';
import getProductsForChime from '@salesforce/apex/l2qChimeCloneClass.getProductsForChime';
import clonePOCToFullIntegrationForm from '@salesforce/apex/l2qChimeCloneClass.clonePOCToFullIntegrationForm';
import clonePOCToPOCForm from '@salesforce/apex/l2qChimeCloneClass.clonePOCToPOCForm';
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class L2q_CloneChimeForm extends NavigationMixin(LightningElement) {
@api chimeId;
@api accId;
whereclause='';
CloneTypeValue;
@track products=[];
implementatonType='Standard';
formValue='POCForm';
isPOCFormSelected=true;
chimeFormName='';
@track opportunityid;
showSpinner= false;
@track isEmergency=false;
@track isWorkAtRisk = false;

connectedCallback(){
    this.whereclause = " and AccountId = '" + this.accId + "'";
    this.CloneTypeValue = false;
    this.getProducts();
}
getProducts(){
    
    getProductsForChime({ chimeId: this.chimeId })
            .then(result => {
                let prods =[];
                console.log('getProductsForChime:',result);
                result.forEach(el =>{
                    prods.push(el);
                })
                this.products = prods;
            })
            .catch(error=>{
                console.log('error:',error);
            })
}
handleChimeNameChange(event){
    this.chimeFormName = event.detail.value;

}
handleClose(){
    const cancelEvent = new CustomEvent('cancel', {});
    this.dispatchEvent(cancelEvent);    
}

handleChangeValueType(event){
    this.CloneTypeValue = event.detail.checked;
}
@track selectedProducts=[];
onProductSelect(event) {
    //let tempProducts = [];
    this.products.forEach(el => {
        if (event.target.value === el.productId) {
            if (event.target.checked) {
                this.processSelection('add',el.productId);
            }
            else {
                this.processSelection('remove',el.productId);
            }
        }
    })
    console.log('selectedProducts',JSON.parse(JSON.stringify(this.selectedProducts)));
}
processSelection(action,productId){
    let selectedProds = this.selectedProducts;
        if (selectedProds.some(selectedProd => selectedProd === productId)) {
            if (action === 'remove') {
                let index = selectedProds.findIndex(v => v === productId);
                selectedProds.splice(index, 1);
            }
        }
        else {
            if (action === 'add') {
                let prod = productId;
                
                selectedProds.push(prod);
            }
        }
        this.selectedProducts = selectedProds;
        console.log('selectedProducts process',JSON.parse(JSON.stringify(this.selectedProducts)));
}

get radioOptions(){
    return [
        { label: 'POC Chime Form', value: 'POCForm' },
        { label: 'Full Integration Form', value: 'FullForm' },
    ];
    
}

get options() {
    return [
        { label: 'Standard', value: 'Standard' },
        { label: 'Managed', value: 'Managed' },
    ];
    
}

getOpportunityId(event) {
    let oppId = event.detail.recordId;
    this.opportunityid = oppId;
}

handleImplementationTypeChange(event) {
    this.implementatonType = event.detail.value;
    if(event.detail.value === 'FullForm'){
        this.pocTypeValue='';
    }
}
handleFormValueChange(event){
    this.isPOCFormSelected = (event.detail.value === 'POCForm') ? true : false;
    if(event.detail.value === 'POCForm'){
        this.selectedProducts = [];
    }
    this.formValue = event.detail.value;
}
get poctypeoptions() {
    return [
        { label: 'Standard-POC', value: 'Standard-POC' },
        { label: 'Custom-POC', value: 'Custom-POC' },
    ];
}

handlePOCTypeChange(event){
    this.pocTypeValue = event.detail.value;
    if(event.detail.value === 'Standard-POC'){
        this.disableImplementationType = true;
        this.implementatonType='';
    }else{
        this.disableImplementationType = false;
    }
}

handleIsEmergencyChange(event){
    console.log('emergency',this.isEmergency);

    //this.isEmergency = event.detail.value;
    this.isEmergency = event.target.checked;

    console.log('emergency',this.isEmergency);
}

handleisWorkAtRiskChange(event){
    this.isWorkAtRisk = event.target.checked;
    console.log('Work At Risk', this.isWorkAtRisk);
}

handleSave() {
    this.isloading = true;
    if (this.selectedProducts.length === 0 && !this.isPOCFormSelected) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error!',
                message: 'Product Selection is Mandatory.',
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

    if(!this.opportunityid){
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error!',
                message: 'Opportunity is mandatory for cloning CHIME form.',
                variant: 'error'
            })
        );
        this.isloading = false;
        return;
    }
    this.createNewChime();
}
createNewChime(){
    if(!this.isPOCFormSelected){
        this.showSpinner = true;
        clonePOCToFullIntegrationForm({ chimeId: this.chimeId, oppId: this.opportunityid, productList : JSON.stringify(this.selectedProducts),
                                        implementationType: this.implementatonType, emergency: this.isEmergency ,chimeFormName: this.chimeFormName ,workatrisk: this.isWorkAtRisk })
                .then(result => {
                    this.showSpinner = false;
                    console.log('clonePOCToFullIntegrationForm'+result);
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: result,
                            objectApiName: 'CHIME__c',
                            actionName: 'view'
                        }
                    });
                })
                .catch(error=>{
                    this.showSpinner = false;
                    console.log('error:',error);
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
                })
    }else{
        this.showSpinner = true;
        clonePOCToPOCForm({ chimeId: this.chimeId, oppId: this.opportunityid, chimeFormName: this.chimeFormName })
        .then(result => {
            this.showSpinner = false;
            console.log('clonePOCToPOCForm'+result);
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: result,
                    objectApiName: 'CHIME__c',
                    actionName: 'view'
                }
            });
        })
        .catch(error=>{
            this.showSpinner = false;
            console.log('error:',error);
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
        })
    }
}


}