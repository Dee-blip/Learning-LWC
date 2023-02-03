/****************************************************************************
* Class name          :   SC_JARVIS_CustomerTouchpoints
* Author              :   Vishnu Vardhan
* Created             :   01-July-2021
* Purpose             :   Jarvis Cutomer touchpoints logic
* Test Class          :   --
-------------------------------------------------------------------------------
* MethodName          : Purpose
-------------------------------------------------------------------------------
* +handleJarvisEmailInserts           :   Post Jarvis Incoming Emails/ Outbound email  (Status = "sent") to CCF
* +handleJarvisEmailUpdates           :   Post Jarvis Outbound email ( Status changes to "Sent") to CCF
* +handleJarvisCaseActivity(taskList) :   Post Jarvis Case activities to CCF
* +sendEmailNotificationToCustomer    :   Send Email notifications for new CCF
* +getEmailNotifylist                 :   get Email Notify List for CCF Alerts
*****************************************************************************
* Util Methods
* -getCommentsForJarvisEmails         :   Build Community Comment record for Jarvis Email
* -getJarvisComment                   :   Build Community Comment record
*****************************************************************************

DATE             DEVELOPER        CR              DESCRIPTION
===========      =========        =======         ===========
July 1, 2021     Vishnu Vardhan   ESESP-4356      Initial Dev
Dec 12, 2021	 Harshil Soni	  ESESP-6360	  Added condition to Ignore Undeliverable emails
Feb 23, 2022     Vishnu Vardhan   ESESP-6759      Skip messages from auto reply email
Mar 10, 2022     Jay Rathod       ESESP-6799      Updated logic to populate community comment created by
Mar 10, 2022     Vishnu Vardhan   ESESP-6882      Fix to capture all outbound emails in Community Comments
April 6, 2022    Sharath          ESESP-6936      Restrict Internal Emails to Case Subscribers
*****************************************************************************/

public class SC_JARVIS_CustomerTouchpoints {
    // Recordtypes in scope for Customer Touchpoints
    static List<String> caseRecordTypes = new List<String>{'Technical', 
                                                            'Emerging Products Engineering', 
                                                            'Managed Security', 
                                                            'Professional Services', 
                                                            'AMG', 
                                                            'Billing'};
    
    // Email Status values 
    // Unused values for reference - STATUS_READ = '1'; STATUS_REPLIED = '2'; STATUS_FORWARD = '4';
    static final String STATUS_NEW = '0';
    static final String STATUS_SENT = '3';
    static final String STATUS_DRAFT = '5';
    

                                                            
    // Post Jarvis Incoming Emails/ Outbound email  (Status = "sent") to CCF
    public static void handleJarvisEmailInserts(List<EmailMessage> newEmails) {

        try{
            List<EmailMessage> jarvisInboundEmails = new List<EmailMessage>();

            for(EmailMessage em: newEmails) {
                
                //ESESP-6759 - Skip messages from auto reply email
                string autoReplyEmailId = SC_FromEmailAddress__c.getValues('auto-reply')?.OrgAddressId__c;
                List<OrgWideEmailAddress> orgAutoReplyEmail = [SELECT Id, Address FROM OrgWideEmailAddress where id = :autoReplyEmailId];
                Boolean isSfAutoReplyEmail = orgAutoReplyEmail.size() > 0 && em.fromAddress == orgAutoReplyEmail[0].Address && em.Incoming == true;
                
                //ESESP-6360 - Added condition to Ignore Undeliverable emails
                //ESESP-6799 - Added condition for jarvis email check - String.isNotBlank(em.ReplyToEmailMessageId)
                Boolean isJarvisTouchpoint = em.Is_Jarvis_Email__c && !isSfAutoReplyEmail 
                                            && ( String.isNotBlank(em.Headers) || String.isNotBlank(em.ReplyToEmailMessageId))
                                            && em.Status != STATUS_DRAFT && !em.Subject.containsIgnoreCase('Undeliverable'); 
                if(isJarvisTouchpoint) {
                    jarvisInboundEmails.add(em);
                }
            }

            if(jarvisInboundEmails.size() == 0) {
                return;
            }

            List<Community_Comments__c> toInsertComments = getCommentsForJarvisEmails(jarvisInboundEmails);
        
            insert toInsertComments;
        }
        catch(Exception e)
        {
            SC_Jarvis_utility.sendErrorMails('handleJarvisEmailInserts ', 'Exception: ', e.getMessage());
        }
    }

    // Post Jarvis Outbound email ( Status changed from Draft to "Sent"/ "Replied"/ "Forwarded) to CCF
    public static void handleJarvisEmailUpdates(Map<Id,  EmailMessage> newEmailsMap, List<EmailMessage> oldEmails) {
        try{
            List<EmailMessage> jarvisEmailMessages = new List<EmailMessage>();

            for(EmailMessage oldEmail: oldEmails) {
                EmailMessage newEmail = newEmailsMap.get(oldEmail.Id);
                
                //ESESP-6799 - Added condition for jarvis email check - String.isNotBlank(em.ReplyToEmailMessageId)
                Boolean isJarvisTouchpoint = newEmail.Is_Jarvis_Email__c
                                            && ( String.isNotBlank(newEmail.Headers) || String.isNotBlank(newEmail.ReplyToEmailMessageId))
                                            && newEmail.Incoming == false 
                                            && oldEmail.Status == STATUS_DRAFT 
                                            && newEmail.Status != STATUS_DRAFT;
                                        // && oldEmail.Status != newEmail.Status && ( oldEmail.Status == '5' || newEmail.status == '3')
                                                
                if(isJarvisTouchpoint) {
                    jarvisEmailMessages.add(newEmail);
                }
            }

            if(jarvisEmailMessages.isEmpty()) {
                return;
            }

            List<Community_Comments__c> toInsertComments = getCommentsForJarvisEmails(jarvisEmailMessages);

            insert toInsertComments;
        }catch(Exception e)
        {
            SC_Jarvis_utility.sendErrorMails('handleJarvisEmailUpdates ', 'Exception: ' , e.getMessage());
        }
    }

    // Post Jarvis Case activities to CCF
    public static void handleJarvisCaseActivity(List<Task> taskList) {
        try{
            List<Community_Comments__c> toInsertCommunityComments = new List<Community_Comments__c>();

            List<Task> caseTasks = new List<Task>();
            List<Id> taskWhoIds = new  List<Id>();
            
            for(Task ts: taskList){
                Boolean isCaseWebUpdateOrCall = ts.visibility__c =='Customer'
                                                && String.isNotBlank(ts.WhatId) 
                                                && ((String)ts.WhatId).startsWith('500') 
                                                && ( ts.Type__c == 'Web Update' || ts.Type__c == 'Call')
                                                && ts.Subject != 'Jarvis Comment';
                
                if(isCaseWebUpdateOrCall) {
                    caseTasks.add(ts);
                    if( ts.AKAM_Created_By__c == 'PCASE') {
                        taskWhoIds.add(ts.WhoId);
                    }
                }
            }

            if(caseTasks.isEmpty()) {
                return;
            }

            Map<Id, Id> contactUserMap = new Map<Id, Id>();
            for( user us:[select Id, ContactId from user where contactid in :taskWhoIds]) {
                contactUserMap.put(us.ContactId, us.Id);
            }
            

            for(Task ts: [ SELECT Id, Type__c, AKAM_Created_By__c, AKAM_Created_Date__c, WhoId, Description, Subject, TYPEOF What WHEN Case THEN Recordtype.Name, Akam_Case_Id__c, ContactId, AccountId END FROM Task 
                        WHERE id in :caseTasks AND What.Type = 'Case' AND 
                        (What.recordtype.Name in :caseRecordTypes OR what.recordtype.name = 'Partner Technical Support')]) 
            {
                Case taskCase = (case)ts.What;
                Id createdById = ts.AKAM_Created_By__c == 'PCASE' && contactUserMap.containsKey(ts.WhoId)
                                    ? contactUserMap.get(ts.WhoId)
                                    : UserInfo.getUserId();
                
                Boolean isWebUpdate = ts.Type__c == 'Web Update';
                Boolean isCall = ts.Type__c == 'Call';
                
                // Post content of web activity to CCF
                if(isWebUpdate) {
                    toInsertCommunityComments.add(getJarvisComment(taskCase, null, ts.Description, createdById, 'Text'));
                } else if(isCall) {
                    // Post Call event with Date Time to CCF
                    String callComment = 'Call logged by <b>' 
                                        + UserInfo.getFirstName() + ' ' + UserInfo.getLastName() 
                                        + '</b> at ' + ts.AKAM_Created_Date__c.formatGmt('MM/dd/yyyy HH:mm:ss')
                                        + ' GMT';
                    toInsertCommunityComments.add(getJarvisComment(taskCase, null, callComment, createdById, 'Text'));
                }
            }
            
            INSERT toInsertCommunityComments;
        }
        catch(Exception e)
        {
            SC_Jarvis_utility.sendErrorMails('handleJarvisCaseActivity ', 'Exception: ' , e.getMessage());
        }
    }

    // Utility Method - Build Community Comment record for Jarvis Email
    private static List<Community_Comments__c> getCommentsForJarvisEmails(List<EmailMessage> emailMessages) {
        List<Community_Comments__c> toInsertComments = new List<Community_Comments__c>();

        Map<String, User> userEmailMap = new Map<String, User>();
        
        Set<String> fromEmails = new Set<String>();

        for(EmailMessage em: emailMessages) {
            if(em.incoming) {
                fromEmails.add(em.fromAddress);
            }
        }

        if(fromEmails.size() > 0) {
             for( User us: [select id, email, contactid, Contact.Email 
                                                from user where email in :fromEmails AND IsActive = TRUE]) 
            {
                userEmailMap.put(us.email,us);
            }
        }

        for(EmailMessage email: [select id, Subject, HTMLBody, FromAddress, Incoming, TextBody,
                                    parentid, Parent.Recordtype.Name, Parent.Akam_case_id__c, Parent.AccountId, Parent.ContactId
                                            from EmailMessage
                                            where id in :emailMessages 
                                                and Parent.Recordtype.Name in :caseRecordTypes ]) 
        {
            Case cs = (Case)email.Parent;
            Id usrId;
            if(email.Incoming){
                usrId = userEmailMap.containsKey(email.FromAddress) ? userEmailMap.get(email.FromAddress).Id: null;
            }else{
                usrId = UserInfo.getUserId();
            }

            Id  contactId = email.Incoming && userEmailMap.containsKey(email.FromAddress) ? userEmailMap.get(email.FromAddress).ContactId: null;
            String comment =  email.Id + '__' + email.Subject;
            String createdBy = String.isBlank(usrId)? email.FromAddress: usrId;
            Community_Comments__c comm = getJarvisComment(cs, contactId, comment, createdBy, 'Email');
            comm.Email_Plain_Text__c = email.TextBody;
            
            toInsertComments.add(comm);
        }

        return toInsertComments;
    }

    // Utility Method - Build Community Comment record
    public static Community_Comments__c getJarvisComment(Case parentCase, String contactId, String comment, String createdBy, String commentType ) { 
        Community_Comments__c comm = new Community_Comments__c();
        comm.Parent_ID__c = parentCase.Id;
        comm.Parent_Name__c = parentCase.Akam_Case_Id__c;
        comm.Contact__c = parentCase.ContactId;
        comm.Commented_By__c = 'Informational';
        comm.Comment__c = comment;
        comm.Related_Object__c = 'Case';
        if(parentCase.recordtype.name == 'AMG' || parentCase.recordtype.name == 'Billing') {
            comm.Account_ID_for_Community_Share__c = parentCase.AccountId;
        }
        comm.Validation_Override__c = true;
        comm.Application__c = 'JARVIS';
        comm.Visibility__c = 'Public';
        comm.Type__c = commentType;
        if(createdBy.contains('@')) {
            comm.Posted_By_Email__c = createdBy;
        } else {
            comm.AKAM_Created_By__c = createdBy;
        }
        comm.AKAM_Created_Date__c = datetime.now();
        comm.AKAM_Modified_Date__c = datetime.now();
        if(commentType == 'File')
            comm.Skip_Email_Notification__c = false;
        else
            comm.Skip_Email_Notification__c = true; 
        return comm;
    }
   
    // Send Email notifications for new CCF
    public static void sendCommCommentEmailNotifications(list<Community_Comments__c> caseCommentlst)
    {
        Set<Id> parentCaseIds = new Set<Id>();
        List<Community_Comments__c> toNotifyCommComments= new List<Community_Comments__c>();
        
        for(Community_Comments__c  cm:  caseCommentlst) {
            if( cm.Application__c == 'JARVIS' && !cm.Skip_Email_Notification__c)  {
                toNotifyCommComments.add(cm);
                parentCaseIds.add(cm.Parent_Id__c);
            }
        }

        if(toNotifyCommComments.isEmpty()) {
            return;
        }

        Map<Id, Case> caseMap = new Map<Id, Case>([select id, OwnerId, AccountId, Severity__c,
                                        RecordType_Name__c, ContactId, ContactEmail, Case_Owner_Email_address__c, Sub_Type__c,
                                        Account.Mailing_List_for_Technical_Case_auto_cc__c,
                                        Jarvis_Also_Notify__c, Alternate_Contact_Email__c
                                    from Case where id in:parentCaseIds]);

       
        String soccFromEmailName = [Select Value_Text__c from SC_Utility__mdt where MasterLabel = 'SOCC From Name' limit 1].Value_Text__c;   
        string fromAdd = SC_FromEmailAddress__c.getValues('auto-reply').OrgAddressId__c;

        
        List<Messaging.SingleEmailMessage> commEmails = new List<Messaging.SingleEmailMessage>();

        Map<Id, Set<String>> accountEmailSubs = getCaseSubscribers(caseMap.values());
        //changes for ESESP-6936
        Map<Id, Set<String>> caseFollowSubs = getCaseFollowUsers(caseMap.values());

        EmailTemplate emailTemplate = [Select Id,Subject,Description,HtmlValue,DeveloperName,Body from EmailTemplate where DeveloperName = 'SC_Jarvis_Case_Update'];

        // TO DO - Fetch and populate Account Email Subscribers
        for(Community_Comments__c eachCaseComment : toNotifyCommComments) {
            
            Case parentCase = caseMap.get(eachCaseComment.Parent_ID__c);
            List<string> toAddressList = new List<string>{};
            
            Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(emailTemplate.Id, eachCaseComment.Parent_Id__c, eachCaseComment.Id); 

            String htmlContent = mail.getHtmlBody();
            Integer delimIndex = htmlContent.indexOfIgnoreCase('emailbodystart');
            String commentBody = htmlContent.substring(delimIndex, htmlContent.length()) ;
            
            String safeHtml = htmlContent.substring(0, delimIndex) 
                            + SC_Jarvis_utility.stripHtmlTag(commentBody, 'img', '<p> <i> ----Image removed, check community comment---- </i> </p>');
            
            mail.setHtmlBody(safeHtml);

            Boolean isCustomer = eachCaseComment.Commented_By__c != 'Internal User';

            toAddressList = getEmailNotifylist(parentCase, accountEmailSubs,caseFollowSubs, isCustomer);
            System.debug('toAddressList ---' + toAddressList);
            if(toAddressList.size() > 0) {
                mail.setToAddresses(toAddressList);
            }

            mail.setOrgWideEmailAddressId(fromAdd);

            if(isCustomer || String.isBlank(parentCase.ContactId)){
                String targetObjId =  String.valueof(parentCase.OwnerId).startsWith('005') 
                                    ? parentCase.OwnerId
                                    : UserInfo.getUserId();
                mail.setTargetObjectId(targetObjId);
            } else {
                mail.setTargetObjectId(parentCase.ContactId);
            }

            mail.setUseSignature(false); 
            mail.setWhatId(eachCaseComment.Parent_ID__c);
            mail.setSaveAsActivity(false);
            commEmails.add(mail);
        }

        Messaging.sendEmail(commEmails, false); 
    }

    static Map<String,String> custUpdNotify = new Map<String,String> {
        'Technical' => 'Case Owner,Account Case Notification Subscription List,Account Auto CC List,Case Contact,Also Notify List,Alternate Contact',
        'Managed Security' => 'Case Owner,Account Case Notification Subscription List,Also Notify List,Case Contact,Alternate Contact',
        'AMG' => 'Case Owner,Account Case Notification Subscription List,Case Contact,Also Notify List,Alternate Contact',
        'Billing' => 'Case Owner,Account Case Notification Subscription List,Case Contact,Also Notify List,Alternate Contact',
        'Professional Services' => 'Case Owner,Case Contact,Also Notify List,Alternate Contact,PS Tix'
    };
    static Map<String,String> akamUpdNotify = new Map<String,String> {
        'Technical' => 'Case Contact,Also Notify List,Alternate Contact,Account Case Notification Subscription List,Account Auto CC List',
        'Managed Security' => 'Also Notify List,Case Contact,Alternate Contact',
        'AMG' => 'Case Contact,Also Notify List,Alternate Contact,Account Case Notification Subscription List,Account Auto CC List',
        'Billing' => 'Case Contact,Also Notify List,Alternate Contact,Account Case Notification Subscription List,Account Auto CC List',
        'Professional Services' => 'Also Notify List,Case Contact,Alternate Contact'
    };
    Static String psTixEmail;
    Static String noReplyEmail;
    static {
        for( SC_Utility__mdt eml: [SELECT DeveloperName, Value_text__c FROM SC_Utility__mdt where DeveloperName IN ('no_reply_id', 'Jarvis_ps_tix')]) {
            if(eml.DeveloperName == 'no_reply_id') {
                noReplyEmail = eml.Value_text__c;
            } else if(eml.DeveloperName == 'Jarvis_ps_tix') {
                psTixEmail = eml.Value_text__c;
            }
        }
    }
    
    public Static List<String> getEmailNotifylist(Case pCase, Map<Id, Set<String>> accountEmailSubs,Map<Id, Set<String>> caseFollowSubs,Boolean isCustomer) {
        String recordType = pCase.RecordType_Name__c;
        String subscriberStr = isCustomer? custUpdNotify.get(recordType): akamUpdNotify.get(recordType);
        Set<String> subscriberEmails = new Set<String>();
        for(String sub: subscriberStr.split(',')) {
            if(sub == 'Case Owner' && String.isNotBlank(pCase.Case_Owner_Email_address__c)) {
                subscriberEmails.add(pCase.Case_Owner_Email_address__c);
            } else if(sub == 'Case Contact' && String.isNotBlank(pCase.ContactEmail)) {
                subscriberEmails.add(pCase.ContactEmail);
            } else if(sub == 'Also Notify List' && String.isNotBlank(pCase.Jarvis_Also_Notify__c)) {
                subscriberEmails.addAll(pCase.Jarvis_Also_Notify__c.split('[,;\\s\n]+'));
            } else if(sub == 'Alternate Contact' && SC_Jarvis_utility.isValidEmail(pCase.Alternate_Contact_Email__c)) {
                subscriberEmails.add(pCase.Alternate_Contact_Email__c);
            } else if(sub == 'PS Tix') {
                subscriberEmails.add(psTixEmail);
            } else if(sub == 'Account Auto CC List' && String.isNotBlank(pCase.Account?.Mailing_List_for_Technical_Case_auto_cc__c)) {
                subscriberEmails.add(pCase.Account.Mailing_List_for_Technical_Case_auto_cc__c);
            }
            //Changes for ESESP-6936: getting CNS and Case Follow list
            else if(sub == 'Account Case Notification Subscription List')
            {
               if(accountEmailSubs.containsKey(pCase.AccountId))
               {
                   subscriberEmails.addAll(accountEmailSubs.get(pCase.AccountId));
               }    
               if(caseFollowSubs.containsKey(pCase.Id))
               {
                   subscriberEmails.addAll(caseFollowSubs.get(pCase.Id));
               }    
                
            }
        }
        Set<String> validEmails = SC_Jarvis_utility.filterValidEmails(subscriberEmails);
        return new List<String>(validEmails);
    }

    public static Map<Id, Set<String>> getCaseSubscribers(List<Case> caseList) {
        Map<Id, Set<String>> caseAccountSubsribers = new Map<Id, Set<String>>();

        for(Case cs: caseList) {
            if(!caseAccountSubsribers.containsKey(cs.AccountId)) {
                caseAccountSubsribers.put(cs.AccountId, new Set<String>());
            }
        }
        //Changes for ESESP-6936: Added Eligible_For_Jarvis_Email__c check and querying ListenEmailComms__c
        Map<Id, Account> accountSubsMap = new Map<Id, Account>([select id, 
                                        ( select Id, Account__c, Case_Record_Type__c,Sub_Type__c,Email__c,Severity__c,ListenEmailComms__c 
                                            from CaseNotificationSubscriptions__r where Eligible_For_Jarvis_Email__c  = true) 
                                        from Account where Id in :caseAccountSubsribers.keySet()]);

        for(Case cs: caseList)  {
            List<Case_Notification_Subscription__c> caseSubs = accountSubsMap.get(cs.AccountId).CaseNotificationSubscriptions__r;
            for(Case_Notification_Subscription__c sub: caseSubs) {
                if(isMatchingSub(sub, cs)) {
                    caseAccountSubsribers.get(cs.AccountId).add(sub.Email__c);
                }
            }
        }

        return caseAccountSubsribers;
    }

    //Changes for ESESP-6936
    public static Map<Id, Set<String>> getCaseFollowUsers(List<Case> caseList) {
        Map<Id, Set<String>> caseFollowUsers = new Map<Id, Set<String>>();

        for(Case cs: caseList) 
        {           
           caseFollowUsers.put(cs.Id, new Set<String>());
        }

        for (SC_CNSOnCase__c  caseFollowUser:  [select Case__c, User__r.email from SC_CNSOnCase__c where 
                                                ListenEmailComms__c = true and Case__c in :caseFollowUsers.keySet()])
        {
            caseFollowUsers.get(caseFollowUser.Case__c).add(caseFollowUser.User__r.email);
        }

        return caseFollowUsers;
    }

    static Boolean isMatchingSub(Case_Notification_Subscription__c sub, Case cs) {
        //Changes for ESESP-6936
        SC_Utility__mdt mdt = SC_Utility__mdt.getInstance('CaseRTForEmailCommListen');
        Set<String> recordTypeNames = new Set<String>();
        for(String rtName : mdt.Value__c.split(','))
        {
			recordTypeNames.add(rtName);
        }

        Boolean isSeverityMatch = String.isNotBlank(sub.Severity__c) 
                                  && String.isNotBlank(cs.Severity__c)
                                  && ( sub.Severity__c.contains(cs.Severity__c) 
                                        || ( sub.Severity__c == '3 & below' && (cs.Severity__c == '3' || cs.Severity__c == '4')));

        if(!isSeverityMatch) {
            return false;
        }                 
        
        //Changes for ESESP-6936
        Boolean emailCommunicationEnabled = !recordTypeNames.contains(cs.RecordType_Name__c) || 
                         	(recordTypeNames.contains(cs.RecordType_Name__c) && sub.ListenEmailComms__c);                            
        //Changes for ESESP-6936: Added emailCommunicationEnabled
        Boolean isRecordtypeMatch = sub.Case_Record_Type__c == cs.RecordType_Name__c && emailCommunicationEnabled;
        Boolean isManagedSecuritySub = isRecordtypeMatch && cs.RecordType_Name__c == 'Managed Security';
        Boolean isSubtypeMatch = sub.Sub_Type__c == cs.Sub_Type__c;

        Boolean cond1 = isRecordtypeMatch 
                        && (sub.Sub_Type__c == 'All' 
                            || sub.Sub_Type__c == 'N/A' 
                            || (isSubtypeMatch && (cs.Sub_Type__c == 'CMP Alerts' || cs.Sub_Type__c == 'BOCC'))
                            || ( cs.Sub_Type__c!= 'CMP Alerts' && cs.Sub_Type__c != 'BOCC' && sub.Sub_Type__c == 'Non-CMP Alerts' ));
        Boolean cond2 = isManagedSecuritySub 
                        && (sub.Sub_Type__c == 'All' ||  (isSubtypeMatch && cs.Sub_Type__c == 'Customer Inquiry'));
        //Changes for ESESP-6936: Added emailCommunicationEnabled
        Boolean cond3 = sub.Case_Record_Type__c == 'All' && emailCommunicationEnabled;

        return cond1 || cond2 || cond3;
    }

}