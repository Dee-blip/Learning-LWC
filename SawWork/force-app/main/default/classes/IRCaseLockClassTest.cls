@isTest
public class IRCaseLockClassTest {
    private static User sysAdmin = SObjectFactory.ADMIN_USER;
    private static String userRoleValue = GsmUtilClass.getGSMSettingValue('User_Role');
    private static User testUser;
    private static User crmUser;
    private static Date startDate = Date.today().toStartOfMonth();
    private static Date endDate = Date.today().toStartOfMonth();
    private static Account acc1;
    private static Opportunity opp1;
    private static Merge_Contract_Header__c mch1;

    public static Merge_Contract_Header__c createContractHeader(String pName, Id pAccId, Id pOpptyId)
    {
        Merge_Contract_Header__c ch=new Merge_Contract_Header__c();
        ch.Name=pName;
        ch.Account_Name__c=pAccId;
        ch.Opportunity_Name__c=pOpptyId;
        ch.Cancellation_Date__c=Date.today().addMonths(5);
        ch.Effective_Start_Date__c=Date.today().addMonths(-2);
        ch.Effective_End_Date__c=Date.today().addYears(1);
        ch.Locked__c=false;
        ch.Active__c=true;
        ch.Acceptance_Date__c=Date.today().addMonths(-1);
        ch.Contract_Type__c = 'Direct Customer';
        ch.Double_Invoice_Review__c=true;
        ch.Manual_List__c=true;
        return ch;
    }

    public static List<Merge_Contract_Header__c> refreshContractHeaderList(List<Merge_Contract_Header__c> contractList)
    {
        return [select Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,
            Effective_End_Date__c,Effective_Start_Date__c,Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId
                From Merge_Contract_Header__c where id IN :contractList];
    }

    public static Merge_Contract_Header__c refreshContractHeader(Merge_Contract_Header__c contract)
    {
        return refreshContractHeaderList(new List<Merge_Contract_Header__c> {contract})[0];
    }

    public static GSM_Custom_Settings__c initGSMCustomSetting(String name, String value){
      GSM_Custom_Settings__c newGSMCustomSetting = new GSM_Custom_Settings__c();
      newGSMCustomSetting.Name = name;
      newGSMCustomSetting.Value__c = value;
      return newGSMCustomSetting;
    }

    @testSetUp static void createData()
    {
        String profileName = 'Sales - Media';
        String roleName = userRoleValue;
        testUser = utilTestClass.CreateUser('CMG_USER', 'CMG', 'CMG');
        crmUser = utilTestClass.CreateUser('CRM_USER', 'Worldwide', 'CRM Integration');
        insert (new User[] {testUser, crmUser});

        System.runAs(sysAdmin){
          Test.startTest();
          list<GSM_Custom_Settings__c> lstGSM = new list<GSM_Custom_Settings__c>();
          
          String invoiceReviewCaseId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Invoice Review Case').getRecordTypeId();

          String readInvoiceReviewCaseId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Invoice Review Read Only').getRecordTypeId();

          String momentumCaseRecordId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Momentum Case Record').getRecordTypeId();

          String productManagementId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Product Management').getRecordTypeId();

          String technicalId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();


          lstGSM.add(initGSMCustomSetting('IRCasesEAlert_RecipientList','achawla@akamai.com'));
          lstGSM.add(initGSMCustomSetting('IR_RecordTypeName_Default','Invoice_Review_Case'));
          lstGSM.add(initGSMCustomSetting('IR_CaseDefaultRecordTypeId',invoiceReviewCaseId));
          lstGSM.add(initGSMCustomSetting('IR_RecordTypeName_Readonly','Invoice_Review_Read_Only'));
          lstGSM.add(initGSMCustomSetting('IR_Unassigned_QueueDevName','IR_Unassigned'));
          lstGSM.add(initGSMCustomSetting('IR_FIN_US_QueueDevName','FIN_IR_US'));
          lstGSM.add(initGSMCustomSetting('IR_FIN_Intl_QueueDevName','FIN_IR_International'));
          lstGSM.add(initGSMCustomSetting('IR_EscalOwner_TeamMemberRole','Services - Secondary'));
          lstGSM.add(initGSMCustomSetting('IR_Owner_TeamMemberRole','CMG - Analyst'));
          lstGSM.add(initGSMCustomSetting('IR_EscalStatus_Default','Pending Review'));
          lstGSM.add(initGSMCustomSetting('IR_Status_Default','Pending Review'));
          lstGSM.add(initGSMCustomSetting('CaseTrigger#updateContact','Collections, International Business Development, Invoice Review Case, Invoice Review Read Only, Momentum Case Record, Partner Portal Case, Product Management, SF Feedback'));
          lstGSM.add(initGSMCustomSetting('IR_CaseRecordTypeIds',invoiceReviewCaseId+','+readInvoiceReviewCaseId));
          lstGSM.add(initGSMCustomSetting('CRM_Integration',crmUser.Id));
          insert lstGSM;

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
          Test.stopTest();
        }
    }

    public static Case createInvoiceCase(String pInvoiceID, Date pInvDate, Id pAccId, Id pOpptyId,Id pContractId , Id pUserId)
    {
        Case existingCase = new Case();

        existingCase.IR_CurrentInvoiceImportDate__c =  Datetime.now().addDays(-1);
        existingCase.IR_CurrentInvoiceNumber__c = pInvoiceId;
        existingCase.OwnerId = pUserId;
        existingCase.IR_Original_Contract_Id__c = pContractId;
        existingCase.RecordTypeId  = GSM_Custom_Settings__c.getValues('IR_CaseDefaultRecordTypeId').Value__c;
        existingCase.AccountID = pAccId;
        existingCase.IR_Escal_Owner__c = pUserId;
        existingCase.IRCache_Acceptance_Date__c =  Date.today().addMonths(-1);
        existingCase.IRCache_AkamOpportunityId__c =  pOpptyId;
        existingCase.Validation_Override__c = true;
        existingCase.IR_Invoice_Date__c = pInvDate;
        existingCase.IR_Invoice_Number__c = pInvoiceId;

        return existingCase;
    }

    public static Invoice_Review_Case_Audit__c createIRCARec(Date pInvDate, String pJobId)
    {
        Invoice_Review_Case_Audit__c newIRCA = new Invoice_Review_Case_Audit__c();
        newIRCA.Import_Status__c = 'In-Progress';
        newIRCA.Import_Start_Date__c = Datetime.now().addSeconds(10);
        newIRCA.Invoice_Review_Date__c = pInvDate;
        newIRCA.InvLoaderJobId__c = pJobId;
        return newIRCA;
    }

    public static Draft_Invoice__c createDraftInvoice(String pCI_accountId, String pContractId, String pInvoiceId, Date pInvDate, Decimal pAmount)
    {
        Draft_Invoice__c newInvoice = new Draft_Invoice__c();
        newInvoice.Invoice_Date__c= pInvDate;
        newInvoice.Name = pInvoiceId;
        newInvoice.Original_Amount__c=pAmount;
        newInvoice.Conversion_Rate_to_USD__c=1;
        newInvoice.billable_flag__c='Y';
        newInvoice.Previous_Month_Outstanding_Amount__c=100;
        return newInvoice;
    }

    public static User GetUser(String name){
      return [select Id from User where Alias = :name LIMIT 1];
    }

    static testmethod void testExecute() {
      System.runAs(sysAdmin)
      {
        User cmgUser = GetUser('CMG_USER');
        Account acc1 = SobjectRepository.getAccount();
        Opportunity opp1 = SobjectRepository.getOpportunity();
        Merge_Contract_Header__c mch1Id = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
        Merge_Contract_Header__c mch1 = refreshContractHeader(mch1Id);

        Invoice_Review_Case_Audit__c irca=createIRCARec(startDate,'IRCaseTest1277');
        irca.Import_Start_Date__c = Datetime.now().addDays(-1);
        irca.Import_Status__c = 'Success';
        irca.Case_Creation_Completed__c=true;
        irca.Import_End_Date__c = Datetime.now().addDays(-1);
        insert irca;

        Draft_Invoice__c di=createDraftInvoice(acc1.Id, mch1.Name, '1503123987', startDate, 50000);
        di.Invoice_Review_Case_Audit__c = irca.id;
        insert di;

        Test.startTest();
        Case existinginvCase = createInvoiceCase (di.Name, startDate, acc1.Id, opp1.Id , mch1.Id, cmgUser.Id);
        existinginvCase.status = 'Pending Review';
        Case existinginvCase1 = createInvoiceCase (di.Name, startDate, acc1.Id, opp1.Id , mch1.Id, cmgUser.Id);
        existinginvCase.status = 'Pending Review';
        insert new Case[] {existinginvCase, existinginvCase1};

        IRCaseLockClass execIRCaseLock = new IRCaseLockClass(startDate, endDate, cmgUser.Id);
  		Database.executeBatch(execIRCaseLock);
        Test.stopTest();

        for (Case cs : [Select Id, IR_Case_Locked__c  from Case where IR_Original_Contract_Id__c = :mch1.Id])
        {
          System.assertEquals(true, cs.IR_Case_Locked__c);
        }
      }
    }
}