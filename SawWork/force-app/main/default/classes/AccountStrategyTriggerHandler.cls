public class AccountStrategyTriggerHandler extends ApexTriggerHandlerAbstractClass{
 
public List<Account_Strategy__c> newList=null;
public Map<Id,Account_Strategy__c>newMap =null;
public List<Account_Strategy__c> oldList=null;
public Map<Id,Account_Strategy__c> oldMap=null;
 
    public void initializeContextVariables()
	{
		newList=	(List<Account_Strategy__c>)trigger.new;
		newMap=(Map<Id,Account_Strategy__c>)trigger.newMap;
		oldList=(List<Account_Strategy__c>)trigger.old;
		oldMap=(Map<Id,Account_Strategy__c>)trigger.oldMap;
	}
    
    public override void beforeInsertBeforeUpdateTrigger()
    {
    	  initializeContextVariables();
    	  AkamFieldHandler akamFieldHandler = new AkamFieldHandler();
    	   if (Trigger.isInsert)
          akamFieldHandler.insertHandler((List<Account_Strategy__c>)newList);    
       else 
          akamFieldHandler.updateHandler((List<Account_Strategy__c>)newList);
    }
    
    public override void afterInsertAfterUpdateTrigger()
    {
        initializeContextVariables();
        List<Account_Strategy__c> asList=new List<Account_Strategy__c>();
        for(Sobject so: trigger.new)
    	    {
	    	 	Account_Strategy__c acs=(Account_Strategy__c)so;
	    	 	if(trigger.isInsert && acs.Akam_Account_Strategy_Id__c ==null)
	        {
	         Account_Strategy__c asNew=new Account_Strategy__c();
	         asNew.Id=acs.Id;
	         asNew.Akam_Account_Strategy_Id__c=acs.Account_Strategy_Auto_Number__c;
	         asList.add(asNew);
	        }
    	 	}
    	 if(asList.size()>0)
      {
         update asList;
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