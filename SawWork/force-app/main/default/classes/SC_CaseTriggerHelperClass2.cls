/*
 * JIRA: ESESP-2467
 * Developer: Sharath Prasanna
 * Enhancement: New case trigger handler class
 * Date: 18th December 2019
 * 
 * Developer                        Date                            Changes
 * Sharath                          13 Jan 2020                     Changed sendSubdomainTakeoverToolNotification. 
                                                                    Modified the query for ESESP-3018
* Vishnu Sharma                     20 Mar 2020                     ESESP-1588 : Case Notification SUbscription
* Sharath                           6th May 2020                    ESESP-3560: Changed the Notification logic to consider 
                                                                    BOCC Subtype for Technical
* Vandhana                          7 May 2020                      ESESP-3529 : Task functionality for S2ET Cases (ensure all tasks closed before closing S2ET Case)
* Vikas                             2 Jun 2020                      ESESP-3663 : Task functionality for Provisioning Cases (ensure all tasks closed before closing PLX Case)
* Vandhana                          10 Dec 2020                     ESESP-4491 : Revamped case history tracker custom functionality

* Tejaswini                         22 Jan 2021                     ESESP-4616 : Support only Configs due and Peer review auto generated tasks for Security Provisioning PLX Cases
* Sujay                             09 Sep 2021                     ESESP-5678 : Creating AutoTask for 24PS cases

*/ 
public class SC_CaseTriggerHelperClass2 
{
    public static Boolean s2etTaskRecursion = true;
    
    public static Boolean customHistoryTrackerRecCheck = true;
    
    public SC_CaseTriggerHelperClass2() 
    {
        
    }

    // changes by Sheena - moved from Case Trigger Class ESESP-2347
    public static void UpdateContactName(Case[] cases)
    {
        if(!UserInfo.getName().equalsIgnoreCase('Connection User') && !UserInfo.getName().equalsIgnoreCase('Automated Process'))
        {
            // Get the User Records
            List<User> users = [select Id, AKAM_User_ID__c from User where Id = :UserInfo.getUserId()];
            
            // Get a map of UserId -> AKAM User Id
            Map<Id, String> usrId_akamIdMap = new Map<Id,String>();
            
            for(User u:users)
            {
                usrId_akamIdMap.put(u.Id, u.AKAM_User_ID__c);
            }   
            
            List<Contact> contacts = [select Id, AKAM_Contact_ID__c from Contact where AKAM_Contact_ID__c IN :usrId_akamIdMap.values()];
            Map<String, Id> conMap = new Map<String, Id>();
             
            for(Contact con:contacts)
                conMap.put(con.AKAM_Contact_ID__c, con.Id);
            
            for(Case c:cases)
            {                
                if(c.ContactId == null && usrId_akamIdMap.containskey(UserInfo.getUserId()) && conMap.containsKey(usrId_akamIdMap.get(UserInfo.getUserId())))
                    c.ContactId = conMap.get(usrId_akamIdMap.get(UserInfo.getUserId()));
            }
        }  
    }

    @future
    public static void sendSubdomainTakeoverToolNotification(List <Id> caseIds)
    {
        //List<String> contactRoles = new List<String>();
        String contactRolesString;
        String orgwideEmail;
        String templateName;
        Id orgWideEmailId;
        Id templateId;
        Id accountId;
        
        for(SC_Utility__mdt utilRec : [select Value__c,Value_Text__c,DeveloperName from SC_Utility__mdt 
                                       where DeveloperName in ('Subdomain_Takeover_Contact','Subdomain_Takeover_Email','Subdomain_Takeover_Template')
                                       and Active__c = true])
        {
            if(utilRec.DeveloperName == 'Subdomain_Takeover_Contact' && utilRec.Value__c != null )
            {
                //contactRoles.addAll(utilRec.Value__c.split(','));
                contactRolesString = utilRec.Value__c;
            }
            else if(utilRec.DeveloperName == 'Subdomain_Takeover_Email')
            {
                orgwideEmail = utilRec.Value_Text__c;   
            }
            else if(utilRec.DeveloperName == 'Subdomain_Takeover_Template')
            {
                templateName = utilRec.Value_Text__c;   
            }
        }
        
        Map<Id,Id> caseIdToAccountId = new Map<Id,Id>();
        Map<Id, List<Id>> accountIdToContacts = new Map<Id, List<Id>>();
        
        List<Id> accountIds = new List<Id>();
        
        //changes for ESESP-3018. Modified the filter
        for(Case caseRec: [select id,accountId from case where id in :caseIds 
                           and (account.Indirect_Customer__c = false or 
                                (account.Indirect_Customer__c= true and account.Channel_Marketing_Prohibited__c = false))])
        {
            caseIdToAccountId.put(caseRec.id,caseRec.accountId);
            accountIds.add(caseRec.accountId);
        }

        String includeString = '(';
        for (string roleString : contactRolesString.split(','))
        {
            includeString +=  '\'' + roleString + '\',';
        }
        includeString = includeString.subString(0,includeString.length() - 1);
        includeString += ')';

        
        String contactQuery = 'select id, accountId from Contact where accountId in : accountIds and HasOptedOutOfEmail = false and IsEmailBounced = false and Contact_Type__c includes ';
        contactQuery += includeString;

        List <contact> contactRecords;
        try
        {
            contactRecords = database.Query(contactQuery);        
        }
        catch(Exception e)
        {
            PSA_AutoCreateProjectUtil.sendErrorMails('Query Error!','Error: ' + e.getMessage());
            return;
        }
        for(Contact contactRec: contactRecords)
        {
            
            if(!accountIdToContacts.containsKey(contactRec.accountId))
            {
                accountIdToContacts.put(contactRec.accountId, new List<Id>());
            }
            accountIdToContacts.get(contactRec.accountId).add(contactRec.Id);
        }
        
        if(caseIdToAccountId.isEmpty() || accountIdToContacts.isEmpty())
        {
            system.debug('contactRolesString: ' + contactRolesString);
            return;
        }
        
        try
        {
            orgWideEmailId = [select Id from OrgWideEmailAddress where Address= :orgwideEmail limit 1].Id;
            templateId = [select id from emailtemplate where developername = :templateName limit 1].Id;
        }
        catch(Exception e)
        {
            orgWideEmailId = null;
            templateId = null;
        }
        
        List<Messaging.SingleEmailMessage> emailsToBeSent = new List<Messaging.SingleEmailMessage>();
        for(Id caseId: caseIdToAccountId.Keyset())
        {
            accountId = caseIdToAccountId.get(caseId);
            if(accountIdToContacts.containsKey(accountId) && !accountIdToContacts.get(accountId).isEmpty())
            {
                for(Id contactId : accountIdToContacts.get(accountId))
                {
                    emailsToBeSent.add(PSA_OverageController.prepareMail(orgWideEmailId,null,contactId, 
                                                                         templateId,caseId, null,null, false));
                }
            }
        }
        

        if(! emailsToBeSent.isempty())
        {
            try
            {
                 Messaging.SendEmailResult[] results = Messaging.sendEmail(emailsToBeSent,false); 
                 populateErrorTableForEmail(results,'Subdomain Takeover Email Failure', 'List of ids: ' + caseIds);                 
            }
            catch(Exception e)
            {
                PSA_AutoCreateProjectUtil.sendErrorMails('Subdomain Takeover Email Failure','List of ids: ' + caseIds + ' Exception Message: ' + e.getMessage() + ' Exception Stack Trace: ' + e.getStackTraceString());
            }
            
        }
        
        
        return;
    }

    //Changes by Sharath: Adding a util method to loop through error mails
    public static void populateErrorTableForEmail(List<Messaging.SendEmailResult> results, string subject, string additionalBody)
    {
        String errors = '';            
        String table = ''; 
        Integer successCount = 0;
        for(Integer i = 0; results != null &&  i < results.size(); i++)
        {
            Messaging.SendEmailResult emailResult = results.get(i);
            if (!emailResult.isSuccess()) 
            {
                for(Messaging.SendEmailError err : emailResult.getErrors()) 
                {
                   errors += '<tr><td>' + err.getStatusCode() + ': ' + err.getMessage() + '</td></tr>';
                }
            }
            else
            {
                successCount++;
            }

        }
        if(errors != '')
        {
          table = '<table><tr><th>' + 'The error in Record </th></tr>';
          table += errors;
          table += '</table><br/><br/>';          
          PSA_AutoCreateProjectUtil.sendErrorMails(subject,additionalBody + '<br/><br/>Success Count: ' + successCount + '<br/><br/>' + table);
        }
        
    }

//         
    /** A method to send case notifications to manual subscribers(Notification Team)

changes by Vishnu : ESESP-1588
*/
    public static void sendEmailToCaseNotificationSubscription(List<Case> newCases,Map<Id,Case> oldMap,Boolean isInsert)
    {   
        if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
        {
            
            //OrgWideEmailAddress noReply = [Select Id From OrgWideEmailAddress Where Address = :SC_FromEmailAddress__c.getValues('Noreply').FromAddress__c Limit 1];
            Id noReply = SC_FromEmailAddress__c.getValues('Noreply').OrgAddressId__c;
            
            Set<Id> accIds = new Set<Id>();
            Set<Id> conIds = new Set<Id>();         
            Map<Id, Schema.RecordTypeInfo> rtMap = Case.sObjectType.getDescribe().getRecordTypeInfosById();
            Map<Id,List<Case_Notification_Subscription__c>> Acc_Subscribers = new Map<Id,List<Case_Notification_Subscription__c>>();
            
            for(Case c : newCases)
            {
                if(c.AccountId != null)  
                    accIds.add(c.AccountId);
                
                if(c.ContactId != null)
                    conIds.add(c.ContactId);
            }
            
            Map<Id, Account> actMap = new Map<Id, Account>();
            if(accIds.size() > 0){
                for(Account eachAccount : [Select Id, Name From Account Where Id IN : accIds])
                    actMap.put(eachAccount.Id, eachAccount);
            } 
            
            Map<Id, Contact> conMap = new Map<Id, Contact>(); 
            if(conIds.size() > 0){
                for(Contact eachContact : [Select Id, Name From Contact Where Id IN : conIds])
                    conMap.put(eachContact.Id, eachContact);
            }
            //Creating Map of Account-CaseNotificationSubscription
            if(accIds.size()>0)
            {
                for(Case_Notification_Subscription__c  subscriber : [Select Account__c,Case_Record_Type__c,Portal_Visibility__c,Case_Origin__c,Sub_Type__c,Email__c,Severity__c,Incident__c from Case_Notification_Subscription__c where Account__c IN : accIds])
                {
                    if(!Acc_Subscribers.containsKey(subscriber.Account__c))
                    {
                        Acc_Subscribers.put(subscriber.Account__c,new list<Case_Notification_Subscription__c>());
                    }
                    Acc_Subscribers.get(subscriber.Account__c).add(subscriber);
                }
            }
            
            Messaging.Singleemailmessage email;
            List<Messaging.Singleemailmessage> emailList;
            
            emailList = new List<Messaging.Singleemailmessage>();
            
            if(Acc_Subscribers.size()>0)
            {  
                for(Case c : newCases)
                {   
                    if(c.AccountId != null && Acc_Subscribers.get(c.AccountId)!=null)
                    {
                        List<String> toAddrsForSeverity = new List<String>();
                        List<String> toAddrsForIncident = new List<String>();
                        List<String> toAddrsForInc_Sev = new List<String>();
                        
                        //List of subscribers for the case
                        for(Case_Notification_Subscription__c subscriber : Acc_Subscribers.get(c.AccountId))
                        {   Boolean isSeverityValidUpdate = false;
                         Boolean isIncidentValidUpdate = false;
                         
                         // Validating if Severity is a valid update.
                         if(
                             !String.isBlank(subscriber.Severity__c) 
                             && 
                             (
                                 (
                                     subscriber.Severity__c.contains(c.Severity__c)
                                     
                                 )    
                                 || 
                                 (subscriber.Severity__c.contains('3 & below') && Integer.valueOf(c.Severity__c) > 3)
                             ) 
                             && (isInsert || c.Severity__c != oldMap.get(c.Id).Severity__c || c.RecordTypeId != oldMap.get(c.Id).RecordTypeId || c.AccountId != oldMap.get(c.Id).AccountId)
                         ){
                             isSeverityValidUpdate = true; 
                         }
                         // Validating if Incident is a valid update.
                         if(subscriber.Incident__c == 'Yes' && !String.isBlank(c.Service_Incident__c) && (isInsert || (c.Service_Incident__c != oldMap.get(c.Id).Service_Incident__c) || c.RecordTypeId != oldMap.get(c.Id).RecordTypeId || c.AccountId != oldMap.get(c.Id).AccountId)){
                             isIncidentValidUpdate = true;
                             
                         }
                         
                         // To send email even for account or record Type change , making boolean checks true
                         /*if(c.RecordTypeId != oldMap.get(c.Id).RecordTypeId || c.AccountId != oldMap.get(c.Id).AccountId){
isSeverityValidUpdate = true; 
isIncidentValidUpdate = true; 
}*/
                         
                         // Validating all checks for valid subscription to send Email.
                         if(
                             
                             (
                                 (
                                     (rtMap.get(c.RecordTypeId).getName() == subscriber.Case_Record_Type__c)
                                 ) 
                                 && 
                                 (
                                     subscriber.Portal_Visibility__c == 'All'
                                     ||
                                     (c.Do_not_show_in_portal__c == false)
                                 ) 
                                 &&
                                 (
                                     (
                                         c.Sub_Type__c == 'CMP Alerts' && subscriber.Sub_Type__c == 'CMP Alerts'
                                     )
                                     ||
                                     (
                                         c.Sub_Type__c == 'BOCC' && subscriber.Sub_Type__c == 'BOCC'
                                     )
                                     ||
                                     subscriber.Sub_Type__c == 'N/A' 
                                     || 
                                     subscriber.Sub_Type__c == 'All' 
                                     || 
                                     (
                                         c.Sub_Type__c!= 'CMP Alerts' && c.Sub_Type__c != 'BOCC' && subscriber.Sub_Type__c == 'Non-CMP Alerts'
                                     )
                                 ) 
                                 && 
                                 (
                                     subscriber.Case_Origin__c == 'All' 
                                     || 
                                     subscriber.Case_Origin__c == 'N/A' 
                                     || 
                                     (c.Origin != 'Proactive' && c.Work_Type__c != 'Proactive')
                                 ) 
                                 && 
                                 (
                                     isSeverityValidUpdate
                                     || isIncidentValidUpdate
                                     /*|| 
(!isInsert && rtMap.get(c.RecordTypeId).getName() == 'AMG' && isIncidentValidUpdate)
||
(isIncidentValidUpdate && rtMap.get(c.RecordTypeId).getName() != 'AMG')*/
                                 )
                             ) 
                             || 
                             (
                                 rtMap.get(c.RecordTypeId).getName() == subscriber.Case_Record_Type__c 
                                 && 
                                 subscriber.Case_Record_Type__c == 'Managed Security' 
                                 &&
                                 (
                                     isSeverityValidUpdate
                                     || 
                                     isIncidentValidUpdate
                                 )
                                 &&
                                 (
                                     (
                                         c.Sub_Type__c == 'Customer Inquiry' && subscriber.Sub_Type__c == 'Customer Inquiry'
                                     )
                                     || 
                                     subscriber.Sub_Type__c == 'All' 
                                 )
                             )
                             ||
                             (   
                                 subscriber.Case_Record_Type__c == 'All' 
                                 &&
                                 (
                                     subscriber.Portal_Visibility__c == 'All'
                                     ||
                                     (c.Do_not_show_in_portal__c == false)
                                 ) 
                                 &&
                                 (
                                     isSeverityValidUpdate
                                     || isIncidentValidUpdate
                                     /*|| 
(!isInsert && rtMap.get(c.RecordTypeId).getName() == 'AMG' && isIncidentValidUpdate)
||
(isIncidentValidUpdate && rtMap.get(c.RecordTypeId).getName() != 'AMG')*/
                                 )
                             )
                         ){
                             if(!isInsert && isSeverityValidUpdate && isIncidentValidUpdate ){
                                 toAddrsForInc_Sev.add(subscriber.EMail__c);
                             }
                             else if(isInsert || isSeverityValidUpdate){
                                 toAddrsForSeverity.add(subscriber.EMail__c);
                             }else{
                                 toAddrsForIncident.add(subscriber.EMail__c);
                             }
                         }
                        }
                        Set<String> emailSetForSeverity = new Set<String>();
                        emailSetForSeverity.addAll(toAddrsForSeverity);
                        toAddrsForSeverity.clear();
                        toAddrsForSeverity.addAll(emailSetForSeverity);
                        
                        Set<String> emailSetForIncident = new Set<String>();
                        emailSetForIncident.addAll(toAddrsForIncident);
                        toAddrsForIncident.clear();
                        toAddrsForIncident.addAll(emailSetForIncident);
                        
                        Set<String> emailSetForInc_Sev = new Set<String>();
                        emailSetForInc_Sev.addAll(toAddrsForInc_Sev);
                        toAddrsForInc_Sev.clear();
                        toAddrsForInc_Sev.addAll(emailSetForInc_Sev);
                        //creating email notification
                        String eventName = 'Updated';
                        
                        if(isInsert){
                            eventName = 'Created';
                        }
                        String subject = '';
                        if(c.Subject != null){
                            subject = c.Subject;
                        }
                        if(toAddrsForSeverity.size()>0)
                        {
                            
                            
                            
                            email = new Messaging.Singleemailmessage();
                            email.setHtmlBody(createEmailBody(c, actMap.get(c.AccountId), conMap.get(c.ContactId),eventName,oldMap.get(c.id), 'Severity__c'));
                            email.setSaveAsActivity(false);
                            email.setToAddresses(toAddrsForSeverity);
                            email.setOrgWideEmailAddressId(noReply);
                            // email.setSubject('[AKAM-CASE #'+c.Akam_Case_Id__c+'] New '+rtMap.get(c.RecordTypeId).getName()+' Case Created for ' + actMap.get(c.AccountId).Name + (c.Subject != null ? (' - ' + c.Subject) : ''));
                            
                            email.setSubject(actMap.get(c.AccountId).Name+': '+'Severity '+c.Severity__c+' '+rtMap.get(c.RecordTypeId).getName()+' Case has been '+eventName+' [AKAM-CASE #'+c.Akam_Case_Id__c+']: '+subject);
                            emailList.add(email);
                            
                        }
                        
                        if(toAddrsForIncident.size()>0)
                        {
                            email = new Messaging.Singleemailmessage();
                            email.setHtmlBody(createEmailBody(c, actMap.get(c.AccountId), conMap.get(c.ContactId),eventName,oldMap.get(c.id),'Incident_Name__c'));
                            email.setSaveAsActivity(false);
                            email.setToAddresses(toAddrsForIncident);
                            email.setOrgWideEmailAddressId(noReply);
                            // email.setSubject('[AKAM-CASE #'+c.Akam_Case_Id__c+'] New '+rtMap.get(c.RecordTypeId).getName()+' Case Created for ' + actMap.get(c.AccountId).Name + (c.Subject != null ? (' - ' + c.Subject) : ''));
                            
                            email.setSubject(actMap.get(c.AccountId).Name+': '+'Incident '+c.Incident_Name__c+' '+rtMap.get(c.RecordTypeId).getName()+' Case has been '+eventName+' [AKAM-CASE #'+c.Akam_Case_Id__c+']: '+subject);
                            emailList.add(email);
                            
                        }
                        if(toAddrsForInc_Sev.size()>0)
                        {
                            email = new Messaging.Singleemailmessage();
                            email.setSaveAsActivity(false);
                            email.setOrgWideEmailAddressId(noReply);
                            email.setHtmlBody(createEmailBody(c, actMap.get(c.AccountId), conMap.get(c.ContactId),eventName,oldMap.get(c.id),'Both'));
                            email.setToAddresses(toAddrsForInc_Sev);
                            email.setSubject(actMap.get(c.AccountId).Name+': '+'Severity '+c.Severity__c+' '+rtMap.get(c.RecordTypeId).getName()+' Case has been '+eventName+' [AKAM-CASE #'+c.Akam_Case_Id__c+']: '+subject);
                            emailList.add(email);
                        }
                        
                        
                    } 
                }
                
                //sending the list of email notifications
                if(emailList.size() > 0) {
                    Messaging.SendEmailResult [] r = Messaging.sendEmail(emailList);
                    System.debug('result**'+r);
                }
            }
        }
    }
    
    
    //Future method of sendEmailToCaseNotificationSubscription 
    @future
    public static void sendEmailToCaseNotificationSubscription_future(List<Id> newCaseIds,String serializeOldMap,Boolean isInsert)
    {   
        List<Case> newCases = new List<Case>([Select Id,AccountId,ContactId,Do_not_show_in_portal__c,Sub_Type__c,
                                              RecordTypeId,Akam_Case_Id__c,Severity__c,Origin,AKAM_Created_Date__c,
                                              Subject,Description,CaseAutoId__C,Work_Type__c,Service_Incident__c,Incident_Name__c from Case where Id IN :newCaseIds]);
        
        Map<Id,Case> oldMap = (Map<Id,Case>)JSON.deserialize(serializeOldMap,Map<Id,Case>.class);
        sendEmailToCaseNotificationSubscription(newCases,oldMap,isInsert);
    }
    
    
    private static String createEmailBody(Case c, Account acct, Contact cont,String eventName,Case oldCase, String changeType)
    {
        String emailBody = '';
        String[] splittedDescription;
        String des = '';
        if(c.Description != null){
            splittedDescription = c.Description.split('\n');
            for(String iteratedPart : splittedDescription){
                if(des == ''){
                    des = iteratedPart;
                }else{
                    des = des + '<br />'+iteratedPart;
                }    
            }
        }    
        
        
        Map<Id, Schema.RecordTypeInfo> rTypeMap = Case.sObjectType.getDescribe().getRecordTypeInfosById();
        //emailBody += 'A new '+rTypeMap.get(c.RecordTypeId).getName()+' case has been created for Account: ' + acct.Name + '. <br /><br />';
        emailBody += eventName != 'Updated' ? 'A new '+rTypeMap.get(c.RecordTypeId).getName()+' case has been created for Account: ' + acct.Name + '. <br /><br />' : 'A '+rTypeMap.get(c.RecordTypeId).getName()+' case has been updated for Account: ' + acct.Name + '. <br /><br />';
        if( eventName == 'Updated'){
            if( changeType == 'Incident_Name__c' || changeType == 'Both' ){
                emailBody += 'Incident is changed to: '+c.Incident_Name__c+' From: '+ oldCase.Incident_Name__c +'<br /><br />';
            } 
            if( changeType == 'Severity__c' || changeType == 'Both' ){
                emailBody += 'Severity is changed to: '+c.Severity__c+' From: '+ oldCase.Severity__c +'<br /><br />';
            } 
        }
        //  emailBody += changeType =='Incident_Name__c' ? 'Incident is changed to:'+c.Incident_Name__c+' From:'+ oldCase.Incident_Name__c : 'Severity is changed to:'+c.Severity__c+' From:'+ oldCase.Severity__c+'<br /><br />';
        emailBody += '<table width=80% border=1 cellpadding=5 style=border-collapse:collapse;>';
        emailBody += '<tr><td>Case #: </td><td>' + c.Akam_Case_Id__c + ' </td></tr>';
        emailBody += '<tr><td>Type: </td><td>' + rTypeMap.get(c.RecordTypeId).getName() + ' </td></tr>';
        emailBody += '<tr><td>Opened Date: </td><td>' + c.AKAM_Created_Date__c + '</td></tr>';
        emailBody += '<tr><td>Severity: </td><td>' + (c.Severity__c != null ? c.Severity__c : '') + '</td></tr>';
        emailBody += '<tr><td>Incident: </td><td>' + (c.Incident_Name__c != null ? c.Incident_Name__c : '') + '</td></tr>';
        emailBody += '<tr><td>Case Contact: </td><td>' + (cont != null ? cont.Name : '') + '</td></tr>';
        emailBody += '<tr><td>Subject: </td><td>' + (c.Subject != null ? c.Subject : '') + '</td></tr>';
        emailBody += '<tr><td>Description: </td><td>' + des + '</span></td></tr></table><br /><br />';
        //  emailBody += '<tr><td>Description: </td><td>' + (c.Description != null ? c.Description : '') + '</span></td></tr></table><br /><br />';
        emailBody += 'For the latest status, go to: <a href=' + Environment_Setup__c.getOrgDefaults().CName_Url__c + c.Akam_Case_Id__c + '>Case</a>';
        System.debug('emailBody**'+emailBody);
        return emailBody;
    }
    
    // changes by Vandhana for S2ET
    public static void createCaseHistoryTrackerRec(Map<Id,Case> oldCase,Map<Id,Case> newCase)
    {
        List<Case_History_Tracker__c> chList = new List<Case_History_Tracker__c>();
        
        Case_History_Tracker__c ch = new Case_History_Tracker__c();
        List<SC_Case_History_Tracker__mdt> histTrackMDT = [Select Tracked_Field_Name__c, Tracked_Field_API_Name__c,
                                                           Duration_Field_API__c , Value_stored_in_Case_Field__c  
                                                           from SC_Case_History_Tracker__mdt];
        
        Map<String,SC_Case_History_Tracker__mdt> histTrackMDTMap = new Map<String,SC_Case_History_Tracker__mdt>();
        
        for(SC_Case_History_Tracker__mdt eachMDT : histTrackMDT)
        {
            histTrackMDTMap.put(eachMDT.Tracked_Field_API_Name__c,eachMDT);
        }
        
        for(Case c : newCase.values())
        {
            for(String caseFieldAPI : histTrackMDTMap.keySet())
            {
                if(oldCase.get(c.Id).get(caseFieldAPI) != newCase.get(c.Id).get(caseFieldAPI))
                {
                    ch = new Case_History_Tracker__c(Case__c=c.Id,
                                                     Case_Field__c = histTrackMDTMap.get(caseFieldAPI).Tracked_Field_Name__c,
                                                     Duration__c = String.valueOf(Trigger.oldMap.get(c.Id).get(histTrackMDTMap.get(caseFieldAPI).Duration_Field_API__c)),
                                                     Old_Value__c = String.valueOf(Trigger.oldMap.get(c.Id).get(histTrackMDTMap.get(caseFieldAPI).Value_stored_in_Case_Field__c)),
                                                     New_Value__c = String.valueOf(Trigger.newMap.get(c.Id).get(histTrackMDTMap.get(caseFieldAPI).Value_stored_in_Case_Field__c))
                                                    );
                    if(caseFieldAPI == 'OwnerId')
                    {
                        ch.Old_Case_Owner_Team__c = oldCase.get(c.Id).Case_Owner_Team__c;
                    }
                    ch.Case_Owner_Team__c = newCase.get(c.Id).Case_Owner_Team__c;
                    chList.add(ch);
                }    
            }
        }    
        
        try
        {
            if(!chList.isEmpty())
            {
                insert chList;
            }   
        }
        catch(Exception e)
        {
            System.debug('Case History Tracker records insert failed :');
            System.debug('Message : ' + e.getMessage());
            System.debug('Stack Trace : ' + e.getStackTraceString());
        }
    }
    
    // changes by Vandhana
    public static void createCaseHistoryCustomRecords(Map<Id,Case> oldCase,Map<Id,Case> newCase)
    {
        Map<String,SC_Case_History_Custom__mdt> customHistoryTrackerFields = new Map<String,SC_Case_History_Custom__mdt>();
        List<List<String>> passToFutureCustomHistory = new List<List<String>>();
        List<List<String>> passToFutureCustomLookupHistory = new List<List<String>>();
        
        List<SC_Case_History_Custom__mdt> customHistoryTrackerMDT = [SELECT Case_Field_API__c,Case_Field_Label__c,Case_Field_to_Display__c,Lookup_field__c,Case_Lookup_Object__c,Datatype__c 
                                                                     FROM SC_Case_History_Custom__mdt];
        
        for(SC_Case_History_Custom__mdt eachRec : customHistoryTrackerMDT)
        {
            customHistoryTrackerFields.put(eachRec.Case_Field_API__c,eachRec);
        }
        
        Map<Integer,String> mapMonthDayString = new Map<Integer,String>();
        mapMonthDayString.put(1,'Jan');
        mapMonthDayString.put(2,'Feb');
        mapMonthDayString.put(3,'Mar');
        mapMonthDayString.put(4,'Apr');
        mapMonthDayString.put(5,'May');
        mapMonthDayString.put(6,'Jun');
        mapMonthDayString.put(7,'Jul');
        mapMonthDayString.put(8,'Aug');
        mapMonthDayString.put(9,'Sep');
        mapMonthDayString.put(10,'Oct');
        mapMonthDayString.put(11,'Nov');
        mapMonthDayString.put(12,'Dec');
                
        // generic Case History Tracker
        for(Case c : newCase.values())
        {
            for(String eachCaseField : customHistoryTrackerFields.keySet())
            {            
                if(oldCase.get(c.Id).get(eachCaseField) != newCase.get(c.Id).get(eachCaseField))
                {
                    /*
                    * If field changed is a lookup, Array Order : CaseID, Field Label, LookupObject, OldVal, NewVal,Time,WhoUpdated
                    * Else, if the field is a simple field on Case, Array Order : CaseID, Field Label, OldVal, NewVal,Time,WhoUpdated
                    */
                    List<String> lstString = new List<String>();
                    lstString.add(c.Id);
                    lstString.add(customHistoryTrackerFields.get(eachCaseField).Case_Field_Label__c);
                    if(customHistoryTrackerFields.get(eachCaseField).Lookup_field__c)
                    {
                        lstString.add(String.valueOf(customHistoryTrackerFields.get(eachCaseField).Case_Lookup_Object__c));
                        lstString.add(String.valueOf(oldCase.get(c.Id).get(customHistoryTrackerFields.get(eachCaseField).Case_Field_API__c)));
                        lstString.add(String.valueOf(newCase.get(c.Id).get(customHistoryTrackerFields.get(eachCaseField).Case_Field_API__c)));
                        lstString.add(String.valueOf(System.now()));
                        lstString.add(Userinfo.getUserId());
                        passToFutureCustomLookupHistory.add(lstString);
                    }
                    else
                    {
                        if(customHistoryTrackerFields.get(eachCaseField).Datatype__c == 'Date')
                        {
                            Date dt;
                            dt = (Date) oldCase.get(c.Id).get(customHistoryTrackerFields.get(eachCaseField).Case_Field_API__c);
                            lstString.add(dt != null ? dt.day() + ' ' + mapMonthDayString.get(dt.month()) + ' ' + dt.year() : '');
                            
                            dt = (Date) newCase.get(c.Id).get(customHistoryTrackerFields.get(eachCaseField).Case_Field_API__c);
                            lstString.add(dt != null ? dt.day() + ' ' + mapMonthDayString.get(dt.month()) + ' ' + dt.year() : '');
                            
                        }
                        else
                            if(customHistoryTrackerFields.get(eachCaseField).Datatype__c == 'Checkbox')
                        {
                            lstString.add(Boolean.valueOf(oldCase.get(c.Id).get(customHistoryTrackerFields.get(eachCaseField).Case_Field_API__c)) ? 'Checked' : 'Unchecked');
                            lstString.add(Boolean.valueOf(newCase.get(c.Id).get(customHistoryTrackerFields.get(eachCaseField).Case_Field_API__c)) ? 'Checked' : 'Unchecked');
                        }
                        else if(customHistoryTrackerFields.get(eachCaseField).Datatype__c == 'Text')
                        {
                            lstString.add(String.valueOf(oldCase.get(c.Id).get(customHistoryTrackerFields.get(eachCaseField).Case_Field_API__c)));
                            lstString.add(String.valueOf(newCase.get(c.Id).get(customHistoryTrackerFields.get(eachCaseField).Case_Field_API__c)));
                        }
                        else if(customHistoryTrackerFields.get(eachCaseField).Datatype__c == 'DateTime')
                        { 
                            DateTime dt;
                            dt = (DateTime) oldCase.get(c.Id).get(customHistoryTrackerFields.get(eachCaseField).Case_Field_API__c);
                            lstString.add(dt != null ? dt.dayGMT() + ' ' + mapMonthDayString.get(dt.monthGMT()) + ' ' + dt.yearGMT() + ' '+ dt.formatGMT('hh:mm a')+ ' UTC' : '');
                            
                            dt = (DateTime) newCase.get(c.Id).get(customHistoryTrackerFields.get(eachCaseField).Case_Field_API__c);
                            lstString.add(dt != null ? dt.dayGMT() + ' ' + mapMonthDayString.get(dt.monthGMT()) + ' ' + dt.yearGMT() + ' '+ dt.formatGMT('hh:mm a')+ ' UTC' : '');
                        }
                        lstString.add(String.valueOf(System.now()));
                        lstString.add(Userinfo.getUserId());
                        passToFutureCustomHistory.add(lstString);   
                    }
                }
            }
        }
        
        if(!passToFutureCustomHistory.isEmpty() || !passToFutureCustomLookupHistory.isEmpty())
        {
            createCustomHistoryTracker(JSON.serialize(passToFutureCustomHistory), JSON.serialize(passToFutureCustomLookupHistory));
        }
    }
    
    @future
    public static void createCustomHistoryTracker(String lstLstStringJSON, String lstLstStringLookupJSON)
    {
        /*
            * If field changed is a lookup, Array Order : CaseID, Field Label, LookupObject, OldVal, NewVal,Time,WhoUpdated
            * Else, if the field is a simple field on Case, Array Order : CaseID, Field Label, OldVal, NewVal,Time,WhoUpdated
        */
        List<List<String>> lstLstString = (List<List<String>>)JSON.deserialize(lstLstStringJSON, List<List<String>>.class);
        List<List<String>> lstLstStringLookup = (List<List<String>>)JSON.deserialize(lstLstStringLookupJSON, List<List<String>>.class);
        
        Case_History_Custom__c caseHistoryCustom;
        List<Case_History_Custom__c> lstCaseHistCust = new List<Case_History_Custom__c>();
        
        if(!lstLstStringLookup.isEmpty())
        {
            List<Id> setOldNewValIDs = new List<Id>();
            for(Integer i=0; i<lstLstStringLookup.size(); i++)
            {
                setOldNewValIDs.add(String.valueOf(lstLstStringLookup[i][3])); 
                setOldNewValIDs.add(String.valueOf(lstLstStringLookup[i][4]));
            }
            System.debug(setOldNewValIDs);
            
            String queryOnSobj = 'SELECT Id,Name FROM ' + lstLstStringLookup[0][2] + ' WHERE ID IN :setOldNewValIDs ';
            System.debug('QUERY : ' +queryOnSobj );
            Map<Id,Sobject> mapSObj = new Map<Id,SObject>(Database.query(queryOnSobj));
            //List<Sobject> mapSObj = Database.query(queryOnSobj);
            
            for(Integer i=0; i<lstLstStringLookup.size(); i++)
            {
                List<String> lstString = lstLstStringLookup[i];
                caseHistoryCustom = new Case_History_Custom__c();
                caseHistoryCustom.Case__c = lstString[0];
                caseHistoryCustom.Field__c = lstString[1];
                if(mapSObj.get(lstString[3]) != NULL)
                {
                    if(String.isNotBlank(String.valueOf(mapSObj.get(lstString[3]).get('Name'))))
                        caseHistoryCustom.Original_Value__c = String.valueOf(mapSObj.get(lstString[3]).get('Name'));
                }
                if(mapSObj.get(lstString[4]) != NULL)
                {
                    if(String.isNotBlank(String.valueOf(mapSObj.get(lstString[4]).get('Name'))))
                        caseHistoryCustom.New_Value__c = String.valueOf(mapSObj.get(lstString[4]).get('Name'));
                }
                caseHistoryCustom.Date__c = DateTime.valueOf(lstString[5]);
                caseHistoryCustom.User__c = lstString[6];
                lstCaseHistCust.add(caseHistoryCustom);
            }
        }

        if(!lstLstString.isEmpty())
        {
            for(Integer i=0; i<lstLstString.size(); i++)
            {
                List<String> lstString = lstLstString[i];
                caseHistoryCustom = new Case_History_Custom__c();
                caseHistoryCustom.Case__c = lstString[0];
                caseHistoryCustom.Field__c = lstString[1];
                caseHistoryCustom.Original_Value__c = lstString[2];
                caseHistoryCustom.New_Value__c = lstString[3];
                caseHistoryCustom.Date__c = DateTime.valueOf(lstString[4]);
                caseHistoryCustom.User__c = lstString[5];
                lstCaseHistCust.add(caseHistoryCustom);
            }
        }
        
        if(!lstCaseHistCust.isEmpty())
        {
            insert lstCaseHistCust;
        }
    }
    
    // changes by Vandhana - ESESP-3529 : Task functionality for S2ET Cases (ensure all tasks closed before closing S2ET Case)
    public static void checkTaskCloseS2ETCase(Map<Id,Case> mapCases)
    {
        Id secServTaskRecTypeId = Task.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Security_Services_Activity').getRecordTypeId();
        Id plxTaskRecTypeId = Task.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Provisioning_Activity').getRecordTypeId();
        
        Boolean checkCloseEsc = [SELECT DeveloperName,Active__c
                                 FROM SC_Utility__mdt
                                 WHERE DeveloperName = 'S2ET_Disable_Closed_Esc_Check'].Active__c; 
        
        AggregateResult[] lstS2ETOpenTasksAggRes = [SELECT WhatId,Count(Id) 
                                                    FROM Task 
                                                    WHERE (RecordTypeId = :secServTaskRecTypeId OR RecordTypeId = :plxTaskRecTypeId) AND (Status != 'Completed' AND Status != 'Cancelled' AND Status != 'Not Applicable' AND Status != 'Failed')
                                                    AND WhatId IN :mapCases.keyset() 
                                                    GROUP BY WhatId];
        
        Map<Id,Integer> mapCaseOpenTaskCount = new Map<Id,Integer>();
        
        for(AggregateResult eachAggRes : lstS2ETOpenTasksAggRes)
        {
            mapCaseOpenTaskCount.put((Id)eachAggRes.get('WhatId'), (Integer)eachAggRes.get('expr0'));
        }
        
        AggregateResult[] lstS2ETOpenEscsAggRes = [SELECT Case__c,Count(Id) 
                                                   FROM Engagement_Request__c 
                                                   WHERE RecordType.Name = 'External Team' AND Request_Status__c != 'Completed'
                                                   AND Case__c IN :mapCases.keyset() 
                                                   GROUP BY Case__c];
        
        Map<Id,Integer> mapCaseOpenEscCount = new Map<Id,Integer>();
        
        for(AggregateResult eachAggRes : lstS2ETOpenEscsAggRes)
        {
            mapCaseOpenEscCount.put((Id)eachAggRes.get('Case__c'), (Integer)eachAggRes.get('expr0'));
        }
        
        
        if(!mapCaseOpenTaskCount.isEmpty() || !mapCaseOpenEscCount.isEmpty())
        {
            for(Id eachCaseId : mapCases.keyset())
            {
                if( (mapCaseOpenTaskCount.containsKey(eachCaseId) && mapCaseOpenTaskCount.get(eachCaseId) > 0) 
                   && (mapCaseOpenEscCount.containsKey(eachCaseId) && mapCaseOpenEscCount.get(eachCaseId) > 0 && !checkCloseEsc) )
                {
                    mapCases.get(eachCaseId).addError('Please ensure all associated Tasks are completed before closing the Case. Also, ensure all associated Escalations are closed before closing the Case or select IAT Following Up as Close Code.');
                }
                else
                if(mapCaseOpenTaskCount.containsKey(eachCaseId) && mapCaseOpenTaskCount.get(eachCaseId) > 0) 
                {
                    mapCases.get(eachCaseId).addError('Please ensure all associated Tasks are completed before closing the Case. ');
                }
                else
                if(mapCaseOpenEscCount.containsKey(eachCaseId) && mapCaseOpenEscCount.get(eachCaseId) > 0 && mapCases.get(eachCaseId).Close_Code__c != 'IAT Following Up' && !checkCloseEsc) 
                {
                    mapCases.get(eachCaseId).addError('Please ensure all associated Escalations are closed before closing the Case or select IAT Following Up as Close Code.');
                }
            }
        }
    }


    //ESESP-5678 : this method is also used for AutoTaskCreation for S2ET & 24 PS cases as well.
    public static void autogenTaskForS2ETCase(Map<Id,Case> mapS2ETCases,Map<String,String> mapSCUtilMDT)
    {
        SC_CaseTriggerHelperClass2.s2etTaskRecursion = false;
        Map<Id,Case> mapNonSchedCase = new Map<Id,Case>();
        Map<Id,Case> mapSchedCase = new Map<Id,Case>();
        List<Task> lstTask = new List<Task>();
        List<Task> lstReceivedTasks = new List<Task>();
        
        /*
        Map<Id,Case> mapExistingAutogenTasksCase = new Map<Id,Case>([SELECT Id,(SELECT Id,Assigned_Division__c,Type__c 
                                                                                FROM Tasks 
                                                                                WHERE Assigned_Division__c = 's2etautogen')
                                                                     FROM Case
                                                                     WHERE Id IN :mapS2ETCases.keyset()]);
        */
        for(Case eachCase : mapS2ETCases.values())
        {
            //if(mapExistingAutogenTasksCase.get(eachCase.Id).Tasks.isEmpty())
            //{
                lstReceivedTasks = createS2ETTask(eachCase,eachCase.Request_Type__c,mapSCUtilMDT);
                lstTask.addAll(lstReceivedTasks);
            //}
        }
        insert lstTask;
    }
    
    public static List<Task> createS2ETTask(Case eachCase, String requestType, Map<String,String> mapSCUtilMDT)
    {
        List<Task> lstS2ETTask = new List<Task>();
        Task newTask = new Task();
        
        Map<String,String> mapCRMInfo = new Map<String,String>();
        String opsName, opsId = '';
        
        List<SC_Utility__mdt> crmOpsInfo = [SELECT DeveloperName,Value_Text__c FROM SC_Utility__mdt WHERE DeveloperName IN ('CRM_Ops_Id','CRM_Ops_Name')];
        for(SC_Utility__mdt eachMDTRec: crmOpsInfo)
        {
            if(eachMDTRec.DeveloperName == 'CRM_Ops_Id')
                opsId = eachMDTRec.Value_Text__c;
            else if(eachMDTRec.DeveloperName == 'CRM_Ops_Name')
                opsName = eachMDTRec.Value_Text__c;
        }

        if(eachCase.Service__c == 'Emergency Integration')
        {
            newTask = new Task();
            newTask.WhatId = eachCase.Id;
            newTask.RecordTypeId = Task.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Security_Services_Activity').getRecordTypeId();
            newTask.Status = 'Not Started';
            newTask.OwnerId = mapSCUtilMDT.get('Owner_Not_Assigned_User_Id');
            newTask.Assigned_Division__c = 's2etautogen';
            newTask.Type__c = 'Case Acknowledgement';
            newTask.Subject = 'Complete case acknowledgement';
            newTask.Description = 'Include customer-specific details here, if appropriate.';
            newTask.DueDateProlexic__c = eachCase.Case_Transition_Date__c.addHours(1);
            newTask.CreatedById = opsId;
            newTask.AKAM_Created_By__c = opsName;
            newTask.AKAM_Created_Date__c = Datetime.now();
            newTask.AKAM_Modified_By__c = opsName;
            newTask.AKAM_Modified_Date__c = Datetime.now();
            newTask.AKAM_System__c = 'FORCE';
            lstS2ETTask.add(newTask);
        }
        else
        if(eachCase.Service__c != 'Emergency Integration' && requestType != 'Scheduled Deployment')
        {
            for(Integer i=0; i<4; i++)
            {
                newTask = new Task();
                newTask.WhatId = eachCase.Id;
                newTask.RecordTypeId = Task.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Security_Services_Activity').getRecordTypeId();
                newTask.Status = 'Not Started';
                newTask.OwnerId = mapSCUtilMDT.get('Owner_Not_Assigned_User_Id');
                newTask.Assigned_Division__c = 's2etautogen';
                newTask.AKAM_Created_By__c = opsName;
                newTask.AKAM_Created_Date__c = Datetime.now();
                newTask.AKAM_Modified_By__c = opsName;
                newTask.AKAM_Modified_Date__c = Datetime.now();
                newTask.AKAM_System__c = 'FORCE';
                
                if(i==0)
                {
                    newTask.Type__c = 'Case Acknowledgement';
                    newTask.Subject = 'Complete case acknowledgement';
                    newTask.Description = 'Include customer-specific details here, if appropriate.';
                    newTask.DueDateProlexic__c = eachCase.Case_Transition_Date__c.addHours(1);
                    lstS2ETTask.add(newTask);

                }
                else if(i==1)
                {
                    newTask.Type__c = 'Initial Investigation';
                    newTask.Subject = 'Perform initial investigation';
                    newTask.Description = 'Include customer-specific details here, if appropriate.';
                    newTask.DueDateProlexic__c = eachCase.Case_Transition_Date__c.addHours(6);
                    lstS2ETTask.add(newTask);
                }
                //ESESP-5678 : Adding below s2et check to avoid Task Creation for 24PS Cases
                else if(i==2 && ((eachCase.Origin_Email__c != NULL && eachCase.Origin_Email__c.containsIgnoreCase('s2et')) || mapSCUtilMDT.get('S2ET_Queue_Id').containsIgnoreCase(eachCase.OwnerId) ))
                {
                    newTask.Type__c = 'Gather Logs';
                    newTask.Subject = 'Gather logs';
                    newTask.Description = 'Include links to log queries generated.';
                    newTask.DueDateProlexic__c = eachCase.Case_Transition_Date__c.addHours(6);
                    lstS2ETTask.add(newTask);
                }
                //ESESP-5678 : Adding below s2et check to avoid Task Creation for 24PS Cases
                else if ((eachCase.Origin_Email__c != NULL && eachCase.Origin_Email__c.containsIgnoreCase('s2et')) || mapSCUtilMDT.get('S2ET_Queue_Id').containsIgnoreCase(eachCase.OwnerId) )
                {
                    newTask.Type__c = 'Perform Analysis';
                    newTask.Subject = 'Perform analysis';
                    newTask.Description = 'Document findings from log analysis work here.';
                    newTask.DueDateProlexic__c = eachCase.Case_Transition_Date__c.addHours(6);
                    lstS2ETTask.add(newTask);

                }
                //lstS2ETTask.add(newTask);
            }
        }
        else if(requestType == 'Scheduled Deployment' && eachCase.Service__c != 'Emergency Integration'
                && String.isNotBlank(String.valueOf(eachCase.Requested_Completion_Date_UTC__c))
                && String.isNotBlank(eachCase.Requested_Completion_Time_UTC__c))
        {
            String[] timeSplit = eachCase.Requested_Completion_Time_UTC__c.split(':');
            Time timeValue = Time.newInstance( Integer.valueOf(timeSplit[0]),Integer.valueOf(timeSplit[1]),0,0);   
            DateTime targetDateTime = DateTime.newInstanceGMT(eachCase.Requested_Completion_Date_UTC__c, timeValue);
            DateTime targetDateTimeLocal = DateTime.newInstance(eachCase.Requested_Completion_Date_UTC__c, timeValue);
            
            System.debug('TIME GMT: ' + targetDateTime);
            System.debug('TIME LOCAL: ' + targetDateTimeLocal);
            
            for(Integer i=0; i<3; i++)
            {
                newTask = new Task();
                newTask.WhatId = eachCase.Id;
                newTask.RecordTypeId = Task.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Security_Services_Activity').getRecordTypeId();
                newTask.Status = 'Not Started';
                newTask.OwnerId = mapSCUtilMDT.get('Owner_Not_Assigned_User_Id');
                newTask.Assigned_Division__c = 's2etautogen';
                newTask.AKAM_Created_By__c = opsName;
                newTask.AKAM_Created_Date__c = Datetime.now();
                newTask.AKAM_Modified_By__c = opsName;
                newTask.AKAM_Modified_Date__c = Datetime.now();
                newTask.AKAM_System__c = 'FORCE';
                
                if(i==0)
                {
                    newTask.Type__c = 'Scheduled Deployment';
                    newTask.Subject = 'Perform scheduled deployment';
                    newTask.Description = 'Include deployment specifications here.';
                    newTask.DueDateProlexic__c = targetDateTime;
                }
                else if(i==1)
                {
                    newTask.Type__c = 'Verify Change Impact';
                    newTask.Subject = 'Verify change impact #1';
                    newTask.Description = 'Document change impact here.';
                    newTask.DueDateProlexic__c = targetDateTime.addHours(1);
                }
                else
                {
                    newTask.Type__c = 'Verify Change Impact';
                    newTask.Subject = 'Verify change impact #2';
                    newTask.Description = 'Document change impact here.';
                    newTask.DueDateProlexic__c = targetDateTime.addHours(6);
                }
                lstS2ETTask.add(newTask);
            }
        }
        return lstS2ETTask;
    }
    
    public static void createS2ETTaskSchedDeploy(List<Task> lstSchedDepTasksCreated)
    {
        String ownerNotAssignedId = [SELECT DeveloperName,Value_Text__c
                                     FROM SC_Utility__mdt
                                     WHERE DeveloperName = 'Owner_Not_Assigned_User_Id'].Value_Text__c;
        
        List<Task> lstS2ETTask = new List<Task>();
        Task newTask = new Task();
        Map<String,String> mapCRMInfo = new Map<String,String>();
        String opsName, opsId = '';
        
        List<SC_Utility__mdt> crmOpsInfo = [SELECT DeveloperName,Value_Text__c FROM SC_Utility__mdt WHERE DeveloperName IN ('CRM_Ops_Id','CRM_Ops_Name')];
        for(SC_Utility__mdt eachMDTRec: crmOpsInfo)
        {
            if(eachMDTRec.DeveloperName == 'CRM_Ops_Id')
                opsId = eachMDTRec.Value_Text__c;
            else if(eachMDTRec.DeveloperName == 'CRM_Ops_Name')
                opsName = eachMDTRec.Value_Text__c;
        }
        
        for(Task eachTask : lstSchedDepTasksCreated)
        {
            for(Integer i=0; i<2; i++)
            {
                newTask = new Task();
                newTask.WhatId = eachTask.WhatId;
                newTask.RecordTypeId = eachTask.RecordTypeId;
                newTask.Status = 'Not Started';
                newTask.OwnerId = ownerNotAssignedId; //mapSCUtilMDT.get('Owner_Not_Assigned_User_Id');
                newTask.Assigned_Division__c = 's2etautogen';
                newTask.AKAM_Created_By__c = opsName;
                newTask.AKAM_Created_Date__c = Datetime.now();
                newTask.AKAM_Modified_By__c = opsName;
                newTask.AKAM_Modified_Date__c = Datetime.now();
                newTask.AKAM_System__c = 'FORCE';
                
                if(i==0)
                {
                    newTask.Type__c = 'Verify Change Impact';
                    newTask.Subject = 'Verify change impact #1';
                    newTask.Description = 'Document change impact here.';
                    newTask.DueDateProlexic__c = eachTask.DueDateProlexic__c.addHours(1); 
                }
                else
                {
                    newTask.Type__c = 'Verify Change Impact';
                    newTask.Subject = 'Verify change impact #2';
                    newTask.Description = 'Document change impact here.';
                    newTask.DueDateProlexic__c = eachTask.DueDateProlexic__c.addHours(6);
                }
                lstS2ETTask.add(newTask);
            }
        }
        SC_TaskTriggerHandler.s2etSchedDepTaskBypass = true;
        insert lstS2ETTask;
        s2etTaskRecursion = false;
    }
    
    @future
    public static void setS2ETNoCommCheckbox(List<Id> lstCaseId)
    {
        System.debug('CALLED FUTURE S2ET');
        List<Case> lstCase = [SELECT Id,S2ET_No_Comm_Check__c FROM Case WHERE ID IN :lstCaseId];
        List<Case> lstCaseToUpdate = new List<Case>();
        for(Case c : lstCase)
        {
            c.S2ET_No_Comm_Check__c = true;
            lstCaseToUpdate.add(c);
        }
        update lstCaseToUpdate;
    }

    /*Change by Vikas for creating autogen tasks for Provisioning case ESESP-3663*/
    public static void autogenTaskForPlxCase(Map<Id,Case> mapPlxCases,Map<String,String> mapSCUtilMDT)
    {
        system.debug('Inside autogenTaskForPlxCase ');
        Map<Id,Case> mapNonSchedCase = new Map<Id,Case>();
        Map<Id,Case> mapSchedCase = new Map<Id,Case>();
        List<Task> lstTask = new List<Task>();
        List<Task> lstReceivedTasks = new List<Task>();
        
        Map<Id,Case> mapExistingAutogenTasksCase = new Map<Id,Case>([SELECT Id,(SELECT Id,Assigned_Division__c,Type__c 
                                                                                FROM Tasks 
                                                                                WHERE Assigned_Division__c = 'plxautogen')
                                                                     FROM Case
                                                                     WHERE Id IN :mapPlxCases.keyset()]);
        
        for(Case eachCase : mapPlxCases.values())
        {
            if(mapExistingAutogenTasksCase.get(eachCase.Id).Tasks.isEmpty())
            {
                lstReceivedTasks = createPlxTask(eachCase,eachCase.Request_Type__c,mapSCUtilMDT);
                lstTask.addAll(lstReceivedTasks);
            }
        }
        system.debug('lstTask : '+lstTask);
        insert lstTask;
    }
    //Changes by Tejaswini for ESESP-4616
    public static List<Task> createPlxTask(Case eachCase, String requestType, Map<String,String> mapSCUtilMDT)
    {
        String opsName, opsId = '';
        
        List<SC_Utility__mdt> crmOpsInfo = [SELECT DeveloperName,Value_Text__c FROM SC_Utility__mdt WHERE DeveloperName IN ('CRM_Ops_Id','CRM_Ops_Name')];
        for(SC_Utility__mdt eachMDTRec: crmOpsInfo)
        {
            if(eachMDTRec.DeveloperName == 'CRM_Ops_Id')
                opsId = eachMDTRec.Value_Text__c;
            else if(eachMDTRec.DeveloperName == 'CRM_Ops_Name')
                opsName = eachMDTRec.Value_Text__c;
        }
        
        List<Task> plxTaskList = new List<Task>();
        Task newTask = new Task();
        Map<String,String> integrationTaskDetailMap = new Map<String, String>{
            /*
            'Case Acknowledgement' => 'Sub:Case Acknowledgement;Desc:Acknowdgemnent of case',
                'Customer E-mail' => 'Sub:Customer E-mail;Desc:E-mails to customer',
                'Kick-Off Call' => 'Sub:Kick-Off Call;Desc:Work related to kick-off call',
                'Turn-up Call' => 'Sub:Turn-up Call;Desc:Work related to turn up calls',
                'Build Configuration' => 'Sub:Build Configuration;Desc:Configuration Work',
                'Peer review' => 'Sub:Peer review;Desc:Peer review related work',
                'Status Call' => 'Sub:Status Call;Desc:General Status Calls',
                'Technical Call' => 'Sub:Technical Call;Desc:Any type of technical calls',
                'Validation/Testing Call' => 'Sub:Validation/Testing Call;Desc:Validation/Testing call',
                'Enable Alerting' => 'Sub:Enable Alerting;Desc:Enablement of alerting',
                'Closing Call' => 'Sub:Closing Call;Desc:Work related to closing calls'
            */
            
            'Build Configuration' => 'Sub:Build Configuration;Desc:Configuration Work',
            'Peer review' => 'Sub:Peer review;Desc:Peer review related work'
        };
            
        Map<String,String> SCATaskDetailMap = new Map<String, String>{
               /* 
                'Case Acknowledgement' => 'Sub:Case Acknowledgement;Desc:Acknowdgemnent of case',
                'Technical Call' => 'Sub:Technical Call;Desc:Any type of technical calls'
              */
            
                
                'Build Configuration' => 'Sub:Build Configuration;Desc:Configuration Work',
                'Peer review' => 'Sub:Peer review;Desc:Peer review related work'
        };
           
        Map<String,String> otherTaskDetailMap = new Map<String, String>{
            /*    
                'Case Acknowledgement' => 'Sub:Case Acknowledgement;Desc:Acknowdgemnent of case',
                'Deprovisioning' => 'Sub:Deprovisioning;Desc:Deprovisioning of service',
                'Peer review' => 'Sub:Peer review;Desc:Peer review related work',
                'Customer E-mail' => 'Sub:Customer E-mail;Desc:E-mails to customer'
            */
                'Build Configuration' => 'Sub:Build Configuration;Desc:Configuration Work',
                'Peer review' => 'Sub:Peer review;Desc:Peer review related work'
            
        };
        if(requestType == 'Onboarding / Integration')
        {
            for(String taskType: integrationTaskDetailMap.keySet()){
                newTask = new Task();
                newTask.WhatId = eachCase.Id;
                newTask.RecordTypeId = Task.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Provisioning_Activity').getRecordTypeId();
                newTask.Status = 'Unassigned';
                newTask.OwnerId = mapSCUtilMDT.get('Owner_Not_Assigned_User_Id');
                newTask.Assigned_Division__c = 'plxautogen';
                newTask.Type__c = taskType;
                newTask.Subject = integrationTaskDetailMap.get(taskType).split(';')[0].split(':')[1];
                newTask.Description = integrationTaskDetailMap.get(taskType).split(';')[1].split(':')[1];
               /* if(taskType == 'Case Acknowledgement'){
                    newTask.DueDateProlexic__c = system.now().addHours(12);
                } */   
                newTask.AKAM_Created_By__c = opsName;
                newTask.AKAM_Created_Date__c = Datetime.now();
                newTask.AKAM_Modified_By__c = opsName;
                newTask.AKAM_Modified_Date__c = Datetime.now();
                newTask.AKAM_System__c = 'FORCE';                
                plxTaskList.add(newTask);
            }
        }
        else if(requestType == 'Security Configuration Assistance')
        {
            for(String taskType: SCATaskDetailMap.keySet()){
                newTask = new Task();
                newTask.WhatId = eachCase.Id;
                newTask.RecordTypeId = Task.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Provisioning_Activity').getRecordTypeId();
                newTask.Status = 'Unassigned';
                newTask.OwnerId = mapSCUtilMDT.get('Owner_Not_Assigned_User_Id');
                newTask.Assigned_Division__c = 'plxautogen';
                newTask.Type__c = taskType;
                newTask.Subject = SCATaskDetailMap.get(taskType).split(';')[0].split(':')[1];
                newTask.Description = SCATaskDetailMap.get(taskType).split(';')[1].split(':')[1];
                /*if(taskType == 'Case Acknowledgement'){
                    newTask.DueDateProlexic__c = system.now().addHours(12);
                }*/
                newTask.AKAM_Created_By__c = opsName;
                newTask.AKAM_Created_Date__c = Datetime.now();
                newTask.AKAM_Modified_By__c = opsName;
                newTask.AKAM_Modified_Date__c = Datetime.now();
                newTask.AKAM_System__c = 'FORCE'; 
                plxTaskList.add(newTask);
            }
        }
        else
        {
            for(String taskType: otherTaskDetailMap.keySet()){
                newTask = new Task();
                newTask.WhatId = eachCase.Id;
                newTask.RecordTypeId = Task.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Provisioning_Activity').getRecordTypeId();
                newTask.Status = 'Unassigned';
                newTask.OwnerId = mapSCUtilMDT.get('Owner_Not_Assigned_User_Id');
                newTask.Assigned_Division__c = 'plxautogen';
                newTask.Type__c = taskType;
                newTask.Subject = otherTaskDetailMap.get(taskType).split(';')[0].split(':')[1];
                newTask.Description = otherTaskDetailMap.get(taskType).split(';')[1].split(':')[1];
                /*if(taskType == 'Case Acknowledgement'){
                    newTask.DueDateProlexic__c = system.now().addHours(12);
                }*/
                newTask.AKAM_Created_By__c = opsName;
                newTask.AKAM_Created_Date__c = Datetime.now();
                newTask.AKAM_Modified_By__c = opsName;
                newTask.AKAM_Modified_Date__c = Datetime.now();
                newTask.AKAM_System__c = 'FORCE'; 
                plxTaskList.add(newTask);
            }
        }
            
        return plxTaskList;
    }
    /*End of change by Vikas for creating autogen tasks for Provisioning case ESESP-3663*/
}