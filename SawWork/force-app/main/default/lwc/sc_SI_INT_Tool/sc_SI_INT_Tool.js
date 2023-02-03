import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent"
import { loadStyle } from 'lightning/platformResourceLoader';
import resourceName from '@salesforce/resourceUrl/SC_Akatec_LightningMigration';
import { NavigationMixin } from 'lightning/navigation';

import getTemplateNames from "@salesforce/apex/SC_SI_INT_Tool_Controller.getTemplateNames";
import saveMailer from "@salesforce/apex/SC_SI_INT_Tool_Controller.saveMailer";
import getMailerData from "@salesforce/apex/SC_SI_INT_Tool_Controller.getMailerData";
import saveFile from "@salesforce/apex/SC_SI_INT_Tool_Controller.saveFile";
import sendTestEmail from "@salesforce/apex/SC_SI_INT_Tool_Controller.sendTestEmail";
import fetchEmailBody from "@salesforce/apex/SC_SI_INT_Tool_Controller.fetchEmailBody";
import postMailer from "@salesforce/apex/SC_SI_INT_Tool_Controller.postMailer";
import getAccountsCount from "@salesforce/apex/SC_SI_INT_Tool_Controller.getAccountsCount";
import getEmailsCount from "@salesforce/apex/SC_SI_INT_Tool_Controller.getEmailsCount";
import downloadAsCSV from "@salesforce/apex/SC_SI_INT_Tool_Controller.downloadAsCSV";
import fetchReportId from "@salesforce/apex/SC_SI_INT_Tool_Controller.fetchReportId";
import emailProcessCount from "@salesforce/apex/SC_SI_INT_Tool_Controller.emailProcessCount";
import generateQueryString from "@salesforce/apex/SC_SI_INT_Tool_Helper.generateQueryString";
import checkInternalUsers from "@salesforce/apex/SC_SI_INT_Tool_Controller.checkInternalUsers";
import Id from '@salesforce/user/Id';



export default class Sc_SI_INT_Tool extends NavigationMixin(LightningElement) {

  userId = Id;
  // Form Variables
  recordFormData = {};
  content;
  templateBody = new Map();
  showSpinner = false;
  @api mailerId;
  savedMailerId;
  mailerExists;
  manualImport = false;
  mailerFilters = [];
  linkValue;
  showPeerSection = false;
  reviewer;
  filtersToRender = false;
  showMailerPreview = false;
  showSoccFieldOptions = false;
  showDefSoccFieldOptions = false;
  showSoccConditionOptions = false;
  showDefSoccConditionOptions = false;
  subjectEmail;
  contentEmail;
  showValue = true;
  testDiv = 1;
  fileLabel = 'Please'
  manualFileName;
  manualDownloadableLink;
  manualDownloadablFileName;
  showManualImport = true;
  show24Filters = true;
  //showAuthFilters=false;
  @track test = true;
  fieldValueTest;
  fieldValue;
  filterData = [];
  retainFilterValues = false;
  testFile;
  hideAuthFilter = true;
  mailerDataResult;
  isMailerValid = false;
  mailerName;
  manualEmaliAddresses;
  isCompleteMailervalid = false;
  isApproved = false;
  templateOptions = [];
  templateData;
  enableValueModal = false;
  inputIconRowIndex;
  inputValue;
  ownerId;

  //For Conditional Required and Disabled fields
  subjectRequired = false;
  contentRequired = false;
  disableFilterAttach = true;

  // Booleans to show fields based on the Inputs
  showAccounTypes = true;
  showCustomerGroups = true;
  showFilters = true;
  showNotificationRecipient = false;
  showEmailTextArea = true;
  showEmailInputTypes = false;

  //Default Values of the fields
  templateTypeValue = 'None';
  subjectValue = 'Akamai Notification';
  contactTypeValue = '24x7 Contact Types';
  accountTypeValue = ['Partner', 'Direct Customer', 'Indirect Customer'];
  customerGroupValue = 'Selected Customers';
  authCustomerGroupValue = 'Selected Customers';
  RecipientTypeValue = 'Emergency Notification Recipients';
  EmailInputValue = 'Enter Email Addresses';



  // Filter Variables
  newFilterNumber = 1;
  newAuthFilterNumber = 1;
  @track filters = [1];
  @track authFilters = [1];
  showFilterLogic = false;
  showAuthFilterLogic = false;
  @track fileName = '';
  attachedFiles = [];
  filesToUpload = [];
  manualFileToUpload = [];
  manuallyImportedFile;
  showAuthFilters = false;
  filterLogic;
  authFilterLogic;


  // For Number of Accounts and downloadable links
  totalAccountCount = 0;
  totalPolicyDomainCount = 0;
  totalEmailCount = 0;
  validEmailCount = 0;
  invalidEmailCount = 0;
  showDownload = false;
  showManualDownload = false;
  showPolicyDownload = false;

  // For Progress bar
  showProgressBar = false
  progress = 5000
  totalCount = 0;
  successCount = 0;
  failedCount = 0;
  completionPercentage = 0;
  mailerStatus = 'Calculating Total Email..'

  // To store reminder time
  reminderValue;

  @api
  myRecordId;





  get templateTypeOptions() {
    return this.templateOptions;
  }

  get radioOptions() {
    return [
      { label: '24x7 Contact Types', value: '24x7 Contact Types' },
      { label: 'Only Send To Manually Entered Email Addresses', value: 'Only Send To Manually Entered Email Addresses' },
      { label: 'Authorized Contacts', value: 'Authorized Contacts' },
    ];
  }
  get customerGroupOptions() {
    return [
      { label: 'All Customers', value: 'All Customers' },
      { label: 'Selected Customers', value: 'Selected Customers' },
    ];
  }

  get checkboxOptions() {
    return [
      { label: 'Partner', value: 'Partner' },
      { label: 'Direct Customer', value: 'Direct Customer' },
      { label: 'Indirect Customer', value: 'Indirect Customer' },
    ];
  }

  get RecipientOptions() {
    return [
      { label: 'Emergency Notification Recipients', value: 'Emergency Notification Recipients' },
      { label: 'Maintenance Notification Recipients', value: 'Maintenance Notification Recipients' },
    ];
  }

  get EmailInputOptions() {
    return [
      { label: 'Enter Email Addresses', value: 'Enter Email Addresses' },
      { label: 'Import Email Addresses', value: 'Import Email Addresses' },
    ];
  }

  get fieldOptions() {
    return [
      { label: 'None', value: 'None' },
      { label: 'Account Id', value: 'Account ID' },
      { label: 'Customer Name', value: 'Customer Name' },
      { label: 'Geography', value: 'Geography' },
      { label: 'Support Level', value: 'Support Level' },
      { label: 'Marketing Product Name', value: 'Marketing Product Name' },
    ];
  }

  get soccFieldOptions() {
    return [
      { label: 'None', value: 'None' },
      { label: 'Marketing Product Name', value: 'Marketing Product Name' },
      { label: 'Policy Domain Name', value: 'Policy Domain Name' }
    ];
  }

  get conditionOptions() {
    return [
      { label: 'None', value: 'None' },
      { label: 'Equal To', value: 'Equal To' },
      { label: 'Not Equal To', value: 'Not Equal To' },
      { label: 'Contains', value: 'Contains' },
      { label: 'Does Not Contain', value: 'Does Not Contain' },
      { label: 'In', value: 'In' },
    ];
  }
  get soccConditionOptions() {
    return [
      { label: 'None', value: 'None' },
      { label: 'Equal To', value: 'Equal To' },
      { label: 'Not Equal To', value: 'Not Equal To' },
      { label: 'In', value: 'In' },
    ];
  }

  get approvalStatusOptions() {
    return [
      { label: 'None', value: 'None' },
      { label: 'Approved', value: 'Approved' },
      { label: 'Not Approved', value: 'Not Approved' },
    ];
  }



  connectedCallback() {


    console.log('Mailer Id in Constructor//' + this.mailerId);
    loadStyle(this, resourceName + '/SC_Akatec_Lightning_Resource/SC_Akatec_Homepage.css')

    getTemplateNames({})
      .then(result => {
        this.templateData = result;
        this.templateOptions = [...this.templateOptions, { label: 'None', value: 'None' }];
        for (let key in result) {
          if (Object.prototype.hasOwnProperty.call(result, key)) {
            this.templateOptions = [...this.templateOptions, { label: key, value: key }];
          }
        }
      })
      .catch(error => {
        console.log('error//' + error)
        console.log('error//' + JSON.stringify(error))
      });

    // If the mailer exists prepopulate the mailer fields
    if (typeof this.mailerId !== 'undefined' && this.mailerId !== null) {

      this.mailerExists = true;
      getMailerData({ mailerId: this.mailerId })
        .then(result => {
          this.mailerDataResult = result;
          console.log('Result in Const//' + JSON.stringify(result));
          console.log('result.CMC_Mailer_Filters__r//' + JSON.stringify(result.CMC_Mailer_Filters__r));

          //Mailer Name for Report Parameter
          this.mailerName = result.Name;

          // OwnerId
          this.ownerId = result.OwnerId;

          // Adding Additional Filter Records
          if (result.CMC_Mailer_Filters__r !== null && typeof result.CMC_Mailer_Filters__r !== 'undefined') {
            this.mailerFilters = result.CMC_Mailer_Filters__r;
          }

          console.log('mailerFilters.length in constructor//' + this.mailerFilters.length);
          console.log('result.CMC_Filter_Logic__c//' + result.CMC_Filter_Logic__c)
          if (this.mailerFilters.length > 0) {
            if (result.CMC_24x7_Contact_Types__c === true) {
              this.newFilterNumber = this.mailerFilters.length;
              if (this.newFilterNumber > 1) {
                this.showFilterLogic = true
                this.filterLogic = result.CMC_Filter_Logic__c;
              }
            }
            else if (result.AuthCon_Authorized_Contacts__c === true) {
              this.newAuthFilterNumber = this.mailerFilters.length;
              if (this.newAuthFilterNumber > 1) {
                this.showAuthFilterLogic = true
                this.authFilterLogic = result.CMC_Filter_Logic__c;
              }
            }

            this.mailerFilters.forEach(eachFilter => {
              console.log('order no in constructor.' + eachFilter.CMC_Filter_Order__c)

              if (eachFilter.CMC_Filter_Order__c !== 1) {
                if (result.CMC_24x7_Contact_Types__c === true) {
                  this.filters.push(eachFilter.CMC_Filter_Order__c);
                }
                else if (result.AuthCon_Authorized_Contacts__c === true) {
                  this.authFilters.push(eachFilter.CMC_Filter_Order__c);
                }

              }
            });
            console.log('this.filters in const//' + this.filters)
          }


          // Template Name
          if (typeof result.CMC_Template_Name__c !== 'undefined') {
            this.templateTypeValue = result.CMC_Template_Name__c;
          }
          else {
            this.templateTypeValue = 'None'
          }

          // Subject
          this.subjectValue = result.CMC_Subject__c;

          // 24x7_Contact_Types
          if (result.CMC_24x7_Contact_Types__c === true) {
            this.contactTypeValue = '24x7 Contact Types';
            this.showAccounTypes = true;
            this.showCustomerGroups = true;
            this.showNotificationRecipient = false;
            this.showEmailInputTypes = false;
            this.showFilters = true;
            this.showAuthFilters = false;
            this.showManualDownload = false;
            this.showPolicyDownload = false;
            this.showSoccFieldOptions = false;
            this.showDefSoccFieldOptions = false;
            if (this.totalAccountCount > 0) {
              this.showDownload = true;
            }
          }
          // Authorized_Contacts
          if (result.AuthCon_Authorized_Contacts__c === true) {
            this.contactTypeValue = 'Authorized Contacts';
            this.showAccounTypes = false;
            this.showCustomerGroups = false;
            this.showNotificationRecipient = true;
            this.showEmailInputTypes = false;
            this.showFilters = false;
            this.showAuthFilters = false;
            this.showManualDownload = false;
            this.showDownload = false;
            this.showSoccFieldOptions = true;
            this.showDefSoccFieldOptions = true;
            if (this.totalPolicyDomainCount > 0) {
              this.showPolicyDownload = true;
            }
            this.reminderValue = result.Reminder__c;
          }
          // Manual Email Addresses
          //  if ((result.CMC_Manual_Email_Addresses__c !== '' && result.CMC_Manual_Email_Addresses__c !== 'undefined' && result.hasOwnProperty('CMC_Manual_Email_Addresses__c')) || (result.CMC_Imported_Emails_AttachmentId__c !== '' && result.CMC_Imported_Emails_AttachmentId__c !== 'undefined' && result.hasOwnProperty('CMC_Imported_Emails_AttachmentId__c'))) {
          if ((result.CMC_Manual_Email_Addresses__c !== '' && typeof result.CMC_Manual_Email_Addresses__c !== 'undefined') || (result.CMC_Imported_Emails_AttachmentId__c !== '' && typeof result.CMC_Imported_Emails_AttachmentId__c !== 'undefined')) {

            console.log('In Manual Const')
            this.contactTypeValue = 'Only Send To Manually Entered Email Addresses';

            this.showAccounTypes = false;
            this.showCustomerGroups = false;
            this.showNotificationRecipient = false;
            this.showEmailInputTypes = true;
            this.showFilters = false;
            this.showAuthFilters = false;
            this.showPolicyDownload = false;
            this.showDownload = false;
            this.showSoccFieldOptions = false;
            this.showDefSoccFieldOptions = false;
            if (this.totalEmailCount > 0) {
              this.showManualDownload = true;
            }
            //  if (result.CMC_Manual_Email_Addresses__c !== '' && result.CMC_Manual_Email_Addresses__c !== 'undefined' && result.hasOwnProperty('CMC_Manual_Email_Addresses__c')) {
            if (result.CMC_Manual_Email_Addresses__c !== '' && typeof result.CMC_Manual_Email_Addresses__c !== 'undefined') {

              this.EmailInputValue = 'Enter Email Addresses';
              this.showEmailTextArea = true
              console.log('result.CMC_Manual_Email_Addresses__c//' + result.CMC_Manual_Email_Addresses__c)
              this.manualEmaliAddresses = result.CMC_Manual_Email_Addresses__c;
              // let manualEmailInput = this.template.querySelector('[data-id="Manual"]');
              // manualEmailInput.value = result.CMC_Manual_Email_Addresses__c;
            }
            else {
              this.EmailInputValue = 'Import Email Addresses';
              this.showEmailTextArea = false;
              this.manualDownloadableLink = '/sfc/servlet.shepherd/document/download/' + result.CMC_Imported_Emails_AttachmentId__c;
              this.manualDownloadablFileName = result.Attachment_Name__c;
              this.showManualImport = false;
            }

          }
          // console.log('this.contactTypeValue//' + this.contactTypeValue)
          // For Account Types
          this.accountTypeValue = [];
          if (result.CMC_Partners__c === true)
            this.accountTypeValue.push('Partner');
          if (result.CMC_Direct_Customers__c === true)
            this.accountTypeValue.push('Direct Customer');
          if (result.CMC_Indirect_Customers__c === true)
            this.accountTypeValue.push('Indirect Customer');
          // console.log('this.accountTypeValue//' + this.accountTypeValue);

          // For Customer Groups
          if (result.CMC_Selected_Customers__c === true) {
            if (result.CMC_24x7_Contact_Types__c === true) {
              this.customerGroupValue = 'Selected Customers';
              this.showAuthFilters = false;
            }
            else if (result.AuthCon_Authorized_Contacts__c === true) {
              this.authCustomerGroupValue = 'Selected Customers';
              this.showFilters = false;
              this.showAuthFilters = true;
            }
          }

          if (result.CMC_All_Customers__c === true) {
            if (result.CMC_24x7_Contact_Types__c === true) {
              this.customerGroupValue = 'All Customers';
            }
            else if (result.AuthCon_Authorized_Contacts__c === true) {
              this.authCustomerGroupValue = 'All Customers';
            }

            this.showFilters = false;
            this.showAuthFilters = false;
          }

          // For Notification Recipients
          if (result.AuthCon_Emergency_Notification_Recipient__c === true)
            this.RecipientTypeValue = 'Emergency Notification Recipients';
          if (result.AuthCon_Maint_Notification_Recipient__c === true)
            this.RecipientTypeValue = 'Maintenance Notification Recipients';

          // Content
          console.log('content in constructor//' + result.EB_AdditionalIssueDescription__c)
          let contentData = this.template.querySelector('lightning-input-rich-text');
          console.log('contentData in constructor 2//' + contentData.value)
          this.content = result.EB_AdditionalIssueDescription__c;

          // SI Number
          let siNumber = this.template.querySelector('[data-id="siNumber"]');
          siNumber.value = result.CMC_IRAPT_SI_Number__c;

          //Is Approved
          this.isApproved = result.CMC_Is_Approved__c

          // Peer Review
          if (result.Peer_Review_Enabled__c === true) {
            this.showPeerSection = true;
            console.log('CMC_Peer_Reviewer__c//' + result.CMC_Peer_Reviewer__c)
            console.log('CMC_Approval_Status__c//' + result.CMC_Approval_Status__c)
            console.log('CMC_Reviewer_Comments__c//' + result.CMC_Reviewer_Comments__c)


            this.reviewer = result.CMC_Peer_Reviewer__c;


            // Approval Status
            if (result.CMC_Approval_Status__c !== 'undefined' && result.CMC_Approval_Status__c !== '' && result.CMC_Approval_Status__c !== null) {

              this.approvalStatusValue = result.CMC_Approval_Status__c;
            }

            // Approval Status
            if (result.CMC_Reviewer_Comments__c !== 'undefined' && result.CMC_Reviewer_Comments__c !== '' && result.CMC_Reviewer_Comments__c !== null) {

              this.approvalCommentValue = result.CMC_Reviewer_Comments__c;
            }

          }

          console.log('this.contacttypeValue in consttt//' + this.contactTypeValue)

          if (this.contactTypeValue !== 'Only Send To Manually Entered Email Addresses') {
            console.log('In contact type if');
            getAccountsCount({ mailerId: this.mailerId })
              .then(accountCountresult => {
                console.log('result of total accounts' + accountCountresult);
                if (this.contactTypeValue === '24x7 Contact Types') {
                  this.totalAccountCount = accountCountresult
                  this.showDownload = true;
                }
                else if (this.contactTypeValue === 'Authorized Contacts') {
                  this.totalPolicyDomainCount = accountCountresult
                  this.showPolicyDownload = true;
                }
              })
              .catch(error => {
                console.log('error//' + error);
                console.log('error//' + JSON.stringify(error));
              });
          }
          else {
            console.log('In contact type else');
            console.log('this.manualEmaliAddresses//' + this.manualEmaliAddresses)
            getEmailsCount({ rawEmailAddresses: this.manualEmaliAddresses, mailerId: this.mailerId })
              .then(emailCountresult => {
                console.log('emailCountresult of valid and invalid accounts//' + emailCountresult);
                this.totalEmailCount = emailCountresult[0];
                this.validEmailCount = emailCountresult[1];
                this.invalidEmailCount = emailCountresult[2];
                this.showManualDownload = true;

              })
              .catch(error => {
                console.log('error//' + error);
                console.log('error//' + JSON.stringify(error));
              })
          }

        })
        .catch(error => {
          console.log('error//' + error);
          console.log('error//' + JSON.stringify(error));

        });

    }
  }

  handleTemplateChange(event) {

    let changedTemplateName = event.detail.value
    console.log("changedTemplateName: " + changedTemplateName);
    if (changedTemplateName !== '' && changedTemplateName !== 'None') {
      this.subjectRequired = false;
      this.contentRequired = false;
    }
    else {
      this.subjectRequired = true;
      this.contentRequired = true;
    }
  }

  get contentData() {
    return this.content;
  }


  handleContactTypeChange(event) {
    this.contactTypeValue = event.detail.value;

    this.hideAuthFilter = false;


    console.log('contactType//' + this.contactTypeValue);
    if (this.contactTypeValue === '24x7 Contact Types') {
      this.showAccounTypes = true;
      this.showCustomerGroups = true;
      this.showNotificationRecipient = false;
      this.showEmailInputTypes = false;
      this.showAuthFilters = false;
      this.showManualDownload = false;
      this.showPolicyDownload = false;
      this.showSoccFieldOptions = false;
      this.showDefSoccFieldOptions = false;
      this.show24Filters = true;
      this.test = true;

      if (this.totalAccountCount > 0) {
        this.showDownload = true;
      }

      if (this.customerGroupValue === 'Selected Customers') {
        this.showFilters = true;
        for (let i = 0; i < this.newFilterNumber; i++) {
          let filtersToHide = this.template.querySelectorAll('[data-id="' + this.filters[i] + '"]');
          console.log('filtersToHide Length//' + filtersToHide.length);
          for (let j = 0; j < filtersToHide.length; j++) {
            filtersToHide[j].style.display = "inline-block"
          }
        }
      }

      for (let i = 0; i < this.newAuthFilterNumber; i++) {
        let filtersToHide = this.template.querySelectorAll('[data-auth="' + this.authFilters[i] + '"]');
        console.log('filtersToHide Length//' + filtersToHide.length);
        for (let j = 0; j < filtersToHide.length; j++) {
          filtersToHide[j].style.display = "none"
        }
      }



    }
    else if (this.contactTypeValue === 'Authorized Contacts') {

      this.showAccounTypes = false;
      this.showCustomerGroups = false;
      this.showNotificationRecipient = true;
      this.showEmailInputTypes = false;
      this.showManualDownload = false;
      this.showDownload = false;
      this.showSoccFieldOptions = true;
      this.showDefSoccFieldOptions = true;
      this.show24Filters = false;
      this.showFilters = false;
      this.test = false;
      if (this.totalPolicyDomainCount > 0) {
        this.showPolicyDownload = true;
      }

      if (this.authCustomerGroupValue === 'Selected Customers') {

        this.showAuthFilters = true;
        for (let i = 0; i < this.newAuthFilterNumber; i++) {
          let filtersToHide = this.template.querySelectorAll('[data-auth="' + this.authFilters[i] + '"]');
          console.log('filtersToHide Length//' + filtersToHide.length);
          for (let j = 0; j < filtersToHide.length; j++) {
            filtersToHide[j].style.display = "inline-block"
          }
        }
      }

      for (let i = 0; i < this.newFilterNumber; i++) {
        let filtersToHide = this.template.querySelectorAll('[data-id="' + this.filters[i] + '"]');
        console.log('filtersToHide Length//' + filtersToHide.length);
        for (let j = 0; j < filtersToHide.length; j++) {
          filtersToHide[j].style.display = "none"
        }
      }



    }
    else if (this.contactTypeValue === 'Only Send To Manually Entered Email Addresses') {
      this.showAccounTypes = false;
      this.showCustomerGroups = false;
      this.showNotificationRecipient = false;
      this.showEmailInputTypes = true;
      this.showFilters = false;
      this.showAuthFilters = false;
      this.showPolicyDownload = false;
      this.showDownload = false;
      this.showSoccFieldOptions = false;
      this.showDefSoccFieldOptions = false;
      if (this.totalEmailCount > 0) {
        this.showManualDownload = true;
      }

      this.manualFileName = ''


      for (let i = 0; i < this.newFilterNumber; i++) {
        let filtersToHide = this.template.querySelectorAll('[data-id="' + this.filters[i] + '"]');       
        for (let j = 0; j < filtersToHide.length; j++) {
          filtersToHide[j].style.display = "none"
        }
      }

      for (let i = 0; i < this.newAuthFilterNumber; i++) {
        let filtersToHide = this.template.querySelectorAll('[data-auth="' + this.authFilters[i] + '"]');
        for (let j = 0; j < filtersToHide.length; j++) {
          filtersToHide[j].style.display = "none"
        }
      }




      this.retainFilterValues = false;
    }

    this.filtersToRender = true;
  }

  handleGroupChange(event) {
    this.CustomerGroupValue = event.detail.value;

    this.hideAuthFilter = false;

    if (this.CustomerGroupValue === 'Selected Customers') {
      console.log('In If');
      this.showFilters = true;
      this.showAuthFilters = false;

      for (let i = 0; i < this.newFilterNumber; i++) {
        let filtersToHide = this.template.querySelectorAll('[data-id="' + this.filters[i] + '"]');
        for (let j = 0; j < filtersToHide.length; j++) {
          filtersToHide[j].style.display = "inline-block"
        }
      }

    }
    else {
      this.showFilters = false;
      this.showAuthFilters = false;
      this.showFilterLogic = false;
      this.showAuthFilterLogic = false;
      for (let i = 0; i < this.newFilterNumber; i++) {
        let filtersToHide = this.template.querySelectorAll('[data-id="' + this.filters[i] + '"]');
        for (let j = 0; j < filtersToHide.length; j++) {
          filtersToHide[j].style.display = "none"
        }
      }

      for (let i = 0; i < this.newAuthFilterNumber; i++) {
        let filtersToHide = this.template.querySelectorAll('[data-auth="' + this.authFilters[i] + '"]');
        for (let j = 0; j < filtersToHide.length; j++) {
          filtersToHide[j].style.display = "none"
        }
      }
    }

    this.filtersToRender = true;
  }


  handleAuthGroupChange(event) {
    this.authCustomerGroupValue = event.detail.value;
    this.hideAuthFilter = false;

    if (this.authCustomerGroupValue === 'Selected Customers') {
      this.showFilters = false;
      this.showAuthFilters = true;

      for (let i = 0; i < this.newAuthFilterNumber; i++) {
        let filtersToHide = this.template.querySelectorAll('[data-auth="' + this.authFilters[i] + '"]');
        for (let j = 0; j < filtersToHide.length; j++) {
          filtersToHide[j].style.display = "inline-block"
        }
      }
    }

    else {
      this.showFilters = false;
      this.showAuthFilters = false;
      for (let i = 0; i < this.newFilterNumber; i++) {
        let filtersToHide = this.template.querySelectorAll('[data-id="' + this.filters[i] + '"]');
        for (let j = 0; j < filtersToHide.length; j++) {
          filtersToHide[j].style.display = "none"
        }
      }

      for (let i = 0; i < this.newAuthFilterNumber; i++) {
        let filtersToHide = this.template.querySelectorAll('[data-auth="' + this.authFilters[i] + '"]');
        for (let j = 0; j < filtersToHide.length; j++) {
          filtersToHide[j].style.display = "none"
        }
      }
    }
    this.filtersToRender = true;
  }




  handleRecipientChange(event) {
    this.RecipientTypeValue = event.detail.value;
    this.filtersToRender = true;

  }

  handleEmailInputChange(event) {
    this.EmailInputValue = event.detail.value;
    if (this.EmailInputValue === 'Enter Email Addresses') {
      this.showEmailTextArea = true;
    }
    else {
      this.showEmailTextArea = false;
    }
  }
  handleManualEmailChange(event) {
    this.manualEmaliAddresses = event.detail.value;
  }

  handleFieldChange(event) {
    let fieldValue = event.detail.value;
    if (fieldValue === 'Marketing Product Name') {
      this.showDefSoccConditionOptions = true;
    }
    else {
      this.showDefSoccConditionOptions = false;
    }
    this.filtersToRender = true;
  }


  handleAuthFieldChange(event) {

    let fieldValue = event.target.value

    let filterRow = event.target.label;

    let filterRowData = this.template.querySelectorAll('[data-auth="' + this.filters[filterRow] + '"]');


    for (let i = 0; i < filterRowData.length; i++) {
      if (filterRowData[i].name === 'condition') {
        if (fieldValue === 'Marketing Product Name') {
          filterRowData[i].options = this.soccConditionOptions
        }
        else {
          filterRowData[i].options = this.conditionOptions;
        }
      }
    }
    this.filtersToRender = true;

  }



  handleConditionChange(event) {
    let conditionalOperator = event.detail.value;
    if (conditionalOperator === 'In') {
      this.disableFilterAttach = false;
    }
    else {
      this.disableFilterAttach = true;
    }
    this.filtersToRender = true;
  }

  handleAddedConditionChange(event) {

    let conditionValue = event.target.value;
    let filterRow = event.target.label;
    let filterRowData;

    if (this.contactTypeValue === '24x7 Contact Types') {
      filterRowData = this.template.querySelectorAll('[data-id="' + this.filters[filterRow] + '"]');
    }
    else if (this.contactTypeValue === 'Authorized Contacts') {
      filterRowData = this.template.querySelectorAll('[data-auth="' + this.authFilters[filterRow] + '"]');
    }


    for (let i = 0; i < filterRowData.length; i++) {
      if (filterRowData[i].name === 'filterAttachment' || filterRowData[i].name === 'valueIcon') {
        if (conditionValue === 'In') {
          filterRowData[i].disabled = false;
        }
        else {
          filterRowData[i].disabled = true;

        }
      }
      if (filterRowData[i].name === 'fileName') {
        if (conditionValue !== 'In') {
          filterRowData[i].value = '';
        }

      }
    }
    this.filtersToRender = true;

  }

  handleAuthConditionChange(event) {

    let conditionValue = event.target.value;
    let filterRow = event.target.label;
    let filterRowData = this.template.querySelectorAll('[data-auth="' + this.filters[filterRow] + '"]');

    for (let i = 0; i < filterRowData.length; i++) {
      if (filterRowData[i].name === 'filterAttachment') {
        if (conditionValue === 'In') {
          filterRowData[i].disabled = false;
        }
        else {
          filterRowData[i].disabled = true;
        }
      }
    }
    this.filtersToRender = true;

  }

  // To Display File Name
  handleManualFileChange(event) {
    if (event.target.files.length > 0) {
      this.manualFileName = event.target.files[0].name
    }

    if (!this.manualFileName.includes('.csv')) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Error!!',
          message: 'Please Choose only a .csv file',
          variant: 'Error',
        }),
      );
      this.manualFileName = '';

    }
    else if (event.target.files[0].size > '3003561') {
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Error!!',
          message: 'Maximum file size limit of 3 MB exceeded.',
          variant: 'Error',
        }),
      );
      this.manualFileName = '';

    }

  }

  addFilter() {

    let restrictAddition = false
    if (this.contactTypeValue === '24x7 Contact Types') {

      if (this.newFilterNumber === 9) {
        restrictAddition = true
      }
      else {
        this.newFilterNumber += 1;
        this.filters.push(this.newFilterNumber);
        this.showFilterLogic = true;
      }
    }
    else if (this.contactTypeValue === 'Authorized Contacts') {

      if (this.newAuthFilterNumber === 9) {
        restrictAddition = true
      }
      else {
        this.newAuthFilterNumber += 1;
        this.authFilters.push(this.newAuthFilterNumber);
        this.showAuthFilterLogic = true;
      }
    }
    if (restrictAddition) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Error!!',
          message: 'You cannot add more than 9 Filters',
          variant: 'Warning',
        }),
      );
    }

    this.filtersToRender = true;


  }

  removeFilter(event) {
    let filterRow;
    let filterNumber
    if (this.contactTypeValue === '24x7 Contact Types') {
      filterNumber = this.filters[event.target.value];
      filterRow = this.template.querySelectorAll('[data-id="' + filterNumber + '"]');
    }
    else if (this.contactTypeValue === 'Authorized Contacts') {
      filterNumber = this.authFilters[event.target.value];
      filterRow = this.template.querySelectorAll('[data-auth="' + filterNumber + '"]');
    }


    if (filterRow[0].disabled === true) {
      for (let i = 0; i < filterRow.length; i++) {
        filterRow[i].disabled = false;
        if (filterRow[i].name === 'downloadLink') {
          filterRow[i].value = '';
        }
        if (filterRow[i].name === 'removeButton') {
          filterRow[i].label = 'Remove'
          if (filterNumber === 1) {
            filterRow[i].disabled = true;
          }
        }
      }

    }

    // Else remove the filter row
    else {

      if (this.contactTypeValue === '24x7 Contact Types') {

        let removedFilterIndex = this.filters.indexOf(filterNumber);
        this.filters.splice(removedFilterIndex, 1);

        this.newFilterNumber -= 1;
        if (this.newFilterNumber === 1) {
          this.showFilterLogic = false;
        }
      }

      else if (this.contactTypeValue === 'Authorized Contacts') {

        let removedFilterIndex = this.authFilters.indexOf(filterNumber);
        this.authFilters.splice(removedFilterIndex, 1);
        this.newAuthFilterNumber -= 1;

        if (this.newAuthFilterNumber === 1) {
          this.showAuthFilterLogic = false;
        }
      }

      this.filtersToRender = true;

    }

  }

  handleFilterLogic(event) {
    this.filterLogic = event.detail.value.toUpperCase();
    this.filtersToRender = true;
  }

  handleAuthFilterLogic(event) {
    this.authFilterLogic = event.detail.value.toUpperCase();
    this.filtersToRender = true;
  }

  handleAddedFilterFileChange(event) {

    let filterRow = event.target.label;
    let filterFields;

    if (this.contactTypeValue === '24x7 Contact Types') {
      filterFields = this.template.querySelectorAll('[data-id="' + this.filters[filterRow] + '"]');
    }
    else if (this.contactTypeValue === 'Authorized Contacts') {
      filterFields = this.template.querySelectorAll('[data-auth="' + this.authFilters[filterRow] + '"]');
    }

    for (let i = 0; i < filterFields.length; i++) {
      if (filterFields[i].name === 'fileName') {
        filterFields[i].value = event.target.files[0].name;
        if (!filterFields[i].value.includes('.csv')) {
          this.dispatchEvent(
            new ShowToastEvent({
              title: 'Error!!',
              message: 'Please Choose only a .csv file',
              variant: 'Error',
            }),
          );
          filterFields[i].value = '';
        }
        else if (event.target.files[0].size > '3003561') {
          this.dispatchEvent(
            new ShowToastEvent({
              title: 'Error!!',
              message: 'Maximum file size limit of 3 MB exceeded.',
              variant: 'Error',
            }),
          );
          filterFields[i].value = '';
        }
      }
    }
  }

  removeManualImportedFile() {
    this.showManualImport = true;
    this.manualDownloadableLink = '';
    // this.
  }

  handleAccountTypeChange(event) {
    this.accountTypeValue = event.detail.value;
    this.filtersToRender = true;
  }

  /********************************** SAVE MAILER FUNCTIONALITY *******************************************************/

  async handleSave(event) {
    this.showSpinner = true;
    this.recordFormData = {};
    let finalFilterList = '';
    this.retainFilterValues = false;

    let fromSaveMailerButton = false
    let orderNumbers = [];


    if (typeof event !== 'undefined' && event.target.name === 'saveButton') {
      fromSaveMailerButton = true;
    }

    // Getting data from form
    const inputFields = this.template.querySelectorAll('lightning-input-field');
    if (inputFields) {
      inputFields.forEach(field => {
        this.recordFormData[field.fieldName] = field.value;
      }
      );
    }

    this.recordFormData.Is_Approved = this.isApproved;

    let contentData = this.template.querySelector('[data-id="content"]');
    if (typeof contentData.value !== 'undefined') {


      let contentDataValue = contentData.value;

      contentDataValue = contentDataValue.replaceAll('<p><br></p>', '<br>');
      contentDataValue = contentDataValue.replaceAll('</p><br>', '<br><br>');
      contentDataValue = contentDataValue.replaceAll('</p><p>', '<br>');
      contentDataValue = contentDataValue.replaceAll('<p>', '');
      contentDataValue = contentDataValue.replaceAll('</p>', '');


      this.recordFormData.Content = contentDataValue;

    }
    else {
      this.recordFormData.Content = '';
    }

    let subject = this.template.querySelector('[data-id="Subject"]');
    this.recordFormData.Subject = subject.value;

    let template = this.template.querySelector('[data-id="Template"]');
    this.recordFormData.Template = template.value;

    this.recordFormData.ContactType = this.contactTypeValue;


    // If Contact Type is 24x7 Contact Types
    if (this.contactTypeValue === '24x7 Contact Types') {
      let accountTypeValue = this.template.querySelector('[data-id="accountTypeValue"]');


      this.recordFormData.AccountType = accountTypeValue.value.toString();

      let customerGroupValue = this.template.querySelector('[data-id="customerGroupValue"]');
      this.recordFormData.CustomerGroupValue = customerGroupValue.value;

      if (this.showFilterLogic === true) {
        let filterLogic = this.template.querySelector('[data-id="filterLogic"]');
        this.recordFormData.FilterLogic = filterLogic.value;
      }


    }
    // If Contact Type is Manual
    else if (this.contactTypeValue === 'Only Send To Manually Entered Email Addresses') {

      let EmailInput = this.template.querySelector('[data-id="EmailInputValue"]');
      this.recordFormData.EmailInputValue = EmailInput.value;

      if (EmailInput.value === 'Enter Email Addresses') {
        let manualEmailInput = this.template.querySelector('[data-id="Manual"]');
        this.recordFormData.manualEmaliAddresses = manualEmailInput.value;
      }
      else {
        let manualFile = this.template.querySelectorAll('[data-id="manualImport"]')
        if (manualFile.length > 0 && manualFile[0].value !== null && manualFile[0].value !== '') {
          this.manuallyImportedFile = manualFile[0].files[0];
          this.manualImport = true;
        }
        else if (manualFile.length === 0 && typeof this.manualDownloadableLink !== 'undefined' && this.manualDownloadableLink !== '') {
          this.recordFormData.ManualAttachmentLink = this.manualDownloadableLink;
        }

      }

    }
    // If Contact Type is Authorized Contacts
    else if (this.contactTypeValue === 'Authorized Contacts') {
      let RecipientType = this.template.querySelector('[data-id="RecipientTypeValue"]');
      this.recordFormData.RecipientTypeValue = RecipientType.value;
      let customerGroupValue = this.template.querySelector('[data-id="customerAuthGroupValue"]');
      this.recordFormData.CustomerGroupValue = customerGroupValue.value;

      if (this.showAuthFilterLogic === true) {
        let filterLogic = this.template.querySelector('[data-id="authFilterLogic"]');
        this.recordFormData.FilterLogic = filterLogic.value;

      }
      // Reminder Value
      this.recordFormData.ReminderValue = this.reminderValue;
    }

    // Fetching Peer Review Data
    if (this.showPeerSection === true) {
      let reviewer = this.template.querySelector('[data-id="peerReviewer"]');
      if (reviewer.value !== '' && reviewer.value !== null && reviewer.value !== undefined)
        this.recordFormData.PeerReviewer = reviewer.value;

      let approvalStatus = this.template.querySelector('[data-id="approvalStatus"]');
      if (approvalStatus.value !== 'None' && approvalStatus.value !== '' && approvalStatus.value !== null && approvalStatus.value !== undefined)
        this.recordFormData.ApprovalStatus = approvalStatus.value;

      let approvalComments = this.template.querySelector('[data-id="approvalComments"]');
      if (approvalComments.value !== '' && approvalComments.value !== null && approvalComments.value !== undefined)
        this.recordFormData.ApprovalComments = approvalComments.value;
    }


    let filterFilesSize = 0;
    // If Contact Type is not Manual - For Filters
    if (this.contactTypeValue !== 'Only Send To Manually Entered Email Addresses') {

      if (this.recordFormData.CustomerGroupValue === 'Selected Customers') {
        // Filter Logic Starts
        this.attachedFiles = [];
        finalFilterList = '[{';

        // For the added filter rows

        let numberOfFilters;

        if (this.contactTypeValue === '24x7 Contact Types') {
          numberOfFilters = this.newFilterNumber;
        }
        else if (this.contactTypeValue === 'Authorized Contacts') {
          numberOfFilters = this.newAuthFilterNumber;
        }

        for (let i = 0; i < numberOfFilters; i++) {

          orderNumbers.push(parseFloat(i + 1));

          let addedfilterFields
          if (this.contactTypeValue === '24x7 Contact Types') {
            addedfilterFields = this.template.querySelectorAll('[data-id="' + this.filters[i] + '"]');
          }
          else if (this.contactTypeValue === 'Authorized Contacts') {
            addedfilterFields = this.template.querySelectorAll('[data-auth="' + this.authFilters[i] + '"]');
          }

          for (let j = 0; j < addedfilterFields.length; j++) {


            if (addedfilterFields[j].name === 'filterAttachment') {
              if (addedfilterFields[j].value !== null && addedfilterFields[j].value.length > 0) {
                this.attachedFiles.push({ 'Order': parseFloat(i + 1), 'File': addedfilterFields[j].files[0] });
                filterFilesSize += addedfilterFields[j].files[0].size
              }
            }

            else {

              finalFilterList += '"' + addedfilterFields[j].name + '" : "' + addedfilterFields[j].value + '",';
            }
            if (j === addedfilterFields.length - 1) {
              finalFilterList += '"Order":"' + parseFloat(i + 1) + '"},{';
            }

          }
          if (i === numberOfFilters - 1) {
            finalFilterList = finalFilterList.slice(0, -2);
            finalFilterList += ']';
          }
        }
        this.filtersToRender = true;

      }

    }


    let createdFilterData = {};
    this.filesToUpload = [];



    //Validate the form
    try {
      this.isMailerValid = await this.validateMailer(this.recordFormData, finalFilterList);
    }
    catch (error) {
    }

    let isFilterLogicValid = true;

    //  if(this.recordFormData.ContactType!=='Only Send To Manually Entered Email Addresses' && this.recordFormData.CustomerGroupValue ==='Selected Customers' && typeof this.recordFormData.FilterLogic !=='undefined' && this.recordFormData.FilterLogic.length>0)
    if (typeof this.recordFormData.FilterLogic !== 'undefined' && this.recordFormData.FilterLogic.length > 0) {
      isFilterLogicValid = this.checkFilterLogic(this.recordFormData.FilterLogic, orderNumbers)
    }

    this.isCompleteMailervalid = this.isMailerValid && isFilterLogicValid

    if (this.isCompleteMailervalid && filterFilesSize > '3003561') {
      this.showSpinner = false;
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Error!!',
          message: 'Maximum size of all the files selected should be upto 3 MB',
          variant: 'Error',
        }),
      );
    }

    else if (this.isMailerValid === true && isFilterLogicValid === true) {

      //  Calling Apex to save the mailer
      let saveMailerResult;
      try {
        saveMailerResult = await saveMailer({ mailerJSON: JSON.stringify(this.recordFormData), filterJSON: finalFilterList, mailerId: this.mailerId, peerReviewEnabled: this.showPeerSection, templateNameObjectMap: this.templateData });
        this.savedMailerId = saveMailerResult.Mailer_Id;
        if (fromSaveMailerButton === true) {
          console.log('fromSaveMailerButton in if//' + fromSaveMailerButton)
          this.dispatchEvent(
            new ShowToastEvent({
              title: 'Success!!',
              message: 'Mailer Saved Successfully!',
              variant: 'success',
            }),
          );
          if (typeof saveMailerResult.Success !== 'undefined') {
            if (this.recordFormData.ContactType !== 'Only Send To Manually Entered Email Addresses') {
              generateQueryString({ mailerId: this.savedMailerId })
                .then(res => {
                  console.log('res//' + res);
                  this.navigateToRecordEditPage();
                  this.showSpinner = false;
                })
                .catch(error => {
                  this.showSpinner = false;
                  console.log('error in 1//' + error)
                  console.log('error in 1//' + JSON.stringify(error))
                  console.log('error in 1//' + error.body.message)
                  //console.log('error in 1//' + JSON.stringify(error.body.message))
                  //console.log('error in 1//' + error.body)
                  this.dispatchEvent(
                    new ShowToastEvent({
                      title: 'Error!!',
                      message: error.body.message,
                      variant: 'error',
                    }),
                  );

                });
            }
            else {
              this.navigateToRecordEditPage();
              this.showSpinner = false;
            }


          }
        }

      }
      catch (error) {
        this.showSpinner = false;
        console.log('error in 2//' + error)
        console.log('error in 2//' + JSON.stringify(error));
      }



      if (this.manualImport === true) {

        if (this.manuallyImportedFile.size > 0 && this.savedMailerId.length > 0) {
          try {
            const importFileData = await this.readUploadedFile(this.manuallyImportedFile, this.savedMailerId)
            this.manualFileToUpload.push(...importFileData);
          } catch (e) {
            console.warn(e.message)
            console.log('e.message//' + e.message)
          }
        }
      }

      if (this.manualFileToUpload.length > 0) {
        this.saveToFile(this.manualFileToUpload, 'Mailer');
      }





      // Logic for Adding Attachments to the Filter Records
      console.log('this.attachedFiles length//' + this.attachedFiles.length)
      this.filtersToRender = true;
      if (this.attachedFiles.length > 0) {
        let excludeResults = ['Success', 'Mailer_Id', 'totalEmailCount', 'validEmailCount', 'invalidEmailCount', 'totalPolicyDomainCount', 'totalAccountCount'];
        for (let key in saveMailerResult) {
          // Preventing unexcepted data
          if (Object.prototype.hasOwnProperty.call(saveMailerResult, key) && !excludeResults.includes(key)) {
            createdFilterData[key] = saveMailerResult[key];
          }
        }



        for (let i = 0; i < this.attachedFiles.length; i++) {
          let file = this.attachedFiles[i].File;
          let filterId = createdFilterData[this.attachedFiles[i].Order];
          try {
            const fileData = this.readUploadedFile(file, filterId)
            this.filesToUpload.push(fileData);
            console.log('this.filesToUpload.size//' + this.filesToUpload.size)
            console.log('this.filesToUpload.length//' + this.filesToUpload.length)
          } catch (e) {
            console.warn(e.message)
            console.log('e.message in file pushing//' + e.message)
          }

        }


        Promise.all(this.filesToUpload)
          .then(files => {
            let filesToSave = [];
            files.forEach(eachFile => {
              filesToSave.push(...eachFile);

            });

            if (files.length > 0) {
              this.saveToFile(filesToSave, 'Filter');
            }
          })
          .catch(error => {
            console.log('erroerr//' + error)
            console.log('erroerr//' + JSON.stringify(error))
          })

      }
    }
    this.filtersToRender = true;
    console.log('this.filtersToRender after save//' + this.filtersToRender)

  }

  /****** File Reader function that returns a promise *****/
  readUploadedFile(file, filterId) {

    return new Promise((resolve, reject) => {
      let fileReader = new FileReader();
      let filesToUpload2 = [];
      // set onload function of FileReader object
      fileReader.onload = () => {

        let base64 = 'base64,';
        let content = fileReader.result.indexOf(base64) + base64.length;
        let fileContents = fileReader.result.substring(content);
        filesToUpload2.push({
          Title: file.name,
          VersionData: fileContents,
          parentId: filterId
        });
        resolve(filesToUpload2);
      }

      fileReader.onerror = function (error) {
        reject(error);
      }

      fileReader.readAsDataURL(file);
    })
  }



  // Calling apex class to insert the file
  saveToFile(filesToUpload, parentObject) {

    saveFile({ filesToInsert: filesToUpload, parentObject: parentObject })

      .then(result => {
        console.log('result ====> ' + result);
        if (this.recordFormData.ContactType !== 'Only Send To Manually Entered Email Addresses') {
          generateQueryString({ mailerId: this.savedMailerId })
            .then(res => {
              console.log('res//' + res);
              this.navigateToRecordEditPage();
              this.showSpinner = false;
            })
            .catch(error => {
              console.log('error//' + error)
            });
        }
        else {
          this.navigateToRecordEditPage();
          this.showSpinner = false;
        }

      })
      .catch(error => {
        // Showing errors if any while inserting the files
        console.log('error//' + error);
        console.log('error//' + error.body);
        console.log('error//' + JSON.stringify(error.body));
        console.log('error in saveeee//' + JSON.stringify(error));
        this.showSpinner = false;
        this.dispatchEvent(
          new ShowToastEvent({
            title: 'Error while uploading File. Maximum size limit of 3 MB exceeded.',
            message: error,
            variant: 'error',
          }),
        );
      });
  }

  navigateToRecordEditPage() {

    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: {
        recordId: this.savedMailerId,
        objectApiName: 'EB_AkaMailer__c',
        actionName: 'edit'
      }
    });
  }




  handleDownload(event) {
    let downloadContactType;
    let fileName;
    let rowData = new Set();
    let columnNames;
    if (this.contactTypeValue === '24x7 Contact Types') {
      downloadContactType = 'AccountDetails';
      fileName = 'AccountDetails.csv';
      rowData = ['AKAM_Account_ID__c', 'Name', 'Geography_Formula__c', 'Division_Formula__c', 'Division__c', 'Support_Level__c', 'Customer_Tier__c', 'Owner', 'Account_Status__c'];
      columnNames = ['Akam Account Id', 'Name', 'Geography', 'Division', 'Region', 'Support Level', 'Customer Tier', 'Account Owner', 'Account Status']

    }
    else if (this.contactTypeValue === 'Only Send To Manually Entered Email Addresses') {
      if (event.target.name === 'validEmails') {
        downloadContactType = 'ValidEmails';
        fileName = 'ValidEmails.csv';
      }
      else if (event.target.name === 'inavalidEmails') {
        downloadContactType = 'InvalidEmails';
        fileName = 'InvalidEmails.csv';
      }

      columnNames = [''];

    }
    else if (this.contactTypeValue === 'Authorized Contacts') {
      downloadContactType = 'PolicyDomainDetails';
      fileName = 'PolicyDomainDetails.csv';
      rowData = ['AKAM_Policy_Domain_ID__c', 'Name', 'Account_ID__c', 'Account_Name__r', 'Policy_Domain_State__c', 'Product__c', 'Service_Account__r']
      columnNames = ['AKAM Policy Domain ID', 'Policy Domain Name', 'AKAM Account ID', 'Account Name', 'Policy Domain State', 'Product', 'Service Account Name']
    }


    downloadAsCSV({ mailerID: this.mailerId, downloadType: downloadContactType })
      .then(result => {

        let csvData = JSON.parse(result);

        if (this.contactTypeValue === 'Only Send To Manually Entered Email Addresses') {
          csvData = csvData[0].toString();
          csvData = csvData.split(',')
        }

        // Download as CSV Logic

        let rowEnd = '\n';
        let csvString = '';



        if (this.contactTypeValue !== 'Only Send To Manually Entered Email Addresses') {
          // Array.from() method returns an Array object from any object with a length property or an iterable object.
          rowData = Array.from(rowData);

        }

        // splitting using ','
        csvString += columnNames.join(',');
        csvString += rowEnd;

        // main for loop to get the data based on key value
        for (let i = 0; i < csvData.length; i++) {
          let colValue = 0;

          if (this.contactTypeValue !== 'Only Send To Manually Entered Email Addresses') {

            // validating keys in data
            for (let key in rowData) {
              if (Object.prototype.hasOwnProperty.call(rowData, key)) {
                // Key value
                // Ex: Id, Name
                let rowKey = rowData[key];

                // add , after every value except the first.
                if (colValue > 0) {
                  csvString += ',';
                }
                let value;
                // If the column is undefined, it as blank in the CSV file.
                if (rowKey === 'Owner' || rowKey === 'Account_Name__r' || rowKey === 'Service_Account__r') {
                  value = csvData[i][rowKey] === undefined ? '' : csvData[i][rowKey].Name;
                }
                else {
                  value = csvData[i][rowKey] === undefined ? '' : csvData[i][rowKey];
                }

                csvString += '"' + value + '"';
                colValue++;
              }
            }
          }
          else {
            let emails = csvData[i] === undefined ? '' : csvData[i];
            csvString += '"' + emails + '"';
          }
          csvString += rowEnd;
        }

        // Creating anchor element to download
        let downloadElement = document.createElement('a');

        // This  encodeURI encodes special characters, except: , / ? : @ & = + $ # (Use encodeURIComponent() to encode these characters).
        downloadElement.href = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csvString);
        downloadElement.target = '_self';
        // CSV File Name
        downloadElement.download = fileName;
        // below statement is required if you are using firefox browser
        document.body.appendChild(downloadElement);
        // click() Javascript function to download CSV file
        downloadElement.click();


      })
      .catch(error => {
        console.log('error//' + error)
      })


  }




  handleSendTestEmail() {

    // promise to save the mailer and then send the test email with updated data
    let myPromise = new Promise((resolve) => {
      resolve(this.handleSave());
    })
    let superThis = this;
    myPromise.then(function () {

      if (superThis.isCompleteMailervalid) {

        sendTestEmail({ mailerId: superThis.mailerId })
          .then(result => {
            superThis.showSpinner = false
            if (result === 'Success') {
              superThis.dispatchEvent(
                new ShowToastEvent({
                  title: 'Success!!',
                  message: 'Test Email Sent Successfully!!!',
                  variant: 'success',
                }),
              );
              let peerReviewButton = superThis.template.querySelector('[data-id="peerReviewButton"]')
              peerReviewButton.disabled = false;
            }
          })
          .catch(error => {
            console.log('error//' + error)
            console.log('error//' + JSON.stringify(error))
            superThis.showSpinner = false
            superThis.dispatchEvent(
              new ShowToastEvent({
                title: 'Error!!',
                message: 'Logged in user should have a valid email and an associated contact',
                variant: 'Error',
              }),
            );

          });
      }
    });

  }

  handleErrorReport() {
    fetchReportId({})
      .then(result => {
        this[NavigationMixin.GenerateUrl]({
          type: 'standard__recordPage',
          attributes: {
            recordId: result,
            objectApiName: 'Report',
            actionName: 'view'
          },
          state: {
            fv0: this.mailerName,
          }
        }).then(url => { window.open(url) });
      })
      .catch(error => {
        console.log('error//' + error)
        console.log('error//' + JSON.stringify(error))
      })

  }

  handlePeerReview() {
    this.showPeerSection = true;
  }
  closePreviewModal() {
    this.showMailerPreview = false;
  }

  handlePreviewAndSendEmail() {
    // promise to save the mailer and then previe the updated mailer
    let myPromise = new Promise((resolve) => {
      resolve(this.handleSave());
    })
    let superThis = this;
    myPromise.then(function () {
      // this.handleSave()
      if (superThis.isCompleteMailervalid) {
        superThis.showMailerPreview = true;
        fetchEmailBody({ mailerId: superThis.mailerId })
          .then(result => {
            superThis.showSpinner = false;
            let emailData = JSON.parse(result);
            superThis.subjectEmail = emailData.subject;
            superThis.contentEmail = emailData.body;

          })
          .catch(error => {
            superThis.showSpinner = false;
            console.log('error in email preview//' + error);
            console.log('error in email preview//' + JSON.stringify(error));
          });
      }
    });


  }



  handleSendEmail() {
    //   this.handleSave();
    this.showSpinner = true;

    postMailer({ mailerId: this.mailerId, emailBody: this.contentEmail })
      .then(result => {
        console.log('result//' + result)
        this.showSpinner = false;
      })
      .catch(error => {
        this.showSpinner = false;
        console.log('error//' + error)
        console.log('error//' + JSON.stringify(error))
      });


    this.showMailerPreview = false;
    this.showProgressBar = true;


    this._interval = setInterval(() => {
      this.progress = this.progress + 5000;
      console.log('this.progress//' + this.progress);
      emailProcessCount({ mailerId: this.mailerId })
        .then(result => {
          let countResult = JSON.parse(result)
          console.log('completionPercentage //' + countResult.completionPercentage)
          console.log('successCount //' + countResult.successCount)
          this.totalCount = countResult.totalCount;
          this.successCount = countResult.successCount;
          this.failedCount = countResult.failureCount;
          this.completionPercentage = countResult.completionPercentage;
          this.mailerStatus = countResult.mailerStatus;

          let x = this.template.querySelector(".progressBar");
          if (this.completionPercentage <= 100) {
            x.style.width = this.completionPercentage + "%";
          }
          else {
            x.style.width = "100%"
          }

        })
        .catch(error => {
          console.log('error//' + error)
          console.log('error//' + JSON.stringify(error))

        });
      if (this.completionPercentage >= 100) {
        clearInterval(this._interval);
        this[NavigationMixin.Navigate]({
          type: 'standard__recordPage',
          attributes: {
            recordId: this.mailerId,
            objectApiName: 'EB_AkaMailer__c',
            actionName: 'view'
          }
        })

      }
    }, this.progress);

  }



  async validateMailer(recordFormData, finalFilterList) {
    let d = new Date();
    let currentDT = d.toISOString();

    let filterList;
    if (finalFilterList.length > 0) {
      filterList = JSON.parse(finalFilterList);
    }
    let validMailer = false

    if (recordFormData.Content === '') {
      this.showSpinner = false;
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Error!!',
          message: 'Please Add the Content.',
          variant: 'error',
        }),
      );
    }
    else if ((recordFormData.Template === '' || recordFormData.Template === 'None' || typeof recordFormData.Template === 'undefined') && recordFormData.Subject === '') {
      this.showSpinner = false;
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Error!!',
          message: 'Subject is mandatory when no template is selected.',
          variant: 'error',
        }),
      );
    }
    else if (recordFormData.Subject !== '' && recordFormData.Subject.length < 8) {

      this.showSpinner = false;
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Error!!',
          message: 'Subject should be minimum 8 character long.',
          variant: 'error',
        }),
      );

    }
    else if (this.reminderValue != null && recordFormData.ReminderValue <= currentDT) {
      this.showSpinner = false;
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Error!!',
          message: 'Selected Reminder should not be before or same as the current date time',
          variant: 'error',
        }),
      );
    }
    else if (typeof recordFormData.PeerReviewer === 'undefined' && this.showPeerSection) {
      this.showSpinner = false;
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Error!!',
          message: 'Please add a reviewer.',
          variant: 'error',
        }),
      );
    }
    else if (typeof recordFormData.PeerReviewer !== 'undefined' && this.userId === this.ownerId && recordFormData.PeerReviewer.toString() === this.userId) {
      this.showSpinner = false;
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Error!!',
          message: 'You cannot add yourself as a reviewer',
          variant: 'error',
        }),
      );
    }


    else if (typeof recordFormData.PeerReviewer !== "undefined" && recordFormData.PeerReviewer.toString() !== this.userId) {
      try {
        let isInternalUser = await checkInternalUsers({
          userId: recordFormData.PeerReviewer.toString()
        })
        if (isInternalUser === false) {
          this.showSpinner = false;
          this.dispatchEvent(
            new ShowToastEvent({
              title: "Error!!",
              message: "You cannot add an external User as a reviewer",
              variant: "error"
            })
          );
        } else {
          validMailer = true;
        }
      } catch (error) {
        console.log('error in checkInternalUsers//' + error);
      }

      this.filtersToRender = true;
    }
    else {
      validMailer = true;
    }



    if (recordFormData.ContactType === '24x7 Contact Types' && recordFormData.AccountType === '') {
      this.showSpinner = false;
      validMailer = false;
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Error!!',
          message: 'No Option selected under section "Send Notification To".Please select atleast one option.',
          variant: 'error',
        }),
      );
    }
    else if (recordFormData.ContactType === 'Only Send To Manually Entered Email Addresses' && recordFormData.EmailInputValue === 'Enter Email Addresses' && (typeof recordFormData.manualEmaliAddresses === 'undefined') || recordFormData.manualEmaliAddresses === '') {
      this.showSpinner = false;
      validMailer = false;
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Error!!',
          message: 'Email TextArea is empty',
          variant: 'error',
        }),
      );
    }

    else if (recordFormData.ContactType === 'Only Send To Manually Entered Email Addresses' && recordFormData.EmailInputValue === 'Import Email Addresses' && ((typeof this.manualFileName === 'undefined' || this.manualFileName === '') && (typeof this.manualDownloadableLink === 'undefined' || this.manualDownloadableLink === ''))) {
      this.showSpinner = false;
      validMailer = false;
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Error!!',
          message: 'Please choose a .csv file.',
          variant: 'error',
        }),
      );
    }

    if (typeof filterList !== 'undefined' && recordFormData.CustomerGroupValue === 'Selected Customers') {

      for (let i = 0; i < filterList.length; i++) {

        if ((filterList[i].field === 'undefined' || filterList[i].field === 'None') && (filterList[i].condition === 'undefined' || filterList[i].condition === 'None') && filterList[i].filterValue === ''
          && filterList[i].fileName === '' && (filterList[i].downloadLink === 'undefined' || filterList[i].downloadLink !== '')) {

          if (filterList[i].Order === '1') {
            validMailer = false;
            this.showSpinner = false;
            this.dispatchEvent(
              new ShowToastEvent({
                title: 'Error!!',
                message: 'First filter can not be Empty. Please populate the first filter to save',
                variant: 'error',
              }),
            );
          }
          else {
            validMailer = false;
            this.showSpinner = false;
            this.dispatchEvent(
              new ShowToastEvent({
                title: 'Error!!',
                message: 'Please remove the filter row which is not required',
                variant: 'error',
              }),
            );
          }
        }
        if (((filterList[i].field === 'undefined' || filterList[i].field === 'None') && ((filterList[i].condition !== 'undefined' && filterList[i].condition !== 'None') || filterList[i].filterValue !== ''
          || filterList[i].fileName !== '' || (filterList[i].downloadLink !== 'undefined' && filterList[i].downloadLink !== ''))) ||

          ((filterList[i].condition === 'undefined' || filterList[i].condition === 'None') && ((filterList[i].field !== 'undefined' && filterList[i].field !== 'None') || filterList[i].filterValue !== ''
            || filterList[i].fileName !== '' || (filterList[i].downloadLink !== 'undefined' && filterList[i].downloadLink !== ''))) ||

          (filterList[i].filterValue === '' && filterList[i].fileName === '' && (filterList[i].downloadLink === 'undefined' || filterList[i].downloadLink === '')
            && ((filterList[i].field !== 'undefined' && filterList[i].field !== 'None') || (filterList[i].condition !== 'undefined' && filterList[i].condition !== 'None')))

        ) {
          validMailer = false;
          this.showSpinner = false;
          this.dispatchEvent(
            new ShowToastEvent({
              title: 'Error!!',
              message: 'Filter Criteria is invalid. Please Populate all the fields for the filter row: ' + filterList[i].Order,
              variant: 'error',
            }),
          );
        }

        if ((filterList[i].field !== 'undefined' && filterList[i].field !== 'None') && ((filterList[i].condition !== 'undefined' && filterList[i].condition !== 'None' && filterList[i].condition === 'In')
          && filterList[i].filterValue !== '' && filterList[i].fileName !== '')) {
          validMailer = false;
          this.showSpinner = false;
          this.dispatchEvent(
            new ShowToastEvent({
              title: 'Error!!',
              message: 'You can either enter a value or import file for the filter row: ' + filterList[i].Order,
              variant: 'error',
            }),
          );
        }
        if (filterList[i].filterValue.length > 255) {
          validMailer = false;
          this.showSpinner = false;
          this.dispatchEvent(
            new ShowToastEvent({
              title: 'Error!!',
              message: 'You cannot add Value more than 255 characters for the filter row: ' + filterList[i].Order,
              variant: 'error',
            }),
          );
        }

      }
    }

    console.log('validMailer//' + validMailer)
    return validMailer;


  }

  handleReviewerChange(event) {

    if (event.detail.value.toString() === this.userId && this.userId === this.ownerId) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Error!!',
          message: 'You cannot add yourself as a reviewer',
          variant: 'error',
        }),
      );

    }
  }


  // function to check if filter logic is valid
  checkFilterLogic(filterLogicStringVal, filterOrderValArray) {
    let result = false;
    let filterLogicInput = filterLogicStringVal.toUpperCase();
    if (filterLogicInput !== "") {
      let filterString = filterLogicInput;
      result = this.parse(filterString, filterOrderValArray);
    }
    return result;
  }


  //Building RegEx for Filter Logic to accept only valid characters and format
  tokenize(code) {
    let results = [];
    let tokenRegExp = /\s*([A-Za-z]+|[0-9]+|\S)\s*/g;
    let m;
    while ((m = tokenRegExp.exec(code)) !== null)
      results.push(m[1]);
    return results;
  }

  parse(code, filterOrderValArray) {
    let superThis = this;
    let isValidLogic = false;
    let filterCountFlag = false;
    for (let i = 0, len = filterOrderValArray.length; i < len; i++) {
      if (code.indexOf(filterOrderValArray[i]) < 0) {
        filterCountFlag = true;
      }
    }
    if (filterCountFlag) {
      //display error message
      this.showSpinner = false;
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Error!!',
          message: 'Filter Logic Expression is not valid. Please include all filters',
          variant: 'error',
        }),
      );
      return false;
    }
    let tokens = this.tokenize(code);
    let position = 0;
    let isErroredCount = false;

    function isNumber(token, filterOrderValArr) {
      let validNumberMin = filterOrderValArr[0]; // Check
      let ValidNumberMax = filterOrderValArr[filterOrderValArr.length - 1]; // Check
      let regexToken = new RegExp("^[" + validNumberMin.toString() + "-" + ValidNumberMax.toString() + "]$");
      return token !== undefined && token.match(regexToken) !== null;
    }

    function parsePrimaryExpr() {
      let t = tokens[position];
      let returnValue;
      if (isNumber(t, filterOrderValArray)) {
        position++;
        returnValue = { type: "number", value: t };
      }
      else if (t === "(") {
        position++;
        returnValue = parseExpr();

        if (tokens[position] !== ")") {
          if (isErroredCount === false) {
            isErroredCount = true;
            superThis.showSpinner = false;
            superThis.dispatchEvent(
              new ShowToastEvent({
                title: 'Error!!',
                message: 'Filter Logic Expression is not valid. Expecting ")"',
                variant: 'error',
              }),
            );
          }
        }
        position++;

      }
      else {
        if (isErroredCount === false) {
          isErroredCount = true;
          superThis.showSpinner = false;
          superThis.dispatchEvent(
            new ShowToastEvent({
              title: 'Error!!',
              message: 'Filter Logic Expression is not valid',
              variant: 'error',
            }),
          );
        }
      }
      return returnValue;
    }

    function parseMulExpr() {
      let expr = parsePrimaryExpr();
      let t = tokens[position];
      while (t === "AND") {
        position++;
        let rhs = parsePrimaryExpr();
        expr = { type: t, left: expr, right: rhs };
        t = tokens[position];
      }
      return expr;
    }

    function parseExpr() {
      let expr = parseMulExpr();
      let t = tokens[position];
      while (t === "OR") {
        position++;
        let rhs = parseMulExpr();
        expr = { type: t, left: expr, right: rhs };
        t = tokens[position];
      }
      return expr;
    }

    parseExpr();

    if (position !== tokens.length) {
      if (isErroredCount === false) {
        this.showSpinner = false;
        this.dispatchEvent(
          new ShowToastEvent({
            title: 'Error!!',
            message: 'Filter Logic Expression is not valid',
            variant: 'error',
          }),
        );
      }
    }
    else {
      if (isErroredCount === false) {
        isValidLogic = true;
      }
    }
    return isValidLogic;
  }


  handleValueModal(event) {
    this.enableValueModal = true;
    this.inputIconRowIndex = event.target.title;
    let inputFilterRow;
    if (this.contactTypeValue === "24x7 Contact Types") {
      inputFilterRow = this.template.querySelectorAll('[data-id="' + this.filters[this.inputIconRowIndex] + '"]');
    }
    else if (this.contactTypeValue === "Authorized Contacts") {
      inputFilterRow = this.template.querySelectorAll('[data-auth="' + this.filters[this.inputIconRowIndex] + '"]');
    }

    if (inputFilterRow.length > 0) {
      for (let i = 0; i < inputFilterRow.length; i++) {
        if (inputFilterRow[i].name === "filterValue") {
          this.inputValue = inputFilterRow[i].value;
        }
      }
    }
    this.filtersToRender = true;
  }

  closeInputModal() {
    this.enableValueModal = false;
    this.filtersToRender = true;
  }
  handleInputValueChange(event) {
    this.inputValue = event.detail.value;
    this.filtersToRender = true;
  }

  handleInputSubmit() {
    this.enableValueModal = false;
    let inputFilterRow;
    if (this.contactTypeValue === "24x7 Contact Types") {
      inputFilterRow = this.template.querySelectorAll('[data-id="' + this.filters[this.inputIconRowIndex] + '"]');
    }
    else if (this.contactTypeValue === "Authorized Contacts") {
      inputFilterRow = this.template.querySelectorAll('[data-auth="' + this.filters[this.inputIconRowIndex] + '"]');
    }

    if (inputFilterRow.length > 0) {
      for (let i = 0; i < inputFilterRow.length; i++) {
        if (inputFilterRow[i].name === "filterValue") {
          inputFilterRow[i].value = this.inputValue;
        }
      }
    }
    this.filtersToRender = true;
  }

  handleReminderChange(event) {

    let selectedDatetime = event.detail.value;
    if (selectedDatetime !== null) {
      this.reminderValue = selectedDatetime;
    }
    else {
      this.reminderValue = null;
    }

  }


  renderedCallback() {
    console.log('In renderedCallback');
    let custVal = this.template.querySelectorAll('[data-id="customerGroupValue"]');
    if (custVal.length > 0) {
      this.customerGroupValue = custVal[0].value;
    }

    if (typeof this.mailerId !== 'undefined' && this.mailerId !== null) {
      // Enabling the Send Test Email Button 
      let testEmailButton = this.template.querySelector('[data-id="testEmailButton"]')
      testEmailButton.disabled = false;

      if (typeof this.mailerDataResult !== 'undefined') {

        // Enabling the Preview and Send Mailer Button
        if (this.mailerDataResult.CMC_Is_Approved__c === true) {
          let previewAndSendButton = this.template.querySelector('[data-id="previewAndSendButton"]')
          previewAndSendButton.disabled = false;

          let errorReportButton = this.template.querySelector('[data-id="errorReportButton"]')
          errorReportButton.disabled = false;

          //Disabling the Peer Review Button
          let peerReviewButton = this.template.querySelector('[data-id="peerReviewButton"]')
          peerReviewButton.disabled = true;

          // Disabling the Notification Recipients and Peer Review Section

          // Disable SI Number 
          let siNumber = this.template.querySelector('[data-id="siNumber"]')
          siNumber.disabled = true;

          //Disable Contact Types 
          let contactType = this.template.querySelector('[data-id="contactType"]')
          contactType.disabled = true;


          // Disable 24x7 Section
          if (this.mailerDataResult.CMC_24x7_Contact_Types__c === true) {

            //Disable Account Types 
            let accountTypes = this.template.querySelector('[data-id="accountTypeValue"]')
            accountTypes.disabled = true;

            //Disable Customer Groups  
            let custGroup = this.template.querySelector('[data-id="customerGroupValue"]')
            custGroup.disabled = true;

            // Disable Filters
            for (let i = 0; i < this.newFilterNumber; i++) {
              let filtersToDisable = this.template.querySelectorAll('[data-id="' + this.filters[i] + '"]');
              for (let j = 0; j < filtersToDisable.length; j++) {
                filtersToDisable[j].disabled = true
              }
            }

          }

          // Disable Authorized Contacts Section
          if (this.mailerDataResult.AuthCon_Authorized_Contacts__c === true) {

            //Disable Customer Groups  
            let RecipientType = this.template.querySelector('[data-id="RecipientTypeValue"]')
            RecipientType.disabled = true;

            //Disable Auth Customer Groups  
            let customerAuthGroup = this.template.querySelector('[data-id="customerAuthGroupValue"]')
            customerAuthGroup.disabled = true;

            //Disable Filters
            for (let i = 0; i < this.newAuthFilterNumber; i++) {
              let filtersToDisable = this.template.querySelectorAll('[data-auth="' + this.authFilters[i] + '"]');
              for (let j = 0; j < filtersToDisable.length; j++) {
                filtersToDisable[j].disabled = true;
              }
            }

          }

          // Disable Add Filter Button
          let addfilterButton = this.template.querySelectorAll('[data-id="addFilterButton"]')
          if (addfilterButton.length > 0) {
            addfilterButton[0].disabled = true;
          }

          // Disable Manual Section 
          if ((this.mailerDataResult.CMC_Manual_Email_Addresses__c !== '' && this.mailerDataResult.CMC_Manual_Email_Addresses__c !== 'undefined' && Object.prototype.hasOwnProperty.call(this.mailerDataResult, 'CMC_Manual_Email_Addresses__c')) || (this.mailerDataResult.CMC_Imported_Emails_AttachmentId__c !== '' && this.mailerDataResult.CMC_Imported_Emails_AttachmentId__c !== 'undefined' && Object.prototype.hasOwnProperty.call(this.mailerDataResult, 'CMC_Imported_Emails_AttachmentId__c'))) {

            // Disable Manual Input Type Combobox
            let manualInputType = this.template.querySelector('[data-id="EmailInputValue"]')
            manualInputType.disabled = true;

            if (this.mailerDataResult.CMC_Manual_Email_Addresses__c !== '' && this.mailerDataResult.CMC_Manual_Email_Addresses__c !== 'undefined' && Object.prototype.hasOwnProperty.call(this.mailerDataResult, 'CMC_Manual_Email_Addresses__c')) {
              // Disable Manual Input Text Area
              let manualInput = this.template.querySelector('[data-id="Manual"]')
              manualInput.disabled = true;

            }
            else {
              // Disable Manual Import
              let manualImport = this.template.querySelector('[data-id="manualImport"]')
              if (manualImport !== null) {
                manualImport.disabled = true;
              }

              //Disable Manual Remove File Button
              let removeManualFileButton = this.template.querySelectorAll('[data-id="removeManualFileButton"]')
              if (removeManualFileButton.length > 0) {
                removeManualFileButton[0].disabled = true;
              }

            }
          }

          // Disable Peer Review Section
          let peerReviewer = this.template.querySelector('[data-id="peerReviewer"]')
          peerReviewer.disabled = true;

          let approvalStatus = this.template.querySelector('[data-id="approvalStatus"]')
          approvalStatus.disabled = true;

          let approvalComments = this.template.querySelector('[data-id="approvalComments"]')
          approvalComments.disabled = true;

        }
        // Disable Peer Review Button
        if (this.mailerDataResult.Test_Email_Sent__c === true && this.mailerDataResult.CMC_Is_Approved__c === false) {
          let peerReviewButton = this.template.querySelector('[data-id="peerReviewButton"]')
          peerReviewButton.disabled = false;
        }

      }
    }



    if ((typeof this.mailerId === 'undefined' || this.mailerId === null) || (typeof this.mailerId !== 'undefined' && this.mailerId !== null && this.hideAuthFilter === false)) {

      // Disabling the remove button for the first filter row when a file is not uploaded
      let addFilterRow;
      let disableRemove = true;

      if (this.contactTypeValue === '24x7 Contact Types') {
        addFilterRow = this.template.querySelectorAll('[data-id="1"]');
      }
      else if (this.contactTypeValue === 'Authorized Contacts') {
        addFilterRow = this.template.querySelectorAll('[data-auth="1"]');
      }

      for (let k = 0; k < addFilterRow.length; k++) {

        if (addFilterRow[k].name === 'downloadLink' && typeof addFilterRow[k].value !== 'undefined') {
          disableRemove = false;
        }

        if (addFilterRow[k].name === 'removeButton' && disableRemove === true) {
          addFilterRow[k].disabled = true;
        }
      }


      if (this.hideAuthFilter === true) {
        if (this.contactTypeValue !== 'Authorized Contacts') {
          for (let i = 0; i < this.newAuthFilterNumber; i++) {
            let authFiltersToHide = this.template.querySelectorAll('[data-auth="' + this.authFilters[i] + '"]');
            //   console.log('authFiltersToHide Length//' + authFiltersToHide.length);
            for (let j = 0; j < authFiltersToHide.length; j++) {
              authFiltersToHide[j].style.display = "none"
            }
          }
        }
        if (this.contactTypeValue !== '24x7 Contact Types') {
          for (let i = 0; i < this.newFilterNumber; i++) {
            let filtersToHide = this.template.querySelectorAll('[data-id="' + this.filters[i] + '"]');
            //   console.log('filtersToHide Length//' + filtersToHide.length);
            for (let j = 0; j < filtersToHide.length; j++) {
              filtersToHide[j].style.display = "none"
            }
          }
        }
      }


    }

    // If the mailer Exists

    if (typeof this.mailerDataResult !== 'undefined' && this.hideAuthFilter === true) {
      let addFilterRow;
      if (this.mailerDataResult.CMC_24x7_Contact_Types__c === true) {
        addFilterRow = this.template.querySelectorAll('[data-id="1"]');
      }

      else if (this.mailerDataResult.AuthCon_Authorized_Contacts__c === true) {
        addFilterRow = this.template.querySelectorAll('[data-auth="1"]');
      }
      if (typeof addFilterRow !== 'undefined' && addFilterRow[0].disabled !== true) {
        for (let k = 0; k < addFilterRow.length; k++) {
          if (addFilterRow[k].name === 'removeButton') {
            addFilterRow[k].disabled = true;
          }
        }
      }


      if (this.mailerDataResult.CMC_All_Customers__c === true || (this.mailerDataResult.AuthCon_Authorized_Contacts__c === false && this.mailerDataResult.CMC_24x7_Contact_Types__c === false)) {
        for (let i = 0; i < this.newAuthFilterNumber; i++) {
          let authFiltersToHide = this.template.querySelectorAll('[data-auth="' + this.authFilters[i] + '"]');
          for (let j = 0; j < authFiltersToHide.length; j++) {
            authFiltersToHide[j].style.display = "none"
          }
        }

        for (let i = 0; i < this.newFilterNumber; i++) {
          let filtersToHide = this.template.querySelectorAll('[data-id="' + this.filters[i] + '"]');
          for (let j = 0; j < filtersToHide.length; j++) {
            filtersToHide[j].style.display = "none"
          }
        }
      }
      else {
        if (this.mailerDataResult.AuthCon_Authorized_Contacts__c === false) {
          for (let i = 0; i < this.newAuthFilterNumber; i++) {
            let authFiltersToHide = this.template.querySelectorAll('[data-auth="' + this.authFilters[i] + '"]');
            for (let j = 0; j < authFiltersToHide.length; j++) {
              authFiltersToHide[j].style.display = "none"
            }
          }
        }
        if (this.mailerDataResult.CMC_24x7_Contact_Types__c === false) {
          for (let i = 0; i < this.newFilterNumber; i++) {
            let filtersToHide = this.template.querySelectorAll('[data-id="' + this.filters[i] + '"]');
            for (let j = 0; j < filtersToHide.length; j++) {
              filtersToHide[j].style.display = "none"
            }
          }
        }
      }
    }



    const style = document.createElement('style');
    style.innerText = `c-sc_-s-i_-I-N-T_-Tool .inline .slds-form-element__control{
            display : inline-block !important;
                    }`;
    this.template.querySelector('lightning-record-edit-form').appendChild(style);

    const style2 = document.createElement('style');
    style2.innerText = `lightning-groupedcombobox_groupedcombobox  .slds-form-element__control
            padding: 0px;
                    }`;
    this.template.querySelector('lightning-input-field').appendChild(style2);

    const style3 = document.createElement('style');
    style3.innerText = `c-sc_-s-i_-I-N-T_-Tool .add-filter .slds-button{
            left: 10px;
            margin-bottom: -40px;
                            }`;
    this.template.querySelector('lightning-button').appendChild(style3);


    const style4 = document.createElement('style');
    style4.innerText = `c-sc_-s-i_-I-N-T_-Tool .align-Value .slds-input{
            margin-left: -4px;
            width: 102%;
                            }`;
    this.template.querySelector('lightning-input').appendChild(style4);

    const style5 = document.createElement('style');
    style5.innerText = `c-sc_-s-i_-I-N-T_-Tool .align-Upload .slds-file-selector__dropzone{
            margin-left: -4px;
                            }`;
    this.template.querySelector('lightning-input').appendChild(style5);

    const style6 = document.createElement('style');
    style6.innerText = `c-sc_-s-i_-I-N-T_-Tool .spinner-height .slds-spinner_container{
            height: 200%;
                            }`;
    this.template.querySelector('lightning-input').appendChild(style6);

    const style7 = document.createElement('style');
    style7.innerText = `c-sc_-s-i_-I-N-T_-Tool .removeButton .slds-button_destructive{
            padding-left: 7px;
            padding-right: 7px;
                            }`;
    this.template.querySelector('lightning-button').appendChild(style7);

    if (this.enableValueModal) {
      const style8 = document.createElement("style");
      style8.innerText = `c-sc_-s-i_-I-N-T_-Tool .inputValue .slds-textarea{
            width: 440%;
            padding-bottom: 70px;
                            }`;
      this.template.querySelector("lightning-textarea").appendChild(style8);
    }

    const style9 = document.createElement("style");
    style9.innerText = `c-sc_-s-i_-I-N-T_-Tool .inputicon .slds-button_icon{

            margin-left: -84px;
                            }`;
    this.template.querySelector("lightning-button-icon").appendChild(style9);


    if (this.showPeerSection === true) {
      // Setting Reviewer in Rendered Call Back on load only
      if (this.reviewer !== 'undefined' && this.reviewer !== '' && this.reviewer !== null) {

        let reviewer = this.template.querySelector('[data-id="peerReviewer"]');
        if (reviewer.value === null || typeof reviewer.value === 'undefined') {
          reviewer.value = this.reviewer;
        }
      }
    }



    // Prepopulating the added filters
    if (this.mailerId !== null && this.mailerId !== '' && this.mailerId !== 'undefined' && this.mailerFilters.length > 0 && this.filtersToRender === false) {
      let i = 0;

      this.mailerFilters.forEach(eachFilter => {
        let addFilterRow;
        if (this.contactTypeValue === '24x7 Contact Types') {
          addFilterRow = this.template.querySelectorAll('[data-id="' + this.filters[i] + '"]');
        }
        else if (this.contactTypeValue === 'Authorized Contacts') {
          addFilterRow = this.template.querySelectorAll('[data-auth="' + this.authFilters[i] + '"]');
        }

        for (let j = 0; j < addFilterRow.length; j++) {

          if (addFilterRow[j].name === 'field') {
            addFilterRow[j].value = eachFilter.CMC_Filter_Field__c;

          }
          if (addFilterRow[j].name === 'condition') {
            addFilterRow[j].value = eachFilter.CMC_Filter_Condition__c;
          }

          if (addFilterRow[j].name === 'filterValue') {
            addFilterRow[j].value = eachFilter.CMC_Filter_Value__c;

          }
          if (eachFilter.CMC_Filter_Condition__c === 'In' && typeof eachFilter.CMC_Filter_Value__c === 'undefined') {
            if (addFilterRow[j].name === 'downloadLink') {
              addFilterRow[j].value = '/sfc/servlet.shepherd/document/download/' + eachFilter.CMC_Filter_Attachment__c;
              addFilterRow[j].label = eachFilter.Attachment_Name__c;

            }

            if (addFilterRow[j].name !== 'downloadLink' && addFilterRow[j].name !== 'removeButton') {
              addFilterRow[j].disabled = true;
            }

            if (addFilterRow[j].name === 'removeButton') {
              if (eachFilter.CMC_Filter_Order__c === 1) {
                addFilterRow[j].disabled = false;
              }

            }

          }
          else if (eachFilter.CMC_Filter_Condition__c === 'In' && typeof eachFilter.CMC_Filter_Value__c !== 'undefined') {
            if (addFilterRow[j].name === 'filterAttachment') {
              if (eachFilter.CMC_Filter_Order__c === 1) {
                addFilterRow[j].disabled = false;
              }

            }
            if (addFilterRow[j].name === "valueIcon") {
              addFilterRow[j].disabled = false;
            }
          }



        }
        i++;
      });
    }

    this.filtersToRender = false;

  }


}