/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
public class ApprovalProcessPageControllerTestClass 
{
    static User partner;
    
    public static testmethod void ApprovalProcess_Positive()
    {
      System.runAs(utilTestClass.getTestRunUser())
      {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        utilTestClass.insertCustomSettings();
        ApprovalHistoryPageControllerTestClass.disableDealMakerCoreSettings();
        Account acc = utilTestClass.CreateAccount('__ test Account');
        insert acc;
        //Create a partner User for that account
        List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,acc.id);
        partner=PartnerUsers[0];
        //Add the User to the chanell mapping table
        // Create 'SalesChannelMgr' User
        //Profile prSCM = [Select Id, Name from profile where id=:PRM_Settings__c.getInstance('Channel manager profile id').Value__c][0]; //SFDC-2573
        Profile prSCM = [Select Id, Name from profile where id=:GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id')][0]; //SFDC-2573
        UserRole roleDVA = [select id, name from UserRole where name='Worldwide'][0];
        User opptySCMOwnerUser = new User(alias = 'scmUsr1', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OpptyOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__mss_owner@akamai.com',profileid = prSCM.Id, UserRoleId = roleDVA.Id );
        insert opptySCMOwnerUser;
        
        //Channel_Mapping__c cm= new Channel_Mapping__c(Name = 'Test Channel Mapping', Partner_Name__c = acc.id, PAE_ID__c = opptySCMOwnerUser.id);
        Channel_Mapping__c cm = utilTestClass.CreateChannelMapping('Test Channel Mapping', acc.Id, opptySCMOwnerUser.Id);
        insert cm;
        
        List<Opportunity> oppList = new List<Opportunity>();
        
        Opportunity opp = utilTestClass.CreateOpportunity('__Test Opportunity','1-Create');
        opp.Channel_Manager__c = cm.Id;
        opp.End_Customer_Country__c = 'USA';
        opp.End_Customer_State__c = 'NY';
        opp.End_Customer_City__c = 'Buffalo';
        opp.End_Customer_Street_Address__c = 'Line1 \r\n Line2';  
        opp.CloseDate= Date.today();
        opp.Partner_Involved__c = acc.Id;
        opp.AccountId = acc.Id;
        opp.Deal_Reg_Account_Status__c='New Account';
        opp.Deal_Reg_Opportunity_Status__c='New Opportunity';
        oppList.add(opp);
        
        Opportunity opp2 = utilTestClass.CreateOpportunity('__Test Opportunity2','1-Create');
        opp2.Channel_Manager__c = cm.Id;
        opp2.End_Customer_Country__c = 'USA';
        opp2.End_Customer_State__c = 'NY';
        opp2.End_Customer_City__c = 'Buffalo';
        opp2.End_Customer_Street_Address__c = 'Line1 \r\n Line2';  
        opp2.CloseDate= Date.today();
        opp2.Partner_Involved__c = acc.Id;
        opp2.AccountId = acc.Id;
        opp2.Deal_Reg_Account_Status__c='New Account';
        opp2.Deal_Reg_Opportunity_Status__c='New Opportunity';
        oppList.add(opp2);
        
        system.runAs(Partner)
        {
          Test.startTest();
          insert oppList;
        }
        
        //Submit the Opportunity for Approval
        PRM_opportunity.submitForApproval(opp.Id);
        PRM_opportunity.submitForApproval(opp2.Id);
        
        PageReference pageRef = Page.ApprovalProcessPage;
        Test.setCurrentPageReference(pageRef);
        pageRef.getParameters().put('oppId', opp.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(opp);
        ApprovalProcessPageController fruc = new ApprovalProcessPageController();
        
        //Approve the Opportunity without adding Rebate Justification value
        PageReference returnURL = fruc.approve();
        //checkcode error fix
        String url = '/' + opp.Id;
        PageReference assertReturnURL = new PageReference(url);
        //System.assertEquals(returnURL.getUrl(), assertReturnURL.getUrl());
        
        //Add the Rebate Justificaion value and Approve
        sc = new ApexPages.StandardController(opp);
        fruc = new ApprovalProcessPageController();
        fruc.opp.Rebate_Justification__c = 'Approved with rebate';
        PageReference returnURL2 = fruc.approve();

        //Refresh the Opportunity        
        opp=[select id,FCM__c,Channel_Manager__c,Rebate__c, Registration_Status__c from Opportunity where id=:opp.id];
        
        //checkcode error fix
        System.assertEquals(opp.Registration_Status__c, 'Approved');
        
        //For Rejection
        PageReference pageRef2 = Page.ApprovalProcessPage;
        Test.setCurrentPageReference(pageRef2);
        pageRef2.getParameters().put('oppId', opp2.Id);
        pageRef2.getParameters().put('reject','1');
        ApexPages.StandardController sc2 = new ApexPages.StandardController(opp2);
        ApprovalProcessPageController fruc2 = new ApprovalProcessPageController();
        
        PageReference returnURL3 = fruc2.reject();
        Test.stopTest();
        opp2=[select id,FCM__c,Channel_Manager__c,Rebate__c, Registration_Status__c from Opportunity where Id=:opp2.id];
        
        System.assertEquals(opp2.Registration_Status__c, 'Rejected');   
      }
    }
    
    public static testMethod void ApprovalProcess_Negative()
    {
      System.runAs(utilTestClass.getTestRunUser())
      {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        utilTestClass.insertCustomSettings();
        ApprovalHistoryPageControllerTestClass.disableDealMakerCoreSettings();
        Account acc = utilTestClass.CreateAccount('__ test Account');
        insert acc;
        //Create a partner User for that account
        List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,acc.id);
        partner=PartnerUsers[0];
        //Add the User to the chanell mapping table
        // Create 'SalesChannelMgr' User
        //Profile prSCM = [Select Id, Name from profile where id=:PRM_Settings__c.getInstance('Channel manager profile id').Value__c][0]; //SFDC-2573
        Profile prSCM = [Select Id, Name from profile where id=:GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id')][0]; //SFDC-2573
        UserRole roleDVA = [select id, name from UserRole where name='Worldwide'][0];
        User opptySCMOwnerUser = new User(alias = 'scmUsr1', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OpptyOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__mss_owner@akamai.com',profileid = prSCM.Id, UserRoleId = roleDVA.Id );
        insert opptySCMOwnerUser;
        
        //Channel_Mapping__c cm= new Channel_Mapping__c(Name = 'Test Channel Mapping', Partner_Name__c = acc.id, PAE_ID__c = opptySCMOwnerUser.id);
        Channel_Mapping__c cm = utilTestClass.CreateChannelMapping('Test Channel Mapping', acc.Id, opptySCMOwnerUser.Id);
        insert cm;
        
        Opportunity opp = utilTestClass.CreateOpportunity('__Test Opportunity','1-Create');
        opp.Channel_Manager__c = cm.Id;
        opp.End_Customer_Country__c = 'USA';
        opp.End_Customer_State__c = 'NY';
        opp.End_Customer_City__c = 'Buffalo';
        opp.End_Customer_Street_Address__c = 'Line1 \r\n Line2';  
        opp.CloseDate= Date.today();
        opp.Partner_Involved__c = acc.Id;
        opp.AccountId = acc.Id;
        
        system.runAs(Partner)
        {
          Test.startTest();
          insert opp;
          Test.stopTest();  
        }
        
        PageReference pageRef = Page.ApprovalProcessPage;
        Test.setCurrentPageReference(pageRef);
        pageRef.getParameters().put('oppId', opp.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(opp);
        ApprovalProcessPageController fruc = new ApprovalProcessPageController();
        
        //Try to initialize Approval Process without submitting for Approval
        Boolean ret = fruc.getProcessInstanceWorkitem();
        
        System.assertEquals(ret, false);
        
        //Cancel the Approval process and return to Opportunity
        PageReference pr = fruc.cancel();
        
        System.assertEquals(pr.getUrl(), '/'+opp.Id);
      }
    }
    
    public static testmethod void ApprovalProcessPublicSec_Positive()
    {
      System.runAs(utilTestClass.getTestRunUser())
      {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        utilTestClass.insertCustomSettings();
        ApprovalHistoryPageControllerTestClass.disableDealMakerCoreSettings();
        Account acc = utilTestClass.CreateAccount('__ test Account');
        insert acc;
        //Create a partner User for that account
        List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,acc.id);
        partner=PartnerUsers[0];
        //Add the User to the chanell mapping table
        // Create 'SalesChannelMgr' User
        //Profile prSCM = [Select Id, Name from profile where id=:PRM_Settings__c.getInstance('Channel manager profile id').Value__c][0]; //SFDC-2573
        Profile prSCM = [Select Id, Name from profile where id=:GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id')][0]; //SFDC-2573
        UserRole roleDVA = [select id, name from UserRole where name='Worldwide'][0];
        User opptySCMOwnerUser = new User(alias = 'scmUsr1', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OpptyOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__mss_owner@akamai.com',profileid = prSCM.Id, UserRoleId = roleDVA.Id );
        insert opptySCMOwnerUser;
        
        //Channel_Mapping__c cm= new Channel_Mapping__c(Name = 'Test Channel Mapping', Partner_Name__c = acc.id, PAE_ID__c = opptySCMOwnerUser.id);
        Channel_Mapping__c cm = utilTestClass.CreateChannelMapping('Test Channel Mapping', acc.Id, opptySCMOwnerUser.Id);
        cm.Partner_Group__c = 'PUB SEC';
        insert cm;
        
        List<Opportunity> oppList = new List<Opportunity>();
        
        Opportunity opp = utilTestClass.CreateOpportunity('__Test Opportunity','1-Create');
        opp.Channel_Manager__c = cm.Id;
        opp.End_Customer_Country__c = 'USA';
        opp.End_Customer_State__c = 'NY';
        opp.End_Customer_City__c = 'Buffalo';
        opp.End_Customer_Street_Address__c = 'Line1 \r\n Line2';  
        opp.CloseDate= Date.today();
        opp.Partner_Involved__c = acc.Id;
        opp.AccountId = acc.Id;
        opp.Deal_Reg_Account_Status__c='New Account';
        opp.Deal_Reg_Opportunity_Status__c='New Opportunity';
        oppList.add(opp);
        
        Opportunity opp2 = utilTestClass.CreateOpportunity('__Test Opportunity2','1-Create');
        opp2.Channel_Manager__c = cm.Id;
        opp2.End_Customer_Country__c = 'USA';
        opp2.End_Customer_State__c = 'NY';
        opp2.End_Customer_City__c = 'Buffalo';
        opp2.End_Customer_Street_Address__c = 'Line1 \r\n Line2';  
        opp2.CloseDate= Date.today();
        opp2.Partner_Involved__c = acc.Id;
        opp2.AccountId = acc.Id;
        opp2.Deal_Reg_Account_Status__c='New Account';
        opp2.Deal_Reg_Opportunity_Status__c='New Opportunity';
        oppList.add(opp2);
        
        system.runAs(Partner)
        {
          Test.startTest();
          insert oppList;  
        }
        
        //Submit the Opportunity for Approval
        PRM_opportunity.submitForApproval(opp.Id);
        PRM_opportunity.submitForApproval(opp2.Id);
        
        PageReference pageRef = Page.ApprovalProcessPage;
        Test.setCurrentPageReference(pageRef);
        pageRef.getParameters().put('oppId', opp.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(opp);
        ApprovalProcessPageController fruc = new ApprovalProcessPageController();
        
        //Approve the Opportunity without adding Rebate Justification value
        PageReference returnURL = fruc.approve();
        //checkcode error fix
        String url = '/' + opp.Id;
        PageReference assertReturnURL = new PageReference(url);
        system.debug('assertReturnURL: '+assertReturnURL+' returnURL: '+returnURL);
        System.assertEquals(returnURL.getUrl(), assertReturnURL.getUrl());
        
        //Add the Rebate Justificaion value and Approve
        sc = new ApexPages.StandardController(opp);
        fruc = new ApprovalProcessPageController();
        fruc.opp.Rebate_Justification__c = 'Approved with rebate';
        PageReference returnURL2 = fruc.approve();

        //Refresh the Opportunity        
        opp=[select id,FCM__c,Channel_Manager__c,Rebate__c, Registration_Status__c from Opportunity where id=:opp.id];
        //checkcode error fix
        System.assertEquals(opp.Registration_Status__c, 'Approved');
        
        //For Rejection
        PageReference pageRef2 = Page.ApprovalProcessPage;
        Test.setCurrentPageReference(pageRef2);
        pageRef2.getParameters().put('oppId', opp2.Id);
        pageRef2.getParameters().put('reject','1');
        ApexPages.StandardController sc2 = new ApexPages.StandardController(opp2);
        ApprovalProcessPageController fruc2 = new ApprovalProcessPageController();
        
        PageReference returnURL3 = fruc2.reject();
        Test.stopTest();
        opp2=[select id,FCM__c,Channel_Manager__c,Rebate__c, Registration_Status__c from Opportunity where Id=:opp2.id];
        
        System.assertEquals(opp2.Registration_Status__c, 'Rejected');   
      }
    }
    
    public static testMethod void ApprovalProcessPublicSec_Negative()
    { 
      System.runAs(utilTestClass.getTestRunUser())
      {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        utilTestClass.insertCustomSettings();
        ApprovalHistoryPageControllerTestClass.disableDealMakerCoreSettings();
        Account acc = utilTestClass.CreateAccount('__ test Account');
        insert acc;
        //Create a partner User for that account
        List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,acc.id);
        partner=PartnerUsers[0];
        //Add the User to the chanell mapping table
        // Create 'SalesChannelMgr' User
        //Profile prSCM = [Select Id, Name from profile where id=:PRM_Settings__c.getInstance('Channel manager profile id').Value__c][0]; //SFDC-2573
        Profile prSCM = [Select Id, Name from profile where id=:GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id')][0]; //SFDC-2573
        UserRole roleDVA = [select id, name from UserRole where name='Worldwide'][0];
        User opptySCMOwnerUser = new User(alias = 'scmUsr1', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OpptyOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__mss_owner@akamai.com',profileid = prSCM.Id, UserRoleId = roleDVA.Id );
        insert opptySCMOwnerUser;
        
        //Channel_Mapping__c cm= new Channel_Mapping__c(Name = 'Test Channel Mapping', Partner_Name__c = acc.id, PAE_ID__c = opptySCMOwnerUser.id);
        Channel_Mapping__c cm = utilTestClass.CreateChannelMapping('Test Channel Mapping', acc.Id, opptySCMOwnerUser.Id);
        cm.Partner_Group__c = 'PUB SEC';
        insert cm;
        
        Opportunity opp = utilTestClass.CreateOpportunity('__Test Opportunity','1-Create');
        opp.Channel_Manager__c = cm.Id;
        opp.End_Customer_Country__c = 'USA';
        opp.End_Customer_State__c = 'NY';
        opp.End_Customer_City__c = 'Buffalo';
        opp.End_Customer_Street_Address__c = 'Line1 \r\n Line2';  
        opp.CloseDate= Date.today();
        opp.AccountId = acc.Id;
        opp.Partner_Involved__c = acc.Id;
        
        system.runAs(Partner)
        {
          Test.startTest();
          insert opp;
          Test.stopTest();  
        }
        
        PageReference pageRef = Page.ApprovalProcessPage;
        Test.setCurrentPageReference(pageRef);
        pageRef.getParameters().put('oppId', opp.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(opp);
        ApprovalProcessPageController fruc = new ApprovalProcessPageController();
        
        //Try to initialize Approval Process without submitting for Approval
        Boolean ret = fruc.getProcessInstanceWorkitem();
        
        System.assertEquals(ret, false);
        
        //Cancel the Approval process and return to Opportunity
        PageReference pr = fruc.cancel();
        
        System.assertEquals(pr.getUrl(), '/'+opp.Id);
      }
    }
}