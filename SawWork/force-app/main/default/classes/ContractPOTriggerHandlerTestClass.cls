@isTest

public class ContractPOTriggerHandlerTestClass {

  



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
                    activeAccounts.add(new Account(Name='TCSC'+i, BillingCountry='USA',BillingPostalCode='87987', ShippingCountry='United States Of America',Type='Indirect Customer - Active', Website='www.testinacc'+i+'.com', BillingState='MA', Anaplan_Sub_Territory__c='Multiple', Vertical__c='Public Sector', Sub_Vertical__c='PS - Higher Ed'));
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
          inv.CurrencyIsoCode = 'INR';
          invoiceList.add(inv);
        }

        insert invoiceList;
      }
        //Create Contract Purchase Orders
        List<Merge_Contract_PO__c> mchPOList = new List<Merge_Contract_PO__c>();
        for(Integer i=0;i<2;i++) {
            Merge_Contract_PO__c mchPO = new Merge_Contract_PO__c();
            mchPO.Original_Contract_Id__c = mchList[i].Id;
            mchPO.PO_Fund__c = 1000;
                Integer numDays = 10 ;

            mchPO.Start_Date__c = Date.today().addDays(-Integer.valueOf(numDays));
            mchPO.End_Date__c = Date.today().addDays(+Integer.valueOf(numDays));
            mchPO.CurrencyIsoCode = 'EUR';
            mchPOList.add(mchPO);
          }

          insert mchPOList;



        }
    }
    
       @isTest static void updateRemainingFundMethodtestMethod() {

        
          List<Merge_Contract_Header__c> mchList = [Select Id From Merge_Contract_Header__c limit 2];
      
          List<Invoice__c> invList = [Select Invoice_Date__c ,Original_Contract_Id__c,CurrencyIsoCode From Invoice__c limit 2];
          invList[0].CurrencyIsoCode = 'INR';

          Integer numDays = 20 ;

          invList[1].CurrencyIsoCode = 'AUD';
          invList[1].Invoice_Date__c = Date.today().addDays(+Integer.valueOf(numDays));
          Test.startTest();                

          update invList;

          List<Merge_Contract_PO__c> mchPOList = [Select Original_Contract_Id__c,Start_Date__c,End_Date__c,Remaining_Fund__c From Merge_Contract_PO__c limit 2];
          Integer numDays2 = 15 ;
          Integer numDays3 = 25;
          mchPOList[0].Start_Date__c = Date.today().addDays(+Integer.valueOf(numDays2));
          mchPOList[0].End_Date__c = Date.today().addDays(+Integer.valueOf(numDays2));

          mchPOList[1].PO_Fund__c = 500;

          update mchPOList;

          Test.stopTest();

          system.assertEquals(mchPOList[0].Remaining_Fund__c>0,true);
          system.assertEquals(mchPOList[1].Remaining_Fund__c>0,true);



     }

     @isTest static void ContractInvoiceTriggerHandlertestMethod() {

        
          List<Merge_Contract_Header__c> mchList = [Select Id From Merge_Contract_Header__c limit 2];
      
          Invoice__c inv = new Invoice__c();
          inv.Original_Amount__c = 200;
          inv.Original_Contract_Id__c = mchList[0].Id;
          inv.Invoice_Date__c = Date.Today();
          inv.CurrencyIsoCode = 'INR';
          
          Test.startTest();                

          insert inv;

          List<Merge_Contract_PO__c> mchPOList = [Select Original_Contract_Id__c,Start_Date__c,End_Date__c,Remaining_Fund__c From Merge_Contract_PO__c limit 2];


          Test.stopTest();
          system.assertEquals(mchPOList[0].Remaining_Fund__c>0,true);


     }


 
    
 
}