/**
CFA_ConfirmAttachmentController
@author : Vinayendra T N <vintara@akamai.com>
@Description : This is the controller class for the CFA_ConfirmAttachment
This class is used by partners to accept the CAF attachment.
@History
--Developer           --Date            --Change
Vinayendra T N       3/2011             CR 1135360 Implement Partner Order Acceptance
- Created VF for Partner to accept the CAf attachment
Vinayendra T N       7/2011             CR 1225381 Discard the old document under POA section on Oppty
- Added logic so that the order which have status as rejected , a proper error message is shown.
Vinayendra T N       11/2011            CR 1387001 Send email notification when Oppty.Contract # is updated.
- Add the internal account/sales team as recipients to email which is sent out when POA is accepted
Pranav Moktali       6/2013             CR 2187443 PRM errors are not being notified.
- Sending exception mails for unhandled exceptions.
Nagaraj Desai        12/2018            - Attachment Migration To Files : SFDC-3953
Nagaraj Desai        3/2020             - Revamp CFA_ConfirmAttachmentController : SFDC-6362
*/
public without sharing class CFA_ConfirmAttachmentController {

    public static String acceptanceDocId {get;set;}
    public ContentVersion attachmentt {
        get { if (attachmentt == null)
            attachmentt = new ContentVersion();
             return attachmentt;} set;
    }
    public static String themeDisplayed {get;set;}

    public CFA_ConfirmAttachmentController() {
        themeDisplayed = NAPSettings.getValue('NapPortalTheme');
    }

    @AuraEnabled
    public static Map<String, String> getInitialDataMap(String contentVersionId) {
        Map<String, String> returnValMap = new Map<String, String>();
        if(contentVersionId == null || contentVersionId == '') {
            String errorMessage = 'Attachment Id not provided';
            returnValMap = addErrors(returnValMap, errorMessage);
            return returnValMap;
        }
        Partner_Order_Acceptance_Document__c acceptanceDoc;
        try {
            acceptanceDoc = [SELECT Id,
                                    Opportunity__c,
                                    Opportunity__r.Name,
                                    Opportunity__r.Account.Id,
                                    Opportunity__r.Account.Name,
                                    Opportunity__r.Account.AKAM_Account_ID__c,
                                    Opportunity__r.Owner.Email, // SFDC-5907
                                    Opportunity__r.Partner_Involved__c,
                                    Opportunity__r.Partner_Involved__r.Name,
                                    Opportunity__r.Partner_Involved__r.Partner_PO_Required__c,
                                    Opportunity__r.Partner_Involved__r.Parent.Id,
                                    Opportunity__r.Partner_Involved__r.Partner_Type__c,
                                    Partner_Account_ID__c,
                                    Partner_Involved_Name__c,
                                    Opportunity__r.Partner_Involved__r.POA_Email_List__c,
                                    Opportunity__r.Id,
                                    Opportunity__r.CloseDate,
                                    Opportunity__r.StageName,
                                    Notification__c,
                                    Notification_email_list__c,
                                    Partner_Notes__c,
                                    Customer_Unique_Id__c,
                                    PO_Number__c,
                                    Order_Acceptance_Status__c,
                                    Customer_Name__c,
                                    Accepted_At__c,
                                    Accepted_By__r.Name,
                                    Rejection_Comments__c,
                                    URL_for_Partners__c,
                                    CreatedById,
                                    Attachment__c,
                                    Opportunity__r.Account.T_Cs_Signed__c
                                    FROM Partner_Order_Acceptance_Document__c WHERE Attachment__c = :contentVersionId ORDER BY CreatedDate DESC LIMIT 1];
        }
        catch(Exception e) {
            Sawyer.saw(e);
            returnValMap = addErrors(returnValMap, NAPSettings.getValue('POAAcceptanceInvalidIdError'));
            return returnValMap;
        }

        if(acceptanceDoc == null) {
            returnValMap = addErrors(returnValMap, NAPSettings.getValue('POAAcceptanceInvalidIdError'));
            return returnValMap;
        }
        
        User currentUser = [SELECT Email, Can_Accept_POA__c, Contact.AccountId FROM User WHERE Id = :Userinfo.getUserId() LIMIT 1];
        
        if(!currentUser.Can_Accept_POA__c) {
            returnValMap = addErrors(returnValMap, GsmUtilClass.getGSMSettingValue('CFA_SendEmailController_InvalidUser'));
            return returnValMap;
        }
        if((currentUser.Contact.AccountId != acceptanceDoc.Partner_Account_ID__c) && (currentUser.Contact.AccountId != acceptanceDoc.Opportunity__r.Partner_Involved__r.Parent.Id)) {
            returnValMap = addErrors(returnValMap, GsmUtilClass.getGSMSettingValue('CFA_SendEmailController_InvalidUser'));
            return returnValMap;
        }
        if(acceptanceDoc.Order_Acceptance_Status__c == 'Accepted' || acceptanceDoc.Order_Acceptance_Status__c == 'Rejected') {
            returnValMap = addErrors(returnValMap, 'The Order Acceptence has already been completed by ' + acceptanceDoc.Accepted_By__r.Name + ' at ' + acceptanceDoc.Accepted_At__c);
            return returnValMap;
        }
        if(acceptanceDoc.Order_Acceptance_Status__c == 'Voided') {
            returnValMap = addErrors(returnValMap, Label.CFA_ConfirmAttachmentController_Status_rejected);
            return returnValMap;
        }

        if(GsmUtilClass.isFeatureToggleEnabledCustomMetadata('IsChannelsPassthroughEnabled') && acceptanceDoc.Opportunity__r.Partner_Involved__r.Partner_Type__c.equalsIgnoreCase('Associate Partner') && !acceptanceDoc.Opportunity__r.Account.T_Cs_Signed__c) {
            returnValMap = addErrors(returnValMap, 'The T&C Document needs to be signed by end customer before proceeding.');
            return returnValMap;
        }

        if(acceptanceDoc.Opportunity__r.Partner_Involved__r.Partner_PO_Required__c) {
            returnValMap.put('PORequired', String.valueOf(true));
            List<ContentDocumentLink> listOfContentDocumentLinks = new List<ContentDocumentLink>();
            List<Id> ownerIdList = new List<Id>();
            //SFDC-3953
            for(ContentDocumentLink eachContentDocumentLink:[SELECT Id, ContentDocumentId, ContentDocument.OwnerId FROM ContentDocumentLink WHERE LinkedEntityId = :acceptanceDoc.Id AND ContentDocument.LatestPublishedVersionId != :contentVersionId]) {
                listOfContentDocumentLinks.add(eachContentDocumentLink);
                ownerIdList.add(eachContentDocumentLink.ContentDocument.OwnerId);
            }

            Map<Id,Id> userToAccountMap = new Map<Id,Id>();

            for(User eachUser : [SELECT Id, AccountId__c FROM User WHERE Id IN :ownerIdList]) {
                userToAccountMap.put(eachUser.Id, eachUser.AccountId__c);
            }
            Id PODocumentId;
            //Check if the logged in partner is a peer and allow them to see and upload the PO based on Partner Involved
            //SFDC-3953
            if(listOfContentDocumentLinks.size() > 0) {
                for(ContentDocumentLink eachContentDocumentLink : listOfContentDocumentLinks)
                {
                    if((userToAccountMap.get(eachContentDocumentLink.ContentDocument.OwnerId) == acceptanceDoc.Opportunity__r.Partner_Involved__c) || (currentUser.Contact.AccountId ==  acceptanceDoc.Opportunity__r.Partner_Involved__r.Parent.Id)) {
                        PODocumentId = eachContentDocumentLink.ContentDocumentId;
                    }
                }
            }
            Boolean PODocumentAttached = false;
            if(PODocumentId != null) {
                PODocumentAttached = true;
                //SFDC-3953
                ContentDocument POContentDocument;
                try {
                    POContentDocument = [SELECT Id, LatestPublishedVersionId, LatestPublishedVersion.Title FROM ContentDocument WHERE Id = :PODocumentId];
                    returnValMap.put('POContentDocument', JSON.serialize(POContentDocument));
                }
                catch (Exception e) {
                    Sawyer.saw(e);
                }

            }
            returnValMap.put('PODocumentAttached', String.valueOf(PODocumentAttached));
            returnValMap.put('showPartnerNotes', String.valueOf(checkRoleName()));
            returnValMap.put('acceptanceDocIdForPO', acceptanceDoc.Id);
        }
        acceptanceDoc.Customer_Unique_Id__c = '';
        try {
            ContentVersion currentContentVersion = [SELECT Title FROM ContentVersion WHERE Id = :contentVersionId LIMIT 1];
            returnValMap.put('orderFileName', currentContentVersion.Title);
        }
        catch(Exception e) {
            Sawyer.saw(e);
            returnValMap.put('orderFileName', 'Order Acceptance File Name');
        }
        returnValMap.put('acceptanceDoc', JSON.serialize(acceptanceDoc));
        returnValMap.put('fileDownloadURL', GsmUtilClass.convertToCommunityURL(NAPSettings.getValue('NewFileDownloadLink')));
        returnValMap.put('contentVersionId', contentVersionId);
        return  returnValMap;                      
    }

    private static Map<String, String> addErrors(Map<String, String> initialMap, String errorMessage) {
        if(initialMap.containsKey('errorMessage')) {
            String previousErrorMessages = initialMap.get('errorMessage');
            previousErrorMessages += '\n' + errorMessage;
            initialMap.put('errorMessage', previousErrorMessages);
        } else {
            initialMap.put('errorMessage', errorMessage);
        }
        return initialMap;
    }

    private static Boolean checkRoleName() {
        Boolean returnboolean = false;
        String CustomSettingRolesNames = GsmUtilClass.getPRMSettingValue('CFA_CnfrmAttach_PartnerNotesEnabled');
        string UserRoleName = '';
        for(UserRole usrrole : [SELECT Name FROM UserRole WHERE Id = :UserInfo.getUserRoleId()]) {
            UserRoleName = usrrole.Name;
        }
        if(UserRoleName != '') {
            List<String> csvalues = CustomSettingRolesNames.toLowerCase().split(',');
            for(String s : csvalues) {
                if(UserRoleName.toLowerCase().startsWith(s)) {
                    returnboolean=true;
                    break;
                }
            }
        }
        return returnboolean;
    }

    @AuraEnabled
    public static Map<String, String> processPartnerOrderAcceptance(Map<String, String> parameterMap) {

        Map<String, String> returnValMap = new Map<String, String>();
        Partner_Order_Acceptance_Document__c acceptanceDoc = (Partner_Order_Acceptance_Document__c) JSON.deserialize(parameterMap.get('acceptanceDoc'), Partner_Order_Acceptance_Document__c.Class);

        if(acceptanceDoc.Opportunity__r.Partner_Involved__r.Partner_PO_Required__c == true && (!parameterMap.containsKey('POContentDocument') || parameterMap.containsKey('POContentDocument') && parameterMap.get('POContentDocument') == null)) {
            returnValMap = addErrors(returnValMap, 'A Purchase Order is required before you can accept the order.Please attach it to the "Upload Purchase Order" section below.');
            return returnValMap;
        }
        if(acceptanceDoc.Notification_email_list__c != null && acceptanceDoc.Notification_email_list__c.length() > 255) {
            returnValMap = addErrors(returnValMap, 'You can only enter a maximum of 255 characters in the Notification List');
            return returnValMap;
        }
        if(acceptanceDoc.Partner_Notes__c != null && acceptanceDoc.Partner_Notes__c.length() > 2000) {
            returnValMap = addErrors(returnValMap, 'Partner Notes field can have a maximum of 2000 characters');
            return returnValMap;
        }

        Savepoint sp = Database.setSavepoint();
        acceptanceDoc.Accepted_At__c = DateTime.now();
        acceptanceDoc.Accepted_By__c = UserInfo.getUserId();
        if(parameterMap.containsKey('POContentDocument')) {
            ContentDocument POContentDocument = (ContentDocument) JSON.deserialize(parameterMap.get('POContentDocument'), ContentDocument.Class);
            acceptanceDoc.PO_Attachment_ID__c = POContentDocument.Id;
        }
        acceptanceDoc.Validation_Override__c = true;
        try {
            //SFDC-8136 Taruni - Start
            String uid= UserInfo.getUserId();
            if (uid!= null){
            	CFA_ConfirmAttachmentController.createOpportunityTeamMember(AcceptanceDoc.Opportunity__r.id,uid );
            }
            //SFDC-8136 Taruni - End
            update acceptanceDoc;
        }
        catch(Exception e) {
            Sawyer.saw(e);
            acceptanceDoc.Order_Acceptance_Status__c = 'Pending Acceptance';
            if(e.getMessage().contains('Customer Unique Id is mandatory for this account')) {
                returnValMap = addErrors(returnValMap, e.getMessage());
            }
            else {
                returnValMap.put('errorMessage', e.getMessage());
            }
            returnValMap.put('acceptanceDoc', JSON.serialize(acceptanceDoc));
            return returnValMap;
        }

        if(acceptanceDoc.Order_Acceptance_Status__c == 'Accepted') {
            //Oppty must be moved to SS6 in case of accept SFDC-6256
            if(acceptanceDoc.Opportunity__r.StageName != 'Closed Won' && acceptanceDoc.Opportunity__r.StageName != 'Closed Lost' && acceptanceDoc.Opportunity__r.StageName != '6. Signed'
                && acceptanceDoc.Opportunity__r.StageName != 'Closed Duplicate' && acceptanceDoc.Opportunity__r.StageName != 'Closed Contract Ended' && acceptanceDoc.Opportunity__r.StageName != 'Closed Admin') {
                //SFDC-6916
                List<Partner_Order_Acceptance_Document__c> listOfPendingPOAs;
                try {
                    listOfPendingPOAs = [SELECT Id From Partner_Order_Acceptance_Document__c WHERE Opportunity__c = :acceptanceDoc.Opportunity__c AND Order_Acceptance_Status__c = 'Pending Acceptance' AND Id != :acceptanceDoc.Id];
                } 
                catch(Exception e) {
                    Sawyer.saw(e);
                }   
                if(listOfPendingPOAs == null || listOfPendingPOAs.size() < 1) {
                    Opportunity opp = new Opportunity ();
                    opp.Id = acceptanceDoc.Opportunity__c;
                    opp.Validation_Override__c = true;
                    opp.StageName = '6. Signed';//SFDC-3539
                    try {
                        update opp;
                    }
                    catch(Exception e) {
                        Sawyer.saw(e);
                        acceptanceDoc.Order_Acceptance_Status__c = 'Pending Acceptance';
                        Database.rollback(sp);
                        if(e.getMessage().contains('INSUFFICIENT_ACCESS_OR_READONLY')) {
                            returnValMap = addErrors(returnValMap, 'You do not have privileges to perform this operation.');
                            return returnValMap;
                        }
                        else {
                            returnValMap.put('errorMessage', e.getMessage());
                            return returnValMap;
                        }
                    }
                }
                // SFDC-6916 End
            }
        }

        if(!sendConfirmationEmail(acceptanceDoc, parameterMap.get('contentVersionId'))) {
            Database.rollback(sp);
            acceptanceDoc.Order_Acceptance_Status__c = 'Pending Acceptance';
            returnValMap = addErrors(returnValMap, 'An error occurred while sending email. Please contact System Admin');
        } 
        else {
            if(acceptanceDoc.Order_Acceptance_Status__c == 'Accepted') {
                returnValMap.put('successMessage', 'You have Succesfully submitted your acceptance.');
            } else {
                returnValMap.put('successMessage', 'You have Succesfully submitted your rejection');
            }
        }
        returnValMap.put('acceptanceDoc', JSON.serialize(acceptanceDoc));
        return returnValMap;
    }

    public static Boolean sendConfirmationEmail(Partner_Order_Acceptance_Document__c acceptanceDoc, String contentVersionId) {
        Boolean emailSentSuccessfully = true;
        List<Id> listOfUserId = new List<Id>();
        listOfUserId.add(acceptanceDoc.CreatedById);
        listOfUserId.add(UserInfo.getUserId());
        Map<Id, User> mapOfIdVsUsers =  new Map<Id, User>([SELECT Id, Name, Email FROM User WHERE Id IN :listOfUserId]);
        User poadCreatedByUser = mapOfIdVsUsers.get(acceptanceDoc.CreatedById);
        User currentUser = mapOfIdVsUsers.get(UserInfo.getUserId());

        Map<String, EmailTemplate> emailTemplateMap = new Map<String, EmailTemplate>();
        for(EmailTemplate eachTemplate : [SELECT Body, Subject, DeveloperName FROM EmailTemplate WHERE DeveloperName = :GsmUtilClass.getGSMSettingValue('CFA_SendEmailController_EmailToPae') OR DeveloperName = 'CAF_Email_to_PAE_Reject']) {
            emailTemplateMap.put(eachTemplate.DeveloperName, eachTemplate);
        }

        EmailTemplate partnerOrderTemplate;
        if(acceptanceDoc.Order_Acceptance_Status__c == 'Accepted') {
            partnerOrderTemplate = emailTemplateMap.get(GsmUtilClass.getGSMSettingValue('CFA_SendEmailController_EmailToPae'));
        } else {
            partnerOrderTemplate = emailTemplateMap.get('CAF_Email_to_PAE_Reject');
        }
        String emailSubject = partnerOrderTemplate.Subject;
        String emailBody = partnerOrderTemplate.Body;

        emailSubject = emailSubject.replace('#PartnerInvolved#', acceptanceDoc.Opportunity__r.Partner_Involved__r.Name);
        emailSubject = emailSubject.replace('#Oppty_Acc#', acceptanceDoc.Opportunity__r.Account.Name);

        emailBody = emailBody.replace('#PartnerInvolved#', acceptanceDoc.Opportunity__r.Partner_Involved__r.Name);
        emailBody = emailBody.replace('#PartnerName#', currentUser.Name);
        emailBody = emailBody.replace('#PartnerEmail#', currentUser.Email);
        emailBody = emailBody.replace('#Oppty_Acc#', acceptanceDoc.Opportunity__r.Account.Name);
        
        if(acceptanceDoc.Customer_Unique_Id__c != null) {
            emailBody = emailBody.replace('#Oppty_AccId#', acceptanceDoc.Customer_Unique_Id__c);
        }
        if(acceptanceDoc.PO_Number__c != null) {
            emailBody = emailBody.replace('#PO_Number#', acceptanceDoc.PO_Number__c);
        }
        emailBody = emailBody.replace('#AcceptanceDate#', acceptanceDoc.Accepted_At__c.format());
        emailBody = emailBody.replace('#PAEName#', poadCreatedByUser.Name);

        String emailHeader = GsmUtilClass.getGSMSettingValue('CFA_SendEmailController_EmailHeader');
        String emailfooter = GsmUtilClass.getGSMSettingValue('CFA_SendEmailController_Emailfooter');

        //Partner Notes
        if(acceptanceDoc.Partner_Notes__c!=null && acceptanceDoc.Partner_Notes__c!='') {
            emailBody = emailBody.replace('#PartnerNotes#','Partner Notes: ' + acceptanceDoc.Partner_Notes__c);
        }
        else {
            emailBody = emailBody.replace('#PartnerNotes#','');
        }

        String htmlBodyOfEmail = emailHeader + emailBody.replace('\n','<br/>') + emailfooter;
        //Put only the link for text email
        emailBody = emailBody.replace('#OpportunityLinkInternal#', URL.getSalesforceBaseUrl().toExternalForm() + '/' + acceptanceDoc.Opportunity__c);
        emailBody = emailBody.replace('#OpportunityLinkPartner#', acceptanceDoc.URL_for_Partners__c);
        //put the hypertext for html email
        htmlBodyOfEmail = htmlBodyOfEmail.replace('#OpportunityLinkInternal#','<b><a href="' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + acceptanceDoc.Opportunity__c + '">here</a></b>');
        htmlBodyOfEmail = htmlBodyOfEmail.replace('#OpportunityLinkPartner#','<b><a href="' + acceptanceDoc.URL_for_Partners__c + '">here</a></b>');
        //Rejection comments
        if(acceptanceDoc.Rejection_Comments__c != null) {
            emailBody = emailBody.replace('#RejectionComments#', acceptanceDoc.Rejection_Comments__c );
            htmlBodyOfEmail = htmlBodyOfEmail.replace('#RejectionComments#', '<i>' + acceptanceDoc.Rejection_Comments__c.replace('\n', '<br/>') + '</i>' );
        }

        List<Messaging.Emailfileattachment> emailFileAccachmentList = new List<Messaging.Emailfileattachment>();
        if(acceptanceDoc.Order_Acceptance_Status__c == 'Accepted') {
            //SFDC-3953
            ContentVersion emailAttachContent = [SELECT Id, FileExtension, Title, VersionData FROM ContentVersion WHERE Id = :contentVersionId LIMIT 1];
            if(emailAttachContent != null) {
                Messaging.Emailfileattachment emailFileAttachment = new Messaging.Emailfileattachment();
                //SFDC-5408
                String fileName = emailAttachContent.Title;
                if((fileName.contains('.') && fileName.substringAfterLast('.') != emailAttachContent.FileExtension) || (!fileName.contains('.'))){
                    fileName += '.' + emailAttachContent.FileExtension;
                }
                emailFileAttachment.setFileName(fileName);
                emailFileAttachment.setBody(emailAttachContent.VersionData);
                emailFileAccachmentList.add(emailFileAttachment);
            }
        }

        Messaging.SingleEmailMessage orderConfirmationEmail = new Messaging.SingleEmailMessage();
        Set<String> toAddresses = new Set<String>();
        toAddresses.add(poadCreatedByUser.Email);
        Set<String> ccAddresses = new Set<String>();
        if(acceptanceDoc.Order_Acceptance_Status__c == 'Accepted') {
            for(AccountTeamMember eachAccountTeamMember : [SELECT User.Email, TeamMemberRole FROM AccountTeamMember WHERE AccountId = :acceptanceDoc.Opportunity__r.Account.Id AND User.Isactive = true]) {
                if(eachAccountTeamMember.TeamMemberRole != 'Partner' && eachAccountTeamMember.User.Email.contains(GsmUtilClass.getGSMSettingValue('OpptyTriggerClass_AkamaiIdentifier'))) {
                    ccAddresses.add(eachAccountTeamMember.User.Email);
                }
            }
        }
        //insert Sales team users to the cc list
        for(OpportunityTeamMember eachOpportunityTeamMember : [SELECT User.Email, TeamMemberRole FROM OpportunityTeamMember WHERE OpportunityId = :acceptanceDoc.Opportunity__c AND User.Isactive = true]) {
            if(acceptanceDoc.Order_Acceptance_Status__c == 'Accepted' && eachOpportunityTeamMember.TeamMemberRole != 'Partner' && eachOpportunityTeamMember.TeamMemberRole != 'CMG - Analyst' &&  eachOpportunityTeamMember.User.Email.contains(GsmUtilClass.getGSMSettingValue('OpptyTriggerClass_AkamaiIdentifier'))) {
                ccAddresses.add(eachOpportunityTeamMember.User.Email);
            }
            // CMG - analyst always needs to be any emails irrespective if its rejected or accepted.
            if(eachOpportunityTeamMember.TeamMemberRole == 'CMG - Analyst')
                ccAddresses.add(eachOpportunityTeamMember.User.Email);
        }

        if(acceptanceDoc.Opportunity__r.Partner_Involved__r.POA_Email_List__c != null) {
            ccAddresses.addAll(acceptanceDoc.Opportunity__r.Partner_Involved__r.POA_Email_List__c.replace(' ','').split(','));
        }

        if(acceptanceDoc.Order_Acceptance_Status__c == 'Accepted') {
            if(acceptanceDoc.Notification_email_list__c != null && acceptanceDoc.Notification_email_list__c != '') {
                ccAddresses.addAll(acceptanceDoc.Notification_email_list__c.replace(' ','').replace('\n',',').split(','));
            }
            if(acceptanceDoc.Notification__c == true) {
                ccAddresses.add(currentUser.Email);
            }
        }
        else { 
            //Add rejection user in the cc list
            ccAddresses.add(currentUser.Email);
        }

        orderConfirmationEmail.setWhatId(acceptanceDoc.Opportunity__c);
        orderConfirmationEmail.setToAddresses(new List<String>(toAddresses));
        String ccAddressString = '';
        //SFDC-5907-start
        if(acceptanceDoc.Opportunity__r.Owner.Email != null && acceptanceDoc.Opportunity__r.Owner.Email != '') {
            ccAddresses.add(acceptanceDoc.Opportunity__r.Owner.Email);
        }
        //SFDC-5907-end
        if(ccAddresses.size() > 0) {
            //convert set to a list
            Integer addressCount = 1;
            list<String> ccAddressesList = new list<String>();
            for(String eachEmailAddress : ccAddresses) {
                ccAddressesList.add(eachEmailAddress);
                ccAddressString += eachEmailAddress + '; ';
                addressCount++;
            }
            orderConfirmationEmail.setCcAddresses(ccAddressesList);
        }
        orderConfirmationEmail.setSubject(emailSubject);
        orderConfirmationEmail.setBccSender(false);
        orderConfirmationEmail.setUseSignature(false);
        orderConfirmationEmail.setPlainTextBody(emailBody);
        orderConfirmationEmail.setHtmlBody(htmlBodyOfEmail);

        if(GsmUtilClass.getPRMSettingValue('CFA_AttachBcc') == 'TRUE') {
            List<String> bccAddresseslist = new List<String>();
            bccAddresseslist.add(GsmUtilClass.getPRMSettingValue('CFA_AttachBccEmail'));
            orderConfirmationEmail.setBccAddresses(bccAddresseslist);
        }
        // Loggin activity manually
        if(emailFileAccachmentList.size() > 0) {
            orderConfirmationEmail.setFileAttachments(emailFileAccachmentList);
        }
        orderConfirmationEmail.setSaveAsActivity(true);
        List<Messaging.SingleEmailMessage> listOfEmails = new List<Messaging.SingleEmailMessage>();
        listOfEmails.add(orderConfirmationEmail);

        try {
            Messaging.sendEmail(listOfEmails);
        }
        catch(Exception e) {
            Sawyer.saw(e);
            emailSentSuccessfully = false;
        }

        //Create Task
        String taskBody = '';
        if(toAddresses.size() > 0) {
            taskBody += '\nTo Addresses:';
            for(String eachToAddress : toAddresses) {
                taskBody += eachToAddress + '; ';
            }
        }
        if(ccAddresses.size() > 0) {
            taskBody += '\nCC Addresses:';
            for(String eachToAddress : ccAddresses) {
                taskBody += eachToAddress + '; ';
            }
        }

        taskBody += '\nBody:\n';
        taskBody += emailBody;
        //move back to as it is
        Task orderAcceptanceTask = new Task();
        orderAcceptanceTask.OwnerId = Userinfo.getuserid();
        orderAcceptanceTask.WhatId = acceptanceDoc.Id;
        orderAcceptanceTask.Subject = emailSubject;
        orderAcceptanceTask.Type__c = 'Email';
        orderAcceptanceTask.Description = taskBody;
        orderAcceptanceTask.Status = 'Completed';
        try {
            insert orderAcceptanceTask;
        } catch(Exception e) {
            Sawyer.saw(e);
            emailSentSuccessfully = false;
        }

        return emailSentSuccessfully;    
    }

    @AuraEnabled
    public static ContentDocument getPODocuments(String acceptanceRecordId, String contentVersionId) {
        ContentDocument POContentDocument;
        try {
            ContentDocumentLink cdv = [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =:acceptanceRecordId AND ContentDocument.LatestPublishedVersionId != :contentVersionId];
            POContentDocument = [SELECT Id, LatestPublishedVersionId, LatestPublishedVersion.Title FROM ContentDocument WHERE Id = :cdv.ContentDocumentId ];
        } catch(Exception e) {
            Sawyer.saw(e);
        }
        return POContentDocument;
        
    }

    @AuraEnabled
    public static Boolean deletePODocument(String contentDocumentId) {
        ContentDocument contentDoc = new ContentDocument();
        contentDoc.Id = contentDocumentId;
        try {
            delete contentDoc;
            return true;
        } 
        catch (Exception e) {
            Sawyer.saw(e);
        }
        return false;
    }

    public PageReference upload() {
        List<Error_Log__c> errorLogs = new List<Error_Log__c>();
        String retUrlString = ApexPages.currentPage().getUrl();
        Map<String, String> mapOfPageAttributes = ApexPages.currentPage().getParameters();
        Integer i = 0;
        for(String eachAttribute : mapOfPageAttributes.keySet()) {
            if(i == 0) {
                retUrlString += '?' + eachAttribute + '=' + mapOfPageAttributes.get(eachAttribute);
            } else {
                retUrlString += '&' + eachAttribute + '=' + mapOfPageAttributes.get(eachAttribute);
            }
            i++;
        }
        PageReference returnURL = new PageReference(retUrlString);

        //Check if the Attachment details exists, Insert the Attachment
        //SFDC-3953
        if(attachmentt != null && attachmentt.VersionData != null) {
            if(attachmentt.Title == null || attachmentt.Title == '') {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'File Title is not populated.'));
                return returnURL;
            }
            attachmentt.OwnerId = UserInfo.getUserId();
            attachmentt.ContentLocation = 'S';
            attachmentt.PathOnClient = attachmentt.Title;
            acceptanceDocId = ApexPages.currentPage().getParameters().get('acceptanceRecordId');
                
            //attachmentt.ParentId = cad.Id; // the record the file is attached to
            //attachmentt.IsPrivate = false;
                
            try {
                //SFDC-3953
                insert attachmentt;
                ContentVersion contentVersionRecord = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =:attachmentt.Id];
                ContentDocumentLink contentDocumentLinkRecord = L2Q_ContentDocumentUtilClass.setContentDocumentLink(contentVersionRecord.ContentDocumentId, acceptanceDocId, 'I', 'AllUsers');
                insert contentDocumentLinkRecord;
            }
            catch (DMLException e) {
                Sawyer.saw(e);
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Error uploading attachment.'));
                return returnURL;
            }
                
            if(errorLogs.size()>0)
                Database.insert(errorLogs, false);
            return back();
        }
        else{
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,' Please attach a file to upload.'));
            return returnURL;
        }
    }

    public PageReference back() {
        String successURL = '/apex/CFA_ConfirmAttachment?id=' + ApexPages.currentPage().getParameters().get('contentVersionId');
        PageReference RetPage = new PageReference(successURL);
        RetPage.setRedirect(true);
        return RetPage;
    }


    //SFDC-8136 Taruni - Start
    public static void createOpportunityTeamMember(String opptyId, string userId){
       
        OpportunityTeamMember otmNew=new OpportunityTeamMember(); 
        otmNew.OpportunityId=opptyId;
        otmNew.TeamMemberRole='Partner';
        otmNew.UserId=userId;
        //otmNew.Validation_Override__c = true;
        try {
            insert otmNew;
        }
        catch(Exception e){
            Sawyer.saw(e);
        }
    }
    //SFDC-8136 Taruni - End

}