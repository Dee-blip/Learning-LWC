import { LightningElement,api,track,wire } from 'lwc';
import lookUp from '@salesforce/apex/CPQ_Custom_LookUp_Controller.search';
export default class CpqCustomLookupComponent extends LightningElement {
@track state={
    selectedName :'',
    records :'',
    isValueSelected :'',
    blurTimeout :'',
    searchTerm :'',
    boxClass :'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus',
    inputClass : ''
}

@api objName;
@api releaseName;
@api releaseId;
@api iconName;
@api searchPlaceholder='Search';

@wire(lookUp, {searchTerm : '$state.searchTerm', myObject : '$objName'})
wiredRecords({ error, data }) {
    if (data) {
        this.error = undefined;
        this.state.records = data;
    } else if (error) {
        this.error = error;
        this.state.records = undefined;
    }
}
connectedCallback() {
    this.loadLookupDetails();
}
loadLookupDetails(){
    this.state.searchTerm = this.releaseName;
    lookUp({
        searchTerm: this.releaseName ,
        myObject : this.objName,
        
    })
        .then((result) => {
            this.state.records  = result;
            const valueSelectedEvent = new CustomEvent('loadresults');
            this.dispatchEvent(valueSelectedEvent);

        })
        .catch((error) => {
            console.log('inside error');
            console.log(error);
            

        });

    
}
handleClick() {
    
    this.state.inputClass = 'slds-has-focus';
    this.state.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus slds-is-open';
    
}

onSelect(event) {
    let selectedId = event.currentTarget.dataset.id;
    let selectedName = event.currentTarget.dataset.name;
    const valueSelectedEvent = new CustomEvent('lookupselected', {detail: {selectedId:selectedId,selectedName:selectedName}  });
    this.dispatchEvent(valueSelectedEvent);
    this.state.isValueSelected = true;
    this.state.selectedName = selectedName;
    if(this.state.blurTimeout) {
        clearTimeout(this.state.blurTimeout);
    }
    this.state.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
}

handleRemovePill() {
    this.state.searchTerm='';
    this.state.isValueSelected = false;
    const valueSelectedEvent = new CustomEvent('removeresults');
    this.dispatchEvent(valueSelectedEvent);
}

onChange(event) {
    this.state.searchTerm = event.target.value;
    if(this.state.searchTerm==='')
    {    
        const valueSelectedEvent = new CustomEvent('removeresults');
        this.dispatchEvent(valueSelectedEvent);
    }
    
}


}