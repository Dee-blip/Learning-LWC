/*
Author          : Sheena, Vamsee
Description     : Controllor Class for INT Tool
Called From		: 
Test Class		: SC_SI_INT_Tool_Test

Date                Developer             JIRA #                            Description                                                       
----------------------------------------------------------------------------------------------------------------------------------
22 Dec 2021       	Sheena	              ESESP-3795               		    Initial Version
30 Apr 2021			Sheena				  ESESP-5274					 	Restricting External Users to be marked as Peer Reviewer
25 Mar 2021       	Sheena                ESESP-5392           				Restricting users to delete filters manually
4  Aug 2021       	Sheena                ESESP-5690          				Making Mass Email as default type for SOCC
2  Jun 2021			Sheena				  ESESP-6818						Send Reminder Emails for SOCC

----------------------------------------------------------------------------------------------------------------------------------

*/

public class SC_SI_INT_Tool_Controller {
    
    // Boolean to bypass delete restriction for Filter deletion in Mailer Filter trigger.
    public static Boolean byPassFilterDeletion = false;
    
    // This method returna a map of template name and template
    @AuraEnabled
    public static Map<String,EmailTemplate> getTemplateNames(){
        // Map of Template name and Template
        Map<String, EmailTemplate> templateNameObjectMap = new  Map<String, EmailTemplate>();
        //List of folder names
        List<String> folderNames = new List<String>();
        
        String strFolderNames = [Select id, DeveloperName, Email_Folder__c from CMC_INT_Public_groups_mapping__mdt where DeveloperName = 'INT' limit 1].Email_Folder__c;
        
        for(String str : strFolderNames.split(',')){
            folderNames.add(str.trim());
        }
        
        for(EmailTemplate template : [select Id, Name,Folder.Name from EmailTemplate where folder.developername In :folderNames AND IsActive = True]) {
            templateNameObjectMap.put(template.Name, template);
        }
        return templateNameObjectMap;
    }
    
    // Method to create Mailer Record
    @AuraEnabled
    public static Map<String,String> saveMailer(String mailerJSON, String filterJSON, String mailerId, Boolean peerReviewEnabled, Map<String,EmailTemplate> templateNameObjectMap){
        
        // Deserializing mailerJSON
        Map<String, String> mMailerData = (Map<String,String>)JSON.deserialize(mailerJSON,Map<String,String>.class);
        
        // Map to store template info
        List<String> folderNames = new List<String>();
        //  map<String, EmailTemplate> templateNameObjectMap  = new map<String, EmailTemplate>();
        
        // Map to store filter data, Mailer Id to be returned
        Map<String, String> mCreatedFilterData = new  Map<String, String>();
        
        // For deleting the attachments/filters if the mailer exists(New filters/attachments will be created) as the data on mailer can be changed
        List<Attachment> attachmentsToDelete;
        List<ContentDocumentLink> importedEmailFile;
        List<CMC_Mailer_Filter__c> filtersToDelete = new  List<CMC_Mailer_Filter__c>();
        
        CMC_Settings__mdt cmcMetadatarec = [select Id,Default_SOCC_Email_Type__c,Default_Mass_Email_Type_for_24_7_Contact__c from CMC_Settings__mdt where MasterLabel = 'CMC' limit 1];
        
        // Boolean to check if the mailer exists
        Boolean mailerExists = false;
        
        // Checking if the mailer exists
        if(mailerId!='' && mailerId!=null){
            mailerExists=true;
        }
        
        // Upserting Mailer Record
        EB_AkaMailer__c newMailer = new EB_AkaMailer__c(Id=mailerId);
        
        // If Mailer Exists clean the existing data 
        if(mailerExists==true){
            
            newMailer.CMC_Template_Name__c  =  '';
            newMailer.CMC_Template_ID__c = '';
            newMailer.EB_Type__c = 'Single Email';
            
            newMailer.CMC_Filter_Logic__c='';
            newMailer.CMC_Selected_Customers__c = false;
            newMailer.CMC_All_Customers__c = false;
            
            newMailer.AuthCon_Authorized_Contacts__c =false;
            newMailer.AuthCon_Emergency_Notification_Recipient__c = false;
            newMailer.AuthCon_Maint_Notification_Recipient__c  = false;
            newMailer.Reminder__c = null;
            newMailer.Reminder_Scheduled__c = false;
            
            newMailer.CMC_24x7_Contact_Types__c =false;
            newMailer.CMC_Partners__c = false;
            newMailer.CMC_Direct_Customers__c  = false;
            newMailer.CMC_Indirect_Customers__c = false;
            
            newMailer.CMC_Manual_Email_Addresses__c ='';
            
            filtersToDelete = [Select Id from CMC_Mailer_Filter__c where CMC_Filter_Mailer__c =: newMailer.Id];
            
            
            if(mMailerData.get('ContactType')=='Only Send To Manually Entered Email Addresses'){
                attachmentsToDelete = [Select id from Attachment where ParentId =:mailerId];
                if(mMailerData.get('ManualAttachmentLink')==null){
                    importedEmailFile = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: mailerId];
                    newMailer.CMC_Imported_Emails_AttachmentId__c ='';
                }
            }
            else{
                importedEmailFile = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: mailerId];
                newMailer.CMC_Imported_Emails_AttachmentId__c ='';
            }
            
            try{
                if(!importedEmailFile.isEmpty() ){
                    delete importedEmailFile;
                }
                if(!attachmentsToDelete.isEmpty()){
                    delete attachmentsToDelete;
                }
                
            }
            catch(exception ex){
                system.debug('error while deleting Imported Email Attachmnet//'+ex.getMessage()); 
            }
            
        }
        
        // Mapping data from the INT form to the Mailer Object
        newMailer.RecordTypeId = Schema.SObjectType.EB_AkaMailer__c.getRecordTypeInfosByName().get('CMC').getRecordTypeId();
        newMailer.CMC_IRAPT_SI_Number__c =  mMailerData.get('CMC_IRAPT_SI_Number__c') != '' ? mMailerData.get('CMC_IRAPT_SI_Number__c') : null ;
        newMailer.CMC_Subject__c  =  mMailerData.get('Subject');
        newMailer.EB_Status__c = 'Draft';
        
        if( mMailerData.get('Template')!=null &&  mMailerData.get('Template')!='' && mMailerData.get('Template')!='None'){
            newMailer.CMC_Template_Name__c  =  mMailerData.get('Template');
            EmailTemplate selectedTemplate = templateNameObjectMap.get(mMailerData.get('Template'));
            newMailer.CMC_Template_ID__c = selectedTemplate.Id;
            newMailer.EB_Type__c = selectedTemplate.Folder.Name.contains('Single') ? 'Single Email' : 'Mass Email';
            newMailer.EB_Type__c = selectedTemplate.Folder.Name.contains('Mass') ? 'Mass Email' : 'Single Email';
            
        }
        
        newMailer.EB_AdditionalIssueDescription__c = mMailerData.get('Content');
        
        if( mMailerData.get('ContactType')=='24x7 Contact Types' || mMailerData.get('ContactType')=='Authorized Contacts'){
            
            
            newMailer.CMC_Filter_Logic__c =  mMailerData.get('FilterLogic');
            newMailer.CMC_Selected_Customers__c  = mMailerData.get('CustomerGroupValue')=='Selected Customers' ? true : false;
            newMailer.CMC_All_Customers__c   = mMailerData.get('CustomerGroupValue')=='All Customers' ? true : false;
            
            if( mMailerData.get('ContactType')=='24x7 Contact Types'){
                
                newMailer.CMC_24x7_Contact_Types__c =  true; 
                newMailer.CMC_Partners__c = mMailerData.get('AccountType').contains('Partner') ? true : false;
                newMailer.CMC_Direct_Customers__c = mMailerData.get('AccountType').contains('Direct Customer') ? true : false;
                newMailer.CMC_Indirect_Customers__c = mMailerData.get('AccountType').contains('Indirect Customer') ? true : false;
                if(cmcMetadatarec.Default_Mass_Email_Type_for_24_7_Contact__c)
                {
                    newMailer.EB_Type__c='Mass Email';
                }
            }
            
            if( mMailerData.get('ContactType')=='Authorized Contacts'){
                
                newMailer.AuthCon_Authorized_Contacts__c =true;
                newMailer.AuthCon_Emergency_Notification_Recipient__c = mMailerData.get('RecipientTypeValue').contains('Emergency Notification Recipients') ? true : false;
                newMailer.AuthCon_Maint_Notification_Recipient__c  = mMailerData.get('RecipientTypeValue').contains('Maintenance Notification Recipients') ? true : false;
                
                // Changes by Sheena - ESESP-5690- Making Mass Email as the default type for SOCC
               
                newMailer.EB_Type__c = cmcMetadatarec.Default_SOCC_Email_Type__c; 
                newMailer.Reminder__c = mMailerData.get('ReminderValue') != null ? DateTime.ValueofGMT(mMailerData.get('ReminderValue').replace('T', ' ')) : null;
                if(mailerExists && mMailerData.get('ReminderValue') != null){
                    Eb_Akamailer__c mailerRec = [Select Id, Parent_Mailer__c from Eb_Akamailer__c where id = :mailerId];
                    if(mailerRec.Parent_Mailer__c==null){
                        newMailer.Reminder_Scheduled__c = mMailerData.get('ReminderValue') != null ? true : false;
                    }
                }
            }
        }
        if( mMailerData.get('ContactType')=='Only Send To Manually Entered Email Addresses'){
            
            newMailer.CMC_Manual_Email_Addresses__c=  mMailerData.get('EmailInputValue')=='Enter Email Addresses' ? mMailerData.get('manualEmaliAddresses') : '';
            
        }
        
        if(peerReviewEnabled==true){
            newMailer.Peer_Review_Enabled__c = true;
            newMailer.CMC_Peer_Reviewer__c = mMailerData.get('PeerReviewer');
            newMailer.CMC_Approval_Status__c = mMailerData.get('ApprovalStatus') != null ?  mMailerData.get('ApprovalStatus') : '';
            newMailer.CMC_Reviewer_Comments__c  = mMailerData.get('ApprovalComments') != null ?  mMailerData.get('ApprovalComments') : '';
            
        }
        try{
            // Upserting Mailer record
            upsert newMailer;
            system.debug('newMailer//'+newMailer);
            
            // Creating filters when Contact Type is not 'Only Send To Manually Entered Email Addresses' and not for All Customers
            if(mMailerData.get('ContactType')!='Only Send To Manually Entered Email Addresses'){
                
                // Creating Filters
                if(filterJSON!=null && filterJSON!='' &&  newMailer.CMC_Selected_Customers__c==true){
                    mCreatedFilterData = createfilterRecs(filterJSON,newMailer.Id,mailerExists);
                }
                
                // For All Customers if the mailer exists, all the previously created filters will be deleted
                else if(filterJSON==''  &&  newMailer.CMC_All_Customers__c==true && mailerExists==true){
                    // Success means there is no filter creation or filter attachment
                    mCreatedFilterData.put('Success','Success');
                    try{
                        if(!filtersToDelete.isEmpty()){
                            delete filtersToDelete;
                            
                        }
                    }
                    catch(exception ex){
                        system.debug('error while deleting Filters for All Customers//'+ex.getMessage()); 
                    }
                }
                
                else{
                    mCreatedFilterData.put('Success','Success');  
                }
                
                // Adding the mailer id to be returned 
                mCreatedFilterData.put('Mailer_Id', newMailer.Id);
                
                return mCreatedFilterData;
            }
            
            // For Manually entered email type
            else{
                mCreatedFilterData.put('Mailer_Id', newMailer.Id);
                mCreatedFilterData.put('Success','Success');
                
                // Delete all the existing Mailer Filters
                if(!filtersToDelete.isEmpty()){
                    delete filtersToDelete;
                    
                }
                
                
                // EB_AkaMailer__c mailer = [SELECT CMC_Is_Approved__c FROM EB_AkaMailer__c where id = :newMailer.Id];
                // calling create Account
                if(newMailer.CMC_Approval_Status__c == 'Approved' && mMailerData.get('Is_Approved') == 'false'){
                    newMailer.CMC_Is_Approved__c = true;
                    Update newMailer;
                    SC_SI_INT_Tool_Helper.createAccount('', newMailer);
                }
                return mCreatedFilterData;
                
            }
            
        }
        catch(exception e){
            system.debug('error//'+e.getMessage());
            mCreatedFilterData.put('error',e.getMessage());
            return mCreatedFilterData;
        }
    }
    
    
    // Method to create Mailer Filters
    public static Map<String, String> createfilterRecs(String filterJSON, String mailerId, Boolean mailerExists){
        
        // Deserializing filterJSON
        List<FilterWrapper> filterData = (List<FilterWrapper>)JSON.deserialize(filterJSON, List<FilterWrapper>.class);
        // Set of Filters not be deleted when a file is attached to it.
        Set<Integer> filtersNotToBeDeleted = new Set<Integer>();
        // List of Filters to be created
        List<CMC_Mailer_Filter__c> filterList = new List<CMC_Mailer_Filter__c>();
        CMC_Mailer_Filter__c newFilter;
        // Map of Order Number and Filter Id for attached files
        Map<String, String> mFiltOrdFiltRec = new Map<String, String>();
        
        
        // If the mailer is edited, delete the previously created filters
        if(mailerExists==true){
            for(FilterWrapper eachFilter: filterData){
                if(eachFilter.downloadLink!=null && eachFilter.downloadLink!='' && eachFilter.downloadLink!='undefined'){
                    filtersNotToBeDeleted.add(eachFilter.Order);
                }
            }
            List<CMC_Mailer_Filter__c> filtersToDelete = [Select Id from CMC_Mailer_Filter__c where CMC_Filter_Mailer__c =: mailerId and CMC_Filter_Order__c !=: filtersNotToBeDeleted];
            try{
                byPassFilterDeletion = true;
                delete filtersToDelete;
                byPassFilterDeletion = false;
            }
            catch(exception ex){
                system.debug('error while deleting the existing filters//'+ ex.getMessage());
            }
        }       
        
        // Creating filters
        for(FilterWrapper eachFilter: filterData){
            if(!filtersNotToBeDeleted.contains(eachFilter.Order)){
                newFilter = new CMC_Mailer_Filter__c();
                newFilter.CMC_Filter_Mailer__c= mailerId;
                newFilter.CMC_Filter_Field__c = eachFilter.field;
                newFilter.CMC_Filter_Condition__c = eachFilter.condition;
                newFilter.CMC_Filter_Value__c = eachFilter.filterValue;
                newFilter.CMC_Filter_Order__c  = eachFilter.Order;
                // newFilter.CMC_Filter_Attachment__c = eachFilter.filterAttachment;
                filterList.add(newFilter);
            }
        }
        
        try{ 
            insert filterList;            
        }
        catch(exception e){
            system.debug('error//'+e.getMessage());
        }
        
        // Storing Order Number and Filter Id in a map to be returned for file creation related to the filters
        if(!filterList.isEmpty()){
            for(CMC_Mailer_Filter__c createdFilter: filterList){
                if(createdFilter.CMC_Filter_Condition__c=='In' && createdFilter.CMC_Filter_Value__c==''){
                    mFiltOrdFiltRec.put(String.valueOf(createdFilter.CMC_Filter_Order__c),createdFilter.Id);
                }                
            }
        }
        
        if (mFiltOrdFiltRec != null && !mFiltOrdFiltRec.isEmpty()) {
            return mFiltOrdFiltRec;
        }
        else{
            // Success means no file needs to be created for the filters
            mFiltOrdFiltRec.put('Success','Success');
            return mFiltOrdFiltRec;
        }        
    }
    
    
    // Method to create files on Filters and imported email addresses on Mailer. 
    @AuraEnabled
    public static String saveFile(list<Object> filesToInsert, String parentObject) {
        
        // List of Content Versions to be created
        List<ContentVersion> lstVersionsToInsert = new List<ContentVersion>();
        // List of Mailers/filter Ids
        List<String> filterWithAttachIds = new List<String>();
        // List of Mailer Filters to be updated with the attched file id
        List<CMC_Mailer_Filter__c> mailerFiltersToUpdate = new List<CMC_Mailer_Filter__c>();
        // List of Mailers to be updated with the attched file id
        List<EB_AkaMailer__c> mailerToUpdate = new List<EB_AkaMailer__c>();
                
        
        // Creating Content Versions
        for (Object file : filesToInsert) {
            FileInfo fileData = (FileInfo)JSON.deserialize(JSON.serialize(file), FileInfo.class);
            ContentVersion objCntVersion = new ContentVersion();
            objCntVersion.PathOnClient = fileData.Title;
            objCntVersion.Title = fileData.Title;
            objCntVersion.VersionData = fileData.VersionData;
            objCntVersion.FirstPublishLocationId = fileData.parentId;
            objCntVersion.IsMajorVersion = true;
            lstVersionsToInsert.add(objCntVersion);
            filterWithAttachIds.add(fileData.parentId);
            
        }
        
        try{
            insert lstVersionsToInsert;
            if(!lstVersionsToInsert.isEmpty()){
                
                // fetching the ContentDocumentLink for getting the file and the parent id
                List<ContentDocumentLink> conDocs = [SELECT ContentDocumentId, ContentDocument.Title, LinkedEntityId  FROM ContentDocumentLink where LinkedEntityId =: filterWithAttachIds];
                
                // Updating the filters with the attached file Id
                if(parentObject=='Filter'){
                    for(ContentDocumentLink eachConDoc: conDocs){
                        CMC_Mailer_Filter__c mailerFilter = new CMC_Mailer_Filter__c(Id=eachConDoc.LinkedEntityId);
                        mailerFilter.CMC_Filter_Attachment__c = eachConDoc.ContentDocumentId;
                        mailerFilter.Attachment_Name__c = eachConDoc.ContentDocument.Title;
                        mailerFiltersToUpdate.add(mailerFilter);
                    }
                }
                // Updating the Mailers with the attached emails file Id
                else if(parentObject=='Mailer'){
                    EB_AkaMailer__c mailerRec = new EB_AkaMailer__c(Id=conDocs[0].LinkedEntityId);
                    mailerRec.CMC_Imported_Emails_AttachmentId__c = conDocs[0].ContentDocumentId;
                    mailerRec.Attachment_Name__c = conDocs[0].ContentDocument.Title;
                    mailerToUpdate.add(mailerRec);
                }
                
            }
        }
        catch(exception e){
            system.debug('error//'+e.getMessage());
            
        }
        
        // Updating Mailer/Filters
        try{
            if(!mailerFiltersToUpdate.isEmpty()){
                update mailerFiltersToUpdate;
            }
            else if (!mailerToUpdate.isEmpty()){
                update mailerToUpdate;
            }
            return 'success';
        }
        catch(exception e){
            system.debug('error//'+e.getMessage());
            return 'Error while updating the Parent with Attachment Id : '+e.getMessage();
        }
        
    }
    
    
    // Fetching the Mailer data
    @AuraEnabled
    public static EB_AkaMailer__c getMailerData(Id mailerId){
        
        return [Select Id,Name,CMC_IRAPT_SI_Number__c,CMC_Subject__c, CMC_Template_Name__c,EB_Type__c,EB_AdditionalIssueDescription__c,
                CMC_Filter_Logic__c,CMC_Selected_Customers__c,CMC_All_Customers__c,CMC_24x7_Contact_Types__c,CMC_Partners__c,EB_Status__c,
                CMC_Direct_Customers__c,CMC_Indirect_Customers__c,AuthCon_Authorized_Contacts__c,AuthCon_Emergency_Notification_Recipient__c,
                AuthCon_Maint_Notification_Recipient__c,CMC_Manual_Email_Addresses__c,CMC_Imported_Emails_AttachmentId__c,Attachment_Name__c,
                Peer_Review_Enabled__c,CMC_Peer_Reviewer__c,CMC_Approval_Status__c,CMC_Reviewer_Comments__c,CMC_Is_Approved__c,Test_Email_Sent__c,OwnerId,Reminder__c,
                (Select Id,CMC_Filter_Mailer__c,CMC_Filter_Field__c,CMC_Filter_Condition__c,CMC_Filter_Value__c,CMC_Filter_Order__c,
                 CMC_Filter_Attachment__c,Attachment_Name__c from CMC_Mailer_Filters__r order by CMC_Filter_Order__c asc)
                from EB_AkaMailer__c where id=:mailerId];
        
    }
    
    
    //Send Test Email
    @AuraEnabled
    Public static string sendTestEmail(Id mailerId){
        
        string returnString = 'Success';
        //List to store the emails that need to be sent
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        
        EB_AkaMailer__c mailerObject = [SELECT Id, CMC_Template_ID__c, CMC_Subject__c, EB_AdditionalIssueDescription__c FROM EB_AkaMailer__c WHERE Id =: mailerId LIMIT 1];
        //Get the Default from Address
        CMC_Settings__mdt cmcSettings = [SELECT Default_From_Email_Address__c FROM CMC_Settings__mdt WHERE DeveloperName = 'CMC'];
        
        //Email Message
        Messaging.SingleEmailMessage emailMessage=new Messaging.SingleEmailMessage();
        emailMessage.setOrgWideEmailAddressId(cmcSettings.Default_From_Email_Address__c);
        
        if(mailerObject.CMC_Template_ID__c != null){
            emailMessage.setTemplateId(mailerObject.CMC_Template_ID__c);
            List<Contact> userContactList = [Select Id from Contact where email =: userinfo.getUserEmail() Limit 1];
            //If loggen user has contact with the same email address then we can use that contact
            if(userContactList.size() == 1){
                emailMessage.setTargetObjectId(userContactList[0].Id);
                emailMessage.setSaveAsActivity(false);
                emailMessage.setWhatId(mailerObject.Id);
            }
            else{
                returnString = 'No Contact is associated with the logged in user';
            }
            
        }
        else{
            //Prepare the Mail to send to logged in user
            List<String> toAddress = new List<String>();
            toAddress.add(userinfo.getUserEmail());
            emailMessage.setToAddresses(toAddress);
            emailMessage.setSubject(mailerObject.CMC_Subject__c);
            emailMessage.setHtmlBody(mailerObject.EB_AdditionalIssueDescription__c);
        }
        
        mails.add(emailMessage);
        List<Messaging.SendEmailResult> sendEmailResults = Messaging.sendEmail(mails);
        for(Messaging.SendEmailResult result : sendEmailResults) {
            if(!result.IsSuccess()){
                System.StatusCode statusCode = result.getErrors()[0].getStatusCode();
                System.debug('Status code: ' + statusCode);
                System.debug('Error msg: ' + result.getErrors()[0].getMessage());
            }
            else{
                EB_AkaMailer__c mailer = new EB_AkaMailer__c(Id=mailerId);
                mailer.Test_Email_Sent__c=true;
                update mailer;
                system.debug('mailer.Test_Email_Sent__c//'+mailer.Test_Email_Sent__c);
            }
        }
        
        return returnString;            
    }
    
    
    //This Method will return the Subject and the Body for the the Email Preview
    @AuraEnabled
    public static String fetchEmailBody(String mailerId){
        Try{
            String htmlBody;
            //This is to display the subject
            String subject;
            //This list stores the Email body
            List<String> textBody;
            List<String> body2;
            String body;
            boolean isTextEmail;            
            
            //Email Preview will be stored as attachment on the mailer.
            
            EB_AkaMailer__c mailerObject = [SELECT CMC_Template_ID__c, CMC_Subject__c , EB_AdditionalIssueDescription__c FROM EB_AkaMailer__c WHERE Id =:mailerId LIMIT 1];
            Messaging.SingleEmailMessage emailMessage=new Messaging.SingleEmailMessage();
            //If Template is not selected
            if(String.isBlank(mailerObject.CMC_Template_ID__c)){
                List<String> toAddress = new List<String>();
                toAddress.add(userinfo.getUserEmail());
                emailMessage.setToAddresses(toAddress);
                emailMessage.setSubject(mailerObject.CMC_Subject__c);
                emailMessage.setHtmlBody(mailerObject.EB_AdditionalIssueDescription__c);  
            }
            //If Template is Selected
            else{
                isTextEmail = false;
                Contact userContact = [Select Id from Contact where email =: userinfo.getUserEmail() Limit 1];
                Messaging.reserveSingleEmailCapacity(1);
                emailMessage.setUseSignature(false);
                emailMessage.setSaveAsActivity(false);
                emailMessage.setTargetObjectId(userContact.Id);
                emailMessage.setTemplateId(mailerObject.CMC_Template_ID__c);
                emailMessage.setWhatId(mailerObject.Id);
            }
            //Get the Email Preview and rollback the changes
            Savepoint sp = Database.setSavepoint();
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {emailMessage});
            //Email will not be sent because of rollback
            Database.rollback(sp);
            subject = emailMessage.getSubject();
            if(emailMessage.getHTMLBody()!=null){
                htmlBody = emailMessage.getHTMLBody();
                body =  emailMessage.getHTMLBody();
                
            }
            else{
                body = emailMessage.getPlainTextBody().replaceAll('\n','<br>');       
            }
            
            emailWrapper emailData = new emailWrapper();
            emailData.subject=subject;
            emailData.body=body;            
            return JSON.serialize(emailData);
            
        }
        Catch(Exception ex){
            System.debug('error in email preview//'+ex.getMessage());          
            return 'error in email preview//'+ex.getMessage();
        }
    }
    
    
    @AuraEnabled
    //This method will called on click of Send mailer
    public static void postMailer(String mailerId, String emailBody){
        System.debug('---Entered PostMailer Method---');
        //Creating the attachment to store the email preview on the mailer
        Attachment attachment = new Attachment();
        attachment.Body = Blob.valueOf(emailBody);
        attachment.Name = String.valueOf('EmailPreview.html');
        attachment.ParentId = mailerId;
        insert attachment;
        
        //Sending Emails
        SC_SI_INT_Tool_BatchJob  postMailerJob = new SC_SI_INT_Tool_BatchJob(null, true, mailerId);
        postMailerJob.postMailerActivity(mailerId);
        System.debug('---Exited PostMailer Method---');
        
    }
    
    /* This method returns the number of accounts which are qualified for the filter logic */
    @AuraEnabled
    Public Static Integer getAccountsCount(Id mailerId){
        system.debug('mailerId//'+mailerId);
        Integer Count = 0;
        if(mailerId != Null){
            try{
                List<Attachment> attachmentList = [Select Id, Body, ContentType from ATTACHMENT where parentId =:MailerId AND Name = 'QueryString.txt' Limit 1];
                system.debug('attachmentList//'+attachmentList);
                if(attachmentList.size() == 1){
                    String queryString = attachmentList[0].body.toString();  
                    queryString = queryString.replaceFirst('SELECT Id', 'SELECT COUNT()');
                    system.debug('queryString//'+queryString);
                    count = Database.countQuery(queryString);
                    system.debug('count//'+count);
                    
                }
            }
            Catch(QueryException ex){
                System.debug('--Exception in SC_SI_INT_Tool_Helper Class--');
                System.debug('Line Number :'+ex.getLineNumber());
                System.debug('Message :'+ex.getMessage()); 
            }
        } 
        return Count;
    }
    
    
    /* This method parse the raw email addresses by spliting on',' or ';'
* regex will validate each email addresses and separate the valid and invalid addresses
* This method returns the count of valid and invalid emails based on paramaters
*/
    @AuraEnabled
    public static List<Integer> getEmailsCount(String rawEmailAddresses,Id mailerId){
        List<String> rawEmailAddressList = new List<String>();
        List<Integer> emailsCount = new List<Integer>();
        integer validEmailsCount = 0;
        integer invalidEmailsCount = 0;
        Try{
            if(String.isBlank(rawEmailAddresses)){
                //if rawEmailAddresses is null then Emails will be stored as Attachment
                ContentDocumentLink conDocLink =  [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: mailerId];
                contentversion attachment = [SELECT versiondata from contentversion WHERE ContentDocumentId =: conDocLink.ContentDocumentId];
                String body = attachment.VersionData.toString();
                rawEmailAddressList = SC_SI_INT_Tool_Helper.SplitStringForAttachment(body);
            }
            else{
                rawEmailAddressList = rawEmailAddresses.split('[\n,\r]');
            }
            
            //Remove duplicates from the rawEmails and trim the email addresses
            Set<String> uniqueRawEmailset = new Set<String>();
            for(String eachString : rawEmailAddressList){
                uniqueRawEmailset.add(eachString.trim());
            }
            rawEmailAddressList.clear();
            rawEmailAddressList.addAll(uniqueRawEmailset);
            uniqueRawEmailset.clear();
            //Whether to exclude Akamai Email Addresses or not
            CMC_Settings__mdt  cmcSettings = [SELECT CMC_Exclude_Akamai_Email_Id__c FROM CMC_Settings__mdt WHERE DeveloperName = 'CMC'];
            // Regex to validate the Email Address
            String emailRegex = '([a-zA-Z0-9_\\-\\.+\'!#$%&*/=?^`{|}~]+)@((\\[a-z]{1,3}\\.[a-z]{1,3}\\.[a-z]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,10}|[0-9]{1,3})';
            Pattern emailPattern = Pattern.compile(emailRegex);
            for(String eachEmail : rawEmailAddressList){
                if(String.isNotBlank(eachEmail)){
                    //To remove special Characters in the email
                    if(!eachEmail.isAsciiPrintable())
                        eachEmail = eachEmail.replaceall('[^\\x00-\\x7F]', ''); 
                    
                    //Validate individual emails
                    Matcher emailMatcher = emailPattern.matcher(eachEmail);
                    if(cmcSettings.CMC_Exclude_Akamai_Email_Id__c && eachEmail.containsIgnoreCase('@akamai.com'))
                        invalidEmailsCount++;
                    else if(emailMatcher.matches())
                        validEmailsCount++;
                    else
                        invalidEmailsCount++;
                }
            }
        }
        catch(Exception ex){
            System.debug('--Exception in SC_SI_INT_Tool_Helper Class--');
            System.debug('Line Number :'+ex.getLineNumber());
            System.debug('Message :'+ex.getMessage());
        }
        rawEmailAddressList.clear();
        emailsCount.add(validEmailsCount + invalidEmailsCount);
        emailsCount.add(validEmailsCount);
        emailsCount.add(invalidEmailsCount);
        return emailsCount; 
    }
    
    
    // Method to download the csv files
    @AuraEnabled
    public static String downloadAsCSV(String mailerID, String downloadType){
        
        List<Policy_Domain__c> policyDomains;
        List<Account> accounts;
        List<List<String>> listOfEmailsList;
        string headers;
        
        Try{
            if(downloadType == 'PolicyDomainDetails'){
                List<Attachment> attachmentList = [Select Id, Body, ContentType from ATTACHMENT where parentId =:mailerId AND Name = 'QueryString.txt' Limit 1];
                if(attachmentList.size() == 1){
                    String queryString = attachmentList[0].body.toString();
                    //Replace "Id" with required field API Name
                    queryString = queryString.replaceFirst('SELECT Id','SELECT AKAM_Policy_Domain_ID__c,Name,Account_ID__c,Account_Name__r.Name,Policy_Domain_State__c,Product__c,Service_Account__r.Name ');
                    policyDomains = database.query(queryString);
                    //Corresponding field names
                    headers = 'AKAM Policy Domain ID,Policy Domain Name,AKAM Account ID,Account Name,Policy Domain State,Product,Service Account Name';
                }
                else
                    system.debug('CMC_DownloadAsCSVCtrl : No QueryString File');
                
                return JSON.serialize(policyDomains);
                
            }
            else if(downloadType == 'AccountDetails'){
                List<Attachment> attachmentList = [Select Id, Body, ContentType from ATTACHMENT where parentId =:mailerId AND Name = 'QueryString.txt' Limit 1];
                if(attachmentList.size() == 1){
                    String queryString = attachmentList[0].body.toString();
                    //Replace "Id" with required field API Name
                    queryString = queryString.replaceFirst('SELECT Id','SELECT Akam_Account_Id__c,Name, Geography_Formula__c,Division_Formula__c,Division__c,Support_Level__c,Customer_Tier__c,Owner.name,Account_Status__c');
                    accounts = database.query(queryString);
                    //Corresponding field names
                    headers = 'Akam Account Id,Name,Geography,Division,Region,Support Level,Customer Tier,Account Owner,Account Status';
                }
                else
                    system.debug('CMC_DownloadAsCSVCtrl : No QueryString File');
                return JSON.serialize(accounts);
            }
            else{
                // To get the valid and invalid email addresses
                EB_AkaMailer__c mailerObject = [Select Id, CMC_Manual_Email_Addresses__c from EB_AkaMailer__c where Id =:mailerId];
                List<String> allEmailsList = new List<String>();
                if(downloadType == 'ValidEmails')
                    allEmailsList = SC_SI_INT_Tool_Helper.ValidateEmailAddresses(mailerObject.CMC_Manual_Email_Addresses__c,mailerObject.Id,true);
                else if(downloadType == 'InvalidEmails')
                    allEmailsList = SC_SI_INT_Tool_Helper.ValidateEmailAddresses(mailerObject.CMC_Manual_Email_Addresses__c,mailerObject.Id,false);
                
                //Spliting the List into List of List because Maximum size for list 10,000 to use it on VF page
                Integer count = 0; 
                
                //This will store the list of Email list
                listOfEmailsList = new List<List<String>>();
                List<String> emails = new List<String>();
                for(String eachEmail : allEmailsList){
                    count = count + 1;
                    emails.add(eachEmail);
                    if(count == 9999){
                        //Creating the temp variable because 'emails' List need to be cleared
                        List<String> temp = new List<String>();
                        temp.addAll(emails);
                        listOfEmailsList.add(temp);
                        emails.clear();
                        //reset the count
                        count = 0;
                    }
                }
                allEmailsList.clear();
                if(emails.size() > 0)
                    listOfEmailsList.add(emails);
                return JSON.serialize(listOfEmailsList);
            }
        }    
        Catch(Exception ex){
            System.debug('--Exception--');
            System.debug('Line Number :'+ex.getLineNumber());
            System.debug('Message :'+ex.getMessage()); 
            return 'Error :'+ex.getMessage();
            
        }
    }
    
    // Checking Internal Users for Peer Review
    @AuraEnabled
    public static Boolean checkInternalUsers(String userId){
        
        Boolean isInternalUser=true;
        
        User u = [Select id,Salesforce_License__c from User where Id=:userId];
            if(u.Salesforce_License__c!='Salesforce' && u.Salesforce_License__c!='Salesforce Platform'){
                isInternalUser=false;
            }
        return isInternalUser;       
    }
    
    // Fetching the Exception report Id
    @AuraEnabled
    public static String fetchReportId(){
        
        return [SELECT Id FROM Report where DeveloperName='Pre_Mailer_Exception_Report'].Id;
        
    }
    
    
    //Method to get mailer total, success and failure count
    @AuraEnabled
    public static String emailProcessCount(String mailerId){
        
        Boolean enbledPoller = true;
        Integer totalCount = 0;
        Integer successCount = 0;
        Integer failureCount = 0;
        Integer completionPercentage = 0;
        String mailerStatus = 'Calculating Total Email..';
        
        EB_AkaMailer__c getMailerProgressCount = new EB_AkaMailer__c();
        if(mailerId != Null){
            AggregateResult result;
            getMailerProgressCount = [select EB_Status__c,CMC_IS_50000_Limit_Crossed__c,CMC_No_of_Processed_Contacts__c,CMC_Total_Emails_Contacts__c from EB_AkaMailer__c where id =:mailerId limit 1];
            totalCount = getMailerProgressCount.CMC_Total_Emails_Contacts__c != Null ? Integer.valueOf(getMailerProgressCount.CMC_Total_Emails_Contacts__c) : totalCount;
            
            if(totalCount > 0){
                mailerStatus = 'Sending Email..'; 
            }
            
            if(getMailerProgressCount.EB_Status__c == 'Email Sent - Processing Contact'){ 
                result = [SELECT SUM(EB_TotalContacts__c) FROM EB_AkaMAccount__c WHERE EB_AkaMailer__c =: mailerId];
                successCount = Integer.valueOf(result.get('expr0'));
                failureCount = [select count() from EB_MailerException__c where EB_Mailer__c =:mailerId and CMC_stage__c = 'Post Mailer'];
                mailerStatus = getMailerProgressCount.EB_Status__c;
                completionPercentage = 10; 
                if(successCount > 0 || failureCount > 0 ){
                    completionPercentage = (((successCount+failureCount)*100)/totalCount) > 100 ? (((successCount+failureCount)*100)/totalCount) - 10 : (((successCount+failureCount)*100)/totalCount);
                        } 
            }
            else if(getMailerProgressCount.EB_Status__c == 'Processed'){
                result = [SELECT SUM(EB_TotalContacts__c) FROM EB_AkaMAccount__c WHERE EB_AkaMailer__c =: mailerId];
                successCount = Integer.valueOf(result.get('expr0'));
                failureCount = [select count() from EB_MailerException__c where EB_Mailer__c =:mailerId and CMC_stage__c = 'Post Mailer'];
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
        
        EmailProcessCountWrapper emailCountWrapper = new EmailProcessCountWrapper();
        emailCountWrapper.enbledPoller=enbledPoller;
        emailCountWrapper.totalCount=totalCount;
        emailCountWrapper.successCount=successCount;
        emailCountWrapper.failureCount=failureCount;
        emailCountWrapper.completionPercentage=completionPercentage;
        emailCountWrapper.mailerStatus=mailerStatus;
        system.debug('emailCountWrapper//'+emailCountWrapper);
        
        return JSON.serialize(emailCountWrapper);
    }
    
    // Wrapper for Progress bar
    public class EmailProcessCountWrapper{
        Boolean enbledPoller;
        Integer totalCount;
        Integer successCount;
        Integer failureCount;
        Integer completionPercentage;
        String mailerStatus;
    }
    
    // Wrapper for Filters
    public class FilterWrapper{
        String field;
        String condition;
        String filterValue;
        String downloadLink;
        Integer Order;
        
    }
    
    // Wrapper for Files
    public class FileInfo {
        String Title;
        Blob VersionData;
        String parentId;
    }
    
    // Wrapper for Email Preview
    public class emailWrapper{
        String subject;
        String body;
    }
    
    // This method will be called from flow to send reminder emails for SOCC
    @InvocableMethod(label='Send Reminder Mailer Notifications' description='Fetch email body and Sends mailer notification to Customers')
    public static void sendReminderNotification(List<Id> mailerIds){
        Try{
            String emailData = fetchEmailBody(mailerIds[0]);
            Map<String, String> emailDataMap = (Map<String,String>)JSON.deserialize(emailData,Map<String,String>.class);
            postMailer(mailerIds[0], emailDataMap.get('body'));
        }
        Catch(Exception ex){
            System.debug('error in email preview//'+ex.getMessage());          
        }
    }
    
}