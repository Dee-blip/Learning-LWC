/*
 * Lisha Murthy          11/11/2013        CR 2411301 - Need to disable trigger code for Service Cloud
                                            - By-passing the trigger code for connection user.
*/
trigger TaskTrigger_bd on Task (before delete) 
{   
    if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
    {
        /** Given Sys Admin Override to delete Tasks for CronKit.
             CR 653554 Error logging / notification for Scheduled Jobs
        */
        Map<String,GSM_Settings__mdt> testcaseCustomSettings = GsmUtilClass.getGSMSettingValue();

        String sysAdminProfileId = testcaseCustomSettings.get('SystemAdminProfileId').Value__c;
        if (Userinfo.getProfileId() != sysAdminProfileId)
        {
            /* Order Approval Activity */
            // CR 860591 Remove Delete functionality on Order Approval Tasks    
            Id oaRecTypeId = TaskTriggerClass.GetOaRecTypeId();
            for(Task tsk:Trigger.old)
                if(tsk.RecordTypeId == oaRecTypeId) // Added the Approval_Request_Agreement_Proposal_Id__c field as part of CR 2499807 (Q2O). Removed the apttus related fields as part of SFDC-2688
                    tsk.addError('Activities associated to an Order Approval cannot be deleted.');
        }
    }
}