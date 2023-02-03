trigger CampaignMemberTrigger on CampaignMember (after insert, after update, before delete, before insert) 
{
    if(ByPassAndLimitUtils.isDisabled('CampaignMemberTrigger'))
        return;

    ApexTriggerHandlerAbstractClass.createHandler('CampaignMember');
}