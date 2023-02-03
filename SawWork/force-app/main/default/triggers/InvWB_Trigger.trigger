trigger InvWB_Trigger on Investment_Workbox__c(	
	before insert, 
    before update,
    before delete,
    after insert, 
    after update,
    after delete,
    after undelete) 
{
        
    if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
    {

        System.debug('TF ::calling ApexTriggerHandlerAbstractClass with Object IW');
        ApexTriggerHandlerAbstractClass.createHandler('Investment_Workbox__c');
    }
    System.debug('After Abstract Class Handler execution');
    
    //boolean dataLoad = InvWB_Handler.dataLoadCheck();
    /************************* Before Insert/Update Actions ************************************/
    /*if(trigger.isBefore){
        
        if(trigger.isInsert){ 
            
            //Check if logged in user is having rights to create a WR's
            //InvWB_Handler.accessCheck(Trigger.New);
            List<Investment_Workbox__c> allApprovedWRs = new List<Investment_Workbox__c>();
            List<Investment_Workbox__c> forWatchers = new List<Investment_Workbox__c>();
            InvWB_Handler wb = new InvWB_Handler();
            List<Investment_Workbox__c> accIdsToCheckLOE = new List<Investment_Workbox__c>();
            
            for(Investment_Workbox__c iwb : Trigger.New){
                //InvWB_Handler.checkModifyRequestFrom(iwb);
                //Data migration check 
                if(iwb.Legacy_Data__c != 'Workbox'){
                    iwb.LOE_Hours__c = iwb.LOE_Hours__c != NULL ? iwb.LOE_Hours__c : 0.0;
                    iwb.LOE_Minutes__c = iwb.LOE_Minutes__c != NULL ? iwb.LOE_Minutes__c : 0.0;
                    
                    forWatchers.add(iwb);
                    System.debug('present status :::::::::::::::::::::::: '+ iwb.Status__c );
                    System.debug('iw projs :' + iwb.Project__c );
                    
                    //When Status turns awaiting Approval and LOE < 4 goes Auto-Approved
                    if(iwb.Status__c != NULL && iwb.Status__c.equals('Awaiting Approval') && (iwb.LOE_Hours__c + iwb.LOE_Minutes__c/60.0) <= 4 && !iwb.Validation_Override__c ){
                        //wb.checkIfSlotAvailableToSubmit(new List<Investment_WorkBox__c>{iwb});
                        accIdsToCheckLOE.add(iwb);
                        System.debug('Auto _ Approved :::::::::::::::::::::::::::::::');
                        iwb.Status__c = 'Auto-Approved';
                        iwb.Submitted_Date__c = DateTime.now(); 
                        iwb.Submitter__c = userInfo.getUserId();
                        iwb.Approved_Date__c = DateTime.now();
                        iwb.Approver__c = userInfo.getUserId();
                        System.debug('before insert and WR Approved');
                        // deducting slot values / adding slot values
                        allApprovedWRs.add(iwb);  
                    } 
                    //When a Request goes Awaiting Approval first time and crosses LOE limit
                    else if (iwb.Status__c != NULL && iwb.Status__c.equals('Awaiting Approval') && (iwb.LOE_Hours__c + iwb.LOE_Minutes__c/60.0) > 4 && !iwb.Validation_Override__c){
                        //wb.checkIfSlotAvailableToSubmit(new List<Investment_WorkBox__c>{iwb});
                        iwb.Submitted_Date__c = DateTime.now();
                        iwb.Submitter__c = userInfo.getUserId();
                        accIdsToCheckLOE.add(iwb);
                        
                    }
                }
                //Only on submit not on save
                
            }
            
            if(accIdsToCheckLOE != NULL && !accIdsToCheckLOE.isEmpty()){
                //method will check for remaining hours left from Region and show error message if no slots available 
                wb.checkIfSlotAvailableToSubmit(accIdsToCheckLOE);
                //method will stamp approvers in the Approver List field
                wb.stampApprovers(accIdsToCheckLOE);
                //stamp EndTime of Workrequests.
                wb.stampEndTime(accIdsToCheckLOE);
            }
            
            if(forWatchers != NULL && forWatchers.size() > 0){
                InvWB_Handler.addDefaultWatchers(forWatchers); 
            }
            
            if(allApprovedWRs != NULL && allApprovedWRs.size() > 0){
                //InvWB_Handler wb = new InvWB_Handler();
                wb.deductSlotForApprovedWRs(allApprovedWRs, true);
            }
            
        }// end of isInsert
        
        if(trigger.isUpdate){
            
            
            //Check if logged in user is having rights to create a WR's     
            //InvWB_Handler.accessCheck(Trigger.New);       
            Map<Id, Investment_Workbox__c> newMap = Trigger.newMap;
            Map<Id, Investment_Workbox__c> oldMap = Trigger.oldMap;
            Set<String> allRegions = new Set<String>();
            //holds all Id TO buttons to requests.
            Map<Id, Set<String>> wrIdToButtons = new Map<Id, Set<String>>();
            List<Investment_Workbox__c> allApprovedWRs = new List<Investment_Workbox__c>();
            List<Investment_Workbox__c> reqStatusChangedList = new List<Investment_Workbox__c>();
            List<Investment_Workbox__c> cancelledWRs = new List<Investment_Workbox__c>();
            List<Investment_Workbox__c> accIdsToCheckLOE = new List<Investment_Workbox__c>();
            InvWB_Handler wb = new InvWB_Handler();
            wrIdToButtons = wb.accessToWR(oldMap.values());
            Id profileId = UserInfo.getProfileId();
            //19.1
            //List<String> access = new List<String>();
            Set<String> access = new Set<String>();
            String profileName =[Select Id, Name from Profile where Id=:profileId].Name;
            //need to bulkify access to 
            //Map<Id, List<String>> wRIdToAccess = Map<Id, List<String>>();
            //wb.getApproverListOfWR();
            
            for(Id iwb : newMap.keySet()){
                // check if LoggedInUser and Creator of the record are same and bypass Sys Admin
                // commenting it for time being to add validation to Loggedin User
                access.clear();
                //19.1 changes to reduce iterations on WR.
                //access = wb.getApproverListOfWR(oldMap.get(iwb), userInfo.getUserId()); 
                access = wrIdToButtons.get(iwb);
                System.debug('access :::: '+ access);
                if(newMap.get(iwb).createdById == UserInfo.getUserId() || profileName.equalsIgnoreCase('System Administrator') || !access.isEmpty()){
                    //InvWB_Handler.checkModifyRequestFrom(newMap.get(iwb));
                    newMap.get(iwb).LOE_Hours__c = newMap.get(iwb).LOE_Hours__c != NULL ? newMap.get(iwb).LOE_Hours__c : 0.0;
                    newMap.get(iwb).LOE_Minutes__c = newMap.get(iwb).LOE_Minutes__c != NULL ? newMap.get(iwb).LOE_Minutes__c : 0.0;
                    Decimal totalHrs = newMap.get(iwb).LOE_Hours__c + (newMap.get(iwb).LOE_Minutes__c/60.0); 
                    
                    System.debug('totalHrs :: ' + totalHrs + ' oldMap.get(iwb).LOE__c :::::::::::::::::::::::' + oldMap.get(iwb).LOE__c);
                    
                    //when there is chnage in STATUS
                    if(newMap.get(iwb).Status__c != NULL && oldMap.get(iwb).Status__c != newMap.get(iwb).Status__c){
                        //when status goes Awaiting Approval and LOE <= 4
                        if(newMap.get(iwb).Status__c.equals('Awaiting Approval') && totalHrs <= 4.00 && !newMap.get(iwb).Validation_Override__c ){
                            accIdsToCheckLOE.add(newMap.get(iwb));
                            //wb.checkIfSlotAvailableToSubmit(new List<Investment_WorkBox__c>{newMap.get(iwb)});
                            newMap.get(iwb).Status__c = 'Auto-Approved';
                            newMap.get(iwb).Submitter__c = userInfo.getUserId();
                            newMap.get(iwb).Approver__c = userInfo.getUserId();
                            newMap.get(iwb).Submitted_Date__c = DateTime.now();
                            newMap.get(iwb).Approved_Date__c = DateTime.now();
                            allApprovedWRs.add(newMap.get(iwb));
                        }
                        //When status (Approved) deduct slot if approved
                        else if( (newMap.get(iwb).Status__c.equals('Approved') || newMap.get(iwb).Status__c.equals('Escalate Approved') || newMap.get(iwb).Status__c.equals('Auto-Approved')) && !newMap.get(iwb).Validation_Override__c ){
                            newMap.get(iwb).Approved_Date__c = DateTime.now();
                            newMap.get(iwb).Approver__c = userInfo.getUserId();
                            System.debug('inside Approved request');
                            allApprovedWRs.add(newMap.get(iwb));
                        }
                        //When status (Rejected) stamp the Approver.
                        else if( newMap.get(iwb).Status__c.equals('Rejected') || newMap.get(iwb).Status__c.equals('Escalate Reject') ){
                            newMap.get(iwb).Approved_Date__c = DateTime.now();
                            newMap.get(iwb).Approver__c = userInfo.getUserId();
                            System.debug('inside Rejected request');
                        }
                        // When Status is Awating Approval/ Escalated and LOE > 4
                        else if( (newMap.get(iwb).Status__c.equals('Awaiting Approval') || newMap.get(iwb).Status__c.equals('Escalated') )&& totalHrs > 4.00){
                            //wb.checkIfSlotAvailableToSubmit(new List<Investment_WorkBox__c>{newMap.get(iwb)});
                            accIdsToCheckLOE.add(newMap.get(iwb));
                            newMap.get(iwb).Submitter__c = userInfo.getUserId();
                            newMap.get(iwb).Submitted_date__c = System.now();
                            reqStatusChangedList.add(newMap.get(iwb));
                            if(newMap.get(iwb).Region__c != NULL){
                                allRegions.add(newMap.get(iwb).Region__c + ' '+ '(Region)');
                                System.debug(' allRegions :: '+ allRegions);
                            }
                        }
                        // When Status is Canceled from Approved - now add slot hrs back to region quarter 
                        else if((oldMap.get(iwb).Status__c.equals('Approved') || oldMap.get(iwb).Status__c.equals('Auto-Approved') || oldMap.get(iwb).Status__c.equals('Escalate Approved')) && newMap.get(iwb).Status__c.equals('Cancelled')){
                            cancelledWRs.add(newMap.get(iwb));
                        }
                        
                    }
                    
                    //when there is change in REGION
                    else if(newMap.get(iwb).Region__c !=  NULL && newMap.get(iwb).Region__c != oldMap.get(iwb).Region__c){
                        reqStatusChangedList.add(newMap.get(iwb));
                        if(newMap.get(iwb).Region__c != NULL){
                            allRegions.add(newMap.get(iwb).Region__c + ' '+ '(Region)');
                            System.debug(' allRegions :: '+ allRegions);
                        }
                    }
                    
                    //when there is change in LOE HOURS and Status in (Awaiting Approval / Escalated)
                    else if(totalHrs !=  NULL && totalHrs != oldMap.get(iwb).LOE__c && (newMap.get(iwb).Status__c.equals('Awaiting Approval') || newMap.get(iwb).Status__c.equals('Escalated'))){
                        if(newMap.get(iwb).Status__c.equals('Awaiting Approval') && totalHrs <= 4.00 && !newMap.get(iwb).Validation_Override__c ){
                            accIdsToCheckLOE.add(newMap.get(iwb));
                            //wb.checkIfSlotAvailableToSubmit(new List<Investment_WorkBox__c>{newMap.get(iwb)});
                            newMap.get(iwb).Status__c = 'Auto-Approved';
                            newMap.get(iwb).Submitter__c = userInfo.getUserId();
                            newMap.get(iwb).Approver__c = userInfo.getUserId();
                            newMap.get(iwb).Submitted_Date__c = DateTime.now();
                            newMap.get(iwb).Approved_Date__c = DateTime.now();
                            allApprovedWRs.add(newMap.get(iwb));
                        }
                        //19.5 adding region Names to check if they fall in Orphan Queue when change in LOE Hours
                        allRegions.add(newMap.get(iwb).Region__c + ' '+ '(Region)');
                        System.debug('chnage LOE HOURS ::::::::::::');
                        accIdsToCheckLOE.add(newMap.get(iwb));
                        //wb.checkIfSlotAvailableToSubmit(new List<Investment_WorkBox__c>{newMap.get(iwb)});
                    }  
                    
                    //If Approver changes the Request to Submit when it is Escalated change status back to Escalated.
                }
                else{
                    newMap.get(iwb).addError('You may not be the Creator/Approver of the Work Request to take any Action ');
                }
                
            }
            
            if(accIdsToCheckLOE != NULL && !accIdsToCheckLOE.isEmpty()){
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
            
            if(allApprovedWRs != NULL && allApprovedWRs.size() > 0){
                wb.deductSlotForApprovedWRs(allApprovedWRs, false);
            }
            
            if(reqStatusChangedList != NULL && reqStatusChangedList.size() > 0){
                //wb.checkIfSlotAvailableToSubmit(reqStatusChangedList);
                wb.setOrphanQueue(reqStatusChangedList, allRegions);
                //method will check for remaining hours left from Region and show error message if no slots available 
                wb.checkIfSlotAvailableToSubmit(reqStatusChangedList);
                //method will stamp approvers in the Approver List field
                wb.stampApprovers(reqStatusChangedList);
            }
            
            if(cancelledWRs != NULL && cancelledWRs.size() > 0){
                wb.checkInvestmentWorkForCancel(cancelledWRs);
            }
            
            
        }//end of isUpdate
        
        if(trigger.isDelete){
            //Check if logged in user is having rights to delete a WR's     
            //InvWB_Handler.accessCheck(Trigger.old);
        }
        
    }// end of Before
    
    
    //************************* After Insert/Update Actions ***********************************
    
    if(trigger.isAfter){
        
        if(trigger.isInsert){
            System.debug('altdt trig');
            //after insert logic
            List<Investment_Workbox__c> reqStatusChangedList = new List<Investment_Workbox__c>();
            List<Id> orphanQueue = new List<Id>();
            Set<String> allRegions = new Set<String>();
            InvWB_Handler wb = new InvWB_Handler();
            List<Investment_Workbox__c> allApprovedWRs = new List<Investment_Workbox__c>();
            
            for(Investment_Workbox__c iwb : Trigger.new){
                if(!iwb.Validation_Override__c){
                    if(iwb.Status__c != NULL && (iwb.Status__c.equals('Awaiting Approval') && (iwb.LOE__c) > 4) ){
                        //Stamp if the request belongs to an Orphan Queue
                        orphanQueue.add(iwb.Id);
                        reqStatusChangedList.add(iwb);
                        
                    }
                    else if(iwb.Status__c != NULL && iwb.Status__c.equals('Auto-Approved')){
                        //reqStatusChangedList.add(iwb);
                        System.debug('doent have proj link  ' + iwb.Project__c );
                        allApprovedWRs.add(iwb);
                    }
                }
                
            }
            
            if(orphanQueue != NULL && orphanQueue.size() > 0){
                InvWB_Handler.setOrphanQueue(orphanQueue);
            }
            if(reqStatusChangedList !=  NULL && reqStatusChangedList.size() > 0){ 
                wb.sendEmailNotificationToUsersonStatus(reqStatusChangedList);
                //
            }   
            if(allApprovedWRs !=  NULL && allApprovedWRs.size() > 0){
                System.debug('ck before trig IW' +allApprovedWRs[0].Account__r.Name );
                wb.createProjectsHandlerFunction(allApprovedWRs);
            }
            
        }//end of After Insert
        
        
        if(trigger.isUpdate){
            //after update logic
            Map<Id, Investment_Workbox__c> newMap = Trigger.newMap;
            Map<Id, Investment_Workbox__c> oldMap = Trigger.oldMap;
            List<Investment_Workbox__c> reqStatusChangedList = new List<Investment_Workbox__c>();
            List<Investment_Workbox__c> approvedWRs = new List<Investment_Workbox__c>();
            InvWB_Handler wb = new InvWB_Handler();
            
            for(Id iwb : newMap.keySet()){
                if(newMap.get(iwb).Status__c != NULL && newMap.get(iwb).Status__c != oldMap.get(iwb).Status__c && !newMap.get(iwb).Validation_Override__c ){
                    
                    if((newMap.get(iwb).Status__c.equals('Approved') || newMap.get(iwb).Status__c.equals('Escalate Approved') || newMap.get(iwb).Status__c.equals('Auto-Approved'))){
                        approvedWRs.add(newMap.get(iwb));
                    }
                    else{
                        System.debug('Else Statement entered');
                        reqStatusChangedList.add(newMap.get(iwb));
                    }
                }
                if(newMap.get(iwb).Status__c != NULL && (newMap.get(iwb).Status__c.equals('Awaiting Approval') || newMap.get(iwb).Status__c.equals('Escalated') ) && newMap.get(iwb).LOE__c != oldMap.get(iwb).LOE__c){
                    reqStatusChangedList.add(newMap.get(iwb));
                }
            }
            
            if(reqStatusChangedList != NULL && reqStatusChangedList.size() > 0){
                wb.sendEmailNotificationToUsersonStatus(reqStatusChangedList);
            }
            if(approvedWRs !=  NULL && approvedWRs.size() > 0){
                System.debug('iW aft updt :' + approvedWRs[0].Account__r.name );
                wb.createProjectsHandlerFunction(approvedWRs);
            }   
            
            
        }// end of After Update
        
    }*/
    
    
}