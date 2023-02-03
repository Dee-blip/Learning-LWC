/*
 * Lisha Murthy          11/11/2013        CR 2411301 - Need to disable trigger code for Service Cloud
                                            - By-passing the trigger code for connection user.
*/
trigger PLM_UpdateParentProductCategoryID on Product_Category__c (before insert, before update)
{    // Cast Iron Integration : Resolve the Parent ProductCategory Key
    if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
    {
        List<Product_Category__c> productCategoryList = new List<Product_Category__c>();
        for(Product_Category__c row : Trigger.new)            
        {                
        if(row.CI_Parent_Product_Category__c != null){
            if(Trigger.isInsert){
                productCategoryList.add(row);
            }
            else
            {
                if(row.CI_Parent_Product_Category__c != Trigger.oldMap.get(row.Id).CI_Parent_Product_Category__c){
                    productCategoryList.add(row);
                }
            } 
        }    
                    
        }            
        if(productCategoryList.size() > 0)                
        PLM_CastIronClass.Resolve_Parent_Product_Category_ForeginKeys(productCategoryList);
    }
}