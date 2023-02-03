//datacloudcompany record can 't be created inside the test scope, That's y making the class seeALLDATA = TRUE
@isTest(SeeAlldata=false)
public class AdvanceAccountSearchTest { 
    private static Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
    static User dmlUser = new User(id=UserInfo.getUserId());
    
    @testSetup
    static void setupMethod(){
        System.runAs(dmlUser) {
            Test.loadData(globalDescribe.get('AdvanceSearchDataCom__c'), 'CS_AdvanceSearchDataCom');
        }
    }
    
    private static  void testAccount(){
        List<Account> acclist = new List<Account>();
        for(Integer i =0 ; i< 30 ;i++){
        Account acc = new Account();
            if(i < 4){
            acc.Name='tets';
            acc.Website ='www.tets'+i+'.com';
            }else{
                acc.name ='tets'+i;
                acc.Website ='www.tets.com';
            }
            acc.Validation_Override__c = true; 
            acclist.add(acc);
        }     
    }
    
    
     //testmethod to check if there is a record in the system
    static testmethod void testSearch(){
        PageReference pageRef = Page.AdvAccAndConSearch;
        Test.setCurrentPage(pageRef);
        Account acc = new Account();
        ApexPages.StandardController controller = new ApexPages.StandardController(acc);
        AdvAccAndConSearchController con = new  AdvAccAndConSearchController(controller);
        testAccount();
        Test.StartTest();
            con.AccName = 'tets';
            con.exactSearch = false;
            con.searchAccount();
          //  con.getDataWrapper();
        Test.stopTest();
    }
    
    static testmethod void methodForCoverege_1(){ //Only for code coverege
        PageReference pageRef = Page.AdvAccAndConSearch;
        Test.setCurrentPage(pageRef);
        Account acc = utilTestClass.CreateAccount('__Test Account');
        insert acc;
        List<Account> accList = new List<Account>();
        accList.add(acc);
        ApexPages.StandardController controller = new ApexPages.StandardController(acc);
        AdvAccAndConSearchController con = new  AdvAccAndConSearchController(controller);
        Test.StartTest();
        con.AccName = '__Test Account';
        con.exactSearch = false;
        con.AccountDatacom = true;
        con.total_size = 10;
        con.CurrentPageNumber = 1;
        con.total_sizeSalesforce= 10;
        con.CurrentPageNumberSalesforce = 1;
       // con.countries = new set<string>();
        con.nodataFlag = false;
        con.SortedAcclstFull = accList;
        con.getSearchresultFlag();
       // con.getaccListNew();
       // con.getDataWrapper();
        //con.fetchAllAccountFromdataCom();
        con.searchAccount();
        con.sortMapGenerator(accList);
        con.SortAccount();
        con.getSortedAcclst();
        con.generateDynamicQuery('Select Id from Account where', 'www', '__Test', true);
       // con.AddAccountToSalesforce();
        con.AddNewAccount();
        con.getcountryList();
        con.Beginning();
        con.offPrevious();
        con.offNext();
        con.getDisablePrevious();
        con.getDisableNext();
        con.getTotal_size();
        con.getCurrentPageNumber();
        con.getTotalPages();
        con.BeginningSfdc();
        con.offPreviousSfdc();
        con.offNextSfdc();
        con.EndSfdc();
        con.getDisablePreviousSfdc();
        con.getDisableNextSfdc();
        con.getTotal_sizeSfdc();
        con.getCurrentPageNumberSfdc();
        con.getTotalPagesSfdc();
      //  con.finalListToAdd(dc);
        con.End();
       // con.queryPurchasedRecords(null);
       // con.searchRecDunsBasis(con.datacloudCompanyList);
        Test.stopTest();
    }

   
}