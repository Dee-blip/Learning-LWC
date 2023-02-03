/***************************************************************************
 * Name             : ACD2_Webservices_Test
 * Created By       : Sharath Prasanna& Vamsee S
 * Created Date     : 28-Apr-2020
 * Purpose          : Test Class for ACD 2.0 Webservices
 * List of Classes	: ACD2_AccountDetails_ANI_WS
 * 					  ACD2_AccountDetails_ERC_WS
 *                    ACD2_AccountGeo_ANI_WS
 * 					  ACD2_AccountTeam_ProductERC_WS
 * 					  ACD2_ActiveCaseDetails_CaseNumber_WS
 *                    ACD2_CaseDetails_CaseNumber_WS
 * 					  ACD2_LeadContactDetails_ANI_WS
 * 					  ACD2_UserDetails_ANI_WS
 * 					  ACD2_UtilClass
 *                    ACD2_DeleteLogsScheduler

 Last Modified BY   	Last Modified Date  	Purpose
 ----------------   	------------------  	---------
 Sharath & Vamsee		    28-Apr-2020			Initial Development
Sharath						1 Mar 2021			test methods for setup automation
 Sharath						3 June 2021			Test method for Automation
 ****************************************************************************/
@isTest(SeeAllData=false)
public class ACD2_Webservices_Test 
{
    //Creating public static variables
	Public static User usr;
    Public static User usr2;
	public static RestRequest request;
	public static Account accountRecord;
    public static Account accountRecord2;
    public static Account accountRecord3;
    Public static PSA_TestUtility testUtil;
    Public static TS_Support_Team__c supportTeam;
    Public static TS_TeamAccount__c teamAccount;
    Public static Case caseRecord;
    public static List<Id> fixedSearchResults;	
    
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
        usr.ACD2_Support_Team_Skill__c = 'Media';   
        usr.UserName = 'acd2'+ datetime.now().millisecond() + '@akamai.com';
        usr.Department = 'AkaTec';
        Insert usr;
        
        request = new RestRequest();
        request.httpMethod = 'GET';
		request.requestUri = System.Url.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/';
        List<Account> accountList = new List<Account>();
        accountRecord = testUtil.newAccount(false);
        accountRecord.Parent_Division__c = 'Media_APJ';
        accountRecord.Region__c = 'karnataka';
        accountRecord.Area__c = 'Bangalore';
        accountRecord.Division__c = 'India';
        accountRecord.Projected_SDR__c = usr.Id;
        accountRecord.AKERC__c = '9999';
        accountRecord.Support_Level__c = 'Premium';
        accountList.add(accountRecord);
        
        accountRecord2 = testUtil.newAccount(false);
        accountRecord2.Name = 'Test 1';
        accountRecord2.Parent_Division__c = 'Web_EMEA';
        accountRecord2.Region__c = 'karnataka';
        accountRecord2.Area__c = 'Bangalore';
        accountRecord2.Division__c = 'India';
        accountRecord2.AKERC__c = '6666';
        accountList.add(accountRecord2);
        
        accountRecord3 = testUtil.newAccount(false);
        accountRecord3.Name = 'Test 3';
        accountRecord3.Parent_Division__c = 'Web_EMEA';
        accountRecord3.Region__c = 'karnataka';
        accountRecord3.Area__c = 'Bangalore';
        accountRecord3.Division__c = 'India';
        accountRecord3.AKERC__c = '6666';
        accountList.add(accountRecord3);
        
        Insert accountList;
        
        fixedSearchResults = new List<Id>();

        supportTeam = new TS_Support_Team__c();
        supportTeam.Team_Name__c = 'PRE_WEB_EAST2_NGUPTA';
        supportTeam.Team_Type__c = 'WebExp_Geo-P';
        supportTeam.VDN__c = 10162.0;
        insert supportTeam;
        
        teamAccount = new TS_TeamAccount__c();
        teamAccount.Team_Account__c = accountRecord.Id;
        teamAccount.TS_Support_Team__c = supportTeam.Id;
        insert teamAccount;
        
        // Case Custom Settings
        SCUtilTestClass.createCustomSettingsForCase();
        
        caseRecord = new Case();
        caseRecord.AccountId = accountRecord.Id;
        caseRecord.Subject = 'Test';
        caseRecord.AKAM_Case_id__c = 'F-CS-123456';
        caseRecord.Description = 'Test';
        caseRecord.Validation_override__c = True;
        Insert caseRecord;
        
    }
	//test method for ACD2_UserDetails_ANI_WS API
    @isTest static void testUserDetailsAPI()
    {
        request.requestUri = request.requestUri + '/ACD2_UserDetails_ANI_WS';
        request.params.put('ANI', '108108108108');
        request.params.put('CallGUID', '12345678');
        RestContext.request = request;

        
		fixedSearchResults.add(usr.Id);
		Test.setFixedSearchResults(fixedSearchResults);

        Test.startTest();
            ACD2_UserDetails_ANI_WS.getListOutput();
            
            request.params.put('ANI', null);
            RestContext.request = request;
            ACD2_UserDetails_ANI_WS.getListOutput();
        Test.stopTest();
    }
    
	//test method for ACD2_AccountGeo_ANI_WS API
    @isTest static void testSOCCGeoAPI()
    {
        
        request.requestUri = request.requestUri + '/ACD2_AccountGeo_ANI_WS';
        request.params.put('ANI', '108108108108');
        request.params.put('CallGUID', '12345678');
        RestContext.request = request;

        Test.startTest();

        	Contact associatedContact = testUtil.newResource(false, accountRecord.Id, usr.Id);
            associatedContact.phone = '108108108108';
            insert associatedContact;

            fixedSearchResults.add(associatedContact.Id);
            Test.setFixedSearchResults(fixedSearchResults);
        
	        ACD2_AccountGeo_ANI_WS.getGeographyOutput();
        Test.stopTest();
        
    }

    //test method for ACD2_LeadContactDetails_ANI_WS API    
    @isTest static void testMarketingAPI()
    {
        request.requestUri = request.requestUri + '/ACD2_LeadContactDetails_ANI_WS';
        request.params.put('ANI', '108108108108');
        request.params.put('CallGUID', '12345678');
        RestContext.request = request;
        			
		Test.startTest();        
            Contact associatedContact = testUtil.newResource(false, accountRecord.Id, usr.Id);
            associatedContact.phone = '108108108108';
            insert associatedContact;

            fixedSearchResults.add(associatedContact.Id);
            Test.setFixedSearchResults(fixedSearchResults);
            
	        ACD2_LeadContactDetails_ANI_WS.getListOutput();
    
	        Lead newLead =  new Lead();
            newLead.Associated_Contact__c = associatedContact.id;
            newLead.Status = 'New';
            newLead.recordTypeId = Schema.getGlobalDescribe().get('Lead').getDescribe().getRecordTypeInfosByName().get('Akamai Lead').getRecordTypeId();
            newLead.Validation_Override__c = true;
	        newLead.OwnerId = usr.id;
            insert newLead;
            
    
            ACD2_LeadContactDetails_ANI_WS.getListOutput();
        Test.stopTest();
        
    }

    //test method 1 for ACD2_AccountDetails_ANI_WS API    
    @isTest static void testAccountDetailsANISingleContact()
    {
        request.requestUri = request.requestUri + '/ACD2_LeadContactDetails_ANI_WS';
        request.params.put('ANI', '108108108108');
        request.params.put('CallGUID', '12345678');
        RestContext.request = request;
        			
		Test.startTest();        
            Contact associatedContact = testUtil.newResource(false, accountRecord.Id, usr.Id);
            associatedContact.phone = '108108108108';
            insert associatedContact;

            fixedSearchResults.add(associatedContact.Id);
            Test.setFixedSearchResults(fixedSearchResults);
            
            ACD2_AccountDetails_ANI_WS.getSupportTeamFromANI();
        Test.stopTest();
        
    }

    //test method 2 for ACD2_AccountDetails_ANI_WS API        
    @isTest static void testAccountDetailsANIMultipleContacts()
    {
        request.requestUri = request.requestUri + '/ACD2_LeadContactDetails_ANI_WS';
        request.params.put('ANI', '108108108108');
        request.params.put('CallGUID', '12345678');
        RestContext.request = request;
        			
        List<contact> contacts = new List<contact>();
		Test.startTest();        
            Contact associatedContact = testUtil.newResource(false, accountRecord.Id, usr.Id);
            associatedContact.phone = '108108108108';
            contacts.add(associatedContact);
        	
        	associatedContact = testUtil.newResource(false, accountRecord.Id, null);
        	associatedContact.RecordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByName().get('Business Contact').getRecordTypeId();
            associatedContact.phone = '108108108108';
            contacts.add(associatedContact);

			insert contacts;
        
        	fixedSearchResults.add(contacts.get(0).Id);
	        fixedSearchResults.add(contacts.get(1).Id);
        
            Test.setFixedSearchResults(fixedSearchResults);
            
            ACD2_AccountDetails_ANI_WS.getSupportTeamFromANI();
        Test.stopTest();
        
    }    

    //test method for ACD2_AccountTeam_ProductERC_WS API        
    @isTest static void testAccountTeamProductERC()
    {
        request.requestUri = request.requestUri + '/ACD2_LeadContactDetails_ANI_WS';
        request.params.put('ERC_Number', '9999');
        request.params.put('ProductName', 'Media');
        request.params.put('CallGUID', '12345678');
        RestContext.request = request;
        			
        List<contact> contacts = new List<contact>();
		Test.startTest();     
			        	
        	system.runAs(usr)
            {                
                usr2 = testUtil.newUserSysAdmin(false); 
                usr2.phone = '108108108108';
                usr2.Owner_Support_Department__c   = 'Technical Support';
                usr2.ACD2_Support_Team_Skill__c = 'Enterprise';
                usr2.UserName = 'acd2'+ datetime.now().millisecond()+ '@akamai.com';
                usr2.Department = 'AkaTec';
                insert usr2;

            }
	       
        	List <id> UserIds = new List <id>{usr.Id,usr2.Id};
    		createSupportTeam(UserIds);

        	fixedSearchResults.add(accountRecord.Id);        
            Test.setFixedSearchResults(fixedSearchResults);
            
            ACD2_AccountTeam_ProductERC_WS.getAgentDetailsFromProduct();
        Test.stopTest();
        
    }    

    //test method for ACD2_UtilClass
    @isTest static void testUtilClass()
    {
		Test.startTest();  
        	String aniString = '+919945565353';
	        createSupportTeam(new List <id> {usr.id});
			ACD2_UtilClass.getAllProducts(new List<Id>{accountRecord.id});
			ACD2_UtilClass.getCountryCodeGeo (aniString);
			ACD2_UtilClass.getTechnicalSupportTeam(accountRecord.id);
			ACD2_UtilClass.sendErrorMail(aniString, 'Dummy Error','Dummy Stack Trace', 'Error');
	        ACD2_UtilClass.getAkaTecGeo(new List<Account>{accountRecord});
			ACD2_UtilClass.isPremiumAccountCheck(new List<Id>{accountRecord.id});
        
        Test.stopTest();
        
    }    
   
    //method to create the support team members
    public static void createSupportTeam(List <id> UserIds)
    {
        	TS_TeamMember__c member;
			List<TS_TeamMember__c> members = new List<TS_TeamMember__c>();
        
        	for (Integer i = 0; i < UserIds.size() ; i++)
            {
                member = new TS_TeamMember__c();
                member.Team_Member__c = UserIds.get(i);
                member.TS_Support_Team__c = supportTeam.Id;
                member.Role__c = 'Technical Support - Primary';
                
                members.add(member);
                

                member = new TS_TeamMember__c();
                member.Team_Member__c = UserIds.get(i);
                member.TS_Support_Team__c = supportTeam.Id;
                member.Role__c = 'Technical Support - Secondary';
                
                members.add(member);
                
                member = new TS_TeamMember__c();
                member.Team_Member__c = UserIds.get(i);
                member.TS_Support_Team__c = supportTeam.Id;
                member.Role__c = 'Technical Support - Other';
                
                members.add(member);
            }
            
           	insert members;            
        
    }
    
    //test method for ACD2_ActiveCaseDetails_CaseNumber_WS API
    @isTest static void testActiveCaseAPI()
    {
        request.requestUri = request.requestUri + '/ACD2_ActiveCaseDetails_CaseNumber_WS';
        request.params.put('CaseNumber', '123456');
        RestContext.request = request;

        Test.startTest();
            ACD2_ActiveCaseDetails_CaseNumber_WS.getListOutput();
            
            request.params.put('CaseNumber', null);
        	request.params.put('CallGUID', '12345678');
            RestContext.request = request;
            ACD2_ActiveCaseDetails_CaseNumber_WS.getListOutput();
        Test.stopTest();
    }
    
    //test method for ACD2_ActiveCaseDetails_CaseNumber_WS API
    @isTest static void testCaseAPI()
    {
        request.requestUri = request.requestUri + '/ACD2_CaseDetails_CaseNumber_WS';
        request.params.put('CaseNumber', '123456');
        RestContext.request = request;

        Test.startTest();
            ACD2_CaseDetails_CaseNumber_WS.getListOutput();
            
            request.params.put('CaseNumber', null);
        	request.params.put('CallGUID', '12345678');
            RestContext.request = request;
            ACD2_CaseDetails_CaseNumber_WS.getListOutput();
        
        	request.params.put('CaseNumber', '000000');
        	request.params.put('CallGUID', '12345678');
            RestContext.request = request;
            ACD2_CaseDetails_CaseNumber_WS.getListOutput();
        Test.stopTest();
    }
    
    //test method for ACD2_AccountDetails_ERC_WS API
    @isTest static void testAccountDetailAPI()
    {
        request.requestUri = request.requestUri + '/ACD2_AccountDetails_ERC_WS';
        request.params.put('ERC', '9999');
        RestContext.request = request;

        Test.startTest();
            ACD2_AccountDetails_ERC_WS.getListOutput();
            
            request.params.put('ERC', null);
        	request.params.put('CallGUID', '12345678');
            RestContext.request = request;
            ACD2_AccountDetails_ERC_WS.getListOutput();
        
        	request.params.put('ERC', '6666');
	        request.params.put('CallGUID', '12345678');
            RestContext.request = request;
            ACD2_AccountDetails_ERC_WS.getListOutput();
        Test.stopTest();
    }
    
     //test method for ACD2_AccountDetails_ERC_WS API
    @isTest static void testDeleteLogscheduler()
    {
        Test.startTest();
        ACD2_Logs__c acdlog = new ACD2_Logs__c();
        acdlog.Call_GUID__c = 'Test';
        acdlog.Input_String__c = 'Test';
        acdlog.Response__c = 'Test';
        acdlog.Status__c= 'Valid';
        acdlog.Webservice_Name__c = 'Test';
        Insert acdlog;
        ACD2_DeleteLogsScheduler testScheduler= new ACD2_DeleteLogsScheduler();
        String jobId = System.schedule('testScheduler', '0 0 0 3 9 ? 2030', testScheduler);
        Test.stopTest();
    }
    
    //test method for the user setup Automation
    @isTest static void testAutomationMethods()
    {
        Test.startTest();
	        ACD2_UtilClass.createIndiaConfigFlow(new List<String>{usr.Id});
		    ACD2_UtilClass.callNonSetupFlowFuture(new List<String>{usr.Id});
            ACD2_UtilClass.callSetupFlowFuture(usr.Id);
        	ACD2_UtilClass.callNonSetupFlow(usr.Id);
        	//ACD2_UtilClass.callSetupFlow(usr.Id);
            ACD2_UtilClass.setupUserForACD(usr.Id);
        Test.stopTest();
    }

    //Automation from Service Request
    @isTest static void testAutomationMethods2()
    {
        Test.startTest();
            HD_Test_Data_Factory.init();
            BMCServiceDesk__CategoryTypes__c catType = new BMCServiceDesk__CategoryTypes__c(name = 'Q_Test');
            insert catType;
            BMCServiceDesk__Category__c acdCategory = new BMCServiceDesk__Category__c(
                name = 'Salesforce Phone Widget (ACD) Issue', BMCServiceDesk__AvailableForIncidents__c = true,
                BMCServiceDesk__FKCategoryType__c = catType.id);
            insert acdCategory;
        
	        ACD2_SetupAutomation.setupUserForACD(new List<String>{usr.Id});
		    ACD2_SetupAutomation.createIncidentRecord(usr.Id);
        Test.stopTest();
    }

}