@isTest(seeAllData=false)
public class SC_CommunityCommentControllerTest {
	@testSetup
    static void setupMethod() {
        
        Account acc = new Account();
        acc.Name = 'TestChimeAccount';
        acc.BillingCountry = 'India';
        acc.BillingState = 'DELHI';
        acc.website = 'www.testchimeaccount.com';
        insert acc;
        
        Opportunity oppty = utilTestClass.CreateOpportunity('__ChimeTest Oppty','1. Identify Need');
        oppty.AccountId = acc.Id;
        oppty.CloseDate = Date.today().addMonths(4);
        insert oppty;
        
        CHIME__c chimeRecord = new CHIME__c();
        chimeRecord.Account__c = acc.id;
        chimeRecord.Opportunity__c = oppty.id;
        chimeRecord.CHIME_Name__c = 'Chime Test Record';
        chimeRecord.Implementation_Type__c = 'Standard';
        chimeRecord.Reopen_Reason__c ='Missing Data';
        insert chimeRecord;
    }
    
    @isTest static void insertnewFileCommentTest(){
        Chime__c chime = [Select id from Chime__c limit 1];
        Test.startTest();
        SC_CommunityCommentController.insertnewFileComment(chime.Id,'CHIME','CHIME__c','Test Comment');
        Test.stopTest();
    }
    
    @isTest static void insertnewCommentTest(){
        Chime__c chime = [Select id from Chime__c limit 1];
        Test.startTest();
        SC_CommunityCommentController.insertnewComment(chime.Id,'CHIME','CHIME__c','Test Comment','Private');
        SC_CommunityCommentController.insertnewComment(chime.Id,'CHIME','CHIME__c','Test Comment','Public');
        Test.stopTest();
    }
    
    @isTest static void getCommentDetailsTest(){
        Chime__c chime = [Select id from Chime__c limit 1];
        Community_Comments__c newcomment = new Community_Comments__c();
        newcomment.Parent_ID__c=chime.Id;
        newcomment.Commented_By__c='Internal User';
        newcomment.Visibility__c='Private';
        newcomment.Comment__c='Test';
        newcomment.Application__c = 'CHIME';
        newcomment.Related_Object__c='CHIME__c';
        newcomment.AKAM_Created_Date__c=datetime.now();
        newcomment.AKAM_Modified_Date__c=datetime.now();
        newcomment.AKAM_Created_By__c=userinfo.getUserId();
        insert newcomment;
        Test.startTest();
        SC_CommunityCommentController.getCommentDetails(chime.Id, 'CHIME', 'CHIME__c', 'Private');
        Test.stopTest();
    }
    
    @isTest static void sendCommNotificationTest(){
        Chime__c chime = [Select id from Chime__c limit 1];
        Test.startTest();
        list<string> toAddress = new list<string>{'abc@test.com'};
        SC_CommunityCommentController.Chime_CommCommentLogic chmLogic = new SC_CommunityCommentController.Chime_CommCommentLogic();
        chmLogic.sendCommNotification(toAddress,'Test','Test','Test','CustomerToInternal',chime.Id);
        Test.stopTest();
    }
}