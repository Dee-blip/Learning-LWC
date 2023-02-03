@isTest(seeAllData=false)
public with sharing class SF1_Controller_AddPartnerContactTest {
        static testmethod void checkForPartnerAndOwner() {
                Account acc = new Account();
                acc.Name = 'TestABC';
                acc.Vertical__c = 'Gaming';
                acc.Sub_Vertical__c = 'Console Mfs';
                insert acc;

                Opportunity opp = new Opportunity();
                opp.Account = acc;
                opp.AccountId = acc.Id;
                opp.Name = 'OppName';
                opp.Deal_Type__c = 'Direct';
                opp.StageName = '1. Identify Need';
                opp.CloseDate = Date.today();
                opp.CurrencyIsoCode = 'BRL';
                insert opp;

                String returnVal = SF1_Controller_AddPartnerContact.checkForPartnerAndOwner(String.valueOf(opp.Id));

                Opportunity opp2 = new Opportunity();
                opp2.Account = acc;
                opp2.AccountId = acc.Id;
                opp2.Name = 'OppName';
                opp2.Deal_Type__c = 'Direct';
                opp2.StageName = '1. Identify Need';
                opp2.CloseDate = Date.today();
                opp2.CurrencyIsoCode = 'BRL';
                opp2.Partner_Involved__c = acc.Id;
                insert opp2;

                returnVal = SF1_Controller_AddPartnerContact.checkForPartnerAndOwner(String.valueOf(opp2.Id));
        }

        static testmethod void getUserContact() {

        }

        private static User CreateUser(String pUsrAlias, Id profileId, Id roleId) {
                User newUser = new User(alias = pUsrAlias,
                                        email=pUsrAlias+'@akamai.com',
                                        emailencodingkey='UTF-8',
                                        lastname=pUsrAlias,
                                        languagelocalekey='en_US',
                                        localesidkey='en_US',
                                        timezonesidkey='America/Los_Angeles',
                                        username=pUsrAlias+'@akamai.com.tclass',
                                        profileid = profileId,
                                        UserRoleId = roleId );
                return newUser;
        }

        static testmethod void addUserToSalesTeam() {
                Account acc = new Account();
                acc.Name = 'TestABC';
                acc.Vertical__c = 'Gaming';
                acc.Sub_Vertical__c = 'Console Mfs';
                insert acc;

                Opportunity opp = new Opportunity();
                opp.Account = acc;
                opp.AccountId = acc.Id;
                opp.Partner_Involved__c = acc.Id;
                opp.Name = 'OppName';
                opp.Deal_Type__c = 'Direct';
                opp.StageName = '1. Identify Need';
                opp.CloseDate = Date.today();
                opp.CurrencyIsoCode = 'BRL';
                insert opp;

                Map<String, GSM_Settings__mdt>  testcaseCustomSettings = GsmUtilClass.getGSMSettingValue();
                Id salesRepProfileId = [select id from profile where name='Sales - Media'][0].Id;
                String roleName = testcaseCustomSettings.get('User_Role').Value__c;
                Id roleId = [select Id from UserRole where name=:roleName][0].Id;
                System.DEBUG('Role Id: ' + roleId);
                User userObj = CreateUser('TST_OUSR', salesRepProfileId, roleId);
                //insert userObj;

                // String returnVal = SF1_Controller_AddPartnerContact.addUserToSalesTeam(String.valueOf(opp.Id), String.valueOf(userObj.Id));
                String returnVal = SF1_Controller_AddPartnerContact.addUserToSalesTeam(String.valueOf(opp.Id), null);
        }

        static testmethod void isLightning() {
                Boolean returnVal = SF1_Controller_AddPartnerContact.isLightning();
        }
}