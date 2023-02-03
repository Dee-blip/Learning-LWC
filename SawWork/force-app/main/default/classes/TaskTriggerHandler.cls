/*****************************************************************************
* Name             : TaskTriggerHandler
* Created By       : Pitamber Sharma (Appirio Offshore)
* Test Class       : Test_TaskTriggerHandler

DATE                DEVELOPER    CR     DESCRIPTION

===========         =========    =======    ===========
03-May-2013         Pitamber   T-165897   - Initial Requirement
22-Apr-14           Kunal                 - Added UpdateIRMilestone() to automate IRMilestopne Completion on external log activity creation.
05/22/2014          Kunal                 - Removed extra SOQLs from the Class.
19-Feb-2015         Jay       2773452     - Validation override flag
20-Mar-15           Akhila    2907264     - By passing Case's RecentUPdate flag update for emails with fromaddr=Case.OwnerEmail
28-JULY-2015        Jay       3081620
17-August-2015      Jay       3061821     - adding LOE feature for Managed Security also)
24-Aug-2015         Jay       3127251     - filtering queue movement for internal emails
14-Dec-15           Himanshu    3177151     - Set MilestoneFire = First Update for case Object. Modified Method = UpdateIRMilestone,updateCaseStatus
14-Jan-16           Himanshu    3200701   - Set MilestoneFire = Case Update for case Object. Modified Method = UpdateIRMilestone,updateCaseStatus
- Optimized all the Methods
02-Feb-16           Deepak      3287751     - (16.2) - Set Validation Override True for Cases so that it doesn't through an error
03-Dec-2015         Aditya      3239211   - Project MS Azure : Visibility and Internal_Only Validation and Changes
19-Jan-16           Akhila          - Added Stamp_PartnerName_Request_Status method
28-Feb-16           Sonia       3295861     - Added BOCC record type for Case Task LOE calculation
08-Mar-16           Aditya    3330461   - Added AMG and Managed Security RT for updating IR Milestone
17-JUN-2016         Himanshu        - 3333381(16.6)     Update BOCC Milestone
28-JUN-2016         Vamsee          - 3171341(16.7)     EPE Send Email Notification
17-OCT-2016         Himanshu        - 3315501(16.10)     Added Logic to exclude Milestone Update for Luna Web Update
2-MAY-2017          Akhila          - CR 3717992         Added new user for luna case management user
13-02-2018          Sumanth         -ESEP 1005           Extended Task LOE calculation for "Carrier Products" Record type
20-07-2018          Vikas           -ESEP 1325           Extended Task LOE calculation for "Professional Services" Record type
25-10-2018          Vandhana        -ESEP 693            Extended Task LOE calculation for "AMG" Record type
27-06-2019          Vishnu          -ESESP-670           Wake up Transitions on Luna Web Updates
02-Jul-2019         Vishnu          -ESESP-758           Update milestone query to include new AMG milestone - AMG Post Initial Response
27-Sep-2019         Sumanth         -ESESP-2698          SOCC Related Changes
27-Sept-2019        Vishnu          -ESESP-2207          Preventative Activities on Paid Accounts
03-Jan-2020         Sheena Bhan     -ESESP-2869          Added a method to update 'User Set-up' Milestone as completed for AMG Cases. 
10-Feb-2020         Sheena Bhan     -ESESP-3152          Added a method for populating Next Task Due field for AMG cases     
24-Feb-2020         Vandhana        -ESESP-3194          Added logic to populate Last Case Owner and Non Case Owner Update for AMG cases
22 Jan 2021         Vandhana        -ESESP-4625          Milestone widget in home page showing an unexpected message
20 Feb 2021         Vandhana        -ESESP-2346          Carrier LX Migration
24-May-2021			Vamsee			-ESESP-5305			 Mark Isstopped = False before completing the milestone
07-Jan-2022			Sheena			-ESESP-6229			 Populate default values on Task based on Type on Managed Security Cases
*****************************************************************************/

public class TaskTriggerHandler 
{
    public static Boolean updateInternalOnlyFlag = true;//asonam: used in method setVisibilityOnTask to avoid recursion
    public static Boolean updateCaseRelatedFlag = true;
    
    public void onAfterInsert(List<Task> tasks) 
    {
        // List to store all Tasks - Related to Case Object + Type = Call
        List<Task> caseCallTasks = new List<Task>();
        
        // Get the Task Record Type = Service Activity, AMG and Managed Security;
        Id recId = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('Service Activity').getRecordTypeId();
        Id recIdAMG = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('AMG Activity').getRecordTypeId();
        Id recIdManagedSec = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('Managed Security Activity').getRecordTypeId();
        Id recIdBOCC = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('BOCC Activity').getRecordTypeId();
        
        // List to store Unique Case Ids for Task Type = Call
        set<Id> relatedCaseIds_CallType = new set<Id>();
        
        // List to store Unique Case Ids for Milestone Update
        set<Id> relatedCaseIds_MilestoneUpdate = new set<Id>();
        
        //SOCC-Metrics: List to store Cases For Metrics Calculation
        set<Id> relatedCaseIds_SOCCMetrics = new set<Id>();
        
        // Change for ESESP-670 - set of Technical Case Ids of web update tasks
        Set<Id> servCaseIds = new Set<Id>();
        
        for(Task t : tasks) 
        {    
            if(t.WhatId != null && String.valueOf(t.WhatId).startsWith('500')) 
            {
                //if Task is external call activity or Luna Generated Activity(Type=web Update)
                if((t.type__c == 'Call' || t.type__c == 'Web Update') 
                   && t.Internal_Only__c == false 
                   && 
                   (t.RecordTypeId == recId || t.RecordTypeId == recIdAMG || t.RecordTypeId == recIdManagedSec || t.RecordTypeId == recIdBOCC)
                  )
                {
                    System.debug('ENTERED type = CALL');
                    caseCallTasks.add(t);
                    relatedCaseIds_CallType.add(t.WhatId);
                    
                    if(t.type__c != 'Web Update')
                    {
                        System.debug('ENTERED relatedCaseIds_MilestoneUpdate');
                        relatedCaseIds_MilestoneUpdate.add(t.WhatId);
                    }
                    //ESESP-670 - Wake up Transitions when Luna Web Update is applied
                    if( t.RecordTypeId == recId && t.type__c == 'Web Update') {
                        servCaseIds.add(t.WhatId);
                    }
                }
                
              
                /** For SOCC Metrics **/    
                relatedCaseIds_SOCCMetrics.add(t.WhatId);
            }
        }
        
        //ESESP-670 - Wake up Transitions when Luna Web Update is applied
        if(servCaseIds.size() > 0){
            List<case_transition__c>  atsCaseTrasnsition = [select id from case_transition__c where approved_date__c != null AND 
                                                            completed__c = false AND 
                                                            Case__c IN :servCaseIds AND 
                                                            Case__r.RecordType.Name = 'Technical' 
                                                            order by createddate desc];
            
            for(case_transition__c ct: atsCaseTrasnsition) {
                ct.shift_tracker__c = false;
            }
            if(atsCaseTrasnsition.size() > 0)
                update atsCaseTrasnsition;
        }
        
        // Calling TaskLOE Method
        updateTaskLoeOnCase(tasks);
        
        // Calling for Update Milestone Method, UpdateCaseStatus Method
        if(relatedCaseIds_MilestoneUpdate.size() > 0) 
        {
            updateCaseStatus(relatedCaseIds_MilestoneUpdate);
            UpdateIRMilestone(relatedCaseIds_MilestoneUpdate);
        }
        
        if(caseCallTasks.size() > 0) 
        {    
            setRecentUpdateOnCaseTrue(caseCallTasks,relatedCaseIds_CallType);
        }
        
        if(relatedCaseIds_SOCCMetrics.size()>0)
        {
            CalculateSOCCMetrics(relatedCaseIds_SOCCMetrics,tasks);
        }
        
    }
    
    public void onAfterUpdate(List<Task> tasks) 
    {
        updateTaskLoeOnCase(tasks);
    }
    
    public void onAfterDelete(List<Task> tasks) 
    {
        updateTaskLoeOnCase(tasks);
    }
    
    public void onAfterUndelete(List<Task> tasks) 
    {
        updateTaskLoeOnCase(tasks);
    }
    
    //  Method for Updating Milestones to completed
    //Changes by avidapan - CR 2521740
    private void UpdateIRMilestone(set<Id> relatedCaseIds_CallType)
    {
        // get the selected case's Milestone
        list<CaseMilestone> lstCaseMilestoneForUpdate = new list<CaseMilestone>();
        
        //Deepak - iterate on Milestone only when relatedCaseIds_CallType is not null
        if(relatedCaseIds_CallType.size()>0)
        {
            // ESESP-758: added condition to include AMG Post Transition Milestone
            // ESESP-1342: Add condition to include Technical (BOCC) Milestone - Customer Notification
            for(CaseMilestone csMilestone: [Select MilestoneType.Name, Id, CaseId, CompletionDate From CaseMilestone
                                            where CaseId in:relatedCaseIds_CallType and
                                            IsCompleted = false and
                                            MilestoneType.Name IN ('AMG Post Transition Initial Response','Initial Response','First Update', 'Case Update','Time to Respond','Time to Alert','Customer Notification') and case.IsClosed = false])
            {                                    
                csMilestone.CompletionDate = Datetime.now();
                lstCaseMilestoneForUpdate.add(csMilestone);
                
            }
        }
        if(lstCaseMilestoneForUpdate.size() > 0){
            update lstCaseMilestoneForUpdate;
        }
    }
    
    //Method to Change Case status from Assigned to Work IN Progress on Call activity creation
    //This is not applicable for Managed Security record type
    private void updateCaseStatus(set<Id> relatedCaseIds)
    {
        // Case List for Update
        List<Case> lCases = new List<Case>();
        
        // Loop for all Related Cases
        // Deepak - Loop only when relatedCaseIds is not null
        if(relatedCaseIds.size()>0)
        {
            for(Case c : [Select Id,status, Isstopped from Case where Id IN: relatedCaseIds and RecordType.Name != 'Managed Security'])
            {
                //Added by Deepak Saxena
                c.Validation_Override__c = True;
                
                if(c.status == 'Assigned'){
                    c.status='Work in Progress';
                    lCases.add(c);
                }
                //Added By Vamsee - ESESP-5305 (Resume the Milestones before marking the milestone complete)
                if(c.Isstopped == True){
                    c.Isstopped = False;
                    lCases.add(c);
                }
                
            }
        }
        
        if(lCases.size() > 0)
            update lCases;
    }
    
    /* CR 2985554 - ssawhney
This method is used to mark the flag isCaseRelated to push a notification for SOC Cases
*/
    public static void markCaseRelatedTask(Task[] taskList)
    {
        if(updateCaseRelatedFlag)
        {
            set<Id> caseIds = new set<Id>();
            set<Task> lstTasks = new set<Task>();
            Set<String> CaseRecordTypes = new Set<String>();
            String wId;
            
            for(SC_StreamTaskForCaseRT__c  rt : SC_StreamTaskForCaseRT__c.getAll().Values()) {
                CaseRecordTypes.add(rt.RecordTypeName__c);
            }
            
            for(Task tsk : taskList){
                wId = tsk.WhatId;
                if(wId!=null && wId.startsWith(Schema.Sobjecttype.Case.getKeyPrefix()) && tsk.Is_Case_Related__c != true)
                {
                    caseIds.add(tsk.WhatId);
                    lstTasks.add(tsk);
                }
            }
            if(caseIds.size() > 0)
            {
                map<Id, Case> mpCases = new map<Id, Case>([Select Id, RecordType.DeveloperName From Case Where Id IN:caseIds]); 
                
                for(Task tsk : lstTasks){
                    string recTypeName = mpCases.get(tsk.WhatId).RecordType.DeveloperName;
                    if(CaseRecordTypes.contains(recTypeName))
                    {
                        tsk.Is_Case_Related__c = true;
                    }
                }
            }
            updateCaseRelatedFlag = false;
        }
    }
    /* CR 2985554 - ssawhney: End of code Addition*/
    
    // Method for Calculation sum of Individual Task LOE and update the same on Case Object
    private void updateTaskLoeOnCase(List<Task> tasks)
    {
        // List to store Unique Case Ids for Object = Case
        set<Id> relatedCaseIds = new set<Id>();
        
        for(Task t : tasks) 
        {
            if(t.WhatId != null && String.valueOf(t.WhatId).startsWith('500')) 
            {    
                relatedCaseIds.add(t.WhatId);
            }
        }
        
        //Loop for all the Task for setting - CaseId_TotalLOE_Map
        // Loop only if relatedCaseIds is not null
        if(relatedCaseIds.size()>0)
        {
            //ESESP-2207 : Added logic to calculate Preventative, Proactive, Reactive LOE
            // changes by Vandhana for ESESP-2346 Carrier LX Migration (removed Carrier Products Record Type)
            List<String> caseRts = new List<String>{'Technical', 'Stability Engineering', 'Managed Security', 'AMG', 'Professional Services'};
                List<Case> toUpdCases = new List<Case>();
            for(Case cs: [select id, RecordType.Name, Proactive_LOE__c, Preventative_LOE__c,Task_LOE__c, Support_Level__c,
                          (select id, LOE_hours__c, Type__c from tasks) 
                          from case where id in :relatedCaseIds and RecordType.Name in :caseRts]) 
            {
                               Decimal totalLOE = 0,
                               preventativeLOE = 0,
                               proactiveLOE = 0;
                              

                for(Task ts: cs.Tasks) 
                {    
                    if(ts.LOE_hours__c == null) 
                    {

                        continue;
                    }
                    totalLOE += ts.LOE_hours__c;
                    if(ts.Type__c == 'Preventative' && cs.RecordType.Name == 'Technical') {
                        preventativeLOE += ts.LOE_hours__c;
                    } 
                    else if(ts.Type__c != null && ts.Type__c.containsIgnoreCase('Proactive') && cs.RecordType.Name == 'Technical') {
                        proactiveLOE += ts.LOE_hours__c;
                    }
                }
                if(totalLOE !=0 || proactiveLOE !=0 || preventativeLOE !=0){
                    cs.Task_LOE__c = totalLOE;
                    cs.Proactive_LOE__c = proactiveLOE;
                    cs.Preventative_LOE__c = preventativeLOE;
                    cs.Validation_Override__c = true;
                    toUpdCases.add(cs);
                    System.debug('Task LOE : ' + cs.Task_LOE__c);
                    //System.assertEquals(-1,cs.Task_LOE__c);
                }
            }
            if(toUpdCases.size() > 0) 
            {
                SC_CaseIssueClass.byPassCaseIssueRUSOCC = true;//Static variable to bypass recent update code block in SC_CaseIssueClass
                update toUpdCases;
            }
        }
    }
    
    /*
* Name      : setRecentUpdateOnCaseTrue
* Purpose : Set Case.Recent_Update__c = true on Case if a new task related to case is created and case owner != task creater.
*                   Set Case.Last_Case_Update__c = Now if new task have Case_Update__c set to true as per T-165897.
*/
    private static void setRecentUpdateOnCaseTrue(List<Task> tasks, set<Id> relatedCaseIds_CallType)
    {
        // List of Task to Notify Luna
        list<Task> lTaskToNotify = new list<Task>();
        
        // List to store all the Cases for Update
        List<Case> recentUpdatedCases = new List<Case>();
        
        // Set to store Unique Case Ids
        Set<Id> recentUpdatedCaseIds = new Set<Id>();
        Map<Id, Case> caseMap;
        // Deepak - Execute only when relatedCaseIds_CallType is not null
        if(relatedCaseIds_CallType.size()>0)
        {
            // Map to store Case Id - Case from Query
            caseMap = new Map<Id, Case>(
                [Select Id, Recent_Update__c, Last_Case_Update__c,Akam_Case_ID__c,
                 Contact.Name,Contact_Portal_Login__c,Support_Level__c,Owner.email,Recordtype.Name,
                 Resolved_Date__c, ownerId, Isclosed, Last_Case_Owner_Update__c, Last_Non_Case_Owner_Update__c
                 from Case
                 Where Id IN : relatedCaseIds_CallType]);
            
            // For individual Case
            Case cs;
            
            // Loop for all the Tasks
            for(Task t : tasks) 
            {    
                cs = caseMap.get(t.WhatId);
                cs.Validation_Override__c = True;

                // If Case is closed, then bypass the Update
                if(cs.Isclosed) 
                {
                    continue;
                }
                
                if(t.Type__c == 'Call' && cs.RecordTypeId == Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('AMG').getRecordTypeId()
                  && t.Internal_Only__c == false )
                {
                    if(t.CreatedById == cs.OwnerId)
                    {
                        cs.Last_Case_Owner_Update__c = System.now();
                    }
                    else
                    {
                        cs.Last_Non_Case_Owner_Update__c = System.now();
                    }
                    //System.assertEquals(1,2);
                }
                                
                // For Sending Email to Luna
                if(t.OwnerId == SCUserIdCustomSetting__c.getValues('LunaPortalIntegration').UserId__c 
                   || t.OwnerId == SCUserIdCustomSetting__c.getValues('PulsarCaseMgmtUserID').UserId__c)
                {
                    lTaskToNotify.add(t);
                }
                
                //Akhila - added condition to bypass below logic for activities created by owner himself by sending emails to case
                if(!t.isCreatedByUser__c && cs.ownerId != t.CreatedById ) 
                {
                    cs.Recent_Update__c = true;    
                }
                
                // If Task is Created by Luna User, then set Last Customer Activity Date else set Last Case Update Date
                if((t.CreatedById == SCUserIdCustomSetting__c.getValues('LunaPortalIntegration').UserId__c
                    || t.CreatedById == SCUserIdCustomSetting__c.getValues('PulsarCaseMgmtUserID').UserId__c) 
                   && t.type__c == 'Web Update')
                {       
                    cs.Last_Customer_Activity_Date__c = Datetime.now();
                }
                else
                {    
                    //Set Case.Last_Case_Update__c = Now
                    cs.Last_Case_Update__c = Datetime.now();
                }
                
                // Adding the Case to Update List
                if(recentUpdatedCaseIds.add(cs.Id))
                    recentUpdatedCases.add(cs);
            }
        }
        
        
        // Updating the Cases
        // Deepak - Update only when recentUpdatedCases is not null
        if(recentUpdatedCases.size()>0)
        {
            Update recentUpdatedCases;
        }
        
        if(lTaskToNotify.size()>0 && caseMap !=null){
            SCCaseAttachmentHandler instanceOfSCCaseAttachmentHandler = new SCCaseAttachmentHandler();
            instanceOfSCCaseAttachmentHandler.sendEmailOnTaskCreation(lTaskToNotify, caseMap);
        }
    }
    
    /**
*  Description - update Type__c and Internal_Only__c field when subject of Task = Call
*  Related Task/Issue - I-74793
*  Created By - Satyanarayan choudhary(JDC Developer)
*/
    public void updateTypeAndInternalOnly(List<Task> lstTask)
    {
        Id rtype = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('Service Activity').getRecordTypeId();
        
        for(Task sObjTask : lstTask)
        {
            if(sObjTask.Subject == 'Call log')
            {
                sObjTask.Type__c = 'Call';
                sObjTask.Internal_Only__c =  false;
                sObjTask.Visibility__c = 'Customer';//asonam:added as part of MS Azure,to populate field Visibility
                sObjTask.RecordTypeId = rtype;
                //Commented by Deepak Saxena as part of CR 3303121
                //sObjTask.Case_Update__c = true;
            }
        }
    }
    
    public static Boolean recCheck=false;
    public static void erValidationForTaskCreateUpdate(List<Task> lNewTask,List<Task> lOldTask,
                                                       Boolean isInsert, Boolean isUpdate)
    {
        
        Id serviceActivityRTId = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('Service Activity').getRecordTypeId();
        Id mangedSecurityActivityRTId = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('Managed Security Activity').getRecordTypeId();
        Id outboundERRTId = Engagement_Request__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Escalation to Microsoft Azure').getRecordTypeId();
        Id inboundERRTId = Engagement_Request__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Escalation From Microsoft Azure').getRecordTypeId();
        
        List<Task> lTaskForInsertOrUpdate = new List<Task>();
        List<String> lTaskWhatId = new List<String>();
        
        Set<String> sCasesToIgnoreValidationRule = new Set<String>();
        
        Map<String,Case> mCaseAndMSAccount = new Map<String,Case>();
        
        if((isUpdate || isInsert) && !recCheck){
            for(integer i=0;i < lNewTask.size();i++){
                if((lNewTask[i].RecordTypeId == serviceActivityRTId || lNewTask[i].RecordTypeId == mangedSecurityActivityRTId)
                   && lNewTask[i].WhatId != Null
                   && String.valueof(lNewTask[i].whatId).substring(0,3) == '500'
                   && !lNewTask[i].Task_Validation_Override__c
                   && lNewTask[i].Type__c != 'Email'){
                       
                       /*if(lNewTask[i].Visibility__c == 'Partner Only'){
sCasesToIgnoreValidationRule.add(lNewTask[i].WhatId);
}*/
                       
                       if(isUpdate
                          && lNewTask[i].Partner_Receipt_Status__c != lOldTask[i].Partner_Receipt_Status__c){
                              
                              sCasesToIgnoreValidationRule.add(lNewTask[i].WhatId);
                          }
                       lTaskForInsertOrUpdate.add(lNewTask[i]);
                       lTaskWhatId.add(lNewTask[i].WhatId);
                   }
            }
            System.debug('### ' + lTaskForInsertOrUpdate);
            if(!lTaskForInsertOrUpdate.isEmpty())
            {
                
                for(Case varCase :[SELECT Id,IsMicrosoftAzureAccount__c 
                                   FROM Case WHERE Id IN :lTaskWhatId])
                {
                    mCaseAndMSAccount.put(varCase.Id, varCase);
                }
                for(Engagement_Request__c varER :[SELECT id,Partner_Ticket__c,Request_Status__c,RecordTypeID,Case__c,
                                                  Case__r.IsMicrosoftAzureAccount__c,Case__r.Partner_Joint_Troubleshooting_Status__c
                                                  FROM Engagement_Request__c
                                                  WHERE Case__c IN : lTaskWhatId
                                                  AND (RecordTypeID = : outboundERRTId OR RecordTypeID = : inboundERRTId)
                                                  AND Case__r.IsMicrosoftAzureAccount__c = True
                                                  AND Partner_Ticket__c != null
                                                  AND Request_Status__c = 'Open'
                                                  AND Case__r.Partner_Joint_Troubleshooting_Status__c = 'Open'])
                {
                    sCasesToIgnoreValidationRule.add(varER.Case__c);                    
                }
                
                for(Task varTask :lTaskForInsertOrUpdate)
                {
                    if(!sCasesToIgnoreValidationRule.contains(varTask.WhatId)
                       && varTask.Visibility__c == 'Partner Only')
                    {
                        if(mCaseAndMSAccount.get(varTask.WhatId).IsMicrosoftAzureAccount__c)
                        {
                            varTask.addError('You can not set visibility to '+varTask.Visibility__c+' : '+
                                             'There are no Open Engagement Request associated to the Case or Partner Ticket # is Null or '+
                                             'Joint Collaboration is closed');
                        }
                        else
                        {
                            varTask.addError('Visibility can be set as \'Partner Only\' only if case is associated with a Partner Account and Joint Troubleshooting Status is Open');     
                        }    
                    }
                }
            }
        }
        recCheck = true;
    }
    
    /*********    asonam: Start of MS Azure Changes related to field Visibility__c and Internal_Only__c   *********/
    //Method to set Visibility Flag when Internal Only field is checked and vice a versa as part of MS Azure
    //Called from TaskTrigger_bi_bu
    public static void setVisibilityOnTask(List<Task> taskNewList)
    {
        if(updateInternalOnlyFlag)
        {
            //Fetching Service Activity Record Type
            Id SerActRecType = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('Service Activity').getRecordTypeId();
            Id MSActRecType = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('Managed Security Activity').getRecordTypeId();
            
            for(task forEachTsk : taskNewList)
            {
                if((forEachTsk.RecordTypeID == SerActRecType || forEachTsk.RecordTypeID == MSActRecType) && forEachTsk.Visibility__c != 'Customer'
                   && forEachTsk.Internal_only__c == False && forEachTsk.Visibility__c != Null)
                {
                    forEachTsk.Internal_only__c = True;
                }
                else if((forEachTsk.RecordTypeID == SerActRecType || forEachTsk.RecordTypeID == MSActRecType) && forEachTsk.Visibility__c == 'Customer'
                        && forEachTsk.Internal_only__c == True && forEachTsk.Visibility__c != Null)
                {
                    forEachTsk.Internal_only__c = False;
                }
            }
            //set recursive trigger flag to false--
            updateInternalOnlyFlag = false;
        }
    }
    
    // Called from TaskTrigger_bi_bu
    // Method stops setting Visibility as Partner Only for Non Partner Account and Closed Collaboration
    /*public static void partnerOnlyVisibilityCheck(List<Task> lNewTask,List<Task> lOldTask,
Boolean isInsert, Boolean isUpdate){
Id serviceActivityRTId = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('Service Activity').getRecordTypeId();
Id mangedSecurityActivityRTId = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('Managed Security Activity').getRecordTypeId();

List<Task> lTaskForInsertOrUpdate = new List<Task>();
List<String> lTaskWhatId = new List<String>();

Set<String> sCasesToIgnoreValidationRule = new Set<String>();



}

//Method to set validation Rule on Task Creation when ER Request Status = Closed and Ticket No. Is Null for MSAzure
//Called from TaskTrigger_bi_bu
public static void erValidationForTaskCreateUpdate(List<Task> lNewTask,List<Task> lOldTask,
Boolean isInsert, Boolean isUpdate){

Id serviceActivityRTId = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('Service Activity').getRecordTypeId();
Id mangedSecurityActivityRTId = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('Managed Security Activity').getRecordTypeId();
Id outboundERRTId = Engagement_Request__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Escalation to Microsoft Azure').getRecordTypeId();
Id inboundERRTId = Engagement_Request__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Escalation From Microsoft Azure').getRecordTypeId();

List<Task> lTaskForInsertOrUpdate = new List<Task>();
List<String> lTaskWhatId = new List<String>();

Set<String> sCasesToIgnoreValidationRule = new Set<String>();

if(isUpdate || isInsert){
for(integer i=0;i < lNewTask.size();i++){
if((lNewTask[i].RecordTypeId == serviceActivityRTId || lNewTask[i].RecordTypeId == mangedSecurityActivityRTId)
&& lNewTask[i].WhatId != Null
&& String.valueof(lNewTask[i].whatId).substring(0,3) == '500'
&& !lNewTask[i].Task_Validation_Override__c
&& lNewTask[i].Type__c != 'Email'){

if(lNewTask[i].Visibility__c == 'Partner Only'){
sCasesToIgnoreValidationRule.add(lNewTask[i].WhatId);
}

else if(isUpdate
&& lNewTask[i].Partner_Receipt_Status__c != lOldTask[i].Partner_Receipt_Status__c){

sCasesToIgnoreValidationRule.add(lNewTask[i].WhatId);
}
lTaskForInsertOrUpdate.add(lNewTask[i]);
lTaskWhatId.add(lNewTask[i].WhatId);
}
}
if(!lTaskForInsertOrUpdate.isEmpty()){
for(Engagement_Request__c varER :[SELECT id,Partner_Ticket__c,Request_Status__c,RecordTypeID,Case__c,
Case__r.IsMicrosoftAzureAccount__c,Case__r.Partner_Joint_Troubleshooting_Status__c
FROM Engagement_Request__c
WHERE Case__c IN : lTaskWhatId
AND (RecordTypeID = : outboundERRTId OR RecordTypeID = : inboundERRTId)
AND Case__r.IsMicrosoftAzureAccount__c = True
AND Partner_Ticket__c != null
AND Request_Status__c = 'Open'
AND Case__r.Partner_Joint_Troubleshooting_Status__c = 'Open']){
sCasesToIgnoreValidationRule.add(varER.Case__c);
}
}

for(Task varTask :lTaskForInsertOrUpdate){
if(!sCasesToIgnoreValidationRule.contains(varTask.WhatId)){
varTask.addError('You can not set visibility to '+varTask.Visibility__c+' : '+
'There are no Open Engagement Request associated to the Case or Partner Ticket # is Null or '+
'Joint Collaboration is closed');
}
}
}
}
*/
    //Called from Trigger TaskTrigger_bi_bu
    //Method to set the visibility to customer for all the service and managed security task created by luna portal.
    Public static void setVisibilityforLunaPortal(List<Task> tskList)
    {
        List<Task> lSCTasks = new List<Task>();
        for(Task varTask :tskList){
            if(varTask.WhatId != null && String.valueof(varTask.whatId).startsWith('500')){
                lSCTasks.add(varTask);
            }
        }
        if(!lSCTasks.isEmpty()){
            Id lunaCaseMgmtUserId = SCUserIdCustomSetting__c.getValues('LunaCaseMgmtUserID').UserId__c;
            Id pulsarCaseMgmtUserId = SCUserIdCustomSetting__c.getValues('PulsarCaseMgmtUserID').UserId__c;            
            Id SerActRecType = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('Service Activity').getRecordTypeId();
            Id MSActRecType = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('Managed Security Activity').getRecordTypeId();
            for(task tsk :lSCTasks){
                
                if( (UserInfo.getUserId() == lunaCaseMgmtUserId || UserInfo.getUserId() == pulsarCaseMgmtUserId) && (tsk.RecordTypeID == SerActRecType || tsk.RecordTypeID == MSActRecType)){
                    tsk.Visibility__c = 'Customer';
                }
            }
        }
    }
    
    
    /*********    asonam: End of MS Azure Changes related to field Visibility__c and Internal_Only__c   *********/
    
    //avidapan:Stamp the partner name and Request Status on non internal activity if case is tied to a partner eg: MSAzure
    Public static void stamp_PartnerName_Receipt_Status(List<Task> newTaskList,Map<Id,Task> oldMap,Boolean isInsert)
    {
        List<String> lCaseIds = new List<String>();
        List<Task> lTasks = new List<Task>();
        Id serviceActivityRtId = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('Service Activity').getRecordTypeId();
        Id MSActivityRtId = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('Managed Security Activity').getRecordTypeId();
        String whatId;
        for(Task t : newTaskList)
        {
            whatId = t.WhatId;
            //Consider only those tasks which are not internal,
            if(t.Visibility__c!='Internal Only' && whatId!=null && whatId.startsWith('500') && (t.RecordTypeId==serviceActivityRtId || t.RecordTypeId==MSActivityRtId) && t.Type__c != 'Inbound Partner Activity')
            {
                lCaseIds.add(t.WhatId);
                lTasks.add(t);
                //system.debug('******'+t);
            }
        }
        
        if(lTasks.size() > 0)
        {
            Map<Id,Case> mCases = new Map<Id,Case>([Select Id,IsMicrosoftAzureAccount__c,Partner_Joint_Troubleshooting_Status__c  from Case where Id IN : lCaseIds and IsMicrosoftAzureAccount__c=true and Partner_Joint_Troubleshooting_Status__c='Open']);
            system.debug(mCases);
            Case c = new Case();
            for(Task t : lTasks)
            {
                c = mCases.get(t.WhatId);
                if(c!=null)
                {
                    //Stamp Partner Name and Receipt Status as new when Task is created
                    
                    //Stamp Receipt status as awaiting when it is inserted or visibility changed from internal or description is changed
                    if((isInsert || t.Description!=oldMap.get(t.Id).Description || t.Subject!=oldMap.get(t.Id).Subject ||
                        (oldMap.get(t.Id).Visibility__c=='Internal Only' && t.Visibility__c!=oldMap.get(t.Id).Visibility__c)
                        || oldMap.get(t.Id).Status!=t.Status) && t.Status == 'Completed')
                        t.Partner_Receipt_Status__c='Awaiting Receipt';
                }
            }
        }
    }
    
    /**** Calculation of All SOCC Metrics ****/
    public static void CalculateSOCCMetrics(set<Id> relatedCaseIds_SOCCMetricsIR,List<Task> Tasks)
    {
        //Final List of Cases to Update
        List<Case> FinalUpdateList = new List<Case>();
        
        // List of Parent Case Id for which Task Type = Call
        set<Id> allCaseid_call = new set<Id>();
        
        //List of Parent Case Id for which Task Type =  Web Update
        set<Id> allCaseid_Luna = new set<Id>();
        
        List<Case> FinalUpdateListCall = new List<Case>();
        
        // Filtering type = call
        for(Task eachTaskRec : Tasks){
            
            if(eachTaskRec.Type__c == 'Call')
                allCaseid_call.add(eachTaskRec.WhatId);
            if(eachTaskRec.Type__c =='Web Update')
                allCaseid_Luna.add(eachTaskRec.WhatId);
        }
        
        //Create a Map of Case Id and Case
        Map<Id,Case> relevantCaseMap = new Map<Id,Case>([Select Id,CreatedDate,Origin,Recent_Update__c,CreatedBy.Name, Alert_Start_Time__c, Initial_Response_SOCC__c, First_Customer_Update_SOCC__c,Initial_Response_SOCC_Date__c,Real_Engagement_Time__c from Case where RecordType.Name='Managed Security' and Id in :relatedCaseIds_SOCCMetricsIR ]);
        
        /*** Prepare Data & HandOver ***/
        Map<Id,Case> SOCCIRCaseMap   = new Map<Id,Case>();             //IR Calculation
        Map<Id,Case> SOCCFirstUpdateCaseMap   = new Map<Id,Case>();    //First Update Calculation
        Map<Id,Case> SOCCRealEngageMap   = new Map<Id,Case>();         //Real Engagement Calculation
        
        
        for(Case C: relevantCaseMap.values())
        {
            
            //
            if(allCaseid_call.contains(C.Id) && C.Recent_Update__c == true) 
            {  
                FinalUpdateListCall.add(new Case(Id=C.Id,Recent_Update__c = false));
            }
            
            //For Luna Update
            if(allCaseid_Luna.contains(C.Id) && C.Recent_Update__c == false)
            {
                FinalUpdateListCall.add(new Case(Id=C.Id,Recent_Update__c = true));
            }
            
            
            if(C.Initial_Response_SOCC__c==null)
            {
                SOCCIRCaseMap.put(C.Id,C);
            }
            
            
            else 
            {
                if(C.Initial_Response_SOCC__c!=null && C.First_Customer_Update_SOCC__c == null)
                {
                    SOCCFirstUpdateCaseMap.put(C.Id,C);
                }
                
                if(C.Initial_Response_SOCC__c!=null && C.Real_Engagement_Time__c==null )
                {
                    SOCCRealEngageMap.put(C.Id,C);
                }
                
            }
            
            
            
        }
        
        if(SOCCIRCaseMap.size()>0)
        {
            List<Case> SOCCIRCasetoUpadate = CalculateSOCCIRMetrics(SOCCIRCaseMap,Tasks);   
            FinalUpdateList.addAll(SOCCIRCasetoUpadate);
        }
        
        if(SOCCFirstUpdateCaseMap.size()>0)
        {
            List<Case> SOCCFUCasetoUpadate = CalculateSOCCFUMetrics(SOCCFirstUpdateCaseMap,Tasks);   
            FinalUpdateList.addAll(SOCCFUCasetoUpadate);
        }
        if(SOCCRealEngageMap.size()>0)
        {
            System.debug('Entering HEre');
            List<Case> SOCCRealCasetoUpadate = CalculateSOCCRealMetrics(SOCCRealEngageMap,Tasks);   
            FinalUpdateList.addAll(SOCCRealCasetoUpadate);
        }
        
        
        
        
        //Final Update Call
        if(FinalUpdateList.size()>0)
        {
            Update FinalUpdateList;
        }
        
        if(FinalUpdateListCall.size()>0)
        {
            Update FinalUpdateListCall;
        }
        
        
        
    }
    
    /** Method to calculate IR **/
    public static List<Case> CalculateSOCCIRMetrics(Map<Id,Case> SOCCIRCaseMap,List<Task> Tasks)
    {
        List<Case> CasetoUpdateSOCCIR = new List<Case>();
        for(Task t :tasks)
        {
            if(SOCCIRCaseMap.Keyset().contains(t.WhatId) && t.Type__c=='Call')
            {
                //TaskCaseMapSOCCIR.put(T.Id,SOCCIRCaseMap.get(t.parentId));
                Case varCase = SOCCIRCaseMap.get(t.WhatId);
                If(varCase.Origin=='Email' || (varCase.Origin=='Web' && ((varCase.CreatedBy.Name=='Pulsar Case Mgmt') || (varCase.CreatedBy.Name=='Luna Case Mgmt'))))
                {
                    Long seconds = (t.CreatedDate.getTime()- varCase.CreatedDate.getTime())/1000;
                    varCase.Initial_Response_SOCC__c = DateTime.valueOf(seconds*1000).formatGMT('HH:mm:ss');
                    varCase.Initial_Response_SOCC_Date__c  = System.now();
                    CasetoUpdateSOCCIR.add(varCase);
                    
                }
                
                If(varCase.Origin=='Web' && varCase.CreatedBy.Name=='Mako Application')
                {
                    if(varCase.Alert_Start_Time__c!=null)
                    {
                        Long seconds = (t.CreatedDate.getTime()- varCase.Alert_Start_Time__c.getTime())/1000;
                        varCase.Initial_Response_SOCC__c = DateTime.valueOf(seconds*1000).formatGMT('HH:mm:ss');
                        varCase.Initial_Response_SOCC_Date__c  = System.now();
                        CasetoUpdateSOCCIR.add(varCase);
                    }
                }
                
            }
            
        }
        
        return CasetoUpdateSOCCIR;
        
    }
    
    /**Method to calculate First Update **/
    public static List<Case> CalculateSOCCFUMetrics(Map<Id,Case> SOCCFirstUpdateCaseMap,List<Task> Tasks)
    {
        List<Case> CasetoUpdateSOCCFU = new List<Case>();
        for(Task t :tasks)
        {
            if(SOCCFirstUpdateCaseMap.keyset().contains(t.WhatId) && t.Type__c=='Call')
            {
                Case varCase = SOCCFirstUpdateCaseMap.get(t.WhatId);
                Long seconds = (t.CreatedDate.getTime()- varCase.Initial_Response_SOCC_Date__c.getTime())/1000;
                varCase.First_Customer_Update_SOCC__c  = DateTime.valueOf(seconds*1000).formatGMT('HH:mm:ss');
                CasetoUpdateSOCCFU.add(varCase);
                
            }
        }
        
        return CasetoUpdateSOCCFU;
        
        
    }
    
    /**Method to Calculate Real Engagement time **/
    public static List<Case> CalculateSOCCRealMetrics(Map<Id,Case> SOCCRealEngageMap,List<Task> Tasks)
    {
        List<Case> CasetoUpdateSOCCReal = new List<Case>();
        for(Task t:tasks)
        {
            system.debug('Task Type' + t.Type__c);
            if(SOCCRealEngageMap.keyset().contains(t.WhatId) && t.Type__c!='Call' && t.Type__c!='Email' && t.Type__c!=null && t.Type!='Email')
            {
                System.debug('Entering Calculation of RealEngegment time');
                Case varCase = SOCCRealEngageMap.get(t.WhatId);
                Long seconds = (t.CreatedDate.getTime()- varCase.Initial_Response_SOCC_Date__c.getTime())/1000;
                varCase.Real_Engagement_Time__c = DateTime.valueOf(seconds*1000).formatGMT('HH:mm:ss');
                CasetoUpdateSOCCReal.add(varCase);
                
            }
        }
        return CasetoUpdateSOCCReal;
    }
    
    //Changes by Sheena for ESESP-2869: Method to update the User Set-up Milestone as completed.
    public static void updateUserSetupMilestone(map<string,task> caseTaskMap, Boolean isUpdate, Map<Id,Task> oldMap)
    {
        system.debug('In updateUserSetupMilestone');
        List<CaseMilestone> caseMilestonesToUpdate = new List<CaseMilestone>();
        if(caseTaskMap.size()>0)
        {
            for(CaseMilestone caseMilestone: [Select MilestoneType.Name, Id, CaseId, CompletionDate, StartDate, TargetDate, IsViolated From CaseMilestone
                                              where CaseId in:caseTaskMap.keySet() and
                                              MilestoneType.Name = 'User Setup' and 
                                              case.RecordType_Name__c='AMG' and
                                              case.IsClosed = false])
                
            {    
                if(caseTaskMap.get(caseMilestone.CaseId).Status == 'Completed')
                {
                    system.debug('In updateUserSetupMilestone1');
                    
                    if(isUpdate && 
                       (caseTaskMap.get(caseMilestone.CaseId).Task_Deferred_Notes__c == 'Postponed - Agreed with Customer/IAT' 
                        || 
                        oldMap.get(caseTaskMap.get(caseMilestone.CaseId).Id).Status == 'Postponed - Agreed with Customer/IAT'
                       ))
                    {
                        // changes by Vandhana for ESESP-4625 Milestone widget in home page showing an unexpected message
                        if(caseTaskMap.get(caseMilestone.CaseId).ActivityDate > System.now())
                        {   caseMilestone.CompletionDate = System.now(); }
                        else
                        {   caseMilestone.CompletionDate = caseTaskMap.get(caseMilestone.CaseId).ActivityDate;}
                        // end of changes by Vandhana
                    }
                    else
                    {
                        caseMilestone.CompletionDate = system.now();
                    }
                    caseMilestonesToUpdate.add(caseMilestone);
                }
                
                if(caseTaskMap.get(caseMilestone.CaseId).Status=='In Progress' 
                   || caseTaskMap.get(caseMilestone.CaseId).Status=='Not Started')
                {
                    system.debug('In updateUserSetupMilestone2');
                    caseMilestone.CompletionDate = null;
                    caseMilestonesToUpdate.add(caseMilestone);
                }
                
                if((caseTaskMap.get(caseMilestone.CaseId).Status=='Postponed - Agreed with Customer/IAT' 
                    || caseTaskMap.get(caseMilestone.CaseId).Status=='Not Applicable') 
                   && caseTaskMap.get(caseMilestone.CaseId).ActivityDate > system.now() )
                {
                    system.debug('In updateUserSetupMilestone3');
                    caseMilestone.CompletionDate = system.now();
                    caseMilestonesToUpdate.add(caseMilestone);
                }
                if((caseTaskMap.get(caseMilestone.CaseId).Status=='Postponed - Agreed with Customer/IAT' 
                    || caseTaskMap.get(caseMilestone.CaseId).Status=='Not Applicable') 
                   && caseTaskMap.get(caseMilestone.CaseId).ActivityDate < system.now() )
                {
                    system.debug('In updateUserSetupMilestone4');
                    caseMilestone.CompletionDate = caseTaskMap.get(caseMilestone.CaseId).ActivityDate;
                    caseMilestonesToUpdate.add(caseMilestone);
                }
                system.debug('caseMilestonesToUpdate///'+caseMilestonesToUpdate);
                
            }
        }
        if(caseMilestonesToUpdate.size() > 0){
            update caseMilestonesToUpdate;
        }
    }
    // Changes End
    
    
    //ESESP-3152: Method for populating Next Task Due field for AMG cases    
    
    public static void addNextTaskDue(Set<Id> caseIds)
    {
        List<Case> casesToUpt = new List<Case>();
        Id recId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('AMG').getRecordTypeId();
        
        List<Case> caseList = [select id,Next_Task_Due__c,RecordTypeId,(select id, ActivityDate from Tasks WHERE ActivityDate != NULL and Status != 'Completed' ORDER BY ActivityDate ASC LIMIT 1)  from Case where id =: caseIds and RecordTypeId=:recId and Status != 'Closed'];
        system.debug('caseList//'+caseList);
        
        for(Case cs:caseList)
        {
            if(cs.Tasks.size()>0)
            {
                system.debug('cs.Tasks[0].ActivityDate//'+cs.Tasks[0].ActivityDate);
                cs.Next_Task_Due__c = cs.Tasks[0].ActivityDate;
                casesToUpt.add(cs) ; 
            }
        }
        
        if(!casesToUpt.isEmpty())
        {
            system.debug('casesToUpt update');
            update casesToUpt;
        }       
        
    }
    /* Changes by Sheena for ESESP-6229 - Populate default values for task on Managed Security Cases
	   Called from TaskTrigger_bi_bu trigger */
    public static void defaultSOCCTaskLOE(List<Task> taskList, Map<Id,Task> oldTaskMap, Boolean isInsert)
    {
        Set<Id> caseIds = new Set<Id>();
        Map<String,String> taskType_Loe_Map = new Map<String,String>();
        for(SC_Utility__mdt soccTaskType : [SELECT Value_Text__c,DeveloperName,Label FROM SC_Utility__mdt
                                            WHERE DeveloperName like 'SOCC_task_Type%']){
                                                taskType_Loe_Map.put(soccTaskType.label,soccTaskType.Value_Text__c);
                                            }
        for(Task t: taskList){
            if(t.LOE_hours__c == null &&(isInsert || (!isInsert && oldTaskMap.get(t.Id).LOE_hours__c!=t.LOE_hours__c)) &&
               t.WhatId != null && String.valueOf(t.WhatId).startsWith('500') && taskType_Loe_Map.containsKey(t.Type__c))
            {    
                caseIds.add(t.WhatId);
            }
        }
        Map<Id,Case> soccCaseMap = new map<id,Case>([Select id  from Case where id =: caseIds and RecordType.Name = 'Managed Security']);
        
        if(!soccCaseMap.isEmpty()){
            for(Task t: taskList){
                if(soccCaseMap.containsKey(t.whatId) && taskType_Loe_Map.containsKey(t.Type__c)){
                    t.LOE_hours__c = (Decimal.valueOf(taskType_Loe_Map.get(t.Type__c)));
                }
            }
        }
    }
    
}