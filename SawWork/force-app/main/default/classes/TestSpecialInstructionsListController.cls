/*=====================================================================================================+
    Class name          :   TestSpecialInstructionsListController 
    Author              :   Himanshu Kar
    Purpose             :   This test class is used to cover code for below Components
                            1. SpecialInstructionsListController
                            
    Last Modified Developer  Purpose            
    ============= =========  =======
    07-JUN-13   Appirio    Initial Developement
    23-APR-14   Akhila     Optimization of test class
    28-JUL-14   Himanshu   Removed See All Data and increased Code Coverage
    23-June-17  Vandhana    Added changes as part of ESESP-514
+=====================================================================================================*/

@isTest
private class TestSpecialInstructionsListController {

    // Variable for Case
    static case testCase;
    
    // Method for Creating Test Data
    public static void testDataSetup(){
    
         // Call to - createCustomSettings For Case Setup
         utilTestClass.createCustomSettings();
        
        // Create custom setting
        SC_SOC_SpecInstr__c cs = new SC_SOC_SpecInstr__c();
        cs.Name = 'Exclude Record Type';
        cs.Record_Type_Name__c = 'Managed Security';
        insert cs;
         
        //Create Account
            Account testAcc = new Account();
            testAcc.name ='Test Vinod11';
            testAcc.Website = 'test@test.com';
            insert testAcc;
            
            //Create Case
            testCase = new Case();
            testCase.AccountId = testAcc.Id;
            testCase.Subject = '__ Test Subject';
            testCase.Recent_Update__c = true;
            testCase.origin = 'Others';
            insert testCase;
            
            // Create Special Instruction Template
            Special_Instruction_Template__c spInstrTemp = new Special_Instruction_Template__c();
            spInstrTemp.Title__c  = 'SI Template 1';
            spInstrTemp.Show_for_Record_Types__c = 'All except Managed Security';
            spInstrTemp.Flag_Icon__c = 'Globe';
            insert spInstrTemp;
        
            //Create list of Instructions
            list<Special_Instructions__c> lstInstructions = new list<Special_Instructions__c>();
            Date stratdate = date.today().addDays(-2);
            for(integer i=0; i<2;i++){
                Special_Instructions__c newInstruction = new Special_Instructions__c();
                newInstruction.Account__c = testAcc.ID;
                newInstruction.Start_Date__c = stratdate;
                newInstruction.Instructions__c = 'Test';
                if(Math.mod(i, 2) == 0) 
                    newInstruction.Special_Instruction_Template__c = spInstrTemp.Id;
                newInstruction.Show_for_Record_Types__c = 'All except Managed Security';
                lstInstructions.add(newInstruction);
            }
            insert lstInstructions;
    
    }
    
        static testMethod void myUnitTest() { 
    
            // Calling Data Setup Method
            testDataSetup();
        
            test.startTest();
        
                PageReference pRef = Page.Special_Instructions;        
                Test.setCurrentPage(pRef);        
                apexpages.currentpage().getparameters().put('id',testCase.id);
                ApexPages.StandardController stdCon = new ApexPages.StandardController(testCase);       
                SpecialInstructionsListController controller = new SpecialInstructionsListController(stdCon);
                controller.setRecentUpdateOnCaseTrue();
                
            test.stopTest(); 
    }
}