@isTest(seeAllData = false)
public class PSA_ProtectedClassPublisherTest
{
        //Public static pse__Region__c div;
        Public static pse__Region__c geo;
        Public static pse__Region__c reg;
        Public static pse__Region__c area;
        Public static pse__Region__c zone;
        Public static pse__Region__c terr;
        Public static Id iwRecordTypeId;
        Public static PSA_TestUtility testUtil;
        Public static Account acct;
        Public static User usr;
        Public static User usr2;
        Public static Inv_WorkBox_Region_Mapping__c regMap;
        Public static Protected_Class_Publisher__c protectedClassOld;
        Public static AccountTeamMember AccountTeamMem;
        Public static RAMD_Cost_Center__c ramdCostCenter;
    static{
        testUtil = new PSA_TestUtility();
        iwRecordTypeId = Schema.SObjectType.Inv_WorkBox_Region_Mapping__c.getRecordTypeInfosByName().get('RAMD').getRecordTypeId();        
        //div = testUtil.newRegionMaster(false);
        //div.Name = 'Unknown (Division)';
        //div.psa_Old__c =false;
        //insert div;
        
        geo = testUtil.newRegionMaster(false);
        geo.Name = 'Unknown (Geography)';
        geo.psa_Old__c =false;
        //geo.pse__Parent_Region__c = div.Id;
        insert geo;
        
        reg = testUtil.newRegionMaster(false);
        reg.Name = 'Unknown (Region)';
        reg.psa_Old__c =false;
        reg.pse__Parent_Region__c = geo.Id;
        insert reg;
        
        area = testUtil.newRegionMaster(false);
        area.Name = 'Unknown (Area)';
        area.psa_Old__c =false;
        area.pse__Parent_Region__c = reg.Id;
        insert area;

        zone = testUtil.newRegionMaster(false);
        zone.Name = 'Unknown (Zone)';
        zone.psa_Old__c =false;
        zone.pse__Parent_Region__c = area.Id;
        insert zone;
        
        terr = testUtil.newRegionMaster(false);
        terr.Name = 'Unknown (Territory)';
        terr.psa_Old__c =false;
        terr.pse__Parent_Region__c = zone.Id;
        insert terr;
        createTestData();
    } 
    
    //The function which creates the test data: called from the static block
    Public static void createTestData()
    {
        // if( SC_BOCC_Setup__c.getValues('BOCC') == null)
        // {
        //     SC_BOCC_Setup__c scSetting = new SC_BOCC_Setup__c();
        //     scSetting.Name = 'BOCC';
        //     scSetting.Entitlement_Process_Id_Proactive__c = '5520f000000fxY0AAI';
        //     scSetting.Entitlement_Process_Id_Reactive__c = '5520f000000fxY5AAI';
        //     scSetting.Product_Id__c = 'M-LC-160618';
        //     insert scSetting;
        // }
        //reg = testUtil.newRegionMaster(true);
        testUtil = new PSA_TestUtility();
        acct = testUtil.newAccount(false);
        acct.TERR_HIER_3__c = 'Unknown';
        acct.TERR_HIER_2__c = 'Unknown';
        //acct.Parent_Division__c = 'Unknown_Unknown';
        acct.TERR_HIER_1__c = 'Unknown';
        insert acct;

        usr = testUtil.newUserSysAdmin(false); 
        usr2 = testUtil.newUserSysAdmin(true); 
        usr.ManagerId = usr2.id;
        usr.Title = 'Manager..Service Line';
        usr.Cost_Center__c  = 10609;
        insert usr;

        AccountTeamMem = new AccountTeamMember();
        AccountTeamMem.UserId = usr.id;
        AccountTeamMem.AccountId = acct.Id;
        //AccountTeamMem.Title = 'Account Development Executive';
        insert AccountTeamMem;

        ramdCostCenter = new RAMD_Cost_Center__c();
        ramdCostCenter.Cost_Center__c = '10609';
        insert ramdCostCenter;

        regMap = new Inv_WorkBox_Region_Mapping__c();
        regMap.User__c = usr.Id;
        regMap.RecordTypeId = iwRecordTypeId;
        //regMap.Division__c = div.Id;
        //regMap.TERR_HIER_1__c = geo.Id;
        regMap.TERR_HIER_2__c = reg.Id;
        insert regMap;

        List<Inv_WorkBox_Region_Mapping__c> newL = new List<Inv_WorkBox_Region_Mapping__c>();

       

        protectedClassOld = new Protected_Class_Publisher__c();
        protectedClassOld.Account__c = acct.Id;
        protectedClassOld.User__c = usr.Id;
        //protectedClassOld.Status__c = 'Pending';
        
        
    }

    @isTest
    static void testApprovalController()
    {
        Test.startTest();

        //ProtectedClassPublisherApproval.recordSubmit(protectedClassOld.Id);
        insert protectedClassOld;
        protectedClassOld.Escalated__c = true;
        System.debug('before fist update');
        System.debug('pc b :' + protectedClassOld );
        update protectedClassOld;
        System.debug('after first upsate');

        system.RunAs(usr)
        {
            System.debug('inside run as direct call');
            ProtectedClassPublisherApproval.recordApprove(protectedClassOld.Id);
            System.debug('inside run as second call');
            ProtectedClassPublisherApproval.recordDeny(protectedClassOld.Id);
        }

        Test.stopTest();    
    }
}