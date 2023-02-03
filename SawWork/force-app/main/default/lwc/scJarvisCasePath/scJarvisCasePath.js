/** @Date       :   Mar 23 2021
* @Author       :   Sumukh SS / Sharath P
* @Description  :   Case Detail Path
WARNING : THIS IS A CUSTOMER FACING COMPONENT. PLEASE PERFORM ALL CODE REVIEWS WITH REQUIRED TEAM MEMBERS BEFORE
DEPLOYING CODE TO PRODUCTION.
*/
import { LightningElement,api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import getLabelDetails from '@salesforce/apex/SC_Jarvis_Create_Case_Controller.getLabelDetails';
import mitigateCase from '@salesforce/apex/SC_Jarvis_Create_Case_Controller.mitigateCase';

import {LABELS} from './i18n.js'

import { loadStyle } from 'lightning/platformResourceLoader';
import staticStyleSheet from "@salesforce/resourceUrl/SC_Jarvis_Questionnaire_Stylesheet";

import {getRecord} from 'lightning/uiRecordApi';
import STATUS_FIELD from '@salesforce/schema/Case.Status';
import RECORDTYPE_FIELD from '@salesforce/schema/Case.RecordType.Name';
//ESESP-6568: added field to pass in function
import SUBTYPE_FIELD from '@salesforce/schema/Case.Sub_Type__c';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Sc_Community_JarvisCasePath extends NavigationMixin(LightningElement) {
    
    label= LABELS;
    @api recordId;
    recordTypeName;
    statusName;
    //ESESP-6568: variable for subtype and change in function
    subType;
    @wire(getRecord, { recordId: '$recordId', fields: [STATUS_FIELD, RECORDTYPE_FIELD, SUBTYPE_FIELD] })
    wiredAccount({ error, data }) {
        if (data) {
            this.recordTypeName = data.fields.RecordType.displayValue;
            this.statusName = data.fields.Status.displayValue;
            this.subType = data.fields.Sub_Type__c.displayValue;
            getLabelDetails ({
                labelvalues:this.label,
                caseid : this.recordId,
                recordTypeName : this.recordTypeName,
                preview : false,
                subType : this.subType
                
            }).then(result => {
                this.steps=result.lstofpathvalues;
                this.akamcaseid=result.akamcaseid;
                    this.subject=result.subject;
                
                    this.caseValues = result.caseValues;
                    this.currentStep=result.status;
                    this.displaytextmap=result.statusHelptextMap;
    
                    this.displaytext=result.statusHelptextMap[result.status];
                    this.statuscasefieldsMap=result.statusCaseValuesMap;
                    this.casefields=result.statusCaseValuesMap[result.status];
                    document.title = result.akamcaseid;
                    this.editAccess = result.editAccess;
                    this.cloneAccess = result.cloneAccess;
                    //this.description = result.description;

            }).catch(error1 => {
                console.log(JSON.stringify(error1));
            });
    
        } else if (error) {
            console.log('HERE: ' + JSON.stringify(error));
        }
    }
    caseRecord;
    
    
  
    currentStep;
    steps;
    displaytext;
    displaytextmap= new Map();
    casefields;
    statuscasefieldsMap = new Map();
    akamcaseid;
    subject;
    status;
    account;
    severity;
    owner;
    editAccess = false;
    cloneAccess = false;
    showCaseupdateModal = false;
    caseValues;
    loadSpinner = false;
    /*
    description;
    showDescriptionModal = false;
    */

    connectedCallback() {
        loadStyle(this, staticStyleSheet);        
    }

    selectedStep;
    handleStepFocus(e)
    {
        
        const stepIndex = e.detail.index;
        var indexValue = 0;
        var index;
        for(index = 0; index < this.steps.length; index++)
        {
            if(this.steps[index].value === this.currentStep)
            {
                indexValue = index;
            }
        }
        if(stepIndex <= indexValue)
        {
            const status = this.steps[stepIndex].value;
            this.selectedStep = this.steps[stepIndex];
            this.displaytext=this.displaytextmap[status];
            this.casefields=this.statuscasefieldsMap[status];    
        }
    }
    closeCaseUpdateModal()
    {
        this.showCaseupdateModal = false;
    }
    showCaseUpdate()
    {
        this.showCaseupdateModal = true;
    }

    handleNavigate() {
        this[NavigationMixin.Navigate]({
            type : 'standard__webPage',
            attributes: {
                url : '/customers/s/support?caseId='+this.recordId
            }
        });
    }    

    /*
    get brDescription()
    {
        return this.description && this.description.includes('\n')? 
        this.description.replaceAll('\n','<br/>'): this.description;
    }
    */
    get showMitigateOption() 
    {
        return this.recordTypeName === 'Technical' && this.editAccess && 
                !this.statusName.includes('Unassigned') && 
                !this.statusName.includes('Mitigated') && 
                !this.statusName.includes('Closed') ? true: false;

    }

    handleCustMitigate() 
    {
        this.loadSpinner = true;
        mitigateCase({caseId: this.recordId }).then(result => {
            this.loadSpinner = false;
            console.log('Mitigated ', result);
            const toastEv = new ShowToastEvent({
                title: this.label.ToastMitigated,
                message: this.label.ToastMessage,
                variant: 'success'
            });
            this.dispatchEvent(toastEv);
            //updateRecord({fields: this.recordId});
            window.location.reload();
        }).catch(error => {
            this.loadSpinner = false;
            console.log('Mitigated ', error);
        });
    }

    /*
    showDescription()
    {
        this.showDescriptionModal = true;
    }
    closeDescription()
    {
        this.showDescriptionModal = false;
    }
    */

}