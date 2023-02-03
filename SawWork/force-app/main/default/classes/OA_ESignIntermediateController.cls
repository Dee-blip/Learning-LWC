// /***
//     OA_ESignIntermediateController
//     @author : Ali KM <mohkhan@akamai.com>
//     @Description : This is the Custom Controller for the ESignIntermediate Page
// 
//     @History
//     --Developer           --Date            --Change
//     Ali KM               01/02/2011         Created this class for
//                                              - CR 919117 e-Signature DocuSign implementation
//    Ali KM				 28/03/2011			CR 919117 e-Signature DocuSign implementation
//             - As per requirements added following features:
//               - On Add New Contact button click: Account.BillingAddress is copied to Contact.MailingAddress
//               - Fetching Email Template / Reminder & Alerts default values from dsfs__DocuSignAccountConfigruation__c objects
//              - For 'Add New Contact' VF section made Name/Email/Account as mandatory fields
//    Ali KM				 25/May/2011		CR 1040808 E-Signature: Void Envelopes
//            - Added logic to populate Envelop Expire by Integer value based on Order Expires Unless Duly Signed by data field.
//    Ali KM				 31/May/2011		CR 1135972 E-Sign: Attachment name too long error
//            - Bug: If E-sign attachment name is more than 80 character it throws an Exception. This is fixed
//             -> If attachment length > 80; shorten it to 80 characters including extension.
//    Ali KM				 20/Sep/2011		CR 1312859 DocuSign Bug Fix - Get an empty screen when no attachments are available for a DocuSign request
//    Ali KM				 31/Jul/2012		CR 1819048 E-Sign request should be valid only until OA.Valid Until Date.
//             -> If OA.Order_Expires_Unless_Duly_Executed_By__c is TODAY or older then set the Default Envelope Expiry date to 30 days (CustomSetting)
//    Ali KM				  03/08/2012		CR 1819048 E-Sign request should be valid only until OA.Valid Until Date.
//             -> added a parameter for SS6 check method to override 'valid until date' check for E-Signature requests.
//    Ali KM				 27/Sep/2012		CR 1916992 - E-Sign Bug - Recipient 2 Signer role set to None causes null exception.
//             -> Bug-Fix.
//    Nagaraj Desai              4 December 2018             SFDC-3953 -> Attachment Migration to Files
// 
// 
 public class OA_ESignIntermediateController {
     public OA_ESignIntermediateController() {}
//         // Associated RSM Contact Id
//         public Contact currentUserContact;
//         //DocuSign Envelope Document
//         private List<dsfs__DocuSign_Envelope_Document__c> dseDocumentList;
//         // ErrorList
//         private List<String> errList;
// 
// 
//         //Fetch Current User Details
//         public static User currentUserRecord;
//         public Integer recipientIndex;
//         public Contact newContact {get; set;}
//         public Boolean newContactFlag {get; set;}
//         public ContentVersion pdfAttachment;
//         public Order_Approval__c oa {get; set;}
//         public List<OA_EmailBlast_AttachmentWrapper> oaAttachment {get; set;}
//         public String viewfilePath {get; set;}
//         public Boolean showPage {get; set;}
//         public Boolean emptyOAId {get; set;}
//         public List<ContentDocumentLink> selectedAttachments;
//         public Integer mode {get; set;}
//         public string ErrorMessage {get; set;}
// 
//         /**
//            initializeCurrentUserRecord()
//            - Fetches current user User record.
//          */
//         public static void initializeCurrentUserRecord()
//         {
//                 if(currentUserRecord == null)
//                         currentUserRecord = [Select LastName, FirstName, Email, Alias From User where Id=:Userinfo.getUserId()][0];
//         }
// 
//         /**
//            GetCustomSettingValue(String pPropertyName)
//            - Generic function to return Custom Setting values for the single Custom Setting Object model
//          */
//         public static String GetCustomSettingValue(String pPropertyName)
//         {
//                 return GSM_Custom_Settings__c.getInstance('ESignature#'+pPropertyName).Value__c;
//         }
// 
//         public Boolean firstLoaded=false;
//         public static Map<String,OA_eSign_Intermediate__c> customSettings = OA_eSign_Intermediate__c.getAll();
//         //DocuSign Config object
//         public dsfs__DocuSignAccountConfiguration__c dsConfiguration {get; set;}
// 
//         //DocuSign Envelope
//         public dsfs__DocuSign_Envelope__c dsEnvelope {get; set;}
//         // DocuSign Envelope Recipient Objects
//         public dsfs__DocuSign_Envelope_Recipient__c dseRecipient1 {get; set;}
//         public dsfs__DocuSign_Envelope_Recipient__c dseRecipient2  {get; set;}
// 
//         // constructor
//         public OA_ESignIntermediateController()
//         {
//                 viewfilePath = '/servlet/servlet.FileDownload?file';
//                 showPage = true;
//                 firstLoaded = init();
//         }
//         // method to fetch customsettings
//         private String getCustomSettingsValue(String pName)
//         {
//                 return customSettings.get(pName).Value__c;
//         }
//         // method to display error on Page.
//         private void showErrorAndDiscontinue(String pErrorMessage)
//         {
//                 showPage = false;
//                 ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, pErrorMessage));
//         }
//         /**
//            addError(String pErrorMessage)
//            - Method to add to list of Errors.
//          */
//         private void addError(String pErrorMessage)
//         {
//                 showPage = false;
//                 errList.add(pErrorMessage);
//         }
//         /**
//            addError(String pErrorMessageList)
//            - Method to add to list of Errors.
//          */
//         private void addError(String[] pErrorMessageList)
//         {
//                 showPage = false;
//                 errList.addAll(pErrorMessageList);
//         }
//         // entry method
//         public Boolean init()
//         {
//                 mode = 0;
//                 oaAttachment = new List<OA_EmailBlast_AttachmentWrapper>();
//                 errList = new List<String>();
//                 for(Order_Approval__c o : [SELECT Id, Name, Approvals_Required__c, CCG__c, Associated_Opportunity__r.Name,
//                                            Legal__c, Deal_Desk__c,
//                                            //Start Modified By Chandra For CR 693820
//                                            New_Churn__c,
//                                            //End Modified By Chandra For CR 693820
//                                            Order_Expires_Unless_Duly_Executed_By__c,
//                                            Account_Territory__c, Associated_Opportunity__c, Associated_Account__c, Associated_Opportunity_Sales_Stage__c,
//                                            Opportunity_Owner__c, Type__c, AKAM_OrderApproval_ID__c, Send_To_Contact__c, Associated_Opportunity__r.AccountId
//                                            FROM Order_Approval__c WHERE id=:ApexPages.currentPage().getParameters().get('id')])
//                         oa = o;
//                 if(oa == null)
//                 {
//                         showErrorAndDiscontinue('Oops! cant find the Order Approval record, please return to previous page and try again.');
//                         emptyOAId = false;
//                         return false;
//                 }
//                 // fetch the Contact Id of logged in User's RSM if it exists...
//                 //Select Id From Contact where AKAM_Contact_ID__c IN (Select Associated_User_RSM__r.AKAM_User_ID__c From Account_Reassignment_Rule__c where Associated_User__c = : Userinfo.getUserId())
//                 Account_Reassignment_Rule__c currentUserRule;
//                 for (Account_Reassignment_Rule__c accRule : [Select Associated_User_RSM__r.AKAM_User_ID__c From Account_Reassignment_Rule__c
//                                                              where Associated_User__c = : Userinfo.getUserId() ORDER BY CreatedDate DESC LIMIT 1])
//                         currentUserRule = accRule;
//                 // Fetch the Configurations from 'DocuSignAccountConfigurations' object.
//                 // Use it in the 'dsEnvelope' initilization.
//                 if (currentUserRule!=null)
//                 {
//                         for (Contact rsmContact : [Select Id From Contact where AKAM_Contact_ID__c = : currentUserRule.Associated_User_RSM__r.AKAM_User_ID__c AND
//                                                                                                      Account.AKAM_Account_ID__c = : getCustomSettingsValue('Akamai Account Id') ORDER BY CreatedDate DESC LIMIT 1])
//                                 currentUserContact = rsmContact;
//                 }
// 
//                 //Fetch the configuration file from `dsfs__DocuSignAccountConfiguration__c' object
//                 for (dsfs__DocuSignAccountConfiguration__c dsConfig : [Select dsfs__EmailSubject__c, dsfs__EmailBody__c, dsfs__DefaultWarnOfExpireNDays__c, dsfs__DefaultReminderNDays__c, dsfs__DefaultRepeatReminderNDays__c,
//                                                                        dsfs__DefaultExpireNDays__c From dsfs__DocuSignAccountConfiguration__c where Name =: getCustomSettingsValue('dsConfigRecordName') ORDER BY CreatedDate DESC LIMIT 1])
//                         dsConfiguration = dsConfig;
//                 // DocuSign Section:
//                 // Create DocuSign Envelope
//                 if (dsEnvelope == null)
//                 {
//                         dsEnvelope = new dsfs__DocuSign_Envelope__c();
//                         dsEnvelope.dsfs__Source_Object__c = oa.Id;
//                         if (dsConfiguration!=null)
//                         {
//                                 initializeCurrentUserRecord();
//                                 String emailBodyStr;
//                                 emailBodyStr = dsConfiguration.dsfs__EmailBody__c;
//                                 emailBodyStr = emailBodyStr.replace('[FirstName]',Userinfo.getFirstName());
//                                 emailBodyStr = emailBodyStr.replace('[LastName]',Userinfo.getLastName());
//                                 emailBodyStr = emailBodyStr.replace('[Email]',currentUserRecord.Email);
//                                 dsEnvelope.dsfs__DocuSign_Email_Subject__c = dsConfiguration.dsfs__EmailSubject__c;
//                                 dsEnvelope.dsfs__DocuSign_Email_Message__c = emailBodyStr;
//                                 // Reminder & Expiration fields
//                                 dsEnvelope.dsfs__Day_Prior_to_Warn_of_expiration__c = dsConfiguration.dsfs__DefaultWarnOfExpireNDays__c;
//                                 dsEnvelope.dsfs__Reminder_Interval__c = dsConfiguration.dsfs__DefaultReminderNDays__c;
//                                 dsEnvelope.dsfs__Reminder_Repeat_Interval_in_Days__c = dsConfiguration.dsfs__DefaultRepeatReminderNDays__c;
// 
//                                 //Add Logic to populate the Expire dates based on some date (Ex: Order_Expires_Unless_Duly_Executed_By__c)
//                                 Decimal expireDays;
//                                 String customExpireSettingToggle = GetCustomSettingValue('CustomExpireSettings');
//                                 if (customExpireSettingToggle.equalsIgnoreCase('true') && oa.Order_Expires_Unless_Duly_Executed_By__c != null && oa.Order_Expires_Unless_Duly_Executed_By__c > datetime.now())
//                                 {
//                                         DateTime orderExpiresUnlessDulyExecutedBy = oa.Order_Expires_Unless_Duly_Executed_By__c;
//                                         Date tempDate = orderExpiresUnlessDulyExecutedBy.date();                                         //dateGmt();
//                                         Date currentDate = Date.today();
//                                         expireDays = currentDate.daysBetween(tempDate) + Decimal.valueOf(GetCustomSettingValue('ExpireEnvelopeGraceDays'));
//                                         if (expireDays > 120)
//                                                 expireDays = dsConfiguration.dsfs__DefaultExpireNDays__c;
//                                 }
//                                 else
//                                 {
//                                         if (oa.Order_Expires_Unless_Duly_Executed_By__c==null)
//                                                 expireDays = dsConfiguration.dsfs__DefaultExpireNDays__c;
//                                         else
//                                                 expireDays= Integer.valueOf(GetCustomSettingValue('DefaultEnvelopeExpireDays'));                                                 //30;
// 
//                                 }
//                                 dsEnvelope.dsfs__Days_before_Envelope_is_Expired_Voided__c = expireDays;
// 
//                                 //dsEnvelope.dsfs__Days_before_Envelope_is_Expired_Voided__c = dsConfiguration.dsfs__DefaultExpireNDays__c;
// 
//                                 if (getCustomSettingsValue('SendEmailReminder')!=null && getCustomSettingsValue('SendEmailReminder')=='true')
//                                         dsEnvelope.dsfs__Send_Reminder__c = true;
//                                 else
//                                         dsEnvelope.dsfs__Send_Reminder__c = false;
//                         }
//                 }
//                 // RSM
//                 dseRecipient1 = new dsfs__DocuSign_Envelope_Recipient__c();
//                 dseRecipient1.dsfs__Routing_Order__c = 1;
//                 dseRecipient1.dsfs__DocuSign_Signer_Type__c = 'Signer';
//                 dseRecipient1.dsfs__DocuSign_Recipient_Role__c = 'Akamai RSM 1';
//                 dseRecipient1.dsfs__Salesforce_Recipient_Type__c = 'Contact';
//                 if (currentUserContact!=null)
//                         dseRecipient1.dsfs__DSER_ContactID__c = currentUserContact.Id;
//                 // Customer
//                 dseRecipient2 = new dsfs__DocuSign_Envelope_Recipient__c();
//                 dseRecipient2.dsfs__Routing_Order__c = 2;
//                 dseRecipient2.dsfs__DocuSign_Signer_Type__c = 'Signer';
//                 dseRecipient2.dsfs__Salesforce_Recipient_Type__c = 'Contact';
//                 dseRecipient2.dsfs__DocuSign_Recipient_Role__c = 'Customer Signatory 1';
//                 // OA & Opportunity Attachment Section
//                 //SFDC-3953 Combine two queries
//                 List<ContentDocumentLink> listOfContentDocumentLink = [SELECT ContentDocumentId, ContentDocument.LatestPublishedVersionId, ContentDocument.LatestPublishedVersion.Title, ContentDocument.LastModifiedDate, LinkedEntityId, LinkedEntity.Type FROM ContentDocumentLink WHERE LinkedEntityId = :oa.Id OR LinkedEntityId = :oa.Associated_Opportunity__c];
//                 for(ContentDocumentLink eachcontentDocumentLink : listOfContentDocumentLink) {
//                         oaAttachment.add(new OA_EmailBlast_AttachmentWrapper(eachcontentDocumentLink));
//                 }
// 
//                 if(oaAttachment.size()==0)
//                 {
//                         emptyOAId = true;
//                         //showPage = false;
//                         //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There are no attachments for this Order Approval OR Associated Opportunity'));
//                         addError('There are no attachments for this Order Approval OR Associated Opportunity');
//                 }
//                 else
//                         oaAttachment.get(0).checked = true;                         // check the checkbox for topmost item ie. based on LastModifiedDate.
// 
//                 return true;
//         }
// 
//         public PageReference validate()
//         {
//                 init();
// 
//                 if (oa != null)
//                 {
//                         errList.addAll(GsmUtilClass.SalesStageSixValidation(oa.Associated_Opportunity__c,'esign'));
//                         if (errList.size()>0)
//                         {
//                                 ErrorMessage='<b>'+Label.DocuSign_CFA_SendEmailControllerTopErrorMessage+'</b><br/>';
//                                 for(string err:errList)
//                                         ErrorMessage+='<br/><b>•</b> '+err+'<br/>';
// 
//                                 return null;
//                         }
//                 }
//                 mode=1;
//                 return null;
//         }
// 
//         //method to Fetch DocuSign corresponding Role for selected RoleName.
//         public Double getRoleValue(String pDocuSign_Recipient_Role)
//         {
//                 Double roleValue;
//                 if (pDocuSign_Recipient_Role.equals(getCustomSettingsValue('Recipient 1')))
//                         roleValue=1;
//                 else if (pDocuSign_Recipient_Role.equals(getCustomSettingsValue('Recipient 2')))
//                         roleValue=2;
//                 else if (pDocuSign_Recipient_Role.equals(getCustomSettingsValue('Recipient 3')))
//                         roleValue=3;
//                 else if (pDocuSign_Recipient_Role.equals(getCustomSettingsValue('Recipient 4')))
//                         roleValue=4;
//                 return roleValue;
//         }
// 
//         //createDocuSignEnvelopeDocument() generates a DocuSignEnvelopeDocument thats will be used before sending the Document for Signing.
//         public dsfs__DocuSign_Envelope_Document__c createDocuSignEnvelopeDocument(Id pDocuSignEnvelopeId, Integer pDocumentOrder, String pAttachmentName, String pAttachmentId)
//         {
//                 System.debug('pAttachmentName='+ pAttachmentName);
//                 if (pAttachmentName.length() > 80)
//                 {
//                         String newFileName;
//                         String extPart;
//                         List<String> parts = pAttachmentName.split('\\.');
//                         extPart = '.' +  parts[parts.size()-1];
//                         newFileName = pAttachmentName.substring(0, 80 - extPart.length()) + extPart;
//                         System.debug('newFileName=' + newFileName);
//                         pAttachmentName = newFileName;
//                         System.assertEquals(80, newFileName.length());
//                 }
// 
//                 dsfs__DocuSign_Envelope_Document__c d = new dsfs__DocuSign_Envelope_Document__c();
//                 d.dsfs__DocuSign_EnvelopeID__c = pDocuSignEnvelopeId;
//                 d.dsfs__Document_Order__c = pDocumentOrder;
//                 d.dsfs__Attachment_Name__c = pAttachmentName;
//                 d.dsfs__Document_Name__c = pAttachmentName;
//                 d.dsfs__Attachment_ID__c = pAttachmentId;
//                 // this is populated by default to Attachment
//                 //tempDSEDoc.dsfs__SFDocument_Type__c = 'Attachment';
//                 return d;
//         }
// 
//         public PageReference Next()
//         {
//                 //SFDC-3953
//                 selectedAttachments = new List<ContentDocumentLink>();
//                 Boolean isError = false;
//                 if (oaAttachment.size()==0)
//                 {
//                         isError = true;
//                         showPage = false;
//                         ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There are no attachments for this Order Approval OR Associated Opportunity'));
//                 }
//                 else if (dseRecipient1.dsfs__DSER_ContactID__c==null)
//                 {
//                         isError = true;
//                         ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Recipient 1 - Contact field cannot be empty, please select a value.'));
//                 }
//                 else if (dseRecipient1.dsfs__DocuSign_Recipient_Role__c==null)
//                 {
//                         isError = true;
//                         ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Recipient 1 - DocuSign Signer Role field cannot be empty, please select a value.'));
//                 }
//                 else if (dseRecipient2.dsfs__DSER_ContactID__c!=null && dseRecipient2.dsfs__DocuSign_Recipient_Role__c==null)
//                 {
//                         isError = true;
//                         ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Recipient 2 - DocuSign Signer Role field cannot be empty, please select a value.'));
//                 }
//                 // if dseRecipient2.dsfs__DocuSign_Recipient_Role__c != null && dseRecipient2.dsfs__DSER_ContactID__c==null
//                 // add error
// 
//                 else
//                 {
//                         for (OA_EmailBlast_AttachmentWrapper a : oaAttachment)
//                         {
//                                 if(a.checked)
//                                         selectedAttachments.add(a.attach);
//                         }
//                         try
//                         {
//                                 if(selectedAttachments.size() > 0)
//                                 {
//                                         // Insert Envelope / Create Recipients
//                                         //this.Action();
//                                         try
//                                         {
//                                                 insert dsEnvelope;
//                                         }
//                                         catch (exception ex)
//                                         {
//                                                 isError = true;
//                                                 throw new CustomException('An error has occcured during email process. Please contact system administrator. Error Details : ' + ex);
//                                         }
//                                         try
//                                         {
//                                                 dseRecipient1.dsfs__DocuSign_EnvelopeID__c = dsEnvelope.Id;
//                                                 dseRecipient1.dsfs__RoleName__c = dseRecipient1.dsfs__DocuSign_Recipient_Role__c;
//                                                 dseRecipient1.dsfs__RoleValue__c = getRoleValue(dseRecipient1.dsfs__DocuSign_Recipient_Role__c);
//                                                 insert dseRecipient1;
// 
//                                                 if (dseRecipient2.dsfs__DSER_ContactID__c!=null)
//                                                 {
//                                                         dseRecipient2.dsfs__DocuSign_EnvelopeID__c = dsEnvelope.Id;
//                                                         dseRecipient2.dsfs__RoleName__c = dseRecipient2.dsfs__DocuSign_Recipient_Role__c;
//                                                         dseRecipient2.dsfs__RoleValue__c = getRoleValue(dseRecipient2.dsfs__DocuSign_Recipient_Role__c);
//                                                         insert dseRecipient2;
//                                                 }
//                                         }
//                                         catch (exception ex)
//                                         {
//                                                 isError = true;
//                                                 throw new CustomException('An error has occcured during email process. Please contact system administrator. Error Details : ' + ex);
//                                         }
//                                         // Generate DocuSign Envelope Documents
//                                         List<dsfs__DocuSign_Envelope_Document__c> dseDocumentList = new List<dsfs__DocuSign_Envelope_Document__c>();
//                                         Integer count = 1;
//                                         for(ContentDocumentLink att: selectedAttachments)
//                                         {
//                                                 dseDocumentList.add(this.createDocuSignEnvelopeDocument(dsEnvelope.Id, count, att.ContentDocument.LatestPublishedVersion.Title, att.ContentDocumentId));
//                                                 count++;
//                                         }
//                                         // update
//                                         Opportunity associatedOppty = [Select Id, Associated_Order_Approval_Id__c from Opportunity where Id = :oa.Associated_Opportunity__c];
//                                         associatedOppty.Associated_Order_Approval_Id__c = oa.Id;
//                                         associatedOppty.Validation_Override__c = true;
//                                         // Insert & Update
//                                         try
//                                         {
//                                                 insert dseDocumentList;
//                                                 update associatedOppty;
//                                         }
//                                         catch (exception ex)
//                                         {
//                                                 isError = true;
//                                                 throw new CustomException('An error has occcured during email process. Please contact system administrator. Error Details : ' + ex);
//                                         }
//                                 }
//                                 else
//                                 {
//                                         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'No Attachments selected, please select atleast one document for E-Signature.'));
//                                         isError = true;
//                                 }
//                         }
//                         catch (exception ex)
//                         {
//                                 //throw ex;
//                                 ApexPages.addMessages(ex);
//                                 showPage = false;
//                                 isError = true;
//                         }
//                 }
//                 if(!isError)
//                 {
//                         String editEnvelopeURL = Label.DocusignEnvelopeURL.replace('##DESID##', dsEnvelope.Id).replace('##OA_ID##', oa.Id);
//                         return (new PageReference(editEnvelopeURL));
//                 }
//                 else
//                         return null;                         // If error,stay on the page
//         }
//         public PageReference cancel()
//         {
//                 return (new PageReference('/' + oa.id));
//         }
//         public PageReference activateAddNewContact1()
//         {
//                 newContact = new Contact();
//                 newContact.AccountID = oa.Associated_Opportunity__r.AccountId;
//                 newContactFlag = true;
//                 showPage = false;
//                 recipientIndex = 1;
//                 return null;
//         }
//         public PageReference activateAddNewContact2()
//         {
//                 newContact = new Contact();
//                 newContact.AccountID = oa.Associated_Opportunity__r.AccountId;
//                 newContactFlag = true;
//                 showPage = false;
//                 recipientIndex = 2;
//                 return null;
//         }
//         public PageReference newContactSave()
//         {
//                 if (newContact.Email==null)
//                         this.showErrorAndDiscontinue('Email: You must enter a value');
//                 else if (newContact.FirstName==null)
//                         this.showErrorAndDiscontinue('First Name: You must enter a value');
//                 else if (newContact.AccountId==null)
//                         this.showErrorAndDiscontinue('Account Name: You must enter a value');
//                 else
//                 {
//                         for (Account acc : [Select BillingCountry, BillingPostalCode, BillingState,
//                                             BillingCity, BillingStreet From Account c WHERE Id = : oa.Associated_Opportunity__r.AccountId])
//                         {
//                                 newContact.MailingStreet=acc.BillingStreet;
//                                 newContact.MailingCity=acc.BillingCity;
//                                 newContact.MailingCountry=acc.BillingCountry;
//                                 newContact.MailingPostalCode=acc.BillingPostalCode;
//                                 newContact.MailingState=acc.BillingState;
//                         }
//                         newContact.Validation_Override__c = true;
//                         //code here to add account Address to the Contact.
//                         insert newContact;
//                         if(recipientIndex == 1)
//                                 dseRecipient1.dsfs__DSER_ContactID__c = newContact.Id;
//                         else
//                                 dseRecipient2.dsfs__DSER_ContactID__c = newContact.Id;
//                         showPage = true;
//                         newContactFlag = false;
//                 }
//                 return null;
//         }
//         public PageReference newContactCancel()
//         {
//                 newContact = null;
//                 newContactFlag = false;
//                 showPage = true;
//                 return null;
//         }
//         public PageReference canceltoOppty()
//         {
//                 return new PageReference('/'+oa.Associated_Opportunity__c);
//         }
 }