public class DeliveryVendorTriggerHandler extends ApexTriggerHandlerAbstractClass{

public List<Delivery_Vendor__c> newList=null;
public Map<Id,Delivery_Vendor__c>newMap =null;
public List<Delivery_Vendor__c> oldList=null;
public Map<Id,Delivery_Vendor__c> oldMap=null;

public void initializeContextVariables()
{
	newList=	(List<Delivery_Vendor__c>)trigger.new;
	newMap=(Map<Id,Delivery_Vendor__c>)trigger.newMap;
	oldList=(List<Delivery_Vendor__c>)trigger.old;
	oldMap=(Map<Id,Delivery_Vendor__c>)trigger.oldMap;
}
 
 public override void beforeInsertBeforeUpdateTrigger()
    {
    	  initializeContextVariables();
    	  AkamFieldHandler akamFieldHandler = new AkamFieldHandler();
    	   if (Trigger.isInsert)
          akamFieldHandler.insertHandler(newList);    
       else 
          akamFieldHandler.updateHandler(newList);
      for(Delivery_Vendor__c dv: newList) {
          Delivery_Vendor__c dvOld = new Delivery_Vendor__c();

    	  	if(trigger.isBefore)
    	  	  dv.Delivery_Vendor_Unique_Key__c=dv.Delivery_Vendor_Unique_Key_Formula__c;

          if(trigger.isBefore && trigger.isInsert) {
            dv.Vendor_Traffic_Share_Modified_Date__c = date.today();
          }

          if(trigger.isBefore && trigger.isUpdate) {
            dvOld=(Delivery_Vendor__c)oldMap.get(dv.Id);
            if(Util.hasChanges('Vendor_Traffic_Share__c',dvOld,dv))
              dv.Vendor_Traffic_Share_Modified_Date__c = date.today();

          }

    	  }
    }
    
    public override void afterInsertAfterUpdateTrigger()
    {
        initializeContextVariables();
        List<Delivery_Vendor__c> dvList=new List<Delivery_Vendor__c>();
         set<id> TrafficShareIDs = new set<id>();
        for(Delivery_Vendor__c dv: newList)
    	    {
            Delivery_Vendor__c dvOld = new Delivery_Vendor__c();
           if(Trigger.isUpdate)
                dvOld=oldMap.get(dv.Id);
          if(trigger.isInsert && dv.Akam_Delivery_Vendor_Id__c ==null)
	        {
	         Delivery_Vendor__c dvNew=new Delivery_Vendor__c();
             dvNew.Id=dv.Id;
             dvNew.Akam_Delivery_Vendor_Id__c=dv.Delivery_Vendor_Auto_Number__c;
             dvList.add(dvNew);
	        }
           //SFDC-5464
          if((trigger.isUpdate && Util.hasChanges('Vendor_Traffic_Share__c',dvOld,dv)) || (trigger.isInsert && dv.Vendor_Traffic_Share__c !=null))
            {      
                  TrafficShareIDs.add(dv.Traffic_Share__c);
                  
            }

        }
    	 if(dvList.size()>0)
      {
         update dvList;
      }
      //SFDC-5464
      if(TrafficShareIDs.size()>0)
            DeliveryVendorTriggerClass.UpdateTrafficList(TrafficShareIDs);
        
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