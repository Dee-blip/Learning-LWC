/*
 * Lisha Murthy          11/11/2013        CR 2411301 - Need to disable trigger code for Service Cloud
                                            - By-passing the trigger code for connection user.
*/
trigger PLM_UpdateProductCategoryID on Product__c (before insert, before update)
{    
    // Cast Iron Integration : Resolve the Product Category Key    
    List<Product__c> productList = new List<Product__c>();
    if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
    {
        for(Product__c row : Trigger.new)            
        {                
            if(Trigger.isInsert && row.CI_Product_Category__c != null)    
            productList.add(row); 
            else if(!Trigger.isInsert && row.CI_Product_Category__c != Trigger.oldMap.get(row.ID).CI_Product_Category__c)
            row.addError('Product Category Id cannot be updated after insert.');
                          
        }            
        if(productList.size() > 0)                
        PLM_CastIronClass.Resolve_Product_Category_ForeginKeys(productList);   
    }
}