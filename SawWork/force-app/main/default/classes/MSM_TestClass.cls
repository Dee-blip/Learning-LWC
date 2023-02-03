@isTest(seeAllData=false) 
public class MSM_TestClass {
	public static User dmlUser = utilTestClass.getTestRunUser();
 @testSetup static void setup() 
 {
     Test.startTest();
     
     List<GSM_Custom_Settings__c> gsmCustomSettings = new List<GSM_Custom_Settings__c>();
     GSM_Custom_Settings__c crmIntSetting = new GSM_Custom_Settings__c();
     crmIntSetting.Name = 'CRM_Integration';
     crmIntSetting.Value__c = '005A0000000NHQc';
     gsmCustomSettings.add(crmIntSetting);
     
     GSM_Custom_Settings__c releaseSetting = new GSM_Custom_Settings__c();
     releaseSetting.Name = 'Release#ReminderOffSet_day:hh:mm';
     releaseSetting.Value__c = '-3:13:30';
     gsmCustomSettings.add(releaseSetting);
     
     
     insert gsmCustomSettings;
     
     Test.stopTest();

 }
	public MSM_TestClass() {	
	}
	static TestMethod void testUtilSubmitRequest() 
	{
		Deployment_Step_Request__c retrievedDsr = new Deployment_Step_Request__c();
		Deployment_Step__c temp = new Deployment_Step__c();
		temp.CR_Number__c = '12345';
		insert temp;
		MSMUtil.submitRequest('new Request','', null, true);
		MSMUtil.submitRequest('new Request','', temp.Id, true);
		retrievedDsr = [SELECT Id, devComments__c, isMailRequired__c FROM Deployment_Step_Request__c WHERE Deployment_Step__r.Id =: temp.Id ORDER BY submissionTime__c DESC LIMIT 1]; 
		System.assertEquals('new Request', retrievedDsr.devComments__c);
		System.assertEquals(true, retrievedDsr.isMailRequired__c);


		Deployment_Step_Request__c dsr = new Deployment_Step_Request__c();
		dsr.Deployment_Step__c = temp.Id;
		MSMUtil.submitRequest('Updated request','', temp.Id, false);
		Deployment_Step_Request__c retrievedDsr2 = new Deployment_Step_Request__c();
		retrievedDsr2 = [SELECT Id, devComments__c, isMailRequired__c FROM Deployment_Step_Request__c WHERE Deployment_Step__r.Id =: temp.Id ORDER BY submissionTime__c DESC LIMIT 1];
		System.assertEquals(retrievedDsr.Id, retrievedDsr2.Id);
		System.assertEquals('Updated request', retrievedDsr2.devComments__c);
		System.assertEquals(false, retrievedDsr2.isMailRequired__c);
	}

	static TestMethod void testUtilGetPrevVals() 
	{
		Deployment_Step__c dp = new Deployment_Step__c();
		dp.CR_Number__c = '123456';
		insert dp;
		String prevVals = MSMUtil.getPrevValues(dp.Id);
		System.assertEquals('[]', prevVals);
 		
 		Deployment_Step_Request__c dsr = new Deployment_Step_Request__c();
		dsr.devComments__c = 'testing Prev Vals';
		dsr.isMailRequired__c = true;
		dsr.Deployment_Step__c = dp.Id;
		insert dsr;
		prevVals = MSMUtil.getPrevValues(dp.Id);
		System.assertNotEquals(null, prevVals);
	}

	static TestMethod void testUtilCheckRelease() 
	{
		Release__c tempRelease = new Release__c();
		tempRelease.Name = 'not-force';
		insert tempRelease;
		Boolean checkReleaseFlag = MSMUtil.checkRelease(tempRelease.Id);
		System.assertEquals(false, checkReleaseFlag);

		Release__c tempRelease2 = new Release__c();
		tempRelease2.Name = 'ese-force 10.1.1';
		tempRelease2.Application__c = 'Salesforce';
		tempRelease2.Release_Date__c = System.today().addDays(7);
		insert tempRelease2;
		checkReleaseFlag = MSMUtil.checkRelease(tempRelease2.Id);
		System.assertEquals(true, checkReleaseFlag);
	}

	static TestMethod void testControllerReloadDSR() 
	{
		MSMController mc = new MSMController();
		mc.isOps = true;
		mc.myRequestsFlag = true;
		mc.reloadDSR();
		mc.myRequestsFlag = false;
		mc.reloadDSR();
		mc.isOps = false;
		mc.myRequestsFlag = true;
		mc.reloadDSR();

	}

	static TestMethod void testControllerReloadDSRCompleted() 
	{
		MSMController mc = new MSMController();

		mc.isOps = true;
		mc.myCompletedRequestsFlag = true;
		mc.reloadDSRCompleted();
		//myRequestsFlag = false
		mc.myCompletedRequestsFlag = false;
		mc.reloadDSRCompleted();

		//isOps = false;
		mc.isOps = false;
		mc.myCompletedRequestsFlag = true;
		mc.reloadDSRCompleted();

	}
	
	/*static TestMethod void testControllerUpdateAssignedDSR() 
	{
		Deployment_Step__c dp = new Deployment_Step__c();
		dp.CR_Number__c = '4567';
		insert dp;
		Deployment_Step_Request__c dsr = new Deployment_Step_Request__c();
		dsr.devComments__c = 'testing Prev Vals';
		dsr.isMailRequired__c = true;
		User u = [SELECT Id FROM User WHERE UserRole.Name = 'System Administrator' AND Profile.Name = 'System Administrator' AND isActive = true LIMIT 1];
		dsr.assignedTo__c = u.Id;
		dsr.requestedBy__c = u.Id;
		dsr.Deployment_Step__c = dp.Id;
		insert dsr;
		Apexpages.currentPage().getParameters().put('id', dsr.Id);
		Apexpages.currentPage().getParameters().put('assignedTo', u.Id);
		Apexpages.currentPage().getParameters().put('passOnComments','Just For Test');
		MSMController mc = new MSMController();
		mc.isOps = false;
		mc.myCompletedRequestsFlag = true;
        mc.myRequestsFlag = false;
		mc.updateAssignedDSR();
	}
	
	static TestMethod void testControllerUpdateStatusDSR() 
	{
		Deployment_Step__c dp = new Deployment_Step__c();
		dp.CR_Number__c = '1324';
		dp.Submit__c = true;
		insert dp;
		Deployment_Step_Request__c dsr = new Deployment_Step_Request__c();
		dsr.devComments__c = 'testing Prev Vals';
		dsr.isMailRequired__c = true;
		User u = [SELECT Id FROM User LIMIT 1];
		dsr.requestedBy__c = u.Id;
		dsr.Deployment_Step__c = dp.Id;
		insert dsr;
		Apexpages.currentPage().getParameters().put('id', dsr.Id);
		Apexpages.currentPage().getParameters().put('reason', 'Test Completed');
		Apexpages.currentPage().getParameters().put('status','Completed');
		MSMController mc = new MSMController();
		
		mc.isOps = false;
		mc.myCompletedRequestsFlag = true;
        mc.myRequestsFlag = false;
		mc.updateStatusDSR();
		
	} */

	static TestMethod void testControllerSetInitialFlags() 
	{
		MSMController mc = new MSMController();
		mc.isOps = true;
		mc.setInitialFlags();
		System.assertEquals(mc.myRequestsFlag, false);
		System.assertEquals(mc.myCompletedRequestsFlag, false);
		mc.isOps = false;
		mc.setInitialFlags();
		System.assertEquals(mc.myRequestsFlag, true);
		System.assertEquals(mc.myCompletedRequestsFlag, true);
	}
	
	static TestMethod void testControllerSetDataByRelease() 
	{
		MSMController mc = new MSMController();
		mc.isOps = false;
		mc.myCompletedRequestsFlag = true;
		mc.setDataByRelease();
		mc.selectedRelease = '000';
		mc.setDataByRelease();
		mc.selectedRelease = null;
		mc.setDataByRelease();
	}
}