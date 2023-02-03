/** Change History
Developer:  Ankit Chawla
Date:       27 Jul 2018
Purpose:    OTB-765 -  Changes to calculate IR Draft and Final threshold for AdHoc Manual Draft Invoices
*/

@isTest(seeAllData=false)
public class IRCaseCreationAdHocManualTestClass{
  private static User cmgUser;
  private static User crmUser;
  private static User sysAdmin = SObjectFactory.ADMIN_USER;
  // private static Account_Reassignment_Rule__c newOwnerRule;
  private static String userRoleValue = GsmUtilClass.getGSMSettingValue('User_Role');
  private static Date reviewDate = Date.today().toStartOfMonth();
  private static Account acc;
  private static Opportunity opp;
  private static Merge_Contract_Header__c mch;
  private static Attachment attachments;
  private static Map<String, GSM_Settings__mdt> gsmCustomMetadata = GsmUtilClass.getGSMSettingValue();

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
      return ch;
  }

  /**
      createDraftInvoice()
  */
  public static Draft_Invoice__c createDraftInvoice(String pCI_accountId, String pContractId, String pInvoiceId, Date pInvDate, Decimal pAmount)
  {
      Draft_Invoice__c newInvoice = new Draft_Invoice__c();
      newInvoice.CI_Account_Name__c = pCI_accountId;
      newInvoice.CI_Original_Contract_Id__c=pContractId;
      newInvoice.Invoice_Date__c= pInvDate;
      newInvoice.Name = pInvoiceId;
      newInvoice.Original_Amount__c=pAmount;
      newInvoice.processedForIRCase__c = false;
      newInvoice.Type__c = 'UI';
      newInvoice.OwnerId = sysAdmin.Id;
      return newInvoice;
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

  /**
      createInvoiceAttachment()
  */
  public static Attachment createInvoiceAttachment(String pInvoiceId)
  {
      Attachment attachment = new Attachment();
      attachment.ParentId = pInvoiceId;
      return attachment;
  }

  public static GSM_Custom_Settings__c initGSMCustomSetting(String name, String value){
    GSM_Custom_Settings__c newGSMCustomSetting = new GSM_Custom_Settings__c();
    newGSMCustomSetting.Name = name;
    newGSMCustomSetting.Value__c = value;
    return newGSMCustomSetting;
  }

  @testSetUp static void createData(){
    crmUser = utilTestClass.CreateUser('CRM_USER', 'Worldwide', 'CRM Integration');
    insert (new User[] {crmUser});
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

    acc =  (Account)new SobjectBuilder(Account.sObjectType)
        .eagerPopulate()
        .put(Account.Type, 'Lead')
        .create()
        .getRecord();

    opp = (Opportunity)new SobjectBuilder(Opportunity.sObjectType)
        .eagerPopulate()
        .put(Opportunity.AccountId, acc.Id)
        .put(Opportunity.StageName, '1-Create')
        .put(Opportunity.Name, 'IRCaseOppty1')
        .put(Opportunity.CloseDate, Date.today().addDays(10))
        .create()
        .getRecord();

    mch = createContractHeader('IRCaseMCH1', acc.Id, opp.Id);
    insert mch;
    Test.stopTest();
    }
  }

  static testMethod void ManualIRCasePositive(){

    System.runAs(SObjectFactory.ADMIN_USER){
      Account acc = SobjectRepository.getAccount();
      Merge_Contract_Header__c mchId = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
      Merge_Contract_Header__c mch = refreshContractHeader(mchId);
      String casePriorityThreshold = GsmUtilClass.getGSMSettingValue('IR_Case_Priority_Threshold');
      Draft_Invoice__c di = createDraftInvoice(acc.Id, mch.Name, '1808123456', reviewDate, (Decimal.valueOf(casePriorityThreshold) + 1));
      insert di;

      Test.startTest();

      di.hasAttachment__c=true;
      di.Original_Contract_Id__c = mch.Id;
      di.Conversion_Rate_to_USD__c = 1;
      update di;

      Test.stopTest();

      Case cs = [Select Id, Description, IR_Original_Contract_Id__c, OwnerId, IR_Priority_level__c from Case where IR_Original_Contract_Id__c = :mch.Id ][0];

      System.assertEquals(mch.Id, cs.IR_Original_Contract_Id__c);
      System.assertEquals(di.OwnerId, cs.OwnerId);
      System.assert(cs.Description.contains(Label.IR_SFDC_Ad_hoc_Invoice));
      System.assertEquals('High', cs.IR_Priority_level__c);

    }
  }

  static testMethod void ManualIRCaseNegative(){
    System.runAs(SObjectFactory.ADMIN_USER){
      Account acc = SobjectRepository.getAccount();
      Merge_Contract_Header__c mchId = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
      Merge_Contract_Header__c mch = refreshContractHeader(mchId);
      Draft_Invoice__c di = createDraftInvoice(acc.Id, mch.Name, '1808123456', reviewDate, 500);
      insert di;

      Test.startTest();

      di.hasAttachment__c=true;
      di.Original_Contract_Id__c = mch.Id;
      di.processedForIRCase__c = true;
      update di;

      Test.stopTest();

      List<Case> cs = [Select Id, Description, IR_Original_Contract_Id__c from Case where IR_Original_Contract_Id__c = :mch.Id];

      System.assertEquals(0, cs.size());
    }
  }

  static testMethod void ManualIRCaseDraftViolationPositive(){
    System.runAs(SObjectFactory.ADMIN_USER){
      Account acc = SobjectRepository.getAccount();
      Merge_Contract_Header__c mchId = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
      Merge_Contract_Header__c mch = refreshContractHeader(mchId);
      Draft_Invoice__c di = createDraftInvoice(acc.Id, mch.Name, '1808123456', reviewDate, 40000);
      insert di;

      di.hasAttachment__c=true;
      di.Original_Contract_Id__c = mch.Id;
      di.processedForIRCase__c = true;
      di.Conversion_Rate_to_USD__c = 1;
      update di;

      List<Case> cs = [Select Id, Description, IR_Original_Contract_Id__c from Case where IR_Original_Contract_Id__c = :mch.Id];

      System.assertEquals(0, cs.size());

      Draft_Invoice__c di1 = createDraftInvoice(acc.Id, mch.Name, '1808123456', reviewDate, 15000);
      di1.Conversion_Rate_to_USD__c = 1;
      insert di1;
      String fluxCheck = GsmUtilClass.getGSMSettingValue('Enable_Flux_Calculation');

      Test.startTest();

      di1.hasAttachment__c=true;
      di1.Original_Contract_Id__c = mch.Id;
      update di1;

      Test.stopTest();

      cs = [Select Id, Description, IRCache_hasThresholdViolation__c, IRCache_hasDraftThresholdViolation__c from Case where IR_Original_Contract_Id__c = :mch.Id];

      String draftDescription = Label.IR_ThresholdViolation_PreviousImport;
      Decimal thresholdVal = IRCaseHelperClass.calculateThreshhold(di.Original_Amount__c,di1.Original_Amount__c);
      draftDescription = draftDescription.replaceAll('#param1#',thresholdVal.toPlainString());

      System.assertEquals(1, cs.size());
      if(fluxCheck == 'true'){
        System.assert(cs[0].Description.contains(Label.IR_SFDC_Ad_hoc_Invoice));
        System.assert(cs[0].Description.contains(draftDescription));
        System.assertEquals(true, cs[0].IRCache_hasDraftThresholdViolation__c);
        System.assertEquals(false, cs[0].IRCache_hasThresholdViolation__c);
      } else {
        System.assertEquals(false, cs[0].IRCache_hasDraftThresholdViolation__c);
      }

    }
  }

  static testMethod void ManualIRCaseFinalViolationPositive(){
    System.runAs(SObjectFactory.ADMIN_USER){
      Account acc = SobjectRepository.getAccount();
      Merge_Contract_Header__c mchId = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
      Merge_Contract_Header__c mch = refreshContractHeader(mchId);

      Draft_Invoice__c di = createDraftInvoice(acc.Id, mch.Name, '1808123456', reviewDate, 10000);
      insert di;

      String fluxCheck = GsmUtilClass.getGSMSettingValue('Enable_Flux_Calculation');

      Test.startTest();

      di.hasAttachment__c=true;
      di.Original_Contract_Id__c = mch.Id;
      di.Conversion_Rate_to_USD__c = 1;
      di.Previous_Month_Outstanding_Amount__c = 50000;
      di.billable_flag__c = 'Y' ;
      update di;

      Test.stopTest();

      List<Case> cs = [Select Id, Description, IRCache_hasThresholdViolation__c, IRCache_hasDraftThresholdViolation__c from Case where IR_Original_Contract_Id__c = :mch.Id];

      String finalDescription = Label.IR_ThresholdViolation_PreviousMonth;
      Decimal thresholdVal = IRCaseHelperClass.calculateThreshhold(di.Previous_Month_Outstanding_Amount__c, di.Original_Amount__c);
      finalDescription = finalDescription.replaceAll('#param1#',thresholdVal.toPlainString());

      System.assertEquals(1, cs.size());
      if(fluxCheck == 'true'){
        System.assert(cs[0].Description.contains(Label.IR_SFDC_Ad_hoc_Invoice));
        System.assert(cs[0].Description.contains(finalDescription));
        System.assertEquals(true, cs[0].IRCache_hasThresholdViolation__c);
        System.assertEquals(false, cs[0].IRCache_hasDraftThresholdViolation__c);
      } else{
        System.assertEquals(false, cs[0].IRCache_hasThresholdViolation__c);
      }

    }
  }

  static testMethod void ManualIRCaseFinalViolationNeg(){
    System.runAs(SObjectFactory.ADMIN_USER){
      Account acc = SobjectRepository.getAccount();
      Merge_Contract_Header__c mchId = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
      Merge_Contract_Header__c mch = refreshContractHeader(mchId);

      Invoice__c prevMonthFinalInvoice = createInvoice(acc.AKAM_Account_ID__c, mch.Name, '1807123456', reviewDate.addMonths(-1), 50000);
      insert prevMonthFinalInvoice;

      Draft_Invoice__c di = createDraftInvoice(acc.Id, mch.Name, '1808123456', reviewDate, 10000);
      insert di;

      String fluxCheck = GsmUtilClass.getGSMSettingValue('Enable_Flux_Calculation');

      Test.startTest();

      di.hasAttachment__c=true;
      di.Original_Contract_Id__c = mch.Id;
      di.Conversion_Rate_to_USD__c = 1;
      di.billable_flag__c = 'N' ;
      update di;

      Test.stopTest();

      List<Case> cs = [Select Id, Description, IRCache_hasThresholdViolation__c, IRCache_hasDraftThresholdViolation__c from Case where IR_Original_Contract_Id__c = :mch.Id];

      String finalDescription = Label.IR_ThresholdViolation_PreviousMonth;
      Decimal thresholdVal = IRCaseHelperClass.calculateThreshhold(prevMonthFinalInvoice.Original_Amount__c, di.Original_Amount__c);
      finalDescription = finalDescription.replaceAll('#param1#',thresholdVal.toPlainString());

      System.assertEquals(1, cs.size());
      if(fluxCheck == 'true'){
        System.assert(cs[0].Description.contains(Label.IR_SFDC_Ad_hoc_Invoice));
        System.assert(!cs[0].Description.contains(finalDescription));
        System.assertEquals(false, cs[0].IRCache_hasThresholdViolation__c);
        System.assertEquals(false, cs[0].IRCache_hasDraftThresholdViolation__c);
      } else{
        System.assertEquals(false, cs[0].IRCache_hasThresholdViolation__c);
      }

    }
  }

    static testMethod void ManualIRCasePositiveNoPriority(){

    System.runAs(SObjectFactory.ADMIN_USER){
      Account acc = SobjectRepository.getAccount();
      Merge_Contract_Header__c mchId = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
      Merge_Contract_Header__c mch = refreshContractHeader(mchId);
      String casePriorityThreshold = GsmUtilClass.getGSMSettingValue('IR_Case_Priority_Threshold');
      Draft_Invoice__c di = createDraftInvoice(acc.Id, mch.Name, '1808123456', reviewDate, (Decimal.valueOf(casePriorityThreshold) - 1));
      insert di;

      Test.startTest();

      di.hasAttachment__c=true;
      di.Original_Contract_Id__c = mch.Id;
      di.Conversion_Rate_to_USD__c = 1;
      update di;

      Test.stopTest();

      Case cs = [Select Id, Description, IR_Original_Contract_Id__c,IR_Priority_level__c from Case where IR_Original_Contract_Id__c = :mch.Id ][0];

      System.assertEquals(mch.Id, cs.IR_Original_Contract_Id__c);
      System.assert(cs.Description.contains(Label.IR_SFDC_Ad_hoc_Invoice));
      System.assertEquals(null, cs.IR_Priority_level__c);

    }
  }
}