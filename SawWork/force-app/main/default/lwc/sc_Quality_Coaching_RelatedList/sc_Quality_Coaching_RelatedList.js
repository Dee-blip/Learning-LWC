import { LightningElement, api, wire } from 'lwc';  
import fetchRecords from '@salesforce/apex/SC_QualityCheckRelatedListController.fetchRecords';  
  
export default class RelatedList extends LightningElement {  
  
     
    @api recordId;  
    @api strTitle = 'Quality Coachings';  
    
    
    
    get vals() {  
        return this.recordId;  
    }  
      
    @wire(fetchRecords, { listValues: '$vals' })  
    records;  
  
}