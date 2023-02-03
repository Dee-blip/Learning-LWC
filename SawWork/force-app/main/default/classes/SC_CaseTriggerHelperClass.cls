/**************************************************************************************
 Jay                    15-july-2015        Transition Requirements: CR 3018620 
Test Class = SC_Case_Trgr_EmlServc_Class_TC, Method = SC_TriggerHelperTest
---------------------------------------------------------------------------------------
History
Developer           Date                Change
---------------------------------------------------------------------------------------
Vikas             21-Dec-2017       JIRA ESESP-822      Case Notifications for Authorized Contacts  
Vikas             29-Jan-2018       JIRA ESESP-953      Changed the email template for case notification
Vandhana          1-Aug-2018        JIRA ESESP-1577     Authorized contacts removed from new case/close case notifications
Sumukh SS         07-April-2020     JIRA ESESP-3259     SOCC Runbooks changes for initial case notification
Vamsee S          12-May-2020       JIRA ESESP-1342     Moved updateCaseEntitlement method from CasetriggerClass
Vamsee S          13-May-2020       JIRA ESESP-1342     BOCC to Technical Lightning Migration
Vamsee S          12-May-2021       JIRA ESESP-5341     Moved updateCaseEntitlement_PartB method from CasetriggerClass
Sheena			  24-Feb-2022		JIRA ESESP-5143		Customer Surveys on internal AMG Cases
Tejaswini         01-Dec-2021       JIRA ESESP-6008     SOCC AIM Program - LA Rollout
*/ 

public class SC_CaseTriggerHelperClass  {
    public static boolean flagvalue = false;
    public static boolean flags = false;
    public static boolean authContactRecCheck = false;
    public static boolean authContactCloserMailCheck = false;
    public static boolean authContactInitialCommunication = false;
    public static boolean verivueRecCheck = true;
    public static boolean sentEmailFlag = false;
    public static boolean surveyEnableCheck = false;
    //Commented by Sonia on 10 March 2016 and replacing with static list of processed Id's
    //public static boolean caseTransitionUpdate = false;
    public static set<Id> lstProcessedTransitionIds = new set<Id>();
    
    
    //Changed by Vikas for ESESP-822: Changed the signature of method by adding two more parameters 
    @future
    public static void sendEmailToAuthorisedContacts(list<string> lCaseIdsToSendEmail, boolean isCaseCloser, Map<Id,Id> lCasePolicyDomainIdMap, Map<Id,String> caseProductMap, Map<Id,Boolean> additionalEmailMap, Map<Id,Boolean> authConEmailMap){
        list<String> lEmailIds = new list<String>();
        Set<String> emailIdSet = new Set<String>();
        Set<String> authContEmailIdSet = new Set<String>();
        Set<String> additionalEmailIdSet = new Set<String>();
        List<Id> policyDomainUpdatedSet = new List<Id>();
        list<Id> caseIdList = new list<Id>();
        caseIdList.addAll((list<Id>)lCaseIdsToSendEmail);
        caseIdList.addAll(lCasePolicyDomainIdMap.keySet());
        caseIdList.addAll(caseProductMap.keySet());
        policyDomainUpdatedSet.addAll(lCasePolicyDomainIdMap.keySet());
        policyDomainUpdatedSet.addAll(caseProductMap.keySet());
        
        // changes for ESESP-1577
        SC_Utility__mdt scMDT = [SELECT Active__c,MasterLabel,DeveloperName
                                 FROM SC_Utility__mdt
                                 where DeveloperName = 'Disable_AuthCon_Mailer_for_SOCC' limit 1
                                ];
        
        list<Case> lCasesToSendEmail = [SELECT Subject,AKAM_Case_ID__c,Description,Id,Policy_Domain__c,
                                        AuthorizedContacts__c,Contact.Email,Contact.Name,Case_Prod_Name__c 
                                        FROM Case WHERE Id IN :caseIdList];
        list<Messaging.SingleEmailMessage> lEmails = new list<Messaging.SingleEmailMessage>();
        
        //ESESP-822: Map to store CaseId and Authorized contacts for that case.
        Map<Id,List<Authorized_Contact__c>> caseAuthConMap = new map<Id,List<Authorized_Contact__c>>();
        
        //Creating the maps: To filter the AE(Additional Emails) and AC(Authorized Contacts) when only AE is updated
        for(Case thisCase :lCasesToSendEmail)
        {
            if(thisCase.Policy_Domain__c != null)
            {
                lCasePolicyDomainIdMap.put(thisCase.Id, thisCase.Policy_Domain__c);
                caseProductMap.put(thisCase.Id, thisCase.Case_Prod_Name__c);
            }
        }
        //ESESP-822: Fetching the Authorized contacts for the case and creating a map of caseid and related authorized contacts
        if(lCasePolicyDomainIdMap!=null && caseProductMap!= null && lCasePolicyDomainIdMap.keySet().size() > 0 && caseProductMap.keySet().size()>0)
        {
            if(!scMDT.Active__c) 
            {
                caseAuthConMap = SC_AuthContOnCaseCtrlr.findValidAuthConFun(lCasePolicyDomainIdMap,caseProductMap);
            }
        }
        for(Case varCase :lCasesToSendEmail){   
            if(! String.isBlank(varCase.AuthorizedContacts__c))
            {    
                for(string varEmailId :varCase.AuthorizedContacts__c.replace(';',',').split(','))
                {
                    if(varCase.Contact == NULL || varEmailId != varCase.Contact.Email)
                    {
                        additionalEmailIdSet.add(varEmailId);
                    }
                }
            }
            if(caseAuthConMap!=null && caseAuthConMap.keyset().size() > 0)
            {
                for(Id caseId : caseAuthConMap.keySet())
                {   if(caseAuthConMap.keySet().contains(varCase.Id) && caseid == varCase.Id)
                    {   for(Authorized_Contact__c authConEmailId: caseAuthConMap.get(caseId))
                        {   if((varCase.Contact == NULL || authConEmailId.Contact_Name__r.Email != varCase.Contact.Email) && !String.isBlank(authConEmailId.Contact_Name__r.Email))
                            {authContEmailIdSet.add(authConEmailId.Contact_Name__r.Email);}
                        }
                    }
                }
            }              
            if(additionalEmailIdSet.size() > 0)
                emailIdSet.addAll(additionalEmailIdSet);
            if(authContEmailIdSet.size() > 0)
                emailIdSet.addAll(authContEmailIdSet);
            
            if(emailIdSet.size() > 0)
            {
                if(authConEmailMap != null && additionalEmailMap != null)
                {
                    if(authConEmailMap.get(varCase.id) != null && authConEmailMap.get(varCase.id) && additionalEmailMap.get(varCase.id) == null)
                        emailIdSet.removeAll(additionalEmailIdSet);
                    else if(additionalEmailMap.get(varCase.id) != null && additionalEmailMap.get(varCase.id) && authConEmailMap.get(varCase.id) == null)
                        emailIdSet.removeAll(authContEmailIdSet);
                }
            }
            
            if(emailIdSet.size() > 0)
                lEmailIds.addAll(emailIdSet);
            
            //ESESP-939 : To limit the "to address" to 100
            if(lEmailIds.size()>100)
            {
                for(Integer index=100; lEmailIds.size()>100; )
                {lEmailIds.remove(index);}
            }
            Messaging.SingleEmailmessage email = new Messaging.SingleEmailMessage();
            if(!isCaseCloser)
            {
                email.setHtmlBody(createEmailBody(varCase));
                email.setSubject(createEmailSubject(varCase));
            }
            else{
                email.setHtmlBody(createEmailBodyForCaseCloser(varCase));
                email.setSubject(createEmailSubjectForCaseCloser(varCase));
            }
            email.setSaveAsActivity(false);
            email.setOrgWideEmailAddressId(SC_FromEmailAddress__c.getValues('TechnialCaseNotification').OrgAddressId__c);
            if(lEmailIds.size() > 0)
            {
                email.setToAddresses(lEmailIds);
                lEmails.add(email); 
            }
        }
        if(lEmails.size()>0)
            Messaging.sendEmail(lEmails);
    }
    
    /*
    @future
    public static void sendEmailOnVerivueUpdate(list<string> lCaseIdsToSendEmail)
    {
        list<String> lEmailIds = new list<String>();
        list<Case> lCasesToSendEmail = [SELECT Subject,AKAM_Case_ID__c,Description,Id,NextStepsExternal__c,
                                        AuthorizedContacts__c,Contact.Email,Contact.Name,ContactId 
                                        FROM CAse WHERE Id IN :lCaseIdsToSendEmail];
        list<Messaging.SingleEmailMessage> lEmails = new list<Messaging.SingleEmailMessage>();
        for(Case varCase :lCasesToSendEmail){
            Messaging.SingleEmailmessage email = new Messaging.SingleEmailMessage();
            email.setHtmlBody(createEmailBodyForVerivue(varCase));
            email.setSubject(createEmailSubjectForVerivue(varCase));
            email.setSaveAsActivity(false);
            email.setOrgWideEmailAddressId(SC_FromEmailAddress__c.getValues('TechnialCaseNotification').OrgAddressId__c);
            email.setTargetObjectId(varCase.ContactId);
            lEmails.add(email);              
        }
        Messaging.sendEmail(lEmails);
    }
    */

    //ESESP-2746 Code to Send Initial Case Communication for SOCC
    @future
    public static void initialNotifyMSCases(list<String> eligibleCaseIdsInitialNotifyMS,boolean is_case_insert)
    {
        //Query All Relevant Cases
        List<Case> eligibleCaseforProcessing = [Select Id,accountid,Subject,AKAM_Case_ID__c,Contact.Email,Case_Prod_Name__c,Description,Policy_Domain__c from Case where id in:eligibleCaseIdsInitialNotifyMS];
        //List to store email ids
        list<Messaging.SingleEmailMessage> lEmails = new list<Messaging.SingleEmailMessage>();
        
        set<id> uniqueAccountID = new set<id>();            
        for(Case varCase:eligibleCaseforProcessing)
        {   
            if(varCase.AccountId!=null)
            {uniqueAccountID.add(varCase.AccountId);}
        }
        
        map<string,list<string>> AccountID_emailmap = new map<string,list<string>>();
        
        if(is_case_insert)
        {
            //Query all account team members who are an SSP or a CSM and add to a map
            list<string> lstaccmemberemails=new list<string>();
            
            for (AccountTeamMember eachrec :[select User.Email,AccountId from AccountTeamMember where  User.isActive = true and AccountId IN :uniqueAccountID
                                             and (TeamMemberRole ='Security Services - Primary' OR user.title like 'Client Service Manager%')])
            {
                if(AccountID_emailmap.containsKey(eachrec.Accountid))
                {lstaccmemberemails=AccountID_emailmap.get(eachrec.Accountid);}
                else
                {lstaccmemberemails= new list<string>();}
                lstaccmemberemails.add(eachrec.User.Email);
                AccountID_emailmap.put(eachrec.Accountid,lstaccmemberemails);
                
            }
        }
        
        
        //Loop through and construct email list for each Case
        for(Case varCase:eligibleCaseforProcessing)
        {
            List<String> toaddressset = new List<String>();
            //Add to the email send list if account team member exists and it is a trigger insert
            if(is_case_insert)
            {
                if(AccountID_emailmap.get(varCase.AccountId)!=null)
                    toaddressset.addall(AccountID_emailmap.get(varCase.AccountId));
            }
            
            if(toaddressset.size()>0)
            {
                Messaging.SingleEmailMessage varEmail = new Messaging.SingleEmailMessage();
                varEmail.setHtmlBody(createEmailBody(varCase));
                varEmail.setSubject(createEmailSubject(varCase));
                varEmail.setToAddresses(toaddressset);
                varEmail.setOrgWideEmailAddressId(SC_FromEmailAddress__c.getValues('TechnialCaseNotification').OrgAddressId__c);
                lEmails.add(varEmail);
            }
        }
        
        //Check size & Send Email
        if(lEmails.size()>0)
        {Messaging.sendEmail(lEmails);}
        
    }
    
    //ESESP-2746 End of Code changes to Send Initial Case Communication for SOCC
    
    //ESESP-953 : Changed the email template
    public static string createEmailBody(Case varCase){
        string emailBody = '';
        emailBody += 'Dear Customer' + ',<br /><br />';
        emailBody += 'Akamai has created a support case for your managed security account. A SOCC representative is reviewing the case and will contact you shortly. Your Case ID is '+varCase.AKAM_Case_ID__c+'. To inquire about this case via email, please send an email to managedsecurity@akamai.com and include [AKAM-CASE #'+varCase.AKAM_Case_ID__c+'] in the subject line.<br /><br />';
        emailBody += 'You may also track the progress of this case online in Control Center by following this link: <br />';
        emailBody += 'https://control.akamai.com/resolve/caseview/caseDetails.jsp?caseId='+varCase.AKAM_Case_ID__c+' <br /><br />';
        emailBody += 'Thank you, <br /> Akamai Support';
        return emailBody;
    }

    /*
    public static string createEmailBodyForVerivue(Case varCase){
        string emailBody = '';
        emailBody += 'Next Steps (External): <br/>';
        emailBody += varCase.NextStepsExternal__c + '<br/> <br/>';
        emailBody += 'You may track the progress of this case online in Control Center by following this link: https://control.akamai.com/resolve/caseview/caseDetails.jsp?caseId=' + varCase.AKAM_Case_ID__c + '<br /><br />';
        return emailBody;
    }
    */

    public static string createEmailSubject(Case varCase){
        string subject = '';
        subject = 'Akamai Support Case Received [AKAM-CASE #' + varCase.AKAM_Case_ID__c + '] - ' + varCase.Subject;
        return subject;
    }
    
    /*
    public static string createEmailSubjectForVerivue(Case varCase){
        string subject = '';
        subject += '[AKAM-CASE #' + varCase.AKAM_Case_ID__c + '] ';
        subject += 'Your case has been updated';
        return subject;
    }   
    */
    
    public static string createEmailSubjectForCaseCloser(Case varCase){
        string subject = '';
        subject = 'Akamai Support Case Closed [AKAM-CASE #' + varCase.AKAM_Case_ID__c + '] - ' + varCase.Subject;
        return subject;
    } 
    
    public static string createEmailBodyForCaseCloser(Case varCase){
        string emailBody = '';
        emailBody += 'Dear Customer' + ',<br /><br />';
        emailBody += 'According to our records, your support request as described below has been resolved:  <br/> <br/>';
        emailBody += 'Case Description : <br />';
        emailBody +=  varCase.Description + '<br/> <br/>';
        emailBody += 'Akamai values the opportunity to provide you with security services. <br /><br />';
        emailBody += 'If you have additional service-related questions or concerns specifically related to this ticket, please respond to this message. If not, please do not respond directly to this email unless you wish to re-open this issue. <br /><br />';
        emailBody += 'Thank you, <br /> Akamai Support';
        return emailBody;
    }

    /*   Function to add/update Entitlement Name on case based on Account.SupportLevel and Custom setting values.
      *   Moved this method from CAseTriggerClass on 24th Apr 2020 (Vamsee - ESESP-1342)
      */
    public static void updateCaseEntitlement(List<Case> lstCase, Map<Id, string> rTypes) 
    {
        Map<String, Web_Entitlements__c> webEntitlements = Web_Entitlements__c.getAll();
        Map<String,EntitlementID__c> entitlementIds = EntitlementID__c.getAll();
        Set<String> entitlementNames = new Set<String>();
        
        for(Web_Entitlements__c we : webEntitlements.values()){
            entitlementNames.add(we.Entitlement_Name__c);
        }
        
        Set<Id> accIds = new Set<Id>();
        Map<Id, Account> accMap;
        
        for(Case c : lstCase){
            accIds.add(c.AccountId);
            
        }
        
        if(accIds.size() > 0){
            accMap = new Map<Id, Account>([Select Id, Support_Level__c, 
                                           (Select Id, Name, AccountId from Entitlements 
                                            Where Name IN : entitlementNames AND Status = 'Active') from Account where Id IN : accIds]); 
        }
        
        Map<String, Entitlement> entitlementMap;
        if(entitlementNames.size() > 0 && accMap.size() > 0)
        {
            entitlementMap = new Map<String, Entitlement>();
            for(Account acc : accMap.values()){
                if(acc.Entitlements != null && acc.Entitlements.size()>0){
                    for(Entitlement e : acc.Entitlements)
                    {entitlementMap.put(e.Name+e.AccountId, e); }
                }
            }
        }
        
        String key;
        Web_Entitlements__c we;
        Id CommunityResponseRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Community Response').getRecordTypeId();
        
        for(Case c : lstCase)
        {    
            if(accMap.containsKey(c.accountId) && accMap.get(c.accountId).Support_Level__c != null && c.RecordTypeId != CommunityResponseRTId) 
            {
                //Adding condition to seperate case with Legacy Type Null
                if(c.Legacy_Type__c == Null || c.Legacy_Type__c == '' || c.Legacy_Type__c=='SOASTA')
                {
                    key = rTypes.get(c.RecordTypeId).substring(0,3) + accMap.get(c.accountId).Support_Level__c;
                    if(webEntitlements.containsKey(key))
                    { we = webEntitlements.get(key);
                        if(entitlementMap.containsKey(we.Entitlement_Name__c+c.AccountId))
                        {c.EntitlementId = entitlementMap.get(we.Entitlement_Name__c+c.AccountId).Id;}
                    }
                }
                //Applying standard Entitlement when Legacy Type is populated
                else
                {    
                    if(c.Legacy_Type__c!='SOASTA')
                    {
                        key = rTypes.get(c.RecordTypeId).substring(0,3) + 'Standard';
                        if(entitlementIds.containsKey(key))
                        {c.EntitlementId = entitlementIds.get(key).EntitlementID__c;}
                    } 
                }
            }
            else if(c.RecordTypeId == CommunityResponseRTId)
            {
                c.EntitlementId = entitlementIds.get('Community Response').EntitlementID__c;
            }
            
            //Added By Vamsee (ESESP-1342) : BOCC Technical Migration
            if(rTypes.get(c.RecordTypeId) != null && (rTypes.get(c.RecordTypeId).equals('Technical')) && c.Sub_Type__c == 'BOCC' && c.AccountId != null)
            {    
                if(entitlementMap.get('Technical (BOCC)' + c.AccountId) != null)
                {    
                    c.EntitlementId = entitlementMap.get('Technical (BOCC)'+c.AccountId).Id;
                }
            }
        }


    }
    
    //Moved this method from CaseTriggerClass on 17th May 2021 (Vamsee - ESESP-5341)
    //This method will update the entitlement Process Id on Case
    public static void updateCaseEntitlement_PartB(boolean isInsert, list<Case> newList, map<ID,Case> oldmap,Map<Id, string> rTypes)
    {
        // get the Entitlement ID from the custome setting
        string entitlementIdForStabEngg = null;
        string entitlementIdForEmergingProd = null;
        map<string,string> mEntitleNameAndId = new map<string,string>();
        Map<String,Case> newMap = new Map<String,Case>();
        List<string> lSupportLevelValues = new List<string>();
        Set<String> technicalExtSupportLevelValues = new Set<String>();
        for(EntitlementID__c varEntitlementId: EntitlementID__c.getAll().values()){
            //[Select EntitlementID__c, Case_Record_Type__c From EntitlementID__c where Case_Record_Type__c ='Stability Engineering' limit 1]){
            entitlementIdForStabEngg = varEntitlementId.EntitlementID__c;
            mEntitleNameAndId.put(varEntitlementId.Case_Record_Type__c, varEntitlementId.EntitlementID__c);
            if(varEntitlementId.Name.equals('Exceda')){
                lSupportLevelValues = varEntitlementId.Support_Level__c.split(',');    
            }else if(varEntitlementId.Name == 'Technical_Ext'){
                technicalExtSupportLevelValues = new Set<String>(varEntitlementId.Support_Level__c.split(';'));
            }
        }
        Set<String> sSupportLevelValues = new Set<String>(lSupportLevelValues);
        // get case recordtype
        if(mEntitleNameAndId != null && mEntitleNameAndId.keySet().size()>0){
            for(Case cs:newList){
                newMap.put(cs.Id,cs);
                if(rTypes.get(cs.RecordTypeId).equals('Stability Engineering')){

                    if(isInsert){
                        cs.EntitlementId = mEntitleNameAndId.get('Stability Engineering');
                    }
                    else if(!rTypes.get(oldmap.get(cs.ID).RecordTypeId).equals('Stability Engineering')){
                        cs.EntitlementId = mEntitleNameAndId.get('Stability Engineering');
                    }
                }

                else if(rTypes.get(cs.RecordTypeId).equals('Emerging Products Engineering')){

                    if(isInsert){
                        cs.EntitlementId = mEntitleNameAndId.get('Emerging Products Engineering');
                    }
                    else if(!rTypes.get(oldmap.get(cs.ID).RecordTypeId).equals('Emerging Products Engineering')){
                        cs.EntitlementId = mEntitleNameAndId.get('Emerging Products Engineering');
                    }
                }

                else if(rTypes.get(cs.RecordTypeId).equals('AMG'))
                {
                    if(isInsert){
                        cs.EntitlementId = mEntitleNameAndId.get('AMG');
                    }
                    else if(!rTypes.get(oldmap.get(cs.ID).RecordTypeId).equals('AMG')){
                        cs.EntitlementId = mEntitleNameAndId.get('AMG');
                    }
                } 
                
                // changes by Vandhana for Carrier LX Migration
                else if(rTypes.get(cs.RecordTypeId).equals('Technical') && cs.Sub_Type__c == 'Carrier' )
                {
                    cs.EntitlementId = mEntitleNameAndId.get('Carrier Products');
                }
                else if(rTypes.get(cs.RecordTypeId).equals('Technical') && (cs.Sub_Type__c == 'Security Event' || cs.Sub_Type__c == 'SSL Support'))
                {
                    if(isInsert){
                        cs.EntitlementId = mEntitleNameAndId.get('Technical');
                    }
                    else if(cs.Sub_Type__c == 'SSL Support' && cs.EntitlementId != mEntitleNameAndId.get('Technical')){
                        cs.EntitlementId = mEntitleNameAndId.get('Technical');
                    }
                    else if(!rTypes.get(oldmap.get(cs.ID).RecordTypeId).equals('Technical')){
                        cs.EntitlementId = mEntitleNameAndId.get('Technical');
                    }
                }
                //Setting ENtitlement Id for Customer onboarding Cases of AMG record type
                else if((isInsert || (cs.EntitlementId != mEntitleNameAndId.get('Technical'))) 
                        && 
                        rTypes.get(cs.RecordTypeId).equals('AMG') && (cs.Service__c == 'Accounts Audits' && cs.Request_Type__c == 'Customer Onboarding' && 
                                                                      cs.Work_Type__c == 'Proactive' && cs.Severity__c == '3' && cs.Do_Not_Show_in_Portal__c))
                {
                    cs.EntitlementId = mEntitleNameAndId.get('Technical');
                }   
                
                // ESESP-2362 CMG Team Case Management System from E-mails
                else if(rTypes.get(cs.RecordTypeId).equals('CMG'))
                {
                    if(isInsert){
                        cs.EntitlementId = mEntitleNameAndId.get('CMG');
                    }
                    else if(!rTypes.get(oldmap.get(cs.ID).RecordTypeId).equals('CMG')){
                        cs.EntitlementId = mEntitleNameAndId.get('CMG');
                    }
                }
                // Changes by Harshil:
                // ESESP - 2917 Exceda support level Entitlement assignment
                else if(rTypes.get(cs.RecordTypeId).equals('Technical') && sSupportLevelValues.contains(cs.Support_Level__c))
                {
                    System.debug('In technical');                    
                    
                    //Added Record Type change check - ESESP-5341
                    if(isInsert || oldmap.get(cs.ID).Support_Level__c != newMap.get(cs.Id).Support_Level__c || oldmap.get(cs.ID).RecordTypeId != newMap.get(cs.Id).RecordTypeId)
                    {
                        cs.EntitlementId = mEntitleNameAndId.get('TechnicalAll');
                    }
                }else if(rTypes.get(cs.RecordTypeId) == 'Technical' && technicalExtSupportLevelValues.contains(cs.Support_Level__c)){
                    if(isInsert || oldmap.get(cs.Id).Support_Level__c != cs.Support_Level__c || oldmap.get(cs.Id).RecordTypeId != cs.RecordTypeId) {
                        cs.EntitlementId = mEntitleNameAndId.get('TechnicalAll_Ext');
                    }
                }

                // Changes by Sharath for ESESP-3659 Billing Case migration: Check for the Billing record type
                else if(rTypes.get(cs.RecordTypeId).equals('Billing') && 
                        (isInsert || !rTypes.get(oldmap.get(cs.ID).RecordTypeId).equals('Billing')))
                {
                     cs.EntitlementId = mEntitleNameAndId.get('Billing');
                }
                System.debug(cs.EntitlementId);
            }
        }
    }
    
    /* ESESP-1342 : BOCC Migration to Technical
     * Mark Mitigation and Root Cause Analysis milestones complete
     * Called from Casetrigger_ai trigger */

    public static void technicalBOCCnCarrierMilestonesUpdate(List<Id> caseIDForCompleteCaseMilestone, String milestoneType)
    {
            list<CaseMilestone> caseMilestoneList = new list<CaseMilestone>();
            for(CaseMilestone eachMilestone: [  SELECT MilestoneType.Name, Id, CompletionDate FROM CaseMilestone  
                                                WHERE CaseId in:caseIDForCompleteCaseMilestone AND 
                                                IsCompleted = False AND MilestoneType.Name = :milestoneType AND
                                                Case.IsClosed = False])
            {
                eachMilestone.CompletionDate = DateTime.now();
                caseMilestoneList.add(eachMilestone);
            }
            if(caseMilestoneList.size() > 0)
            {
                update caseMilestoneList;
            }
    }
    
    /* ESESP-1342 : Method to send surveys on internal AMG Cases
	   Called from Casetrigger_ai trigger */
    public static void checkSurveyEnabledAMGCase(List<Case> caseList, Map<Id,Case> oldMap, Boolean isInsert)
    {
        List<Case> eligibleCaseList = new List<Case>();
        Map<String,String> caseIdOwnerEmailMap = new Map<String,String>();
        List<Case> caseListToDisableSurvey = new List<Case>();
        Set<Id> caseIdsNotEligible = new Set<Id>();
        List<CS_Survey_Contact__c> surveyContactsToDelete = new  List<CS_Survey_Contact__c>();
        List<Case> caseListToUpdate = new List<Case>();
        Map<Id,EmailMessage> caseIdEmailMsgMap = new Map<Id,EmailMessage>();
        List<EmailMessage> emailMessageList = new List<EmailMessage>();
        Map<String,Contact> emailContactMap = new Map<String,Contact>();
        Set<String> emailIds = new Set<String>();
        CS_Survey_Contact__c  surveyContact;
        List<CS_Survey_Contact__c> surveyContactsList = new List<CS_Survey_Contact__c>();
        EmailMessage em;
        Boolean isCustomerEmail = false;
        Set<String> toAddresses;// = new Set<String>();
        List<String> invalidSupportLevels = new List<String>{'None-Collections','Network Support','None','None-ContractExpired','None-NoContractLine','Indirect_Customer'};
        List<String> validAccountStatuses = new List<String>{'Direct Customer - Active','Multiple w ISP - Active','Multiple wo ISP - Active','Tier 1 Reseller - Active','Value Added Reseller - Active','VAR Customer - Active'};
        List<String> invalidOrigins = new List<String>{'AkaChat Community','AkaChat Luna','Alert','amg@akamai.com'};   
                
        List<Case> caseListNew = [Select id,AccountId,Do_Not_Show_In_Portal_Picklist__c,Qualtrics_Survey_Notification_Sent__c,
                                          Status,OwnerId,Service__c,Request_Type__c,Case_Owner_Email_address__c,AuthorizedContacts__c,
                                          MilestoneStatus,Internal_Case_Survey_Enabled__c,Support_Level__c,Account.Account_Status__c,Subject,Origin
                                          from Case where id =: caseList];
        
        for(Case cs: caseListNew){
            // Check if the conditions are satisfied
            if((isInsert || (!isInsert && (cs.Service__c != oldMap.get(cs.Id).Service__c || cs.Request_Type__c != oldMap.get(cs.Id).Request_Type__c
                                           || cs.Do_Not_Show_In_Portal_Picklist__c != oldMap.get(cs.Id).Do_Not_Show_In_Portal_Picklist__c
                                           || (cs.Status != oldMap.get(cs.Id).Status && (cs.Status=='Closed' || cs.Status=='Reopened'))
                                           || cs.OwnerId != oldMap.get(cs.Id).OwnerId || cs.Support_Level__c != oldMap.get(cs.Id).Support_Level__c
                                           || cs.Subject != oldMap.get(cs.Id).Subject || cs.AccountId != oldMap.get(cs.Id).AccountId || cs.Origin != oldMap.get(cs.Id).Origin)))){
                                               if(cs.Do_Not_Show_In_Portal_Picklist__c == 'Internal Only' && !cs.Qualtrics_Survey_Notification_Sent__c && String.valueOf(cs.OwnerId).startsWith(Schema.SObjectType.User.getKeyPrefix())
                                                  && !invalidSupportLevels.contains(cs.Support_Level__c) && validAccountStatuses.contains(cs.Account.Account_Status__c)
                                                  && (cs.Subject == null || !cs.Subject.startsWithIgnoreCase('Auto-provisioned CP Code')) && !invalidOrigins.contains(cs.Origin)
                                                  && !(
                                                      (cs.Service__c == 'Customer Initiatives (with PCU Impact)' && cs.Request_Type__c.contains('Customer Initiative')) 
                                                      || (cs.Service__c=='Accounts Audits' && (cs.Request_Type__c=='Customer OffBoarding' || cs.Request_Type__c=='Order Form Review'))
                                                      || (cs.Service__c=='Billing Related' && (cs.Request_Type__c=='Manual Invoice Review' || cs.Request_Type__c=='Revenue Forecast & Verification'
                                                                                               || cs.Request_Type__c=='Revenue Recognition' || cs.Request_Type__c=='Past Due Invoice'))
                                                      || (cs.Service__c=='Contract Management' && (cs.Request_Type__c=='Service Migration' || cs.Request_Type__c=='Contract Migration'
                                                                                                   || cs.Request_Type__c=='Renewal Management' || cs.Request_Type__c=='Opportunity Management'))
                                                      
                                                      || (cs.Service__c=='General Account Management' && (cs.Request_Type__c=='Unbilled Traffic' || cs.Request_Type__c=='DDC Reporting'
                                                                                                          || cs.Request_Type__c=='Akatec Request Management' || cs.Request_Type__c=='Customer Meeting & Notes' 
                                                                                                          || cs.Request_Type__c=='Wiki Page Update' || cs.Request_Type__c=='Translation'|| cs.Request_Type__c=='BAM Reconciliation' 
                                                                                                          || cs.Request_Type__c=='Account Transition' || cs.Request_Type__c=='PS Request Management' || cs.Request_Type__c=='IAT Meeting & Notes'))
                                                      
                                                      || cs.Service__c=='Credits'
                                                      || cs.Service__c=='Internal Initiatives (w/o PCU impact)'
                                                      || cs.Service__c=='Marketplace'
                                                      || cs.Service__c=='Outreach'
                                                      || cs.Service__c=='Survey Operations'
                                                      || cs.Request_Type__c=='New CP Code')
                                                 )
                                               {
                                                   eligibleCaseList.add(cs);
                                                   caseIdOwnerEmailMap.put(cs.Id, cs.Case_Owner_Email_address__c);
                                                   
                                               }
                                               
                                               else{
                                                   if(cs.Internal_Case_Survey_Enabled__c && !cs.Qualtrics_Survey_Notification_Sent__c){
                                                       cs.Internal_Case_Survey_Enabled__c  = false;
                                                       caseListToDisableSurvey.add(cs);
                                                   }
                                                   
                                               }
                                           }
            // If Case is reopened before the survey is sent to customers, the Survey Contacts created should be deleted
            if(cs.Status=='Reopened' && cs.Status != oldMap.get(cs.Id).Status && !cs.Qualtrics_Survey_Notification_Sent__c ){
                caseIdsNotEligible.add(cs.Id);   
            }
        }
        
        if(!caseIdsNotEligible.isEmpty()){
            surveyContactsToDelete = [Select Id, Name from CS_Survey_Contact__c where CS_Case__c =: caseIdsNotEligible];
        }

        
        try{
            if(!caseListToDisableSurvey.isEmpty()){
                surveyEnableCheck = true;
                update caseListToDisableSurvey;
            }
            if(!surveyContactsToDelete.isEmpty()){
                delete surveyContactsToDelete;
            }
        }
        catch(exception e){
            system.debug('Error Message//'+ e.getMessage());
        }
        if(!eligibleCaseList.isEmpty()){
            // Fetching emails on Case which are sent to the Customer from the Case Owner
            emailMessageList = [SELECT Id, ParentId, ActivityId, FromAddress, FromName, ToAddress,incoming,customer_email__c
                                FROM EmailMessage where parentid =: eligibleCaseList and Status != '5' order by MessageDate desc];
            
            if(!emailMessageList.isEmpty()){
                
                for(EmailMessage emailMsg : emailMessageList){
                    if(emailMsg.FromAddress.equalsIgnoreCase(caseIdOwnerEmailMap.get(emailMsg.ParentId))){

                        if(emailMsg.ToAddress != null){
                            for(String Address : emailMsg.ToAddress.split('; '))
                            {
                                if(!Address.contains('@akamai.com'))
                                {
                                    isCustomerEmail =true;
                                    emailIds.add(Address);
                                }
                            }
                            if(isCustomerEmail){
                                caseIdEmailMsgMap.put(emailMsg.ParentId,emailMsg);
                            }
                        }
                        break;
                    }
                }
                
                
                List<Contact> contactList = [Select id, Name, AccountId, email, Active_Portal_Login__c, Last_Time_Contact_Surveyed__c,No_Longer_with_Company__c  from Contact where No_Longer_with_Company__c=false and email in: emailIds];
                for(Contact con: contactList){
                    emailContactMap.put(con.email,con);
                }
                
                for(Case cs: eligibleCaseList){
                    if(caseIdEmailMsgMap.get(cs.Id)!=null){
                        em = caseIdEmailMsgMap.get(cs.Id);
                        if(cs.Status!='Closed'){
                            if(!cs.Internal_Case_Survey_Enabled__c){
                                cs.Internal_Case_Survey_Enabled__c = true;
                                caseListToUpdate.add(cs);    
                            }
                        }
                        // If status is closed, then the Survey Contacts will be created
                        if(cs.Status=='Closed' && surveyContactsList.isEmpty()){
                            for(String toAdd: em.ToAddress.split('; ')){
                                if(emailContactMap.containsKey(toAdd) && emailContactMap.get(toAdd).AccountId==cs.AccountId
                                   && (emailContactMap.get(toAdd).Last_Time_Contact_Surveyed__c < datetime.now().addHours(-12) || emailContactMap.get(toAdd).Last_Time_Contact_Surveyed__c == null)){
                                       // create new record  
                                       surveyContact = new CS_Survey_Contact__c();
                                       surveyContact.CS_Contact_Name__c = emailContactMap.get(toAdd).Id;
                                       surveyContact.CS_Case__c = cs.Id;
                                       surveyContact.CS_AuthorizedContacts__c = cs.AuthorizedContacts__c;
                                       surveyContact.CS_Milestone_Status__c = cs.MilestoneStatus;
                                       surveyContact.CS_Contact_Email__c = toAdd;
                                       surveyContactsList.add(surveyContact);
                                   }
                                else{
                                    if(cs.Internal_Case_Survey_Enabled__c){
                                        cs.Internal_Case_Survey_Enabled__c = false;
                                        cs.Validation_Override__c = true;
                                        caseListToUpdate.add(cs);    
                                    }  
                                }
                            }
                        }
                    }
                }

                try{
                    surveyEnableCheck = true;
                    if(!caseListToUpdate.isEmpty()){
                        update caseListToUpdate;
                    }
                    if(!surveyContactsList.isEmpty()){
                        insert surveyContactsList;
                    }
                }
                catch(exception e){
                    system.debug('exception://'+ e.getMessage());
                }
            } 
        }
    }

    //Changes by Tejaswini for ESESP-6008 SOCC AIM Program: LA Rollout 
    //Call bigpanda to resolve incidents that are associated to case and form post body
    
    public static void updateBPIncident(Id caseId,String operation){
        
        List<BP_Incident__c> lBPIncident = [Select Incident_Id__c,Case__r.AKAM_Case_ID__c from BP_Incident__c where Case__c=:caseId];
        String postbody;
        String postString = SC_BigPanda_Case_Modal_Ctrl.getIncidentWrapper(lBPIncident,operation);

        System.debug('the final request body for incidents update is'+postString);
        Id sfbpLogId;
        Id recordTypeId = Schema.SObjectType.Salesforce_BigPanda_Log__c.getRecordTypeInfosByName().get('Outbound Request').getRecordTypeId();

        SC_Utility__mdt  mdt = SC_Utility__mdt.getInstance('BigPanda_Post_Incident_URL');
        String  bpEndPoint = mdt.Value__c;
        System.debug('the bpEndPoint is: '+bpEndPoint);
        String method='POST';

        Salesforce_BigPanda_Log__c sfbpLog = new Salesforce_BigPanda_Log__c();

        if(lBPIncident.size()>0 && postString!=null){
            
            sfbpLog.RecordTypeId = recordTypeId;
            sfbpLog.Case_Id__c = caseId;
            sfbpLog.Request_Endpoint__c = bpEndPoint;
            sfbpLog.Request_Method__c = method;
            sfbpLog.Request_Body__c = postString;
            sfbpLog.Do_Not_Retry__c = false;
            sfbpLog.Number_of_Tries__c = 1;
            
            if(operation.equalsIgnoreCase('Case Escalation')){
                sfbpLog.Action__c = 'Case Escalation';
                sfbpLog.Flow_Name__c = 'post_incidentsSub_Flow';
            }
            else if(operation.equalsIgnoreCase('Case Close')){
                sfbpLog.Action__c = 'Case Close';
                sfbpLog.Flow_Name__c = 'post_incidentsSub_Flow';
            }
            

            try{
                insert sfbpLog;
                System.debug('the id of Salesforce_BigPanda_Log__c record is: '+sfbpLog.Id);
                sfbpLogId = sfbpLog.Id;

                //send record id as email
                //SC_BigPanda_Case_Modal_Ctrl.sendEmailLogRecId(bpEndPoint,sfbpLogId);
    
            }catch(Exception e)
            { System.debug('The following exception has occurred: ' + e.getMessage()); }
        }
         
        if(lBPIncident.size()>0 && sfbpLogId!=null && !Test.isRunningTest())
        {
            System.enqueueJob(new SC_BigPandaAPI(bpEndPoint, method,postString, sfbpLog));
        }
    }
    
    public static void updateBPIncidentTags(Id caseId){
        List<BP_Incident__c> lBPIncident = [Select Incident_Id__c from BP_Incident__c where Case__c=:caseId];
        //String requestbody='[';
        String postString = SC_BigPanda_Case_Modal_Ctrl.getIncidentTagWrapper(lBPIncident);
        
        Id sfbpLogId;
        Id recordTypeId = Schema.SObjectType.Salesforce_BigPanda_Log__c.getRecordTypeInfosByName().get('Outbound Request').getRecordTypeId();

        SC_Utility__mdt  mdt = SC_Utility__mdt.getInstance('BigPanda_Post_Incident_Tags_URL');
        String  bpEndPoint = mdt.Value__c;
        System.debug('the bpEndPoint is: '+bpEndPoint);
        String method='POST';

        Salesforce_BigPanda_Log__c sfbpLog = new Salesforce_BigPanda_Log__c();

        if(lBPIncident.size()>0){
        
            sfbpLog.RecordTypeId = recordTypeId;
            sfbpLog.Case_Id__c = caseId;
            sfbpLog.Request_Endpoint__c = bpEndPoint;
            sfbpLog.Request_Method__c = method;
            sfbpLog.Request_Body__c = postString;
            sfbpLog.Do_Not_Retry__c = false;
            sfbpLog.Number_of_Tries__c = 1;
            sfbpLog.Action__c = 'Case Escalation';
            sfbpLog.Flow_Name__c = 'post_incidentTagsSub_Flow';

            try{
                insert sfbpLog;
                System.debug('the id of Salesforce_BigPanda_Log__c record is: '+sfbpLog.Id);
                sfbpLogId = sfbpLog.Id;
                
                //send record id as email
                //SC_BigPanda_Case_Modal_Ctrl.sendEmailLogRecId(bpEndPoint,sfbpLogId);        
    
            }catch(Exception e)
            {    System.debug('The following exception has occurred: ' + e.getMessage());  }

        }
        
        if(lBPIncident.size()>0 && sfbpLogId!=null && !Test.isRunningTest())
        {
            System.enqueueJob(new SC_BigPandaAPI(bpEndPoint, method, postString, sfbpLog));
        }
    }
}