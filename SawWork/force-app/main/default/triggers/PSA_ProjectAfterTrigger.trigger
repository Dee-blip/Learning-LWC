/*
Author: janantha
Description: after trigger on project for aligning end date of milestones with project
Created date: 30/12/2014
*/

trigger PSA_ProjectAfterTrigger on pse__Proj__c (after insert,after update) 
{
    List<pse__Proj__c> projects = new List<pse__Proj__c>();
    /*Start of changes by janantha for CR 2576145*/
    if(CheckRecursion.runOnce())
    {
    /*End of changes by janantha for CR 2576145*/
        if (trigger.isAfter && trigger.isUpdate)   
        {
            projects = trigger.new;
            for(pse__Proj__c proj:projects)
            {
                if(proj.Update_Milestone_Target_Date__c)
                    PSA_ProjectActions.checkForEndDateChange(trigger.oldMap, trigger.newMap);       
            }
       
            //Start of changes for CR 3053831 by Vandhana
            PSA_ProjectActions.sendEmailTSP(trigger.oldMap, trigger.newMap,true);  
            //End of changes for CR 3053831 by Vandhana

            //Start of changes for CR 3123441 by Vandhana Krishnamurthy
            PSA_ProjectActions.uncheckCloseTimeEntryHelper(trigger.oldMap, trigger.newMap);
            //End of changes for CR 3123441 by Vandhana

            /*Start of changes by janantha for CR 2576145*/        
            //PSA_ProjectActions.checkForProjectManagerChange(trigger.oldMap, trigger.newMap); 
            /*End of changes by janantha for CR 2576145*/   

            //Changes by Sharath for CR 3593271: Check for the project manager change and change the approver of the pending timecards
            PSA_ProjectActions.changeTimecardApprover(trigger.oldMap,trigger.newMap);
            //End of changes by Sharath                           
        }
        if (trigger.isAfter)
        {
            try
            {
                PSA_ProjectActions.autoCreateAssignments(trigger.new); 
            }
            catch(exception e)
            {
               system.debug('Error in creating Auto Assignment for PM: '+ e.getMessage()); 
            }
              
          
        }
        //CheckRecursion.setRunOnce();
    }
    //start of changes by shprasan
    if(trigger.isAfter && trigger.isinsert)
    {
        if(CheckRecursion.runInsertOnce())
        {
            //Start of changes for CR 3053831 by Vandhana Krishnamurthy            
            PSA_ProjectActions.sendEmailTSP(trigger.oldMap,trigger.newMap,false);
            //End of changes for CR 3053831 by Vandhana Krishnamurthy                            
        }   
    }
    //end of changes by shprasan

    // Changes by Suhas for FFPSA-490
    if(trigger.isAfter && trigger.isUpdate)
    {
        PSA_ProjectActions.notifyforBEDExtension(trigger.new, trigger.oldMap);
    }
    // End of changes by Suhas
   
}