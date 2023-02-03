/*
CR 2985554 - Need to prevent case worker collision with activities on SOC cases
Created On: 2 October 2015
Created By: ssawhney
Description: Test class for SC_displayCaseTasks
---------------------------------------------------------------------------------------
26-Aug-2018		Vamsee S		Changed Test Class to Seealldata False (ESESP-1624)
*/
@isTest(SeeAllData=false)
private class SC_displayCaseTasks_Test {
	
	@isTest static void TestFilterTasks() {
        
        /*    These users are required to avoid
              "MIXED_DML_OPERATION, DML operation on setup object is not permitted after you have updated a non-setup object" Error
        */
        user sysAdmin2 = utilTestClass.testUserCreation( 'System Administrator', 'TestABC' , 'ABC' ,'TestABC@akamai.com', 'TestABC@akamai.com');
        user sysAdmin3 = utilTestClass.testUserCreation( 'System Administrator', 'TestXYZ' , 'XYZ' ,'TestXYZ@akamai.com', 'TestXYZ@akamai.com');
    
        system.runAs(sysAdmin2){
            	utilTestClass.createCustomSettings();
        }
        system.runAs(sysAdmin3){
            Account acc = utilTestClass.CreateAccount('test displayCaseTasks');
            insert acc;
    
            Case objCase = utilTestClass.createcase(acc.id);
            
            List<Task> lstTsk = new List<Task>();
            Task tsk1 =  utilTestClass.CreateTask(Userinfo.getUserId(), 'Customer Meeting', 'In Progress', 'Meeting', objCase.Id);
            lstTsk.add(tsk1);
    
            Task tsk2 =  utilTestClass.CreateTask(Userinfo.getUserId(), 'Call', 'Not Started', 'Call', objCase.Id);
            lstTsk.add(tsk2);
            insert lstTsk; 
    
            PageReference newPage = Page.SC_displayCaseTasks;
            Test.setCurrentPageReference(newPage);
            newPage.getParameters().put('Id', objCase.Id);
    
            ApexPages.StandardController sc = new ApexPages.StandardController(objCase);
            SC_displayCaseTasks displayTasks = new SC_displayCaseTasks(sc);
            displayTasks.FilterTasks();
            system.assertEquals(displayTasks.lstFilteredList.size(), 2);
    
            displayTasks.filter = 'In Progress';
            displayTasks.FilterTasks();
            system.assertEquals(displayTasks.lstFilteredList.size(), 1);
    
            displayTasks.caseId = null;
            displayTasks.FilterTasks();
            system.assertEquals(displayTasks.lstFilteredList.size(), 0);
        }
    }	
}