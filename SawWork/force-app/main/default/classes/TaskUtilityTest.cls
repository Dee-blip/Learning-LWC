/*=====================================================================================================+
    Class name          :   Test_CaseTransitionController 
    Author              :   Himanshu Kar
    Purpose             :   This test class is used to cover code for below Components
                            1. CaseTransitionController
                            
    Last Modified Developer  Purpose            
    ============= =========  =======
    21-MAY-13	Appirio    Initial Developement
    07-AUG-14     Himanshu   Removed See All Data and increased Code Coverage
    
+=====================================================================================================*/

@isTest
private class TaskUtilityTest {

	//Variable for Account
	static Account acc;

	// Method for Creating Test Data
	public static void testDataSetup(){
	
		// Call to - createCustomSettings For Case Setup
		utilTestClass.createCustomSettings();
		
		//Create Account
		acc = EB_InitializeObjects.createAccount('TestAccount_01_task'); 
        	Database.insert(acc); 
		
	}	

    static testMethod void createTaskTest() {
    	  
    	  //Calling Testdata Method
        testDataSetup();
        
        test.startTest();
        
		  // Task Creation
		  Task task = TaskUtility.createTask(acc.Id,UserInfo.getUserId(), 'Test subject');
		  
		  //For creation queue Task
		  TaskUtility tasks = new TaskUtility();
        	  tasks.queue(acc.Id,UserInfo.getUserId(), 'Test subject');
        	  tasks.queue(acc.Id,null, 'Test subject');
        	  tasks.queue(acc.Id,null, 'Test subject');
        
              List<Task> taskList = tasks.insertQueue();
              
              // Calling getTaskList Method
              TaskUtility tu = new TaskUtility();
              taskList = tu.getTaskList();
		  
        test.stopTest();
    }
    
    
}