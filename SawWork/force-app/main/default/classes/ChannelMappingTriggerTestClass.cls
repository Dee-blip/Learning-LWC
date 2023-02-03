@isTest
public class ChannelMappingTriggerTestClass 
{
    /*private static User CreateUser(String pUsrAlias, String pProfile, String pRole)
    {
        Profile pr = [select Id from Profile where Name=:pProfile][0];
        UserRole role = [select Id, Name from UserRole where Name=:pRole][0];
        User newUser = new User(alias = pUsrAlias, email=pUsrAlias+'@akamai.com',emailencodingkey='UTF-8', lastname='NewOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username= pUsrAlias +'@akamai.com',profileid = pr.Id, UserRoleId = role.Id );
        return newUser;     
    }
     static{
     utilTestClass.insertCustomSettings();
    } */
    // Changes for CR 2842878(fix the Mixed Dml Exception)
    static User dmlUser = new User(id=UserInfo.getUserId());
    
    private static Opportunity RefreshOpportunity(Id pOppId)
    {
        return [select Id, Channel_Manager__c from Opportunity  where Id=: pOppId];
    }
    
    public static testmethod void ChannelMappingTrigger_Positive()
    {
        
        ManagedPkgErrorClass.isFromManagedPackage = false;
        Account acc = utilTestClass.CreateAccount('__Test Account');
        acc.Partner_Type__c = 'Unknown';
        insert acc;

        // Added  3 line for CR 2842878(fix the Mixed Dml Exception)
         User User1;
         User User2;
         User User3;
                  User User4;


        // Added line for CR 2842878(fix the Mixed Dml Exception)
        System.runAs(dmlUser) {
            List<User> usrList = new List<User>();
            User1 = utilTestClass.CreateUser('TSTPAE1', 'Sales Operations', 'Sales Operations');
            usrList.add(User1);
            User2 = utilTestClass.CreateUser('FRAPPVR1', 'Sales Operations', 'Sales Operations');
            usrList.add(User2);
            User3 = utilTestClass.CreateUser('TSTPAE2', 'Sales Operations', 'Sales Operations');
            usrList.add(User3);  
            User4 = utilTestClass.CreateUser('TSTPAE3', 'Sales Operations', 'Sales Operations');  
            usrList.add(User4);

            insert usrList;

         }   
        //Channel_Mapping__c cm = new Channel_Mapping__c(Partner_Name__c=acc.Id,MDF_Approver__c=User1.Id, PAE_ID__c = User2.Id,VAR_Manager_Team_Role__c='Channel - Primary');
        Channel_Mapping__c cm = utilTestClass.CreateChannelMapping('Test Channel Mapping', acc.Id, User2.Id);
        cm.MDF_Approver__c = User1.Id;
        cm.VAR_Manager_Team_Role__c = 'Channel - Primary';
        cm.Temp_PAE__c = User4.Id;

        insert cm;
        Test.startTest();
        Opportunity oppty = utilTestClass.CreateOpportunity('__Test Oppty','1-Create');
        oppty.Partner_Involved__c = acc.Id;
        oppty.OwnerId = User1.Id;
        oppty.CloseDate = Date.today().addMonths(4);
        oppty.Channel_Manager__c = cm.Id;
        insert oppty;
        
        oppty.GSI_Channel_Manager__c = cm.id;
        update oppty;
        
        ChannelMappingTriggerClass.setChannelMappingMemberFirstRunFlag = true;
        
        cm.Temp_PAE__c = User3.Id;
        update cm;
        
        OpportunityTeamMember otm = [SELECT Id, OpportunityId, UserId, TeamMemberRole FROM OpportunityTeamMember WHERE OpportunityId =: oppty.Id and UserId=: User3.Id];
        
        system.assertEquals(otm.TeamMemberRole,'Channel - Secondary');
        
        List<OpportunityShare> opptyShare = [SELECT Id, OpportunityId, OpportunityAccessLevel, UserOrGroupId FROM OpportunityShare WHERE OpportunityId=: oppty.Id AND UserorGroupId=: User3.Id];

        //Due to Summer'16 release, now Read record also getting created for Oppty Team and hence we will have both Read and Write Share record
        //system.assertEquals(opptyShare.OpportunityAccessLevel, 'Edit');
        List<Channel_Mapping__c> cmList = new List<Channel_Mapping__c>();
        cmList.add(cm);
        ChannelMappingTriggerClass.AddTempPAEtoSalesTeam(cmList);
        Test.stopTest();
    }
   
    public static testmethod void ChannelMappingTrigger_Negative()
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        Account acc = utilTestClass.CreateAccount('__Test Account');
        acc.Partner_Type__c = 'Unknown';
        insert acc;
        
        
        // Added below  3 line for CR 2842878(fix the Mixed Dml Exception)
        User User1;
        User User2;
        System.runAs(dmlUser) {
            User1 = utilTestClass.CreateUser('TSTPAE1', 'Sales Operations', 'Sales Operations');
            User2 = utilTestClass.CreateUser('FRAPPVR1', 'Sales Operations', 'Sales Operations'); 
            insert User1;
            insert User2;
        }
        
        //Channel_Mapping__c cm = new Channel_Mapping__c(Partner_Name__c=acc.Id,MDF_Approver__c=User1.Id, PAE_ID__c = User2.Id,VAR_Manager_Team_Role__c='Channel - Primary');
        Channel_Mapping__c cm = utilTestClass.CreateChannelMapping('Test Channel Mapping', acc.Id, User2.Id);
        cm.MDF_Approver__c = User1.Id;
        cm.VAR_Manager_Team_Role__c = 'Channel - Primary';
        insert cm;
        
        Opportunity oppty = utilTestClass.CreateOpportunity('__Test Oppty','1-Create');
        oppty.Partner_Involved__c = acc.Id;
        oppty.OwnerId = User1.Id;
        oppty.CloseDate = Date.today().addMonths(4);
        oppty.Channel_Manager__c = cm.Id;
        insert oppty;
        
        ChannelMappingTriggerClass.setChannelMappingMemberFirstRunFlag = true;

        // Added Statement System.runA line for CR 2842878(fix the Mixed Dml Exception)
        System.runAs(dmlUser) {
            User2.IsActive = false;
            update User2;
        }
        cm.Temp_PAE__c = User1.Id;
        update cm;
        
        OpportunityShare opptyShare = [SELECT Id, OpportunityId, OpportunityAccessLevel, UserOrGroupId FROM OpportunityShare WHERE OpportunityId=: oppty.Id AND UserorGroupId=: User1.Id];
        system.assertNotEquals(opptyShare.OpportunityAccessLevel, 'Edit');

    } 
    
    
    public static testmethod void ChannelMappingTrigger_BulkPositive()
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        Account acc = utilTestClass.CreateAccount('__Test Account');
        acc.Partner_Type__c = 'Unknown';
        insert acc;

        // Added below  4 line for CR 2842878(fix the Mixed Dml Exception)
        User User1;
        User User2;
        User User3;
        System.runAs(dmlUser) {
            User1 = utilTestClass.CreateUser('TSTPAE1', 'Sales Operations', 'Sales Operations');
            User2 = utilTestClass.CreateUser('FRAPPVR1', 'Sales Operations', 'Sales Operations');
            User3 = utilTestClass.CreateUser('TSTPAE2', 'Sales Operations', 'Sales Operations'); 
            insert User1;
            insert User2;
            insert User3;
         }   
        
        //Channel_Mapping__c cm = new Channel_Mapping__c(Partner_Name__c=acc.Id,MDF_Approver__c=User1.Id, PAE_ID__c = User2.Id,VAR_Manager_Team_Role__c='Channel - Primary');
        Channel_Mapping__c cm = utilTestClass.CreateChannelMapping('Test Channel Mapping', acc.Id, User2.Id);
        cm.MDF_Approver__c = User1.Id;
        cm.VAR_Manager_Team_Role__c = 'Channel - Primary';
        insert cm;
        
        List<Opportunity> opptyList = new List<Opportunity>();
        
        for (Integer i=1;i<=10;i++)
        {
            Opportunity oppty = utilTestClass.CreateOpportunity('__Test Oppty'+i,'1-Create');
            oppty.Partner_Involved__c = acc.Id;
            oppty.OwnerId = User1.Id;
            oppty.CloseDate = Date.today().addMonths(4);
            oppty.Channel_Manager__c = cm.Id;
            opptyList.add(oppty);
        }
        insert opptyList;

        ChannelMappingTriggerClass.setChannelMappingMemberFirstRunFlag = true;
        
        cm.Temp_PAE__c = User3.Id;
        update cm;
        
        List<OpportunityTeamMember> otm = [SELECT Id, OpportunityId, UserId, TeamMemberRole FROM OpportunityTeamMember WHERE UserId=: User3.Id AND OpportunityId IN :opptyList];
        
        List<OpportunityShare> opptyShare = [SELECT Id, OpportunityId, OpportunityAccessLevel, UserOrGroupId FROM OpportunityShare WHERE OpportunityId IN :opptyList AND UserorGroupId=: User3.Id];

        for(Integer i=1;i<10;i++)
        {
            system.assertEquals(otm[i].TeamMemberRole,'Channel - Secondary');
            system.assertEquals(opptyShare[i].OpportunityAccessLevel, 'Edit');
        }
    }
    
    public static testmethod void ChannelMapping_bi_bu_Trigger_Positive(){

        Account acc = utilTestClass.CreateAccount('__Test Account');
        acc.Partner_Type__c = 'Unknown';
        insert acc;
        
        // Added below  3 line for CR 2842878(fix the Mixed Dml Exception)
        User User1;
        User User2;
        System.runAs(dmlUser) {
            User1 = utilTestClass.CreateUser('TSTPAE1', 'Sales Operations', 'Sales Operations');
            User2 = utilTestClass.CreateUser('FRAPPVR1', 'Sales Operations', 'Sales Operations');
            insert User1;
            insert User2;
         }   
    
        Channel_Mapping__c cm = utilTestClass.CreateChannelMapping('Test Channel Mapping', acc.Id, User2.Id);
        cm.MDF_Approver__c = User1.Id;
        cm.VAR_Manager_Team_Role__c = 'Channel - Primary';
        insert cm;
        
        Opportunity oppty = utilTestClass.CreateOpportunity('__Test Oppty','1-Create');
        oppty.Partner_Involved__c = acc.Id;
        oppty.OwnerId = User1.Id;
        oppty.CloseDate = Date.today().addMonths(4);
        oppty.Channel_Manager__c = cm.Id;
        insert oppty;

        cm.Active__c = false;
        try{
            update cm;
        }
        catch(Exception e){
            String err = Label.Channel_Mapping_Inactivation_Error;
            system.assert(e.getMessage().contains(err));
        }
    }

    public static testmethod void ChannelMapping_bi_bu_Trigger_Negative(){

        Account acc = utilTestClass.CreateAccount('__Test Account');
        acc.Partner_Type__c = 'Unknown';
        insert acc;

        // Added below  3 line for CR 2842878(fix the Mixed Dml Exception)
        User User1;
        User User2;
        System.runAs(dmlUser) {
            User1 = utilTestClass.CreateUser('TSTPAE1', 'Sales Operations', 'Sales Operations');
            User2 = utilTestClass.CreateUser('FRAPPVR1', 'Sales Operations', 'Sales Operations');
            insert User1;
            insert User2;
        }

        Channel_Mapping__c cm = utilTestClass.CreateChannelMapping('Test Channel Mapping', acc.Id, User2.Id);
        cm.MDF_Approver__c = User1.Id;
        cm.VAR_Manager_Team_Role__c = 'Channel - Primary';
        insert cm;
        
        Opportunity oppty = utilTestClass.CreateOpportunity('__Test Oppty','1-Create');
        oppty.Partner_Involved__c = acc.Id;
        oppty.OwnerId = User1.Id;
        oppty.CloseDate = Date.today().addMonths(4);
        oppty.Channel_Manager__c = cm.Id;
        insert oppty;

        oppty.StageName = 'Closed Lost';
        oppty.Validation_Override__c = true;
        update oppty;

        cm.Active__c = false;
        update cm;

        system.assertEquals(cm.Active__c, false);
    }



    public static testmethod void ChannelMapping_bi_bu_Trigger_NoOpps_Negative(){
        Account acc = utilTestClass.CreateAccount('__Test Account');
        acc.Partner_Type__c = 'Unknown';
        insert acc;

        // Added below  3 line for CR 2842878(fix the Mixed Dml Exception)
        User User1;
        User User2;
        System.runAs(dmlUser) {
            User1 = utilTestClass.CreateUser('TSTPAE1', 'Sales Operations', 'Sales Operations');
            User2 = utilTestClass.CreateUser('FRAPPVR1', 'Sales Operations', 'Sales Operations');
            insert User1;
            insert User2;
        }
        Channel_Mapping__c cm = utilTestClass.CreateChannelMapping('Test Channel Mapping', acc.Id, User2.Id);
        cm.MDF_Approver__c = User1.Id;
        cm.VAR_Manager_Team_Role__c = 'Channel - Primary';
        insert cm;

        cm.Active__c = false;
        update cm;
        system.assertEquals(cm.Active__c, false);
    
    } 
    
}