/* History:
 * =========================
 *  @author     Hitesh Chawda,     5th June'17
    Test class for SendEmail_PurchaseOrder_AccountCollector
    SFDC-1483
 */
@isTest
public class SendEmail_PO_AccountCollectorTestClass {
    @testSetUp static void createTestData()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            utilTestClass.insertCustomSettings();

            Map<String,GSM_Settings__mdt> testcaseCustomSettings = GsmUtilClass.getGsmSettingValue();
            
            User accOwner = utilTestClass.CreateUser('TSaOps', testcaseCustomSettings.get('User_Role').Value__c, 'Sales Operations');
            insert accOwner; 

            User sysAdmin = utilTestClass.CreateUser('TSysAd', 'Worldwide', 'CRM Integration');
            insert sysAdmin;      
            
            Account_Reassignment_Rule__c rule = utilTestClass.CreateAccountReassignmentRule('__TestRule', accOwner.Id, testcaseCustomSettings.get('User_Role').Value__c);         
            rule.SubTerritory__c='Multiple';
            insert rule;

            List<Account> activeAccounts = new List<Account>();


            System.runAs(accOwner)
            {

                for(integer i=0;i<2;i++)
                {
                    activeAccounts.add(new Account(Name='TCSC'+i, BillingCountry='USA', BillingPostalCode='56789', ShippingCountry='United States Of America',Type='Indirect Customer - Active', Website='testinacc'+i+'.com', BillingState='MA', Anaplan_Sub_Territory__c='Multiple', Vertical__c='Public Sector', Sub_Vertical__c='PS - Higher Ed'));
                }

                insert activeAccounts;

            }


            //Create Contracts
            List<Merge_Contract_Header__c> mchList = new list<Merge_Contract_Header__c>();
            
            for(Integer i=0;i<2;i++) {

              Merge_Contract_Header__c newHeader = new Merge_Contract_Header__c();
              newHeader.Original_Contract_Id__c = 'abcd'+i;
              newHeader.Name = 'abcd'+i;
              newHeader.Effective_End_Date__c = Date.today();
              newHeader.Account_Name__c = activeAccounts[i].Id; 
              newHeader.Active__c= true;
              mchList.add(newHeader);
            }
            
            insert mchList;

            //Create Invoices for contracts
system.runAs(sysAdmin)
{
          List<Invoice__c> invoiceList = new List<Invoice__c>();

        for(Integer i=0;i<2;i++)
        {
          Invoice__c inv = new Invoice__c();
          inv.Original_Amount__c = 200;
          inv.Original_Contract_Id__c = mchList[i].Id;
          inv.Invoice_Date__c = Date.Today();
          inv.CurrencyIsoCode = 'EUR';
          invoiceList.add(inv);
        }

        insert invoiceList;
      }
        //Create Contract Purchase Orders
        List<Merge_Contract_PO__c> mchPOList = new List<Merge_Contract_PO__c>();
        for(Integer i=0;i<2;i++) {
            Merge_Contract_PO__c mchPO = new Merge_Contract_PO__c();
            mchPO.Original_Contract_Id__c = mchList[i].Id;
            mchPO.PO_Fund__c = 250;
                Integer numDays = 10 ;

            mchPO.Start_Date__c = Date.today().addDays(-Integer.valueOf(numDays));
            mchPO.End_Date__c = Date.today().addDays(+Integer.valueOf(numDays));
            mchPO.CurrencyIsoCode = 'EUR';
            mchPOList.add(mchPO);
          }

          insert mchPOList;



        }
    }

    static testmethod void testMethod1() {

        List<Account> accList = new List<Account>();
        accList = [ Select Id,Collector__c From Account limit 2];
        User collector = [ Select Id From User  Where alias ='TSaOps'];
        accList[0].Collector__c = collector.Id;
        Test.startTest(); 
        update accList;

        Cron_Batch_Job__c testBatchJob = utilTestClass.createCronBatchJob('Purchase Order Account Collector Email','Purchase Order Account Collector Email');
        insert testBatchJob;
        Cron_Batch_Run__c testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
        insert testBatchRun;
        testBatchRun.Trigger_Batch_Run__c = true;
        update testBatchRun;
        System.enqueueJob(new SendEmail_PurchaseOrder_AccountCollector());
        Test.stopTest();
       
    }
    

}