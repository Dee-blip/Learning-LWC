/*=====================================================================================================+
Class name          :   SC_OrderApprovals_LightningCtrlTest
Author              :   Vikas
Created             :   08-Jul-19
Purpose             :   This class is a test class for SC_OrderApprovals_LightningCtrl

Last Modified   Developer   Purpose            
=============   =========   ============ 

+=====================================================================================================*/
@isTest(seeAllData=false)
public class SC_OrderApprovals_LightningCtrlTest {
    static User dmlUser = new User(id=UserInfo.getUserId()); 
    public static testmethod void fetchDetailsTest()
    {
        List<String> ADIdList = new List<String>();
        utilTestClass.createCustomSettings();
        utilTestClass.createData_SC_SupportEmail();
        
        // Create Account
        Account thisAccount = utilTestClass.CreateAccount('Test Account for OA');           
        insert thisAccount;
        
        //Create Contact
        Contact thisContact = utilTestClass.CreateContact('firstName','lastName');
        thisContact.AccountId = thisAccount.id;
        thisContact.Akam_Contact_Id__c = 'F-CO-2435149';
        insert thisContact;
        
        //Create Opportunity
        Opportunity opp = utilTestClass.CreateOpportunity('Test Opportuniry for OA','1. Identify Need');
        opp.AccountId = thisAccount.Id;
        opp.CloseDate = Date.today().addMonths(4);
        opp.Validation_Override__c = true;
        insert opp;
        
        System.runAs(dmlUser){
            Order_Approval__c thisOA = new Order_Approval__c();
            thisOA.Associated_Opportunity__c = opp.id;
            thisOA.Validation_Override__c = true;
            insert thisOA;
            
            Case thisCase = new Case();
            thisCase.Description = 'testPS1';
            thisCase.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Order Approval-Deal Desk').getRecordTypeId();
            thisCase.Subject = 'testS2ET1';
            thisCase.Service__c = 'Managed Integration';
            thisCase.Validation_Override__c = true;
            thisCase.AccountId = thisAccount.Id;
            thisCase.Opportunity__c = opp.Id;
            thisCase.Order_Approval__c = thisOA.id;
            thisCase.AutoClose__c = true;
            insert thisCase;
            
            Approval_Details__c thisAD = new Approval_Details__c();
            thisAD.Related_To__c = thisCase.id;
            thisAD.Validation_Override__c = true;
            thisAD.Approver_Notes__c = 'Test';
            insert thisAD;
            
            Approval_Details__c updateAD = [Select Approval_Status__c from Approval_Details__c where id =: thisAD.id];    
            updateAD.Approval_Status__c = 'Rejected';
            update updateAD;
            
            ADIdList.add(String.valueOf(thisAD.id));
            test.startTest();
            SC_OrderApprovals_LightningCtrl.fetchCaseDetails(String.valueOf(thisCase.id));
            SC_OrderApprovals_LightningCtrl.fetchADRecTypeId('Deal Desk Approval Details');
            SC_OrderApprovals_LightningCtrl.fetchParentCaseId(String.valueOf(thisAD.id));
            SC_OrderApprovals_LightningCtrl.fetchAccountDetails(String.valueOf(thisAccount.id));
            SC_OrderApprovals_LightningCtrl.fetchApprovalDetails(String.valueOf(thisCase.id));
            SC_OrderApprovals_LightningCtrl.fetchOADetails(String.valueOf(thisOA.id));
            SC_OrderApprovals_LightningCtrl.fetchCaseApprovalDetails(String.valueOf(thisCase.id));
            SC_OrderApprovals_LightningCtrl.updateRecords(ADIdList,'Approved');
            SC_OrderApprovals_LightningCtrl.createOACase(String.valueOf(thisOA.id),String.valueOf(Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Order Approval-Deal Desk').getRecordTypeId()),'True');
            SC_OrderApprovals_LightningCtrl.fetchApprovalDetailRecord(String.valueOf(thisAD.id),'Approval_Request__c');
            SC_OrderApprovals_LightningCtrl.areAnyRelatedOACasesPending(String.valueOf(thisCase.id));
        	
        }
        SC_OrderApprovals_LightningCtrl.fetchOARecordTypes();
        SC_OrderApprovals_LightningCtrl.getOARecordTypes();
        SC_OrderApprovals_LightningCtrl.checkEscalationAccess();
        SC_OrderApprovals_LightningCtrl.getIconName('Approval_Details__c');
        SC_OrderApprovals_LightningCtrl.fetchStatusList();
        SC_OrderApprovals_LightningCtrl.fetchDependentPLValues();
        SC_OrderApprovals_LightningCtrl.fetchControllingPLValues();
        SC_OrderApprovals_LightningCtrl.fetchRecTypeId('Order Approval-Legal');
        SC_OrderApprovals_LightningCtrl.returnLayoutSectionFields();
        test.stopTest();
    }
    
    public static testmethod void closeCaseTest()
    {
        User DDUser = [select id from user where profile.name =: 'Deal Desk' and isActive =: true limit 1];
        
        List<String> appIdList = new List<String>();
        utilTestClass.createCustomSettings();
        utilTestClass.createData_SC_SupportEmail();
        
        // Create Account
        Account thisAccount = utilTestClass.CreateAccount('Test Account for OA');           
        insert thisAccount;
        
        Contact thisContact = utilTestClass.CreateContact('firstName','lastName');
        thisContact.AccountId = thisAccount.id;
        thisContact.Akam_Contact_Id__c = 'F-CO-2435149';
        insert thisContact;
        
        Opportunity opp = utilTestClass.CreateOpportunity('Test Opportuniry for OA','1. Identify Need');
        opp.AccountId = thisAccount.Id;
        opp.CloseDate = Date.today().addMonths(4);
        opp.Validation_Override__c = true;
        insert opp;

        System.runAs(DDUser){
            Order_Approval__c thisOA = new Order_Approval__c();
            thisOA.Associated_Opportunity__c = opp.id;
            thisOA.Validation_Override__c = true;
            insert thisOA;
            
            Case thisCase = new Case();
            thisCase.Description = 'testPS1';
            thisCase.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Order Approval-Deal Desk').getRecordTypeId();
            thisCase.Subject = 'testS2ET1';
            thisCase.Service__c = 'Managed Integration';
            thisCase.Validation_Override__c = true;
            thisCase.AccountId = thisAccount.Id;
            thisCase.Opportunity__c = opp.Id;
            thisCase.Order_Approval__c = thisOA.id;
            insert thisCase;
            
            thisCase = [select id,ownerid from case where id =: thisCase.id limit 1];
            thisCase.ownerid = DDUser.id;
            update thisCase;
            
            test.startTest();
            SC_OrderApprovals_LightningCtrl.closeCase(String.valueOf(thisCase.id),'Closed-Approved');     
            SC_OrderApprovals_LightningCtrl.reopenCase(thisCase,'Test'); 
            
            SC_OrderApprovals_LightningCtrl.pickilstReopenReasonCode();
            test.stopTest();
            
        }
    }
    
    public static testmethod void ADTriggerTest()
    {
        User DDUser = [select id from user where profile.name =: 'Deal Desk' and isActive =: true limit 1];
        
        List<String> appIdList = new List<String>();
        utilTestClass.createCustomSettings();
        utilTestClass.createData_SC_SupportEmail();
        
        // Create Account
        Account thisAccount = utilTestClass.CreateAccount('Test Account for OA');           
        insert thisAccount;
        
        Contact thisContact = utilTestClass.CreateContact('firstName','lastName');
        thisContact.AccountId = thisAccount.id;
        thisContact.Akam_Contact_Id__c = 'F-CO-2435149';
        insert thisContact;
        
        Opportunity opp = utilTestClass.CreateOpportunity('Test Opportuniry for OA','1. Identify Need');
        opp.AccountId = thisAccount.Id;
        opp.CloseDate = Date.today().addMonths(4);
        opp.Validation_Override__c = true;
        insert opp;

        System.runAs(DDUser){
            Order_Approval__c thisOA = new Order_Approval__c();
            thisOA.Associated_Opportunity__c = opp.id;
            thisOA.Validation_Override__c = true;
            insert thisOA;
            
            //Test method fo Approval Detail Trigger
            Case thisOthersCase = new Case();
            thisOthersCase.Description = 'testPS1';
            thisOthersCase.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Order Approval-Others').getRecordTypeId();
            thisOthersCase.Subject = 'testS2ET1';
            thisOthersCase.Service__c = 'Managed Integration';
            thisOthersCase.Validation_Override__c = true;
            thisOthersCase.AccountId = thisAccount.Id;
            thisOthersCase.Opportunity__c = opp.Id;
            thisOthersCase.Order_Approval__c = thisOA.id;
            thisOthersCase.AutoClose__c = true;
            thisOthersCase.Approver__c = UserInfo.getUserId();
            insert thisOthersCase;
            
            Approval_Details__c thisOthersAD = new Approval_Details__c();
            thisOthersAD.Related_To__c = thisOthersCase.id;
            thisOthersAD.Validation_Override__c = true;
            thisOthersAD.Approver_Notes__c = 'Test';
            test.startTest();
            insert thisOthersAD;
            test.stopTest();
        }
    }
}