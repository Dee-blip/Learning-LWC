/* 
/*********************************************************************************************************************
 * JIRA             : ESESP-5250
 * Author           : Sujay Surendranath
 * Created Date     : 03-23-2022
 * Purpose          : To Hanle Delivery Team Membership 
 
/************************************************************************************************************************
*/ 

public without sharing class PS_DTMHandler extends ApexTriggerHandlerAbstractClass
{

    public override void beforeInsertBeforeUpdateTrigger()
    {   
      if(Trigger.isInsert)
       PS_DTMTriggerClass.beforeInsertUpdate(true, null, newList , null, null);

      if(Trigger.isUpdate)
       PS_DTMTriggerClass.beforeInsertUpdate(false, oldList, newList, (Map <Id, Delivery_Team_Membership__c>) oldMap, (Map <Id, Delivery_Team_Membership__c>) newMap);
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