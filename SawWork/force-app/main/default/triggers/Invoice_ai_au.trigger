/***

	Invoice_ai_au.trigger
    @author : Ali KM <mohkhan@akamai.com>

	@History
	--Developer				--Date			--Change
	Ali KM					8/Jul/2012		CR 1735546 Invoice Security
											->  Broke the Master-Detail tie between Account & Invoice__c. Now Invoice__c is child of Merge_Contract_Header__c. 
												Prior to this change, Account.Max Invoice Date field was roll-up summary field. Now mimicking the Roll-Up functionality
												and updating Account.Max Invoice Date whenever an Invoice is created/edited.
*/

trigger Invoice_ai_au on Invoice__c (after insert, after update) 
{
	List<String> invoiceAccountUpdateList = new List<String>();
	for(Invoice__c invoice : Trigger.new)
	{
		if (invoice.Account_Name__c==null) //invoice.Invoice_Date__c==null || 
			continue;
		
		if (Trigger.isInsert)
			invoiceAccountUpdateList.add(invoice.Account_Name__c);
		else if (Trigger.isUpdate && invoice.Invoice_Date__c != Trigger.oldMap.get(invoice.id).Invoice_Date__c)
			invoiceAccountUpdateList.add(invoice.Account_Name__c);
	}
	if (invoiceAccountUpdateList.size()>0) 
		InvoiceTrigger.updateAccounts(invoiceAccountUpdateList);
		
    //Jira:ESESP-4094 
    //Added By:Bhavesh to autogenerate Billing Case on creation of Invoice record.
    if (Trigger.isInsert && Trigger.isAfter)
    	SC_InvoiceTriggerHandler.createBillingCaseForInvoice(Trigger.new);
}