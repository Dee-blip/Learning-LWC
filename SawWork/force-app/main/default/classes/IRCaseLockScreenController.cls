/**
IRCaseHelperClass
    @author : Ali KM <mohkhan@akamai.com>
    @Description : This is controller class for IRCaseLockScreen VF page. This controller handles FINAL FINAL locking of cases for the OPs team
          at the end of Invoice Review Cycle every month.

    @History
    --Developer       --Date        --Change
  Ali KM              06/02/2013      Created the class
                                        CR 2068273 - Invoice Review Cases Process migration from Siebel to SF.
  Ali KM        30/05/2013    CR 2204912 - IR Case - Lock Screen VF giving - Time Limit Exceeded message.
                    - Moving the IR Case lockdown to @future method call.
  Ankit Chawla        08/03/2017      IRCase Lock should not pick Draft Sync Cases for upcoming month : CR: 3412081
*/
public class IRCaseLockScreenController
{
    private static User crmInt;
    public Boolean initializeFlag {get; set;}
    public Invoice_Review_Case_Audit__c ircaExisting { get; set; }
    public Case dummyCase { get; set; }

    public IRCaseLockScreenController()
    {
       dummyCase = new Case();
       initializeFlag=true;

       //CR: 3412081

       //for (Invoice_Review_Case_Audit__c irca : [Select Id, Invoice_Review_Date__c, Name from Invoice_Review_Case_Audit__c where
         //Case_Creation_Status__c='Success' AND Import_Status__c='Success' AND Invoice_Review_Date__c!=null Order by LastModifiedDate DESC limit 1])

       Date firstDtOfCurrMonth = Date.today().toStartOfMonth();

       for (Invoice_Review_Case_Audit__c irca : [Select Id, Invoice_Review_Date__c, Name from Invoice_Review_Case_Audit__c where
         Case_Creation_Status__c='Success' AND Import_Status__c='Success' AND Invoice_Review_Date__c!=null AND Invoice_Review_Date__c<= :firstDtOfCurrMonth Order by LastModifiedDate DESC limit 1])
            ircaExisting=irca;
       System.debug('ircaExisting=' + ircaExisting);
       if (ircaExisting!=null)
       {
          dummyCase.IR_Invoice_Date__c=ircaExisting.Invoice_Review_Date__c;
          dummyCase.IRCache_Acceptance_Date__c=dummyCase.IR_Invoice_Date__c.addMonths(1).toStartOfMonth().addDays(-1);
       }
       else
       {
           dummyCase.IR_Invoice_Date__c=Date.today().toStartOfMonth();
           dummyCase.IRCache_Acceptance_Date__c=Date.today().addMonths(1).toStartOfMonth().addDays(-1);
       }
    }

    public static GSM_Custom_Settings__c initGSMCustomSetting(String name, String value){
        GSM_Custom_Settings__c newGSMCustomSetting = new GSM_Custom_Settings__c();
        newGSMCustomSetting.Name = name;
        newGSMCustomSetting.Value__c = value;
        return newGSMCustomSetting;
      }

    /**
        submit()
        - Lock IR Cases
    */
    public PageReference submit()
    {
        if (dummyCase.IR_Invoice_Date__c==null || dummyCase.IRCache_Acceptance_Date__c==null)
        {
            ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Review Cycle Start Date / End Date cannot be empty.');
            ApexPages.addMessage(errMsg);
            return null;
        }
  //CR 3412081
        if (dummyCase.IR_Invoice_Date__c > Date.today().toStartOfMonth() || dummyCase.IRCache_Acceptance_Date__c > Date.today().addMonths(1).toStartOfMonth().addDays(-1))
        {
            ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Review Cycle Start Date / End Date cannot be locked.');
            ApexPages.addMessage(errMsg);
            return null;
        }

        String resultMessage = IRCaseHelperClass.lockIRCases(dummyCase.IR_Invoice_Date__c, dummyCase.IRCache_Acceptance_Date__c);
        String[]  resultList = resultMessage.split(':');
        ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.INFO, resultList[1]);
        ApexPages.addMessage(errMsg);
        return null;
    }

    @isTest(SeeAllData=false)
    static void unitTest()
    {
        String invoiceReviewCaseId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Invoice Review Case').getRecordTypeId();

        crmInt = utilTestClass.CreateUser('CRM_USER', 'Worldwide', 'CRM Integration');

        list<GSM_Custom_Settings__c> lstGSM = new list<GSM_Custom_Settings__c>();
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
          lstGSM.add(initGSMCustomSetting('CRM_Integration',crmInt.Id));
          lstGSM.add(initGSMCustomSetting('AccountDelete#EnabledProfileId','00eA0000000QpNLIA0,00eA0000000VTG1IAO'));
          lstGSM.add(initGSMCustomSetting('IRCase_CutOffDayOfMonth','24'));
          lstGSM.add(initGSMCustomSetting('IR_CaseAccessProfileIDs','00eA0000000QpNLIA0,00eA0000000VTG1IAO,00eA0000000QpQUIA0'));
          lstGSM.add(initGSMCustomSetting('IRCase_DefaultInvoiceNumber','N/A'));
          insert lstGSM;
        Invoice_Review_Case_Audit__c irca = new Invoice_Review_Case_Audit__c();
        irca.Invoice_Review_Date__c = Date.today().toStartOfMonth();
        irca.Case_Creation_Status__c = 'Success';
        irca.Import_Status__c = 'Success';
        insert irca;

        PageReference extendPage = Page.IRCaseLockScreen;
        Test.setCurrentPageReference(extendPage);
        IRCaseLockScreenController controller = new IRCaseLockScreenController();
        Test.startTest();
        controller.submit();
        Test.stopTest();
    }
}