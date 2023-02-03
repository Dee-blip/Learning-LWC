/******

Author: Sharath Ravishankar
Created Date: 30th May 2017
Description: This test class is created to cover the trigger ContractEngProdTrigger_ai
Jira : FFPSA-167

Modified by Sujay : As part of 19.3 FF merging CustomMeataData for Fall18 Upgrade.
    				This Test Class that covers InsertContractEnggProdRecords class,
					which is currectly inctive as FastMerge MuleProject is on hold.
*/
@isTest(SeeAllData=false)
global class ContractEngProdTrigger_Test {
    
     static{
        PSA_Products__c prods 	= new PSA_Products__c();
        prods.product_name__c 	= 'Services_and_Support::Services_and_Support';
        prods.name 				= '1';
        insert prods;
    }
    
	global Static testmethod void testInsertConEngProd()
    {
    	Test.startTest();
            CONTRACT_ENGINEERING_PRODUCT_DETAIL__c enggProd = new CONTRACT_ENGINEERING_PRODUCT_DETAIL__c();
            enggProd.INTERNAL_PRODUCT_NAME__c 				= 'Services_and_Support::Services_and_Support';
        	enggProd.ENGINEERING_PRODUCT_NAME__c 			= 'Services_and_Support::Services_and_Support';
         	enggProd.CONTRACT_ID__c 						= 'F-JOFMY0';
            enggProd.MARKETING_PRODUCT_ID__c 				= 'M-LC-1311';
            insert enggProd;
        	
        	CONTRACT_ENGINEERING_PRODUCT_DETAIL__c enggProd2 = new CONTRACT_ENGINEERING_PRODUCT_DETAIL__c();
            enggProd2.INTERNAL_PRODUCT_NAME__c 				= 'mPulse';
        	enggProd2.ENGINEERING_PRODUCT_NAME__c 			= 'Services_and_Support::Services_and_Support';
         	enggProd2.CONTRACT_ID__c 						= 'F-JOFMYS';
            enggProd2.MARKETING_PRODUCT_ID__c 				= 'M-LC-1312';
            insert enggProd2;
        	//delete enggProd;
        Test.stopTest();
    }
    
}