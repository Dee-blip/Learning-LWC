/*

   Anand Hegde - 1. Removed disabling of existing partner users which used to take a lot of time.
                 2. Made the same account as partner involved instead of creating a new account.
                 3. Inserting only selected custom settings instead of all the custom settings.

                 
 */

@isTest
public class PRMScheduledJobsTestClass
{
    static 
    {
       utilTestClass.insertCustomSettings(new Map<String, String >{ 'PRM_Settings__c'           => 'CS_PRM_Settings', 
                                                                    'GSM_Custom_Settings__c'    => 'CS_GSM_Custom_Settings',
                                                                    'Communities_Settings__c'   => 'CS_Communities_Settings',
                                                                    'Address_Validation_Class_Settings__c' => 'CS_Address_Validation_Class_Settings',
                                                                    'Features_Toggle__c' => 'CS_Features_Toggle',
                                                                    'UserTriggerClassSettings__c' => 'CS_UserTriggerClassSettings',
                                                                    'Environment_Setup__c' => 'CS_Environment_Setup',
                                                                    'MDF_Configurations__c' => 'CS_MDF_Configurations',
                                                                    'Sync_To_Siebel_Fields_Settings__c' => 'CS_Sync_To_Siebel_Fields_Settings'}); 

    }

    static User dmlUser = new User(id=UserInfo.getUserId());



    static testMethod void AddPartnerAdminToSalesTeamTest() 
    {
        
        System.runAs(dmlUser) {
            Account acc = utilTestClass.CreateAccount('__ Test Account');
            insert acc;
            //Create a partner User for that account
            List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,acc.id);
            User Partner=PartnerUsers[0];
            Profile pr=[select id from profile where name='Partner Community Admin'][0];
            Partner.ProfileId=pr.id;
            update Partner;

            Profile prSCM = [Select Id, Name from profile where name='Sales - Partner Account Executive'][0];
            UserRole roleDVA = [select id, name from UserRole where name='Worldwide'][0];
            User opptySCMOwnerUser = new User(alias = 'scmUsr1', email='vinatara@akamai.com',emailencodingkey='UTF-8', lastname='OpptyOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__mss_owner@akamai.com',profileid = prSCM.Id, UserRoleId = roleDVA.Id );
            insert opptySCMOwnerUser;

            Channel_Mapping__c cm= new Channel_Mapping__c(Name = 'Test Channel Mapping', Partner_Name__c = acc.id, PAE_ID__c = opptySCMOwnerUser.id , Partner_SubGroup__c='DM VAR',MDF_Approver__c= opptySCMOwnerUser.id);
            insert cm;

            /*Opportunity opp2=new Opportunity();
              opp2.Name = 'opp 2';
              opp2.StageName = '1-Create';*/
            Opportunity opp2 = utilTestClass.CreateOpportunity('opp 2','1-Create');
            opp2.CloseDate= Date.today();
            opp2.Deal_Type__c='Indirect';
            opp2.Partner_Involved__c=acc.id;
            insert opp2;
            test.startTest();
            PRMScheduledJobs.AddPartnerAdminToSalesTeam();
            test.stopTest();
            Opportunity opp= [select id,Registration_Status__c from Opportunity where id=:opp2.id][0];
            system.assertequals(opp.Registration_Status__c,'Akamai Provided');  
        }
    }

    static testMethod void SendDealRegEmailReminderTest() 
    {
        System.runAs(dmlUser) {
            Map<string, PRM_Settings__c> PRMSettingsMap = PRM_Settings__c.getall();
            Account acc = utilTestClass.CreateAccount('__ Test Account');
            insert acc;
            //Create a partner User for that account
            List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,acc.id);
            User Partner=PartnerUsers[0];
            //Add the User to the chanell mapping table
            // Create 'SalesChannelMgr' User
            //SFDC-2572
            Profile prSCM = [Select Id, Name from profile where id=:GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id')][0];
            UserRole roleDVA = [select id, name from UserRole where name='Worldwide'][0];
            User opptySCMOwnerUser = new User(alias = 'scmUsr1', email='vinatara@akamai.com',emailencodingkey='UTF-8', lastname='OpptyOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__mss_owner@akamai.com',profileid = prSCM.Id, UserRoleId = roleDVA.Id );
            insert opptySCMOwnerUser;

            Channel_Mapping__c cm= new Channel_Mapping__c(Name = 'Test Channel Mapping', Partner_Name__c = acc.id, PAE_ID__c = opptySCMOwnerUser.id , Partner_SubGroup__c='DM VAR',MDF_Approver__c= opptySCMOwnerUser.id);
            insert cm;
            List<Opportunity> opptyList=new List<Opportunity>();

            Opportunity opp = utilTestClass.CreateOpportunity('opp 1','1-Create'); 
            opp.End_Customer_Country__c = 'USA';
            opp.End_Customer_State__c = 'NY';
            opp.End_Customer_City__c = 'Buffalo';
            opp.End_Customer_Street_Address__c = 'Line1 \r\n Line2';
            opp.Partner_Involved__c = acc.Id;   
            opp.CloseDate= Date.today();

            Opportunity opp2 = utilTestClass.CreateOpportunity('opp 2','1-Create');
            opp2.End_Customer_Country__c = 'USA';
            opp2.End_Customer_State__c = 'NY';
            opp2.End_Customer_City__c = 'Buffalo';
            opp2.End_Customer_Street_Address__c = 'Line1 \r\n Line2';   
            opp2.CloseDate= Date.today();
            opp2.Partner_Involved__c = acc.Id;

            opptyList.add(opp);
            opptyList.add(opp2);
            system.runAs(Partner)
            {
                insert opptyList;
            }
            /*system.runAs(Partner)
              {
              insert opp2;
              }*/
            string[] limits = (PRMSettingsMap.get('job#deal time limits').Value__c).split(':');
            integer lowerlimit=integer.valueof(limits[0]);
            integer middlelimit=integer.valueof(limits[1]);
            integer upperlimit=integer.valueof(limits[2]);

            opp.Registration_Status__c=PRMSettingsMap.get('job#deal Registration Status').Value__c;
            opp.Registration_Submitted_Date__c=DateTime.now().addHours(lowerlimit-2);
            //update opp;
            opp2.Registration_Status__c=PRMSettingsMap.get('job#deal Registration Status').Value__c;
            opp2.Registration_Submitted_Date__c=DateTime.now().addHours(middlelimit-2);
            //update opp2;
            update opptyList;

            SFDC_Budget__c fb = utilTestClass.CreateFundBudget(2000);
            fb.Account__c = acc.Id;
            insert fb;

            List<SFDC_MDF__c> frList=new List<SFDC_MDF__c>();
            SFDC_MDF__c fm=new SFDC_MDF__c();
            fm.Name=' FR 1';
            fm.Amount__c=1000;
            fm.Account__c = acc.Id;
            fm.SOE_or_PubSec_Event__c = 'Yes';
            fm.Program_End_Date__c = Date.today().addDays(1);
            SFDC_MDF__c fm2=new SFDC_MDF__c();
            fm2.Name=' FR 2';
            fm2.Amount__c=1000;
            fm2.Account__c = acc.Id;
            fm2.SOE_or_PubSec_Event__c = 'Yes';
            fm2.Program_End_Date__c = Date.today().addDays(1);
            frList.add(fm);
            frList.add(fm2);
            test.startTest();
            system.runAs(Partner)
            {
                insert frList;
            }

            /*system.runAs(Partner)
              {
              insert fm2;
              }*/
            limits = (PRMSettingsMap.get('job#MDF time limits').Value__c).split(':');
            lowerlimit=integer.valueof(limits[0]);
            middlelimit=integer.valueof(limits[1]);
            upperlimit=integer.valueof(limits[2]);

            fm.Status__c=PRMSettingsMap.get('job#MDF Status').Value__c;
            fm.Submitted_Date__c=DateTime.now().addHours(lowerlimit-2);
            //update fm;

            fm2.Status__c=PRMSettingsMap.get('job#MDF Status').Value__c;
            fm2.Submitted_Date__c=DateTime.now().addHours(middlelimit-2);
            //update fm2;
            update frList;
            string result=PRMScheduledJobs.SendDealRegEmailReminder();
            //throw new CustomException('##Final result'+result);
            for(Task tsk : [select id,subject,whatid from Task where 
                    whatid=:opp.id or 
                    whatid=:opp2.id or
                    whatid=:fm.id or
                    whatid=:fm2.id
                    ])
            {
                if(tsk.whatid==opp.id)
                    system.assertequals(tsk.subject,PRMSettingsMap.get('job#deal 24hr task subject').Value__c);
                if(tsk.whatid==opp2.id)
                    system.assertequals(tsk.subject,PRMSettingsMap.get('job#deal 48hr task subject').Value__c);
                if(tsk.whatid==fm.id)
                    system.assertequals(tsk.subject,PRMSettingsMap.get('job#MDF 24hr task subject').Value__c);
                if(tsk.whatid==fm2.id)
                    system.assertequals(tsk.subject,PRMSettingsMap.get('job#MDF 48hr task subject').Value__c);

            }
            test.stopTest();
        }
    }

    static testMethod void PRMAddPartnerToSalesTeamControllerTest() 
    {
        System.runAs(dmlUser) {
            Account acc = utilTestClass.CreateAccount('__TEST acc');
            acc.Website='www.scheduleweb.com';
            insert acc;
            //Create a partner User for that account
            List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,acc.id);
            User partner=PartnerUsers[0];
            //SFDC-2572
            Profile prSCM = [Select Id, Name from profile where id=:GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id')][0];
            UserRole roleDVA = [select id, name from UserRole where name ='Business Operations'][0];
            User opptySCMOwnerUser = new User(alias = 'scmUsr1', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OpptyOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__mss_owner@akamai.com',profileid = prSCM.Id, UserRoleId = roleDVA.Id );
            insert opptySCMOwnerUser;
            Channel_Mapping__c cm= new Channel_Mapping__c(Name = 'Test Channel Mapping', Partner_Name__c = acc.id, PAE_ID__c = opptySCMOwnerUser.id);
            insert cm;
            Test.startTest();
            Opportunity oppty = utilTestClass.CreateOpportunity('Test Oppty','1-Create');
            oppty.Deal_Type__c='Indirect';
            oppty.Partner_Involved__c=acc.id;
            oppty.AccountId=acc.id;
            oppty.CloseDate= Date.today();
            insert oppty;
            PageReference pageRef = Page.PRMAddPartnerToSalesTeam;
            Test.setCurrentPageReference(pageRef);
            pageRef.getParameters().put('pid', partner.id);
            ApexPages.StandardController sc = new ApexPages.StandardController(oppty);
            PRMAddPartnerToSalesTeamController fruc = new PRMAddPartnerToSalesTeamController(sc);

            fruc.setvalue();
            fruc.AddUserAndSendEmail();
            Opportunity oppty1 = utilTestClass.CreateOpportunity('Test Oppty2','1-Create');
            oppty1.CloseDate= Date.today();
            insert oppty1;
            Test.stopTest();
            system.runAs(opptySCMOwnerUser)
            {
                PageReference pageRef2 = Page.PRMAddPartnerToSalesTeam;
                Test.setCurrentPageReference(pageRef2);
                ApexPages.StandardController sc2 = new ApexPages.StandardController(oppty1);
                PRMAddPartnerToSalesTeamController fruc2 = new PRMAddPartnerToSalesTeamController(sc2);
                fruc2.setvalue();
                fruc2.AddUser();
                fruc2.cancel();
            }
        }
    }

}