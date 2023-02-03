@isTest(seeAllData=false)
private class L2Q_MDF_DefaultValuesTest {
        static testmethod void getDefaultValues() {

                utilTestClass.insertCustomSettings();

                User partnerSupUser = new User();
                User partnerUser = new User();
                List<User> userRecs = new List<User>();

                /*Account genericAcc =  (Account)new SobjectBuilder(Account.sObjectType)
                              .eagerPopulate()
                              .put(Account.Type, 'Lead')
                              .create()
                              .getRecord();*/

                List<Account> partnerAccounts = SobjectFactory.createPartnerAccounts(1);
                Account accRec =  partnerAccounts.get(0);

              Account genericAcc =new Account();
               genericAcc.Name='Test_Parjhtnerna';
               genericAcc.website='www.TepartnName.com';
               genericAcc.type ='Lead';
               insert genericAcc;

               /* Account accRec = new Account();
               accRec.Name='Test_Partnerna';
               accRec.website='www.TestpartnName.com';
               accRec.Partner_Type__c='ADS Partner';
               accRec.Partner_Status__c='Partner';
               accRec.Partner_Tier__c= 'Gold';
               accRec.Partner_Reach__c= 'Local';
               accRec.IsPartnerCustom__c= true;
              // accRec.IsPartner= true;
               insert accRec;*/

                L2Q_MDF_DefaultValues lmdv = new L2Q_MDF_DefaultValues();

                SFDC_Budget__c fb = utilTestClass.CreateFundBudget(2000);

                fb.Account__c = accRec.Id;
                fb.Validation_Override__c = true;
                insert fb;

                Contact conRec = utilTestClass.CreateContact('Partner Supp Generic Contact','Smith');
                conRec.AccountId=accRec.id;
                conRec.MailingStreet='123 Main Partner';
                conRec.MailingCity='Peoria';
                conRec.MailingState='IL';
                conRec.MailingPostalCode='33333';
                conRec.MobilePhone='3213213210';
                conRec.Fax='3213123210';
                conRec.Email ='partsupsmith@akamai.com';
                conRec.Active_Partner__c=True;
                insert conRec;

                User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

                system.runAs(thisUser){
                        Profile partnerProf = [select id,name from Profile where Name =:GsmUtilClass.getPRMSettingValue('Partner_Admin_Profile')];
                        Profile businessOperations = [Select Id From Profile Where Name = 'Business Operations' LIMIT 1]; //SDFC 7223
                        partnerSupUser = new User(
                                Username='partnersup@akamai.com',
                                Alias = 'prtSUser',
                                Email='partnersup@akamai.com',
                                FirstName='partusr1',
                                LastName='sup1',
                                //ProfileId = '00eG0000000eAyO',
                                ProfileId = businessOperations.id, // SDFC 7223
                                LanguageLocaleKey='en_US',
                                LocaleSidKey='en_US',
                                EmailEncodingKey='UTF-8',
                                TimeZoneSidKey='America/Los_Angeles',
                                //ContactId = conRec.Id,
                                Can_Accept_POA__c=true
                                );

                        partnerUser = new User(
                                Username='partnerUser@akamai.com',
                                Alias = 'prtUser',
                                Email='partnerUser@akamai.com',
                                FirstName='partusr2',
                                LastName='sup2',
                                ProfileId = partnerProf.Id,
                                LanguageLocaleKey='en_US',
                                LocaleSidKey='en_US',
                                EmailEncodingKey='UTF-8',
                                TimeZoneSidKey='America/Los_Angeles',
                                ContactId = conRec.Id,
                                Can_Accept_POA__c=true
                                );


                        userRecs.add(partnerSupUser);
                        userRecs.add(partnerUser);
                        insert userRecs;
                }


                SFDC_MDF__c fundRequest = utilTestClass.CreateFundRequest('New Fund Request Test', 100.10);
                fundRequest.Account__c = accRec.Id;
                fundRequest.CurrencyIsoCode = 'USD';
                fundRequest.Validation_Override__c = true;
                insert fundRequest;

                ApexPages.StandardController fundRequestController = new ApexPages.StandardController(fundRequest);

                L2Q_MDF_DefaultValues tempController = new L2Q_MDF_DefaultValues(fundRequestController);
                ApexPages.currentPage().getParameters().put('CF00NA0000007i3NP_lkid', accRec.Id);
                tempController = new L2Q_MDF_DefaultValues(fundRequestController);
                
                String returnVal = L2Q_MDF_DefaultValues.getDefaultValues('SFDC_MDF__c', '');
                returnVal = L2Q_MDF_DefaultValues.getDefaultValues('SFDC_MDF_Claim__c', '');
                returnVal = L2Q_MDF_DefaultValues.getDefaultValues('SFDC_MDF__c', genericAcc.Id);

                SFDC_MDF_Claim__c fundClaim = UtilTestClass.CreateFundClaim(fundRequest.Id, 10);
                ApexPages.StandardController fundClaimController = new ApexPages.StandardController(fundClaim);
                //SFDC-6038
                ApexPages.currentPage().getParameters().put(GsmUtilClass.getGSMSettingValue('FC_FR_RelationshipId'), fundRequest.Id);
                
                //Covers L2Q_FundRequestFlowClass
                L2Q_FundClaimFlowController tempControllerForFlow = new L2Q_FundClaimFlowController(fundClaimController);
                tempController = new L2Q_MDF_DefaultValues(fundClaimController);

                System.runAs(partnerSupUser) {
                        returnVal = L2Q_MDF_DefaultValues.getDefaultValues('SFDC_MDF__c', '');
                        returnVal = L2Q_MDF_DefaultValues.getDefaultValues('SFDC_MDF_Claim__c', '');
                        returnVal = L2Q_MDF_DefaultValues.getDefaultValues('SFDC_MDF__c', genericAcc.Id);
                        returnVal = L2Q_MDF_DefaultValues.getDefaultValues('SFDC_MDF_Claim__c', genericAcc.Id);
                }
                System.runAs(partnerUser) {
                        returnVal = L2Q_MDF_DefaultValues.getDefaultValues('SFDC_MDF__c', accRec.Id);
                        returnVal = L2Q_MDF_DefaultValues.getDefaultValues('SFDC_MDF_Claim__c', '');
                        returnVal = L2Q_MDF_DefaultValues.getDefaultValues('SFDC_MDF_Claim__c', accRec.Id);

                        SFDC_MDF__c fundRequest2 = utilTestClass.CreateFundRequest('New Fund Request Test', 100.10);
                        fundRequest2.Account__c = accRec.Id;
                        fundRequest2.CurrencyIsoCode = 'USD';
                        fundRequest2.Validation_Override__c = true;
                        insert fundRequest2;

                        returnVal = L2Q_MDF_DefaultValues.getDefaultValues('SFDC_MDF_Claim__c', fundRequest2.Id);
                }
        }
        
        static testmethod void frOnPma(){
            List<Account> partnerAccounts = SobjectFactory.createPartnerAccounts(1);
          /* Account accRec = new Account();
               accRec.Name='Test_Partnjhbverna';
               accRec.website='www.TesvbntpartnName.com';
               accRec.Partner_Type__c='ADS Partner';
               accRec.Partner_Status__c='Partner';
               accRec.Partner_Tier__c= 'Gold';
               accRec.Partner_Reach__c= 'Local';
               accRec.IsPartnerCustom__c= true;
               //accRec.IsPartner= true;
               insert accRec;*/

                Account accRec =  partnerAccounts.get(0);
             SFDC_Channel_Account_Plan__c cap = (SFDC_Channel_Account_Plan__c)new SobjectBuilder(SFDC_Channel_Account_Plan__c.sObjectType)
                .eagerPopulate()
                .put(SFDC_Channel_Account_Plan__c.Partner_Account__c, accRec.id)
                .create()
                .getRecord();

            Partner_Marketing_Plan__c pmp = (Partner_Marketing_Plan__c)new SobjectBuilder(Partner_Marketing_Plan__c.sObjectType)
                .eagerPopulate()
                .put(Partner_Marketing_Plan__c.Business_Plan__c, cap.Id)
                .create()
                .getRecord();

            Partner_Marketing_Activity__c pma = (Partner_Marketing_Activity__c)new SobjectBuilder(Partner_Marketing_Activity__c.sObjectType)
                .eagerPopulate()
                .put(Partner_Marketing_Activity__c.Partner_Marketing_Plan__c, pmp.Id)
                .create()
                .getRecord();

            pmp.Plan_Status__c = 'Approved';
            update pmp;
            SFDC_MDF__c fundRequest = utilTestClass.CreateFundRequest('New Fund Request Test', 100.20);
                

                ApexPages.StandardController fundRequestController = new ApexPages.StandardController(fundRequest);
                L2Q_MDF_DefaultValues tempController = new L2Q_MDF_DefaultValues(fundRequestController);
                ApexPages.currentPage().getParameters().put(GsmUtilClass.getGSMSettingValue('FR_PM_Relationship_Id'), pma.Id);
                tempController = new L2Q_MDF_DefaultValues(fundRequestController);
                
                //Covers L2Q_FundRequestFlowClass
                L2Q_FundRequestFlowClass tempControllerForFlow = new L2Q_FundRequestFlowClass(fundRequestController);

                String returnVal = L2Q_MDF_DefaultValues.getDefaultValues('SFDC_MDF__c', '');

                //fundRequest.Account__c = accRec.Id;
                //fundRequest.CurrencyIsoCode = 'USD';
                //fundRequest.Validation_Override__c = true;
                //insert fundRequest;
                //SFDC_MDF_Claim__c fundClaim = UtilTestClass.CreateFundClaim(fundRequest.Id, 10);
                //ApexPages.StandardController fundClaimController = new ApexPages.StandardController(fundClaim);
                //tempController = new L2Q_MDF_DefaultValues(fundClaimController);
                returnVal = L2Q_MDF_DefaultValues.getDefaultValues('SFDC_MDF_Claim__c', fundRequest.Id);

        }

}