/***
    AccountReassignmentUpdateRolesClass
    
    --Developer           --Date            --Change
    
                                            
    Sonali Tandon         26/02/2015        Created the class  
    										CR 2913906 - Account Reassignment Rule creation: User Role not updated
    										Created job to schedule UpdateOwnerRole() asychronously to avoid group membership lock 
    										and ensure successful updation of user roles during account reassignment.    
*/

global class AccountReassignmentUpdateRolesClass implements Schedulable{

    global Set<Id> reassignmentRuleIds;

    global AccountReassignmentUpdateRolesClass(Set<Id> ruleIds)
    {
        reassignmentRuleIds = ruleIds;
    }

    global void execute(SchedulableContext sc)
    {
        AccountReassignmentRuleTriggerClass.UpdateOwnerRole(reassignmentRuleIds);
    }

}