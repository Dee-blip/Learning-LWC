trigger AccountTeamMemberTrigger on AccountTeamMember (after delete, after insert, after undelete, after update, before delete, before insert, before update) 
{
    
    ApexTriggerHandlerAbstractClass.createHandler('AccountTeamMember');
    
}