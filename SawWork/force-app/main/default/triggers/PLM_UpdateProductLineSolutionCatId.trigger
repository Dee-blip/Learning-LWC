trigger PLM_UpdateProductLineSolutionCatId on ProductLine_SolutionCategory__c (before insert, before update) {
	
	
	List<ProductLine_SolutionCategory__c> productlinesolncatList = new List<ProductLine_SolutionCategory__c>();    
	
	for(ProductLine_SolutionCategory__c row : Trigger.new)            
	{                
		if(Trigger.isInsert && row.CI_Product_Line__c != null && row.CI_Solution_Category__c != null)    
		productlinesolncatList.add(row);
		else if((!Trigger.isInsert && row.CI_Product_Line__c != Trigger.oldMap.get(row.ID).CI_Product_Line__c) || (!Trigger.isInsert && row.CI_Solution_Category__c != Trigger.oldMap.get(row.ID).CI_Solution_Category__c))
		row.addError('Product line id or solution category id cannot be updated after insert');
		             
	}            
	
	if(productlinesolncatList.size() > 0)                
		PLM_CastIronClass.Resolve_ProductLine_SolutionCategory_ForeginKeys(productlinesolncatList);
	
	

}