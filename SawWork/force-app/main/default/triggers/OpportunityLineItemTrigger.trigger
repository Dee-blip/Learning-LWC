/* Ruchika Sharma   21/01/2014  CR 2891568 and 2948870 - added code for calling OpportunityLineItemTriggerClass.populateStrategicNetMRR  
                                -> populate strategic net MRR as MRR from opportunity line item except line item having forecast group ‘Media’ but include 'Media & Delivery - Dynamic Site Delivery' 
*/
trigger OpportunityLineItemTrigger on OpportunityLineItem (after delete, after insert, after undelete, after update, before delete, before insert, before update)
{
    
    // SFORCE-146 Dissabled the trigger while running the USDconversion job
    if(!CronCurrencyToUsdConversionBatchClass.dissableTriggerFlag)
         return;
    if(ByPassAndLimitUtils.isDisabled('OpportunityLineItemTrigger'))
    {
        //set akam field
        if(Trigger.isBefore)
            ByPassAndLimitUtils.setAkamField(Trigger.isInsert, Trigger.isUpdate, Trigger.New);
        return;
    }
    ApexTriggerHandlerAbstractClass.createHandler('OpportunityLineItem');
}