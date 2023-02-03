import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

import GENERAL_INFORMATION from "@salesforce/schema/SecLaw_Transition_Form__c.General_Information__c";
import CONTENT_ON_AKAMAI from "@salesforce/schema/SecLaw_Transition_Form__c.Content_on_Akamai__c";
import AKAMAI_RELATED from "@salesforce/schema/SecLaw_Transition_Form__c.Akamai_related__c";
import REQUEST_TYPE from "@salesforce/schema/SecLaw_Transition_Form__c.Request_Type__c";
import ENOUGH_INFORMATION from "@salesforce/schema/SecLaw_Transition_Form__c.Enough_information__c";

export default class ScSeclawTransitionFormRecordPage extends LightningElement {
    @api recordId;
    showHighPrioritySection = false;
    showCPClaimQuestionnaireSection = false;
    showCPCodeSection = false;
    showOtherSection1 = false;
    showOtherSection2 = false;
    showAdditionalDetailsSection = false;
    showInformationForAnalysisSection = false;
    showAbuseDetailsSection = false;
    showSpinner = true;
    showForm = false;
    volumetricDataFieldLabel = '';

    @wire(getRecord, { recordId: '$recordId', fields: [GENERAL_INFORMATION, CONTENT_ON_AKAMAI, AKAMAI_RELATED, REQUEST_TYPE, ENOUGH_INFORMATION] })
    loadForm({ error, data }) {
        if (data) {
            this.showHighPrioritySection = data.fields.General_Information__c.value === 'High Priority';
            this.showCPClaimQuestionnaireSection = data.fields.General_Information__c.value === 'CP Claim';
            this.showCPCodeSection = this.showCPClaimQuestionnaireSection && data.fields.Content_on_Akamai__c.value;
            this.showOtherSection1 = data.fields.General_Information__c.value === 'Other';
            this.showOtherSection2 = this.showOtherSection1 && data.fields.Akamai_related__c.value;
            this.showAdditionalDetailsSection = this.showOtherSection2;
            this.showInformationForAnalysisSection = this.showAdditionalDetailsSection && data.fields.Enough_information__c.value;
            this.showAbuseDetailsSection = data.fields.Request_Type__c.value === 'Abuse Complaint';
            switch (data.fields.Request_Type__c.value) {
                case 'Copyright and Trademark Complaint':
                case 'Malware Complaint':
                case 'Phishing Complaint':
                    this.volumetricDataFieldLabel = 'Screenshots, volumetric data, traffic snippets or logs, forwarded email communication:';
                    break;
                default:
                    this.volumetricDataFieldLabel = 'Screenshots, volumetric data, traffic snippets or logs:';
            }
            this.showForm = true;
            this.showSpinner = false;
        }
        else if (error) {
            console.log(error);
        }
    }
}