@isTest
public class EBCRequestDetailControllerTest{
    
    static{
        utilTestClass.insertCustomSettings();
    }
    
    public static opportunity OpportunityCreate(Id AccId, String pOpptyName, String pStageName ){
        Opportunity opp = new Opportunity();
        opp.Name = pOpptyName;
        opp.StageName = pStageName;
        return opp;
    }
    
    public class OpportunityWrapper{
        public Opportunity opp{get; set;}
        public Boolean CheckBox{get; set;}
    }
    
    static testmethod void testPossitiveEBCDetail() {
        List<OpportunityWrapper> wrapperList;
        Account acc=utilTestClass.CreateAccount('Test acc__1');    
        insert acc;
        
        Opportunity opp = EBCRequestDetailControllerTest.OpportunityCreate(acc.id,'TestOppty','0 Plan');
        opp.Closedate = Date.today();
        insert opp;
     
         EBC_Request__c newEBCRequest = new EBC_Request__c();
         newEBCRequest.Location_of_visit__c = 'Zurich';
         newEBCRequest.Pre_Brief_Call__c = Date.today();
         newEBCRequest.Associated_Account__c = acc.Id;
         insert newEBCRequest;
         Test.startTest();
             PageReference ref = Page.EBCdetailCustomNewPage;
             test.setCurrentpage(ref);
             EBC_Request_Detail__c reqDetail = new EBC_Request_Detail__c(EBC_Request__c = newEBCRequest.Id);
             ApexPages.StandardController stdcontroller = new ApexPages.StandardController(reqDetail);
             EBCRequestDetailController ebcController = new EBCRequestDetailController(stdcontroller);
             ebcController.getOpptyWrapperList();
             ebcController.saveOppty();
          Test.stopTest();
         
  }

}