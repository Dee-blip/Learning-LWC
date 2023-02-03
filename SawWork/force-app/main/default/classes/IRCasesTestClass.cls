/**
    IRCase Functionality related test cases.
    13/Aug/2014     CR 2723520 - Changing the logic of Threshold case creation so that even if a final invoice is not present,draft invoice
                                 threshold case should be created. Created following methods for test cases:
                                 1. IRCaseCreation_ThresholdNegTest
                                 2. IRCaseCreation_ThresholdPosFinalOnly
                                 3. IRCaseCreation_ThresholdPosDrftOnly
                                 4. IRCaseCreation_ThresholdPosBulk
    24/Mar/2015    CR 2867070 - Creating attachment with final invoice. If attachment is not there,IRCaseCreationData.initFinalInvoices fails to fetch the data.
                                    Also adding IRCache_hasDraftThresholdViolation__c in getCases query

    24/Mar/2015      CR 2965556 - If the case status or Escal status is Rejected  and correction notes are null, then case should not be updated
                                    If there is a contract change, then a case which is already in Approved status, should be reopened.
                                    Also doing consolidation changes by moving case initialization data to creationData method
    14-Apr-2015     CR 2986499 - If upsert happens on contract manual list, due to first run flag, the insert doesn't fire the trigger   Merge_Contract_Manual_List_ai_au
    29-Jan-2016     CR 3272721 - CMG wanted to stop Cases creation for scenarios of "contract change in the prior month"
    30-Mar-2017     CR 3668332 - Case amount currency is always USD even if Contract has non USD currency.
    06Apr-2017      CR 3713022 - Improving code coverage of OTB/IR classes
    04-May-2017     CR 3619951 - IR case incase of invoice missing last month
*/
@isTest(seeAllData=false)
public class IRCasesTestClass
{
    private static Boolean initFlag = false;
    private static User newOwner;
    private static User newOwnerRSM;
    private static User cmgUser;
    private static User sysAdmin = SObjectFactory.ADMIN_USER;
    private static Account_Reassignment_Rule__c newOwnerRule;
    // private static Map<String, GSM_Settings__mdt> testcaseCustomSettings = GsmUtilClass.getGSMSettingValue();
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
        // existingCase.RecordTypeId  = GsmUtilClass.GetCustomSettingValue('IR_CaseDefaultRecordTypeId');
        existingCase.RecordTypeId  = GSM_Custom_Settings__c.getValues('IR_CaseDefaultRecordTypeId').Value__c;
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
        newInvoice.Conversion_Rate_to_USD__c=1;
        newInvoice.billable_flag__c='Y';
        newInvoice.Previous_Month_Outstanding_Amount__c=100;
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
        return [select Id,Name,Account_Name__c,Invoice_Review_Case_Audit__c,OwnerId,Case__c,Type__c,Original_Contract_Id__c,Invoice_Date__c,Original_Amount__c, billable_flag__c, Previous_Month_Outstanding_Amount__c,Conversion_Rate_to_USD__c from Draft_Invoice__c where Id IN:pInvoiceList];
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

    public static User GetUser(String name){
      return [select Id from User where Alias = :name LIMIT 1];
    }

    public static GSM_Custom_Settings__c initGSMCustomSetting(String name, String value){
      GSM_Custom_Settings__c newGSMCustomSetting = new GSM_Custom_Settings__c();
      newGSMCustomSetting.Name = name;
      newGSMCustomSetting.Value__c = value;
      return newGSMCustomSetting;
    }

    /**
        Create IR_Case_Info__c records
    */

    //creating the IRcaseinfo record
    public static IR_Case_Info__c createIRCaseInfoRecord(Merge_Contract_Header__c pMch, Draft_Invoice__c di, String uniqueId)
    {
        IR_Case_Info__c irCaseInfo = new IR_Case_Info__c();
        irCaseInfo.Order_Id__c = pMch.Name;
        irCaseInfo.Active_Flag__c = true;
        irCaseInfo.Alert_Description__c = 'some data ; PS_OVERAGE_NOMATCH ; some extra data';
        irCaseInfo.Alert_Line__c = 'some data ; PS_OVERAGE_NOMATCH ; some extra data';
        irCaseInfo.Alert_Name__c = 'PS_OVERAGE_NOMATCH';
        irCaseInfo.Billable_Invoice_Id__c = di.Name;
        irCaseInfo.Invoice_Date__c = reviewDate;
        irCaseInfo.Create_Date__c	= Date.today();
        irCaseInfo.Last_Update_Date__c = Date.today();
        irCaseInfo.Invoice_Id__c = di.Name;
        irCaseInfo.Unique_Id__c = uniqueId;
        return irCaseInfo;
    }



    /**
        Init()
        - Intialize the static variables for this Test Class
    */
    // public static void Init()
    @testSetUp static void createData()
    {
      if(initFlag)
          return;

      reviewDate = Date.today().toStartOfMonth();

      String profileName = 'Sales - Media';
      String roleName = userRoleValue;
      newOwner = utilTestClass.CreateUser('TST_NUSR', roleName, profileName);
      newOwnerRSM = utilTestClass.CreateUser('TST_NRSM', roleName, profileName);
      cmgUser = utilTestClass.CreateUser('CMG_USER', 'CMG', 'CMG');

      insert (new User[] {newOwner, newOwnerRSM, cmgUser});
      System.runAs(sysAdmin){
        Test.startTest();
        newOwnerRule = utilTestClass.CreateAccountReassignmentRule(newOwner.Name, newOwner.Id, roleName);
        newOwnerRule.Associated_User_RSM__c = newOwnerRSM.Id;

        insert (new Account_Reassignment_Rule__c[] {newOwnerRule});


        list<GSM_Custom_Settings__c> lstGSM = new list<GSM_Custom_Settings__c>();

        User crmUser = utilTestClass.CreateUser('CRM_USER', 'Worldwide', 'CRM Integration');
        insert (new User[] {crmUser});

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
        lstGSM.add(initGSMCustomSetting('IR_CaseRecordTypeIds',invoiceReviewCaseId + ',' + readInvoiceReviewCaseId));
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

        Account acc1 =  (Account)new SobjectBuilder(Account.sObjectType)
            .eagerPopulate()
            .put(Account.Type, 'Lead')
            .create()
            .getRecord();
        Opportunity opp1 = (Opportunity)new SobjectBuilder(Opportunity.sObjectType)
            .eagerPopulate()
            .put(Opportunity.AccountId, acc1.Id)
            .put(Opportunity.StageName, '1-Create')
            .put(Opportunity.Name, 'IRCaseOppty1')
            .put(Opportunity.CloseDate, Date.today().addDays(10))
            .create()
            .getRecord();
        mch1 = createContractHeader('IRCaseMCH1', acc1.Id, opp1.Id);
        insert mch1;

        mcManList = createContractManualList('IRCaseMlist1', mch1.Name);
        mcManList.Review_Frequency__c = 'Monthly';
        mcManList.End_Date__c = Date.today().addMonths(2);
        mcManList.Owner__c = 'UNKNOWN';
        mcManList.Review_Date__c = reviewDate;
        mcManList.Priority__c = 'TESTPRIORITY';
        insert mcManList;
        prevMonthFinalInvoice = createInvoice(acc1.Akam_Account_Id__c, mch1.Name, '1303123567', reviewDate.addMonths(-1).addDays(4), 300);
        insert prevMonthFinalInvoice;


        //2867070
        attachments = createInvoiceAttachment (prevMonthFinalInvoice.Id);
        Blob b = Blob.valueOf('Test Data');
        attachments.Body = b;
        attachments.Name = 'Test Attachment for Parent';
        insert attachments;
        System.debug('Attachment Id : '+attachments.Id);
        initFlag = true;

        //Create PDF in File section
        ContentVersion cv = new ContentVersion();
        cv.FirstPublishLocationId = prevMonthFinalInvoice.Id;
        cv.PathOnClient= 'TestFilePDF';
        cv.Title= 'TestFilePDF';
        cv.VersionData = b;
        insert cv;

        Test.stopTest();
      }
    }

    public static void creationData(List<Merge_Contract_Header__c> pmchList,Invoice_Review_Case_Audit__c pIrcaCurrent , Invoice_Review_Case_Audit__c pIrcaLast)// , IRCaseCreationData pIrCaseData)
    {
            //pIrCaseData.initContractData(scope);
            IRCaseCreationData pIrCaseData = new IRCaseCreationData(pmchList,pircaCurrent,pircaLast,'batch');
            pIrCaseData.initContractData(pmchList,reviewDate);
            pIrCaseData.initExistingCaseData(pIrCaseData.getMchIdsSet(), reviewDate);
            pIrCaseData.initOwnerData(pIrCaseData.getMchIdsSet(), reviewDate, pIrCaseData.getMchIdAccIdMap().values());
            pIrCaseData.initCurrDraftInvData(pIrCaseData.getMchIdsSet(),pIrcaCurrent.Id, reviewDate);
            pIrCaseData.initFinalInvoices(pIrCaseData.getMchIdsSet(), reviewDate);
            if (!pIrCaseData.getFirstInvoiceImport())
                pIrCaseData.initLastDraftInvData(pIrCaseData.getMchIdsSet(), reviewDate, pIrcaLast.Import_Start_Date__c, pIrcaCurrent.Import_Start_Date__c,pIrcaLast.Id);

            // Id unassignedQueueId = pIrCaseData.getIRQueueByDevName(GSMUtilClass.GetCustomSettingValue('IR_Unassigned_QueueDevName'));
            Id unassignedQueueId = pIrCaseData.getIRQueueByDevName(GSM_Custom_Settings__c.getValues('IR_NewMissingProcess_BatchSize').Value__c);
            List<Case> existingIRCaseList = pIrCaseData.getExistingIRCaseList();
            Map<Id,Case> existingMCHIdCaseMap = pIrCaseData.getExistingMCHIdCaseMap();
            Map<Id,Case> mchOldCaseMap = pIrCaseData.getMchOldCaseMap();

            Set<Id> mchIdsSet = pIrCaseData.getMchIdsSet();
            mchIdList = pIrCaseData.getMchList();
            Map<Id, Merge_Contract_Header__c> mchMap = pIrCaseData.getMchMap();
            Map<Id,Merge_Contract_Manual_List__c> mchIDManualListMap = pIrCaseData.getMchIDManualListMap();
            Map<String,Id> manualListUserAliasIdMap = pIrCaseData.getManualListUserAliasIdMap();
            Map<Id,String> manualListUserIdAliasMap = pIrCaseData.getManualListUserIdAliasMap();
            mchIdAccIdMap = pIrCaseData.getMchIdAccIdMap();

            accOwnerIdMap = pIrCaseData.getAccOwnerIdMap();
            Map<Id,List<AccountTeamMember>> accATMMap = pIrCaseData.getAccATMMap();
            Map<Id,AccountTeamMember> accIRCaseOwnerATMMap = pIrCaseData.getAccIRCaseOwnerATMMap();
            accIRCaseEscalOwnerATMMap = pIrCaseData.getAccIRCaseEscalOwnerATMMap();

            List<Draft_Invoice__c> dIList = pIrCaseData.getDIList();
            Map<Id,Draft_Invoice__c> dIMap = pIrCaseData.getDIMap();
            Map<Id,Id> dIMCHIdsMap = pIrCaseData.getDIMCHIdsMap();
            Map<Id,Id> mCHDIIdsMap = pIrCaseData.getMCHDIIdsMap();

            //if (!pIrCaseData.getFirstInvoiceImport())
            Map<Id, Draft_Invoice__c> lastImportDIMap = pIrCaseData.getLastImportDIMap();
            Map<Id,Id> lastImportDIMCHIdsMap = pIrCaseData.getLastImportDIMCHIdsMap();
            Map<Id,Id> lastImportMCHDIIdsMap = pIrCaseData.getLastImportMCHDIIdsMap();

            List<Invoice__c> lastReviewFinalInvoiceList = pIrCaseData.getLastReviewFinalInvoiceList();
            Map<Id,Invoice__c> lastReviewFinalInvoiceMap = pIrCaseData.getLastReviewFinalInvoiceMap();
            Map<Id,Id> lastReviewFinalMCHInvoiceIdsMap = pIrCaseData.getLastReviewFinalMCHInvoiceIdsMap();
            Map<Id,Id> lastReviewFinalInvoiceMCHIdsMap = pIrCaseData.getLastReviewFinalInvoiceMCHIdsMap();

            contractIDCaseWrapperMap = pIrCaseData.getContractIDCaseWrapperMap();

         irCaseData = pIrCaseData;

     }

     static testMethod void adhocIRCase_SinglePositiveTest()
    {
        User cmgUser = GetUser('CMG_USER');
        Account acc1 = SobjectRepository.getAccount();
        Opportunity opp1 = SobjectRepository.getOpportunity();
        Merge_Contract_Header__c mch1Id = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
        Merge_Contract_Header__c mch1 = refreshContractHeader(mch1Id);
        Draft_Invoice__c di = createDraftInvoice(acc1.Id, mch1.Name, '1304123789', reviewDate, 500);
        di.OwnerId=cmgUser.Id;
        di.Original_Contract_Id__c=mch1.Id;
        di.Conversion_Rate_to_USD__c = 1;
        System.runAs(cmgUser)
        {
            insert di;

            di = refreshDraftInvoice(di);
            System.assertEquals(di.Type__c, 'UI');
            System.assertEquals(di.Name, '1304123789');
            System.assertEquals(di.Original_Contract_Id__c, mch1.Id);
            System.assertEquals(di.Invoice_Date__c, reviewDate);
            System.assertEquals(di.Original_Amount__c, 500);
            System.assertEquals(di.OwnerId, cmgUser.Id);

            Test.startTest();
                di.hasAttachment__c=true;
                update di;
            Test.stopTest();
        }

        di = refreshDraftInvoice(di);
        Case cs = getCase(di.Case__c);
        Merge_Contract_Manual_List__c mList1 = [select Id from Merge_Contract_Manual_List__c where Manual_List_Id__c = 'IRCaseMlist1' limit 1];

        mcManList = refreshContractMList(mList1);

        System.Debug('diCase=' + cs);
        System.assertEquals(cs.Id,di.Case__c);

        System.assert(cs.Description.contains(Label.IR_SFDC_Ad_hoc_Invoice));
        System.assertEquals(cs.OwnerId,cmgUser.Id);
        System.assertEquals(cs.IR_Invoice_Date__c,reviewDate);
        System.assertEquals(cs.IR_Original_Contract_Id__c,mch1.Id);
        System.assertEquals(cs.OwnerId,cmgUser.Id);
        System.assertEquals(cs.Contract_Manual_List_Priority__c,mcManList.Priority__c);
    }

    static testMethod void IRCaseCreationBatch_SinglePositiveTest()
    {
        System.runAs(sysAdmin)
        {
            Account acc1 = SobjectRepository.getAccount();
            Opportunity opp1 = SobjectRepository.getOpportunity();
            Merge_Contract_Header__c mch1Id = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
            Merge_Contract_Header__c mch1 = refreshContractHeader(mch1Id);

            Merge_Contract_Header__c mch2 = createContractHeader('IRCaseMCH2', acc1.Id, opp1.Id);
            mch2.Manual_List__c = false;
            mch2.Acceptance_Date__c = reviewDate.addMonths(-1).addDays(10);
            insert mch2;

            Merge_Contract_Manual_List__c mcManList2 = createContractManualList('IRCaseMlist2', mch2.Name);
            mcManList2.Review_Frequency__c = 'Monthly';
            mcManList2.End_Date__c = Date.today().addMonths(2);
            mcManList2.Owner__c = 'UNKNOWN';
            mcManList2.Review_Date__c = reviewDate;
            mcManList2.Priority__c = 'TESTPRIORITY';
            insert mcManList2;

            //Added by chakri
            Merge_Contract_Manual_List__c mcManList3 = createContractManualList('IRCaseMlist3', mch2.Name);
            mcManList3.Review_Frequency__c = 'Monthly';
            mcManList3.End_Date__c = Date.today().addMonths(2);
            mcManList3.Owner__c = 'UNKNOWN';
            mcManList3.Review_Date__c = reviewDate;
            mcManList3.Priority__c = 'TESTPRIORITY';
            insert mcManList3;


            Invoice__c prevMonthFinalInvoice2 = createInvoice(acc1.AKAM_Account_ID__c, mch2.Name, '1303123232', reviewDate.addMonths(-1), 10);
            insert prevMonthFinalInvoice2;

            Invoice_Review_Case_Audit__c ircaCurrent=createIRCARec(reviewDate,'IRCaseTest1278');
            insert ircaCurrent;

            Invoice_Review_Case_Audit__c ircaLast=new Invoice_Review_Case_Audit__c();

            Draft_Invoice__c di1=createDraftInvoice(acc1.Id, mch1.Name, '1304123789', reviewDate, 500);
            di1.CI_Original_Contract_Id__c=mch1.Name;
            di1.Invoice_Review_Case_Audit__c=ircaCurrent.Id;
            insert di1;

            di1 = refreshDraftInvoice(di1);
            System.assertEquals(di1.Type__c, 'System');
            System.assertEquals(di1.Name, '1304123789');
            System.assertEquals(di1.Original_Contract_Id__c, mch1.Id);
            System.assertEquals(di1.Invoice_Date__c, reviewDate);
            System.assertEquals(di1.Original_Amount__c, 500);
            System.assertEquals(di1.OwnerId, sysAdmin.Id);
            System.assertEquals(di1.Invoice_Review_Case_Audit__c, ircaCurrent.Id);

            di1.hasAttachment__c=true;
            update di1;

            //Test.startTest();
                ircaCurrent.Import_End_Date__c=Datetime.now();
                ircaCurrent.Import_Status__c='Success';
                ircaCurrent.Trigger_Case_Creation__c = true;
                update ircaCurrent;
            //Test.stopTest();
            Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));
            String query = 'SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,Effective_Start_Date__c,';
               query += 'Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,Review_Date__c,';
               query += 'Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Active__c=true AND Contract_Type__c != \'ISP\''; // Order by End_Date__c DESC limit 1 //2965556
               query +=  ' AND Locked__c=true AND Effective_End_Date__c >= '+ IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + 'AND (Cancellation_Date__c=null OR Cancellation_Date__c >= ' + IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + ')';
               query +=  ' Limit ' + batchSize;

            System.debug('Query=' + query);

            Test.startTest();
            IRCaseCreationBatchable execIRCaseCreation = new IRCaseCreationBatchable(ircaCurrent, ircaLast);
            execIRCaseCreation.query=query;
            //Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));
            ID batchprocessid=Database.executeBatch(execIRCaseCreation,batchSize);
            //System.debug(Database.executeBatch(execIRCaseCreation,batchSize));
            System.debug('batchprocessid=' + batchprocessid);
            Test.stopTest();

            ircaCurrent = refreshIRCA(ircaCurrent);
            System.assert(ircaCurrent.Case_Creation_Completed__c);
            System.assert(ircaCurrent.Case_Creation_End_Date__c!=null);
            System.assertEquals('Success', ircaCurrent.Case_Creation_Status__c);

        }
    }

    static testMethod void IRCaseCreation_AllPositiveTest()
    {
        System.runAs(sysAdmin)
        {
            Account acc1 = SobjectRepository.getAccount();
            Opportunity opp1 = SobjectRepository.getOpportunity();
            Merge_Contract_Header__c mch1Id = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
            Merge_Contract_Header__c mch1 = refreshContractHeader(mch1Id);

            Merge_Contract_Header__c mch2 = createContractHeader('IRCaseMCH2', acc1.Id, opp1.Id);
            mch2.Manual_List__c = false;
            mch2.Acceptance_Date__c = reviewDate.addMonths(-1).addDays(10);
            insert mch2;

            Merge_Contract_Manual_List__c mcManList2 = createContractManualList('IRCaseMlist2', mch2.Name);
            mcManList2.Review_Frequency__c = 'Monthly';
            mcManList2.End_Date__c = Date.today().addMonths(2);
            mcManList2.Owner__c = 'UNKNOWN';
            mcManList2.Review_Date__c = reviewDate;
            mcManList2.Priority__c = 'TESTPRIORITY';
            insert mcManList2;

            Invoice__c prevMonthFinalInvoice2 = createInvoice(acc1.AKAM_Account_ID__c, mch2.Name, '1303123232', reviewDate.addMonths(-1), 10);
            insert prevMonthFinalInvoice2;

            Invoice_Review_Case_Audit__c ircaCurrent=createIRCARec(reviewDate,'IRCaseTest1278');
            insert ircaCurrent;

            Invoice_Review_Case_Audit__c ircaLast=new Invoice_Review_Case_Audit__c();

            Draft_Invoice__c di1=createDraftInvoice(acc1.Id, mch1.Name, '1304123789', reviewDate, 500);
            di1.CI_Original_Contract_Id__c=mch1.Name;
            di1.Invoice_Review_Case_Audit__c=ircaCurrent.Id;
            insert di1;

            di1 = refreshDraftInvoice(di1);
            System.assertEquals(di1.Type__c, 'System');
            System.assertEquals(di1.Name, '1304123789');
            System.assertEquals(di1.Original_Contract_Id__c, mch1.Id);
            System.assertEquals(di1.Invoice_Date__c, reviewDate);
            System.assertEquals(di1.Original_Amount__c, 500);
            System.assertEquals(di1.OwnerId, sysAdmin.Id);
            System.assertEquals(di1.Invoice_Review_Case_Audit__c, ircaCurrent.Id);

            di1.hasAttachment__c=true;
            update di1;

            //Test.startTest();
                ircaCurrent.Import_End_Date__c=Datetime.now();
                ircaCurrent.Import_Status__c='Success';
                ircaCurrent.Trigger_Case_Creation__c = true;
                update ircaCurrent;
            //Test.stopTest();

            Test.startTest();
            List<Merge_Contract_Header__c> mchList1 = new List<Merge_Contract_Header__c>();
            for (Merge_Contract_Header__c mch : [SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,
            Effective_Start_Date__c,Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,
            Review_Date__c,Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Active__c=true AND Contract_Type__c != 'ISP' //2965556
            AND Locked__c=true AND Effective_End_Date__c >= :reviewDate.addMonths(-1) AND (Cancellation_Date__c=null OR Cancellation_Date__c >= :reviewDate.addMonths(-1)) LIMIT 100])
            //(Id=:mch1.Id OR Id=:mch2.Id)])
            {
                mchList1.add(mch);
            }
            System.debug('mchList1 size=' + mchList1.size());
            System.debug('mchList1=' + mchList1);

            CaseTriggerClass.isIRCaseCreationInprogress=true;
            creationData(mchList1,ircaCurrent,ircaLast); //Consolidated data creation for all test methods in  creationData method
            /*IRCaseCreationData irCaseData = new IRCaseCreationData(mchList1,ircaCurrent,ircaLast,'batch');
            //irCaseData.initContractData(scope);
            irCaseData.initContractData(mchList1,reviewDate);
            irCaseData.initExistingCaseData(irCaseData.getMchIdsSet(), reviewDate);
            irCaseData.initOwnerData(irCaseData.getMchIdsSet(), reviewDate, irCaseData.getMchIdAccIdMap().values());
            irCaseData.initCurrDraftInvData(irCaseData.getMchIdsSet(),ircaCurrent.Id, reviewDate);
            irCaseData.initFinalInvoices(irCaseData.getMchIdsSet(), reviewDate);
            if (!irCaseData.getFirstInvoiceImport())
                irCaseData.initLastDraftInvData(irCaseData.getMchIdsSet(), reviewDate, ircaLast.Import_Start_Date__c, ircaCurrent.Import_Start_Date__c,ircaLast.Id);

            Id unassignedQueueId = irCaseData.getIRQueueByDevName(GSMUtilClass.GetCustomSettingValue('IR_Unassigned_QueueDevName'));
            List<Case> existingIRCaseList = irCaseData.getExistingIRCaseList();
            Map<Id,Case> existingMCHIdCaseMap = irCaseData.getExistingMCHIdCaseMap();
            Map<Id,Case> mchOldCaseMap = irCaseData.getMchOldCaseMap();

            Set<Id> mchIdsSet = irCaseData.getMchIdsSet();
            List<Merge_Contract_Header__c> mchList = irCaseData.getMchList();
            Map<Id, Merge_Contract_Header__c> mchMap = irCaseData.getMchMap();
            Map<Id,Merge_Contract_Manual_List__c> mchIDManualListMap = irCaseData.getMchIDManualListMap();
            Map<String,Id> manualListUserAliasIdMap = irCaseData.getManualListUserAliasIdMap();
            Map<Id,String> manualListUserIdAliasMap = irCaseData.getManualListUserIdAliasMap();
            Map<Id,Id> mchIdAccIdMap = irCaseData.getMchIdAccIdMap();

            Map<Id,Id> accOwnerIdMap = irCaseData.getAccOwnerIdMap();
            Map<Id,List<AccountTeamMember>> accATMMap = irCaseData.getAccATMMap();
            Map<Id,AccountTeamMember> accIRCaseOwnerATMMap = irCaseData.getAccIRCaseOwnerATMMap();
            Map<Id,AccountTeamMember> accIRCaseEscalOwnerATMMap = irCaseData.getAccIRCaseEscalOwnerATMMap();

            List<Draft_Invoice__c> dIList = irCaseData.getDIList();
            Map<Id,Draft_Invoice__c> dIMap = irCaseData.getDIMap();
            Map<Id,Id> dIMCHIdsMap = irCaseData.getDIMCHIdsMap();
            Map<Id,Id> mCHDIIdsMap = irCaseData.getMCHDIIdsMap();

            //if (!irCaseData.getFirstInvoiceImport())
            Map<Id, Draft_Invoice__c> lastImportDIMap = irCaseData.getLastImportDIMap();
            Map<Id,Id> lastImportDIMCHIdsMap = irCaseData.getLastImportDIMCHIdsMap();
            Map<Id,Id> lastImportMCHDIIdsMap = irCaseData.getLastImportMCHDIIdsMap();

            List<Invoice__c> lastReviewFinalInvoiceList = irCaseData.getLastReviewFinalInvoiceList();
            Map<Id,Invoice__c> lastReviewFinalInvoiceMap = irCaseData.getLastReviewFinalInvoiceMap();
            Map<Id,Id> lastReviewFinalMCHInvoiceIdsMap = irCaseData.getLastReviewFinalMCHInvoiceIdsMap();
            Map<Id,Id> lastReviewFinalInvoiceMCHIdsMap = irCaseData.getLastReviewFinalInvoiceMCHIdsMap();

            Map<Id,IRCaseWrapper> contractIDCaseWrapperMap = irCaseData.getContractIDCaseWrapperMap();
            */
            // check IR Case creation criteria
            //CR 3272721
            //IRCaseCreationCriteria.checkForContractChangeBulk(irCaseData, reviewDate);
            IRCaseCreationCriteria.checkForManualContractBulk(irCaseData, reviewDate);
            IRCaseCreationCriteria.checkForDoubleInvoiceReviewBulk(true,mchIdList,irCaseData,reviewDate, contractIDCaseWrapperMap,accOwnerIdMap,mchIdAccIdMap,accIRCaseEscalOwnerATMMap); //2965556
            IRCaseCreationCriteria.checkForMissingInvoiceBulk(irCaseData, reviewDate);
            IRCaseCreationCriteria.checkForNewInvoiceBulk(irCaseData, reviewDate);
            IRCaseCreationCriteria.checkForNegativeAmountBulk(irCaseData, reviewDate);
            IRCaseCreationCriteria.checkForThresholdViolationBulk(irCaseData, reviewDate);
            Test.stopTest();
        }
    }
    //Multiple Manual List items
    static testMethod void IRCaseCreationBatch_PosMonthlyML()
    {
        System.runAs(sysAdmin)
        {
            Account acc1 = SobjectRepository.getAccount();
            Opportunity opp1 = SobjectRepository.getOpportunity();
            Merge_Contract_Header__c mch1Id = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
            Merge_Contract_Header__c mch1 = refreshContractHeader(mch1Id);

            Merge_Contract_Header__c mch2 = createContractHeader('IRCaseMCH2', acc1.Id, opp1.Id);
            mch2.Manual_List__c = false;
            mch2.Acceptance_Date__c = reviewDate.addMonths(-1).addDays(10);
            insert mch2;

            /*
            *   Creating two manual list items which are active for the present review date
            *   ---------------------------------------------------------------------------
            *   Review Frequency : Monthly
            *   Review Date      : Present review date
            *   End date         : In Future
            */
            Merge_Contract_Manual_List__c mcManList2 = createContractManualList('IRCaseMlist2', mch2.Name);
            mcManList2.Review_Frequency__c = 'Monthly';
            mcManList2.End_Date__c = Date.today().addMonths(2);
            mcManList2.Owner__c = 'UNKNOWN';
            mcManList2.Review_Date__c = reviewDate;
            mcManList2.Priority__c = 'TESTPRIORITY';
            insert mcManList2;

            Merge_Contract_Manual_List__c mcManList3 = createContractManualList('IRCaseMlist3', mch2.Name);
            mcManList3.Review_Frequency__c = 'Monthly';
            mcManList3.End_Date__c = Date.today().addMonths(2);
            mcManList3.Owner__c = 'UNKNOWN';
            mcManList3.Review_Date__c = reviewDate;
            mcManList3.Priority__c = 'TESTPRIORITY';
            insert mcManList3;

            Invoice__c prevMonthFinalInvoice2 = createInvoice(acc1.AKAM_Account_ID__c, mch2.Name, '1303123232', reviewDate.addMonths(-1), 10);
            insert prevMonthFinalInvoice2;

            Invoice_Review_Case_Audit__c ircaCurrent=createIRCARec(reviewDate,'IRCaseTest1278');
            insert ircaCurrent;

            Invoice_Review_Case_Audit__c ircaLast=new Invoice_Review_Case_Audit__c();

            Draft_Invoice__c di1=createDraftInvoice(acc1.Id, mch1.Name, '1304123789', reviewDate, 500);
            di1.CI_Original_Contract_Id__c=mch1.Name;
            di1.Invoice_Review_Case_Audit__c=ircaCurrent.Id;
            insert di1;

            di1 = refreshDraftInvoice(di1);
            System.assertEquals(di1.Type__c, 'System');
            System.assertEquals(di1.Name, '1304123789');
            System.assertEquals(di1.Original_Contract_Id__c, mch1.Id);
            System.assertEquals(di1.Invoice_Date__c, reviewDate);
            System.assertEquals(di1.Original_Amount__c, 500);
            System.assertEquals(di1.OwnerId, sysAdmin.Id);
            System.assertEquals(di1.Invoice_Review_Case_Audit__c, ircaCurrent.Id);

            di1.hasAttachment__c=true;
            update di1;

            //Test.startTest();
                ircaCurrent.Import_End_Date__c=Datetime.now();
                ircaCurrent.Import_Status__c='Success';
                ircaCurrent.Trigger_Case_Creation__c = true;
                update ircaCurrent;
            //Test.stopTest();
            Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));
            String query = 'SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,Effective_Start_Date__c,';
               query += 'Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,Review_Date__c,';
               query += 'Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Active__c=true AND Contract_Type__c != \'ISP\''; // Order by End_Date__c DESC limit 1 //2965556
               query +=  ' AND Locked__c=true AND Effective_End_Date__c >= '+ IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + 'AND (Cancellation_Date__c=null OR Cancellation_Date__c >= ' + IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + ')';
               query +=  ' Limit ' + batchSize;

            System.debug('Query=' + query);

            Test.startTest();
            IRCaseCreationBatchable execIRCaseCreation = new IRCaseCreationBatchable(ircaCurrent, ircaLast);
            execIRCaseCreation.query=query;
            //Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));
            ID batchprocessid=Database.executeBatch(execIRCaseCreation,batchSize);
            //System.debug(Database.executeBatch(execIRCaseCreation,batchSize));
            System.debug('batchprocessid=' + batchprocessid);
            System.debug('--->');
            Test.stopTest();

            ircaCurrent = refreshIRCA(ircaCurrent);
            System.assert(ircaCurrent.Case_Creation_Completed__c);
            System.assert(ircaCurrent.Case_Creation_End_Date__c!=null);
            System.assertEquals('Success', ircaCurrent.Case_Creation_Status__c);


            for (Case cs : [Select Id, Multiple_Manual_Lists__c  from Case where IR_Original_Contract_Id__c = :mch2.Id])
            {
                System.assertEquals(true, cs.Multiple_Manual_Lists__c);
            }
        }
    }
     //Multiple Manual List items
    static testMethod void IRCaseCreationBatch_PosBothML()
    {
        System.runAs(sysAdmin)
        {
            Account acc1 = SobjectRepository.getAccount();
            Opportunity opp1 = SobjectRepository.getOpportunity();
            Merge_Contract_Header__c mch1Id = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
            Merge_Contract_Header__c mch1 = refreshContractHeader(mch1Id);

            Merge_Contract_Header__c mch2 = createContractHeader('IRCaseMCH2', acc1.Id, opp1.Id);
            mch2.Manual_List__c = false;
            mch2.Acceptance_Date__c = reviewDate.addMonths(-1).addDays(10);
            insert mch2;

            /*
            *   Creating two manual list items which are active for the present review date
            *   ---------------------------------------------------------------------------
            *   Review Frequency : Monthly,One Time
            *   Review Date      : Present review date
            *   End date         : In Future
            */
            Merge_Contract_Manual_List__c mcManList2 = createContractManualList('IRCaseMlist2', mch2.Name);
            mcManList2.Review_Frequency__c = 'Monthly';
            mcManList2.End_Date__c = Date.today().addMonths(2);
            mcManList2.Owner__c = 'UNKNOWN';
            mcManList2.Review_Date__c = reviewDate;
            mcManList2.Priority__c = 'TESTPRIORITY';
            insert mcManList2;

            Merge_Contract_Manual_List__c mcManList3 = createContractManualList('IRCaseMlist3', mch2.Name);
            mcManList3.Review_Frequency__c = 'One Time';
            mcManList3.End_Date__c = Date.today().addMonths(2);
            mcManList3.Owner__c = 'UNKNOWN';
            mcManList3.Review_Date__c = reviewDate;
            mcManList3.Priority__c = 'TESTPRIORITY';
            insert mcManList3;

            Invoice__c prevMonthFinalInvoice2 = createInvoice(acc1.AKAM_Account_ID__c, mch2.Name, '1303123232', reviewDate.addMonths(-1), 10);
            insert prevMonthFinalInvoice2;

            Invoice_Review_Case_Audit__c ircaCurrent=createIRCARec(reviewDate,'IRCaseTest1278');
            insert ircaCurrent;

            Invoice_Review_Case_Audit__c ircaLast=new Invoice_Review_Case_Audit__c();

            Draft_Invoice__c di1=createDraftInvoice(acc1.Id, mch1.Name, '1304123789', reviewDate, 500);
            di1.CI_Original_Contract_Id__c=mch1.Name;
            di1.Invoice_Review_Case_Audit__c=ircaCurrent.Id;
            insert di1;

            di1 = refreshDraftInvoice(di1);
            System.assertEquals(di1.Type__c, 'System');
            System.assertEquals(di1.Name, '1304123789');
            System.assertEquals(di1.Original_Contract_Id__c, mch1.Id);
            System.assertEquals(di1.Invoice_Date__c, reviewDate);
            System.assertEquals(di1.Original_Amount__c, 500);
            System.assertEquals(di1.OwnerId, sysAdmin.Id);
            System.assertEquals(di1.Invoice_Review_Case_Audit__c, ircaCurrent.Id);

            di1.hasAttachment__c=true;
            update di1;

            //Test.startTest();
                ircaCurrent.Import_End_Date__c=Datetime.now();
                ircaCurrent.Import_Status__c='Success';
                ircaCurrent.Trigger_Case_Creation__c = true;
                update ircaCurrent;
            //Test.stopTest();
            Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));
            String query = 'SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,Effective_Start_Date__c,';
               query += 'Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,Review_Date__c,';
               query += 'Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Active__c=true AND Contract_Type__c != \'ISP\''; // Order by End_Date__c DESC limit 1 //2965556
               query +=  ' AND Locked__c=true AND Effective_End_Date__c >= '+ IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + 'AND (Cancellation_Date__c=null OR Cancellation_Date__c >= ' + IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + ')';
               query +=  ' Limit ' + batchSize;

            System.debug('Query=' + query);

            Test.startTest();
            IRCaseCreationBatchable execIRCaseCreation = new IRCaseCreationBatchable(ircaCurrent, ircaLast);
            execIRCaseCreation.query=query;
            //Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));
            ID batchprocessid=Database.executeBatch(execIRCaseCreation,batchSize);
            //System.debug(Database.executeBatch(execIRCaseCreation,batchSize));
            System.debug('batchprocessid=' + batchprocessid);
            System.debug('--->');
            Test.stopTest();

            ircaCurrent = refreshIRCA(ircaCurrent);
            System.assert(ircaCurrent.Case_Creation_Completed__c);
            System.assert(ircaCurrent.Case_Creation_End_Date__c!=null);
            System.assertEquals('Success', ircaCurrent.Case_Creation_Status__c);


            for (Case cs : [Select Id, Multiple_Manual_Lists__c  from Case where IR_Original_Contract_Id__c = :mch2.Id])
            {
                System.assertEquals(true, cs.Multiple_Manual_Lists__c);
            }
        }
    }

    //Multiple Manual List items
    static testMethod void IRCaseCreationBatch_NegOneTimeExpML()
    {
        System.runAs(SObjectFactory.ADMIN_USER)
        {
            Account acc1 = SobjectRepository.getAccount();
            Opportunity opp1 = SobjectRepository.getOpportunity();
            Merge_Contract_Header__c mch2 = createContractHeader('IRCaseMCH2', acc1.Id, opp1.Id);
            mch2.Manual_List__c = false;
            mch2.Acceptance_Date__c = reviewDate.addMonths(-1).addDays(10);
            insert mch2;

            /*
            *   Creating two manual list items which are active for the present review date
            *   ---------------------------------------------------------------------------
            *   Review Frequency : Monthly,One Time
            *   Review Date      : Present review date for monthly is valid and One time expired
            *   End date         : In Future
            */
            Merge_Contract_Manual_List__c mcManList2 = createContractManualList('IRCaseMlist2', mch2.Name);
            mcManList2.Review_Frequency__c = 'Monthly';
            mcManList2.End_Date__c = Date.today().addMonths(2);
            mcManList2.Owner__c = 'UNKNOWN';
            mcManList2.Review_Date__c = reviewDate;
            mcManList2.Priority__c = 'TESTPRIORITY';
            insert mcManList2;

            Merge_Contract_Manual_List__c mcManList3 = createContractManualList('IRCaseMlist3', mch2.Name);
            mcManList3.Review_Frequency__c = 'One Time';
            mcManList3.End_Date__c = Date.today().addMonths(2);
            mcManList3.Owner__c = 'UNKNOWN';
            mcManList3.Review_Date__c = Date.today().addMonths(-5);
            mcManList3.Priority__c = 'TESTPRIORITY';
            insert mcManList3;

            Invoice__c prevMonthFinalInvoice2 = createInvoice(acc1.Akam_Account_Id__c, mch2.Name, '1303123232', reviewDate.addMonths(-1), 10);
            insert prevMonthFinalInvoice2;

            Invoice_Review_Case_Audit__c ircaCurrent=createIRCARec(reviewDate,'IRCaseTest1278');
            insert ircaCurrent;

            Invoice_Review_Case_Audit__c ircaLast=new Invoice_Review_Case_Audit__c();

            Merge_Contract_Header__c mch1 = [select Id, Name from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
            Draft_Invoice__c di1=createDraftInvoice(acc1.Id, mch1.Name, '1304123789', reviewDate, 500);
            di1.CI_Original_Contract_Id__c=mch1.Name;
            di1.Invoice_Review_Case_Audit__c=ircaCurrent.Id;
            insert di1;

            di1 = refreshDraftInvoice(di1);
            System.assertEquals(di1.Type__c, 'System');
            System.assertEquals(di1.Name, '1304123789');
            System.assertEquals(di1.Original_Contract_Id__c, mch1.Id);
            System.assertEquals(di1.Invoice_Date__c, reviewDate);
            System.assertEquals(di1.Original_Amount__c, 500);
            System.assertEquals(di1.OwnerId, SObjectFactory.ADMIN_USER.Id);
            System.assertEquals(di1.Invoice_Review_Case_Audit__c, ircaCurrent.Id);

            di1.hasAttachment__c=true;
            update di1;

            //Test.startTest();
                ircaCurrent.Import_End_Date__c=Datetime.now();
                ircaCurrent.Import_Status__c='Success';
                ircaCurrent.Trigger_Case_Creation__c = true;
                update ircaCurrent;
            //Test.stopTest();
            // Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));
            Integer batchSize = Integer.valueOf(GSM_Custom_Settings__c.getValues('IR_NewMissingProcess_BatchSize').Value__c);
            String query = 'SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,Effective_Start_Date__c,';
               query += 'Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,Review_Date__c,';
               query += 'Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Active__c=true AND Contract_Type__c != \'ISP\''; // Order by End_Date__c DESC limit 1 //2965556
               query +=  ' AND Locked__c=true AND Effective_End_Date__c >= '+ IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + 'AND (Cancellation_Date__c=null OR Cancellation_Date__c >= ' + IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + ')';
               query +=  ' Limit ' + batchSize;

            System.debug('Query=' + query);
            Test.startTest();
            IRCaseCreationBatchable execIRCaseCreation = new IRCaseCreationBatchable(ircaCurrent, ircaLast);
            execIRCaseCreation.query=query;
            //Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));
            ID batchprocessid=Database.executeBatch(execIRCaseCreation,batchSize);
            //System.debug(Database.executeBatch(execIRCaseCreation,batchSize));
            System.debug('batchprocessid=' + batchprocessid);
            System.debug('--->');
            Test.stopTest();

            ircaCurrent = refreshIRCA(ircaCurrent);
            System.assert(ircaCurrent.Case_Creation_Completed__c);
            System.assert(ircaCurrent.Case_Creation_End_Date__c!=null);
            System.assertEquals('Success', ircaCurrent.Case_Creation_Status__c);


            for (Case cs : [Select Id, Multiple_Manual_Lists__c  from Case where IR_Original_Contract_Id__c = :mch2.Id])
            {
                System.assertNotEquals(true, cs.Multiple_Manual_Lists__c);
            }
        }
    }

    //Multiple Manual List items
    static testMethod void IRCaseCreationBatch_NegBothExpML()
    {
        System.runAs(sysAdmin)
        {
            Account acc1 = SobjectRepository.getAccount();
            Opportunity opp1 = SobjectRepository.getOpportunity();
            Merge_Contract_Header__c mch1Id = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
            Merge_Contract_Header__c mch1 = refreshContractHeader(mch1Id);

            Merge_Contract_Header__c mch2 = createContractHeader('IRCaseMCH2', acc1.Id, opp1.Id);
            mch2.Manual_List__c = false;
            mch2.Acceptance_Date__c = reviewDate.addMonths(-1).addDays(10);
            insert mch2;

            /*
            *   Creating two manual list items which are active for the present review date
            *   ---------------------------------------------------------------------------
            *   Review Frequency : Monthly,One Time
            *   Review Date      : Both ML has expired dates
            *   End date         : In Future
            */
            Merge_Contract_Manual_List__c mcManList2 = createContractManualList('IRCaseMlist2', mch2.Name);
            mcManList2.Review_Frequency__c = 'Monthly';
            mcManList2.End_Date__c = Date.today().addMonths(2);
            mcManList2.Owner__c = 'UNKNOWN';
            mcManList2.Review_Date__c = Date.today().addMonths(-5);
            mcManList2.Priority__c = 'TESTPRIORITY';
            insert mcManList2;

            Merge_Contract_Manual_List__c mcManList3 = createContractManualList('IRCaseMlist3', mch2.Name);
            mcManList3.Review_Frequency__c = 'One Time';
            mcManList3.End_Date__c = Date.today().addMonths(2);
            mcManList3.Owner__c = 'UNKNOWN';
            mcManList3.Review_Date__c = Date.today().addMonths(-5);
            mcManList3.Priority__c = 'TESTPRIORITY';
            insert mcManList3;

            Invoice__c prevMonthFinalInvoice2 = createInvoice(acc1.AKAM_Account_ID__c, mch2.Name, '1303123232', reviewDate.addMonths(-1), 10);
            insert prevMonthFinalInvoice2;

            Invoice_Review_Case_Audit__c ircaCurrent=createIRCARec(reviewDate,'IRCaseTest1278');
            insert ircaCurrent;

            Invoice_Review_Case_Audit__c ircaLast=new Invoice_Review_Case_Audit__c();

            Draft_Invoice__c di1=createDraftInvoice(acc1.Id, mch1.Name, '1304123789', reviewDate, 500);
            di1.CI_Original_Contract_Id__c=mch1.Name;
            di1.Invoice_Review_Case_Audit__c=ircaCurrent.Id;
            insert di1;

            di1 = refreshDraftInvoice(di1);
            System.assertEquals(di1.Type__c, 'System');
            System.assertEquals(di1.Name, '1304123789');
            System.assertEquals(di1.Original_Contract_Id__c, mch1.Id);
            System.assertEquals(di1.Invoice_Date__c, reviewDate);
            System.assertEquals(di1.Original_Amount__c, 500);
            System.assertEquals(di1.OwnerId, sysAdmin.Id);
            System.assertEquals(di1.Invoice_Review_Case_Audit__c, ircaCurrent.Id);

            di1.hasAttachment__c=true;
            update di1;

            //Test.startTest();
                ircaCurrent.Import_End_Date__c=Datetime.now();
                ircaCurrent.Import_Status__c='Success';
                ircaCurrent.Trigger_Case_Creation__c = true;
                update ircaCurrent;
            //Test.stopTest();
            Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));
            String query = 'SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,Effective_Start_Date__c,';
               query += 'Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,Review_Date__c,';
               query += 'Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Active__c=true AND Contract_Type__c != \'ISP\''; // Order by End_Date__c DESC limit 1 //2965556
               query +=  ' AND Locked__c=true AND Effective_End_Date__c >= '+ IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + 'AND (Cancellation_Date__c=null OR Cancellation_Date__c >= ' + IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + ')';
               query +=  ' Limit ' + batchSize;

            System.debug('Query=' + query);

            Test.startTest();
            IRCaseCreationBatchable execIRCaseCreation = new IRCaseCreationBatchable(ircaCurrent, ircaLast);
            execIRCaseCreation.query=query;
            //Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));
            ID batchprocessid=Database.executeBatch(execIRCaseCreation,batchSize);
            //System.debug(Database.executeBatch(execIRCaseCreation,batchSize));
            System.debug('batchprocessid=' + batchprocessid);
            System.debug('--->');
            Test.stopTest();

            ircaCurrent = refreshIRCA(ircaCurrent);
            System.assert(ircaCurrent.Case_Creation_Completed__c);
            System.assert(ircaCurrent.Case_Creation_End_Date__c!=null);
            System.assertEquals('Success', ircaCurrent.Case_Creation_Status__c);


            for (Case cs : [Select Id, Multiple_Manual_Lists__c  from Case where IR_Original_Contract_Id__c = :mch2.Id])
            {
                System.assertNotEquals(true, cs.Multiple_Manual_Lists__c);
            }
        }
    }
    //Multiple Manual List items
    static testMethod void IRCaseCreationBatch_Neg()
    {
        System.runAs(sysAdmin)
        {
            Account acc1 = SobjectRepository.getAccount();
            Opportunity opp1 = SobjectRepository.getOpportunity();
            Merge_Contract_Header__c mch1Id = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
            Merge_Contract_Header__c mch1 = refreshContractHeader(mch1Id);

            Merge_Contract_Header__c mch2 = createContractHeader('IRCaseMCH2', acc1.Id, opp1.Id);
            mch2.Manual_List__c = false;
            mch2.Acceptance_Date__c = reviewDate.addMonths(-1).addDays(10);
            insert mch2;

            /*
            *   Creating two manual list items which are active for the present review date
            *   ---------------------------------------------------------------------------
            *   Review Frequency : Monthly,One Time
            *   Review Date      : Monthly date is expired
            *   End date         : In Future
            */
            Merge_Contract_Manual_List__c mcManList2 = createContractManualList('IRCaseMlist2', mch2.Name);
            mcManList2.Review_Frequency__c = 'Monthly';
            mcManList2.End_Date__c = Date.today().addMonths(2);
            mcManList2.Owner__c = 'UNKNOWN';
            mcManList2.Review_Date__c = Date.today().addMonths(-5);
            mcManList2.Priority__c = 'TESTPRIORITY';
            insert mcManList2;

            Merge_Contract_Manual_List__c mcManList3 = createContractManualList('IRCaseMlist3', mch2.Name);
            mcManList3.Review_Frequency__c = 'One Time';
            mcManList3.End_Date__c = Date.today().addMonths(2);
            mcManList3.Owner__c = 'UNKNOWN';
            mcManList3.Review_Date__c = Date.today().toStartOfMonth().addDays(-1);//reviewDate; //2867070
            mcManList3.Priority__c = 'TESTPRIORITY';
            insert mcManList3;

            Invoice__c prevMonthFinalInvoice2 = createInvoice(acc1.AKAM_Account_ID__c, mch2.Name, '1303123232', reviewDate.addMonths(-1), 10);
            insert prevMonthFinalInvoice2;

            Invoice_Review_Case_Audit__c ircaCurrent=createIRCARec(reviewDate,'IRCaseTest1278');
            insert ircaCurrent;

            Invoice_Review_Case_Audit__c ircaLast=new Invoice_Review_Case_Audit__c();

            Draft_Invoice__c di1=createDraftInvoice(acc1.Id, mch1.Name, '1304123789', reviewDate, 500);
            di1.CI_Original_Contract_Id__c=mch1.Name;
            di1.Invoice_Review_Case_Audit__c=ircaCurrent.Id;
            insert di1;

            di1 = refreshDraftInvoice(di1);
            System.assertEquals(di1.Type__c, 'System');
            System.assertEquals(di1.Name, '1304123789');
            System.assertEquals(di1.Original_Contract_Id__c, mch1.Id);
            System.assertEquals(di1.Invoice_Date__c, reviewDate);
            System.assertEquals(di1.Original_Amount__c, 500);
            System.assertEquals(di1.OwnerId, sysAdmin.Id);
            System.assertEquals(di1.Invoice_Review_Case_Audit__c, ircaCurrent.Id);

            di1.hasAttachment__c=true;
            update di1;

            //Test.startTest();
                ircaCurrent.Import_End_Date__c=Datetime.now();
                ircaCurrent.Import_Status__c='Success';
                ircaCurrent.Trigger_Case_Creation__c = true;
                update ircaCurrent;
            //Test.stopTest();
            Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));
            String query = 'SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,Effective_Start_Date__c,';
               query += 'Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,Review_Date__c,';
               query += 'Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Active__c=true AND Contract_Type__c != \'ISP\''; // Order by End_Date__c DESC limit 1 //2965556
               query +=  ' AND Locked__c=true AND Effective_End_Date__c >= '+ IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + 'AND (Cancellation_Date__c=null OR Cancellation_Date__c >= ' + IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + ')';
               query +=  ' Limit ' + batchSize;

            System.debug('Query=' + query);

            Test.startTest();
            IRCaseCreationBatchable execIRCaseCreation = new IRCaseCreationBatchable(ircaCurrent, ircaLast);
            execIRCaseCreation.query=query;
            //Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));
            ID batchprocessid=Database.executeBatch(execIRCaseCreation,batchSize);
            //System.debug(Database.executeBatch(execIRCaseCreation,batchSize));
            System.debug('batchprocessid=' + batchprocessid);
            System.debug('--->');
            Test.stopTest();

            ircaCurrent = refreshIRCA(ircaCurrent);
            System.assert(ircaCurrent.Case_Creation_Completed__c);
            System.assert(ircaCurrent.Case_Creation_End_Date__c!=null);
            System.assertEquals('Success', ircaCurrent.Case_Creation_Status__c);


            for (Case cs : [Select Id, Multiple_Manual_Lists__c  from Case where IR_Original_Contract_Id__c = :mch2.Id])
            {
                System.assertNotEquals(true, cs.Multiple_Manual_Lists__c);
            }
        }
    }

    //CR 2723520
    static testMethod void IRCaseCreation_ThresholdNegTest()
    {
        System.runAs(sysAdmin)
        {
            Account acc1 = SobjectRepository.getAccount();
            Opportunity opp1 = SobjectRepository.getOpportunity();
            Merge_Contract_Header__c mch1Id = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
            Merge_Contract_Header__c mch1 = refreshContractHeader(mch1Id);

            Invoice_Review_Case_Audit__c ircaLast = createIRCARec(reviewDate,'IRCaseTest1277');
            ircaLast.Import_Start_Date__c = Datetime.now().addDays(-1);
            ircaLast.Import_Status__c = 'Success';
            ircaLast.Case_Creation_Completed__c=true;
            ircaLast.Import_End_Date__c = Datetime.now().addDays(-1);
            insert ircaLast;
            System.debug('Last import irca '+ircaLast.id);

            Invoice_Review_Case_Audit__c ircaCurrent=createIRCARec(reviewDate,'IRCaseTest1278');
            insert ircaCurrent;
            System.debug('inserted current irca'+ircaCurrent.id);

            Draft_Invoice__c di1=createDraftInvoice(acc1.Id, mch1.Name, '1304123759', reviewDate, 400);
            di1.CI_Original_Contract_Id__c=mch1.Name;
            di1.Invoice_Review_Case_Audit__c=ircaLast.Id;

            System.debug('di1.Original_Contract_Id__c '+di1.Original_Contract_Id__c);

            Draft_Invoice__c di2 = createDraftInvoice(acc1.Id, mch1.Name, '1304123759', reviewDate, 445);
            di2.CI_Original_Contract_Id__c=mch1.Name;
            di2.Invoice_Review_Case_Audit__c=ircaCurrent.Id;
            insert di2;

            System.debug('di2.Original_Contract_Id__c '+di2.Original_Contract_Id__c);
            System.debug('di2.CI_Original_Contract_Id__c '+di2.CI_Original_Contract_Id__c);

            insert di1;


            di1 = refreshDraftInvoice(di1);
            di2 = refreshDraftInvoice(di2);

            System.assertEquals(di1.Type__c, 'System');
            System.assertEquals(di1.Name, '1304123759');
            System.assertEquals(di1.Original_Contract_Id__c, mch1.Id);
            System.assertEquals(di1.Invoice_Date__c, reviewDate);
            System.assertEquals(di1.Original_Amount__c, 400);
            System.assertEquals(di1.OwnerId, sysAdmin.Id);
            System.assertEquals(di1.Invoice_Review_Case_Audit__c, ircaLast.Id);

            di1.hasAttachment__c=true;
            di2.hasAttachment__c=true;

            update di1;
            update di2;

            //Test.startTest();
                ircaCurrent.Import_End_Date__c=Datetime.now();
                ircaCurrent.Import_Status__c='Success';
                ircaCurrent.Trigger_Case_Creation__c = true;
                update ircaCurrent;
            //Test.stopTest();

            Test.startTest();
            List<Merge_Contract_Header__c> mchList1 = new List<Merge_Contract_Header__c>();
            for (Merge_Contract_Header__c mch : [SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,
            Effective_Start_Date__c,Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,
            Review_Date__c,Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Active__c=true AND Contract_Type__c != 'ISP' //2965556
            AND Locked__c=true AND Effective_End_Date__c >= :reviewDate.addMonths(-1) AND (Cancellation_Date__c=null OR Cancellation_Date__c >= :reviewDate.addMonths(-1)) //LIMIT 100])
            AND (Id=:mch1.Id )])
            {
                mchList1.add(mch);
            }
            System.debug('mchList1 size=' + mchList1.size());
            System.debug('mchList1=' + mchList1);

            CaseTriggerClass.isIRCaseCreationInprogress=true;
            creationData(mchList1,ircaCurrent,ircaLast); //2965556


            // check IR Case creation criteria for Threshold violation

            //IRCaseCreationCriteria.checkForThresholdViolationBulk(irCaseData, reviewDate);

            Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));
            String query = 'SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,Effective_Start_Date__c,';
               query += 'Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,Review_Date__c,';
               query += 'Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Id  =\''+mch1.Id+'\''; //2965556
               query += ' AND Active__c=true AND Contract_Type__c != \'ISP\''; // Order by End_Date__c DESC limit 1
               query +=  ' AND Locked__c=true AND Effective_End_Date__c >= '+ IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + 'AND (Cancellation_Date__c=null OR Cancellation_Date__c >= ' + IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + ')';
               query +=  ' Limit ' + batchSize;

            System.debug('Query=' + query);

             //Test.startTest();
            IRCaseCreationBatchable execIRCaseCreation = new IRCaseCreationBatchable(ircaCurrent, ircaLast);
            execIRCaseCreation.query=query;
            //Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));
            ID batchprocessid=Database.executeBatch(execIRCaseCreation,batchSize);
            //System.debug(Database.executeBatch(execIRCaseCreation,batchSize));
            System.debug('batchprocessid=' + batchprocessid);
            System.debug('--->');
            Test.stopTest();

            ircaCurrent = refreshIRCA(ircaCurrent);

            System.debug('ircaCurrent.Case_Creation_Completed__c: '+ircaCurrent.Case_Creation_Completed__c);
            System.debug('ircaCurrent.Case_Creation_End_Date__c: '+ircaCurrent.Case_Creation_End_Date__c);
            System.debug('ircaCurrent.Case_Creation_Status__c: '+ircaCurrent.Case_Creation_Status__c);
            System.assert(ircaCurrent.Case_Creation_Completed__c);
            System.assert(ircaCurrent.Case_Creation_End_Date__c!=null);
            System.assertEquals('Success', ircaCurrent.Case_Creation_Status__c);


            for (Case cs : [Select Id, IRCache_hasThresholdViolation__c,IRCache_hasDraftThresholdViolation__c,Description  from Case where IR_Original_Contract_Id__c = :mch1.Id]) //2867070
            {
                System.assertNotEquals(true, cs.IRCache_hasDraftThresholdViolation__c); //2867070
                System.debug('Description: '+cs.Description);
            }

        }
    }

    static testMethod void IRCaseCreation_ThresholdPosFinalOnly()
    {
        System.runAs(sysAdmin)
        {
            Account acc1 = SobjectRepository.getAccount();
            Opportunity opp1 = SobjectRepository.getOpportunity();
            Merge_Contract_Header__c mch1Id = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
            Merge_Contract_Header__c mch1 = refreshContractHeader(mch1Id);

            Merge_Contract_Header__c mch2 = createContractHeader('IRCaseMCH2', acc1.Id, opp1.Id);
            mch2.Manual_List__c = false;
            mch2.Acceptance_Date__c = reviewDate.addMonths(-1).addDays(10);
            mch2.Contract_Type__c = 'Indirect Customer';
            insert mch2;

            Invoice_Review_Case_Audit__c ircaLast=createIRCARec(reviewDate,'IRCaseTest1277');
            ircaLast.Import_Start_Date__c = Datetime.now().addDays(-1);
            ircaLast.Import_Status__c = 'Success';
            ircaLast.Case_Creation_Completed__c=true;
            ircaLast.Import_End_Date__c = Datetime.now().addDays(-1);
            insert ircaLast;
            System.debug('Last import irca '+ircaLast.id);

            Invoice_Review_Case_Audit__c ircaCurrent=createIRCARec(reviewDate,'IRCaseTest1278');
            insert ircaCurrent;
            System.debug('inserted current irca'+ircaCurrent.id);


            Draft_Invoice__c di2=createDraftInvoice(acc1.Id, mch2.Name, '1304123770', reviewDate, 100);
            di2.CI_Original_Contract_Id__c=mch2.Name;
            di2.Invoice_Review_Case_Audit__c=ircaCurrent.Id;
            di2.billable_flag__c = 'N';
            di2.Previous_Month_Outstanding_Amount__c = 25200;
            insert di2;

            System.debug('di2.Original_Contract_Id__c '+di2.Original_Contract_Id__c);

            //insert di1;


            di2 = refreshDraftInvoice(di2);
            di2.hasAttachment__c=true;

            update di2;

            //Test.startTest();
                ircaCurrent.Import_End_Date__c=Datetime.now();
                ircaCurrent.Import_Status__c='Success';
                ircaCurrent.Trigger_Case_Creation__c = true;
                update ircaCurrent;
            //Test.stopTest();

            Test.startTest();
            List<Merge_Contract_Header__c> mchList1 = new List<Merge_Contract_Header__c>();
            for (Merge_Contract_Header__c mch : [SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,
            Effective_Start_Date__c,Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,
            Review_Date__c,Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Active__c=true AND Contract_Type__c != 'ISP' //2965556
            AND Locked__c=true AND Effective_End_Date__c >= :reviewDate.addMonths(-1) AND (Cancellation_Date__c=null OR Cancellation_Date__c >= :reviewDate.addMonths(-1)) //LIMIT 100])
            AND (Id=:mch1.Id OR Id=:mch2.Id)])
            {
                mchList1.add(mch);
            }
            System.debug('mchList1 size=' + mchList1.size());
            System.debug('mchList1=' + mchList1);

            CaseTriggerClass.isIRCaseCreationInprogress=true;
            creationData(mchList1,ircaCurrent,ircaLast); //2965556


            // check IR Case creation criteria for Threshold violation

            //IRCaseCreationCriteria.checkForThresholdViolationBulk(irCaseData, reviewDate);

            Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));
            String query = 'SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,Effective_Start_Date__c,Currency__c,';
               query += 'Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,Review_Date__c,';
               query += 'Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Id  =\''+mch2.Id+'\''; //2965556
               query += ' AND Active__c=true AND Contract_Type__c != \'ISP\''; // Order by End_Date__c DESC limit 1
               query +=  ' AND Locked__c=true AND Effective_End_Date__c >= '+ IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + 'AND (Cancellation_Date__c=null OR Cancellation_Date__c >= ' + IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + ')';
               query +=  ' Limit ' + batchSize;

            System.debug('Query=' + query);

             //Test.startTest();
            IRCaseCreationBatchable execIRCaseCreation = new IRCaseCreationBatchable(ircaCurrent, ircaLast);
            execIRCaseCreation.query=query;
            //Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));
            ID batchprocessid=Database.executeBatch(execIRCaseCreation,batchSize);
            //System.debug(Database.executeBatch(execIRCaseCreation,batchSize));
            System.debug('batchprocessid=' + batchprocessid);
            System.debug('--->');
            Test.stopTest();

            ircaCurrent = refreshIRCA(ircaCurrent);

            System.debug('ircaCurrent.Case_Creation_Completed__c: '+ircaCurrent.Case_Creation_Completed__c);
            System.debug('ircaCurrent.Case_Creation_End_Date__c: '+ircaCurrent.Case_Creation_End_Date__c);
            System.debug('ircaCurrent.Case_Creation_Status__c: '+ircaCurrent.Case_Creation_Status__c);
            System.assert(ircaCurrent.Case_Creation_Completed__c);
            System.assert(ircaCurrent.Case_Creation_End_Date__c!=null);
            System.assertEquals('Success', ircaCurrent.Case_Creation_Status__c);


            for (Case cs : [Select Id, IRCache_hasThresholdViolation__c,Description  from Case where IR_Original_Contract_Id__c = :mch2.Id])
            {
              System.assertEquals(true, cs.IRCache_hasThresholdViolation__c);
                System.debug('Description: '+cs.Description);
            }

        }
    }

    //CR 2723520
    static testMethod void IRCaseCreation_ThresholdPosDrftOnly()
    {
        System.runAs(sysAdmin)
        {
            Account acc1 = SobjectRepository.getAccount();
            Opportunity opp1 = SobjectRepository.getOpportunity();
            Merge_Contract_Header__c mch1Id = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
            Merge_Contract_Header__c mch1 = refreshContractHeader(mch1Id);

            Merge_Contract_Header__c mch2 = createContractHeader('IRCaseMCH2', acc1.Id, opp1.Id);
            mch2.Manual_List__c = false;
            mch2.Acceptance_Date__c = reviewDate.addMonths(-1).addDays(10);
            insert mch2;

            Invoice_Review_Case_Audit__c ircaLast=createIRCARec(reviewDate,'IRCaseTest1277');
            ircaLast.Import_Start_Date__c = Datetime.now().addDays(-1);
            ircaLast.Import_Status__c = 'Success';
            ircaLast.Case_Creation_Completed__c=true;
            ircaLast.Import_End_Date__c = Datetime.now().addDays(-1);
            insert ircaLast;
            System.debug('Last import irca '+ircaLast.id);

            Invoice_Review_Case_Audit__c ircaCurrent=createIRCARec(reviewDate,'IRCaseTest1278');
            insert ircaCurrent;
            System.debug('inserted current irca'+ircaCurrent.id);

            Draft_Invoice__c di1=createDraftInvoice(acc1.Id, mch1.Name, '1304123779', reviewDate, 400);
            di1.CI_Original_Contract_Id__c=mch1.Name;
            di1.Invoice_Review_Case_Audit__c=ircaLast.Id;

            System.debug('di1.Original_Contract_Id__c '+di1.Original_Contract_Id__c);

            Draft_Invoice__c di2=createDraftInvoice(acc1.Id, mch1.Name, '1304123779', reviewDate, 900);
            di2.CI_Original_Contract_Id__c=mch1.Name;
            di2.Invoice_Review_Case_Audit__c=ircaCurrent.Id;
            insert di2;

            System.debug('di2.Original_Contract_Id__c '+di2.Original_Contract_Id__c);
            System.debug('di2.CI_Original_Contract_Id__c '+di2.CI_Original_Contract_Id__c);

            insert di1;


            di1 = refreshDraftInvoice(di1);
            di2 = refreshDraftInvoice(di2);

            System.assertEquals(di1.Type__c, 'System');
            System.assertEquals(di1.Name, '1304123779');
            System.assertEquals(di1.Original_Contract_Id__c, mch1.Id);
            System.assertEquals(di1.Invoice_Date__c, reviewDate);
            System.assertEquals(di1.Original_Amount__c, 400);
            System.assertEquals(di1.OwnerId, sysAdmin.Id);
            System.assertEquals(di1.Invoice_Review_Case_Audit__c, ircaLast.Id);

            di1.hasAttachment__c=true;
            di2.hasAttachment__c=true;

            update di1;
            update di2;

            //Test.startTest();
                ircaCurrent.Import_End_Date__c=Datetime.now();
                ircaCurrent.Import_Status__c='Success';
                ircaCurrent.Trigger_Case_Creation__c = true;
                update ircaCurrent;
            //Test.stopTest();

            Test.startTest();
            List<Merge_Contract_Header__c> mchList1 = new List<Merge_Contract_Header__c>();
            for (Merge_Contract_Header__c mch : [SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,
            Effective_Start_Date__c,Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,
            Review_Date__c,Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Active__c=true AND Contract_Type__c != 'ISP' //2965556
            AND Locked__c=true AND Effective_End_Date__c >= :reviewDate.addMonths(-1) AND (Cancellation_Date__c=null OR Cancellation_Date__c >= :reviewDate.addMonths(-1)) //LIMIT 100])
            AND (Id=:mch1.Id OR Id=:mch2.Id)])
            {
                mchList1.add(mch);
            }
            System.debug('mchList1 size=' + mchList1.size());
            System.debug('mchList1=' + mchList1);

            CaseTriggerClass.isIRCaseCreationInprogress=true;
            creationData(mchList1,ircaCurrent,ircaLast); //2965556

            Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));
            String query = 'SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,Effective_Start_Date__c,';
               query += 'Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,Review_Date__c,';
               query += 'Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Id  =\''+mch1.Id+'\''; //2965556
               query += ' AND Active__c=true AND Contract_Type__c != \'ISP\''; // Order by End_Date__c DESC limit 1
               query +=  ' AND Locked__c=true AND Effective_End_Date__c >= '+ IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + 'AND (Cancellation_Date__c=null OR Cancellation_Date__c >= ' + IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + ')';
               query +=  ' Limit ' + batchSize;

            System.debug('Query=' + query);

             //Test.startTest();
            IRCaseCreationBatchable execIRCaseCreation = new IRCaseCreationBatchable(ircaCurrent, ircaLast);
            execIRCaseCreation.query=query;
            //Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));
            ID batchprocessid=Database.executeBatch(execIRCaseCreation,batchSize);
            //System.debug(Database.executeBatch(execIRCaseCreation,batchSize));
            System.debug('batchprocessid=' + batchprocessid);
            System.debug('--->');
            Test.stopTest();

            ircaCurrent = refreshIRCA(ircaCurrent);

            System.debug('ircaCurrent.Case_Creation_Completed__c: '+ircaCurrent.Case_Creation_Completed__c);
            System.debug('ircaCurrent.Case_Creation_End_Date__c: '+ircaCurrent.Case_Creation_End_Date__c);
            System.debug('ircaCurrent.Case_Creation_Status__c: '+ircaCurrent.Case_Creation_Status__c);
            System.assert(ircaCurrent.Case_Creation_Completed__c);
            System.assert(ircaCurrent.Case_Creation_End_Date__c!=null);
            System.assertEquals('Success', ircaCurrent.Case_Creation_Status__c);


            for (Case cs : [Select Id, IRCache_hasThresholdViolation__c,IRCache_hasDraftThresholdViolation__c,Description  from Case where IR_Original_Contract_Id__c = :mch1.Id]) //2867070
            {
                System.assertEquals(true, cs.IRCache_hasDraftThresholdViolation__c); //2867070
                System.debug('Description: '+cs.Description);
            }

        }
    }

    //CR 2723520
    static testMethod void IRCaseCreation_ThresholdPosBulk()
    {
        System.runAs(sysAdmin)
        {
            Account acc1 = SobjectRepository.getAccount();
            Opportunity opp1 = SobjectRepository.getOpportunity();
            Merge_Contract_Header__c mch1Id = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
            Merge_Contract_Header__c mch1 = refreshContractHeader(mch1Id);

            Merge_Contract_Header__c mch2 = createContractHeader('IRCaseMCH2', acc1.Id, opp1.Id);
            mch2.Manual_List__c = false;
            mch2.Acceptance_Date__c = reviewDate.addMonths(-1).addDays(10);
            insert mch2;

            Merge_Contract_Manual_List__c mcManList2 = createContractManualList('IRCaseMlist2', mch2.Name);
            mcManList2.Review_Frequency__c = 'Monthly';
            mcManList2.End_Date__c = Date.today().addMonths(2);
            mcManList2.Owner__c = 'UNKNOWN';
            mcManList2.Review_Date__c = reviewDate;
            mcManList2.Priority__c = '1';
            insert mcManList2;

            Invoice_Review_Case_Audit__c ircaLast=createIRCARec(reviewDate,'IRCaseTest1277');
            ircaLast.Import_Start_Date__c = Datetime.now().addDays(-1);
            ircaLast.Import_Status__c = 'Success';
            ircaLast.Case_Creation_Completed__c=true;
            ircaLast.Import_End_Date__c = Datetime.now().addDays(-1);
            insert ircaLast;
            System.debug('Last import irca '+ircaLast.id);

            Invoice_Review_Case_Audit__c ircaCurrent=createIRCARec(reviewDate,'IRCaseTest1278');
            insert ircaCurrent;
            System.debug('inserted current irca'+ircaCurrent.id);

            Draft_Invoice__c di1=createDraftInvoice(acc1.Id, mch1.Name, '1304123789', reviewDate, 500);
            di1.CI_Original_Contract_Id__c=mch1.Name;
            di1.Invoice_Review_Case_Audit__c=ircaLast.Id;

            Draft_Invoice__c di2=createDraftInvoice(acc1.Id, mch1.Name, '1304123789', reviewDate, 900);
            di2.CI_Original_Contract_Id__c=mch1.Name;
            di2.Invoice_Review_Case_Audit__c=ircaCurrent.Id;
            insert di2;

            System.debug('di2.Original_Contract_Id__c '+di2.Original_Contract_Id__c);

            insert di1;

            di1 = refreshDraftInvoice(di1);
            di2 = refreshDraftInvoice(di2);

            System.debug('di1.Original_Contract_Id__c '+di1.Original_Contract_Id__c);

            System.assertEquals(di1.Type__c, 'System');
            System.assertEquals(di1.Name, '1304123789');
            System.assertEquals(di1.Original_Contract_Id__c, mch1.Id);
            System.assertEquals(di1.Invoice_Date__c, reviewDate);
            System.assertEquals(di1.Original_Amount__c, 500);
            System.assertEquals(di1.OwnerId, sysAdmin.Id);
            System.assertEquals(di1.Invoice_Review_Case_Audit__c, ircaLast.Id);

            di1.hasAttachment__c=true;
            di2.hasAttachment__c=true;

            update di1;
            update di2;

            //Test.startTest();
                ircaCurrent.Import_End_Date__c=Datetime.now();
                ircaCurrent.Import_Status__c='Success';
                ircaCurrent.Trigger_Case_Creation__c = true;
                update ircaCurrent;
            //Test.stopTest();

            Test.startTest();
            List<Merge_Contract_Header__c> mchList1 = new List<Merge_Contract_Header__c>();
            for (Merge_Contract_Header__c mch : [SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,
            Effective_Start_Date__c,Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,
            Review_Date__c,Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Active__c=true AND Contract_Type__c != 'ISP' //2965556
            AND Locked__c=true AND Effective_End_Date__c >= :reviewDate.addMonths(-1) AND (Cancellation_Date__c=null OR Cancellation_Date__c >= :reviewDate.addMonths(-1)) //LIMIT 100])
            AND (Id=:mch1.Id OR Id=:mch2.Id)])
            {
                mchList1.add(mch);
            }
            System.debug('mchList1 size=' + mchList1.size());
            System.debug('mchList1=' + mchList1);

            CaseTriggerClass.isIRCaseCreationInprogress=true;
            creationData(mchList1,ircaCurrent,ircaLast); //2965556

            Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));
            String query = 'SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,Effective_Start_Date__c,';
               query += 'Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,Review_Date__c,';
               query += 'Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Id  =\''+mch1.Id+'\''; //2965556
               query += ' AND Active__c=true AND Contract_Type__c != \'ISP\''; // Order by End_Date__c DESC limit 1
               query +=  ' AND Locked__c=true AND Effective_End_Date__c >= '+ IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + 'AND (Cancellation_Date__c=null OR Cancellation_Date__c >= ' + IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + ')';
               query +=  ' Limit ' + batchSize;

            System.debug('Query=' + query);

             //Test.startTest();
            IRCaseCreationBatchable execIRCaseCreation = new IRCaseCreationBatchable(ircaCurrent, ircaLast);
            execIRCaseCreation.query=query;
            //Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));
            ID batchprocessid=Database.executeBatch(execIRCaseCreation,batchSize);
            //System.debug(Database.executeBatch(execIRCaseCreation,batchSize));
            System.debug('batchprocessid=' + batchprocessid);
            System.debug('--->');
            Test.stopTest();

            ircaCurrent = refreshIRCA(ircaCurrent);

            System.debug('ircaCurrent.Case_Creation_Completed__c: '+ircaCurrent.Case_Creation_Completed__c);
            System.debug('ircaCurrent.Case_Creation_End_Date__c: '+ircaCurrent.Case_Creation_End_Date__c);
            System.debug('ircaCurrent.Case_Creation_Status__c: '+ircaCurrent.Case_Creation_Status__c);
            System.assert(ircaCurrent.Case_Creation_Completed__c);
            System.assert(ircaCurrent.Case_Creation_End_Date__c!=null);
            System.assertEquals('Success', ircaCurrent.Case_Creation_Status__c);

            for (Case cs : [Select Id,caseNumber,IRCache_hasDraftThresholdViolation__c,IRCache_isManual__c,Description  from Case where IR_Original_Contract_Id__c = :mch1.Id])
            {
                System.debug('caseNumber: '+cs.caseNumber);
                System.debug('IRCache_hasDraftThresholdViolation__c: '+cs.IRCache_hasDraftThresholdViolation__c);
                System.debug('IRCache_isManual__c: '+cs.IRCache_isManual__c);
                System.debug('Description: '+cs.Description);

                System.assertEquals(true, cs.IRCache_hasDraftThresholdViolation__c);
                System.assertEquals(true,cs.IRCache_isManual__c);
            }

        }
    }

    //2965556
      static testMethod void IRCaseReject_Multiple_Pos()
    {
        /**This method creates the  following scenarios
         * 1. There is a threshold violation on the draft invoice.
         * 2. Contract is marked for Double Invoice Review
         * 3. Contract has a Manual List tied to it.
         * 4. Contract has Paper Change.
         *
         * There is an existing case on the Draft Invoice but since it is in Rejected Status,
         * flags for all 4 scenarios mentioned above won't be updated to the case.
         * CR : 2965556
         */
        System.runAs(sysAdmin)
        {

            Account acc1 = SobjectRepository.getAccount();
            Opportunity opp1 = SobjectRepository.getOpportunity();
            Merge_Contract_Header__c mch1Id = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
            Merge_Contract_Header__c mch1 = refreshContractHeader(mch1Id);

            Invoice_Review_Case_Audit__c ircaLast=createIRCARec(reviewDate,'IRCaseTest1277');
            ircaLast.Import_Start_Date__c = Datetime.now().addDays(-1);
            ircaLast.Import_Status__c = 'Success';
            ircaLast.Case_Creation_Completed__c=true;
            ircaLast.Import_End_Date__c = Datetime.now().addDays(-1);
            insert ircaLast;
            System.debug('Last import irca '+ircaLast.id);

            Invoice_Review_Case_Audit__c ircaCurrent=createIRCARec(reviewDate,'IRCaseTest1278');
            insert ircaCurrent;
            System.debug('inserted current irca'+ircaCurrent.id);

            mch1.Double_Invoice_Review__c = true;
            mch1.acceptance_date__c = Date.today().addMonths(-1).addDays(2);
            mch1.Opportunity_Name__c=opp1.id;
            update mch1;

            Draft_Invoice__c di1=createDraftInvoice(acc1.Id, mch1.Name, '1503123987', reviewDate, 50000);
            di1.CI_Original_Contract_Id__c=mch1.Name;
            di1.Invoice_Review_Case_Audit__c=ircaLast.Id;
            di1.Conversion_Rate_to_USD__c = 1;
            di1.Previous_Month_Outstanding_Amount__c = 500;
            di1.billable_flag__c = 'Y';
            insert di1;

            Draft_Invoice__c di2=createDraftInvoice(acc1.Id, mch1.Name, '1503123987', reviewDate, 90000);
            di2.CI_Original_Contract_Id__c=mch1.Name;
            di2.Invoice_Review_Case_Audit__c=ircaCurrent.Id;
            di2.Conversion_Rate_to_USD__c = 1;
            di2.billable_flag__c = 'Y';
            insert di2;

            System.debug('di2.Original_Contract_Id__c '+di2.Original_Contract_Id__c);

            //insert di1;

            di1 = refreshDraftInvoice(di1);
            di2 = refreshDraftInvoice(di2);

            User newOwnerRSM = GetUser('TST_NRSM');
            Case existinginvCase = createInvoiceCase (di1.Name, reviewDate, acc1.Id, opp1.Id , mch1.Id, newOwnerRSM.Id);
            existinginvCase.IR_Escal_Status__c = 'Pending Review';
            existinginvCase.status = 'Pending Review';
            existinginvCase.Description = 'Test Case Reject Threshold Positive';
            existinginvCase.IR_CurrentInvoiceAmount__c = 500;
            existingInvCase.Approved_On__c = Datetime.now().addHours(2);

            insert existinginvCase;

            existinginvCase = getCase(existinginvCase.Id);

            System.debug('existinginvCase Inserted Id : '+existinginvCase.Id);
            System.debug('existinginvCase Inserted CASENUMBER : '+existinginvCase.CaseNumber);
            System.debug('existinginvCase Inserted Status : '+existinginvCase.Status);
            System.debug('existinginvCase Inserted IR_Escal_Status__c : '+existinginvCase.IR_Escal_Status__c);


            di1.hasAttachment__c=true;
            di2.hasAttachment__c=true;

            update di1;
            update di2;

            //Test.startTest();
                ircaCurrent.Import_End_Date__c=Datetime.now();
                ircaCurrent.Import_Status__c='Success';
                ircaCurrent.Trigger_Case_Creation__c = true;
                update ircaCurrent;
            //Test.stopTest();

            Test.startTest();
            List<Merge_Contract_Header__c> mchList1 = new List<Merge_Contract_Header__c>();
            for (Merge_Contract_Header__c mch : [SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,
            Effective_Start_Date__c,Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,
            Review_Date__c,Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Active__c=true AND Contract_Type__c != 'ISP'
            AND Locked__c=true AND Effective_End_Date__c >= :reviewDate.addMonths(-1) AND (Cancellation_Date__c=null OR Cancellation_Date__c >= :reviewDate.addMonths(-1)) //LIMIT 100])
            AND (Id=:mch1.Id)])
            {
                mchList1.add(mch);
            }
            System.debug('mchList1 size=' + mchList1.size());
            System.debug('mchList1=' + mchList1);

            CaseTriggerClass.isIRCaseCreationInprogress=true;

            creationData(mchList1,ircaCurrent,ircaLast);

            IRCaseCreationCriteria.checkForThresholdViolationBulk(irCaseData, ircaCurrent.Invoice_Review_Date__c);
            IRCaseCreationCriteria.checkForDoubleInvoiceReviewBulk(false,mchIdList,irCaseData,ircaCurrent.Invoice_Review_Date__c, contractIDCaseWrapperMap,accOwnerIdMap,mchIdAccIdMap,accIRCaseEscalOwnerATMMap);
            IRCaseCreationCriteria.checkForManualContractBulk(irCaseData, ircaCurrent.Invoice_Review_Date__c);
            //CR 3272721
            //IRCaseCreationCriteria.checkForContractChangeBulk(irCaseData, ircaCurrent.Invoice_Review_Date__c);

            for (IRCaseWrapper ircw : contractIDCaseWrapperMap.values())

            {
                //Case tempCase = ircw.associatedCase;
                System.debug('hasDraftThresholdViolation : '+ircw.hasDraftThresholdViolation);
                System.debug('hasFinalThresholdViolation : '+ircw.hasFinalThresholdViolation);
                System.debug('hasDoubleInvoiceReview : '+ircw.hasDoubleInvoiceReview);
                System.debug('isManualInvoice : '+ircw.isManualInvoice);
                System.debug('contractIDCaseWrapperMap.get(mch1.Id).acceptanceDate: '+contractIDCaseWrapperMap.get(mch1.Id).acceptanceDate);

                System.assertEquals('Pending Review', ircw.associatedCase.Status);
                System.assertEquals('Pending Review', ircw.associatedCase.IR_Escal_Status__c);
                System.assertEquals(true, ircw.hasDraftThresholdViolation);
                System.assertEquals(true, ircw.hasFinalThresholdViolation);
                System.assertEquals(true, ircw.hasDoubleInvoiceReview);
                System.assertEquals(true, ircw.isManualInvoice);
                // CR 3272721
                //System.assertEquals(true, ircw.hasPaperChange);
                //System.assertEquals(mch1.Acceptance_Date__c,contractIDCaseWrapperMap.get(mch1.Id).acceptanceDate);
            }

            existinginvCase.IR_Escal_Status__c = 'Rejected';
            existinginvCase.status = 'Rejected';
            existinginvCase.IR_Escal_Reject_Comments__c = 'Rejected';
            existinginvCase.IR_Escal_Reject_Reason__c = 'Other';
            existinginvCase.IR_Reject_Comments__c = 'Rejected';
            existinginvCase.IR_Reject_Reason__c = 'Other';

            update existinginvCase;

            Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));
            String query = 'SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,Effective_Start_Date__c,';
               query += 'Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,Review_Date__c,';
               query += 'Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Id  =\''+mch1.Id+'\'';
               query += ' AND Active__c=true AND Contract_Type__c != \'ISP\''; // Order by End_Date__c DESC limit 1
               query +=  ' AND Locked__c=true AND Effective_End_Date__c >= '+ IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + 'AND (Cancellation_Date__c=null OR Cancellation_Date__c >= ' + IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + ')';
               query +=  ' Limit ' + batchSize;

            System.debug('Query=' + query);

             //Test.startTest();
            IRCaseCreationBatchable execIRCaseCreation = new IRCaseCreationBatchable(ircaCurrent, ircaLast);
            execIRCaseCreation.query=query;
            //Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));
            ID batchprocessid=Database.executeBatch(execIRCaseCreation,batchSize);
            //System.debug(Database.executeBatch(execIRCaseCreation,batchSize));
            System.debug('batchprocessid=' + batchprocessid);
            System.debug('--->');
            Test.stopTest();

            ircaCurrent = refreshIRCA(ircaCurrent);

            System.debug('ircaCurrent.Case_Creation_Completed__c: '+ircaCurrent.Case_Creation_Completed__c);
            System.debug('ircaCurrent.Case_Creation_End_Date__c: '+ircaCurrent.Case_Creation_End_Date__c);
            System.debug('ircaCurrent.Case_Creation_Status__c: '+ircaCurrent.Case_Creation_Status__c);
            System.assert(ircaCurrent.Case_Creation_Completed__c);
            System.assert(ircaCurrent.Case_Creation_End_Date__c!=null);
            System.assertEquals('Success', ircaCurrent.Case_Creation_Status__c);

            for (Case cs : [Select Id,caseNumber,status,IR_Escal_Status__c,IRCache_hasDoubleInvoiceReview__c , IRCache_hasThresholdViolation__c,IRCache_hasDraftThresholdViolation__c,IRCache_isManual__c,IRCache_Acceptance_Date__c,Description  from Case where IR_Original_Contract_Id__c = :mch1.Id])
            {
                System.debug('caseNumber: '+cs.caseNumber);
                System.debug('IRCache_hasThresholdViolation__c: '+cs.IRCache_hasThresholdViolation__c);
                System.debug('IRCache_hasDraftThresholdViolation__c: '+cs.IRCache_hasDraftThresholdViolation__c);
                System.debug('IRCache_hasDoubleInvoiceReview__c : '+cs.IRCache_hasDoubleInvoiceReview__c );
                System.debug('IRCache_isManual__c : '+cs.IRCache_isManual__c );
                System.debug('status: '+cs.status);
                System.debug('IR_Escal_Status__c: '+cs.IR_Escal_Status__c);

                System.assertEquals('Rejected',cs.status);
                System.assertEquals('Rejected',cs.IR_Escal_Status__c);
                System.assertEquals(false, cs.IRCache_hasDraftThresholdViolation__c);
                System.assertEquals(false, cs.IRCache_hasThresholdViolation__c);
                System.assertEquals(false, cs.IRCache_hasDoubleInvoiceReview__c );
                System.assertEquals(false, cs.IRCache_isManual__c );
                System.assertnotEquals(mch1.Acceptance_Date__c,cs.IRCache_Acceptance_Date__c);

            }

        }
    }

    //2965556
    static testMethod void IRCaseReject_MissInv_Pos()
    {
        /**This method creates a scenario where Invoice for the contract was present
         * in the previous invoice review import but is missing in the current import.
         * There is an existing case on the Draft Invoice but since it is in Rejected Status,
         * the Missing Invoice violation won't be updated to the case.
         * CR : 2965556
         */
        System.runAs(sysAdmin)
        {
            Account acc1 = SobjectRepository.getAccount();
            Opportunity opp1 = SobjectRepository.getOpportunity();
            Merge_Contract_Header__c mch1Id = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
            Merge_Contract_Header__c mch1 = refreshContractHeader(mch1Id);

            Invoice_Review_Case_Audit__c ircaLast=createIRCARec(reviewDate,'IRCaseTest1277');
            ircaLast.Import_Start_Date__c = Datetime.now().addDays(-1);
            ircaLast.Import_Status__c = 'Success';
            ircaLast.Case_Creation_Completed__c=true;
            ircaLast.Import_End_Date__c = Datetime.now().addDays(-1);
            insert ircaLast;
            System.debug('Last import irca '+ircaLast.id);

            Invoice_Review_Case_Audit__c ircaCurrent=createIRCARec(reviewDate,'IRCaseTest1278');
            insert ircaCurrent;
            System.debug('inserted current irca'+ircaCurrent.id);

            Draft_Invoice__c di1=createDraftInvoice(acc1.Id, mch1.Name, '1503123987', reviewDate, 350);
            di1.CI_Original_Contract_Id__c=mch1.Name;
            di1.Invoice_Review_Case_Audit__c=ircaLast.Id;
            insert di1;

            di1 = refreshDraftInvoice(di1);

            System.debug('di1.Original_Contract_Id__c '+di1.Original_Contract_Id__c);

            User newOwnerRSM = GetUser('TST_NRSM');

            Case existinginvCase = createInvoiceCase (di1.Name, reviewDate, acc1.Id, opp1.Id , mch1.Id, newOwnerRSM.Id);
            //existinginvCase.IR_Escal_Status__c = 'Pending Review';
            existinginvCase.status = 'Pending Review';
            existinginvCase.Description = 'Test Case Reject MissingInv Positive';
            existinginvCase.IR_CurrentInvoiceAmount__c = 350;
            existinginvCase.Approved_On__c = Datetime.now().addHours(2);
            insert existinginvCase;

            existinginvCase = getCase(existinginvCase.Id);

            System.debug('existinginvCase Inserted Id : '+existinginvCase.Id);
            System.debug('existinginvCase Inserted CASENUMBER : '+existinginvCase.CaseNumber);
            System.debug('existinginvCase Inserted Status : '+existinginvCase.Status);
            System.debug('existinginvCase Inserted Approved_On__c : '+existinginvCase.Approved_On__c);
            //System.debug('existinginvCase Inserted IR_Escal_Status__c : '+existinginvCase.IR_Escal_Status__c);


            di1.hasAttachment__c=true;

            update di1;

            //Test.startTest();
                ircaCurrent.Import_End_Date__c=Datetime.now();
                ircaCurrent.Import_Status__c='Success';
                ircaCurrent.Trigger_Case_Creation__c = true;
                update ircaCurrent;
            //Test.stopTest();

            Test.startTest();
            List<Merge_Contract_Header__c> mchList1 = new List<Merge_Contract_Header__c>();
            for (Merge_Contract_Header__c mch : [SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,
            Effective_Start_Date__c,Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,
            Review_Date__c,Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Active__c=true AND Contract_Type__c != 'ISP'
            AND Locked__c=true AND Effective_End_Date__c >= :reviewDate.addMonths(-1) AND (Cancellation_Date__c=null OR Cancellation_Date__c >= :reviewDate.addMonths(-1)) //LIMIT 100])
            AND (Id=:mch1.Id)])
            {
                mchList1.add(mch);
            }
            System.debug('mchList1 size=' + mchList1.size());
            System.debug('mchList1=' + mchList1);

            CaseTriggerClass.isIRCaseCreationInprogress=true;

            creationData(mchList1,ircaCurrent,ircaLast);

            IRCaseCreationCriteria.checkForMissingInvoiceBulk(irCaseData, ircaCurrent.Invoice_Review_Date__c);

            for (IRCaseWrapper ircw : contractIDCaseWrapperMap.values())

            {
                System.debug('isMissingInDInv : '+ircw.isMissingInDInv);

                System.assertEquals('Pending Review', ircw.associatedCase.Status);
                System.assertEquals(true, ircw.isMissingInDInv);
            }

            existinginvCase.status = 'Rejected';
            existinginvCase.IR_Reject_Comments__c = 'Rejected';
            existinginvCase.IR_Reject_Reason__c = 'Other';

            update existinginvCase;

            Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));
            String query = 'SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,Effective_Start_Date__c,';
               query += 'Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,Review_Date__c,';
               query += 'Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Id  =\''+mch1.Id+'\'';
               query += ' AND Active__c=true AND Contract_Type__c != \'ISP\''; // Order by End_Date__c DESC limit 1
               query +=  ' AND Locked__c=true AND Effective_End_Date__c >= '+ IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + 'AND (Cancellation_Date__c=null OR Cancellation_Date__c >= ' + IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + ')';
               query +=  ' Limit ' + batchSize;

            System.debug('Query=' + query);

             //Test.startTest();
            IRCaseCreationBatchable execIRCaseCreation = new IRCaseCreationBatchable(ircaCurrent, ircaLast);
            execIRCaseCreation.query=query;
            //Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));
            ID batchprocessid=Database.executeBatch(execIRCaseCreation,batchSize);
            //System.debug(Database.executeBatch(execIRCaseCreation,batchSize));
            System.debug('batchprocessid=' + batchprocessid);
            Test.stopTest();

            ircaCurrent = refreshIRCA(ircaCurrent);

            System.debug('ircaCurrent.Case_Creation_Completed__c: '+ircaCurrent.Case_Creation_Completed__c);
            System.debug('ircaCurrent.Case_Creation_End_Date__c: '+ircaCurrent.Case_Creation_End_Date__c);
            System.debug('ircaCurrent.Case_Creation_Status__c: '+ircaCurrent.Case_Creation_Status__c);
            System.assert(ircaCurrent.Case_Creation_Completed__c);
            System.assert(ircaCurrent.Case_Creation_End_Date__c!=null);
            System.assertEquals('Success', ircaCurrent.Case_Creation_Status__c);

            for (Case cs : [Select Id,caseNumber,status,IRCache_isMissingDraftInvCheck__c,Description  from Case where IR_Original_Contract_Id__c = :mch1.Id])
            {
                System.debug('caseNumber: '+cs.caseNumber);
                System.debug('IRCache_isMissingDraftInvCheck__c: '+cs.IRCache_isMissingDraftInvCheck__c);
                System.debug('Case Status: '+cs.Status);

                System.assertEquals('Rejected', cs.Status);
                System.assertEquals(false, cs.IRCache_isMissingDraftInvCheck__c);
            }

        }
    }

    //2965556
    static testMethod void IRCaseReject_Bulk_Pos()
    {
        /**This method creates a scenario where Invoices for different contracts were present
         * in the previous invoice review import but are missing in the current import.
         * There is an existing case on each of the Draft Invoice but since they are in Rejected Status,
         * the Missing Invoice violation flag won't be updated to the cases.
         * CR : 2965556
         */
        System.runAs(sysAdmin)
        {
            Account acc1 = SobjectRepository.getAccount();
            Opportunity opp1 = SobjectRepository.getOpportunity();
            Merge_Contract_Header__c mch1Id = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
            Merge_Contract_Header__c mch1 = refreshContractHeader(mch1Id);

            Merge_Contract_Header__c mch2 = createContractHeader('IRCaseMCH2', acc1.Id, opp1.Id);
            mch2.Manual_List__c = false;
            mch2.Acceptance_Date__c = reviewDate.addMonths(-1).addDays(10);
            insert mch2;

            System.debug('mch2.Id: '+mch2.Id);


            Invoice__c prevMonthFinalInvoice2 = createInvoice(acc1.AKAM_Account_ID__c, mch2.Name, '1303123568', reviewDate.addMonths(-1), 700);
            insert prevMonthFinalInvoice2;

            Attachment attachments2 = createInvoiceAttachment (prevMonthFinalInvoice2.Id);
            Blob b = Blob.valueOf('Test Data2');
            attachments2.Body = b;
            attachments2.Name = 'Test Attachment for Parent2';
            insert attachments2;
            System.debug('Attachment2 Id : '+attachments2.Id);

            Invoice_Review_Case_Audit__c ircaLast=createIRCARec(reviewDate,'IRCaseTest1277');
            ircaLast.Import_Start_Date__c = Datetime.now().addDays(-1);
            ircaLast.Import_Status__c = 'Success';
            ircaLast.Case_Creation_Completed__c=true;
            ircaLast.Import_End_Date__c = Datetime.now().addDays(-1);
            insert ircaLast;
            System.debug('Last import irca '+ircaLast.id);

            Invoice_Review_Case_Audit__c ircaCurrent=createIRCARec(reviewDate,'IRCaseTest1278');
            insert ircaCurrent;
            System.debug('inserted current irca'+ircaCurrent.id);

            Draft_Invoice__c di1=createDraftInvoice(acc1.Id, mch1.Name, '1503123987', reviewDate, 500);
            di1.CI_Original_Contract_Id__c=mch1.Name;
            di1.Invoice_Review_Case_Audit__c=ircaLast.Id;
            insert di1;

            Draft_Invoice__c di2=createDraftInvoice(acc1.Id, mch2.Name, '1503123988', reviewDate, 900);
            di2.CI_Original_Contract_Id__c=mch2.Name;
            di2.Invoice_Review_Case_Audit__c=ircaLast.Id;
            insert di2;

            System.debug('di2.Original_Contract_Id__c '+di2.Original_Contract_Id__c);

            di1 = refreshDraftInvoice(di1);
            di2 = refreshDraftInvoice(di2);

            System.debug('di1.Original_Contract_Id__c '+di1.Original_Contract_Id__c);

            User newOwnerRSM = GetUser('TST_NRSM');

            Case case1 = createInvoiceCase (di1.Name, reviewDate, mch1.Account_Name__c, opp1.Id , mch1.Id, newOwnerRSM.Id);
            //case1.IR_Escal_Status__c = 'Pending Review';
            case1.status = 'Pending Review';
            case1.Description = 'Test Case Bulk Positive 1';
            case1.IR_CurrentInvoiceAmount__c = 500;


            Case case2 = createInvoiceCase (di2.Name, reviewDate, mch2.Account_Name__c, opp1.Id , mch2.Id, newOwnerRSM.Id);
            //case1.IR_Escal_Status__c = 'Pending Review';
            case1.status = 'Pending Review';
            case1.Description = 'Test Case Bulk Positive 2';
            case1.IR_CurrentInvoiceAmount__c = 900;

            insert case1;
            insert case2;

            case1 = getCase(case1.Id);
            case2 = getCase(case2.Id);

            System.debug('case1 Inserted Id : '+case1.Id);
            System.debug('case1 Inserted CASENUMBER : '+case1.CaseNumber);
            System.debug('case1 Inserted Status : '+case1.Status);

            System.debug('case2 Inserted Id : '+case2.Id);
            System.debug('case2 Inserted CASENUMBER : '+case2.CaseNumber);
            System.debug('case2 Inserted Status : '+case2.Status);


            di1.hasAttachment__c=true;
            di2.hasAttachment__c=true;

            update di1;
            update di2;

            //Test.startTest();
                ircaCurrent.Import_End_Date__c=Datetime.now();
                ircaCurrent.Import_Status__c='Success';
                ircaCurrent.Trigger_Case_Creation__c = true;
                update ircaCurrent;
            //Test.stopTest();

            Test.startTest();
            List<Merge_Contract_Header__c> mchList1 = new List<Merge_Contract_Header__c>();
            for (Merge_Contract_Header__c mch : [SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,
            Effective_Start_Date__c,Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,
            Review_Date__c,Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Active__c=true AND Contract_Type__c != 'ISP'
            AND Locked__c=true AND Effective_End_Date__c >= :reviewDate.addMonths(-1) AND (Cancellation_Date__c=null OR Cancellation_Date__c >= :reviewDate.addMonths(-1)) //LIMIT 100])
            AND (Id=:mch1.Id OR Id=:mch2.Id)])
            {
                mchList1.add(mch);
            }
            System.debug('mchList1 size=' + mchList1.size());
            System.debug('mchList1=' + mchList1);

            CaseTriggerClass.isIRCaseCreationInprogress=true;

            creationData(mchList1,ircaCurrent,ircaLast);

            IRCaseCreationCriteria.checkForMissingInvoiceBulk(irCaseData, ircaCurrent.Invoice_Review_Date__c);

            for (IRCaseWrapper ircw : contractIDCaseWrapperMap.values())

            {
                //Case tempCase = ircw.associatedCase;
                System.debug('isMissingInDInv : '+ircw.isMissingInDInv);
                System.debug('Status : '+ircw.associatedCase.status);

                System.assertEquals('Pending Review', ircw.associatedCase.Status);
                System.assertEquals(true, ircw.isMissingInDInv);

            }


            case1.status = 'Rejected';
            case1.IR_Reject_Comments__c = 'Rejected';
            case1.IR_Reject_Reason__c = 'Other';

            case2.status = 'Rejected';
            case2.IR_Reject_Comments__c = 'Rejected';
            case2.IR_Reject_Reason__c = 'Other';

            update case1;
            update case2;


            Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));
            String query = 'SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,Effective_Start_Date__c,';
               query += 'Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,Review_Date__c,';
               query += 'Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where (Id = \''+mch1.Id+'\''+' OR '+ 'Id = \''+mch2.Id+'\')';
               query += ' AND Active__c=true AND Contract_Type__c != \'ISP\''; // Order by End_Date__c DESC limit 1
               query +=  ' AND Locked__c=true AND Effective_End_Date__c >= '+ IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + 'AND (Cancellation_Date__c=null OR Cancellation_Date__c >= ' + IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + ')';
               query +=  ' Limit ' + batchSize;

            System.debug('Query=' + query);

             //Test.startTest();
            IRCaseCreationBatchable execIRCaseCreation = new IRCaseCreationBatchable(ircaCurrent, ircaLast);
            execIRCaseCreation.query=query;
            //Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));
            ID batchprocessid=Database.executeBatch(execIRCaseCreation,batchSize);
            //System.debug(Database.executeBatch(execIRCaseCreation,batchSize));
            System.debug('batchprocessid=' + batchprocessid);
            Test.stopTest();

            ircaCurrent = refreshIRCA(ircaCurrent);

            System.debug('ircaCurrent.Case_Creation_Completed__c: '+ircaCurrent.Case_Creation_Completed__c);
            System.debug('ircaCurrent.Case_Creation_End_Date__c: '+ircaCurrent.Case_Creation_End_Date__c);
            System.debug('ircaCurrent.Case_Creation_Status__c: '+ircaCurrent.Case_Creation_Status__c);
            System.assert(ircaCurrent.Case_Creation_Completed__c);
            System.assert(ircaCurrent.Case_Creation_End_Date__c!=null);
            System.assertEquals('Success', ircaCurrent.Case_Creation_Status__c);

            for (Case cs : [Select Id,caseNumber,status , IRCache_isMissingDraftInvCheck__c,Description  from Case where (IR_Original_Contract_Id__c = :mch1.Id OR IR_Original_Contract_Id__c =:mch2.Id)])
            {
                System.debug('caseNumber: '+cs.caseNumber);
                System.debug('IRCache_isMissingDraftInvCheck__c: '+cs.IRCache_isMissingDraftInvCheck__c);
                System.debug('status: '+cs.status);

                System.assertEquals(false, cs.IRCache_isMissingDraftInvCheck__c);

            }

        }
    }

     //CR 2986499
       static testMethod void IRCaseManualListUpsert_Pos()
    {
        System.runAs(sysAdmin)
        {
            Account acc1 = SobjectRepository.getAccount();
            Opportunity opp1 = SobjectRepository.getOpportunity();
            Merge_Contract_Header__c mch1Id = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
            Merge_Contract_Header__c mch1 = refreshContractHeader(mch1Id);
            //Setting manual list flag for Contract mch1 as false. After manual list trigger fire,
            //it should get re-checked.
            mch1.Manual_List__c = false;
            Update mch1;

            Merge_Contract_Manual_List__c mList1 = [select Id from Merge_Contract_Manual_List__c where Manual_List_Id__c = 'IRCaseMlist1' limit 1];
            mcManList = refreshContractMList(mList1);

            //Updating manual list for contract mch1
            mcManList.Owner__c = 'UPDATE1';
            mcManList.Priority__c = '1';

            Test.startTest();
            update mcManList;
            Test.stopTest();

            mcManList=refreshContractMList(mcManList);

            System.debug('Refreshed mcManList.Owner__c: '+mcManList.Owner__c);
            System.debug('Refreshed mcManList.Priority__c: '+mcManList.Priority__c);

            mch1=refreshContractHeader(mch1);

            System.debug('mch1.Id: '+mch1.Id);
            System.debug('mch1.Manual_List__c: '+mch1.Manual_List__c);

            //Asserting that the Manual_List__c flag on contract is re-checked after manual list update
            System.assertEquals(true, mch1.Manual_List__c);

        }
    }

    //CR 2986499
    static testMethod void IRCaseManualListUpsert_Neg()
    {
        System.runAs(sysAdmin)
        {
            Account acc1 = SobjectRepository.getAccount();
            Opportunity opp1 = SobjectRepository.getOpportunity();
            Merge_Contract_Header__c mch1Id = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
            Merge_Contract_Header__c mch1 = refreshContractHeader(mch1Id);

            Merge_Contract_Manual_List__c mList1 = [select Id from Merge_Contract_Manual_List__c where Manual_List_Id__c = 'IRCaseMlist1' limit 1];
            mcManList = refreshContractMList(mList1);
            //Since init() creates a manual list for contract: mch1,manual list flag gets  checked.
            //Setting manual list flag for Contract mch1 as false. After manual list trigger fire,
            //it should get re-checked if conditions are met.
            mch1.Manual_List__c = false;
            Update mch1;

            /**
             * Updating manual list for contract mch1
             * Since the end date is more than 20 days prior from today, acc. to the condition
             * in manual list trigger, contract will not be marked manual
            */
            mcManList.Owner__c = 'UPDATE1';
            mcManList.Priority__c = '1';
            mcManList.End_Date__c = Date.today().addDays(-21);

            Test.startTest();
            update mcManList;
            Test.stopTest();

            mcManList=refreshContractMList(mcManList);

            System.debug('Refreshed mcManList.Owner__c: '+mcManList.Owner__c);
            System.debug('Refreshed mcManList.Priority__c: '+mcManList.Priority__c);

            mch1=refreshContractHeader(mch1);

            System.debug('mch1.Id: '+mch1.Id);
            System.debug('mch1.Manual_List__c: '+mch1.Manual_List__c);

            //Asserting that Manual_List__c flag on the contract is unchecked
            System.assertEquals(false, mch1.Manual_List__c);
        }
    }

    //CR 2986499
    static testMethod void IRCaseManualListUpsert_Bulk()
    {
        System.runAs(sysAdmin)
        {
            Account acc1 = SobjectRepository.getAccount();
            Opportunity opp1 = SobjectRepository.getOpportunity();
            Merge_Contract_Header__c mch1Id = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
            Merge_Contract_Header__c mch1 = refreshContractHeader(mch1Id);

            String contName = 'IRCaseMCH';
            String mlName = 'IRCaseMlist';
            List<Merge_Contract_Header__c> mchList = new List<Merge_Contract_Header__c>();
            List<Merge_Contract_Manual_List__c> mlList = new List<Merge_Contract_Manual_List__c>();
            List<Id> mchMLFalseId = new List<Id>();

            Account acc2 = utilTestClass.CreateAccount('IRCaseTestAcc2');
            insert acc2;
            acc2 = RefreshAccount(acc2);

            Opportunity opp2 = utilTestClass.CreateOpportunity('IRCaseOppty2', '1-Create');
            opp2.AccountId=acc2.Id;
            opp2.CloseDate= Date.today().addDays(10);
            insert opp2;

            Opportunity opp3 = utilTestClass.CreateOpportunity('IRCaseOppty3', '1-Create');
            opp3.AccountId=acc2.Id;
            opp3.CloseDate= Date.today().addDays(10);
            insert opp3;

            //Creating 100 contracts for opp2 and opp3 each
            for (integer i = 2;i<=201 ; i++)
            {
                Id oppId;
                if (i<=101)
                 oppId = opp2.Id;
                else
                 oppId = opp3.Id;
                Merge_Contract_Header__c mch2 = createContractHeader(contName+i, acc2.Id, oppId);
                mch2.Manual_List__c = false;
                mch2.Acceptance_Date__c = reviewDate.addMonths(-1).addDays(10);
                mchList.add(mch2);
            }

            insert mchList;

            //Creating one manual list for each of the created contracts
            String j = NULL;

            for (Merge_Contract_header__c mch : mchList)
            {
                j = mch.Name.substring(9);
                Merge_Contract_Manual_List__c mcManList2 = createContractManualList(mlName+j, mch.Name);
                mcManList2.Review_Frequency__c = 'Monthly';
                mcManList2.Manual_List_Id__c  = 'ManualListId'+j;
                System.debug('mcManList2.Manual_List_Id__c: '+mcManList2.Manual_List_Id__c);
                System.debug('mcManList2.Id: '+mcManList2.Id);
                mcManList2.End_Date__c = Date.today().addMonths(2);
                mcManList2.Owner__c = 'Owner';
                mcManList2.Review_Date__c = reviewDate;
                mcManList2.Priority__c = 'PRIORITY';
                mlList.add(mcManList2);

                //Setting Manual_List__c flag to false for half of the contracts
                Integer k =integer.valueof(j);
                if (Math.mod(k,2)==0)
                mch.Manual_List__c=false;
                mchMLFalseId.add(mch.Id);

            }

            insert mlList;

            //Updating the contracts where Manual_List__c flag has been marked false
            List<Merge_Contract_header__c>mchMLFalseList = [Select Id, Name, Manual_List__c, (SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,
            Priority__c,Review_Date__c,Review_Frequency__c,Owner__c,Manual_List_Modify__c from Merge_Contract_Manual_Lists__r Order by End_Date__c DESC) From Merge_Contract_Header__c where Id IN :mchMLFalseId];

            update mchMLFalseList;

            If (mchMLFalseId.size()>0)
                System.debug('Count of mchMLFalseId '+mchMLFalseId.size());



            //Updating the manual lists of contracts for which Manual_List__c flag has been marked false
            //This update should set manual_list__c flag back to true for these contracts
            List<Merge_Contract_Manual_List__c> mlUpdateList = [Select Id,Owner__c,Priority__c from Merge_Contract_Manual_List__c
                                                               where Id in :mchMLFalseId];

            for (Merge_Contract_Manual_List__c mlUpdList : mlUpdateList)
            {
                mlUpdList.Owner__c = 'OwnerChange';
                mlUpdList.Priority__c = 'PriorityNew';

            }

            Test.startTest();
            update mlUpdateList;
            Test.stopTest();

            //mchList contains total 200 contracts
            mchList = refreshContractHeaderList(mchList);

            //Check Any contracts for which manual_list__c is still false
            List<Merge_Contract_Header__c> mchMLFalseList1 = [Select Id, Manual_List__c from Merge_Contract_Header__c where Id IN :mchList AND Manual_List__c= false];

            if (mchMLFalseList1.size()>0)
            {
                System.assert(false);
            }
            else
            {
                System.debug('Contract with Manual List Flag Passed..');
                System.assert(true);
            }
        }
    }

    //CR 3668332
    static testMethod void IRCaseCreationBatch_CaseCcyPos()
    {
        System.runAs(sysAdmin)
        {
            Account acc1 = SobjectRepository.getAccount();
            Opportunity opp1 = SobjectRepository.getOpportunity();
            Merge_Contract_Header__c mch1Id = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
            Merge_Contract_Header__c mch1 = refreshContractHeader(mch1Id);

            Merge_Contract_Header__c mch2 = createContractHeader('IRCaseMCH2', acc1.Id, opp1.Id);
            mch2.Manual_List__c = false;
            mch2.Acceptance_Date__c = reviewDate.addMonths(-1).addDays(10);
            mch2.Currency__c='EUR';
            insert mch2;

            Invoice__c prevMonthFinalInvoice2 = createInvoice(acc1.AKAM_Account_ID__c, mch2.Name, '1303123232', reviewDate.addMonths(-1), 10);
            insert prevMonthFinalInvoice2;

            Invoice_Review_Case_Audit__c ircaCurrent=createIRCARec(reviewDate,'IRCaseTest1279');
            insert ircaCurrent;

            Invoice_Review_Case_Audit__c ircaLast=new Invoice_Review_Case_Audit__c();

            Draft_Invoice__c di1=createDraftInvoice(acc1.Id, mch2.Name, '1304123789', reviewDate, 500);
            di1.CI_Original_Contract_Id__c=mch2.Name;
            di1.Invoice_Review_Case_Audit__c=ircaCurrent.Id;

            insert di1;

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

            IRCaseCreationBatchable execIRCaseCreation = new IRCaseCreationBatchable(ircaCurrent, ircaLast);
            execIRCaseCreation.query=query;
            ID batchprocessid=Database.executeBatch(execIRCaseCreation,batchSize);
            System.debug('batchprocessid=' + batchprocessid);
            System.debug('contractID------- '+mch2.Id);
            Test.stopTest();

            ircaCurrent = refreshIRCA(ircaCurrent);
            System.assert(ircaCurrent.Case_Creation_Completed__c);
            System.assert(ircaCurrent.Case_Creation_End_Date__c!=null);
            System.assertEquals('Success', ircaCurrent.Case_Creation_Status__c);

            for (Case cs : [Select Id,CurrencyIsoCode,IR_CurrentInvoiceAmount__c  from Case where IR_Original_Contract_Id__c = :mch2.Id])
            {
                System.assertEquals('EUR',cs.CurrencyIsoCode);
            }
        }
    }

    //CR 3668332
    static testMethod void IRCaseCreationBatch_CaseCcyNeg()
    {
        System.runAs(sysAdmin)
        {
            Account acc1 = SobjectRepository.getAccount();
            Opportunity opp1 = SobjectRepository.getOpportunity();
            Merge_Contract_Header__c mch1Id = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
            Merge_Contract_Header__c mch1 = refreshContractHeader(mch1Id);

            Merge_Contract_Header__c mch2 = createContractHeader('IRCaseMCH2', acc1.Id, opp1.Id);
            mch2.Manual_List__c = false;
            mch2.Acceptance_Date__c = reviewDate.addMonths(-1).addDays(10);
            //Commenting the code to assign currency to Contract. Default should be USD
            //mch2.Currency__c='EUR';
            insert mch2;

            Invoice__c prevMonthFinalInvoice2 = createInvoice(acc1.AKAM_Account_ID__c, mch2.Name, '1303123232', reviewDate.addMonths(-1), 10);
            insert prevMonthFinalInvoice2;

            Invoice_Review_Case_Audit__c ircaCurrent=createIRCARec(reviewDate,'IRCaseTest1279');
            insert ircaCurrent;

            Invoice_Review_Case_Audit__c ircaLast=new Invoice_Review_Case_Audit__c();

            Draft_Invoice__c di1=createDraftInvoice(acc1.Id, mch2.Name, '1304123789', reviewDate, 500);
            di1.CI_Original_Contract_Id__c=mch2.Name;
            di1.Invoice_Review_Case_Audit__c=ircaCurrent.Id;

            insert di1;

            di1 = refreshDraftInvoice(di1);
            di1.hasAttachment__c=true;
            update di1;


                ircaCurrent.Import_End_Date__c=Datetime.now();
                ircaCurrent.Import_Status__c='Success';
                ircaCurrent.Trigger_Case_Creation__c = true;
                update ircaCurrent;
            //Test.stopTest();
            Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));

            String query = 'SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,Effective_Start_Date__c,Currency__c,';
               query += 'Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,Review_Date__c,';
               query += 'Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where (Name = \'IRCaseMCH2\') AND Active__c=true AND Contract_Type__c != \'ISP\''; // Order by End_Date__c DESC limit 1 //2965556
               query +=  ' AND Locked__c=true AND Effective_End_Date__c >= '+ IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + 'AND (Cancellation_Date__c=null OR Cancellation_Date__c >= ' + IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + ')';
               query +=  ' Limit ' + batchSize;

            System.debug('Query=' + query);

            Test.startTest();

            IRCaseCreationBatchable execIRCaseCreation = new IRCaseCreationBatchable(ircaCurrent, ircaLast);
            execIRCaseCreation.query=query;
            ID batchprocessid=Database.executeBatch(execIRCaseCreation,batchSize);
            System.debug('batchprocessid=' + batchprocessid);
            System.debug('contractID------- '+mch2.Id);
            Test.stopTest();

            ircaCurrent = refreshIRCA(ircaCurrent);
            System.assert(ircaCurrent.Case_Creation_Completed__c);
            System.assert(ircaCurrent.Case_Creation_End_Date__c!=null);
            System.assertEquals('Success', ircaCurrent.Case_Creation_Status__c);

            for (Case cs : [Select Id,CurrencyIsoCode,IR_CurrentInvoiceAmount__c  from Case where IR_Original_Contract_Id__c = :mch2.Id])
            {

                System.assertNotEquals('EUR',cs.CurrencyIsoCode);
                System.assertEquals('USD',cs.CurrencyIsoCode); //Default ccy
            }
        }
    }

    //CR 3668332
    static testMethod void IRCaseCreationBatch_CaseCcyBulk()
    {
        System.runAs(sysAdmin)
        {

            Account acc1 = SobjectRepository.getAccount();
            Opportunity opp1 = SobjectRepository.getOpportunity();
            Merge_Contract_Header__c mch1Id = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
            Merge_Contract_Header__c mch1 = refreshContractHeader(mch1Id);

            Invoice_Review_Case_Audit__c ircaCurrent=createIRCARec(reviewDate,'IRCaseTest1279');
            insert ircaCurrent;

            Invoice_Review_Case_Audit__c ircaLast=new Invoice_Review_Case_Audit__c();

            List<Merge_Contract_Header__c> mchList = new List<Merge_Contract_Header__c>();
            List<Draft_Invoice__c> draftInvList = new List<Draft_Invoice__c>();
            List<String> mchListOdd = new List<String>();
            List<String> mchListEven = new List<String>();

            for (Integer x=0; x <15 ; x++){

                Merge_Contract_Header__c mch2 = createContractHeader('TestIRCaseMCH'+x, acc1.Id, opp1.Id);
                mch2.Manual_List__c = false;
                mch2.Acceptance_Date__c = reviewDate.addMonths(-1).addDays(10);

                if(math.mod(x,2) == 0){
                   mch2.Currency__c='EUR';
                   mchListEven.add(mch2.Name);
                }
                else{
                   mchListOdd.add(mch2.Name);
                }

                mchList.add(mch2);

                Draft_Invoice__c di1=createDraftInvoice(acc1.Id, mch2.Name, '1703123'+String.valueOf(x).leftPad(3,'0'), reviewDate, 500);
                di1.CI_Original_Contract_Id__c=mch2.Name;
                di1.Invoice_Review_Case_Audit__c=ircaCurrent.Id;

                draftInvList.add(di1);
            }

            insert mchList;
            insert draftInvList;

            List<Draft_Invoice__c> refDIList = new List<Draft_Invoice__c>();

            draftInvList=refreshDraftInvoiceList(draftInvList);
            for(Draft_Invoice__c di : draftInvList){
                di.hasAttachment__c=true;
                refDIList.add(di);
            }

            update refDIList;

            ircaCurrent.Import_End_Date__c=Datetime.now();
            ircaCurrent.Import_Status__c='Success';
            ircaCurrent.Trigger_Case_Creation__c = true;
            update ircaCurrent;

            Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));

            String query = 'SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,Effective_Start_Date__c,Currency__c,';
               query += 'Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,Review_Date__c,';
               query += 'Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where (Name like \'TestIRCaseMCH%\') AND Active__c=true AND Contract_Type__c != \'ISP\''; // Order by End_Date__c DESC limit 1 //2965556
               query +=  ' AND Locked__c=true AND Effective_End_Date__c >= '+ IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + 'AND (Cancellation_Date__c=null OR Cancellation_Date__c >= ' + IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + ')';
               query +=  ' Limit ' + batchSize;

            System.debug('Query=' + query);

            Test.startTest();

            IRCaseCreationBatchable execIRCaseCreation = new IRCaseCreationBatchable(ircaCurrent, ircaLast);
            execIRCaseCreation.query=query;
            ID batchprocessid=Database.executeBatch(execIRCaseCreation,batchSize);
            System.debug('batchprocessid=' + batchprocessid);

            Test.stopTest();

            ircaCurrent = refreshIRCA(ircaCurrent);
            System.assert(ircaCurrent.Case_Creation_Completed__c);
            System.assert(ircaCurrent.Case_Creation_End_Date__c!=null);
            System.assertEquals('Success', ircaCurrent.Case_Creation_Status__c);

            for (Case cs : [Select Id,CurrencyIsoCode,IR_CurrentInvoiceAmount__c,Description  from Case where IR_Original_Contract_Id__r.Name IN :mchListOdd])
            {
                System.assertNotEquals('EUR',cs.CurrencyIsoCode);
                System.assertEquals('USD',cs.CurrencyIsoCode); //Default ccy
            }

            for (Case cs : [Select Id,CurrencyIsoCode,IR_CurrentInvoiceAmount__c,Description  from Case where IR_Original_Contract_Id__r.Name IN :mchListEven])
            {

                System.assertEquals('EUR',cs.CurrencyIsoCode);

            }
        }
    }

    //CR 3668332
    static testMethod void IRCaseCreationBatch_CaseCcyUpdate()
    {
        System.runAs(sysAdmin)
        {
            Account acc1 = SobjectRepository.getAccount();
            Opportunity opp1 = SobjectRepository.getOpportunity();
            Merge_Contract_Header__c mch1Id = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
            Merge_Contract_Header__c mch1 = refreshContractHeader(mch1Id);

            Merge_Contract_Manual_List__c mList1 = [select Id from Merge_Contract_Manual_List__c where Manual_List_Id__c = 'IRCaseMlist1' limit 1];

            mcManList = refreshContractMList(mList1);
            Merge_Contract_Header__c mch2 = createContractHeader('IRCaseMCH2', acc1.Id, opp1.Id);
            mch2.Manual_List__c = false;
            mch2.Acceptance_Date__c = reviewDate.addMonths(-1).addDays(10);
            mch2.Currency__c='EUR';
            insert mch2;

            Invoice__c prevMonthFinalInvoice2 = createInvoice(acc1.AKAM_Account_ID__c, mch2.Name, '1303123232', reviewDate.addMonths(-1), 10);
            insert prevMonthFinalInvoice2;

            Invoice_Review_Case_Audit__c ircaCurrent=createIRCARec(reviewDate,'IRCaseTest1279');
            insert ircaCurrent;

            Invoice_Review_Case_Audit__c ircaLast=new Invoice_Review_Case_Audit__c();

            Draft_Invoice__c di1=createDraftInvoice(acc1.Id, mch2.Name, '1304123789', reviewDate, 500);
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


            User newOwnerRSM = GetUser('TST_NRSM');
            Case existinginvCase = createInvoiceCase (di1.Name, reviewDate, acc1.Id, opp1.Id , mch2.Id, newOwnerRSM.Id);
            existinginvCase.IR_Escal_Status__c = 'Pending Review';
            existinginvCase.status = 'Pending Review';
            existinginvCase.Description = 'Test Case Reject Threshold Positive';
            existinginvCase.IR_CurrentInvoiceAmount__c = 500;
            existinginvCase.CurrencyIsoCode = 'USD';
            existingInvCase.Approved_On__c = Datetime.now().addHours(2);

            insert existinginvCase;
            System.assertEquals('USD',existinginvCase.CurrencyIsoCode);

            existinginvCase = getCase(existinginvCase.Id);


            Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));

            String query = 'SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,Effective_Start_Date__c,Currency__c,';
               query += 'Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,Review_Date__c,';
               query += 'Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where (Name = \'IRCaseMCH2\') AND Active__c=true AND Contract_Type__c != \'ISP\''; // Order by End_Date__c DESC limit 1 //2965556
               query +=  ' AND Locked__c=true AND Effective_End_Date__c >= '+ IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + 'AND (Cancellation_Date__c=null OR Cancellation_Date__c >= ' + IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + ')';
               query +=  ' Limit ' + batchSize;

            System.debug('Query=' + query);

            Test.startTest();

            IRCaseCreationBatchable execIRCaseCreation = new IRCaseCreationBatchable(ircaCurrent, ircaLast);
            execIRCaseCreation.query=query;
            ID batchprocessid=Database.executeBatch(execIRCaseCreation,batchSize);
            System.debug('batchprocessid=' + batchprocessid);
            System.debug('contractID------- '+mch2.Id);
            Test.stopTest();

            ircaCurrent = refreshIRCA(ircaCurrent);
            System.assert(ircaCurrent.Case_Creation_Completed__c);
            System.assert(ircaCurrent.Case_Creation_End_Date__c!=null);
            System.assertEquals('Success', ircaCurrent.Case_Creation_Status__c);
            //CR 3713022
            /*
            for (Case cs : [Select Id,CurrencyIsoCode,IR_CurrentInvoiceAmount__c  from Case where IR_Original_Contract_Id__c = :mch2.Id])
            {

                System.assertEquals('EUR',cs.CurrencyIsoCode);
            }
            */
            Case cs = IRCaseHelperClass.getExistingIRCase(mch2.Id,reviewDate);
            System.assertEquals('EUR',cs.CurrencyIsoCode);
        }
    }

        //CR 3619951
        static testMethod void IRCaseCreation_InvMissingLastMonthNeg()
        {
            System.runAs(sysAdmin)
            {
                Account acc1 = SobjectRepository.getAccount();
                Opportunity opp1 = SobjectRepository.getOpportunity();
                Merge_Contract_Header__c mch1Id = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
                Merge_Contract_Header__c mch1 = refreshContractHeader(mch1Id);

                Merge_Contract_Header__c mch2 = createContractHeader('IRCaseMCH2', acc1.Id, opp1.Id);
                mch2.Manual_List__c = false;
                mch2.Acceptance_Date__c = reviewDate.addMonths(-1).addDays(10);
                insert mch2;

                Invoice_Review_Case_Audit__c ircaCurrent=createIRCARec(reviewDate,'IRCaseTest1280');
                insert ircaCurrent;

                //Invoice__c last2LastMonthFinalInvoice2 = createInvoice(acc2.AKAM_Account_ID__c, mch2.Name, '1703123232', reviewDate.addMonths(-2), 450);
                //insert last2LastMonthFinalInvoice2;

                Invoice_Review_Case_Audit__c ircaLast=new Invoice_Review_Case_Audit__c();

                Draft_Invoice__c di1=createDraftInvoice(acc1.Id, mch2.Name, '1705123789', reviewDate, 500);
                di1.CI_Original_Contract_Id__c=mch2.Name;
                di1.Invoice_Review_Case_Audit__c=ircaCurrent.Id;
                di1.billable_flag__c = 'Y';

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
                IRCaseCreationBatchable execIRCaseCreation = new IRCaseCreationBatchable(ircaCurrent, ircaLast);
                execIRCaseCreation.query=query;
                ID batchprocessid=Database.executeBatch(execIRCaseCreation,batchSize);
                System.debug('batchprocessid=' + batchprocessid);
                System.debug('contractID------- '+mch2.Id);
                Test.stopTest();

                ircaCurrent = refreshIRCA(ircaCurrent);
                System.assert(ircaCurrent.Case_Creation_Completed__c);
                System.assert(ircaCurrent.Case_Creation_End_Date__c!=null);
                System.assertEquals('Success', ircaCurrent.Case_Creation_Status__c);

                for (Case cs : [Select Id,IRCache_isNewInvoice__c ,IRCache_hasMissingInvoiceLastMonth__c  from Case where IR_Original_Contract_Id__c = :mch2.Id])
                {
                    System.debug(LoggingLevel.ERROR, 'cs: '+cs);
                    System.assertEquals(true,cs.IRCache_isNewInvoice__c);
                    System.assertEquals(false,cs.IRCache_hasMissingInvoiceLastMonth__c);
                }

      }
    }

    //CR 3619951
        static testMethod void IRCaseCreation_InvMissingLastMonthNegFirstImport()
        {
            System.runAs(sysAdmin)
            {
                Account acc1 = SobjectRepository.getAccount();
                Opportunity opp1 = SobjectRepository.getOpportunity();
                Merge_Contract_Header__c mch1Id = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
                Merge_Contract_Header__c mch1 = refreshContractHeader(mch1Id);

                Merge_Contract_Header__c mch2 = createContractHeader('IRCaseMCH2', acc1.Id, opp1.Id);
                mch2.Manual_List__c = false;
                mch2.Acceptance_Date__c = reviewDate.addMonths(-1).addDays(10);
                //Commenting the code to assign currency to Contract. Default should be USD
                mch2.Currency__c='EUR';
                insert mch2;

                Invoice_Review_Case_Audit__c ircaCurrent=createIRCARec(reviewDate,'IRCaseTest1279');
                insert ircaCurrent;

                Invoice_Review_Case_Audit__c ircaLast=new Invoice_Review_Case_Audit__c();

                String casePriorityThreshold = GsmUtilClass.getGSMSettingValue('IR_Case_Priority_Threshold');
                Draft_Invoice__c di1=createDraftInvoice(acc1.Id, mch2.Name, '1304123789', reviewDate, (Decimal.valueOf(casePriorityThreshold) + 1));
                di1.CI_Original_Contract_Id__c=mch2.Name;
                di1.Invoice_Review_Case_Audit__c=ircaCurrent.Id;
				di1.billable_flag__c = 'Y';

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
                IRCaseCreationBatchable execIRCaseCreation = new IRCaseCreationBatchable(ircaCurrent, null);
                execIRCaseCreation.query=query;
                ID batchprocessid=Database.executeBatch(execIRCaseCreation,batchSize);
                System.debug('batchprocessid=' + batchprocessid);
                System.debug('contractID------- '+mch2.Id);
                Test.stopTest();

                ircaCurrent = refreshIRCA(ircaCurrent);
                System.assert(ircaCurrent.Case_Creation_Completed__c);
                System.assert(ircaCurrent.Case_Creation_End_Date__c!=null);
                System.assertEquals('Success', ircaCurrent.Case_Creation_Status__c);


                for (Case cs : [Select Id,IRCache_isNewInvoice__c ,IRCache_hasMissingInvoiceLastMonth__c,IR_Priority_level__c from Case where IR_Original_Contract_Id__c = :mch2.Id])
                {
                    System.debug(LoggingLevel.ERROR, 'cs: '+cs);
                    System.assertEquals(true,cs.IRCache_isNewInvoice__c);
                    System.assertEquals(false,cs.IRCache_hasMissingInvoiceLastMonth__c);
                    System.assertEquals('High', cs.IR_Priority_level__c);
                }

      }
    }

    //CR 3619951
        static testMethod void IRCaseCreation_InvMissingLastMonth()
        {
            System.runAs(sysAdmin)
            {
                Account acc1 = SobjectRepository.getAccount();
                Opportunity opp1 = SobjectRepository.getOpportunity();
                Merge_Contract_Header__c mch1Id = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
                Merge_Contract_Header__c mch1 = refreshContractHeader(mch1Id);

                Merge_Contract_Header__c mch2 = createContractHeader('IRCaseMCH2', acc1.Id, opp1.Id);
                mch2.Manual_List__c = false;
                mch2.Acceptance_Date__c = reviewDate.addMonths(-1).addDays(10);
                insert mch2;

                Invoice_Review_Case_Audit__c ircaCurrent=createIRCARec(reviewDate,'IRCaseTest1280');
                insert ircaCurrent;

                Invoice_Review_Case_Audit__c ircaLast=new Invoice_Review_Case_Audit__c();

                Invoice__c oldFinalInvoice2 = createInvoice(acc1.AKAM_Account_ID__c, mch2.Name, '1701123232', reviewDate.addMonths(-4), 450);
                insert oldFinalInvoice2;

                String casePriorityThreshold = GsmUtilClass.getGSMSettingValue('IR_Case_Priority_Threshold');
                Draft_Invoice__c di1=createDraftInvoice(acc1.Id, mch2.Name, '1705123789', reviewDate, (Decimal.valueOf(casePriorityThreshold) - 1));
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
                IRCaseCreationBatchable execIRCaseCreation = new IRCaseCreationBatchable(ircaCurrent, ircaLast);
                execIRCaseCreation.query=query;
                ID batchprocessid=Database.executeBatch(execIRCaseCreation,batchSize);
                System.debug('batchprocessid=' + batchprocessid);
                System.debug('contractID------- '+mch2.Id);
                Test.stopTest();

                ircaCurrent = refreshIRCA(ircaCurrent);
                System.assert(ircaCurrent.Case_Creation_Completed__c);
                System.assert(ircaCurrent.Case_Creation_End_Date__c!=null);
                System.assertEquals('Success', ircaCurrent.Case_Creation_Status__c);

                for (Case cs : [Select Id,IRCache_isNewInvoice__c ,IRCache_hasMissingInvoiceLastMonth__c,IR_Priority_level__c from Case where IR_Original_Contract_Id__c = :mch2.Id])
                {
                    System.debug(LoggingLevel.ERROR, 'cs: '+cs);
                    System.assertEquals(false,cs.IRCache_isNewInvoice__c);
                    System.assertEquals(true,cs.IRCache_hasMissingInvoiceLastMonth__c);
                    System.assertEquals(null, cs.IR_Priority_level__c);
                }

            }
        }

    //CR 3619951
        static testMethod void IRCaseCreation_InvMissingLastMonthFirstImport()
        {
            System.runAs(sysAdmin)
            {
                Account acc1 = SobjectRepository.getAccount();
                Opportunity opp1 = SobjectRepository.getOpportunity();
                Merge_Contract_Header__c mch1Id = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
                Merge_Contract_Header__c mch1 = refreshContractHeader(mch1Id);

                Merge_Contract_Header__c mch2 = createContractHeader('IRCaseMCH2', acc1.Id, opp1.Id);
                mch2.Manual_List__c = false;
                mch2.Acceptance_Date__c = reviewDate.addMonths(-1).addDays(10);
                insert mch2;

                Invoice_Review_Case_Audit__c ircaCurrent=createIRCARec(reviewDate,'IRCaseTest1280');
                insert ircaCurrent;

                Invoice_Review_Case_Audit__c ircaLast=new Invoice_Review_Case_Audit__c();

                Invoice__c oldFinalInvoice2 = createInvoice(acc1.AKAM_Account_ID__c, mch2.Name, '1701123232', reviewDate.addMonths(-4), 450);
                insert oldFinalInvoice2;

                Draft_Invoice__c di1=createDraftInvoice(acc1.Id, mch2.Name, '1705123789', reviewDate, 500);
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
                ircaLast = null;
                IRCaseCreationBatchable execIRCaseCreation = new IRCaseCreationBatchable(ircaCurrent, ircaLast);
                execIRCaseCreation.query=query;
                ID batchprocessid=Database.executeBatch(execIRCaseCreation,batchSize);
                System.debug('batchprocessid=' + batchprocessid);
                System.debug('contractID------- '+mch2.Id);
                Test.stopTest();

                ircaCurrent = refreshIRCA(ircaCurrent);
                System.assert(ircaCurrent.Case_Creation_Completed__c);
                System.assert(ircaCurrent.Case_Creation_End_Date__c!=null);
                System.assertEquals('Success', ircaCurrent.Case_Creation_Status__c);

                for (Case cs : [Select Id,IRCache_isNewInvoice__c ,IRCache_hasMissingInvoiceLastMonth__c  from Case where IR_Original_Contract_Id__c = :mch2.Id])
                {
                    System.debug(LoggingLevel.ERROR, 'cs: '+cs);
                    System.assertEquals(false,cs.IRCache_isNewInvoice__c);
                    System.assertEquals(true,cs.IRCache_hasMissingInvoiceLastMonth__c);
                }
            }
        }

        static testMethod void IRCaseCreationNonBillableMultipleScenarios ()
        {
          System.runAs(sysAdmin)
          {
            Account acc1 = SobjectRepository.getAccount();
            Opportunity opp1 = SobjectRepository.getOpportunity();
            Merge_Contract_Header__c mch1Id = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];

            Merge_Contract_Header__c mch1 = refreshContractHeader(mch1Id);
            mch1.Contract_Type__c = 'Indirect Customer';
            update mch1;

            Invoice_Review_Case_Audit__c ircaLast=createIRCARec(reviewDate,'IRCaseTest1277');
            ircaLast.Import_Start_Date__c = Datetime.now().addDays(-1);
            ircaLast.Import_Status__c = 'Success';
            ircaLast.Case_Creation_Completed__c=true;
            ircaLast.Import_End_Date__c = Datetime.now().addDays(-1);
            insert ircaLast;
            System.debug('Last import irca '+ircaLast.id);

            Invoice_Review_Case_Audit__c ircaCurrent=createIRCARec(reviewDate,'IRCaseTest1278');
            insert ircaCurrent;
            System.debug('inserted current irca'+ircaCurrent.id);

            Draft_Invoice__c di1=createDraftInvoice(acc1.Id, mch1.Name, '1304123789', reviewDate, -500);
            di1.CI_Original_Contract_Id__c=mch1.Name;
            di1.Invoice_Review_Case_Audit__c=ircaCurrent.Id;
            di1.billable_flag__c = 'N';
            insert di1;

            di1 = IRCaseHelperClass.getExistingDraftInvoice(mch1.Id,reviewDate);

            di1 = refreshDraftInvoice(di1);
            di1.hasAttachment__c=true;
            update di1;

            ircaCurrent.Import_End_Date__c=Datetime.now();
            ircaCurrent.Import_Status__c='Success';
            ircaCurrent.Trigger_Case_Creation__c = true;
            update ircaCurrent;

            InvoiceReviewCaseWrapper ircw = new InvoiceReviewCaseWrapper();
            Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));

            String query = 'SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,Effective_Start_Date__c,Currency__c,';
               query += 'Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,Review_Date__c,';
               query += 'Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where (Name = \'IRCaseMCH1\') AND Active__c=true AND Contract_Type__c != \'ISP\''; // Order by End_Date__c DESC limit 1 //2965556
               query +=  ' AND Locked__c=true AND Effective_End_Date__c >= '+ IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + 'AND (Cancellation_Date__c=null OR Cancellation_Date__c >= ' + IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + ')';
               query +=  ' Limit ' + batchSize;

            System.debug('Query=' + query);

            Test.startTest();
            ircaLast = null;
            IRCaseCreationBatchable execIRCaseCreation = new IRCaseCreationBatchable(ircaCurrent, ircaLast);
            execIRCaseCreation.query=query;
            ID batchprocessid=Database.executeBatch(execIRCaseCreation,batchSize);
            System.debug('batchprocessid=' + batchprocessid);
            System.debug('contractID------- '+mch1.Id);
            Test.stopTest();

            ircaCurrent = refreshIRCA(ircaCurrent);
            System.assert(ircaCurrent.Case_Creation_Completed__c);
            System.assert(ircaCurrent.Case_Creation_End_Date__c!=null);
            System.assertEquals('Success', ircaCurrent.Case_Creation_Status__c);

            for (Case cs : [Select Id ,IRCache_hasMissingInvoiceLastMonth__c, description  from Case where IR_Original_Contract_Id__c = :mch1.Id])
            {
                System.debug(LoggingLevel.ERROR, 'cs: '+cs.description);
                System.assertEquals(true,cs.description.contains('Contract requires double Invoice Review'));
                System.assertEquals(true,cs.description.contains('Manual Contract'));
                System.assertEquals(true,cs.description.contains('Negative invoice detected'));
            }
          }
        }

        static testMethod void IRCaseCreation_ThresholdFinalWithCrMemo()
        {
            System.runAs(sysAdmin)
            {
                Account acc1 = SobjectRepository.getAccount();
                Opportunity opp1 = SobjectRepository.getOpportunity();
                Merge_Contract_Header__c mch1Id = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
                Merge_Contract_Header__c mch1 = refreshContractHeader(mch1Id);

                Merge_Contract_Header__c mch2 = createContractHeader('IRCaseMCH2', acc1.Id, opp1.Id);
                mch2.Manual_List__c = false;
                mch2.Acceptance_Date__c = reviewDate.addMonths(-1).addDays(10);
                insert mch2;

                Invoice_Review_Case_Audit__c ircaLast=createIRCARec(reviewDate,'IRCaseTest1277');
                ircaLast.Import_Start_Date__c = Datetime.now().addDays(-1);
                ircaLast.Import_Status__c = 'Success';
                ircaLast.Case_Creation_Completed__c=true;
                ircaLast.Import_End_Date__c = Datetime.now().addDays(-1);
                insert ircaLast;
                System.debug('Last import irca '+ircaLast.id);

                Invoice_Review_Case_Audit__c ircaCurrent=createIRCARec(reviewDate,'IRCaseTest1278');
                insert ircaCurrent;
                System.debug('inserted current irca'+ircaCurrent.id);


                Draft_Invoice__c di2=createDraftInvoice(acc1.Id, mch2.Name, '1304123770', reviewDate, 12000);
                di2.CI_Original_Contract_Id__c=mch2.Name;
                di2.Invoice_Review_Case_Audit__c=ircaCurrent.Id;
                di2.Previous_Month_Outstanding_Amount__c = 60000;
                di2.billable_flag__c = 'Y';
                insert di2;

                //Testing that Credit Memo invoice is not included for IR Case creation
                Invoice__c prevMonthFinalInvoiceCrMemo = createInvoice(acc1.Akam_Account_Id__c, mch2.Name, '9123456788', reviewDate.addMonths(-1).addDays(4), 50000);
                insert prevMonthFinalInvoiceCrMemo;

                Attachment attachmentsCrMemo = createInvoiceAttachment (prevMonthFinalInvoiceCrMemo.Id);
                Blob b1 = Blob.valueOf('Test Data');
                attachmentsCrMemo.Body = b1;
                attachmentsCrMemo.Name = 'Test Attachment for Parent';
                insert attachmentsCrMemo;

                System.debug('di2.Original_Contract_Id__c '+di2.Original_Contract_Id__c);

                di2 = refreshDraftInvoice(di2);
                di2.hasAttachment__c=true;

                update di2;

                //Test.startTest();
                    ircaCurrent.Import_End_Date__c=Datetime.now();
                    ircaCurrent.Import_Status__c='Success';
                    ircaCurrent.Trigger_Case_Creation__c = true;
                    update ircaCurrent;
                //Test.stopTest();

                Test.startTest();
                List<Merge_Contract_Header__c> mchList1 = new List<Merge_Contract_Header__c>();
                for (Merge_Contract_Header__c mch : [SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,
                Effective_Start_Date__c,Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,
                Review_Date__c,Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Active__c=true AND Contract_Type__c != 'ISP' //2965556
                AND Locked__c=true AND Effective_End_Date__c >= :reviewDate.addMonths(-1) AND (Cancellation_Date__c=null OR Cancellation_Date__c >= :reviewDate.addMonths(-1)) //LIMIT 100])
                AND (Id=:mch1.Id OR Id=:mch2.Id)])
                {
                    mchList1.add(mch);
                }
                System.debug('mchList1 size=' + mchList1.size());
                System.debug('mchList1=' + mchList1);

                CaseTriggerClass.isIRCaseCreationInprogress=true;
                creationData(mchList1,ircaCurrent,ircaLast); //2965556


                // check IR Case creation criteria for Threshold violation

                Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));
                String query = 'SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,Effective_Start_Date__c,Currency__c,';
                   query += 'Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,Review_Date__c,';
                   query += 'Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Id  =\''+mch2.Id+'\''; //2965556
                   query += ' AND Active__c=true AND Contract_Type__c != \'ISP\''; // Order by End_Date__c DESC limit 1
                   query +=  ' AND Locked__c=true AND Effective_End_Date__c >= '+ IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + 'AND (Cancellation_Date__c=null OR Cancellation_Date__c >= ' + IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + ')';
                   query +=  ' Limit ' + batchSize;

                System.debug('Query=' + query);

                 //Test.startTest();
                IRCaseCreationBatchable execIRCaseCreation = new IRCaseCreationBatchable(ircaCurrent, ircaLast);
                execIRCaseCreation.query=query;
                //Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));
                ID batchprocessid=Database.executeBatch(execIRCaseCreation,batchSize);
                //System.debug(Database.executeBatch(execIRCaseCreation,batchSize));
                System.debug('batchprocessid=' + batchprocessid);
                System.debug('--->');
                Test.stopTest();

                ircaCurrent = refreshIRCA(ircaCurrent);

                System.debug('ircaCurrent.Case_Creation_Completed__c: '+ircaCurrent.Case_Creation_Completed__c);
                System.debug('ircaCurrent.Case_Creation_End_Date__c: '+ircaCurrent.Case_Creation_End_Date__c);
                System.debug('ircaCurrent.Case_Creation_Status__c: '+ircaCurrent.Case_Creation_Status__c);
                System.assert(ircaCurrent.Case_Creation_Completed__c);
                System.assert(ircaCurrent.Case_Creation_End_Date__c!=null);
                System.assertEquals('Success', ircaCurrent.Case_Creation_Status__c);


                for (Case cs : [Select Id, IRCache_hasThresholdViolation__c,Description  from Case where IR_Original_Contract_Id__c = :mch2.Id])
                {
                  System.assertEquals(true, cs.IRCache_hasThresholdViolation__c);
                  System.assert(cs.Description.contains('80.0'));
                    System.debug('Description: '+cs.Description);
                }

            }
        }

        static testMethod void IRCaseCreation_DirectNonBillableChild()
        {
            System.runAs(sysAdmin)
            {
                Account acc1 = SobjectRepository.getAccount();
                Opportunity opp1 = SobjectRepository.getOpportunity();
                Merge_Contract_Header__c mch1Id = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
                Merge_Contract_Header__c mch1 = refreshContractHeader(mch1Id);

                Invoice_Review_Case_Audit__c ircaLast=createIRCARec(reviewDate,'IRCaseTest1277');
                ircaLast.Import_Start_Date__c = Datetime.now().addDays(-1);
                ircaLast.Import_Status__c = 'Success';
                ircaLast.Case_Creation_Completed__c=true;
                ircaLast.Import_End_Date__c = Datetime.now().addDays(-1);
                insert ircaLast;
                System.debug('Last import irca '+ircaLast.id);

                Invoice_Review_Case_Audit__c ircaCurrent=createIRCARec(reviewDate,'IRCaseTest1278');
                insert ircaCurrent;
                System.debug('inserted current irca'+ircaCurrent.id);

                Draft_Invoice__c di1=createDraftInvoice(acc1.Id, mch1.Name, '1903123770', reviewDate, 2000);
                di1.CI_Original_Contract_Id__c=mch1.Name;
                di1.Invoice_Review_Case_Audit__c=ircaLast.Id;
                di1.billable_flag__c = 'N';
                insert di1;

                Draft_Invoice__c di2=createDraftInvoice(acc1.Id, mch1.Name, '1903123770', reviewDate, 32000);
                di2.CI_Original_Contract_Id__c=mch1.Name;
                di2.Invoice_Review_Case_Audit__c=ircaCurrent.Id;
                di2.billable_flag__c = 'N';
                insert di2;

                System.debug('di2.Original_Contract_Id__c '+di2.Original_Contract_Id__c);

                di1 = refreshDraftInvoice(di1);
                di2 = refreshDraftInvoice(di2);
                di1.hasAttachment__c=true;
                di2.hasAttachment__c=true;

                update di1;
                update di2;

                //Test.startTest();
                    ircaCurrent.Import_End_Date__c=Datetime.now();
                    ircaCurrent.Import_Status__c='Success';
                    ircaCurrent.Trigger_Case_Creation__c = true;
                    update ircaCurrent;
                //Test.stopTest();

                Test.startTest();
                // List<Merge_Contract_Header__c> mchList1 = new List<Merge_Contract_Header__c>();
                // for (Merge_Contract_Header__c mch : [SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,
                // Effective_Start_Date__c,Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,
                // Review_Date__c,Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Active__c=true AND Contract_Type__c != 'ISP' //2965556
                // AND Locked__c=true AND Effective_End_Date__c >= :reviewDate.addMonths(-1) AND (Cancellation_Date__c=null OR Cancellation_Date__c >= :reviewDate.addMonths(-1)) //LIMIT 100])
                // AND (Id=:mch1.Id)])
                // {
                //     mchList1.add(mch);
                // }
                // System.debug('mchList1 size=' + mchList1.size());
                // System.debug('mchList1=' + mchList1);
                //
                // CaseTriggerClass.isIRCaseCreationInprogress=true;
                // creationData(mchList1,ircaCurrent,ircaLast); //2965556


                // check IR Case creation criteria for Threshold violation

                Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));
                String query = 'SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,Effective_Start_Date__c,Currency__c,';
                   query += 'Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,Review_Date__c,';
                   query += 'Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Id  =\''+mch1.Id+'\''; //2965556
                   query += ' AND Active__c=true AND Contract_Type__c != \'ISP\''; // Order by End_Date__c DESC limit 1
                   query +=  ' AND Locked__c=true AND Effective_End_Date__c >= '+ IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + 'AND (Cancellation_Date__c=null OR Cancellation_Date__c >= ' + IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + ')';
                   query +=  ' Limit ' + batchSize;

                System.debug('Query=' + query);

                 //Test.startTest();
                IRCaseCreationBatchable execIRCaseCreation = new IRCaseCreationBatchable(ircaCurrent, ircaLast);
                execIRCaseCreation.query=query;
                //Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));
                ID batchprocessid=Database.executeBatch(execIRCaseCreation,batchSize);
                //System.debug(Database.executeBatch(execIRCaseCreation,batchSize));
                System.debug('batchprocessid=' + batchprocessid);
                System.debug('--->');
                Test.stopTest();

                ircaCurrent = refreshIRCA(ircaCurrent);

                System.debug('ircaCurrent.Case_Creation_Completed__c: '+ircaCurrent.Case_Creation_Completed__c);
                System.debug('ircaCurrent.Case_Creation_End_Date__c: '+ircaCurrent.Case_Creation_End_Date__c);
                System.debug('ircaCurrent.Case_Creation_Status__c: '+ircaCurrent.Case_Creation_Status__c);
                System.assert(ircaCurrent.Case_Creation_Completed__c);
                System.assert(ircaCurrent.Case_Creation_End_Date__c!=null);
                System.assertEquals('Success', ircaCurrent.Case_Creation_Status__c);


                for (Case cs : [Select Id, IRCache_hasDraftThresholdViolation__c,Description  from Case where IR_Original_Contract_Id__c = :mch1.Id])
                {
                  System.assertEquals(false, cs.IRCache_hasDraftThresholdViolation__c);
                  System.debug('Description: '+cs.Description);
                }

            }
        }



        /********************************************* Test Cases for checkForAlerts method begin ***************************************/


        static testMethod void activeFlgIsTrue()
         //scenario: there no exisiting case, and there is one info(from the view) record corresponding to the case having active flag true
        //expectation: the alert type should be Alert Name and the description is Alert Line of the corresponding record and on case the inv item is associated
        //(the case might get created for other reasons but descrition and alert type should be updated appropriately)

        {
            System.runAs(sysAdmin)
            {
                Account acc1 = SobjectRepository.getAccount();
                Merge_Contract_Header__c mch1Id = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
                Merge_Contract_Header__c mch1 = refreshContractHeader(mch1Id);

                Invoice_Review_Case_Audit__c ircaLast=createIRCARec(reviewDate,'IRCaseTest1277');
                ircaLast.Import_Start_Date__c = Datetime.now().addDays(-1);
                ircaLast.Import_Status__c = 'Success';
                ircaLast.Case_Creation_Completed__c=true;
                ircaLast.Import_End_Date__c = Datetime.now().addDays(-1);
                insert ircaLast;
                System.debug(Logginglevel.INFO,'Last import irca '+ircaLast.id);

                Invoice_Review_Case_Audit__c ircaCurrent=createIRCARec(reviewDate,'IRCaseTest1278');
                insert ircaCurrent;
                System.debug(Logginglevel.INFO,'inserted current irca'+ircaCurrent.id);


                Draft_Invoice__c di2=createDraftInvoice(acc1.Id, mch1.Name, '1304123770', reviewDate, 12000);
                di2.CI_Original_Contract_Id__c=mch1.Name;
                di2.Invoice_Review_Case_Audit__c=ircaCurrent.Id;
                //di2.Previous_Month_Outstanding_Amount__c = 60000;
                //di2.billable_flag__c = 'Y';
                insert di2;

                String alertName1 = 'PS_OVERAGE_NOMATCH';
                String uniqueID1 = mch1.Name + String.valueof(reviewDate) +alertName1;

                IR_Case_Info__c irci = createIRCaseInfoRecord(mch1, di2, uniqueID1);
                insert irci;

                List<IR_Case_Info__c> data1 = [Select id, Order_Id__c, Active_Flag__c,Alert_Description__c, Alert_Line__c, Alert_Name__c, Billable_Invoice_Id__c,
                                              Invoice_Date__c from IR_Case_Info__c where Order_Id__c = :mch1.Name and Invoice_Date__c = :reviewDate];


                System.debug(Logginglevel.INFO,'Info inserted ****************************************************'+data1);

                System.debug(Logginglevel.INFO,'di2.Original_Contract_Id__c '+di2.Original_Contract_Id__c);

                //di2 = refreshDraftInvoice(di2);
                di2.hasAttachment__c=true;
                di2.isDuplicate__c = false;
                di2.Original_Contract_Id__c = mch1.Id;
                update di2;
                System.debug(Logginglevel.INFO,'draft inv------------------------------------------------------------------'+di2);

                //Test.startTest();
                    ircaCurrent.Import_End_Date__c=Datetime.now();
                    ircaCurrent.Import_Status__c='Success';
                    ircaCurrent.Trigger_Case_Creation__c = true;
                    update ircaCurrent;
                //Test.stopTest();

                Test.startTest();
                List<Merge_Contract_Header__c> mchList1 = new List<Merge_Contract_Header__c>();
                for (Merge_Contract_Header__c mch : [SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,
                Effective_Start_Date__c,Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,
                Review_Date__c,Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Active__c=true AND Contract_Type__c != 'ISP' //2965556
                AND Locked__c=true AND Effective_End_Date__c >= :reviewDate.addMonths(-1) AND (Cancellation_Date__c=null OR Cancellation_Date__c >= :reviewDate.addMonths(-1)) //LIMIT 100])
                AND (Id=:mch1.Id)])
                {
                    mchList1.add(mch);
                }
                System.debug(Logginglevel.INFO,'mchList1 size=' + mchList1.size());
                System.debug(Logginglevel.INFO,'mchList1=' + mchList1);

                CaseTriggerClass.isIRCaseCreationInprogress=true;
                creationData(mchList1,ircaCurrent,ircaLast); //2965556


                // check IR Case creation criteria for Threshold violation

                Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));
                String query = 'SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,Effective_Start_Date__c,Currency__c,';
                   query += 'Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,Review_Date__c,';
                   query += 'Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Id  =\''+mch1.Id+'\''; //2965556
                   query += ' AND Active__c=true AND Contract_Type__c != \'ISP\''; // Order by End_Date__c DESC limit 1
                   query +=  ' AND Locked__c=true AND Effective_End_Date__c >= '+ IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + 'AND (Cancellation_Date__c=null OR Cancellation_Date__c >= ' + IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + ')';
                   query +=  ' Limit ' + batchSize;

                System.debug(Logginglevel.INFO,'Query=' + query);

                 //Test.startTest();
                IRCaseCreationBatchable execIRCaseCreation = new IRCaseCreationBatchable(ircaCurrent, ircaLast);
                execIRCaseCreation.query=query;
                //Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));
                ID batchprocessid=Database.executeBatch(execIRCaseCreation,batchSize);
                //System.debug(Database.executeBatch(execIRCaseCreation,batchSize));
                System.debug(Logginglevel.INFO,'batchprocessid=' + batchprocessid);
                System.debug(Logginglevel.INFO,'--->');
                Test.stopTest();

                ircaCurrent = refreshIRCA(ircaCurrent);

                System.debug(Logginglevel.INFO,'ircaCurrent.Case_Creation_Completed__c: '+ircaCurrent.Case_Creation_Completed__c);
                System.debug(Logginglevel.INFO,'ircaCurrent.Case_Creation_End_Date__c: '+ircaCurrent.Case_Creation_End_Date__c);
                System.debug(Logginglevel.INFO,'ircaCurrent.Case_Creation_Status__c: '+ircaCurrent.Case_Creation_Status__c);
                System.assert(ircaCurrent.Case_Creation_Completed__c, 'Case creation completed');
                System.assert(ircaCurrent.Case_Creation_End_Date__c!=null, 'Case creation end date is not null');
                System.assertEquals('Success', ircaCurrent.Case_Creation_Status__c, 'Case creation status is success');

                List<Case> cases = [Select Id, Description, IR_Case_Type__c,IR_Invoice_Number__c  from Case where IR_Original_Contract_Id__c = :mch1.Id];
                System.debug(Logginglevel.INFO,'Cases created ***************************************************'+cases);

                 for (Case cs : [Select Id, IR_Case_Type__c, Description, IR_Invoice_Number__c  from Case where IR_Original_Contract_Id__c = :mch1.Id])
                 {
                  System.debug(Logginglevel.INFO,'cs.Description=========================================='+cs.Description);
                  System.debug(Logginglevel.INFO,'cs.IR_Case_Type__c=========================================='+cs.IR_Case_Type__c);
                  System.assert(cs.Description.contains(data1[0].Alert_Line__c),'should contain the alerts description');
                  System.assert(cs.IR_Case_Type__c.contains(data1[0].Alert_Name__c), 'should contain the alerts Name');
                  System.debug(Logginglevel.INFO,'cs.IR_Invoice_Number__c=========================================='+cs.IR_Invoice_Number__c);
                  System.debug(Logginglevel.INFO,'di2.Name=========================================='+di2.Name);
                  System.assertEquals(di2.Name, cs.IR_Invoice_Number__c,'should contain the inv draft no');

                }

            }
        }

    static testMethod void activeFlgIsFalse()
        //scenario: there no exisiting case, and there is one info(from the view) record corresponding to the case having active flag false
        //expectation: the alert type is null and the description is not added (the case might get created for other reasons but descrition and alert type is not updated)
        {
            System.runAs(sysAdmin)
            {
                Account acc1 = SobjectRepository.getAccount();
                Merge_Contract_Header__c mch1Id = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
                Merge_Contract_Header__c mch1 = refreshContractHeader(mch1Id);

                Invoice_Review_Case_Audit__c ircaLast=createIRCARec(reviewDate,'IRCaseTest1277');
                ircaLast.Import_Start_Date__c = Datetime.now().addDays(-1);
                ircaLast.Import_Status__c = 'Success';
                ircaLast.Case_Creation_Completed__c=true;
                ircaLast.Import_End_Date__c = Datetime.now().addDays(-1);
                insert ircaLast;
                System.debug(Logginglevel.INFO,'Last import irca '+ircaLast.id);

                Invoice_Review_Case_Audit__c ircaCurrent=createIRCARec(reviewDate,'IRCaseTest1278');
                insert ircaCurrent;
                System.debug(Logginglevel.INFO,'inserted current irca'+ircaCurrent.id);


                Draft_Invoice__c di2=createDraftInvoice(acc1.Id, mch1.Name, '1304123770', reviewDate, 12000);
                di2.CI_Original_Contract_Id__c=mch1.Name;
                di2.Invoice_Review_Case_Audit__c=ircaCurrent.Id;
                insert di2;

                String alertName1 = 'PS_OVERAGE_NOMATCH';
                String uniqueID1 = mch1.Name + String.valueof(reviewDate) +alertName1;

                IR_Case_Info__c irci = createIRCaseInfoRecord(mch1, di2, uniqueID1);
                insert irci;

                irci.Active_Flag__c = false;
                update irci;

                List<IR_Case_Info__c> data1 = [Select id, Order_Id__c, Active_Flag__c,Alert_Description__c, Alert_Line__c, Alert_Name__c, Billable_Invoice_Id__c,
                                              Invoice_Date__c from IR_Case_Info__c where Order_Id__c = :mch1.Name and Invoice_Date__c = :reviewDate];


                System.debug(Logginglevel.INFO,'Info inserted ****************************************************'+data1);

                System.debug(Logginglevel.INFO,'di2.Original_Contract_Id__c '+di2.Original_Contract_Id__c);

                di2.hasAttachment__c=true;
                di2.isDuplicate__c = false;
                di2.Original_Contract_Id__c = mch1.Id;
                update di2;
                System.debug(Logginglevel.INFO,'draft inv------------------------------------------------------------------'+di2);

                    ircaCurrent.Import_End_Date__c=Datetime.now();
                    ircaCurrent.Import_Status__c='Success';
                    ircaCurrent.Trigger_Case_Creation__c = true;
                    update ircaCurrent;

                Test.startTest();
                List<Merge_Contract_Header__c> mchList1 = new List<Merge_Contract_Header__c>();
                for (Merge_Contract_Header__c mch : [SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,
                Effective_Start_Date__c,Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,
                Review_Date__c,Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Active__c=true AND Contract_Type__c != 'ISP' //2965556
                AND Locked__c=true AND Effective_End_Date__c >= :reviewDate.addMonths(-1) AND (Cancellation_Date__c=null OR Cancellation_Date__c >= :reviewDate.addMonths(-1)) //LIMIT 100])
                AND (Id=:mch1.Id)])
                {
                    mchList1.add(mch);
                }
                System.debug(Logginglevel.INFO,'mchList1 size=' + mchList1.size());
                System.debug(Logginglevel.INFO,'mchList1=' + mchList1);

                CaseTriggerClass.isIRCaseCreationInprogress=true;
                creationData(mchList1,ircaCurrent,ircaLast); //2965556

                Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));
                String query = 'SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,Effective_Start_Date__c,Currency__c,';
                   query += 'Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,Review_Date__c,';
                   query += 'Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Id  =\''+mch1.Id+'\''; //2965556
                   query += ' AND Active__c=true AND Contract_Type__c != \'ISP\''; // Order by End_Date__c DESC limit 1
                   query +=  ' AND Locked__c=true AND Effective_End_Date__c >= '+ IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + 'AND (Cancellation_Date__c=null OR Cancellation_Date__c >= ' + IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + ')';
                   query +=  ' Limit ' + batchSize;

                System.debug(Logginglevel.INFO,'Query=' + query);

                IRCaseCreationBatchable execIRCaseCreation = new IRCaseCreationBatchable(ircaCurrent, ircaLast);
                execIRCaseCreation.query=query;
                ID batchprocessid=Database.executeBatch(execIRCaseCreation,batchSize);
                System.debug(Logginglevel.INFO,'batchprocessid=' + batchprocessid);
                System.debug(Logginglevel.INFO,'--->');
                Test.stopTest();

                ircaCurrent = refreshIRCA(ircaCurrent);

                System.debug(Logginglevel.INFO,'ircaCurrent.Case_Creation_Completed__c: '+ircaCurrent.Case_Creation_Completed__c);
                System.debug(Logginglevel.INFO,'ircaCurrent.Case_Creation_End_Date__c: '+ircaCurrent.Case_Creation_End_Date__c);
                System.debug(Logginglevel.INFO,'ircaCurrent.Case_Creation_Status__c: '+ircaCurrent.Case_Creation_Status__c);
                System.assert(ircaCurrent.Case_Creation_Completed__c, 'Case creation completed');
                System.assert(ircaCurrent.Case_Creation_End_Date__c!=null, 'Case creation end date is not null');
                System.assertEquals('Success', ircaCurrent.Case_Creation_Status__c, 'Case creation status is success');

                List<Case> cases = [Select Id, Description, IR_Case_Type__c,IR_Invoice_Number__c  from Case where IR_Original_Contract_Id__c = :mch1.Id];
                System.debug(Logginglevel.INFO,'Cases created ***************************************************'+cases);

                 for (Case cs : [Select Id, IR_Case_Type__c, Description, IR_Invoice_Number__c  from Case where IR_Original_Contract_Id__c = :mch1.Id])
                 {
                  System.debug(Logginglevel.INFO,'cs.Description=========================================='+cs.Description);
                  System.debug(Logginglevel.INFO,'cs.IR_Case_Type__c=========================================='+cs.IR_Case_Type__c);
                  System.assert(!cs.Description.contains(data1[0].Alert_Line__c), 'Dsecription is not updated');
                  System.assertEquals(null, cs.IR_Case_Type__c, 'ir case type is null not updated');
                }

            }
        }

        static testMethod void withTwoAlertInfo()
        //scenario: there no exisiting case, and there are two info(from the view) records corresponding to the case having active flag false
        //expectation: the alert type and description is updated with both the corresponding alert Info
        {
            System.runAs(sysAdmin)
            {
                Account acc1 = SobjectRepository.getAccount();
                Merge_Contract_Header__c mch1Id = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
                Merge_Contract_Header__c mch1 = refreshContractHeader(mch1Id);

                Invoice_Review_Case_Audit__c ircaLast=createIRCARec(reviewDate,'IRCaseTest1277');
                ircaLast.Import_Start_Date__c = Datetime.now().addDays(-1);
                ircaLast.Import_Status__c = 'Success';
                ircaLast.Case_Creation_Completed__c=true;
                ircaLast.Import_End_Date__c = Datetime.now().addDays(-1);
                insert ircaLast;
                System.debug(Logginglevel.INFO,'Last import irca '+ircaLast.id);

                Invoice_Review_Case_Audit__c ircaCurrent=createIRCARec(reviewDate,'IRCaseTest1278');
                insert ircaCurrent;
                System.debug(Logginglevel.INFO,'inserted current irca'+ircaCurrent.id);


                Draft_Invoice__c di2=createDraftInvoice(acc1.Id, mch1.Name, '1304123770', reviewDate, 12000);
                di2.CI_Original_Contract_Id__c=mch1.Name;
                di2.Invoice_Review_Case_Audit__c=ircaCurrent.Id;
                insert di2;

                String alertName1 = 'PS_OVERAGE_NOMATCH';
                String alertName2 = 'PS_OVERAGE_ERROR';

                String uniqueID1 = mch1.Name + String.valueof(reviewDate) +alertName1;
                String uniqueID2 = mch1.Name + String.valueof(reviewDate) + alertName2;

                IR_Case_Info__c irci1 = createIRCaseInfoRecord(mch1, di2, uniqueID1);
                insert irci1;

                IR_Case_Info__c irci2 = createIRCaseInfoRecord(mch1, di2, uniqueID2);
                irci2.Alert_Description__c = 'some data ; PS_OVERAGE_ERROR ; some extra data';
        		    irci2.Alert_Line__c = 'some data ; PS_OVERAGE_ERROR ; some extra data';
        		    irci2.Alert_Name__c = 'PS_OVERAGE_ERROR';
                insert irci2;

                List<IR_Case_Info__c> data1 = [Select id, Order_Id__c, Active_Flag__c,Alert_Description__c, Alert_Line__c, Alert_Name__c, Billable_Invoice_Id__c,
                                              Invoice_Date__c from IR_Case_Info__c where Order_Id__c = :mch1.Name and Invoice_Date__c = :reviewDate];


                System.debug(Logginglevel.INFO,'Info inserted 1****************************************************'+data1[0]);
                System.debug(Logginglevel.INFO,'Info inserted 2****************************************************'+data1[1]);

                System.debug(Logginglevel.INFO,'di2.Original_Contract_Id__c '+di2.Original_Contract_Id__c);

                di2.hasAttachment__c=true;
                di2.isDuplicate__c = false;
                di2.Original_Contract_Id__c = mch1.Id;
                update di2;
                System.debug(Logginglevel.INFO,'draft inv------------------------------------------------------------------'+di2);

                    ircaCurrent.Import_End_Date__c=Datetime.now();
                    ircaCurrent.Import_Status__c='Success';
                    ircaCurrent.Trigger_Case_Creation__c = true;
                    update ircaCurrent;

                Test.startTest();
                List<Merge_Contract_Header__c> mchList1 = new List<Merge_Contract_Header__c>();
                for (Merge_Contract_Header__c mch : [SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,
                Effective_Start_Date__c,Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,
                Review_Date__c,Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Active__c=true AND Contract_Type__c != 'ISP' //2965556
                AND Locked__c=true AND Effective_End_Date__c >= :reviewDate.addMonths(-1) AND (Cancellation_Date__c=null OR Cancellation_Date__c >= :reviewDate.addMonths(-1)) //LIMIT 100])
                AND (Id=:mch1.Id)])
                {
                    mchList1.add(mch);
                }
                System.debug(Logginglevel.INFO,'mchList1 size=' + mchList1.size());
                System.debug(Logginglevel.INFO,'mchList1=' + mchList1);

                CaseTriggerClass.isIRCaseCreationInprogress=true;
                creationData(mchList1,ircaCurrent,ircaLast); //2965556

                Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));
                String query = 'SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,Effective_Start_Date__c,Currency__c,';
                   query += 'Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,Review_Date__c,';
                   query += 'Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Id  =\''+mch1.Id+'\''; //2965556
                   query += ' AND Active__c=true AND Contract_Type__c != \'ISP\''; // Order by End_Date__c DESC limit 1
                   query +=  ' AND Locked__c=true AND Effective_End_Date__c >= '+ IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + 'AND (Cancellation_Date__c=null OR Cancellation_Date__c >= ' + IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + ')';
                   query +=  ' Limit ' + batchSize;

                System.debug(Logginglevel.INFO,'Query=' + query);

                IRCaseCreationBatchable execIRCaseCreation = new IRCaseCreationBatchable(ircaCurrent, ircaLast);
                execIRCaseCreation.query=query;
                ID batchprocessid=Database.executeBatch(execIRCaseCreation,batchSize);
                System.debug(Logginglevel.INFO,'batchprocessid=' + batchprocessid);
                System.debug(Logginglevel.INFO,'--->');
                Test.stopTest();

                ircaCurrent = refreshIRCA(ircaCurrent);

                System.debug(Logginglevel.INFO,'ircaCurrent.Case_Creation_Completed__c: '+ircaCurrent.Case_Creation_Completed__c);
                System.debug(Logginglevel.INFO,'ircaCurrent.Case_Creation_End_Date__c: '+ircaCurrent.Case_Creation_End_Date__c);
                System.debug(Logginglevel.INFO,'ircaCurrent.Case_Creation_Status__c: '+ircaCurrent.Case_Creation_Status__c);
                System.assert(ircaCurrent.Case_Creation_Completed__c, 'Case creation is completed');
                System.assert(ircaCurrent.Case_Creation_End_Date__c!=null, 'Case creation end date is not null');
                System.assertEquals('Success', ircaCurrent.Case_Creation_Status__c, 'Case creation status is success');

                List<Case> cases = [Select Id, Description, IR_Case_Type__c,IR_Invoice_Number__c  from Case where IR_Original_Contract_Id__c = :mch1.Id];
                System.debug(Logginglevel.INFO,'Cases created ***************************************************'+cases);

                 for (Case cs : [Select Id, IR_Case_Type__c, Description, IR_Invoice_Number__c  from Case where IR_Original_Contract_Id__c = :mch1.Id])
                 {
                  System.debug(Logginglevel.INFO,'cs.Description=========================================='+cs.Description);
                  System.debug(Logginglevel.INFO,'cs.IR_Case_Type__c=========================================='+cs.IR_Case_Type__c);
                  System.assert(cs.Description.contains(data1[0].Alert_Line__c), 'description should contain alert line of alert1');
                  System.assert(cs.Description.contains(data1[1].Alert_Line__c), 'description should contain alert line of alert1');
                  System.assert(cs.IR_Case_Type__c.contains(data1[0].Alert_Name__c), 'ir case type contains alert name of alert1');
                  System.assert(cs.IR_Case_Type__c.contains(data1[1].Alert_Name__c), 'ir case type contains alert name of alert2');
                }

            }
        }

        static testMethod void withTwoAlertInfoTrueAndFalse()
        //scenario: there no exisiting case, and there are two info(from the view) records corresponding one with active flg true and other with flg as false
        //expectation: the alert type and description of the case is updated with only that record whose flg is true
        {
            System.runAs(sysAdmin)
            {
                Account acc1 = SobjectRepository.getAccount();
                Merge_Contract_Header__c mch1Id = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
                Merge_Contract_Header__c mch1 = refreshContractHeader(mch1Id);

                Invoice_Review_Case_Audit__c ircaLast=createIRCARec(reviewDate,'IRCaseTest1277');
                ircaLast.Import_Start_Date__c = Datetime.now().addDays(-1);
                ircaLast.Import_Status__c = 'Success';
                ircaLast.Case_Creation_Completed__c=true;
                ircaLast.Import_End_Date__c = Datetime.now().addDays(-1);
                insert ircaLast;
                System.debug(Logginglevel.INFO,'Last import irca '+ircaLast.id);

                Invoice_Review_Case_Audit__c ircaCurrent=createIRCARec(reviewDate,'IRCaseTest1278');
                insert ircaCurrent;
                System.debug(Logginglevel.INFO,'inserted current irca'+ircaCurrent.id);


                Draft_Invoice__c di2=createDraftInvoice(acc1.Id, mch1.Name, '1304123770', reviewDate, 12000);
                di2.CI_Original_Contract_Id__c=mch1.Name;
                di2.Invoice_Review_Case_Audit__c=ircaCurrent.Id;
                insert di2;

                String alertName1 = 'PS_OVERAGE_NOMATCH';
                String alertName2 = 'PS_OVERAGE_ERROR';

                String uniqueID1 = mch1.Name + String.valueof(reviewDate) +alertName1;
                String uniqueID2 = mch1.Name + String.valueof(reviewDate) + alertName2;

                IR_Case_Info__c irci1 = createIRCaseInfoRecord(mch1, di2, uniqueID1);
                insert irci1;

                IR_Case_Info__c irci2 = createIRCaseInfoRecord(mch1, di2, uniqueID2);
                irci2.Alert_Description__c = 'some data ; PS_OVERAGE_ERROR ; some extra data';
        		    irci2.Alert_Line__c = 'some data ; PS_OVERAGE_ERROR ; some extra data';
        		    irci2.Alert_Name__c = 'PS_OVERAGE_ERROR';
                irci2.Active_Flag__c = false;
                insert irci2;

                List<IR_Case_Info__c> data1 = [Select id, Order_Id__c, Active_Flag__c,Alert_Description__c, Alert_Line__c, Alert_Name__c, Billable_Invoice_Id__c,
                                              Invoice_Date__c from IR_Case_Info__c where Order_Id__c = :mch1.Name and Invoice_Date__c = :reviewDate];


                System.debug(Logginglevel.INFO,'Info inserted 1****************************************************'+data1[0]);
                System.debug(Logginglevel.INFO,'Info inserted 2****************************************************'+data1[1]);

                System.debug(Logginglevel.INFO,'di2.Original_Contract_Id__c '+di2.Original_Contract_Id__c);

                di2.hasAttachment__c=true;
                di2.isDuplicate__c = false;
                di2.Original_Contract_Id__c = mch1.Id;
                update di2;
                System.debug(Logginglevel.INFO,'draft inv------------------------------------------------------------------'+di2);

                    ircaCurrent.Import_End_Date__c=Datetime.now();
                    ircaCurrent.Import_Status__c='Success';
                    ircaCurrent.Trigger_Case_Creation__c = true;
                    update ircaCurrent;

                Test.startTest();
                List<Merge_Contract_Header__c> mchList1 = new List<Merge_Contract_Header__c>();
                for (Merge_Contract_Header__c mch : [SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,
                Effective_Start_Date__c,Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,
                Review_Date__c,Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Active__c=true AND Contract_Type__c != 'ISP' //2965556
                AND Locked__c=true AND Effective_End_Date__c >= :reviewDate.addMonths(-1) AND (Cancellation_Date__c=null OR Cancellation_Date__c >= :reviewDate.addMonths(-1)) //LIMIT 100])
                AND (Id=:mch1.Id)])
                {
                    mchList1.add(mch);
                }
                System.debug(Logginglevel.INFO,'mchList1 size=' + mchList1.size());
                System.debug(Logginglevel.INFO,'mchList1=' + mchList1);

                CaseTriggerClass.isIRCaseCreationInprogress=true;
                creationData(mchList1,ircaCurrent,ircaLast); //2965556

                Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));
                String query = 'SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,Effective_Start_Date__c,Currency__c,';
                   query += 'Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,Review_Date__c,';
                   query += 'Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Id  =\''+mch1.Id+'\''; //2965556
                   query += ' AND Active__c=true AND Contract_Type__c != \'ISP\''; // Order by End_Date__c DESC limit 1
                   query +=  ' AND Locked__c=true AND Effective_End_Date__c >= '+ IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + 'AND (Cancellation_Date__c=null OR Cancellation_Date__c >= ' + IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + ')';
                   query +=  ' Limit ' + batchSize;

                System.debug(Logginglevel.INFO,'Query=' + query);

                IRCaseCreationBatchable execIRCaseCreation = new IRCaseCreationBatchable(ircaCurrent, ircaLast);
                execIRCaseCreation.query=query;
                ID batchprocessid=Database.executeBatch(execIRCaseCreation,batchSize);
                System.debug(Logginglevel.INFO,'batchprocessid=' + batchprocessid);
                System.debug(Logginglevel.INFO,'--->');
                Test.stopTest();

                ircaCurrent = refreshIRCA(ircaCurrent);

                System.debug(Logginglevel.INFO,'ircaCurrent.Case_Creation_Completed__c: '+ircaCurrent.Case_Creation_Completed__c);
                System.debug(Logginglevel.INFO,'ircaCurrent.Case_Creation_End_Date__c: '+ircaCurrent.Case_Creation_End_Date__c);
                System.debug(Logginglevel.INFO,'ircaCurrent.Case_Creation_Status__c: '+ircaCurrent.Case_Creation_Status__c);
                System.assert(ircaCurrent.Case_Creation_Completed__c, 'case creation is completed');
                System.assert(ircaCurrent.Case_Creation_End_Date__c!=null, 'case creation end date is not null');
                System.assertEquals('Success', ircaCurrent.Case_Creation_Status__c, 'Case creation status is success');

                List<Case> cases = [Select Id, Description, IR_Case_Type__c,IR_Invoice_Number__c  from Case where IR_Original_Contract_Id__c = :mch1.Id];
                System.debug(Logginglevel.INFO,'Cases created ***************************************************'+cases);

                 for (Case cs : [Select Id, IR_Case_Type__c, Description, IR_Invoice_Number__c  from Case where IR_Original_Contract_Id__c = :mch1.Id])
                 {
                  System.debug(Logginglevel.INFO,'cs.Description=========================================='+cs.Description);
                  System.debug(Logginglevel.INFO,'cs.IR_Case_Type__c=========================================='+cs.IR_Case_Type__c);
                  System.assert(cs.Description.contains(data1[0].Alert_Line__c), 'Description contains alert line of alert1');
                  System.assert(!cs.Description.contains(data1[1].Alert_Line__c), 'Description does not contains alert line of alert2');
                  System.assertEquals(data1[0].Alert_Name__c, cs.IR_Case_Type__c, 'IR case type is updated with alert name of alert1');
                }

            }
        }

        static testMethod void withExistingCaseOneInfo()
        //scenario: there is exisiting case, and there is one info(from the view) records corresponding one with active flg true
        //expectation: the alert type and description of the case is updated for the existing case
        {
            System.runAs(sysAdmin)
            {
                Account acc1 = SobjectRepository.getAccount();
                Opportunity opp1 = SobjectRepository.getOpportunity();
                Merge_Contract_Header__c mch1Id = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
                Merge_Contract_Header__c mch1 = refreshContractHeader(mch1Id);

                Invoice_Review_Case_Audit__c ircaLast=createIRCARec(reviewDate,'IRCaseTest1277');
                ircaLast.Import_Start_Date__c = Datetime.now().addDays(-1);
                ircaLast.Import_Status__c = 'Success';
                ircaLast.Case_Creation_Completed__c=true;
                ircaLast.Import_End_Date__c = Datetime.now().addDays(-1);
                insert ircaLast;
                System.debug(Logginglevel.INFO,'Last import irca '+ircaLast.id);

                Invoice_Review_Case_Audit__c ircaCurrent=createIRCARec(reviewDate,'IRCaseTest1278');
                insert ircaCurrent;
                System.debug(Logginglevel.INFO,'inserted current irca'+ircaCurrent.id);


                Draft_Invoice__c di2=createDraftInvoice(acc1.Id, mch1.Name, '1304123770', reviewDate, 12000);
                di2.CI_Original_Contract_Id__c=mch1.Name;
                di2.Invoice_Review_Case_Audit__c=ircaCurrent.Id;
                insert di2;

                String alertName1 = 'PS_OVERAGE_NOMATCH';
                String uniqueID1 = mch1.Name + String.valueof(reviewDate) +alertName1;

                IR_Case_Info__c irci1 = createIRCaseInfoRecord(mch1, di2, uniqueID1);
                insert irci1;

                List<IR_Case_Info__c> data1 = [Select id, Order_Id__c, Active_Flag__c,Alert_Description__c, Alert_Line__c, Alert_Name__c, Billable_Invoice_Id__c,
                                              Invoice_Date__c from IR_Case_Info__c where Order_Id__c = :mch1.Name and Invoice_Date__c = :reviewDate];

                System.debug(Logginglevel.INFO,'Info inserted 1****************************************************'+data1[0]);

                System.debug(Logginglevel.INFO,'di2.Original_Contract_Id__c '+di2.Original_Contract_Id__c);

                di2.hasAttachment__c=true;
                di2.isDuplicate__c = false;
                di2.Original_Contract_Id__c = mch1.Id;
                update di2;
                System.debug(Logginglevel.INFO,'draft inv------------------------------------------------------------------'+di2);

                ircaCurrent.Import_End_Date__c=Datetime.now();
                ircaCurrent.Import_Status__c='Success';
                ircaCurrent.Trigger_Case_Creation__c = true;
                update ircaCurrent;

                User newOwnerRSM = GetUser('TST_NRSM');
                Case existingCase = createInvoiceCase (di2.Name, reviewDate, acc1.Id, opp1.Id , mch1.Id, newOwnerRSM.Id);
                existingCase.Description = 'some existing description';
                insert existingCase;
                System.debug(Logginglevel.INFO,'existing case---------------------------------------------------------------'+existingCase);


                Test.startTest();
                List<Merge_Contract_Header__c> mchList1 = new List<Merge_Contract_Header__c>();
                for (Merge_Contract_Header__c mch : [SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,
                Effective_Start_Date__c,Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,
                Review_Date__c,Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Active__c=true AND Contract_Type__c != 'ISP' //2965556
                AND Locked__c=true AND Effective_End_Date__c >= :reviewDate.addMonths(-1) AND (Cancellation_Date__c=null OR Cancellation_Date__c >= :reviewDate.addMonths(-1)) //LIMIT 100])
                AND (Id=:mch1.Id)])
                {
                    mchList1.add(mch);
                }
                System.debug(Logginglevel.INFO,'mchList1 size=' + mchList1.size());
                System.debug(Logginglevel.INFO,'mchList1=' + mchList1);

                CaseTriggerClass.isIRCaseCreationInprogress=true;
                creationData(mchList1,ircaCurrent,ircaLast); //2965556

                Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));
                String query = 'SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,Effective_Start_Date__c,Currency__c,';
                   query += 'Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,Review_Date__c,';
                   query += 'Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Id  =\''+mch1.Id+'\''; //2965556
                   query += ' AND Active__c=true AND Contract_Type__c != \'ISP\''; // Order by End_Date__c DESC limit 1
                   query +=  ' AND Locked__c=true AND Effective_End_Date__c >= '+ IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + 'AND (Cancellation_Date__c=null OR Cancellation_Date__c >= ' + IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + ')';
                   query +=  ' Limit ' + batchSize;

                System.debug(Logginglevel.INFO,'Query=' + query);

                IRCaseCreationBatchable execIRCaseCreation = new IRCaseCreationBatchable(ircaCurrent, ircaLast);
                execIRCaseCreation.query=query;
                ID batchprocessid=Database.executeBatch(execIRCaseCreation,batchSize);
                System.debug(Logginglevel.INFO,'batchprocessid=' + batchprocessid);
                System.debug(Logginglevel.INFO,'--->');
                Test.stopTest();

                ircaCurrent = refreshIRCA(ircaCurrent);

                System.debug(Logginglevel.INFO,'ircaCurrent.Case_Creation_Completed__c: '+ircaCurrent.Case_Creation_Completed__c);
                System.debug(Logginglevel.INFO,'ircaCurrent.Case_Creation_End_Date__c: '+ircaCurrent.Case_Creation_End_Date__c);
                System.debug(Logginglevel.INFO,'ircaCurrent.Case_Creation_Status__c: '+ircaCurrent.Case_Creation_Status__c);
                System.assert(ircaCurrent.Case_Creation_Completed__c, 'Case creation completed');
                System.assert(ircaCurrent.Case_Creation_End_Date__c!=null, 'Case creation end date is not null');
                System.assertEquals('Success', ircaCurrent.Case_Creation_Status__c, 'Case creation status is success');
                System.debug(Logginglevel.INFO,'existing case after updation---------------------------------------------------------------'+existingCase);

                List<Case> updatedCases = [Select Id, Description, IR_Case_Type__c,IR_Invoice_Number__c  from Case where Id = :existingCase.Id];
                System.debug(Logginglevel.INFO,'Cases created ***************************************************'+updatedCases);

                System.assert(updatedCases[0].Description.contains(data1[0].Alert_Line__c), 'Description contains alert line of alert1');
                System.assert(updatedCases[0].IR_Case_Type__c.contains(data1[0].Alert_Name__c), 'Ir case type contains the alert name of alert1');
                System.assertEquals(di2.Name, updatedCases[0].IR_Invoice_Number__c, 'draft inv is associated with case');

            }
        }

        static testMethod void withExistingCaseWithExistingInfo()
        //scenario: there is exisiting case which already has alert1 and there is one info(from the view) corresponding to alert1 one with active flg false
        //expectation: the alert type remains the same and description of the case the messages wrt alert1 is replaced with new message
        // eg: case has description : 'some data\n old data ; PS_OVERAGE_ERROR ; old extra data';
        // alert has description : 'new data ; PS_OVERAGE_ERROR ; new extra data';
        // after case updation:  'some data\n new data ; PS_OVERAGE_ERROR ; new extra data';
        {
            System.runAs(sysAdmin)
            {
                Account acc1 = SobjectRepository.getAccount();
                Opportunity opp1 = SobjectRepository.getOpportunity();
                Merge_Contract_Header__c mch1Id = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
                Merge_Contract_Header__c mch1 = refreshContractHeader(mch1Id);

                Invoice_Review_Case_Audit__c ircaLast=createIRCARec(reviewDate,'IRCaseTest1277');
                ircaLast.Import_Start_Date__c = Datetime.now().addDays(-1);
                ircaLast.Import_Status__c = 'Success';
                ircaLast.Case_Creation_Completed__c=true;
                ircaLast.Import_End_Date__c = Datetime.now().addDays(-1);
                insert ircaLast;
                System.debug(Logginglevel.INFO,'Last import irca '+ircaLast.id);

                Invoice_Review_Case_Audit__c ircaCurrent=createIRCARec(reviewDate,'IRCaseTest1278');
                insert ircaCurrent;
                System.debug(Logginglevel.INFO,'inserted current irca'+ircaCurrent.id);


                Draft_Invoice__c di2=createDraftInvoice(acc1.Id, mch1.Name, '1304123770', reviewDate, 12000);
                di2.CI_Original_Contract_Id__c=mch1.Name;
                di2.Invoice_Review_Case_Audit__c=ircaCurrent.Id;
                insert di2;

                String alertName1 = 'PS_OVERAGE_NOMATCH';
                String uniqueID1 = mch1.Name + String.valueof(reviewDate) +alertName1;

                IR_Case_Info__c irci1 = createIRCaseInfoRecord(mch1, di2, uniqueID1);
                irci1.Alert_Description__c = 'new data ; PS_OVERAGE_ERROR ; new extra data';
        		    irci1.Alert_Line__c = 'new data ; PS_OVERAGE_ERROR ; new extra data';
        		    irci1.Alert_Name__c = 'PS_OVERAGE_ERROR';
                insert irci1;

                List<IR_Case_Info__c> data1 = [Select id, Order_Id__c, Active_Flag__c,Alert_Description__c, Alert_Line__c, Alert_Name__c, Billable_Invoice_Id__c,
                                              Invoice_Date__c from IR_Case_Info__c where Order_Id__c = :mch1.Name and Invoice_Date__c = :reviewDate];

                System.debug(Logginglevel.INFO,'Info inserted 1****************************************************'+data1[0]);

                System.debug(Logginglevel.INFO,'di2.Original_Contract_Id__c '+di2.Original_Contract_Id__c);

                di2.hasAttachment__c=true;
                di2.isDuplicate__c = false;
                di2.Original_Contract_Id__c = mch1.Id;
                update di2;
                System.debug(Logginglevel.INFO,'draft inv------------------------------------------------------------------'+di2);

                ircaCurrent.Import_End_Date__c=Datetime.now();
                ircaCurrent.Import_Status__c='Success';
                ircaCurrent.Trigger_Case_Creation__c = true;
                update ircaCurrent;

                User newOwnerRSM = GetUser('TST_NRSM');
                Case existingCase = createInvoiceCase (di2.Name, reviewDate, acc1.Id, opp1.Id , mch1.Id, newOwnerRSM.Id);
                String existingAlertDescription = 'old data ; PS_OVERAGE_ERROR ; old extra data';
                String existingDescription1 = 'some existing description';
                String existingDescription2 = 'some extra existing data';
                existingCase.Description = existingDescription1 + '\n' + existingAlertDescription +'\n'+ existingDescription2;
                existingCase.IR_Case_Type__c = 'PS_OVERAGE_ERROR';
                insert existingCase;
                System.debug(Logginglevel.INFO,'existing case---------------------------------------------------------------'+existingCase);


                Test.startTest();
                List<Merge_Contract_Header__c> mchList1 = new List<Merge_Contract_Header__c>();
                for (Merge_Contract_Header__c mch : [SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,
                Effective_Start_Date__c,Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,
                Review_Date__c,Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Active__c=true AND Contract_Type__c != 'ISP' //2965556
                AND Locked__c=true AND Effective_End_Date__c >= :reviewDate.addMonths(-1) AND (Cancellation_Date__c=null OR Cancellation_Date__c >= :reviewDate.addMonths(-1)) //LIMIT 100])
                AND (Id=:mch1.Id)])
                {
                    mchList1.add(mch);
                }
                System.debug(Logginglevel.INFO,'mchList1 size=' + mchList1.size());
                System.debug(Logginglevel.INFO,'mchList1=' + mchList1);

                CaseTriggerClass.isIRCaseCreationInprogress=true;
                creationData(mchList1,ircaCurrent,ircaLast); //2965556

                Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));
                String query = 'SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,Effective_Start_Date__c,Currency__c,';
                   query += 'Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,Review_Date__c,';
                   query += 'Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Id  =\''+mch1.Id+'\''; //2965556
                   query += ' AND Active__c=true AND Contract_Type__c != \'ISP\''; // Order by End_Date__c DESC limit 1
                   query +=  ' AND Locked__c=true AND Effective_End_Date__c >= '+ IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + 'AND (Cancellation_Date__c=null OR Cancellation_Date__c >= ' + IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + ')';
                   query +=  ' Limit ' + batchSize;

                System.debug(Logginglevel.INFO,'Query=' + query);

                IRCaseCreationBatchable execIRCaseCreation = new IRCaseCreationBatchable(ircaCurrent, ircaLast);
                execIRCaseCreation.query=query;
                ID batchprocessid=Database.executeBatch(execIRCaseCreation,batchSize);
                System.debug(Logginglevel.INFO,'batchprocessid=' + batchprocessid);
                System.debug(Logginglevel.INFO,'--->');
                Test.stopTest();

                ircaCurrent = refreshIRCA(ircaCurrent);

                System.debug(Logginglevel.INFO,'ircaCurrent.Case_Creation_Completed__c: '+ircaCurrent.Case_Creation_Completed__c);
                System.debug(Logginglevel.INFO,'ircaCurrent.Case_Creation_End_Date__c: '+ircaCurrent.Case_Creation_End_Date__c);
                System.debug(Logginglevel.INFO,'ircaCurrent.Case_Creation_Status__c: '+ircaCurrent.Case_Creation_Status__c);
                System.assert(ircaCurrent.Case_Creation_Completed__c, 'Case Creation is completed');
                System.assert(ircaCurrent.Case_Creation_End_Date__c!=null, 'Case creation end date is not null');
                System.assertEquals('Success', ircaCurrent.Case_Creation_Status__c, 'Case creation status is success');
                System.debug(Logginglevel.INFO,'existing case after updation---------------------------------------------------------------'+existingCase);

                List<Case> updatedCases = [Select Id, Description, IR_Case_Type__c,IR_Invoice_Number__c  from Case where Id = :existingCase.Id];
                System.debug(Logginglevel.INFO,'Cases created ***************************************************'+updatedCases);

                System.assert(updatedCases[0].Description.contains(data1[0].Alert_Line__c), 'description contains the alert line of alert1');
                System.assert(updatedCases[0].IR_Case_Type__c.contains(data1[0].Alert_Name__c), 'ir case type contains the alert name of alert1');
                System.assert(!updatedCases[0].Description.contains(existingAlertDescription), 'the existing description wrt to alert1 is replaced');
                System.assert(updatedCases[0].Description.contains(existingDescription1), 'the existing description remains');
                System.assert(updatedCases[0].Description.contains(existingDescription2), 'the existing description remains');

            }
        }

        static testMethod void withExistingCaseWithExistingTwoInfo()
        //scenario: there is exisiting case which already has both alert1 and alert2 there is two info(from the view)
        //corresponding to alert1 with active flg as true and alert2 one with active flg false
        //expectation: the alert type remains the same and description for both should get updated
        // eg: case has description : 'some data\n old data ; PS_OVERAGE_ERROR ; old extra data\n new data ; PS_OVERAGE_NOMATCH ; new extra data';
        // alert1 has description : 'new data ; PS_OVERAGE_ERROR ; new extra data';
        // alert2 has description : 'new data ; PS_OVERAGE_NOMATCH ; new extra data';
        // after case updation:  'some data\n new data ; PS_OVERAGE_ERROR ; new extra data'\n new data ; PS_OVERAGE_NOMATCH ; new extra data';
        {
            System.runAs(sysAdmin)
            {
                Account acc1 = SobjectRepository.getAccount();
                Opportunity opp1 = SobjectRepository.getOpportunity();
                Merge_Contract_Header__c mch1Id = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
                Merge_Contract_Header__c mch1 = refreshContractHeader(mch1Id);

                Invoice_Review_Case_Audit__c ircaLast=createIRCARec(reviewDate,'IRCaseTest1277');
                ircaLast.Import_Start_Date__c = Datetime.now().addDays(-1);
                ircaLast.Import_Status__c = 'Success';
                ircaLast.Case_Creation_Completed__c=true;
                ircaLast.Import_End_Date__c = Datetime.now().addDays(-1);
                insert ircaLast;
                System.debug(Logginglevel.INFO,'Last import irca '+ircaLast.id);

                Invoice_Review_Case_Audit__c ircaCurrent=createIRCARec(reviewDate,'IRCaseTest1278');
                insert ircaCurrent;
                System.debug(Logginglevel.INFO,'inserted current irca'+ircaCurrent.id);


                Draft_Invoice__c di2=createDraftInvoice(acc1.Id, mch1.Name, '1304123770', reviewDate, 12000);
                di2.CI_Original_Contract_Id__c=mch1.Name;
                di2.Invoice_Review_Case_Audit__c=ircaCurrent.Id;
                insert di2;

                String alertName1 = 'PS_OVERAGE_NOMATCH';
                String uniqueID1 = mch1.Name + String.valueof(reviewDate) +alertName1;
                String alertName2 = 'PS_OVERAGE_ERROR';
                String uniqueID2 = mch1.Name + String.valueof(reviewDate) +alertName2;

                IR_Case_Info__c irci1 = createIRCaseInfoRecord(mch1, di2, uniqueID1);
                irci1.Alert_Description__c = 'new data ; PS_OVERAGE_ERROR ; new extra data';
        		    irci1.Alert_Line__c = 'new data ; PS_OVERAGE_ERROR ; new extra data';
        		    irci1.Alert_Name__c = 'PS_OVERAGE_ERROR';
                irci1.Active_Flag__c = true;
                insert irci1;

                IR_Case_Info__c irci2 = createIRCaseInfoRecord(mch1, di2, uniqueID2);
                irci2.Alert_Description__c = 'new data ; PS_OVERAGE_NOMATCH ; new extra data';
        		    irci2.Alert_Line__c = 'new data ; PS_OVERAGE_NOMATCH ; new extra data';
        		    irci2.Alert_Name__c = 'PS_OVERAGE_NOMATCH';
                irci2.Active_Flag__c = false;

                insert irci2;

                List<IR_Case_Info__c> data1 = [Select id, Order_Id__c, Active_Flag__c,Alert_Description__c, Alert_Line__c, Alert_Name__c, Billable_Invoice_Id__c,
                                              Invoice_Date__c from IR_Case_Info__c where Order_Id__c = :mch1.Name and Invoice_Date__c = :reviewDate];

                System.debug(Logginglevel.INFO,'Info inserted 1****************************************************'+data1[0]);
                System.debug(Logginglevel.INFO,'Info inserted 2****************************************************'+data1[1]);

                System.debug(Logginglevel.INFO,'di2.Original_Contract_Id__c '+di2.Original_Contract_Id__c);

                di2.hasAttachment__c=true;
                di2.isDuplicate__c = false;
                di2.Original_Contract_Id__c = mch1.Id;
                update di2;
                System.debug(Logginglevel.INFO,'draft inv------------------------------------------------------------------'+di2);

                ircaCurrent.Import_End_Date__c=Datetime.now();
                ircaCurrent.Import_Status__c='Success';
                ircaCurrent.Trigger_Case_Creation__c = true;
                update ircaCurrent;

                User newOwnerRSM = GetUser('TST_NRSM');
                Case existingCase = createInvoiceCase (di2.Name, reviewDate, acc1.Id, opp1.Id , mch1.Id, newOwnerRSM.Id);
                String existingAlertDescription1 = 'old data ; PS_OVERAGE_ERROR ; old extra data';
                String existingAlertDescription2 = 'old data ; PS_OVERAGE_NOMATCH ; old extra data';
                String existingDescription1 = 'some existing description';
                String existingDescription2 = 'some extra existing data';
                existingCase.Description = existingDescription1 + '\n' + existingAlertDescription1 +'\n'+ existingAlertDescription2+'\n'+existingDescription2;
                existingCase.IR_Case_Type__c = 'PS_OVERAGE_ERROR;PS_OVERAGE_NOMATCH';
                insert existingCase;
                System.debug(Logginglevel.INFO,'existing case---------------------------------------------------------------'+existingCase);


                Test.startTest();
                List<Merge_Contract_Header__c> mchList1 = new List<Merge_Contract_Header__c>();
                for (Merge_Contract_Header__c mch : [SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,
                Effective_Start_Date__c,Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,
                Review_Date__c,Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Active__c=true AND Contract_Type__c != 'ISP' //2965556
                AND Locked__c=true AND Effective_End_Date__c >= :reviewDate.addMonths(-1) AND (Cancellation_Date__c=null OR Cancellation_Date__c >= :reviewDate.addMonths(-1)) //LIMIT 100])
                AND (Id=:mch1.Id)])
                {
                    mchList1.add(mch);
                }
                System.debug(Logginglevel.INFO,'mchList1 size=' + mchList1.size());
                System.debug(Logginglevel.INFO,'mchList1=' + mchList1);

                CaseTriggerClass.isIRCaseCreationInprogress=true;
                creationData(mchList1,ircaCurrent,ircaLast); //2965556

                Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));
                String query = 'SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,Effective_Start_Date__c,Currency__c,';
                   query += 'Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,Review_Date__c,';
                   query += 'Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Id  =\''+mch1.Id+'\''; //2965556
                   query += ' AND Active__c=true AND Contract_Type__c != \'ISP\''; // Order by End_Date__c DESC limit 1
                   query +=  ' AND Locked__c=true AND Effective_End_Date__c >= '+ IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + 'AND (Cancellation_Date__c=null OR Cancellation_Date__c >= ' + IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + ')';
                   query +=  ' Limit ' + batchSize;

                System.debug(Logginglevel.INFO,'Query=' + query);

                IRCaseCreationBatchable execIRCaseCreation = new IRCaseCreationBatchable(ircaCurrent, ircaLast);
                execIRCaseCreation.query=query;
                ID batchprocessid=Database.executeBatch(execIRCaseCreation,batchSize);
                System.debug(Logginglevel.INFO,'batchprocessid=' + batchprocessid);
                System.debug(Logginglevel.INFO,'--->');
                Test.stopTest();

                ircaCurrent = refreshIRCA(ircaCurrent);

                System.debug(Logginglevel.INFO,'ircaCurrent.Case_Creation_Completed__c: '+ircaCurrent.Case_Creation_Completed__c);
                System.debug(Logginglevel.INFO,'ircaCurrent.Case_Creation_End_Date__c: '+ircaCurrent.Case_Creation_End_Date__c);
                System.debug(Logginglevel.INFO,'ircaCurrent.Case_Creation_Status__c: '+ircaCurrent.Case_Creation_Status__c);
                System.assert(ircaCurrent.Case_Creation_Completed__c, 'Case creation completed');
                System.assert(ircaCurrent.Case_Creation_End_Date__c!=null, 'Case creation end date is not null');
                System.assertEquals('Success', ircaCurrent.Case_Creation_Status__c, 'Case creation status is success');
                System.debug(Logginglevel.INFO,'existing case after updation---------------------------------------------------------------'+existingCase);

                List<Case> updatedCases = [Select Id, Description, IR_Case_Type__c,IR_Invoice_Number__c  from Case where Id = :existingCase.Id];
                System.debug(Logginglevel.INFO,'Cases created ***************************************************'+updatedCases);

                System.assert(updatedCases[0].Description.contains(data1[0].Alert_Line__c), 'description contains the alert line of alert1');
                System.assert(updatedCases[0].Description.contains(data1[1].Alert_Line__c), 'description contains the alert line of alert2');
                System.assert(updatedCases[0].IR_Case_Type__c.contains(data1[0].Alert_Name__c), 'ir case type contains the alert name of alert1');
                System.assert(updatedCases[0].IR_Case_Type__c.contains(data1[1].Alert_Name__c), 'ir case type contains the alert name of alert2');
                System.assert(!updatedCases[0].Description.contains(existingAlertDescription1), 'the existing description wrt to alert1 is replaced');
                System.assert(!updatedCases[0].Description.contains(existingAlertDescription2), 'the existing description wrt to alert2 is replaced');
                System.assert(updatedCases[0].Description.contains(existingDescription1), 'the existing description remains');
                System.assert(updatedCases[0].Description.contains(existingDescription2), 'the existing description remains');

            }
        }

        static testMethod void existingCaseWithOneExistingInfo()
        //scenario: there is exisiting case which already has both alert1, there are two info(from the view)
        //corresponding to alert1 with active flg as true and alert2 one with active flg false
        //expectation: the alert type remains the same and description for alert1 is replaced but alert2 is not at all added
        // as there is no existing type already and the flg is false
        {
            System.runAs(sysAdmin)
            {
                Account acc1 = SobjectRepository.getAccount();
                Opportunity opp1 = SobjectRepository.getOpportunity();
                Merge_Contract_Header__c mch1Id = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
                Merge_Contract_Header__c mch1 = refreshContractHeader(mch1Id);

                Invoice_Review_Case_Audit__c ircaLast=createIRCARec(reviewDate,'IRCaseTest1277');
                ircaLast.Import_Start_Date__c = Datetime.now().addDays(-1);
                ircaLast.Import_Status__c = 'Success';
                ircaLast.Case_Creation_Completed__c=true;
                ircaLast.Import_End_Date__c = Datetime.now().addDays(-1);
                insert ircaLast;
                System.debug(Logginglevel.INFO,'Last import irca '+ircaLast.id);

                Invoice_Review_Case_Audit__c ircaCurrent=createIRCARec(reviewDate,'IRCaseTest1278');
                insert ircaCurrent;
                System.debug(Logginglevel.INFO,'inserted current irca'+ircaCurrent.id);


                Draft_Invoice__c di2=createDraftInvoice(acc1.Id, mch1.Name, '1304123770', reviewDate, 12000);
                di2.CI_Original_Contract_Id__c=mch1.Name;
                di2.Invoice_Review_Case_Audit__c=ircaCurrent.Id;
                insert di2;

                String alertName1 = 'PS_OVERAGE_NOMATCH';
                String uniqueID1 = mch1.Name + String.valueof(reviewDate) +alertName1;
                String alertName2 = 'PS_OVERAGE_ERROR';
                String uniqueID2 = mch1.Name + String.valueof(reviewDate) +alertName2;

                IR_Case_Info__c irci1 = createIRCaseInfoRecord(mch1, di2, uniqueID1);
                irci1.Alert_Description__c = 'new data ; PS_OVERAGE_ERROR ; new extra data';
        		    irci1.Alert_Line__c = 'new data ; PS_OVERAGE_ERROR ; new extra data';
        		    irci1.Alert_Name__c = 'PS_OVERAGE_ERROR';
                irci1.Active_Flag__c = true;
                insert irci1;

                IR_Case_Info__c irci2 = createIRCaseInfoRecord(mch1, di2, uniqueID2);
                irci2.Alert_Description__c = 'new data ; PS_OVERAGE_NOMATCH ; new extra data';
        		    irci2.Alert_Line__c = 'new data ; PS_OVERAGE_NOMATCH ; new extra data';
        		    irci2.Alert_Name__c = 'PS_OVERAGE_NOMATCH';
                irci2.Active_Flag__c = false;

                insert irci2;

                List<IR_Case_Info__c> data1 = [Select id, Order_Id__c, Active_Flag__c,Alert_Description__c, Alert_Line__c, Alert_Name__c, Billable_Invoice_Id__c,
                                              Invoice_Date__c from IR_Case_Info__c where Order_Id__c = :mch1.Name and Invoice_Date__c = :reviewDate];

                System.debug(Logginglevel.INFO,'Info inserted 1****************************************************'+data1[0]);
                System.debug(Logginglevel.INFO,'Info inserted 2****************************************************'+data1[1]);

                System.debug(Logginglevel.INFO,'di2.Original_Contract_Id__c '+di2.Original_Contract_Id__c);

                di2.hasAttachment__c=true;
                di2.isDuplicate__c = false;
                di2.Original_Contract_Id__c = mch1.Id;
                update di2;
                System.debug(Logginglevel.INFO,'draft inv------------------------------------------------------------------'+di2);

                ircaCurrent.Import_End_Date__c=Datetime.now();
                ircaCurrent.Import_Status__c='Success';
                ircaCurrent.Trigger_Case_Creation__c = true;
                update ircaCurrent;

                User newOwnerRSM = GetUser('TST_NRSM');
                Case existingCase = createInvoiceCase (di2.Name, reviewDate, acc1.Id, opp1.Id , mch1.Id, newOwnerRSM.Id);
                String existingAlertDescription1 = 'old data ; PS_OVERAGE_ERROR ; old extra data';
                String existingDescription1 = 'some existing description';
                String existingDescription2 = 'some extra existing data';
                existingCase.Description = existingDescription1 + '\n' + existingAlertDescription1 + '\n'+existingDescription2;
                existingCase.IR_Case_Type__c = 'PS_OVERAGE_ERROR';
                insert existingCase;
                System.debug(Logginglevel.INFO,'existing case---------------------------------------------------------------'+existingCase);


                Test.startTest();
                List<Merge_Contract_Header__c> mchList1 = new List<Merge_Contract_Header__c>();
                for (Merge_Contract_Header__c mch : [SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,
                Effective_Start_Date__c,Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,
                Review_Date__c,Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Active__c=true AND Contract_Type__c != 'ISP' //2965556
                AND Locked__c=true AND Effective_End_Date__c >= :reviewDate.addMonths(-1) AND (Cancellation_Date__c=null OR Cancellation_Date__c >= :reviewDate.addMonths(-1)) //LIMIT 100])
                AND (Id=:mch1.Id)])
                {
                    mchList1.add(mch);
                }
                System.debug(Logginglevel.INFO,'mchList1 size=' + mchList1.size());
                System.debug(Logginglevel.INFO,'mchList1=' + mchList1);

                CaseTriggerClass.isIRCaseCreationInprogress=true;
                creationData(mchList1,ircaCurrent,ircaLast); //2965556

                Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));
                String query = 'SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,Effective_Start_Date__c,Currency__c,';
                   query += 'Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,Review_Date__c,';
                   query += 'Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Id  =\''+mch1.Id+'\''; //2965556
                   query += ' AND Active__c=true AND Contract_Type__c != \'ISP\''; // Order by End_Date__c DESC limit 1
                   query +=  ' AND Locked__c=true AND Effective_End_Date__c >= '+ IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + 'AND (Cancellation_Date__c=null OR Cancellation_Date__c >= ' + IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + ')';
                   query +=  ' Limit ' + batchSize;

                System.debug(Logginglevel.INFO,'Query=' + query);

                IRCaseCreationBatchable execIRCaseCreation = new IRCaseCreationBatchable(ircaCurrent, ircaLast);
                execIRCaseCreation.query=query;
                ID batchprocessid=Database.executeBatch(execIRCaseCreation,batchSize);
                System.debug(Logginglevel.INFO,'batchprocessid=' + batchprocessid);
                System.debug(Logginglevel.INFO,'--->');
                Test.stopTest();

                ircaCurrent = refreshIRCA(ircaCurrent);

                System.debug(Logginglevel.INFO,'ircaCurrent.Case_Creation_Completed__c: '+ircaCurrent.Case_Creation_Completed__c);
                System.debug(Logginglevel.INFO,'ircaCurrent.Case_Creation_End_Date__c: '+ircaCurrent.Case_Creation_End_Date__c);
                System.debug(Logginglevel.INFO,'ircaCurrent.Case_Creation_Status__c: '+ircaCurrent.Case_Creation_Status__c);
                System.assert(ircaCurrent.Case_Creation_Completed__c, 'Case creation completed');
                System.assert(ircaCurrent.Case_Creation_End_Date__c!=null, 'Case creation end date is not null');
                System.assertEquals('Success', ircaCurrent.Case_Creation_Status__c, 'Case creation status is success');
                System.debug(Logginglevel.INFO,'existing case after updation---------------------------------------------------------------'+existingCase);

                List<Case> updatedCases = [Select Id, Description, IR_Case_Type__c,IR_Invoice_Number__c  from Case where Id = :existingCase.Id];
                System.debug(Logginglevel.INFO,'Cases created ***************************************************'+updatedCases);

                System.assert(updatedCases[0].Description.contains(data1[0].Alert_Line__c), 'description contains the alert line of alert1');
                System.assert(!updatedCases[0].Description.contains(data1[1].Alert_Line__c), 'description does not contains the alert line of alert1');
                System.assert(updatedCases[0].IR_Case_Type__c.contains(data1[0].Alert_Name__c), 'ir case type contains the alert name of alert1');
                System.assert(!updatedCases[0].IR_Case_Type__c.contains(data1[1].Alert_Name__c), 'ir case type does not contains the alert name of alert1');
                System.assert(!updatedCases[0].Description.contains(existingAlertDescription1), 'the existing description wrt to alert1 is replaced');
                System.assert(updatedCases[0].Description.contains(existingDescription1), 'the existing description remains');
                System.assert(updatedCases[0].Description.contains(existingDescription2), 'the existing description remains');

            }
        }

        static testMethod void existingCaseWithOneExistingInfoTwoAlerts()
        //scenario: there is exisiting case which already has alert1, there are two info(from the view)
        //both alerts have active flag as true
        //expectation: the alert type now has both the alert types same and description for alert1 is replaced and the description of
        //alert2 is added
        {
            System.runAs(sysAdmin)
            {
                Account acc1 = SobjectRepository.getAccount();
                Opportunity opp1 = SobjectRepository.getOpportunity();
                Merge_Contract_Header__c mch1Id = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
                Merge_Contract_Header__c mch1 = refreshContractHeader(mch1Id);

                Invoice_Review_Case_Audit__c ircaLast=createIRCARec(reviewDate,'IRCaseTest1277');
                ircaLast.Import_Start_Date__c = Datetime.now().addDays(-1);
                ircaLast.Import_Status__c = 'Success';
                ircaLast.Case_Creation_Completed__c=true;
                ircaLast.Import_End_Date__c = Datetime.now().addDays(-1);
                insert ircaLast;
                System.debug(Logginglevel.INFO,'Last import irca '+ircaLast.id);

                Invoice_Review_Case_Audit__c ircaCurrent=createIRCARec(reviewDate,'IRCaseTest1278');
                insert ircaCurrent;
                System.debug(Logginglevel.INFO,'inserted current irca'+ircaCurrent.id);


                Draft_Invoice__c di2=createDraftInvoice(acc1.Id, mch1.Name, '1304123770', reviewDate, 12000);
                di2.CI_Original_Contract_Id__c=mch1.Name;
                di2.Invoice_Review_Case_Audit__c=ircaCurrent.Id;
                insert di2;

                String alertName1 = 'PS_OVERAGE_NOMATCH';
                String uniqueID1 = mch1.Name + String.valueof(reviewDate) +alertName1;
                String alertName2 = 'PS_OVERAGE_ERROR';
                String uniqueID2 = mch1.Name + String.valueof(reviewDate) +alertName2;

                IR_Case_Info__c irci1 = createIRCaseInfoRecord(mch1, di2, uniqueID1);
                irci1.Alert_Description__c = 'new data ; PS_OVERAGE_ERROR ; new extra data';
        		    irci1.Alert_Line__c = 'new data ; PS_OVERAGE_ERROR ; new extra data';
        		    irci1.Alert_Name__c = 'PS_OVERAGE_ERROR';
                irci1.Active_Flag__c = true;
                insert irci1;

                IR_Case_Info__c irci2 = createIRCaseInfoRecord(mch1, di2, uniqueID2);
                irci2.Alert_Description__c = 'new data ; PS_OVERAGE_NOMATCH ; new extra data';
        		    irci2.Alert_Line__c = 'new data ; PS_OVERAGE_NOMATCH ; new extra data';
        		    irci2.Alert_Name__c = 'PS_OVERAGE_NOMATCH';
                irci2.Active_Flag__c = true;

                insert irci2;

                List<IR_Case_Info__c> data1 = [Select id, Order_Id__c, Active_Flag__c,Alert_Description__c, Alert_Line__c, Alert_Name__c, Billable_Invoice_Id__c,
                                              Invoice_Date__c from IR_Case_Info__c where Order_Id__c = :mch1.Name and Invoice_Date__c = :reviewDate];

                System.debug(Logginglevel.INFO,'Info inserted 1****************************************************'+data1[0]);
                System.debug(Logginglevel.INFO,'Info inserted 2****************************************************'+data1[1]);

                System.debug(Logginglevel.INFO,'di2.Original_Contract_Id__c '+di2.Original_Contract_Id__c);

                di2.hasAttachment__c=true;
                di2.isDuplicate__c = false;
                di2.Original_Contract_Id__c = mch1.Id;
                update di2;
                System.debug(Logginglevel.INFO,'draft inv------------------------------------------------------------------'+di2);

                ircaCurrent.Import_End_Date__c=Datetime.now();
                ircaCurrent.Import_Status__c='Success';
                ircaCurrent.Trigger_Case_Creation__c = true;
                update ircaCurrent;

                User newOwnerRSM = GetUser('TST_NRSM');
                Case existingCase = createInvoiceCase (di2.Name, reviewDate, acc1.Id, opp1.Id , mch1.Id, newOwnerRSM.Id);
                String existingAlertDescription1 = 'old data ; PS_OVERAGE_ERROR ; old extra data';
                String existingDescription1 = 'some existing description';
                String existingDescription2 = 'some extra existing data';
                existingCase.Description = existingDescription1 + '\n' + existingAlertDescription1 + '\n'+existingDescription2;
                existingCase.IR_Case_Type__c = 'PS_OVERAGE_ERROR';
                insert existingCase;
                System.debug(Logginglevel.INFO,'existing case---------------------------------------------------------------'+existingCase);


                Test.startTest();
                List<Merge_Contract_Header__c> mchList1 = new List<Merge_Contract_Header__c>();
                for (Merge_Contract_Header__c mch : [SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,
                Effective_Start_Date__c,Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,
                Review_Date__c,Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Active__c=true AND Contract_Type__c != 'ISP' //2965556
                AND Locked__c=true AND Effective_End_Date__c >= :reviewDate.addMonths(-1) AND (Cancellation_Date__c=null OR Cancellation_Date__c >= :reviewDate.addMonths(-1)) //LIMIT 100])
                AND (Id=:mch1.Id)])
                {
                    mchList1.add(mch);
                }
                System.debug(Logginglevel.INFO,'mchList1 size=' + mchList1.size());
                System.debug(Logginglevel.INFO,'mchList1=' + mchList1);

                CaseTriggerClass.isIRCaseCreationInprogress=true;
                creationData(mchList1,ircaCurrent,ircaLast); //2965556

                Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));
                String query = 'SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,Effective_Start_Date__c,Currency__c,';
                   query += 'Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,Review_Date__c,';
                   query += 'Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Id  =\''+mch1.Id+'\''; //2965556
                   query += ' AND Active__c=true AND Contract_Type__c != \'ISP\''; // Order by End_Date__c DESC limit 1
                   query +=  ' AND Locked__c=true AND Effective_End_Date__c >= '+ IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + 'AND (Cancellation_Date__c=null OR Cancellation_Date__c >= ' + IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + ')';
                   query +=  ' Limit ' + batchSize;

                System.debug(Logginglevel.INFO,'Query=' + query);

                IRCaseCreationBatchable execIRCaseCreation = new IRCaseCreationBatchable(ircaCurrent, ircaLast);
                execIRCaseCreation.query=query;
                ID batchprocessid=Database.executeBatch(execIRCaseCreation,batchSize);
                System.debug(Logginglevel.INFO,'batchprocessid=' + batchprocessid);
                System.debug(Logginglevel.INFO,'--->');
                Test.stopTest();

                ircaCurrent = refreshIRCA(ircaCurrent);

                System.debug(Logginglevel.INFO,'ircaCurrent.Case_Creation_Completed__c: '+ircaCurrent.Case_Creation_Completed__c);
                System.debug(Logginglevel.INFO,'ircaCurrent.Case_Creation_End_Date__c: '+ircaCurrent.Case_Creation_End_Date__c);
                System.debug(Logginglevel.INFO,'ircaCurrent.Case_Creation_Status__c: '+ircaCurrent.Case_Creation_Status__c);
                System.assert(ircaCurrent.Case_Creation_Completed__c, 'Case creation completed');
                System.assert(ircaCurrent.Case_Creation_End_Date__c!=null, 'Case creation end date is not null');
                System.assertEquals('Success', ircaCurrent.Case_Creation_Status__c, 'Case creation status is success');
                System.debug(Logginglevel.INFO,'existing case after updation---------------------------------------------------------------'+existingCase);

                List<Case> updatedCases = [Select Id, Description, IR_Case_Type__c,IR_Invoice_Number__c  from Case where Id = :existingCase.Id];
                System.debug(Logginglevel.INFO,'Cases created ***************************************************'+updatedCases);

                System.assert(updatedCases[0].Description.contains(data1[0].Alert_Line__c), 'description contains the alert line of alert1');
                System.assert(updatedCases[0].Description.contains(data1[1].Alert_Line__c), 'description contains the alert line of alert2');
                System.assert(updatedCases[0].IR_Case_Type__c.contains(data1[0].Alert_Name__c), 'ir case type contains the alert name of alert1');
                System.assert(updatedCases[0].IR_Case_Type__c.contains(data1[1].Alert_Name__c), 'ir case type contains the alert name of alert2');
                System.assert(!updatedCases[0].Description.contains(existingAlertDescription1), 'the existing description wrt to alert1 is replaced');
                System.assert(updatedCases[0].Description.contains(existingDescription1), 'the existing description remains');
                System.assert(updatedCases[0].Description.contains(existingDescription2), 'the existing description remains');

            }
        }

        static testMethod void withExistingCaseOneInfoExistingDes()
        //scenario: there is exisiting case, and there is one info(from the view) records corresponding one with active flg true
        //and there is already a description associated as 'Contract requires double Invoice Review.' and the data created in this test satisfies
        //the condition for double Invoice Review this test is to make sure the description double invoice appears only once ans is not repeated
        //expectation: the alert type and description of the case is updated for the existing case with existing Contract requires double Invoice
        //to appear only once
        {
            System.runAs(sysAdmin)
            {
                Account acc1 = SobjectRepository.getAccount();
                Opportunity opp1 = SobjectRepository.getOpportunity();
                Merge_Contract_Header__c mch1Id = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
                Merge_Contract_Header__c mch1 = refreshContractHeader(mch1Id);

                Invoice_Review_Case_Audit__c ircaLast=createIRCARec(reviewDate,'IRCaseTest1277');
                ircaLast.Import_Start_Date__c = Datetime.now().addDays(-1);
                ircaLast.Import_Status__c = 'Success';
                ircaLast.Case_Creation_Completed__c=true;
                ircaLast.Import_End_Date__c = Datetime.now().addDays(-1);
                insert ircaLast;
                System.debug(Logginglevel.INFO,'Last import irca '+ircaLast.id);

                Invoice_Review_Case_Audit__c ircaCurrent=createIRCARec(reviewDate,'IRCaseTest1278');
                insert ircaCurrent;
                System.debug(Logginglevel.INFO,'inserted current irca'+ircaCurrent.id);


                Draft_Invoice__c di2=createDraftInvoice(acc1.Id, mch1.Name, '1304123770', reviewDate, 12000);
                di2.CI_Original_Contract_Id__c=mch1.Name;
                di2.Invoice_Review_Case_Audit__c=ircaCurrent.Id;
                insert di2;

                String alertName1 = 'PS_OVERAGE_NOMATCH';
                String uniqueID1 = mch1.Name + String.valueof(reviewDate) +alertName1;

                IR_Case_Info__c irci1 = createIRCaseInfoRecord(mch1, di2, uniqueID1);
                insert irci1;

                List<IR_Case_Info__c> data1 = [Select id, Order_Id__c, Active_Flag__c,Alert_Description__c, Alert_Line__c, Alert_Name__c, Billable_Invoice_Id__c,
                                              Invoice_Date__c from IR_Case_Info__c where Order_Id__c = :mch1.Name and Invoice_Date__c = :reviewDate];

                System.debug(Logginglevel.INFO,'Info inserted 1****************************************************'+data1[0]);

                System.debug(Logginglevel.INFO,'di2.Original_Contract_Id__c '+di2.Original_Contract_Id__c);

                di2.hasAttachment__c=true;
                di2.isDuplicate__c = false;
                di2.Original_Contract_Id__c = mch1.Id;
                update di2;
                System.debug(Logginglevel.INFO,'draft inv------------------------------------------------------------------'+di2);

                ircaCurrent.Import_End_Date__c=Datetime.now();
                ircaCurrent.Import_Status__c='Success';
                ircaCurrent.Trigger_Case_Creation__c = true;
                update ircaCurrent;

                User newOwnerRSM = GetUser('TST_NRSM');
                Case existingCase = createInvoiceCase (di2.Name, reviewDate, acc1.Id, opp1.Id , mch1.Id, newOwnerRSM.Id);
                String contractRelatedDesc = IRCaseHelperClass.fetchNowInGMTDateTime() + Label.IR_DoubleInvoiceReview;
                existingCase.Description = 'some existing description' + '\n' + contractRelatedDesc;
                existingCase.IRCache_hasDoubleInvoiceReview__c = true;
                insert existingCase;
                System.debug(Logginglevel.INFO,'existing case---------------------------------------------------------------'+existingCase);


                Test.startTest();
                List<Merge_Contract_Header__c> mchList1 = new List<Merge_Contract_Header__c>();
                for (Merge_Contract_Header__c mch : [SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,
                Effective_Start_Date__c,Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,
                Review_Date__c,Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Active__c=true AND Contract_Type__c != 'ISP' //2965556
                AND Locked__c=true AND Effective_End_Date__c >= :reviewDate.addMonths(-1) AND (Cancellation_Date__c=null OR Cancellation_Date__c >= :reviewDate.addMonths(-1)) //LIMIT 100])
                AND (Id=:mch1.Id)])
                {
                    mchList1.add(mch);
                }
                System.debug(Logginglevel.INFO,'mchList1 size=' + mchList1.size());
                System.debug(Logginglevel.INFO,'mchList1=' + mchList1);

                CaseTriggerClass.isIRCaseCreationInprogress=true;
                creationData(mchList1,ircaCurrent,ircaLast); //2965556

                Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));
                String query = 'SELECT Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,Effective_End_Date__c,Effective_Start_Date__c,Currency__c,';
                   query += 'Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId,(SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,Review_Date__c,';
                   query += 'Review_Frequency__c,Owner__c,AKAM_Created_Date__c from Merge_Contract_Manual_Lists__r), (Select Id from Invoices__r limit 1) FROM Merge_Contract_Header__c where Id  =\''+mch1.Id+'\''; //2965556
                   query += ' AND Active__c=true AND Contract_Type__c != \'ISP\''; // Order by End_Date__c DESC limit 1
                   query +=  ' AND Locked__c=true AND Effective_End_Date__c >= '+ IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + 'AND (Cancellation_Date__c=null OR Cancellation_Date__c >= ' + IRCaseHelperClass.getDateStringGmt(reviewDate.addMonths(-1)) + ')';
                   query +=  ' Limit ' + batchSize;

                System.debug(Logginglevel.INFO,'Query=' + query);

                IRCaseCreationBatchable execIRCaseCreation = new IRCaseCreationBatchable(ircaCurrent, ircaLast);
                execIRCaseCreation.query=query;
                ID batchprocessid=Database.executeBatch(execIRCaseCreation,batchSize);
                System.debug(Logginglevel.INFO,'batchprocessid=' + batchprocessid);
                System.debug(Logginglevel.INFO,'--->');
                Test.stopTest();

                ircaCurrent = refreshIRCA(ircaCurrent);

                System.debug(Logginglevel.INFO,'ircaCurrent.Case_Creation_Completed__c: '+ircaCurrent.Case_Creation_Completed__c);
                System.debug(Logginglevel.INFO,'ircaCurrent.Case_Creation_End_Date__c: '+ircaCurrent.Case_Creation_End_Date__c);
                System.debug(Logginglevel.INFO,'ircaCurrent.Case_Creation_Status__c: '+ircaCurrent.Case_Creation_Status__c);
                System.assert(ircaCurrent.Case_Creation_Completed__c, 'Case Creation completed');
                System.assert(ircaCurrent.Case_Creation_End_Date__c!=null, 'Case creation end date is not null');
                System.assertEquals('Success', ircaCurrent.Case_Creation_Status__c, 'case creation status is success');
                System.debug(Logginglevel.INFO,'existing case after updation---------------------------------------------------------------'+existingCase);

                List<Case> updatedCases = [Select Id, Description, IR_Case_Type__c,IR_Invoice_Number__c  from Case where Id = :existingCase.Id];
                System.debug(Logginglevel.INFO,'Cases created ***************************************************'+updatedCases);

                System.assert(updatedCases[0].Description.contains(data1[0].Alert_Line__c), 'description contains the alert line of alert 1');
                System.assert(updatedCases[0].IR_Case_Type__c.contains(data1[0].Alert_Name__c), 'IR case type contains the alert name of alert 1');
                System.assertEquals(di2.Name, updatedCases[0].IR_Invoice_Number__c, 'inv item is associated to case');
                List<String> descList = updatedCases[0].Description.split('\n');
        				List<String> requiredData = new List<String>();
        				for(String data: descList){
            			if(data.contains(Label.IR_DoubleInvoiceReview)){
                			requiredData.add(data);
            			}
        				}
                System.debug(Logginglevel.INFO,'data size-----------------------------------------------'+requiredData.size());
                System.assertEquals(1, requiredData.size(), 'the existing message added as part of other criteria is not repeated and the size is one');

            }
        }

}