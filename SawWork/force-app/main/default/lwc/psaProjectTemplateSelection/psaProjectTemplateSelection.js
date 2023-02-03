import { LightningElement, wire, track } from 'lwc';
import getProjectTemplates from '@salesforce/apex/PSA_ProjectCreationPageController.getProjectTemplates';
import { CurrentPageReference, NavigationMixin} from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Used to display colums with rows
const columns = [{
    label: 'PROJECT TEMPLATE',
    fieldName: 'Name',
    type: 'text',
    initialWidth: 500
},
{
    label: 'PLANNED HOURS',
    fieldName: 'pse__Planned_Hours__c',
    type: 'text',
    initialWidth: 170
},
{
    label: 'ACCOUNT',
    fieldName: 'accounturl',
    type: 'url',
    typeAttributes: {label: {fieldName: 'accountName'}, target: '_blank'}
},
{
    label: 'REGION',
    fieldName: 'regionurl',
    type: 'url',
    typeAttributes: {label: {fieldName: 'regionName'}, target: '_blank'}
},
{
    label: 'PRACTICE',
    fieldName: 'practiceurl',
    type: 'url',
    typeAttributes: {label: {fieldName: 'practiceName'}, target: '_blank'}
}
];


export default class Psa_ProjectCreationPageLWC extends NavigationMixin(LightningElement) {

    @track projects = [];
    @track allselectedRows = [];
    @track error;
    columns = columns;
    data1;
    @track searchkey = '';
    showCreatePage = false;
    selectedTemplateId = '';
    parentrecId = '';
    urlStateParameters = '';
    @track rowSelected = [];

    // Used to get the parent URL 
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {  
       if (currentPageReference) {
            let urlobject = {};    
            this.urlStateParameters = currentPageReference.state.inContextOfRef;
            let urlparam = this.urlStateParameters;
            let durl = urlparam.slice(2);
            let durlparse = JSON.parse(atob(durl));
            urlobject = durlparse;
            //let recIdval = urlobject["attributes"];
            this.parentrecId = urlobject.attributes.recordId;
            console.log('URL Parms in =>', this.parentrecId);
       }
    }

    // To fetch Project templates from Apex controller
    @wire(getProjectTemplates, { namesearch: '$searchkey'})
    wiredProjects({ error, data }) {
        if (data) {
            this._wiredResult = data; 
            this.projects = JSON.parse(JSON.stringify(data));
            this.projects.forEach(pro => {
                pro.accountName = pro.pse__Account__r.Name;
                pro.regionName = pro.pse__Region__r.Name;
                pro.practiceName = pro.pse__Practice__r.Name;
                pro.accounturl = '/'+pro.pse__Account__r.Id;
                pro.regionurl = '/'+pro.pse__Region__r.Id;
                pro.practiceurl = '/'+pro.pse__Practice__r.Id;
            });
        }
        else if (error) {
            this.error = error;
            this.projects = undefined;
            console.log('error :',error);
            const evt = new ShowToastEvent({
                title: 'Error!',
                message: 'Some unexpected error occured',
                variant: 'error',
                mode: 'dismissable',
                duration: 5000
            });
            this.dispatchEvent(evt);
        }
    }

    // Gets called on Row selection on Datatable
    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        for (let i = 0; i < selectedRows.length; i++) {
            this.selectedTemplateId = selectedRows[i].Id;
        }
    }

    // To handle filters on the page and call wiremethod
    handleFilter() {
        this.template.querySelector('lightning-datatable').selectedRows = [];
        let inputfilter = '';
        inputfilter =this.template.querySelector('lightning-input').value;
        this.searchkey = inputfilter;
    }

    // To clear the filter text
    handleClear() {
        this.searchkey = '';
        this.selectedTemplateId = '';
        this.template.querySelector('lightning-datatable').selectedRows = [];
    }

    // Used to hide parentCmp 
    handleselect(){
        if(this.selectedTemplateId !== ''){
            this.template.querySelector('.parentCmp').style.display = 'none';
            this.showCreatePage = true;
        }
    }

    // handles cancel action
    handlecancel(){
        let parentObj = 'Account';
        if (this.parentrecId.startsWith('006')){
            parentObj = 'Opportunity';
        }
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.parentrecId,
                objectApiName: parentObj,
                actionName: 'view'
            }
        });
    }
}