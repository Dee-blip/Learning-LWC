import { LightningElement, wire, api, track } from 'lwc';
import getProjectwrapper from '@salesforce/apex/PSA_ProjectCreationPageController.getProjectinfo'
import createRecord from '@salesforce/apex/PSA_ProjectCreationPageController.saveProject'
import { loadStyle } from 'lightning/platformResourceLoader';
import LightningCardCSS from '@salesforce/resourceUrl/PSA_PTSUStyles';
import { NavigationMixin} from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class PSA_CreateProjectPageLWC extends NavigationMixin(LightningElement) {

    @track columns = [
        { label: 'Resource Request Id', fieldName: 'Display_Name__c', type: 'text',hideDefaultActions: "true"},
        { label: 'Title', fieldName: 'pse__Notes__c', type: 'text',hideDefaultActions: "true"},
        { label: 'Requested Hours', fieldName: 'pse__SOW_Hours__c', type: 'number',hideDefaultActions: "true"},
        { label: 'Status', fieldName: 'pse__Status__c', type: 'text',hideDefaultActions: "true"},
        { label: 'Resource Name', fieldName: 'stafferResource', type: 'text',hideDefaultActions: "true"},
        { label: 'Start Date', fieldName: 'pse__Start_Date__c', type: 'date',hideDefaultActions: "true"},
        { label: 'End Date', fieldName: 'pse__End_Date__c', type: 'date',hideDefaultActions: "true"}
    ];

    data;
    error;
    project = {}
    milestone = {}
    tasks = {}
    @api tempid = '';
    @api parentid = '';
    showPCLIComponent = false;
    pcliValue = '';
    productValue = '';
    cliId = '';
    @track showSpinner = true;
    projectId = '';
    @track showRR = false;
    projName = '';
    completionDate = '';
    feeschedule = '';
    contractClosed = '';
    plannedhrs = '';
    recurringPlannedHrs = '';
    recurringBudgetAmt = '';
    budgetDescription = '';

    activeSections = ['A','B','C','D','E'];

    // This method will retrieve a Project record by cloning selected template 
    @wire(getProjectwrapper, {templateId: '$tempid', parentrecId: '$parentid'})
    wrapperList({ error, data }) {
        console.log('inside wire');
        if (data) {          
            this.data = JSON.parse(JSON.stringify(data));
            this.plannedhrs = this.data.prorec.pse__Planned_Hours__c;
            if(this.data.newResourceRequests.length >0 ){
                this.showRR = true;
                this.data.newResourceRequests.forEach(resreq => {
                    if(resreq.pse__Status__c  !== 'Ready to Staff'){
                        console.log('resreq inside=>',resreq.pse__Staffer_Resource__r.Name);
                        resreq.stafferResource = resreq.pse__Staffer_Resource__r.Name;
                    }
                });
            }

            Promise.all([
                loadStyle( this, LightningCardCSS )
                ]).then(() => {
                    console.log( 'Files loaded' );
                });
            console.log('Payload is',this.data);    
            this.showSpinner = false;
        }
        else if (error) {
            this.error = error;
            console.log('error :' + error);
            this.showSpinner = false;
        }
    }
    // This method calls CLI selection screen
    callCliScreen (){
        if(this.showPCLIComponent === false)
        {
            this.showPCLIComponent = true;
        } else if(this.showPCLIComponent === true)
        {
            this.showPCLIComponent = false;
        }       
    }

    handleoncloseEvent(event){
        console.log('handleoncloseEvent =>', JSON.stringify(event.detail));
        if(this.showPCLIComponent === false)
        {
            this.showPCLIComponent = true;
        } else if(this.showPCLIComponent === true)
        {
            this.showPCLIComponent = false;
        }
    }
    // This event maps CLI and Product details to psaProjectCreate cmp from CLI selection screen
    handleparentcloseEvent(event){
        this.cliId = event.detail.val1;
        let prodVal = event.detail.val2;
        let cliVal = event.detail.val3;

        if(prodVal !== this.productValue && prodVal !== ''){
            this.productValue = event.detail.val2;
        }

        if(cliVal !== this.pcliValue && cliVal !== ''){
            this.pcliValue = event.detail.val3;
        }
    }
    // This method will redirect the URL to parent Account/ Opportunity record
    handlecancel(){
        this.showSpinner = true;
        window.open( '/' + this.parentid, '_self' ); 
        this.showSpinner = false;
    }
    // Used to retain field values on error 
    handleNamechange (event){
        this.projName = event.target.value;
    }
    handlecompletionDatechange (event){
        this.completionDate = event.target.value;
    }
    handlefeeschedulechange (event){
        this.feeschedule = event.target.value;
    }
    handlecontractClosedchange (event){
        this.contractClosed = event.target.value;
    }
    handleplannedhrschange (event){
        this.plannedhrs = event.target.value;
    }
    handlerecurringPlannedHrschange (event){
        this.recurringPlannedHrs = event.target.value;
    }
    handlerecurringBudgetAmtchange (event){
        this.recurringBudgetAmt = event.target.value;
    }
    handlebudgetDescriptionchange (event){
        this.budgetDescription = event.target.value;
    }
    
    // This method creates Project and all its related records by reading field values and passing it to APEX for DML
    handlecreate(event) {
        let callApex = true;
        console.log('Spinner val is :', this.show);
        event.preventDefault();
        this.template.querySelectorAll('lightning-input-field').forEach(element => {
            if(!element.reportValidity()){
                console.log('report validity is false');
                callApex = false;            
            }
        });

        try{
            if(callApex){
                this.showSpinner = true;     
                let projectobj = {};
                let budgetobj = {};
                let taskobj = [];
                let milestoneobj = [];
                let selectedrow = [];

                let el = this.template.querySelector('lightning-datatable');
                // console.log('datatable values =>',el);
                if(el !== null){
                    selectedrow = el.getSelectedRows();
                    // console.log('selected datatable rows =>',selectedrow);
                }
                let projfields = this.template.querySelectorAll(`lightning-input-field[data-group=projfield]`);
                let budgetfields = this.template.querySelectorAll(`lightning-input-field[data-group=budgetfield]`);
        
                projfields.forEach(field => {
                    projectobj[field.fieldName] = field.value;
                });
        
                budgetfields.forEach(field => {
                    budgetobj[field.fieldName] = field.value;
                });
        
                this.data.milestonesrecs.forEach( mile =>{
                    console.log('Each Milestone rec =>',mile);
                    let milestonerec = {};
                    let milefields = this.template.querySelectorAll('lightning-input[data-group="'+mile.Id+'"]');
                    milefields.forEach(val =>{
                        // console.log('each field val in milestone =>',val.getAttribute("data-fieldapi"));
                        if (val.getAttribute("data-fieldapi") === 'Billable__c'){
                            milestonerec[val.getAttribute("data-fieldapi")] = val.checked;
                        }
                        else{
                            milestonerec[val.getAttribute("data-fieldapi")] = val.value;
                        }
                    });
                    milestoneobj.push(milestonerec);
                });
        
                this.data.taskrecs.forEach(task =>{
                    let singletaskrec = {};
                    let taskfields = this.template.querySelectorAll('lightning-input[data-group="'+task.Id+'"]');
                    taskfields.forEach(val =>{
                        if (val.getAttribute("data-fieldapi") === 'Billable__c'){
                            singletaskrec[val.getAttribute("data-fieldapi")] = val.checked;
                        }
                        else{
                            singletaskrec[val.getAttribute("data-fieldapi")] = val.value;
                        }
                    });
                    taskobj.push(singletaskrec);
                });
         
                let milestonestr = JSON.stringify(milestoneobj);
                let projstr  = JSON.stringify(projectobj);
                let budgetstr  = JSON.stringify(budgetobj);
                let taskstr  = JSON.stringify(taskobj);
                let resroucereqstr = JSON.stringify(selectedrow);

                console.log('complete milestonestr is ',milestonestr);
                // Used to create record by passing the input fields in JSON format
                createRecord({ projstr: projstr, budgetstr:budgetstr, milestonestr:milestonestr, taskstr: taskstr, parentrecId: this.parentid, cliId: this.cliId, resreq:resroucereqstr})
                    .then(result => {
                        this.projectId = result.Id;
                        console.log('this.projectId',result.Id);                       
                        const evt = new ShowToastEvent({
                            title: 'Success!',
                            message: 'The Record has been successfully created',
                            variant: 'success',
                            mode: 'dismissable',
                            duration: 5000
                        });
                        this.showSpinner = false;
                        window.open( '/' + this.projectId, '_self' ); 
                        this.dispatchEvent(evt);
                        // this.navigateToRecordPage();
                    })
                    .catch (error => {
                        console.log('Error message =>',error);
                        this.showSpinner = false;
                        let errorMsg = '';
                        let errorfieldErr = '';
                        let errorpageErr = '';
                        //this.projName = this.projNamebackup;
                        
                        if(error.body.fieldErrors){
                            errorfieldErr = JSON.parse(JSON.stringify(error.body.fieldErrors));
                        }
                        if(error.body.pageErrors){
                            errorpageErr = JSON.parse(JSON.stringify(error.body.pageErrors));
                        }

                        for(let key in errorfieldErr){
                            if(Object.prototype.hasOwnProperty.call(errorfieldErr, key)){
                                errorMsg += errorfieldErr[key][0].message+ '\n';
                            }
                        }

                        for(let key in errorpageErr){
                            if(Object.prototype.hasOwnProperty.call(errorpageErr, key)){
                                errorMsg += errorpageErr[key].message+ '\n';
                            }
                        }

                        if(error.body.message){
                            errorMsg += error.body.message+ '\n';
                        }
                        
                        if (errorMsg === '' || errorMsg === null) {
                            errorMsg = 'Some unexpected error';
                        }

                        console.log('error while saving',errorMsg);
                        const evt = new ShowToastEvent({
                            title: 'Error!',
                            message: errorMsg,
                            variant: 'error',
                            mode: 'dismissable',
                            duration: 9000
                        });
                        this.dispatchEvent(evt);
                    });
                }
        }
        catch(error){
            this.showSpinner = false;
            console.log('error =>', error);
        }
    }
    // To redirect to Record detail page on Save
    navigateToRecordPage() {
        console.log('Inside navigate method:',this.recordId);
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.projectId,
                objectApiName: 'pse__Proj__c',
                actionName: 'view'
            }
        });
    }
}