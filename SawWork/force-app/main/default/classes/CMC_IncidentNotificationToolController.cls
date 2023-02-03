/*
 * Author   : Vamsee Surya S
 * Date     : 14th Feb 2017
 * Purpose  : This class is the controller of CMC_IncidentNotificationTool page and it will be used to create mailer.
 *             This is implemented as part of CMC project (CR 3426181) 
 * ---------------------------------------------------------------------------------------------------
 * 07-Dec-2020      Vamsee S		ESESP-3817(21.1) Service Incident Lightning Migration     
 */

public class CMC_IncidentNotificationToolController {

    public string typeId{get;set;}
    public string conditionId{get;set;}
    public string valueId{get;set;}
    public string FilterLogicId{get;set;}
    public String mailerFormInput{get;set;}
    public String mailerFormDataList{get;set;}
    public String savedMailerId{get;set;}
    public String allAttachmentId{get;set;}
    
    //This is used in VF page to get the value of selected template
    public string templateName{get;set;}
    public string onLoadSINumber{get;set;}
    public Id mailerId{get;set;}
    public Boolean isSaveSuccess{get;set;}
    public Boolean testEmailSent{get;set;}
    
    public string filterIdList{get;set;}
    public Boolean mailerApprovedVal{get;set;}
    public integer totalAccountCount{get;set;}
    public integer validEmailCount{get;set;}
    public integer invalidEmailCount{get;set;}
    public integer totalEmailCount{get;set;}
    public string savedJSONString{get;set;}
    public string allFileAttachmentId{get;set;}
    public string allFilterId{get;set;}
    public string updatedFilterJSON{get;set;}
    public string mailerIdForUpdate{get;set;}
    //public string selectionType{get;set;}
    
    
    
    
    //Mailer Object to access UI Elements
    public EB_AkaMailer__c mailerObject{get;set;}
    public string SINumber{get;set;}

    //varible for getting count for progress bar
    public integer completionPercentage{get;set;}
    public integer successCount{get;set;}
    public integer failureCount{get;set;}
    public integer totalCount{get;set;}
    public string sendMailerStatus{get;set;}
    public boolean enbledPoller{get;set;}
    public string mailerName{get;set;}
    public string mailerSubject{get;set;}
    public string peerReviewer{get;set;}
    public string preMailerErrorReportId{get;set;}
    public Id filterIdForDelete{get;set;}
    //To display the error messages on the page.
    public string errorMessage{get;set;}
    public boolean hasAllAccountCreated{get;set;}
    public boolean isSendTestEmailEnabled{get;set;}
    public string mailerStatus{get;set;}
    public string contactRadioDefault{get;set;}
    
    
    //This map will store Name and Id of the templates
    map<String, EmailTemplate> templateNameObjectMap  = new map<String, EmailTemplate>();

    //This metadata stores all the settings related to CMC
    CMC_Settings__mdt  cmcSettings;
    
    //This method is to display the Template names as picklist values
    public List<SelectOption> getTemplateNames(){

        String userProfile = [Select id, Name from Profile where id = :userinfo.getProfileId() limit 1].Name;

        List<String> folderNames = new List<String>();
        for(CMC_INT_Public_groups_mapping__mdt eachrec : [Select id, DeveloperName, Email_Folder__c, Profile_Name__c from CMC_INT_Public_groups_mapping__mdt where DeveloperName != 'INT']){
            if(String.isNotBlank(eachrec.Profile_Name__c) && eachrec.Profile_Name__c.containsIgnoreCase(userProfile))
                for(String str : eachrec.Email_Folder__c.split(','))
                    folderNames.add(str.trim());
        }
        if(folderNames.size()==0){
            String strFolderNames = [Select id, DeveloperName, Email_Folder__c from CMC_INT_Public_groups_mapping__mdt where DeveloperName = 'INT' limit 1].Email_Folder__c;
            for(String str : strFolderNames.split(','))
                    folderNames.add(str.trim());
        }
        List<SelectOption> TemplateNames = new List<SelectOption>();
        TemplateNames.add(new SelectOption('','--None--'));
        for(EmailTemplate template : [select Id, Name,Folder.Name from EmailTemplate where folder.developername In :folderNames AND IsActive = True]) {
                TemplateNames.add(new SelectOption(template.Name,template.Name));  
                templateNameObjectMap.put(template.Name, template);
        }
        return TemplateNames;
    }
    
    //This method is called when user click on Save from VF Page
    public void createMailerData() {  
            createMailer(mailerFormInput);       
    }
    
    public void updateFilterListValue(){
        getTypes();
    }
    
    //List of fields for Filters
    public List<SelectOption> getTypes() {
        List<SelectOption> options;
        //if(options != Null) options.clear();
        //if(selectionType != 'authorizedContacts'){

            options = new List<SelectOption>();
            options.add(new SelectOption('--None--','--None--'));
            options.add(new SelectOption('Account ID','Account ID'));
            options.add(new SelectOption('Customer Name','Customer Name'));
            options.add(new SelectOption('Geography','Geography'));
            options.add(new SelectOption('Support Level','Support Level'));
            options.add(new SelectOption('Tier','Tier'));
            options.add(new SelectOption('Marketing Product Name','Marketing Product Name'));
            options.add(new SelectOption('Policy Domain Name','Policy Domain Name'));
   
        
        return options;
    }

    //List of operators for Filters
    public List<SelectOption> getConditions() {

        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('--None--','--None--'));
        options.add(new SelectOption('Equal To','Equal To'));
        options.add(new SelectOption('Not Equal To','Not Equal To'));
        options.add(new SelectOption('Contains','Contains'));
        options.add(new SelectOption('Does Not Contain','Does Not Contain'));
        options.add(new SelectOption('In','In'));
 
        return options;
    }
    
    public List<SelectOption> getRadioItems() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('24x7Contact','24x7 Contact Types'));
        options.add(new SelectOption('manualEmail','Only Send To Manually Entered Email Addresses'));
        options.add(new SelectOption('authorizedContacts','Authorized Contacts'));

        return options;
    }
    
    /*Constructor*/
    public CMC_IncidentNotificationToolController(ApexPages.StandardController ctlr)
    {
        id mailerIdFromPage = ApexPages.currentPage().getParameters().get('id');
        
        cmcSettings = [SELECT CMC_Default_Account_Id__c, CMC_Default_Contact_Id__c, Default_From_Email_Address__c FROM CMC_Settings__mdt WHERE DeveloperName = 'CMC'];
        preMailerErrorReportId = [SELECT Pre_Mailer_Exception_Report__c FROM CMC_Report_Ids__c limit 1].Pre_Mailer_Exception_Report__c;
        mailerObject = new EB_AkaMailer__c();
        enbledPoller = false;
        testEmailSent = false;
        mailerApprovedVal = false;
        hasAllAccountCreated = false;
        mailerName = '';
        completionPercentage = 0;
        totalCount = 0;
        successCount = 0;
        failureCount = 0;
        allFilterId = '';
        allFileAttachmentId = '';
        peerReviewer = '';
        isSendTestEmailEnabled = true;
        contactRadioDefault = '24x7Contact';

        if(mailerIdFromPage != Null){
            
            mailerObject = [select Id,Name,EB_Status__c,CMC_AllFileAttachmentId__c,CMC_AllFilterId__c,CMC_JSONStringAfterSave__c,CMC_Subject__c,EB_AdditionalIssueDescription__c,CMC_IRAPT_SI_Number__c ,CMC_Peer_Reviewer__c,CMC_Peer_Reviewer__r.Name,CMC_Approval_Status__c,CMC_Reviewer_Comments__c,CMC_Template_Name__c,CMC_Is_Approved__c,CMC_24x7_Contact_Types__c,CMC_Query_String__c,CMC_Manual_Email_Addresses__c,AuthCon_Authorized_Contacts__c from EB_AkaMailer__c where id =: mailerIdFromPage limit 1];
            
            savedJSONString = mailerObject.CMC_JSONStringAfterSave__c;
            templateName = mailerObject.CMC_Template_Name__c;
            onLoadSINumber = mailerObject.CMC_IRAPT_SI_Number__c;
            sendMailerStatus = mailerObject.EB_Status__c;
            mailerSubject = mailerObject.CMC_Subject__c;
            mailerId = mailerObject.id;
            mailerName = mailerObject.name;
            allFilterId = mailerObject.CMC_AllFilterId__c;
            peerReviewer = mailerObject.CMC_Peer_Reviewer__r.Name;
            isSendTestEmailEnabled = false;
            allFileAttachmentId = (mailerObject.CMC_AllFileAttachmentId__c  != Null || mailerObject.CMC_AllFileAttachmentId__c  != '[]') ? mailerObject.CMC_AllFileAttachmentId__c  : '';
            if(allFileAttachmentId != Null){
                allFileAttachmentId.trim();
                allFileAttachmentId.replaceAll('null','');

            }
            //To get the count of Accounts or Count of email addresses when page loads
            if(mailerObject.CMC_24x7_Contact_Types__c == True || mailerObject.AuthCon_Authorized_Contacts__c == True){
                totalAccountCount = CMC_MailerHelper.GetAccountsCount(mailerObject.Id);
            }
            else{
                List<Integer> emailsCount = CMC_MailerHelper.GetEmailsCount(mailerObject.CMC_Manual_Email_Addresses__c,mailerObject.Id);
                totalEmailCount = emailsCount[0];
                validEmailCount = emailsCount[1];
                invalidEmailCount = emailsCount[2];
            }  
        }     
    }
    
    
    /* This method parse the json string and creates mailer object
     */
    public void createMailer(String jsonString){
        EB_AkaMailer__c mailerObjectTemp;
        if(mailerObject.Id != Null){
            //Is approved field is getting set in other method hence it is required to get the latest value from the database
            mailerObjectTemp = [select CMC_Is_Approved__c from EB_AkaMailer__c where id =: mailerObject.Id limit 1];
            mailerObject.CMC_Is_Approved__c = mailerObjectTemp.CMC_Is_Approved__c;
        }
            
        Map<String, Object> jsonMap = (Map<String, Object>)JSON.deserializeUntyped(jsonString);
        map<String, Object> accountInfoMap = (map<String, Object>)jsonMap.get('AccountInfo');
        id mailerIdFromPage = ApexPages.currentPage().getParameters().get('id');

        //Setting the record type to CMC
        mailerObject.RecordTypeId = Schema.SObjectType.EB_AkaMailer__c.getRecordTypeInfosByName().get('CMC').getRecordTypeId();

        //Update the type of email based on the template selection by checking folder of the template
        if(templateName != null){
            mailerObject.CMC_Template_Name__c = templateName;
            EmailTemplate selectedTemplate = templateNameObjectMap.get(templateName);
            mailerObject.CMC_Template_ID__c = selectedTemplate.Id;
            if(selectedTemplate.Folder.Name.contains('Single'))
                mailerObject.EB_Type__c = 'Single Email';
            else if(selectedTemplate.Folder.Name.contains('Mass'))
                mailerObject.EB_Type__c = 'Mass Email';
        }
        else{
            mailerObject.CMC_Template_Name__c = null;
            mailerObject.CMC_Template_ID__c = null;
            mailerObject.EB_Type__c = 'Single Email';
        }

        //This String stores the JSON of filter 
        String jsonFilterString;

        //If Approved flag is True means no updation in the customer selection section.
        if(mailerObject.CMC_Is_Approved__c == False){
            mailerObject.EB_Status__c = 'Draft';

            //All the Count variables are defaulted to zero.
            totalEmailCount =0;
            validEmailCount=0;
            invalidEmailCount=0;
            totalAccountCount =0;
            mailerObject.CMC_JSONStringAfterSave__c  = jsonString;
            if(accountInfoMap.get('ContactType') == '24x7 Contact Types'){
                
                /* To Delete the attachment and also Attachment Id stored in the field. 
                 * This required because User can switch from imported/Manual Entered email to 24x7 Contact types
                 */
                if(mailerObject.Id != null){
                    CMC_MailerHelper.cleanUpBeforeSave(mailerObject.Id, 'Attachment');
                    mailerObject.CMC_Imported_Emails_AttachmentId__c = '';
                }
                mailerObject.CMC_Manual_Email_Addresses__c = '';

                mailerObject.CMC_24x7_Contact_Types__c = True;
                mailerObject.AuthCon_Emergency_Notification_Recipient__c = False;
                mailerObject.AuthCon_Maint_Notification_Recipient__c = False;
                mailerObject.AuthCon_Authorized_Contacts__c = False;
                
                Set<Object> accountTypeSet = new set<Object>((List<Object>)accountInfoMap.get('AccountType'));
                //Check for Customer type
                if(accountTypeSet.size() > 0){
                    //Check for Indirect Customer
                    if(accountTypeSet.contains('Indirect Customer'))
                        mailerObject.CMC_Indirect_Customers__c = True;
                    else
                        mailerObject.CMC_Indirect_Customers__c = False;
                    
                    //Check for Direct Customer
                    if(accountTypeSet.contains('Direct Customer'))
                        mailerObject.CMC_Direct_Customers__c = True;
                    else
                        mailerObject.CMC_Direct_Customers__c = False;
                    
                    //Check for Partners
                    if(accountTypeSet.contains('Partner'))
                        mailerObject.CMC_Partners__c = True;
                    else
                        mailerObject.CMC_Partners__c = False;
                
                }
                else{
                    //apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'No Option selected under section "Send Notification To".Please select atleast one option.'));
                }
                    
            }
            else if(accountInfoMap.get('ContactType') == 'Manual Email Addresses' || accountInfoMap.get('ContactType') == 'Import Email Addresses'){
                //Check for Default Contact Isbounced flag
                String result = CMC_MailerHelper.ValidateContactEmail();
                if(result != 'Valid'){
                    errorMessage = result;
                    apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,result));  
                }


                if(mailerObject.Id != null){
                    //Delete all the filters associated with the mailer
                    CMC_MailerHelper.cleanUpBeforeSave(mailerObject.Id, 'Filter');

                    //Delete the QueryString Attachment
                    CMC_MailerHelper.cleanUpBeforeSave(mailerObject.Id, 'QueryString');

                    if((String)jsonMap.get('forDelete') == 'true'){
                        //Delete the old attachment
                        CMC_MailerHelper.cleanUpBeforeSave(mailerObject.Id, 'Attachment');
                    }   
                 }
                
                filterIdList = '';
                allFilterId = '';
                jsonFilterString = '';  
                mailerObject.CMC_AllFilterId__c = '';
                mailerObject.CMC_24x7_Contact_Types__c = False;
                mailerObject.CMC_All_Customers__c = False;
                mailerObject.CMC_Selected_Customers__c = False;
                mailerObject.CMC_Indirect_Customers__c = False;
                mailerObject.CMC_Direct_Customers__c = False;
                mailerObject.CMC_Partners__c = False;
                mailerObject.AuthCon_Emergency_Notification_Recipient__c = False;
                mailerObject.AuthCon_Maint_Notification_Recipient__c = False;
                mailerObject.AuthCon_Authorized_Contacts__c = False;
                mailerObject.CMC_Query_String__c = '';
                if(accountInfoMap.get('EmailTextArea') != null){
                    mailerObject.CMC_Manual_Email_Addresses__c = (String)accountInfoMap.get('EmailTextArea');
                    
                    /* Delete the Attachment and Attachement Id Stored in the field
                     * This required because user can swich from imported emaill address to manual entered email address
                     */
                    CMC_MailerHelper.cleanUpBeforeSave(mailerObject.Id, 'Attachment');
                    mailerObject.CMC_AllFileAttachmentId__c = '[]';
                    mailerObject.CMC_Imported_Emails_AttachmentId__c = '';
                    
                }
                else{
                    mailerObject.CMC_Manual_Email_Addresses__c = null;
                }
            }
            else if(accountInfoMap.get('ContactType') == 'Authorized Contacts'){
                /* To Delete the attachment and also Attachment Id stored in the field. 
                 * This required because User can switch from imported/Manual Entered email to Authorized Contacts
                 */
                if(mailerObject.Id != null){
                    CMC_MailerHelper.cleanUpBeforeSave(mailerObject.Id, 'Attachment');
                    mailerObject.CMC_Imported_Emails_AttachmentId__c = '';
                }
                mailerObject.CMC_Manual_Email_Addresses__c = '';
                mailerObject.CMC_24x7_Contact_Types__c = False;
                mailerObject.AuthCon_Authorized_Contacts__c = True;
                mailerObject.CMC_Indirect_Customers__c = False;
                mailerObject.CMC_Direct_Customers__c = False;
                mailerObject.CMC_Partners__c = False;
                
                Set<Object> accountTypeSet = new set<Object>((List<Object>)accountInfoMap.get('AccountType'));
                //Check for Customer type
                if(accountTypeSet.size() > 0){
                    if(accountTypeSet.contains('Emergency Notification Recipients')){
                        mailerObject.AuthCon_Emergency_Notification_Recipient__c = True;
                        mailerObject.AuthCon_Maint_Notification_Recipient__c = False;
                    }
                    else{
                        mailerObject.AuthCon_Emergency_Notification_Recipient__c = False;
                        mailerObject.AuthCon_Maint_Notification_Recipient__c = True;
                    }
                }
                
                
            }
            else{
               // apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please Select Customer Contact Type'));
            }

            if(accountInfoMap.get('ContactType') == 'Authorized Contacts' || accountInfoMap.get('ContactType') == '24x7 Contact Types')
                if(accountInfoMap.get('CustomerSelection') == ' Selected Customers'){
                    mailerObject.CMC_All_Customers__c = False;
                    mailerObject.CMC_Selected_Customers__c = True;
                    List<Object> filterList = (List<Object>)jsonMap.get('Filters');
                    if(filterList.size() > 0){
                        //Filter part of JSON String
                        jsonFilterString = JSON.serialize(jsonMap.get('Filters'));
                        mailerObject.CMC_Filter_Logic__c = (String)jsonMap.get('FilterLogic');
                    }
                    else{
                        //apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'First filter can not be Empty. Please populate the first filter to save.'));
                    }
                }
                else If(accountInfoMap.get('CustomerSelection') == ' All Customers'){
                    /* Delete the filters
                     * This required because users can switch from Selected Customers to All Customers
                     */
                    CMC_MailerHelper.cleanUpBeforeSave(mailerObject.Id, 'Filter');
                    mailerObject.CMC_All_Customers__c = True;
                    mailerObject.CMC_Selected_Customers__c = False;
                    mailerObject.CMC_AllFileAttachmentId__c = '[]';
                    mailerObject.CMC_AllFilterId__c = '';
                    jsonFilterString = '';
                }
        }

        try{
            Upsert mailerObject;
            mailerName = mailerObject.Name;

            //If Filters are present
            if(!String.isBlank(jsonFilterString)){
                filterIdList = '';
                allFilterId ='';

                //This method return the list of filter objects by parsing the JSON filter string
                List<CMC_Mailer_Filter__c> filterObjectList = CMC_MailerHelper.ParseFilterJSON(jsonFilterString, mailerObject.Id);

                //Get the Id's of updated filters
                List<Id> filtersNotToDelete = new List<Id>();
                Map<Id,Id> filtersNotToDeleteMap = new Map<Id,Id>();
                For(CMC_Mailer_Filter__c eachFilter : filterObjectList){
                    if(eachFilter.Id != null){
                        filtersNotToDelete.add(eachFilter.Id);
                        filtersNotToDeleteMap.put(eachFilter.Id, eachFilter.Id);
                    }
                }

                //Delete the removed filters or Filters for which attachment is changed are deleted
                List<CMC_Mailer_Filter__c> filtersToDeleteList = [SELECT Id FROM CMC_Mailer_Filter__c WHERE CMC_Filter_Mailer__c = :mailerObject.Id AND Id NOT In :filtersNotToDelete];
                Delete filtersToDeleteList;
                
                //Objects with Id will be updated and others will be inserted
                Upsert filterObjectList;
                
                //Filters with attachments
                for(CMC_Mailer_Filter__c forEach : filterObjectList){
                    allFilterId = allFilterId + '{"CMC_Filter_Order__c":"'+(forEach.CMC_Filter_Order__c).intvalue()+'",'+'"Id":"'+forEach.Id+'"},';
                    //Add all the filter Ids which contains Attachment
                    if(forEach.CMC_Filter_Condition__c == 'In' && String.isBlank(forEach.CMC_Filter_Value__c) && (!filtersNotToDeleteMap.containsKey(forEach.id))){ 
                        filterIdList = filterIdList + forEach.id + ',';
                    }
                }
                allFilterId = '{"allFilters":['+allFilterId.removeEnd(',')+']}';
                allFilterId = allFilterId.startsWith('null') ? allFilterId.substringAfter('null') : allFilterId;
                mailerObject.CMC_AllFilterId__c = allFilterId;
                Update mailerObject;
            }
            
        }
        catch(Exception ex){
            apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            System.debug('--Exception in CMC_MailerHelper Class--');
            System.debug('Line Number :'+ex.getLineNumber());
            System.debug('Message :'+ex.getMessage()); 
        }    
        if(mailerObject.id != Null){
            isSaveSuccess = true;
            mailerId = mailerObject.id;
            isSendTestEmailEnabled = false;
        }        
       //return null;
    }
    
    //This method will be called after createmailer from the VF page
    Public void queryBuildForAttachment(){

        try{
            EB_AkaMailer__c mailer = [Select Id,CMC_Filter_Logic__c,CMC_Imported_Emails_AttachmentId__c, CMC_AllFileAttachmentId__c,CMC_All_Customers__c,CMC_24x7_Contact_Types__c,CMC_Query_String__c,CMC_Manual_Email_Addresses__c ,CMC_Indirect_Customers__c,CMC_Direct_Customers__c,CMC_Partners__c,CMC_Approval_Status__c,CMC_Is_Approved__c,AuthCon_Authorized_Contacts__c, AuthCon_Emergency_Notification_Recipient__c, AuthCon_Maint_Notification_Recipient__c, (Select CMC_Filter_Condition__c,CMC_Filter_Field__c,CMC_Filter_Order__c,CMC_Filter_Value__c from CMC_Mailer_Filters__r ) from  EB_AkaMailer__c where Id = :mailerObject.Id Limit 1];
            mailer.CMC_AllFileAttachmentId__c = buildUrlForAttachment();
            
            //If 24X7 Contact type is true then update the query string else update the Email Address Count for manual entered email addresses
            if(mailer.CMC_24x7_Contact_Types__c == True && mailer.CMC_Is_Approved__c == False){
                //If All Customers = False Means Selected Customers. Update the attachment Id on the filter which contains attachment as value
                if(mailer.CMC_All_Customers__c == False){
                    CMC_MailerHelper.UpdateAttachmentIds(mailer.Id);
                }

                //This method will return the query string based on the Notification recepients section
                String queryString = CMC_MailerHelper.GenerateQuery(mailer);

                //Query string will be stored as an attachment on the mailer
                CMC_MailerHelper.QueryStringAttachment(queryString,mailer.Id);

                //If mailer is approved then Mailer accounts need to be inserted
                if(mailer.CMC_Approval_Status__c == 'Approved'){
                    mailer.CMC_Is_Approved__c = true;
                    CMC_MailerHelper.createAccount(queryString, mailer);
                    //List<EB_AkaMAccount__c> mailerAccountList = CMC_MailerHelper.createAccount(queryString, mailer);
                    //Insert mailerAccountList;
                }
                Update mailer;

                //To get the count of accounts selected 
                totalAccountCount = CMC_MailerHelper.GetAccountsCount(mailer.Id);
            }
            //If Authorized Contacts type is true then update the query string else update the Email Address Count for manual entered email addresses
            else if(mailer.AuthCon_Authorized_Contacts__c == True && mailer.CMC_Is_Approved__c == False){
                //If All Customers = False Means Selected Customers. Update the attachment Id on the filter which contains attachment as value
                if(mailer.CMC_All_Customers__c == False){
                    CMC_MailerHelper.UpdateAttachmentIds(mailer.Id);
                }
                
                //This method will return the query string based on the Notification recepients section
                String queryString = CMC_MailerHelper.GenerateQueryForSOCC(mailer);
                
                //Query string will be stored as an attachment on the mailer
                CMC_MailerHelper.QueryStringAttachment(queryString,mailer.Id);

                //If mailer is approved then Mailer accounts need to be inserted
                if(mailer.CMC_Approval_Status__c == 'Approved'){
                    mailer.CMC_Is_Approved__c = true;
                    CMC_MailerHelper.createAccount(queryString, mailer);
                    //List<EB_AkaMAccount__c> mailerAccountList = CMC_MailerHelper.createAccount(queryString, mailer);
                    //Insert mailerAccountList;
                }
                Update mailer;

                //To get the count of accounts selected 
                totalAccountCount = CMC_MailerHelper.GetAccountsCount(mailer.Id);
            }
            
            //Not required to calculate the query string since the customer selection is read only after peer review.
            else if((mailer.CMC_24x7_Contact_Types__c == True || mailer.AuthCon_Authorized_Contacts__c == True) && mailer.CMC_Is_Approved__c == True){
                totalAccountCount = CMC_MailerHelper.GetAccountsCount(mailer.Id);
            }
            else{
                //Get the count of email addresses
                List<Integer> emailsCount = CMC_MailerHelper.GetEmailsCount(mailer.CMC_Manual_Email_Addresses__c,mailer.Id);
                totalEmailCount = emailsCount[0];
                validEmailCount = emailsCount[1];
                invalidEmailCount = emailsCount[2];
                //Update the attachment Id on Mailer for imported Email addresses
                if(String.isBlank(mailer.CMC_Manual_Email_Addresses__c) && mailer.CMC_Is_Approved__c == False){
                    List<Attachment> attachmentList = [SELECT ID FROM Attachment WHERE ParentId =: mailer.Id];
                    if(attachmentList.size() == 1){
                        mailer.CMC_Imported_Emails_AttachmentId__c = attachmentList[0].Id;
                    }
                }
                //If mailer is approved then Default mailer Account need to be inserted
                if(mailer.CMC_Approval_Status__c == 'Approved' && mailer.CMC_Is_Approved__c == False){
                    mailer.CMC_Is_Approved__c = true;
                    CMC_MailerHelper.createAccount('', mailer);
                    //List<EB_AkaMAccount__c> mailerAccountList = CMC_MailerHelper.createAccount('', mailer);
                    //Insert mailerAccountList;
                }
                Update mailer; 
            }
            //return true;
        }
        catch(Exception ex){
           apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            System.debug('--Exception in CMC_MailerHelper Class--');
            System.debug('Line Number :'+ex.getLineNumber());
            System.debug('Message :'+ex.getMessage()); 
            //return false;
        }
        
    }
    
    //method to update attachment id on mailer
    public String buildUrlForAttachment(){
        string allFilterAttJSON;
        list<CMC_Mailer_Filter__c> filterListAfterSave = [select Id,CMC_Filter_Order__c,CMC_Filter_Value__c, CMC_Filter_Condition__c,(SELECT Id, Name FROM Attachments) from CMC_Mailer_Filter__c where CMC_Filter_Mailer__c = :mailerObject.Id];
        list<EB_AkaMailer__c> mailerManualEmailAtt = [select id,(SELECT Id, Name FROM Attachments) from EB_AkaMailer__c where Id = :mailerObject.Id];
        if(filterListAfterSave.size()>0){
            allFilterAttJSON = '';
            for(CMC_Mailer_Filter__c forEachFilter :filterListAfterSave){
                for(Attachment att :forEachFilter.attachments){
                    if(forEachFilter.CMC_Filter_Condition__c == 'In' && (forEachFilter.CMC_Filter_Value__c == Null || forEachFilter.CMC_Filter_Value__c == '')){
                        allFilterAttJSON += '{"slNo":'+forEachFilter.CMC_Filter_Order__c+',"attachmentId":"'+att.Id+'","filename":"'+att.Name+'"},';
                    }
                }  
            }
            if(allFilterAttJSON != Null){
                allFilterAttJSON = allFilterAttJSON.removeEnd(',');
                allFilterAttJSON = '['+allFilterAttJSON+']';
                if(allFilterAttJSON.startsWithIgnoreCase('null')){
                    allFilterAttJSON = allFilterAttJSON.substringAfter('null');
                }
            }
        }
        
        else if(mailerManualEmailAtt[0].attachments.size()>0){
            for(EB_AkaMailer__c forEachFilter :mailerManualEmailAtt){
                for(Attachment att :forEachFilter.attachments){
                   allFilterAttJSON += '[{"slNo":'+'""'+',"attachmentId":"'+att.Id+'","filename":"'+att.Name+'"}]'; 
                }  
            }
            if(allFilterAttJSON != Null && allFilterAttJSON.startsWithIgnoreCase('null')){
               allFilterAttJSON = allFilterAttJSON.substringAfter('null');
                
            }
        }
        
        return allFilterAttJSON;
    }


    
    
    //This method will send the Test email to the logged in user
    public void sendTestEmail(){

        //Send Test Email Should be called only after mailer is saved
        If(mailerObject.Id != null){
            Try{
                EB_AkaMailer__c mailerObjectTemp = new EB_AkaMailer__c();
                mailerObjectTemp.Id = mailerObject.Id;
                
                //List to store the emails that need to be sent
                List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
                
                //Email Message
                Messaging.SingleEmailMessage emailMessage=new Messaging.SingleEmailMessage();
                emailMessage.setOrgWideEmailAddressId(cmcSettings.Default_From_Email_Address__c);
                
                //Subject, Content and Template need to be updated in the database when user clicks on send test email
                mailerObjectTemp.CMC_Subject__c = mailerObject.CMC_Subject__c;
                mailerObjectTemp.EB_AdditionalIssueDescription__c = mailerObject.EB_AdditionalIssueDescription__c;
                if(templateName != null){
                    //Getting the template Id and Calculating the type of the mailer
                    mailerObjectTemp.CMC_Template_Name__c = templateName;
                    EmailTemplate selectedTemplate = templateNameObjectMap.get(templateName);
                    mailerObjectTemp.CMC_Template_ID__c = selectedTemplate.Id;
                    if(selectedTemplate.Folder.Name.contains('Single'))
                        mailerObjectTemp.EB_Type__c = 'Single Email';
                    else if(selectedTemplate.Folder.Name.contains('Mass'))
                        mailerObjectTemp.EB_Type__c = 'Mass Email';
                    
                    //Prepare the Mail to send to logged in user
                    emailMessage.setTemplateId(templateNameObjectMap.get(templateName).Id);
                    List<Contact> userContactList = [Select Id from Contact where email =: userinfo.getUserEmail() Limit 1];
                    //If loggen user has contact with the same email address then we can use that contact
                    if(userContactList.size() == 1){
                        emailMessage.setTargetObjectId(userContactList[0].Id);
                        emailMessage.setSaveAsActivity(false);
                        emailMessage.setWhatId(mailerObjectTemp.Id);
                    }
                    else{
                        testEmailSent = false;
                        apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'No Contact is associated with the logged in user'));
                        errorMessage = 'No Contact is associated with the logged in user';
                        return;
                    }
                }
                else{
                    //Update the mailer object with the latest user selection
                    mailerObjectTemp.CMC_Template_Name__c = null;
                    mailerObjectTemp.CMC_Template_ID__c = null;
                    mailerObjectTemp.EB_Type__c = 'Single Email';
                    
                    ///Prepare the Mail to send to logged in user
                    List<String> toAddress = new List<String>();
                    toAddress.add(userinfo.getUserEmail());
                    emailMessage.setToAddresses(toAddress);
                    emailMessage.setSubject(mailerObjectTemp.CMC_Subject__c);
                    emailMessage.setHtmlBody(mailerObjectTemp.EB_AdditionalIssueDescription__c);
                }
                
                
                //Updating the Mailer with latest Template name, Subject, Content that user has selected.
                Update mailerObjectTemp;
                
                mails.add(emailMessage);
                List<Messaging.SendEmailResult> sendEmailResults = Messaging.sendEmail(mails);
                for(Messaging.SendEmailResult result : sendEmailResults) {
                    if(result.IsSuccess()){
                        testEmailSent = true;
                    }
                    else{
                        testEmailSent = false;
                        System.StatusCode statusCode = result.getErrors()[0].getStatusCode();
                        errorMessage = result.getErrors()[0].getMessage();
                        System.debug('Status code: ' + statusCode);
                        System.debug('Error msg: ' + errorMessage);
                    }
                }
            }
            Catch(Exception ex){
                System.debug('Exception : SendTestEmail');
                System.debug('Error Message :'+ ex.getMessage());
                errorMessage = ex.getMessage();
                apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,errorMessage));
                        
            }
        }
    }

    //Method for attaching files
    @RemoteAction
    public static String processChunk(boolean is24x7Type,String parentId, String attachmentId, String attachmentName, String base64ChunkPayload) {
        if(parentId != null) {
            CMC_Mailer_Filter__c  filter;
            EB_AkaMailer__c  mailer;

            if(is24x7Type){
              filter = getFilterMailer(parentId);
            }
            else{
              mailer = getMailer(parentId);
            }
            if(mailer != null || filter != null) {
                if(base64ChunkPayload != null) {
                    Attachment attachment = getAttachment(attachmentId);
                    String newBody = '';
                    if(attachment.Body != null) {
                        newBody = EncodingUtil.base64Encode(attachment.Body);
                    }
                    newBody += base64ChunkPayload;
                    attachment.Body = EncodingUtil.base64Decode(newBody);
                
                    if(attachmentId == null) {

                        attachment.Name = attachmentName;
                        
                        attachment.parentId = mailer != null ? mailer.Id : filter.id;
                    }
                    upsert attachment;
                    return attachment.Id;
                } else {
                    return 'Error:Attachment Body is null';
                }
            } else {
                return 'Error:Parent record could not be found';
            }
        } else {
            return 'Error:Parent Id is null';
        }
    }

    @TestVisible private static Attachment getAttachment(String attachmentId) {
        List<Attachment> attachments = [SELECT Id,ParentId,Body FROM Attachment WHERE Id =: attachmentId];
        if(attachments.isEmpty()) {
            Attachment a = new Attachment();
            return a;
        } 
        else {
            return attachments[0];
        }
    }
    
    @TestVisible private static CMC_Mailer_Filter__c getFilterMailer(String filterId){
        List<CMC_Mailer_Filter__c > filters = [SELECT Id, Name FROM CMC_Mailer_Filter__c WHERE Id =:filterId];
        List<Attachment> filterAtt = [SELECT Id,ParentId, Body FROM Attachment WHERE parentId =: filterId];
        if(!filterAtt.isEmpty())
            delete filterAtt;
        if(filters.isEmpty())
            return null;
        else 
            return filters[0];
    } 
    @TestVisible private static EB_AkaMailer__c getMailer(String mailerId){

        List<EB_AkaMailer__c > mailers = [SELECT Id, Name FROM EB_AkaMailer__c WHERE Id =:mailerId];
        if(mailers.isEmpty())
            return null;
        else
            return mailers[0];
    }
    
    //Called from action function on the page to update the JSON string with filter ID on the mailer
    public void updateFilterJSONWithId(){

        EB_AkaMailer__c ebMailer = new EB_AkaMailer__c();
        ebMailer.CMC_JSONStringAfterSave__c = updatedFilterJSON;
        ebMailer.id = mailerIdForUpdate;
        update ebMailer;
    }
    
    //This method will validate whether given SI number is valid or not
    public void ValidateSINumber(){

        Integer count = Database.countQuery('SELECT COUNT() FROM SC_SI_Service_Incident__c WHERE Name  =\''+SINumber+'\'');
        if(count == 0)
            apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'SI Number: No matches found.'));
    }
    
    
    //Method to get mailer total, success and failure count
    public void emailProcessCount(){

        enbledPoller = true;
        totalCount = 0;
        successCount = 0;
        failureCount = 0;
        completionPercentage = 0;
        mailerStatus = 'Calculating Total Email..';
    
        EB_AkaMailer__c getMailerProgressCount = new EB_AkaMailer__c();
        if(mailerObject.Id != Null){
            AggregateResult result;
            getMailerProgressCount = [select EB_Status__c,CMC_IS_50000_Limit_Crossed__c,CMC_No_of_Processed_Contacts__c,CMC_Total_Emails_Contacts__c from EB_AkaMailer__c where id =:mailerObject.Id limit 1];
            totalCount = getMailerProgressCount.CMC_Total_Emails_Contacts__c != Null ? Integer.valueOf(getMailerProgressCount.CMC_Total_Emails_Contacts__c) : totalCount;
            
            if(totalCount > 0){
               mailerStatus = 'Sending Email..'; 
            }
            
            if(getMailerProgressCount.EB_Status__c == 'Email Sent - Processing Contact'){ 
               result = [SELECT SUM(EB_TotalContacts__c) FROM EB_AkaMAccount__c WHERE EB_AkaMailer__c =: mailerObject.Id];
               successCount = Integer.valueOf(result.get('expr0'));
               failureCount = [select count() from EB_MailerException__c where EB_Mailer__c =:mailerObject.Id and CMC_stage__c = 'Post Mailer'];
               mailerStatus = getMailerProgressCount.EB_Status__c;
               completionPercentage = 10; 
               if(successCount > 0 || failureCount > 0 ){
                        completionPercentage = (((successCount+failureCount)*100)/totalCount) > 100 ? (((successCount+failureCount)*100)/totalCount) - 10 : (((successCount+failureCount)*100)/totalCount);
               } 
            }
            else if(getMailerProgressCount.EB_Status__c == 'Processed'){
                result = [SELECT SUM(EB_TotalContacts__c) FROM EB_AkaMAccount__c WHERE EB_AkaMailer__c =: mailerObject.Id];
                successCount = Integer.valueOf(result.get('expr0'));
                failureCount = [select count() from EB_MailerException__c where EB_Mailer__c =:mailerObject.Id and CMC_stage__c = 'Post Mailer'];
                mailerStatus = getMailerProgressCount.EB_Status__c; 
                CompletionPercentage = 100;
                enbledPoller = false; 
            }
            
            else if(getMailerProgressCount.EB_Status__c == 'Failed' || getMailerProgressCount.EB_Status__c == 'Email Sent - Failed to Process Contacts'){
               mailerStatus = getMailerProgressCount.EB_Status__c; 
               completionPercentage = 110;
               enbledPoller = false;
            } 
        }        
    }
    
    
    //Method to get new data from mailer and update the page
    public void reloadPage(){
        allFilterId = '';
        allFileAttachmentId = '';
        peerReviewer = '';
        
        if(mailerObject.Id != Null){
            
            mailerObject = [select Id, Name,EB_Status__c,CMC_AllFileAttachmentId__c,CMC_AllFilterId__c,CMC_JSONStringAfterSave__c,CMC_Subject__c,EB_AdditionalIssueDescription__c,CMC_IRAPT_SI_Number__c ,CMC_Peer_Reviewer__c,CMC_Peer_Reviewer__r.Name,CMC_Approval_Status__c,CMC_Reviewer_Comments__c,CMC_Template_Name__c,CMC_Is_Approved__c,CMC_24x7_Contact_Types__c,CMC_Query_String__c,CMC_Manual_Email_Addresses__c,AuthCon_Authorized_Contacts__c from EB_AkaMailer__c where id =: mailerObject.Id limit 1];
            
            savedJSONString = mailerObject.CMC_JSONStringAfterSave__c;
            templateName = mailerObject.CMC_Template_Name__c;
            onLoadSINumber = mailerObject.CMC_IRAPT_SI_Number__c;
            sendMailerStatus = mailerObject.EB_Status__c;
            mailerSubject = mailerObject.CMC_Subject__c;
            mailerId = mailerObject.id;
            mailerName = mailerObject.name;
            allFilterId = mailerObject.CMC_AllFilterId__c;
            peerReviewer = mailerObject.CMC_Peer_Reviewer__r.Name;
            allFileAttachmentId = (mailerObject.CMC_AllFileAttachmentId__c  != Null || mailerObject.CMC_AllFileAttachmentId__c  != '[]') ? mailerObject.CMC_AllFileAttachmentId__c  : '';
            
            if(allFileAttachmentId != Null && allFileAttachmentId.startsWith('null')){
                allFileAttachmentId.trim();
                allFileAttachmentId.substringAfter('null');
            }
            //To get the count of Accounts or Count of email addresses when page loads
            if(mailerObject.CMC_24x7_Contact_Types__c == True || mailerObject.AuthCon_Authorized_Contacts__c == True){
                totalAccountCount = CMC_MailerHelper.GetAccountsCount(mailerObject.Id);
            }
            else{
                List<Integer> emailsCount = CMC_MailerHelper.GetEmailsCount(mailerObject.CMC_Manual_Email_Addresses__c,mailerObject.Id);
                totalEmailCount = emailsCount[0];
                validEmailCount = emailsCount[1];
                invalidEmailCount = emailsCount[2];
            }  
        }  
    }
}