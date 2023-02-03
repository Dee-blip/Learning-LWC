/**
 * Name             : IndirectCustomerPopupControllerTest
 * Created By       : Satyanarayan choudhary
 * Created Date     : 15-July-2013
 * Purpose          : evaluate functionalty of IndirectCustomerPopupController. 
 */
@isTest(seeAllData=false)
private class IndirectCustomerPopupControllerTest{

    @testSetup static void setup()
        {
            SCUtilTestClass.createCustomSettingsForCase();
            utilTestClass.createData_SC_SupportEmail();
            
            List<SCUserIdCustomSetting__c> lSCUserIds = new List<SCUserIdCustomSetting__c>();
            SCUserIdCustomSetting__c portalUserId = new SCUserIdCustomSetting__c();
            portalUserId.Name = 'LunaPortalIntegration';
            portalUserId.UserId__c = 'Test1234';
            lSCUserIds.add(portalUserId);
            
            SCUserIdCustomSetting__c psQueueId = new SCUserIdCustomSetting__c();
            psQueueId.Name = 'Primary/SecondaryAssignmentQueue';
            psQueueId.UserId__c = 'Test1234';
            lSCUserIds.add(psQueueId);
            
            SCUserIdCustomSetting__c lunaUserID = new SCUserIdCustomSetting__c();
            lunaUserID.Name = 'LunaCaseMgmtUserID';
            lunaUserID.UserId__c = 'Test1234';
            lSCUserIds.add(lunaUserID);
    
            SCUserIdCustomSetting__c pulsarUserID = new SCUserIdCustomSetting__c();
            pulsarUserID.Name = 'PulsarCaseMgmtUserID';
            pulsarUserID.UserId__c = 'Test1234';
            lSCUserIds.add(pulsarUserID);
    
            SCUserIdCustomSetting__c billingQueueId = new SCUserIdCustomSetting__c();
            billingQueueId.Name = 'Billing Queue';
            billingQueueId.UserId__c = 'Test1234';
            lSCUserIds.add(billingQueueId);
            
            SCUserIdCustomSetting__c scUserIdcs = new SCUserIdCustomSetting__c();
            scUserIdcs.Name = 'NOCC/Network Agent';
            scUserIdcs.UserId__c = Userinfo.getUserId();
            lSCUserIds.add(scUserIdcs);
            
            SCUserIdCustomSetting__c cashApp = new SCUserIdCustomSetting__c();
            cashApp.Name = 'Cash Apps';
            cashApp.UserId__c = Userinfo.getUserId();
            lSCUserIds.add(cashApp);
            //Insert lSCUserIds;
            
        }

    @IsTest
    static void testIndirectCustomerList(){
        // create test data
        //utilTestClass.createCustomSettings();
        //Features_Toggle__c ft = new Features_Toggle__c();
        //ft.Name = 'isContractShareEnabled';
        //ft.Toggle__c = false;
        //insert ft;
        Account acc1 = utilTestClass.createAccount('test1 Acc');  
        insert acc1;    
        Account acc2 = utilTestClass.createAccount('test2 Acc');      
        acc2.type = 'Indirect Customer - Active';
        insert acc2;
        Case sObjCaseTest = utilTestClass.createCase(acc1.Id);
        Merge_Contract_Header__c cont = new Merge_Contract_Header__c(Effective_End_Date__c = Date.Today()
                                            ,Parent_Account_Name__c = acc1.Id
                                            ,Account_Name__c = acc2.Id);
        insert cont;
        
         PageReference pageRef = new PageReference('/apex/IndirectCustomerPopup?Id='+sObjCaseTest.Id+'');
         Test.setCurrentPage(pageRef);
         
         // instantiate controller
         ApexPages.StandardController con = new ApexPages.StandardController(sObjCaseTest);
         IndirectCustomerPopupController controller = new IndirectCustomerPopupController(con);
         
         //PageReference ref1 = controller.dmlOperation();
         //System.assert(controller.contractList.size() > 0,'List size is zero');
         controller.selectIndirectCustomer();
         System.assert(controller.closeWin == true,'Close win false');
         
          
    }
     
}