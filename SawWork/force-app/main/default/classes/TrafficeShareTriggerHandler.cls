public class TrafficeShareTriggerHandler extends ApexTriggerHandlerAbstractClass{
	
public List<Traffic_Share__c> newList=null;
public Map<Id,Traffic_Share__c>newMap =null;
public List<Traffic_Share__c> oldList=null;
public Map<Id,Traffic_Share__c> oldMap=null;

	public void initializeContextVariables()
	{
		newList=	(List<Traffic_Share__c>)trigger.new;
		newMap=(Map<Id,Traffic_Share__c>)trigger.newMap;
		oldList=(List<Traffic_Share__c>)trigger.old;
		oldMap=(Map<Id,Traffic_Share__c>)trigger.oldMap;
	}
	public override void beforeInsertBeforeUpdateTrigger()
    {
    	  initializeContextVariables();
    	  AkamFieldHandler akamFieldHandler = new AkamFieldHandler();
    	   if (Trigger.isInsert)
          akamFieldHandler.insertHandler(newList);    
       else 
          akamFieldHandler.updateHandler(newList);
      for(Traffic_Share__c ts: newList)
    	  {
          Traffic_Share__c tsOld = new Traffic_Share__c();
    	  	if(trigger.isBefore)
	     ts.Traffic_Share_Unique_Key__c=ts.Traffic_Share_Unique_Key_Formula__c; 

          if(trigger.isBefore && trigger.isInsert) {
            ts.P_B_Month_Modified_Date__c = date.today();
          }

          if(trigger.isBefore && trigger.isUpdate) {
            tsOld=(Traffic_Share__c)oldMap.get(ts.Id);
            if(Util.hasChanges('Amount__c',tsOld,ts))
              ts.P_B_Month_Modified_Date__c = date.today();

          }

    	  }
    }
    
    public override void afterInsertAfterUpdateTrigger()
    {
        initializeContextVariables();
        List<Traffic_Share__c> tsList=new List<Traffic_Share__c>();
        for(Traffic_Share__c ts: newList)
    	    { 
          if(trigger.isInsert && ts.Akam_Traffic_Share_Id__c ==null)
	        {
	         Traffic_Share__c tsNew=new Traffic_Share__c();
             tsNew.Id=ts.Id;
             tsNew.Akam_Traffic_Share_Id__c=ts.Traffic_Share_Auto_Number__c;
             tsList.add(tsNew);
	        }
        }
    	 if(tsList.size()>0)
      {
         update tsList;
      }
        
    }
    public override void beforeDeleteBeforeUndeleteTrigger()
    {
        System.debug('This is before delete and before undelete.');
    }

    public override void afterDeleteAfterUndeleteTrigger()
    {
        System.debug('This is after delete and after undelete.');
    }
}