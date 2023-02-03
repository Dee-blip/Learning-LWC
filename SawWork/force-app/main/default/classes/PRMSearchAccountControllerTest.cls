/**
  PRMSearchAccountControllerTest
    @author : Vinayendra T N <vintara@akamai.com>
    Anand Hegde - upgraded to API 29.0 and seeAllDate=false
*/
@isTest
private class PRMSearchAccountControllerTest {
  static User partner;
  static User dmlUser = new User(id=UserInfo.getUserId());

  static testMethod void PRMSearchAccountControllerTestPositive()
    {
      System.runAs(dmlUser) {
        utilTestClass.insertCustomSettings();
        ManagedPkgErrorClass.isFromManagedPackage = false;

        //Account acc = CreateAccount('__TEST account PRM');
        Account acc = utilTestClass.CreateAccount('__ TEST account PRM');
        acc.Website='www.twebsite.com';
        acc.IsCustomer__c = true;
        insert acc;
        //Account accnew = CreateAccount('__TEST acc PRM');
        Account accnew = utilTestClass.CreateAccount('__ TEST account PbhRM New');
        accnew.Website='www.testwebjjsite.com';
        insert accnew;

        //Create a partner User for that account
        List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,acc.id);
        partner=PartnerUsers[0];
        /*Profile prSCM = [Select Id, Name from profile where id=:PRM_Settings__c.getInstance('Channel manager profile id').Value__c][0];
        UserRole roleDVA = [select id, name from UserRole where name='Worldwide'][0];
        User opptySCMOwnerUser = new User(alias = 'scmUsr1', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OpptyOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__mss_owner@akamai.com',profileid = prSCM.Id, UserRoleId = roleDVA.Id );*/

        //User opptySCMOwnerUser = utilTestClass.CreateUserWithProfileId('scmUsr1', 'Worldwide', PRM_Settings__c.getInstance('Channel manager profile id').Value__c); //SFDC-2573
        User opptySCMOwnerUser = utilTestClass.CreateUserWithProfileId('scmUsr1', 'Worldwide', GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id')); //SFDC-2573
        insert opptySCMOwnerUser;
        //Channel_Mapping__c cm= new Channel_Mapping__c(Name = 'Test Channel Mapping', Partner_Name__c = acc.id, PAE_ID__c = opptySCMOwnerUser.id);
        Channel_Mapping__c cm = utilTestClass.CreateChannelMapping('Test Channel Mapping', acc.Id, opptySCMOwnerUser.Id);
        insert cm;

        /*Opportunity oppty = new Opportunity();
        oppty.Name = 'Test Oppty';
        oppty.StageName = '1-Create';*/
        Opportunity oppty = utilTestClass.CreateOpportunity('Test Oppty','1-Create');
        oppty.CloseDate= Date.today();
        oppty.End_Customer_Country__c='India';
        oppty.Customer_Company_Name__c='__TEST acc PRM';
        oppty.End_Customer_Website__c='www.saiwebsite.com';
        oppty.End_Customer_Street_Address__c='test';
        oppty.End_Customer_City__c='test';
        oppty.End_Customer_State__c='test';
        oppty.End_Customer_Zip_Code__c='56003';
        oppty.Partner_Involved__c = acc.Id;
        Oppty.Deal_Reg_Opportunity_Status__c = 'New Opportunity';
        system.runAs(partner)
          {
            Test.startTest();
            insert oppty;
          }
        OpportunityShare oppsh = null;
        oppsh=PRM_search_account_controller.opptyUpdateShareTable(oppty.id,opptySCMOwnerUser.id,'Edit');
        //for(OpportunityShare oppshare:[select id,OpportunityAccessLevel,UserOrGroupId from OpportunityShare where OpportunityId=:oppty.id and UserOrGroupId=:opptySCMOwnerUser.id])
        //    oppsh=oppshare;
        //if(oppsh!=null)
        //    oppsh.OpportunityAccessLevel='Edit';
        //if(oppsh!=null)
        update oppsh;
        Test.stopTest();
        system.runAs(opptySCMOwnerUser)
          {
            PageReference pageRef = Page.PRM_Search_Account;
            pageRef.getParameters().put('opptyid', oppty.id);
            Test.setCurrentPageReference(pageRef);
            PRM_search_account_controller fpc = new PRM_search_account_controller();
            pageRef.getParameters().put('pid', accnew.id);
            fpc.AddAccount();
          }
      }
    }
  static testMethod void PRMSearchAccountControllerTestCreate() {
    User MarkingUser =[select id from user where profile.name='Marketing - wo Import' and isactive=true limit 1];
    System.runAs(dmlUser) {
      utilTestClass.insertCustomSettings();
      ManagedPkgErrorClass.isFromManagedPackage = false;
      //Account acc = CreateAccount('__TEST account PRM');
      Account acc = utilTestClass.CreateAccount('__ TEST account PRM');
      acc.Website='www.testwebsite.com';
      acc.IsCustomer__c = true;
      insert acc;
      //Account accnew = CreateAccount('__TEST acc PRM');
      Account accnew = utilTestClass.CreateAccount('__ TEST accokjhgunt PRM New');
      accnew.Website='www.tstwsite.com';
      insert accnew;
      //Create a partner User for that account
      List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,acc.id);
      partner=PartnerUsers[0];
      /*Profile prSCM = [Select Id, Name from profile where id=:PRM_Settings__c.getInstance('Channel manager profile id').Value__c][0];
      UserRole roleDVA = [select id, name from UserRole where name ='Business Operations'][0];
      User opptySCMOwnerUser = new User(alias = 'scmUsr1', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OpptyOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__mss_owner@akamai.com',profileid = prSCM.Id, UserRoleId = roleDVA.Id );*/

      //User opptySCMOwnerUser = utilTestClass.CreateUserWithProfileId('scmUsr1', 'Business Operations', PRM_Settings__c.getInstance('Channel manager profile id').Value__c); //SFDC-2573
      User opptySCMOwnerUser = utilTestClass.CreateUserWithProfileId('scmUsr1', 'Business Operations', GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id')); //SFDC-2573
      insert opptySCMOwnerUser;
      /*Account_Reassignment_Rule__c rule2 = new Account_Reassignment_Rule__c();
      rule2.Name = 'TestRule2';
      rule2.Associated_User__c = opptySCMOwnerUser.Id;
      if(featureToggleCustomSettings.get('UserRoleUpdateThroughAssignmentRule').Toggle__c == true)
        rule2.User_Role__c = 'Sales Operations';//roleDVA.Name;*/
      Account_Reassignment_Rule__c rule2 = utilTestClass.CreateAccountReassignmentRule('TestRule2', opptySCMOwnerUser.Id, 'Sales Operations');
      insert rule2;
      Channel_Mapping__c cm = utilTestClass.CreateChannelMapping('Test Channel Mapping', acc.Id, opptySCMOwnerUser.Id);
      //Channel_Mapping__c cm= new Channel_Mapping__c(Name = 'Test Channel Mapping', Partner_Name__c = acc.id, PAE_ID__c = opptySCMOwnerUser.id);
      insert cm;
      /*Opportunity oppty = new Opportunity();
      oppty.Name = 'Test Oppty';
      oppty.StageName = '1-Create';*/

      //CR 2770464 - rsharma: Adding startTest to refresh Governor limits
      Test.startTest();
      Opportunity oppty = utilTestClass.CreateOpportunity('Test Oppty','1-Create');
      oppty.CloseDate= Date.today();
      oppty.End_Customer_Country__c='India';
      oppty.Customer_Company_Name__c='__TEST account PRM';
      oppty.End_Customer_Website__c='www.akaweb.com';
      oppty.End_Customer_Street_Address__c='test';
      oppty.End_Customer_City__c='test';
      oppty.End_Customer_State__c='test';
      oppty.End_Customer_Zip_Code__c='56003';
      oppty.Partner_Involved__c = acc.Id;
      oppty.Deal_Reg_Opportunity_Status__c = 'Existing Opportunity';
      system.runAs(partner)
        {
          insert oppty;
        }
      OpportunityShare oppsh = null;
      for(OpportunityShare oppshare:[select id,OpportunityAccessLevel,UserOrGroupId from OpportunityShare where OpportunityId=:oppty.id and UserOrGroupId=:opptySCMOwnerUser.id])
        oppsh=oppshare;
      if(oppsh!=null)
        oppsh.OpportunityAccessLevel='Edit';
      if(oppsh!=null)
        update oppsh;
      system.runAs(opptySCMOwnerUser)
        {
          PageReference pageRef = Page.PRM_Search_Account;
          pageRef.getParameters().put('opptyid', oppty.id);
          Test.setCurrentPageReference(pageRef);
          PRM_search_account_controller fpc = new PRM_search_account_controller();
          pageRef.getParameters().put('pid', acc.id);
          fpc.CreateMode();
          fpc.allowDuplicate = false;
          fpc.DupAccountCheck();
          fpc.CreateAcc();
          fpc.AddAccount();
        }
        system.runas(MarkingUser){
        PageReference pageRef = Page.PRM_Search_Account;
          pageRef.getParameters().put('opptyid', oppty.id);
          Test.setCurrentPageReference(pageRef);
          PRM_search_account_controller fpc1 = new PRM_search_account_controller();
          pageRef.getParameters().put('pid', acc.id);
          
        fpc1.CreateMode();
        }
      Test.stopTest();
    }
  }

  static testMethod void PRMSearchAccountControllerTestCreateAccount(){

    System.runAs(dmlUser) {
      utilTestClass.insertCustomSettings();
      Account acc = utilTestClass.CreateAccount('__ TEST account PRM 1');
      acc.Website='www.websit.com';
      acc.IsCustomer__c = true;
      acc.BillingState = 'Karnataka';
      acc.Partner_Type__c = 'ADS Partner';
      acc.Partner_status__c = 'Partner';
      insert acc;

      //User opptySCMOwnerUser = utilTestClass.CreateUserWithProfileId('scmUsr1', 'Business Operations', PRM_Settings__c.getInstance('Channel manager profile id').Value__c); //SFDC-2573
      User opptySCMOwnerUser = utilTestClass.CreateUserWithProfileId('scmUsr1', 'Business Operations', GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id')); //SFDC-2573
      insert opptySCMOwnerUser;
      Account_Reassignment_Rule__c rule2 = utilTestClass.CreateAccountReassignmentRule('TestRule2', opptySCMOwnerUser.Id, 'Sales Operations');
      insert rule2;
      Channel_Mapping__c cm = utilTestClass.CreateChannelMapping('Test Channel Mapping', acc.Id, opptySCMOwnerUser.Id);
      //Channel_Mapping__c cm= new Channel_Mapping__c(Name = 'Test Channel Mapping', Partner_Name__c = acc.id, PAE_ID__c = opptySCMOwnerUser.id);
      insert cm;
      Test.startTest();

      system.runAs(opptySCMOwnerUser)
        {
          PageReference pageRef = Page.PRM_Search_Account;
          PRM_search_account_controller fpc = new PRM_search_account_controller();

        }

      Opportunity oppty = utilTestClass.CreateOpportunity('Test Oppty','1-Create');
      oppty.CloseDate= Date.today();
      oppty.End_Customer_Country__c='India';
      oppty.Customer_Company_Name__c='__TEST acchglount PRM 1';
      oppty.End_Customer_Website__c='www.testwjhgebsite.com';
      oppty.End_Customer_Street_Address__c='test';
      oppty.End_Customer_City__c='test';
      oppty.End_Customer_State__c='Karnataka';
      oppty.End_Customer_Zip_Code__c='56003';
      oppty.Partner_Involved__c = acc.Id;
      oppty.Deal_Reg_Opportunity_Status__c = 'Existing Opportunity';
      insert oppty;
      system.runAs(opptySCMOwnerUser)
        {
          PageReference pageRef = Page.PRM_Search_Account;
          pageRef.getParameters().put('opptyid', oppty.id);
          Test.setCurrentPageReference(pageRef);
          PRM_search_account_controller fpc = new PRM_search_account_controller();
          pageRef.getParameters().put('pid', acc.id);
          fpc = new PRM_search_account_controller();
          fpc.CreateMode();
          fpc.allowDuplicate = true;
          fpc.DupAccountCheck();
          fpc.CreateAcc();
          fpc.AddAccount();
        }
      Test.stopTest();
    }

  }
  static testMethod void PRMSearchAccountControllerTestNegtive() {

    System.runAs(dmlUser) {
      utilTestClass.insertCustomSettings();
      ManagedPkgErrorClass.isFromManagedPackage = false;
      //Account acc = CreateAccount('__TEST account PRM');
      Account acc = utilTestClass.CreateAccount('__ TEST account PRM');
      acc.Website='www.testwebsi.com';
      insert acc;
      //Account accnew = CreateAccount('__TEST acc PRM');
      Account accnew = utilTestClass.CreateAccount('__ TEST accont PM New');
      accnew.Website='www.estsit.com';
      insert accnew;
      //Create a partner User for that account
      List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,acc.id);
      partner=PartnerUsers[0];
      /*Profile prSCM = [Select Id, Name from profile where id=:PRM_Settings__c.getInstance('Channel manager profile id').Value__c][0];
      UserRole roleDVA = [select id, name from UserRole where name='Worldwide'][0];
      User opptySCMOwnerUser = new User(alias = 'scmUsr1', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OpptyOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__mss_owner@akamai.com',profileid = prSCM.Id, UserRoleId = roleDVA.Id );*/

      //User opptySCMOwnerUser = utilTestClass.CreateUserWithProfileId('scmUsr1', 'Worldwide', PRM_Settings__c.getInstance('Channel manager profile id').Value__c); //SFDC-2573
      User opptySCMOwnerUser = utilTestClass.CreateUserWithProfileId('scmUsr1', 'Worldwide', GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id')); //SFDC-2573
      insert opptySCMOwnerUser;
      //Channel_Mapping__c cm= new Channel_Mapping__c(Name = 'Test Channel Mapping', Partner_Name__c = acc.id, PAE_ID__c = opptySCMOwnerUser.id);
      Channel_Mapping__c cm = utilTestClass.CreateChannelMapping('Test Channel Mapping', acc.Id, opptySCMOwnerUser.Id);
      insert cm;
      /*Opportunity oppty = new Opportunity();
      oppty.Name = 'Test Oppty';
      oppty.StageName = '1-Create';*/
      Opportunity oppty = utilTestClass.CreateOpportunity('Test Oppty','1-Create');
      oppty.CloseDate= Date.today();
      oppty.End_Customer_Country__c='India';
      oppty.Customer_Company_Name__c='__TEST account PRM';
      oppty.End_Customer_Website__c='www.estweite.com';
      oppty.End_Customer_Street_Address__c='test';
      oppty.End_Customer_City__c='test';
      oppty.End_Customer_State__c='test';
      oppty.End_Customer_Zip_Code__c='560039';
      oppty.Partner_Involved__c = acc.Id;
      test.startTest(); // SFDC-5952
      system.runAs(partner)
        {
          insert oppty;
        }
      system.runAs(opptySCMOwnerUser)
        {
          PageReference pageRef = Page.PRM_Search_Account;
          pageRef.getParameters().put('opptyid', oppty.id);
          Test.setCurrentPageReference(pageRef);
          PRM_search_account_controller fpc = new PRM_search_account_controller();
          pageRef.getParameters().put('pid', acc.id);
          fpc.CreateMode();
          fpc.CancelCreate();
        }
      system.runAs(opptySCMOwnerUser)
        {
          PageReference pageRef = Page.PRM_Search_Account;
          pageRef.getParameters().put('opptyid', oppty.id);
          Test.setCurrentPageReference(pageRef);
          PRM_search_account_controller fpc = new PRM_search_account_controller();
          pageRef.getParameters().put('pid', acc.id);
          fpc.cancel();
        }
      system.runAs(opptySCMOwnerUser)
        {
          PageReference pageRef = Page.PRM_Search_Account;
          Test.setCurrentPageReference(pageRef);
          PRM_search_account_controller fpc = new PRM_search_account_controller();
        }
      test.stopTest(); // SFDC-5952
    }
  }
}