/***
    TaskTriggerClass
    @author : Karteek Mekala <kmekala@akamai.com>
    @Description :  This class contains static methods that are called by Task trigger.
                    The following functionality is achieved :
                    1. Populate the "Task.Associated_Account" and "Task.Associated_Opportunity" fields, based on values in whatId.
                    2. When Usser Profile is 'CRM Integration' : Populate WhatId, WhatId, etc according to the AKAM Ids. 
                    
    @History
    --Developer           --Date            --Change
    Karteek Kumar M       --/02/10          Created the class.
    Karteek Kumar M       17/03/10          Removed hardcoding of prefix and used Schema.Sobjecttype.**Object**.getKeyPrefix()
                                            Made more robust, by adding 'if null' checks.
    Karteek Kumar M       18/03/10          Added SendCreditCheckCompleteEmail()
                                            This function sends an email to the Opportunity Owner when a Credit Check Activity is closed.
    Karteek Kumar M       19/03/10          Commented out SendCreditCheckCompleteEmail()
    Karteek Kumar M       24/03/10          Deleted SendCreditCheckCompleteEmail() due to change in req.
                                            Updating OrderApprovalActivity.Type = CDN / ADS along with Assoc fields
    Karteek Kumar M       29/03/10          Major Change, Trying to reduce worst-case number of SOQL queries for UpdateAssocFields.
    Karteek Kumar M       03/08/10          CR 634816 Remove any data migration specific code in salesforce
                                            Removing the function IntegrationWhatIdWhoIdMap()
    Karteek Kumar M       29/11/10          CR 886789 Fix bug with Task AKAM fields
                                            Removing firstRunFlaglogc for Akam System fields function
                                            Also removing isUpdateCauseFlag func.                                               
    Vinayendra T N        28/01/11          CR 924616 Limit the number of function calls in order approval class
                                            - Created a new method currentUserInit() which is called only the first time, and returns the alias.
                                            This is done to prevent the no. of SOQL queries.        
    Karteek Kumar M       01/02/11          CR 953967 Optimize Task -> Set AKAM Activity Id
                                            Using a static Map to prevent multiple queries when mutiple Tasks are created as separate transactions
    Karteek Kumar M       24/02/11          CR 953967 Optimize Task -> Set AKAM Activity Id
                                            Got rid of previous approach .. now using an insert into a "Random number generator" table for id                                                                           
    Ruchika Sharma        13/07/2015        CR 3081361: Reset credit check status if the existing task for creidt check gets completed. Added method: resetCreditCheckFlag
    Sonia Sawhney         29/09/2015        CR 2985554 - Need to prevent case worker collision with activities on SOC cases. Added a method to check if the task is related to a case or not.                                                                                               
    Shivani               02/06/2015        QTOO-3283: New credit Check task getting created even when the account has an open Credit Check task. 
    Sandeep               21/05/2018        SFDC-2688: Removing Apttus related code

*/
global class TaskTriggerClass 
{
    private static Boolean sendCreditCheckCompleteEmailFirstRunFlag = true;
    private static Boolean integrationWhatIdWhoIdMapFirstRunFlag = true;
    public static Boolean regularIdsMapFirstRunFlag = true;
    public static Boolean updateAssocFieldsFirstRunFlag = true;
    public static Boolean updateLeadWithLastActivity = true;
    public static Boolean updateAccWithccStatus = true;
    //SFDC-2266
    public static Boolean insertTaskForReviewFirstRunFlag = true;
    public static Boolean updateReviewTaskOwnerFirstRunFlag = true;
    private static Id oaRecTypeId;
    private static User currentUser;
    private static Map<Id, Task> currentTaskTriggerMap;
    public static Id GetOaRecTypeId()
    {
        if(oaRecTypeId == null)
            oaRecTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Order Approval Activity').getRecordTypeId();
        return oaRecTypeId;
    }

    /*
    SFDC-4178
     public static void sendEmailNotification(List<Task> taskList){
         EmailTemplate emailTemplate;
         emailTemplate = [select Id, Subject, HtmlValue, Body from EmailTemplate where Name = 'Deal desk task Creation Notification'];
        //List for sending Bulk Email
        List<Messaging.SingleEmailMessage > mailList = new List<Messaging.SingleEmailMessage >();
        For(Task t : taskList){
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        //checking the task Type for APTTUS
          If(t.Task_Type__c == 'Deal Desk' ){
                message.setTargetObjectId(t.CreatedById);
                message.setSaveAsActivity(false);
                message.setWhatId(t.Id); 
                message.setTemplateId(emailTemplate.id);
                mailList.add(message);
            }
            
            }
            If(!mailList.isEmpty()){
                Messaging.sendEmail(mailList);
            }
        
     }
     */

     /** Given Sys Admin Override to delete Tasks for CronKit.
             CR 653554 Error logging / notification for Scheduled Jobs
      */
    public static void beforeDeleteCheck(List<Task> tasksList) {
        Map<String,GSM_Settings__mdt> testcaseCustomSettings = GsmUtilClass.getGSMSettingValue();

        String sysAdminProfileId = testcaseCustomSettings.get('SystemAdminProfileId').Value__c;
        if (Userinfo.getProfileId() != sysAdminProfileId)
        {
            /* Order Approval Activity */
            // CR 860591 Remove Delete functionality on Order Approval Tasks    
            Id oaRecTypeId = TaskTriggerClass.GetOaRecTypeId();
            for(Task tsk:tasksList)
                if(tsk.RecordTypeId == oaRecTypeId) // Added the Approval_Request_Agreement_Proposal_Id__c field as part of CR 2499807 (Q2O).
                    tsk.addError('Activities associated to an Order Approval cannot be deleted.');
        }
        //SFDC-3054
        Set<Id> taskIds = (new Map<Id,Task>(tasksList)).keySet();
        Map<Id, Task> taskMap =  new Map<ID, Task>([Select Id,whoID, RecordType.DeveloperName from Task where ID in :taskIds]);
        for(Task tsk: tasksList){
            if(tsk.whoID != null && taskMap.get(tsk.Id).RecordType != null){
                String whoID = tsk.whoID;
                String recordTypeDevName = taskMap.get(tsk.Id).RecordType.DeveloperName;
                if(whoID.startsWithIgnoreCase('00Q') && recordTypeDevName == 'Standard_Activity') {
                    tsk.addError('Activities associated to Lead cannot be deleted.');
               }
           }
        }
    }
    /*
    public static void orderApprovalActivities(List<sObject> tasksList, Map<Id,sObject> oldMap) {

        Order Approval Activity
        Id oaRecTypeId = TaskTriggerClass.GetOaRecTypeId();
        List<Task> orderApprovalActivitiesNew = new List<Task>();
        List<Task> orderApprovalActivitiesOld = new List<Task>();
        List<Task> dealDeskOAActivities = new List<Task>();
        for(sObject stsk:tasksList)
        {
            Task tsk = (Task) stsk;
            if(tsk.RecordTypeId == oaRecTypeId)
            {
                orderApprovalActivitiesNew.add(tsk);
                if(!trigger.isInsert)
                    orderApprovalActivitiesOld.add(((Task)oldMap.get(tsk.Id)));
            }
        }
        if(orderApprovalActivitiesNew.size()>0)
        {
            //OrderApprovalClass.OrderApprovalActivity_UpdateOrder(orderApprovalActivitiesNew);
            if(!trigger.isInsert)
                OrderApprovalClass.SendOrderApprovalActivityEmails(orderApprovalActivitiesOld, orderApprovalActivitiesNew);
            //else    
            //    OrderApprovalClass.SendOrderApprovalTaskCreationNotifications(orderApprovalActivitiesNew);
        }
    }
    */
     
  //SFDC 1497 - Create Actions on Opportunity to access in wave dashboards - Defaulting subject
    public static void updateSubjectForQuickActivity(List<Task> tasksList) {
        
        /* Checking the Sales Rep Activity record type and also checking whether the task belongs to opportunity
         * Creating a list of eligible tasks and map to task's Opportunity id to name to populate subject on task
         */
        Id salesRepActivityRecordTypeId = Schema.SObjectType.task.getRecordTypeInfosByName().get('Sales Rep Activity').getRecordTypeId();
        List<id> opptyTaskIds = new List<Id>();
        List<Task> eligibleOpptyTasks = new List<Task>();
        List<id> accTaskIds = new List<Id>();
        List<Task> eligibleAccTasks = new List<Task>();
        Map<String,String> oppIdToNameMap = new Map<String,String>();
        Map<String,String> accIdToNameMap = new Map<String,String>();
            
        for (Task taskval:tasksList) {
            if (taskval.WhatId != null) {

                String sObjName = taskval.WhatId.getSObjectType().getDescribe().getName();
                
                if (salesRepActivityRecordTypeId.equals(taskval.recordTypeId) ) {
                    if (sObjName.equals('Opportunity')) {
                        if (taskval.subject == null || taskval.subject == '') {
                            //taskval.subject = taskval.QuickActionType__c + ' : '+ (taskval.What);
                            opptyTaskIds.add(taskval.WhatId);
                            eligibleOpptyTasks.add(taskval);
                        }
                    } else if (sObjName.equals('Account')) {
                        if (taskval.subject == null || taskval.subject == '') {
                            //taskval.subject = taskval.QuickActionType__c + ' : '+ (taskval.What);
                            accTaskIds.add(taskval.WhatId);
                            eligibleAccTasks.add(taskval);
                        }
                    }
                }
            }
        }
          
        if (opptyTaskIds.size() > 0) {
            
            List<Opportunity> oppList = [Select id,Account.Name from Opportunity where id IN:opptyTaskIds];
            
            for (Opportunity opp:oppList) {
                oppIdToNameMap.put(opp.id,opp.Account.Name);
            }

            for (Task t:eligibleOpptyTasks) {
                t.subject = t.QuickActionType__c + ' : '+ oppIdToNameMap.get(t.WhatId);

                if (t.Type__c == null)
                    t.Type__c = t.QuickActionType__c;
            }

        } 

        if (accTaskIds.size() > 0) {
            
            List<Account> accList = [Select id,Name from Account where id IN:accTaskIds];
            
            for (Account a:accList) {
              accIdToNameMap.put(a.id,a.Name);
            }
            for (Task t:eligibleAccTasks) {
              t.subject = t.QuickActionType__c + ' : '+ accIdToNameMap.get(t.WhatId);
              if (t.Type__c == null)
                t.Type__c = t.QuickActionType__c;
            }
        }
    }   
    /**
        getCurrentTriggerTaskList(Task[] pTaskList)
        - We cant just use firstRun flag logic to achieve this because when 2 workflows create
          2 tasks separately, each has its own Trigger transaction.
    *
    public static List<Task> getCurrentTriggerTaskList(Task[] pTaskList)
    {
        if(currentTaskTriggerMap == null)
            currentTaskTriggerMap = new Map<Id, Task>();
            
        Boolean runQuery = false;
        for(Task t:pTaskList)
        {
            if(!currentTaskTriggerMap.keySet().contains(t.Id))
            {
                runQuery = true;
                break;
            }
        }
        
        if(runQuery)
        {
            for(Task tsk:[select Id, 
                                 AKAM_Activity_ID__c, 
                                 ActivityAutoID__c 
                          from Task 
                          where Id IN :pTaskList])
                currentTaskTriggerMap.put(tsk.Id, tsk);
        }
        return currentTaskTriggerMap.values();
    }   */
    /**
        SeetAkamActivityId()
        
    global static void SetAkamActivityId(Task[] tasks)
    {
        //List<Task> activityIdUpdateList = [select Id, AKAM_Activity_ID__c, ActivityAutoID__c from Task where Id IN :tasks and AKAM_Activity_ID__c = null];
        List<Task> activityIdUpdateList = getCurrentTriggerTaskList(tasks);
        for(Task tsk:activityIdUpdateList)
            tsk.AKAM_Activity_ID__c = tsk.ActivityAutoID__c;
        if(activityIdUpdateList.size()>0)
            update activityIdUpdateList;
    }*/
    /**
        SetAkamActivityId2
    */

    global static void SetAkamActivityId2(Task[] tasks)
    {
        List<Random_Number_Generator__c> randomNumberList = new List<Random_Number_Generator__c>();
        for(Integer i=0;i<tasks.size();i++)
            randomNumberList.add(NewRandomNumberRecord());
        insert randomNumberList;
        
        String environmentPrefix = Environment_Setup__c.getOrgDefaults().Akam_Id_Start_String__c;
        
        for(Integer i=0;i<tasks.size();i++)
        {
            //if(tasks[i].AKAM_Activity_ID__c == null || tasks[i].AKAM_Activity_ID__c == '') //SFDC-2584-Commented
            if((tasks[i].AKAM_Activity_ID__c == null || tasks[i].AKAM_Activity_ID__c == '') || tasks[i].RecurrenceActivityId != null) //SFDC-2584-Added
                tasks[i].AKAM_Activity_ID__c = environmentPrefix + 'TA-' + (randomNumberList[i].Id + '').substring(3, 18); // The middle 12 chars are the unique identifier
        }
    }
       
    public static Random_Number_Generator__c NewRandomNumberRecord()
    {
        Random_Number_Generator__c temp = new Random_Number_Generator__c();
        temp.Object__c = 'Task';
        return temp;
    }
    /**
        currentUserInit()
        Get user Alias , making it static so that there is only one Soql query
    */

    //l2q team's code - Also check if this can be removed
    public static void currentUserInit()
    {
        if(currentUser != null)
            return;
        currentUser = [select Id, Alias from User where Id=:Userinfo.getUserId()];
    }
    /**
       UpdateAssocFields(Task[] tasks)
       - Called on "before insert / before update" events on "Task".
       - Called in "TaskTrigger_bi_bu.triggger"
       - If, "Task.Related To" -> Order Approval, then populate "Task.Associated_Account" and "Task.Associated_Opportunity" with reference values from Order Approval.
       - If, "Task.Related To" -> Opportunity, then populate "Task.Associated_Account" and "Task.Associated_Opportunity" with reference values from Opportunity.
       - If, "Task.Related To" -> Account, then populate only "Task.Associated_Account" with values from Account.
    */
    
    public static void UpdateAssocFields(Task[] tasks)
    {
        if(!updateAssocFieldsFirstRunFlag)
            return;
        String wId;
        Set<Id> oaIds = new Set<ID>();
        Set<Id> opptyIds = new Set<Id>();
        Set<Id> accIds = new Set<Id>();
        // -------Get the Order Approval.Ids from Related To
        for(Task tsk : tasks)
        {
            wId = tsk.WhatId;
            // If Order Approval
            if(wId!=null && wId.startsWith(Schema.Sobjecttype.Order_Approval__c.getKeyPrefix()) && !oaIds.contains(tsk.WhatId))
                oaIds.add(tsk.WhatId);                  
        }
        // Pull the Order Approval records for the Ids that appear in Task.whatId
        List<Order_Approval__c> taskOrderApprovals;
        Map<Id, Order_Approval__c> oaMap = new Map<Id, Order_Approval__c>();                
        if(oaIds.size()>0)
        {           
            taskOrderApprovals = [Select Id, Name, Associated_Opportunity__c, Associated_Opportunity__r.Name, Associated_Opportunity__r.Associated_Account_Name__c, Associated_Opportunity__r.Associated_Account_Sales_Region__c, Type__c, Associated_Opportunity__r.Account.Commercial_Segmentation__c from Order_Approval__c where Id IN :oaIds];
            for(Order_Approval__c oa: taskOrderApprovals)
                oaMap.put(oa.Id,oa);
        }           
        // -------Get the Opportunity.Id from Related To
        for(Task tsk : tasks)
        {
            wId = tsk.WhatId;
            // If Opportunity
            if(wId!=null && wId.startsWith(Schema.Sobjecttype.Opportunity.getKeyPrefix()) && !opptyIds.contains(tsk.WhatId))
                opptyIds.add(tsk.WhatId);                   
        }
        // Pull the Opportunity records for the Opportunity ids that appear in Task.whatId
        List<Opportunity> taskOpportunitys;
        Map<Id, Opportunity> opptyMap = new Map<Id, Opportunity>();             
        if(opptyIds.size()>0)
        {           
            taskOpportunitys = [Select Id, Name, AccountId, Associated_Account_Name__c, Associated_Account_Sales_Region__c, Account.Commercial_Segmentation__c from Opportunity where Id IN :opptyIds];
            for(Opportunity o : taskOpportunitys)
                opptyMap.put(o.Id,o);
        }       
        // -------Get the Account.Id from Related To
        for(Task tsk : tasks)
        {               
            wId = tsk.WhatId;
            // If Account               
            if(wId!=null && wId.startsWith(Schema.Sobjecttype.Account.getKeyPrefix()) && !accIds.contains(tsk.WhatId))
                accIds.add(tsk.WhatId);
        }       
        // Pull the Account records for the Account ids that appear in Task.whatId
        List<Account> taskAccounts;
        Map<Id, Account> accMap = new Map<Id, Account>();       
        if(accIds.size()>0)
        {
            taskAccounts = [Select Id, Name, TERR_HIER_2__c, TERR_HIER_5__c, Commercial_Segmentation__c from Account where Id IN :accIds]; //SFDC-4481 : Added Commercial_Segmentation__c
            for(Account acc : taskAccounts)
                accMap.put(acc.Id,acc); 
        }                       
        //Update the Custom fields
        if(accIds.size()>0 || opptyIds.size()>0 || oaIds.size()>0)
        {
            for(Task tsk : tasks)
            {
                wId = tsk.WhatId;
                String salesRegion;
                //If Related To -> Order Approval
                if(wId!=null && wId.startsWith(Schema.Sobjecttype.Order_Approval__c.getKeyPrefix()))
                {
                    if(oaMap.containsKey(tsk.WhatId))
                    {
                        tsk.Order_Approval_Type__c = oaMap.get(tsk.WhatId).Type__c;                     // Set CDN/ ADS
                        tsk.Associated_Opportunity__c = oaMap.get(tsk.WhatId).Associated_Opportunity__r.Name;                       
                        tsk.Associated_Account__c = oaMap.get(tsk.WhatId).Associated_Opportunity__r.Associated_Account_Name__c;
                        salesRegion = oaMap.get(tsk.WhatId).Associated_Opportunity__r.Associated_Account_Sales_Region__c;
                        tsk.Account_Sales_Region__c = String.isNotBlank(salesRegion) && salesRegion.length() > 60 ?salesRegion.substring(0, 60): salesRegion;
                        tsk.Commercial_Segmentation__c = oaMap.get(tsk.WhatId).Associated_Opportunity__r.Account.Commercial_Segmentation__c;
                    }
                }
                // If Related To -> Opportunity
                else if(wId!=null && wId.startsWith(Schema.Sobjecttype.Opportunity.getKeyPrefix()))
                {
                    if(opptyMap.containsKey(tsk.WhatId))
                    {
                        tsk.Associated_Opportunity__c= opptyMap.get(tsk.WhatId).Name;
                        tsk.Associated_Account__c = opptyMap.get(tsk.WhatId).Associated_Account_Name__c;
                        salesRegion = opptyMap.get(tsk.WhatId).Associated_Account_Sales_Region__c;
                        tsk.Account_Sales_Region__c = String.isNotBlank(salesRegion) && salesRegion.length() > 60 ?salesRegion.substring(0, 60): salesRegion;
                        tsk.Commercial_Segmentation__c = opptyMap.get(tsk.WhatId).Account.Commercial_Segmentation__c;
                    }
                }
                // If Related To -> Account
                else if(wId!=null && wId.startsWith(Schema.Sobjecttype.Account.getKeyPrefix()))
                {
                    if(accMap.containsKey(tsk.WhatId))
                    {
                        tsk.Associated_Account__c = accMap.get(tsk.WhatId).Name;
                        salesRegion = accMap.get(tsk.WhatId).TERR_HIER_2__c + ' '  + accMap.get(tsk.WhatId).TERR_HIER_5__c;
                        tsk.Account_Sales_Region__c = String.isNotBlank(salesRegion) && salesRegion.length() > 60 ?salesRegion.substring(0, 60): salesRegion;
                        tsk.Commercial_Segmentation__c = accMap.get(tsk.WhatId).Commercial_Segmentation__c; //SFDC-4481
                    }  
                }               
            }
        }
        updateAssocFieldsFirstRunFlag = false;
    }
    /** 
       RegularIdsMap()
       - If an task is created from a lead, this will reassociate that task
         to the contact object and sets all the correct associated akamIDs used for
         integration.
            
    */
    public static void RegularIdsMap(Task[] tasks)
    {     
        if(!regularIdsMapFirstRunFlag)
            return;
        Set<Id> eventWhoIDSet = new Set<Id>();
        // Initalize the Order Approval Record Type Id, if it is not initialized
        GetOaRecTypeId();
        
        String contactWhoId = Schema.Sobjecttype.Contact.getKeyPrefix();
        String leadWhoId = Schema.Sobjecttype.Lead.getKeyPrefix();
        Id standardActRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Standard Activity').getRecordTypeId();
        Id salesRepActRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Sales Rep Activity').getRecordTypeId();

        for (Task t : tasks){
            if (t.RecordTypeID != oaRecTypeId) {
                String whoId = t.whoID;
                if (whoId != null) {
                    if (whoId.startsWith(contactWhoId) || whoId.startsWith(leadWhoId) )
                        eventWhoIDSet.add(t.whoID);
                } 
            } 
            //SFDC-3053
            if(t.Type == 'Email' && t.type__c == null && (t.RecordTypeId == standardActRecordTypeId || t.RecordTypeId == salesRepActRecordTypeId)){
                t.type__c = 'Email';
            }
        }
        //since task could be for multiple objects
        //we set up a map for each where updates are needed
        if (!eventWhoIDSet.isEmpty()) //don't enter if only order appr record types
        {
            Map<Id, Lead> leadMap = new Map<Id,Lead>();
            //if its a task on a lead, multiple updates to who, what and AKAM ids
            for (Lead l:[Select Id, AKAM_LEAD_ID__c, Associated_Contact__c,
                Associated_Contact__r.AKAM_Contact_ID__c,
                Associated_Contact__r.OD_Contact_ROW_ID__c,
                Associated_Contact__r.AccountId,
                Associated_Contact__r.Account.AKAM_Account_ID__c,
                Associated_Contact__r.Account.OD_Account_Row_ID__c
                from Lead where id in :eventWhoIDSet])
            {
                leadMap.put(l.id, l);
            }
            
            Map<Id, Contact> contactMap = new Map<Id,Contact>();
            //if its a task on a contact, add acct to whatid and AKAM ids
            for (Contact c:[Select Id, AKAM_Contact_ID__c, 
                AccountId, Account.AKAM_Account_ID__c
                from Contact where id in :eventWhoIDSet])
            {
                ContactMap.put(c.id, c);
            }
            Id orgWhoID; //this is needed to hold the original id as it will be replaced midway
            // need to update task.akam_campaign_id with oldest lead's campaign
            // so create a map of AKAM_Campaign_ids for batch
            Map<Id, CampaignMember> CampaignMap = new Map<Id,CampaignMember>();
            for (Lead l2:[SELECT id, 
                (SELECT Id, campaign.AKAM_Campaign_ID__c 
                FROM CampaignMembers order by createddate desc limit 1) 
                FROM lead WHERE id in :eventWhoIDSet ])
            {
                for (CampaignMember cm: l2.CampaignMembers)
                    campaignMap.put(l2.id, cm);
            }
    
            //loop tasks and assign who,what and AKAM id's
            for (Task t2 : tasks)
            {
                orgWhoID = null; //reset
                if(leadMap.containsKey(t2.WhoID))
                //this task record is from a lead
                {
                    t2.Associated_AKAM_Lead_ID__c = leadMap.get(t2.whoID).AKAM_Lead_ID__c;
                    //move task to contact and Account
                    orgWhoID = t2.WhoId; // since we're changing this, need original for map
                    //SFDC-3054 Commenting whoID and WhatID
                    //t2.whoID= leadMap.get(orgWhoID).Associated_Contact__c;
                    t2.Associated_AKAM_Contact_ID__c = leadMap.get(orgWhoID).Associated_Contact__r.AKAM_Contact_ID__c;
                    //t2.whatID = leadMap.get(orgWhoID).Associated_Contact__r.AccountId;
                    t2.Associated_AKAM_Account_ID__c = leadMap.get(orgWhoID).Associated_Contact__r.Account.AKAM_Account_ID__c;
                    //last step, add the correct campaign id
                    if (campaignMap.containsKey(orgWhoID))
                        t2.Associated_AKAM_Campaign_ID__c = campaignMap.get(orgWhoID).Campaign.AKAM_Campaign_ID__c;
                }
                if(contactMap.containsKey(t2.WhoID))
                //this task record is from a CONTACT
                {
                    t2.Associated_AKAM_Contact_ID__c = contactMap.get(t2.whoID).AKAM_Contact_ID__c;
                    if (t2.whatid == null) //if no acct, update it with the acct info
                        t2.WhatID = contactMap.get(t2.whoID).AccountId;
                    t2.Associated_AKAM_Account_ID__c = contactMap.get(t2.WhoID).Account.AKAM_Account_ID__c;
                }
            }
        }
        regularIdsMapFirstRunFlag = false;
    }
        
    /**
       AKAM_System_Fields(Task[] tasks)
       - Update AKAM Created/Created By/System/Modified/Modified Date when a record is created and either values is left blank
    */
    public static void AKAM_System_Fields(Task[] tasks)
    {
        currentUserInit();
        for(Task t:tasks)
        {
            t.AKAM_Created_By__c = currentUser.Alias;
            t.AKAM_Created_Date__c = Datetime.now();
            t.AKAM_System__c = 'FORCE';
            t.AKAM_Modified_By__c = currentUser.Alias;
            t.AKAM_Modified_Date__c = Datetime.now();
        }
    }

    /*
    CR 3081361 Reset credit check status if the existing task for creidt check gets completed.
    QTOO-3283: New credit Check task getting created even when the account has an open Credit Check task.
               On completion of a CC Task, checking if there are no other open CC tasks under that account, then making taskCreatedForCreditCheck__c = false.
               (Earlier, as soon as task is completed, taskCreatedForCreditCheck__c was made false. Because of which multiple task may get created for accounts already having multiple CC tasks, i.e, some old data). 
    */
    public static void resetCreditCheckFlag(List<Task> taskList, Map<ID, Task> oldMap){
         //if task.Status = Completed and tsk.Subject = 'Credit Check Needed' and account's taskCreatedForCreditCheck__c is true, then make it false.
            if(!updateAccWithccStatus)
                return;

            Map<Id,String> tskIdWhatIds = new Map<Id,String>();
            List<Account> toUpdateCreditCheckFlags = new List<Account>();
            Set<Id> triggeredCompletedTasks = new Set<Id>();
            Map<id,Boolean> accToOpenCCTasksMap = new Map<id,Boolean>();
            Set<String> accIds = new Set<String>();
            for(Task tsk:taskList){
                String wId = tsk.WhatId;
                if(wId!=null && wId.startsWith(Schema.Sobjecttype.Account.getKeyPrefix()) && !accIds.contains(wId)){
                    accIds.add(wId);
                    tskIdWhatIds.put(tsk.id,wid);
                }
            }
        if(accIds.size() > 0 ){
            Map<Id,Account> accList = new Map<Id,Account>([Select taskCreatedForCreditCheck__c from Account where id IN :accIds]);
            //Adding the triggered tasks that got completed in a list, such that query for all other openCreditCheckTasks will not take these completed tasks as not-completed.
            for(Task tsk:taskList){
                if(tsk.Status == 'Completed' && tsk.status!=oldMap.get(tsk.id).Status && tsk.Subject == 'Credit Check Needed'){
                    triggeredCompletedTasks.add(tsk.Id);
                }
            }
            List<Task> openCreditCheckTasks=[Select WhatId from Task where WhatId in:accIds and Status != 'Completed' and Subject = 'Credit Check Needed' and id not in:triggeredCompletedTasks];
            for(Task openTask :openCreditCheckTasks)
            {
                if(accToOpenCCTasksMap.get(openTask.WhatId)==null)
                    accToOpenCCTasksMap.put(openTask.WhatId, true);
            }
            for(Task tsk:taskList){
                if(tsk.Status == 'Completed' && tsk.status!=oldMap.get(tsk.id).Status && tsk.Subject == 'Credit Check Needed'){
                    String accId = tskIdWhatIds.get(tsk.id);
                    Account creditCheckAcc = accList.get(accId);
                    if(creditCheckAcc!=null){
                        if(creditCheckAcc.taskCreatedForCreditCheck__c == true && (accToOpenCCTasksMap.get(creditCheckAcc.id)==null || accToOpenCCTasksMap.get(creditCheckAcc.id)!=true)) {
                            creditCheckAcc.taskCreatedForCreditCheck__c = false;
                            toUpdateCreditCheckFlags.add(creditCheckAcc);
                        }
                    }
                }
            }
            update toUpdateCreditCheckFlags;
            updateAccWithccStatus = false;
        }
        
    }

    // public static void stampLastActivityOnAssociatedLead(Task[] taskList, Map<ID, Task> newMap) //Commented by Vivek as this functionality is no longer in use.

    //SFDC-1190
    public static void closedTasksWithNullContractAcceptedDate(List<Task> ClosedTasks)
    {
        List<Id> TasksOfOppty = new List<Id>();
        Map<Id,Task> TaskToOpptyMap = new Map<Id,Task>();

        for(Task eachTask:ClosedTasks)
        {
            {
                TasksOfOppty.add(eachTask.WhatId);
                System.debug('GSP: '+TasksOfOppty);
                TaskToOpptyMap.put(eachTask.WhatId, eachTask);
            }
        }

        //added List Query to SOQL for
        //SFDC-1291
        //SFDC-2704
           String ErrorMsg='';

            for(Opportunity eachOppty:[select Id,Contract_Accepted_Date__c,Contract_Reviewed_by__c,Double_Reviewed_By__c,Account_Customer_Tier__c from Opportunity where Id IN :TasksOfOppty and (Contract_Accepted_Date__c = null OR (Double_Reviewed__c=null AND Account_Customer_Tier__c='A+')) AND StageName='Closed Won'])
            {
                if(eachOppty.Contract_Accepted_Date__c==null)
                    ErrorMsg = GsmUtilClass.getGSMSettingValue('TaskTriggerErrorMsg');
                if(eachOppty.Double_Reviewed_By__c==null && eachOppty.Account_Customer_Tier__c!=null && GSMUtilClass.getGSMSettingValue('CMG_Acc_Cust_Tier_For_Double_Review').contains(eachOppty.Account_Customer_Tier__c)){
                    if(!String.isEmpty(ErrorMsg))
                        ErrorMsg +='<br/>';
                    ErrorMsg += GsmUtilClass.getGSMSettingValue('Task_Double_Reviewed_By_Error');
                }
                 if(TaskToOpptyMap.containsKey(eachOppty.Id))
                {
                    //it might be escaped in lightning
                    TaskToOpptyMap.get(eachOppty.Id).addError(ErrorMsg,false);
                }
            }
    }

    //SFDC-2266
    public static void insertTaskForReview(List<Task> ss6TaskList,List<Id> whatIdList){
            if(!insertTaskForReviewFirstRunFlag)
                return;
            String CMGReviewerQueueUser = GsmUtilClass.getGSMSettingValue('CMGReviewerQueue'); //SFDC-2304
            String cmgReviewTaskSubject = GsmUtilClass.getGSMSettingValue('cmgReviewTaskSubject'); //create in sandbox
            List<Task> reviewerTaskList = new List<Task>();
            map<id,task> OpptyIdTaskMap=new map<id,task>();
            //check if no existing review task is present on oppty
            for(Task t:[select id,WhatId from Task where Subject=:cmgReviewTaskSubject and WhatId IN :whatIdList and IsClosed=false])
                OpptyIdTaskMap.put(t.WhatId,t);
            for(Task task: ss6TaskList){
                if(OpptyIdTaskMap.get(task.WhatId)==null){
                    Task reviewerTask = OpportunityTriggerClass.createtask(CMGReviewerQueueUser,task.WhatId,cmgReviewTaskSubject,'','Not Started');
                    reviewerTaskList.add(reviewerTask);
                }
            }
            GsmUtilClass.doDatabaseInsert(reviewerTaskList,'TaskTriggerClass','insertTaskForReview',false);
            insertTaskForReviewFirstRunFlag = false;
    }
    
        // SFDC-2591
    public static void handleLowRiskTransactions(List<Opportunity> listOfLowRiskTransactionOpportunities) {
        for(Opportunity eachOpportunity : listOfLowRiskTransactionOpportunities) {
            // Update Contract_Accepted_Date__c to 1st day of the month of CloseDate
            System.DEBUG('Inside HandleLowRiskTransactions');
            if(eachOpportunity.CloseDate != null) {
                //SFDC-4136
                eachOpportunity.Contract_Accepted_Date__c = DateTime.newInstanceGmt(eachOpportunity.CloseDate.year(), eachOpportunity.CloseDate.month(), 1, 13, 0, 0);               
                eachOpportunity.Validation_Override__c = true;
            }
        }
        try {
            update listOfLowRiskTransactionOpportunities;
        }
        catch (Exception e) {
            System.DEBUG('Exception: ' + String.valueOf(e.getMessage()));
            Error_log__c erroLog = new Error_log__c(Name = 'TaskTriggerClass Update Failure of lowriskOppty Transactions', Class__c = 'TaskTriggerClass', Error_Message__c = String.valueOf(e.getMessage()));
            insert erroLog;
        }
    }

    // SFDC-2591 call insertTaskForReview if high risk transaction else handleLowRiskTransactions
    public static void validateRiskOfTransaction(Map<Id, Task> mapOfOpptyIdvsTask) {
        List<Task> ss6TaskList = new List<Task>();
        List<Id> listOfOpptyIdsRequiringNewTask = new List<Id>();
        List<opportunity> updateContractOppty = new list<opportunity>();
        String SS6TaskAccSeg = GsmUtilClass.getGSMSettingValue('AccountSegmentationCMGTask');

        // Add Field values to metadata
        String[] transactionTypeNotIn = GsmUtilClass.getPRMSettingValue('POC_PicklistValsHighRisk_TransactionType').split(',');
       // Map<Id, Opportunity> mapOfOpptyIdsVsLowRiskTransactionOpportunities = new Map<Id, Opportunity>([SELECT Id, CloseDate, Contract_Accepted_Date__c, Transaction_Type__c FROM Opportunity WHERE Id = :mapOfOpptyIdvsTask.keySet() AND Transaction_Type__c != null AND Transaction_Type__c != :transactionTypeNotIn]);
        Map<Id, Opportunity> mapOfOpptyIdsVsLowRiskTransactionOpportunities = new Map<Id, Opportunity>([SELECT Id, CloseDate, Contract_Accepted_Date__c, Transaction_Type__c,Momentum_Automated__c,Account.Commercial_Segmentation__c FROM Opportunity WHERE Id = :mapOfOpptyIdvsTask.keySet()]);
        
        //System.DEBUG('mapOfOpptyIdsVsLowRiskTransactionOpportunities : ' + mapOfOpptyIdsVsLowRiskTransactionOpportunities);
        for(Id eachId : mapOfOpptyIdvsTask.keySet()) {
           /* if(!mapOfOpptyIdsVsLowRiskTransactionOpportunities.containsKey(eachId)) {
                listOfOpptyIdsRequiringNewTask.add(eachId);
                ss6TaskList.add(mapOfOpptyIdvsTask.get(eachId));
            }*/
            //SFDC-7351
            if(mapOfOpptyIdsVsLowRiskTransactionOpportunities.get(eachId).Transaction_Type__c != Null && !transactionTypeNotIn.contains(mapOfOpptyIdsVsLowRiskTransactionOpportunities.get(eachId).Transaction_Type__c)){
                updateContractOppty.add(mapOfOpptyIdsVsLowRiskTransactionOpportunities.get(eachId));
            }
            else{
                Opportunity oppty = mapOfOpptyIdsVsLowRiskTransactionOpportunities.get(eachId);
                if(oppty.Momentum_Automated__c != 'Fully Automated' && (oppty.Account.Commercial_Segmentation__c == null || 
                    (oppty.Account.Commercial_Segmentation__c != null && 
                     //( !oppty.Account.Commercial_Segmentation__c.contains('Standardized') &&
                       (/*!SS6TaskAccSeg.contains(oppty.Account.Commercial_Segmentation__c)*/ !oppty.Account.Commercial_Segmentation__c.contains('Standardized') || (/*SS6TaskAccSeg.contains(oppty.Account.Commercial_Segmentation__c)*/ oppty.Account.Commercial_Segmentation__c.contains('Standardized') && oppty.Momentum_Automated__c == 'Straight Through Processing'))))){
                    listOfOpptyIdsRequiringNewTask.add(eachId);
                    ss6TaskList.add(mapOfOpptyIdvsTask.get(eachId));
                }
            }
            if(mapOfOpptyIdsVsLowRiskTransactionOpportunities.get(eachId).Account.Commercial_Segmentation__c != null && SS6TaskAccSeg.contains(mapOfOpptyIdsVsLowRiskTransactionOpportunities.get(eachId).Account.Commercial_Segmentation__c)){
                updateContractOppty.add(mapOfOpptyIdsVsLowRiskTransactionOpportunities.get(eachId));
            }
        }

        if(updateContractOppty.size() > 0) {
            handleLowRiskTransactions(updateContractOppty);
        }
        if(!ss6TaskList.isEmpty()) {
            insertTaskForReview(ss6TaskList, listOfOpptyIdsRequiringNewTask);
        }
    }
    // END SFDC-2591

    public static void updateReviewTaskOwner(List<Task> reassignTaskList,List<Id> whatIdList){
        if(!updateReviewTaskOwnerFirstRunFlag)
                return;
        string SS6TaskSubject = GsmUtilClass.getGSMSettingValue('OpptyTrigger_SS6TaskSubject'); //SFDC-2304
        list<Id> opptoQuery = new List<Id>();
        List<Opportunity> oppList = new List<Opportunity>();
        map<id,id> OpptyidActiveOwnerMap = new map<id,Id>();
        map<id,id> OpptyidManagerMap = new map<id,id>();
        map<id,id> opptyIdCMGAnalystMap = new map<id,id>();

        //get owner for SS6TaskSubject to reassign task
        //To Do: check if previous owner of entry task could be cmg review queue
        List<Task> SS6TaskList= [select id,OwnerId,whatId,owner.isActive from task where subject=:SS6TaskSubject AND whatId IN:whatIdList];
        
        for(Task tsk:SS6TaskList){
            if(tsk.Owner.isActive)
                opptyIdCMGAnalystMap.put(tsk.whatId,tsk.OwnerId);
            else
                opptoQuery.add(tsk.whatId);
        }
        if(!opptoQuery.isEmpty()){
           oppList= [select id,OwnerId,Owner.isActive,Owner.Managerid from Opportunity where id in :opptoQuery];
               if(!oppList.isEmpty()){
                for(Opportunity oppty:oppList){
                   if(oppty.Owner.isActive)
                        OpptyidActiveOwnerMap.put(oppty.id,oppty.ownerid);
                    else if(oppty.Owner.Managerid!=null)
                        OpptyidManagerMap.put(oppty.id,oppty.owner.managerId);
                }
            }
        }

            for(Task tsk: reassignTaskList){

                    if(opptyIdCMGAnalystMap.containsKey(tsk.whatId))
                        {
                             tsk.OwnerId = opptyIdCMGAnalystMap.get(tsk.whatId);
                        }
                        
                        //if owner is active. Assign the task to owner
                        else if(OpptyidActiveOwnerMap.containsKey(tsk.whatId))
                        {
                            tsk.OwnerId = OpptyidActiveOwnerMap.get(tsk.whatId);
                        }
                        else if(OpptyidManagerMap.containsKey(tsk.whatId))
                        {//else if manager exists then assign the task to manager
                            tsk.OwnerId = OpptyidManagerMap.get(tsk.whatId);
                        }
                        else
                        {//else assign the task to current user
                            tsk.OwnerId = Userinfo.getUserId();//
                        }

            }
            
    }
}