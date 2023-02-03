public without sharing class IW_InvestmentWorkHandler extends ApexTriggerHandlerAbstractClass {
    
    // used across all the trigger events
    List<Investment_Workbox__c> allApprovedWRs;
    List<Investment_Workbox__c> forWatchers;
    InvWB_Handler wb;
    List<Investment_Workbox__c> accIdsToCheckLOE;
    Set<String> allRegions;
    Map<Id, Set<String>> wrIdToButtons;
    List<Investment_Workbox__c> reqStatusChangedList;
    List<Investment_Workbox__c> cancelledWRs;
    Set<String> access;  
    String profileName;
    List<Id> orphanQueue;
    List<Investment_Workbox__c> approvedWRs;
    
    
    public IW_InvestmentWorkHandler()
    {   
    }
    
    public void initializeAttributes()
    {
        allApprovedWRs 			= new List<Investment_Workbox__c>();
        forWatchers 			= new List<Investment_Workbox__c>();
        wb 						= new InvWB_Handler();
        accIdsToCheckLOE 		= new List<Investment_Workbox__c>();
        allRegions 				= new Set<String>();
        wrIdToButtons 			= new Map<Id, Set<String>>();
        reqStatusChangedList	= new List<Investment_Workbox__c>();
        cancelledWRs 			= new List<Investment_Workbox__c>();
        access 					= new Set<String>();  
        profileName				= '';
        orphanQueue 			= new List<Id>();
        approvedWRs 			= new List<Investment_Workbox__c>();
    }
    
    public override void beforeInsertBeforeUpdateTrigger()
    {   
        if(Trigger.isInsert)
        {
            initializeAttributes();
            validateRequestsAndProcess(newList, (Map <Id, Investment_Workbox__c>) oldMap, true);
        }
        
        if(Trigger.isUpdate)
        {
            initializeAttributes();
            validateRequestsAndProcess(newList, (Map <Id, Investment_Workbox__c>) oldMap, false);
        }
    }
    
    public override void afterInsertAfterUpdateTrigger()
    {   
        if(Trigger.isInsert)
        {
            initializeAttributes();
            validateRequestsAndProcessAIRecords(newList, (Map <Id, Investment_Workbox__c>) oldMap, true);
        }
        
        if(Trigger.isUpdate)
        {
            initializeAttributes();
            validateRequestsAndProcessAIRecords(newList, (Map <Id, Investment_Workbox__c>) oldMap, false);
        }
    }
    
    public override void beforeDeleteBeforeUndeleteTrigger()
    {
        
    }
    
    public override void afterDeleteAfterUndeleteTrigger()
    {
        
    }   
    
    
    //caled before insert/update
    public void validateRequestsAndProcess(List<Investment_Workbox__c> newList, Map<Id,Investment_Workbox__c> oldMap , boolean isInsert)
    {
        System.debug('before Trigger : context : ' + isInsert);

        decimal loeLowLimit = [SELECT Id,Value__c,LOE_Low_Limts__c,MasterLabel
                                FROM PSA_Common_Setting__mdt
                                WHERE type__c = 'IW_Settings__mdt' and MasterLabel = 'IW LOE 4 To 40'].LOE_Low_Limts__c ;
        //Load on update
        if(!isInsert)
        {
            Id profileId 	= UserInfo.getProfileId();
            profileName 	= [Select Id, Name from Profile where Id=:profileId].Name;
            wrIdToButtons 	= wb.accessToWR(oldMap.values());
        }
        
        for(Investment_Workbox__c iwb : newList)
        {
            if(iwb.Legacy_Data__c != 'Workbox' && !iwb.Validation_Override__c)
            {
                iwb.LOE_Hours__c = iwb.LOE_Hours__c != NULL ? iwb.LOE_Hours__c : 0.0;
                iwb.LOE_Minutes__c = iwb.LOE_Minutes__c != NULL ? iwb.LOE_Minutes__c : 0.0;
                
                //perform all before Instert Operations
                if(isInsert)
                {
                    forWatchers.add(iwb);
                    //When Status turns awaiting Approval and LOE < 4 goes Auto-Approved
                    if(iwb.Status__c != NULL && iwb.Status__c.equals('Awaiting Approval') && (iwb.LOE_Hours__c + iwb.LOE_Minutes__c/60.0) <= loeLowLimit)
                    {
                        getRequestApproved(iwb);
                        // deducting slot values / adding slot values
                        allApprovedWRs.add(iwb);  
                    }
                    //When a Request goes Awaiting Approval first time and crosses LOE limit
                    else if (iwb.Status__c != NULL && iwb.Status__c.equals('Awaiting Approval') && (iwb.LOE_Hours__c + iwb.LOE_Minutes__c/60.0) > loeLowLimit)
                    {
                        //wb.checkIfSlotAvailableToSubmit(new List<Investment_WorkBox__c>{iwb});
                        getRequestSubmitted(iwb);
                        accIdsToCheckLOE.add(iwb);
                    }
                    
                }
                
                //perform all before Update Operations
                if(!isInsert)
                {
                    System.debug('on Updating the record :: ' + iwb);
                    access.clear();
                    access = wrIdToButtons.get(iwb.Id);
                    if(iwb.createdById == UserInfo.getUserId() || profileName.equalsIgnoreCase('System Administrator') || !access.isEmpty())
                    {
                        System.debug('User have access :: ' + iwb);
                        Decimal totalHrs = iwb.LOE_Hours__c + (iwb.LOE_Minutes__c/60.0); 
                        
                        //when there is chnage in STATUS
                        if(iwb.Status__c != NULL && oldMap.get(iwb.Id).Status__c != iwb.Status__c)
                        {
                            //when status goes Awaiting Approval and LOE <= 4
                            if(iwb.Status__c.equals('Awaiting Approval') && totalHrs <= loeLowLimit)
                            {
                                accIdsToCheckLOE.add(iwb);
                                getRequestApproved(iwb);
                                allApprovedWRs.add(iwb);
                            }
                            //When status (Approved) deduct slot if approved
                            else if( iwb.Status__c.equals('Approved') || iwb.Status__c.equals('Escalate Approved') || iwb.Status__c.equals('Auto-Approved') )
                            {
                                getRequestApprovedORRejected(iwb);
                                System.debug('inside Approved request');
                                allApprovedWRs.add(iwb);
                            }
                            //When status (Rejected) stamp the Approver.
                            else if( iwb.Status__c.equals('Rejected') || iwb.Status__c.equals('Escalate Reject') )
                            {
                                getRequestApprovedORRejected(iwb);
                                System.debug('inside Rejected request');
                            }
                            // When Status is Awating Approval/ Escalated and LOE > 4
                            else if( (iwb.Status__c.equals('Awaiting Approval') || iwb.Status__c.equals('Escalated') ) && totalHrs > loeLowLimit )
                            {
                                accIdsToCheckLOE.add(iwb);
                                getRequestSubmitted(iwb);
                                reqStatusChangedList.add(iwb);
                                if(iwb.Region__c != NULL){
                                    allRegions.add(iwb.Region__c + ' '+ '(Region)');
                                }
                            }
                            // When Status is Canceled from Approved - now add slot hrs back to region quarter 
                            else if((oldMap.get(iwb.Id).Status__c.equals('Approved') || oldMap.get(iwb.Id).Status__c.equals('Auto-Approved') || oldMap.get(iwb.Id).Status__c.equals('Escalate Approved')) && iwb.Status__c.equals('Cancelled'))
                            {
                                cancelledWRs.add(iwb);
                            }
                            
                        }
                        
                        //when there is change in REGION
                        else if(iwb.Region__c !=  NULL && iwb.Region__c != oldMap.get(iwb.Id).Region__c)
                        {
                            reqStatusChangedList.add(iwb);
                            if(iwb.Region__c != NULL)
                            {
                                allRegions.add(iwb.Region__c + ' '+ '(Region)');
                                System.debug(' allRegions :: '+ allRegions);
                            }
                        }
                        
                        //when there is change in LOE HOURS and Status in (Awaiting Approval / Escalated)
                        else if(totalHrs !=  NULL && totalHrs != oldMap.get(iwb.Id).LOE__c && (iwb.Status__c.equals('Awaiting Approval') || iwb.Status__c.equals('Escalated')))
                        {
                            if(iwb.Status__c.equals('Awaiting Approval') && totalHrs <= loeLowLimit )
                            {
                                accIdsToCheckLOE.add(iwb);
                                getRequestApproved(iwb);
                                allApprovedWRs.add(iwb);
                            }
                            //19.5 adding region Names to check if they fall in Orphan Queue when change in LOE Hours
                            allRegions.add(iwb.Region__c + ' '+ '(Region)');
                            accIdsToCheckLOE.add(iwb);
                        }  
                    }
                    else
                    {
                        iwb.addError('You may not be the Creator/Approver of the Work Request to take any Action ');
                    }
                }
            }
            
        }
        
        //check for before insert validations and proceed
        if(isInsert)
        {
            if(accIdsToCheckLOE != NULL && !accIdsToCheckLOE.isEmpty())
            {
                //method will check for remaining hours left from Region and show error message if no slots available 
                wb.checkIfSlotAvailableToSubmit(accIdsToCheckLOE);
                //method will stamp approvers in the Approver List field
                wb.stampApprovers(accIdsToCheckLOE);
                //stamp EndTime of Workrequests.
                wb.stampEndTime(accIdsToCheckLOE);
            }
            
            if(forWatchers != NULL && forWatchers.size() > 0)
            {
                InvWB_Handler.addDefaultWatchers(forWatchers); 
            }
            
            if(allApprovedWRs != NULL && allApprovedWRs.size() > 0)
            {
                //InvWB_Handler wb = new InvWB_Handler();
                wb.deductSlotForApprovedWRs(allApprovedWRs, true);
            }
            
        }
        
        //check for before update validations and proceed
        if(!isInsert)
        {
            if(accIdsToCheckLOE != NULL && !accIdsToCheckLOE.isEmpty())
            {
                //method will check for remaining hours left from Region and show error message if no slots available 
                wb.checkIfSlotAvailableToSubmit(accIdsToCheckLOE);
                //method will stamp approvers in the Approver List field
                wb.stampApprovers(accIdsToCheckLOE);
                //stamp End Time
                wb.stampEndTime(accIdsToCheckLOE);
                //19.5 set if it falls in Orphan Queue
                if(!allRegions.isEmpty()){
                    wb.setOrphanQueue(accIdsToCheckLOE, allRegions);
                }
            }
            
            if(allApprovedWRs != NULL && allApprovedWRs.size() > 0)
            {
                wb.deductSlotForApprovedWRs(allApprovedWRs, false);
            }
            
            if(reqStatusChangedList != NULL && reqStatusChangedList.size() > 0)
            {
                //wb.checkIfSlotAvailableToSubmit(reqStatusChangedList);
                wb.setOrphanQueue(reqStatusChangedList, allRegions);
                //method will check for remaining hours left from Region and show error message if no slots available 
                wb.checkIfSlotAvailableToSubmit(reqStatusChangedList);
                //method will stamp approvers in the Approver List field
                wb.stampApprovers(reqStatusChangedList);
            }
            
            if(cancelledWRs != NULL && cancelledWRs.size() > 0)
            {
                wb.checkInvestmentWorkForCancel(cancelledWRs);
            }
        }
        
        
        
    }
    
    //caled after insert/update
    public void validateRequestsAndProcessAIRecords(List<Investment_Workbox__c> newList, Map<Id,Investment_Workbox__c> oldMap , boolean isInsert)
    {

        decimal loeLowLimit = [SELECT Id,Value__c,LOE_Low_Limts__c,MasterLabel
                                FROM PSA_Common_Setting__mdt
                                WHERE type__c = 'IW_Settings__mdt' and MasterLabel = 'IW LOE 4 To 40'].LOE_Low_Limts__c ;
        
        for(Investment_Workbox__c iwb : newList)
        {
            if(!iwb.Validation_Override__c)
            {
                //after Insert operations
                if(isInsert)
                {
                    if(iwb.Status__c != NULL && (iwb.Status__c.equals('Awaiting Approval') && (iwb.LOE__c) > loeLowLimit) )
                    {
                        //Stamp if the request belongs to an Orphan Queue
                        orphanQueue.add(iwb.Id);
                        reqStatusChangedList.add(iwb);
                        
                    }
                    else if(iwb.Status__c != NULL && iwb.Status__c.equals('Auto-Approved'))
                    {
                        allApprovedWRs.add(iwb);
                    }
                }
                
                //after update operations
                if(!isInsert)
                {
                    if(iwb.Status__c != NULL && iwb.Status__c != oldMap.get(iwb.Id).Status__c)
                    {
                        
                        if((iwb.Status__c.equals('Approved') || iwb.Status__c.equals('Escalate Approved') || iwb.Status__c.equals('Auto-Approved')))
                        {
                            approvedWRs.add(iwb);
                        }
                        else
                        {
                            System.debug('Else Statement entered');
                            reqStatusChangedList.add(iwb);
                        }
                    }
                    if(iwb.Status__c != NULL && (iwb.Status__c.equals('Awaiting Approval') || iwb.Status__c.equals('Escalated') ) && iwb.LOE__c != oldMap.get(iwb.Id).LOE__c)
                    {
                        reqStatusChangedList.add(iwb);
                    }
                    
                }
                
            }
            
        }
        
        // after Insert Operations - check for validations and process
        if(isInsert)
        {
            if(orphanQueue != NULL && orphanQueue.size() > 0)
            {
                InvWB_Handler.setOrphanQueue(orphanQueue);
            }
            if(reqStatusChangedList !=  NULL && reqStatusChangedList.size() > 0)
            {
                wb.sendEmailNotificationToUsersonStatus(reqStatusChangedList);
            }   
            if(allApprovedWRs !=  NULL && allApprovedWRs.size() > 0)
            {
                wb.createProjectsHandlerFunction(allApprovedWRs);
            }
            
        }
        
        //after update Operations - check for validations and process
        if(!isInsert)
        {
            if(reqStatusChangedList != NULL && reqStatusChangedList.size() > 0)
            {
                wb.sendEmailNotificationToUsersonStatus(reqStatusChangedList);
            }
            if(approvedWRs !=  NULL && approvedWRs.size() > 0)
            {
                wb.createProjectsHandlerFunction(approvedWRs);
            }   
            
        }
        
        
    }
    
    //to get requests AutoApproved
    public void getRequestApproved(Investment_Workbox__c iwb)
    {
        iwb.Status__c = 'Auto-Approved';
        iwb.Submitted_Date__c = DateTime.now(); 
        iwb.Submitter__c = userInfo.getUserId();
        iwb.Approved_Date__c = DateTime.now();
        iwb.Approver__c = userInfo.getUserId();
    }
    
    //to get requests Submitted
    public void getRequestSubmitted(Investment_Workbox__c iwb)
    {
        iwb.Submitted_Date__c = DateTime.now();
        if( ! iwb.Status__c.equals('Escalated') )
        {
            iwb.Submitter__c = userInfo.getUserId();
        }
    }
    
    //stamp Approved/Rejected
    public void getRequestApprovedORRejected(Investment_Workbox__c iwb)
    {
        iwb.Approved_Date__c = DateTime.now();
        iwb.Approver__c = userInfo.getUserId();
    }
    
    
}