trigger PSA_TaskTime_BeforeTrigger on pse__Task_Time__c (before insert, before update) {
    if(trigger.isInsert || trigger.isUpdate)
    {
        try {
            PSA_TaskTimeActions.checkMilestoneTypeTaskMatch(Trigger.New);
        }
        Catch(Exception e)
        {
            PSA_AutoCreateProjectUtil.sendErrorMails('Error in validating Milestone and Task Type match',e.getMessage());
        }
    }

}