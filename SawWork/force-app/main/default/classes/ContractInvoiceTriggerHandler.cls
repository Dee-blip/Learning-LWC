public class ContractInvoiceTriggerHandler extends ApexTriggerHandlerAbstractClass{

	public ContractInvoiceTriggerHandler() 
	{

	}
    
    public override void beforeInsertBeforeUpdateTrigger()
	{
		
	}

	public override void afterInsertAfterUpdateTrigger()
	{
		Map<Id,List<Invoice__c>> mchToInvoiceInsertUpdateMap = new Map<Id,List<Invoice__c>>();
		List<Invoice__c> invoiceList = new List<Invoice__c>();
		Set<Id> originalContractIdSet = new Set<Id>();	 

		for(SObject so: newList)
		{
			Invoice__c conInvoice=(Invoice__c)so;
			Invoice__c conInvoiceOld=null;
			if(!trigger.isInsert)
				conInvoiceOld=(Invoice__c)oldMap.get(conInvoice.Id);	
			if(trigger.isInsert && conInvoice.Invoice_Date__c != null && conInvoice.Original_Amount__c != null ) {
		   				originalContractIdSet.add(conInvoice.Original_Contract_Id__c);
		   			}
		}
		if(originalContractIdSet.size()>0)
		   	invoiceList = [Select Id,Original_Amount__c,Original_Contract_Id__c,Invoice_Date__c,CurrencyIsoCode from  Invoice__c Where Original_Contract_Id__c IN :originalContractIdSet AND Original_Amount__c != null AND Invoice_Date__c != null ];

		if(invoiceList.size() >0)
			{
				for(Invoice__c conInvoice :invoiceList)
				{
					if(mchToInvoiceInsertUpdateMap.containsKey(conInvoice.Original_Contract_Id__c))
		   			mchToInvoiceInsertUpdateMap.get(conInvoice.Original_Contract_Id__c).add(conInvoice);
		   			
		   			else
		   			{
		   				List<Invoice__c> tempInvoiceList = new List<Invoice__c>();
		   				tempInvoiceList.add(conInvoice);
						mchToInvoiceInsertUpdateMap.put(conInvoice.Original_Contract_Id__c,tempInvoiceList);
		   			}
		   		}
		   	}

		if(!mchToInvoiceInsertUpdateMap.isEmpty())
		   	updateInvoiceRemainingFundMethod(mchToInvoiceInsertUpdateMap);
		   	
	}

	public override void beforeDeleteBeforeUndeleteTrigger()
	{
		System.debug('This is before delete and before undelete.');
	}

	public override void afterDeleteAfterUndeleteTrigger()
	{
		System.debug('This is after delete and after undelete.');
	}

	public void updateInvoiceRemainingFundMethod(Map<Id,List<Invoice__c>> mchToInvoiceListInsertUpdateMap)
	{
	  	system.debug('Invoice Contract Map '+mchToInvoiceListInsertUpdateMap);
	  	Map<Merge_Contract_PO__c,List<Invoice__c>> poToInvoiceListMap = new Map<Merge_Contract_PO__c,List<Invoice__c>>();
	  	List<Merge_Contract_PO__c> mchPOUpdateList = new List<Merge_Contract_PO__c>();
	  	for(Merge_Contract_PO__c mchCPORecord : [Select Id, Original_Contract_Id__c,PO_Fund__c,Remaining_Fund__c,Start_Date__c,End_Date__c,CurrencyIsoCode from  Merge_Contract_PO__c Where Original_Contract_Id__c IN :mchToInvoiceListInsertUpdateMap.KeySet() AND PO_Fund__c != null ])
		{
			if(mchToInvoiceListInsertUpdateMap.containsKey(mchCPORecord.Original_Contract_Id__c))
			{

				for(Invoice__c mchInvoice :mchToInvoiceListInsertUpdateMap.get(mchCPORecord.Original_Contract_Id__c))
				{

					if(mchInvoice.Invoice_Date__c >=mchCPORecord.Start_Date__c && mchInvoice.Invoice_Date__c <= mchCPORecord.End_Date__c)
						{
							if(poToInvoiceListMap.containsKey(mchCPORecord))
		   						poToInvoiceListMap.get(mchCPORecord).add(mchInvoice);
		   					else
		   					{
		   						List<Invoice__c> tempInvoiceList = new List<Invoice__c>();
		   						tempInvoiceList.add(mchInvoice);
		   						poToInvoiceListMap.put(mchCPORecord,tempInvoiceList);
		   					}

						}
				}


			}
	
		}

		
		system.debug(' MCHPO to Invoice Map '+poToInvoiceListMap);
		List<Merge_Contract_PO__c> mchPurOrdList = GsmUtilClass.calculateRemaingFundOnPurchaseOrder(poToInvoiceListMap);
		system.debug('Record after conversion returned '+mchPurOrdList);
		if(mchPurOrdList.size() > 0)
			update mchPurOrdList;


	}

	 
}