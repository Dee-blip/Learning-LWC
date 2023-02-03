/******

Author: Sharath Ravishankar
Created Date: 30th May 2017
Description: This class is created to add the new service product to the PSA_Products__c custom settings
            from the CONTRACT_ENGINEERING_PRODUCT_DETAIL__c object.

Jira : FFPSA-167
Developer               Date                Description
Sharath Ravishankar     24th June 2017     FFPSA251 : Rectified the bugs and have made changes for
                                         adding service products to custom metadata asynchronously using future method

*/
public class InsertContractEnggProdRecords {
    
    //filter the list of service products having Services_and_Support::Services_and_Support as their Engg product name
    public void checkForServiceProduct(List<CONTRACT_ENGINEERING_PRODUCT_DETAIL__c> newEngProdList)
    {
        List<Id> serviceConEngProdIdList = new List<Id>();
        for(CONTRACT_ENGINEERING_PRODUCT_DETAIL__c engProdVar : newEngProdList)
        {
            if(engProdVar.ENGINEERING_PRODUCT_NAME__c == 'Services_and_Support::Services_and_Support')
            {
                serviceConEngProdIdList.add(engProdVar.Id);
            }
        }

        if(serviceConEngProdIdList != null && serviceConEngProdIdList.size() != 0 )
        {
            addProductstoPSAProducts(serviceConEngProdIdList);
        }

    }

    //async method to add the internal product name of the service products which are not present in the psa_products custom settings
    @future
    public static void addProductstoPSAProducts(List<Id> serviceConEngProdIdList)
    {
        List<Id> toBeInsertedIdList = new List<Id>();
        Set<String> productNameSet = new Set<String>();
        Integer num = 1;
        List<PSA_Products__c> insertProdList = new List<PSA_Products__c>();
        List<CONTRACT_ENGINEERING_PRODUCT_DETAIL__c> serviceConEngProdList = new List<CONTRACT_ENGINEERING_PRODUCT_DETAIL__c>();
        serviceConEngProdList = [SELECT id,INTERNAL_PRODUCT_NAME__c FROM CONTRACT_ENGINEERING_PRODUCT_DETAIL__c 
                                where Id =: serviceConEngProdIdList];
        

        for(PSA_Products__c prodVar : PSA_Products__c.getall().values())
        {
            productNameSet.add(prodVar.product_name__c);
            num = ((Integer.valueOf(prodVar.name) > num ) ? Integer.valueOf(prodVar.name) : num);
        }
        for(CONTRACT_ENGINEERING_PRODUCT_DETAIL__c engProdVar : serviceConEngProdList)
        {
            if(engProdVar.INTERNAL_PRODUCT_NAME__c != null && !productNameSet.contains(engProdVar.INTERNAL_PRODUCT_NAME__c))  
            {
                PSA_Products__c newProduct = new PSA_Products__c();
                newProduct.product_name__c=engProdVar.INTERNAL_PRODUCT_NAME__c;
                newProduct.name = String.valueOf(++num);
                insertProdList.add(newProduct);
                productNameSet.add(engProdVar.INTERNAL_PRODUCT_NAME__c);
            }
        }
        insert(insertProdList); 
    }
}