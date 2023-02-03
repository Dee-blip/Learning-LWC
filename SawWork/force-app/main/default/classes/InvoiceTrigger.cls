/***

	InvoiceTrigger.cls
    @author : Ali KM <mohkhan@akamai.com>

	@History
	--Developer				--Date			--Change
	Ali KM					8/Jul/2012		CR 1735546 Invoice Security
											->  Broke the Master-Detail tie between Account & Invoice__c. Now Invoice__c is child of Merge_Contract_Header__c. 
												Prior to this change, Account.Max Invoice Date field was roll-up summary field. Now mimicking the Roll-Up functionality
												and updating Account.Max Invoice Date whenever an Invoice is created/edited.
*/

global class InvoiceTrigger
{  
	/**
		updateAccounts(String[] pAccountIds) 
		- Updates Account.Max Invoice Date field with the MAX(Invoice__c.Invoice_Date__c) of all associated Invoices on the Account. 
		@to do: Currently referring to the Invoice__c.Account_Name__c for picking up the associated Account, need to change that to refer to Parent.Account__c instead. 
		This will need a Cast Iron change to stop updating the Invoice.CI_Account_Name__c field. 
	*/
	//@future 
	public static void updateAccounts(String[] pAccountIds) 
	{
		// Map of Account and List of Invoice Dates.
		Map<Id,List<Date>> accToInvoiceDateMap = new Map<Id,List<Date>>();
		for (Invoice__c invoice : [Select Id, Account_Name__c, Invoice_Date__c from Invoice__c where Account_Name__c 
			IN :pAccountIds AND Invoice_Date__c!=null AND CreatedDate >= LAST_N_YEARS:5 ]) // need to check if this will blow out coz of QueryException for 100K records.
			{
				if (accToInvoiceDateMap.containsKey(invoice.Account_Name__c))
					accToInvoiceDateMap.get(invoice.Account_Name__c).add(invoice.Invoice_Date__c);
				else
					accToInvoiceDateMap.put(invoice.Account_Name__c, new List<Date> {invoice.Invoice_Date__c});
			}
		
		if (accToInvoiceDateMap.size()<1)
			return;
		
		List<Account> accToUpdateList = new List<Account>();	
		for (Id accId : accToInvoiceDateMap.keySet())
		{
			accToInvoiceDateMap.get(accId).sort();
			//System.debug('accToInvoiceDateMap SORTED=' + accToInvoiceDateMap.get(accId));
			Date maxInvoiceDate = accToInvoiceDateMap.get(accId)[accToInvoiceDateMap.get(accId).size()-1];
			//System.debug('maxInvoiceDate=' + maxInvoiceDate);
			accToUpdateList.add(new Account(id=accId, Max_Invoice_Date__c=maxInvoiceDate, Validation_Override__c=true));
		}  
		
		if (accToUpdateList.size()>0)
		{
			System.debug('accToUpdateList=' + accToUpdateList);
			update accToUpdateList;
		}	
  	}
}