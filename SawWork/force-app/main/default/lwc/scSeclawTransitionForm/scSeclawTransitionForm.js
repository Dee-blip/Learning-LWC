import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import USER_ID from '@salesforce/user/Id';
import USER_NAME from '@salesforce/schema/User.Name';

import GENERAL_INFORMATION from "@salesforce/schema/SecLaw_Transition_Form__c.General_Information__c";
import CONTENT_ON_AKAMAI from "@salesforce/schema/SecLaw_Transition_Form__c.Content_on_Akamai__c";
import AKAMAI_RELATED from "@salesforce/schema/SecLaw_Transition_Form__c.Akamai_related__c";
import REQUEST_TYPE from "@salesforce/schema/SecLaw_Transition_Form__c.Request_Type__c";
import ENOUGH_INFORMATION from "@salesforce/schema/SecLaw_Transition_Form__c.Enough_information__c";

import AKAM_CASE_ID from '@salesforce/schema/Case.AKAM_Case_ID__c';
import CONTACT_NAME from '@salesforce/schema/Case.Contact.Name';
import IS_CASE_CLOSED from '@salesforce/schema/Case.IsClosed';
import RECORD_TYPE_DEVELOPER_NAME from '@salesforce/schema/Case.RecordType.DeveloperName';

import transitionToSecLaw from '@salesforce/apex/SC_SecLawTransitionFormController.transitionToSecLaw';
import getSavedFormOnCase from '@salesforce/apex/SC_SecLawTransitionFormController.getSavedFormOnCase';
import getForm from '@salesforce/apex/SC_SecLawTransitionFormController.getForm';

export default class ScSeclawTransitionForm extends LightningElement {
    @api recordId;
    @api objectApiName;
    savedConfig = {
        General_Information__c: '',
        Content_on_Akamai__c: false,
        Akamai_related__c: false,
        Request_Type__c: '',
        Enough_information__c: false
    };
    firstLoad = true;
    showSpinner = true;
    showHighPrioritySection = false;
    showCPClaimQuestionnaireSection = false;
    showCPCodeSection = false;
    showOtherSection1 = false;
    showOtherSection2 = false;
    showAdditionalDetailsSection = false;
    showInformationForAnalysisSection = false;
    showAbuseDetailsSection = false;
    showResetConfirmation = false;
    showBottomDiv = false;
    showForm = false;
    showError = false;
    showFormCannotBeEditedError = false;
    volumetricDataFieldLabel = '';
    formId = '';
    caseId = '';
    @wire(getRecord, { recordId: '$formId', fields: [GENERAL_INFORMATION, CONTENT_ON_AKAMAI, AKAMAI_RELATED, REQUEST_TYPE, ENOUGH_INFORMATION] })
    saveConfig({ error, data }) {
        if (data) {
            this.savedConfig = { // save the configuration of the updated form
                General_Information__c: data.fields.General_Information__c.value,
                Content_on_Akamai__c: data.fields.Content_on_Akamai__c.value,
                Akamai_related__c: data.fields.Akamai_related__c.value,
                Request_Type__c: data.fields.Request_Type__c.value,
                Enough_information__c: data.fields.Enough_information__c.value
            };
        }
        else if (error) {
            console.log(error);
        }
    }
    @wire(getRecord, { recordId: '$caseId', fields: [AKAM_CASE_ID, CONTACT_NAME, IS_CASE_CLOSED, RECORD_TYPE_DEVELOPER_NAME] }) case;
    @wire(getRecord, { recordId: USER_ID, fields: [USER_NAME] }) user;

    get formDivClasses() {
        return 'form-div slds-clearfix slds-is-relative'
            // if on form record edit page, add box and theme for the form
            + (this.objectApiName === 'SecLaw_Transition_Form__c' ? ' slds-box slds-theme_default' : '')
            // if spinner is shown, add translate(0, 0) rule so that spinner background is rendered properly
            + (this.showSpinner ? ' form-div-fix-spinner' : '');
    }

    connectedCallback() {
        if (this.objectApiName === 'Case') {
            this.caseId = this.recordId;
            getSavedFormOnCase({ caseId: this.caseId }).then(config => {
                if (config) {
                    this.savedConfig = config;
                    this.displaySections(config);
                    this.formId = config.Id;
                }
            }).catch(error => {
                this.showSpinner = false;
                if (!(String(error.body?.message).startsWith('You do not have access to the Apex class'))) {
                    // this toast will not be displayed when the user is missing access to seclaw transition form,
                    // instead the error will be displayed in the lightning-messages element
                    this.displayToast('There was an error loading this form!', 'error', 'Please reload this page.');
                }
                console.log(JSON.stringify(error));
            });
        }
        else { // if this.objectApiName is 'SecLaw_Transition_Form__c'
            this.showBottomDiv = true; // add a small empty div at the bottom of the Edit page to prevent form buttons from being obscured by the utility bar
            getForm({ formId: this.recordId }).then(config => {
                if (config) {
                    if (config.Form_Status__c === 'Incomplete') {
                        this.savedConfig = config;
                        this.caseId = config.Case__c;
                        this.displaySections(config);
                        this.formId = config.Id;
                    }
                    else { // if the form has been submitted already, close the edit tab and open the form record page
                        this.showSpinner = false;
                        this.showFormCannotBeEditedError = true;
                        this.invokeWorkspaceAPI('isConsoleNavigation').then(isConsole => {
                            if (isConsole) {
                                this.invokeWorkspaceAPI('getFocusedTabInfo').then(editTab => {
                                    this.invokeWorkspaceAPI('openSubtab', {
                                        parentTabId: editTab.parentTabId,
                                        recordId: this.recordId,
                                        focus: true
                                    }).then(() => {
                                        this.invokeWorkspaceAPI('closeTab', {
                                            tabId: editTab.tabId
                                        });
                                    });
                                });
                            }
                        });
                    }
                }
            }).catch(error => {
                this.showSpinner = false;
                this.displayToast('There was an error loading this form!', 'error', 'Please reload this page.');
                console.log(JSON.stringify(error));
            });
        }
    }

    invokeWorkspaceAPI(methodName, methodArgs) {
        return new Promise((resolve, reject) => {
            const apiEvent = new CustomEvent('internalapievent', {
                bubbles: true,
                composed: true,
                cancelable: false,
                detail: {
                    category: 'workspaceAPI',
                    methodName: methodName,
                    methodArgs: methodArgs,
                    callback: (err, response) => {
                        if (err) {
                            return reject(err);
                        }
                        return resolve(response);
                    }
                }
            });
            window.dispatchEvent(apiEvent);
        });
    }

    async handleFormLoad() {
        if (this.firstLoad) {
            this.showSpinner = false;
            this.showForm = true;
            await new Promise(resolve => setTimeout(resolve, 100)); // wait for form to be rendered
            this.firstLoad = false;
        }
        if (this.firstSave) { // only hide spinner after saved form is loaded for the first time
            this.showSpinner = false;
            this.firstSave = false;
        }
    }

    handleSubmitButton(event) {
        this.showSpinner = true;
        this.submitType = event.target.dataset.type; // store the button (Save or Submit) that was clicked
        if (this.submitType === 'save') { // disable required field validation when form is being saved, so that form can be saved in any state
            this.template.querySelectorAll('lightning-input-field').forEach(field => {
                field.required = false;
            });
        }
        this.showSpinner = false;
    }

    handleFormSubmit(event) {
        event.preventDefault();
        this.showSpinner = true;
        if (getFieldValue(this.case.data, RECORD_TYPE_DEVELOPER_NAME) !== 'Technical') {
            this.displayToast('The Case Record Type must be Technical in order to save or submit this form', 'error');
            this.showSpinner = false;
            return;
        }
        getSavedFormOnCase({ caseId: this.caseId }).then(result => {
            if (!this.formId && result) {
                this.displayToast('There is an existing saved form on this case.', 'error', 'Please reload this page to load it.');
                this.showSpinner = false;
            }
            else if (this.submitType === 'save' && this.formId && !result) {
                this.displayToast('This form might have been submitted already.', 'error', 'Please reload this page.');
                this.showSpinner = false;
            }
            else {
                this.formData = JSON.parse(JSON.stringify(event.detail.fields));
                this.submitForm();
            }
        }).catch(error => {
            this.displayToast('There was an error processing this form.', 'error', 'Please reload this page.');
            this.showSpinner = false;
            console.log(JSON.stringify(error));
        });
    }

    submitForm() {
        if (this.formId) { // set fields that are not displayed on the form to null in the record
            if (!this.showCPCodeSection) {
                this.formData.CP_Code__c = null;
                this.formData.Content_Blocked_Removed__c = false;
                this.formData.Customer_informed_of_content_blocking__c = false;
                this.formData.Requestor_informed_of_case_handling__c = false;
            }
            if (!this.showCPClaimQuestionnaireSection) {
                this.formData.Content_on_Akamai__c = false;
            }
            if (!this.showOtherSection1) {
                this.formData.Akamai_related__c = false;
            }
            if (!this.showOtherSection2) {
                this.formData.URLs_IPs_and_connected_CP_code__c = null;
                this.formData.Connected_Account__c = null;
            }
            if (!this.showAdditionalDetailsSection) {
                this.formData.Request_Type__c = null;
                this.formData.reported_issue__c = null;
                this.formData.Complainant_is_informed__c = false;
                this.formData.What_is_required_from_SecLaw__c = null;
                this.formData.Enough_information__c = false;
                if (!this.showHighPrioritySection) {
                    this.formData.Steps_taken_so_far__c = null; // same field is used in different places for High Priority and Other
                }
            }
            if (!this.showInformationForAnalysisSection) {
                this.formData.Timeframe__c = null;
                this.formData.In_depth_description__c = null;
                this.formData.Volumetric_data_traffic_snippets_logs__c = null;
            }
            if (!this.showAbuseDetailsSection) {
                this.formData.Abuse_claim_attack_details__c = null;
            }
        }
        else { // if new form is being created
            this.formData.Case__c = this.caseId;
            this.formData.Name = `SecLaw Transition: ${getFieldValue(this.case.data, AKAM_CASE_ID)}`;
        }
        if (this.submitType === 'save') {
            this.formData.Form_Status__c = 'Incomplete';
            this.template.querySelector('lightning-record-edit-form').submit(this.formData);
            this.template.querySelectorAll('lightning-input-field[data-required="true"]').forEach(field => { // reenable required field validation after form is saved
                field.required = true;
            });
            return;
        }
        // if this.submitType is 'submit'
        if (getFieldValue(this.case.data, IS_CASE_CLOSED)) {
            this.displayFormMessage('Closed cases cannot be transferred to SecLaw.');
            this.showSpinner = false;
            return;
        }
        let requiredFieldsFilled = true;
        this.template.querySelectorAll('lightning-input-field[data-required="true"]').forEach(async field => {
            // for each required field, check if input is not just whitespace
            if (field.value.trim() === '' || (field.dataset?.fieldType === 'rich' && field.value.match(/^<p>\s+<\/p>$/))) {
                requiredFieldsFilled = false;
                field.scrollIntoView({ behavior: 'smooth', block: 'center', inline: 'nearest' });
                await new Promise(resolve => setTimeout(resolve, 200)); // wait for scrolling to complete
                this.showSpinner = false;
                this.displayToast(`Please complete the ${field.dataset.fieldLabel} field`, 'error');
                await new Promise(resolve => setTimeout(resolve, 100)); // wait for spinner to be hidden
                field.focus();
            }
        });
        if (!requiredFieldsFilled) {
            return;
        }
        this.subtype = '';
        this.severity = '';
        this.akamaiSpecificDetails = '';
        if (this.formData.General_Information__c === 'High Priority') {
            this.subtype = 'Subpoenas';
        }
        else if (this.formData.General_Information__c === 'CP Claim') {
            if (this.formData.Content_on_Akamai__c === false) {
                this.displayFormMessage('This case will not be transferred as the SecLaw team only handles Akamai related cases.');
                this.showSpinner = false;
                return;
            }
            this.subtype = 'CP Complaints';
            this.severity = '1';
        }
        else { // if this.formData.General_Information__c is 'Other'
            if (this.formData.Akamai_related__c === false) {
                this.displayFormMessage('This case will not be transferred as the SecLaw team only handles Akamai related cases.');
                this.showSpinner = false;
                return;
            }
            if (this.formData.Enough_information__c === false) {
                this.showInfoRequestTemplate1 = this.showInfoRequestTemplate2 = this.showInfoRequestTemplate3 = false;
                this.requestorName = getFieldValue(this.case.data, CONTACT_NAME) ?? '{requestor’s name}';
                this.akamCaseId = getFieldValue(this.case.data, AKAM_CASE_ID) ?? 'F-CS-{id number}';
                this.signature = getFieldValue(this.user.data, USER_NAME) ?? '{signature}';
                switch (this.formData.Request_Type__c) {
                    case 'Abuse Complaint':
                    case 'AUP Violation':
                        this.showInfoRequestTemplate1 = true;
                        break;
                    case 'Copyright and Trademark Complaint':
                    case 'Malware Complaint':
                    case 'Phishing Complaint':
                        this.showInfoRequestTemplate2 = true;
                        break;
                    case 'Other':
                        this.showInfoRequestTemplate3 = true;
                        break;
                    default:
                }
                this.displayFormMessage('', true); // template is rendered in html so that it can be copied
                this.showSpinner = false;
                return;
            }
            switch (this.formData.Request_Type__c) {
                case 'Abuse Complaint':
                    this.subtype = 'Abuse Complaints';
                    break;
                case 'AUP Violation':
                    this.subtype = 'AUP Violations';
                    break;
                case 'Copyright and Trademark Complaint':
                    this.subtype = 'Copyright and Trademark Complaints';
                    break;
                case 'Malware Complaint':
                    this.subtype = 'Malware Complaints';
                    break;
                case 'Phishing Complaint':
                    this.subtype = 'Phishing';
                    break;
                case 'Other':
                    this.subtype = 'Other';
                    break;
                default:
            }
            this.akamaiSpecificDetails = this.formData.URLs_IPs_and_connected_CP_code__c;
        }
        this.formData.Form_Status__c = 'Complete';
        this.template.querySelector('lightning-record-edit-form').submit(this.formData);
    }

    handleFormSuccess(event) {
        if (this.submitType === 'save') {
            if (this.errorOnSubmit) { // if form is being saved after case transition failure
                this.displayToast('The form has been saved.', 'info');
                this.errorOnSubmit = false;
            }
            else {
                this.displayToast('The form has been saved successfully!', 'info');
                this.openFormSubtab(event.detail.id);
            }
            if (this.formId) {
                this.showSpinner = false;
            }
            else { // if new form is being created
                this.firstSave = true;
                this.showSpinner = false;
                this.formId = event.detail.id;
                this.showSpinner = true;
            }
            this.submitType = '';
        }
        else { // if this.submitType is 'submit'
            transitionToSecLaw({ caseId: this.caseId, subtype: this.subtype, severity: this.severity, akamaiSpecificDetails: this.akamaiSpecificDetails }).then(async result => {
                if (result === 'success') {
                    this.displayToast('The case was successfully transitioned to SecLaw!', 'success', 'Reloading this page now...');
                    this.openFormSubtab(event.detail.id);
                    await new Promise(resolve => setTimeout(resolve, 3000)); // wait a bit for success toast to be seen by user
                    window.location.reload();
                }
                else if (result === 'not technical') {
                    this.displayToast('The Case Record Type must be Technical to submit this form.', 'error', 'Please reload this page.');
                    this.showSpinner = false;
                }
                this.submitType = '';
            }).catch(error => {
                this.displayToast('The case was not transitioned to SecLaw.', 'error', 'Please try again.');
                console.log(JSON.stringify(error));
                this.errorOnSubmit = true;
                // save the form with 'Incomplete' status if there was an error while transitioning the case
                this.submitType = 'save';
                this.formData.Form_Status__c = 'Incomplete';
                this.template.querySelector('lightning-record-edit-form').submit(this.formData);
                this.submitType = '';
            });
        }
    }

    handleFormError(event) {
        if (this.submitType === 'save') {
            this.displayToast('There was an error saving the form!', 'error');
        }
        else if (this.submitType === 'submit') {
            this.displayToast('There was an error submitting the form!', 'error');
        }
        else if (!this.firstLoad) {
            this.displayToast('There was an error displaying the form!', 'error', 'Please reload this page.');
        }
        this.showSpinner = false;
        this.submitType = '';
        console.log(JSON.stringify(event.detail));
    }

    handleFormChange() {
        this.showError = false;
    }

    async handleFormReset() {
        this.showError = false;
        this.template.querySelector('lightning-record-edit-form').scrollIntoView({ behavior: 'smooth', block: 'center', inline: 'nearest' });
        await new Promise(resolve => setTimeout(resolve, 200)); // wait for scrolling to complete
        this.showAbuseDetailsSection = false;
        this.showInformationForAnalysisSection = false;
        this.showAdditionalDetailsSection = false;
        this.showOtherSection2 = false;
        this.showOtherSection1 = false;
        this.showCPCodeSection = false;
        this.showCPClaimQuestionnaireSection = false;
        this.showHighPrioritySection = false;
        if (this.formId) { // if form is being reset to saved state
            await new Promise(resolve => setTimeout(resolve, 100)); // wait for all sections to be hidden
            this.displaySections(this.savedConfig);
        }
        this.template.querySelectorAll('lightning-input-field').forEach(async field => {
            field.reset();
            await new Promise(resolve => setTimeout(resolve, 100)); // wait for field to be reset before reporting validity
            if (field.value !== null) {
                field.reportValidity();
            }
            this.hideResetModal();
        });
    }

    showResetModal() {
        this.resetText = this.formId ? 'The contents of the form will be reset to the previously saved state!' : 'The contents of the form will be deleted!';
        this.showResetConfirmation = true;
    }

    hideResetModal() {
        this.showResetConfirmation = false;
    }

    displaySections(config) {
        this.showHighPrioritySection = config.General_Information__c === 'High Priority';
        this.showCPClaimQuestionnaireSection = config.General_Information__c === 'CP Claim';
        this.showCPCodeSection = this.showCPClaimQuestionnaireSection && config.Content_on_Akamai__c;
        this.showOtherSection1 = config.General_Information__c === 'Other';
        this.showOtherSection2 = this.showOtherSection1 && config.Akamai_related__c;
        this.showAdditionalDetailsSection = this.showOtherSection2;
        this.showInformationForAnalysisSection = this.showAdditionalDetailsSection && config.Enough_information__c;
        this.showAbuseDetailsSection = this.showInformationForAnalysisSection && config.Request_Type__c === 'Abuse Complaint';
        switch (config.Request_Type__c) {
            case 'Copyright and Trademark Complaint':
            case 'Malware Complaint':
            case 'Phishing Complaint':
                this.volumetricDataFieldLabel = 'Screenshots, volumetric data, traffic snippets or logs, forwarded email communication:';
                break;
            default:
                this.volumetricDataFieldLabel = 'Screenshots, volumetric data, traffic snippets or logs:';
        }
    }

    async displayFormMessage(message, notEnoughInfoError = false) {
        if (notEnoughInfoError) {
            this.showAdditionalInfoRequestTemplate = true;
        }
        else {
            this.showAdditionalInfoRequestTemplate = false;
            this.errorText = message;
        }
        this.showError = true;
        this.displayToast('The case was not transitioned to SecLaw', 'error');
        await new Promise(resolve => setTimeout(resolve, 100)); // wait for form error div to be rendered
        this.template.querySelector('.form-error').scrollIntoView({ behavior: 'smooth', block: 'center', inline: 'nearest' });
    }

    displayToast(title, variant, message = '') {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            variant: variant,
            message: message
        }));
    }

    handleConfigChange(event) {
        if ((event.target.fieldName === 'General_Information__c' || event.target.fieldName === 'Request_Type__c') && event.target.value) {
            event.target.reportValidity();
        }
        this.displaySections({
            General_Information__c: this.template.querySelector('lightning-input-field[data-field="gen_info"]').value,
            Content_on_Akamai__c: this.template.querySelector('lightning-input-field[data-field="content_on_akamai"]')?.value ?? this.savedConfig.Content_on_Akamai__c,
            Akamai_related__c: this.template.querySelector('lightning-input-field[data-field="akamai_related"]')?.value ?? this.savedConfig.Akamai_related__c,
            Request_Type__c: this.template.querySelector('lightning-input-field[data-field="request_type"]')?.value,
            Enough_information__c: this.template.querySelector('lightning-input-field[data-field="enough_info"]')?.value ?? this.savedConfig.Enough_information__c
        });
    }

    handleFieldChange(event) {
        if (event.target) {
            event.target.reportValidity();
        }
    }

    openFormSubtab(formId) {
        this.invokeWorkspaceAPI('isConsoleNavigation').then(isConsole => {
            if (isConsole) {
                this.invokeWorkspaceAPI('getFocusedTabInfo').then(currentTab => {
                    this.invokeWorkspaceAPI('openSubtab', {
                        parentTabId: currentTab.isSubtab ? currentTab.parentTabId : currentTab.tabId,
                        recordId: formId,
                        focus: true
                    });
                });
            }
        });
    }
}