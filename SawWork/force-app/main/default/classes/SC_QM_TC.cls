/*=====================================================================================================+
    Class name          :   SC_QM_TC 
    Author              :   Supreeth,Sumukh,Himanshu
    Created             :   12-Feb-18
    Purpose             :   This is a Test class for QM Tool. Code coverage for below components
                            1. SC_QM_MainClass 
                            2. SC_QM_ACD 
                            
                            
    Last Modified Developer     			Purpose            
    ============= ========================  =======
    14-APR-18     Supreeth,Sumukh,Himanshu  Initial Development(Jira Ticket# )
+=====================================================================================================*/

@isTest
public class SC_QM_TC{

    @testSetup static void datasetup() {
        
        //Create all custom settings
        utilTestClass.createCustomSettings();
       
    	// Creating Account
        Account accRec = new Account(Name='Test Account IP Addr',AKAM_Account_ID__c='Test-ABC-123IPAddr',Type='Brand - Active');
        insert accRec;  
        
        // Creating Case 
        Case newCase = new Case();
        newCase.Subject = 'TestCase';
        newCase.Description = 'TestDescription';
        newCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        newCase.validation_override__c = true;
        newCase.AccountId = accRec.Id;
        insert newCase;      
    }
    
	//  Test Method -1 : For New User  	
    	public static testmethod void scenario_1(){
        
            // Deleting Existing User Data
            delete [select Id from SC_QM_User_Filter__c where User_Id__c = :UserInfo.getUserId()];
    		Test.startTest(); 
            
            	SC_QM_MainClass mainCls = new SC_QM_MainClass();
            
            	// Calling all the support methods
            	Pagereference pr = mainCls.refreshPage();
            	pr = mainCls.resetAllFilter();
            	mainCls.upsertUserDetails('test',UserInfo.getUserId());
            	pr = mainCls.test();
            
            	// Calling Apply Filter with Parameters
            	mainCls.applyFilter();
            	Test.setCurrentPageReference(new PageReference('Page.SC_QM_Page')); 
				System.currentPageReference().getParameters().put('SLName', 'Standard,Azure');
            	System.currentPageReference().getParameters().put('QueueName', 'ENT');
            	System.currentPageReference().getParameters().put('GeographyName', 'APJ,EMEA');
            	
            	try{
            		mainCls.applyFilter();
                }catch(exception e){}
            
            	// Calling Apply Filter without Parameters
            	System.currentPageReference().getParameters().put('SLName', '');
            	System.currentPageReference().getParameters().put('QueueName', '');
            	System.currentPageReference().getParameters().put('GeographyName', '');
            	mainCls.applyFilter();
                
            	          
        	Test.stopTest();
    	}
    	
    	//  Test Method -2 : For Existing User  	
    	public static testmethod void scenario_2(){

			Group queue = [SELECT Id FROM Group WHERE DeveloperName = 'Orphan_Queue' LIMIT 1];
        	// Creating Test Data for SC_QM_User_Filter__c
        	SC_QM_User_Filter__c upsertUserData = new SC_QM_User_Filter__c();
      	upsertUserData.User_Id__c		= UserInfo.getUserId();
      	upsertUserData.Support_Level__c	= 'Standard';
      	upsertUserData.Queue__c			= queue.Id;
      	upsertUserData.Geography__c		= 'Americas';
      	upsertUserData.Query_String__c	= 'Select Id,description,AKAM_Case_ID__c,Account.Name,Subject,Severity__c,Support_Level__c,createddate,OwnerId,Case_Assignment_Using_Active_Rules__c,Case_Prod_Name__c,Support_Geography__c,Account.Division__c,AccountId,Owner.Name,Age_days__c,has_active_transition__c,(select TimeRemaininginMins,TargetDate from CaseMilestones where IsCompleted = false) from Case limit 10';
      	
      	upsert upsertUserData User_Id__c;
        	
    		Test.startTest(); 
            
            	SC_QM_MainClass mainCls = new SC_QM_MainClass();
            	          
        	Test.stopTest();
    	}
    	
    	//  Test Method -3 : For ACD API Data 	
    	public static testmethod void scenario_3(){
    	
    		// Creating API - 1 Data
		string api1_data = '{"summary":{"Split/Skill":"661","Agents":{"Staffed":71,"Available":24,"Ringing":0,"ACD Calls":0,"ACW":0,"AUX Work":46,"Other":1},"Calls Waiting":"0","Oldest Call Waiting":":00","Direct Agent Calls Wait":"0","% Ans Within    0 Secs":"","Calls Answered":"0","Calls Abandoned":"0"},"agents":[{"Agent Name":"M_P_MATAYLOR","Login ID":"81314","Extn":"43938","Reason":"","State":"AVAIL","Split/Skill":"0","Time":"0:18:22","VDN":""}]}';
    		
    		// Creating API - 2 Data
    		string api2_data = 		'['+
		'    {'+
		'        "acdg_id": "1",'+
		'        "acdg_skill_id": "661",'+
		'        "acdg_type": "Media",'+
		'        "acdg_type2": "Paid",'+
		'        "acdg_name": "Paid_Media_West",'+
		'        "acdg_label": "Paid Media - West",'+
		'        "acdg_timezone": "PST8PDT",'+
		'        "acdg_work_days": "Monday,Tuesday,Wednesday,Thursday,Friday",'+
		'        "acdg_min_agent": "3",'+
		'        "acdg_notification_frequency": "30",'+
		'        "acdg_notification_email": "",'+
		'        "acdg_notification_email_enabled": "1",'+
		'        "acdg_weekly_email": "",'+
		'        "acdg_weekly_email_enabled": "1",'+
		'        "acda_id": "4",'+
		'        "acda_acdg_id": "1",'+
		'        "acda_ldap_id": "reradhak",'+
		'        "acda_acd_login_id": "81314",'+
		'        "acda_first_name": "Renuka",'+
		'        "acda_last_name": "Radhakrishnan",'+
		'        "acda_phone_ext": "70249",'+
		'        "acda_country_id": "230",'+
		'        "acda_field1": null,'+
		'        "acda_base_score": "0",'+
		'        "acda_selected": "0",'+
		'        "acda_status": "0",'+
		'        "country_id": "230",'+
		'        "country_code": "US",'+
		'        "country_name": "United States"'+
		'    }]';

    		
    		Test.startTest(); 
            
            	// Setting the Parameters
            	Test.setCurrentPageReference(new PageReference('Page.SC_QM_Page')); 
			System.currentPageReference().getParameters().put('getACD_API_1_Data', api1_data);
            	System.currentPageReference().getParameters().put('getACD_API_2_Data', api2_data);
            	
            	// Calling Main ACD Method
            	SC_QM_ACDClass acdCls1 = new SC_QM_ACDClass();
            	acdCls1.getDatainApexForAPI_Main();
             	
             	// Calling QM Main Class
            	SC_QM_MainClass mainCls = new SC_QM_MainClass();
        		SC_QM_ACDClass acdCls = new SC_QM_ACDClass(mainCls);
            	          
        	Test.stopTest();
    	}
 
      
}