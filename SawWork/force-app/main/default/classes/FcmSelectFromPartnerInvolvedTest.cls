/**
 * FCM select from Partner involved Test Class
 * This is a test class for controller class FcmSelectFromPartnerInvolved page
 * History:
 * =========================
 * Developer        Date        Description
 * --------------------------------------------------------------------------------------------------
   Vinayendra T N   01/2011     Created Class
 **/
@isTest
private class FcmSelectFromPartnerInvolvedTest {
    static User partner;
    static User dmlUser = new User(id=UserInfo.getUserId());
    
    static testMethod void FCMSelectPositive() {
        System.runAs(utilTestClass.getTestRunUser())
        {
            utilTestClass.insertCustomSettings();
            ManagedPkgErrorClass.isFromManagedPackage = false;
            //Account acc = CreateAccount('__ Test Account');
            Account acc = utilTestClass.CreateAccount('__ Test Account');
            insert acc;
            //Create a partner User for that account
            List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,acc.id);
            partner=PartnerUsers[0];
            //Add the User to the chanell mapping table
            // Create 'SalesChannelMgr' User
            /*Profile prSCM = [Select Id, Name from profile where id=:PRM_Settings__c.getInstance('Channel manager profile id').Value__c][0];
              UserRole roleDVA = [select id, name from UserRole where name='Worldwide'][0];
            //1st FCM
            User opptySCMOwnerUser = new User(alias = 'scmUsr1', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OpptyOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__mss_owner@akamai.com',profileid = prSCM.Id, UserRoleId = roleDVA.Id );
            insert opptySCMOwnerUser;

            //2nd FCM
            User opptySCMOwnerUser2 = new User(alias = 'scmUsr2', email='salesop2@akamai.com',emailencodingkey='UTF-8', lastname='OpptyOwner2', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__mss_owner2@akamai.com',profileid = prSCM.Id, UserRoleId = roleDVA.Id );
            insert opptySCMOwnerUser2;*/

            User opptySCMOwnerUser;
            User opptySCMOwnerUser2;
            System.runAs(dmlUser) {
                //1st FCM
                //opptySCMOwnerUser = utilTestClass.CreateUserWithProfileId('scmUsr1', 'Worldwide', PRM_Settings__c.getInstance('Channel manager profile id').Value__c); //SFDC-2573
                opptySCMOwnerUser = utilTestClass.CreateUserWithProfileId('scmUsr1', 'Worldwide', GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id')); //SFDC-2573
                insert opptySCMOwnerUser;

                //2nd FCM
                //opptySCMOwnerUser2 = utilTestClass.CreateUserWithProfileId('scmUsr2', 'Worldwide', PRM_Settings__c.getInstance('Channel manager profile id').Value__c); //SFDC-2573
                opptySCMOwnerUser2 = utilTestClass.CreateUserWithProfileId('scmUsr2', 'Worldwide', GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id')); //SFDC-2573
                insert opptySCMOwnerUser2;
                opptySCMOwnerUser2.ManagerId=opptySCMOwnerUser.id;
                update opptySCMOwnerUser2;
            }
            //Channel Mapping for 1st FCM
            //Channel_Mapping__c cm= new Channel_Mapping__c(Name = 'Test Channel Mapping', Partner_Name__c = acc.id, PAE_ID__c = opptySCMOwnerUser.id);
            Channel_Mapping__c cm = utilTestClass.CreateChannelMapping('Test Channel Mapping', acc.Id, opptySCMOwnerUser.Id);
            insert cm;
            //Channel Mapping for 2nd FCM
            //Channel_Mapping__c cm2= new Channel_Mapping__c(Name = 'Test Channel Mapping2', Partner_Name__c = acc.id, PAE_ID__c = opptySCMOwnerUser2.id);
            Channel_Mapping__c cm2 = utilTestClass.CreateChannelMapping('Test Channel Mapping2', acc.Id, opptySCMOwnerUser2.Id);
            insert cm2;

            //Opportunity opp= CreateOpportunity('__Test Opportunity__');
            Opportunity opp = utilTestClass.CreateOpportunity('__Test Opportunity__','1-Create'); 
            opp.End_Customer_Country__c = 'USA';
            opp.End_Customer_State__c = 'NY';
            opp.End_Customer_City__c = 'Buffalo';
            opp.End_Customer_Street_Address__c = 'Line1 \r\n Line2';    
            opp.CloseDate= Date.today();
            opp.Partner_Involved__c = acc.Id;
            system.runAs(Partner)
            {
                Test.startTest();
                insert opp;
            }
            //system.runAs(opptySCMOwnerUser)
            //{
            
            PageReference pageRef = Page.SelectFcmFromPartnerInvolved;
            pageRef.getParameters().put('oppty', opp.id);
            Test.setCurrentPageReference(pageRef);
            PRM_Opportunity.submitForApproval(opp.Id);
            FcmSelectFromPartnerInvolved fsfpi= new FcmSelectFromPartnerInvolved();
            pageRef.getParameters().put('pid', opptySCMOwnerUser2.id);
            Test.setCurrentPageReference(pageRef);
            fsfpi.AddFCM();
            Test.stopTest();
            //}
        }
    }
    static testMethod void FCMSelectNegative() {
        System.runAs(utilTestClass.getTestRunUser())
        {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            utilTestClass.insertCustomSettings();
            //Account acc = CreateAccount('__ Test Account');
            Account acc = utilTestClass.CreateAccount('__ Test Account');
            insert acc;
            //Create a partner User for that account
            List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,acc.id);
            partner=PartnerUsers[0];
            //Add the User to the chanell mapping table
            // Create 'SalesChannelMgr' User
            /*Profile prSCM = [Select Id, Name from profile where id=:PRM_Settings__c.getInstance('Channel manager profile id').Value__c][0];
              UserRole roleDVA = [select id, name from UserRole where name='Worldwide'][0];
            //1st FCM
            User opptySCMOwnerUser = new User(alias = 'scmUsr1', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OpptyOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__mss_owner@akamai.com',profileid = prSCM.Id, UserRoleId = roleDVA.Id );
            insert opptySCMOwnerUser;

            //2nd FCM
            User opptySCMOwnerUser2 = new User(alias = 'scmUsr2', email='salesop2@akamai.com',emailencodingkey='UTF-8', lastname='OpptyOwner2', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__mss_owner2@akamai.com',profileid = prSCM.Id, UserRoleId = roleDVA.Id );
            insert opptySCMOwnerUser2;*/
            User opptySCMOwnerUser;
            User opptySCMOwnerUser2;
            System.runAs(dmlUser) {
                //1st FCM
                //opptySCMOwnerUser = utilTestClass.CreateUserWithProfileId('scmUsr1', 'Worldwide', PRM_Settings__c.getInstance('Channel manager profile id').Value__c); //SFDC-2573
                opptySCMOwnerUser = utilTestClass.CreateUserWithProfileId('scmUsr1', 'Worldwide', GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id')); //SFDC-2573
                insert opptySCMOwnerUser;

                //2nd FCM
                //opptySCMOwnerUser2 = utilTestClass.CreateUserWithProfileId('scmUsr2', 'Worldwide', PRM_Settings__c.getInstance('Channel manager profile id').Value__c); //SFDC-2573
                opptySCMOwnerUser2 = utilTestClass.CreateUserWithProfileId('scmUsr2', 'Worldwide', GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id')); //SFDC-2573
                insert opptySCMOwnerUser2;
                opptySCMOwnerUser2.ManagerId=opptySCMOwnerUser.id;
                update opptySCMOwnerUser2;
            }  
            //Channel Mapping for 1st FCM
            //Channel_Mapping__c cm= new Channel_Mapping__c(Name = 'Test Channel Mapping', Partner_Name__c = acc.id, PAE_ID__c = opptySCMOwnerUser.id);
            Channel_Mapping__c cm = utilTestClass.CreateChannelMapping('Test Channel Mapping', acc.Id, opptySCMOwnerUser.Id);
            insert cm;
            //Channel Mapping for 2nd FCM
            //Channel_Mapping__c cm2= new Channel_Mapping__c(Name = 'Test Channel Mapping2', Partner_Name__c = acc.id, PAE_ID__c = opptySCMOwnerUser2.id);
            Channel_Mapping__c cm2 = utilTestClass.CreateChannelMapping('Test Channel Mapping2', acc.Id, opptySCMOwnerUser2.Id);
            insert cm2;

            //Opportunity opp= CreateOpportunity('__Test Opportunity__');
            Opportunity opp = utilTestClass.CreateOpportunity('__Test Opportunity__','1-Create'); 
            opp.End_Customer_Country__c = 'USA';
            opp.End_Customer_State__c = 'NY';
            opp.End_Customer_City__c = 'Buffalo';
            opp.End_Customer_Street_Address__c = 'Line1 \r\n Line2';    
            opp.CloseDate= Date.today();
            opp.Partner_Involved__c = acc.Id;

            system.runAs(Partner)
            {
                Test.startTest();
                insert opp;
            }
            //system.runAs(opptySCMOwnerUser)
            //{
            
            PageReference pageRef = Page.SelectFcmFromPartnerInvolved;
            pageRef.getParameters().put('oppty', opp.id);
            Test.setCurrentPageReference(pageRef);
            PRM_Opportunity.submitForApproval(opp.Id);
            FcmSelectFromPartnerInvolved fsfpi= new FcmSelectFromPartnerInvolved();
            pageRef.getParameters().put('pid', opptySCMOwnerUser2.id);
            Test.setCurrentPageReference(pageRef);
            fsfpi.cancel();
            pageRef = Page.SelectFcmFromPartnerInvolved;
            Test.setCurrentPageReference(pageRef);
            fsfpi= new FcmSelectFromPartnerInvolved();
            fsfpi.AddFCM();
            Test.stopTest();
            //}
        }
    }
}