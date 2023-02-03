/***
    PSA_Milestone_Trigger
    @author Liz Ichihashi
    @Description : This is a before delete trigger on Milestone.
                   It calls a method to check to see whether the
                   delete should be allowed.  Also checks to see
                   whether the milestone is a template one 
                   and enforces some fields as read-only 
    @History
    --Developer           --Date            --Change
    Liz Ichihashi         9/04/2013     Created the class.  
    Sonia                 30/05/2014    CR 2576469 - User Profile: Ability to add, modify & remove Project templates      
*/
trigger PSA_Milestone_Trigger on pse__Milestone__c (before delete, before update, before insert) {
    if (trigger.isUpdate) {
        PSA_MilestoneActions.checkForUpdatesToTemplateMilestones(trigger.old, trigger.new);
        PSA_MilestoneActions.checkForValidClosedForTimeEntry(trigger.old, trigger.new);
    } else if (trigger.isDelete) {
        PSA_MilestoneActions.checkForRelatedTimecardsOrIsFromTemplate(trigger.old);
    } 
    //start of changes for  CR 2576469 
    else if (trigger.isInsert) {
        PSA_MilestoneActions.checkTemplateMilestoneInsert(trigger.new);
    }  
    //end of changes for  CR 2576469 
}