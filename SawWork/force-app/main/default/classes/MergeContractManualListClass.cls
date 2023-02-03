/**
MergeContractManualListClass 
    
    @Change History
    Developer :	Ankit  
	CR		  : 2986499
	Date	  :	15/04/2015 
	Change	  :	If CI job upsert is a combination of update and insert,trigger fires only once. Hence removing this flag.
*/
public with sharing class MergeContractManualListClass {
	
	//public static Boolean firstRunFlagManualListActiveCheck=false; CR 2986499
	
	public static void contractManualList_checkForActiveInActive(List<Merge_Contract_Manual_List__c> pTriggerNew)
	{	
		//CR 2986499 flag check commented
		//if (MergeContractManualListClass.firstRunFlagManualListActiveCheck)
		//	return;
			
		
		Map<Id,Merge_Contract_Header__c> mchToUpdateMap = new Map<Id,Merge_Contract_Header__c>();  
		List<Merge_Contract_Header__c> mchToUpdateList = new List<Merge_Contract_Header__c>();
		Set<Id> mchIdSet = new Set<Id>(); 
		
		for(Merge_Contract_Manual_List__c mcml : pTriggerNew)		
		{ 
			mchIdSet.add(mcml.Original_Contract_Id__c); 
		}		
		
		// loop over every contract and every CML within it. Check for a condition. Mark contract.Manual_List__c=true if condition success. 
		for (Merge_Contract_Header__c mch : [Select Id, Name, Manual_List__c, (SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,
			Priority__c,Review_Date__c,Review_Frequency__c,Owner__c,Manual_List_Eval__c,Manual_List_Modify__c from Merge_Contract_Manual_Lists__r Order by End_Date__c DESC) From Merge_Contract_Header__c where Id IN: mchIdSet])
			{
				for (Merge_Contract_Manual_List__c mcml : mch.Merge_Contract_Manual_Lists__r)
				{
					//changed condition. Checks if Manual_List_Eval__c==1 , conditon is IF( ISNULL( End_Date__c ) || ((End_Date__c - TODAY()+20)>0 ), 1, 0)
					if(mcml.Manual_List_Eval__c==1)
								{	
									mchToUpdateMap.put(mch.Id, new Merge_Contract_Header__c(id=mch.Id,Manual_List__c=true));									
									break;									
								}
								else if (!mchToUpdateMap.containsKey(mch.Id)) 
								{									
									mchToUpdateMap.put(mch.Id, new Merge_Contract_Header__c(id=mch.Id,Manual_List__c=false));								
								}
				}	
			}
			
		if (mchToUpdateMap.size()>0)
		{
			mchToUpdateList = mchToUpdateMap.values();
			System.debug('mchToUpdateMap=' + mchToUpdateMap.size());
			System.debug('mchToUpdateList=' + mchToUpdateList);
			update mchToUpdateList;
		}
		//MergeContractManualListClass.firstRunFlagManualListActiveCheck=true;	CR 2986499
	}
	
	// Commented as part of SFDC-2728
	/*	public static String CronJobHandler()
	{
		String res='1:';
		
		try
		{		
		List<Merge_Contract_Manual_List__c> mcmltoupdate = new List<Merge_Contract_Manual_List__c>();
		
		for (Merge_Contract_Manual_List__c mcml : [SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,
			Priority__c,Review_Date__c,Review_Frequency__c,Owner__c,Manual_List_Eval__c,Manual_List_Modify__c from Merge_Contract_Manual_List__c where Manual_List_Modify__c=1 ])
			{
				mcml.Validation_Override__c = true;
				mcmltoupdate.add(mcml);
			}
			
			
			if (mcmltoupdate.size()>0)
			{
				update mcmltoupdate;
			}

	    }
	    catch(Exception e)
	{
	  	res='0:'+ e.getMessage();
    }
   	 	return res;
	    
	    
	} */
}