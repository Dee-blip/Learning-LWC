/**
 * This class contains unit tests for Chatter Pulse
 */
@isTest(seeAllData=false)
private class TestChatterPulse {
    static
    {
        utilTestClass.insertCustomSettings();
    }
    static testmethod void myChatterPulse() {

        //Check to see if Account is Feed Enabled
        Schema.DescribeSObjectResult r = Account.sObjectType.getDescribe();     
        if(r.IsFeedEnabled())
        {
            Test.startTest();
            //Create a test Account
            //Account acc = new Account(Name = 'Test Account');
            //insert acc;
            Account acc = utilTestClass.CreateAccount('testyac1');
            insert acc;
     
            // Create post on Account
            FeedItem fi = new FeedItem();
            fi.Body = 'This is a test, this is only a test';
            fi.parentId = acc.id;
            insert fi;
            
            //Comment on the post
            FeedComment fc = new FeedComment();
            fc.CommentBody = 'Commenton the test post';
            fc.FeedItemId = fi.id;
            insert fc;            
            
            datetime t = System.now();
            date myReportingDate = Date.newInstance(t.year(),t.month(),t.day());
            
            //CP_Chatter_Pulse__c[] myPulse = [SELECT Update_Type__c FROM CP_Chatter_Pulse__c 
            //WHERE CP_Chatter_Pulse__c.Reporting_Date__c = :myReportingDate AND OwnerId =:UserInfo.getUserId() ORDER BY createdDate ASC];
            
            CP_Chatter_Pulse__c[] myPulse = [SELECT Update_Type__c FROM CP_Chatter_Pulse__c
            WHERE CP_Chatter_Pulse__c.Related_Record__c = :acc.Id];
            
            String ActualUpdateType = myPulse[0].Update_Type__c;
            
            System.Assert(ActualUpdateType.startsWith('Feed: '));
            Test.stopTest();
        }
        
    }
    
    static testmethod void myChatterUserPulse() {
        Test.startTest();
        
        User user = [select id, CurrentStatus from User where id =:UserInfo.getUserId()];
        user.CurrentStatus = 'Testing the user feed';
        update user;

        User[] myUserPulse = [SELECT CurrentStatus FROM User 
        WHERE User.ID = :UserInfo.getUserId()];
           
        System.AssertEquals(myUserPulse[0].CurrentStatus, 'Testing the user feed');
        Test.stopTest();
    }


}