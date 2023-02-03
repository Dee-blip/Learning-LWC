/***

Pramod Kamath Voderbet      Release 3.33        Test Class for OnlineChannelAccountAddController
                                                CR2379747.
                                                
Pramod Kamath Voderbet      Release 3.38        Updated test class                                                
             
Ruchika Sharma              CR 2768583 - Online Channel: Change Package Id data type to picklist                                                
  3.42     
***/
@isTest
//(SeeAllData=true)
private class OnlineChannelAccountAddControllerTest {
    
        private static void init()
    {
        utilTestClass.insertCustomSettings();
    }

    static testMethod void AddOCBulkAccountTest() {
        // TO DO: implement unit test
        //CR 2770464 - rsharma: calling init() to prevent test class from failing (as seeAllData!=true)
        
        System.runAs(utilTestClass.getTestRunUser())
        {
        init();
        Account myacc=utilTestClass.CreateAccount('mytestaccpr');
        myacc.Parent_Division__c='Americas_Americas';
        myacc.Website='www.akamai.com';
        insert myacc;
        
        Campaign_Package__c testpack=new Campaign_Package__c();
        testpack.Name='Testpack';
        //CR 2768583: Ruchika Sharma: commenting reference of Package_Id__c, as data type of this field needs to be changed
        //testpack.Package_Id__c='tpckid';
        testpack.Is_Valid__c=true;
        insert testpack; 
        
        Campaign_AkamOnline__c testcamp=new Campaign_AkamOnline__c();
        testcamp.Name='testcamp';
        testcamp.Campaign_Package__c=testpack.Id;
        testcamp.StartDate__c=Date.today();
        // Sonali Tandon : CR 3333741 :: Remove geography filter from Online channel bulk account search.
        //testcamp.Geography__c='Americas';
        testcamp.cms_content_url__c='www.akamai.com';
        insert testcamp;
        
        
        Campaign_Account__c oca=new Campaign_Account__c();
        oca.Account__c=myacc.Id;
        oca.Campaign_AkamOnline__c=testcamp.Id;
        insert oca;
        
        
        
        //here
        
        //Apexpages.StandardController stdController = new Apexpages.StandardController(testcamprod);
//   campaignProdExtnController testcont = new campaignProdExtnController(stdController); 
        
   OnlineChannelAccountAddController testcont=new OnlineChannelAccountAddController();
        
        String url='/apex/OnlineChannelAccountAdd';
        PageReference pageRef=new PageReference(url);
        pageRef.getParameters().put('id',testcamp.Id);
        pageRef.getParameters().put('geo',testcamp.Geography__c);
         test.setCurrentPageReference(pageref);
         
         testcont.campId=pageRef.getParameters().get('id');
         testcont.getFilterObject();
                 testcont.first();
                 String str= testcont.sortField; 
                Boolean mbool= testcont.hasNext;
                Boolean mbool1=testcont.hasPrevious;
                Integer myint=testcont.pagenumber;
         testcont.last();
         testcont.previous();
         testcont.next();
           testcont.setOcah();
         
          String rUrl = '/' + ApexPages.currentPage().getParameters().get('cId');
            PageReference rPage = new PageReference(rUrl);
            rPage.setRedirect(true);
            
            
            
           testcont.getMyAccounts();
                
         PageReference pr=testcont.save();   
         
          //CR2525466 update : start  
        testcont.getBlacklistAccounts();
        testcont.getBlAccRecordCount();
        testcont.first();
        String sortField= testcont.sortField; 
        Boolean hasNext= testcont.hasNext;
        Boolean hasPrev=testcont.hasPrevious;
        Integer pgNum=testcont.pagenumber;
        testcont.last();
        testcont.previous();
        testcont.next();
        testcont.unBlacklist(); 
        //CR2525466 update : end      
        
         system.assertEquals(rPage.getUrl(),pr.getUrl());
        }
          
    }
}