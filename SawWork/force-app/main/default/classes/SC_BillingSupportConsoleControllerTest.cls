/*=====================================================================================================+

|  HISTORY  |                                                                            

|  DATE           DEVELOPER         CR          DESCRIPTION                                                       

|  ===========    =========         =======     =========== 
                                                       
|  9-Nov-2015    Deepak Saxena     2596476     Test Class for Controller Class for SC_BillingSupportConsoleController
   29-Oct-2020    Tejaswini        ESESP-4019     Changed to seeAllData=False and added testSetup method
+=====================================================================================================*/
@isTest(seeAllData=False)
public class SC_BillingSupportConsoleControllerTest
{
    @testSetup static void setup() {
        utilTestClass.createCustomSettings(); 
    }
    
    @isTest static void testBillingSupportConsoleController(){
	
    //private testmethod static void testBillingSupportConsoleController(){
        
        List<Case> caseList = new List<Case>();
        List<External_Dependency__c> extDepList = new List<External_Dependency__c>();

        List<group> BillingSupportQueue = [SELECT id, name FROM GROUP WHERE type = 'queue' AND name = 'Billing Queue'];
        List<SC_Billing_Support_Home_Console_Limits__c> customsettingList = new List<SC_Billing_Support_Home_Console_Limits__c>();
        if(SC_Billing_Support_Home_Console_Limits__c.getValues('External Dependency Section 3') == null){
            customsettingList.add(new SC_Billing_Support_Home_Console_Limits__c(Name='External Dependency Section 3', Limit__c = 100));
        
        }
        
        if(SC_Billing_Support_Home_Console_Limits__c.getValues('Billing Support Queue Section 5') == null){
            customsettingList.add(new SC_Billing_Support_Home_Console_Limits__c(Name='Billing Support Queue Section 5', Limit__c = 100));
        
        }
        
        if(SC_Billing_Support_Home_Console_Limits__c.getValues('My Cases Section 4') == null){
            customsettingList.add(new SC_Billing_Support_Home_Console_Limits__c(Name='My Cases Section 4', Limit__c = 100));
        
        }
        
        if(customsettingList.size()>0)
            insert customsettingList;
        
        Id recTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Billing').getRecordTypeId();

        for(Integer i=0;i<20;i++)
        {
            Case c = new Case();
            c.RecordTypeId = recTypeId;
            c.Subject = 'Test Subject';
            c.Description = 'Test Description';
            c.Status = 'Unassigned';
            c.Service__c = 'Billing Information Change';
            c.origin = 'Others';
           
            if(i<=15)
            {
                if (BillingSupportQueue != null && BillingSupportQueue.size() > 0 )
                {
                    c.OwnerId = BillingSupportQueue[0].Id;
                }
            }
            else 
            {
                c.OwnerId = UserInfo.getUserId();
            } 

            caseList.add(c);
        }
    
        Test.startTest();
        
        insert caseList;

        for(Case c : [Select Id from Case where OwnerId = :UserInfo.getUserId() and isClosed = false AND RecordTypeId = :recTypeId])
        {
            External_Dependency__c extDep = new External_Dependency__c(Case__c = c.Id);
            extDepList.add(extDep);
        }
		
        insert extDepList;
               
        SC_BillingSupportConsoleController sc = new SC_BillingSupportConsoleController();
        sc.passRecId = caseList[0].Id;
        
        //Changes by Tejaswini to Increase the Code coverage
        sc.DashboardFilter='This Quarter';
        sc.updateDashboard();
        sc.DashboardFilter='Test values';
        sc.updateDashboard();
        sc.DashboardFilter2='This Quarter';
        sc.updateDashboard2();
        sc.DashboardFilter2='Test values';
        sc.updateDashboard2();
        sc.passMyRecId='Test values';
        sc.MyFilter='Test values';
		sc.sumLOE=new List<String>(); 
        
        Account accRec = new Account(Name='Test Account1 zpxtx',AKAM_Account_ID__c='Test-111');
        insert accRec;
        Contact conRec = new Contact(AccountId = accRec.Id, Login__c = 'Test_xyz', Email = 'Test_xyz@akamai.com',
                           No_Longer_with_Company__c = false, LastName = 'Test Contact');
        insert conRec;
        Case c = new Case();
        c.RecordTypeId = recTypeId;
        c.Subject = 'Test Subject1';
        c.Description = 'Test Description1';
        c.Status = 'Unassigned';
        c.Service__c = 'Billing Information Change';
        c.origin = 'Others';
        c.AccountId=accRec.Id;
        c.ContactId=conRec.Id;
        insert c;
        Map<Id,CaseMilestone> mQCaseMile = new Map<Id,CaseMilestone>();
        Map<Id,CaseMilestone> mapCaseResMile=new Map<Id,CaseMilestone>();
        Case c1=[Select Id,AKAM_Case_ID__c, AccountId,Account.Name,Subject,Contact.Name,CreatedDate,Status,Origin,Recent_Update__c,Task_LOE__c from Case where OwnerId = :UserInfo.getUserId() and isClosed = false AND RecordTypeId = :recTypeId Limit 1];
        SC_BillingSupportConsoleController.CaseERWrapperClass cWrap = new SC_BillingSupportConsoleController.CaseERWrapperClass(c1, mQCaseMile, mapCaseResMile, 'Test', 'Test');
        cWrap.qicon='Test values'; 
        cWrap.qSLA='Test values';
        Long tm= 111440;
        String f1=cWrap.minsToDay(tm);
        String f2=cWrap.minsToHrs(tm);
        //sc.CaseERWrapperClass cWrap;
        //cWrap.qicon='Test values';
        //cWrap.qSLA='Test values';
        
        sc.pickCaseER();
        sc.populateExternalDependencyTable();
        sc.populateMyTable();
        sc.populateQTable();
        sc.suppressCaseUpdate();  
        
        Test.stopTest();
    }
    
    
}