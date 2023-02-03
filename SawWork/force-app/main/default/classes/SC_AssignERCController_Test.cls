/***************************************************************************
 * Name             : SC_AssignERCController_Test
 * Created By       : Sharath Prasanna
 * Created Date     : 28-May-2020
 * Purpose          : Test Class for SC_AssignERCController
 Last Modified BY   	Last Modified Date  	Purpose
 ----------------   	------------------  	---------
 Sharath		    	26-May-2020			Initial Development
 ****************************************************************************/
@isTest(SeeAllData=false)
public class SC_AssignERCController_Test 
{
    //Creating public static variables
	Public static User usr;

    public static Account accountRecord;
    public static Account accountRecord2;

    Public static PSA_TestUtility testUtil;
    
    Public static TS_Support_Team__c supportTeam;
    Public static TS_TeamAccount__c teamAccount;
    
    static
    {
        createTestData();
    }
	//Static method to create test data
    Public static void createTestData()
    {
        testUtil = new PSA_TestUtility();
        
        usr = testUtil.newUserSysAdmin(false); 
        usr.phone = '108108108108';
        usr.Owner_Support_Department__c   = 'Technical Support';
        usr.Team__c = 'AkaTec - Media';   
        usr.UserName = 'acd2'+ datetime.now().millisecond() + '@akamai.com';
        Insert usr;
        
        List<Account> accountList = new List<Account>();
        accountRecord = testUtil.newAccount(false);
        accountRecord.Parent_Division__c = 'Media_APJ';
        accountRecord.Region__c = 'karnataka';
        accountRecord.Area__c = 'Bangalore';
        accountRecord.Division__c = 'India';
        accountRecord.Projected_SDR__c = usr.Id;
        //accountRecord.AKERC__c = '9999';
        accountList.add(accountRecord);

        accountRecord2 = testUtil.newAccount(false);
        accountRecord2.Name = 'Test 1';
        accountRecord2.Parent_Division__c = 'Web_EMEA';
        accountRecord2.Region__c = 'karnataka';
        accountRecord2.Area__c = 'Bangalore';
        accountRecord2.Division__c = 'India';
        accountRecord2.AKERC__c = '6666';
        accountList.add(accountRecord2);
        
        Insert accountList;
        

        supportTeam = new TS_Support_Team__c();
        supportTeam.Team_Name__c = 'PRE_WEB_EAST2_NGUPTA';
        supportTeam.Team_Type__c = 'Premium WebExp';
        supportTeam.VDN__c = 10162.0;
        insert supportTeam;
        
        teamAccount = new TS_TeamAccount__c();
        teamAccount.Team_Account__c = accountRecord.Id;
        teamAccount.TS_Support_Team__c = supportTeam.Id;
        insert teamAccount;
        
        
    }
	//test method for SC_AssignERCController
    @isTest static void testMethod1()
    {
        Test.startTest();
			SC_AssignERCController.getERCWrapper(accountRecord.Id,'6666');
        Test.stopTest();
    }

}