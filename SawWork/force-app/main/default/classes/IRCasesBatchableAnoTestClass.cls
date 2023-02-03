/** IR Cases Functionality related test cases for IRCaseCreationBatchableAno class
Change History

Developer Name		Created Date		Description
Ankit				06/Jun/2017			CR: 3619951-Created new test class for improving code coverage for IRCaseCreationBatchableAno class

Ankit   	15/Oct/2018  SFDC-3619: Changing name of profile Sales - Rep to Sales - Media
**/
@isTest(SeeAllData=false)
public class IRCasesBatchableAnoTestClass
{
    private static Boolean initFlag = false;
    private static User newOwner;
    private static User newOwnerRSM;
    private static User cmgUser;
    private static User sysAdmin = SObjectFactory.ADMIN_USER;
    private static User crmUser;
    private static Account_Reassignment_Rule__c newOwnerRule;
    private static String userRoleValue = GsmUtilClass.getGSMSettingValue('User_Role');
    private static Date reviewDate = Date.today().toStartOfMonth();

    private static Account acc1;
    private static AccountTeamMember atmEscalOwner;
    private static AccountTeamMember atmCMGAnalyst;
    private static Opportunity opp1;
    private static Merge_Contract_Header__c mch1;
    private static Merge_Contract_Manual_List__c mcManList;
    private static Invoice__c prevMonthFinalInvoice;
    private static Attachment attachments; //2867070
    private static Case existingCases; //2965556
    private static IRCaseCreationData irCaseData; //2965556
    private static List<Merge_Contract_Header__c> mchIdList; //2965556
    private static Map<Id,IRCaseWrapper> contractIDCaseWrapperMap; //2965556
    private static Map<Id,Id> accOwnerIdMap; //2965556
    private static Map<Id,AccountTeamMember> accIRCaseEscalOwnerATMMap; //2965556
    private static Map<Id,Id> mchIdAccIdMap; //2965556

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

        System.debug('reviewDate in TEST Method=' + reviewDate);

        String profileName = 'Sales - Media' ;
        String roleName = userRoleValue;

        newOwner = utilTestClass.CreateUser('TST_NUSR', roleName, profileName);
        newOwnerRSM = utilTestClass.CreateUser('TST_NRSM', roleName, profileName);
        cmgUser = utilTestClass.CreateUser('CMG_USER', 'CMG', 'CMG');
        sysAdmin = utilTestClass.CreateUser('SYS_USER', 'System Administrator', 'System Administrator');
        crmUser = utilTestClass.CreateUser('CRM_USER', 'Worldwide', 'CRM Integration');

        insert (new User[] {newOwner, newOwnerRSM, cmgUser, sysAdmin, crmUser});

        System.runAs(sysAdmin){
          Test.startTest();

          list<GSM_Custom_Settings__c> lstGSM = new list<GSM_Custom_Settings__c>();

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
          lstGSM.add(initGSMCustomSetting('CRM_Integration',crmUser.Id));
          insert lstGSM;

          //To be removed once Service Cloud fixes triggers

          SCUserIdCustomSetting__c scUserIdCS = new SCUserIdCustomSetting__c();
          scUserIdCS.Name = 'Primary/SecondaryAssignmentQueue';
          scUserIdCS.UserId__c = crmUser.Id;

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

          newOwnerRule = utilTestClass.CreateAccountReassignmentRule(newOwner.Name, newOwner.Id, roleName);
          newOwnerRule.Associated_User_RSM__c = newOwnerRSM.Id;

              insert (new Account_Reassignment_Rule__c[] {newOwnerRule});


          acc1 = utilTestClass.CreateAccount('IRCaseTestAcc1');
          insert acc1;
          acc1 = RefreshAccount(acc1);

          atmEscalOwner = createATM(acc1.id, GsmUtilClass.GetCustomSettingValue('IR_EscalOwner_TeamMemberRole'), newOwnerRSM.Id);
          atmCMGAnalyst = createATM(acc1.id, GsmUtilClass.GetCustomSettingValue('IR_Owner_TeamMemberRole'), cmgUser.Id);
          insert (new AccountTeamMember[] {atmEscalOwner, atmCMGAnalyst});

          opp1 = utilTestClass.CreateOpportunity('IRCaseOppty1', '1-Create');
          opp1.AccountId=acc1.Id;
          opp1.CloseDate=Date.today().addDays(10);
          insert opp1;

          mch1 = createContractHeader('IRCaseMCH1', acc1.Id, opp1.Id);
          insert mch1;

          mcManList = createContractManualList('IRCaseMlist1', mch1.Name);
          mcManList.Review_Frequency__c = 'Monthly';
          mcManList.End_Date__c = Date.today().addMonths(2);
          mcManList.Owner__c = 'UNKNOWN';
          mcManList.Review_Date__c = reviewDate;
          mcManList.Priority__c = 'TESTPRIORITY';
          insert mcManList;

          prevMonthFinalInvoice = createInvoice(acc1.AKAM_Account_ID__c, mch1.Name, '1303123567', reviewDate.addMonths(-1), 300);
          insert prevMonthFinalInvoice;


          //2867070
          attachments = createInvoiceAttachment (prevMonthFinalInvoice.Id);
          Blob b = Blob.valueOf('Test Data');
          attachments.Body = b;
          attachments.Name = 'Test Attachment for Parent';
          insert attachments;
          System.debug('Attachment Id : '+attachments.Id);
          initFlag = true;
        Test.stopTest();
      }
    }

    static testMethod void IRCaseCreationBatchableAnoTest()
        {
          User newOwnerRSM = GetUser('TST_NRSM');
          User cmgUser = GetUser('CMG_USER');
            System.runAs(sysAdmin)
            {
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

                Merge_Contract_Header__c mch2 = createContractHeader('IRCaseMCH2', acc2.Id, opp2.Id);
                mch2.Manual_List__c = false;
                mch2.Acceptance_Date__c = reviewDate.addMonths(-1).addDays(10);
                insert mch2;

                Invoice_Review_Case_Audit__c ircaCurrent=createIRCARec(reviewDate,'IRCaseTest1280');
                insert ircaCurrent;

                Invoice_Review_Case_Audit__c ircaLast=new Invoice_Review_Case_Audit__c();

                Invoice__c oldFinalInvoice2 = createInvoice(acc2.AKAM_Account_ID__c, mch2.Name, '1701123232', reviewDate.addMonths(-4), 450);
                insert oldFinalInvoice2;

                Draft_Invoice__c di1=createDraftInvoice(acc2.Id, mch2.Name, '1705123789', reviewDate, 500);
                di1.CI_Original_Contract_Id__c=mch2.Name;
                di1.Invoice_Review_Case_Audit__c=ircaCurrent.Id;

                insert di1;
                //CR 3713022
                System.debug(LoggingLevel.ERROR, 'First DI: '+di1);

                di1 = IRCaseHelperClass.getExistingDraftInvoice(mch2.Id,reviewDate);
                System.debug(LoggingLevel.ERROR, 'Second DI: '+di1);

                di1 = refreshDraftInvoice(di1);
                di1.hasAttachment__c=true;
                update di1;

                    ircaCurrent.Import_End_Date__c=Datetime.now();
                    ircaCurrent.Import_Status__c='Success';
                    ircaCurrent.Trigger_Case_Creation__c = true;
                    update ircaCurrent;


                Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));

                String query = 'SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,Effective_Start_Date__c,Currency__c,';
                   query += 'Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,Review_Date__c,';
                   query += 'Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where (Name = \'IRCaseMCH2\') AND Active__c=true AND Contract_Type__c != \'ISP\''; // Order by End_Date__c DESC limit 1 //2965556
                   query +=  ' AND Locked__c=true AND Effective_End_Date__c >= '+ IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + 'AND (Cancellation_Date__c=null OR Cancellation_Date__c >= ' + IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + ')';
                   query +=  ' Limit ' + batchSize;

                System.debug('Query=' + query);

                Test.startTest();
                //ircaLast = null;
                IRCaseCreationBatchableAno execIRCaseCreation = new IRCaseCreationBatchableAno(ircaCurrent, ircaLast);
                execIRCaseCreation.query=query;
                ID batchprocessid=Database.executeBatch(execIRCaseCreation,batchSize);
                System.debug('batchprocessid=' + batchprocessid);
                System.debug('contractID------- '+mch2.Id);
                Test.stopTest();

                ircaCurrent = refreshIRCA(ircaCurrent);


                for (Case cs : [Select Id,IRCache_isNewInvoice__c ,IRCache_hasMissingInvoiceLastMonth__c  from Case where IR_Original_Contract_Id__c = :mch2.Id])
                {
                    System.debug(LoggingLevel.ERROR, 'cs: '+cs);
                    System.assertEquals(false,cs.IRCache_isNewInvoice__c);
                    System.assertEquals(true,cs.IRCache_hasMissingInvoiceLastMonth__c);
                }

            }
        }

    static testMethod void IRCaseCreationBatchableAnoThresholdTest()
        {
            User newOwnerRSM = GetUser('TST_NRSM');
            User cmgUser = GetUser('CMG_USER');
            System.runAs(sysAdmin)
            {
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

                Merge_Contract_Header__c mch2 = createContractHeader('IRCaseMCH2', acc2.Id, opp2.Id);
                mch2.Manual_List__c = false;
                mch2.Acceptance_Date__c = reviewDate.addMonths(-1).addDays(10);
                insert mch2;

                Invoice_Review_Case_Audit__c ircaLast=createIRCARec(reviewDate,'IRCaseTest1277');
            	ircaLast.Import_Start_Date__c = Datetime.now().addDays(-1);
                ircaLast.Import_Status__c = 'Success';
                ircaLast.Case_Creation_Completed__c=true;
                ircaLast.Import_End_Date__c = Datetime.now().addDays(-1);
                insert ircaLast;


                Invoice_Review_Case_Audit__c ircaCurrent=createIRCARec(reviewDate,'IRCaseTest1280');
                insert ircaCurrent;

                Invoice__c prevFinalInvoice2 = createInvoice(acc2.AKAM_Account_ID__c, mch2.Name, '1701123232', reviewDate.addMonths(-1), 45);
                insert prevFinalInvoice2;

                Attachment att = createInvoiceAttachment(prevFinalInvoice2.Id);

                Blob b = Blob.valueOf('Test Data');
                att.Body = b;
                att.Name = 'Test Attachment for Parent';
                insert att;

                Draft_Invoice__c di1=createDraftInvoice(acc2.Id, mch2.Name, '1705123789', reviewDate, 500);
                di1.CI_Original_Contract_Id__c=mch2.Name;
                di1.Invoice_Review_Case_Audit__c=ircaLast.Id;

                insert di1;

                Draft_Invoice__c di2=createDraftInvoice(acc2.Id, mch2.Name, '1705123789', reviewDate, 900);
                di2.CI_Original_Contract_Id__c=mch2.Name;
                di2.Invoice_Review_Case_Audit__c=ircaCurrent.Id;

                insert di2;

                di1 = refreshDraftInvoice(di1);
                di1.hasAttachment__c=true;
                update di1;

                di2 = refreshDraftInvoice(di2);
                di2.hasAttachment__c=true;
                update di2;

                ircaCurrent.Import_End_Date__c=Datetime.now();
                ircaCurrent.Import_Status__c='Success';
                ircaCurrent.Trigger_Case_Creation__c = true;
                update ircaCurrent;

                Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));

                String query = 'SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,Effective_Start_Date__c,Currency__c,';
                   query += 'Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,Review_Date__c,';
                   query += 'Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where (Name = \'IRCaseMCH2\') AND Active__c=true AND Contract_Type__c != \'ISP\''; // Order by End_Date__c DESC limit 1 //2965556
                   query +=  ' AND Locked__c=true AND Effective_End_Date__c >= '+ IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + 'AND (Cancellation_Date__c=null OR Cancellation_Date__c >= ' + IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + ')';
                   query +=  ' Limit ' + batchSize;

                System.debug('Query=' + query);

                Test.startTest();
                IRCaseCreationBatchableAno execIRCaseCreation = new IRCaseCreationBatchableAno(ircaCurrent, ircaLast);
                execIRCaseCreation.query=query;
                ID batchprocessid=Database.executeBatch(execIRCaseCreation,batchSize);
                System.debug('batchprocessid=' + batchprocessid);
                System.debug('contractID------- '+mch2.Id);
                Test.stopTest();

                ircaCurrent = refreshIRCA(ircaCurrent);


                for (Case cs : [Select Id,IRCache_hasDraftThresholdViolation__c,IRCache_hasThresholdViolation__c,IRCache_hasDoubleInvoiceReview__c   from Case where IR_Original_Contract_Id__c = :mch2.Id])
                {
                    System.debug(LoggingLevel.ERROR, 'cs: '+cs);
                    System.assertEquals(true,cs.IRCache_hasDraftThresholdViolation__c);
                    System.assertEquals(true,cs.IRCache_hasThresholdViolation__c);
                    System.assertEquals(true,cs.IRCache_hasDoubleInvoiceReview__c);
                }

            }
        }

    static testMethod void IRCaseCreationBatchableAnoRejectedCaseTest()
        {
            User newOwnerRSM = GetUser('TST_NRSM');
            User cmgUser = GetUser('CMG_USER');
            System.runAs(sysAdmin)
            {
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

                Merge_Contract_Header__c mch2 = createContractHeader('IRCaseMCH2', acc2.Id, opp2.Id);
                mch2.Manual_List__c = false;
                mch2.Acceptance_Date__c = reviewDate.addMonths(-1).addDays(10);
                insert mch2;

                Invoice_Review_Case_Audit__c ircaLast=createIRCARec(reviewDate,'IRCaseTest1277');
                ircaLast.Import_Start_Date__c = Datetime.now().addDays(-1);
                ircaLast.Import_Status__c = 'Success';
                ircaLast.Case_Creation_Completed__c=true;
                ircaLast.Import_End_Date__c = Datetime.now().addDays(-1);
                insert ircaLast;
                Invoice_Review_Case_Audit__c ircaCurrent=createIRCARec(reviewDate,'IRCaseTest1278');
                insert ircaCurrent;
            	//insert ircaLast;

                //Invoice__c prevFinalInvoice2 = createInvoice(acc2.AKAM_Account_ID__c, mch2.Name, '1701123232', reviewDate.addMonths(-1), 45);
                //insert prevFinalInvoice2;

                Draft_Invoice__c di1=createDraftInvoice(acc2.Id, mch2.Name, '1705123789', reviewDate, 500);
                di1.CI_Original_Contract_Id__c=mch2.Name;
                di1.Invoice_Review_Case_Audit__c=ircaLast.Id;

                insert di1;

                Draft_Invoice__c di2=createDraftInvoice(acc2.Id, mch2.Name, '1705123789', reviewDate, 900);
                di2.CI_Original_Contract_Id__c=mch2.Name;
                di2.Invoice_Review_Case_Audit__c=ircaCurrent.Id;

                insert di2;

                di1 = refreshDraftInvoice(di1);
                di1.hasAttachment__c=true;
                update di1;

                di2 = refreshDraftInvoice(di2);
                di2.hasAttachment__c=true;
                update di2;

                ircaCurrent.Import_End_Date__c=Datetime.now();
                ircaCurrent.Import_Status__c='Success';
                ircaCurrent.Trigger_Case_Creation__c = true;
                update ircaCurrent;


                Case existinginvCase = createInvoiceCase (di1.Name, reviewDate, acc2.Id, opp2.Id , mch2.Id, newOwnerRSM.Id);
                existinginvCase.IR_Escal_Status__c = 'Rejected';
                existinginvCase.status = 'Rejected';
                existinginvCase.Description = 'Test Case Reject Threshold Positive';
                existinginvCase.IR_CurrentInvoiceAmount__c = 500;
                existingInvCase.Approved_On__c = Datetime.now().addHours(2);
                existingInvCase.IR_Correction_Notes__c = null;

                insert existinginvCase;


                existinginvCase = getCase(existinginvCase.Id);


                Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));

                String query = 'SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,Effective_Start_Date__c,Currency__c,';
                   query += 'Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,Review_Date__c,';
                   query += 'Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where (Name = \'IRCaseMCH2\') AND Active__c=true AND Contract_Type__c != \'ISP\''; // Order by End_Date__c DESC limit 1 //2965556
                   query +=  ' AND Locked__c=true AND Effective_End_Date__c >= '+ IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + 'AND (Cancellation_Date__c=null OR Cancellation_Date__c >= ' + IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + ')';
                   query +=  ' Limit ' + batchSize;

                System.debug('Query=' + query);

                Test.startTest();
                IRCaseCreationBatchableAno execIRCaseCreation = new IRCaseCreationBatchableAno(ircaCurrent, ircaLast);
                execIRCaseCreation.query=query;
                ID batchprocessid=Database.executeBatch(execIRCaseCreation,batchSize);
                System.debug('batchprocessid=' + batchprocessid);
                System.debug('contractID------- '+mch2.Id);
                Test.stopTest();

                ircaCurrent = refreshIRCA(ircaCurrent);


                for (Case cs : [Select Id,IRCache_hasDraftThresholdViolation__c,IR_CurrentInvoiceNumber__c   from Case where IR_Original_Contract_Id__c = :mch2.Id])
                {

                    System.assertEquals(di1.Name,cs.IR_CurrentInvoiceNumber__c);
                }

            }
        }
}