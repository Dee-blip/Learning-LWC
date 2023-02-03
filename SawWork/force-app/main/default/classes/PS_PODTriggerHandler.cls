/* 
/*********************************************************************************************************************
 * JIRA             : ESESP-5250
 * Author           : Sujay Surendranath
 * Created Date     : 03-23-2022
 * Purpose          : To Hanle Delivery POD Trigger
 
/**********************************************************************************************************************
*/ 

public without sharing class PS_PODTriggerHandler extends ApexTriggerHandlerAbstractClass
{
    public override void beforeInsertBeforeUpdateTrigger()
    {   
      if(Trigger.isInsert)
       PS_PODTriggerClass.beforeInsertUpdate(true, null, newList , null, null);

      if(Trigger.isUpdate)
       PS_PODTriggerClass.beforeInsertUpdate(false, oldList, newList, (Map <Id, POD_Association__c>) oldMap, (Map <Id, POD_Association__c>) newMap);
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