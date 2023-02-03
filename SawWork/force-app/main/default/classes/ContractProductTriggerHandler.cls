public with sharing class ContractProductTriggerHandler extends ApexTriggerHandlerAbstractClass
{
	public List<Contract_Product__c> contractProductForeignKeyResolveList=null;
	public ContractProductTriggerHandler() 
	{
		
	}

	public override void beforeInsertBeforeUpdateTrigger()
	{
		contractProductForeignKeyResolveList=new List<Contract_Product__c>();
		for(SObject so: newList)
		{
			Contract_Product__c conProd=(Contract_Product__c)so;
			Contract_Product__c conProdOld=null;
			if(!trigger.isInsert)
			conProdOld=(Contract_Product__c)oldMap.get(conProd.Id);	
			if((trigger.isInsert && conProd.CI_Original_Contract_Id__c != null))
		   	{
		   		contractProductForeignKeyResolveList.add(conProd);
		   	}
		   	else if(!trigger.isInsert && conProdOld.CI_Original_Contract_Id__c!=null && conProd.CI_Original_Contract_Id__c != conProdOld.CI_Original_Contract_Id__c)
		   	{
		   		conProd.addError('Original Contract Id can not be updated after insert');
		   	}
		}
		if(contractProductForeignKeyResolveList.size()>0)
		{
			Resolve_ContractProduct_ContractHeaderForeignKeys(contractProductForeignKeyResolveList);
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
	
	public void Resolve_ContractProduct_ContractHeaderForeignKeys(List<Contract_Product__c> contractProductList)
	{
		Set<String> contractAkamIdSet=new Set<String>();
        for(Contract_Product__c con : contractProductList)
        {
            contractAkamIdSet.add(con.CI_Original_Contract_Id__c);
        }
        
        Map<String, Id> contractIdMap=new Map<String,Id>();
        for(Merge_Contract_Header__c contract : [select Id, Name from Merge_Contract_Header__c where Name IN :contractAkamIdSet])
        {
            contractIdMap.put(contract.Name, contract.Id);
        }
        for(Contract_Product__c con : contractProductList)
        { 
            con.Original_Contract_Id__c=contractIdMap.get(con.CI_Original_Contract_Id__c);
            if(con.CI_Original_Contract_Id__c != '' && con.Original_Contract_Id__c == null)
                con.addError('Invalid Contract Id : ' + con.CI_Original_Contract_Id__c);
        }
	}
    
}