/* eslint-disable vars-on-top */
/* eslint-disable no-console */
import { LightningElement, wire,track,api } from 'lwc';
import getPIValues from '@salesforce/apex/SC_AC_BulkEdit.getProductInterestsOnLoad';
import getAuthorizedContacts from '@salesforce/apex/SC_AC_BulkEdit.getRecordsToDisplay';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import util from 'c/scUtil'; 

export default class ScMultiselectPicklist extends LightningElement {

@api productInterestSelected; 
@api authContactId; 

@track options=[];
@track error;
@track dropdown = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
@track dataList;
@track dropdownList = 'slds-media slds-listbox__option slds-listbox__option_entity slds-listbox__option_has-meta';
@track selectedValue ;
@track selectedListOfValues='';
showSpinner = false;
actualPIs = [];

connectedCallback() 
{
    this.refreshContacts();
    
}
refreshContacts(){
    util.register('refreshPIs', this.handleRefreshEvent.bind(this));
}

handleRefreshEvent(PDId){
    getAuthorizedContacts({parentId: PDId})
    .then(result => {
        this.actualPIs = result;
        if(this.actualPIs.length > 0){
            this.selectedValue = [];
            for(let i = 0; i < this.actualPIs.length; i++){
                if(this.actualPIs[i].Id === this.authContactId){
                    this.selectedValue = this.actualPIs[i].Product_Interests__c.split(';');
                }
            }
        }
        //this.dropdown =  'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open'; 
        for (let i = 0; i < this.options.length; i++) {
            if(this.selectedValue.includes(this.options[i].value )){
                this.options[i].isChecked = true;
                //this.options[i].class = 'slds-media slds-listbox__option slds-listbox__option_plain slds-media_small slds-media_center slds-is-selected';
            }
            else{
                this.options[i].isChecked = false;
                //this.options[i].class = this.dropdownList;
            }
        }
    })
    .catch(error => {
        console.log('ERROR : '+error);
    })
}

/*@wire(getPIValues)
wiredCountryProperty(response){
    
    if(response.data){
        //alert(this.refreshTable);
        this.selectedValue = this.productInterestSelected;
        this.dataList = response.data.getProductInterests;
        console.log('datalist1==>' + JSON.stringify(this.dataList));
        console.log('datastring==>' + response.data.getContactName);

        for (let i = 0; i < this.dataList.length; i++) {
            this.options = [...this.options, 
                { 
                    value: this.dataList[i], 
                    label: this.dataList[i],
                    isChecked:false,
                    class:this.dropdownList 
                }
            ];
        }
        console.log('optionslist==>' + JSON.stringify(this.options));
        this.error = undefined;
    }
    else if (response.error) {
        this.error = response.error;
        this.options = undefined;
    }
}*/

@wire(getPIValues)
wiredCountryProperty({data, error}){
    
    if(data){
        this.selectedValue = this.productInterestSelected;
        this.dataList = data.getProductInterests;
        console.log('datalist1==>' + JSON.stringify(this.dataList));
        console.log('datastring==>' + data.getContactName);

        for (let i = 0; i < this.dataList.length; i++) {
            this.options = [...this.options, 
                { 
                    value: this.dataList[i], 
                    label: this.dataList[i],
                    isChecked:false,
                    class:this.dropdownList 
                }
            ];
        }
        console.log('optionslist==>' + JSON.stringify(this.options));
        this.error = undefined;
     }
     else if (error) {
           this.error = error;
           this.options = undefined;
         }
}


openDropdown(){
    /*if(this.actualPIs.length > 0){
        this.selectedValue = [];
        for(let i = 0; i < this.actualPIs.length; i++){
            if(this.actualPIs[i].Id === this.authContactId){
                this.selectedValue = this.actualPIs[i].Product_Interests__c.split(';');
            }
        }
    }*/
    this.dropdown =  'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open'; 
    for (let i = 0; i < this.options.length; i++) {
        if(this.selectedValue.includes(this.options[i].value )){
            this.options[i].isChecked = true;
            this.options[i].class = 'slds-media slds-listbox__option slds-listbox__option_plain slds-media_small slds-media_center slds-is-selected';
        }
        else{
            this.options[i].isChecked = false;
            this.options[i].class = this.dropdownList;
        }
    }
}

closeDropDown(){
   this.dropdown =  'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
}

selectOption(event){

var isCheck = event.currentTarget.dataset.id;
var label = event.currentTarget.dataset.name;
var selectedListData=[];
var allOptions = this.options;
var checkedCount = 0;
    for(let i=0;i<allOptions.length;i++){ 
        if(allOptions[i].isChecked){
            checkedCount++;
        }
    }

    for(let i=0;i<allOptions.length;i++){ 
        if(allOptions[i].label===label)
        { 
            if(isCheck==='true')
            { 
                if(checkedCount === 1){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error selecting products',
                            message: 'Select atleast one Product',
                            variant: 'error'
                        })
                    );
                    allOptions[i].isChecked = true; 
                    allOptions[i].class = 'slds-media slds-listbox__option slds-listbox__option_plain slds-media_small slds-media_center slds-is-selected';
                }
                else if(checkedCount > 1){
                    allOptions[i].isChecked = false;
                    allOptions[i].class = this.dropdownList;
                }
                
            }
            else
            { 
                allOptions[i].isChecked = true; 
                allOptions[i].class = 'slds-media slds-listbox__option slds-listbox__option_plain slds-media_small slds-media_center slds-is-selected';
            }
        } 
        if(allOptions[i].isChecked)
        { 
            selectedListData.push(allOptions[i].label); 
        } 
        
    }

    this.options = allOptions;
    this.selectedValue = selectedListData;
    this.selectedListOfValues = selectedListData;
    
    this.dispatchEvent(new CustomEvent('saveproductinterest', {
            detail: {
                PISel: this.selectedListOfValues,
                ACId:this.authContactId,
                fieldName: 'Service__c', 
                value: true
            },  
            bubbles: true, 
            composed: true
        })
    );
}

}