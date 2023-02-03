/**
DraftInvoiceTriggerHandler
    @author : Ali KM <mohkhan@akamai.com>
    @Description : This class is used to handle all triggers for Draft_invoice object.
    			
	@History
	--Developer		      --Date			--Change
	Ali KM		     	  06/02/2013		Created the class	
											CR 2068273 - Invoice Review Cases Process migration from Siebel to SF. 
	Ali IM				  24/04/2013		CR 2181044 - IR Case - For Ad-Hoc DraftInvoice/Case creation change.										
											- Enabled AfterInsert trigger code.	 											
*/
public without sharing class DraftInvoiceTriggerHandler extends ITrigger
{
	public override void beforeInsert(List<SObject> so) 
	{	
    	DraftInvoiceTriggerClass.beforeInsertUpdate(true, null, (List<Draft_Invoice__c>)so, null, null);
  	}
  
  	public override void beforeUpdate(Map<Id, SObject> oldSo, Map<Id, SObject> so) 
  	{
    	DraftInvoiceTriggerClass.beforeInsertUpdate(false, (List<Draft_Invoice__c>)oldSo.values(), (List<Draft_Invoice__c>)so.values(), (Map<Id, Draft_Invoice__c>)oldSo, (Map<Id, Draft_Invoice__c>)so);
  	}
  	
  	public override void beforeDelete(Map<Id, SObject> so) 
  	{
  		IRCaseHelperClass.restrictDelete(so.values());
  	}
  
  	public override void afterInsert(Map<Id, SObject> so) 
  	{
    	DraftInvoiceTriggerClass.afterInsertUpdate(true, null, (List<Draft_Invoice__c>)so.values(), null, (Map<Id, Draft_Invoice__c>)so);
  	}
	
	public override void afterUpdate(Map<Id, SObject> oldSo, Map<Id, SObject> so) 
	{
		DraftInvoiceTriggerClass.afterInsertUpdate(false, (List<Draft_Invoice__c>)oldSo.values(), (List<Draft_Invoice__c>)so.values(), (Map<Id, Draft_Invoice__c>)oldSo, (Map<Id, Draft_Invoice__c>)so);
	}
	  
	public override void afterDelete(Map<Id, SObject> so) {}
}