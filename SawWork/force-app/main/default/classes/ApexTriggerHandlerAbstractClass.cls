/**
*  ApexTriggerHandlerAbstractClass
*
 --Developer         --Date          --Description
   Sausharm           18/06/2018       SFDC-2854 Adding support for multiple handlers
**/

public with sharing abstract class ApexTriggerHandlerAbstractClass implements ApexTriggerInterface
{
  
  public  static Set<ApexTriggerHandlerAbstractClass> handlerList;

  public static String sObjectName=null;

  public static Map<String,Set<ApexTriggerHandlerAbstractClass>> sObjectTypeTohandlerClassObj = new Map<String,Set<ApexTriggerHandlerAbstractClass>>();
  
  public List<SObject> newList=null;
  
  public Map<Id,SObject>newMap =null;
  
  public List<SObject> oldList=null;
  
  public Map<Id,SObject> oldMap=null;

  public static String dataClassName = null;

  //SFDC-4047
  public static Boolean firstRunFlag = true;
  public static Boolean objTrackingFeature = false;

  public TriggerAbstractDataClass dataClassHandlerObj = null;
  
  public ApexTriggerHandlerAbstractClass() 
  {
    if(dataClassName != null)
    {
      Type tt = Type.forName(dataClassName);
      dataClassHandlerObj = (TriggerAbstractDataClass)tt.newInstance();
      dataClassHandlerObj.initializeDataClassMethods();
    }
    
  }

  // SFDC-2854 Reads and invokes through the Handlers provided in TriggerHandlerMappings custom metadata
  // All active Handlers against sObject name will be called in specified sequence (Handlers with no sequence are called at end)
  // Provide sObject Name under "TriggerObject", multiple records need to be created for multiple Handlers
  public static Set<ApexTriggerHandlerAbstractClass> createHandler(String sObjectType)
  {
    
    // If we already got the list of handlers, we can skip this step and move on to executing the handlers
    if(!sObjectTypeTohandlerClassObj.containsKey(sObjectType))
    {
     handlerList = new Set<ApexTriggerHandlerAbstractClass>();
     try
     {
       
       for( TriggerHandlerMapping__mdt handlerMDTRecord : [select DeveloperName,Object_Tracking_Feature__c,TriggerHandlerClassName__c,isActive__c,TriggerDataClassName__c,Sequence__C from TriggerHandlerMapping__mdt where TriggerObject__c =: sObjectType AND isActive__c =: true ORDER BY Sequence__c ASC NULLS LAST])
       {
          if(!objTrackingFeature && handlerMDTRecord.Object_Tracking_Feature__c){
              objTrackingFeature = handlerMDTRecord.Object_Tracking_Feature__c;
            }
         String handlerClassName = handlerMDTRecord.TriggerHandlerClassName__c;
         if(handlerMDTRecord.TriggerDataClassName__c != null)
         {
           dataClassName = handlerMDTRecord.TriggerDataClassName__c;
         }
       
         Type t= Type.forName(handlerClassName);
         ApexTriggerHandlerAbstractClass handlerClassObj= (ApexTriggerHandlerAbstractClass)t.newInstance();
         handlerList.add(handlerClassObj);
         
      }
      sObjectTypeTohandlerClassObj = new Map<String,Set<ApexTriggerHandlerAbstractClass>>();
      if(handlerList.size()>0)
      {
        sObjectTypeTohandlerClassObj.put(sObjectType,handlerList);
      }

     }
     catch(Exception e)
     {
        new ApexExceptionHandlerClass().handleError(e);
     }
     
    }
    if(handlerList.size()>0)
    {        
        for( ApexTriggerHandlerAbstractClass handlerClassObj : handlerList)
        {
          // Initialize trigger variables like "NewList", "NewMap"  
          initializeTriggerContextVariables(handlerClassObj);
          handlerClassObj.startTrigger(sObjectType);
      }
      
    }    
   return handlerList;
  }  
  
  // SFDC-2854 Initialize any Trigger data/variables here
  public static void initializeTriggerContextVariables(ApexTriggerHandlerAbstractClass handlerClassObj)
  {
    handlerClassObj.newList=trigger.new;
    handlerClassObj.oldList=trigger.old;
    handlerClassObj.newMap=trigger.newMap;
    handlerClassObj.oldMap=trigger.oldMap;
    
  }

  // SFDC-2854 Before methods of multiple Handlers are called first followed by After methods
  public void startTrigger(String sObjectType)
  {
    if(Trigger.isBefore)
    {
      if(Trigger.isInsert || Trigger.isUpdate)
        beforeInsertBeforeUpdateTrigger();

      if(Trigger.isDelete || Trigger.isUndelete)
        beforeDeleteBeforeUndeleteTrigger();  

    }
    else
    {       
      if(Trigger.isInsert || Trigger.isUpdate){

        //SFDC-4047
        if(Trigger.isUpdate && firstRunFlag){
            if(newList.size() > 0 && objTrackingFeature){
                RecordUpdateHistoryHandler handler = new RecordUpdateHistoryHandler(newList, sObjectType, UserInfo.getUIThemeDisplayed());
                System.enqueueJob(handler);
                firstRunFlag = false;
            }
        }
        
        afterInsertAfterUpdateTrigger();
      }

      if(Trigger.isDelete || Trigger.isUndelete)
        afterDeleteAfterUndeleteTrigger();  
    }
  }

  public abstract void beforeInsertBeforeUpdateTrigger();

  //public abstract void beforeUpdateTrigger();

  public abstract void beforeDeleteBeforeUndeleteTrigger();

  public abstract void afterInsertAfterUpdateTrigger();

  //public abstract void afterUpdateTrigger();

  public abstract void afterDeleteAfterUndeleteTrigger();
}