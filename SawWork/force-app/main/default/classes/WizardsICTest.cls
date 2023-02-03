@isTest
private class WizardsICTest
{
    public static List<IdeaComment__c> ideaComments;
    
    static testMethod void testICEmailFlow()
    {
        //ideaComments = WizardsInitData.createIdeaComments();
        ideaComments = new List<IdeaComment__c>();
        List<User> users = new List<User>();
        Idea idea = WizardsInitData.createIdea();
        WizardsInitData.voteIdeas(idea);
        Profile p = [select Id from Profile where Name = 'Standard User'];
        
        User u1 = new User(Alias = 'standt', Email='standarduser1@akamai.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='standarduser1@akamai.com');
        
        User u2 = new User(Alias = 'standt', Email='standarduser2@akamai.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='standarduser2@akamai.com');
        
        users.add(u1);
        users.add(u2);
        insert users;
        
        IdeaComment__c ideaComment1 = new IdeaComment__c();
        System.runAs(u1)
        {
            ideaComment1.IdeaId__c = idea.Id;
            ideaComment1.CommentBody__c = 'Test Idea Comment1 for objIdea';
            ideaComment1.ActualCreator__c = UserInfo.getUserId();
            ideaComment1.IsDataLoad__c = false; 
            insert ideaComment1;
        }
        ideaComments.add(ideaComment1);
        
        Test.startTest();
            IdeaComment__c ideaComment2 = new IdeaComment__c();
            System.runAs(u2)
            {
                ideaComment2.IdeaId__c = idea.Id;
                ideaComment2.CommentBody__c = 'Test Idea Comment2 for objIdea';
                ideaComment2.ActualCreator__c = UserInfo.getUserId();
                ideaComment2.IsDataLoad__c = false;
                insert ideaComment2;
            }
            ideaComments.add(ideaComment2);
        Test.stopTest();
        
        System.assert(ideaComments.size() > 0);
    }
}