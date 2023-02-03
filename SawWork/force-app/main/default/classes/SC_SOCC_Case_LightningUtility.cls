/*
Author          : Sumukh SS
Description     : Apex Controller for SOCC Lightning Migration and SOCCDash
Test Class      : SC_SOCC_Case_LightningUtility_TC

Date                 Developer                  JIRA #          Description                                                       
-----------------------------------------------------------------------------------------------------------------
23 Sep 2019         Sumukh/Sumanth/Himanshu     ESESP-2198      SOCC Lightning Migration (SOCDash and SOCC Case Management/Automation)
09 Oct 2019         Pinkesh                     ESESP-2689      Change Passphrase access
01 Jan 2020			Sumukh SS					ESESP-2922		Adjust SOCCDash View
14 Jan 2020			Sumukh SS		 			ESESP-2026		SOCC CAR 2 - RunBooks 
22 Apr 2020         Pinkesh                     ESESP-3411      scSoccCaseTask LWC component changes, removed aura task component menthods
27 OCT 2021         Jay                         ESESP-6265      Added LIMIT 50000 to unbounded SOQLs
18 Apr 2022         Tejaswini                   ESESP-6444      Salesforce automation for case closure - SOCC
------------------------------------------------------------------------------------------------------------------
*/
public class SC_SOCC_Case_LightningUtility 
{
   
            //----------------------------------Internal Email Quick Action-----------------------------
            
            // Method - 1 : To Get all Internal Emails
            @AuraEnabled
            public static List<EmailMessage> getEmail(String recordId)
        {
            // List to return
            List<EmailMessage> FinalMessageList = new List<EmailMessage>();
            
            for(EmailMessage Msg : [Select Id, FromAddress,FromName,ToAddress,BccAddress, CcAddress,Subject,TextBody,HtmlBody,MessageDate 
                                    From EmailMessage 
                                    where Parentid =: recordId 
                                    order by MessageDate desc]){
                                        
                                        
                                        Boolean Toflag = false; // If All To Addresses are @akamai, then set it to True
                                        Boolean Fromflag = false;
                                        Boolean CCflag = false; // If All CC Addresses are @akamai, then set it to True
                                        Boolean BCCflag = false; // If All Bcc Addresses are @akamai, then set it to True
                                        
                                        /*****Processing To address ****/
                                        if(Msg.ToAddress!=null)
                                        {
                                            for(String toadd:Msg.ToAddress.split(';'))
                                            {
                                                if(toadd.contains('@akamai.com'))
                                                {
                                                    
                                                    Toflag =true;
                                                    
                                                }
                                                else
                                                {
                                                    Toflag =false;
                                                    break;
                                                    
                                                }
                                                
                                            }
                                            
                                        }
                                        
                                        
                                        /***Processing From Address ****/
                                        if(Msg.FromAddress!=null)
                                        {
                                            Fromflag = Msg.FromAddress.contains('@akamai.com') ? true : false;
                                            
                                        }
                                        
                                        /***Processing CC Address *****/
                                        if(Msg.CCAddress==null)
                                        {
                                            
                                            CCflag =true;
                                        }
                                        if(Msg.CcAddress!=null)
                                        {
                                            for(String ccadd:Msg.CcAddress.split(';'))
                                            {
                                                if(ccadd.contains('@akamai.com'))
                                                {
                                                    
                                                    CCflag =true;
                                                    
                                                }
                                                else
                                                {
                                                    CCflag =false;
                                                    break;
                                                    
                                                }
                                                
                                            }
                                        }
                                        
                                        /****Processing BCC Address *****/
                                        if(Msg.BCCAddress==null)
                                        {
                                            
                                            BCCflag =true;
                                        }
                                        if(Msg.BccAddress!=null)
                                        {
                                            
                                            for(String bccadd:Msg.BccAddress.split(';'))
                                            {
                                                if(bccadd.contains('@akamai.com'))
                                                {
                                                    
                                                    BCCflag =true;
                                                    
                                                }
                                                else
                                                {
                                                    BCCflag =false;
                                                    break;
                                                    
                                                }
                                                
                                            }  
                                        }
                                        
                                        /***Verify if its a valid internal email and add to final list ***/
                                        if(Toflag && Fromflag && CCflag && BCCflag)
                                        {
                                            
                                            FinalMessageList.add(Msg);
                                            
                                        }            
                                    }
            
            return FinalMessageList;
            
        }
    
    // Method - 2 : Called when User Clicks on Email Link to navigate to Email Message Record
    @AuraEnabled
    public static EmailMessage getSingleEmail(String recordId)
    {
        return [Select Id, FromAddress,ToAddress,BccAddress, CcAddress,Subject,TextBody,HtmlBody,MessageDate From EmailMessage where id =: recordId limit 1];
    }
    
       
    // Method - 4 : Called When Email Internal Quick Action is clicked
    @AuraEnabled
    public static List<String> getInternalEmails(String CaseId)
    {
        
        List<String> EmailList = new List<String>();
        List<String> InternalEmailList = new List<String>();
        
        Case lCases = [select AuthorizedContacts__c,policy_domain__c,Contact.Email,Subject,AKAM_Case_Id__c,Alternate_Contact_Email__c,Suggested_Recipients__c,Microsoft_Email_address__c from Case where id=:CaseId limit 1];
        
        if(lCases.AuthorizedContacts__c!=null)
        {
            EmailList.addAll(lCases.AuthorizedContacts__c.replace(';',',').split(','));
        }
        
        if(lCases.Contact.Email!=null)
        {
            EmailList.add(lCases.Contact.Email);
        }
        
        if(lCases.Suggested_Recipients__c!=null)
        {
            EmailList.addAll(lCases.Suggested_Recipients__c.replace(';',',').split(','));
            
        }
        
        //Getting Authorised Contact Emails
        If(lCases.policy_domain__c != null)
        {
            for(Authorized_Contact__c ac: [select Contact_Name__r.name,Contact_Name__r.Email,Contact_Name__c,Contact_Name__r.Passphrase__c,
                                           Product_Interests__c ,Emergency_Email__c, Emergency_Text__c , Emergency_Voice__c , Maintenance_Email__c, 
                                           Contact_Name__r.Accountid  
                                           from Authorized_Contact__c 
                                           where Policy_Domain__c =:lCases.policy_domain__c 
                                           order by Contact_Name__r.name])
            {
                
                EmailList.add(ac.Contact_Name__r.Email);
            }
        }
        
        // Final Set
        for(String Email:EmailList)
        {
            if(Email.contains('@akamai.com'))
            {
                InternalEmailList.add(Email);
            }
        }
        
        return InternalEmailList;
        
    }
    
  
    
    //Method - 6  : To get Contact Email
    @AuraEnabled 
    public static String getContactEmail(String CaseId)
    {
        return [Select Contact.Email from Case where Id=:CaseId limit 1].Contact.Email;
    }
    
    // Method - 7 : Called When Case Detail Page -> Left Side bar -> Luna Customer Update
    @AuraEnabled
    public static list<task> getwebupdateTaskDetails(String caseId){
        return [select id, who.name,whoid, Description, whatid, Type__c,createddate from task where whatid=:caseId and Type__c='Web Update' order by lastmodifieddate desc];
        
    }
    // ---------------------- SC_SOCC_Lightning_CaseInitialSetup.cmp------------------------------
    
    // Method - 8 : Getting Case details
    @AuraEnabled
    public static list<case> getCaseInitialSetupDetails(String caseId){
        return [Select Id,Is_Socc_Case_Authorized__c,SOCC_Image_Banner_Category__c,Case_Situation_Handler__c,Service_Category__c,Case_Product__c,Policy_Domain__c from case where id=:caseId limit 1];
    }    
    
    
    // Method - 10 : Called from Initial Case Setup + Case Authorization
    @AuraEnabled 
    public static string UpdateImageBanner(String caseId, string imageBanner){
        Case c = [Select Id,isClosed from case where id =: caseId limit 1];
        if(c.isClosed == false){
            c.Is_Socc_Case_Authorized__c  = True;
            c.Validation_Override__c = True;
            c.SOCC_Image_Banner_Category__c =imageBanner;
            try{
                update c;
            }catch(Exception e){ return e.getMessage(); }
        }
        return 'success';
    }
    
    // Method - 10 : for sending Email when No Policy Domain Exists to account team
    @AuraEnabled
    public static string sendEmailToAccountTeam(string caseId){
        
        // For all To Address
        List<string> allToAddress = new List<string>();
        
        // For all CC Address
        List<string> allCCAddress = new List<string>();
        
        try {
            
            // For From Address & Name
            String Soccfromnamefinal = [Select Value_Text__c from SC_Utility__mdt where MasterLabel = 'SOCC From Name' limit 1].Value_Text__c;   
            string fromAdd = [select Id from OrgWideEmailAddress where Address =:Soccfromnamefinal limit 1].Id;         
            
            //Get case Details
            case getcasedetails=[select Case_Account_Name__c,AKAM_Account_ID__c ,akam_case_id__c,AccountId,Case_Prod_Name__c, Contact.name  from case where id=:caseId limit 1];
            
            //Get Loggedin users signature
            User currUser = [Select Signature from User where Id=:userinfo.getuserId()]; string userSignature = (currUser.Signature!=null) ? currUser.Signature : '';
            
            
            //Set email subject
            String SubjectString = '[AKAM-CASE #'+getcasedetails.akam_case_id__c+']: Urgent: Policy Domain creation required for : '+getcasedetails.Case_Account_Name__c;
            
            //Set Body
            String Body = '<b>Account Name : </b>'+getcasedetails.Case_Account_Name__c+'<br/>';
            Body += '<b>Account ID : </b>'+getcasedetails.AKAM_Account_ID__c+'<br/>';
            Body += '<b>Case Product : </b>'+getcasedetails.Case_Prod_Name__c+'<br/><br/>';
            Body += 'Hello Account Team'+',<br/><br/>'; 
            Body = Body+'A managed security ticket has been opened with the SOCC by '+getcasedetails.Contact.name+'. We noticed that the required policy domain for this contact is missing or has not been created yet, and is resulting in issues with identifying the user privileges and providing the required support for this ticket as well as for future tickets. Please consider resolving the policy domain issues on priority so that we can proceed further with assisting the customer.<br/><br/>';
            Body = Body+'Please feel free to call the Global SOCC for any queries or concerns.';
            Body = Body+'<br/><br/>Regards,<br/>'+userSignature+'<br/></br/>Security Operations Command Center<br/>Akamai Technologies<br/>';
            Body = Body+'<a class="external-link" title="http://www.akamai.com/threatresearch" href="http://www.akamai.com/threatresearch" target="_blank" rel="nofollow noopener">www.akamai.com/threatresearch</a> <br/>';
            Body = Body+'(+1) 617-444-4955<br/>(+1) 855-662-5662, Toll Free (US Only)<br/>(+65)  657-693-50, APJ<br/>(+48) 123-847-924, EMEA<br/>(+81) 345-207-530, Japan<br/>';
            Body = Body+'International Dialing Instructions:&nbsp;<a class="external-link" href="https://www.akamai.com/us/en/support/global-support-phone-numbers.jsp" target="_blank" rel="nofollow noopener">https://www.akamai.com/us/en/support/global-support-phone-numbers.jsp</a>';
            
            // Setting To & CC Address
            for (AccountTeamMember eachmemeber : [select User.Email,TeamMemberRole from AccountTeamMember where 
                                                  User.isActive = true and 
                                                  AccountId = :getcasedetails.AccountId and 
                                                  TeamMemberRole IN ('Security Services - Primary', 'Security Services - Secondary', 
                                                                     'Services - Primary', 'Services - Secondary')]){
                                                                         
                                                                         if(eachmemeber.TeamMemberRole == 'Security Services - Primary' || eachmemeber.TeamMemberRole == 'Security Services - Secondary')
                                                                             allToAddress.add(eachmemeber.User.Email);
                                                                         else
                                                                             allCCAddress.add(eachmemeber.User.Email);                              
                                                                     }
            
            
            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            if(allToAddress.size() > 0)
                mail.setToAddresses(allToAddress);
            
            if(allCCAddress.size() > 0)
                mail.setCcAddresses(allCCAddress);
            
            mail.setOrgWideEmailAddressId(fromAdd);
            mail.setSubject(SubjectString);
            mail.setHtmlBody(Body);
            mail.setUseSignature(false); 
            mail.setWhatId(caseId);
            mail.setSaveAsActivity(true);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); 
            
        }
        catch (exception e){
            return 'Failed! Error: '+ e.getMessage();   
        }
        return 'Success';                                   
    }
    
    //------------------------Method to get list of Policy Domains for a account(Lightning comp: SC_PolicyDomainSelector)------------------------------
    // Method - 13 : Called from Initial Case Setup - Shows List of PD and associated situations for Account - Case Product
    
    
    public class PD_Situation_Wrapper{
        @AuraEnabled public  string policyDomainOptions{get;set;}
        @AuraEnabled public  String AssociatedSituationOptions{get;set;}
    }
    
    @AuraEnabled (cacheable=true)
    public static PD_Situation_Wrapper getPolicyDomainList(String caseId, string CaseProdID){
        
        PD_Situation_Wrapper each_PD_Situation_Wrapper = new PD_Situation_Wrapper();
        //Store the policyDomain ID whether Saved already or the first PD in the PolicyDomainList. This for loading the plaussible situations simultaneously 
        string policydomainid_situation;
        
        List<Policy_Domain__c > PolicyDomainList=new list<Policy_Domain__c>();
        String PolicyDomainMapping = '[';
        Case caseRec = [Select Id, AccountId,Case_Product__r.Name,Policy_Domain__c,Case_Situation_Handler__c from case where Id =:caseId limit 1];
        if(CaseProdID!=null)
        {
            EB_AccountProductMap__c caseprodname = [select name from EB_AccountProductMap__c where id=:CaseProdID limit 1];
            
            PolicyDomainList = [SELECT Name, Id FROM Policy_Domain__c WHERE  Account_Name__c  = :caseRec.AccountId and 
                                (Additional_Product__c includes (:caseprodname.Name) OR Product__c = :caseprodname.Name) and 
                                Policy_Domain_State__c ='Active' order by Name ASC];
            
            if(PolicyDomainList.size() > 0)
                policydomainid_situation=PolicyDomainList[0].Id;
        }
        else
        {
            PolicyDomainList = [SELECT Name, Id FROM Policy_Domain__c WHERE 
                                Account_Name__c  = :caseRec.AccountId and (Additional_Product__c includes (:caseRec.Case_Product__r.Name) 
                                                                           OR Product__c = :caseRec.Case_Product__r.Name) and Policy_Domain_State__c ='Active' order by Name ASC];
            
            //If case has a policy domain choosen getting situations only for that PD, else getting the situations for the first PD in ascending order
            if(caseRec.Policy_Domain__c!=null)
            {
                policydomainid_situation=caseRec.Policy_Domain__c;
            }
            else
            {	
                if(PolicyDomainList.size() > 0)
                    policydomainid_situation=PolicyDomainList[0].Id;
            }
            
        }
        
        if(PolicyDomainList.size() > 0){
            for(Policy_Domain__c c : PolicyDomainList){
                // If Case-Policy Domain = Policy Domain then mark Selected = true
                if(CaseProdID==null){
                    if(c.id == caseRec.Policy_Domain__c)
                        PolicyDomainMapping += '{"id": "' + c.Id + '", "label": "' + c.Name + '", "selected": true}, ';
                    else
                        PolicyDomainMapping += '{"id": "' + c.Id + '", "label": "' + c.Name + '"}, ';
                }
                else
                    PolicyDomainMapping += '{"id": "' + c.Id + '", "label": "' + c.Name + '"}, ';       
            }  			
            
            PolicyDomainMapping = PolicyDomainMapping.substring(0,PolicyDomainMapping.length()-2) + ']';
            
            each_PD_Situation_Wrapper.policyDomainOptions=PolicyDomainMapping;
        }
        else
        {each_PD_Situation_Wrapper.policyDomainOptions='null';}
        
        //Getting Associated Situations 
        String SituationMapping = '[';
        List<SC_SOCC_Situation_to_Handler_Mapping__c > situationlist=new list<SC_SOCC_Situation_to_Handler_Mapping__c>();
        
        situationlist = [select id, Situation__c,Situation__r.name from SC_SOCC_Situation_to_Handler_Mapping__c where Policy_Domain__c =:policydomainid_situation];        
        
        if(situationlist.size() > 0){
            
            for(SC_SOCC_Situation_to_Handler_Mapping__c sit : situationlist){
                
                if(sit.id == caseRec.Case_Situation_Handler__c)
                    SituationMapping += '{"id": "' + sit.id + '", "label": "' + sit.Situation__r.Name + '", "selected": true}, ';
                else
                    SituationMapping += '{"id": "' + sit.id + '", "label": "' + sit.Situation__r.Name + '"}, ';
            }  
            SituationMapping = SituationMapping.substring(0,SituationMapping.length()-2) + ']';
            
            each_PD_Situation_Wrapper.AssociatedSituationOptions= SituationMapping;
        }
        else
        {each_PD_Situation_Wrapper.AssociatedSituationOptions='null';}
        
        return each_PD_Situation_Wrapper;
        
    }
    
    @AuraEnabled(cacheable=true)
    public static string getSituationsforPolicyDomain(string PolicyDomainId, string caseId)
    {
        String SituationMapping = '[';
        List<SC_SOCC_Situation_to_Handler_Mapping__c > situationlist=new list<SC_SOCC_Situation_to_Handler_Mapping__c>();
        
        // policy_Domain__c PolicyDomainList = [Select Id, Additional_Product__c ,Product__c  from policy_Domain__c where Id =:PolicyDomainId limit 1];
        situationlist = [select id, Situation__c,Situation__r.name from SC_SOCC_Situation_to_Handler_Mapping__c where Policy_Domain__c =:PolicyDomainId];        
        case caseRec = [select id, Case_Situation_Handler__c  from case where id=:caseId limit 1];
        
        if(situationlist.size() > 0){
            
            for(SC_SOCC_Situation_to_Handler_Mapping__c c : situationlist){
                
                // If Case-Policy Domain = Policy Domain then mark Selected = true
                if(c.id == caseRec.Case_Situation_Handler__c)
                    SituationMapping += '{"id": "' + c.id + '", "label": "' + c.Situation__r.Name + '", "selected": true}, ';
                else
                    SituationMapping += '{"id": "' + c.id + '", "label": "' + c.Situation__r.Name + '"}, ';
            }  
            SituationMapping = SituationMapping.substring(0,SituationMapping.length()-2) + ']';
            
            return SituationMapping;
        }
        else
            return 'null';
    }
    
    // Method - 14 : Method to save/update Policy Domain
    @AuraEnabled 
    public static string savePolicyDomainandSituation(String caseId, String newPolicyDomainId, string newSituationID){
        
        Case c = [Select Id, Policy_Domain__c,Case_Situation_Handler__c,Validation_Override__c,isClosed from case where id =:caseId limit 1];
        
        // If Status is not Closed and PD is changed
        if(c.isClosed == false){
            
            c.Policy_Domain__c = newPolicyDomainId;
            c.Case_Situation_Handler__c=newSituationID;
            c.Validation_Override__c = True;
            try{
                update c;
            }catch(Exception e){ return e.getMessage(); }
            
            return 'success';
        }
        else
            return 'Closed Case can not be updated!';
    }
    
    //---------------------------------SC_SOCC_LivingSummaryTemplate.cmp----------------------------
    // Method - 11 : Getting all Living Summary Template
    @AuraEnabled(cacheable=true)
    public static list<SC_SOCC_Living_Summary_Template__c> getLivingSummaryDetails(){
        return [ select id ,name from SC_SOCC_Living_Summary_Template__c order by name LIMIT 50000];
    }   
    
    // Method - 12 : Gets the living summary body and appends the user ALIAS to it
    @AuraEnabled(cacheable=true)
    public static string getLivingSummaryBody(string LSid)
    {
        string LSBody= [select Living_Summary_Template__c  from SC_SOCC_Living_Summary_Template__c where id=:LSid limit 1].Living_Summary_Template__c;
        string ldapname=[select alias from user where id = :userinfo.getUserId() limit 1].alias;
        LSBody = LSBody.replace('[]', '['+ldapname+']');
        return LSBody;
    }
    
    //---------------------------------SC_SOCC_Lightning_Runbook_Handler.cmp----------------------------
    
    
    public class CaseStatus_RunBook_Wrapper{
        @AuraEnabled public string StatusMessage{get;set;}
        @AuraEnabled public string PolicyDomID{get;set;}
        @AuraEnabled public string EscListID{get;set;}
        @AuraEnabled public list<SC_SOCC_Situation_to_Handler_Mapping__c> HandlerDetails{get;set;}
        
    }
    
    // Method - 9 : Getting Case-Handler details
    @AuraEnabled
    public static CaseStatus_RunBook_Wrapper getCaseHandlerDetails(String caseId){
        
        CaseStatus_RunBook_Wrapper each_CaseStatus_RunBook_Wrapper = new CaseStatus_RunBook_Wrapper();
        
        list<case> casedet=[select id,Is_Socc_Case_Authorized__c,policy_domain__c,Case_Situation_Handler__r.handler__r.Id,Case_Situation_Handler__r.handler__r.Escalation_List__c,Case_Situation_Handler__c from case where id=:caseId limit 1];
        if(casedet[0].Is_Socc_Case_Authorized__c)
        {
            if(casedet[0].Case_Situation_Handler__c==null)
            {
                each_CaseStatus_RunBook_Wrapper.StatusMessage='Please tag this case to a situation!';
            }
            else if(casedet[0].Case_Situation_Handler__r.handler__r.Id==null)
            {
                each_CaseStatus_RunBook_Wrapper.StatusMessage='There seems to be no handler associated with this situation! Please associate, to view the Runbook Instructions.';
            }
            else
            {
                each_CaseStatus_RunBook_Wrapper.HandlerDetails=[select handler__r.Id,handler__r.Name, handler__r.Handler_Type__r.Name, handler__r.Policy_Domain__r.Name, handler__r.Situation_Instruction__c, handler__r.Ignore_Condition__c,handler__r.Escalation_List__r.Instructions__c,handler__r.Escalation_List__r.Name   from SC_SOCC_Situation_to_Handler_Mapping__c where id=:casedet[0].Case_Situation_Handler__c limit 1];
                each_CaseStatus_RunBook_Wrapper.PolicyDomID=casedet[0].policy_domain__c;
                each_CaseStatus_RunBook_Wrapper.EscListID=casedet[0].Case_Situation_Handler__r.handler__r.Escalation_List__c;
                each_CaseStatus_RunBook_Wrapper.StatusMessage='Success';
            }
        }
        else
        {
            each_CaseStatus_RunBook_Wrapper.StatusMessage='Please complete the Case Setup flow to view the Runbook Instructions!';
            each_CaseStatus_RunBook_Wrapper.HandlerDetails=null;
        }
        return each_CaseStatus_RunBook_Wrapper;
    }   
    
    // ----------- SC_SOCC_Authorized_Contacts.cmp------------------------------
    
    // Method - 15 : Main wrapper for returning whether the case is already authorized or not - 2 Level Main Wrapper
    public class main_Auth_contact_wrapper
    {
        @AuraEnabled public list<sub_Contact_Wrapper> wrapperlist {get;set;}
        @AuraEnabled public string case_authorized{get;set;}
    }
    
    // Method - 16 : List of Authorized Contact
    public class sub_Contact_Wrapper{
        @AuraEnabled public  Authorized_Contact__c EachAuthContRec{get;set;}
        @AuraEnabled public  String hasAccess{get;set;}
    }
    
    // Method - 17 : Get list of authorized contacts for the contacts + passphrase + Access to view
    @AuraEnabled
    public static main_Auth_contact_wrapper getAuthorizedContacts(String caseId){
        
        list<case> caserec =[select id,accountid,Is_Socc_Case_Authorized__c,Case_Situation_Handler__c, Service_Category__c,Case_Product__c,policy_domain__c from case where id=:caseId limit 1];
        
        list<Authorized_Contact__c> authorizedcon= new list<Authorized_Contact__c>();
        authorizedcon = [select Contact_Name__r.name ,Contact_Name__c,Contact_Name__r.Passphrase__c,Product_Interests__c ,Emergency_Email__c,Instruct__c , 
                         Emergency_Text__c , Emergency_Voice__c , Maintenance_Email__c, Contact_Name__r.Accountid   
                         from Authorized_Contact__c 
                         where Policy_Domain__c =:caserec[0].policy_domain__c AND Policy_Domain__c != ''  order by Instruct__c,Contact_Name__r.name];
        
        //Initializing main Wrapper
        main_Auth_contact_wrapper Each_main_Auth_contact_wrapper = new main_Auth_contact_wrapper();
        
        //Initializing Contact Wrapper
        List<sub_Contact_Wrapper> sub_Contact_Wrapper_List=new List<sub_Contact_Wrapper>();
        
        sub_Contact_Wrapper Each_sub_Contact_Wrapper;
        
        string hasProfileAccess;
        
        // Set to store Account Id who has access
        Set<Id> sAccountIDHasAccess;
        
        //Fetching profiles with passphrase permission that are stored in SC_SOC_Passphrase_Access__mdt for SOCC and Sys Admins
        List<SC_SOC_Passphrase_Access__mdt> lPassPhraseAccessForSOCC = [Select Id, Profile_ID_Text__c FROM SC_SOC_Passphrase_Access__mdt WHERE DeveloperName LIKE 'Passphrase_Access_For_SOCC_n_Admin%'];
        String lProfileIdForSOCC = '';
        for(SC_SOC_Passphrase_Access__mdt eachrec : lPassPhraseAccessForSOCC){
            lProfileIdForSOCC += eachrec.Profile_ID_Text__c + ',';
        }
        
        
        hasProfileAccess = (lProfileIdForSOCC.contains(Userinfo.getProfileId())) ? 'true' : 'false';
        
        set<Id> uniqueAccountIds = new set<Id>();
        for(Authorized_Contact__c eachaccid : authorizedcon){
            
            uniqueAccountIds.add(eachaccid.Contact_Name__r.AccountId);
        }
        
        // Setting the Set
        sAccountIDHasAccess = getAccountTeamDetailsAccess(uniqueAccountIds);
        uniqueAccountIds.clear();
        
        // for Setting Child Wrapper
        for(Authorized_Contact__c eachContact : authorizedcon)
        {
            Each_sub_Contact_Wrapper = new sub_Contact_Wrapper();
            Each_sub_Contact_Wrapper.EachAuthContRec = eachContact;
            Each_sub_Contact_Wrapper.hasAccess = (hasProfileAccess == 'true' || sAccountIDHasAccess.contains(eachContact.Contact_Name__r.AccountId)) ? 'true' : 'false';
            
            sub_Contact_Wrapper_List.add(Each_sub_Contact_Wrapper);
        }
        
        
        // for Setting Main Wrapper
        Each_main_Auth_contact_wrapper.wrapperlist=sub_Contact_Wrapper_List;
        
        // If true = Hide the Authorized Button
        Each_main_Auth_contact_wrapper.case_authorized = (caserec[0].Is_Socc_Case_Authorized__c == true || 
                                                          (caserec[0].Is_Socc_Case_Authorized__c==false && caserec[0].Case_Product__c==null) || 
                                                          (caserec[0].Is_Socc_Case_Authorized__c==false && caserec[0].policy_domain__c==null)//||
                                                          // (caserec[0].Is_Socc_Case_Authorized__c==false && caserec[0].Case_Situation_Handler__c==null)
                                                         ) ? 'true' : 'false';
        
        if(caserec[0].Service_Category__c=='Internal' ||caserec[0].Service_Category__c=='SOA'||caserec[0].Service_Category__c=='Non-Managed' )
        {
            Each_main_Auth_contact_wrapper.case_authorized = 'true';
        }
        
        return Each_main_Auth_contact_wrapper;
        
    }
    
    // Method - 18 : Called from getAuthorizedContacts Method
    public static Set<Id> getAccountTeamDetailsAccess(set<id> allAccList){
        //Fetching profiles with passphrase permission that are stored in SC_SOC_Passphrase_Access__mdt for PS profiles
        List<SC_SOC_Passphrase_Access__mdt> lPassPhraseAccessForPS = [Select Id, Profile_ID_Text__c, Account_Team_Role__c FROM SC_SOC_Passphrase_Access__mdt WHERE DeveloperName LIKE 'Passphrase_Access_For_PS%'];
        String lProfileIdForPS = '';
        Set<String> sAccountTeamRoleForPS = new Set<String>();
        for(SC_SOC_Passphrase_Access__mdt eachrec : lPassPhraseAccessForPS){
            lProfileIdForPS += eachrec.Profile_ID_Text__c + ',';
            if(String.isNotBlank(eachrec.Account_Team_Role__c))
                sAccountTeamRoleForPS.addAll(eachrec.Account_Team_Role__c.split(','));
        }

        //Fetching profiles with passphrase permission that are stored in SC_SOC_Passphrase_Access__mdt for AMG profiles
        List<SC_SOC_Passphrase_Access__mdt> lPassPhraseAccessForAMG = [Select Id, Profile_ID_Text__c, Account_Team_Role__c, User_Title_text__c FROM SC_SOC_Passphrase_Access__mdt WHERE DeveloperName LIKE 'Passphrase_Access_For_AMG%'];
        String lProfileIdForAMG = '';
        Set<String> sAccountTeamRoleForAMG = new Set<String>();
        Set<String> sUserTitleForAMG = new Set<String>();
        for(SC_SOC_Passphrase_Access__mdt eachrec : lPassPhraseAccessForAMG){
            lProfileIdForAMG += eachrec.Profile_ID_Text__c + ',';
            if(String.isNotBlank(eachrec.Account_Team_Role__c))
                sAccountTeamRoleForAMG.addAll(eachrec.Account_Team_Role__c.split(','));
            if(String.isNotBlank(eachrec.User_Title_text__c))
                sUserTitleForAMG.addAll(eachrec.User_Title_text__c.split(','));
        }

        //Set of account where user has access to see passphrase
        Set<Id> sAccountIDHasAccess = new Set<Id>();
        
        // Getting all Account Team Members
        for(AccountTeamMember eachMember : [SELECT Id, AccountId, UserId, User.Title, TeamMemberRole, Title FROM AccountTeamMember where AccountID IN : allAccList and UserId = :UserInfo.getUserId()]){
            //Checking permissions for PS profile
            if(lProfileIdForPS.contains(Userinfo.getProfileId()) && sAccountTeamRoleForPS.contains(eachMember.TeamMemberRole)){
                sAccountIDHasAccess.add(eachMember.AccountId);
            }
            //Checking permissions for AMG profile
            else if(lProfileIdForAMG.contains(Userinfo.getProfileId()) && sAccountTeamRoleForAMG.contains(eachMember.TeamMemberRole) && sUserTitleForAMG.contains(eachMember.User.Title)){
                sAccountIDHasAccess.add(eachMember.AccountId);
            }
        }
        return sAccountIDHasAccess;
    }
    
    // Method - 19 : Getting contact details details and then decrypting passphrase
    public class Contact_Details_Wrapper{
        @AuraEnabled public  contact contactdetails{get;set;}
        @AuraEnabled public  String decryptedPassphrase{get;set;}
    }
    
    // Method - 20 : Setting Contact Wrapper
    @AuraEnabled 
    public static Contact_Details_Wrapper getContactDetails(String ContactId){
        
        //Initializing wrapper
        Contact_Details_Wrapper Each_Contact_Details_Wrapper = new Contact_Details_Wrapper();
        
        contact varCon=[select name,Phone,MobilePhone, Email ,Passphrase__c,encryption_key__c,AKAM_Contact_ID__c from contact where id=:ContactId limit 1];
        
        //Assigning contact details to wrapper variable
        Each_Contact_Details_Wrapper.contactdetails = varCon;
        Schema.DescribeSObjectResult res = Contact.sObjectType.getDescribe();
        String keyPrefix = res.getKeyPrefix();
        Blob IV = Blob.valueOf((keyPrefix + varCon.AKAM_Contact_ID__c.leftPad(13,'_')).substring(0,16));
        
        if((varCon.Passphrase__c != null && varCon.encryption_key__c != null)){
            
            //Decrypting Passphrase
            Blob decrypted = Crypto.decrypt('AES256', EncodingUtil.base64Decode(varCon.encryption_key__c), IV, EncodingUtil.base64Decode(varCon.Passphrase__c));
            Each_Contact_Details_Wrapper.decryptedPassphrase = decrypted.toString();
        }
        else
            Each_Contact_Details_Wrapper.decryptedPassphrase = 'No Passphrase';
        
        return Each_Contact_Details_Wrapper;
    }
    
    //=================================================================================================    
    //-----------------------SOCC Dash / SOCC Lightning Home Methods ---------------------------------
    //==================================================================================================
    // Method - 21 :  Wrapper for Chart -1 : By Due Date
    public class Task_chart_wrapper{ 
        
        //Initializing Constructor
        public Task_chart_wrapper( integer TaskCountbelow0to6 ,Integer TaskCount0to6,Integer TaskCount6to12,Integer TaskCountabove12){
            
            this.TaskCountbelow0to6  = TaskCountbelow0to6 ; 
            this.TaskCount0to6 = TaskCount0to6 ;
            this.TaskCount6to12=TaskCount6to12;
            this.TaskCountabove12=TaskCountabove12;
        }
        
        @AuraEnabled public integer TaskCountbelow0to6{get;set;}
        @AuraEnabled public integer TaskCount0to6{get;set;}
        @AuraEnabled public integer TaskCount6to12{get;set;}
        @AuraEnabled public integer TaskCountabove12{get;set;}   
        
    }
    
    // Method - 22 : Returns Data for Chart -1 
    @AuraEnabled
    public static list <Task_chart_wrapper> getTaskcountByDueDate()
    {
        list<Task_chart_wrapper> Task_Chart_Data=new list<Task_chart_wrapper>();
        
        DateTime fromTime = system.now().addHours(-6);
        DateTime toTime = system.now();
        
        // Query - 1 : get tasks between -6hrs to Now
        List<AggregateResult> result =  [select count(id) from task 
                                         where DueDateProlexic__c>=:fromTime and DueDateProlexic__c<:toTime and 
                                         what.type = 'Case' 
                                         and what.recordtype.name='Managed Security'
                                         and status NOT IN ('Completed', 'Completed Important', 'Closed Duplicate', 'Not Applicable')];
        integer duedatebelow0to6=(integer)result[0].get('expr0');
        
        // Query -2 : Get tasks between Now to 6Hrs
        fromTime = system.now();
        toTime = system.now().addHours(6);
        
        result =  [select count(id) from task where DueDateProlexic__c>=:fromTime and 
                   DueDateProlexic__c<=:toTime 
                   and what.type = 'Case' 
                   and what.recordtype.name='Managed Security'
                   and status NOT IN ('Completed', 'Completed Important', 'Closed Duplicate', 'Not Applicable')];
        integer duedatebet0to6=(integer)result[0].get('expr0');
        
        // Query - 3 : Get tasks between 6Hrs to 12Hrs
        fromTime = system.now().addHours(6);
        toTime = system.now().addHours(12);
        
        result =  [select count(id) from task where DueDateProlexic__c>=:fromTime and DueDateProlexic__c<=:toTime and what.type = 'Case' and what.recordtype.name='Managed Security'
                   and status NOT IN ('Completed', 'Completed Important', 'Closed Duplicate', 'Not Applicable')];
        integer duedatebet6to12=(integer)result[0].get('expr0');
        
        // Query - 4 : Count of tasks greater than 12Hrs
        fromTime = system.now().addHours(12);
        result =  [select count(id) from task where DueDateProlexic__c>:fromTime and what.type = 'Case' and what.recordtype.name='Managed Security'
                   and status NOT IN ('Completed', 'Completed Important', 'Closed Duplicate', 'Not Applicable')];
        integer duedateabove12=(integer)result[0].get('expr0');
        
        Task_Chart_Data.add(new Task_chart_wrapper(duedatebelow0to6,duedatebet0to6 ,duedatebet6to12,duedateabove12));
        return Task_Chart_Data;
        
    }
    
    // Method - 23 : Wrapper for Chart - 2 : By Geo
    public class Task_geo_chart_wrapper{ 
        
        //Initializing Constructor
        public Task_geo_chart_wrapper( integer apj ,Integer emea,Integer americas){
            this.apj  = apj ; 
            this.emea = emea ;
            this.americas=americas;
        }
        @AuraEnabled public integer apj{get;set;}
        @AuraEnabled public integer emea{get;set;}
        @AuraEnabled public integer americas{get;set;}
        
    }
    
    // Method - 24 : Returns Data for Chart - 2
    @AuraEnabled
    public static list <Task_geo_chart_wrapper> getTaskcountBygeo()
    {
        // Map to store Case Id + no of Task count
        map<id,integer> caseId_noOfTask_map=new map<id,integer>();
        
        // Map to store Case Id + Geo
        map<id,string> case_Geography_map=new map<id,string>();
        
        // Initializing geo variables
        integer apjcount=0,emeacount=0,americascount=0;
        
        DateTime fromTime = system.now();
        DateTime toTime = system.now().addHours(6);
        
        //Query - 1 : get tasks group by CaseId between Now to 6hrs
        List<AggregateResult> taskresult =  [select whatid,count(id) from task where DueDateProlexic__c>=:fromTime and DueDateProlexic__c<=:toTime and what.type = 'Case' and what.recordtype.name='Managed Security'
                                             and status NOT IN ('Completed', 'Completed Important', 'Closed Duplicate', 'Not Applicable') 
                                             group by whatid]; 
        
        // setting caseId_noOfTask_map 
        for(AggregateResult ar : taskresult){
            
            caseId_noOfTask_map.put((string)ar.get('whatid'), (integer)ar.get('expr0'));
        }
        
        // Getting Case details
        for(case eachCaseRec : [select id,support_geography__c from case where id in :caseId_noOfTask_map.keyset()])
        {
            case_Geography_map.put(eachCaseRec.id,eachCaseRec.support_geography__c);
        }
        
        string taskgeo;
        // Loop for caseId_noOfTask_map
        for(string eachCaseId : caseId_noOfTask_map.keyset()){
            
            
            apjcount =  (case_Geography_map.get(eachCaseId) == 'APJ') ? apjcount + caseId_noOfTask_map.get(eachCaseId) :apjcount;
            emeacount =  (case_Geography_map.get(eachCaseId) == 'EMEA') ? emeacount + caseId_noOfTask_map.get(eachCaseId) : emeacount;
            americascount =  (case_Geography_map.get(eachCaseId) == 'Americas') ? americascount + caseId_noOfTask_map.get(eachCaseId) : americascount;
        }
        
        // Adding to wrapper
        list<Task_geo_chart_wrapper> Task_geo_Chart_Data=new list<Task_geo_chart_wrapper>();
        Task_geo_Chart_Data.add(new Task_geo_chart_wrapper(apjcount,emeacount ,americascount));
        return Task_geo_Chart_Data;
    }
    
   
    //Method - 41 :  Method to get list of case products for an account (Case product and Policy Domain Selector Component)
    @AuraEnabled 
    public static string getCaseProductList(String caseId){
        String caseProductMapping = '[';
        
        // Getting Case Details
        Case caseRec = [Select Id, AccountId, Case_Product__c from case where Id =:caseId limit 1];
        
        // Getting All Case Product
        for(EB_AccountProductMap__c c : [SELECT Name, Id FROM EB_AccountProductMap__c WHERE EB_MarkedForDeletion__c =false and 
                                         EB_Account__c = :caseRec.AccountId order by Name ASC]){
                                             
                                             // If Case Product Matching with Case-> Case Product, then Mark Selected = true
                                             if(c.id == caseRec.Case_Product__c)
                                                 caseProductMapping += '{"id": "' + c.Id + '", "label": "' + c.Name + '", "selected": true}, ';
                                             else
                                                 caseProductMapping += '{"id": "' + c.Id + '", "label": "' + c.Name + '"}, ';
                                         }  
        
        // If No Product then return Null, else return all Prod
        if(caseProductMapping.length() == 1)
            return 'null';
        else
            return caseProductMapping.substring(0,caseProductMapping.length()-2) + ']';
        
    }
    
    //Method - 42 : Method to save/update Case Product and policy domain for the case
    @AuraEnabled 
    public static string saveProduct(String caseId, String newProductId, string newPolicyDomainId, string newSituationID){
        
        Case updateCase = new Case(Id = caseId, Case_Product__c = newProductId, Policy_Domain__c = newPolicyDomainId,Case_Situation_Handler__c=newSituationID);
        try{
            update updateCase;
            return 'success';
            
        }catch(Exception e){ return e.getMessage(); }
        
    }


    //------------------------- Start of ESESP-3411: scSoccCaseTask LWC component---------------------------------------
    //Static sort order map for sorting task based on status value
    public static Map<String,integer> sortOrder;
    static 
    {
        sortOrder = new Map<String,integer> ();
        sortOrder.put('In Progress',0);
        sortOrder.put('Not Started',1);
        sortOrder.put('Deferred',2);
        sortOrder.put('Waiting on someone else',3);
        sortOrder.put('Completed Important',4);
        sortOrder.put('Completed',5);
    }

    //TaskWrapper :(Comparable Interface)This class helps to custom sort the activities based on the pre-defined order of Status values
    public class TaskWrapper implements Comparable{
        @AuraEnabled public Id id;
        @AuraEnabled public String idUrl;
        @AuraEnabled public String subject;
        @AuraEnabled public String type;
        @AuraEnabled public Id assignedToId;
        @AuraEnabled public String assignedToName;
        @AuraEnabled public String status;
        @AuraEnabled public String cellColorStyle;
        
            
        // This method returns an integer, that is the result of the comparison
        public Integer compareTo(Object compareTo) {
            TaskWrapper compareToTask = (TaskWrapper)compareTo;
            //if Status value is not present in the map then give higher number. This will avoid null pointer exception
            Integer instanceValue = (sortOrder.containsKey(status) == True) ? sortOrder.get(status) : 999;
            Integer compareToValue = (sortOrder.containsKey(compareToTask.status) == True) ? sortOrder.get(compareToTask.status) : 999;
            return instanceValue - compareToValue;
        }
    }

    //Method 1 - Get list of TraskWrapper records for table data
    @AuraEnabled
    public static List<TaskWrapper> getTaskData(String caseId, String statusFilter, String typeFilter){
        String redColorClass = [SELECT Id, Value_Text__c FROM SC_Utility__mdt WHERE Active__c = true AND DeveloperName = 'Red_Color' LIMIT 1].Value_Text__c;

        List<TaskWrapper> lTask = new List<TaskWrapper>();

        String queryString = 'SELECT Id, Subject, Type__c, OwnerId, Owner.Name, Status FROM Task WHERE WhatId = \'' + caseId + '\'';
        if(statusFilter != null && statusFilter != '' && statusFilter != 'All')
            queryString += ' AND Status = \'' + statusFilter + '\'';
        if(typeFilter != null && typeFilter != '' && typeFilter != 'All')
            queryString += ' AND Type__c = \'' + typeFilter + '\'';
        queryString += ' ORDER BY Status, CreatedDate DESC';

        for(Task eachrec : Database.query(queryString)){
            TaskWrapper taskWrapper = new TaskWrapper();
            taskWrapper.id = eachrec.Id;
            taskWrapper.idUrl = '/' + eachrec.Id;
            taskWrapper.subject = eachrec.Subject;
            taskWrapper.type = eachrec.Type__c;
            taskWrapper.assignedToId = eachrec.OwnerId;
            taskWrapper.assignedToName = eachrec.Owner.Name;
            taskWrapper.status = eachrec.Status;
            if(eachrec.Status == 'In Progress')
                taskWrapper.cellColorStyle = redColorClass;
            lTask.add(taskWrapper);
        }

        lTask.sort();
        return lTask;
    }

    //Method 2 - Assign Task to me
    @AuraEnabled
    public static void assignTask(String taskId){
        Task taskRec = new Task(Id=taskId, Status='In Progress', OwnerId=UserInfo.getUserId());
        update taskRec;
    }

    //Method - 3 : Defer a task
    @AuraEnabled
    public static void deferTask(String taskId, Integer deferValue)
    {
        Task taskRec = [SELECT Id, Status, DueDateProlexic__c FROM Task WHERE Id =:taskId LIMIT 1];
        taskRec.DueDateProlexic__c  = taskRec.DueDateProlexic__c.addHours(deferValue);
        taskRec.Status = 'Deferred';
        update taskRec;
    }

    //Method - 4 : mark a task complete complete
    @AuraEnabled
    public static void completeTask(String taskId)
    {
        Task taskRec = new Task(Id=taskId, Status='Completed');
        update taskRec;
    }

    //------------------------- End of ESESP-3411: scSoccCaseTask LWC component-----------------------------------------

    //Changes for ESESP-6444

    @AuraEnabled
    public static String createTicketPushTask(String taskHr, String caseIdStr) {
        System.debug('Number of Queries used in this apex code so far(line:957) in createTicketPushTask: ' + Limits.getQueries());
        String message;
        System.debug('the ticket push timings hour is : ' + taskHr);
        System.debug('the Case id string is: ' + caseIdStr);
        Id caseId = Id.valueOf(caseIdStr);
        System.debug('the case id is: ' + caseId);
    
        List < Case > lc = [Select Id, isClosed,Solution_Summary__c, Policy_Domain__c,Case_Product__c from Case where Id =: caseId AND RecordType.DeveloperName ='Managed_Security' /*AND isClosed = true*/ limit 1];
        System.debug('the case list size is: '+lc.size());
        if(lc.size() <= 0)
        {
            message='Can not create ticket push task for non-managed security case';
        }
        else if(lc.size() > 0)
        {
            if (lc[0].isClosed == true) {
                message = 'Can not create ticket push task for a closed managed security case';
            } 
            else if((lc[0].Solution_Summary__c==null || lc[0].Policy_Domain__c==null ||lc[0].Case_Product__c==null ))
            {
                message = 'All the mandatory fields are not filled in ';
            }
            else {
                List < Task > ts = [Select Id, Type__c, Status, WhatId from Task where WhatId =: caseId and /*status = 'Deferred'*/ status NOT IN('Completed', 'Completed Important') AND(Type__c = 'Ticket Push 24h' OR Type__c = 'Ticket Push 72h')];
                if (ts.size() > 0) //List size should be always 1
                {
                    message = 'An open 24h/72h Push Task already exists';
                } 
                else {
                    //Check what should be the record type for the Task now it is Standard Activity
                    Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Managed Security Activity').getRecordTypeId();
                    DateTime todayDateTime = DateTime.now();
                    Task newtask = new Task();
                    newtask.WhatId = caseId;
                    newtask.recordTypeId = recordTypeId;
                    newtask.Status = 'Deferred';
                    if (taskHr == '24') {
                        newtask.Type__c = 'Ticket Push 24h';
                        newtask.Subject = 'Ticket Push 24h';
                        newtask.Description = 'If no reply in 24 hours, please close in region';
                        newtask.DueDateProlexic__c = todayDateTime.addHours(24);
                    } else if (taskHr == '72') {
                        newtask.Type__c = 'Ticket Push 72h';
                        newtask.Subject = 'Ticket Push 72h';
                        newtask.Description = 'If no reply in 72 hours, please close in region';
                        newtask.DueDateProlexic__c = todayDateTime.addHours(72);
                    }
            
                    try {
                        insert newtask;
                        //message = 'The ticket push task is created';
                        String status = sendTicketPushEmail(taskHr, caseId);
                        if (status == 'Success') {
                            message = 'The ticket push task is created and email sent successfully';
                        } else if (status == 'Failed') {
                            message = 'Salesforce has encountered an error while sending email for the ticket push task. Please close the task and initiate the ticket push workflow again';
                        } else {
                            message = 'The ticket push task is created. ' + status;
                        }
            
                        //Return success or failure from sendemail method and form the message accordingly
                    } 
                    catch (Exception e) {
                        message = e.getMessage();
                    }
            
                }
            
            }
        }
        
        
        System.debug('Number of Queries used in this apex code so far(line:1023) in createTicketPushTask: ' + Limits.getQueries());
        return message;
    
    }    


    @AuraEnabled
    public static String sendTicketPushEmail(String taskHr, Id caseId) {
        System.debug('Number of Queries used in this apex code so far(line:1031) in sendTicketPushEmail: ' + Limits.getQueries());
        String status;
        System.debug('Inside the sendTicketPushEmail method');
        SC_Utility__mdt mdt1 = SC_Utility__mdt.getInstance('EmailMessage_ManagedSecurityEmailAddress');
        System.debug('the value of metadata is: ' + mdt1);
        System.debug('the value of the value text is :' + mdt1.Value_Text__c);
        String managedSecurityEmail = mdt1.Value_Text__c;
    
        List < String > sendTo = new List < String > ();
        List < String > sendCc = new List < String > ();
        List < String > sendBcc = new List < String > ();
        String mailSubject;
        EmailTemplate emailTemplate = [Select Id, Subject, Description, HtmlValue, DeveloperName, Body from EmailTemplate where Name = 'Ticket Push Task Template' limit 1];
        String tempMailBody = emailTemplate.HtmlValue;
        String mailBody = tempMailBody.replace('{task.hour}', taskHr); /*'The task hour is: '+taskHr+'<br/>'*/
        List < EmailMessage > lEmails = [Select id, MessageDate, ToAddress, CcAddress, FromAddress, BccAddress, Status, Subject, TextBody, HtmlBody, CreatedDate from EmailMessage where ParentId =: caseId and Status != '5' order by MessageDate desc];
    
        if (lEmails.size() > 0) {
    
            //Form additional body
            String fAd;
            List < User > luser;
            if (lEmails[0].FromAddress != null) {
                fAd = lEmails[0].FromAddress;
                luser = [Select Id, FirstName, LastName from User where Email =: fAd limit 1];
            }
    
            String body = '--------------- Original Message ---------------';
            if (luser.size() > 0) {
                body += '<br/>From:' + luser[0].LastName + ',' + luser[0].FirstName + '[' + lEmails[0].FromAddress + ']';
            } else {
                body += '<br/>From:' + lEmails[0].FromAddress + '[' + lEmails[0].FromAddress + ']';
            }
            body += '<br/>Sent:' + (lEmails[0].CreatedDate) /*.formatGMT('MM/dd/yyyy hh:mm')*/ ;
            if (lEmails[0].ToAddress != null) {
                body += '<br/>To:' + lEmails[0].ToAddress;
            }
            if (lEmails[0].CcAddress != null) {
                body += '<br/>Cc:' + lEmails[0].CcAddress;
            }
            body += '<br/>Subject: ' + lEmails[0].Subject;
            mailbody += '<br/><br/>' + body;
            mailBody += '<br/><br/>' + lEmails[0].HtmlBody;
            if (lEmails[0].Status == '3') //Status = 3 = Sent
            {
                mailSubject = lEmails[0].Subject;
                if (lEmails[0].ToAddress != null) {
                    System.debug('The value of lEmails[0].ToAddress: ' + lEmails[0].ToAddress);
                    sendTo = (lEmails[0].ToAddress).split('; ');
                    System.debug('the value of sendTo: ' + sendTo);
                }
                //sendTo.addAll(toAddr);
                if (lEmails[0].CcAddress != null) {
                    System.debug('The value of lEmails[0].CcAddress: ' + lEmails[0].CcAddress);
                    sendCc = (lEmails[0].CcAddress).split('; ');
                    System.debug('the value of sendCc: ' + sendCc);
                }
                if (lEmails[0].BccAddress != null) {
                    System.debug('The value of lEmails[0].BccAddress: ' + lEmails[0].BccAddress);
                    sendBcc = (lEmails[0].BccAddress).split('; ');
                    System.debug('the value of sendBcc: ' + sendBcc);
                }
                System.debug('the size of sendTo list: ' + sendTo.size());
                System.debug('the size of sendCc list: ' + sendCc.size());
                System.debug('the size of sendCc list: ' + sendCc.size());
                if (sendTo.contains(managedSecurityEmail)) {
                    System.debug('the value of sendTo before : ' + sendTo);
                    Integer result = sendTo.indexOf(managedSecurityEmail);
                    sendTo.remove(result);
                    System.debug('the value of sendTo after : ' + sendTo);
    
                }
    
                if (sendCc.contains(managedSecurityEmail)) {
                    System.debug('the value of sendCc before : ' + sendCc);
                    Integer result = sendCc.indexOf(managedSecurityEmail);
                    sendCc.remove(result);
                    System.debug('the value of sendCc after : ' + sendCc);
                }
                if (sendBcc.contains(managedSecurityEmail)) {
                    System.debug('the value of sendBcc before : ' + sendBcc);
                    Integer result = sendBcc.indexOf(managedSecurityEmail);
                    sendBcc.remove(result);
                    System.debug('the value of sendBcc after : ' + sendBcc);
                }
            } 
            else if (lEmails[0].Status == '1') //Status = 1 = Read
            {
                //remove the socc email id from TO or CC if it is there
                for (EmailMessage emsg: lEmails) {
                    if (emsg.Status == '3') {
                        mailSubject = emsg.Subject;
                        break;
                    }
                }
                //String[] strArray = (lEmails[0].Subject).split('Re: Sandbox: '); //Take the subject of Latest Sent email..Iterate over the list
                //mailSubject = strArray[1];
    
                if (lEmails[0].ToAddress != null) {
                    System.debug('The value of lEmails[0].ToAddress: ' + lEmails[0].ToAddress);
                    sendTo = (lEmails[0].ToAddress).split('; ');
                    System.debug('the value of sendTo: ' + sendTo);
                }
                if (lEmails[0].FromAddress != null) {
                    System.debug('The value of lEmails[0].FromAddress: ' + lEmails[0].FromAddress);
                    sendTo.add(lEmails[0].FromAddress);
                    System.debug('the value of sendTo: ' + sendTo);
                }
                if (lEmails[0].CcAddress != null) {
                    System.debug('The value of lEmails[0].CcAddress: ' + lEmails[0].CcAddress);
                    sendCc = (lEmails[0].CcAddress).split('; ');
                    System.debug('the value of sendTo: ' + sendCc);
                }
                if (lEmails[0].BccAddress != null) {
                    System.debug('The value of lEmails[0].BccAddress: ' + lEmails[0].BccAddress);
                    sendBcc = (lEmails[0].BccAddress).split('; ');
                    System.debug('the value of sendBcc: ' + sendBcc);
                }
                if (sendTo.contains(managedSecurityEmail)) {
                    System.debug('the value of sendTo before: ' + sendTo);
                    Integer result = sendTo.indexOf(managedSecurityEmail);
                    sendTo.remove(result);
                    System.debug('the value of sendTo after: ' + sendTo);
                }
    
                if (sendCc.contains(managedSecurityEmail)) {
                    System.debug('the value of sendCc before: ' + sendCc);
                    Integer result = sendCc.indexOf(managedSecurityEmail);
                    sendCc.remove(result);
                    System.debug('the value of sendCc after: ' + sendCc);
                }
                if (sendBcc.contains(managedSecurityEmail)) {
                    System.debug('the value of sendBcc before: ' + sendBcc);
                    Integer result = sendBcc.indexOf(managedSecurityEmail);
                    sendBcc.remove(result);
                    System.debug('the value of sendBcc after: ' + sendBcc);
                }
    
            }
    
            System.debug('sendTo.size() is'+sendTo.size());
            System.debug('sendCc.size() is'+sendCc.size());
            //(1,0) :Email should go
            //(0,1) :Email should go
            //(1,1) :Email should go
            //(0,0) :Email shouldn't go
            //if (sendTo.size() > 0){
            if((sendTo.size() > 0 && sendCc.size() > 0) || (sendTo.size() > 0 && sendCc.size() == 0) || (sendTo.size() == 0 && sendCc.size() > 0)){
                SC_Utility__mdt mdt = SC_Utility__mdt.getInstance('Org_Wide_Address_MS_Ticket_Push');
                System.debug('the value of metadata is: ' + mdt);
                System.debug('the value of the value text is :' + mdt.Value_Text__c);
                String orgEmailId = mdt.Value_Text__c;
                System.debug('the To addresses are: ' + sendTo);
                System.debug('the CC addresses are: ' + sendCc);
                System.debug('the Mail Subject is: ' + mailSubject);
                System.debug('the mail body is: ' + mailbody);
    
                List < Messaging.SingleEmailMessage > emailList = new List < Messaging.SingleEmailMessage > ();
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setOrgWideEmailAddressId(orgEmailId);
                if (sendTo.size() > 0) {
                    email.setToAddresses(sendTo);
                }                
                if (sendCc.size() > 0) {
                    email.setCcAddresses(sendCc);
                }
                if (sendBcc.size() > 0) {
                    email.setBccAddresses(sendBcc);
                }
                email.setSubject(mailSubject);
                email.setHtmlBody(mailbody);
                email.setWhatId(caseId);
                emailList.add(email);
    
                if (!Test.isRunningTest()) {
                    try {
                        Messaging.sendEmail(emailList);
                        status = 'Success';
                    } 
                    catch (Exception e) {
                        System.debug('The system thrown exception is '+e.getMessage());
                        status = 'Failed';
                    }
                }
            }
            else {
                status = 'We could not send the ticket push email as there is missing To and Cc address on existing email on this case.';
            }
        } 
        else {
            status = 'We could not send the ticket push email as there is no existing email on this case.';
        }
        System.debug('Number of Queries used in this apex code so far(line:1215) in sendTicketPushEmail: ' + Limits.getQueries());
        return status;
    }
}