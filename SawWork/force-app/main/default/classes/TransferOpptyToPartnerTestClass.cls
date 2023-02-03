@isTest
public class TransferOpptyToPartnerTestClass
{

    static User dmlUser = new User(id=UserInfo.getUserId());
    static testMethod void PRMAddPartnerToSalesTeamControllerTest() 
    {
        System.runAs(dmlUser) {
            Account acc = utilTestClass.CreateAccount('__TEST acc');
            acc.Website='www.tkjiestwebsite.com';
            insert acc;
            //Create a partner User for that account
            List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,acc.id);
            User partner=PartnerUsers[0];
            //Profile prSCM = [Select Id, Name from profile where id=:PRM_Settings__c.getInstance('Channel manager profile id').Value__c][0]; //SFDC-2573
            Profile prSCM = [Select Id, Name from profile where id=:GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id')][0]; //SFDC-2573
            UserRole roleDVA = [select id, name from UserRole where name ='Business Operations'][0];
            User opptySCMOwnerUser = new User(alias = 'scmUsr1', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OpptyOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__mss_owner@akamai.com',profileid = prSCM.Id, UserRoleId = roleDVA.Id );
            insert opptySCMOwnerUser;
            Channel_Mapping__c cm= new Channel_Mapping__c(Name = 'Test Channel Mapping', Partner_Name__c = acc.id, PAE_ID__c = opptySCMOwnerUser.id);
            insert cm;
            Opportunity oppty = utilTestClass.CreateOpportunity('Test Oppty','1-Create');
            oppty.Deal_Type__c='Indirect';
            oppty.Partner_Involved__c=acc.id;
            oppty.AccountId=acc.id;
            oppty.CloseDate= Date.today();
            insert oppty;
            OpportunityTeamMember otm = new OpportunityTeamMember(OpportunityId=oppty.id, TeamMemberRole='Partner', UserId=partner.id);
            insert otm;
            system.runAs(opptySCMOwnerUser)
            {
                PageReference pageRef = Page.TransferOpptyToPartner;
                Test.setCurrentPageReference(pageRef);
                pageRef.getParameters().put('pid', partner.id);
                ApexPages.StandardController sc = new ApexPages.StandardController(oppty);
                TransferOpptyToPartnerController topp= new TransferOpptyToPartnerController(sc);
                topp.setvalue();
                topp.redirectToAddPartnerPage();
                topp.cancel();
                topp.transferToPartner();
            }
        }
    }
}