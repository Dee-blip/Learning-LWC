/*
************************************************************************************************************
Author              :   Vikas R
Created             :   19-April-2022
Purpose             :   Test Class for SC_BOCCDashboard_Controller
JIRA Story          :   ESESP-6534 :: BOCC Dashboard

@History
--Developer         --Date              --Change
Vikas				26-Apr-2022			ESESP-6534 : Initial Development

************************************************************************************************************
*/
@isTest
public class SC_BOCCDashboard_Controller_Test {
	/* TEST DATA SETUP */
    @testSetup
    static void testDataSetup()
    {
        utilTestClass.createCustomSettings();
		Group boccQueue = [Select Id, Name FROM Group 
                               WHERE Type = 'Queue' 
                               AND Name = 'ATS_BOCC_QUEUE'];        
        // Creating Account
        List<Account> accList =  new List<Account>();
        Account acc = utilTestClass.CreateAccount('TestBOCCAccount');   
        accList.add(acc);
        insert accList;
        
        Test.startTest();
        List<Case> newCaseInsertList = new List<Case>();
        Case newCase = new Case();
        for(Integer i=0; i<3; i++)
        {
            newCase = new Case();
            newCase.Subject = 'New Test Case BOCC : '+i;
            newCase.Sub_Type__c = 'BOCC';
            newCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();
            newCase.validation_override__c = true;
            newCase.AccountId = accList[0].Id;
            newCase.ownerId = boccQueue.Id;
            newCase.Status = 'Unassigned';
            if(i==0)
            	newCase.Work_Type__c = 'Reactive';
            if(i==1){
                Datetime lastCustomerActivity = Datetime.newInstance(2022, 04, 02, 12, 30, 2);
                Datetime lastCaseUpdate = Datetime.newInstance(2022, 04, 01, 12, 30, 2);
                newCase.Last_Customer_Activity_Date__c = lastCustomerActivity;
				newCase.Last_Case_Update__c = lastCaseUpdate;
            }
                
            newCaseInsertList.add(newCase);
        }
        insert newCaseInsertList;
        Test.stopTest();
    }
    
    public static testMethod void fetchCaseTest()
    {
        String caseWorkType = 'Reactive,Proactive';
        String caseSeverity = '1,2,3,4';
        String selectAll = 'CaseWorkType:Reactive,Proactive&CaseSeverity:1,2,3,4';
        SC_User_Filter__c filter = new SC_User_Filter__c();
        filter.Filter_Values__c = 'CaseWorkType:Reactive,Proactive&CaseSeverity:1,2,3,4';
        filter.RecordTypeId = Schema.SObjectType.SC_User_Filter__c.getRecordTypeInfosByName().get('BOCC').getRecordTypeId();
        filter.Unique_ID__c = String.valueOf(UserInfo.getUserId()+'-'+Schema.SObjectType.SC_User_Filter__c.getRecordTypeInfosByName().get('BOCC').getRecordTypeId());
        insert filter;
        SC_BOCCDashboard_Controller.fetchCaseList(caseWorkType,caseSeverity);
        SC_BOCCDashboard_Controller.saveBOCCFilters(selectAll);
    }
    
    public static testMethod void saveFilterTest()
    {
        String selectAll = 'CaseWorkType:Reactive,Proactive&CaseSeverity:1,2,3,4';
        SC_BOCCDashboard_Controller.saveBOCCFilters(selectAll);
    }
    
    public static testMethod void saveNoFilterTest()
    {
        SC_User_Filter__c filter = new SC_User_Filter__c();
        filter.Filter_Values__c = 'CaseWorkType:Reactive,Proactive&CaseSeverity:1,2,3,4';
        filter.RecordTypeId = Schema.SObjectType.SC_User_Filter__c.getRecordTypeInfosByName().get('BOCC').getRecordTypeId();
        filter.Unique_ID__c = String.valueOf(UserInfo.getUserId()+'-'+Schema.SObjectType.SC_User_Filter__c.getRecordTypeInfosByName().get('BOCC').getRecordTypeId());
        insert filter;
        String selectAll = '';
        SC_BOCCDashboard_Controller.saveBOCCFilters(selectAll);
    }
}