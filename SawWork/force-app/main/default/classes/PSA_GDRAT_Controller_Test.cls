/* ========================================================================
    Author: Sharath Prasanna
    Description: This is a test Class for PSA_GDRAT_Controller and PSA_CronGDRATController
    Created Date : 21 December 2016
    ======================================================================== */
@isTest(SeeAllData = false)
public class PSA_GDRAT_Controller_Test {
	

		//As the seeAllData is false, creating the custom settings
		public static PSA_TestUtility testUtil;
		public static pse__Region__c reg1;
		public static pse__Region__c reg2;
		public static pse__Region__c reg3;
		public static pse__Region__c reg4;
		public static pse__Region__c reg5;
		public static pse__Region__c reg6;
		public static Account acct;
		public static Contact resource;
		public static pse__Practice__c pract;
		public static User usr;
		public static pse__proj__c proj;
		public static Territory_Mapping__c terMap;
	    static 
	    {
    	    utilTestClass.createCustomSettings();
            /*PSA_Settings__c psaSetting1 = new PSA_Settings__c();
        	psaSetting1.Name = 'CRM Integration';
        	psaSetting1.Value__c = '00eA0000000QpNL';
	    	insert psaSetting1;*/

	    	createData();
        	 	

	    }    

	    //This method creates the data required for the test methods
	    public static void createData()
	    {

        		testUtil = new PSA_TestUtility();
	    		acct = testUtil.newAccount(true);

        	 	usr = testUtil.newUserSysAdmin(true);        
        		resource = testUtil.newResource(true, acct.Id, usr.Id);
        		pract = testUtil.newPracticeMaster(true);
        		
		    	reg1 = testUtil.newRegionMaster(false);
		    	reg1.Name = 'Corporate';
		    	reg1.Region_Unique_Id__c = 'level1';
		    	insert reg1;

        		proj = testUtil.newProject(false,reg1.id,pract.Id,true,'One-Time: Fixed Price', resource.Id, acct.Id);
        		proj.pse__Allow_Timecards_Without_Assignment__c = false;
        		insert proj;
			    
			    terMap = new Territory_Mapping__c();
		        /*terMap.Name = 'Reg - Terr';
		        terMap.Parent_Division__c = 'Abc_Xyz';
		        terMap.Division__c = 'Reg';
		        terMap.Region__c = 'Area';
		        terMap.Area__c = 'Terr';*/
				terMap.Name = 'Reg - Terr';
		        terMap.TERR_HIER_1__c = 'APJ';
		        terMap.TERR_HIER_2__c = 'Japan';
		        terMap.TERR_HIER_3__c = 'GO-NET';
		        terMap.TERR_HIER_4__c = 'GO-NET';
				terMap.TERR_HIER_5__c = 'GO-NET';
		        insert terMap;       

		        reg2 = testUtil.newRegionMaster(false);
				reg2.Name = 'Xyza (Division)';
				reg2.pse__Parent_Region__c = reg1.Id;
				reg2.pse__Hierarchy_Depth__c = 1;
				reg2.Region_Unique_Id__c = 'level2';
				insert reg2;

		        reg3 = testUtil.newRegionMaster(false);
		        reg3.Name = 'Abcd (Geography)';
		        reg3.pse__Parent_Region__c = reg2.Id;
		        reg3.pse__Hierarchy_Depth__c = 2;
		        reg3.Region_Unique_Id__c = 'level3';
		        insert reg3;


		        reg4 = testUtil.newRegionMaster(false);
		        reg4.Name = 'Reg2 (Region)';
		        reg4.pse__Parent_Region__c = reg3.Id;
		        reg4.pse__Hierarchy_Depth__c = 3;
		        reg4.Region_Unique_Id__c = 'level4';
		        insert reg4;

		        reg5 = testUtil.newRegionMaster(false);
		        reg5.Name = 'Area1 (Area)';
		        reg5.pse__Parent_Region__c = reg4.Id;
		        reg5.pse__Hierarchy_Depth__c = 4;
		        reg5.Region_Unique_Id__c = 'level5';
		        insert reg5;

		        reg6 = testUtil.newRegionMaster(false);
		        reg6.Name = 'Terr1 (Territory)';
		        reg6.pse__Parent_Region__c = reg5.Id;
		        reg6.pse__Hierarchy_Depth__c = 5;
		        reg6.Region_Unique_Id__c = 'level6';
		        insert reg6;

	    }   

	    //This method is for the PSA_CronGDRATController class
	    public static testMethod void testCronGDRATController()
	    {
	    	PSA_CronGDRATController cronGDRATController  = new PSA_CronGDRATController();
	    	Test.startTest();
	    	cronGDRATController.executeGDRATAlignment();
	    	Test.stopTest();
	    }	

	    //This method is for the PSA_GDRAT_Controller class
	    public static testMethod void testGDRATController ()
	    {
	    	PSA_GDRAT_Controller psaGDRATCtrl = new PSA_GDRAT_Controller();
	    	Test.startTest();
	    	psaGDRATCtrl.updateGDRAT();
	    	psaGDRATCtrl.updateOldRegions();
	    	psaGDRATCtrl.deletOldGDRAT();
	    	psaGDRATCtrl.updateRR();
	    	psaGDRATCtrl.updateProjects();
	    	psaGDRATCtrl.save();
	    	Test.stopTest();
	    }
	    
}