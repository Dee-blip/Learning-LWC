/*---------------------------------------------------------------------------------
 * Test Class Name 		: SC_ScrubIPAddressBatchClasses_Test
 * Developer Name 		: Aditi Singh, Vandhana Krishnamurthy
 * Date 				: 25th April,2022
 * JIRA 				: ESESP-8457
 * Classes Covered		: SC_ScrubIPAddressesForFeed_Batch, SC_ScrubIPAddressesForCollabFeed_Batch, SC_ScrubIPAddressesForCollabComm_Batch
 ---------------------------------------------------------------------------------*/ 

@isTest
public class SC_ScrubIPAddressBatchClasses_Test 
{
    public static User crmOpsUser;
    
    // Method-1: Creating Test Data
    @testSetup static void testDataSetup()
    {
        String crmOpsId = SC_Utility__mdt.getInstance('CRM_Ops_Id').Value_Text__c;
        crmOpsUser = [SELECT Id FROM User WHERE Id = :crmOpsId];
        
        System.runAs(crmOpsUser)
        {    
            //inserting custom setting
            SC_SupportEmail__c cs = new SC_SupportEmail__c();
            cs.Name='1';
            cs.Support_Email_AutoGen__c = 'sc-dev@akamai.com';
            insert cs;

            //Account Setup
            Account accRec; 
            utilTestClass.createCustomSettings();
            accRec = new Account(Name='Test Account IP Addr',AKAM_Account_ID__c='Test-ABC-123IPAddr',Type='Brand - Active',IP_Scrubbing_Days__c = 0);
            insert accRec; 
            
            //Case Setup
            list<case> testCaseList = new list<case>();
            list<case> testCaseListUpdate = new list<case>();
            for(integer i = 0 ; i <= 10 ; i++)
            {
                Case caseRec = new Case();
                caseRec.AccountId = accRec.id;
                caseRec.Subject = 'Test IP Addresses : Success List : 111.222.111.111, 1111:2222:3333:4444:5555:6666:7777:88888';
                caseRec.Description = '1.2.3.4 Test 11.22.11.22 test 111.111.111.111';
                caseRec.Origin = 'Phone';
                caseRec.Validation_Override__c = true;
                caseRec.IP_Scrubbing_Failed_Objects__c = 'FeedItem FeedComment';
                
                caseRec.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();

                if(i == 3 || i == 4)
                {
                	caseRec.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('AMG').getRecordTypeId();
                    caseRec.Solution_Summary__c = '1::1';
                }
                else if(i == 5 || i == 6)
                {
                	caseRec.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Managed Security').getRecordTypeId();
                    caseRec.Next_Action_Recommendation__c = '::a';
                    caseRec.IP_Scrubbing_Failed_Objects__c = 'FeedComment';
                }
                else if(i == 7 || i == 8)
                {
                	caseRec.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
                    caseRec.Comments__c = 'a::';
                    caseRec.IP_Scrubbing_Failed_Objects__c = 'FeedItem';
                }
                else if(i == 9 || i == 10)
                {
                    caseRec.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Invalid Case').getRecordTypeId();
                    caseRec.Living_Summary_Next_Steps__c = '0.0.0.0';
                }
                
                testCaseList.add(caseRec);
            } 
            insert testCaseList;
            
            //CaseFeedItem Setup
            list<FeedItem> feedList = new list<FeedItem>();
            for(case eachCaseFeed :testCaseList)
            {
                FeedItem eachFeed = new FeedItem();
                eachFeed.ParentId = eachCaseFeed.Id;
                eachFeed.Body = '1.2.3.4 Test 11.22.11.22 test 111.111.111.111 IPV6 11::22';
                eachFeed.Title = '1.2.3.4 Test 11.22.11.22 test 111.111.111.111 IPV6 11::22';
                feedList.add(eachFeed);
            }
            insert feedList;
    
            //CaseFeedComment Setup
            list<FeedComment> feedCommentList = new list<FeedComment>();
            for(FeedItem fitem :feedList)
            {
                FeedComment eachFeedComm = new FeedComment();
                eachFeedComm.FeedItemId = fitem.Id;
                //eachFeedComm.ParentId = fitem.ParentId;
                eachFeedComm.CommentBody = '1.2.3.4 Test 11.22.11.22 test 111.111.111.111 IPV6 11::22';
                feedCommentList.add(eachFeedComm);
            }
            insert feedCommentList;
            
            for(Case c : testCaseList)
            {
                case updateCase = new case();
                updateCase.Validation_Override__c = true;
                updateCase.status = 'Closed';
                updateCase.Id = c.id;
                testCaseListUpdate.add(updateCase); 
            }
            update testCaseListUpdate;
            
            //Creating collaboration group
            List<CollaborationGroup> grpsList = new List<CollaborationGroup>();
            for (Integer i = 0;i<5;i++) 
            {
                CollaborationGroup g = new CollaborationGroup(Name='Test Class Ip Srcub Test Collab Group '+i, CollaborationType='Public');
                grpsList.add(g);
            }
            insert grpsList;
            
            //FeedItem Setup for Swarms
            list<FeedItem> collabFeedList = new list<FeedItem>();
            for(CollaborationGroup grp :grpsList)
            {
                FeedItem eachFeed = new FeedItem();
                eachFeed.ParentId = grp.Id;
                eachFeed.Body = '1.2.3.4 Test 11.22.11.22 test 111.111.111.111';
                eachFeed.Title = '1.2.3.4 Test 11.22.11.22 test 111.111.111.111';
                collabFeedList.add(eachFeed);
            }
            insert collabFeedList;
            
            //FeedItem Setup for Swarms
            list<FeedComment> collabFeedCommentList = new list<FeedComment>();
            for(FeedItem fitem :collabFeedList)
            {
                FeedComment eachFeedComm = new FeedComment();
                eachFeedComm.FeedItemId = fitem.Id;
                eachFeedComm.CommentBody = '1.2.3.4 Test 11.22.11.22 test 111.111.111.111';
                collabFeedCommentList.add(eachFeedComm);
            }
            insert collabFeedCommentList;
        }
        
        //Query inserted user
        User endUser = [Select Id from User where Profile.Name = 'Support - Tech Support Manager' and IsActive = true LIMIT 1];
        Case csNew = [SELECT Id FROM Case WHERE RecordType.Name = 'Technical' LIMIT 1];
        
        System.runAs(endUser)
        {
            list<FeedItem> feedListByUser = new list<FeedItem>();
            for(Integer i = 0;i<3;i++){
                FeedItem eachFeed = new FeedItem();
                eachFeed.ParentId = csNew.Id;
                eachFeed.Body = '1.2.3.4 Test 11.22.11.22 test 111.111.111.111';
                feedListByUser.add(eachFeed);
            }
            insert feedListByUser;
        }
        
        endUser.IsActive = false;
        update endUser;
    }
    
    public static testmethod void testingSC_ScrubIPAddressesForCollabFeedAndComment_Batch()
    {
        Test.startTest(); 
        Test.setMock(HttpCalloutMock.class, new SC_ScrubIPCaseMuleHttpRequestMock());
        Id scrubIPBatchId = Database.executeBatch(new SC_ScrubIPAddressesForCollabFeed_Batch());
        Test.stopTest();
        (new SC_ScrubIPAddressesForFeed_Batch()).senEmailWhenError('EmailSubject','EmailBody');
    }
}