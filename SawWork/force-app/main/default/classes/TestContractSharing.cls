@isTest(seeAllData=false)
private class TestContractSharing 
{ 
    static {
        utilTestClass.insertCustomSettings();
    }

    static testMethod void testAccountTeamCreation() 
    {

        // Create 200 test accounts - this simulates one execute.  
        System.runAs(utilTestClass.getTestRunUser())
        {

            List<Account> tAccounts= new List<Account>();
            Integer numberOfTestAccounts = 100;
            for(integer i = 0; i<numberOfTestAccounts; i++){
                Account a = new Account(Name='tttt1'+i, 
                        BillingCountry= 'India', BillingState= 'Delhi'); 
                tAccounts.add(a);
            }  
            insert tAccounts;  

            Profile pr = [select id from profile where name='Sales Operations'][0];

            User tmUser = new User(alias = 'tmUser1', email='ttt12@akamai.com',emailencodingkey='UTF-8', lastname='TmUser1', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__team_meber1@akamai.com',profileid = pr.Id);
            Test.startTest();
            insert tmUser;

            List<AccountTeamMember> accTeam = new list<AccountTeamMember>();
            List<Merge_Contract_Header__c> mchList = new List<Merge_Contract_Header__c>();
            Integer k=0;
            for(Account acc : tAccounts)
            {
                AccountTeamMember member = new AccountTeamMember();
                member.AccountId = acc.Id;
                member.UserId = tmUser.Id;   
                member.TeamMemberRole = 'Sales - secondary';     
                accTeam.add(member);

                Merge_Contract_Header__c mch = utilTestClass.CreateContractHeader('Test Contract'+k+'d',acc.Id);
                k=k+1;
                mchList.add(mch);

            }
            insert mchList;
            insert accTeam;


            List<Account_Team__c>accountTeam =  new list<Account_Team__c>();
            for(AccountTeamMember team : accTeam)
            {
                Account_Team__c member = new Account_Team__c();
                member.Account__c = team.AccountId;
                member.User__c = team.UserId;   
                member.TeamMemberRole__c = team.TeamMemberRole;    
                member.AccountTeamId__c = team.Id; 
                accountTeam.add(member);
            }
            insert accountTeam;
            Test.stopTest();


            // number of contract_shares__c created = numberOfTestAccounts

            System.assertEquals(numberOfTestAccounts, [select count() from Account_Team__c where Account__c in :tAccounts]);

            System.assertEquals(numberOfTestAccounts, [select count() from Contract_Share__c where Associated_User__c=:tmUser.Id]);

            delete accountTeam;
            System.assertEquals(0, [select count() from Contract_Share__c where Associated_User__c=:tmUser.Id]);


        }
    }

    static testMethod void testOpptyTeamCreation() 
    {
        System.runAs(utilTestClass.getTestRunUser())
        {

            Account a = utilTestClass.CreateAccount('__ TEST');
            insert a;
            List<Opportunity> listOfTestOpp = new List<Opportunity>();
            OpportunityStage stage = [select MasterLabel from OpportunityStage limit 1];
            Integer numOfTimes=50;
            for(Integer num=0 ; num<numOfTimes ; num++)
            {
                Opportunity o = utilTestClass.CreateOpportunity('__ TEST',stage.MasterLabel);
                o.AccountId = a.id;
                o.CurrencyIsoCode = 'INR';  
                o.name = 'test'+ String.valueof(num+1);
                o.CloseDate    = Date.today() + 365;
                listOfTestOpp.add(o);
            }
            insert(listOfTestOpp);
            Profile pr = [select id from profile where name='Sales Operations'][0];
            User tmUser = new User(alias = 'tmUser1', email='ttt12@akamai.com',emailencodingkey='UTF-8', lastname='TmUser1', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__team_meber1@akamai.com',profileid = pr.Id);
            Test.startTest();
            insert tmUser;


            List<OpportunityTeamMember> otmList = new List<OpportunityTeamMember>();
            List<Merge_Contract_Header__c> mchList = new List<Merge_Contract_Header__c>();
            Integer k=0;

            for(Opportunity tOpp : listOfTestOpp)
            {
                OpportunityTeamMember otm=new OpportunityTeamMember(OpportunityId=tOpp.id, TeamMemberRole='Sales - Secondary', UserId=tmUser.id);
                otmList.add(otm);
                Merge_Contract_Header__c mch = utilTestClass.CreateContractHeader('Test Contract'+k+'d',a.Id);
                mch.Opportunity_Name__c= tOpp.Id;
                k=k+1;
                mchList.add(mch);
            }

            insert mchList;

            insert otmList;
            Test.stopTest();

            System.assertEquals(numOfTimes,  [select count() from Contract_Share__c where Associated_User__c=:tmUser.Id]);
            delete otmList;
            System.assertEquals(0,  [select count() from Contract_Share__c where Associated_User__c=:tmUser.Id]);



        }
    }
}