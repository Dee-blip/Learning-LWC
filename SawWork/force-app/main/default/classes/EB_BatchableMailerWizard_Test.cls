/*
Author : Sharath K
Description: This is a test class for EB_BatchableMailerWizard. CR# 819957
Created On: 9/16/2010
*/

@isTest(SeeAllData=true)
private class EB_BatchableMailerWizard_Test {
    static EB_EmailTemplate__c testTemplate;
    static EB_AkaMailer__c singleMailer;
    static EB_AkaMailer__c massMailer;
    static list<Account> lstAccount;
    static list<Contact> lstContact = new list<Contact>();
    static Account acc1;
    static EB_NotificationType__c templateType;
    static EmailTemplate et;
    static EB_Token__c token;
    static Merge_Contract_Header__c contract;
    static list<Merge_Contract_Header__c> lstContract = new list<Merge_Contract_Header__c>();
    static String ContactQuery = 'SELECT id, Account.Id, Account.Name, lastname, firstname, Contact_Type__c, Phone, Email FROM Contact WHERE (Contact_Type__c INCLUDES (\'Technical Primary - 24X7\', \'Tech Secondary - 24X7\')) AND Email != \'\' AND Email != null order by CreatedDate desc limit 200';

    static public void init()
    {
       ManagedPkgErrorClass.isFromManagedPackage=false;
       
       templateType=new EB_NotificationType__c();
       templateType.Name= 'Single Email1';
       templateType.Folder_Name__c=' EB_CNSingleMail';
       database.insert(templateType);
            
       User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
       System.runAs ( thisUser ) {
           et = EB_InitializeObjects.createEmailTemplate('New_Email_Template','text');
           Database.insert(et);
       }

       testTemplate= EB_InitializeObjects.createCustomTemplate('Testtemplate 2','text',et.Id);
       database.insert(testTemplate);
     
       lstAccount = new list<Account>();
       acc1 =EB_InitializeObjects.createAccount('DummyAccount1');
       lstAccount.add(acc1);
       
       Account acc2 =EB_InitializeObjects.createAccount('DummyAccount2');
       lstAccount.add(acc2);
       
       Account acc3 =EB_InitializeObjects.createAccount('DummyAccount3');
       lstAccount.add(acc3);
       
       Account acc4 =EB_InitializeObjects.createAccount('DummyAccount4');
       lstAccount.add(acc4);
       
       insert lstAccount;
        
       Contact con1 = EB_InitializeObjects.createContact('Fname1','Lname1',acc3.Id);
       con1.EmailBouncedReason = '550:Invaid Recipient';
       con1.Email = 'test_con1@akamai.com';
       con1.Contact_Type__c = 'Technical Primary - 24X7';
       lstContact.add(con1);
        
       Contact con2 = EB_InitializeObjects.createContact('Fname2','Lname2',acc1.Id);
       con2.Email = 'test_con2@akamai.com';
       con2.Contact_Type__c = 'Technical Primary - 24X7';
       lstContact.add(con2);
        
       Contact con3 = EB_InitializeObjects.createContact('Fname3','Lname3',acc2.Id);
       con3.Email = 'test_con3@akamai.com';
       con3.Contact_Type__c = 'Technical Primary - 24X7';
       lstContact.add(con3);
        
       Contact con4 = EB_InitializeObjects.createContact('Fname4','Lname4',acc4.Id);
       con4.Email = 'test_con4@akamai.com';
       con4.Contact_Type__c = 'Technical Primary - 24X7';
       lstContact.add(con4);
       insert lstContact;
               
       singleMailer=EB_InitializeObjects.createMailer(testTemplate.Id,'Single Email');
       database.insert(singleMailer);

       massMailer=EB_InitializeObjects.createMailer(testTemplate.Id,'Mass Email');
       database.insert(massMailer);  
       
       token = EB_InitializeObjects.createToken(testTemplate.Id);
       insert token;
       
       list<EB_SelectedAccounts__c> lstSelectedAcc = new list<EB_SelectedAccounts__c>();

       for(Account acc:lstAccount)
       {
           EB_SelectedAccounts__c selectedAccount = new EB_SelectedAccounts__c(EB_ParentToken__c = token.Id, Eb_Account__c = acc.Id);
           lstSelectedAcc.add(selectedAccount);
       }
       insert lstSelectedAcc;
       
       contract = new Merge_Contract_Header__c();
       contract.Original_Contract_Id__c = 'Test Contract1';
       contract.Name = 'Test Contract1';
       contract.Account_Name__c = acc1.Id;
       contract.Parent_Account_Name__c = acc1.Id;
       contract.Active__c=TRUE;
       contract.Effective_End_Date__c = Date.today().addMonths(1);
       insert contract;
       
       Merge_Contract_Header__c contract1 = new Merge_Contract_Header__c();
       contract1.Original_Contract_Id__c = 'Test Contract2';
       contract1.Name =  'Test Contract2';
       contract1.Account_Name__c = acc1.Id;
       contract1.Parent_Account_Name__c = acc1.Id;
       contract1.Parent_Contract__c = contract.Id;
       contract1.Active__c=TRUE;
       contract1.Effective_End_Date__c = Date.today().addMonths(1);
       lstContract.add(contract1);
        
       Merge_Contract_Header__c contract2 = new Merge_Contract_Header__c();
       contract2.Original_Contract_Id__c = 'Test Contract3';
       contract2.Name =  'Test Contract3';
       contract2.Account_Name__c = acc1.Id;
       contract2.Parent_Account_Name__c = acc1.Id;
       contract2.Parent_Contract__c = contract.Id;
       contract2.Active__c=TRUE;
       contract2.Effective_End_Date__c = Date.today().addMonths(1);
       lstContract.add(contract2);
       insert lstContract;
        
       EB_ResellerContractId__c reseller = new EB_ResellerContractId__c();
       reseller.Name = 'DummyAccount1';
       reseller.Original_Contract_Id__c = 'Test Contract1';
       insert reseller;
    }
    
    /*
     Author : Sharath K
Description: This mehod contains all the test cases for EB_BatchableMailerWizard. CR# 819957
Created On: 9/16/2010
    */
    static testMethod void myUnitTest() 
    {
        Init();
        ManagedPkgErrorClass.isFromManagedPackage=false;
        Database.BatchableContext BC;
        List<sObject> scope;
        //Instantiate the class
        EB_BatchableMailerWizard batchableTest = new EB_BatchableMailerWizard(ContactQuery);
        //Invoke the start method
        Database.QueryLocator ql = batchableTest.start(BC);
        System.assertEquals(ql.getQuery(),ContactQuery);
        //Invoke the execute method
        batchableTest.execute(BC,scope);
        //Invoke the finish method
        batchableTest.finish(BC);
        
        //just to improve coverage of class, invoke the class with other 2 constructors
        list<String> reseller = new list<String>();
        reseller.add(acc1.Id);
        EB_BatchableMailerWizard batchableTestDummy1 = new EB_BatchableMailerWizard();
        EB_BatchableMailerWizard batchableTestDummy2 = new EB_BatchableMailerWizard(ContactQuery,reseller);
    }
    
    static testMethod void EB_BatchableCreateMailer_test() 
    {
        Init();
        
        lstContact = new list<Contact>();
        for(Account acc:lstAccount)
        {
           Contact cnt = utilTestClass.CreateContact('test' , 'contact');
           cnt.AccountId = acc.Id;
           cnt.Contact_Type__c = 'Technical Primary - 24X7';
           lstContact.add(cnt);
        }
        insert lstContact;
        
        EB_BatchableCreateMailer batchmailerCls = new EB_BatchableCreateMailer(ContactQuery,singleMailer,token.Id,false,null,null);
 
        list<Account> reseller = new list<Account>();
        reseller.add(acc1);
        batchmailerCls = new EB_BatchableCreateMailer(ContactQuery,singleMailer,token.Id,false,null,reseller);

        Id batchinstanceid1 = Database.executeBatch(batchmailerCls,200);  
    }
    
    static testMethod void EB_BatchableCreateMassMailer_test() 
    {
        Init();
        
        lstContact = new list<Contact>();
        /*for(Account acc:lstAccount)
        {
           for(integer i=0;i<5;i++)
           {
               Contact cnt = utilTestClass.CreateContact('test' , 'contact');
               cnt.AccountId = acc.Id;
               cnt.Contact_Type__c = 'Technical Primary - 24X7';
               lstContact.add(cnt);
           }
        }*/
         
        EB_AkaMAccount__c akamAccount = new EB_AkaMAccount__c(); 
        akamAccount.EB_AkaMailer__c = massMailer.Id;
        akamAccount.EB_Status__c = 'New';
        akamAccount.EB_EnableValidationRules__c=false;
        insert akamAccount;
        
		EB_BatchableCreateMassMailer batchmailerCls = new EB_BatchableCreateMassMailer(ContactQuery,massMailer,token.Id,akamAccount,false,null,null);        
        list<Account> reseller = new list<Account>();
        reseller.add(acc1);
        batchmailerCls = new EB_BatchableCreateMassMailer(ContactQuery,massMailer,token.Id,akamAccount,false,null,reseller);
        Id batchinstanceid1 = Database.executeBatch(batchmailerCls,200);  
    }
    
    /*static{
        utilTestClass.createCustomSettings();   
        
        EB_ResellerContractId__c reseller = new EB_ResellerContractId__c();
        reseller.Name = 'DummyAccount1';
        reseller.Original_Contract_Id__c = 'Test Contract1';
        insert reseller;
    }*/
}