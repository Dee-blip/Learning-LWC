@isTest(seeAllData=false)
public class SF1_LocateAccountControllerTest {
static User dmlUser = new User(id = UserInfo.getUserId());
@TestSetup
static void intializeData()
{
  utilTestClass.insertCustomSettings();
  List<Account> accList = new List<Account>();
  Account acc = utilTestClass.CreateAccount('__Test Account');
  acc.website='www.indi.com';
  acc.Vertical__c = 'Commerce';
  acc.Sub_Vertical__c = 'Commerce - Other'; 
  accList.add(acc);   
  
  Account accSub = utilTestClass.CreateAccount('__Test Acc01');
  accSub.Partner_Type__c = 'Sub-Reseller';
  accSub.website='www.isampledi.com';  
  accSub.Vertical__c = 'Commerce';
  accSub.Sub_Vertical__c = 'Commerce - Other';
  accList.add(accSub);   

  insert accList;

  List<Opportunity> oppList = new List<Opportunity>();
  Opportunity oppty = utilTestClass.CreateOpportunity('__Test Oppty','1. Identify Need');
  oppty.AccountId =accSub.Id; 
  oppty.Deal_Reg_Opportunity_Status__c ='New Opportunity';
  oppty.CloseDate = Date.today().addMonths(4); 
  oppList.add(oppty);
  
  Opportunity oppty1 = utilTestClass.CreateOpportunity('__Test Oppty','1. Identify Need');
  oppty1.AccountId =acc.Id; 
  oppty1.Deal_Reg_Opportunity_Status__c ='Existing Opportunity';
  oppty1.CloseDate = Date.today().addMonths(4);
  oppList.add(oppty1);

  insert oppList;
}

@isTest
static void getOpportunityTest(){
    Account acc = [Select id,Name,Website,BillingCountry,BillingState from account where name = '__Test Account' LIMIT 1];
    Opportunity oppty = [select id,name,Deal_Reg_Opportunity_Status__c from opportunity where accountId = :acc.Id Limit 1];
    Opportunity opp=SF1_LocateAccountController.getOpportunity(oppty.id);
    System.assertNotEquals(opp,null);
}
@isTest 
static void accSearchTest() {

    Account acc = [Select id,Name,Website,BillingCountry,BillingState from account where name = '__Test Account' LIMIT 1];
    Opportunity oppty = [select id,name,Deal_Reg_Opportunity_Status__c from opportunity where accountId = :acc.Id Limit 1];
    Integer oset=5; 
    List<Account> Accs=SF1_LocateAccountController.accSearch(acc.Name,acc.Website,acc.BillingCountry,acc.BillingState,oset);

}
@isTest
static void AddAccntTest()
{
    Account acc = [Select id,Name,Website,BillingCountry,BillingState,BillingStreet,BillingCity,Zip_Postal_Code_Local__c,Customer_or_Account__c,Vertical__c, Sub_Vertical__c from account where name = '__Test Account' LIMIT 1];
    Opportunity oppty = [select id,Partner_Involved__r.No_Rebate_Required__c,name,Deal_Reg_Opportunity_Status__c from opportunity where accountId = :acc.Id Limit 1];
    Account acc1 = [Select id,Name,Website,BillingCountry,BillingState,BillingStreet,BillingCity,Zip_Postal_Code_Local__c,Customer_or_Account__c, Vertical__c, Sub_Vertical__c from account where name = '__Test Acc01' LIMIT 1];
    Opportunity oppty1 = [select id,Partner_Involved__r.No_Rebate_Required__c,name,Deal_Reg_Opportunity_Status__c from opportunity where accountId = :acc1.Id Limit 1];
    
    User dmlUser = utilTestClass.getTestRunUser();

  OpportunityTeamMember otm = new OpportunityTeamMember();
  otm.TeamMemberRole = 'Partner';
  otm.UserId = dmlUser.Id;
  otm.OpportunityId = oppty.id;
  otm.Validation_Override__c = true;
  insert otm;
  

   // insert opt;
    // String opp=SF1_LocateAccountController.AddAccount(acc.id,oppty.id);
    SF1_LocateAccAndExistingOppService.updateOpportunityAfterLocateAccount(acc.id,acc,Oppty);
    SF1_LocateAccAndExistingOppService.updateOpportunityAfterLocateAccount(acc1.id,acc1,Oppty1);
    
     Test.startTest();
     SF1_LocateAccountController.DupAccountCheck(oppty.id,acc.name+'Test___AddAccnt',acc.Website,acc.BillingStreet,acc.BillingCity,acc.BillingState,acc.Zip_Postal_Code_Local__c,acc.BillingCountry);
    
     String opp1=SF1_LocateAccountController.AddAccnt(oppty.id,acc.name+'Test___AddAccnt',acc.Website,acc.BillingStreet,acc.BillingCity,acc.BillingState,acc.Zip_Postal_Code_Local__c,acc.BillingCountry, acc.Vertical__c, acc.Sub_Vertical__c);
     Test.stopTest(); 
}
@isTest
static void uiThemetest()
{
  boolean themeType =   SF1_LocateAccountController.getuserTheme();
  System.assertNotEquals(themeType,null);
}
@isTest
static void testSubresellerDetail()
{
  Account acc = [Select id,Name,Website,BillingCountry,BillingState,BillingStreet,BillingCity,Zip_Postal_Code_Local__c from account where name = '__Test Account' LIMIT 1];
  Opportunity oppty = [select id,name,Deal_Reg_Opportunity_Status__c from opportunity where accountId = :acc.Id Limit 1];
     
 SF1_LocateAccountController.getIntialsubresellerdetail(oppty.Id);
 Test.startTest();
 SF1_LocateAccountController.getSubreseller(10,10,oppty.Id,'test');
 Test.stopTest();

}

@isTest
static void testUpdatereseller()
{
  Account acc = [Select id,Name,Website,BillingCountry,BillingState,BillingStreet,BillingCity,Zip_Postal_Code_Local__c from account where name = '__Test Account' LIMIT 1];
  Account acc1 = [Select id,Name,Website,BillingCountry,BillingState,BillingStreet,BillingCity,Zip_Postal_Code_Local__c from account where name = '__Test Acc01' LIMIT 1];
  Opportunity oppty = [select id,name,Deal_Reg_Opportunity_Status__c from opportunity where accountId = :acc.Id Limit 1];
  Test.startTest();
  try{
  SF1_LocateAccountController.updateSubreseller(acc1.Id,oppty.Id);
  SF1_LocateAccountController.AccountCreateAccess();
  }
  catch (Exception ex)
  {

  }
  Test.stopTest();   


}
  @isTest
  static void getCustomDependablePicklist(){
    Test.startTest();

    SF1_LocateAccountController.customPicklistWrapper cpwWrapper = new SF1_LocateAccountController.customPicklistWrapper();
    cpwWrapper = SF1_LocateAccountController.getCustomDependablePicklist('Account','Vertical__c','Sub_Vertical__c');

    Test.stopTest();
  }
}