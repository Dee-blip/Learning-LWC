/***
    TaskTrigger_bi_bu
    @author Karteek Mekala <kmekala@akamai.com>
    @Description : This trigger is called on 'before insert, before update'
                   The following is achieved :
                    1. Populate the "Task.Associated Account" and "Task.Associated Opportunity" according to "Task.WhatId"    
                    2. If "Task.RecordType" = "Order Approval Activity"
                        - Update AKAM Created/Created By/System when a record is created and either values is left blank
                        - The "Task.TaskType" is updated according to the Profile of the "Task.Owner"
                        - This update to "Task.Type" inturn affects the Order through OrderApprovalClass.OrderApprovalActivity_UpdateOrder
                        
 * History (include TaskTrigger.Trigger):
 * =================================================================================================
 * Developer        Date        Description
 * --------------------------------------------------------------------------------------------------
 * Dan Pejanovic    1/2010      Created Class
 * Karteek Kumar M  1/2010      Commented out Line 71
 * Dan Pejanovic    1/2010      cleaned up code, removed OD field updates
 * Karteek Kumr M   1/2020      Changed types for variables: 
                                cMap : Map<Id, Contact> ->  Map<String, Contact>
                                oMap : Map<Id, Opportunity> ->  Map<String, Opportunity>
                                mMap : Map<Id, Campaign> ->  Map<String, Campaign>
                                aMap : Map<Id, Account> ->  Map<String, Account>
                                While updating Task as CRM Integration user, "ADDED CRITERIA IN THE IF CONDITIONS" to make code reachable :
                                Line 63 -> t3.Associated_AKAM_Contact_ID__c!=null
                                Line 65 -> t3.Associated_AKAM_Opportunity_ID__c!=null
                                Line 69 -> t3.Associated_AKAM_Campaign_ID__c!=null
                                Line 71 -> t3.Associated_AKAM_Account_ID__c!=null
* Karteek Kumar M   1/2010      Changed criteria :
                                cMap.containsKey(t3.Associated_AKAM_Opportunity_ID__c))     ->   oMap.containsKey(t3.Associated_AKAM_Opportunity_ID__c))
                                cMap.containsKey(t3.Associated_AKAM_Campaign_ID__c          ->   mMap.containsKey(t3.Associated_AKAM_Campaign_ID__c
                                cMap.containsKey(t3.Associated_AKAM_Account_ID__c           ->   aMap.containsKey(t3.Associated_AKAM_Account_ID__c
                                
* Eric Jerskey      1/2010      Added replace logic for OwnerId, AKAM_CreatedBy and AKAM_ModifiedBy
* Karteek Kumar M   1/2010      Merged the changes Eric made in QA with the changes Dan made in test.
                                The change in test was to "not run when Task.Record Type = Order Approval Activity"
* Karteek Kumar M   3/2010      Fixed the bug that was causing Errors for Eric. The bug was bad implemtation of leadMap.
* Karteek Kumar M   3/2010      Fixed the bug with campaignMap also.    
* Karteek Kumar M   3/2010      Moved all the code to TaskTriggerClass.IntegrationWhatIdWhoIdMap and TaskTriggerClass.RegularIdsMap.
                                Added firstRunFlag logic for both the functions.
* Karteek Kumar M   03/08/2010  CR 634816 Remove any data migration specific code in salesforce
                                Marked TaskTrigger.trigger for delete and moved in the function call RegularIdsMap()
* Karteek Kumar M   28/10/2010  Force users to assign PS Approval tasks to PS Approvers
* Karteek Kumar M   29/11/10    CR 886789 Fix bug with Task AKAM fields
                                Removing firstRunFlaglogc for Akam System fields function
                                Also removing isUpdateCauseFlag func.
* Lisha Murthy      11/11/2013  CR 2411301 - Need to disable trigger code for Service Cloud
                                - By-passing the trigger code for connection user.  
*Aditya Sonam      13/11/2014   CR 2637462 Existing Customer Onboarding- Task DueDate update based on Subject Name
jayarm thippeswamy 28/05/2015   Auto populate fields for Call CTI
Jay                21/06/2015   CR3061011 , null pointer exceptions in production

* Ruchika Sharma    13/07/2015  CR 3081361 Reset credit check status if the existing task for credit check gets completed.
Sonia Sawhney       29/09/2015  CR 2985554 - Need to prevent case worker collision with activities on SOC cases. Added a method to check if the task is related to a case or not.                                                                                           
Akhila Vidapanapati 27-Jan-2016 Stamping Request Status and Partner Name.   
Aditya              27-Jan-2016 Visibility Validation and MS Azure Changes
Suhas               21/05/2018  FFPSA-490 Alerting to project owner when BED extended

Vandhana            10/05/2020  ESESP-3524 : S2ET
Vikas               20/07/2020  ESESP-3669 : Provisioning
Vamsee              22/09/2020  ACD2-81: ACD. Setting LOE hours
Vandhana			22/09/2020  ESESP-4237 : S2ET (Do Not Override Task Owner Name with Owner Not Assigned When Creating New S2ET Task)
Sheena				07/01/2021  ESESP-6229 : Populate default values on Task based on Type on Managed Security Cases
Tejaswini           28/04/2022  ESESP-6444 : Salesforce automation for case closure - SOCC
Test Classes
* SC_TaskTrigger_Test
*/

trigger TaskTrigger_bi_bu on Task (before insert, before update) 
{
 if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
    {   
        //avidapan : Stamping Partner Name based on case and Receipt Status as Awaiting Receipt 
        if(MSAzureHandler.varActivateMSAzureCode)
            TaskTriggerHandler.stamp_PartnerName_Receipt_Status(Trigger.new,Trigger.oldMap,Trigger.isInsert);

        // Set the AKAM Activity Id
        if(Trigger.isInsert)
            TaskTriggerClass.SetAkamActivityId2(Trigger.new);
            
        /* Moved in from TaskTrigger.trigger */
        TaskTriggerClass.RegularIdsMap(Trigger.new);
        
         //Calling method setVisibilityforLunaPortal for seeting Visibility for Service and Managed Security task created by Luna
        if(Trigger.isInsert){ 
            TaskTriggerHandler.setVisibilityforLunaPortal(Trigger.new);           
        }
        
        //Setting Akamai internal only as part of MS Azure
         TaskTriggerHandler.setVisibilityOnTask(Trigger.new);
        
        // Allow partner only in visibility for partner case only with joint troubleshooting open
         //TaskTriggerHandler.partnerOnlyVisibilityCheck(Trigger.new,Trigger.old,Trigger.isInsert,Trigger.isUpdate);
        
        //Validation Rule for Creating Activity for MS Azure when ER status is Closed and Ticket No. is Null
         if(MSAzureHandler.varActivateMSAzureCode)
            TaskTriggerHandler.erValidationForTaskCreateUpdate(Trigger.new,Trigger.old,Trigger.isInsert,Trigger.isUpdate);

        /*Commenting it out as part of CR 3303361
        //Creating an activity whenever the visibility field value is changed as part of MS Azure
        if(Trigger.isUpdate){
            TaskTriggerHandler.isChangedVisibilityCreateActivity(Trigger.new,Trigger.old);
        }*/
        
        /* Update the Assoc fields */
        
        // Stores ECOB Task ID
        List<Id> EcobTaskID = new List<Id>();
        
        // Stores ECOB Task
        List<Task> ecobTaskList = new List<Task>();
        
        //ECOB : Fetching Service Activity Record Type
        Id SARecType = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('Service Activity').getRecordTypeId();
        
        // variable for checking whether Task Parent is Case or Not
        Id checkCaseOwnerId;
        
        //ECOB: Stores Task trigger whatID
        List<Id> contactIdCTIList = new List<Id>();
        Map<Id,Contact> contactCTIMap ;
        for(task ecobTask : Trigger.New)
        {
            //added logic 2553150
            if(trigger.isInsert)
            {
                if (ecobTask.CallDurationInSeconds != null){
                    if (ecobTask.whoId != null && String.valueof(ecobTask.whoId).substring(0,3) == '003' ){
                        contactIdCTIList.add(ecobTask.whoId);
                    }    
                }
            }
        
             if(ecobTask.RecordTypeID == SARecType && ecobTask.WhatId <> null && String.valueOf(ecobTask.WhatId).startsWith('500'))
         
                 EcobTaskID.add(ecobTask.WhatId);
                 ecobTaskList.add(ecobTask);
        }
        
        if (contactIdCTIList != null && contactIdCTIList.size() > 0){
            contactCTIMap = new Map<Id,contact>([select id,name,email from contact where id in :contactIdCTIList]);
        }
        
         
        // ECOB: Fetching AMG Record type ID
        Id AMGRecType = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('AMG').getRecordTypeId();
        
        // Map to store Case Id - Case Owner Id
        Map<Id, Id> caseId_OwnerMap = new Map<Id, Id>();
        
        if(Trigger.isInsert && Trigger.isBefore && EcobTaskID.size()>0)
        {
            
            // ECOB: List of Existing Customer Onboarding Case
            
            for(case eachCaseRec : [Select OwnerId,Id,CaseNumber from case where Work_Type__c = 'Proactive' and
                                    Request_Type__c = 'Existing Customer Onboarding' and RecordTypeId = : AMGRecType and
                                    AKAM_Created_By__c = 'CRMOPS' and Service__c = 'Accounts Audits' and 
                                    Id IN : EcobTaskID] ){
                                        
                                        caseId_OwnerMap.put(eachCaseRec.Id, eachCaseRec.OwnerId);                      
                                        
                                    }
            
            // Comparing Task and Owner Id and setting Case Owner Id to task owner id if case owner is a user
            if(caseId_OwnerMap.size() > 0){      
                for( Task ecobTask : ecobTaskList){ 
                    
                    checkCaseOwnerId = caseId_OwnerMap.get(ecobTask.WhatId);
                    
                    if(checkCaseOwnerId <> null && String.valueOf(checkCaseOwnerId).startsWith('005')){
                        ecobTask.ownerId =  checkCaseOwnerId  ; 
                    }
                }   
            } 
        }     
        
        // changes by Vandhana for S2ET ESESP-3524
        List<Task> lstS2ETTasks = new List<Task>();
        Id secServRecTypeId = Task.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Security_Services_Activity').getRecordTypeId();
        
        List<Task> s2ETSchedDepTasks = new List<Task>();
        
        //Changes by Vikas for Provisioning
        Id plxRecTypeId = Task.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Provisioning_Activity').getRecordTypeId();
        Id onaId = [SELECT DeveloperName,Value_Text__c
                    FROM SC_Utility__mdt
                    WHERE DeveloperName IN ('Owner_Not_Assigned_User_Id')].Value_Text__c;
        
        for(Task eachTask : Trigger.new)
        {               
            if(eachTask.RecordTypeId == secServRecTypeId 
               && String.isNotBlank(String.valueOf(eachTask.DueDateProlexic__c)) 
               && ( (Trigger.isInsert) 
                   || 
                   (Trigger.isUpdate && Trigger.oldMap.get(eachTask.Id).DueDateProlexic__c != eachTask.DueDateProlexic__c)
                  )
               && (SC_TaskTriggerHandler.s2etCheckRecursion || SC_TaskTriggerHandler.s2etSchedDepTaskBypass)
              )
            {
                lstS2ETTasks.add(eachTask);
            }
            
            /* 
             * Commmenting code out as part of ESESP-4237
             * 
            if(eachTask.RecordTypeId == secServRecTypeId && Trigger.isInsert)
            {
                eachTask.OwnerId = onaId;
            }
            */
            
            if(eachTask.RecordTypeId == secServRecTypeId 
               && Trigger.isUpdate 
               && Trigger.oldMap.get(eachTask.Id).OwnerId != eachTask.OwnerId
               && Trigger.oldMap.get(eachTask.Id).OwnerId == onaId
               && String.valueOf(eachTask.OwnerId).startsWith(Schema.SObjectType.User.getKeyPrefix())
               && eachTask.Status == 'Not Started'
               )
            {
                eachTask.Status = 'In Progress';
            }
            
            //ACD2-81 Calculate LOE Hours from CallDuration field
            
           eachTask.loe_hours__c = (eachTask.CallDurationInSeconds != null && eachTask.CallDurationInSeconds > 0 && eachTask.cnx__UniqueId__c != null) ? 
                        					Decimal.valueof(eachTask.CallDurationInSeconds).Divide(3600, 2) : eachTask.loe_hours__c;
           //Setting the type to Call for ACD2-205
           eachTask.Type__c = eachTask.cnx__UniqueId__c != null? 'Call' : eachTask.Type__c;
           
            //Changes by Vikas for Provisioning
            if(eachTask.RecordTypeId == plxRecTypeId){
                if(Trigger.isInsert){
                    if(eachTask.OwnerId != onaId 
                       && String.valueOf(eachTask.OwnerId).startsWith(Schema.SObjectType.User.getKeyPrefix()) 
                       && eachTask.Status == 'Unassigned')
                    {
                        eachTask.Status = 'Not Started';
                    }
                } 
                else if(Trigger.isUpdate){
                    if(Trigger.oldMap.get(eachTask.Id).OwnerId != eachTask.OwnerId
                       && Trigger.oldMap.get(eachTask.Id).OwnerId == onaId
                       && String.valueOf(eachTask.OwnerId).startsWith(Schema.SObjectType.User.getKeyPrefix())
                       && eachTask.Status == 'Unassigned')
                    {
                        eachTask.Status = 'Not Started';
                    }
                }
            }
            //End of Changes by Vikas for Provisioning
        }
        
        
        if(!lstS2ETTasks.isEmpty())
        {
            SC_TaskTriggerHandler.s2etDueDateCorrect(lstS2ETTasks, Trigger.isInsert);
        }
        
        // end of changes by Vandhana for S2ET ESESP-3524
        
        String taskWhatId;
        for(Task tsk:Trigger.new)
        {
            if (trigger.IsInsert)
            {
                //prepopulate only for case
                 if (tsk.CallDurationInSeconds != null && tsk.WhatId != null && String.valueOf(tsk.WhatId).substring(0,3) == '500' )
                 {
                     tsk.type__c = 'Call';
                     Decimal toround = tsk.CallDurationInSeconds;
                     tsk.loe_hours__c = toround.Divide(3600, 1);
                     if (tsk.whoId != null)
                     {
                         Contact contactObject = contactCTIMap.get(tsk.whoId);
                         if (contactObject != null && contactObject.email != null && (!contactObject.email.tolowercase().contains('akamai.com')))
                         {
                             tsk.Internal_Only__c = false;
                             //Added by aditya as part of MS Azure new Visibility field
                             tsk.Visibility__c = 'Customer';
                         }
                         
                     }
                 }    
            }
        }
        
        
        /* Set Old Owner and Old Status*/
        if(!Trigger.isInsert)
        {
            // Get Set of Old and New OwnerIds
            Set<Id> oldOwnerSet = new Set<Id>();
            Set<Id> newOwnerSet = new Set<Id>();
            for(Task tsk:Trigger.new)
            {
                oldOwnerSet.add(Trigger.oldMap.get(tsk.Id).OwnerId);
                newOwnerSet.add(tsk.OwnerId);
            }
            
            //Get a Map of user.id -> user.name
            Map<Id, String> usrNameMap = new Map<Id, String>();
            for(User usr : [select Id, Name from User where Id IN :oldOwnerSet or ID IN :newOwnerSet])
                usrNameMap.put(usr.Id,usr.Name);
    
            for(Task tsk:Trigger.new)
            {       
                tsk.Old_Owner__c = usrNameMap.get(Trigger.oldMap.get(tsk.Id).OwnerId);
                tsk.Old_Status__c = Trigger.oldMap.get(tsk.Id).Status;
            }

            //CR 3081361 : Reset credit check status if the existing task for creidt check gets completed.
            TaskTriggerClass.resetCreditCheckFlag(Trigger.new,Trigger.oldMap);
        }


        //CR 2985554 - Added a method to check if the task is related to a case or not.                                                                                           
        TaskTriggerHandler.markCaseRelatedTask(Trigger.new);
        
        if(Trigger.isInsert || Trigger.isUpdate)
        {
            //EPM_GenerateCustomApprovalRequest.createApprovalRequest(Trigger.new);
        }//End
        // Changes by Suhas for FFPSA-490
        if((Trigger.isBefore ) &&  (Trigger.isUpdate || Trigger.isInsert))
        {
            try
            {
                PSA_ProjectActions.preventDupBED(Trigger.New, Trigger.Old, Trigger.isInsert);
            }
            Catch(Exception e)
            {
                PSA_AutoCreateProjectUtil.sendErrorMails('Error in preventing duplicate task on projects for BED',e.getMessage());
            }
        }
        // Changes by Suhas for FFPSA-490
        // Changes by Sheena for ESESP-6229 - Populate default values for task on Managed Security Cases
         if((Trigger.isBefore ) &&  (Trigger.isUpdate || Trigger.isInsert))
        {
            TaskTriggerHandler.defaultSOCCTaskLOE(Trigger.New, Trigger.OldMap, Trigger.isInsert);
        }
        //Changes for ESESP-6444
        if(Trigger.isBefore && Trigger.isInsert)
        {
            SC_TaskTriggerHandler.handleTicketPushTask(Trigger.new);
        }
    }
    
}