/* eslint no-use-before-define: 0 */  // --> OFF

import { LightningElement, wire, api, track } from 'lwc';
import getAuthorizedContacts from '@salesforce/apex/SC_AC_BulkEdit.getRecordsToDisplay';
import { NavigationMixin } from 'lightning/navigation';
import { loadStyle } from 'lightning/platformResourceLoader';
import SC_SBulkEdit_AC from '@salesforce/resourceUrl/SC_BulkEdit_AC';

import { refreshApex } from '@salesforce/apex';

import updateContacts from '@salesforce/apex/SC_AC_BulkEdit.updateContacts';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

import { deleteRecord } from 'lightning/uiRecordApi';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import util from 'c/scUtil'; 


const actions = 
    [
        { label: 'Edit', name: 'edit'}, 
        { label: 'Delete', name: 'delete'}, 
    ];

const COLS = [
    {
        label: 'Contact Name',
        fieldName: 'contactUrl',
        type: 'url',
        typeAttributes: 
        { 
            label: { fieldName: 'contactName' },
            tooltip: 'Go to Contact', 
            target: '_self'
        },
        editable: false,
        sortable: true,
        initialWidth: 160,
        wrapText: false
        
    },
    { 
        label: 'Passphrase', 
        fieldName: 'passphrase', 
        type: 'url' ,
        typeAttributes: 
        { 
            label: { fieldName: 'passphraseText' },
            tooltip: 'Go to Contact', 
            target: '_blank'
        },
        editable: false,
        sortable: true,
        initialWidth: 142,
        wrapText: true
    },
    { 
        label: 'PD Lead', 
        fieldName: 'PD_Lead__c', 
        type: 'boolean',
        editable: true, 
        initialWidth: 114,
        wrapText: true
    },
    { 
        label: 'Product Interests', 
        type: 'scMultiSelect', 
        initialWidth: 219, 
        typeAttributes: { 
            authContactId:{ fieldName: 'Id' }, 
            productInterestSelected: { fieldName: 'Product_Interests__c' }, 
        },
        cellAttributes: { class: 'my-pick-cls'} 
    },

    { label: 'Service', fieldName: 'Service__c', editable: true, type: 'boolean',sortable: true,wrapText: true,initialWidth: 120,},
    { label: 'Instruct', fieldName: 'Instruct__c', editable: true, type: 'boolean',sortable: true, wrapText: true, initialWidth: 120,},
    { label: 'Maintenance Email', fieldName: 'Maintenance_Email__c', editable: true, type: 'boolean',sortable: true, wrapText: true, initialWidth: 170,},
    { label: 'Emergency Email', fieldName: 'Emergency_Email__c', editable: true, type: 'boolean',sortable: true, wrapText: true, initialWidth: 170,},
    { label: 'Emergency Text', fieldName: 'Emergency_Text__c', editable: true, type: 'boolean',sortable: true,wrapText: true, initialWidth: 170,},
    { label: 'Emergency Voice', fieldName: 'Emergency_Voice__c', editable: true, type: 'boolean',sortable: true, wrapText: true,initialWidth: 170,},
    {
        type: 'action',
        typeAttributes: {
            rowActions: actions,
            menuAlignment: 'right'
        }
    }
];

//Changes by Tejaswini for ESESP-4953
const contactColumns = 
[
    /*{
        label:'NAME',
        fieldName:'contactName', 
        type: 'text', 
        cellAttributes:{alignment:'left'},
        wrapText: true,
        sortable : "true"
        //,initialWidth: 200
    },*/
    {
        label:'NAME',
        fieldName:'contactUrl',
        type: 'url',
        typeAttributes: 
        { 
            label: { fieldName: 'contactName' },
            tooltip: 'Go to Contact', 
            target: '_blank'
        },
        cellAttributes:{alignment:'left'},
        wrapText: true,
        sortable : "true"
    },
    {
        label: 'CONTACT ID',
        fieldName: 'akamContactId',
        type: 'text',
        wrapText: true,
        hideDefaultActions: true,
        sortable : "true"
        //,initialWidth: 155
    },
    {
        label: 'TITLE',
        fieldName: 'title',
        type: 'text',
        wrapText: true,
        sortable : "true"
        //,initialWidth: 500
    },
    {
        label: 'EMAIL',
        fieldName: 'email',
        type: 'text',
        wrapText: true,
        hideDefaultActions: true,
        sortable : "true"
        //,initialWidth: 180
    },

    /*{
        label: 'ACCOUNT NAME',
        fieldName: 'accountName',
        type: 'text',
        wrapText: true,
        hideDefaultActions: true,
        sortable : "true"
        //,initialWidth: 120
    },*/
    {
        label:'ACCOUNT NAME',
        fieldName:'accountUrl',
        type: 'url',
        typeAttributes: 
        { 
            label: { fieldName: 'accountName' },
            tooltip: 'Go to Account', 
            target: '_blank'
        },
        wrapText: true,
        sortable : "true"
    }
     
];

export default class ScBulkEditAC extends NavigationMixin(LightningElement){

    @api recordId;
    @track columns;
    draftValues = [];
    contactData = [];
    slicedContactData = [];
    contact;
    error;
    showSpinner = false;
    authConSize = 0;

    showAll = false;
    pdName;
    conIdProdIntMap = new Map();
    productInterestsSelected;
    authConId;
    contactPresent = false;

    //Changes by Tejaswini for ESESP-4953
    @track contactColumns=contactColumns;
    @track showModal = false;
    @track showDeleteModal = false;


    
    connectedCallback() 
    {
        loadStyle(this, SC_SBulkEdit_AC);
        this.refreshAuthContacts();
    }
    refreshAuthContacts(){
        util.register('refreshAuthContact', this.refreshContacts.bind(this));
    }
    
    @wire(getAuthorizedContacts, { parentId: '$recordId' })
    wiredContact(response){
        this.columns = COLS;
        this.contact = response;
        if (response.data) {
            this.authConSize = response.data.length;
            let authContacts = [];
            if(this.authConSize > 0)
                this.pdName = response.data[0].Policy_Domain__r.Name;
            response.data.forEach((eachContact) => {
                let authContact = {};
                authContact.Id = eachContact.Id;
                if(eachContact.Contact_Name__c){
                    authContact.contactName = eachContact.Contact_Name__r.Name;
                    authContact.contactUrl = '/lightning/r/Contact/' + eachContact.Contact_Name__c + '/view';
                }
                authContact.passphrase = '/'+eachContact.Passphrase__c.split('target')[0].split('href="/')[1].replace('"','');
                authContact.passphraseText = 'Click here';
                authContact.PD_Lead__c = eachContact.PD_Lead__c;
                authContact.Product_Interests__c = eachContact.Product_Interests__c;
                authContact.Service__c = eachContact.Service__c;
                authContact.Instruct__c = eachContact.Instruct__c;
                authContact.Maintenance_Email__c = eachContact.Maintenance_Email__c;
                authContact.Emergency_Email__c = eachContact.Emergency_Email__c;
                authContact.Emergency_Text__c = eachContact.Emergency_Text__c;
                authContact.Emergency_Voice__c = eachContact.Emergency_Voice__c;
                authContact.Refreshed = false;
                authContacts.push(authContact);
            });
            this.contactData = authContacts;
            this.slicedContactData = this.contactData.slice(0,5);
        } 
        else if(response.error){
            this.error = response.error;
            this.contactData = undefined;
        }
        if(this.contactData.length > 0){
            this.contactPresent = true;
        }
    }

    viewAll(){
        this.showAll = true;
    }
    closeViewAll(){
        this.showAll = false;
    }

    async handleSave(event) {
        this.showSpinner = true;
        let updatedFields = event.detail.draftValues;
        let tempMap = this.conIdProdIntMap;
        console.log(this.conIdProdIntMap);
        let idList = [];

        let uniqueDraftValues = this.draftValues.reduce((unique, o) => {
            if(!unique.some(obj => obj.Id === o.Id && obj.Product_Interests__c === o.Product_Interests__c)) {
              unique.push(o);
            }
            return unique;
        },[]);

        if(updatedFields.length > 0){
            for(let i=0; i<updatedFields.length; i++){
                if(tempMap.has(updatedFields[i].Id)){
                    updatedFields[i].Product_Interests__c = tempMap.get(updatedFields[i].Id);
                }
                idList.push(updatedFields[i].Id);
            }
        }
        else{
            if(uniqueDraftValues.length > 0){
                for(let j=0; j<uniqueDraftValues.length; j++){
                    if(tempMap.has(uniqueDraftValues[j].Id)){
                        updatedFields.push({ 
                            Product_Interests__c: tempMap.get(uniqueDraftValues[j].Id),
                            Id: uniqueDraftValues[j].Id
                        });
                        idList.push(updatedFields[j].Id);
                    }
                }
            }
        }

        for (const [key, value] of tempMap.entries()) {
            if(!idList.includes(key)){
                updatedFields.push({ 
                    Product_Interests__c: value,
                    Id: key
                });
            }
        }
       
        // Prepare the record IDs for getRecordNotifyChange()
        const notifyChangeIds = updatedFields.map(
            row => { 
                return { "recordId": row.Id } 
            }
        );

        // Pass edited fields to the updateContacts Apex controller
        await updateContacts({data: updatedFields})
        .then(result => {
            console.log(JSON.stringify("Apex update result: "+ result));
            if(result.includes('Success')){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Contact updated',
                        variant: 'success'
                    })
                );
            }
            else if(result.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION') || result.includes('exception')){
                let errorMsg = result;
                if(result.split('FIELD_CUSTOM_VALIDATION_EXCEPTION, ') !== null && result.split('FIELD_CUSTOM_VALIDATION_EXCEPTION, ') !== undefined){
                    if(result.split('FIELD_CUSTOM_VALIDATION_EXCEPTION, ')[1] !== null && result.split('FIELD_CUSTOM_VALIDATION_EXCEPTION, ')[1] !== undefined){
                        errorMsg = result.split('FIELD_CUSTOM_VALIDATION_EXCEPTION, ')[1] ;
                    } 
                }
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating or refreshing records',
                        message: errorMsg,
                        variant: 'error'
                    })
                );
                this.refreshContacts();
            }
    
            // Refresh LDS cache and wires
            getRecordNotifyChange(notifyChangeIds);
        
            // Display fresh data in the datatable
            refreshApex(this.contact).then(() => {
                // Clear all draft values in the datatable
                this.draftValues = [];
                this.showSpinner = false;
            });

       }).catch(error => {
           this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error updating or refreshing records',
                    message: error.body.message,
                    variant: 'error'
                })
            );
        });
    }

    handleCancel(event){
        console.log('event'+event);
        util.fire('refreshPIs', this.recordId);
    }
    

    removeContacts(){
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: {
                url: '/apex/SC_AddAuthorizedContacts?policyDomainId=' + this.recordId+'&isDelete=True&fromPD=True'
            }
        }).then(vfURL => {
            window.open(vfURL,"_self");
        });
    }
    handlePicklistSelectionPopup(event){
        if(event.detail.PISel.length > 0){
            this.productInterestsSelected = event.detail.PISel.join(';');
            this.authConId = event.detail.ACId;
            this.conIdProdIntMap.set(this.authConId,this.productInterestsSelected);
            
            if(this.template.querySelector('c-sc-custom-datatable[data-id=mainTablePopupId]').draftValues.length > 0){
                //if(this.template.querySelector('c-sc-bulk-edit-a-c-table[data-id=mainTablePopupId]').draftValues.length > 0){
                this.draftValues.push({ 
                    Product_Interests__c: event.detail.PISel.join(';'),
                    Id: event.detail.ACId
                });
            }
            else if(this.draftValues.length === 0){
                this.draftValues = [{}];
                this.draftValues.push({ 
                    Product_Interests__c: event.detail.PISel.join(';'),
                    Id: event.detail.ACId
                });
                this.draftValues.shift();
            }
            else{
                let obj = this.draftValues.find((o, i) => {
                    if (o.Id === event.detail.ACId) {
                        this.draftValues[i] = { Id: event.detail.ACId, Product_Interests__c: event.detail.PISel.join(';')};
                        //return false; // stop searching
                    }
                    else{
                        this.draftValues.push({ 
                            Product_Interests__c: event.detail.PISel.join(';'),
                            Id: event.detail.ACId
                        });  
                    }
                });
                console.log('obj : '+obj);
            }
        }
    }
    handlePicklistSelection(event){
        if(event.detail.PISel.length > 0){
            this.productInterestsSelected = event.detail.PISel.join(';');
            this.authConId = event.detail.ACId;
            this.conIdProdIntMap.set(this.authConId,this.productInterestsSelected);
            if(this.template.querySelector('c-sc-custom-datatable').draftValues.length > 0){
                //if(this.template.querySelector('c-sc-bulk-edit-a-c-table').draftValues.length > 0){
                this.draftValues.push({ 
                    Product_Interests__c: event.detail.PISel.join(';'),
                    Id: event.detail.ACId
                });
            }
            else if(this.draftValues.length === 0){
                this.draftValues = [{}];
                this.draftValues.push({ 
                    Product_Interests__c: event.detail.PISel.join(';'),
                    Id: event.detail.ACId
                });
                this.draftValues.shift();
            }
            else{
                let obj = this.draftValues.find((o, i) => {
                    if (o.Id === event.detail.ACId) {
                        this.draftValues[i] = { Id: event.detail.ACId, Product_Interests__c: event.detail.PISel.join(';')};
                        //return false; // stop searching
                    }
                    else{
                        this.draftValues.push({ 
                            Product_Interests__c: event.detail.PISel.join(';'),
                            Id: event.detail.ACId
                        }); 
                    }
                });
                console.log('obj : '+obj);
            }
        }
    }

    handleRowAction(event){
        let actionName = event.detail.action.name;
        let rowId = event.detail.row.Id;
        this.showSpinner = true;
        if(actionName === 'edit')
        {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: rowId, // pass the record id here.
                    actionName: 'edit',
                },
            });
            this.showSpinner = false;
        }
        else if(actionName === 'delete')
        {
            deleteRecord(rowId)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Record deleted successfully',
                        variant: 'success'
                    })
                );
                this.refreshContacts();
            })
            .catch(error => {
                console.log(error);
            });
            this.showSpinner = false;
        }
    }

    refreshContacts(){
        util.fire('refreshPIs', this.recordId);
        this.showSpinner = true;
        if(this.contactData.length === 0){
            //this.contactPresent = false;
        }
        // Display fresh data in the datatable
        refreshApex(this.contact).then(() => {
            // Clear all draft values in the datatable
            this.draftValues = [];
            this.showSpinner = false;
        });
    }

    //Changes by Tejaswini for ESESP-4953
    
    closeModal() {
    this.showModal = false;
    this.refreshContacts();
    }

    showModalPopup() {

    this.showModal = true;
    }

    showRemovePopup(){
        this.showDeleteModal = true;
        
    }

    closeDeleteModal(){
    this.showDeleteModal = false;
    this.refreshContacts();
    }
}