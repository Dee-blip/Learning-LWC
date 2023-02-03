/***
    PSA_ProjectContractLineItemActions_Test
    @author Liz Ichihashi
    @Description : This Class contains methods to test PSA_ProjectContractLineItemActions
                   which contains methods called from PSA_ProjectContractLineItem_Trigger.
                   One method (on before delete) prevents deletes when there is a related Milestone or Assignment.
                   One method (on after delete) checks to see if any childless Project Contract records can
                   be deleted.
                   
                   This class supports PSA customization requirment 4.1.2 and 4.1.3 - Add/Remove Project Contract Line Item
    @History
    --Developer           --Date            --Change
    Liz Ichihashi         7/04/2013     Created the class.       
*/
trigger PSA_Assignment_Trigger on pse__Assignment__c (before insert,before update) {
    if(Trigger.isInsert)
   PSA_AssignmentActions.checkForProjectContractLineItemToAssociate(trigger.new);
    else if(Trigger.isUpdate)
   PSA_AssignmentActions.checkForValidClosedForTimeEntry(trigger.old, trigger.new);  
}