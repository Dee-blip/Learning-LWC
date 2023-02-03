/**
 * FCM selection page controller Test Class
 * This is a Test calss for FCM selection page
 * History:
 * =========================
 * Developer        Date        Description
 * --------------------------------------------------------------------------------------------------
   Vinayendra T N   01/2011     Created Class
 **/
@isTest(seeAllData=false)
private class FCMPageControllerTestClass 
{
    static User partner;
    static User dmlUser = new User(id=UserInfo.getUserId());
    private static Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
    @testSetup static void insertCustomSettings() 
    {
        System.runAs(dmlUser) 
        {
            //utilTestClass.insertCustomSettings();
            Test.loadData(globalDescribe.get('Communities_Settings__c'), 'CS_Communities_Settings');
            Test.loadData(globalDescribe.get('GSM_Custom_Settings__c'), 'CS_GSM_Custom_Settings');
            Test.loadData(globalDescribe.get('PRM_Settings__c'), 'CS_PRM_Settings');
        }
    }


    private static Opportunity refreshOpportunity(String opptyId)
    {
        return [select id, FCM__c from Opportunity where id=:opptyId][0];
    }

    static testMethod void FCMPagePositive() 
    {
        System.runAs(dmlUser) {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            //Account acc = CreateAccount('__ Test Account');
            Account acc = utilTestClass.CreateAccount('__ Test Account');
            insert acc;
            //Create a partner User for that account
            List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,acc.id);
            partner=PartnerUsers[0];

            User opptySCMOwnerUser;
            User opptySCMOwnerUser2;

            //opptySCMOwnerUser = utilTestClass.CreateUserWithProfileId('scmUsr1', 'Worldwide', PRM_Settings__c.getInstance('Channel manager profile id').Value__c); //SFDC-2573
            opptySCMOwnerUser = utilTestClass.CreateUserWithProfileId('scmUsr1', 'Worldwide', GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id')); //SFDC-2573
            insert opptySCMOwnerUser;

            //2nd FCM
            //opptySCMOwnerUser2 = utilTestClass.CreateUserWithProfileId('scmUsr2', 'Worldwide', PRM_Settings__c.getInstance('Channel manager profile id').Value__c); //SFDC-2573
            opptySCMOwnerUser2 = utilTestClass.CreateUserWithProfileId('scmUsr2', 'Worldwide', GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id')); //SFDC-2573
            insert opptySCMOwnerUser2;
            Channel_Mapping__c cm = utilTestClass.CreateChannelMapping('Test Channel Mapping', acc.Id, opptySCMOwnerUser.Id);
            insert cm;
            Channel_Mapping__c cm2 = utilTestClass.CreateChannelMapping('Test Channel Mapping2', acc.Id, opptySCMOwnerUser2.Id);
            insert cm2;
            Opportunity opp = utilTestClass.CreateOpportunity('__Test Opportunity__','1-Create');
            opp.End_Customer_Country__c = 'USA';
            opp.End_Customer_State__c = 'NY';
            opp.End_Customer_City__c = 'Buffalo';
            opp.End_Customer_Street_Address__c = 'Line1 \r\n Line2';
            opp.Partner_Involved__c = acc.Id;
            opp.CloseDate= Date.today();

            SFDC_Budget__c fb = utilTestClass.CreateFundBudget(2000);
            fb.Account__c = acc.Id; 

            SFDC_MDF__c Fr = utilTestClass.CreateFundRequest('__ Fund Request__',1000);
            fr.Account__c = acc.Id;

            system.runAs(Partner)
            {
                insert opp; 
                Test.startTest();
                PageReference pageRef = Page.FCMselectionpage;
                pageRef.getParameters().put('oppty', opp.id);
                Test.setCurrentPageReference(pageRef);
                FCM_page_controller fpc = new FCM_page_controller();
                fpc.init();
                fpc.getItems();
                fpc.checkForNoFCM();
                fpc.setCountry(opptySCMOwnerUser.id);
                fpc.getCountry();
                fpc.updateoppty();
                insert fb;
                insert Fr;
                pageRef = Page.FCMselectionpage;
                pageRef.getParameters().put('fr', Fr.id);
                Test.setCurrentPageReference(pageRef);
                fpc = new FCM_page_controller();
                fpc.init();
                fpc.getItems();
                fpc.checkForNoFCM();
                fpc.setCountry(opptySCMOwnerUser.id);
                fpc.getCountry();
                fpc.updateoppty();
                Test.stopTest();
            }
        }      
    }

    static testMethod void FCMPageNegative() 
    {
        System.runAs(dmlUser) {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            //Account acc = CreateAccount('__ Test Account');
            Account acc = utilTestClass.CreateAccount('__ Test Account');
            insert acc;
            //Create a partner User for that account
            List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,acc.id);
            partner=PartnerUsers[0];
            //Add the User to the chanell mapping table

            //Opportunity opp= CreateOpportunity('__Test Opportunity__');
            Opportunity opp = utilTestClass.CreateOpportunity('__Test Opportunity__','1-Create');
            opp.End_Customer_Country__c = 'USA';
            opp.End_Customer_State__c = 'NY';
            opp.End_Customer_City__c = 'Buffalo';
            opp.End_Customer_Street_Address__c = 'Line1 \r\n Line2';    
            opp.CloseDate= Date.today();
            opp.Partner_Involved__c = acc.Id;

            SFDC_Budget__c fb = utilTestClass.CreateFundBudget(2000);
            fb.Account__c = acc.Id; 

            SFDC_MDF__c Fr = utilTestClass.CreateFundRequest('__ Fund Request__',1000);
            fr.Account__c = acc.Id;

            system.runAs(Partner)
            {
                insert opp; 
                Test.startTest();
                PageReference pageRef = Page.FCMselectionpage;
                pageRef.getParameters().put('oppty', opp.id);
                Test.setCurrentPageReference(pageRef);
                FCM_page_controller fpc = new FCM_page_controller();
                fpc.init();
                fpc.getItems();
                fpc.checkForNoFCM();
                insert fb;
                insert Fr;
                pageRef = Page.FCMselectionpage;
                pageRef.getParameters().put('fr', Fr.id);
                Test.setCurrentPageReference(pageRef);
                fpc = new FCM_page_controller();
                fpc.init();
                fpc.getItems();
                fpc.checkForNoFCM();
                Test.stopTest();
            }
        }
    }

    static testMethod void FCMPageNegative2() 
    {
        System.runAs(dmlUser) 
        {
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

            SFDC_Budget__c fb = utilTestClass.CreateFundBudget(2000);
            fb.Account__c = acc.Id; 

            SFDC_MDF__c Fr = utilTestClass.CreateFundRequest('__ Fund Request__',1000);
            fr.Account__c = acc.Id;

            system.runAs(Partner)
            {
                Test.startTest();
                insert opp; 
                PageReference pageRef = Page.FCMselectionpage;
                pageRef.getParameters().put('oppty', opp.id);
                Test.setCurrentPageReference(pageRef);
                FCM_page_controller fpc = new FCM_page_controller();
                fpc.init();
                fpc.getItems();
                fpc.checkForNoFCM();
                fpc.setCountry(opptySCMOwnerUser.id);
                fpc.getCountry();
                fpc.cancel();
                fpc.getOppty();
                insert fb;
                insert Fr;
                pageRef = Page.FCMselectionpage;
                pageRef.getParameters().put('fr', Fr.id);
                Test.setCurrentPageReference(pageRef);
                fpc = new FCM_page_controller();
                fpc.init();
                fpc.getItems();
                fpc.checkForNoFCM();
                fpc.setCountry(opptySCMOwnerUser2.id);
                fpc.getCountry();
                fpc.updateoppty();
                Test.stopTest();
            }
        }
    }

    static testMethod void FCMPageNegative3() 
    {
        System.runAs(dmlUser) 
        {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            //Account acc = CreateAccount('__ Test Account');
            Account acc = utilTestClass.CreateAccount('__ Test Account');
            insert acc;
            //Create a partner User for that account
            List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,acc.id);
            partner=PartnerUsers[0];

            //Opportunity opp= CreateOpportunity('__Test Opportunity__');
            Opportunity opp = utilTestClass.CreateOpportunity('__Test Opportunity__','1-Create');
            opp.End_Customer_Country__c = 'USA';
            opp.End_Customer_State__c = 'NY';
            opp.End_Customer_City__c = 'Buffalo';
            opp.End_Customer_Street_Address__c = 'Line1 \r\n Line2';    
            opp.CloseDate= Date.today();
            opp.Partner_Involved__c = acc.Id;

            SFDC_Budget__c fb = utilTestClass.CreateFundBudget(2000);
            fb.Account__c = acc.Id; 

            SFDC_MDF__c Fr = utilTestClass.CreateFundRequest('__ Fund Request__',1000);
            fr.Account__c = acc.Id;

            system.runAs(Partner)
            {
                insert opp; 
                Test.startTest();
                // No id
                PageReference pageRef = Page.FCMselectionpage;
                Test.setCurrentPageReference(pageRef);
                FCM_page_controller fpc = new FCM_page_controller();
                fpc.init();
                fpc.cancel();
                fpc.updateoppty();
                fpc.checkForNoFCM();
                fpc.setCountry('54321');
                fpc.updateoppty();
                fpc.cancel();
                // wrong Oppty Id
                pageRef = Page.FCMselectionpage;
                pageRef.getParameters().put('oppty', '123456789');
                fpc = new FCM_page_controller();
                fpc.init();
                fpc.setCountry('54321');
                fpc.updateoppty();
                fpc.cancel();
                insert fb;
                insert Fr;
                // wrong fund request id
                pageRef = Page.FCMselectionpage;
                pageRef.getParameters().put('fr', '123456789');
                fpc = new FCM_page_controller();
                fpc.init();
                fpc.setCountry('54321');
                fpc.updateoppty();
                fpc.cancel();
                Test.stopTest();
            }
        }
    }

    static testMethod void verifyPAEAssignmentOnIDontKnowSelection()
    {
        System.runAs(dmlUser) {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            //Account acc = CreateAccount('__ Test Account');
            Account acc = utilTestClass.CreateAccount('__ Test Account');
            insert acc;
            //Create a partner User for that account
            List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,acc.id);
            partner=PartnerUsers[0];
            User opptySCMOwnerUser;
            User opptySCMOwnerUser2;

            //opptySCMOwnerUser = utilTestClass.CreateUserWithProfileId('scmUsr1', 'Worldwide', PRM_Settings__c.getInstance('Channel manager profile id').Value__c); //SFDC-2573
            opptySCMOwnerUser = utilTestClass.CreateUserWithProfileId('scmUsr1', 'Worldwide', GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id')); //SFDC-2573
            insert opptySCMOwnerUser;

            //2nd FCM
            //opptySCMOwnerUser2 = utilTestClass.CreateUserWithProfileId('scmUsr2', 'Worldwide', PRM_Settings__c.getInstance('Channel manager profile id').Value__c); //SFDC-2573
            opptySCMOwnerUser2 = utilTestClass.CreateUserWithProfileId('scmUsr2', 'Worldwide', GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id')); //SFDC-2573
            insert opptySCMOwnerUser2;

            //opptySCMOwnerUser2.IsActive = true;
            //update opptySCMOwnerUser2;

            Channel_Mapping__c cm = utilTestClass.CreateChannelMapping('Test Channel Mapping', acc.Id, opptySCMOwnerUser.Id);
            cm.Master_Channel_Mapping__c=false;
            insert cm;
            Channel_Mapping__c cm2 = utilTestClass.CreateChannelMapping('Test Channel Mapping2', acc.Id, opptySCMOwnerUser2.Id);
            cm2.Master_Channel_Mapping__c=true;
            cm2.Active__c = true;
            cm2.Temp_PAE__c=null ;
            cm2.Partner_Name__c = acc.Id;
            cm2.PAE_ID__c = opptySCMOwnerUser2.Id; 
            cm2.MDF_Approver__c = opptySCMOwnerUser2.Id;
            insert cm2;

            Opportunity opp = utilTestClass.CreateOpportunity('__Test Opportunity__','1-Create');
            opp.End_Customer_Country__c = 'USA';
            opp.End_Customer_State__c = 'NY';
            opp.End_Customer_City__c = 'Buffalo';
            opp.End_Customer_Street_Address__c = 'Line1 \r\n Line2';
            opp.Partner_Involved__c = acc.Id;
            opp.CloseDate= Date.today();
            
            SFDC_Budget__c fb = utilTestClass.CreateFundBudget(2000);
            fb.Account__c = acc.Id; 

            SFDC_MDF__c Fr = utilTestClass.CreateFundRequest('__ Fund Request__',1000);
            fr.Account__c = acc.Id;

            system.runAs(dmlUser)
            {
                insert opp;
                Test.startTest();
                PageReference pageRef = Page.FCMselectionpage;
                pageRef.getParameters().put('oppty', opp.id);
                Test.setCurrentPageReference(pageRef);
                FCM_page_controller fpc = new FCM_page_controller();
                fpc.init();
                fpc.getItems();
                fpc.fcm_selected = 'NONE';
                /* fpc.checkForNoFCM(); */
                /* fpc.setCountry(opptySCMOwnerUser.id); */
                /* fpc.getCountry(); */
                fpc.updateoppty();
                
                /* Start of code coverage */
                insert fb;
                insert Fr;
                pageRef = Page.FCMselectionpage;
                pageRef.getParameters().put('fr', Fr.id);
                Test.setCurrentPageReference(pageRef);
                fpc = new FCM_page_controller();
                fpc.init();
                fpc.getItems();
                fpc.fcm_selected = 'NONE';
                fpc.checkForNoFCM();
                fpc.setCountry(opptySCMOwnerUser2.id);
                fpc.getCountry();
                fpc.updateoppty();
                /* End of code coverage */
                
                Test.stopTest();
                opp = refreshOpportunity(opp.Id);
                // FCM should have master channel mapping PAE
                //System.assertEquals(opp.FCM__c, opptySCMOwnerUser2.Id); //Commented by Vivek since (PAE_ID__r.IsActive = true) was not satisfying so assertion was failing.
            }
        }
    }
    static testMethod void assignMasterChannelMappingTestMethod1() 
    {
        System.runAs(dmlUser) {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            //Account acc = CreateAccount('__ Test Account');
            Account acc = utilTestClass.CreateAccount('__ Test Account');
            insert acc;
            //Create a partner User for that account
            List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,acc.id);
            partner=PartnerUsers[0];

            User opptySCMOwnerUser;
            User opptySCMOwnerUser2;

            //opptySCMOwnerUser = utilTestClass.CreateUserWithProfileId('scmUsr1', 'Worldwide', PRM_Settings__c.getInstance('Channel manager profile id').Value__c); //SFDC-2573
            opptySCMOwnerUser = utilTestClass.CreateUserWithProfileId('scmUsr1', 'Worldwide', GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id')); //SFDC-2573
            insert opptySCMOwnerUser;

            //2nd FCM
            //opptySCMOwnerUser2 = utilTestClass.CreateUserWithProfileId('scmUsr2', 'Worldwide', PRM_Settings__c.getInstance('Channel manager profile id').Value__c); //SFDC-2573
            opptySCMOwnerUser2 = utilTestClass.CreateUserWithProfileId('scmUsr2', 'Worldwide', GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id')); //SFDC-2573
            insert opptySCMOwnerUser2;
            Channel_Mapping__c cm = utilTestClass.CreateChannelMapping('Test Channel Mapping', acc.Id, opptySCMOwnerUser.Id);
            cm.Active__c = true;
            cm.Temp_PAE__c=null ;
            cm.Partner_Name__c = acc.Id;
            cm.Master_Channel_Mapping__c=true ;
            cm.PAE_ID__c = opptySCMOwnerUser2.Id; 
            cm.MDF_Approver__c = opptySCMOwnerUser2.Id;

            insert cm;
            Channel_Mapping__c cm2 = utilTestClass.CreateChannelMapping('Test Channel Mapping2', acc.Id, opptySCMOwnerUser2.Id);
            insert cm2;
            Opportunity opp = utilTestClass.CreateOpportunity('__Test Opportunity__','1-Create');
            opp.End_Customer_Country__c = 'USA';
            opp.End_Customer_State__c = 'NY';
            opp.End_Customer_City__c = 'Buffalo';
            opp.End_Customer_Street_Address__c = 'Line1 \r\n Line2';
            opp.Partner_Involved__c = acc.Id;
            opp.CloseDate= Date.today();

            SFDC_Budget__c fb = utilTestClass.CreateFundBudget(2000);
            fb.Account__c = acc.Id; 

            SFDC_MDF__c Fr = utilTestClass.CreateFundRequest('__ Fund Request__',1000);
            fr.Account__c = acc.Id;

            system.runAs(Partner)
            {
                insert opp; 
                Test.startTest();
                insert fb;
                insert Fr;
                FCM_page_controller fpc = new FCM_page_controller();
                fpc.init();
                FCM_page_controller.assignMasterChannelMapping(fr.Id);
                
                
                Test.stopTest();
            }
        }      
    }

    static testMethod void assignMasterChannelMappingTestMethod2() 
    {
        System.runAs(dmlUser) {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            //Account acc = CreateAccount('__ Test Account');
            Account acc = utilTestClass.CreateAccount('__ Test Account');
            insert acc;
            //Create a partner User for that account
            List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,acc.id);
            partner=PartnerUsers[0];

            User opptySCMOwnerUser;
            User opptySCMOwnerUser2;

            //opptySCMOwnerUser = utilTestClass.CreateUserWithProfileId('scmUsr1', 'Worldwide', PRM_Settings__c.getInstance('Channel manager profile id').Value__c); //SFDC-2573
            opptySCMOwnerUser = utilTestClass.CreateUserWithProfileId('scmUsr1', 'Worldwide', GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id')); //SFDC-2573
            insert opptySCMOwnerUser;

            //2nd FCM
            //opptySCMOwnerUser2 = utilTestClass.CreateUserWithProfileId('scmUsr2', 'Worldwide', PRM_Settings__c.getInstance('Channel manager profile id').Value__c); //SFDC-2573
            opptySCMOwnerUser2 = utilTestClass.CreateUserWithProfileId('scmUsr2', 'Worldwide', GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id')); //SFDC-2573
            insert opptySCMOwnerUser2;
            Channel_Mapping__c cm = utilTestClass.CreateChannelMapping('Test Channel Mapping', acc.Id, opptySCMOwnerUser.Id);
            cm.Active__c = true;
            cm.Temp_PAE__c=null ;
            cm.Partner_Name__c = acc.Id;
            cm.Master_Channel_Mapping__c=False ;
            cm.PAE_ID__c = opptySCMOwnerUser2.Id; 
            cm.MDF_Approver__c = opptySCMOwnerUser2.Id;

            insert cm;
            Channel_Mapping__c cm2 = utilTestClass.CreateChannelMapping('Test Channel Mapping2', acc.Id, opptySCMOwnerUser2.Id);
            insert cm2;
            Opportunity opp = utilTestClass.CreateOpportunity('__Test Opportunity__','1-Create');
            opp.End_Customer_Country__c = 'USA';
            opp.End_Customer_State__c = 'NY';
            opp.End_Customer_City__c = 'Buffalo';
            opp.End_Customer_Street_Address__c = 'Line1 \r\n Line2';
            opp.Partner_Involved__c = acc.Id;
            opp.CloseDate= Date.today();

            SFDC_Budget__c fb = utilTestClass.CreateFundBudget(2000);
            fb.Account__c = acc.Id; 

            SFDC_MDF__c Fr = utilTestClass.CreateFundRequest('__ Fund Request__',1000);
            fr.Account__c = acc.Id;
        

            system.runAs(Partner)
            {
                insert opp; 
                Test.startTest();
                insert fb;
                insert Fr;
                FCM_page_controller fpc = new FCM_page_controller();
                fpc.init();
                FCM_page_controller.assignMasterChannelMapping(fr.Id);
                
                
                Test.stopTest();
            }
        }      
    }
}