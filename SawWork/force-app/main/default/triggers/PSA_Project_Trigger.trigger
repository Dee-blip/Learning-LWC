/***
PSA_Project_Trigger
@author Liz Ichihashi
@Description : This trigger calls methods in the Action class on before insert and update
that are called by PSA_Contract_Trigger
@History
--Developer           --Date            --Change
Liz Ichihashi         7/04/2013     Created the class.   
*/
trigger PSA_Project_Trigger on pse__Proj__c (before insert, before update) {
    if (trigger.isUpdate || trigger.isInsert) {
        PSA_ProjectActions.checkForProjectManagerOwnerChange(trigger.old, trigger.new);     
    }   
    if (trigger.isUpdate) {
        PSA_ProjectActions.checkForContractClosedWithoutProjectContractItems(trigger.old, trigger.new);
        //20.6 - 
        PSA_ProjectActions.checkForCLIPresense(trigger.oldMap, trigger.newMap);
        //PSA_Settings__c CrmIntegProfile = PSA_Settings__c.getInstance('CRM Integration');
        //Id CrmIntegProfileId = CrmIntegProfile.Value__c;
        List<PSA_Common_Setting__mdt> CrmIntegProfile = new List<PSA_Common_Setting__mdt>([Select Value_Long__c from PSA_Common_Setting__mdt where Name__c = 'CRM Integration']);
        Id CrmIntegProfileId = CrmIntegProfile.get(0).Value_Long__c;
        if(UserInfo.getProfileId()== CrmIntegProfileId)
            PSA_ProjectActions.checkForAssignmentUpdates(trigger.old, trigger.new);
        PSA_ProjectActions.checkForValidClosedForTimeEntry(trigger.old, trigger.new);
        //Start of changes by Samir for Release 4.11
        PSA_ProjectActions.CheckUncheckIgnoreSavedTimecards(trigger.old, trigger.new);
        //PSA_ProjectActions.CheckForSavedTimecardsWhenPMChanges(trigger.old, trigger.new);
        //End of changes by Samir for Release 4.11
        PSA_ProjectActions.createOpptyTask(Trigger.New, Trigger.oldMap);
        //Changes by Sandeep Naga for FFPSA-772
        if(trigger.isBefore)
            PSA_ProjectActions.updateBICAndICOnProject(trigger.oldMap,trigger.new);
        //Changes by Suhas Jain for JIRA FFPSA-636
        PSA_ProjectActions.restrictCurrentTermFieldAccess(trigger.oldMap, trigger.new);
    }
}