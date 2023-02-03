/**
 * @description       : This class covers the coverage for : PSA_AutoCreateTimeOffProjectYOY 
 * @author            : Sujay
 * date               : October 2021
 * @last modified on  : October 2021
**/

@isTest
public class PSA_AutoCreateTimeOffProjectYOY_Test {
    
        Public static pse__Region__c reg;
        Public static Account acct;
        Public static Contact resource;
        Public static pse__Proj__c proj1;
        Public static pse__Practice__c pract;
        Public static Id practId;
        Public static User usr;
        Public static pse__Permission_Control__c pc;
        Public static PSA_TestUtility testUtil;
        public static Id professionalServicesId;
   
    //Static block to create test data
    static{
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        Test.loadData(globalDescribe.get('GSM_Custom_Settings__c'), 'CS_GSM_Custom_Settings');
        //Map<String, Schema.SObjectType> globalDescribe1 = Schema.getGlobalDescribe();
        //Test.loadData(globalDescribe1.get('Email_to_Case__c'), 'Email_to_Case');  
        professionalServicesId  = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();

        Environment_Setup__c esSetting = new Environment_Setup__c();
        //esSetting.SetupOwnerId = '';
        esSetting.Active_Org__c = true;
        esSetting.Connection_Name__c = 'DR';
        esSetting.ConnectionId__c = '04PG0000000PDf9MAG';
        esSetting.CName_Url__c = 'https://crm.akamai.com/apex/OpenByAKAMid?Id=';
        esSetting.Akam_Id_Start_String__c = 'F-';
        esSetting.Environment_Type__c = 'Primary';
        insert esSetting;

        // SC_BOCC_Setup__c scBOCCSetup = new SC_BOCC_Setup__c();
        // scBOCCSetup.Entitlement_Process_Id_Proactive__c = '5520f000000fxY0AAI';
        // scBOCCSetup.Entitlement_Process_Id_Reactive__c = '5520f000000fxY5AAI';
        // scBOCCSetup.Product_Id__c = 'M-LC-160618';
        // scBOCCSetup.Name = 'BOCC';
        // insert scBOCCSetup;

        PSA_Settings__c validateOnRecallSetting = new PSA_Settings__c();
        validateOnRecallSetting.name = 'Validation On Timecard Recall Active';
        validateOnRecallSetting.Value__c = 'Yes';
        insert validateOnRecallSetting;

        GSM_Custom_Settings__c gsmSetting = new GSM_Custom_Settings__c();
        gsmSetting.Name = 'CastIronClass#AlertHourSetting';
        gsmSetting.Value__c = '1';
        insert gsmSetting;
        GSM_Custom_Settings__c gsmSetting1 = new GSM_Custom_Settings__c();
        gsmSetting1.Name = 'CastIronClass#AlertToAddress';
        gsmSetting1.Value__c = 'vparimi-gmail@noemail-akamai.com';
        insert gsmSetting1;
        GSM_Custom_Settings__c gsmSetting2 = new GSM_Custom_Settings__c();
        gsmSetting2.Name = 'CastIronClass#EmailTemplateName';
        gsmSetting2.Value__c = 'Castiron_Polling_Email_Template';
        insert gsmSetting2;
        GSM_Custom_Settings__c gsmSetting3 = new GSM_Custom_Settings__c();
        gsmSetting3.Name = 'CastIronClass#OrgWideAddressId';
        gsmSetting3.Value__c = '0D2G00000004D7S';
        insert gsmSetting3;
        GSM_Custom_Settings__c gsmSetting4 = new GSM_Custom_Settings__c();
        gsmSetting4.Name = 'CastIronClass#ReplyToAddress';
        gsmSetting4.Value__c = 'eaeblrops-gmail@noemail-akamai.com';
        insert gsmSetting4;

        List<PSA_Settings__c> psaSettings = new List<PSA_Settings__c>();
        PSA_Settings__c workItemLimit;
        if(PSA_Settings__c.getInstance('Work Item Limit') == null)
        {
            workItemLimit = new PSA_Settings__c();
            workItemLimit.Name = 'Work Item Limit';
            workItemLimit.Value__c = '10';
            psaSettings.add(workItemLimit);
            
        }

        if(PSA_Settings__c.getInstance('Engineering Team Email') == null)
        {
            workItemLimit = new PSA_Settings__c();
            workItemLimit.Name = 'Engineering Team Email';
            workItemLimit.Value__c = 'services-engg@akamai.com';
            psaSettings.add(workItemLimit);
            
        }

        if(!psaSettings.isEmpty())
        {
            insert psaSettings;
        }
        PSA_AutoCreateTimeOffProjectYOY_Test.createTestData();
   
    }
    
    //The function which creates the test data: called from the static block
    Public static void createTestData()
    {
        testUtil = new PSA_TestUtility();
        
        reg = testUtil.newRegionMaster(false);
        reg.Name = 'Corporate';
        insert reg;
        
        acct = testUtil.newAccount(false);
        acct.Name = 'Akamai Technologies - Assets';
        insert acct;
        
        pract = testUtil.newPracticeMaster(false);
        pract.name = 'Internal';
        insert pract;
        
        practId = pract.ID;
        
        usr = testUtil.newUserSysAdmin(true); 
        
        resource = testUtil.newResource(false, acct.Id, usr.Id);
        resource.email = 'PSAProjMgr2@akamai.com';
        insert resource;
        
        proj1 = testUtil.newProject(false,reg.id,practId,true,'One-Time: Fixed Price', resource.Id, acct.Id);
        
        proj1.pse__Project_Type__c = 'Internal';
        proj1.Project_Sub_Type__c = 'Time Off';
        proj1.pse__Project_Manager__c = null;
        proj1.pse__Is_Billable__c = false;
        
        insert proj1;
            
        
        pc = testUtil.newPermissionControl(true, usr.Id, reg.Id); 
    }
    
    //This method is used to test the function which sends out mail to TSP.
    public static testMethod void test_method_One()
    {
        test.startTest();
            System.debug(' region :: '+ [select Id,Name from pse__Region__c where Name = 'Corporate' limit 1].Id);
            PSA_AutoCreateTimeOffProjectYOY runBatch = new PSA_AutoCreateTimeOffProjectYOY();
            runBatch.yearEndDate = Date.today().addDays(1);
            Database.executeBatch(runBatch);
        test.stopTest();
    }
    
}