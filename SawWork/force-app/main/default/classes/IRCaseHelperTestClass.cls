/**
 * IRCase Helper Test Class

Change History:
    Date        Developer       Description
    06/Jun/2017 Ankit Chawla    CR:3767571 : Created the test class for improving code coverage of IRCaseHelperClass
    15/Oct/2018 Ankit Chawla    SFDC-3619: Changing name of profile Sales - Rep to Sales - Media
    20/Feb/2019 Ankit Chawla    SFDC-4155: Updated test class to avoid 101 SOQL issue 

 * **/

@isTest(SeeAllData=false)
public class IRCaseHelperTestClass {

    private static Boolean initFlag = false;
    private static User newOwner;
    private static User newOwnerRSM;
    private static User cmgUser;
    private static User sysAdmin = SObjectFactory.ADMIN_USER;
    private static User crmInt;
    private static Account_Reassignment_Rule__c newOwnerRule;
    private static Map<String, GSM_Settings__mdt> testcaseCustomSettings = GsmUtilClass.getGSMSettingValue();
    private static Date reviewDate= Date.today().toStartOfMonth();
    private static String userRoleValue = GsmUtilClass.getGSMSettingValue('User_Role');

    private static Account acc1;
    private static AccountTeamMember atmEscalOwner;
    private static AccountTeamMember atmCMGAnalyst;
    private static Opportunity opp1;
    private static Merge_Contract_Header__c mch1;
    private static Merge_Contract_Manual_List__c mcManList;
    private static Invoice__c prevMonthFinalInvoice;
    private static Attachment attachments;
    private static Case existingCases;
    private static IRCaseCreationData irCaseData;
    private static List<Merge_Contract_Header__c> mchIdList;
    private static Map<Id,IRCaseWrapper> contractIDCaseWrapperMap;
    private static Map<Id,Id> accOwnerIdMap;
    private static Map<Id,AccountTeamMember> accIRCaseEscalOwnerATMMap;
    private static Map<Id,Id> mchIdAccIdMap;



    /**
        RefreshAccount(Account acc)
        - Refresh single account
    */
    public static Account RefreshAccount(Account acc)
    {
        return RefreshAccountList(new Account[]{acc})[0];
    }
    /**
        RefreshAccountList(Account[] acc)
        - Refresh bulk accounts
    */
    public static Account[] RefreshAccountList(Account[] accounts)
    {
        return [select Id,OwnerId,AKAM_Account_ID__c,Account_Status__c from Account where Id IN :accounts];
    }

    /**
        RefreshOpportunity()
        - Overloaded to refresh Single Opportunity
    */
    public static List<Opportunity> RefreshOpportunity(Opportunity pOpp)
    {
        return RefreshOpportunityList(new List<Opportunity> {pOpp});
    }
    /**
        RefreshOpportunityList()
        - Overloaded to refresh bulk Opportunities
    */
    public static List<Opportunity> RefreshOpportunityList(List<Opportunity> pOppList)
    {
        return [select Id,Name,AKAM_Opportunity_ID__c,OwnerId,CreatedById from Opportunity where Id IN :pOppList];
    }

    /**
        createATM()
    */
    public static AccountTeamMember createATM(Id pAccountId, String pTeamMemberRole, Id pUserId)
    {
        AccountTeamMember atm = new AccountTeamMember();
        atm.AccountId = pAccountId;
        atm.UserId = pUserId;
        atm.TeamMemberRole = pTeamMemberRole;
        return atm;
    }
    /**
        refreshATMList()
    */
    public static List<AccountTeamMember> refreshATMList(List<Account> pAccList)
    {
        return [SELECT Id,AccountId,UserId,AccountAccessLevel,TeamMemberRole FROM AccountTeamMember WHERE AccountId IN :pAccList];
    }
    /**
        refreshATM()
    */
    public static AccountTeamMember refreshATM(Account pAcc)
    {
        return refreshATMList(new List<Account> {pAcc})[0];
    }

    /**
        getCasesBulk()
    */
    public static List<Case> getCases(List<Merge_Contract_Header__c> mchList, Date pReviewDate)
    {
        return [Select Id,IR_Case_Locked__c, OwnerId, Description,RecordTypeId,Contract_Manual_List_Priority__c,IR_Defer_Until__c, IR_Escal_Owner__c,IR_Invoice_Number__c,IR_Invoice_Date__c,Status,IR_Escal_Status__c,IR_Original_Contract_Id__c, //2965556
            Validation_Override__c,CreatedDate,IR_CurrentInvoiceAmount__c, IR_CurrentInvoiceImportDate__c, IR_CurrentInvoiceNumber__c, IRCache_Acceptance_Date__c, IRCache_hasDoubleInvoiceReview__c, IRCache_isManual__c,
                IRCache_AkamOpportunityId__c,IRCache_isMissingFinalInvCheck__c,IRCache_isMissingDraftInvCheck__c, IRCache_isNewInvoice__c, IRCache_hasThresholdViolation__c, IRCache_hasDraftThresholdViolation__c ,Approved_On__c from Case where IR_Invoice_Date__c = :pReviewDate AND //2867070
                    IR_Original_Contract_Id__c!=null AND IR_Original_Contract_Id__c IN :mchList AND CreatedDate=LAST_N_DAYS:30]; //AND RecordTypeId IN :irRectypesMap.values()
    }
    /**
        getCasesBulk()
    */
    public static List<Case> getCases(List<Id> pCaseIdList)
    {
        return [Select Id,IR_Case_Locked__c, OwnerId,CaseNumber,Description,RecordTypeId,Contract_Manual_List_Priority__c,IR_Defer_Until__c, IR_Escal_Owner__c,IR_Invoice_Number__c,IR_Invoice_Date__c,Status,IR_Escal_Status__c,IR_Original_Contract_Id__c,//2965556
            Validation_Override__c,CreatedDate,IR_CurrentInvoiceAmount__c, IR_CurrentInvoiceImportDate__c, IR_CurrentInvoiceNumber__c, IRCache_Acceptance_Date__c, IRCache_hasDoubleInvoiceReview__c, IRCache_isManual__c,
                IRCache_AkamOpportunityId__c,IRCache_isMissingFinalInvCheck__c,IRCache_isMissingDraftInvCheck__c, IRCache_isNewInvoice__c, IRCache_hasThresholdViolation__c, IRCache_hasDraftThresholdViolation__c,Approved_On__c  from Case where Id IN :pCaseIdList]; //2867070
    }

    /**
        getCase()
    */
    public static Case getCase(Merge_Contract_Header__c mch, Date pReviewDate)
    {
        return getCases(new List<Merge_Contract_Header__c> {mch}, pReviewDate)[0];
    }

    /**
        getCase()
    */
    public static Case getCase(Id pCaseId)
    {
        return getCases(new List<Id> {pCaseId})[0];
    }

    /**
        createContractHeader
            - generates a new Contract record based on parameters
            - returns Contract
    */
    public static Merge_Contract_Header__c createContractHeader(String pName, Id pAccId, Id pOpptyId)
    {
        Merge_Contract_Header__c ch=new Merge_Contract_Header__c();
        ch.Name=pName;
        ch.Account_Name__c=pAccId;
        ch.Opportunity_Name__c=pOpptyId;
        ch.Cancellation_Date__c=Date.today().addMonths(5);
        ch.Effective_Start_Date__c=Date.today().addMonths(-2);
        ch.Effective_End_Date__c=Date.today().addYears(1);
        ch.Locked__c=true;
        ch.Active__c=true;
        ch.Acceptance_Date__c=Date.today().addMonths(-1);
        ch.Contract_Type__c = 'Direct Customer';
        ch.Double_Invoice_Review__c=true;
        ch.Manual_List__c=true;
        return ch;
    }
    /**
        refreshContractHeaderList()
    */
    public static List<Merge_Contract_Header__c> refreshContractHeaderList(List<Merge_Contract_Header__c> contractList)
    {
        return [select Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,
            Effective_End_Date__c,Effective_Start_Date__c,Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId
                From Merge_Contract_Header__c where id IN :contractList];
    }
    /**
        refreshContractHeader()
    */
    public static Merge_Contract_Header__c refreshContractHeader(Merge_Contract_Header__c contract)
    {
        return refreshContractHeaderList(new List<Merge_Contract_Header__c> {contract})[0];
    }

    /**
        createContractMList()
    */
    public static Merge_Contract_Manual_List__c createContractManualList(String pMListName, String pCI_OriginalContractId)
    {
        Merge_Contract_Manual_List__c newMList = new Merge_Contract_Manual_List__c();
        newMList.CI_Original_Contract_Id__c = pCI_OriginalContractId;
        newMList.Manual_List_Id__c = pMListName;
        return newMList;
    }
    /**
        refreshContractMLists()
    */
    public static List<Merge_Contract_Manual_List__c> refreshContractMLists(List<Merge_Contract_Manual_List__c> pContractMLists)
    {
        return [SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,Review_Date__c,
            Review_Frequency__c,Owner__c from Merge_Contract_Manual_List__c where Id IN :pContractMLists];
    }
    /**
        refreshContractMList()
    */
    public static Merge_Contract_Manual_List__c refreshContractMList(Merge_Contract_Manual_List__c pContractMList)
    {
        return refreshContractMLists(new List<Merge_Contract_Manual_List__c> {pContractMList})[0];
    }

    /**
        createInvoice()
    */
    public static Invoice__c createInvoice(String pCI_accountId, String pContractId, String pInvoiceId, Date pInvDate, Decimal pAmount)
    {
        Invoice__c newInvoice = new Invoice__c();
        newInvoice.CI_Account_Name__c = pCI_accountId;
        newInvoice.CI_Original_Contract_Id__c=pContractId;
        newInvoice.Invoice_Date__c= pInvDate;
        newInvoice.Name = pInvoiceId;
        newInvoice.Original_Amount__c=pAmount;
        return newInvoice;
    }

    //2867070
    public static Attachment createInvoiceAttachment(String pInvoiceId)
    {
        Attachment attachment = new Attachment();
        attachment.ParentId = pInvoiceId;
        return attachment;
    }

    //2965556
    public static Case createInvoiceCase(String pInvoiceID, Date pInvDate, Id pAccId, Id pOpptyId,Id pContractId , Id pUserId)
    {
        Case existingCase = new Case();

        existingCase.IR_CurrentInvoiceImportDate__c =  Datetime.now().addDays(-1);
        existingCase.IR_CurrentInvoiceNumber__c = pInvoiceId;
        existingCase.OwnerId = pUserId;
        existingCase.IR_Original_Contract_Id__c = pContractId;
        existingCase.RecordTypeId  = GsmUtilClass.GetCustomSettingValue('IR_CaseDefaultRecordTypeId');
        existingCase.AccountID = pAccId;
        existingCase.IR_Escal_Owner__c = pUserId;
        existingCase.IRCache_Acceptance_Date__c =  Date.today().addMonths(-1);
        existingCase.IRCache_AkamOpportunityId__c =  pOpptyId;
        //existingCase.IRCache_hasDoubleInvoiceReview__c = true;
        existingCase.Validation_Override__c = true;
        existingCase.IR_Invoice_Date__c = pInvDate;
        existingCase.IR_Invoice_Number__c = pInvoiceId;

        return existingCase;
    }
    /**
        refreshInvoice()
    */
    public static Invoice__c refreshInvoice(Invoice__c pInvoice)
    {
        return refreshInvoiceList(new List<Invoice__c> {pInvoice})[0];
    }
    /**
        refreshInvoiceList()
    */
    public static List<Invoice__c> refreshInvoiceList(List<Invoice__c> pInvoiceList)
    {
        return [select Id,Name,Account_Name__c,Original_Contract_Id__c,Invoice_Date__c,Original_Amount__c from Invoice__c where Id IN:pInvoiceList];
    }

    /**
        createDraftInvoice()
    */
    public static Draft_Invoice__c createDraftInvoice(String pCI_accountId, String pContractId, String pInvoiceId, Date pInvDate, Decimal pAmount)
    {
        Draft_Invoice__c newInvoice = new Draft_Invoice__c();
        //newInvoice.CI_Account_Name__c = pCI_accountId;
        //newInvoice.CI_Original_Contract_Id__c=pContractId;
        newInvoice.Invoice_Date__c= pInvDate;
        newInvoice.Name = pInvoiceId;
        newInvoice.Original_Amount__c=pAmount;
        return newInvoice;
    }
    /**
        refreshDraftInvoice()
    */
    public static Draft_Invoice__c refreshDraftInvoice(Draft_Invoice__c pInvoice)
    {
        return refreshDraftInvoiceList(new List<Draft_Invoice__c> {pInvoice})[0];
    }
    /**
        refreshDraftInvoiceList()
    */
    public static List<Draft_Invoice__c> refreshDraftInvoiceList(List<Draft_Invoice__c> pInvoiceList)
    {
        return [select Id,Name,Account_Name__c,Invoice_Review_Case_Audit__c,OwnerId,Case__c,Type__c,Original_Contract_Id__c,Invoice_Date__c,Original_Amount__c from Draft_Invoice__c where Id IN:pInvoiceList];
    }

    /**
        createIRCARec()
    */
    public static Invoice_Review_Case_Audit__c createIRCARec(Date pInvDate, String pJobId)
    {
        Invoice_Review_Case_Audit__c newIRCA = new Invoice_Review_Case_Audit__c();
        newIRCA.Import_Status__c = 'In-Progress';
        newIRCA.Import_Start_Date__c = Datetime.now().addSeconds(10);
        newIRCA.Invoice_Review_Date__c = pInvDate;
        newIRCA.InvLoaderJobId__c = pJobId;
        //newIRCA.Trigger_Case_Creation__c
        //newIRCA.Import_End_Date__c
        return newIRCA;
    }
    /**
        refreshIRCA()
    */
    public static Invoice_Review_Case_Audit__c refreshIRCA(Invoice_Review_Case_Audit__c pIRCA)
    {
        return [SELECT Invoice_Review_Date__c,Case_Creation_Completed__c,Case_Creation_End_Date__c,Case_Creation_Status__c, CreatedDate,Id,Import_End_Date__c,Import_Results__c,Case_Creation_Start_Date__c,
            Total_Cases_Created__c,Import_Start_Date__c,Import_Type__c,IsDeleted,LastModifiedById,LastModifiedDate,Name,OwnerId,Import_Status__c FROM Invoice_Review_Case_Audit__c where Id= :pIRCA.Id][0];
    }

    public static GSM_Custom_Settings__c initGSMCustomSetting(String name, String value){
      GSM_Custom_Settings__c newGSMCustomSetting = new GSM_Custom_Settings__c();
      newGSMCustomSetting.Name = name;
      newGSMCustomSetting.Value__c = value;
      return newGSMCustomSetting;
    }


    public static User GetUser(String name){
      return [select Id from User where Alias = :name LIMIT 1];
    }
    /**
        Init()
        - Intialize the static variables for this Test Class
    */
    @testSetUp static void Init()
    {
        if(initFlag)
            return;

        reviewDate = Date.today().toStartOfMonth();
        System.debug('reviewDate in TEST Method=' + reviewDate);

        String profileName = 'Sales - Media';
        String roleName = userRoleValue;

        newOwner = utilTestClass.CreateUser('TST_NUSR', roleName, profileName);
        newOwnerRSM = utilTestClass.CreateUser('TST_NRSM', roleName, profileName);
        cmgUser = utilTestClass.CreateUser('CMG_USER', 'CMG', 'CMG');
        crmInt = utilTestClass.CreateUser('CRM_USER', 'Worldwide', 'CRM Integration');

        insert (new User[] {newOwner, newOwnerRSM, cmgUser, crmInt});

        System.runAs(sysAdmin){
          Test.startTest();
          newOwnerRule = utilTestClass.CreateAccountReassignmentRule(newOwner.Name, newOwner.Id, roleName);
          newOwnerRule.Associated_User_RSM__c = newOwnerRSM.Id;

          insert (new Account_Reassignment_Rule__c[] {newOwnerRule});

          list<GSM_Custom_Settings__c> lstGSM = new list<GSM_Custom_Settings__c>();

          Map<String, Id > profilesMap = new Map<String, Id>();
          List<Profile> profiles = [SELECT Id, Name FROM Profile WHERE Name IN ('CRM Integration', 'System Administrator', 'CMG') LIMIT 3];
          for (Profile p: profiles) {
            profilesMap.put(p.Name, p.Id);
          }
          Id crmProfileId = profilesMap.get('CRM Integration');
          Id adminProfileId = profilesMap.get('System Administrator');
          Id cmgProfileId = profilesMap.get('CMG');

          String invoiceReviewCaseId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Invoice Review Case').getRecordTypeId();

          String readInvoiceReviewCaseId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Invoice Review Read Only').getRecordTypeId();

          String momentumCaseRecordId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Momentum Case Record').getRecordTypeId();

          String productManagementId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Product Management').getRecordTypeId();

          String technicalId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();

          lstGSM.add(initGSMCustomSetting('IR_NewMissingProcess_BatchSize','15'));
          lstGSM.add(initGSMCustomSetting('IR_CaseDefaultRecordTypeId',invoiceReviewCaseId));
          lstGSM.add(initGSMCustomSetting('IRCasesEAlert_RecipientList','achawla@akamai.com'));
          lstGSM.add(initGSMCustomSetting('IR_RecordTypeName_Default','Invoice_Review_Case'));
          lstGSM.add(initGSMCustomSetting('IR_RecordTypeName_Readonly','Invoice_Review_Read_Only'));
          lstGSM.add(initGSMCustomSetting('IR_Unassigned_QueueDevName','IR_Unassigned'));
          lstGSM.add(initGSMCustomSetting('IR_FIN_US_QueueDevName','FIN_IR_US'));
          lstGSM.add(initGSMCustomSetting('IR_FIN_Intl_QueueDevName','FIN_IR_International'));
          lstGSM.add(initGSMCustomSetting('IR_EscalOwner_TeamMemberRole','Services - Secondary'));
          lstGSM.add(initGSMCustomSetting('IR_Owner_TeamMemberRole','CMG - Analyst'));
          lstGSM.add(initGSMCustomSetting('IRCA_FinalInvThresPercent','50'));
          lstGSM.add(initGSMCustomSetting('IRCA_DraftInvThresPercent','25'));
          lstGSM.add(initGSMCustomSetting('IR_EscalStatus_Default','Pending Review'));
          lstGSM.add(initGSMCustomSetting('IR_Status_Default','Pending Review'));
          lstGSM.add(initGSMCustomSetting('CaseTrigger#updateContact','Collections, International Business Development, Invoice Review Case, Invoice Review Read Only, Momentum Case Record, Partner Portal Case, Product Management, SF Feedback'));
          lstGSM.add(initGSMCustomSetting('IR_CaseRecordTypeIds',invoiceReviewCaseId+','+readInvoiceReviewCaseId));
          lstGSM.add(initGSMCustomSetting('CRM_Integration',crmInt.Id));
          lstGSM.add(initGSMCustomSetting('AccountDelete#EnabledProfileId', crmProfileId + ',' + adminProfileId));
          lstGSM.add(initGSMCustomSetting('IRCase_CutOffDayOfMonth','24'));
          lstGSM.add(initGSMCustomSetting('IR_CaseAccessProfileIDs', crmProfileId + ',' + adminProfileId + ',' + cmgProfileId));
          lstGSM.add(initGSMCustomSetting('IRCase_DefaultInvoiceNumber','N/A'));
          insert lstGSM;

          //To be removed once Service Cloud fixes triggers

          SCUserIdCustomSetting__c scUserIdCS = new SCUserIdCustomSetting__c();
          scUserIdCS.Name = 'Primary/SecondaryAssignmentQueue';
          scUserIdCS.UserId__c = crmInt.Id;

          insert scUserIdCS;

          list<Email_to_Case__c> lstEmail2Case = new list<Email_to_Case__c>();

          Email_to_Case__c emailToCaseMomentum = new  Email_to_Case__c();
          emailToCaseMomentum.Name = 'Momentum';
          emailToCaseMomentum.CaseRecord__c = momentumCaseRecordId;
          lstEmail2Case.add(emailToCaseMomentum);

          Email_to_Case__c emailToCaseProdMgmnt = new  Email_to_Case__c();
          emailToCaseProdMgmnt.Name = 'ProdMgmt';
          emailToCaseProdMgmnt.CaseRecord__c = productManagementId;
          lstEmail2Case.add(emailToCaseProdMgmnt);

          insert lstEmail2Case;

          SC_RiverbedCaseProdID__c rvrBed = new SC_RiverbedCaseProdID__c();
          rvrBed.Name = 'Riverbed_SAAS_OEM';
          rvrBed.RecordTypeID__c = technicalId;
          insert rvrBed;

          SCRecordTypeCustomSetting__c scRTCustomSetting = new SCRecordTypeCustomSetting__c();
          scRTCustomSetting.Name = 'NotificationTeam';
          scRTCustomSetting.RecordTypeName__c = 'Professional Services&&AMG&&Technical&&Managed Security&&Carrier Products&&Emerging Products Engineering';

          insert scRTCustomSetting;
          //To be removed once Service Cloud fixes triggers

          Account acc1 =  (Account)new SobjectBuilder(Account.sObjectType)
            .eagerPopulate()
            .put(Account.Type, 'Lead')
            .create()
            .getRecord();

          acc1 = RefreshAccount(acc1);

          atmEscalOwner = createATM(acc1.id, GsmUtilClass.GetCustomSettingValue('IR_EscalOwner_TeamMemberRole'), newOwnerRSM.Id);
          atmCMGAnalyst = createATM(acc1.id, GsmUtilClass.GetCustomSettingValue('IR_Owner_TeamMemberRole'), cmgUser.Id);
          insert (new AccountTeamMember[] {atmEscalOwner, atmCMGAnalyst});

          Opportunity opp1 = (Opportunity)new SobjectBuilder(Opportunity.sObjectType)
              .eagerPopulate()
              .put(Opportunity.AccountId, acc1.Id)
              .put(Opportunity.StageName, '1-Create')
              .put(Opportunity.Name, 'IRCaseOppty1')
              .put(Opportunity.CloseDate, Date.today().addDays(10))
              .create()
              .getRecord();

          initFlag = true;
          Test.stopTest();
        }
    }

    //Check if the user has access to delete the account
    @isTest static void restrictAccountDelete(){
            //init();
            User cmgUser = GetUser('CMG_USER');
            System.debug('>>>3 cmgUser  '+cmgUser);
            System.runAs(cmgUser){

            // Account acc2 = utilTestClass.CreateAccount('IRCaseTestAcc2');
            // insert acc2;
            // acc2 = RefreshAccount(acc2);
            Account acc2 = SobjectRepository.getAccount();

            List<Account> accList = new List<Account>();
            accList.add(acc2);

            Test.startTest();
            IRCaseHelperClass.restrictDelete(accList);
            Test.stopTest();
            System.assertEquals(true, ApexPages.getMessages()[0].getDetail().contains(Label.IR_Insufficient_Delete_AccessErrorMessage));

        }
    }

    @isTest static void commonTestMethods(){


        String now = IRCaseHelperClass.fetchNowInGMTDateTime();

        List<Account> accList = new List<Account>();
        List<Account> accList2 = new List<Account>();
        Set<Id> set1 = new Set<Id>();
        Set<Id> set2 = new Set<Id>();
        for(Integer x=0; x<10 ; x++){
            Account acc2 = utilTestClass.CreateAccount('IRCaseTestAcc'+x);
            accList.add(acc2);
            if (math.mod(x,2) == 0){
                accList2.add(acc2);
            }
        }
        insert accList;

        for (Account ac : accList){
            System.debug(LoggingLevel.ERROR, 'Inside common method 123: '+ac.Id);
            set1.add(ac.Id);
        }

        for(Account ac : accList2){
            set2.add(ac.Id);
        }

        IRCaseHelperClass.diffP1MinusP2(set1, set2);
        IRCaseHelperClass.getDateTimeStringGmt(DateTime.now());
        IRCaseHelperClass.getCurrentReviewCycleInvoiceDate();

    }

    @isTest static void btnExecuteTestFIN_US(){
        System.runAs(sysAdmin){
            Account acc2 = SobjectRepository.getAccount();
            Opportunity opp2 = SobjectRepository.getOpportunity();
            User newOwnerRSM = GetUser('TST_NRSM');

            Merge_Contract_Header__c mch2 = createContractHeader('IRCaseMCH2', acc2.Id, opp2.Id);
            mch2.Manual_List__c = false;
            mch2.Acceptance_Date__c = reviewDate.addMonths(-1).addDays(10);
            insert mch2;


            Invoice_Review_Case_Audit__c ircaLast=new Invoice_Review_Case_Audit__c();

            Draft_Invoice__c di1=createDraftInvoice(acc2.Id, mch2.Name, '1304123789', reviewDate, 500);
            di1.CI_Original_Contract_Id__c=mch2.Name;
            //di1.Invoice_Review_Case_Audit__c=ircaCurrent.Id;

            insert di1;

            Case existinginvCase = createInvoiceCase (di1.Name, reviewDate, acc2.Id, opp2.Id , mch2.Id, newOwnerRSM.Id);
            existinginvCase.IR_Escal_Status__c = 'Pending Review';
            existinginvCase.status = 'Pending Review';
            existinginvCase.Description = 'Test Case Reject Threshold Positive';
            existinginvCase.IR_CurrentInvoiceAmount__c = 500;
            existinginvCase.CurrencyIsoCode = 'USD';
            existingInvCase.Approved_On__c = Datetime.now().addHours(2);
            //existingInvCase.OwnerId = IRCaseHelperClass.getIRQueues(GsmUtilClass.GetCustomSettingValue('IR_FIN_US_QueueDevName'));

            insert existinginvCase;

            existinginvCase = getCase(existinginvCase.Id);
            System.debug(LoggingLevel.ERROR,'Owner of case: '+existinginvCase.OwnerId);
            String action = 'FIN-US';

            Test.startTest();
            //Invalid action
            String result = IRCaseHelperClass.btnExecute('randomAction', existinginvCase.Id, IRCaseHelperClass.getIRQueues(GsmUtilClass.GetCustomSettingValue('IR_FIN_Intl_QueueDevName')));
            System.assertEquals(result,'0:Action undefined');

            //Invalid Case
            result = IRCaseHelperClass.btnExecute(action, null, IRCaseHelperClass.getIRQueues(GsmUtilClass.GetCustomSettingValue('IR_FIN_Intl_QueueDevName')));
            System.assertEquals(result,'0:Case Id is null. Please refresh the page and try again and if problem persists get in touch with eae-ops@akamai.com for further assistance.');


            result = IRCaseHelperClass.btnExecute(action, existinginvCase.Id, IRCaseHelperClass.getIRQueues(GsmUtilClass.GetCustomSettingValue('IR_FIN_Intl_QueueDevName')));
            Test.stopTest();

            System.assertEquals('1:Successfully updated the Case Owner', result);
        }
    }

    @isTest static void btnExecuteTestFIN_Intl(){
        System.runAs(sysAdmin){
            Account acc2 = SobjectRepository.getAccount();
            Opportunity opp2 = SobjectRepository.getOpportunity();
            User newOwnerRSM = GetUser('TST_NRSM');

            Merge_Contract_Header__c mch2 = createContractHeader('IRCaseMCH2', acc2.Id, opp2.Id);
            mch2.Manual_List__c = false;
            mch2.Acceptance_Date__c = reviewDate.addMonths(-1).addDays(10);
            insert mch2;


            Invoice_Review_Case_Audit__c ircaLast=new Invoice_Review_Case_Audit__c();

            Draft_Invoice__c di1=createDraftInvoice(acc2.Id, mch2.Name, '1304123789', reviewDate, 500);
            di1.CI_Original_Contract_Id__c=mch2.Name;
            //di1.Invoice_Review_Case_Audit__c=ircaCurrent.Id;

            insert di1;

            Case existinginvCase = createInvoiceCase (di1.Name, reviewDate, acc2.Id, opp2.Id , mch2.Id, newOwnerRSM.Id);
            existinginvCase.IR_Escal_Status__c = 'Pending Review';
            existinginvCase.status = 'Pending Review';
            existinginvCase.Description = 'Test Case Reject Threshold Positive';
            existinginvCase.IR_CurrentInvoiceAmount__c = 500;
            existinginvCase.CurrencyIsoCode = 'USD';
            existingInvCase.Approved_On__c = Datetime.now().addHours(2);
            //existingInvCase.OwnerId = IRCaseHelperClass.getIRQueues(GsmUtilClass.GetCustomSettingValue('IR_FIN_US_QueueDevName'));

            insert existinginvCase;

            existinginvCase = getCase(existinginvCase.Id);
            System.debug(LoggingLevel.ERROR,'Owner of case: '+existinginvCase.OwnerId);
            String action = 'FIN-Intl';
            Test.startTest();
            String result = IRCaseHelperClass.btnExecute(action, existinginvCase.Id, IRCaseHelperClass.getIRQueues(GsmUtilClass.GetCustomSettingValue('IR_FIN_Intl_QueueDevName')));
            Test.stopTest();

            System.assertEquals('0: Case is already assigned to the Queue user.', result);
        }
    }

    @isTest static void btnExecuteTestManualIRCaseApproval(){
        System.runAs(sysAdmin){
            Account acc2 = SobjectRepository.getAccount();
            Opportunity opp2 = SobjectRepository.getOpportunity();
            User newOwnerRSM = GetUser('TST_NRSM');

            Merge_Contract_Header__c mch2 = createContractHeader('IRCaseMCH2', acc2.Id, opp2.Id);
            mch2.Manual_List__c = false;
            mch2.Acceptance_Date__c = reviewDate.addMonths(-1).addDays(10);
            insert mch2;


            Invoice_Review_Case_Audit__c ircaLast=new Invoice_Review_Case_Audit__c();

            Draft_Invoice__c di1=createDraftInvoice(acc2.Id, mch2.Name, '1304123789', reviewDate, 500);
            di1.CI_Original_Contract_Id__c=mch2.Name;
            //di1.Invoice_Review_Case_Audit__c=ircaCurrent.Id;

            insert di1;

            Case existinginvCase = createInvoiceCase (di1.Name, reviewDate, acc2.Id, opp2.Id , mch2.Id, newOwnerRSM.Id);
            existinginvCase.IR_Escal_Status__c = 'Pending Review';
            existinginvCase.status = 'Pending Review';
            existinginvCase.Description = 'Test Case Reject Threshold Positive';
            existinginvCase.IR_CurrentInvoiceAmount__c = 500;
            existinginvCase.CurrencyIsoCode = 'USD';
            existingInvCase.Approved_On__c = Datetime.now().addHours(2);
            //existingInvCase.OwnerId = IRCaseHelperClass.getIRQueues(GsmUtilClass.GetCustomSettingValue('IR_FIN_US_QueueDevName'));

            insert existinginvCase;

            existinginvCase = getCase(existinginvCase.Id);
            System.debug(LoggingLevel.ERROR,'Owner of case: '+existinginvCase.OwnerId);
            String action = 'manualIRCaseApproval';
            Test.startTest();
            String result = IRCaseHelperClass.btnExecute(action, existinginvCase.Id, IRCaseHelperClass.getIRQueues(GsmUtilClass.GetCustomSettingValue('IR_FIN_Intl_QueueDevName')));
            String result1 = IR_CaseCustomButtonsController.handleButtonClick(action, existinginvCase.Id);
            Test.stopTest();

            System.assertEquals('1:Successfully approved.', result);
            	System.assertEquals('1:Successfully approved.', result1);
        }
    }

    @isTest static void IRCaseLockScreenTest(){

        User crmInt = GetUser('CRM_USER');
        System.runAs(crmInt)
        {
            Account acc1 = SobjectRepository.getAccount();
            Opportunity opp1 = SobjectRepository.getOpportunity();
            User newOwnerRSM = GetUser('TST_NRSM');
            User cmgUser = GetUser('CMG_USER');

            Invoice_Review_Case_Audit__c ircaExisting = new Invoice_Review_Case_Audit__c();


            Account acc2 = utilTestClass.CreateAccount('IRCaseTestAcc2');
            insert acc2;
            acc2 = RefreshAccount(acc2);

            AccountTeamMember atmEscalOwner2 = createATM(acc2.id, GsmUtilClass.GetCustomSettingValue('IR_EscalOwner_TeamMemberRole'), newOwnerRSM.Id);
            AccountTeamMember atmCMGAnalyst2 = createATM(acc2.id, GsmUtilClass.GetCustomSettingValue('IR_Owner_TeamMemberRole'), cmgUser.Id);
            insert (new AccountTeamMember[] {atmEscalOwner2, atmCMGAnalyst2});

            Opportunity opp2 = utilTestClass.CreateOpportunity('IRCaseOppty2', '1-Create');
            opp2.AccountId=acc2.Id;
            opp2.CloseDate= Date.today().addDays(10);
            insert opp2;

            Merge_Contract_Header__c mch1 = createContractHeader('IRCaseMCH1', acc1.Id, opp1.Id);
            mch1.Manual_List__c = false;
            mch1.Acceptance_Date__c = reviewDate.addMonths(-1).addDays(10);

            insert mch1;

            Merge_Contract_Header__c mch2 = createContractHeader('IRCaseMCH2', acc2.Id, opp2.Id);
            mch2.Manual_List__c = false;
            mch2.Acceptance_Date__c = reviewDate.addMonths(-1).addDays(10);

            insert mch2;

            Merge_Contract_Manual_List__c mcManList2 = createContractManualList('IRCaseMlist2', mch2.Name);
            mcManList2.Review_Frequency__c = 'Monthly';
            mcManList2.End_Date__c = Date.today().addMonths(1);
            mcManList2.Owner__c = 'UNKNOWN';
            mcManList2.Review_Date__c = reviewDate;
            mcManList2.Priority__c = 'TESTPRIORITY';
            insert mcManList2;

            Invoice_Review_Case_Audit__c ircaCurrent=createIRCARec(reviewDate,'IRCA1279');
            insert ircaCurrent;

            Draft_Invoice__c di1=createDraftInvoice(acc1.Id, mch1.Name, '1704123788', reviewDate, 500);
            di1.CI_Original_Contract_Id__c=mch1.Name;
            di1.Invoice_Review_Case_Audit__c=ircaCurrent.Id;

            Draft_Invoice__c di2=createDraftInvoice(acc2.Id, mch2.Name, '1704123789', reviewDate, 500);
            di2.CI_Original_Contract_Id__c=mch2.Name;
            di2.Invoice_Review_Case_Audit__c=ircaCurrent.Id;

            insert di1;
            insert di2;

            di1 = IRCaseHelperClass.getExistingDraftInvoice(mch1.Id,reviewDate);

            di1 = refreshDraftInvoice(di1);
            di1.hasAttachment__c=true;
            update di1;

            di2 = IRCaseHelperClass.getExistingDraftInvoice(mch2.Id,reviewDate);

            di2 = refreshDraftInvoice(di2);
            di2.hasAttachment__c=true;
            update di2;

            Date currInvDate = IRCaseHelperClass.getCurrentReviewCycleInvoiceDate(di1.Name);

                ircaCurrent.Import_End_Date__c=Datetime.now();
                ircaCurrent.Import_Status__c='Success';
                ircaCurrent.Trigger_Case_Creation__c = true;
                ircaCurrent.Case_Creation_Status__c = 'Success';
                update ircaCurrent;

            Test.startTest();
            List<Case> existinginvCaseList = new List<Case>();

            Case existinginvCase = createInvoiceCase (di1.Name, reviewDate, acc1.Id, opp1.Id , mch1.Id, newOwnerRSM.Id);
            existinginvCase.IR_Escal_Status__c = 'Pending Review';
            existinginvCase.status = 'Rejected';
            existinginvCase.Description = 'Test Case Reject Threshold Positive';
            existinginvCase.IR_CurrentInvoiceAmount__c = 500;
            existinginvCase.CurrencyIsoCode = 'USD';
            existingInvCase.Approved_On__c = Datetime.now().addHours(2);
            existinginvCaseList.add(existinginvCase);

            Case existinginvCase2 = createInvoiceCase (di2.Name, reviewDate, acc2.Id, opp2.Id , mch2.Id, newOwnerRSM.Id);
            existinginvCase2.IR_Escal_Status__c = 'Pending Review';
            existinginvCase2.status = 'Deferred';
            existinginvCase2.Description = 'Test Case Reject Threshold Positive';
            existinginvCase2.IR_CurrentInvoiceAmount__c = 500;
            existinginvCase2.CurrencyIsoCode = 'USD';
            existingInvCase2.Approved_On__c = Datetime.now().addHours(2);
            existinginvCase2.IR_Defer_Until__c = Date.today().addMonths(1);

            existinginvCaseList.add(existinginvCase2);
            insert existinginvCaseList;


            String resultMessage = IRCaseHelperClass.lockIRCases(reviewDate, reviewDate);
            String[]  resultList = resultMessage.split(':');

            System.debug(LoggingLevel.ERROR,'resultList : ' + resultList);
            ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.INFO, resultList[1]);
            ApexPages.addMessage(errMsg);
            Test.stopTest();

            existinginvCase = getCase(existinginvCase.Id);

            System.debug(LoggingLevel.ERROR,'ApexPageMessage: ' + ApexPages.getMessages());
            System.assert(existinginvCase.IR_Case_Locked__c,true);
        }
    }

    @isTest static void btnExecuteLockIRCasesTest(){

        User crmInt = GetUser('CRM_USER');
        System.runAs(crmInt){
            String pAction = 'lockIRCases';
            //Undefined action
            String result= IRCaseHelperClass.btnExecuteLockIRCases('');
            System.assertEquals(result,'0:Action undefined');

            //Defined action
            Invoice_Review_Case_Audit__c irca=createIRCARec(reviewDate,'IRCA1');
            insert irca;

            irca.Import_Status__c='Success';
            irca.Case_Creation_Status__c = 'Success';
            update irca;
            Test.startTest();
            result = IRCaseHelperClass.btnExecuteLockIRCases(pAction);
            Test.stopTest();

        }
    }

    //Test methods for IR_NewDraftInvoiceController.getDefaults
    @isTest static void existingDraftInvoiceGetDefaults(){
      User cmgUser = GetUser('CMG_USER');
      System.runAs(cmgUser){

        Account acc2 = SobjectRepository.getAccount();
        Opportunity opp2 = SobjectRepository.getOpportunity();
        User newOwnerRSM = GetUser('TST_NRSM');

        Merge_Contract_Header__c mch2 = createContractHeader('IRCaseMCH2', acc2.Id, opp2.Id);
        mch2.Manual_List__c = false;
        mch2.Acceptance_Date__c = reviewDate.addMonths(-1).addDays(10);
        insert mch2;


        Invoice_Review_Case_Audit__c ircaLast=new Invoice_Review_Case_Audit__c();

        Draft_Invoice__c di1=createDraftInvoice(acc2.Id, mch2.Name, '1304123789', reviewDate, 500);
        di1.CI_Original_Contract_Id__c=mch2.Name;
        //di1.Invoice_Review_Case_Audit__c=ircaCurrent.Id;

        insert di1;

        Case existinginvCase = createInvoiceCase (di1.Name, reviewDate, acc2.Id, opp2.Id , mch2.Id, newOwnerRSM.Id);
        existinginvCase.IR_Escal_Status__c = 'Pending Review';
        existinginvCase.status = 'Pending Review';
        existinginvCase.Description = 'Test Case Reject Threshold Positive';
        existinginvCase.IR_CurrentInvoiceAmount__c = 500;
        existinginvCase.CurrencyIsoCode = 'USD';
        existingInvCase.Approved_On__c = Datetime.now().addHours(2);
        //existingInvCase.OwnerId = IRCaseHelperClass.getIRQueues(GsmUtilClass.GetCustomSettingValue('IR_FIN_US_QueueDevName'));

        insert existinginvCase;

        existinginvCase = getCase(existinginvCase.Id);

        Draft_Invoice__c newDI = IR_NewDraftInvoiceController.getDefaults(mch2.id);
        System.assertEquals(newDI.Name, di1.Name);
        System.assertEquals(newDI.Invoice_Date__c,existinginvCase.IR_Invoice_Date__c);
        System.assertEquals(newDI.Original_Contract_Id__c, mch2.Id);
      }
    }

    @isTest static void newDraftInvoiceGetDefaults(){
      User cmgUser = GetUser('CMG_USER');
      System.runAs(cmgUser){

        Account acc2 = SobjectRepository.getAccount();
        Opportunity opp2 = SobjectRepository.getOpportunity();
        User newOwnerRSM = GetUser('TST_NRSM');

        Merge_Contract_Header__c mch2 = createContractHeader('IRCaseMCH2', acc2.Id, opp2.Id);
        mch2.Manual_List__c = false;
        mch2.Acceptance_Date__c = reviewDate.addMonths(-1).addDays(10);
        insert mch2;


        Draft_Invoice__c newDI = IR_NewDraftInvoiceController.getDefaults(mch2.id);
        System.assertEquals(newDI.Name, GsmUtilClass.GetCustomSettingValue('IRCase_DefaultInvoiceNumber'));
        System.assertEquals(newDI.Invoice_Date__c,IRCaseHelperClass.getCurrentReviewCycleInvoiceDate());
        System.assertEquals(newDI.Original_Contract_Id__c, mch2.Id);
      }
    }

}