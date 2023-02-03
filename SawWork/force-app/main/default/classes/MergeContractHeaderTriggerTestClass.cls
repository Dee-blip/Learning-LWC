@isTest(SeeAllData=false)
public class MergeContractHeaderTriggerTestClass
{
    private static Integer numberOfActiveTestAccounts=10;

    @testSetUp static void insertCustomSettingsAndCreateData()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            //utilTestClass.insertCustomSettings();
            utilTestClass.createCustomSettings();
            
            List<PMI_SKU__c> productSKUs = new List<PMI_SKU__c>();

            for(integer i=0;i<10;i++)
            {
                productSKUs.add(new PMI_SKU__c(Name='TestingCSC'+i, isValid__c=true, Marketing_Product_Id__c='MPI-00'+i, Parent_Product_Name__c='TestingCSC'+i, AKAM_SKU_ID__c='T-SKU09'+i));
            }

            insert productSKUs;

            List<Account> activeAccounts = new List<Account>();

            for(integer i=0;i<numberOfActiveTestAccounts+1;i++)
            {
                activeAccounts.add(new Account(Name='TCSC'+i, BillingCountry='USA', BillingPostalCode='67589', Type='Indirect Customer - Active'));
            }
            
            insert activeAccounts;

            
            List<Merge_Contract_Header__c> activeContracts = new List<Merge_Contract_Header__c>();
            List<Merge_Contract_Header__c> resellerList = new List<Merge_Contract_Header__c>();
            Merge_Contract_Header__c resellerContract = new Merge_Contract_Header__c(Name='MCHCSCR', Original_Contract_Id__c='MCHCSCR', Account_Name__c=activeAccounts[numberOfActiveTestAccounts].Id, Active__c=true, Contract_Type__c='Tier 1 Reseller', Parent_Account_Name__c=activeAccounts[numberOfActiveTestAccounts].Id,Effective_End_Date__c=Date.today());
            Merge_Contract_Header__c resellerContractWithoutParentAccount = new Merge_Contract_Header__c(Name='MCHCSCR', Original_Contract_Id__c='MCHCSCR-1', Account_Name__c=activeAccounts[numberOfActiveTestAccounts-1].Id, Active__c=true, Contract_Type__c='Tier 1 Reseller',Effective_End_Date__c=Date.today());
            resellerList.add(resellerContract);
            resellerList.add(resellerContractWithoutParentAccount);
            insert resellerList;
            Merge_Contract_Header__c resellerContractWithParent = new Merge_Contract_Header__c(Name='MCHCSC'+1, Original_Contract_Id__c='MCHCSC-2', Account_Name__c=activeAccounts[numberOfActiveTestAccounts-2].Id, Active__c=true, Contract_Type__c='Indirect Customer',Parent_Contract__c =resellerContractWithoutParentAccount.Id, Parent_Account_Name__c=activeAccounts[numberOfActiveTestAccounts-1].Id, Effective_End_Date__c=Date.Today());
            insert resellerContractWithParent;
            Merge_Contract_Header__c resellerContractWithParent2 = new Merge_Contract_Header__c(Name='MCHCSC'+2, Original_Contract_Id__c='MCHCSC-3', Account_Name__c=activeAccounts[numberOfActiveTestAccounts-3].Id, Active__c=true, Contract_Type__c='Indirect Customer',Parent_Contract__c =resellerContractWithParent.Id, Parent_Account_Name__c=activeAccounts[numberOfActiveTestAccounts-2].Id, Effective_End_Date__c=Date.Today());
            Merge_Contract_Header__c resellerContractWithParent3 = new Merge_Contract_Header__c(Name='MCHCSC'+3, Original_Contract_Id__c='MCHCSC-4', Account_Name__c=activeAccounts[numberOfActiveTestAccounts-4].Id, Active__c=true, Contract_Type__c='Indirect Customer',Parent_Contract__c =resellerContract.Id, Parent_Account_Name__c=activeAccounts[numberOfActiveTestAccounts-3].Id, Effective_End_Date__c=Date.Today());

            List<Merge_Contract_Header__c> resellerList1 = new List<Merge_Contract_Header__c>();
            
            resellerList1.add(resellerContractWithParent2);
            resellerList1.add(resellerContractWithParent3);
            //SFDC-1572
            List<Merge_Contract_Detail__c> detailList = new List<Merge_Contract_Detail__c>();
            insert resellerList1;
            

            for(integer i=0;i<numberOfActiveTestAccounts-1;i++)
            {
                activeContracts.add(new Merge_Contract_Header__c(Name='MCHCSC'+i, Original_Contract_Id__c='MCHCSC'+i, Account_Name__c=activeAccounts[i].Id, Active__c=true, Contract_Type__c='Indirect Customer',Parent_Contract__c =resellerList.get(0).Id, Parent_Account_Name__c=activeAccounts[numberOfActiveTestAccounts-i-1].Id, Effective_End_Date__c=Date.Today().addDays(-10)));
                activeContracts.add(new Merge_Contract_Header__c(Name='MCHCSC'+i, Original_Contract_Id__c='MCHCSC'+i+1, Account_Name__c=activeAccounts[i].Id, Active__c=true, Contract_Type__c='Indirect Customer',Parent_Contract__c =resellerList.get(1).Id, Parent_Account_Name__c=activeAccounts[numberOfActiveTestAccounts-i-1].Id, Effective_End_Date__c=Date.Today().addDays(10)));
                activeContracts.add(new Merge_Contract_Header__c(Name='MCHCSC'+i, Original_Contract_Id__c='MCHCSC'+i+2, Account_Name__c=activeAccounts[i].Id, Active__c=true, Contract_Type__c='Indirect Customer',Parent_Contract__c =resellerContractWithParent.Id, Parent_Account_Name__c=activeAccounts[numberOfActiveTestAccounts-i-1].Id, Effective_End_Date__c=Date.Today()));
                activeContracts.add(new Merge_Contract_Header__c(Name='MCHCSC'+i, Original_Contract_Id__c='MCHCSC'+i+3, Account_Name__c=activeAccounts[i].Id, Active__c=true, Contract_Type__c='Indirect Customer',Parent_Contract__c =resellerList1.get(0).Id, Parent_Account_Name__c=activeAccounts[numberOfActiveTestAccounts-i-1].Id, Effective_End_Date__c=Date.Today()));
                activeContracts.add(new Merge_Contract_Header__c(Name='MCHCSC'+i, Original_Contract_Id__c='MCHCSC'+i+4, Account_Name__c=activeAccounts[i].Id, Active__c=true, Contract_Type__c='Indirect Customer',Parent_Contract__c =resellerList1.get(1).Id, Parent_Account_Name__c=activeAccounts[numberOfActiveTestAccounts-i-1].Id, Effective_End_Date__c=Date.Today()));
                //detailList.add(utilTestClass.createContractDetail('test','test',activeContracts.get(i).id, System.today(), System.today().addDays(50)));
            }
            
            for(integer i=0;i<numberOfActiveTestAccounts-1;i++)
            {
                activeContracts.add(new Merge_Contract_Header__c(Name='MCHCSCD'+i, Original_Contract_Id__c='MCHCSCD'+i, Account_Name__c=activeAccounts[i].Id, Active__c=true, Contract_Type__c='Direct Customer', Effective_End_Date__c=Date.today()));
                //detailList.add(utilTestClass.createContractDetail('test','test',activeContracts.get(i).id, System.today(), System.today().addDays(70)));
            }

            insert activeContracts;
            for(integer i=0;i<2*(numberOfActiveTestAccounts-1);i++)
            {
                detailList.add(utilTestClass.createContractDetail('test','MPI-00'+i,activeContracts.get(i).id, System.today(), System.today().addDays(50)));
            }

            insert detailList;
        }
    }



    static testmethod void verifyCurrentSalesChannelCreation()
    {
        Test.startTest();
        CurrentSalesChannelBatchClass bClass = new CurrentSalesChannelBatchClass();
        Database.executeBatch(bClass);
        Test.stopTest();

        // verify that 2 CurrentSalesChannel records are created per account

        Integer indirectContractSummaries = [select count() from Current_Sales_Channel__c where Partner_Account__c!=null];
        System.assertEquals(indirectContractSummaries, 2*(numberOfActiveTestAccounts-1));

        Integer directSummaries = [select count() from Current_Sales_Channel__c where Partner_Account__c=null];

        System.assertEquals(directSummaries, numberOfActiveTestAccounts-1);

    }

    static testmethod void verifyPartnerMarketingProhibitedCheckbox()
    {
        Test.startTest();

        //verify that partner marketing prohibited is unchecked for all accounts in the beginning
        Integer numberProhibited = [select count() from Account where Channel_Marketing_Prohibited__c=false];
        System.assertEquals(numberProhibited, numberOfActiveTestAccounts+1);

        // update do not contact on all accounts
        List<Account> activeAccounts = [select id, Do_Not_Contact_Indirect_Customers__c, Validation_Override__c from Account limit 50000];
        for(Account acc : activeAccounts)
        {
            acc.Do_Not_Contact_Indirect_Customers__c=true;
            acc.Validation_Override__c=true;
        }

        update activeAccounts;

        // Run the batch job

        CurrentSalesChannelBatchClass bClass = new CurrentSalesChannelBatchClass();
        Database.executeBatch(bClass);
        Test.stopTest();

        
        // verify that partner marketing prohibited has been checked on all accounts now
        numberProhibited = [select count() from Account where Channel_Marketing_Prohibited__c=true];
        System.assertEquals(numberProhibited, numberOfActiveTestAccounts-1);
    }



    static testmethod void testCurrentSalesChannelBulkDeletion()
    {
        CurrentSalesChannelBatchClass bClass = new CurrentSalesChannelBatchClass(true);
        Database.executeBatch(bClass);
        
        List<Account> activeAccounts = [select id from account limit 50000];
        List<Merge_Contract_Header__c> activeContracts = [select id from Merge_Contract_Header__c where isdeleted=false AND Account_Name__c=:activeAccounts[numberOfActiveTestAccounts-2].id];
        
        for(Merge_Contract_Header__c mhc : activeContracts){
            mhc.Effective_End_Date__c = Date.today().addDays(-30);
        }
        update activeContracts;
        //run the deletion batch job

        Test.startTest();
        CurrentSalesChannelDeletionBatchClass bDelClass = new CurrentSalesChannelDeletionBatchClass();
        Database.executeBatch(bDelClass);
        Test.stopTest();

        //verify that few Current_Sales_Channel__c records get deleted

        System.assertEquals((2*(numberOfActiveTestAccounts-1))+(numberOfActiveTestAccounts-1)-3, [select count() from Current_Sales_Channel__c where isdeleted=false]);
    }

     static testmethod void testNAPMasterContractUpdate()
     {
         System.runAs(utilTestClass.getTestRunUser())
         {
             ManagedPkgErrorClass.isFromManagedPackage=false;
             Account testAcc=UtilTestClass.CreateAccount('testacc1');
             Test.startTest();

             insert(testAcc);

             List<Merge_Contract_Header__c> listOfMCH = new List<Merge_Contract_Header__c>();
             Merge_Contract_Header__c napMasterContract= createContractWithAkamId(testAcc.Id, 'randomContract12', null, 'B-I-433');
             listOfMCH.add(napMasterContract);

             Merge_Contract_Header__c newContract = createContractWithAkamId(testAcc.Id, 'randomContract11', null, 'B-I-432');
             newContract.Akam_NAP_Master_Contract_ID__c = napMasterContract.Original_Contract_Id__c;
             listOfMCH.add(newContract);

             insert listOfMCH;
             Test.stopTest();

             newContract = refreshMCH(newContract.Id);
             System.assertEquals(newContract.NAP_Master_Contract__c, napMasterContract.Id);
         }

     }

     static testmethod void testNAPMasterContractUpdateBulk()
     {
         System.runAs(utilTestClass.getTestRunUser())
         {
             ManagedPkgErrorClass.isFromManagedPackage=false;
             List<Id> listOfMCHIds = new List<Id>();
             Account testAcc=UtilTestClass.CreateAccount('testacc1');
             Test.startTest();

             insert(testAcc);

             Integer numberOfMCH = 100;
             List<Merge_Contract_Header__c> listOfMCH = new List<Merge_Contract_Header__c>();
             for(Integer i=0;i<100;i++)
             {
                 Merge_Contract_Header__c newContract= createContractWithAkamId(testAcc.Id, 'randomContract12', null, 'B-I-'+String.valueof(i));
                 if(i==0)
                 {
                     newContract.Akam_NAP_Master_Contract_ID__c='B-I-99';
                 }
                 else
                 {
                     newContract.Akam_NAP_Master_Contract_ID__c = 'B-I-'+String.valueof(i-1);
                 }

                 listOfMCH.add(newContract);
             }

             insert listOfMCH;
             for(Merge_Contract_Header__c tempMCH : listOfMCH)
             {
                 listOfMCHIds.add(tempMCH.Id);
             }

             Test.stopTest();

             listOfMCH = refreshMCHList(listOfMCHIds);
             for(Integer i=0;i<100;i++)
             {
                 if(i==0)
                 {
                     System.assertEquals(listOfMCH[i].NAP_Master_Contract__c, listOfMCH[99].Id);
                 }
                 else
                 {
                     System.assertEquals(listOfMCH[i].NAP_Master_Contract__c, listOfMCH[i-1].Id);

                 }

             }

         }

     }

      static testmethod void updateAccountPartnerTypeTest()
     {
        ManagedPkgErrorClass.isFromManagedPackage=false;

        Integer numOfTimes = 5;
             Test.startTest();
        //Create 5 Accounts
        /*List<Account> listOfTestAccounts = new List<Account>();
        List<Id> listOfIds = new List<Id>();
        for(Integer num =0; num<numOfTimes ; num++)
        {
            Account testAcc=UtilTestClass.CreateAccount('testacc'+String.valueof(num));
            listOfTestAccounts.add(testAcc);
            listOfIds.add(testAcc.Id);
        }

        Database.insert(listOfTestAccounts);

        //Update Partner Type for above 5 accounts to SRA Partner

        for( Account acc : listOfTestAccounts)
        {
            System.Debug('checkpoint x:' + acc);
            System.assertEquals(acc.get('Partner_status__c'), null);
            acc.put('Partner_Type__c', 'SRA Partner');
            System.Debug('checkpoint y:' + acc);
        }

        numOfTimes=5;
        Database.update(listOfTestAccounts);


        System.Debug('checkpoint z:' + listOfTestAccounts[0]);
        
        //Check the Partner Status changed and Create 5 Contracts for each Account
        List<Merge_Contract_Header__c> testContracts = new List<Merge_Contract_Header__c>();
        for( Account acc : [select Partner_status__c, Id from Account where Id in :listOfIds])
        {
            System.assertEquals(acc.get('Partner_status__c'), 'Prospect');
            for(Integer j =0 ; j<numOfTimes ; j++)
            {
                Merge_Contract_Header__c newContract = createContract(acc.Id, 'randomContract'+String.valueof(j), null);
                testContracts.add(newContract);
            }
        }
        Database.insert(testContracts);


        List<Merge_Contract_Header__c> testContractsAgain = new List<Merge_Contract_Header__c>();
    

        //Update Partner type for 25 Contracts
        for(Merge_Contract_Header__c testMCH : testContracts)
        {
             testMCH.Partner_Type__c = 'SI';
        }
        Database.update(testContracts);


        for( Account acc : [select Partner_status__c, Id from Account where Id in :listOfIds])
        {
            System.assertEquals(acc.get('Partner_status__c'), 'Partner');
        }
        */
        
        Account testAccount=UtilTestClass.CreateAccount('testingaccount');
        insert testAccount;
        
        //Partner Status Null > SRA Partner > Prospect >Partner
        Account fetchedAccount = [select Id, Partner_status__c from Account where id= :testAccount.Id];
        System.assertEquals(fetchedAccount.get('Partner_status__c'), null);

        Merge_Contract_Header__c newContract = createContract(testAccount.Id, 'random1', null);
        insert newContract;
        
        L2Q_AccountTriggerClass.handlePartnerTypeChangeFirstRunFlag = true;
        /*Account fetchedAccount2 = [select Id, Partner_status__c, Partner_Type__c from Account where id= :testAccount.Id];
        System.assertEquals(fetchedAccount2.get('Partner_status__c'), null);*/
        fetchedAccount.put('Partner_Type__c', 'SRA Partner');
        
        L2Q_AccountTriggerClass.handlePartnerTypeChangeFirstRunFlag = true;
        System.Debug('checkpoint a:'+fetchedAccount);
        update fetchedAccount;
        
        Account fetchedAccount3 = [select Id, Partner_status__c, Partner_Type__c from Account where id= :testAccount.Id];
        System.Debug('checkpoint b:'+fetchedAccount3);
        System.assertEquals(fetchedAccount3.get('Partner_status__c'), 'Prospect');

        newContract.Partner_Type__c = 'SI';
        update newContract;

        Account fetchedAccount4 = [select Id, Partner_status__c, Partner_Type__c from Account where id= :testAccount.Id];
        System.assertEquals(fetchedAccount4.get('Partner_status__c'), 'Partner');

        Account testAccount2=UtilTestClass.CreateAccount('testingaccount2');
        insert testAccount2;
        List<Merge_Contract_Header__c> mchList = new List<Merge_Contract_Header__c>();
        Merge_Contract_Header__c newContract2 = createContract(testAccount2.Id, 'random2', null);
        mchList.add(newContract2);
        //insert newContract2;

        Merge_Contract_Header__c newContract3 = createContract(testAccount2.Id, 'random3', 'SI');
        mchList.add(newContract3);
        //insert newContract3;

        insert mchList;

        Account fetchedAccount5 = [select Id, Partner_status__c, Partner_Type__c from Account where id= :testAccount2.Id];
        System.assertEquals(fetchedAccount5.get('Partner_status__c'), null);
        fetchedAccount5.put('Partner_Type__c', 'SRA Partner');
        L2Q_AccountTriggerClass.handlePartnerTypeChangeFirstRunFlag = true;
        update fetchedAccount5;
        
        Account fetchedAccount6 = [select Id, Partner_status__c, Partner_Type__c from Account where id= :testAccount2.Id];
        System.assertEquals(fetchedAccount6.get('Partner_status__c'), 'Partner');

        Account testAccount3=UtilTestClass.CreateAccount('testingaccount3');
        testAccount3.put('Partner_Type__c', 'SRA Partner');
        insert testAccount3;
        Merge_Contract_Header__c newContract4 = createContract(testAccount3.Id, 'random4', 'SI');
        insert newContract4;
        
        Account fetchedAccount7 = [select Id, Partner_status__c, Partner_Type__c from Account where id= :testAccount3.Id];
        System.assertEquals(fetchedAccount7.get('Partner_status__c'), 'Partner');

        //CR 2808039 - rsharma - increase code coverage of MergeContractHeaderTriggerClass class
        //--> Addition of new Code to Test isBlank(contract.Partner_Type__c)
        //--> Pass blank Partner Type to createContract
        Account testAccount4=UtilTestClass.CreateAccount('testingaccount4');
        testAccount4.put('Partner_Type__c', 'SRA Partner');
        insert testAccount4;
        Merge_Contract_Header__c newContract5 = createContract(testAccount3.Id, 'random4', 'SI');
        insert newContract5;
        newContract5.Partner_Type__c = '';
        update newContract5;
        List<Account> fetchedAccount8 = [select Id, Partner_status__c, Partner_Type__c from Account where id= :testAccount4.Id];
            if(fetchedAccount8!=null)
                System.assertEquals(fetchedAccount8.get(0).get('Partner_status__c'), null);
                             Test.stopTest();

      }

      static testmethod void testMethodForCoverege(){
          //Account Creation
          List<Account> accList = new List<Account>();
          Account acc1 = utilTestClass.CreateAccount('__Test Account1');
          accList.add(acc1);
          
          Account acc2 = utilTestClass.CreateAccount('__Test Account2');
          accList.add(acc2);
          insert accList;
          
          //Opportunity Creation
          List<Opportunity> oppList = new List<Opportunity>();
          Opportunity opp1 = utilTestClass.CreateOpportunity('__Test Oppty1','1-Create');
          opp1.AccountId = acc1.Id;
          opp1.CloseDate = Date.today().addDays(30);    
          oppList.add(opp1);    
          
          Opportunity opp2 = utilTestClass.CreateOpportunity('__Test Oppty2','1-Create');
          opp2.AccountId = acc2.Id;
          opp2.CloseDate = Date.today().addDays(30);    
          oppList.add(opp2);    
          insert oppList;
          
          Merge_Contract_Header__c contract1 = createContract(acc1.Id, 'random2', null);
          contract1.Opportunity_Name__c = opp1.Id;
          insert contract1;
          
          contract1.Account_Name__c = acc2.Id;
          contract1.Opportunity_Name__c = opp2.Id;
          update contract1;
          
      }

      public static Merge_Contract_Header__c createContract(String accountId, String name, String partnerType)
      {
        Merge_Contract_Header__c newContract = new Merge_Contract_Header__c();
        newContract.Account_Name__c = accountId;
        newContract.Name = name;
        newContract.Partner_Type__c = partnerType;
        return newContract;
      }

      public static Merge_Contract_Header__c createContractWithAkamId(String accountId, String name, String partnerType, String akamId)
      {
        Merge_Contract_Header__c newContract = createContract(accountId, name, partnerType);
        newContract.Original_Contract_Id__c= akamId;
        return newContract;
      }

      public static Merge_Contract_Header__c refreshMCH(String mchId)
      {
          return [select id, NAP_Master_Contract__c from Merge_Contract_Header__c where id= :mchId];
      }

      public static List<Merge_Contract_Header__c> refreshMCHList(List<Id> mchIdList)
      {
          return [select id, NAP_Master_Contract__c from Merge_Contract_Header__c where id in :mchIdList];
      }

}