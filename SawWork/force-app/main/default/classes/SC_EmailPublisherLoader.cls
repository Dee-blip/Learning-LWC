/*
__________________________________________________________________________________________________
* Name             : SC_EmailPublisherLoader
* Created By       : Vandhana Krishnamurthy
* Created Date     : 17 December, 2016
* Purpose          : CR 3596981 : Customise the Standard Email Action on Case Feed
* Test Class       : SC_EmailPublisherLoader_Test

Last Modified Date          Last Modified BY              Purpose
----------------------   --------------------------     -------------

17 December, 2016           Vandhana  Krishnamurthy         3596981     
17 Feb,2017                 Pinkesh                         3647413
24 May 2017                 kusharma                        ESESP-529
21 February, 2018           Vandhana Krishnamurthy          ESESP-852
24 September, 2019          Vishnu Vardhan                  ESESP-2587
March 13, 2020              Sumukh SS                       ESESP-2944 - SOCC Runbook T2P1  
April 4, 2020               Sumukh SS                       ESESP-3259 - SOCC Runbook T2P2
19 May, 2020                Pinkesh                         ESESP-3292 - Adding Reply All feature for Akatec 
27 June, 2020               Sumukh SS                       ESESP-3819
04 Aug, 2020                Pinkesh                         ESESP-3730 - SOCC-Runbooks: Case communications need to be Situation specific
1 Mar 2021                  Vandhana                        ESESP-2346 Carrier LX Migration
25 Jun 2021                 Vikas                          ESESP-4682 Append previous to Address
23 Jul 2021                 Vikas                          ESESP-5681 Remove managedsecurity email address from toAddress
21 Mar 2022                 Harshil                         ESESP-6908 Remove auto-reply/no-reply email address from to Address
__________________________________________________________________________________________________
*/

global class SC_EmailPublisherLoader implements QuickAction.QuickActionDefaultsHandler {
    Boolean isReplyALL; //true if action triggered from Standard Reply All link
    String technicalRTId;
    String managedSecurityRTId;
    String azureCCAddress;
    static final String QU_SECSALES = 'Infosec_SecSales_Queue';
    //Created as part of ESESP-4682
    static string previousCCAddress;
    //static string previousBCCAddress;
    static string previousToAddress;
    static Boolean bounceEmail = false;
        
    List<String> lMSAzureValues = new List<String>{'MS_Azure_CC_Address','MS_Technical_Record_Types','MS_Managed_Security_Record_Types'};
        //Constructor
        global SC_EmailPublisherLoader(){
            isReplyALL = false;

            for(Parter_Configuration_Data__mdt varPartnerConfigData : [SELECT Salesforce_Id__c,DeveloperName 
                                                                       FROM Parter_Configuration_Data__mdt 
                                                                       WHERE DeveloperName IN: lMSAzureValues]){
                                                                           
                                                                           if(varPartnerConfigData.DeveloperName == 'MS_Technical_Record_Types'){
                                                                               technicalRTId = varPartnerConfigData.Salesforce_Id__c;
                                                                           }
                                                                           if(varPartnerConfigData.DeveloperName == 'MS_Managed_Security_Record_Types'){
                                                                               managedSecurityRTId = varPartnerConfigData.Salesforce_Id__c;
                                                                           }
                                                                           if(varPartnerConfigData.DeveloperName == 'MS_Azure_CC_Address'){
                                                                               azureCCAddress = varPartnerConfigData.Salesforce_Id__c;                                               
                                                                           }
                                                                       }
            
        }
    
    // The main interface method
    global void onInitDefaults(QuickAction.QuickActionDefaults[] defaults) 
    {
        QuickAction.SendEmailQuickActionDefaults sendEmailDefaults = null;
        
        // Check if the quick action is the standard Case Feed send email action
        for (Integer j = 0; j < defaults.size(); j++) 
        {
            if (defaults.get(j) instanceof QuickAction.SendEmailQuickActionDefaults && 
                defaults.get(j).getTargetSObject().getSObjectType() == 
                EmailMessage.sObjectType && 
                (defaults.get(j).getActionName().equals('Case.Email') && defaults.get(j).getActionType().equals('Email')) ||
                (defaults.get(j).getActionName().equals('Case.Send_Email_SOCC') && defaults.get(j).getActionType().equals('SendEmail')) ||
                (defaults.get(j).getActionName().equals('Case.SendEmailLightning_SecSales') && defaults.get(j).getActionType().equals('SendEmail')) ||
                (defaults.get(j).getActionName().equals('EmailMessage._ReplyAll')))
            {
                sendEmailDefaults = (QuickAction.SendEmailQuickActionDefaults)defaults.get(j);
                
                if(sendEmailDefaults.getActionName().equals('EmailMessage._ReplyAll'))
                    isReplyALL = true;
                break;
            }
        }
                
        //Added as part of ESESP-4682
        if(sendEmailDefaults != null && sendEmailDefaults.getInReplyToId() != null){
            EmailMessage em = [select id,ToAddress,FromAddress,CcAddress, createddate,Subject from EmailMessage where id=:sendEmailDefaults.getInReplyToId() limit 1];
            if(String.isNotBlank(em.FromAddress) && em.FromAddress.contains('mailer-daemon@') && em.Subject.contains('Undeliverable')){
                bounceEmail = true;
            }
            if(em.ToAddress != null){
                if(String.isNotBlank(em.FromAddress)){
                    previousToAddress = em.ToAddress+';'+em.FromAddress;
                }
                else{
                    previousToAddress = em.ToAddress;
                }
            }
            if(em.CcAddress != null)
              previousCCAddress = em.CcAddress;
            //if(em.BccAddress != null)
              //previousBCCAddress = em.BccAddress;
        }
        //End of ESESP-4682
        
        if (sendEmailDefaults != null) 
        {
            Set<Id> caseRecTypeIdSet = new Set<Id>();
            //List<String> listRecordTypeName = SCRecordTypeCustomSetting__c.getValues('SCAutoSubjectRT').RecordTypeName__c.split(',');
            
            for(String eachCaseRecType : SCRecordTypeCustomSetting__c.getValues('SCAutoSubjectRT').RecordTypeName__c.split(','))
            {
                caseRecTypeIdSet.add(Case.sObjectType.getDescribe().getRecordTypeInfosByName().get(eachCaseRecType).getRecordTypeId());
            }
            
            Case eachCase = [SELECT Status,Case.Account.Name,Case.AccountId,Subject, AKAM_Case_Id__c,Partner_Joint_Troubleshooting_Status__c,
                             RecordTypeId,Owner.Email, Account.Mailing_List_for_Technical_Case_auto_cc__c,Do_Not_Show_in_Portal__c,Sub_Type__c,
                             IsMicrosoftAzureAccount__c,AuthorizedContacts__c,RecordType.Name,Policy_Domain__c,Case.Policy_Domain__r.Name,Case.Case_Product__r.Name,
                             Case.ContactId,Case.Contact.Name,Case.Contact.Email,Case_Situation_Handler__c,Case_Situation_Handler__r.Handler__r.Escalation_List__c
                             FROM Case WHERE Id=:sendEmailDefaults.getContextId() limit 1];
            
            SC_Utility__mdt nominumBCCID = [SELECT Active__c, Value_Text__c
                                            FROM SC_Utility__mdt 
                                            where MasterLabel = 'Nominum Answer Customer BCC'
                                            limit 1
                                           ];
            
            //ESESP-6908: query metadata to store emails to exclude
            List<String> soccExcludeEmails = [SELECT Active__c, Value_Text__c From SC_Utility__mdt where MasterLabel = 'SOCC Email Action: addresses to exclude' limit 1].Value_Text__c.split(',');
            
            EmailMessage emailMessage = (EmailMessage)sendEmailDefaults.getTargetSObject();  
            
            //ESESP-2587 - populate CC with email addresses of secsales queue members
            if(eachCase.RecordType.Name == 'SecSales' && !isReplyALL) {
                List<String> secSalesEamails = getEmailIdsOfQueueMembers(QU_SECSALES);
                if(secSalesEamails.size() > 0) {
                    emailMessage.ccAddress = String.join(secSalesEamails, ',');
                }
            }
            
            if(caseRecTypeIdSet.contains(eachCase.RecordTypeId))
            {   
                String akamCaseNumString = '[AKAM-CASE #' + eachCase.AKAM_Case_Id__c + '] ';
                if(emailMessage.Subject == eachCase.Subject || !emailMessage.Subject.containsIgnoreCase(akamCaseNumString))
                {
                    emailMessage.Subject = String.isNotBlank(emailMessage.Subject) ? akamCaseNumString + emailMessage.Subject : akamCaseNumString + eachCase.Subject;
                }
                emailMessage.Subject = emailMessage.Subject.left(255);
                if(eachCase.RecordTypeId == Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId())
                {
                    String ownerIdString = eachCase.OwnerId;
                    
                    if(ownerIdString.startsWith(Schema.SObjectType.User.getKeyPrefix()))
                    {
                        if(emailMessage.CcAddress == NULL)
                        {
                            emailMessage.CcAddress = eachCase.Owner.Email;
                        }
                        else if(!emailMessage.CcAddress.containsIgnoreCase(eachCase.Owner.Email))
                        { 
                            emailMessage.CcAddress = emailMessage.CcAddress + '; ' + eachCase.Owner.Email;
                        }
                        if(!isReplyALL && eachCase.Account.Mailing_List_for_Technical_Case_auto_cc__c != NULL && emailMessage.CcAddress != NULL && !emailMessage.CcAddress.containsIgnoreCase(eachCase.Account.Mailing_List_for_Technical_Case_auto_cc__c))
                            emailMessage.CcAddress = emailMessage.CcAddress + '; ' + eachCase.Account.Mailing_List_for_Technical_Case_auto_cc__c;
                    }
                }
                
                // changes by Vandhana for ESESP-852 : Nominum Service Cloud Migration
                // changes by Vandhana for ESESP-2346 Carrier LX Migration
                if(eachCase.RecordTypeId == Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId() && eachCase.Sub_Type__c == 'Carrier' && !isReplyALL)
                {
                    if(String.isNotBlank(eachCase.Contact.Email))
                    {
                        if(emailMessage.ToAddress != NULL && !emailMessage.ToAddress.containsIgnoreCase(eachCase.Contact.Email)) 
                            emailMessage.ToAddress = emailMessage.ToAddress + '; ' + eachCase.Contact.Email;
                        else
                            emailMessage.ToAddress = eachCase.Contact.Email;
                    }
                    if(nominumBCCID.Active__c)
                    {
                        if(emailMessage.BccAddress != NULL && !emailMessage.BccAddress.containsIgnoreCase(nominumBCCID.Value_Text__c)) 
                            emailMessage.BccAddress = emailMessage.BccAddress + '; ' + nominumBCCID.Value_Text__c;
                        else
                            emailMessage.BccAddress = nominumBCCID.Value_Text__c;
                    }
                }
                // end of changes by Vandhana for ESESP-852
                
                //Changes for Managed Security SOCC Runbook Changes
                if(eachCase.RecordTypeId == Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Managed Security').getRecordTypeId()  && !isReplyALL)
                {
                    //Added as part of ESESP-4682
                    if(bounceEmail){
                        EmailMessage latestEmail = [select id,ToAddress,ccAddress,FromAddress,ParentId,parent.recordtype.name,createddate,bccAddress from EmailMessage where parentid =: eachCase.id and (not FromAddress like '%mailer-daemon@%') and (not Subject like '%Undeliverable%') order by createddate desc limit 1];
                        if(String.isNotBlank(latestEmail.ToAddress))
                          emailMessage.ToAddress = latestEmail.ToAddress;
                        if(String.isNotBlank(latestEmail.ccAddress))
                          emailMessage.ccAddress = latestEmail.ccAddress;
                        //if(String.isNotBlank(latestEmail.bccAddress))
                            //emailMessage.BccAddress = latestEmail.bccAddress;
                    }
                    else{
                        if(String.isNotBlank(previousToAddress))
                            emailMessage.ToAddress = previousToAddress;
                        if(String.isNotBlank(previousCCAddress))
                            emailMessage.ccAddress = previousCCAddress;
                        //if(String.isNotBlank(previousBCCAddress))
                            //emailMessage.BccAddress = previousBCCAddress;
                    }
                    //End of ESESP-4682
                    if(String.isNotBlank(eachCase.Contact.Email) && eachCase.Do_Not_Show_in_Portal__c == false)
                    {
                        //Appened previous toAddress as part of ESESP-4682
                        if(emailMessage.ToAddress != null)
                          emailMessage.ToAddress+= ';'+eachCase.Contact.Email;
                        else
                            emailMessage.ToAddress = eachCase.Contact.Email;
                    }
                    
                    //Check if Additonal Email is not null and populate
                    if(eachCase.AuthorizedContacts__c!=null && eachCase.Do_Not_Show_in_Portal__c == false)
                    {
                        for(String emailrec:eachCase.AuthorizedContacts__c.replace(';',',').split(','))
                        {
                            if(emailMessage.ToAddress!=null)
                            {
                                emailMessage.ToAddress = emailMessage.ToAddress+';'+emailrec;
                            }
                            else
                            {
                                emailMessage.ToAddress = emailrec;
                            }
                        }
                    }
                    
                    /***Sumukh Changes for Email Body ***/
                    //ESESP-2860
                    if(emailMessage.htmlBody!=null)
                    {
                        emailMessage.htmlBody = '<b>Account Name : </b>'+eachcase.Account.Name + '<br/>'+ '<b>Policy Domain : </b>'+ eachCase.Policy_Domain__r.Name+'<br/>'+emailMessage.htmlBody;
                    }
                    
                    else
                    {
                        emailMessage.htmlBody = '<b>Account Name : </b>'+eachcase.Account.Name + '<br/>'+ '<b>Policy Domain : </b>'+ eachCase.Policy_Domain__r.Name;
                    }
                    
                    
                    //SOCC RUN BOOK changes - Get Authorized Contacts with Communication Preferences = All Case Communication
                    If(eachCase.Policy_Domain__c!=null && eachCase.Case_Situation_Handler__c!=null && eachCase.Do_Not_Show_in_Portal__c == false)
                    {   
                        //List to store Ids of contact to be pre populated
                        List<Id> notifyccids = new List<Id>();
                        String notifyCCAddress = '';
                        if(eachCase.Case_Situation_Handler__r.Handler__r.Escalation_List__c!=null){
                            for(SC_SOCC_Escalation_via_Case_Email__c eachrec: [SELECT Id, Name, Authorized_Contact__c, Authorized_Contact__r.Contact_Name__c,  Authorized_Contact__r.Contact_Name__r.Email, Authorized_Contact__r.Contact_Name__r.SMS_Notifications__c
                                                              FROM SC_SOCC_Escalation_via_Case_Email__c WHERE Escalation_List__c =:eachCase.Case_Situation_Handler__r.Handler__r.Escalation_List__c ORDER BY Name])
                            {
                                notifyccids.add(eachrec.Authorized_Contact__r.Contact_Name__c);
                                notifyCCAddress+=eachrec.Authorized_Contact__r.Contact_Name__r.Email+';';
                            }
                        }
                        
                        if(String.isNotBlank(notifyCCAddress)){
                            if(emailMessage.ccAddress != null)
                                emailMessage.ccAddress+= ';'+notifyCCAddress;
                            else
                                emailMessage.ccAddress = notifyCCAddress;
                        }
                        /*if(notifyccids.size()>0)
                        {
                            emailMessage.CCIds = notifyccids;
                        }*/
                    }
                    
                    //ESESP-5681
                    if(emailMessage.ToAddress != null){
                        List<String> toAddressList = new List<String>();
                        Set<String> toAddressSet = new Set<String>();
                        String finalToAddress = '';
                        toAddressList = emailMessage.ToAddress.split(';');
                        toAddressSet.addAll(toAddressList);
                        for(String toAdd : toAddressSet){
                            //ESESP-6908: changed condition to check email exclusion
                            if(!soccExcludeEmails.contains(toAdd))
                                finalToAddress+=toAdd+';';
                        }
                        emailMessage.ToAddress = finalToAddress;
                    }
                    
                    //End of ESESP-5681
                }
                // end of changes for Managed Security SOCC 
                /***End of Sumukh Changes for Email Body ***/
               
            }
            setMSAzureEmailDefaults(eachCase,emailMessage);
        }
    }
    
    private void setMSAzureEmailDefaults(Case caseToPopulate, EmailMessage emailMessage){
        if((caseToPopulate.RecordTypeId == managedSecurityRTId
            || caseToPopulate.RecordTypeId == technicalRTId )
           && caseToPopulate.IsMicrosoftAzureAccount__c){
               
               if(emailMessage.CcAddress != null){
                   for(String ccAddressToAppend : azureCCAddress.split(';')){
                       if(!emailMessage.CcAddress.containsIgnoreCase(ccAddressToAppend)){
                           emailMessage.CcAddress = emailMessage.CcAddress + '; ' + ccAddressToAppend;
                       }
                   }
               }
           }
    }
    
    /* 
__________________________________________________________________________________________________
* Method Name      : getEmailIdsOfQueueMembers
* Created By       : Vishnu Vardhan
* Created Date     : 23 September, 2017
* Purpose          : ESESP-2587 : For a given queue, return email list of all queue memebers (Users)
__________________________________________________________________________________________________
*/
    public List<String> getEmailIdsOfQueueMembers(String queueName) {
        set<String> memberEmails = new set<String>();
        set<Id> userIds = new Set<Id>();
        
        for(GroupMember qMem: [SELECT UserOrGroupId, Id, GroupId, Group.type, Group.Name 
                               FROM GroupMember  
                               WHERE Group.type = 'Queue' AND Group.Name = :queueName]) {
                                   String userOrGroupId = qMem.UserOrGroupId;
                                   if(userOrGroupId.startsWith('005')) {
                                       userIds.add(qMem.UserOrGroupId);
                                   }
                               }
        
        if(userIds.size() == 0) {
            return new List<String>();
        }
        
        for(User usr: [select id, email from user where id in :userIds]) {
            memberEmails.add(usr.email);
        }
        
        return new List<String>(memberEmails);
    }
}