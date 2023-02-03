/*=====================================================================================================+
    Class name          :   SC_CaseIssueClass_Test 
    Author              :   Vandhana Krishnamurthy
    Created             :   07-January-2017
    Purpose             :   Covers code for below functions in SC_CaseIssueClass

createERForPrmAccounts()
ecobContractReport()
createBOCCEntitlement()
BOCC_Calculation()

	 Last Modified    Developer  	Purpose            
     =============    =========  	=======
	  28-Sep-2020     Tejaswini     ESESP-4020 : Set seeAllData = false , added testSetup method

*/

@isTest
public class SC_CaseIssueClass_Test 
{
	@testSetup static void setup() {
    	utilTestClass.createCustomSettings(); 
        utilTestClass.createData_SC_SupportEmail();
        
        Profile pfl = [select id from Profile where name = 'System Administrator' limit 1];
        User usr = [select Id from User where IsActive = True and ProfileId = :pfl.Id limit 1];
        RecordType rectype= [select id from RecordType where sObjectType='Case' and Name='Technical' and isActive=true limit 1];
        
        Case csRec = new Case(subject='Test', description='test',Ownerid = usr.Id,AKAM_Case_ID__c='ehsdsg',status = 'Open',
            RecordTypeId=rectype.Id,Do_not_show_in_portal__c = true,Origin = 'Email');
        insert csRec;
        
        
        List<Account> lstAcc = new List<Account>();
        Account account1 = new Account(Name = 'Account1 SC_CaseIssueClass', Support_Level__c = 'Premium',AKAM_Account_ID__c='Test-111-ABC-XYZ',Auto_Escalate_Sev_1_Technical_Cases__c = true);
        lstAcc.add(account1);
        Account account2 = new Account(Name = 'Account2 SC_CaseIssueClass', Support_Level__c = 'Standard',AKAM_Account_ID__c='Test-222-ABC-XYZ');
        lstAcc.add(account2);
        insert lstAcc;
        
        
    }
    
    @isTest static void testFunction1()
    {
        Test.startTest();
        User adminUser = utilTestClass.CreateUser('TstUsr2', 'Worldwide', 'System Administrator');
        /*List<Account> lstAcc = new List<Account>();
        Account account1 = new Account(Name = 'Account1 SC_CaseIssueClass', Support_Level__c = 'Premium',AKAM_Account_ID__c='Test-111-ABC-XYZ',Auto_Escalate_Sev_1_Technical_Cases__c = true);
        lstAcc.add(account1);
        Account account2 = new Account(Name = 'Account2 SC_CaseIssueClass', Support_Level__c = 'Standard',AKAM_Account_ID__c='Test-222-ABC-XYZ');
        lstAcc.add(account2);
        insert lstAcc;*/
        
        Account account1 = [Select Id from Account Limit 1];
        
        Id techRecTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
                
        Case eachCase;
        List<Case> listCase = new List<Case>();
        for(Integer i=0; i<3; i++){
            eachCase = new Case(Status = 'Unassigned', Sub_Type__c = 'Product Support', OwnerId = (Id)UserInfo.getUserId(), severity__c = '1');
            eachCase.AccountId = account1.Id;
            eachCase.RecordTypeID = techRecTypeId;
           	eachCase.Origin = 'Email';
            eachCase.Autogen_UseCase__c = 'ECOB';
            eachCase.Is_ECOB_Update__c = true;
            listCase.add(eachCase);
        }
        
        // to cover createERForPrmAccounts()
        insert listCase;
        Set<Id> caseIdset = new set<Id>();
        for(Case eachCase1 : listCase){
            caseIdset.add(eachCase1.Id);
        }
        // to cover ecobContractReport()
        SC_CaseIssueClass.ecobContractReport(listCase);
        SC_CaseIssueClass.ChangeRecordType(caseIdset);
        
        
        // to cover BOCCEntitlement()
        List<Merge_Contract_Header__c> headerList = new List<Merge_Contract_Header__c>();
        Merge_Contract_Header__c merge_contract;
        merge_contract = new Merge_Contract_Header__c();
        merge_contract.Name                       ='Test Merge Contract-1';
        merge_contract.Contract_Id__c             ='Test-123-1';
        merge_contract.Original_Contract_Id__c    = 'Test-123-ABC-XYZ1';
        merge_contract.Account_Name__c            = account1.Id;
        merge_contract.Locked__c                  = true;
        merge_contract.Cancellation_Date__c       = Null;
        merge_contract.Contract_Transferred_To__c = Null;
        merge_contract.Is_COB_Created__c          = False;
        merge_contract.Effective_Start_Date__c    = system.Today().addDays(-14);
        merge_contract.Effective_End_Date__c      = system.Today().addMonths(6);
        merge_contract.Active__c                  = true;
        headerList.add(merge_contract);
        
        Merge_Contract_Header__c merge_contract2;
        merge_contract2 = new Merge_Contract_Header__c();
        merge_contract2.Name                       ='Test Merge Contract-2';
        merge_contract2.Contract_Id__c             ='Test-123-1';
        merge_contract2.Original_Contract_Id__c    = 'Test-123-ABC-XYZ2';
        //merge_contract2.Account_Name__c            = account1.Id;
        merge_contract2.Locked__c                  = true;
        merge_contract2.Cancellation_Date__c       = Null;
        merge_contract2.Contract_Transferred_To__c = Null;
        merge_contract2.Is_COB_Created__c          = False;
        merge_contract2.Effective_Start_Date__c    = system.Today().addDays(-14);
        merge_contract2.Effective_End_Date__c      = system.Today().addMonths(6);
        merge_contract2.Active__c                  = true;
        headerList.add(merge_contract2);
        Insert headerList;
        
        
        
        List<Merge_Contract_Detail__c> detailList = new List<Merge_Contract_Detail__c>();
        Merge_Contract_Detail__c mcd        = new Merge_Contract_Detail__c();
        mcd.Original_Contract_Id__c         =   headerList[0].Id;
        mcd.Effective_Start_Date__c         =   system.Today();
        mcd.Effective_End_Date__c           =   system.Today().addDays(10);
        mcd.Product_Id__c                   =   'M-LC-160618';
        mcd.Units_Low__c                    =   12;
        mcd.Units_High__c                   =   12;
        mcd.Unit_of_Measure__c              =   'Others';
        mcd.IS_Existing_COB__c              =   True;
        mcd.Original_Detail_Id__c           =   merge_contract.Id + 'UniqueId-141'; 
        detailList.add(mcd);
        
        Merge_Contract_Detail__c mcd2        = new Merge_Contract_Detail__c();
        mcd2.Original_Contract_Id__c         =   headerList[1].Id;
        mcd2.Effective_Start_Date__c         =   system.Today();
        mcd2.Effective_End_Date__c           =   system.Today().addDays(10);
        mcd2.Product_Id__c                   =   'M-LC-161199';
        mcd2.Units_Low__c                    =   12;
        mcd2.Units_High__c                   =   12;
        mcd2.Unit_of_Measure__c              =   'Others';
        mcd2.IS_Existing_COB__c              =   True;
        mcd2.Original_Detail_Id__c           =   merge_contract.Id + 'UniqueId-142'; 
        detailList.add(mcd2);
        Insert detailList;
        
        Test.stopTest();
    }
    
    // Method# 2 - (For changeTaskOwner Method)
  	static testMethod void changeTaskOwner_CaseMethod() {
    
        Test.StartTest();
        
        /*Profile pfl = [select id from Profile where name = 'System Administrator' limit 1];
User usr = [select Id from User where IsActive = True and ProfileId = :pfl.Id limit 1];
RecordType rectype= [select id from RecordType where sObjectType='Case' and Name='Technical' and isActive=true limit 1];
Case csRec1 = new Case(subject='Test', description='test',AKAM_Case_ID__c='F-Test-Ownr',RecordTypeId=rectype.Id,OwnerId=usr.Id);
Insert csRec1;*/
        
        Case csRec = [select Id,OwnerId from case where status <> 'Closed' and origin != null Limit 1];
        
        System.debug('-----------the case is '+csRec);
        //Creating Task Record
        Task newtask = new Task();
        newtask.Subject            =   'Test';
        newtask.Description     =   'Test';
        newtask.ActivityDate    =   system.today();                             
        newtask.Type__c         =   'Email';
        newtask.Status          =   'Not Started';
        newtask.WhatId          =   csRec.Id;
        newtask.OwnerId         =   UserInfo.getUserId();
        newtask.LOE_hours__c    =   4;
        Insert newtask; 
        
        SC_CaseIssueClass sc_CaseIssueCls = new SC_CaseIssueClass();
        Map<Id,Id> caseId_OwnerId = new Map<Id,Id>();
        caseId_OwnerId.put(csRec.Id,UserInfo.getUserId());
        Try{
            sc_CaseIssueCls.changeTaskOwner_Case(caseId_OwnerId);
            
            Attachment att = new Attachment();
            att.ParentId = csRec.id;
            att.Body = blob.valueOf('testt');
            att.ContentType = 'text/html; charset=UTF-8';  
            att.Name = 'Email contents.html';   
            att.ContentType='ContentPost';
            Insert att;
            
            csRec.do_not_show_in_portal__c = false;
            set<Id> caseIdForAttachmntUpdate = new set<Id>();
            caseIdForAttachmntUpdate.add(csRec.id);
            SC_CaseIssueClass caseIssue = new SC_CaseIssueClass();
            caseIssue.updateAttachment(caseIdForAttachmntUpdate);
            
        }
        Catch(exception e){}
        
        Test.StopTest();
    
  }
}