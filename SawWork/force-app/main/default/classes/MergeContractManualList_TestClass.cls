/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest(SeeAllData=false)
private class MergeContractManualList_TestClass {
    static
    {
      System.runAs(utilTestClass.getTestRunUser())
      {
        utilTestClass.insertCustomSettings();
      }
    }

private static Merge_Contract_Manual_List__c CreateContractMList (String pMListId, String pCI_OriginalContractId)
	{
		Merge_Contract_Manual_List__c newMList = new Merge_Contract_Manual_List__c();
		newMList.CI_Original_Contract_Id__c = pCI_OriginalContractId;
		newMList.Manual_List_Id__c = pMListId;
		return newMList;
	}
	
	
private static List<Merge_Contract_Header__c> refreshContractHeaderList(List<Merge_Contract_Header__c> contractList)
	{
		return [select Id,Account_Name__c,Bill_To_Contact__C,Contract_transferred_To__c,Opportunity_Name__c
    	                      ,Parent_Account_Name__c,Parent_Contract__C,Referred_By_Account__C, Manual_list__c From Merge_Contract_Header__c where id IN :contractList];
	}

	private static Merge_Contract_Header__c refreshContractHeader(Merge_Contract_Header__c contract)
	{
		return refreshContractHeaderList(new List<Merge_Contract_Header__c> {contract})[0];
	}
	
	

   
   
    static testMethod void Merge_Contract_Header_Manual_listCheck_Positive() 
     {
         System.runAs(utilTestClass.getTestRunUser())
         {
             Account acc = utilTestClass.CreateAccount('testuac');
             acc.AKAM_Account_ID__c='F-AC-Test';
             insert acc;


             Merge_Contract_Header__c parentContract=utilTestClass.CreateContractHeader('Test Contract',acc.Id);
             insert parentContract;

             //MCML insert
             Merge_Contract_Manual_List__c mlist = CreateContractMList('#Test-FC-MCML1', 'Test Contract');
             mlist.Original_Contract_Id__c=parentContract.Id;
             mlist.Priority__c='1';		
             mlist.End_Date__c=Date.today();
             insert mlist;

             // Refresh		
             parentContract=refreshContractHeader(parentContract);

             // Assert
             system.assertEquals(parentContract.Manual_List__c,true);
         }
	     	
     }
     
     
    
          static testMethod void Merge_Contract_Header_Manual_listBulk_Positive() 
     {
         System.runAs(utilTestClass.getTestRunUser())
         {
             Account acc = utilTestClass.CreateAccount('tespac');
             acc.AKAM_Account_ID__c='F-AC-Test';
             insert acc;     	

             Merge_Contract_Header__c parentContract=utilTestClass.CreateContractHeader('Test Contract',acc.Id);
             insert parentContract;

             //MCML insert-positive case
             Merge_Contract_Manual_List__c m2list = CreateContractMList('#Test-FC-MCML2', 'Test Contract');
             m2list.Original_Contract_Id__c=parentContract.Id;
             m2list.End_Date__c=Date.today();
             insert m2list;

             //MCML insert-Negative case
             Merge_Contract_Manual_List__c mlist = CreateContractMList('#Test-FC-MCML1', 'Test Contract');

             mlist.End_Date__c=Date.Today().toStartOfMonth().addMonths(-10);
             insert mlist;


             // Refresh		
             parentContract=refreshContractHeader(parentContract);

             // Assert
             system.assertEquals(parentContract.Manual_List__c,true);
         }
	     	
     }   
     
    
     static testMethod void Merge_Contract_Header_Manual_listCheck_Negative() 
     {
         System.runAs(utilTestClass.getTestRunUser())
         {
             Account acc = utilTestClass.CreateAccount('testqac');
             acc.AKAM_Account_ID__c='F-AC-Test';
             insert acc;


             Merge_Contract_Header__c parentContract=utilTestClass.CreateContractHeader('Test Contract',acc.Id);
             insert parentContract;

             Merge_Contract_Manual_List__c mlist = CreateContractMList('#Test-FC-MCML1', 'Test Contract');
             mlist.Original_Contract_Id__c=parentContract.Id;
             mlist.Review_Frequency__c='abcd';
             mlist.End_Date__c=Date.Today().toStartOfMonth().addMonths(-10);
             insert mlist;

             // Refresh		
             parentContract=refreshContractHeader(parentContract);

             // Assert
             system.assertEquals(parentContract.Manual_List__c,false);
         }
	     	
     }
     
     /*CR 2808039 - Addition of new method to increase code coverage of MergeContractManualListClass*/
     // Commented as part of SFDC-2728
    /* static testMethod void testCronJobHandler(){
         System.runAs(utilTestClass.getTestRunUser())
         {
             ManagedPkgErrorClass.isFromManagedPackage=false;
             Account acc = utilTestClass.CreateAccount('testuac');
             acc.AKAM_Account_ID__c='F-AC-Test';
             Test.startTest();
             insert acc;


             Merge_Contract_Header__c parentContract=utilTestClass.CreateContractHeader('Test Contract',acc.Id);
             parentContract.Manual_List__c=false;
             insert parentContract;

             parentContract = [select id, Manual_List__c from Merge_Contract_Header__c where id=:parentContract.Id];
             System.assertEquals(parentContract.Manual_List__c, false);

             //MCML insert
             Merge_Contract_Manual_List__c mlist = CreateContractMList('#Test-FC-MCML1', 'Test Contract');
             mlist.Original_Contract_Id__c=parentContract.Id;
             mlist.Priority__c='1';
             mlist.End_Date__c=Date.today()-30;
             Test.stopTest();
             insert mlist;

             mlist = [select id, Manual_List_Eval__c, Manual_List_Modify__c from Merge_Contract_Manual_List__c where id=:mlist.Id];
             System.assertEquals(mlist.Manual_List_Eval__c, 0.0);


             MergeContractManualListClass.CronJobHandler();
         }
     } */
}