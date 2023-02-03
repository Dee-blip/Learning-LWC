@isTest
public class DraftInvoiceRefreshControllerTest{ 

  private static User sysAdmin = SObjectFactory.ADMIN_USER;
  private static Account acc;


  @testSetUp static void createData(){
    System.runAs(sysAdmin){
      Account acc =  (Account)new SobjectBuilder(Account.sObjectType)
          .eagerPopulate()
          .put(Account.Type, 'Lead')
          .create()
          .getRecord();
    }


  }

  public static Draft_Invoice__c createDraftInvoice(String pInvoiceId, Date pInvDate)
  {
      Draft_Invoice__c newDI = new Draft_Invoice__c();
      newDI.Invoice_Date__c= pInvDate;
      newDI.Name = pInvoiceId;
      return newDI;
  }

  public static Invoice_Review_Case_Audit__c createIRCARec(Date pInvDate, String pJobId)
  {
      Invoice_Review_Case_Audit__c newIRCA = new Invoice_Review_Case_Audit__c();
      newIRCA.Import_Status__c = 'Success';
      newIRCA.Import_Start_Date__c = Datetime.now().addDays(-1);
      newIRCA.Import_End_Date__c = Datetime.now().addDays(-1);
      newIRCA.Invoice_Review_Date__c = pInvDate;
      newIRCA.InvLoaderJobId__c = pJobId;
      return newIRCA;
  }

  static testMethod void refreshDraftInvoicePositive(){
    Draft_Invoice__c di = createDraftInvoice('12345', Date.today().toStartOfMonth());
    insert di;

    Map<String,String> result = DraftInvoiceRefreshController.refreshDraftInvoice(di.id);
    List<String> resultKeyList = new list<string>(result.keySet());
    System.assertEquals(resultKeyList[0], 'success');
    System.assertEquals(result.get(resultKeyList[0]), 'A refresh has been requested. Please wait for a while before the line items are updated.');
  }

  static testMethod void refreshDraftInvoiceAlreadyRefreshed(){
    Draft_Invoice__c di = createDraftInvoice('12345', Date.today().toStartOfMonth());
    di.Refreshed__c = true;
    insert di;

    Map<String,String> result = DraftInvoiceRefreshController.refreshDraftInvoice(di.id);
    List<String> resultKeyList = new list<string>(result.keySet());
    System.assertEquals(resultKeyList[0], 'error');
    System.assertEquals(result.get(resultKeyList[0]), 'A Refresh has already been requested on this Invoice.');
  }

  static testMethod void refreshDraftInvoiceWithLineItems(){

    Account acc = SobjectRepository.getAccount();

    Invoice_Review_Case_Audit__c irca=createIRCARec(Date.today().toStartOfMonth(),'IRCaseTest1');
    insert irca;

    Draft_Invoice__c di = createDraftInvoice('12345', Date.today().toStartOfMonth());
    di.Invoice_Review_Case_Audit__c=irca.Id;
    insert di;

    Draft_Invoice_Line_Item__c diLineItem = new Draft_Invoice_Line_Item__c();
    diLineItem.Draft_Invoice__c = di.id;
    diLineItem.CI_Draft_Invoice_id__c = '12345';
    diLineItem.Account_ID__c = acc.id;
    diLineItem.Create_Date__c = Date.today();
    diLineItem.Create_User__c = sysAdmin.id;
    diLineItem.Part_Number__c = '1';
    diLineItem.Update_Date__c = Date.today();

    insert diLineItem;

    Map<String,String> result = DraftInvoiceRefreshController.refreshDraftInvoice(di.id);
    List<String> resultKeyList = new list<string>(result.keySet());
    System.assertEquals(resultKeyList[0], 'error');
    System.assertEquals(result.get(resultKeyList[0]), 'You need to create a new invoice header to refresh this invoice.');
  }

  static testMethod void refreshDraftInvoiceWithNonNumericInvoiceNumber(){
    Draft_Invoice__c di = createDraftInvoice('N/A', Date.today().toStartOfMonth());
    insert di;

    Map<String,String> result = DraftInvoiceRefreshController.refreshDraftInvoice(di.id);
    List<String> resultKeyList = new list<string>(result.keySet());
    System.assertEquals(resultKeyList[0], 'error');
    System.assertEquals(result.get(resultKeyList[0]), 'Please provide a numeric invoice number.');
  }
}