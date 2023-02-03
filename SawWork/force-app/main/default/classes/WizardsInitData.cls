public class WizardsInitData
{
    static Idea objIdea;
    static IdeaComment__c ideaComment1;
    static IdeaComment__c ideaComment2;
    static List<IdeaComment__c> ideaComments;
    static IdeaEmail__c objIdeaEmail;

    public static void createCS()
    {
        Idea_Environment_Url__c ideaEnvURL = new Idea_Environment_Url__c();
        ideaEnvURL.Current_Cycle_End_Date__c = Date.newInstance(2016,10,31);
        ideaEnvURL.Idea_Year__c = 2016;
        ideaEnvURL.Incrementer__c = 1;
        ideaEnvURL.challenge_incrementer__c = 1;
        ideaEnvURL.SetupOwnerId=UserInfo.getOrganizationId();
        insert ideaEnvURL;
        
        Profile cp = [Select Id from Profile where Name='Customer Communities Profile' limit 1];
        Communities_Settings__c CS = new Communities_Settings__c();
        cs.Name = 'Community';
        cs.SetupOwnerId=UserInfo.getOrganizationId();
        cs.User_Name_Append_Value__c = '.akamai';
        cs.Self_Registration_Community_Profile_Id__c = cp.Id;
        insert cs;
        
        List<Features_Toggle__c> fts = new List<Features_Toggle__c>();
        Features_Toggle__c ft = new Features_Toggle__c();
        ft.Name = 'UpdateContactOwnerForInActiveUsers';
        ft.Toggle__c  = true;
        fts.add(ft);
        
        Features_Toggle__c ft1 = new Features_Toggle__c();
        ft1.Name = 'UserActivationSendEmail';
        ft1.Toggle__c  = true;
        fts.add(ft1);
        
        insert fts;
        
        UserTriggerClassSettings__c utcs = new UserTriggerClassSettings__c();
        utcs.Name = 'v1.0';
        utcs.exemptedUserAlias__c = 'CINTEGRA, ONA';
        insert utcs;
        
        GSM_Custom_Settings__c gcs = new GSM_Custom_Settings__c();
        gcs.Name = 'UserTriggerClass#ChannelUsersProfiles';
        gcs.Value__c = '00eG0000000eAyJIAU,00eG0000000eAyOIAU,00eA0000000QkKxIAK,00eG0000000g65cIAA';
        insert gcs;
    }
    
    public static Idea createIdea()
    {
        Id zoneId = [Select Id from Community where name = 'Wizards' limit 1].Id;
        createCS();
        objIdea = new Idea();
        objIdea.CommunityId = zoneId;
        objIdea.Title = 'Title Idea Trigger';
        objIdea.Body = 'Body Idea Trigger';
        objIdea.Status = 'New';
        objIdea.Effort_investment_needed_to_implement__c = 'Effort';
        objIdea.What_are_the_cost_benefits_of_solution__c = 'Benefit';
        objIdea.What_is_the_business_or_tech_problem__c = 'Problem';
        objIdea.What_is_the_proposed_sol_or_prod_concept__c = 'Solution';
        objIdea.Project_Type__c = 'Finance';
        objIdea.ActualCreator__c = UserInfo.getUserId();
        insert objIdea;
        return objIdea;
    }
    
    public static List<IdeaComment__c> createIdeaComments()
    {
        ideaComments = new List<IdeaComment__c>();
        Idea idea = createIdea();
        voteIdeas(idea);
        Profile p = [select Id from Profile where Name = 'Standard User'];
        
        User u1 = new User(Alias = 'standt', Email='standarduser1@akamai.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='standarduser1@akamai.com');
        
        User u2 = new User(Alias = 'standt', Email='standarduser2@akamai.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='standarduser2@akamai.com');
        
        System.runAs(u1)
        {
            ideaComment1 = new IdeaComment__c();
            ideaComment1.IdeaId__c = idea.Id;
            ideaComment1.CommentBody__c = 'Test Idea Comment1 for objIdea';
            ideaComment1.ActualCreator__c = UserInfo.getUserId();
            ideaComment1.IsDataLoad__c = false; 
            insert ideaComment1;
        }
        
        System.runAs(u2)
        {
            ideaComment2 = new IdeaComment__c();
            ideaComment2.IdeaId__c = idea.Id;
            ideaComment2.CommentBody__c = 'Test Idea Comment2 for objIdea';
            ideaComment2.ActualCreator__c = UserInfo.getUserId();
            ideaComment2.IsDataLoad__c = false;
            insert ideaComment2;
        }
        
        ideaComments.add(ideaComment1);
        ideaComments.add(ideaComment2);
        //insert ideaComments;
        return ideaComments;        
    }

    public static List<Vote__c> voteIdeas(Idea idea){

        //upvote and downvote with different users
        Profile p = [select Id from Profile where Name = 'Standard User'];
        User randomUser = new User(Alias = 'standt', Email='standarduser3@akamai.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='standarduser3@akamai.com');

        List<Vote__c> votes = new List<Vote__c>();

        System.runAs(randomUser){

            Vote__c upVote = new Vote__c();
            upVote.ActualCreator__c = UserInfo.getUserId();
            upVote.Type__c = 'Up';
            upVote.ParentId__c = idea.Id;
            votes.add(upVote);

            Vote__c downVote = new Vote__c();
            downVote.ActualCreator__c = UserInfo.getUserId();
            downVote.Type__c = 'Down';
            downVote.ParentId__c = idea.Id;
            votes.add(downVote);

            insert votes;
        }

        return votes;
    }

    public static IdeaEmail__c createIdeaEmail()
    {
        objIdeaEmail = new IdeaEmail__c();
        objIdeaEmail.To__c = 'standarduser1@akamai.com';
        objIdeaEmail.CC__c = 'standarduser2@akamai.com';
        objIdeaEmail.Subject__c = 'Test Class Subject Check';
        objIdeaEmail.Msg__c = 'Test Class Msg Check';
        objIdeaEmail.Feedback_Type__c = 'Test Class Feedback Email';
        objIdeaEmail.Mail_Type__c = 'IdeaEmail';
        objIdeaEmail.SenderName__c = 'Standard';

        insert objIdeaEmail;
        return objIdeaEmail;

    }
}