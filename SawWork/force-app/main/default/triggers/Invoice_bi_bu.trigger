/***

	Invoice_ai_au.trigger
    @author : Chandra Mohan Lohani <clohani@akamai.com>

	@History
	--Developer				--Date			--Change
	Ali KM					8/Jul/2012		CR 1735546 Invoice Security
											-> Changed the order of Invoice AKAM ID resolution to invoiceContractResolve first and then invoiceAccountResolve next.
											-> @to do: Need to stop resolving the Account_Name__c in future and make it Formula field (=Parent.Account_Name__c). This will need CI change first.
*/

trigger Invoice_bi_bu on Invoice__c (before insert, before update) {

	List<Invoice__c> invoiceContractResolveList = new List<Invoice__c>();
	for(Invoice__c invoice : Trigger.new)
	{
		if((Trigger.isInsert && invoice.CI_Original_Contract_Id__c != null))// || (!Trigger.isInsert && invoice.CI_Original_Contract_Id__c != Trigger.oldMap.get(invoice.ID).CI_Original_Contract_Id__c))
			{
			 invoiceContractResolveList.add(invoice);
			}
		else if (!Trigger.isInsert && invoice.CI_Original_Contract_Id__c != Trigger.oldMap.get(invoice.ID).CI_Original_Contract_Id__c)
			{
				invoice.addError('Original Contract Id cannot be updated after insert.');
			}
	}
	if(invoiceContractResolveList.size() > 0)
	   {
		CastIronClass.Resolve_Invoice_ContractHeaderForeignKeys(invoiceContractResolveList);
	   }

	// Cast Iron Integration : Resolve the Account Foreign Keys
	List<Invoice__c> invoiceAccResolveList = new List<Invoice__c>();
	for(Invoice__c invoice : Trigger.new)
	{
		if((Trigger.isInsert && invoice.CI_Account_Name__c != null) || (!Trigger.isInsert && invoice.CI_Account_Name__c != Trigger.oldMap.get(invoice.ID).CI_Account_Name__c))
			{
				invoiceAccResolveList.add(invoice);
			}
		/*
		else if(!Trigger.isInsert && invoice.CI_Account_Name__c != Trigger.oldMap.get(invoice.ID).CI_Account_Name__c)
		    {
		    	invoice.addError('Account Id cannot be updated after insert.');
		    }
		    */
	}
	if(invoiceAccResolveList.size() > 0)
	{
		CastIronClass.Resolve_Invoice_AccountForeignKeys(invoiceAccResolveList);
	}
 //  Code By Rahul : AKAM field updation Through The code
  if(Trigger.isBefore) {
    Id CrmIntegration = Id.valueOf(GsmUtilClass.getGSMSettingValue('CRM_Integration'));
    for(Invoice__c invoice : Trigger.new){
      //This code takes care OF AKAM fields while insert if any of these field is null or Empty
      if(Trigger.isInsert){
        if((UserInfo.getUserId() == CrmIntegration && (invoice.AKAM_Created_By__c =='' ||
          invoice.AKAM_Created_Date__c == null ||invoice.AKAM_System__c =='')) || UserInfo.getUserId() != CrmIntegration ) {
          invoice.AKAM_Created_By__c = invoice.AKAM_Alias__c ;
          invoice.AKAM_Created_Date__c = system.now();
          invoice.AKAM_System__c ='FORCE';
        }
      }
    // This code bassically checks if any value of Akam modified is null for Insert or Updates it populates the default value
      if((UserInfo.getUserId() == CrmIntegration && (invoice.AKAM_Modified_Date__c  == null||
        invoice.AKAM_Modified_By__c == '' || invoice.AKAM_Modified_By__c == null)) || UserInfo.getUserId() != CrmIntegration )  {
        invoice.AKAM_Modified_By__c = invoice.AKAM_Alias__c;
        invoice.AKAM_Modified_Date__c =  system.now();
      }
    }
  }
}