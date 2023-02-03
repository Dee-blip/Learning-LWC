import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import productDetails from '@salesforce/apex/L2Q_ChimeProductsLinksController.getProductLOEDetailsForLink';

export default class L2q_ChimeProductsLink extends LightningElement {
    @track error;
    @track Products;
    @track ProductsBackUp;
    connectedCallback() {
       
        this.loadProductsDetails();
    }
    
    loadProductsDetails(){
        productDetails()
            .then(result => {
                this.Products = result;
                this.ProductsBackUp = result;
               
            })
            .catch(error => {
                this.error = error;
                
            });
    }

    renderedCallback() {
        const style = document.createElement('style');
        style.innerText = `c-l2q_-chime-products-link .search .slds-input{
        background-color:beige;
        width:500px;
        border-radius:25px;
        }`;
        this.template.querySelector('lightning-input').appendChild(style);
    
        
        }

    handleClose(){
        
        this.dispatchEvent(new CustomEvent('close'));
    }

    keycheck(event){
        if(event.which === 13){
            this.handleSearch(event);
        }
    } 

      //handlig search functionality on blur
      handleSearch(event){
        // At least 3 characters required for search
        if(event.target.value !== '' && event.target.value.length < 3){
            this.showToast('Please type at least 3 characters for search.','error','dismissable');
            return;
        }
    
        //search variable setting based on section
        this.searchKey = event.target.value;
         if(event.target.value === '' || event.target.value === null || event.target.value === undefined){
             this.Products = this.ProductsBackUp;
         }else{
             this.searchKey = event.target.value;
             let searchString = event.target.value.toLowerCase();
             let tempList = [];
             let productsList = [];
             
             productsList = this.ProductsBackUp;
             
             for(let i=0;i<productsList.length;i++){
             let tempRecord = Object.assign({}, productsList[i]); 
             if(tempRecord.Product_Name__c.toLowerCase().includes(searchString)){
                 //if(tempRecord.Incident_ID.includes(this.searchKeyMyIncidentsSection) || tempRecord.Title.includes(this.searchKeyMyIncidentsSection) || tempRecord.Status.includes(this.searchKeyMyIncidentsSection) || tempRecord.Impact.includes(this.searchKeyMyIncidentsSection) || tempRecord.OwnerName.includes(this.searchKeyMyIncidentsSection) || tempRecord.Incident_Requested_By.includes(this.searchKeyMyIncidentsSection) || tempRecord.TIM.includes(this.searchKeyMyIncidentsSection)){
                     tempList.push(tempRecord); 
                 } 
             }
            this.Products = tempList;
         }   
    }  
    showToast(message,variant,mode) {
        // alert('here');
        const evt = new ShowToastEvent({
            
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }
}