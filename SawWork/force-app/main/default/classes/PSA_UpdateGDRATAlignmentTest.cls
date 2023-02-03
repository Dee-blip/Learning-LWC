/*		

 * Test class for PSA_Project_Clone class
 * History:
 * Developer     Date    Description
 * --------------------------------------------------------------------------------------------------
 * Vandhana Krishnamurthy  1/14/2015    Created Class

*/

@isTest(seeAllData=false)
private class PSA_UpdateGDRATAlignmentTest 
{}
/*
	static testMethod void PSA_UpdateGDRATAlignmentTest()
    {
        PSA_TestUtility testUtil = new PSA_TestUtility();
	 	
        pse__Region__c reg1 = testUtil.newRegionMaster(true);
        reg1.Name = 'Corporate';
        update reg1; 

        pse__Region__c testReg = testUtil.newRegionMaster(true);
        testReg.Name = 'Test Region';
        update testReg;
        
        pse__Region__c reg2 = testUtil.newRegionMaster(true);
        reg2.Name = 'Abc (Geography)';
        reg2.pse__Parent_Region__c = reg1.Id;
        update reg2;

        pse__Region__c reg3 = testUtil.newRegionMaster(true);
		reg3.Name = 'Xyz (Division)';
		reg3.pse__Parent_Region__c = reg2.Id;
		update reg3;

        pse__Region__c reg4 = testUtil.newRegionMaster(true);
        reg4.Name = 'Reg (Region)';
        reg4.pse__Parent_Region__c = reg3.Id;
        update reg4;

        pse__Region__c reg5 = testUtil.newRegionMaster(true);
        reg5.Name = 'Terr (Territory)';
        reg5.pse__Parent_Region__c = reg4.Id;
        update reg5;

        Territory_Mapping__c terMap = new Territory_Mapping__c();
        terMap.Name = 'New Territory Mapping';
        terMap.Parent_Division__c = 'Abc_Xyz';
        terMap.Division__c = 'Reg';
        terMap.Region__c = 'Area';
        terMap.Area__c = 'Terr';
        insert terMap;

        Test.startTest();
		PSA_updateGDRATalignment ps = new PSA_updateGDRATalignment();
        ps.updateGDRAT();
        Test.stopTest();    
    }

*/