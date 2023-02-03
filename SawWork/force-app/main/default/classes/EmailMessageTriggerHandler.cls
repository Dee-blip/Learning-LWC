/*********************************************************************************************************
Name         :   EmailMessageTriggerHandler
Author       :   Vinod Kumar (Appirio Offshore)
Test Class   :   TestEmailMessageTriggerHandler

Last Modified BY       Last Modified Date      Purpose
----------------       ------------------      ---------
Vinod-Appirio          04-Jun-13               Initial Dev(T-148640)
Himanshu               25-Mar-14               To Handle Exceptions(Release - 3.40) 
Himanshu               25-Jun-14               Code Optimization(Release - 3.43)    
JAy                    19-Feb-15               CR:2773452: Validation override flag
Akhila                 20-Mar-15               CR 2907264 - By passing Case's RecentUPdate flag update for emails with fromaddr=Case.OwnerEmail
Akhila                 20-May-15               CR 2954540 - Case should change status to "In Progress" after IR is sent 
Himanshu               12-Nov-15               CR - 3194331(4.13) - Update Task Type = Email for Outgoing Emails
Himanshu               14-Dec-15               CR - 3177151(4.14) - Set MilestoneFire = First Update for case Object. Modified Method = setRecentUpdateOnCaseTrue
Himanshu               14-Feb-16               CR - 3200701(16.2)  - Set MilestoneFire = Case Update for case Object. Modified Method = UpdateCaseResolutionSent,setRecentUpdateOnCaseTrue
- Optimized all the Methods
Deepak Saxena          02-Feb-16               CR - 3287751 (16.2) - Set Validation Override True for Cases so that it doesn't through an error
Aditya Sonam           03-Dec-2015             CR 3308991,3307861,3239211: Project MS Azure
Himanshu Kar           17-JUN-2016             3333321(16.6)     Update BOCC Custom setting
Vamsee                 23-Feb-2018             ESESP-1011: Pause/Resume the SLA Clock for Carrier Product
Pinkesh                21-Jan-2019             ESESP-1602: (Akatec Lightning Migration)Set "Resolution Sent" checkbox to TRUE, when an email from @akamai.com address is sent with the phrase "Resolution Summary" in the subject.
Pinkesh                04-Mar-2019             ESESP-2069: Set Resolution Sent to TRUE when emails are sent from outlook as well.
Vishnu                 02-Jul-2019             ESESP-758: Update milestone query to include new AMG milestone - AMG Post Initial Response
Vandhana        		24-Feb-2020 		    ESESP-3194 : Added logic to populate Last Case Owner and Non Case Owner Update for AMG cases
Sharath                 07-Dec-2020             ESESP-4435: Cross-Share validation
Vandhana                20-02-2021              ESESP-2346 Carrier LX Migration
Vamsee					24-May-2021				ESESP-5305: mark Isstopped = False before completing the milestone
Aravind                 27-May-2021             ESESP-5210: Disabled updation of Last Customer Update field when SOCC case email is sent from managed security email address
Jay                     29-Dec-2021             ESESP-5526  Added emailToCNS method which sends outgoing email message to CNS subscribers
Sheena					07-Jan-2021				ESESP-6229: Update Task LOE on Managed Security Case with default Email Template values
Sharath					21 Feb 2022				ESESP-6716: jarvis Global Beta: Bypassing Milestone Logic
Sheena                  24-Feb-2022             ESESP-5143: Enable 'Internal Case Survey Enabled' field on Case on Customer Email from Owner and based on Case Criteria 
Tejaswini               20-Apr-2022             ESESP-6444: Salesforce automation for case closure - SOCC
*******************************************************************************************************/
public with sharing class EmailMessageTriggerHandler {
    
    // Function to update the Case.Resolution Sent checkbox and case Milestone with name Initial Response = Completed.
    // Related task: T-148640, T-148455
    
    //By Pass Initial Response Update for SOCC. This Variable is set from Casetrigger_ai
    public static boolean byPassIRUpdateSOCC = false;
    public static Boolean flagSendEmailToCNS = false;

    //Changes by Sharath for Jarvis
    public static boolean bypassMilestoneClosure = false;
    
    public static void UpdateCaseResolutionSent(list<EmailMessage> lstMessages, Map<Id, Case> caseMap){
        
        // List to store Case Id for - Email body which contains RESNOT
        set<ID> caseIDForUpdatingCase = new set<ID>();
        
        // List to store Case Id for - Milestones to be updated
        set<ID> caseIDForCompleteCaseMilestone = new set<ID>();
        
        // List of Task for Update
        List<Task> updateableTasks = new List<Task>();
        
        // List of case for Update
        List<Case> lstCasesForUpdate = new list<Case>();
        
        //asonam:Stores case id realted to MS Azure
        Set<Id> isMicrosoftCaseSet = new Set<Id>();
        
        //asonam:Added as part of MS Azure to avoid task Validation while sending email
        for(case forcase : caseMap.values()){
            if(forcase.IsMicrosoftAzureAccount__c == true && forcase.Partner_Joint_Troubleshooting_Status__c == 'open'){
                isMicrosoftCaseSet.add(forcase.Id);
            }        
        }
        
        for (EmailMessage em : lstMessages){
            string strParenTID = em.ParentId;
            
            if(strParenTID != null && strParenTID.startsWith('500') )
            {    
                // Scenario-1 : Checking if it is Outgoing Email and Body contains RESNOT in body or 'Resolution Summary' in Subject Line
                if(em.FromAddress.containsIgnoreCase('@akamai.com') && ((em.TextBody != null && em.TextBody.containsIgnoreCase('Type: RESNOT')) || (em.Subject != null && em.Subject.containsIgnoreCase('Resolution Summary'))))
                {    
                    // store id to update the case Resolution_Sent__c
                    caseIDForUpdatingCase.add(em.ParentId);
                }
                
                // Scenario-2 : If From Add = @akamai.com and at least one ToAdd != @akamai.com
                if(em.FromAddress.contains('@akamai.com') && em.ToAddress != null && em.ToAddress != '' &&
                   !(em.ToAddress.containsIgnoreCase('nocc@akamai.com') || em.ToAddress.containsIgnoreCase('nocc-tix@akamai.com') || em.ToAddress.containsIgnoreCase('nocc-shift@akamai.com') ||
                     (em.ccAddress != null && em.ccAddress != '' && (em.ccAddress.containsIgnoreCase('nocc@akamai.com') || em.ccAddress.containsIgnoreCase('nocc-tix@akamai.com') || em.ccAddress.containsIgnoreCase('nocc-shift@akamai.com')))))
                {         
                    for(string varToAddress: em.ToAddress.split(';'))
                    {    
                        if(!varToAddress.containsIgnoreCase('@akamai.com'))
                        {    
                                 // store id to  updatye the casemilestone to complete
                                 caseIDForCompleteCaseMilestone.add(em.ParentId);
                             }
                         }
                     }    
                
                // Scenario-3 : If From Add = @akamai.com and at least one CCAdd != @akamai.com
                if(em.FromAddress.contains('@akamai.com') && em.ccAddress != null && em.ccAddress != '' && 
                   !((em.ToAddress != null && em.ToAddress != '' && (em.ToAddress.containsIgnoreCase('nocc@akamai.com') || em.ToAddress.containsIgnoreCase('nocc-tix@akamai.com') 
                                                                     || em.ToAddress.containsIgnoreCase('nocc-shift@akamai.com'))) ||
                     em.ccAddress.containsIgnoreCase('nocc@akamai.com') || em.ccAddress.containsIgnoreCase('nocc-tix@akamai.com') || em.ccAddress.containsIgnoreCase('nocc-shift@akamai.com')))
                {
                                 
                    for(string varCCAddress: em.ccAddress.split(';'))
                    {    
                        if(!varCCAddress.containsIgnoreCase('@akamai.com'))
                        {    
                                 // store id to  updatye the casemilestone to complete
                                 caseIDForCompleteCaseMilestone.add(em.ParentId);
                             }
                         }
                     }
                
                /* Commenting it out as part of CR 3239211,Modified Code is below with Visibility field Logic 
                // Scenario-4 : If it is outgoing Email,
                if(em.Incoming == false && em.ActivityId != null) {
                
                updateableTasks.add(new Task(id = em.ActivityId,
                Type__c = 'Email', 
                Internal_Only__c = EmailToCaseUtility.isInternalActivity(em.FromAddress, em.ToAddress != null ? em.ToAddress : '', em.CcAddress != null ? em.CcAddress : ''))); 
                }
                */
                
                //asonam: to incorporate the new visibility and internal only field logic as part of MS Azure
                if(em.Incoming == false && em.ActivityId != null) 
                {
                    if(EmailToCaseUtility.isInternalActivity(em.FromAddress, em.ToAddress != null ? em.ToAddress : '', em.CcAddress != null ? em.CcAddress : '')){
                        updateableTasks.add(new Task(id = em.ActivityId, Internal_Only__c = True, Visibility__c = 'Internal Only',Type__c = 'Email'));
                    }
                    else if(strParenTID != null && strParenTID.startsWith('500') && !isMicrosoftCaseSet.isEmpty() && isMicrosoftCaseSet.contains(strParenTID) 
                            && EmailToCaseUtility.isPartnerActivity(em.FromAddress, em.ToAddress != null ? em.ToAddress : '', em.CcAddress != null ? em.CcAddress : '')){
                                
                                updateableTasks.add(new Task(id = em.ActivityId, Internal_Only__c = True, Visibility__c = 'Partner Only',Type__c = 'Email'));
                            }
                    else
                    {
                        updateableTasks.add(new Task(id = em.ActivityId, Internal_Only__c = False, Visibility__c = 'Customer',Type__c = 'Email'));
                    }     
                }     
            }
        }  // End of For Loop  
        
        
        // For Each Case Record from Map
        Case caseUpdate;
        
        // Setting Case Update List
        for(Id eachCaseId : caseMap.keyset())
        {    
            // Getting Case
            caseUpdate = caseMap.get(eachCaseId);
            caseUpdate.Validation_Override__c = True;
            
            // Criteria-1 : For Checking Case for Resolution Flag
            if(caseIDForUpdatingCase.contains(eachCaseId))
            {    
                caseUpdate.Validation_Override__c = true;//Added by Aditi for ESESP-5229
                caseUpdate.Resolution_Sent__c = true;
                lstCasesForUpdate.add(caseUpdate);
            }
        }
        
        // Setting Milestone Update List
        if(caseIDForCompleteCaseMilestone.size() > 0)
        {    
            // get the selected case's Milestone
            list<CaseMilestone> lstCaseMilestoneForUpdate = new list<CaseMilestone>();
            
            //Set of Case Ids to mark isstopped = False (ESESP-5305)
            Set<Id> caseIdSet = new Set<Id>();
            
            // Fetching the Current Milestone for Updating Completion Date
            // ESESP-758: added condition to include AMG Post Transition Milestone
            // Vamsee : ESESP-1342: Add condition to include Technical (BOCC) Milestone - Customer Notification
            for(CaseMilestone csMilestone: [Select MilestoneType.Name, Id, CompletionDate, Case.Id, Case.Isstopped From CaseMilestone  
                                            where CaseId in:caseIDForCompleteCaseMilestone and 
                                            IsCompleted = false and 
                                            MilestoneType.Name IN ('Initial Response','AMG Post Transition Initial Response','First Update', 'Case Update','Time to Respond','Time to Alert', 'Customer Notification') and
                                            case.IsClosed = false])
            {
                                                
                                                csMilestone.CompletionDate = DateTime.now();
												lstCaseMilestoneForUpdate.add(csMilestone);
                                                if(csMilestone.Case.Isstopped == True){
                                                    caseIdSet.add(csMilestone.Case.Id);
                                                }
                                            }
            if(caseIdSet.size() > 0){
                List<Case> caseListforUpdate = new List<Case>();
                Case eachCase;
                for(Id eachId : caseIdSet){
                    eachCase = new Case();
                    eachCase.Id = eachId;
                    eachCase.Validation_Override__c = True;
                    eachCase.IsStopped = False;
                    caseListforUpdate.add(eachCase);
                }
                Update caseListforUpdate;
            }
            
            if(lstCaseMilestoneForUpdate.size() > 0)
            {
                update lstCaseMilestoneForUpdate;               
            }
        }
        
        // For Updating Tasks
        if(updateableTasks.size() > 0) {
            update updateableTasks;
        }
        
        // For Updating Cases
        if(lstCasesForUpdate.size() > 0){
            update lstCasesForUpdate;               
        }
    }
    
    /*
    * Name      : setRecentUpdateOnCaseTrue
    * Purpose : For inbound Email, set the below fields
    Case.Recent_Update__c = true 
    Case.Last_Customer_Activity_Date__c = Now
    
    For Outbound Email, set below fields
    Case.Last_Case_Update__c = Now 
    */
    public static void setRecentUpdateOnCaseTrue(Map<EmailMessage,Boolean> scEmailsforRecentUpdate, Map<Id, Case> caseMap) 
    {    
        System.debug('£££ ' + scEmailsforRecentUpdate + ' ££££ ' + caseMap);
        // Set to store Unique Case Ids
        Set<Id> recentUpdatedCaseIds = new Set<Id>();
        
        // List of cases for Update
        List<Case> caseLst = new List<Case>();
        
        // For Individual Case
        Case cs;
        
        String amgFromEmailAddress = [SELECT Value_Text__c FROM SC_Utility__mdt
                                      WHERE DeveloperName = 'AMG_From_Email_Address' AND Active__c = TRUE].Value_Text__c;
        
        String amgEmail2CaseUserName =  [SELECT Value_Text__c FROM SC_Utility__mdt
                                         WHERE DeveloperName = 'AMG_Email2Case_User_Name' AND Active__c = TRUE].Value_Text__c;
        
        
        //Collect the incoming emails' CaseIds
        for(EmailMessage em : scEmailsforRecentUpdate.keySet()) 
        {
            // Getting the Related Case and setting Override Flag
            cs = caseMap.get(em.ParentId);
            cs.Validation_Override__c = true; 
            
            // Checking if Parent Object = Case
            if(String.valueOf(em.ParentId).startsWith('500') && cs != null && !cs.Isclosed) 
            {
                // Checking if it is Incoming Email, else outgoing Email
                if(em.Incoming == true) 
                {
                    // For Setting Recent Update Flag
                    if(scEmailsforRecentUpdate.get(em) && cs.RecordType.Name != 'Managed Security') //ByPassing MS Cases - ESESP-2698
                        cs.Recent_Update__c = true;
                    //Setting static variable to byPass method updateRecentUpdateFlag_SOCC in SC_CaseIssueClass for Managed Security Case
                    if(cs.RecordType.Name == 'Managed Security')
                        SC_CaseIssueClass.byPassCaseIssueRUSOCC = true;
                    
                    // For Setting Last Customer Activity Date  
                    if(!em.FromAddress.contains('@akamai.com'))
                    {
                        cs.Last_Customer_Activity_Date__c = Datetime.now();
                        cs.Next_Action__c = 'Case Owner';
                    }   
                } 
                
                //For outgoing Email(Answer Customer) + Incoming Email(Sending from Outlook)
                if (em.FromAddress.containsIgnoreCase('@akamai.com'))
                {    
                    //List to store all the Email Addresses
                    List<String> allEmailAddress = new List<String>();
                    
                    //Add all TO Addresses
                    if(String.isNotBlank(em.ToAddress)){                
                        allEmailAddress.addAll(em.ToAddress.split(';'));
                    }
                    
                    //Add all CC Addresses
                    if(String.isNotBlank(em.ccAddress))
                        allEmailAddress.addAll(em.ccAddress.split(';'));
                    
                    //Checking if atleast one of TO/CC Address is a non-akamai address(Customer address)
                    if(allEmailAddress.size() > 0)
                    {
                        for(string eachEmailAddress: allEmailAddress)
                        {
                            if(!eachEmailAddress.containsIgnoreCase('@akamai.com'))
                            {
                                cs.Last_Case_Update__c = Datetime.now();
                                if(cs.RecordTypeId == Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('AMG').getRecordTypeId())
                                {
                                    if(UserInfo.getUserId() == cs.OwnerId 
                                       || (String.valueOf(cs.OwnerId).startsWith(Schema.SObjectType.User.getKeyPrefix()) &&
                                           String.isNotBlank(cs.Case_Owner_Email_address__c) &&
                                           em.FromAddress.containsIgnoreCase(cs.Case_Owner_Email_address__c))	
                                      )
                                    {
                                        cs.Last_Case_Owner_Update__c = DateTime.now();
                                        
                                    }
                                    else
                                    {
                                        if(em.FromAddress.equalsIgnoreCase(amgFromEmailAddress))
                                        {
                                            if(UserInfo.getName() != amgEmail2CaseUserName)
                                                cs.Last_Non_Case_Owner_Update__c = DateTime.now();
                                        }
                                        else 
                                        {
                                            cs.Last_Non_Case_Owner_Update__c = DateTime.now();
                                        }
                                    }
                                    
                                    System.debug('Last Case Owner Update : ' + cs.Last_Case_Owner_Update__c);
                                    System.debug('Last NON Case Owner Update : ' + cs.Last_Non_Case_Owner_Update__c);
                                }
                                
                                // changes by Vandhana for Carrier LX Migration
                                if(cs.RecordType.Name == 'Technical' && cs.Sub_Type__c == 'Carrier')
                                {
                                    cs.Status = (cs.Status != 'Unassigned') ? 'Work in Progress' : cs.Status;
                                    cs.IsStopped = true;
                                    cs.Next_Action__c = 'Customer';
                                }
                                else
                                {
                                    cs.Status = (cs.Status == 'Assigned') ? 'Work in Progress' : cs.Status;
                                }
                                break;
                            }
                        }
                        allEmailAddress.clear();
                    }
                }
                
                if(recentUpdatedCaseIds.add(cs.Id)){
                    caseLst.add(cs);
                }
                
            } // End of IF - For Case Object
            
        } // End of For Loop
        
        caseUpdateForIR(recentUpdatedCaseIds);
        if(caseLst.size() > 0) {
            update caseLst;
        }
        
    }
    
    public static void handleRecentUpdateforMSCase(List<Case> MSCasesforRecentUpdate)
    {
        //Construct a Map of Case and Email Messages where incoming = ture
        Map<Id,List<EmailMessage>> CaseEmailMessageMap = new Map<Id,List<EmailMessage>>();
        
        //Final Case Update List
        List<Case> FinalRUCaseUpdateList = new List<Case>();
        
        //Query all Email Messages
        List<EmailMessage> RelEmailMessage = [Select Subject,ParentId from EmailMessage where Incoming=true and ParentId in:MSCasesforRecentUpdate];
        
        //Populate Map
        if(RelEmailMessage.size()>0)
        {
            for(EmailMessage em:RelEmailMessage)
            {
                if(CaseEmailMessageMap.get(em.ParentId)!=null)
                {
                    List<EmailMessage> TempHolder = CaseEmailMessageMap.get(em.ParentId);
                    TempHolder.add(em);
                    CaseEmailMessageMap.put(em.ParentId,TempHolder);
                }
                else
                {
                    CaseEmailMessageMap.put(em.ParentId,new List<EmailMessage>{em});
                }
            }
        }
        //Check Size and prepare update list Map
        if(CaseEmailMessageMap.size()>0)
        {
            for(Id id:CaseEmailMessageMap.keyset())
            {
                If(CaseEmailMessageMap.get(id).size()==1)
                {
                    Case varCase = new Case(Id=id);
                    varCase.Recent_Update__c=false;
                    FinalRUCaseUpdateList.add(varCase);
                }
            }
        }
        if(FinalRUCaseUpdateList.size()>0)
        {
            update FinalRUCaseUpdateList;
        }
    }
    
    public static void handleRecentUpdateforMSCaseOutbound(List<EmailMessage> scEmails,Map<Id, Case> MSCasesforRecentUpdateOutboundMap,String caseType)	
    {	
        // List of cases for Update	
        List<Case> caseLst = new List<Case>();	
        	
        for(EmailMessage em:scEmails)	
        {	
            Case cs = MSCasesforRecentUpdateOutboundMap.get(em.ParentId);	
            if(String.valueOf(em.ParentId).startsWith('500') && cs != null)	
            {	
                if(em.Incoming==false)	
                {	
                    if(caseType == 'Managed Security')	
                    	cs.Recent_Update__c = false;	
                    else if(caseType == 'Professional Services')	
                        cs.Plx_Update__c = false;	
                    caseLst.add(cs);	
                }	
            }	
        }	
        if(caseLst.size()>0)	
        {	
            update caseLst;	
        }	
    }
    
    //Method to handle Recent Update for Inbound Emails MS	
    public static void handleRecentUpdateforMSCaseInBound(List<EmailMessage> scEmails,Map<Id, Case> msCasesforRecentUpdateInboundMap, String caseType)	
    {	
        	
        String managedSecurityEmail = [SELECT Value_Text__c FROM SC_Utility__mdt
                                       WHERE DeveloperName = 'EmailMessage_ManagedSecurityEmailAddress'
                                       AND Active__c = true].Value_Text__c;
        //List of Cases for Update	
        List<Case> caseList = new List<Case>();	
        for(EmailMessage varEmail:scEmails)	{
            	
            Case varCase = msCasesforRecentUpdateInboundMap.get(varEmail.ParentId);
            if(varEmail.Incoming && varCase!=null 
                && String.valueOf(varEmail.ParentId).startsWith('500')){
                if (caseType == 'Managed Security'){
                    //Changes for ESESP-6444	
					if((varEmail.FromAddress.contains('@akamai.com') || !varEmail.FromAddress.contains('@akamai.com')) && varEmail.FromAddress != managedSecurityEmail)
                    {
                        System.debug('the changes for ESESP-6444');
                        List<Task> lTask = [Select Id,Type__c,Status,WhatId,CreatedDate from Task where /*status = 'Deferred'*/ status NOT IN ('Completed','Completed Important') and (Type__c='Ticket Push 24h' or Type__c='Ticket Push 72h') and WhatId=:varCase.Id limit 1];
                        System.debug('Outside the if block');
                        System.debug('the size of listTask is: '+lTask.size());
                        if(lTask.size()>0)
                        {
                            System.debug('Inside the if block');
                            System.debug('The Task type is: '+lTask[0].Type__c);
                            if(lTask[0].Type__c=='Ticket Push 24h' || lTask[0].Type__c=='Ticket Push 72h'){
                                lTask[0].Status='Completed';
                            }
                            update lTask;
                        }
                    }
                    //End of Changes	
                    if(!varEmail.FromAddress.contains('@akamai.com')){	
                        varCase.Recent_Update__c = true;                    	
                    }                
                if(varEmail.FromAddress.contains('@akamai.com') && varEmail.FromAddress != managedSecurityEmail){	
                    //Socc non socc check	
                    //Call a method that returns a Map of Case Id,Boolean.The Boolean is set to true if incoming email id belongs to Non-SOCC	
                    Map<String,Boolean> soccNonSoccMap = isSOCCNONSOCC(scEmails,msCasesforRecentUpdateInboundMap);
                        if(soccNonSoccMap.get(varCase.Id)!=null && soccNonSoccMap.get(varCase.Id)==true){	                           
                            varCase.Recent_Update__c = true;	
                            varCase.Last_Customer_Activity_Date__c = Datetime.now();	                            	
                            //caseList.add(varCase);   	
                        }	                                                	
                        else{	                            
                            varCase.Last_Case_Update__c = Datetime.now();	
                            //caseList.add(varCase);	
                        }	
                    }	
                }
                if (caseType == 'Professional Services'){
                    //Call a method that returns a Map of Case Id,Boolean.The Boolean is set to true if incoming email id belongs to Non-PS	
                    Map<String,Boolean> psNonpsMap = isPSNONPS(scEmails,msCasesforRecentUpdateInboundMap);
                    if(!varEmail.FromAddress.contains('@akamai.com') || 
                        (varEmail.FromAddress.contains('@akamai.com') && psNonpsMap.get(varCase.Id)!=null 
                        && psNonpsMap.get(varCase.Id) )){
                        varCase.Plx_Update__c = true;
                    }                    
                }
                caseList.add(varCase);
            }
        }
            /*if(String.valueOf(varEmail.ParentId).startsWith('500') && varCase!=null)	
            {	
                if(varEmail.Incoming==true)	
                {	
                    //Check if Incoming emails from address is non akamai	
                    if(!varEmail.FromAddress.contains('@akamai.com'))	
                    {	
                        if(caseType == 'Managed Security')	
                    		varCase.Recent_Update__c = true;	
                    	else if(caseType == 'Professional Services')	
                        	varCase.Plx_Update__c = true;	
                        caseList.add(varCase);	
                    }	
                    	
                    //If Incoming Email From Address is akamai,Run a Socc vs non socc check	
                    if(varEmail.FromAddress.contains('@akamai.com'))	
                    {	
                        //Socc non socc check	
                        if(soccNonSoccMap.get(varCase.Id)!=null && soccNonSoccMap.get(varCase.Id)==true)	
                        {	
                            if(caseType == 'Managed Security'){	
                                varCase.Recent_Update__c = true;	
                            	varCase.Last_Customer_Activity_Date__c = Datetime.now();	
                            }	
                    		else if(caseType == 'Professional Services')	
                        		varCase.Plx_Update__c = true;	
                            	
                            caseList.add(varCase);   	
                        }	
                        //Ps non Ps check	
                        else if(psNonpsMap.get(varCase.Id)!=null && psNonpsMap.get(varCase.Id)==true)	
                        {	
                            if(caseType == 'Managed Security'){	
                                varCase.Recent_Update__c = true;	
                            	varCase.Last_Customer_Activity_Date__c = Datetime.now();	
                            }	
                    		else if(caseType == 'Professional Services')	
                        		varCase.Plx_Update__c = true;	
                            	
                            caseList.add(varCase);   	
                        }	
                        else	
                        {	
                            if(caseType == 'Managed Security')	
                            	varCase.Last_Case_Update__c = Datetime.now();	
                            caseList.add(varCase);	
                        }	
                    }	
                }	
            }
        }*/
        	
        if(CaseList.size()>0)	
        {	
            if(caseType == 'Managed Security' || caseType == 'Professional Services'){	
                SC_CaseIssueClass.byPassCaseIssueRUSOCC = true;//Static variable to bypass recent update code block in SC_CaseIssueClass	
            }	
            	
            update caseList;	
        }	
    }
    
    //Method to calculat SOCC/Non-SOCC 
    public static Map<String,Boolean> isSOCCNONSOCC(List<EmailMessage> scEmails,Map<Id, Case> msCasesforRecentUpdateInboundMap)
    {
        //Map to be returned
        Map<String,Boolean> soccNonSoccMap = new Map<String,Boolean>();
        Id msProfileId = [SELECT DeveloperName,Value_Text__c FROM SC_Utility__mdt WHERE DeveloperName ='Managed_Security_Profile_Id' limit 1].Value_Text__c;
        //Get a list of all emails corresponding to Managed Security
        List<String> EmailSet = new List<String>();
        for(User eachUser:[Select Email from User where ProfileId =: msProfileId and isactive=true])
        {
            EmailSet.add(eachUser.Email);
        }
        
        for(EmailMessage varEmailMessage:scEmails)
        {
            if(varEmailMessage.FromAddress.contains('@akamai.com'))
            {
                if(!EmailSet.contains(varEmailMessage.FromAddress))
                {
                    soccNonSoccMap.put(varEmailMessage.ParentId,true);
                }
            }
        }
        return soccNonSoccMap;
    }
    
    //Changes by Vikas for Provisioning : Method to calculat PS/Non-PS 	
    public static Map<String,Boolean> isPSNONPS(List<EmailMessage> scEmails,Map<Id, Case> msCasesforRecentUpdateInboundMap)	
    {	
        //Map to be returned	
        Map<String,Boolean> psNonPsMap = new Map<String,Boolean>();	
        String excludeProfiles = [SELECT DeveloperName,Value_Text__c	
                                              FROM SC_Utility__mdt	
                                              WHERE DeveloperName IN ('Plx_Exclude_PS_Profile') limit 1].Value_Text__c;	
        //List<String> excludeProfileList = excludeProfiles.split(',');
        List<String> lProfilesToExclude = excludeProfiles.split(',');
        List<String> lFromEmailIds = new List<String>();
        //Get a list of all emails corresponding to PS
        for (EmailMessage varEmailMessage: scEmails) {
            lFromEmailIds.add(varEmailMessage.FromAddress);
        }	
        //List<String> EmailSet = new List<String>();	
        Set<String> sUsersToExclude = new Set<String>();
        for(User eachUser:[SELECT Email, Profile.Name FROM User where Email IN:lFromEmailIds AND Profile.Name IN :lProfilesToExclude]){	
            sUsersToExclude.add(eachUser.Email);	
        }	
        	
        for(EmailMessage varEmailMessage:scEmails)	
        {	
            if(!sUsersToExclude.contains(varEmailMessage.FromAddress)){	
                psNonPsMap.put(varEmailMessage.ParentId,true);	
            }	            
        }	
        return psNonPsMap;	
    }	
	//End of Changes by Vikas for Provisioning : Method to calculat PS/Non-PS 
    
    // Method for Updating Case with Initial_Response_Date__c - Only for SOCC (SOCC Lightning Migration)
    public static void caseUpdateForIR(set<ID> uniqueCaseIds){
        
        // Getting Managed Sec Recordtype Id
        Id recIdManagedSec = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Managed Security').getRecordTypeId();
        
        // List to Update Cases
        List<Case> updateCaseList = new List<Case>();
        
        // Query to get All Cases . If IR date is null then set it to current time as we will stamp only first time
        for(Case eachCaserec : [select Id,Initial_Response_Date__c from Case where 
                                ID=:uniqueCaseIds and 
                                RecordtypeId = :recIdManagedSec and 
                                Initial_Response_Date__c = null]){
                                    
                                    system.debug('----byPassIRUpdateSOCC---'+ EmailMessageTriggerHandler.byPassIRUpdateSOCC);
                                    if(EmailMessageTriggerHandler.byPassIRUpdateSOCC == false){
                                    eachCaserec.Initial_Response_Date__c = system.now();
                                    updateCaseList.add(eachCaserec);
                                }
                                }
        
        if(updateCaseList.size() > 0) {
            SC_CaseIssueClass.byPassCaseIssueRUSOCC = true;//Static variable to bypass recent update code block in SC_CaseIssueClass
            update updateCaseList;
        }
    }
    
    //Method for SOCC Metrics Calculation
    public static void CalculateSOCCMetrics(Map<EmailMessage,Case> IncomingMap)
    {
        //Final List of Cases to Update
        List<Case> FinalUpdateList = new List<Case>();
        
        
        Map<Id,Case> SOCCIRCaseMap   = new Map<Id,Case>(); //Collect Cases for IR
        Map<Id,Case> SOCCFUCaseMap   = new Map<Id,Case>(); //Collect Cases for First Update
        
        for(Case C:IncomingMap.Values())
        {
            if(C.Initial_Response_SOCC__c==null)
            {
                SOCCIRCaseMap.put(C.Id,C);
            }
            else if(C.Initial_Response_SOCC__c!=null && C.First_Customer_Update_SOCC__c==null)
            {
                SOCCFUCaseMap.put(C.Id,C);
            }
        }
        
        if(SOCCIRCaseMap.size()>0)
        {
            List<Case> SOCCIRCasetoUpadate = CalculateSOCCIRMetrics(SOCCIRCaseMap,IncomingMap);   
            FinalUpdateList.addAll(SOCCIRCasetoUpadate);
        }
        if(SOCCFUCaseMap.size()>0)
        {
            List<Case> SOCCFUCasetoUpadate = CalculateSOCCFUMetrics(SOCCFUCaseMap,IncomingMap);   
            FinalUpdateList.addAll(SOCCFUCasetoUpadate);
        }
        
        //Final Update Call
        if(FinalUpdateList.size()>0)
        {
            Update FinalUpdateList;
        }
    }
    
    //Calculate SOCC IR Metrics
    public static List<Case> CalculateSOCCIRMetrics(Map<Id,Case> SOCCIRCaseMap,Map<EmailMessage,Case> IncomingMap)
    {
        List<Case> CasetoUpdateSOCCIR = new List<Case>();
        
        for(EmailMessage em:IncomingMap.KeySet())
        {   
            
            If(SOCCIRCaseMap.Keyset().contains(em.ParentId))
            {
                Case varCase=IncomingMap.get(em);
                If(varCase.Origin=='Email' || (varCase.Origin=='Web' && ((varCase.CreatedBy.Name=='Pulsar Case Mgmt') || (varCase.CreatedBy.Name=='Luna Case Mgmt'))))
                {
                    Long seconds = (em.MessageDate.getTime()- varCase.CreatedDate.getTime())/1000;
                    varCase.Initial_Response_SOCC__c = DateTime.valueOf(seconds*1000).formatGMT('HH:mm:ss');
                    varCase.Initial_Response_SOCC_Date__c  = System.now();
                    CasetoUpdateSOCCIR.add(varCase);
                }
                If(varCase.Origin=='Web' && varCase.CreatedBy.Name=='Mako Application')
                {
                    if(varCase.Alert_Start_Time__c!=null)
                    {
                        Long seconds = (em.MessageDate.getTime()- varCase.Alert_Start_Time__c.getTime())/1000;
                        varCase.Initial_Response_SOCC__c = DateTime.valueOf(seconds*1000).formatGMT('HH:mm:ss');
                        varCase.Initial_Response_SOCC_Date__c  = System.now();
                        CasetoUpdateSOCCIR.add(varCase);
                    }
                }
            }
            
        }
        return CasetoUpdateSOCCIR;
    }
    
    //Calculate SOCC FirstUpdate Metrics
    public static List<Case> CalculateSOCCFUMetrics(Map<Id,Case> SOCCFUCaseMap,Map<EmailMessage,Case> IncomingMap)
    {
        List<Case> CasetoUpdateSOCCFU = new List<Case>();
        for(EmailMessage em:IncomingMap.KeySet())
        {
            If(SOCCFUCaseMap.Keyset().contains(em.ParentId))
            {
                Case varCase=IncomingMap.get(em);
                Long seconds = (em.MessageDate.getTime()- varCase.Initial_Response_SOCC_Date__c.getTime())/1000;
                varCase.First_Customer_Update_SOCC__c  = DateTime.valueOf(seconds*1000).formatGMT('HH:mm:ss');
                CasetoUpdateSOCCFU.add(varCase);
            }
            
        }
        return CasetoUpdateSOCCFU;
    }
    //Changes by Sharath for ESESP-4435: Method to parse through the email addresses value from a message record
    public static Set<String> getAddressFromEmail(EmailMessage emailMessageRec)
    {
        Set<String> addresses = new Set<String>();
        String emailAddresses = !String.isBlank(emailMessageRec.toAddress)?emailMessageRec.toAddress : '';
        emailAddresses += !String.isBlank(emailMessageRec.ccAddress)?
            emailAddresses.length() > 0? ';' + emailMessageRec.ccAddress : emailMessageRec.ccAddress 
                : '';
        emailAddresses += !String.isBlank(emailMessageRec.bccAddress)?
            emailAddresses.length() > 0? ';' + emailMessageRec.bccAddress : emailMessageRec.bccAddress 
                : '';
        emailAddresses += !String.isBlank(emailMessageRec.FromAddress)?
            emailAddresses.length() > 0? ';' + emailMessageRec.FromAddress : emailMessageRec.FromAddress 
                : '';
                
        if(!String.isBlank(emailAddresses))
        {
            for(String emailAddress: emailAddresses.split(';'))
            {
                if(!emailAddress.contains('@akamai.com'))
                {
                    addresses.add(emailAddress.trim());
                }
            }
        }
        
        return addresses;
    }
    //Changes by Sharath for ESESP-4435: Method to validate the email message record
    public static void validateEmailMessageRecords(Map<Id,Case> caseMapForValidation,List<EmailMessage> emRecords)
    {
        Map<Id,Set<String>> accountToValidEmails = new Map<Id,Set<String>>();
        Map<Id,Set<String>> emailToAddresses = new Map<Id,Set<String>>();
        Set<String> addressesToQuery = new Set<String>();
        Set<Id> policyDomainIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        Case caseRec;
        Id accountId;
        for(EmailMessage emRec : emRecords)
        {   
            if(caseMapForValidation.containsKey(emRec.ParentId))
            {
                emailToAddresses.put(emRec.id,new Set<String>());
                emailToAddresses.get(emRec.id).addAll(getAddressFromEmail(emRec));
                addressesToQuery.addAll(emailToAddresses.get(emRec.id));
            }
        }
        for(Id caseId : caseMapForValidation.keySet())
        {            
            caseRec = caseMapForValidation.get(caseId);
            if(caseRec.RecordType.Name == 'Managed Security')
            {
                policyDomainIds.add(caseRec.Policy_Domain__c);   
            }
            else
            {
                accountIds.add(caseRec.accountId);   
            }
            accountToValidEmails.put(caseRec.accountId, new Set<String>());
            for (EmailMessage emailMessageRec : caseRec.emailmessages)
            {
                accountToValidEmails.get(caseRec.accountId).addAll(getAddressFromEmail(emailMessageRec));
            }
        }
        if(!accountIds.isEmpty())
        {
            for(Contact contactRec : [Select email,accountid from Contact where accountid in :accountIds and email in :addressesToQuery])
            {
                accountToValidEmails.get(contactRec.accountId).add(contactRec.email.trim());
            }
        }
        if(!policyDomainIds.isEmpty())
        {
            for(Authorized_Contact__c contactRec : [Select Contact_Name__r.email,Policy_Domain__r.Account_Name__c from Authorized_Contact__c where Policy_Domain__c in :policyDomainIds and Contact_Name__r.email in :addressesToQuery])
            {
                accountToValidEmails.get(contactRec.Policy_Domain__r.Account_Name__c).add(contactRec.Contact_Name__r.email.trim());
            }
        }
        for(EmailMessage emRec : emRecords)
        {     
            if(emailToAddresses.containsKey(emRec.Id))
            {
                accountId = caseMapForValidation.get(emRec.ParentId).AccountId;
                emailToAddresses.get(emRec.id).removeAll(accountToValidEmails.get(accountId));
                if(!emailToAddresses.get(emRec.id).isEmpty())
                {
                    emRec.addError('The following recipients are not recognised as contacts for the customer you are emailing. Tick ‘Override recipient validation’ and click send to ignore this warning and send the email to the below recipients: "' + String.join(new List <String>(emailToAddresses.get(emRec.id)),'" , "') + '"',false);
                }
                
            }
            
        }
        
    }
    
    //Send Email To Case Notification Subscribers
    public static void emailToCNS(List<EmailMessage> emailMessages){
        if(flagSendEmailToCNS) return;
        List<EmailMessage> outboundEMs = new List<EmailMessage>();
        for (EmailMessage em : emailMessages){
            if (!em.Incoming) {
                outboundEMs.add(em);
            }
        }
        if (!outboundEMs.isEmpty()) {
            SC_CNSUtility.emailToCNS(outboundEMs);
            flagSendEmailToCNS = true;
        }
    }

    // Changes by Sheena for ESESP-6229 : Update Task LOE on Managed Security Case with defaulte Email Template values
    public static void calculateSOCCCaseLOE(Map<EmailMessage,Case> emailMessageCaseMap, Map<Id,Id> activityIdTemplateIdMap)
    {
        List<LOE_Tracking_Template__c> templateList = new List<LOE_Tracking_Template__c>();
        Map<String,Decimal> tempNameLoeHrMap = new  Map<String,Decimal>();
        Map<Id,Decimal> taskIdLOEMap = new Map<Id,Decimal>();
        List<String> templateNames = new List<String>();
        Map<Id,EmailTemplate> emailTemplateMap = new Map<Id,EmailTemplate>();
                
        for(EmailTemplate et : [Select id, Name from EmailTemplate where id=: activityIdTemplateIdMap.values()]){
            templateNames.add(et.Name);
            emailTemplateMap.put(et.Id, et);
        }
        templateNames.add('Default Email Template LOE');
        
        templateList = [Select id, Name, LOE_Hours__c  from LOE_Tracking_Template__c where Name =: templateNames];
        
        for(LOE_Tracking_Template__c temp: templateList){
            tempNameLoeHrMap.put(temp.Name, temp.LOE_Hours__c);
        } 
        
        for(Task t: [Select id, LOE_Hours__c from Task where id=: activityIdTemplateIdMap.keySet()]){
            if(tempNameLoeHrMap.containsKey(emailTemplateMap.get(activityIdTemplateIdMap.get(t.Id)).Name)){
                t.LOE_Hours__c=tempNameLoeHrMap.get(emailTemplateMap.get(activityIdTemplateIdMap.get(t.Id)).Name);
                
            }
            else{
                t.LOE_Hours__c = tempNameLoeHrMap.get('Default Email Template LOE'); 
            }
            taskIdLOEMap.put(t.Id, t.LOE_hours__c);
        }
        
        if(!taskIdLOEMap.isEmpty()){
            //Calling future method to update LOE on Tasks
            if(!(System.isFuture() || System.isBatch()))
            {
                system.debug('Calling future method');
                updateLOEOnTasks(taskIdLOEMap);
            }
        }
        
    }
    
    // Method to update LOE on Managed Security Tasks
    @future
    public static void updateLOEOnTasks(Map<Id,Decimal> taskIdLOEMap)
    {
        List<Task> taskList = new List<Task>();
        List<Task> taskListToUpdate = new List<Task>();
        
        taskList = [Select Id,LOE_Hours__c from Task where id =:  taskIdLOEMap.keySet()];
        for(Task t: taskList){
            t.LOE_Hours__c= taskIdLOEMap.get(t.Id);
            taskListToUpdate.add(t);
        }
        if(!taskListToUpdate.isEmpty()){
            try{
                update taskListToUpdate;
            }
            catch(exception e){
                system.debug('error while updating Loe on SOCC Case//'+e.getMessage());
            }
        }
    }
    
    // Method to Enable 'Internal Case Survey Enabled' field on Case
    public static void internalAMGSurveyCheck(Map<EmailMessage,Case> amgEmailMsgCaseMap, Boolean isCustomerEmail){
        
        Case cs;
        Set<String> emailIds = new Set<String>();
        Map<Id,EmailMessage> caseIdEmailMsgMap = new Map<Id,EmailMessage>();
        List<Case> caseListToDisableSurvey = new List<Case>();
        List<Case> caseListToEnableSurvey = new List<Case>();
        List<Case> eligibleCaseList = new List<Case>();
        Map<String,Contact> emailContactMap = new Map<String,Contact>();
        Set<String> toAddresses;
        EmailMessage emailMsg;
        List<String> invalidSupportLevels = new List<String>{'None-Collections','Network Support','None','None-ContractExpired','None-NoContractLine','Indirect_Customer'};
        List<String> validAccountStatuses = new List<String>{'Direct Customer - Active','Multiple w ISP - Active','Multiple wo ISP - Active','Tier 1 Reseller - Active','Value Added Reseller - Active','VAR Customer - Active'};
        List<String> invalidOrigins = new List<String>{'AkaChat Community','AkaChat Luna','Alert','amg@akamai.com'};   

        
        for(EmailMessage em: amgEmailMsgCaseMap.keySet()){
            cs = amgEmailMsgCaseMap.get(em);
            if(isCustomerEmail && cs.Do_Not_Show_In_Portal_Picklist__c == 'Internal Only' && !cs.Qualtrics_Survey_Notification_Sent__c && String.valueOf(cs.OwnerId).startsWith(Schema.SObjectType.User.getKeyPrefix())
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
                caseIdEmailMsgMap.put(em.ParentId,em);
                emailIds.addAll(em.ToAddress.split('; '));
                eligibleCaseList.add(cs);
            }
            
            else{
                if(amgEmailMsgCaseMap.get(em).Internal_Case_Survey_Enabled__c){
                    cs.Internal_Case_Survey_Enabled__c = false; 
                    caseListToDisableSurvey.add(cs);
                }
            }
        }
        
        // Fetching the contacts in the email
        List<Contact> contactList = [Select id, Name, AccountId, email, Active_Portal_Login__c, Last_Time_Contact_Surveyed__c,No_Longer_with_Company__c  from Contact where No_Longer_with_Company__c=false and email in: emailIds];
        for(Contact con: contactList){
            emailContactMap.put(con.email,con);
        }
        
        for(Case c: eligibleCaseList){
            if(caseIdEmailMsgMap.get(c.Id)!=null){
                emailMsg = caseIdEmailMsgMap.get(c.Id);
                for(String toAdd: emailMsg.ToAddress.split('; ')){
                    if(emailContactMap.containsKey(toAdd) && emailContactMap.get(toAdd).AccountId==c.AccountId && (emailContactMap.get(toAdd).Last_Time_Contact_Surveyed__c < datetime.now().addHours(-12) || emailContactMap.get(toAdd).Last_Time_Contact_Surveyed__c == null)){
                        if(!c.Internal_Case_Survey_Enabled__c){
                            c.Internal_Case_Survey_Enabled__c=true;
                            caseListToEnableSurvey.add(c);
                        }
                    }
                }
            }
        }
        try{
            if(!caseListToEnableSurvey.isEmpty()){
                update caseListToEnableSurvey;
            }
            if(!caseListToDisableSurvey.isEmpty()){
                update caseListToDisableSurvey;
            }
        }
        catch(exception e){
            system.debug('exception://'+ e.getMessage());
        }
    }
    
}