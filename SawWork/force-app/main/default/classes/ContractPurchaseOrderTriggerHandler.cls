public class ContractPurchaseOrderTriggerHandler extends ApexTriggerHandlerAbstractClass{
    
    
	public ContractPurchaseOrderTriggerHandler() 
	{

	}
    
    public override void beforeInsertBeforeUpdateTrigger()
	{
		Map<Id,List<Merge_Contract_PO__c>> mchToCPOInsertUpdateMap = new Map<Id,List<Merge_Contract_PO__c>>();
		String accountDefaultCollector = GsmUtilClass.getGSMSettingValue('PurchaseOrderDefaultCollector');

		for(SObject so: newList)
		{
			
			Merge_Contract_PO__c conPurchaseOrder=(Merge_Contract_PO__c)so;
			Merge_Contract_PO__c conPurchaseOrderOld=null;
			if(!trigger.isInsert)
				conPurchaseOrderOld=(Merge_Contract_PO__c)oldMap.get(conPurchaseOrder.Id);	
					 
			if((trigger.isInsert && conPurchaseOrder.PO_Fund__c != null && conPurchaseOrder.Start_Date__c != null && conPurchaseOrder.End_Date__c != null) ||
				(!trigger.isInsert && ((conPurchaseOrder.PO_Fund__c != null  && conPurchaseOrder.PO_Fund__c != conPurchaseOrderOld.PO_Fund__c) || (conPurchaseOrder.Start_Date__c != null && conPurchaseOrder.Start_Date__c != conPurchaseOrderOld.Start_Date__c) || (conPurchaseOrder.End_Date__c != null && conPurchaseOrder.End_Date__c != conPurchaseOrderOld.End_Date__c) )))
		   	{
		   		if(mchToCPOInsertUpdateMap.containsKey(conPurchaseOrder.Original_Contract_Id__c))
		   			mchToCPOInsertUpdateMap.get(conPurchaseOrder.Original_Contract_Id__c).add(conPurchaseOrder);
		   			
		   		else
		   			{
		   				List<Merge_Contract_PO__c> tempCPOList = new List<Merge_Contract_PO__c>();
		   				tempCPOList.add(conPurchaseOrder);
						mchToCPOInsertUpdateMap.put(conPurchaseOrder.Original_Contract_Id__c,tempCPOList);
		   			}
		   	}

		   	
		   	
		   	if(!mchToCPOInsertUpdateMap.isEmpty()){
		   		updateRemainingFundMethod(mchToCPOInsertUpdateMap);
		   	}
		   	
		}
	}

	public override void afterInsertAfterUpdateTrigger()
	{
		System.debug('This is after insert and after update.');
	}

	public override void beforeDeleteBeforeUndeleteTrigger()
	{
		System.debug('This is before delete and before undelete.');
	}

	public override void afterDeleteAfterUndeleteTrigger()
	{
		System.debug('This is after delete and after undelete.');
	}

	public void updateRemainingFundMethod(Map<Id,List<Merge_Contract_PO__c>> mchToCPOListInsertUpdateMap)
	{
	  Map<Merge_Contract_PO__c,List<Invoice__c>> poToInvoiceListMap = new Map<Merge_Contract_PO__c,List<Invoice__c>>();

	  for(Invoice__c mchInvoiceRecord : [Select Id,Original_Amount__c,Original_Contract_Id__c,Invoice_Date__c,CurrencyIsoCode from  Invoice__c Where Original_Contract_Id__c IN :mchToCPOListInsertUpdateMap.KeySet()])
		{
			
			if(mchToCPOListInsertUpdateMap.containsKey(mchInvoiceRecord.Original_Contract_Id__c))
			{
				for(Merge_Contract_PO__c mchPO :mchToCPOListInsertUpdateMap.get(mchInvoiceRecord.Original_Contract_Id__c))
				{
					if(mchInvoiceRecord.Invoice_Date__c >=mchPO.Start_Date__c && mchInvoiceRecord.Invoice_Date__c <= mchPO.End_Date__c)
						{
							if(poToInvoiceListMap.containsKey(mchPO))
		   						poToInvoiceListMap.get(mchPO).add(mchInvoiceRecord);
		   					else
		   					{
		   						List<Invoice__c> tempInvoiceList = new List<Invoice__c>();
		   						tempInvoiceList.add(mchInvoiceRecord);
		   						poToInvoiceListMap.put(mchPO,tempInvoiceList);
		   					}

						}
				}
			}

		}

		List<Merge_Contract_PO__c> mchPurOrdList = GsmUtilClass.calculateRemaingFundOnPurchaseOrder(poToInvoiceListMap);

		
		
	}


	
    
	

}