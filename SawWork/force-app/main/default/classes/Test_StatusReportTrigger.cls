/*=====================================================================================================+
    Class name          :   Test_StatusReportTrigger 
    Purpose             :   This test class is used to cover code for below Components
                            1. StatusReportTrigger
                            
    Last Modified Developer  Purpose            
    ============= =========  =======
    13-JUL-13     Appirio    Initial Development 
	22-Apr-14	  Akhila	 Optimization of the test class
    05-AUG-14     Himanshu   Removed SeeAllData and Optimized the Class
    
+=====================================================================================================*/
 
@isTest
private class Test_StatusReportTrigger {

    static testMethod void myUnitTest() {
       
        Test.startTest(); 
        	
        	// Call to - createCustomSettings For Case Setup
			utilTestClass.createCustomSettings();
        
        	//Creation of Case
        	Case cs = new Case(Status = 'Unassigned', Origin = 'Email', ProductPL__c = 'Alta');
        	insert cs;
                
        	//Creation of Status Report 
        	Status_Report__c sr = new Status_Report__c(Case__c = cs.Id, Status_Report_Sent__c = Date.today());
        	insert sr;
        Test.stopTest();
       
    }
}