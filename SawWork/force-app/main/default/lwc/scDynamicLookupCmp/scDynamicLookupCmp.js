/** @Date		:	Aug 05 2020
* @Author		: 	Sumukh SS 
* @Description	:	Cases in Queue functionality for Unified Case Dashboard
*/
import { LightningElement, track, api } from "lwc";  
import findRecords from "@salesforce/apex/SC_UCD_HomePage.findLookupRecords";  

 export default class scdynamiclookupcmp extends LightningElement {  
  @track recordsList;  
  @track searchKey = "";  
  @track selectedValue;  
  @track selectedRecordId;  
  @api iconName;  
  @api lookupLabel;  
  @api searchQuery;
  @api keyField; //For e.g Id
  @api labelField; //For e.g. Name
  @track message;  
    
  timeoutId;

  onLeave(event) {  
   setTimeout(() => {  
    this.searchKey = "";  
    this.recordsList = null;  
   }, 300);  
  }  
    
  onRecordSelection(event) {  
   this.selectedRecordId = event.currentTarget.dataset.key;  
   this.selectedValue = event.currentTarget.dataset.name;  
   this.searchKey = "";  
   this.onSeletedRecordUpdate();  
  }  
   
  handleKeyChange(event) {  
   const searchKey = event.target.value;  
   this.searchKey = searchKey;  
   clearTimeout(this.timeoutId);
   this.timeoutId = setTimeout(this.getLookupResult.bind(this), 500);
  }  
   
  removeRecordOnLookup(event) {  
   this.searchKey = "";  
   this.selectedValue = null;  
   this.selectedRecordId = null;  
   this.recordsList = null;  
   this.onSeletedRecordUpdate();  
 }  

  getLookupResult() {

  if(this.searchKey) {
   findRecords({ searchKey: this.searchKey, searchQuery : this.searchQuery })  
    .then((result) => {  
     if (result.length===0) {  
       this.recordsList = [];  
       this.message = "No Records Found";  
      } else {  
        this.recordsList = result.map(row => ({
                ...row,
                key:this.keyField.split('.').reduce((o,i)=>o[i], row),
                label:this.labelField.split('.').reduce((o,i)=>o[i], row)}
        ));
       this.message = "";  
      }  
      this.error = undefined;  
    })  
    .catch((error) => {  
     this.error = error;  
     this.recordsList = undefined;  
    });  
   }  
  }
   
  onSeletedRecordUpdate(){  
   const passEventr = new CustomEvent('recordselection', {  
     detail: { selectedRecordId: this.selectedRecordId, selectedValue: this.selectedValue }  
    });  
    this.dispatchEvent(passEventr);  
  }  
 }