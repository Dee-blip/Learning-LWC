@isTest
public with sharing class PA_AccountBased_ControllerTestClass {

 private static  User CreateUser(String pUsrAlias, String pProfile, String pRole)
  {
    Profile pr = [select Id from Profile where Name=:pProfile][0];
    UserRole role = [select Id, Name from UserRole where Name=:pRole][0];
    User newUser = new User(alias = pUsrAlias, email=pUsrAlias+'@akamai.com',emailencodingkey='UTF-8', lastname='NewOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username= pUsrAlias + '@akamai.com',profileid = pr.Id, UserRoleId = null );
    insert newUser;
    return newUser;     
  }
  
public static Account create_account(){
Account acc_master = utilTestClass.CreateAccount('_AccMerge_TestCase_Master_');
   insert acc_master;
    return acc_master;

}

public static Product_Approvals__c create_PA()
{
 Product_Approvals__c pac=new Product_Approvals__c();
 pac.Account__c=create_account().Id;
 //insert pac;
 return pac;
}

public static PA_AccountBased_Controller init1(){
    
PA_AccountBased_Controller pacc=new PA_AccountBased_Controller();

pacc.pac=create_PA();

return pacc;
}

testmethod static void init_test(){
ManagedPkgErrorClass.isFromManagedPackage=false;
Account acc_master = utilTestClass.CreateAccount('_AccMerge_TestCase_Master_');
Product_Approvals__c prod_app=new Product_Approvals__c();
prod_app.Account__c=acc_master.Id;
PA_AccountBased_Controller pacc=new PA_AccountBased_Controller();

list<GSM_Custom_Settings__c> lstGSM = new list<GSM_Custom_Settings__c>();

GSM_Custom_Settings__c csGSMFields1=new GSM_Custom_Settings__c(); 
csGSMFields1.Name='CRM_Integration';
csGSMFields1.Value__c='005A0000001XPcD';
lstGSM.add(csGSMFields1);

insert lstGSM;

pacc.pac=prod_app;

Survey__c sc=new Survey__c();
sc.Name='Sample survey';
sc.Submit_Response__c='abc';
insert sc;
Approval_Workflow__c awc=new Approval_Workflow__c();
awc.Name='Site Shield';
awc.Survey__c=sc.Id;
insert awc;
pacc.pa =new ProductApprovalCS__c();
pacc.pa.Value__c=awc.Id;

System.debug(awc.Id+'awcid');
System.debug(pacc.pa.Value__c+'paval');
Test.startTest();
pacc.Acct_name='test account name';
pacc.save();
System.AssertEquals(pacc.pac.Survey__c,sc.Id); 
System.AssertEquals(pacc.pac.Approval_Workflow__c,awc.Id);   
Test.stopTest();
}

testmethod static void save_survey_test(){
ManagedPkgErrorClass.isFromManagedPackage=false;
Account acc_master = utilTestClass.CreateAccount('_AccMerge_TestCase_Master_');
Product_Approvals__c prod_app=new Product_Approvals__c();
prod_app.Account__c=acc_master.Id;
PA_AccountBased_Controller pacc=new PA_AccountBased_Controller();


list<GSM_Custom_Settings__c> lstGSM = new list<GSM_Custom_Settings__c>();

GSM_Custom_Settings__c csGSMFields1=new GSM_Custom_Settings__c(); 
csGSMFields1.Name='CRM_Integration';
csGSMFields1.Value__c='005A0000001XPcD';
lstGSM.add(csGSMFields1);

insert lstGSM;


pacc.pac=prod_app;
Survey__c sc=new Survey__c();
sc.Name='Sample survey';
sc.Submit_Response__c='abc';
insert sc;
Approval_Workflow__c awc=new Approval_Workflow__c();
awc.Name='Site Shield';
awc.Survey__c=sc.Id;
insert awc;
pacc.pa =new ProductApprovalCS__c();
pacc.pa.Value__c=awc.Id;

System.debug(pacc.pa.Value__c+'paval');
Test.startTest();
pacc.Acct_name='test account name';
pacc.save_survey();
System.AssertEquals(pacc.pac.Survey__c,sc.Id);
System.AssertEquals(pacc.pac.Approval_Workflow__c,awc.Id);
Test.stopTest();
}


testmethod static void cancel_test(){
ManagedPkgErrorClass.isFromManagedPackage=false;
Account acc_master = utilTestClass.CreateAccount('_AccMerge_TestCase_Master_');
Product_Approvals__c prod_app=new Product_Approvals__c();
prod_app.Account__c=acc_master.Id;
PA_AccountBased_Controller pacc=new PA_AccountBased_Controller();
pacc.pac=prod_app;
pacc.acct_id=acc_master.Id;

Test.startTest();
PageReference pr=pacc.cancel();
PageReference pr1=pacc.cancel();
system.assertEquals(pr.getURL(), pr1.getURL()); 
Test.stopTest();

}


}