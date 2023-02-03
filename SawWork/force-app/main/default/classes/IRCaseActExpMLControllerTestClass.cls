@isTest

private class IRCaseActExpMLControllerTestClass
{
    private static Boolean initFlag = false;
    private static User sysAdmin;
    private static User newOwnerRSM;
    private static Map<String, GSM_Settings__mdt> testcaseCustomSettings = GsmUtilClass.getGSMSettingValue();
    private static Date reviewDate;

    private static Account acc1;
    private static Opportunity opp1;
    private static Merge_Contract_Header__c mch1;
    private static Merge_Contract_Manual_List__c mcManList;
    private static Case existingCases;  


    /**
        createContractHeader
            - generates a new Contract record based on parameters
            - returns Contract
    */
    private static Merge_Contract_Header__c createContractHeader(String pName, Id pAccId, Id pOpptyId)
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
        createContractMList()
    */
    private static Merge_Contract_Manual_List__c createContractManualList(String pMListName, String pCI_OriginalContractId)
    {
        Merge_Contract_Manual_List__c newMList = new Merge_Contract_Manual_List__c();
        newMList.CI_Original_Contract_Id__c = pCI_OriginalContractId;
        newMList.Manual_List_Id__c = pMListName;
        return newMList;
    }

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
        existingCase.Validation_Override__c = true;
        existingCase.IR_Invoice_Date__c = pInvDate;
        existingCase.IR_Invoice_Number__c = pInvoiceId;

        return existingCase;
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
    public static Case getCase(Id pCaseId)
    {
        return getCases(new List<Id> {pCaseId})[0];
    }

    /**
        RefreshAccount(Account acc)
        - Refresh single account
    */
    private static Account RefreshAccount(Account acc)
    {
        return RefreshAccountList(new Account[]{acc})[0];
    }
    /**
        RefreshAccountList(Account[] acc)
        - Refresh bulk accounts
    */
    private static Account[] RefreshAccountList(Account[] accounts)
    {
        return [select Id,OwnerId,AKAM_Account_ID__c,Account_Status__c from Account where Id IN :accounts];
    }

    public static GSM_Custom_Settings__c initGSMCustomSetting(String name, String value){
      GSM_Custom_Settings__c newGSMCustomSetting = new GSM_Custom_Settings__c();
      newGSMCustomSetting.Name = name;
      newGSMCustomSetting.Value__c = value;
      return newGSMCustomSetting;
    }

    /**
        Init()
        - Intialize the static variables for this Test Class
    */
    private static void Init()
    {
        if(initFlag)
            return;

        reviewDate = Date.today().toStartOfMonth();
        System.debug('reviewDate in TEST Method=' + reviewDate);

        String profileName = 'Sales - Media';
        String roleName = testcaseCustomSettings.get('User_Role').Value__c;

        sysAdmin = utilTestClass.CreateUser('SYS_USER', 'System Administrator', 'System Administrator');
        newOwnerRSM = utilTestClass.CreateUser('TST_NRSM', roleName, profileName);

        insert (new User[] {newOwnerRSM,sysAdmin});

        System.runAs(sysAdmin){

        list<GSM_Custom_Settings__c> lstGSM = new list<GSM_Custom_Settings__c>();

        lstGSM.add(initGSMCustomSetting('IR_NewMissingProcess_BatchSize','15'));
        lstGSM.add(initGSMCustomSetting('IR_CaseDefaultRecordTypeId','012G0000000ygAxIAI'));
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
        lstGSM.add(initGSMCustomSetting('IR_CaseRecordTypeIds','012G0000000ygAxIAI,012G0000000ygB2IAI'));
        lstGSM.add(initGSMCustomSetting('CRM_Integration','005A0000000NHQc'));
        lstGSM.add(initGSMCustomSetting('IRCA_ManList_Extn_Days','20'));


        insert lstGSM;

        SCUserIdCustomSetting__c scUserIdCS = new SCUserIdCustomSetting__c();
        scUserIdCS.Name = 'Primary/SecondaryAssignmentQueue';
        scUserIdCS.UserId__c = '00GG0000002igPLMAY';

        insert scUserIdCS;

        list<Email_to_Case__c> lstEmail2Case = new list<Email_to_Case__c>();

        Email_to_Case__c emailToCaseMomentum = new  Email_to_Case__c();
        emailToCaseMomentum.Name = 'Momentum';
        emailToCaseMomentum.CaseRecord__c = '012A0000000OWfW';
        lstEmail2Case.add(emailToCaseMomentum);

        Email_to_Case__c emailToCaseProdMgmnt = new  Email_to_Case__c();
        emailToCaseProdMgmnt.Name = 'ProdMgmt';
        emailToCaseProdMgmnt.CaseRecord__c = '012A0000000OmQ8';
        lstEmail2Case.add(emailToCaseProdMgmnt);

        insert lstEmail2Case;

        SC_RiverbedCaseProdID__c rvrBed = new SC_RiverbedCaseProdID__c();
        rvrBed.Name = 'Riverbed_SAAS_OEM';
        rvrBed.RecordTypeID__c = '012G0000000z10xIAA';
        insert rvrBed;

        SCRecordTypeCustomSetting__c scRTCustomSetting = new SCRecordTypeCustomSetting__c();
        scRTCustomSetting.Name = 'NotificationTeam';
        scRTCustomSetting.RecordTypeName__c = 'Professional Services&&AMG&&Technical&&Managed Security&&Carrier Products&&Emerging Products Engineering';

        insert scRTCustomSetting;

        acc1 = utilTestClass.CreateAccount('IRCaseTestAcc1');
        insert acc1;
        acc1 = RefreshAccount(acc1);

        opp1 = utilTestClass.CreateOpportunity('IRCaseOppty1', '1-Create');
        opp1.AccountId=acc1.Id;
        opp1.CloseDate=Date.today().addDays(10);
        insert opp1;

        mch1 = createContractHeader('IRCaseMCH1', acc1.Id, opp1.Id);
        insert mch1;

        mcManList = createContractManualList('IRCaseMlist1', mch1.Name);
        mcManList.Review_Frequency__c = 'Monthly';
        mcManList.End_Date__c = Date.today().addDays(2);
        mcManList.Owner__c = 'UNKNOWN';
        mcManList.Review_Date__c = reviewDate;
        mcManList.Priority__c = '1';
        insert mcManList;

    }
    }


  static testMethod void extControllerTest()
    {
        init();
        System.runAs(sysAdmin)
        {
            List<Merge_Contract_Manual_List__c> mlList= new  List<Merge_Contract_Manual_List__c>();
            Integer manList_Extn_Days = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IRCA_ManList_Extn_Days')); //CR 3102071

            //Monthly Expired ML
            mcManList = createContractManualList('IRCaseMlist2', mch1.Name);
            mcManList.Review_Frequency__c = 'Monthly';
            mcManList.End_Date__c = Date.today().addDays(-21);
            mcManList.Owner__c = 'UNKNOWN';
            mcManList.Review_Date__c = reviewDate;
            mcManList.Priority__c = '2';

            mlList.add(mcManList);

            //Monthly ML with End Date NULL
            mcManList = createContractManualList('IRCaseMlist3', mch1.Name);
            mcManList.Review_Frequency__c = 'Monthly';
            mcManList.End_Date__c = NULL;
            mcManList.Owner__c = 'UNKNOWN';
            mcManList.Review_Date__c = reviewDate;
            mcManList.Priority__c = '2';

            mlList.add(mcManList);

            //One Time Expired ML
            mcManList = createContractManualList('IRCaseMlist4', mch1.Name);
            mcManList.Review_Frequency__c = 'One Time';
            mcManList.Owner__c = 'UNKNOWN';
            mcManList.Review_Date__c = Date.today().addDays(-22);
            mcManList.Priority__c = '3';
            mlList.add(mcManList);

            //One Time Active ML
            mcManList = createContractManualList('IRCaseMlist5', mch1.Name);
            mcManList.Review_Frequency__c = 'One Time';
            mcManList.Owner__c = 'UNKNOWN';
            mcManList.Review_Date__c = Date.today().addDays(manList_Extn_Days);
            mcManList.Priority__c = '2';
            mlList.add(mcManList);

            insert mlList;

            Draft_Invoice__c di1=createDraftInvoice(acc1.Id, mch1.Name, '1503123987', reviewDate, 350);
            di1.CI_Original_Contract_Id__c=mch1.Name;
            insert di1;


            Case existinginvCase = createInvoiceCase (di1.Name, reviewDate, mch1.Account_Name__c, Opp1.Id , mch1.Id, newOwnerRSM.Id);
            existinginvCase.status = 'Pending Review';
            existinginvCase.Description = 'Test Case';
            existinginvCase.IR_CurrentInvoiceAmount__c = 350;
            insert existinginvCase;

            existinginvCase = getCase(existinginvCase.Id);

            // PageReference ref =
            // new PageReference('/apex/IRCaseActExpManList?Id='+existinginvCase.Id);
            // Test.setCurrentPage(ref);
            //
            // ApexPages.StandardController controller = new ApexPages.StandardController(existinginvCase);
            // IRCaseActExpMLExtension actexpML = new IRCaseActExpMLExtension(controller);
            //
            // System.debug('Active ML Size: '+actexpML.amlList.size());
            // System.debug('Expired ML Size: '+actexpML.emlList.size());

            Map<String, List<Merge_Contract_Manual_List__c>> result = IRCaseActExpMLController.getManualLists(existinginvCase.Id);
            List<Merge_Contract_Manual_List__c> amlList = result.get('active');
            List<Merge_Contract_Manual_List__c> emlList = result.get('expired');



            Merge_Contract_Manual_List__c actMonthlyML1 = [Select ID,Manual_List_Id__c from Merge_Contract_Manual_List__c
                                                               where Original_Contract_Id__c=:mch1.Id AND  Review_Frequency__c = 'Monthly' ORDER BY End_Date__c DESC NULLS FIRST LIMIT 1];
            //Monthly ML, End Date NULL or >=(Today-IRCA_ManList_Extn_Days) should come in Active ML
            System.assertEquals(actMonthlyML1.Id,amlList[0].Id );

            Merge_Contract_Manual_List__c expMonthlyML1 = [Select ID,Manual_List_Id__c from Merge_Contract_Manual_List__c
                                                           where Original_Contract_Id__c=:mch1.Id AND Review_Frequency__c = 'Monthly' AND End_Date__c<> NULL AND End_Date__c < :System.Date.today().addDays(-(manList_Extn_Days))
                                                           ORDER BY End_Date__c DESC NULLS LAST LIMIT 1];
            //Monthly ML, End Date < (Today- IRCA_ManList_Extn_Days) should come on top of Expired ML
            System.assertEquals(expMonthlyML1.Id,emlList[0].Id );

            Merge_Contract_Manual_List__c actOneTimeML1 = [Select ID,Manual_List_Id__c from Merge_Contract_Manual_List__c
                                                           where Original_Contract_Id__c=:mch1.Id AND Review_Frequency__c = 'One Time' AND (Review_Date__c >= :System.Date.today().addDays(-(manList_Extn_Days)) OR Review_Date__c = NULL)
                                                           ORDER BY End_Date__c DESC NULLS FIRST LIMIT 1];
            //One Time ML, Review Date NULL or >=(Today- IRCA_ManList_Extn_Days) should come in Active ML
            System.assertEquals(actOneTimeML1.Id,amlList[1].Id );

            Merge_Contract_Manual_List__c expOneTimeML1 = [Select ID,Manual_List_Id__c from Merge_Contract_Manual_List__c
                                                           where Original_Contract_Id__c=:mch1.Id AND Review_Frequency__c = 'One Time' AND Review_Date__c < :System.Date.today().addDays(-(manList_Extn_Days))
                                                           ORDER BY End_Date__c DESC NULLS LAST LIMIT 1];
            //One Time ML, Review Date < (Today- IRCA_ManList_Extn_Days) should come in Expired ML
            System.assertEquals(expOneTimeML1.Id,emlList[1].Id );

        }
    }
}