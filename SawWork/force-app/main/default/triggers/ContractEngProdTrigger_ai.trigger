/******

Author: Sharath Ravishankar
Created Date: 30th May 2017
Description: This trigger is created to add the new service product to the PSA_Products__c custom settings
            from the CONTRACT_ENGINEERING_PRODUCT_DETAIL__c object.

Jira : FFPSA-167

Developer               Date                Description
Sharath Ravishankar     24th June 2017     FFPSA251 : Changes are made in the trigger for the modified method name
                                           and for running testclass independednt of the custom metadata value.
Sujay                   28th November 18    19.3 : Merging Custom metadata for FALL18.
                                                

*/
trigger ContractEngProdTrigger_ai on CONTRACT_ENGINEERING_PRODUCT_DETAIL__c (after insert) 
{
    if (Trigger.isAfter && Trigger.isInsert)
    {
        //for (Contract_Engg_Trigger__mdt settingVar : [SELECT QualifiedApiName,value__c FROM Contract_Engg_Trigger__mdt] )
        //Chnages by Sujay for 19.3
        for (PSA_Common_Setting__mdt settingVar : [SELECT Name__c, LOE_High_Limit__c FROM PSA_Common_Setting__mdt WHERE Type__c = 'Contract_Engg_Trigger__mdt'] )
        {
            if((settingVar.Name__c == 'ActivateTrigger' && settingVar.LOE_High_Limit__c == 1) || system.Test.isRunningTest() )
            {
                InsertContractEnggProdRecords ins = new InsertContractEnggProdRecords();
                ins.checkForServiceProduct(Trigger.new);
            }

        }
        
        
    }

    
}