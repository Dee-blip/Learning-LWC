public class BeepTriggerHandler extends ApexTriggerHandlerAbstractClass
{
    public BeepTriggerHandler(){}

    public override void beforeInsertBeforeUpdateTrigger()
    {
        for(SObject so: newList)
        {
            Beep__c bp = (Beep__c)so;
            Beep__c oldBp;
            if(Trigger.isUpdate)
                oldBp = (Beep__c)oldMap.get(bp.Id);

            if(Trigger.isUpdate && bp.Status__c!=oldBp.Status__c)
            {
                if(bp.Status__c=='MUTED')
                    bp.Muted_On__c=System.now();
                else if(bp.Status__c=='RESOLVED')
                    bp.Resolved_On__c=System.now();
            }

        }
    }

    public override void afterInsertAfterUpdateTrigger(){}

    public override void beforeDeleteBeforeUndeleteTrigger(){}

    public override void afterDeleteAfterUndeleteTrigger(){}

}