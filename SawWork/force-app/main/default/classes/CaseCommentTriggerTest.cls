/**
 * Name             : CaseCommentTriggerTest
  Purpose           :   This test class is used to cover code for below Components
                            1. CaseCommentTrigger
                            2. CaseCommentTriggerHandler
                            3. CaseComment_bi_bu
 
  Last Modified Developer  Purpose            
  ============= =========  =======
  17-JUL-13     Appirio    Initial Development 
  05-AUG-14     Himanshu   Removed SeeAllData = True and optimized the class
 */
 
 @isTest
 private class CaseCommentTriggerTest{
 
 	// For Case Record
	public static Case caseRec;
	
	// For User Record
	public static User newUsr;
	
 	// Method for Creating Test Data
	public static void testDataSetup(){
	
		 // ***********Creating Test Data ***************
		 
		 // Call to - createCustomSettings For Case Setup
		 utilTestClass.createCustomSettings();
		
		// For Account Record
            Account accRec = new Account(Name='Test Account',AKAM_Account_ID__c='Test-111-ABC-XYZ');
            insert accRec;
            
            // Creating New User for Case Owner
            newUsr = utilTestClass.CreateUser('strdUsr', 'Worldwide', 'Standard User');
            Insert newUsr;
            
            // Creating Case
            caseRec = utilTestClass.createCase(accRec.Id);
            
      }
      
    static testmethod void testSetRecentUpdateOnCaseTrue(){
        System.runAs(utilTestClass.getTestRunUser())
        {

            // Calling dataSetup Method
            testDataSetup();

            Test.startTest(); 

            // Changing Case Owner
            caseRec.OwnerId = newUsr.Id;
            update caseRec;

            // Creating Case Comment
            CaseComment CaseCommentRec = new CaseComment(ParentId = caseRec.Id);
            insert CaseCommentRec;

            Test.stopTest();
        }
        
    }
 }