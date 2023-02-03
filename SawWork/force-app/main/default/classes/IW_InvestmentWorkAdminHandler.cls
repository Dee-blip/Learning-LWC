/**
 * @description       : FFPSA-558
 * @author            : Sujay 
 * date               : March 2020
 * @last modified on  : 07-12-2021
**/

public without sharing class IW_InvestmentWorkAdminHandler extends ApexTriggerHandlerAbstractClass
{
    InvWB_RQMapHandler rqMap = new InvWB_RQMapHandler();
    public IW_InvestmentWorkAdminHandler()
    {
    }
    
    
    public override void beforeInsertBeforeUpdateTrigger()
    {   
        if(Trigger.isInsert)
        {
            rqMap.rQMapRecordsBeforeInsert(Trigger.new);
        }
        
        if(Trigger.isUpdate)
        {
            rqMap.rQMapRecordsBeforeUpdate((Map <Id, Inv_Workbox_Region_Quarter_Mapping__c>) newMap,(Map <Id, Inv_Workbox_Region_Quarter_Mapping__c>) oldMap);
        }
    }
    
    public override void afterInsertAfterUpdateTrigger()
    {   
        
    }
    
    public override void beforeDeleteBeforeUndeleteTrigger()
    {
        
    }
    
    public override void afterDeleteAfterUndeleteTrigger()
    {
        
    }   
    
    
}