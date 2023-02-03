/***

Pramod Kamath           23rd Septmeber     Moving Test Class to campaignProdExtnControllerTest
Ruchika Sharma          CR 2768583 - Online Channel: Change Package Id data type to picklist
***/

//CR 2770464 - rsharma: Marking this class with @isTest annotation, since it is only containing a test method
@isTest
public with sharing class campaignProdExtnControllerTest {

    @isTest(SeeAllData=false)
        static void unitTest()
        {
            System.runAs(utilTestClass.getTestRunUser())
            {

                utilTestClass.insertCustomSettings();

                Campaign_Package__c testpack=new Campaign_Package__c();
                testpack.Name='Testpack';
                //CR 2768583: Ruchika Sharma: commenting reference of Package_Id__c, as data type of this field needs to be changed
                //testpack.Package_Id__c='testpackgid';
                testpack.Is_Valid__c=true;
                insert testpack;        

                Campaign_AkamOnline__c testcamp=new Campaign_AkamOnline__c();
                testcamp.Name='testcamp';
                testcamp.Campaign_Package__c=testpack.Id;
                testcamp.StartDate__c=Date.today();
                testcamp.cms_content_url__c='www.akamai.com';
                insert testcamp;

                Campaign_Product__c testcamprod=new Campaign_Product__c();
                testcamprod.name='Test Product';
                testcamprod.MPID__c='1244';
                testcamprod.Trial_Quantity__c=123;
                testcamprod.Campaign__c=testcamp.id;
                //insert testcamprod;

                //  Campaign_Pricing__c testprice=new Campaign_Pricing__c();
                //  testprice.Name='testprice';
                //   testprice.Campaign_Product__c = testcamprod.Id;
                //      testprice.CurrencyIsoCode ='USD';
                //    testprice.Name = testprice.CurrencyIsoCode;
                //insert testprice;             

                Apexpages.StandardController stdController = new Apexpages.StandardController(testcamprod);
                campaignProdExtnController testcont = new campaignProdExtnController(stdController); 

                String url='/apex/newCampaignProd';
                PageReference pageRef=new PageReference(url);
                pageRef.getParameters().put('id',testcamp.Id);
                test.setCurrentPageReference(pageref);

                testcont.campId=pageRef.getParameters().get('id');
                testcont.campProd=testcamprod;          
                PageReference sPage = testcont.save()  ;  
                testcont.cancel();             
            }

        }



}