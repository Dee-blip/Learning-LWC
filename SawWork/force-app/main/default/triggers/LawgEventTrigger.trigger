trigger LawgEventTrigger on Lawg__e (after insert) 
{
    LawgPlatformEventTriggerHandler.afterInsert(Trigger.new);
}