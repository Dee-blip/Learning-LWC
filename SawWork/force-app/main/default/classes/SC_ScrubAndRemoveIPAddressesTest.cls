/*---------------------------------------------------------------------------------
 * Class Name 			: SC_ScrubAndRemoveIPAddressesTest
 * Class Type 			: Test Class
 * Parent Class Name 	: SC_Scrub_IP_Batch,SC_ScrubAndRemoveIPAddresses
 * Developer Name 		: Aditya Sonam
 * Date 				: 8th May,2017
 * JIRA 				: ESESP-561 
 ---------------------------------------------------------------------------------*/ 

@isTest(SeeAllData = false)
public class SC_ScrubAndRemoveIPAddressesTest {
    
    // Method-1: Creating Test Data
    @testSetup static void testDataSetup(){
       User userRun = [SELECT Id FROM User WHERE Alias = 'CRMOPS' limit 1];
       system.runAs(userRun){
       // For Case Record Type
       Id caseTechnicalRT = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
       String testStringWithIPs = '1.2.3.4 Test 11.22.11.22 test 111.111.111.111'; 
       Account accRec; 
       //Account Setup
       utilTestClass.createCustomSettings();
       accRec = new Account(Name='Test Account IP Addr',AKAM_Account_ID__c='Test-ABC-123IPAddr',Type='Brand - Active');
       insert accRec; 
           
       //Product Setup
          EB_AccountProductMap__c ProdTest = new EB_AccountProductMap__c(); 
          ProdTest.Name = 'Riverbed_Product';
          ProdTest.EB_Account__c = accRec.Id;
          ProdTest.EB_Product__c = 'Riverbed_Product';
      
      	insert ProdTest;
        
	   //Case Setup
	    list<case> testCaseList = new list<case>();
        list<case> testCaseListUpdate = new list<case>();
        
        for(integer i = 0 ; i < 10 ; i++){
        	Case caseRec = new Case();
        	caseRec.AccountId = accRec.id;
       		caseRec.status = 'Assigned';
       		caseRec.RecordTypeId = caseTechnicalRT;
        	caseRec.Subject = 'Test IP Addresses : Success List : 111.222.111.111, 1111:2222:3333:4444:5555:6666:7777:88888';
        	caseRec.Description = testStringWithIPs;
        	caseRec.Origin = 'Email';
        	caseRec.Is_IP_Scrubbed__c = false;
            caseRec.Validation_Override__c = true;
            caseRec.Case_Product__c = ProdTest.id;
            testCaseList.add(caseRec);
        } 
        insert testCaseList;
 
        //Case Transition Setup
        list<Case_Transition__c> caseTrasitionList = new List<Case_Transition__c>();
        for(case eachCase :testCaseList){
           Case_Transition__c caseTrans = new Case_Transition__c();
           caseTrans.Case__c = eachCase.id;
           caseTrans.Issue_Summary__c = testStringWithIPs;
           caseTrans.Troubleshooting_to_Date__c = testStringWithIPs;
           caseTrans.Data_Collected__c = testStringWithIPs;
           caseTrans.Customer_Expectations__c = testStringWithIPs;
           caseTrans.Next_Action_Recommendation__c = testStringWithIPs;
           caseTrans.Validation_Override__c = true;  
           caseTrasitionList.add(caseTrans);       
        } 
        insert caseTrasitionList;
               
        //Engagement Request Setup
        list<Engagement_Request__c> caseERList = new List<Engagement_Request__c>();
        for(case eachCaseER :testCaseList){
           Engagement_Request__c caseER = new Engagement_Request__c();
           caseER.Case__c = eachCaseER.id;
           caseER.Description__c = testStringWithIPs;
           caseER.Steps_to_Reproduce__c = testStringWithIPs;
           caseER.Sample_URLs__c = testStringWithIPs;
           caseER.Additional_Data__c = testStringWithIPs;
           caseER.Validation_Override__c = true;
		   caseERList.add(caseER);       
        } 
        insert caseERList;
        
        //Activity Setup
        list<Task> taskList = new list<Task>();
        Id taskRT = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('AMG Activity').getRecordTypeId();
        for(case eachCaseTask :testCaseList){
            task eachTask = new task();
            eachTask.WhatId = eachCaseTask.Id;
            eachTask.subject = testStringWithIPs;
            eachTask.Description = testStringWithIPs;
            eachTask.RecordTypeId = taskRT;
            eachTask.Task_Validation_Override__c = true;
            taskList.add(eachTask);
        }

        insert taskList;
        
        //FeedItem Setup
        list<FeedItem> feedList = new list<FeedItem>();
        for(case eachCaseFeed :testCaseList){
            FeedItem eachFeed = new FeedItem();
            eachFeed.ParentId = eachCaseFeed.Id;
            eachFeed.Body = testStringWithIPs;
			feedList.add(eachFeed);
        }
        insert feedList;
        
        for(Case c :testCaseList){
            case updateCase = new case();
            updateCase.Validation_Override__c = true;
            updateCase.status = 'Closed';
            updateCase.Id = c.id;
            testCaseListUpdate.add(updateCase); 
        }
      	update testCaseListUpdate;
    }
    }
    
    
    public static testmethod void ScrubIPTest(){

        Test.startTest(); 
            
            Id scrubIPBatchId = Database.executeBatch(new SC_ScrubIPAddresses_Batch());
                     
        Test.stopTest();
    }

}