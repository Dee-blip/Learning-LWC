@isTest
public class utilTestClass 
{
    private static Integer nextUserSerialNumber = -1;
    private static Map<String, Schema.SObjectType> globalDescribe= Schema.getGlobalDescribe();
    public static Account CreateAccount(String pAccName)
    {
        Account newAccount = new Account();
        newAccount.Name = pAccName;
        newAccount.BillingCountry = 'India';
        newAccount.BillingState = 'DELHI';
        return newAccount;
    }

  public static AccountTeamMember CreateAccountTeamMember(id pAccId, id pUserId)
    {
        AccountTeamMember newAccountTeamMember = new AccountTeamMember();
        newAccountTeamMember.AccountId = pAccId;
        newAccountTeamMember.UserId = pUserId;
        return newAccountTeamMember;
    }
    
        public static Merge_Contract_Header__c CreateContractHeader(String pOrignalContractId, Id pAccountId)
    {
        Merge_Contract_Header__c newHeader = new Merge_Contract_Header__c();
        newHeader.Original_Contract_Id__c = pOrignalContractId;
        newHeader.Name = pOrignalContractId;
        newHeader.Account_Name__c = pAccountId;     
        return newHeader;
    }

    //SFDC-1572
     public static Merge_Contract_Detail__c createContractDetail(String prod,String prodId, Id origContId, Date startDate, Date endDate){
  
      Merge_Contract_Detail__c contractDetail = new Merge_Contract_Detail__c(
        Product__c = prod,
        Product_Id__c = prodId,
        Original_Contract_Id__c = origContId,
        Effective_Start_Date__c = startDate,
        Effective_End_Date__c = endDate
      );
      return contractDetail;
    }
    //SFDC-3057

    public static Marketing_Product__c createMarketingProduct(String Engineering_Product_Name,String Marketing_Product_Id, String Parent_Product_Id,String uniqueKey){
  
      Marketing_Product__c mp = new Marketing_Product__c(
        Engineering_Product_Name__c = Engineering_Product_Name,
        Marketing_Product_Id__c = Marketing_Product_Id,
        Parent_Product_Id__c = Parent_Product_Id,
        Product_Unique_Key__c = uniqueKey
        //Name = mpname
      );
      return mp;
    }
    
    public static Partner_Onboarding__c CreatePartnerOnboarding(Id opptyId)
    {
        Partner_Onboarding__c pOb = new Partner_Onboarding__c();
        pOb.Partner_Opportunity__c = opptyId;
        return pOb;
    }
    
    public static Contact CreateContact(String pFirstName, String pLastName)
    {
        Contact newContact = new Contact();
        newContact.FirstName = pFirstName;
        newContact.LastName = pLastName;
        newContact.Email ='__testContact'+Math.round(Math.random()*10000000*Math.random())+'@Testing.com';
        newContact.Phone = '999999';   
        //newContact.Akamai_Vertical__c = 'Gaming';
        //newContact.Sub_Vertical__c = 'Console Mfs'; 
        newContact.MailingCountry = 'India';
        newContact.MailingState = 'DELHI';
        newContact.Title = 'Tester';
        return newContact;
    }
    public static Lead CreateLead()
    {
        Lead lead = new Lead();
        //lead.Akamai_Vertical__c = 'Gaming';
        lead.LeadSource = 'Web';
        //lead.Sub_Vertical__c = 'Console Mfs';   
        return lead;
    }
    /*public static Apttus__APTS_Agreement__c CreateAgreement(String pName )
    {
        Apttus__APTS_Agreement__c agreement = new Apttus__APTS_Agreement__c();
        agreement.name = pName;
        return agreement;
    }*/
    public static Opportunity CreateOpportunity(String pOpptyName, String pStageName)
    {
        Opportunity opp = new Opportunity();
        opp.Name = pOpptyName;
        opp.StageName = pStageName;
        return opp;
    }
    /*public static Apttus_Proposal__Proposal__c createProposal(String pName) 
    {
        Apttus_Proposal__Proposal__c proposal = new Apttus_Proposal__Proposal__c();
        proposal.Apttus_Proposal__Proposal_Name__c = pName;
        return  proposal;  
    }
    public static Apttus_Proposal__Proposal__c refreshProposal(Apttus_Proposal__Proposal__c proposal){
        return  [select Id,Trigger_Custom_Validations__c from Apttus_Proposal__Proposal__c where Id = :proposal.Id];
    }*/
    public static List<User> createPartnerUsers(Integer max, id accountId)
    {
        
        final List<Profile> partnerProfiles = 
        [select id,name from Profile where (Name='Partner Community User' or Name='Partner Community Admin') limit :max];
        System.assert(
            !(partnerProfiles == null || partnerProfiles.size() <= 0), 
            'No partner profiles exist therefore test cannot be executed');
        final List<Account> accounts = new List<Account>();
        if(accountId == null){
            for(Integer i = 0; i < partnerProfiles.size(); i++)
            {
                //accounts.add(new Account(name='Test ' + i,Partner_Type__c='Unknown'));
                Account a = utilTestClass.CreateAccount('Test '+i);
                a.Partner_Type__c = 'Unknown';
                accounts.add(a);
            }
        insert accounts;
        for(Account account : accounts){
            account.Validation_Override__c=true;
            account.IsPartner = true;
            }
        update accounts;
        }
        if(accountId != null){
            Account acc=[select id from Account where id=:accountId];
            acc.IsPartner=true;
            acc.Validation_Override__c=true;
            acc.Partner_Type__c='Unknown';
            acc.Rebate_TC_Status__c='Accepted';
            acc.Rebate_TC_Accepted_At__c=DateTime.now();
            update acc;
        }
        final List<Contact> contacts = new List<Contact>();
        for(Integer i = 0; i < partnerProfiles.size(); i++)
        {
            Contact c = utilTestClass.CreateContact('John','Doe'+i);
            c.AccountId=(accountId == null ? accounts.get(i).id : accountId);
            c.MailingStreet='123 Main';
            c.MailingCity='Peoria';
            c.MailingState='IL';
            c.MailingPostalCode='33333';
            c.MobilePhone='3213213211';
            c.Fax='3213123211';
            c.Email = i+'@akamai.com';
            c.Active_Partner__c=True;
            contacts.add(c);
        }
        System.Debug('wat@@@ contacts' + contacts);
        insert contacts;
        final List<User> users = new List<User>();
        for(Integer i = 0; i < partnerProfiles.size(); i++)
        {
            String userName = getRandomString(5);
                users.add(
                    new User(
                        Username=''+userName+'@akamai.com',
                        Alias = 'tst'+userName, 
                        Email=''+userName+'@akamai.com', 
                        FirstName='John', 
                        LastName='Doe'+userName, 
                        ProfileId = partnerProfiles.get(i).Id, 
                        LanguageLocaleKey='en_US', 
                        LocaleSidKey='en_US', 
                        EmailEncodingKey='UTF-8', 
                        TimeZoneSidKey='America/Los_Angeles',
                        ContactId = contacts.get(i).id,
                        Can_Accept_POA__c=true
                    )
            );
        }
        insert users;
        return users;
    }
    
    public static SFDC_MDF__c CreateFundRequest(String pFRName,Decimal pAmount)
    {
        SFDC_MDF__c fm=new SFDC_MDF__c();
        fm.Name=pFRName;
        fm.Amount__c=pAmount;
        fm.Program_End_Date__c = Date.today().addDays(2);
        fm.SOE_or_PubSec_Event__c = 'Yes';
        fm.Spender_Confirmed__c = true;
        return fm;
    }
    
    public static SFDC_MDF_Claim__c CreateFundClaim(Id pFRId,Decimal pAmount)
    {
        SFDC_MDF_Claim__c fc = new SFDC_MDF_Claim__c(); 
        fc.Fund_Request__c=pFRId;
        fc.Amount__c=pAmount;
        fc.SOE_PubSec_Documentation__c = true;
        fc.Fund_Claim_Activity_Spender__c = 'Akamai';
        return fc;
    }
    
    public static SFDC_Budget__c CreateFundBudget(Decimal pAmount)
    {
        SFDC_Budget__c budget = new SFDC_Budget__c();   
        budget.Active__c=true;
        budget.Amount__c=pAmount;
        budget.Fund_Request_Deadline__c = Date.today().addMonths(6);
        budget.Fund_Claim_Deadline__c = Date.today().addMonths(6);
        return budget;
    }
    
    public static Budget_Allocation__c CreateFBA(Id pFRId, Id pBudgetId, Decimal pAmount)
    {
        Budget_Allocation__c ba = new Budget_Allocation__c();
        ba.Amount__c = pAmount;
        ba.Budget__c = pBudgetId;
        ba.Fund_Request__c = pFRId;
        return ba;
    }
    
    public static Account_Reassignment__c CreateAccountReassignment(Id pAccId, Id pRuleId)
    {
        Account_Reassignment__c accReassign=new Account_Reassignment__c();
        accReassign.Account__c=pAccId;
        accReassign.Assign_To__c=pRuleId;
        accReassign.Reassign__c=true;
        return accReassign;
    }
    
    public static Account_Reassignment_Rule__c CreateAccountReassignmentRule(String pName, Id pUserId, String pRoleName)
    {
        //Map<String,Features_Toggle__c> featureToggleCustomSettings = Features_Toggle__c.getAll();
        Account_Reassignment_Rule__c rule = new Account_Reassignment_Rule__c();
        rule.Name = pName;
        rule.Associated_User__c = pUserId;
        if(GsmUtilClass.isFeatureToggleEnabledCustomMetadata('UserRoleUpdateThroughAssignmentRule') == true) 
            rule.User_Role__c = pRoleName;
        return rule;
    }

    public static Order_Approval__c CreateOrderApproval(String opptyId, String SAOwnerId)
    {
        //Order_approval_class_settings__c orderApprovalCustomSettings = Order_approval_class_settings__c.getInstance('v1.0'); //SFDC-2304
        Order_Approval__c orderApproval = new Order_Approval__c();
        orderApproval.Associated_Opportunity__c = opptyId;
        orderApproval.RecordTypeId = GsmUtilClass.getGSMSettingValue('OA_CCG_Only_Approval_Id'); //SFDC-2304
        orderApproval.CCG_Owner__c = SAOwnerId;
        return orderApproval;
    }
    
    public static Campaign CreateCampaign(String pName)
    {
        Campaign cmpgn = new Campaign();
        cmpgn.Name = '__ Test Cmpgn';
        return cmpgn;
    }
    
    public static CampaignMember CreateCampaignMember(Id pLeadId, Id pCampaignId)
    {
        CampaignMember cmpgnMember = new CampaignMember();
        cmpgnMember.LeadId = pLeadId;
        cmpgnMember.CampaignId = pCampaignId;
        return cmpgnMember;
    }
    
    public static Channel_Mapping__c CreateChannelMapping(String pName, Id pAccId, Id pVARManagerId)
    {
        Channel_Mapping__c cm = new Channel_Mapping__c();
        cm.Name = pName;
        cm.Partner_Name__c = pAccId;
        cm.PAE_ID__c = pVARManagerId;
        return cm;
    }

    public static Channel_Mapping__c CreateChannelMapping(String pName, Id pAccId, Id pVARManagerId, Id fundRequestApprover)
    {
        Channel_Mapping__c cm = CreateChannelMapping(pName, pAccId, pVARManagerId);
        cm.MDF_Approver__c = fundRequestApprover;
        return cm;
    }
    
    public static User CreateUser(String pUserName, String pRoleName, String pProfileName)
    {
        Profile pr = [select Id from profile where name=:pProfileName][0];
        UserRole role = [select Id, name from UserRole where name=: pRoleName][0];
        User user = new User(alias = pUserName, email=pUserName+'@akamai.com',emailencodingkey='UTF-8', lastname='testLastName', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username=pUserName+'_@akamai.com',profileid = pr.Id, UserRoleId = role.Id );
        return user;
    }
    
    public static User CreateUserWithProfileId(String pUserName, String pRoleName, Id pProfileId)
    {
        UserRole role = [select Id, name from UserRole where name=: pRoleName][0];
        User user = new User(alias = pUserName, email=pUserName+'@akamai.com',emailencodingkey='UTF-8', lastname='testLastName', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username=pUserName+'_@akamai.com',profileid = pProfileId, UserRoleId = role.Id );
        return user;
    }
    
    public static List<Case> createCases(Integer noOfCases, Boolean isInsert, Id oId, String sev) {
        Case cs;
        List<Case> caseLst = new List<Case>();
        for(Integer i = 0; i < noOfCases; i++) {
            cs = new Case(Status = 'Unassigned', Origin = 'Email', OwnerId = oId, severity__c = sev);
            caseLst.add(cs);
        }
        
        if(isInsert && caseLst.size() > 0) {
            insert caseLst;
        }
        
        return caseLst;
    }
public static Task CreateTask(String oldUser,String subject,String status,String taskType,Id whId)
    {
        Task ta=new Task();
        ta.OwnerId=oldUser;
        ta.Subject=subject;
        ta.Status=status;
        ta.Task_type__c=taskType;
        ta.Type__c = taskType;
        ta.WhatId=whId;
        return ta;
    } 
    public static Task CreateTask(String oldUser,String subject,String status,String taskType)
    {
        Task ta=new Task();
        ta.OwnerId=oldUser;
        ta.Subject=subject;
        ta.Status=status;
        ta.Task_type__c=taskType;
        ta.Type__c = taskType;
        return ta;
    }
    
// Added by Deepak Saxena for CR 2884602
    public static SC_Issues__c CreateIssue(String pcaseIssueExt, String pMigrationBatchNumber, id pCaseId)
    {
        SC_Issues__c newIssue = new SC_Issues__c();
        newIssue.Case_Issue_Ext__c = pcaseIssueExt;
        newIssue.SC_Migration_Batch_Number__c = pMigrationBatchNumber;
        newIssue.Related_Case__c = pCaseId;
        return newIssue;
    }
    
    public static Case_Issue__c CreateCaseIssue(Id pCaseId, Id pIssueId)
    {
        Case_Issue__c newcaseissue = new Case_Issue__c(Related_Case__c = pCaseId, Related_Issue__c = pIssueId);
        return newcaseissue;
    }
    
    public static Case_Article__c CreateCaseArticleShaddow(Id pCaseId, Id pCaseArticleId, String pKAID, String pKAURLName)
    {
        Case_Article__c newcasearticle = new Case_Article__c(Case__c = pCaseId, CaseArticleID__c = pCaseArticleId, KnowledgeArticleID__c = pKAID, KnowledgeArticle_URLName__c = pKAURLName );
        return newcasearticle;
    }
	// End of Changes for CR 2884602

	//Start of changes for CR-2746200
    public static Product2 createProductForStandardPricebook(String productName,String productFamily,Boolean isInsert)
    {    
        Product2 product = new Product2(name = productName,family = productFamily);
        if(isInsert)
        {
            insert product;
        }
        return product;
    }
    
    public static void createStandardPricebookEntry(Id pricebookId,Id productId,Boolean pricebookEntryIsActive, String pricebookEntryCurrencyISOCode,Boolean isInsert,Decimal price ){
        
        PricebookEntry pricebookEntry = new PricebookEntry(product2Id = productId,pricebook2Id = pricebookId,isActive = pricebookEntryIsActive, currencyISOCode = pricebookEntryCurrencyISOCode,unitPrice = price  );
        
        if(isInsert)
        {
            insert pricebookEntry;
        }
    }
    
    //rsharma: generate random string of given length
    public static String getRandomString(Integer len) {
        //Define set of character to be chosen from
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
        //Define a random string to be made
        String randomString = '';
        while (randomString.length() < len) {
            //get a random number by Crypto class, take mod of it from length of 'chars' to randomly select a character
            Integer randomNo = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randomString += chars.substring(randomNo, randomNo+1);
        }
        return randomString; 
    }
    
    //End of changes for CR-2746200 
    
    public static void createCustomSettings() {
        
        string adminId = (string)[Select Id from Profile where Name = 'System Administrator'].Id;
        
        
        SCUserIdCustomSetting__c scUserIdcs = new SCUserIdCustomSetting__c();
        scUserIdcs.Name = 'NOCC/Network Agent';
        scUserIdcs.UserId__c = Userinfo.getUserId();
        Insert scUserIdcs;
        
        list<GSM_Custom_Settings__c> lstGSM = new list<GSM_Custom_Settings__c>();//bulk List of custom setting object for bulk insert
        
        GSM_Custom_Settings__c csGSMFields0909=new GSM_Custom_Settings__c(); 
        csGSMFields0909.Name='OpptyTrigger#SS6TaskSubject';
        csGSMFields0909.Value__c='Request for Contract Entry';
        lstGSM.add(csGSMFields0909);
        
        GSM_Custom_Settings__c csGSMFields1=new GSM_Custom_Settings__c(); 
        csGSMFields1.Name='AccountTrigger#ChinaAccOwnerId';
        csGSMFields1.Value__c='005A0000000MvlZIAS';
        lstGSM.add(csGSMFields1);
        
        GSM_Custom_Settings__c csGSMFields2=new GSM_Custom_Settings__c(); 
        csGSMFields2.Name='AccountDelete#EnabledProfileId';
        csGSMFields2.Value__c= adminId;
        lstGSM.add(csGSMFields2);
        
        GSM_Custom_Settings__c csGSMFields3=new GSM_Custom_Settings__c(); 
        csGSMFields3.Name='AccountMerge#EnabledProfileId';
        csGSMFields3.Value__c= adminId ;
        lstGSM.add(csGSMFields3);
        
        GSM_Custom_Settings__c csGSMFields4=new GSM_Custom_Settings__c(); 
        csGSMFields4.Name='AccountTrigger#ChinaProfileId';
        csGSMFields4.Value__c='00eG0000000eFOXIA2';
        lstGSM.add(csGSMFields4);
        
        GSM_Custom_Settings__c csGSMFields5=new GSM_Custom_Settings__c();
        csGSMFields5.Name='ContactTriggerClass#ErrorException';
        csGSMFields5.Value__c='005A0000000MvEqIAK';
        lstGSM.add(csGSMFields5);
        
        GSM_Custom_Settings__c csGSMFields6=new GSM_Custom_Settings__c();
        csGSMFields6.Name='CaseInvoiceTrigger#AccMismatchError';
        csGSMFields6.Value__c='Case Account and Related Invoice account should match.';
        lstGSM.add(csGSMFields6);
        
        GSM_Custom_Settings__c csGSMFields10 =new GSM_Custom_Settings__c();
        csGSMFields10.Name='IR_System_ProfileIDs';
        csGSMFields10.Value__c= adminId ;
        lstGSM.add(csGSMFields10);
        
        GSM_Custom_Settings__c csGSMFields11 =new GSM_Custom_Settings__c();
        csGSMFields11.Name='CaseTrigger#updateContact';
        csGSMFields11.Value__c='Collections, International Business Development, Invoice Review Case, Invoice Review Read Only, Momentum Case Record, Partner Portal Case, Product Management, SF Feedback';
        lstGSM.add(csGSMFields11);
        
        GSM_Custom_Settings__c csGSMFields12 =new GSM_Custom_Settings__c();
        csGSMFields12.Name='IR_CaseDefaultRecordTypeId';
        csGSMFields12.Value__c='012C00000004iJAIAY';
        lstGSM.add(csGSMFields12);
        
        GSM_Custom_Settings__c csGSMFields13 =new GSM_Custom_Settings__c();
        csGSMFields13.Name='IR_CaseRecordTypeIds';
        csGSMFields13.Value__c='012C00000004iJAIAY,012C00000004iJBIAY';
        lstGSM.add(csGSMFields13);
        
        GSM_Custom_Settings__c csGSMFields14 =new GSM_Custom_Settings__c();
        csGSMFields14.Name='ContactTrigger#ProfileCheck';
        csGSMFields14.Value__c= '00eA0000000QpNLIA0,00eJ0000000HrFoIAK' ;
        lstGSM.add(csGSMFields14);
        
        GSM_Custom_Settings__c csGSMFields15 =new GSM_Custom_Settings__c();
        csGSMFields15.Name='Common#ONAUserId';
        csGSMFields15.Value__c= '005A0000000OLetIAG' ;
        lstGSM.add(csGSMFields15);
        
        //Start of changes for CR-2746200
        GSM_Custom_Settings__c csGSMFields16 =new GSM_Custom_Settings__c();
        csGSMFields16.Name='OpptyTrigger#ExceptionProfileNames';
        csGSMFields16.Value__c= 'System Administrator,Business Operations,CRM Integration' ;
        lstGSM.add(csGSMFields16);
        
        GSM_Custom_Settings__c csGSMFields17 =new GSM_Custom_Settings__c();
        csGSMFields17.Name='OpptyTrigCls#SalesPAEProfileId';
        csGSMFields17.Value__c= '00eA0000000QkKxIAK' ;
        lstGSM.add(csGSMFields17);
        
        GSM_Custom_Settings__c csGSMFields18 =new GSM_Custom_Settings__c();
        csGSMFields18.Name='Opportunity_SalesOverlay_TeamRole';
        csGSMFields18.Value__c= 'Sales - Secondary' ;
        lstGSM.add(csGSMFields18);
        
        GSM_Custom_Settings__c csGSMFields19 =new GSM_Custom_Settings__c();
        csGSMFields19.Name='Opportunity_SalesOverlay_OTMAccess';
        csGSMFields19.Value__c= 'Edit' ;
        lstGSM.add(csGSMFields19);
        
        GSM_Custom_Settings__c csGSMFields20 =new GSM_Custom_Settings__c();
        csGSMFields20.Name='updateDollarMRR#DataFix';
        csGSMFields20.Value__c= 'true' ;
        lstGSM.add(csGSMFields20);
        
        GSM_Custom_Settings__c csGSMFields21 =new GSM_Custom_Settings__c();
        csGSMFields21.Name='Forecasting#OLIFixLowerLimitDays';
        csGSMFields21.Value__c= '2' ;
        lstGSM.add(csGSMFields21);
        
        GSM_Custom_Settings__c csGSMFields22 =new GSM_Custom_Settings__c();
        csGSMFields22.Name='Forecasting#OLIFixUpperLimitMonths';
        csGSMFields22.Value__c= '2' ;
        lstGSM.add(csGSMFields22);
        
        GSM_Custom_Settings__c csGSMFields23 =new GSM_Custom_Settings__c();
        csGSMFields23.Name='Forecasting#ExemptedSalesStage';
        csGSMFields23.Value__c= 'none' ;
        lstGSM.add(csGSMFields23);
        
        GSM_Custom_Settings__c csGSMFields24 =new GSM_Custom_Settings__c();
        csGSMFields24.Name='OpptyTrigger#MarkettingOpsProfileId';
        csGSMFields24.Value__c= '00eA0000000QpQp' ;
        lstGSM.add(csGSMFields24);
        
        GSM_Custom_Settings__c csGSMFields25 =new GSM_Custom_Settings__c();
        csGSMFields25.Name='OpptyTrigger#AkamaiOpptyRecType';
        csGSMFields25.Value__c= '012A0000000CvQL' ;
        lstGSM.add(csGSMFields25);
        
        GSM_Custom_Settings__c csGSMFields26 =new GSM_Custom_Settings__c();
        csGSMFields26.Name='OpptyLineItemTrigger#MobileProduct';
        csGSMFields26.Value__c= 'Mobile Products' ;
        lstGSM.add(csGSMFields26);
        
        GSM_Custom_Settings__c csGSMFields27 =new GSM_Custom_Settings__c();
        csGSMFields27.Name='OpptyLineItemTrigger#PAEProfileName';
        csGSMFields27.Value__c= 'Sales - Partner Account Executive' ;
        lstGSM.add(csGSMFields27);
        
        GSM_Custom_Settings__c csGSMFields28 =new GSM_Custom_Settings__c();
        csGSMFields28.Name='OpptyLineItems#ManageProductsError';
        csGSMFields28.Value__c= 'You are not authorized to Manage Products. Please contact your Akamai Sales Rep for more information.' ;
        lstGSM.add(csGSMFields28);
        
        GSM_Custom_Settings__c csGSMFields29 =new GSM_Custom_Settings__c();
        csGSMFields29.Name='OpptyLineItemTrigCls#delErrMsg';
        csGSMFields29.Value__c= 'You cannot delete a product on Closed Opportunities.' ;
        lstGSM.add(csGSMFields29);
        
        GSM_Custom_Settings__c csGSMFields30 =new GSM_Custom_Settings__c();
        csGSMFields30.Name='OppLineItemTrigCls#delExcptProfId';
        csGSMFields30.Value__c= '00eA0000000QpNBIA0,00eA0000000QpRDIA0' ;
        lstGSM.add(csGSMFields30);
        
        //End of changes for CR-2746200
        
        GSM_Custom_Settings__c csGSMFields31 =new GSM_Custom_Settings__c();
        csGSMFields31.Name='OppSchCls#NetOpsId';
        csGSMFields31.Value__c= '005A0000000MvgZ' ;
        lstGSM.add(csGSMFields31);
        
        GSM_Custom_Settings__c csGSMFields32 =new GSM_Custom_Settings__c();
        csGSMFields32.Name='LeadButtonsClass#CanViewButtons';
        csGSMFields32.Value__c= adminId ;
        lstGSM.add(csGSMFields32);
        
        GSM_Custom_Settings__c csGSMFields33 =new GSM_Custom_Settings__c();
        csGSMFields33.Name='CRM_Integration';
        csGSMFields33.Value__c= '005A0000000NHQc' ;
        lstGSM.add(csGSMFields33);
        
        GSM_Custom_Settings__c csGSMFields34 =new GSM_Custom_Settings__c();
        csGSMFields34.Name='ContactTrigger#ProfileRestrictAccount';
        csGSMFields34.Value__c= '00eA0000000e5HsIAI' ;
        lstGSM.add(csGSMFields34);
        
        GSM_Custom_Settings__c csGSMFields35 =new GSM_Custom_Settings__c();
        csGSMFields35.Name='UserTriggerClass#ChannelUsersProfiles';
        csGSMFields35.Value__c= '00eG0000000eAyJIAU,00eG0000000eAyOIAU,00eA0000000QkKxIAK,00eG0000000g65cIAA' ;
        lstGSM.add(csGSMFields35);
        
        GSM_Custom_Settings__c csGSMFields36 =new GSM_Custom_Settings__c();
        csGSMFields36.Name='AddressDoctor#EmailLicenseKey';
        csGSMFields36.Value__c= '7CC5248C0AF21C5D96B8' ;
        lstGSM.add(csGSMFields36);
        
        GSM_Custom_Settings__c csGSMFields37 =new GSM_Custom_Settings__c();
        csGSMFields37.Name='AddressDoctor#EmailTimeout';
        csGSMFields37.Value__c= '90' ;
        lstGSM.add(csGSMFields37);
        
        GSM_Custom_Settings__c csGSMFields38 =new GSM_Custom_Settings__c();
        csGSMFields38.Name='AccTriggerCls#ExclusionAccountList';
        csGSMFields38.Value__c= 'WWW Lead Gen (DO NOT DELETE!),WWW Pending Lead Gen (Do Not Delete!),WWW Bad Data (Do Not Delete)' ;
        lstGSM.add(csGSMFields38);
        
        GSM_Custom_Settings__c csGSMFields39 =new GSM_Custom_Settings__c();
        csGSMFields39.Name='AddressDoctor#BatchSize';
        csGSMFields39.Value__c= '10' ;
        lstGSM.add(csGSMFields39);
        
        GSM_Custom_Settings__c csGSMFields40 =new GSM_Custom_Settings__c();
        csGSMFields40.Name='AddressDoctor#CronChainIntervalInMin';
        csGSMFields40.Value__c= '10' ;
        lstGSM.add(csGSMFields40);
        
        GSM_Custom_Settings__c csGSMFields41 =new GSM_Custom_Settings__c();
        csGSMFields41.Name='AddressDoctor#DaysToQueryContacts';
        csGSMFields41.Value__c= '1' ;
        lstGSM.add(csGSMFields41);
        
        GSM_Custom_Settings__c csGSMFields42 =new GSM_Custom_Settings__c();
        csGSMFields42.Name='AddressDoctor#DisableLimitPercentage';
        csGSMFields42.Value__c= '98' ;
        lstGSM.add(csGSMFields42);
        
        GSM_Custom_Settings__c csGSMFields43 =new GSM_Custom_Settings__c();
        csGSMFields43.Name='AddressDoctor#EmailRemainingLicenses';
        csGSMFields43.Value__c= '2000' ;
        lstGSM.add(csGSMFields43);  
        
        GSM_Custom_Settings__c csGSMFields44 =new GSM_Custom_Settings__c();
        csGSMFields44.Name='AddressDoctor#EnableUIVerification';
        csGSMFields44.Value__c= 'true' ;
        lstGSM.add(csGSMFields44);
        
        GSM_Custom_Settings__c csGSMFields45 =new GSM_Custom_Settings__c();
        csGSMFields45.Name='AddressDoctor#LicenseMonitorEmailIds';
        csGSMFields45.Value__c= 'test12345@akamai.com' ;
        lstGSM.add(csGSMFields45);
        
        GSM_Custom_Settings__c csGSMFields46 =new GSM_Custom_Settings__c();
        csGSMFields46.Name='AddressDoctor#MigratorLimit';
        csGSMFields46.Value__c= '5' ;
        lstGSM.add(csGSMFields46);
        
        GSM_Custom_Settings__c csGSMFields48 =new GSM_Custom_Settings__c();
        csGSMFields48.Name='AddressDoctor#MigratorLimitApplicable';
        csGSMFields48.Value__c= 'false' ;
        lstGSM.add(csGSMFields48);
        
        GSM_Custom_Settings__c csGSMFields49 =new GSM_Custom_Settings__c();
        csGSMFields49.Name='AddressDoctor#MigratorQueryDays';
        csGSMFields49.Value__c= '1' ;
        lstGSM.add(csGSMFields49);
        
        GSM_Custom_Settings__c csGSMFields50 =new GSM_Custom_Settings__c();
        csGSMFields50.Name='AddressDoctor#OriginalEmailLicenses';
        csGSMFields50.Value__c= '25000' ;
        lstGSM.add(csGSMFields50);
        
        GSM_Custom_Settings__c csGSMFields51 =new GSM_Custom_Settings__c();
        csGSMFields51.Name='AddressDoctor#OriginalPhoneLicenses';
        csGSMFields51.Value__c= '25000' ;
        lstGSM.add(csGSMFields51);
        
        GSM_Custom_Settings__c csGSMFields53 =new GSM_Custom_Settings__c();
        csGSMFields53.Name='AddressDoctor#PhoneLicenseKey';
        csGSMFields53.Value__c= '6AE4A6A1A6F2ECA5CFE3' ;
        lstGSM.add(csGSMFields53);
        
        GSM_Custom_Settings__c csGSMFields54 =new GSM_Custom_Settings__c();
        csGSMFields54.Name='AddressDoctor#PhoneRemainingLicenses';
        csGSMFields54.Value__c= '6371' ;
        lstGSM.add(csGSMFields54); 
        
        GSM_Custom_Settings__c csGSMFields55 =new GSM_Custom_Settings__c();
        csGSMFields55.Name='AddressDoctor#SpecialCharactersPhone';
        csGSMFields55.Value__c= '!@ #$%^&*()-_=+";:{}<>,.?/' ;
        lstGSM.add(csGSMFields55);    	
        
        GSM_Custom_Settings__c csGSMFields56 =new GSM_Custom_Settings__c();
        csGSMFields56.Name='TaskTriggerCls#ActivityToStampOnLead';
        csGSMFields56.Value__c= 'Call,Follow up - Contact in Future,%Email%' ;
        lstGSM.add(csGSMFields56); 
        
        GSM_Custom_Settings__c csGSMFields57 =new GSM_Custom_Settings__c();
        csGSMFields57.Name='ApprovalHistory#SysAdminId';
        csGSMFields57.Value__c= adminId ;
        lstGSM.add(csGSMFields57);    	
        
        GSM_Custom_Settings__c csGSMFields58 =new GSM_Custom_Settings__c();
        csGSMFields58.Name='CMGProfileId';
        csGSMFields58.Value__c= '00eA0000000QpQU' ;
        lstGSM.add(csGSMFields58);
        
        GSM_Custom_Settings__c csGSMFields59 =new GSM_Custom_Settings__c();
        csGSMFields59.Name='OpptyTriggerClass#DelegatedApprover';
        csGSMFields59.Value__c= 'Channel - Delegated Approver';
        lstGSM.add(csGSMFields59);
        
        //Start of changes by sharath for the 16.6 release
        
        //SC_BOCC_Setup__c boccCs = new SC_BOCC_Setup__c();
        //boccCs.Name='BOCC';
        //boccCs.Product_Id__c = 'BOCC Product';
        //Insert boccCs;      
        
        //End of changes by sharath for the 16.6 release  
        
        //Start of changes for CR 3125261 by shprasan
        
        List <PSA_Settings__c> lstpsaSettings = new List <PSA_Settings__c>();
        
        PSA_Settings__c psaSetting1 = new PSA_Settings__c();
        psaSetting1.Name = 'FromEmailAdress';
        if(URL.getSalesforceBaseUrl().toExternalForm().contains('qa') || URL.getSalesforceBaseUrl().toExternalForm().contains('QA'))
        {
            psaSetting1.Value__c = 'qa-ps-notify@akamai.com';
        }
        else
        {
            psaSetting1.Value__c = 'prod-ps-notify@akamai.com';            
        }
        lstpsaSettings.add(psaSetting1);
        
        PSA_Settings__c psaSetting2 = new PSA_Settings__c();
        psaSetting2.Name = 'GSS Team Email';
        psaSetting2.Value__c = 'GSS-compliance-qa@akamai.com';
        lstpsaSettings.add(psaSetting2);
        
        PSA_Settings__c psaSetting3 = new PSA_Settings__c();
        psaSetting3.Name = 'Engineering Team Email';
        psaSetting3.Value__c = 'services-engg-qa@akamai.com';
        lstpsaSettings.add(psaSetting3);
        
        PSA_Settings__c psaSetting4 = new PSA_Settings__c();
        psaSetting4.Name = 'CRM Integration';
        psaSetting4.Value__c = '00eA0000000QpNL';
        lstpsaSettings.add(psaSetting4);
        
        PSA_Settings__c psaSetting5 = new PSA_Settings__c();
        psaSetting5.Name = 'TimeCardReminderTemplate';
        psaSetting5.Value__c = 'PSA_Timecard_Reminder_Template';
        lstpsaSettings.add(psaSetting5);
        
        PSA_Settings__c psaSetting6 = new PSA_Settings__c();
        psaSetting6.Name = 'JobNotificationAdress';
        if(URL.getSalesforceBaseUrl().toExternalForm().contains('qa'))
        {
            psaSetting6.Value__c = 'qa-ps-notify@akamai.com';
        }
        else
        {
            psaSetting6.Value__c = 'prod-ps-notify@akamai.com';            
        }
        lstpsaSettings.add(psaSetting6);
        
        PSA_Settings__c psaSetting7 = new PSA_Settings__c();
        psaSetting7.Name = 'Work Item Limit';
        psaSetting7.Value__c = '1000';
        lstpsaSettings.add(psaSetting7);
        
        SC_DGRAT_Reorg_Mapping__c dgrat = new SC_DGRAT_Reorg_Mapping__c();
        dgrat.Geography_AMERICAS__c = 'Carrier Americas, Media Americas, Web Americas, CSPs Americas, Global CSPs, Enterprise Americas, Platforms';
        dgrat.Geography_APJ__c = 'Carrier APJ, Media APJ, Media APJ Acquisition, Media APJ Adjust, Web APJ, Web APJ Acquisition, Web APJ Adjust, Enterprise APJ';
        dgrat.Geography_EMEA__c = 'Carrier EMEA, Media EMEA, Web EMEA, Enterprise EMEA';
        
        //End of changes for CR 3125261 by shprasan
        
        /*Address_Validation_Class_Settings__c csAddValidation = new Address_Validation_Class_Settings__c(); //SFDC-2304
        csAddValidation.Name = 'v1.0';
        csAddValidation.Country_Error__c='Country field is mandatory. Please review "List of valid countries and states" link under FAQ';
        csAddValidation.Country_Error_USA__c='Please enter a valid country. Note - State is mandatory for USA and Canada. Please review "List of valid countries and states" link under FAQ';
        csAddValidation.country_primary_address__c = 'Country is required for Primary Address. Note - State is mandatory for USA and Canada. Please review "List of valid countries and states" link under FAQ';
        csAddValidation.country_primary_contact__c = 'Country is required for Primary Contact Address. Note - State is mandatory for USA and Canada. Please review "List of valid countries and states" link under FAQ.';
        csAddValidation.country_valid_error__c = 'Please enter a valid state for the selected country. Please review "List of valid countries and states" link under FAQ.';
        csAddValidation.Profile_Exceptions__c = adminId;
        csAddValidation.State_Mandatory_error__c = 'State is mandatory for the selected Country. Please review "List of valid countries and states" link under FAQ.';
        csAddValidation.Street_lines_error__c = 'Street field can accept a maximum of 3 lines.';
        csAddValidation.TBD__c = 'TBD';*/ //SFDC-2304
        
        
        List <Features_Toggle__c> csFeatureList = new List <Features_Toggle__c>();
        Features_Toggle__c csFeature1 = new Features_Toggle__c();
        csFeature1.Name = 'AutoPDRAUpdateOnAcctInsert';
        csFeature1.Disabled_Alert_Message__c='';
        csFeature1.Toggle__c=true;
        csFeatureList.add(csFeature1);
        
        Features_Toggle__c csFeature2 = new Features_Toggle__c(); 
        csFeature2.Name = 'Oppty Products-Other Drop & Add';
        csFeature2.Disabled_Alert_Message__c='';
        csFeature2.Toggle__c=true;
        csFeatureList.add(csFeature2);
        
        Features_Toggle__c csFeature3 = new Features_Toggle__c(); 
        csFeature3.Name = 'UpdateContactOwnerForInActiveUsers';
        csFeature3.Disabled_Alert_Message__c='';
        csFeature3.Toggle__c=false;
        csFeatureList.add(csFeature3);
        
        Features_Toggle__c csFeature4 = new Features_Toggle__c(); 
        csFeature4.Name = 'UserActivationSendEmail';
        csFeature4.Disabled_Alert_Message__c='';
        csFeature4.Toggle__c=true;
        csFeatureList.add(csFeature4);  
        
        Features_Toggle__c csFeature5= new Features_Toggle__c(); 
        csFeature5.Name = 'isContractShareEnabled';
        csFeature5.Disabled_Alert_Message__c='';
        csFeature5.Toggle__c=true;
        csFeatureList.add(csFeature5);

        //Start of changes for CR-2746200
        
        Features_Toggle__c csFeature6= new Features_Toggle__c(); 
        csFeature6.Name = 'UpdateChannelManagerToOpptySalesTeam';
        csFeature6.Disabled_Alert_Message__c='';
        csFeature6.Toggle__c=true;
        csFeatureList.add(csFeature6);
        
        Features_Toggle__c csFeature7= new Features_Toggle__c(); 
        csFeature7.Name = 'isOOTBForecastingEnabled';
        csFeature7.Disabled_Alert_Message__c='This feature is currently unavailable. Please contact CRM Admins <eae-ops@akamai.com> for assistance.';
        csFeature7.Toggle__c=true;
        csFeatureList.add(csFeature7);
        
        //End of changes for CR-2746200
        
        //Start of changes by shprasan
        Features_Toggle__c csFeature8= new Features_Toggle__c(); 
        csFeature8.Name = 'Partner Sellable Country Toggle';
        csFeature8.Disabled_Alert_Message__c='This feature is currently unavailable. Sorry for the inconvenience. Please contact your System Administrator for assistance.';
        csFeature8.Toggle__c=false;
        csFeatureList.add(csFeature8);
        
        Features_Toggle__c csFeature9= new Features_Toggle__c(); 
        csFeature9.Name = 'PostRefreshActivitySwitch';
        csFeature9.Disabled_Alert_Message__c='';
        csFeature9.Toggle__c=false;
        csFeatureList.add(csFeature9);
        
        //End of change sby shprasan
        
        /*UserTriggerClassSettings__c csUTClassSetting = new UserTriggerClassSettings__c(); //SFDC-2304
        csUTClassSetting.Name = 'v1.0';
        csUTClassSetting.exemptedUserAlias__c= 'TestAlias';*/ //SFDC-2304
                
                /*Account_Reassignment_Settings__c csAccountReAssign = new Account_Reassignment_Settings__c(); //Custom Setting for Contact Fields //SFDC-2304
        csAccountReAssign.Name = 'RuleExceptionProfileIds';
        csAccountReAssign.Value__c=adminId;*/ //SFDC-2304
                //SFDC-2572
                /*List <PRM_Settings__c> csPRMList = new List <PRM_Settings__c>();
        PRM_Settings__c csPRM1 = new PRM_Settings__c();
        csPRM1.Name = 'Partner Admin Id';
        csPRM1.Value__c = '00eA0000000e5Hs';
        csPRMList.add(csPRM1);
        
        PRM_Settings__c csPRM2 = new PRM_Settings__c();
        csPRM2.Name = 'Partner Admin Profile';
        csPRM2.Value__c = 'Akamai Partner Administrator';
        csPRMList.add(csPRM2); 

		//Start of changes for CR-2746200

        PRM_Settings__c csPRM3 = new PRM_Settings__c();
        csPRM3.Name = 'Channel manager profile id';
        csPRM3.Value__c = '00eA0000000QkKx';
        csPRMList.add(csPRM3); */    

        //End of changes for CR-2746200     
        
        
        List <Email_to_Case__c> csEmailCaseList = new List <Email_to_Case__c>();
        
        Email_to_Case__c csEmailCase1 = new Email_to_Case__c();
        csEmailCase1.Name = 'Momentum';
        csEmailCase1.CaseRecord__c= '012A0000000OWfW';
        csEmailCaseList.add(csEmailCase1);
        
        Email_to_Case__c csEmailCase2 = new Email_to_Case__c();
        csEmailCase2.Name = 'ProdMgmt';
        csEmailCase2.CaseRecord__c= '012A0000000OmQ8';
        csEmailCaseList.add(csEmailCase2);
        
        Email_to_Case__c csEmailCase3 = new Email_to_Case__c();
        csEmailCase3.Name = 'CollectionsEmailToCase';
        csEmailCase3.CaseRecord__c= '012G0000000yfp1';
        csEmailCase3.ContextAlias__c = 'CRMOPS';
        csEmailCase3.delimiter__c = 'Case #';
        csEmailCase3.EmailTemplate__c = '00XA0000000bwQE';
        csEmailCase3.GroupEmail__c = 'crm-help@akamai.com';
        csEmailCase3.Severity__c = '3 - Difficult to do job';
        csEmailCase3.reporterId__c = '0B7A0000000CaWW';
        csEmailCase3.OrgWide__c = '0D2G00000004D7SKAU';
        csEmailCase3.Priority__c = 'Medium';
        csEmailCase3.Queue_Email__c = 'crm-test@akamai.com';
        
        csEmailCaseList.add(csEmailCase3);
        
        PartnerNetworkConnection connection = [Select id, ConnectionName from PartnerNetworkConnection where connectionStatus = 'Accepted' limit 1];
       
        Environment_Setup__c environSetup = new Environment_Setup__c();
        environSetup.Environment_Type__c = 'Primary';
        environSetup.Akam_Id_Start_String__c = 'F-';
        environSetup.Active_Org__c = true;
        if(connection != null){
        	environSetup.ConnectionId__c = connection.Id;
            environSetup.Connection_Name__c = connection.ConnectionName;
        }
        
        /*Countries__c country = new Countries__c(); //SFDC-2304
        country.Name = 'India';
        country.Check_State__c = false;*/ //SFDC-2304
        
        Communities_Settings__c community = new Communities_Settings__c();
        community.Name = 'Community';
        community.Communities_User_Account_Id__c = '001G0000014uFDR';
        community.Self_Registration_Community_Profile_Id__c = '00eG0000000egHE';
        community.User_Name_Append_Value__c = '.akamai' ;
        
        List <SCRecordTypeCustomSetting__c> SCRecordTypes = new List <SCRecordTypeCustomSetting__c>();    
        SCRecordTypeCustomSetting__c SCRecordType1 = new SCRecordTypeCustomSetting__c();
        SCRecordType1.Name = 'AccountTeam';
        SCRecordtype1.RecordTypeName__c = 'Technical&&AMG';
        SCRecordtype1.RecordTypeDeveloperName__c = '';
        SCRecordTypes.add(SCRecordtype1);

        SCRecordTypeCustomSetting__c SCRecordType2 = new SCRecordTypeCustomSetting__c();
        SCRecordType2.Name = 'NotificationTeam';
        SCRecordType2.RecordTypeName__c = 'Professional Services&&AMG&&Technical';
        SCRecordType2.RecordTypeDeveloperName__c = '';
        SCRecordTypes.add(SCRecordtype2);
        
        SCRecordTypeCustomSetting__c SCRecordType3 = new SCRecordTypeCustomSetting__c();
        SCRecordType3.Name = 'ReopenRT';
        SCRecordType3.RecordTypeName__c = '';
        SCRecordType3.RecordTypeDeveloperName__c = 'Managed_Security';
        SCRecordTypes.add(SCRecordtype3);
        
        SCRecordTypeCustomSetting__c SCRecordType4 = new SCRecordTypeCustomSetting__c();
        SCRecordType4.Name = 'SCAutoSubjectRT';
        SCRecordType4.RecordTypeName__c = 'AMG,Billing,BOCC,Carrier Products,Emerging Products Engineering,Encoder Qualification,Managed Security,Professional Services,Stability Engineering,Technical';
        SCRecordType4.RecordTypeDeveloperName__c = '';
        SCRecordTypes.add(SCRecordtype4);
        
        List<SC_FromEmailAddress__c> FromEmails = new List<SC_FromEmailAddress__c>();
        SC_FromEmailAddress__c FromEmail = new SC_FromEmailAddress__c();
        FromEmail.Name = 'TechnialCaseNotification';
        FromEmail.FromAddress__c = 'sf-no-reply-qa@akamai.com';
        FromEmails.add(FromEmail);
        
        FromEmail = new SC_FromEmailAddress__c();
        FromEmail.Name = 'Noreply';
        FromEmail.FromAddress__c = 'sf-no-reply-qa@akamai.com';
        FromEmails.add(FromEmail);
        
        FromEmail = new SC_FromEmailAddress__c();
        FromEmail.Name = 'managedsecurity';
        FromEmail.FromAddress__c = 'managedsecurity@akamai.com';
        FromEmail.OrgAddressId__c = '0D2G00000004G4xKAE';
        FromEmails.add(FromEmail);
        
        FromEmail = new SC_FromEmailAddress__c();
        FromEmail.Name = 'CPSIntegration';
        FromEmail.FromAddress__c = 'tehdrczozvvf@zfmpvdyl.com';
        FromEmail.OrgAddressId__c = '0D2G00000004FpY';
        FromEmails.add(FromEmail);
        
        
        List<SC_ECOB_Report_ID__c> scECOBReports = new List<SC_ECOB_Report_ID__c>();
        SC_ECOB_Report_ID__c scRep = new SC_ECOB_Report_ID__c();
        scRep.ECOB_No_Day__c = -1;
        scRep.Name = 'ECOB No Day';
        scECOBReports.add(scRep);
        
        SC_ECOB_Report_ID__c scRep1 = new SC_ECOB_Report_ID__c();
        scRep1.ECOB_No_Day__c = -1;
        scRep1.Name = 'ECOB Contract-Detail Information';
        scRep1.Report_ID__c='00OG0000007IANU';
        scECOBReports.add(scRep1);
        
        List<SCUserIdCustomSetting__c> lSCUserIds = new List<SCUserIdCustomSetting__c>();
        SCUserIdCustomSetting__c portalUserId = new SCUserIdCustomSetting__c();
        portalUserId.Name = 'LunaPortalIntegration';
        portalUserId.UserId__c = '005G0000003dnrRIAQ';
        lSCUserIds.add(portalUserId);
        
        SCUserIdCustomSetting__c psQueueId = new SCUserIdCustomSetting__c();
        psQueueId.Name = 'Primary/SecondaryAssignmentQueue';
        psQueueId.UserId__c = '00GG0000002igPLMAY';
        lSCUserIds.add(psQueueId);
        
        SCUserIdCustomSetting__c lunaUserID = new SCUserIdCustomSetting__c();
        lunaUserID.Name = 'LunaCaseMgmtUserID';
        lunaUserID.UserId__c = '005G0000003dnrRIAQ';
        lSCUserIds.add(lunaUserID);
        
        SCUserIdCustomSetting__c pulsarUserID = new SCUserIdCustomSetting__c();
        pulsarUserID.Name = 'PulsarCaseMgmtUserID';
        pulsarUserID.UserId__c = '005m0000002HWFa';
        lSCUserIds.add(pulsarUserID);
        
        SCUserIdCustomSetting__c billingQueueId = new SCUserIdCustomSetting__c();
        billingQueueId.Name = 'Billing Queue';
        billingQueueId.UserId__c = '00GG0000002igOuMAI';
        lSCUserIds.add(billingQueueId);
        
        SCUserIdCustomSetting__c cashApp = new SCUserIdCustomSetting__c();
        cashApp.Name = 'Cash Apps';
        cashApp.UserId__c = Userinfo.getUserId();
        lSCUserIds.add(cashApp);
        
        SC_PSEditCaseProfileId__c psCS = new SC_PSEditCaseProfileId__c();
        psCS.Name = 'LunaPortalIntegration';
        psCS.ProfileId__c = '00eG0000000f0ZFIAY';
        
        Web_Entitlements__c wEnt = new Web_Entitlements__c();
        wEnt.Entitlement_Name__c = 'Premium';
        wEnt.Record_Type__c = 'Technical ';
        wEnt.Name = 'TecPremium';
        wEnt.Support_Level__c = 'Premium';
        
        list<EBCS_Application__c> EB_ApplicationSettings = new list<EBCS_Application__c>();
        
        EBCS_Application__c EAS1 = new EBCS_Application__c();
        EAS1.Name = 'EnvironmentURL';
        EAS1.Value__c = 'https://akamai--test.cs11.my.salesforce.com/';
        EB_ApplicationSettings.add(EAS1);
        
        EBCS_Application__c EAS2 = new EBCS_Application__c();
        EAS2.Name='UseOrgWideEmailAddress';
        EAS2.Value__c = 'TRUE';
        EB_ApplicationSettings.add(EAS2);
        
        EBCS_Application__c EAS3 = new EBCS_Application__c();
        EAS3.Name = 'OrgWideEmailAddressName';
        EAS3.Value__c = 'Akamai Customer Care';
        EB_ApplicationSettings.add(EAS3);
        
        EBCS_Application__c EAS4 = new EBCS_Application__c();
        EAS4.Name = 'OrgWideReplyToEmailAddressName';
        EAS4.Value__c = 'ccare-replyTo';
        EB_ApplicationSettings.add(EAS4);
        
        EBCS_Application__c EAS5 = new EBCS_Application__c();
        EAS5.Name = 'SingleMailsBatchSize';
        EAS5.Value__c = '1';
        EB_ApplicationSettings.add(EAS5);
        
        EBCS_Application__c EAS6 = new EBCS_Application__c();
        EAS6.Name = 'MassMailsBatchSize';
        EAS6.Value__c = '1';
        EB_ApplicationSettings.add(EAS6);
        
        EBCS_Application__c EAS9 = new EBCS_Application__c();
        EAS9.Name = 'CastIron URL';
        EAS9.Value__c = 'http://172.27.8.43/';
        EB_ApplicationSettings.add(EAS9);
        
        
        EBCS_Application__c EAS7 = new EBCS_Application__c();
        EAS7.Name = 'InternalContactId';
        EAS7.Value__c = '003Z000000nSfuu';
        EB_ApplicationSettings.add(EAS7);
        
        EBCS_Application__c EAS8 = new EBCS_Application__c();
        EAS8.Name = 'UpdateTemplateBatchSize';
        EAS8.Value__c = '1000';
        EB_ApplicationSettings.add(EAS8);
        
        EBCS_Application__c EAS10 = new EBCS_Application__c();
        EAS10.Name = 'LimitSQL';
        EAS10.Value__c = '1000';
        EB_ApplicationSettings.add(EAS10);
        
        EBCS_Application__c EAS11 = new EBCS_Application__c();
        EAS11.Name = 'DebugSQL';
        EAS11.Value__c = 'TRUE';
        EB_ApplicationSettings.add(EAS11);
        
        EBCS_Application__c EAS12 = new EBCS_Application__c();
        EAS12.Name = 'RowsPerPage';
        EAS12.Value__c = '3';
        EB_ApplicationSettings.add(EAS12);
        
        list<EBCS_Reports__c> EBReport = new list<EBCS_Reports__c>();
        EBCS_Reports__c er1 = new EBCS_Reports__c();
        er1.Name ='Mailer Exception Report';
        er1.ReportId__c='00OA0000002t4MY';
        EBReport.add(er1);    
        
        EBCS_Reports__c er2 = new EBCS_Reports__c();
        er2.Name ='Email Bounce Report';
        er2.ReportId__c = '00OA0000002uoVy';
        EBReport.add(er2);   
        
        EBCS_Reports__c er3 = new EBCS_Reports__c();
        er3.Name = 'Mailer Warning Report';
        er3.ReportId__c= '00OA0000002t4Mb';
        EBReport.add(er3);
        
        EBCS_UseActionPollerToSendMails__c UseActionPoller = new EBCS_UseActionPollerToSendMails__c();
        UseActionPoller.EB_UseActionPoller__c = 'True';
        UseActionPoller.EB_UseActionPollerMassEmails__c = 'True';
        UseActionPoller.EB_UseActionPollerUpdateTemplates__c = 'True';
        
        EBCS_CNProgressImages__c ImageSettings = new EBCS_CNProgressImages__c();
        ImageSettings.Processed2__c = '015G000000192x1';
        ImageSettings.Failed__c = '015G000000192x3';
        ImageSettings.InProcess__c = '015G000000192x2';
        
        SC_RiverbedCaseProdID__c scCasePrd = new SC_RiverbedCaseProdID__c();
        scCasePrd.Name = 'Riverbed_SAAS_OEM';
        scCasePrd.Case_Product_ID__c = 'a0TG0000003wloVMAQ';
        scCasePrd.RecordTypeID__c = '012G0000000z10xIAA';
        
        SC_NQLB_Record_Type_Id__c scNQLBRecType = new SC_NQLB_Record_Type_Id__c();
        scNQLBRecType.JIVECommunityAccount__c = '0015B00000O28wh';
        scNQLBRecType.UserId__c = '005G00000056qJW';
        
        List<EntitlementID__c> lEntId = new List<EntitlementID__c>();
        
        EntitlementID__c entId = new EntitlementID__c();
        entId.Case_Record_Type__c = 'Technical';
        entId.Name = 'AMPStandard';
        entId.EntitlementID__c = '';
        lEntId.add(entId);
        
        //Start of Change for ESESP-4020
        
        List<Agent_Home_Collection_Limit__c> lstHomeCollection=new List<Agent_Home_Collection_Limit__c>();
        
        Agent_Home_Collection_Limit__c hc1 = new Agent_Home_Collection_Limit__c();
        hc1.Name = 'HomeScreenLimit ';
        hc1.Collection_Limit__c = 300 ;
        lstHomeCollection.add(hc1);
        
        
        Agent_Home_Collection_Limit__c hc2 = new Agent_Home_Collection_Limit__c();
        hc2.Name = 'Limit Value';
        hc2.Collection_Limit__c =500;
        lstHomeCollection.add(hc2);
        
        List<SCUserIdCustomSetting__c> lstSCUserId = new List<SCUserIdCustomSetting__c>();
        
        SCUserIdCustomSetting__c uid1 = new SCUserIdCustomSetting__c();
        uid1.Name = 'HomeScreenReportId';
        uid1.UserId__c = '00OG0000007Hksv';
        lstSCUserId.add(uid1);
        
        SCUserIdCustomSetting__c uid2 = new SCUserIdCustomSetting__c();
        uid2.Name = 'HomeScreenLOEReportId';
        uid2.UserId__c = '00OG0000007Hkw4';
        lstSCUserId.add(uid2);
        
        List<SC_Smart_Template_Loader_Conf__c> lstTemplateLoader = new List<SC_Smart_Template_Loader_Conf__c>();
        
        SC_Smart_Template_Loader_Conf__c temploader = new SC_Smart_Template_Loader_Conf__c();
        temploader.Name = 'DefaultTemplateNameConsole';
        temploader.Template_Name__c  = 'SC_Default_with_AKAM_CaseID';
        
        lstTemplateLoader.add(temploader);
        
        EntitlementID__c entId1 = new EntitlementID__c();
        entId1.Case_Record_Type__c = 'Community Response';
        entId1.Name = 'Community Response';
        entId1.EntitlementID__c = '';
         lEntId.add(entId1);
        
        SC_SOC_SpecInstr__c  socSpec = new SC_SOC_SpecInstr__c();
        socSpec.Name = 'Exclude Record Type';
        socSpec.Record_Type_Name__c = 'Managed Security';
        
        
        List<SC_External_Links__c> lExtLinks = new List<SC_External_Links__c>();
        
        SC_External_Links__c extLink1 = new SC_External_Links__c();
        extLink1.Name = 'Cracker';
        extLink1.category__c = 'Case';
        extLink1.has_merge_Fields__c = False;
        extLink1.URL__c ='https://tools.gss.akamai.com/crack/crack.cgi';
        extLink1.URL_Name__c = 'Cracker';
        extLink1.openURLInServiceCLoud__c = True;
        lExtLinks.add(extLink1);
        
        SC_External_Links__c extLink2 = new SC_External_Links__c();
        extLink2.Name = 'Debug Parser';
        extLink2.category__c = 'Case';
        extLink2.has_merge_Fields__c = False;
        extLink2.URL__c ='https://tools.gss.akamai.com/dparser/';
        extLink2.URL_Name__c = 'Debug Parser';
        extLink2.openURLInServiceCLoud__c = True;
        lExtLinks.add(extLink2);
        
        SC_External_Links__c extLink3 = new SC_External_Links__c();
        extLink3.Name = 'eStats';
        extLink3.category__c = 'Case';
        extLink3.has_merge_Fields__c = False;
        extLink3.URL__c ='https://tools.gss.akamai.com/estats/';
        extLink3.URL_Name__c = 'eStats';
        extLink3.openURLInServiceCLoud__c = True;
        lExtLinks.add(extLink3);
        
        SC_External_Links__c extLink4 = new SC_External_Links__c();
        extLink4.Name = 'IP Tool';
        extLink4.category__c = 'Case';
        extLink4.has_merge_Fields__c = False;
        extLink4.URL__c ='https://tools.gss.akamai.com/ip-host-search/';
        extLink4.URL_Name__c = 'IP Tool';
        extLink4.openURLInServiceCLoud__c = True;
        lExtLinks.add(extLink4);
        
        SC_External_Links__c extLink5 = new SC_External_Links__c();
        extLink5.Name = 'Log Parser';
        extLink5.category__c = 'Case';
        extLink5.has_merge_Fields__c = False;
        extLink5.URL__c ='http://lp.engr.akamai.com/';
        extLink5.URL_Name__c = 'Log Parser';
        extLink5.openURLInServiceCLoud__c = False;
        lExtLinks.add(extLink5);
        
        SC_External_Links__c extLink6 = new SC_External_Links__c();
        extLink6.Name = 'Mapper';
        extLink6.category__c = 'Case';
        extLink6.has_merge_Fields__c = False;
        extLink6.URL__c ='https://map.akamai.com/cgi-bin/FreeFlow/Analysis/m2_iptracker.pl';
        extLink6.URL_Name__c = 'Mapper';
        extLink6.openURLInServiceCLoud__c = True;
        lExtLinks.add(extLink6);
        
        SC_External_Links__c extLink7 = new SC_External_Links__c();
        extLink7.Name = 'Manage in Portal';
        extLink7.category__c = 'Case';
        extLink7.has_merge_Fields__c = True;
        extLink7.URL__c ='https://control.akamai.com/portal/search/manage_account.jsp?accountid=replaceMergeStartAKAM_Account_ID__creplaceMergeEnd';
        extLink7.URL_Name__c = 'Manage in Portal';
        extLink7.openURLInServiceCLoud__c = False;
        lExtLinks.add(extLink7);
        
        SC_External_Links__c extLink8 = new SC_External_Links__c();
        extLink8.Name = 'Command Builder';
        extLink8.category__c = 'Case';
        extLink8.has_merge_Fields__c = False;
        extLink8.URL__c ='http://info.akamai.com/~jacmacke/';
        extLink8.URL_Name__c = 'Command Builder';
        extLink8.openURLInServiceCLoud__c = False;
        lExtLinks.add(extLink8);
        
        SC_External_Links__c extLink9 = new SC_External_Links__c();
        extLink9.Name = 'Fetch & View';
        extLink9.category__c = 'Case';
        extLink9.has_merge_Fields__c = False;
        extLink9.URL__c ='https://tools.gss.akamai.com/fetch-view-logs/';
        extLink9.URL_Name__c = 'Fetch & View';
        extLink9.openURLInServiceCLoud__c = True;
        lExtLinks.add(extLink9);
        
        SC_External_Links__c extLink10 = new SC_External_Links__c();
        extLink10.Name = 'HD Troubleshooter';
        extLink10.category__c = 'Case';
        extLink10.has_merge_Fields__c = False;
        extLink10.URL__c ='http://prod-cdn-app02.kendall.corp.akamai.com/HDLiveTroubleshootingTool.html';
        extLink10.URL_Name__c = 'HD Troubleshooter';
        extLink10.openURLInServiceCLoud__c = false;
        lExtLinks.add(extLink10);
        
        SC_External_Links__c extLink11 = new SC_External_Links__c();
        extLink11.Name = 'Useful Queries';
        extLink11.category__c = 'Case';
        extLink11.has_merge_Fields__c = False;
        extLink11.URL__c ='http://info.akamai.com/~lleccia/queries.htm';
        extLink11.URL_Name__c = 'Useful Queries';
        extLink11.openURLInServiceCLoud__c = False;
        lExtLinks.add(extLink11);

        List<SC_Streaming_Settings__c> lStremSet = new List<SC_Streaming_Settings__c>();
        
        SC_Streaming_Settings__c stremSet1 = new SC_Streaming_Settings__c();
        stremSet1.Name = 'Enable LOE Streaming';
        stremSet1.Keyvalue__c = 'true';
        lStremSet.add(stremSet1);
        
        SC_Streaming_Settings__c stremSet2 = new SC_Streaming_Settings__c();
        stremSet2.Name = 'Enable SI Streaming';
        stremSet2.Keyvalue__c = 'true';
        lStremSet.add(stremSet2);
        //Creating a Custom Object Special_Instruction_Template__C
        /* titleOutputText = SITemplateMap.get(templateTitle).Title__c;
            recordTypesOutputText = SITemplateMap.get(templateTitle).Show_for_Record_Types__c;
            instructionsOutputText = SITemplateMap.get(templateTitle).Instructions__c;
            flagIconOutputText = SITemplateMap.get(templateTitle).Flag_Icon__c;  */
       
        
        //End of Change for ESESP-4020


        /*list<Sync_To_Siebel_Fields_Settings__c> lstSync = new list<Sync_To_Siebel_Fields_Settings__c>(); //SFDC-2304

Sync_To_Siebel_Fields_Settings__c sync1 = new Sync_To_Siebel_Fields_Settings__c();
sync1.Name = 'Account';
sync1.Value__c = 'Account#FieldList1';
lstSync.add(sync1);

Sync_To_Siebel_Fields_Settings__c sync2 = new Sync_To_Siebel_Fields_Settings__c();
sync2.Name = 'Account#FieldList1';
sync2.Value__c = 'ADS_Account__c, AKAM_Account_ID__c, AKAM_Parent_Account_ID__c,Billing_Integration_Id__c,BillingCity,BillingCountry,BillingPostalCode,BillingState,BillingStreet';
lstSync.add(sync2);

Sync_To_Siebel_Fields_Settings__c sync3 = new Sync_To_Siebel_Fields_Settings__c();
sync3.Name = 'Contact';
sync3.Value__c = 'Contact#FieldList1';
lstSync.add(sync3);

Sync_To_Siebel_Fields_Settings__c sync4 = new Sync_To_Siebel_Fields_Settings__c();
sync4.Name = 'Contact#FieldList1';
sync4.Value__c = 'AccountId, Active_Portal_Login__c, AKAM_Contact_ID__c, Akamai_Vertical__c, Contact_Type__c, Cumulative_Activity_Score__c, Department, Duplicate_Email__c, Email, Email_Bounce__c, Language__c';
lstSync.add(sync4);*/ //SFDC-2304
        
        System.runas(new User(Id = Userinfo.getUserId())) {
            //insert csAddValidation; //SFDC-2304
            insert csFeatureList;
            //insert csAccountReAssign; //SFDC-2304
            //SFDC-2572
            //insert csPRMList;
            insert lstGSM;
            insert csEmailCaseList;
            //insert csUTClassSetting; //SFDC-2304
            insert environSetup;
            //insert country; //SFDC-2304
            insert community;
            insert SCRecordTypes;
            insert FromEmails;
            insert lSCUserIds;
            insert wEnt;
            insert EB_ApplicationSettings;
            insert UseActionPoller;
            insert EBReport;
            insert ImageSettings;
            insert scCasePrd;
            insert scNQLBRecType;
            //insert lstSync; //SFDC-2304
            insert lstpsaSettings;
            insert psCS;
            insert dgrat;
            insert scECOBReports;
            //insert entId;
            insert lstHomeCollection;
            insert lstSCUserId;
            insert lstTemplateLoader;
            insert lEntId;
            insert socSpec;
            insert lExtLinks;
            insert lStremSet;
        }
    }
    
    //For Agent home page controller
    public static void CreateAgentPageCustomSettings()
    {
        Communities_Settings__c comSet = new Communities_Settings__c();
        comSet.Name= 'Community';
        comSet.Communities_User_Account_Id__c = '001G0000014uFDR';
        comSet.Self_Registration_Community_Profile_Id__c = '00eG0000000egHE';
        comSet.User_Name_Append_Value__c = '.akamai';
        
        Agent_Home_Collection_Limit__c aHomeSet =  new Agent_Home_Collection_Limit__c();
        aHomeSet.Name = 'Limit Value';
        aHomeSet.Collection_Limit__c = 1000;
        
        insert comSet;
        insert aHomeSet;
    } 
    public static Case CreateCase(id accID){
        Case newcase = new Case();
        newcase.AccountId = accID;
        newcase.Subject = '__ Test Subject';
        newcase.origin = 'Others';
        insert newcase;
        return newcase;
    }
    
    public static Territory_Mapping__c createTerritoryMapping(String territoryMappingName, String geo, String area_Zone)
    {
        /*Territory_Mapping__c newTerritoryMapping = new Territory_Mapping__c();
        newTerritoryMapping.Parent_Division__c = geoDivision;
        newTerritoryMapping.Region__c= area;
        List<String> splitTerritoryMappingName = new List<String>();
        splitTerritoryMappingName = territoryMappingName.split('-');
        newTerritoryMapping.Division__c = splitTerritoryMappingName[0].trim();
        newTerritoryMapping.Area__c = splitTerritoryMappingName[1].trim();*/

        Territory_Mapping__c newTerritoryMapping = new Territory_Mapping__c();
        newTerritoryMapping.Name = territoryMappingName;
        newTerritoryMapping.TERR_HIER_1__c = geo;
        newTerritoryMapping.TERR_HIER_3__c = area_Zone;
        newTerritoryMapping.TERR_HIER_4__c = area_Zone;
        List<String> splitTerritoryMappingName = territoryMappingName.split('-');
        newTerritoryMapping.TERR_HIER_2__c = splitTerritoryMappingName[0].trim();
        newTerritoryMapping.TERR_HIER_5__c = splitTerritoryMappingName[1].trim();

        return newTerritoryMapping;
    }
    
    //If the method is called without any args, just create with the below default values
    public static Territory_Mapping__c createTerritoryMapping()
    {
        return createTerritoryMapping('India - India Media Strategic', 'APJ', 'India Media Strategic');
    }
    
    public static void insertAttachment(Id objId)
    {
        Attachment att= new Attachment();
        att.Body=blob.valueOf('My new attachment');
        att.Name='Sample text.txt';
        att.ContentType='text/plain';
        att.ParentId=objId;
        insert att;
    }
    
    public static void insertCustomSettings(Map<String, String> objectToCustomSettingResource)
    {
        
        for(String objectName : objectToCustomSettingResource.keySet())
        {
            List<sObject> listOfRecords = Test.loadData(globalDescribe.get(objectName), objectToCustomSettingResource.get(objectName));
            system.assert(listOfRecords.size() > 0, 'Failed to insert ' + objectName + ' custom setting'); 
        }
        /*inserting custom setting to prevent null pointer exception coming from TaskTrigger_bi_bu
commented By Himanshu - This custom setting is not going in 4.2 Release
SC_TaskDueDate__c scTaskDueDateObj = new SC_TaskDueDate__c();
scTaskDueDateObj.Name = 'CRM Integration';
scTaskDueDateObj.UserID__c = '005Z0000002DbVzIAK';
insert scTaskDueDateObj; */
    }
    
    
    public static void insertCustomSettings(List<String> listOfCustomSettings)
    {
        //Anand Hegde - format will be
        // API Name = customSettingName + '__c'
        // Static resource = 'CS_' + customSettingName
        Map<String, String> objectToCustomSettingResource = new Map<String, String>();
        for(String customSettingName : listOfCustomSettings)
        {
            objectToCustomSettingResource.put(customSettingName+'__c', 'CS_'+customSettingName);
        }
        insertCustomSettings(objectToCustomSettingResource);
    }
    
    public static void insertCustomSettings()
    {
        //Anand Hegde - Each custom setting object is uploaded as a CSV in a static resource
        // Test.loadData loads the CSV and inserts the records
        // The CSV has to be <20KB. Otherwise you get an exception
        // Object_API_Name => Static_Resource_Name
        Map<String, String> objectToCustomSettingResource = new Map<String, String>{ 
            'PRM_Settings__c'           => 'CS_PRM_Settings', 
                'GSM_Custom_Settings__c'    => 'CS_GSM_Custom_Settings',
                'Communities_Settings__c'   => 'CS_Communities_Settings',
                'Account_Reassignment_Settings__c' => 'CS_Account_Reassignment_Settings',
                'Account_Reassignment_Class_Settings__c' => 'CS_Account_Reassignment_Class_Settings',
                'Address_Validation_Class_Settings__c' => 'CS_Address_Validation_Class_Settings',
                'Order_approval_class_settings__c' => 'CS_Order_Approval_Class_Settings',
                'Opportunity_Trigger_Class_Settings__c' => 'CS_Opportunity_Trigger_Class_Settings',
                'MDF_Configurations__c' => 'CS_MDF_Configurations',
                'UserTriggerClassSettings__c' => 'CS_UserTriggerClassSettings',
                'Features_Toggle__c' => 'CS_Features_Toggle',
                'Environment_Setup__c' => 'CS_Environment_Setup',
                'Countries__c' => 'CS_Countries',
                'States__c' => 'CS_States',
                'Sync_To_Siebel_Fields_Settings__c' => 'CS_Sync_To_Siebel_Fields_Settings',
                'Campaign_Settings__c' => 'CS_Campaign',
                'Alexa_Web_Service_Custom_Setting__c' => 'CS_Alexa_Web_Service_Custom_Setting',
                'AlexaWebServiceCountryMapping__c'   =>'CS_Alexa_Country_Mapping'
                };
                    insertCustomSettings(objectToCustomSettingResource);
    }
    
    //SFDC-1571
    public static Id insertProductAndPriceBookEntry(String currencyIsoCode,String productFamily,Decimal UnitPrice)
    {
        Product2 testProduct2= new Product2();
        testProduct2.Name = 'TEST';
        //AKAM_Product_ID__c
        testProduct2.Family = productFamily;
        insert(testProduct2);
        PricebookEntry testPriceBookEntry= new PricebookEntry();
        testPriceBookEntry.Pricebook2Id = Test.getStandardPricebookId();
        testPriceBookEntry.Product2Id   = testProduct2.id;
        testPriceBookEntry.CurrencyIsoCode = currencyIsoCode;
        testPriceBookEntry.IsActive     = true;
        testPriceBookEntry.UnitPrice    = UnitPrice;
        insert(testPriceBookEntry);
        return testPriceBookEntry.Id;
    }
    
    public static List<OpportunityLineItem> insertOpptyProductsWithFamilyAndMRR(Opportunity tempOpp, String currencyIsoCode,string productFamily,Decimal projCommit,decimal baselineCommit,integer numOfOli)
    {
        Id priceBookEntryId = utilTestClass.insertProductAndPriceBookEntry(currencyIsoCode,productFamily,projCommit-baselineCommit);
        List<OpportunityLineItem> listOfOpportunityLineItems= new OpportunityLineItem[]{};
            //List<OpportunityLineItem> listOfOpportunityLineItems= new OpportunityLineItem[]{};
            for(Integer index=0; index<numOfOli;index++){
                OpportunityLineItem tempOLI = new OpportunityLineItem();
                tempOLI.opportunityId       = tempOpp.id;
                tempOLI.pricebookentryid    = priceBookEntryId;
                tempOLI.quantity            = 12;
                tempOLI.unitprice           = projCommit - baselineCommit;
                tempOLI.Projected_Monthly_commit_fees__c = projCommit;
                tempOLI.Average_Renewal_Commit_MRR__c =baselineCommit;
                tempOLI.NRR__c = 108;
                //SFDC-1453
                tempOLI.Average_Renewal_Usage_MRR__c = 100;
                tempOLI.Projected_Avg_Rev_Non_Commit__c = 200;
                tempOLI.NRR__c = 108;
                listOfOpportunityLineItems.add(tempOLI);
            }
        
        return listOfOpportunityLineItems;
    }
    
    public static Id insertProductAndPriceBookEntry(String currencyIsoCode)
    {
        Product2 testProduct2= new Product2();
        testProduct2.Name = 'TEST';
        insert(testProduct2);
        PricebookEntry testPriceBookEntry= new PricebookEntry();
        testPriceBookEntry.Pricebook2Id = Test.getStandardPricebookId();
        testPriceBookEntry.Product2Id   = testProduct2.id;
        testPriceBookEntry.CurrencyIsoCode = currencyIsoCode;
        testPriceBookEntry.IsActive     = true;
        testPriceBookEntry.UnitPrice    = 1;
        insert(testPriceBookEntry);
        return testPriceBookEntry.Id;
    }
    
    public static Map<Id, List<OpportunityLineItem>> insertOpptyProductForEach(List<Opportunity> listOfOpp, Integer numberOfOpptyProductsForEachOppty, String currencyIsoCode)
    {
        Id priceBookEntryId = insertProductAndPriceBookEntry(currencyIsoCode);
        Map<Id, List<OpportunityLineItem>> opptyIdToOLIList= new Map<Id, List<OpportunityLineItem>>();
        List<OpportunityLineItem> listOfOpportunityLineItems= new OpportunityLineItem[]{};
            for(Opportunity tempOpp : listOfOpp )
        {
            opptyIdToOLIList.put(tempOpp.Id, new List<OpportunityLineItem>());
            for(Integer i=0;i<numberOfOpptyProductsForEachOppty;i++)
            {
                OpportunityLineItem tempOLI = new OpportunityLineItem();
                tempOLI.opportunityId       = tempOpp.id;
                tempOLI.pricebookentryid    = priceBookEntryId;
                tempOLI.quantity            = 12;
                tempOLI.unitprice           = 108+i;
                tempOLI.Projected_Monthly_commit_fees__c = 208+i;
                tempOLI.Average_Renewal_Commit_MRR__c =100;
                tempOLI.NRR__c = 108;
                //SFDC-1453
                tempOLI.Average_Renewal_Usage_MRR__c = 100;
                tempOLI.Projected_Avg_Rev_Non_Commit__c = 200;
                tempOLI.NRR__c = 108;
                listOfOpportunityLineItems.add(tempOLI);
                
                opptyIdToOLIList.get(tempOpp.Id).add(tempOLI);
            }
        }
        
        insert listOfOpportunityLineItems;
        return opptyIdToOLIList;
    }
    
    public static Map<Id, List<OpportunityLineItem>> insertOpptyProductForEach(Opportunity opp, Integer numberOfOpptyProductsForEachOppty, String currencyIsoCode)
    {
        return insertOpptyProductForEach(new List<Opportunity>{opp}, numberOfOpptyProductsForEachOppty, currencyIsoCode);
    }
    
    // Start of Testdata Creation for test class of CR-2697069 
    public Static user  testUserCreation( String ProfileName, String salias , String lName ,String mail, String usern){
        Profile pr = [select id from profile where name=: ProfileName][0];
        User usObj = new User(alias = salias, email= mail,emailencodingkey='UTF-8', lastname=lname, languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username= usern ,profileid = pr.Id);
        insert usObj;
        return usObj;
        
    }
    
    //TestData: Single AccountCreation
    public  static id AccountCreation(Id userId, String accName , String web){
        Account acc = new Account(Name =accName, Website = web,OwnerId = UserId);    
        insert acc;
        return acc.id;
        
    }
    
    // Multiple TestDataContract Creation
    public  static void multipleContractCreation(Integer count, Id accId){
        List<Merge_Contract_Header__c> mchList = new List<Merge_Contract_Header__c>();
        for(Integer ci= 0 ;  ci < count ; ci++ ){
            Merge_Contract_Header__c mchObj = new Merge_Contract_Header__c(Name = 'TestContract'+ ci , Account_Name__c = accid);  
            mchList.add(mchObj);
        }
        insert mchList;
    }
    //End of Testdata Creation for test class of CR-2697069 
    
    // Main method for All Service Cloud Autogen Custom Setting Sub Methods - Himanshu
    public static void SC_Autogen_init_Method()
    {
        // 1. Create Custom Setting Data for - SC Autogen Case Freq
        createData_SC_Autogen_Case_Freq();
        
        // 2. Create Custom Setting Data for - SC Autogen Running Freq
        createData_SC_Autogen_Run_Freq();
        
        // 3. Create Custom Setting Data for - SC_Account_Geo
        createData_SC_Account_Geo();
        
        // 4. Create Custom Setting Data for - SC_AutoGencase - Activity
        createData_SC_AutoGencase_Activity();
        
        // 5. Create Custom Setting Data for - SC_AutoGen_RUS_Cal
        createData_SC_AutoGen_RUS_Cal();
        
        // 6. Create Custom Setting Data for - SC_PPSM_Config
        createData_SC_PPSM_Config();
        
        // 7. Create Custom Setting Data for - SC_Serv_ReqTyp_value
        createData_SC_Serv_ReqTyp_value();
        
        // 8. Create Custom Setting Data for - SC_SupportEmail
        createData_SC_SupportEmail();
        
        // 9. Create Custom Setting Data for - SC_TCR_WAF_ProdList
        createData_SC_TCR_WAF_ProdList();
        
        // 10. Create Custom Setting Data for - SCUserIdCustomSetting
        createData_SCUserIdCustomSetting();
    }
    
    // Method-1 : For Creating SC Autogen Case Freq
    public static void createData_SC_Autogen_Case_Freq(){
        
        // List to Insert All Case Freq Data
        List<SC_Autogen_Case_Freq__c> caseFreqRecInsert = new List<SC_Autogen_Case_Freq__c>();
        
        // For Each Record
        SC_Autogen_Case_Freq__c caseFreqRec;
        
        caseFreqRec = new SC_Autogen_Case_Freq__c();
        caseFreqRec.Name                    = 'QBR';
        caseFreqRec.Initial_Freq__c         = 0;
        caseFreqRec.Subsequent_Freq_in_Days__c  = 0;
        caseFreqRec.Subsequent_Freq_in_Months__c    = 3;
        caseFreqRecInsert.add(caseFreqRec);
        
        caseFreqRec = new SC_Autogen_Case_Freq__c();
        caseFreqRec.Name                    = 'RUS';
        caseFreqRec.Initial_Freq__c         = 14;
        caseFreqRec.Subsequent_Freq_in_Days__c  = 0;
        caseFreqRec.Subsequent_Freq_in_Months__c    = 0;
        caseFreqRecInsert.add(caseFreqRec);
        
        caseFreqRec = new SC_Autogen_Case_Freq__c();
        caseFreqRec.Name                    = 'TCR';
        caseFreqRec.Initial_Freq__c         = 5;
        caseFreqRec.Subsequent_Freq_in_Days__c  = 0;
        caseFreqRec.Subsequent_Freq_in_Months__c    = 6;
        caseFreqRecInsert.add(caseFreqRec);
        
        caseFreqRec = new SC_Autogen_Case_Freq__c();
        caseFreqRec.Name                    = 'WAF';
        caseFreqRec.Initial_Freq__c         = 0;
        caseFreqRec.Subsequent_Freq_in_Days__c  = 0;
        caseFreqRec.Subsequent_Freq_in_Months__c    = 6;
        caseFreqRecInsert.add(caseFreqRec);
        
        caseFreqRec = new SC_Autogen_Case_Freq__c();
        caseFreqRec.Name                    = 'KONA';
        caseFreqRec.Initial_Freq__c         = 14;
        caseFreqRec.Subsequent_Freq_in_Days__c  = 0;
        caseFreqRec.Subsequent_Freq_in_Months__c    = 0;
        caseFreqRecInsert.add(caseFreqRec);
        
        caseFreqRec = new SC_Autogen_Case_Freq__c();
        caseFreqRec.Name                    = 'PIHC';
        caseFreqRec.Initial_Freq__c         = 14;
        caseFreqRec.Subsequent_Freq_in_Days__c  = 0;
        caseFreqRec.Subsequent_Freq_in_Months__c    = 0;
        caseFreqRecInsert.add(caseFreqRec);
        
        caseFreqRec = new SC_Autogen_Case_Freq__c();
        caseFreqRec.Name                    = 'SMP-Sec';
        caseFreqRec.Initial_Freq__c         = 40;
        caseFreqRec.Subsequent_Freq_in_Days__c  = 0;
        caseFreqRec.Subsequent_Freq_in_Months__c    = 0;
        caseFreqRecInsert.add(caseFreqRec);
        
        caseFreqRec = new SC_Autogen_Case_Freq__c();
        caseFreqRec.Name                    = 'KBSyncBatchSize-Document';
        //caseFreqRec.Initial_Freq__c         =  ;
        caseFreqRec.Subsequent_Freq_in_Days__c  = 3;
        //caseFreqRec.Subsequent_Freq_in_Months__c    = ;
        caseFreqRecInsert.add(caseFreqRec);
        
        // Insert all data
        Insert caseFreqRecInsert;
    }
    
    // Method-2 : For Creating SC Autogen Running Freq
    public static void createData_SC_Autogen_Run_Freq()
    {
        // List to Insert  SC_Autogen_Job_Enable_Disable__c
        SC_Autogen_Job_Enable_Disable__c scAutogenJobeEnDis = new SC_Autogen_Job_Enable_Disable__c();
        scAutogenJobeEnDis.Name = 'ECOB';
        scAutogenJobeEnDis.IsActive__c = true;
        insert scAutogenJobeEnDis;
        
        SC_Autogen_Job_Enable_Disable__c scAutogenJobeEnDis1 = new SC_Autogen_Job_Enable_Disable__c();
        scAutogenJobeEnDis1.Name = 'SMP-Project';
        scAutogenJobeEnDis1.IsActive__c = true;
        insert scAutogenJobeEnDis1;
        
        SC_AutogenJob__c scAutoJob = new SC_AutogenJob__c();
        scAutoJob.Active__c = true;
        scAutoJob.Autogen_UseCase_Name__c = 'COB';
        scAutoJob.Case_Record_Type__c = 'Professional Services';
        scAutoJob.Description__c = 'Please refer to the Guided Delivery Service Quarterly Insight steps located at: https://agora.akamai.com/wiki/Guided_Delivery_Service_Provisioning_Body_of_Knowledge#Quarterly_Insight';
        scAutoJob.Do_not_Show_in_Portal__c = true;
        scAutoJob.Initial_Frequency__c = 7;
        scAutoJob.IS_Case_Routing_Required__c = true;
        scAutoJob.IsTaskTobeCreated__c = true;
        scAutoJob.Origin__c = 'Autogen';
        scAutoJob.Product__c = 'M-LC-159905';
        scAutoJob.PS_Product__c = 'PLX Connect';
        scAutoJob.Recurring_Frequency__c = '90';
        scAutoJob.Request_Type__c = 'Onboarding / Integration';
        scAutoJob.Service__c = 'Technical Advisory Service';
        scAutoJob.Subject__c = 'Technical Advisory Service :: Customer Onboarding ::';
        scAutoJob.Severity__c = '3';
        scAutoJob.Sub_Type__c = 'BOCC';
        insert scAutoJob;
        
        // List to Insert All Run Freq Data
        List<SC_Autogen_Running_Freq__c> runFreqRecInsert = new List<SC_Autogen_Running_Freq__c>();
        
        // For Each Record
        SC_Autogen_Running_Freq__c runFreqRec;
        
        runFreqRec = new SC_Autogen_Running_Freq__c();
        runFreqRec.Name = 'COB';
        runFreqRec.Batch_Size__c = 200;
        runFreqRec.Cron_Time__c = '0 0 0-23 * * ?';
        runFreqRecInsert.add(runFreqRec);
        
        runFreqRec = new SC_Autogen_Running_Freq__c();
        runFreqRec.Name = 'SMP';
        runFreqRec.Batch_Size__c = 200;
        runFreqRec.Cron_Time__c = '75,165,255,345';
        runFreqRecInsert.add(runFreqRec);
        
        runFreqRec = new SC_Autogen_Running_Freq__c();
        runFreqRec.Name = 'TCR_WAF';
        runFreqRec.Batch_Size__c = 200;
        runFreqRec.Cron_Time__c = '0 0 0-23 * * ?';
        runFreqRecInsert.add(runFreqRec);
        
        runFreqRec = new SC_Autogen_Running_Freq__c();
        runFreqRec.Name = 'ECOB';
        runFreqRec.Batch_Size__c = 200;
        runFreqRec.Cron_Time__c = '0 0 0-23 * * ?';
        runFreqRecInsert.add(runFreqRec);
        
        runFreqRec = new SC_Autogen_Running_Freq__c();
        runFreqRec.Name = 'KBSyncBatchSize-Document';
        runFreqRec.Batch_Size__c = 3;
        //runFreqRec.Cron_Time__c = ' ';
        runFreqRecInsert.add(runFreqRec);
        
        // Insert all data
        Insert runFreqRecInsert;
        
    }
    
    // Method-3 : For Creating SC_Account_Geo
    public static void createData_SC_Account_Geo(){
        
        // List to Insert All Account_Geo Data
        List<SC_Account_Geo__c> Account_GeoInsert = new List<SC_Account_Geo__c>();
        
        // For Each Record
        SC_Account_Geo__c Account_GeoRec;
        
        Account_GeoRec = new SC_Account_Geo__c();
        Account_GeoRec.Name = 'APJ';
        Account_GeoRec.GDRT_Value__c = 'APJ';
        Account_GeoInsert.add(Account_GeoRec);
        
        Account_GeoRec = new SC_Account_Geo__c();
        Account_GeoRec.Name = 'EMEA';
        Account_GeoRec.GDRT_Value__c = 'EMEA';
        Account_GeoInsert.add(Account_GeoRec);
        
        // Insert all data
        Insert Account_GeoInsert;
        
    }
    
    // Method-4 : For Creating SC_AutoGencase - Activity
    public static void createData_SC_AutoGencase_Activity()
    {
        // List to Insert All Autogen COB Activity
        List<SC_AutoGencase_Activity__c> AutoGencase_ActivityInsert = new List<SC_AutoGencase_Activity__c>();
        
        // For Each Record
        SC_AutoGencase_Activity__c AutoGencase_ActivityRec;
        
        AutoGencase_ActivityRec = new SC_AutoGencase_Activity__c();
        AutoGencase_ActivityRec.Name = '1';
        AutoGencase_ActivityRec.Activity_Details__c = 'test';
        AutoGencase_ActivityRec.Activity_Due_date__c = '3';
        AutoGencase_ActivityRec.Activity_Name__c = 'Intro email';
        AutoGencase_ActivityInsert.add(AutoGencase_ActivityRec);
        
        AutoGencase_ActivityRec = new SC_AutoGencase_Activity__c();
        AutoGencase_ActivityRec.Name = '10';
        AutoGencase_ActivityRec.Activity_Details__c = 'test11';
        AutoGencase_ActivityRec.Activity_Due_date__c = null;
        AutoGencase_ActivityRec.Activity_Name__c = 'First Invoice Confirmation';
        AutoGencase_ActivityInsert.add(AutoGencase_ActivityRec);
        
        // Insert all data
        Insert AutoGencase_ActivityInsert;
        
        SCECOBAdditionalTask__c s = new SCECOBAdditionalTask__c();
        s.Name='ECOB Additional Task';
        s.Activity_Detail__c  = 'C/PSM raises a case for AkaTec';
        s.Activity_Due_date__c = '0';
        s.Activity_Name__c = 'AKAtec Activity';
        insert s;
        
        List<SC_Autogen_ExistingCOB_Activity__c> lst = new List<SC_Autogen_ExistingCOB_Activity__c>();
        for(Integer i=0;i<5;i++)
        {
            SC_Autogen_ExistingCOB_Activity__c sactivity = new SC_Autogen_ExistingCOB_Activity__c();
            sactivity.Activity_Detail__c = 'Test Activity'+i;
            sactivity.Activity_Due_date__c = '2';
            sactivity.Activity_Name__c = 'Test Activity'+i;
            sactivity.Name='ECoB Task'+i;
            lst.add(sactivity);
        }
        insert lst;
    }
    
    // Method-5 : For Creating SC_AutoGen_RUS_Cal
    public static void createData_SC_AutoGen_RUS_Cal(){
        
        // List to Insert All SC_AutoGen_RUS_Cal
        List<SC_AutoGen_RUS_Cal__c> SC_AutoGen_RUS_CalInsert = new List<SC_AutoGen_RUS_Cal__c>();
        
        // For Each Record
        SC_AutoGen_RUS_Cal__c SC_AutoGen_RUS_CalRec;
        
        SC_AutoGen_RUS_CalRec = new SC_AutoGen_RUS_Cal__c();
        SC_AutoGen_RUS_CalRec.Name = '12';
        SC_AutoGen_RUS_CalRec.Subsequent_Freq_in_Days__c = 0;
        SC_AutoGen_RUS_CalRec.Subsequent_Freq_in_Months__c = 1;
        SC_AutoGen_RUS_CalInsert.add(SC_AutoGen_RUS_CalRec);
        
        // Insert all data
        Insert SC_AutoGen_RUS_CalInsert;
        
    }
    
    // Method-6 : For Creating SC_PPSM_Config
    public static void createData_SC_PPSM_Config(){
        
        // List to Insert All SC_PPSM_Config
        List<SC_PPSM_Config__c> SC_PPSM_Config_Insert = new List<SC_PPSM_Config__c>();
        
        // For Each Record
        SC_PPSM_Config__c SC_PPSM_Config_Rec;
        
        SC_PPSM_Config_Rec = new SC_PPSM_Config__c();
        SC_PPSM_Config_Rec.Name = 'Freq-1';
        SC_PPSM_Config_Rec.Case_Title__c = 'Security Review';
        SC_PPSM_Config_Rec.PPSM_Freq__c = '15';
        SC_PPSM_Config_Insert.add(SC_PPSM_Config_Rec);
        
        SC_PPSM_Config_Rec = new SC_PPSM_Config__c();
        SC_PPSM_Config_Rec.Name = 'Freq-2';
        SC_PPSM_Config_Rec.Case_Title__c = 'Performance Review';
        SC_PPSM_Config_Rec.PPSM_Freq__c = '150';
        SC_PPSM_Config_Insert.add(SC_PPSM_Config_Rec);
        
        SC_PPSM_Config_Rec = new SC_PPSM_Config__c();
        SC_PPSM_Config_Rec.Name = 'Freq-3';
        SC_PPSM_Config_Rec.Case_Title__c = 'Security Review';
        SC_PPSM_Config_Rec.PPSM_Freq__c = '165';
        SC_PPSM_Config_Insert.add(SC_PPSM_Config_Rec);
        
        SC_PPSM_Config_Rec = new SC_PPSM_Config__c();
        SC_PPSM_Config_Rec.Name = 'Freq-4';
        SC_PPSM_Config_Rec.Case_Title__c = 'Security Review';
        SC_PPSM_Config_Rec.PPSM_Freq__c = '315';
        SC_PPSM_Config_Insert.add(SC_PPSM_Config_Rec);
        
        SC_PPSM_Config_Rec = new SC_PPSM_Config__c();
        SC_PPSM_Config_Rec.Name = 'Freq-5';
        SC_PPSM_Config_Rec.Case_Title__c = 'Performance Review';
        SC_PPSM_Config_Rec.PPSM_Freq__c = '330';
        SC_PPSM_Config_Insert.add(SC_PPSM_Config_Rec);
        
        // Insert all data
        Insert SC_PPSM_Config_Insert;
        
    }
    
    // Method-7 : For Creating SC_Serv_ReqTyp_value
    public static void createData_SC_Serv_ReqTyp_value()
    {
        // List to Insert All SC_Serv_ReqTyp_value
        List<SC_Serv_ReqTyp_value__c> SC_Serv_ReqTyp_valueInsert = new List<SC_Serv_ReqTyp_value__c>();
        
        // For Each Record
        SC_Serv_ReqTyp_value__c SC_Serv_ReqTyp_value_Rec;
        
        SC_Serv_ReqTyp_value_Rec = new SC_Serv_ReqTyp_value__c();
        SC_Serv_ReqTyp_value_Rec.Name = 'AMG';
        SC_Serv_ReqTyp_value_Rec.RequestTypeVal__c = 'Technical Configuration Review';
        SC_Serv_ReqTyp_value_Rec.ServiceVal__c = 'Service and Support Packages';
        SC_Serv_ReqTyp_valueInsert.add(SC_Serv_ReqTyp_value_Rec);
        
        SC_Serv_ReqTyp_value_Rec = new SC_Serv_ReqTyp_value__c();
        SC_Serv_ReqTyp_value_Rec.Name = 'QBR';
        SC_Serv_ReqTyp_value_Rec.RequestTypeVal__c = 'Quarterly Business Review';
        SC_Serv_ReqTyp_value_Rec.ServiceVal__c = 'Accounts Audits';
        SC_Serv_ReqTyp_valueInsert.add(SC_Serv_ReqTyp_value_Rec);
        
        SC_Serv_ReqTyp_value_Rec = new SC_Serv_ReqTyp_value__c();
        SC_Serv_ReqTyp_value_Rec.Name = 'TCR-Category1';
        SC_Serv_ReqTyp_value_Rec.RequestTypeVal__c = 'Technical Config Review';
        SC_Serv_ReqTyp_value_Rec.ServiceVal__c = 'SMP (Non-Security)';
        SC_Serv_ReqTyp_valueInsert.add(SC_Serv_ReqTyp_value_Rec);
        
        SC_Serv_ReqTyp_value_Rec = new SC_Serv_ReqTyp_value__c();
        SC_Serv_ReqTyp_value_Rec.Name = 'NES';
        SC_Serv_ReqTyp_value_Rec.RequestTypeVal__c = 'Customer Onboarding';
        SC_Serv_ReqTyp_value_Rec.ServiceVal__c = 'Account Audits';
        SC_Serv_ReqTyp_valueInsert.add(SC_Serv_ReqTyp_value_Rec);
        
        SC_Serv_ReqTyp_value_Rec = new SC_Serv_ReqTyp_value__c();
        SC_Serv_ReqTyp_value_Rec.Name = 'TCR-Category2';
        SC_Serv_ReqTyp_value_Rec.RequestTypeVal__c = 'Technical Config Review';
        SC_Serv_ReqTyp_value_Rec.ServiceVal__c = 'SMP (Security)';
        SC_Serv_ReqTyp_valueInsert.add(SC_Serv_ReqTyp_value_Rec);
        
        SC_Serv_ReqTyp_value_Rec = new SC_Serv_ReqTyp_value__c();
        SC_Serv_ReqTyp_value_Rec.Name = 'KONA';
        SC_Serv_ReqTyp_value_Rec.RequestTypeVal__c = 'Review';
        SC_Serv_ReqTyp_value_Rec.ServiceVal__c = 'Account Audits';
        SC_Serv_ReqTyp_valueInsert.add(SC_Serv_ReqTyp_value_Rec);
        
        SC_Serv_ReqTyp_value_Rec = new SC_Serv_ReqTyp_value__c();
        SC_Serv_ReqTyp_value_Rec.Name = 'ECOB';
        SC_Serv_ReqTyp_value_Rec.RequestTypeVal__c = 'Customer Onboarding';
        SC_Serv_ReqTyp_value_Rec.ServiceVal__c = 'Accounts Audits';
        SC_Serv_ReqTyp_value_Rec.Request_SubTypeVal__c = 'N/A - Not Applicable';
        SC_Serv_ReqTyp_valueInsert.add(SC_Serv_ReqTyp_value_Rec);
        
        SC_Serv_ReqTyp_value_Rec = new SC_Serv_ReqTyp_value__c();
        SC_Serv_ReqTyp_value_Rec.Name = 'KDD';
        SC_Serv_ReqTyp_value_Rec.RequestTypeVal__c = 'Customer Onboarding';
        SC_Serv_ReqTyp_value_Rec.ServiceVal__c = 'Kona DDoS Defender';
        SC_Serv_ReqTyp_value_Rec.Request_SubTypeVal__c = 'N/A - Not Applicable';
        SC_Serv_ReqTyp_valueInsert.add(SC_Serv_ReqTyp_value_Rec);
        
        SC_Serv_ReqTyp_value_Rec = new SC_Serv_ReqTyp_value__c();
        SC_Serv_ReqTyp_value_Rec.Name = 'MDS-COB';
        SC_Serv_ReqTyp_value_Rec.RequestTypeVal__c = 'Customer Onboarding';
        SC_Serv_ReqTyp_value_Rec.ServiceVal__c = 'Managed Delivery Service';
        SC_Serv_ReqTyp_value_Rec.Request_SubTypeVal__c = 'N/A - Not Applicable';
        SC_Serv_ReqTyp_valueInsert.add(SC_Serv_ReqTyp_value_Rec);
        
        SC_Serv_ReqTyp_value_Rec = new SC_Serv_ReqTyp_value__c();
        SC_Serv_ReqTyp_value_Rec.Name = 'KSD-COB';
        SC_Serv_ReqTyp_value_Rec.RequestTypeVal__c = 'Onboarding / Integration';
        SC_Serv_ReqTyp_value_Rec.ServiceVal__c = 'Other (Security)';
        SC_Serv_ReqTyp_value_Rec.Request_SubTypeVal__c = 'N/A - Not Applicable';
        SC_Serv_ReqTyp_valueInsert.add(SC_Serv_ReqTyp_value_Rec);
        
        SC_Serv_ReqTyp_value_Rec = new SC_Serv_ReqTyp_value__c();
        SC_Serv_ReqTyp_value_Rec.Name = 'SOA-Prolexic';
        SC_Serv_ReqTyp_value_Rec.RequestTypeVal__c = 'Customer Onboarding';
        SC_Serv_ReqTyp_value_Rec.ServiceVal__c = 'Security Optimization Assistance';
        SC_Serv_ReqTyp_value_Rec.Request_SubTypeVal__c = 'N/A - Not Applicable';
        SC_Serv_ReqTyp_valueInsert.add(SC_Serv_ReqTyp_value_Rec);
        
        SC_Serv_ReqTyp_value_Rec = new SC_Serv_ReqTyp_value__c();
        SC_Serv_ReqTyp_value_Rec.Name = 'SOA-Parent';
        SC_Serv_ReqTyp_value_Rec.RequestTypeVal__c = 'Customer Onboarding';
        SC_Serv_ReqTyp_value_Rec.ServiceVal__c = 'Security Optimization Assistance';
        SC_Serv_ReqTyp_value_Rec.Request_SubTypeVal__c = 'N/A - Not Applicable';
        SC_Serv_ReqTyp_valueInsert.add(SC_Serv_ReqTyp_value_Rec);
        
        SC_Serv_ReqTyp_value_Rec = new SC_Serv_ReqTyp_value__c();
        SC_Serv_ReqTyp_value_Rec.Name = 'SOA-BotManager';
        SC_Serv_ReqTyp_value_Rec.RequestTypeVal__c = 'Customer Onboarding';
        SC_Serv_ReqTyp_value_Rec.ServiceVal__c = 'Security Optimization Assistance';
        SC_Serv_ReqTyp_value_Rec.Request_SubTypeVal__c = 'N/A - Not Applicable';
        SC_Serv_ReqTyp_valueInsert.add(SC_Serv_ReqTyp_value_Rec);
        
        SC_Serv_ReqTyp_value_Rec = new SC_Serv_ReqTyp_value__c();
        SC_Serv_ReqTyp_value_Rec.Name = 'SOA-WebAppFirewall';
        SC_Serv_ReqTyp_value_Rec.RequestTypeVal__c = 'Customer Onboarding';
        SC_Serv_ReqTyp_value_Rec.ServiceVal__c = 'Security Optimization Assistance';
        SC_Serv_ReqTyp_value_Rec.Request_SubTypeVal__c = 'N/A - Not Applicable';
        SC_Serv_ReqTyp_valueInsert.add(SC_Serv_ReqTyp_value_Rec);
        
        // Insert all data
        Insert SC_Serv_ReqTyp_valueInsert;
        
    }
    
    // Method-8 : For Creating SC_SupportEmail
    public static void createData_SC_SupportEmail()
    {
        // List to Insert All SC_SupportEmail
        List<SC_SupportEmail__c> SC_SupportEmail_Insert = new List<SC_SupportEmail__c>();
        
        // For Each Record
        SC_SupportEmail__c SC_SupportEmail_Rec;
        
        SC_SupportEmail_Rec = new SC_SupportEmail__c();
        SC_SupportEmail_Rec.Name = '1';
        SC_SupportEmail_Rec.Default_Task_Owner__c = 'ONA';
        SC_SupportEmail_Rec.Support_Email_AMS__c = 'sc-dev@akamai.com';
        SC_SupportEmail_Rec.Support_Email_AutoGen__c = 'sc-dev@akamai.com';
        SC_SupportEmail_Insert.add(SC_SupportEmail_Rec);
        
        // Insert all data
        Insert SC_SupportEmail_Insert;
        
    }
    
    // Method-9 : For Creating SC_TCR_WAF_ProdList
    public static void createData_SC_TCR_WAF_ProdList(){
        
        // List to Insert All SC_TCR_WAF_ProdList
        List<SC_TCR_WAF_ProdList__c> SC_TCR_WAF_ProdList_Insert = new List<SC_TCR_WAF_ProdList__c>();
        
        // For Each Record
        SC_TCR_WAF_ProdList__c SC_TCR_WAF_ProdList_Rec;
        
        SC_TCR_WAF_ProdList_Rec = new SC_TCR_WAF_ProdList__c();
        SC_TCR_WAF_ProdList_Rec.Name = 'PPSM';
        SC_TCR_WAF_ProdList_Rec.Product_Id__c = 'M-LC-37859';
        SC_TCR_WAF_ProdList_Insert.add(SC_TCR_WAF_ProdList_Rec);
        
        SC_TCR_WAF_ProdList_Rec = new SC_TCR_WAF_ProdList__c();
        SC_TCR_WAF_ProdList_Rec.Name = 'QBR';
        SC_TCR_WAF_ProdList_Rec.Product_Id__c = 'B-3-4LC2D9,B-3-4LC2BU,M-LC-793,M-LC-794,M-LC-795,M-LC-1048,M-LC-1049,M-LC-1050';
        SC_TCR_WAF_ProdList_Insert.add(SC_TCR_WAF_ProdList_Rec);
        
        SC_TCR_WAF_ProdList_Rec = new SC_TCR_WAF_ProdList__c();
        SC_TCR_WAF_ProdList_Rec.Name = 'RUS';
        SC_TCR_WAF_ProdList_Rec.Product_Id__c = 'M-LC-38271';
        SC_TCR_WAF_ProdList_Insert.add(SC_TCR_WAF_ProdList_Rec);
        
        SC_TCR_WAF_ProdList_Rec = new SC_TCR_WAF_ProdList__c();
        SC_TCR_WAF_ProdList_Rec.Name = 'SMP';
        SC_TCR_WAF_ProdList_Rec.Product_Id__c = 'M-LC-120877,M-LC-128087';
        SC_TCR_WAF_ProdList_Insert.add(SC_TCR_WAF_ProdList_Rec);
        
        SC_TCR_WAF_ProdList_Rec = new SC_TCR_WAF_ProdList__c();
        SC_TCR_WAF_ProdList_Rec.Name = 'SMP-RC';
        SC_TCR_WAF_ProdList_Rec.Product_Id__c = 'M-LC-120877';
        SC_TCR_WAF_ProdList_Insert.add(SC_TCR_WAF_ProdList_Rec);
        
        SC_TCR_WAF_ProdList_Rec = new SC_TCR_WAF_ProdList__c();
        SC_TCR_WAF_ProdList_Rec.Name = 'TCR';
        SC_TCR_WAF_ProdList_Rec.Product_Id__c = 'B-3-5SCZIN,M-PC-859,M-LC-790,M-LC-793,M-LC-791,M-LC-794,M-LC-1038,M-LC-1040,M-LC-1041';
        SC_TCR_WAF_ProdList_Insert.add(SC_TCR_WAF_ProdList_Rec);
        
        SC_TCR_WAF_ProdList_Rec = new SC_TCR_WAF_ProdList__c();
        SC_TCR_WAF_ProdList_Rec.Name = 'WAF';
        SC_TCR_WAF_ProdList_Rec.Product_Id__c = 'M-LC-1239';
        SC_TCR_WAF_ProdList_Insert.add(SC_TCR_WAF_ProdList_Rec);
        
        // For KONA Use Case
        SC_TCR_WAF_ProdList_Rec = new SC_TCR_WAF_ProdList__c();
        SC_TCR_WAF_ProdList_Rec.Name = 'KONA';
        SC_TCR_WAF_ProdList_Rec.Product_Id__c = 'M-LC-62167,M-LC-139829,M-LC-132413';
        SC_TCR_WAF_ProdList_Insert.add(SC_TCR_WAF_ProdList_Rec);
        
        // For NES Use Case
        SC_TCR_WAF_ProdList_Rec = new SC_TCR_WAF_ProdList__c();
        SC_TCR_WAF_ProdList_Rec.Name = 'NES';
        SC_TCR_WAF_ProdList_Rec.Product_Id__c = 'M-LC-60519,M-LC-63815,M-LC-63403,M-LC-63609,M-LC-134061,M-LC-136533';
        SC_TCR_WAF_ProdList_Insert.add(SC_TCR_WAF_ProdList_Rec);
        
        // For NES Use Case
        SC_TCR_WAF_ProdList_Rec = new SC_TCR_WAF_ProdList__c();
        SC_TCR_WAF_ProdList_Rec.Name = 'KONA-COB';
        SC_TCR_WAF_ProdList_Rec.Product_Id__c = 'M-LC-62167,M-LC-139829';
        SC_TCR_WAF_ProdList_Insert.add(SC_TCR_WAF_ProdList_Rec);
        
        // For NES Use Case
        SC_TCR_WAF_ProdList_Rec = new SC_TCR_WAF_ProdList__c();
        SC_TCR_WAF_ProdList_Rec.Name = 'KDD';
        SC_TCR_WAF_ProdList_Rec.Product_Id__c = 'M-LC-144155';
        SC_TCR_WAF_ProdList_Insert.add(SC_TCR_WAF_ProdList_Rec);
        
        // For NES Use Case
        SC_TCR_WAF_ProdList_Rec = new SC_TCR_WAF_ProdList__c();
        SC_TCR_WAF_ProdList_Rec.Name = 'MDS';
        SC_TCR_WAF_ProdList_Rec.Product_Id__c = 'M-LC-159939,M-LC-160650';
        SC_TCR_WAF_ProdList_Insert.add(SC_TCR_WAF_ProdList_Rec);
        
        // For NES Use Case
        SC_TCR_WAF_ProdList_Rec = new SC_TCR_WAF_ProdList__c();
        SC_TCR_WAF_ProdList_Rec.Name = 'KSD';
        SC_TCR_WAF_ProdList_Rec.Product_Id__c = 'M-LC-140035';
        SC_TCR_WAF_ProdList_Insert.add(SC_TCR_WAF_ProdList_Rec);
        
        SC_TCR_WAF_ProdList_Rec = new SC_TCR_WAF_ProdList__c();
        SC_TCR_WAF_ProdList_Rec.Name = 'GDS';
        SC_TCR_WAF_ProdList_Rec.Product_Id__c = 'M-LC-159905';
        SC_TCR_WAF_ProdList_Insert.add(SC_TCR_WAF_ProdList_Rec);
        
        SC_TCR_WAF_ProdList_Rec = new SC_TCR_WAF_ProdList__c();
        SC_TCR_WAF_ProdList_Rec.Name = 'SMP-Security';
        SC_TCR_WAF_ProdList_Rec.Product_Id__c = 'M-LC-128087';
        SC_TCR_WAF_ProdList_Insert.add(SC_TCR_WAF_ProdList_Rec);
        
        SC_TCR_WAF_ProdList_Rec = new SC_TCR_WAF_ProdList__c();
        SC_TCR_WAF_ProdList_Rec.Name = 'SMP-NonSecurity';
        SC_TCR_WAF_ProdList_Rec.Product_Id__c = 'M-LC-120877';
        SC_TCR_WAF_ProdList_Insert.add(SC_TCR_WAF_ProdList_Rec);
        
        SC_TCR_WAF_ProdList_Rec = new SC_TCR_WAF_ProdList__c();
        SC_TCR_WAF_ProdList_Rec.Name = 'SMP-NonSecurity-RC';
        SC_TCR_WAF_ProdList_Rec.Product_Id__c = 'M-LC-120877,M-LC-162764';
        SC_TCR_WAF_ProdList_Insert.add(SC_TCR_WAF_ProdList_Rec);
        
        // Insert all data
        Insert SC_TCR_WAF_ProdList_Insert;
        
    }
    
    // Method-10 : For Creating SCUserIdCustomSetting
    public static void createData_SCUserIdCustomSetting()
    {
        // List to Insert UserID Custom Setting
        List<SCUserIdCustomSetting__c> SC_UserID_Insert = new List<SCUserIdCustomSetting__c>();
        
        // For Each Record
        SCUserIdCustomSetting__c SC_UserID_Insert_Rec;

        SC_UserID_Insert_Rec = new SCUserIdCustomSetting__c();
        SC_UserID_Insert_Rec.Name = 'CC_SEC_QUEUE';
        SC_UserID_Insert_Rec.UserId__c = '00GG0000002igP2';
        SC_UserID_Insert.add(SC_UserID_Insert_Rec);
        
        SCUserIdCustomSetting__c scUserIdcs = new SCUserIdCustomSetting__c();
        scUserIdcs.Name = 'Cash Apps';
        scUserIdcs.UserId__c = Userinfo.getUserId();
        SC_UserID_Insert.add(scUserIdcs);
        
        SC_UserID_Insert_Rec = new SCUserIdCustomSetting__c();
        SC_UserID_Insert_Rec.Name = 'CPSContactId';
        SC_UserID_Insert_Rec.UserId__c = '003G000002NCmOb';
        SC_UserID_Insert.add(SC_UserID_Insert_Rec);
        
        
        
        // Insert all data
        Insert SC_UserID_Insert;
        
    }
    
    
    
    
    public static Legal_Text__c createLegalText(String name, String legalType) 
    {
        Legal_Text__c legalText = new Legal_Text__c();
        legalText.Name = name;
        legalText.type__c = legalType;
        return legalText;
    }
    
    public static User getTestRunUser()
    {
        User testRunUser = new User(id=Userinfo.getUserId());
        return testRunUser;
    }
    
    public static OpportunityContactRole createOpportunityContactRole(Id opptyId, Id contactId, String role)
    {
        OpportunityContactRole opptyContactRole = new OpportunityContactRole();
        opptyContactRole.ContactId = contactId;
        opptyContactRole.OpportunityId  = opptyId;
        opptyContactRole.Role = role;
        
        return opptyContactRole; 
    }
    
    public static Contract_Product__c CreateContractProduct(String cioriginalContractId, String forecastProductId, String contractProductAkamId)
    {
        Contract_Product__c contractProduct = new Contract_Product__c();
        contractProduct.CI_Original_Contract_Id__c = cioriginalContractId;
        contractProduct.Forecast_Product_Id__c = forecastProductId;
        contractProduct.Contract_Product_Akam_Id__c = contractProductAkamId;
        return contractProduct;
    }
    
    //SFDC-1499
    public static Cron_Batch_Job__c createCronBatchJob(String batchJobType, String batchJobName)
    {
        Cron_Batch_Job__c cbj = new Cron_Batch_Job__c();
        cbj.Batch_Job_Type__c = batchJobType;
        cbj.Name = batchJobName;
        cbj.Period__c = 'Day';
        cbj.Run_Every__c = 1;
        cbj.Scheduled_To_Run__c = Date.today();
        return cbj;
    }
    
    public static Cron_Batch_Run__c createCronBatchRun(Id batchJobId)
    {
        Cron_Batch_Run__c cbr = new Cron_Batch_Run__c();
        cbr.Trigger_Batch_Run__c = true;
        cbr.Cron_Batch_Job__c = batchJobId;
        cbr.Scheduled_To_Run__c = Date.today();
        return cbr;
    }
    // End of SFDC-1499

}