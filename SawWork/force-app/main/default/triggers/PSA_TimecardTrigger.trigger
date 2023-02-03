/* ========================================================================
    Author: Sonia Sawhney
    Description: Used to restrict users from deleting timecards filled by other users
    Created Date : 10/04/2014
    Changes by Sharath Prasanna for CR: . Admin should be able to delete saved timecards. A new field valid delete has been added. If the field is set to true, then only saved timecards can be deleted by system admin apart from the resource. 
    ======================================================================== */
trigger PSA_TimecardTrigger on pse__Timecard_Header__c (before delete,Before Update,after insert,after update) {
    //Get the current user deleting the timecard
    Id currentUserId = UserInfo.getUserId();
    //Get the salesforce user id for the resource 
    If(Trigger.isDelete)
    {
        Map<Id, pse__Timecard_Header__c> mpTimecards = new Map<Id,pse__Timecard_Header__c>( [Select Id, Valid_Delete__c,pse__Resource__r.pse__Salesforce_User__c,pse__Status__c from pse__Timecard_Header__c where Id in :Trigger.oldmap.keyset()]);
        for(pse__Timecard_Header__c timecard: Trigger.old)
        {
            pse__Timecard_Header__c tc = mpTimecards.get(timecard.Id); 
            //Changes by sharath: before adding the error check if the user is the resource or its a valid delete by the admin and the timecard status is saved
            if(tc.pse__Resource__r.pse__Salesforce_User__c != currentUserId && !(tc.Valid_Delete__c && tc.pse__Status__c == 'Saved'))
            {

                timecard.addError('You do not have access to delete this timecard!');
            }
        }
    }

    if(Trigger.isUpdate)
    {
        PSA_TimecardActions.updateTaskTimeMilestone(Trigger.oldMap, Trigger.newMap);
        
         if(PSA_TimecardApproval_Validation.isRecursive == false)
         {
            PSA_TimecardApproval_Validation ValidateApproval = new PSA_TimecardApproval_Validation();
            ValidateApproval.validateApproval(trigger.New, trigger.OldMap);
         }

        // FFPSA-1719 - Issue with multiple timecard approval
        if (trigger.isBefore){
            PSA_TimecardApproval_Validation ValidateApproval = new PSA_TimecardApproval_Validation();
            ValidateApproval.stoptimecardApproval(trigger.New, trigger.OldMap);
        }
    }

    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate))
    {
        PSA_TimecardApproval_Validation ValidateApproval = new PSA_TimecardApproval_Validation();
        try
        {
            ValidateApproval.milestonePlannedHoursCheck(trigger.New, trigger.OldMap, trigger.isInsert);  
        }
        Catch(Exception e) 
        {
            PSA_AutoCreateProjectUtil.sendErrorMails('Error in Milestone Planned Hour Validation',e.getMessage());
        }
        
    }
    
    /* Start of changes by janantha for Automated Billing to stamp TimeDate records Eligible for billing. */
    /*if(CheckRecursion.runOnce())
    {*/
        
        if(Trigger.isAfter && Trigger.isUpdate)
        {
            PSA_TimecardActions timecardActions = new PSA_TimecardActions();
            timecardActions.stampTDEligibleForBilling(Trigger.new,Trigger.oldMap,true);
        }
        
        //Changes for FF v15 upgrade: Workaround: Set the timcard billable flag to false if the milestone is not billable 
        //Changes for FF v16 upgrade: commenting Workaround for FFv15
        //Following custom settings is used to enable/disable timecard billability check.
        PSA_Settings__c psaSetting = PSA_Settings__c.getValues('Timecard Billable check');
    String billableCheck;    
      if(psaSetting == null)
        {
            billableCheck = 'true';
        }
      else
        {  
            billableCheck = psaSetting.value__c;  
        }  
        if(billableCheck == 'true' && Trigger.isBefore && Trigger.isUpdate)
        {
            Map<Id,Boolean> timecardMilestones = new Map<Id,Boolean>();
            List<id> milestoneIDs = new List<id>();
            for (pse__Timecard_Header__c tch:trigger.new)
            {
                milestoneIDs.add(tch.pse__Milestone__c);
            }
            for (pse__Milestone__c milestone: [select id, Billable__c from pse__Milestone__c where id in :milestoneIDs])
            {
                timecardMilestones.put(milestone.id,milestone.Billable__c);
            }
            for(pse__Timecard_Header__c tch:trigger.new)
            {
                if(!timecardMilestones.get(tch.pse__Milestone__c))
                {
                    tch.pse__Billable__c = false;
                }
            }

        }

        if(Trigger.isAfter && Trigger.isInsert)
        {
            PSA_TimecardActions timecardActions = new PSA_TimecardActions();
            timecardActions.stampTDEligibleForBilling(Trigger.new,null,false);
        } 
    //}
    
    /* End of changes by janantha for Automated Billing to stamp TimeDate records Eligible for billing. */

    // Changes by Suhas for FFPSA-545
    if(Trigger.isAfter && Trigger.isUpdate)
    {
        try {
            PSA_TimecardActions.psHoursUtilization(Trigger.New, Trigger.OldMap);
        }
        Catch(Exception e)
        {
            PSA_AutoCreateProjectUtil.sendErrorMails('Error in calculating PS Hours',e.getMessage());
        }
    }
    // End Of Changes by Suhas for FFPSA-545

    //Start of changes by Sandeep for FFPSA-1328 : timecard hours threshold restriction.
    if(Trigger.isUpdate)
    { 
        try{
            //-> before trigger : SUbmit and recall, -> after trigger for Reject and approve
            //-> runOnce() is for recursions check

            // if we are data fixing both submit+recall and approve+reject timecards at the same time, it causes a problem, doesnt handle the approved timecards
            if(Trigger.isBefore){
                System.debug('@@@ trigger 1');
                PSA_TimecardHoursThreshold_Validation.ValidateTotalHoursWithThresholds(Trigger.New,Trigger.OldMap); 
            }
        
            if(Trigger.isAfter){
                System.debug('@@@ trigger 2');
                PSA_TimecardHoursThreshold_Validation.upsertweeklyUserTimecardHours(Trigger.New,Trigger.OldMap);  
            }
        }
        catch(Exception e){
            system.debug('@@@Error'+e.getMessage());
            PSA_AutoCreateProjectUtil.sendErrorMails('Error in Timecard Threshold Validation',e.getMessage());
        }
    }
    
    //End of changes by Sandeep for FFPSA-1328 : timecard hours threshold restriction.
    

}