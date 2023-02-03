import { LightningElement,track,api,wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import findRecords from "@salesforce/apex/SC_Jarvis_Case_Questionnaire_Controller.findLookupRecords";  
import getProblem from "@salesforce/apex/SC_Jarvis_Case_Questionnaire_Controller.getProblem";

import { getRecord } from 'lightning/uiRecordApi';
import PRODUCT_FIELD from '@salesforce/schema/Case_Questionnaire__c.Case_Product__c';
import PROBLEM_FIELD from '@salesforce/schema/Case_Questionnaire__c.Problem__c';
import OPTIONS_FIELD from '@salesforce/schema/Case_Questionnaire__c.Answer_Options__c';

export default class ScJarvisCaseQuestionnaire extends NavigationMixin(LightningElement)
{

    @api recordId;

    selectedProblem;
    selectedProduct;

    loadSpinner = false;
    modalClass = "slds-modal slds-modal_medium slds-fade-in-open";
    @track currentRecordsList=null;
    @track currentMessage='';
    @track currentError='';
    problems;
    nameClass='requiredClass';
    typeClass='requiredClass typeClass';
    optionClass = 'optionClass';
    problemClass='';
    applyErrorToProduct=false;
    optionRequired=false;
    problemRequired = false;
    disableSubmit = true;

    @wire(getRecord, { recordId: '$recordId', fields: [PRODUCT_FIELD,PROBLEM_FIELD,OPTIONS_FIELD] })
    wiredProject({ error, data }) {
        if (data) 
        {
            let record = data;
            this.selectedProduct = record.fields.Case_Product__c.value;
            this.optionRequired = record.fields.Answer_Options__c.value? true : false;
            if(record.fields.Problem__c.value)
            {
                this.selectedProblem = record.fields.Problem__c.value;
                this.getproblemFromProduct();                
            }            
        }
        else if(error)
        {
            console.log('Error: ' + error);
        } 
    }    

    getproblemFromProduct()
    {
        getProblem({productName : this.selectedProduct})
        .then((result) => 
        {  
            //console.log('result: ' + JSON.stringify(result));
            this.problems = result.options;
            this.problemRequired=this.problems.length > 0 ? true: false;
        })    
        .catch((error) => 
        {  
            console.log('error:' + JSON.stringify(error));
        });  

    }
    onProductSelection(e) 
    {
        this.selectedProduct = e.detail.selectedValue;
        this.selectedProblem = '';
        if(!this.selectedProduct)
        {
            this.problemRequired=false;
            return;
        }
        this.applyErrorToProduct = false;        
        //console.log('this.selectedProduct:' + this.selectedProduct);

        this.getproblemFromProduct();
    }

    onProblemChange(event)
    {
        this.selectedProblem = event.detail.value;
        if(this.selectedProblem)
        {
            this.problemClass = '';
        }
        //console.log('this.selectedProblem:' + this.selectedProblem);
    }
    handleSearch(event)
    {
        const queryString = event.detail.searchKey; 
        
        findRecords({ searchKey: queryString })  
        .then((result) => 
        {  
            //console.log('result: ' + JSON.stringify(result));
            if (result.length===0) 
            {  
                //console.log('length 0!!!' + result);
                this.currentRecordsList = [];  
                this.currentMessage = "No Records Found";  
            } 
            else 
            {                  
                //console.log('length 0!!!' + result);
                this.currentRecordsList = result;  
                this.currentMessage = "";  
            }  
            this.currentError = undefined;  
        })  
        .catch((error) => 
        {  
            this.currentError = error;  
            this.currentRecordsList = undefined;  
        });  
    }  

    removeErrorClass(event)
    {
        //console.log('Inside onchange');
        let fieldName = event.target.dataset.field; 
        let value = event.detail.value;

        //console.log('fieldName:' + fieldName);
        //console.log('value:' + value);
        if(!value)
        {
            if(fieldName === "Question_Type__c")
            {
                this.optionRequired = false;
            }
            return;
        }
        switch(fieldName) 
        {
            case "Question__c" :
                this.nameClass= 'requiredClass';
            break;
            case "Question_Type__c":
                this.typeClass='requiredClass typeClass';
                this.optionRequired = value === "Picklist" ? true: false;
                this.template.querySelector(".optionClass").value = '';
            break;
            case "Answer_Options__c":
                this.optionClass = 'optionClass';
            break;
            default:
                console.log('The Default use case');  
          }
    }
    validateForm()
    {
        let validForm = true;
        let element = this.template.querySelector(".typeClass");
        let typeValue = element.value;
        //console.log('typeValue: ' + typeValue);
        element = this.template.querySelector(".optionClass"); 
        let optionValue = element.value;
        //console.log('optionValue: ' + optionValue);
        if(typeValue === "Picklist" && !optionValue && !this.optionClass.includes("slds-has-error"))
        {
            validForm = false;
            //console.log('NULL option');
            this.optionClass += ' slds-has-error';
        }

        [...this.template.querySelectorAll('.requiredClass')].forEach(inputCmp =>{
            if(!inputCmp.value && inputCmp.dataset.field === "Question__c" && !this.nameClass.includes("slds-has-error"))
            {
                validForm = false;
                this.nameClass +=" slds-has-error";
            }
            if(!inputCmp.value && inputCmp.dataset.field === "Question_Type__c" &&  !this.typeClass.includes("slds-has-error"))
            {
                validForm = false;
                this.typeClass +=" slds-has-error";
            } 

        });
        if(!this.selectedProduct)
        {
            //console.log('this.applyErrorToProduct: ' + this.applyErrorToProduct);
            validForm = false;
            this.applyErrorToProduct = true;
        }
        if(!this.selectedProblem && this.problems && this.problems.length > 0)
        {
            validForm = false;
            this.problemClass = 'slds-has-error';
        }
        if(validForm)
        {
            this.loadSpinner = true;
            this.disableSubmit = false;
            //console.log('here!!! in Submit:'+this.disableSubmit);
            
            //this.template.querySelector("lightning-record-edit-form").submit();
            const btn = this.template.querySelector( ".hiddenButton" );

            if( btn )
            { 
                //console.log('Button: ' + btn);
                btn.click();
            }
            
            //console.log('after')
        }
        else
        {
            this.showToast('error','Please complete all the fields!','Error!','dismissible');
        }
    }

    submitMethod(event)
    {
        //console.log('this.disableSubmit: ' + this.disableSubmit);
        if(this.disableSubmit)
        {
            event.preventDefault();
        }
        //console.log('Here!!' + JSON.stringify(event.detail.fields));
    }

    handleSucess(event)
    {
        this.disableSubmit = true;
        const updatedRecord = event.detail.id;
        console.log('onsuccess: ', updatedRecord);   
        
        this.loadSpinner = false;
        let toastMessage = this.recordId? "Successfully Updated!" : "Successfully Created!";
        this.showToast('success',toastMessage,'Success!','dismissible');
        this.navigateToRecord(updatedRecord); 
    }

    handleError(event)
    {
        this.disableSubmit = true;
        this.loadSpinner = false;
        let errorVar = event.detail.output.fieldErrors? event.detail.output.fieldErrors : event.detail.error;

        this.showToast('error',errorVar,'Error!','dismissible');
        console.log('errorVar: ', errorVar);     
    }

    closeModal()
    {        
        if(this.recordId)
        {
            //console.log('HERE!!!' + this.recordId);
            this.navigateToRecord(this.recordId);
        }
        else
        {
            this.navigateToHome();
        }
        this.modalClass = "hidden";
    }

    navigateToHome()
    {
        var object = 'Case_Questionnaire__c';
        const closeclickedevt = new CustomEvent("closeclicked", {
            detail: { object }
          });
          // Fire the custom event
        this.dispatchEvent(closeclickedevt);

        this.modalClass = "hidden";
    }
    navigateToRecord(recordToNavigate)
    {
        var record = recordToNavigate;
        const closeclickedevt = new CustomEvent("closeclicked", {
            detail: { record }
          });
          // Fire the custom event
        this.dispatchEvent(closeclickedevt);

        this.modalClass = "hidden";             
    }

    get disableOptions()
    {
        return !this.optionRequired;
    }
    get disableProblem()
    {
        return !this.problemRequired;
    }

    showToast(variant,message,title,mode)
    {
        const event = new ShowToastEvent({
            "title": title,
            "message": message,
            "mode" : mode,
            "variant" : variant
        });
        this.dispatchEvent(event);        
    }
}