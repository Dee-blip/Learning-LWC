/*=====================================================================================================+
    Class name          :   Test_CaseTransitionController 
    Author              :   Himanshu Kar
    Purpose             :   This test class is used to cover code for below Components
                            1. CaseTransitionController
                            
    Last Modified Developer  Purpose            
    ============= =========  =======
    21-MAY-13	Appirio    Initial Developement
    07-AUG-14     Himanshu   Removed See All Data and increased Code Coverage
    3-June-17	Vandhana	Added case product
+=====================================================================================================*/

@isTest
private class Test_CaseTransitionController {

	//Variable for Case
	static case cs;
	
	// For User Record
	public static User newUsr;

	// Method for Creating Test Data
	public static void testDataSetup(){
	
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];       
        System.runAs (thisUser) 
        {
        
		// Call to - createCustomSettings For Case Setup
		utilTestClass.createCustomSettings();
		
		// Creating New User for Case Owner
            newUsr = utilTestClass.CreateUser('strdUsr', 'Worldwide', 'Standard User');
            Insert newUsr;
        }

        Account acc = utilTestClass.CreateAccount('testAccount123');
        insert acc;
	 
        EB_AccountProductMap__c ProdTest = new EB_AccountProductMap__c(); 
        ProdTest.Name = 'Riverbed_Product';
        ProdTest.EB_Account__c = acc.Id;
        ProdTest.EB_Product__c = 'Riverbed_Product';
        insert ProdTest;

		//Creating Case
		Map<String, Schema.RecordTypeInfo> rtMap = Case.sObjectType.getDescribe().getRecordTypeInfosByName();
		
	    cs = new Case();
		cs.RecordTypeId = rtMap.get('Technical').getRecordTypeId();
		cs.Status = 'Unassigned';
		cs.Origin = 'Email';
		cs.ProductPL__c = 'Alta';
        cs.AccountId = acc.Id;
		cs.Case_Product__c = ProdTest.Id;
        
		insert cs;
  
	}
		
    static testMethod void myUnitTest() {
    	
    	 //Call to Data Setup Method
    	  testDataSetup();
    	  
    	  test.startTest();
    	  
		  CaseTransitionController controller = new CaseTransitionController(new ApexPages.StandardController(cs));
	  
		  controller.showEdit();
	  
		  controller.ctEdit.Customer_Expectations__c = 'Test Customer Expectation';
		  controller.ctEdit.Data_Collected__c = 'Test Data Collected';
		  controller.ctEdit.Next_Action_Recommendation__c = 'Test Next Action Recommendation';
		  controller.ctEdit.Troubleshooting_to_Date__c = 'Test Troubleshooting to Date';
		  controller.ctEdit.Reason__c = 'Test Reason';
		  controller.ctEdit.Issue_Summary__c = 'Test Issue Summary';
          	  controller.ctEdit.New_Owner__c = newUsr.Id;
	  
		  controller.saveCase();
	  
		  controller.ctID = controller.ctEdit.Id;
		  
		  controller.assignUser();
		  System.assertEquals(true, controller.showOwnerPrompt);
		  
		  controller.saveCTOwner();
	  
          	  // Covering Code when Old Owner != New Owner
           	  controller.oldOwnerId = UserInfo.getUserId();
        	  controller.saveCTOwner();
        
		  controller.ctID = controller.ctEdit.Id;
		  controller.showDetail();
		  System.assertEquals(controller.ctEdit.Id, controller.ctDetail.Id);
	  
		  controller.showEdit();
		  controller.cancelRequest();
		  controller.isNotEmpty('test');
		  controller.isNotEmpty('');
        
        test.stopTest();
        
    }
}