/*
Pramod Kamath           03rd April 2013     TestClass for OnlineChannelProdAdd.(CR 2568594 - Online Channel:Package Creation)

Ruchika Sharma          CR 2768583 - Online Channel: Change Package Id data type to picklist
 */
@isTest
private class OnlineChannelProdAddTest {

  //  @isTest(SeeAllData=true)
  
   private static void init()
    {
        utilTestClass.insertCustomSettings();
    }
static testMethod void unitTest()
    {
        
        System.runAs(utilTestClass.getTestRunUser())
        {
        Campaign_Package__c testpack=new Campaign_Package__c();
        testpack.Name='Testpack';
        //CR 2768583: Ruchika Sharma: commenting reference of Package_Id__c, as data type of this field needs to be changed
       // testpack.Package_Id__c='testid';
        testpack.Is_Valid__c=true;
        insert testpack;        
            
 
        
        Online_Channel_Package_Product__c testcamprod=new Online_Channel_Package_Product__c();
        testcamprod.name='Test Product';
        testcamprod.Trial_Quantity__c=123;
        testcamprod.Online_Channel_Package__c=testpack.id;
        
            
        
        Apexpages.StandardController stdController = new Apexpages.StandardController(testcamprod);
   		OnlineChannelProdAdd testcont = new OnlineChannelProdAdd(stdController); 
        
        String url='/apex/OnlineChannelProductAdd';
        String testurl='/'+String.valueOf(testpack.id);
        PageReference testpageRef=new PageReference(testurl);
        
        PageReference pageRef=new PageReference(url);
        pageRef.getParameters().put('pkgId',testpack.Id);
         test.setCurrentPageReference(pageref);
         
         testcont.pkgId=pageRef.getParameters().get('pkgId');
         testcont.campProd=testcamprod;          
         PageReference sPage = testcont.save()  ;  
         testcont.cancel();
         system.assertEquals(spage.getUrl(), testpageRef.getUrl())  ;           
        }
               
            }
            
            
            static testMethod void pricetest()
            {
                  System.runAs(utilTestClass.getTestRunUser())
                  {
        Campaign_Package__c testpack=new Campaign_Package__c();
        testpack.Name='Testpack';
        //CR 2768583: Ruchika Sharma: commenting reference of Package_Id__c, as data type of this field needs to be changed
       // testpack.Package_Id__c='testid';
        testpack.Is_Valid__c=true;
        insert testpack;        
            
 
        
        Online_Channel_Package_Product__c testcamprod=new Online_Channel_Package_Product__c();
        testcamprod.name='Test Product';
        testcamprod.Trial_Quantity__c=123;
        testcamprod.Online_Channel_Package__c=testpack.id;
        insert testcamprod;
        
        
        Online_Channel_Package_Pricing__c  testprice=new Online_Channel_Package_Pricing__c();
        testprice.Name='Testpricename';
        testprice.Online_Channel_Package_Product__c=testcamprod.id;
        insert testprice;
            
            
            
            }
            
    }
    
}