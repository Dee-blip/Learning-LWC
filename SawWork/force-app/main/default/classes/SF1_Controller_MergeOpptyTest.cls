@isTest(seeAllData=false)
public with sharing class SF1_Controller_MergeOpptyTest {
        static testmethod void getOpportunityRecord() {
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

                Opportunity returnVal = SF1_Controller_MergeOppty.getOpportunityRecord(String.valueOf(opp.Id));
                // System.AssertEquals(Opportunity:{Id=0062F000003dFY4QAM, Name=OppName, RecordTypeId=012A0000000CvQLIA0, AccountId=0012F00000Cpc6WQAR, StageName=1. Identify Need, AKAM_Opportunity_ID__c=F-OP-1836227}, returnVal);
        }

        static testmethod void getListOfOpportunities() {
                Account acc = new Account();
                acc.Name = 'TestABC';
                acc.Vertical__c = 'Gaming';
                acc.Sub_Vertical__c = 'Console Mfs';
                insert acc;

                List<Opportunity> returnVal = SF1_Controller_MergeOppty.getListOfOpportunities(String.valueOf(acc.Id));
                // System.AssertEquals('()', returnVal);
        }

        static testmethod void getListOfAQLOpportunities() {
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

                List<Opportunity> returnVal = SF1_Controller_MergeOppty.getListOfAQLOpportunities(String.valueOf(opp.Name));
                // System.AssertEquals('()', returnVal);
        }

        static testmethod void updateOpportunity() {
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

                Opportunity opp2 = new Opportunity();
                opp2.Account = acc;
                opp2.AccountId = acc.Id;
                opp2.Partner_Involved__c = acc.Id;
                opp2.Name = 'OppName';
                opp2.Deal_Type__c = 'Direct';
                opp2.StageName = '1. Identify Need';
                opp2.CloseDate = Date.today();
                opp2.CurrencyIsoCode = 'BRL';
                insert opp2;

                Opportunity opp3 = new Opportunity();
                opp3.Account = acc;
                opp3.AccountId = acc.Id;
                opp3.Partner_Involved__c = acc.Id;
                opp3.Name = 'OppName';
                opp3.Deal_Type__c = 'Direct';
                opp3.StageName = '1. Identify Need';
                opp3.CloseDate = Date.today();
                opp3.CurrencyIsoCode = 'BRL';
                insert opp3;

                List<Id> listId = new List<Id>();
                listId.add(opp.Id);
                listId.add(opp2.Id);

                String strJson = JSON.serialize(listId);

                String rtrMsg = SF1_Controller_MergeOppty.updateOpportunity(strJson, opp3);
                System.AssertEquals('', rtrMsg);

        }

        static testmethod void getDuplicateOpportunityError() {
                String str = SF1_Controller_MergeOppty.getDuplicateOpportunityError();
                System.AssertEquals('No Duplicate Opportunity Found', str);
        }

        static testmethod void isLightning() {
                Boolean retMsg = SF1_Controller_MergeOppty.isLightning();
                System.AssertEquals(false, retMsg);
        }
}