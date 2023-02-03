import { LightningElement, track, api } from "lwc";  
// import findRecords from "@salesforce/apex/SC_Jarvis_Case_Questionnaire_Controller.findLookupRecords";  

export default class ScCommunityDynamicPickList extends LightningElement 
{
    //@api searchresult = [];
    @track recordslistInternal =undefined;  
    @track selectedvalueInternal;  
    @track selectedRecordIdInternal;  

    @api
    get recordslist() {
        return this.recordslistInternal;
    }

    set recordslist(value) {
       this.recordslistInternal = value;
    }
    
    
    @track searchKey = "";  
    
    @api
    get selectedvalue() {
        return this.selectedvalueInternal;
    }

    set selectedvalue(value) {
       this.selectedvalueInternal = value;
    }

    
    
    @api
    get selectedRecordId() {
        return this.selectedRecordIdInternal;
    }

    set selectedRecordId(value) {
       this.selectedRecordIdInternal = value;
    }
    
    @api iconname;  
    @api lookupLabel;  
    @api searchQuery;
    @api message;  
    @api error;
    @api haserror = false;
    @api required = false;
    @api labelstyle = '';
    
    iconClass='slds-combobox__form-element slds-input-has-icon slds-input-has-icon_left-right';
    timeoutId;
  
    connectedCallback()
    {
        if(this.recordslist)
        {
            this.recordslistInternal = [...this.recordslist];
        }
        if(this.selectedvalue)
        {
            this.selectedvalueInternal = this.selectedvalue;
        }
        if(this.selectedRecordId)
        {
            this.selectedRecordIdInternal = this.selectedRecordId;
        }
        
    }
    onLeave() {  
     setTimeout(() => {  
      this.searchKey = "";  
      this.recordslistInternal = null;  
     }, 300);  
    }  
    
    onRecordSelection(event) {  
     this.selectedRecordIdInternal = event.target.dataset.key;  
     this.selectedvalueInternal = event.target.dataset.name;  
     this.searchKey = "";  
     this.onSeletedRecordUpdate();  
    }  
     
    handleKeyChange(event) {  
     const searchKey = event.target.value;  
     this.searchKey = searchKey;  
     clearTimeout(this.timeoutId);
     this.timeoutId = setTimeout(this.getLookupResult.bind(this), 500);
    }  
     
    removeRecordOnLookup() {  
        console.log('removal!!');
     this.searchKey = "";  
     this.selectedvalueInternal = null;  
     this.selectedRecordIdInternal = null;  
     this.recordslistInternal = null;  
     this.onSeletedRecordUpdate();  
   }  
  
    getLookupResult() 
    {  

        console.log('this.iconClass:' + this.iconClass);
        console.log('this.iconName:' + this.iconname);
        if(this.searchKey === '' || this.searchKey === undefined)
        {
            this.recordslistInternal = undefined;  
            this.selectedvalueInternal = undefined;
        }
        else
        {
            const passEventr = new CustomEvent('searchevent', {  
                detail: { searchKey: this.searchKey}  
                });  
                this.dispatchEvent(passEventr);  
                //console.log('this.recordslist:' + this.recordslistInternal);
        
        }

    }
          
    onSeletedRecordUpdate(){  
     const passEventr = new CustomEvent('recordselection', {  
       detail: { selectedRecordId: this.selectedRecordIdInternal, selectedValue: this.selectedvalueInternal }  
      });  
      this.dispatchEvent(passEventr);  
    }
}