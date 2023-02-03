@isTest(SeeAllData=false)
public with sharing class PSA_PCLIAssociationHistoryTest {
    Public static pse__Proj__c proj1;
    Public static PSA_TestUtility testUtil;
    Public static pse__Region__c reg;
    Public static pse__Practice__c pract;
    Public static Id practId;
    Public static Contact resource;
    Public static Account acct;
    Public static User usr;
    Public static Merge_Contract_Header__c contract;
    Public static Merge_Contract_Detail__c contDetail;
    Public static Project_Contract__c projCont;
    Public static Project_Contract_Line_Item__c projContItem;
    Public static Project_Contract__c projCont1;
    Public static Project_Contract_Line_Item__c projContItem1;
    public static Id professionalServicesId;

    
    
    static {
        testUtil = new PSA_TestUtility();
        acct = testUtil.newAccount(true);
        reg = testUtil.newRegionMaster(true);
        pract = testUtil.newPracticeMaster(true);
        practId = pract.ID;
        usr = testUtil.newUserSysAdmin(true); 
        resource = testUtil.newResource(true, acct.Id, usr.Id);
        resource.email = 'PSAProjMgr2@akamai.com';
        update resource;

        proj1 = testUtil.newProject(true,reg.id,practId,true,'One-Time: Fixed Price', resource.Id, acct.Id);

        contract = testUtil.newContract(true, acct.Id, '123','456',null,System.today(), System.today().addDays(50));
        contDetail = testUtil.newContractDetail(true, 'test','test',contract.Id, System.today(), System.today().addDays(50));
        projCont = testUtil.newProjectContract(true, proj1.Id, contract.Id, acct.Id);
        projContItem = testUtil.newProjectContractLineItem(true, proj1.Id, contract.Id, contDetail.Id, projCont.Id);
        projContItem.Merge_Contract_Detail_Id__c = contDetail.Id.to15();
        update projContItem;

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
        if (PSA_Settings__c.getInstance('ContractDetailBatch') == null)
        {
            workItemLimit = new PSA_Settings__c();
            workItemLimit.Name = 'ContractDetailBatch';
            workItemLimit.Value__c = '2021-10-08T07:59:35.000+0000';
            psaSettings.add(workItemLimit);
            
        }

        if(!psaSettings.isEmpty())
        {
            insert psaSettings;
        }

    }

    @isTest 
    static void test1()
    {
        
        test.startTest();
        contDetail.Product_Id__c = '1234';
        update contDetail;
        Database.executeBatch(new PSA_PCLIAssociationHistory(), 200);
        delete projContItem;
        test.stopTest();  
    }

    @isTest
    static void test2()
    {
        
        test.startTest();
        contDetail.Product_Id__c = '1234';
        update contDetail;
        Database.executeBatch(new PSA_PCLIAssociationHistory(), 200);
        delete contDetail;
        test.stopTest();  
    }


    @isTest
    static void test3()
    {
        // PSA_Batch_Job_Tracking__c psaJt = new PSA_Batch_Job_Tracking__c();
        // string s = '2021-08-21T11:27:54.14Z';
        // psaJt.Last_Successful_Run__c = Datetime.valueOf(s.replace('T',' ')) ;
        // psaJt.name ='PCLI Association History';
        // insert psaJt;
        test.startTest();

        projCont1 = testUtil.newProjectContract(true, proj1.Id, contract.Id, acct.Id);
        projContItem1 = testUtil.newProjectContractLineItem(true, proj1.Id, contract.Id, contDetail.Id, projCont1.Id);
        
        test.stopTest();  
    }


}