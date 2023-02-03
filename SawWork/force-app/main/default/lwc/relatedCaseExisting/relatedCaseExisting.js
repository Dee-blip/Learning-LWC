import { LightningElement, api, track } from 'lwc';
import getCaseRecords from '@salesforce/apex/RelatedCaseExistingController.getCaseRecords';
import updateParentCase from '@salesforce/apex/RelatedCaseExistingController.updateParentCase';
import getParentIds from '@salesforce/apex/RelatedCaseExistingController.getOnLoadCaseNumber';

import cssStyleSheet from "@salesforce/resourceUrl/SC_RelatedCaseExistingExtCSS";
import { loadStyle } from "lightning/platformResourceLoader";

const columns = [
    /*{ label: '', fieldName: 'title', type: 'text', wrapText: true,
        cellAttributes:{  class:{  fieldName: 'format'}}
    },*/
    { label: "Case Number", fieldName: "CaseLink", type: "url",  
        typeAttributes: { label: { fieldName: "caseNumber" }, tooltip: 
        {
            fieldName: 'title'
        }, 
        target: "_blank" },
        cellAttributes:{  class:{  fieldName: 'format'}},
        sortable: true
    },
    { label: 'Subject', fieldName: 'Subject', type: 'text', sortable: true},
    { label: "Account Name", fieldName: "AccountLink", type: "url",  sortable: true,
        typeAttributes: { label: { fieldName: "accountName" }, tooltip:"Account Name", target: "_blank" }  
    },
    { label: 'AKAM Case Id', fieldName: 'AKAM_Case_ID__c', type: 'text', sortable: true },
    { label: "Parent Case", fieldName: "ParentLink", type: "url", sortable: true, 
        typeAttributes: { label: { fieldName: "parentCase" }, tooltip:"Parent Case", target: "_blank" }  
    },
    { label: 'Status', fieldName: 'Status', type: 'text', sortable: true },
    { label: 'Owner', fieldName: 'OwnerName', type: 'text', sortable: true },
    { label: 'Record Type', fieldName: 'RecordTypeName', type: 'text', sortable: true },
];
export default class RelatedCaseExisting extends LightningElement {

@api recordId;//Stores the parent's id
@api themeOfUser;//Store theme(console or nonconsole app) to redirect the back button
@track casesWrap = undefined;//holds the wrapper values from the wire service
columns = columns;
@track selectedRows = [];
casesSpinner = false;
noRecordsFound = false;
recordsFound = false;
isUpdating = false;


//Sorting variables
sortedBy;
defaultSortDirection = 'asc';
sortDirection = 'asc';
//Sorting variables end

AkamIdOfCase;
CaseNumberOfCase;


inputCaseIds = undefined;//holds the value from the input field

//Method executed before the page is rendered
connectedCallback(){
    //do something
    getParentIds({
        caseId : this.recordId
    })
    .then(result =>{
        if(JSON.stringify(result) !== '{}'){
            this.AkamIdOfCase = result.akamId;
            this.CaseNumberOfCase = result.caseNumber;
        }
        else{
            this.AkamIdOfCase = undefined;
            this.CaseNumberOfCase = undefined;
        }
    })
    .catch(error =>{
        let errorMessage = '';
        if ( error.body.message) {
            errorMessage =error.body.message;
        }
        this.template.querySelector('c-custom-toast-cmp').showToast('error', errorMessage,'Error : Failed to load the current record data');
    })
    loadStyle(this, cssStyleSheet);
} 


//Method to search the case using the Search Cases button
searchCase(){
    var arr;
    this.inputCaseIds = this.template.querySelector('.idVals').value;
    if(this.inputCaseIds){
        arr = this.inputCaseIds.split(/[\s,;\t\n]+/);
        if(arr.length>100){
            this.template.querySelector('c-custom-toast-cmp').showToast('error', 'Number of records exceeds 100','Error : Can only search upto 100 records');
        }
        else{
            this.casesSpinner = true;
            this.noRecordsFound = false;
            this.recordsFound = false;
            this.selectedRows = [];
            getCaseRecords({
                idsToSearchStr : JSON.stringify(arr),
                caseId : this.recordId
            })
            .then(result =>{
                console.log('result :: '+JSON.stringify(result));
                if(!result.length){
                    //The case list returned is empty here
                    this.casesWrap = undefined;
                    this.noRecordsFound = true;
                    this.casesSpinner = false;
                }
                else{
                    let prepareDataList = [];
                    result.forEach(caseWr =>{
                        let prepareData = {};
                        prepareData.title = caseWr.title;
                        //prepareData.format = prepareData.title !== 'Please select this Case to update' ? 'slds-text-color_error':'slds-text-color_success';
                        if(prepareData.title === 'This case is parented by a case that is also its child'){
                            prepareData.format = 'SameCaseBg';
                        }
                        else if(prepareData.title === 'This case already has a parent'){
                            prepareData.format = 'HasParentAlready';
                        }
                        else if(prepareData.title === 'This case is already closed'){
                            prepareData.format = 'AlreadyClosed';
                        }
                        if(caseWr.caseToDisplayWrapper.Id){
                            prepareData.CaseLink = "/" + caseWr.caseToDisplayWrapper.Id;
                            prepareData.caseNumber = caseWr.caseToDisplayWrapper.CaseNumber;
                            prepareData.Id = caseWr.caseToDisplayWrapper.Id;
                        }
                        else{
                            prepareData.CaseLink = null;
                            prepareData.caseNumber = null;
                            prepareData.Id = null;
                        }
                        prepareData.Subject = caseWr.caseToDisplayWrapper.Subject;
                        if(caseWr.caseToDisplayWrapper.AccountId){
                            prepareData.AccountLink = "/" + caseWr.caseToDisplayWrapper.AccountId;
                            prepareData.accountName = caseWr.caseToDisplayWrapper.Account.Name;
                            prepareData.AccountId = caseWr.caseToDisplayWrapper.AccountId;
                        }
                        else{
                            prepareData.AccountLink = null;
                            prepareData.accountName = null;
                            prepareData.AccountId = null;
                        }
                        prepareData.AKAM_Case_ID__c = caseWr.caseToDisplayWrapper.AKAM_Case_ID__c;
                        if(caseWr.caseToDisplayWrapper.ParentId){
                            prepareData.ParentLink = "/" + caseWr.caseToDisplayWrapper.ParentId;
                            prepareData.parentCase = caseWr.caseToDisplayWrapper.Parent.CaseNumber;
                            prepareData.ParentId = caseWr.caseToDisplayWrapper.ParentId;
                        }
                        else{
                            prepareData.ParentLink = null;
                            prepareData.parentCase = null;
                            prepareData.ParentId = null;
                        }
                        prepareData.Status = caseWr.caseToDisplayWrapper.Status;
                        prepareData.OwnerName = caseWr.caseToDisplayWrapper.Owner.Name;
                        prepareData.OwnerId = caseWr.caseToDisplayWrapper.OwnerId;
                        prepareData.RecordTypeName = caseWr.caseToDisplayWrapper.RecordType.Name;
                        prepareData.RecordTypeId = caseWr.caseToDisplayWrapper.RecordTypeId;
                        prepareDataList.push(prepareData);
                    });
                    this.casesSpinner = false;
                    this.recordsFound = true;
                    this.casesWrap = prepareDataList;
                }
            })
            .catch(error =>{
                this.casesWrap = undefined;
                this.noRecordsFound = true;
                this.casesSpinner = false;
                let errorMessage = '';
                if ( error.body.message) {
                    errorMessage =error.body.message;
                }
                this.template.querySelector('c-custom-toast-cmp').showToast('error', errorMessage,'Error : Search Failed');
            }) 
            console.log('casesWrap :: '+this.casesWrap);
        }
    }
    else{
        this.template.querySelector('c-custom-toast-cmp').showToast('error', 'Please enter value to search','Error : Invalid Input');
    }
}

//Method fired when Update Cases button is clicked
handleUpdate(){
    var el = this.template.querySelector('lightning-datatable');
    var selected = el.getSelectedRows();
    if(selected.length !== 0){
        this.isUpdating = true;
        updateParentCase({
            csLst : JSON.stringify(selected),
            parentCaseId : this.recordId
        })
        .then(result =>{
            console.log(JSON.stringify(result));
            if(JSON.stringify(result) !== '{}'){
                if(result.successMsg){
                    this.template.querySelector('c-custom-toast-cmp').showToast('success', result.successMsg,'Success : Records Updated');
                    if(!result.errorMsg){
                        this.isUpdating = false;
                    }
                    else if(result.errorMsg){
                        setTimeout(function(){
                            this.template.querySelector('c-custom-toast-cmp').showToast('error', result.errorMsg,'Error : Records failed to Update');
                            this.isUpdating = false;
                        }.bind(this), 8000);

                        /*setTimeout( ()=>{
                            this.template.querySelector('c-custom-toast-cmp').showToast('error', result.errorMsg,'Error : Records failed to Update');
                            this.isUpdating = false;
                        }, 8000);*/
                    }
                }
                else if(!result.successMsg){
                    if(result.errorMsg){
                        this.template.querySelector('c-custom-toast-cmp').showToast('error', result.errorMsg,'Error : Records failed to Update');
                        this.isUpdating = false;
                    }
                }
            }
            else{
                this.isUpdating = false; //This is executed when empty call was made and no error or success came back
            }
            this.searchCase();
        })
        .catch(error =>{
            this.isUpdating = false;
            let errorMessage = 'The update for records failed. ';
            if ( error.body.message) {
                errorMessage =error.body.message;
            }
            this.template.querySelector('c-custom-toast-cmp').showToast('error', errorMessage,'Error : Records failed to Update');
        }) 
    }
    else{
        this.template.querySelector('c-custom-toast-cmp').showToast('error', 'Select records to update','Error : No Records Selected to Update');
    }
}

handleRowSelection() {
    var cmp = this.template.querySelector('c-custom-toast-cmp');
    var errorMsg = '';
    let localVal =[];
    console.log('this.selectedRows :: '+JSON.stringify(this.selectedRows));
    const selRows = this.template.querySelector('lightning-datatable').getSelectedRows();
    console.log('this.selectedRows :: '+JSON.stringify(selRows));
    
    selRows.forEach(function(element){
        if(element.title === 'Please select this Case to update'){ // Implement your own code logic instead of this line
            localVal.push(element.Id);
        }
        else{
            errorMsg += element.AKAM_Case_ID__c+' :: '+element.title+';';
        }
    });
    console.log('this.selectedRows :: '+JSON.stringify(localVal));
    if(localVal){
        this.template.querySelector('lightning-datatable').selectedRows= localVal;
        this.selectedRows = localVal;
    }
    if(errorMsg){
        cmp.showToast('error', errorMsg,'Error : Invalid Selection');//the context is set to cmp here
    }
    console.log('this.selectedRows after push :: '+JSON.stringify(this.selectedRows));
}

cancelThePage(){
    if(this.themeOfUser === 'Theme4d'){
        window.history.back();
        return false;
    }
    else if(this.themeOfUser === 'Theme4u'){
        this.dispatchEvent(new CustomEvent('closeSubTab', {bubbles:true, composed:true}));
    }
    return null;
}

onHandleSort( event ) {

    const { fieldName: sortedBy, sortDirection } = event.detail;
    const cloneData = [...this.casesWrap];

    cloneData.sort( this.sortBy( sortedBy, sortDirection === 'asc' ? 1 : -1 ) );
    this.casesWrap = cloneData;
    this.sortDirection = sortDirection;
    this.sortedBy = sortedBy;

}

sortBy( field, reverse, primer ) {

    const key = primer
        ? function( x ) {
              return primer(x[field]);
          }
        : function( x ) {
              return x[field];
          };

    return function( a, b ) {
        a = key(a);
        b = key(b);
        return reverse * ( ( a > b ) - ( b > a ) );
    };
}


}