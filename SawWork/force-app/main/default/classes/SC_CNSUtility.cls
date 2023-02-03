/*******************************************************************************************************
Author       :   jrathod
Created Date :   Dec 29, 2021
JIRA         :   ESESP-5526
Description  :   Created this utitlity class to handle Case Notification Subscription related functionalities.
********************************************************************************************************
Jay         29-Dec-2021     ESESP-5526      Initial version
*/

public without sharing class SC_CNSUtility {

    /**
     * @description @see SC_CNSUtility.emailToCNS
     * @param emailMessageIds EmailMessage record Ids.
     * @author jrathod
     * @date 12/29/21
     */
    @Future
    public static void emailToCNSAsync(List<Id> emailMessageIds){
        List<EmailMessage> messages = [SELECT Id,ParentId,Status,HasAttachment,FromAddress,ToAddress,CcAddress,MessageDate,Subject,HtmlBody,TextBody,Incoming FROM EmailMessage WHERE Id IN: emailMessageIds];
        emailToCNS(messages);
    }

    /**
     * @description This method forwards email message to CNS subscribers
     * @param emailMessages Messages to forward
     * @author jrathod
     * @date 12/29/21
     */
    public static void emailToCNS(List<EmailMessage> emailMessages) {
        SC_Utility__mdt mdt = SC_Utility__mdt.getInstance('CaseRTForEmailCommListen');
        if (!mdt.Active__c) return;
        Map<String,Id> applicableRTs = new Map<String, Id>();//Applicable Case record types
        for(String rtName : mdt.Value__c.split(',')){
            applicableRTs.put(rtName,Schema.SObjectType.Case.getRecordTypeInfosByName().get(rtName).getRecordTypeId());
        }
        Map<Id,List<EmailMessage>> caseIdToMessage = new Map<Id, List<EmailMessage>>();
        Set<Id> emWithAttachments = new Set<Id>();
        for(EmailMessage message : emailMessages){
            //don't want to send draft version on the email message
            if (message.Status!='5') {
                if (message.HasAttachment) {
                    emWithAttachments.add(message.Id);
                }
                if (caseIdToMessage.containsKey(message.ParentId)) {
                    caseIdToMessage.get(message.ParentId).add(message);
                }else{
                    caseIdToMessage.put(message.ParentId,new List<EmailMessage>{message});
                }
            }
        }

        Map<Id,List<Id>> emIdByAttachmentIds = new Map<Id, List<Id>>();
        if (!emWithAttachments.isEmpty()) {
            for(ContentDocumentLink dl : [SELECT LinkedEntityId,ContentDocument.LatestPublishedVersionId FROM ContentDocumentLink WHERE LinkedEntityId IN :emWithAttachments]){
                if (emIdByAttachmentIds.containsKey(dl.LinkedEntityId)) {
                    emIdByAttachmentIds.get(dl.LinkedEntityId).add(dl.ContentDocument.LatestPublishedVersionId);
                }else{
                    emIdByAttachmentIds.put(dl.LinkedEntityId,new List<Id>{dl.ContentDocument.LatestPublishedVersionId});
                }
            }
            for (Attachment att : [SELECT Id,ParentId FROM Attachment WHERE ParentId IN :emWithAttachments]){
                if (emIdByAttachmentIds.containsKey(att.ParentId)) {
                    emIdByAttachmentIds.get(att.ParentId).add(att.Id);
                }else{
                    emIdByAttachmentIds.put(att.ParentId,new List<Id>{att.Id});
                }
            }
        }

        if (!caseIdToMessage.isEmpty()) {
            Map<Id,List<Case>> accIdByCases = new Map<Id, List<Case>>();
            Map<Id,Case> casesByIds = new Map<Id, Case>();
            for (Case aCase : [SELECT Id,AccountId,RecordType_Name__c,Sub_Type__c,Do_Not_Show_in_Portal__c,Work_Type__c,Severity__c,Service_Incident__c,Origin,AKAM_Case_ID__c,Case_Account_Name__c,Subject,AKAM_Created_Date__c,Incident_Name__c,Contact.Name,Description FROM Case WHERE Id IN: caseIdToMessage.keySet() AND RecordTypeId IN :applicableRTs.values()]){
                casesByIds.put(aCase.Id,aCase);
                if (accIdByCases.containsKey(aCase.AccountId)) {
                    accIdByCases.get(aCase.AccountId).add(aCase);
                }else {
                    accIdByCases.put(aCase.AccountId,new List<Case>{aCase});
                }
            }
            Map<Id,Set<Id>> caseIdToSubs = new Map<Id, Set<Id>>();
            Set<Id> userIds = new Set<Id>();
            for (Case_Notification_Subscription__c sub : [SELECT Id,Account__c,User__c,Case_Record_Type__c,Sub_Type__c,Portal_Visibility__c,Case_Origin__c,Severity__c,Incident__c FROM Case_Notification_Subscription__c WHERE Account__c IN :accIdByCases.keySet() AND ListenEmailComms__c = TRUE]){
                for (Case aCase : accIdByCases.get(sub.Account__c)){
                    if (isCaseEligibleForCNS(aCase,sub)) {
                        userIds.add(sub.User__c);
                        if (caseIdToSubs.containsKey(aCase.Id)) {
                            caseIdToSubs.get(aCase.Id).add(sub.User__c);
                        }else{
                            caseIdToSubs.put(aCase.Id,new Set<Id>{sub.User__c});
                        }
                    }
                }
            }
            for (SC_CNSOnCase__c sub : [SELECT Id,User__c,Case__c FROM SC_CNSOnCase__c WHERE Case__c IN :casesByIds.keySet() AND ListenEmailComms__c = TRUE AND User__c!=NULL]){
                userIds.add(sub.User__c);
                if (caseIdToSubs.containsKey(sub.Case__c)) {
                    caseIdToSubs.get(sub.Case__c).add(sub.User__c);
                }else{
                    caseIdToSubs.put(sub.Case__c,new Set<Id>{sub.User__c});
                }
            }
            if (!caseIdToSubs.isEmpty()) {
                System.debug('userIds: '+userIds);
                Map<Id,User> usersMap = new Map<Id, User>([SELECT Id,IsActive FROM User WHERE Id IN :userIds]);
                Id noReply = SC_FromEmailAddress__c.getValues('Noreply').OrgAddressId__c;
                List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
                for (Id caseId : caseIdToSubs.keySet()){
                    Set<Id> subscriberIds = caseIdToSubs.get(caseId);
                    for (EmailMessage em : caseIdToMessage.get(caseId)){
                        String header = createEmailForwardHeader(em);
                        Boolean hasAtt = emIdByAttachmentIds.containsKey(em.Id);
                        for (Id userId : subscriberIds){
                            User aUsr = usersMap.get(userId);
                            if (!aUsr.IsActive) continue;
                            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                            message.setSubject(em.Subject);
                            message.setTargetObjectId(userId);
                            message.setOrgWideEmailAddressId(noReply);
                            message.setSaveAsActivity(false);
                            message.setHtmlBody(header+em.HtmlBody);
                            message.setPlainTextBody(em.TextBody);
                            if (hasAtt) {
                                message.setEntityAttachments(emIdByAttachmentIds.get(em.Id));
                            }
                            messages.add(message);
                        }
                    }
                }
                if (!messages.isEmpty()) {
                    Messaging.sendEmail(messages);
                }
            }
        }
    }

    public static Boolean isCaseEligibleForCNS(Case aCase, Case_Notification_Subscription__c sub){

        if (!(sub.Case_Record_Type__c == 'All' || sub.Case_Record_Type__c == aCase.RecordType_Name__c)) return false;
        if (!(sub.Sub_Type__c == null || sub.Sub_Type__c == 'All' || sub.Sub_Type__c == aCase.Sub_Type__c)) return false;
        if(!(sub.Portal_Visibility__c == null || sub.Portal_Visibility__c == 'All' || aCase.Do_Not_Show_in_Portal__c == false)) return false;
        if(!(sub.Case_Origin__c == null || sub.Case_Origin__c == 'All' || sub.Case_Origin__c =='N/A' || (aCase.Origin != 'Proactive' && aCase.Work_Type__c != 'Proactive'))) return false;
        if(sub.Incident__c == 'Yes' && aCase.Service_Incident__c==null) return false;
        Integer sev = !String.isBlank(aCase.Severity__c) ? Integer.valueOf(aCase.Severity__c.substringBefore(' ')) : -1;
        if(!((sub.Severity__c.contains('3 & below') && sev >= 3 ) || sub.Severity__c.contains(sev+''))) return false;

        return true;
    }
/*
    public static Messaging.SingleEmailMessage createEmailCommunicationNotification(String accName,String akamCaseId, String rtName, String sev, String caseSubject, Datetime createdDate, String incidentName, String caseContact, String description, String eventName, String emailMessageId){
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        String subject = accName+': '+'Severity '+sev+' '+rtName+' Case has '+eventName+' [AKAM-CASE #'+akamCaseId+']: '+caseSubject;
        message.setSubject(subject);
        description = description.replaceAll('\n','<br>');
        String emailBody = '<table width=80% border=1 cellpadding=5 style=border-collapse:collapse;>';
        emailBody += '<tr><td>Case #: </td><td>' + akamCaseId + ' </td></tr>';
        emailBody += '<tr><td>Type: </td><td>' + rtName + ' </td></tr>';
        emailBody += '<tr><td>Opened Date: </td><td>' + createdDate + '</td></tr>';
        emailBody += '<tr><td>Severity: </td><td>' + (sev != null ? sev : '') + '</td></tr>';
        emailBody += '<tr><td>Incident: </td><td>' + (incidentName != null ? incidentName : '') + '</td></tr>';
        emailBody += '<tr><td>Case Contact: </td><td>' + (caseContact!=null ? caseContact : '') + '</td></tr>';
        emailBody += '<tr><td>Subject: </td><td>' + (caseSubject != null ? caseSubject : '') + '</td></tr>';
        emailBody += '<tr><td>Description: </td><td>' + description + '</span></td></tr>';
        emailBody += eventName == 'New Email Conversation' ? '<tr><td>Email Message: </td><td><a href="' + Url.getSalesforceBaseUrl().toExternalForm()+'/'+emailMessageId + '">Click to go to the new email </a></span></td></tr>': '';
        emailBody += '</table><br /><br />';
        emailBody += 'For the latest status, go to: <a href=' + Environment_Setup__c.getOrgDefaults().CName_Url__c + akamCaseId + '>Case</a>';
        message.setHtmlBody(emailBody);
        return message;
    }
*/
    public static String createEmailForwardHeader(EmailMessage message){
        String header = '<hr><b>From:</b> '+message.FromAddress + '<br>';
        header+='<b>Date:</b> '+message.MessageDate + '<br>';
        header+='<b>To:</b> '+ message.ToAddress + '<br>';
        header+= '<b>Cc:</b> '+ (!String.isBlank(message.CcAddress) ? message.CcAddress : '') + '<br>';
        header+= '<b>Subject:</b> '+(!String.isBlank(message.Subject) ? message.Subject : '') + '<br><br><br>';
        return header;
    }

    @AuraEnabled
    public static List<Map<String, Object>> getCaseNotificationSubsOnACase(Id caseId){
        List<Map<String,Object>> subs = new List<Map<String, Object>>();
        for (SC_CNSOnCase__c sub : [SELECT Id,User__c,User__r.Name,User__r.Email,User__r.SmallPhotoUrl,CreatedDate,CreatedBy.Name FROM SC_CNSOnCase__c WHERE Case__c =:caseId AND User__c!=NULL ORDER BY CreatedDate ASC]){
            subs.add(new Map<String,Object>{
                    'id' => sub.Id,
                    'userId' => sub.User__c,
                    'name' => sub.User__r.Name,
                    'email' => sub.User__r.Email,
                    'avatarUrl' => sub.User__r.SmallPhotoUrl,
                    'createdDate' => sub.CreatedDate,
                    'createdBy' => sub.CreatedBy.Name
            });
        }
        return subs;
    }

}