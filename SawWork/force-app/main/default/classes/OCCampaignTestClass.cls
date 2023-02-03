@isTest
private class OCCampaignTestClass {

    static testMethod void myUnitTest() {
    System.runAs(utilTestClass.getTestRunUser())
        {
    Campaign_Package__c testocp=new Campaign_Package__c();
        testocp.Name='Test';
        //CR 2768583: Ruchika Sharma: commenting reference of Package_Id__c, as data type of this field needs to be changed
        //testocp.Package_Id__c='tpckid';
        testocp.Is_Valid__c=true;
        insert testocp;   
        
        Campaign_AkamOnline__c testocc=new Campaign_AkamOnline__c();
        testocc.Name='Test';
        testocc.Campaign_Package__c=testocp.id;
        testocc.Product_Type__c='Default';
        testocc.Campaign_Type__c='Default';
        testocc.StartDate__c=Date.today();
         // Sonali Tandon : CR 3333741 :: Remove geography filter from Online channel bulk account search.
       // testocc.Geography__c='EMEA';
        testocc.cms_content_url__c='www.akamai.com';
        insert testocc;      
 
       // testocp = [select id, AKAM_Package_ID__c from Campaign_Package__c where id = :testocp.id];
        //System.assert(testocp.AKAM_Package_ID__c.contains('OCP'));
        
        }
        
        
    }
}