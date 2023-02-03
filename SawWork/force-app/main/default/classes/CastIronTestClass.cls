/***
    CastIronTestClass
    - Tests the functions implemented in CastIronClass.
    - Covering the following scenarious for each Cast Iron Resolve:
        => Single Postive
        => Single Negative
        => Bulk Positive
    
    @History
    --Developer           --Date            --Change
    Karteek Kumar M       09/08/2010        Created the class as per CR 737434 Add reference key triggers to custom objects.
    Karteek Kumar M       10/08/2010        More test cases :
                                            - Manual List resolves
                                            - Purchase Orders resolves
    Chandra Mohan Lohani  24/09/2010        More test Cases:
                                              Invoice Foriegn Key relationship with Account and Contract header
                                              CR 1735546 Invoice Security
    Ali KM                09/Jul/2012       CR 1735546 Invoice Security
                                              Added an assertion to verify the Account.Max_Invoice_Date__c is equal to Invoice.Invoice_Date__c.
                                               
    Pramod Kamath V       15/04/2013        CR 2181485- IR Case:Need to roll-up/add code to update ManualList flag from Contract Manual List.      
                                           
    
 */
@isTest(seeAlldata = false)
public class CastIronTestClass 
{
    /**
      CreateAccount()
     */
    /*
       private static Account CreateAccount(String pAccName)
       {
       Account newAccount = new Account();
       newAccount.Name = pAccName;
       newAccount.BillingCountry = 'India';
       return newAccount;
       }*/
    /**
      CreateOpportunity()
     */

    /*     static{
           utilTestClass.insertCustomSettings();
           } */
    
    @testSetup static void setup() {
        
        Test.startTest();
        
         List<GSM_Custom_Settings__c> gsmCustomSettings = new List<GSM_Custom_Settings__c>();
                GSM_Custom_Settings__c crmIntSetting = new GSM_Custom_Settings__c();
                crmIntSetting.Name = 'CRM_Integration';
                crmIntSetting.Value__c = '005A0000000NHQc';
                gsmCustomSettings.add(crmIntSetting);
        
        insert gsmCustomSettings;
        Test.stopTest();
    }
    
    private static Opportunity CreateOpportunity(String pOppName, Id pAccId)
    {
        Opportunity newOpp = new Opportunity();
        newOpp.Name = pOppName;
        newOpp.AccountId = pAccId;
        newOpp.StageName = '1-Create';
        newOpp.CloseDate = Date.today().addMonths(4);       
        return newOpp;
    }   
    /**
      CreateContractHeader()
     */  
    public static Merge_Contract_Header__c CreateContractHeader(String pOrignalContractId, Id pAccountId)
    {
        Merge_Contract_Header__c newHeader = new Merge_Contract_Header__c();
        newHeader.Original_Contract_Id__c = pOrignalContractId;
        newHeader.Name = pOrignalContractId;
        newHeader.Account_Name__c = pAccountId;     
        return newHeader;
    }
    /**
      CreateContractAcitivty()
     */  
    private static Merge_Contract_Activity__c CreateContractAcitivty (String pActivityId, String pCI_OriginalContractId)
    {
        Merge_Contract_Activity__c newActivity = new Merge_Contract_Activity__c();
        newActivity.CI_Original_Contract_Id__c = pCI_OriginalContractId;
        newActivity.Activity_Id__c = pActivityId;
        return newActivity;
    }
    /**
      CreateContractPO()
     */  
    private static Merge_Contract_PO__c CreateContractPO (String pOrderId, String pCI_OriginalContractId)
    {
        Merge_Contract_PO__c newOrder = new Merge_Contract_PO__c();
        newOrder.CI_Original_Contract_Id__c = pCI_OriginalContractId;
        newOrder.PO_Number__c = pOrderId;
        return newOrder;
    }   
    /**
      CreateContractMList()
     */  
    private static Merge_Contract_Manual_List__c CreateContractMList (String pMListId, String pCI_OriginalContractId)
    {
        Merge_Contract_Manual_List__c newMList = new Merge_Contract_Manual_List__c();
        newMList.CI_Original_Contract_Id__c = pCI_OriginalContractId;
        newMList.Manual_List_Id__c = pMListId;
        return newMList;
    }
    /**
      Added By Chandra
      CreateInvoice()
     */  
    public static Invoice__c Createinvoice (String pInvoiceId, String pCI_accountId,String contractId)
    {
        Invoice__c newInvoice = new Invoice__c();
        newInvoice.CI_Account_Name__c = pCI_accountId;
        newInvoice.CI_Original_Contract_Id__c=contractId;
        newInvoice.Invoice_Date__c= Date.today();
        newInvoice.Name = pInvoiceId;
        return newInvoice;
    }
    /*
       Added by chandra
       create Contact
     */
    /*
       private static Contact createContact(String name, Id accId)
       {
       Contact con=new Contact();
       con.LastName=name;
       con.AccountId=accId;
       con.FirstName='Common';
       return con;
       }*/     
    /**
      RefreshContractActivity()
      - Overloaded to refresh Single Activity
     */
    private static Merge_Contract_Activity__c RefreshContractActivity(Merge_Contract_Activity__c pActivity)
    {
        return RefreshContractActivity(new List<Merge_Contract_Activity__c> {pActivity})[0];
    }
    /**
      RefreshContractActivity()
      - Overloaded to refresh bulk Activities
     */
    private static List<Merge_Contract_Activity__c> RefreshContractActivity(List<Merge_Contract_Activity__c> pActivityList)
    {
        return [select Id,
               Original_Contract_Id__c
                   from 
                   Merge_Contract_Activity__c 
                   where Id IN :pActivityList];
    }
    /**
      RefreshContractPO()
      - Overloaded to refresh Single Purchase Order
     */
    private static Merge_Contract_PO__c RefreshContractPO(Merge_Contract_PO__c pOrder)
    {
        return RefreshContractPO(new List<Merge_Contract_PO__c> {pOrder})[0];
    }
    /**
      RefreshContractPO()
      - Overloaded to refresh bulk Purchase Orders
     */
    private static List<Merge_Contract_PO__c> RefreshContractPO(List<Merge_Contract_PO__c> pOrderList)
    {
        return [select Id,
               Original_Contract_Id__c
                   from 
                   Merge_Contract_PO__c 
                   where Id IN :pOrderList];
    }
    /**
      RefreshContractMList()
      - Overloaded to refresh Single Manua List
     */
    private static Merge_Contract_Manual_List__c RefreshContractMList(Merge_Contract_Manual_List__c pMList)
    {
        return RefreshContractMList(new List<Merge_Contract_Manual_List__c> {pMList})[0];
    }
    /**
      RefreshContractMList()
      - Overloaded to refresh bulk Manua Lists
     */
    private static List<Merge_Contract_Manual_List__c> RefreshContractMList(List<Merge_Contract_Manual_List__c> pMList)
    {
        return [select Id,
               Original_Contract_Id__c
                   from 
                   Merge_Contract_Manual_List__c 
                   where Id IN :pMList];
    }
    /**
      Added By Chandra
      refreshInvoice()
     */
    private static Invoice__c refreshInvoice(Invoice__c pInvoice)
    {
        return refreshInvoiceList(new List<Invoice__c> {pInvoice})[0];
    }
    /**
      Added By Chandra
      refreshInvoiceList()
     */
    private static List<Invoice__c> refreshInvoiceList(List<Invoice__c> pInvoiceList)
    {
        return [select Id
            ,Account_Name__c
            ,Original_Contract_Id__c
            ,Invoice_Date__c
            from
            Invoice__c
            where Id IN:pInvoiceList];
    }
    /**
      Added By Ali
      refreshAccount()
     */
    private static Account refreshAccount(Account pAccount)
    {
        return refreshAccountList(new List<Account> {pAccount})[0];
    }
    /**
      Added By Ali
      refreshAccountList()
     */
    private static List<Account> refreshAccountList(List<Account> pAccountList)
    {
        return [select Id
            ,Name
            ,Max_Invoice_Date__c
            from
            Account
            where Id IN:pAccountList];
    }
    /**
      Added by Chandra
      refreshContractHeaderList()

     */
    private static List<Merge_Contract_Header__c> refreshContractHeaderList(List<Merge_Contract_Header__c> contractList)
    {
        return [select Id,Account_Name__c,Bill_To_Contact__C,Contract_transferred_To__c,Opportunity_Name__c
            ,Parent_Account_Name__c,Parent_Contract__C,Referred_By_Account__C, Manual_list__c From Merge_Contract_Header__c where id IN :contractList];
    }
    /**
      Added By Chandra
      refreshContractHeader()
     */
    private static Merge_Contract_Header__c refreshContractHeader(Merge_Contract_Header__c contract)
    {
        return refreshContractHeaderList(new List<Merge_Contract_Header__c> {contract})[0];
    }
    /**
      Added by Chandra
      refreshContractDetailList()

     */
    private static List<Merge_Contract_Detail__c> refreshContractDetailList(List<Merge_Contract_Detail__c> conDetailList)
    {
        return [select Id,Original_Contract_Id__C From Merge_Contract_Detail__c where id IN :conDetailList];
    }

    /**
      Added By Chandra
      refreshContractDetail()
     */
    private static Merge_Contract_Detail__c refreshContractDetail(Merge_Contract_Detail__c conDetail)
    {
        return refreshContractDetailList(new List<Merge_Contract_Detail__c> {conDetail})[0];
    }               
    /**
      Resolve_MergeContractActivity_ContractHeaderForeginKeys_SingleTest_Positive()
      - Single
      - Positive
     */  
    static testMethod void Resolve_MergeContractActivity_ContractHeaderForeginKeys_SingleTest_Positive() 
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            // Create required Records
            //Account acc = CreateAccount('_##Test Account 1');
            Account acc = utilTestClass.CreateAccount('_##Test Account 1');
            insert acc;
            Merge_Contract_Header__c header = CastIronTestClass.CreateContractHeader('#Test-FC-MCH1', acc.Id);
            insert header;

            // Use the CI field to associate to Header.
            Test.startTest();
            Merge_Contract_Activity__c activity = CastIronTestClass.CreateContractAcitivty('#Test-FC-MCA1', '#Test-FC-MCH1');
            insert activity;
            Test.stopTest();

            // Refresh
            activity = CastIronTestClass.RefreshContractActivity(activity);

            // Assert
            system.assertEquals(activity.Original_Contract_Id__c, header.Id);
        }
    }
    /**
      Resolve_MergeContractActivity_ContractHeaderForeginKeys_SingleTest_Negative()
      - Single
      - Negative
     */  
    static testMethod void Resolve_MergeContractActivity_ContractHeaderForeginKeys_SingleTest_Negative() 
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            // Create required Records
            //Account acc = CreateAccount('_##Test Account 1');
            Account acc = utilTestClass.CreateAccount('_##Test Account 1');
            insert acc;

            Merge_Contract_Header__c header = CastIronTestClass.CreateContractHeader('#Test-FC-MCH1', acc.Id);
            insert header;

            // Use the CI field to associate to Header.
            Test.startTest();
            Boolean negativeCheckFlag = false;
            try
            {
                Merge_Contract_Activity__c activity = CastIronTestClass.CreateContractAcitivty('#Test-FC-MCA1', '#INVALID');
                insert activity;
            }
            catch(Exception e)
            {
                system.assert(e.getMessage().contains('Invalid Contract Header Id'));
                negativeCheckFlag = true;
            }
            Test.stopTest();

            // Assert
            system.assertEquals(negativeCheckFlag, true);
        }
    }  
    /**
      Resolve_MergeContractActivity_ContractHeaderForeginKeys_BulkTest_Positive()
      - Bulk
      - Positive
     */      
    static testMethod void Resolve_MergeContractActivity_ContractHeaderForeginKeys_BulkTest_Positive() 
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            // Create required Records
            Integer i;
            //Account acc = CreateAccount('_##Test Account 1');
            Account acc = utilTestClass.CreateAccount('_##Test Account 1');
            insert acc;

            // Create 100 Headers
            List<Merge_Contract_Header__c> headerList = new List<Merge_Contract_Header__c>();
            for(i=0;i<100;i++)
                headerList.add(CastIronTestClass.CreateContractHeader('#Test-FC-MCH' + i, acc.Id));
            insert headerList;

            // Use the CI field to associate 100 Activities to 100 Header.
            Test.startTest();
            List<Merge_Contract_Activity__c> activityList = new List<Merge_Contract_Activity__c>();
            for(i=0;i<100;i++)              
                activityList.add(CastIronTestClass.CreateContractAcitivty('#Test-FC-MCA' + i, '#Test-FC-MCH' + i));
            insert activityList;
            Test.stopTest();

            // Refresh
            activityList = CastIronTestClass.RefreshContractActivity(activityList);

            // Assert
            for(i=0;i<100;i++)      
                system.assertEquals(activityList[i].Original_Contract_Id__c, headerList[i].Id);
        }
    }
    /**
      Resolve_MergeContractPO_ContractHeaderForeginKeys_SingleTest_Positive()
      - Single
      - Positive
     */  
    static testMethod void Resolve_MergeContractPO_ContractHeaderForeginKeys_SingleTest_Positive() 
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            // Create required Records
            //Account acc = CreateAccount('_##Test Account 1');
            Account acc = utilTestClass.CreateAccount('_##Test Account 1');
            insert acc;
            Merge_Contract_Header__c header = CastIronTestClass.CreateContractHeader('#Test-FC-MCH1', acc.Id);
            insert header;

            // Use the CI field to associate to Header.
            Test.startTest();
            Merge_Contract_PO__c order = CastIronTestClass.CreateContractPO('#Test-FC-MCPO1', '#Test-FC-MCH1');
            insert order;
            Test.stopTest();

            // Refresh
            order = CastIronTestClass.RefreshContractPO(order);

            // Assert
            system.assertEquals(order.Original_Contract_Id__c, header.Id);
        }
    }    
    /**
      Resolve_MergeContractPO_ContractHeaderForeginKeys_SingleTest_Negative()
      - Single
      - Negative
     */  
    static testMethod void Resolve_MergeContractPO_ContractHeaderForeginKeys_SingleTest_Negative() 
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            // Create required Records
            //Account acc = CreateAccount('_##Test Account 1');
            Account acc = utilTestClass.CreateAccount('_##Test Account 1');
            insert acc;
            Merge_Contract_Header__c header = CastIronTestClass.CreateContractHeader('#Test-FC-MCH1', acc.Id);
            insert header;

            // Use the CI field to associate to Header.
            Test.startTest();
            Boolean negativeCheckFlag = false;
            try
            {
                Merge_Contract_PO__c order = CastIronTestClass.CreateContractPO('#Test-FC-MCA1', '#INVALID');
                insert order;
            }
            catch(Exception e)
            {
                system.assert(e.getMessage().contains('Invalid Contract Header Id'));
                negativeCheckFlag = true;
            }
            Test.stopTest();

            // Assert
            system.assertEquals(negativeCheckFlag, true);
        }
    }   
    /**
      Resolve_MergeContractPO_ContractHeaderForeginKeys_BulkTest_Positive()
      - Bulk
      - Positive
     */      
    static testMethod void Resolve_MergeContractPO_ContractHeaderForeginKeys_BulkTest_Positive() 
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            // Create required Records
            Integer i;
            //Account acc = CreateAccount('_##Test Account 1');
            Account acc = utilTestClass.CreateAccount('_##Test Account 1');
            insert acc;

            // Create 100 Headers
            List<Merge_Contract_Header__c> headerList = new List<Merge_Contract_Header__c>();
            for(i=0;i<100;i++)
                headerList.add(CastIronTestClass.CreateContractHeader('#Test-FC-MCH' + i, acc.Id));
            insert headerList;

            // Use the CI field to associate 100 Activities to 100 Header.
            Test.startTest();
            List<Merge_Contract_PO__c> orderList = new List<Merge_Contract_PO__c>();
            for(i=0;i<100;i++)              
                orderList.add(CastIronTestClass.CreateContractPO('#Test-FC-MCPO' + i, '#Test-FC-MCH' + i));
            insert orderList;
            Test.stopTest();

            // Refresh
            orderList = CastIronTestClass.RefreshContractPO(orderList);

            // Assert
            for(i=0;i<100;i++)      
                system.assertEquals(orderList[i].Original_Contract_Id__c, headerList[i].Id);
        }
    }   
    /**
      Resolve_MergeContractMList_ContractHeaderForeginKeys_SingleTest_Positive()
      - Single
      - Positive
     */  
    static testMethod void Resolve_MergeContractMList_ContractHeaderForeginKeys_SingleTest_Positive() 
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            // Create required Records
            //Account acc = CreateAccount('_##Test Account 1');
            Account acc = utilTestClass.CreateAccount('_##Test Account 1');
            insert acc;
            Merge_Contract_Header__c header = CastIronTestClass.CreateContractHeader('#Test-FC-MCH1', acc.Id);
            insert header;

            // Use the CI field to associate to Header.
            Test.startTest();
            Merge_Contract_Manual_List__c mlist = CastIronTestClass.CreateContractMList('#Test-FC-MCML1', '#Test-FC-MCH1');
            insert mlist;
            Test.stopTest();

            // Refresh
            mlist = CastIronTestClass.RefreshContractMList(mlist);

            // Assert
            system.assertEquals(mlist.Original_Contract_Id__c, header.Id);
        }
    }   
    /**
      Resolve_MergeContractMList_ContractHeaderForeginKeys_SingleTest_Negative()
      - Single
      - Negative
     */  
    static testMethod void Resolve_MergeContractMList_ContractHeaderForeginKeys_SingleTest_Negative() 
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            // Create required Records
            //Account acc = CreateAccount('_##Test Account 1');
            Account acc = utilTestClass.CreateAccount('_##Test Account 1');
            insert acc;
            Merge_Contract_Header__c header = CastIronTestClass.CreateContractHeader('#Test-FC-MCH1', acc.Id);
            insert header;

            // Use the CI field to associate to Header.
            Test.startTest();
            Boolean negativeCheckFlag = false;
            try
            {
                Merge_Contract_Manual_List__c mlist = CastIronTestClass.CreateContractMList('#Test-FC-MCML1', '#INVALID');
                insert mlist;
            }
            catch(Exception e)
            {
                system.assert(e.getMessage().contains('Invalid Contract Header Id'));
                negativeCheckFlag = true;
            }
            Test.stopTest();

            // Assert
            system.assertEquals(negativeCheckFlag, true);
        }
    }         
    /**
      Resolve_MergeContractMList_ContractHeaderForeginKeys_BulkTest_Positive()
      - Bulk
      - Positive
     */      
    static testMethod void Resolve_MergeContractMList_ContractHeaderForeginKeys_BulkTest_Positive() 
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            // Create required Records
            Integer i;
            //Account acc = CreateAccount('_##Test Account 1');
            Account acc = utilTestClass.CreateAccount('_##Test Account 1');
            insert acc;

            // Create 100 Headers
            List<Merge_Contract_Header__c> headerList = new List<Merge_Contract_Header__c>();
            for(i=0;i<100;i++)
                headerList.add(CastIronTestClass.CreateContractHeader('#Test-FC-MCH' + i, acc.Id));
            insert headerList;

            // Use the CI field to associate 100 Activities to 100 Header.
            Test.startTest();
            List<Merge_Contract_Manual_List__c> mList = new List<Merge_Contract_Manual_List__c>();
            for(i=0;i<100;i++)              
                mList.add(CastIronTestClass.CreateContractMList('#Test-FC-MCML' + i, '#Test-FC-MCH' + i));
            insert mList;
            Test.stopTest();

            // Refresh
            mList = CastIronTestClass.RefreshContractMList(mList);

            // Assert
            for(i=0;i<100;i++)      
                system.assertEquals(mList[i].Original_Contract_Id__c, headerList[i].Id);
        }
    } 
    /**
      Resolve_Inovice_ContractHeader_Account_ForeignKeys_SingleTest_Positive()
      - Single
      - Positiveative
     */  
    static testMethod void Resolve_Inovice_ContractHeader_Account_ForeignKeys_SingleTest_Positive() 
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            // Create required Records
            //Account acc = CreateAccount('_##Test Account 1');
            Account acc = utilTestClass.CreateAccount('_##Test Account 1');
            acc.AKAM_Account_ID__c='F-AC-Test';
            insert acc;

            Merge_Contract_Header__c con=new Merge_Contract_Header__c();
            con=CreateContractHeader('_##Test Conract ',acc.Id);
            insert con;
            // Use the CI field to associate to Account.
            Test.startTest();

            Invoice__c newInvoice = CastIronTestClass.CreateInvoice('#Test-FC-Invoice', acc.AKAM_Account_ID__c,con.Original_Contract_Id__c);
            insert newInvoice;

            Test.stopTest();
            //refresh Invoice
            newInvoice=refreshInvoice(newInvoice);

            // Assert
            system.assertEquals(newInvoice.Original_Contract_Id__c, con.ID);
            system.assertEquals(newInvoice.Account_Name__c, acc.ID);

            //refresh Account
            acc = refreshAccount(acc);
            system.assertEquals(newInvoice.Invoice_Date__c, acc.Max_Invoice_Date__c);
        }
    }   

    /**
      Resolve_Inovice_ContractHeader_ForeignKeys_SingleTest_Negative()
      - Single
      - Negative
     */  
    static testMethod void Resolve_Inovice_ContractHeader_ForeignKeys_SingleTest_Negative() 
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            // Create required Records
            //Account acc = CreateAccount('_##Test Account 1');
            Account acc = utilTestClass.CreateAccount('_##Test Account 1');
            acc.AKAM_Account_ID__c='F-AC-Test';
            insert acc;

            Merge_Contract_Header__c con=new Merge_Contract_Header__c();
            con=CreateContractHeader('_##Test Conract ',acc.Id);
            insert con;
            // Use the CI field to associate to Account.
            Test.startTest();
            Boolean negativeCheckFlag = false;
            try
            {
                Invoice__c newInvoice = CastIronTestClass.CreateInvoice('#Test-FC-Invoice', acc.AKAM_Account_ID__c,'#INVALID');
                insert newInvoice;
            }
            catch(Exception e)
            {
                system.assert(e.getMessage().contains('Invalid Contract Header Id'));
                negativeCheckFlag = true;
            }

            Test.stopTest();

            // Assert
            system.assertEquals(negativeCheckFlag, true);
        }
    }   
    /**
      Resolve_Inovice_AccountForeginKeys_SingleTest_Negative()
      - Single
      - Negative
     */  
    static testMethod void Resolve_Inovice_Account_ForeignKeys_SingleTest_Negative() 
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            // Create required Records
            //Account acc = CreateAccount('_##Test Account 1');
            Account acc = utilTestClass.CreateAccount('_##Test Account 1');
            acc.AKAM_Account_ID__c='F-AC-Test';
            insert acc;

            Merge_Contract_Header__c con=new Merge_Contract_Header__c();
            con=CreateContractHeader('_##Test Conract ',acc.Id);
            insert con;
            // Use the CI field to associate to Account.
            Test.startTest();
            Boolean negativeCheckFlag = false;
            try
            {
                Invoice__c newInvoice = CastIronTestClass.CreateInvoice('#Test-FC-Invoice', '#INVALID',con.Original_Contract_Id__c);
                insert newInvoice;
            }
            catch(Exception e)
            {
                system.assert(e.getMessage().contains('Invalid Account Id'));
                negativeCheckFlag = true;
            }

            Test.stopTest();

            // Assert
            system.assertEquals(negativeCheckFlag, true);
        }
    }   
    /**
      Test method added By Chandra
      Resolve_Invoice_ContractHeader_Account_ForeignKeys_BulkTest_Positive()
      -Bulk
      -Positive
     */          
     /*
    static testMethod void Resolve_Invoice_ContractHeader_Account_ForeignKeys_BulkTest_Positive()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            //create Account
            Integer i;
            List <Account> accList=new List<Account>();
            for(i=0;i<100;i++)
            {
                accList.add(utilTestClass.CreateAccount('Test Account Parent'+i));
                accList[i].AKAM_Account_ID__c='F-AC-Test'+i;
            }
            insert accList;
            //create 100 conract header
            List<Merge_Contract_Header__c> contractList=new List<Merge_Contract_Header__c>() ;
            for(i=0;i<100;i++)
            {
                contractList.add(CreateContractHeader('_##Test Conract '+i,accList[i].Id));
            }
            insert contractList;

            // create Invoice for above account
            Test.startTest();
            List<Invoice__c> invoiceList=new List<Invoice__c>();
            for(i=0;i<100;i++)
                invoiceList.add(CastIronTestClass.CreateInvoice('#Test-FC-Invoice'+i,accList[i].AKAM_Account_ID__c,contractList[i].Original_Contract_Id__c));
            insert invoiceList;
            Test.stopTest();

            //Refresh Invoice object
            invoiceList=refreshInvoiceList(invoiceList);

            //Assert
            for(i=0;i<100;i++)
            {
                system.assertEquals(invoiceList[i].Account_Name__c,accList[i].Id);
                system.assertEquals(invoiceList[i].Original_Contract_Id__c,contractList[i].Id);
            }
        }
    } 
    */
    /**
      Test method added by Chandra
      Resolve_ContratHeader_ForeignKeys_SingleTest_Positive()
     */

    static testMethod void Resolve_ContratHeader_ForeignKeys_SingleTest_Positive()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            //create account
            //Account acc = createAccount('Test Account');
            Account acc = utilTestClass.CreateAccount('testyac');
            acc.AKAM_Account_ID__c='F-AC-Test';
            insert acc;
            //create Opportunity
            //Opportunity opp= CreateOpportunity('Test Opportunity',acc.Id);
            //opp.AKAM_Opportunity_ID__c='F-OP-Test';
            //insert opp;
            // create contact
            Contact con=utilTestClass.CreateContact('Common','Test Contact');
            con.AccountId = acc.Id;
            con.AKAM_Contact_ID__c='F-C-Test';
            insert con;
            //create contract
            Merge_Contract_Header__c testContract=CreateContractHeader('Test Contract',acc.Id);
            insert testContract;

            test.startTest();

            Merge_Contract_Header__c childContract=new Merge_Contract_Header__c();
            childContract.CI_Account_Name__c=acc.AKAM_Account_ID__c;
            childContract.CI_Bill_To_Contact__c=con.AKAM_Contact_ID__c;
            childContract.CI_Contract_Transferred_To__c=testContract.Original_Contract_Id__c;
            //childContract.CI_Opportunity_Name__c=opp.AKAM_Opportunity_ID__c;
            childContract.CI_Parent_Account_Name__c=acc.AKAM_Account_ID__c;
            childContract.CI_Parent_Contract__c=testContract.Original_Contract_Id__c;
            childContract.CI_Referred_By_Account__c=acc.AKAM_Account_ID__c;
            insert childContract;
            Test.stopTest();
            //refresh Child Conract
            childContract=[select Id,Account_Name__c,Bill_To_Contact__C,Contract_transferred_To__c,Opportunity_Name__c
                ,Parent_Account_Name__c,Parent_Contract__C,Referred_By_Account__C From Merge_Contract_Header__c where id =:childContract.Id][0];

            // assert 
            system.assertEquals(childContract.Account_Name__c,acc.Id);
            system.assertEquals(childContract.Bill_To_Contact__C,con.Id);
            system.assertEquals(childContract.Contract_transferred_To__c,testContract.Id);
            //system.assertEquals(childContract.Opportunity_Name__c,opp.Id);
            system.assertEquals(childContract.Parent_Account_Name__c,acc.Id);
            system.assertEquals(childContract.Parent_Contract__C,testContract.Id);
            system.assertEquals(childContract.Referred_By_Account__C,acc.Id);
        }
    }

    /**
      Test method added by Chandra
      Resolve_ContratHeader_ForeignKeys_BulkTest_Positive()
     */
    /*
    static testMethod void Resolve_ContratHeader_ForeignKeys_BulkTest_Positive()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            //create account
            Integer i=0;
            List<Account> acclist=new List<Account>();
            for(i=0;i<100;i++)
            {
                accList.add(utilTestClass.CreateAccount('Test Account Parent'+i));
                accList[i].AKAM_Account_ID__c='F-AC-Test'+i;
            }
            insert accList;
            //create Opportunity
            //List<Opportunity> oppList=new List<Opportunity>();
            //for(i=0;i<100;i++)
            //{
            // oppList.add(CreateOpportunity('Test Opportunity'+i,accList[i].Id));
            // oppList[i].AKAM_Opportunity_ID__c='F-OP-Test'+i;
            //}
            //insert oppList;
            // create contact
            List<Contact> conList=new List<Contact>();
            for(i=0;i<100;i++)
            {
                conList.add(utilTestClass.CreateContact('Common','Test Contact Parent'+i));
                conList[i].AccountId = accList[i].Id;
                conList[i].AKAM_Contact_ID__c='F-C-Test'+i;
            }
            insert conList;
            //create contract
            List<Merge_Contract_Header__c> parentContractList=new List<Merge_Contract_Header__c>();
            for(i=0;i<100;i++)
            {
                parentContractList.add(CreateContractHeader('Test Contract'+i,accList[i].Id));
            }
            insert parentContractList;
            //boolean testFlag=false;
            test.startTest();
            List<Merge_Contract_Header__c> childContractList=new List<Merge_Contract_Header__c>();
            for(i=0;i<100;i++)
            {
                childContractList.add(new Merge_Contract_Header__c());
            }
            for(i=0;i<100;i++)
            {
                childContractList[i].CI_Account_Name__c=accList[i].AKAM_Account_ID__c;
                childContractList[i].CI_Bill_To_Contact__c=conList[i].AKAM_Contact_ID__c;
                childContractList[i].CI_Contract_Transferred_To__c=parentContractList[i].Original_Contract_Id__c;
                //childContractList[i].CI_Opportunity_Name__c=oppList[i].AKAM_Opportunity_ID__c;
                childContractList[i].CI_Parent_Account_Name__c=accList[i].AKAM_Account_ID__c;
                childContractList[i].CI_Parent_Contract__c=parentContractList[i].Original_Contract_Id__c;
                childContractList[i].CI_Referred_By_Account__c=accList[i].AKAM_Account_ID__c;
            }

            insert childContractList;
            Test.stopTest();
            // refresh 
            childContractList=refreshContractHeaderList(childContractList);
            // assert 
            for(i=0;i<100;i++)
            {
                System.assertEquals(childContractList[i].Account_Name__c,accList[i].Id);
                System.assertEquals(childContractList[i].Bill_To_Contact__c,conList[i].Id);
                System.assertEquals(childContractList[i].Contract_Transferred_To__c,parentContractList[i].Id);
                //System.assertEquals(childContractList[i].Opportunity_Name__c,oppList[i].Id);
                System.assertEquals(childContractList[i].Parent_Account_Name__c,accList[i].Id);
                System.assertEquals(childContractList[i].Parent_Contract__c,parentContractList[i].Id);
                System.assertEquals(childContractList[i].Referred_By_Account__c,accList[i].Id);
            }
        }

    } 
    */
    /**
      Test method added by Chandra
      Resolve_ContratHeader_ForeignKeys_SingleTest_Negative()
     */

    static testMethod void Resolve_ContratHeader_ForeignKeys_SingleTest_Negative()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            //create account
            //Account acc = createAccount('Test Account');
            Account acc = utilTestClass.CreateAccount('test6ac');
            acc.AKAM_Account_ID__c='F-AC-Test';
            insert acc;
            //create Opportunity
            //Opportunity opp= CreateOpportunity('Test Opportunity',acc.Id);
            //opp.AKAM_Opportunity_ID__c='F-OP-Test';
            //insert opp;
            // create contact
            Contact con=utilTestClass.CreateContact('Common','Test Contact');
            con.AccountId = acc.Id;
            con.AKAM_Contact_ID__c='F-C-Test';
            insert con;
            //create contract
            Merge_Contract_Header__c testContract=CreateContractHeader('Test Contract',acc.Id);
            insert testContract;
            boolean testFlag=false;
            test.startTest();
            try
            {
                Merge_Contract_Header__c childContract=new Merge_Contract_Header__c();
                childContract.CI_Account_Name__c=acc.AKAM_Account_ID__c;
                childContract.CI_Bill_To_Contact__c=con.AKAM_Contact_ID__c;
                childContract.CI_Contract_Transferred_To__c='Invalid';
                //childContract.CI_Opportunity_Name__c=opp.AKAM_Opportunity_ID__c;
                childContract.CI_Parent_Account_Name__c=acc.AKAM_Account_ID__c;
                childContract.CI_Parent_Contract__c=testContract.Original_Contract_Id__c;
                childContract.CI_Referred_By_Account__c=acc.AKAM_Account_ID__c;
                insert childContract;

            } 
            catch(Exception e)
            {
                if(e.getMessage().contains('Contract_Transferred_To'))
                    testFlag=true;
            }
            Test.stopTest(); 
            system.assert(testFlag,true);
        }
    }  
    /**
      Test method added by Chandra
      Resolve_ContractDetails_ContractHeaderForiegnKey_SingleTest_Positive()
     */                                     
    static testmethod void Resolve_ContractDetails_ContractHeaderForiegnKey_SingleTest_Positive()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            //create account
            //Account acc = createAccount('Test Account');
            Account acc = utilTestClass.CreateAccount('test5ac');
            acc.AKAM_Account_ID__c='F-AC-Test';
            insert acc;

            //create contract
            Merge_Contract_Header__c parentContract=CreateContractHeader('Test Contract',acc.Id);
            insert parentContract;

            //
            test.startTest();
            Merge_Contract_Detail__c conDetail=new Merge_Contract_Detail__c();
            conDetail.CI_Original_Contract_Id__c=parentContract.Original_Contract_Id__c;
            conDetail.Name='Test_Contract_Detail';
            conDetail.Original_Detail_Id__c='Test_Contract_Detail';
            insert conDetail;
            Test.stopTest();
            //refresh contract detail

            conDetail=refreshContractDetail(conDetail);
            //assert

            System.assertEquals(conDetail.Original_Contract_Id__c,parentContract.Id);

        }
    }
    /**
      Test method added by Chandra
      Resolve_ContractDetails_ContractHeaderForiegnKey_SingleTest_Negative()
     */                                     
    static testmethod void Resolve_ContractDetails_ContractHeaderForiegnKey_SingleTest_Negative()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            //create account
            //Account acc = createAccount('Test Account');
            Account acc = utilTestClass.CreateAccount('test2ac');
            acc.AKAM_Account_ID__c='F-AC-Test';
            insert acc;

            //create contract
            Merge_Contract_Header__c parentContract=CreateContractHeader('Test Contract',acc.Id);
            insert parentContract;
            Boolean testFlag=false;
            //
            test.startTest();
            try
            {
                Merge_Contract_Detail__c conDetail=new Merge_Contract_Detail__c();
                conDetail.CI_Original_Contract_Id__c='Invalid';
                conDetail.Name='Test_Contract_Detail';
                conDetail.Original_Detail_Id__c='Test_Contract_Detail';
                insert conDetail;
            }
            catch(Exception e)
            {
                if(e.getMessage().contains('Invalid Contract Id'))
                {
                    testFlag=true;
                }
            }
            test.stopTest();

            //assert
            System.assert(testFlag,true);
        }

    }
    /**
      Test method added by Chandra
      Resolve_ContractDetails_ContractHeaderForiegnKey_BulkTest_Positive()
     */                                     
    static testmethod void Resolve_ContractDetails_ContractHeaderForiegnKey_BulkTest_Positive()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            //create account
            //Account acc = createAccount('Test Account');
            Account acc = utilTestClass.CreateAccount('test3ac');
            acc.AKAM_Account_ID__c='F-AC-Test';
            insert acc;

            //create contract
            Integer i=0;
            List<Merge_Contract_Header__c> parentContractList=new List<Merge_Contract_Header__c>();
            for(i=0;i<100;i++)
            {
                parentContractList.add(CreateContractHeader('Test Contract'+i,acc.Id));
            }
            insert parentContractList;

            //
            test.startTest();
            List<Merge_Contract_Detail__c> conDetailList=new List<Merge_Contract_Detail__c>();
            for(i=0;i<100;i++)
            {
                conDetailList.add(new Merge_Contract_Detail__c());
            }
            for(i=0;i<100;i++)
            {
                conDetailList[i].CI_Original_Contract_Id__c=parentContractList[i].Original_Contract_Id__c;
                conDetailList[i].Name='Test_Contract_Detail'+i;
                conDetailList[i].Original_Detail_Id__c='Test_Contract_Detail'+i;
            }
            insert conDetailList;
            Test.stopTest();
            //refresh contract detail

            conDetailList=refreshContractDetailList(conDetailList);
            //assert
            for(i=0;i<100;i++)
            {
                System.assertEquals(conDetailList[i].Original_Contract_Id__c,parentContractList[i].Id);
            }
        }

    }

    static testMethod void testCastIronMonitoringCronJob()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            CastIron_Polling__c castIronPolling =new  CastIron_Polling__c();
            castIronPolling.Name='AccountSync';
            castIronPolling.OrchKey__c='AccountSync';
            castIronPolling.LastSucessfulRunTime__c=DateTime.now().addHours(-2);
            castIronPolling.Verify_Polling__c = TRUE;
            castIronPolling.Inactive__c = FALSE;
            insert castIronPolling;
            String res=CastIronClass.checkCastIronPolling();
            Boolean isSuccess=res.startsWith('1:');
            System.assertEquals(isSuccess,true);
        }
    }

    static testmethod void Resolve_Payments_Invoice_Foreign_Keys_BulkPositive()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            Account acc = utilTestClass.CreateAccount('testrac');
            acc.AKAM_Account_ID__c='F-AC-Test';
            insert acc;

            Merge_Contract_Header__c parentContract=CreateContractHeader('Test Contract',acc.Id);
            insert parentContract;
            test.startTest();
            Invoice__c inv =new Invoice__c();
            inv.Name='1123422Test';
            inv.Akam_invoice_id__c='1123422Test';
            inv.Account_Name__c=acc.Id;
            inv.Original_Contract_Id__c=parentContract.Id;
            insert inv;
            List<Payment__c> paymentList=new List<Payment__c>();
            integer i=0;
            for(i=0;i<100;i++)
            {
                Payment__c pay=new Payment__c();
                pay.CI_Akam_Invoice_Id__c='1123422Test';
                pay.Name='RECEIPT';
                pay.Total_payment_Amount__c=100+i;
                pay.Payment_Date__c=Date.today().addDays(i);
                paymentList.add(pay);
            }
            insert paymentList;
            test.stopTest();
            for(Payment__c pay :[select Id,Invoice_Number__c from Payment__c where id in : paymentList])
            {
                System.assertEquals(pay.Invoice_Number__c,inv.Id);
            }

            //refresh Account
            acc=[select Id,Last_Payment_Amount__c,Last_Payment_Date__c from Account where Id=: acc.Id];
            System.assertEquals(acc.Last_Payment_Amount__c,199.00);
            System.assertEquals(acc.last_Payment_Date__C,Date.today().addDays(99));
        }

    }

    /*  
        static testMethod void Merge_Contract_Header_Manual_listCheck_Positive() 
        {//for Release 3.24.2
        Account acc = utilTestClass.CreateAccount('Test Account');
        acc.AKAM_Account_ID__c='F-AC-Test';
        insert acc;


        Merge_Contract_Header__c parentContract=CastIronTestClass.CreateContractHeader('Test Contract',acc.Id);
        insert parentContract;

    //MCML insert
    Merge_Contract_Manual_List__c mlist = CastIronTestClass.CreateContractMList('#Test-FC-MCML1', 'Test Contract');
    mlist.Original_Contract_Id__c=parentContract.Id;
    mlist.Review_Frequency__c='One Time';
    insert mlist;

    // Refresh      
    parentContract=CastIronTestClass.refreshContractHeader(parentContract);

    // Assert
    system.assertEquals(parentContract.Manual_List__c,true);

        }

        static testMethod void Merge_Contract_Header_Manual_listBulk_Positive() 
        {//for Release 3.24.2
        Account acc = utilTestClass.CreateAccount('Test Account');
        acc.AKAM_Account_ID__c='F-AC-Test';
        insert acc;         

        Merge_Contract_Header__c parentContract=CastIronTestClass.CreateContractHeader('Test Contract',acc.Id);
        insert parentContract;

    //MCML insert-positive case
    Merge_Contract_Manual_List__c m2list = CastIronTestClass.CreateContractMList('#Test-FC-MCML2', 'Test Contract');
    m2list.Original_Contract_Id__c=parentContract.Id;
    m2list.Review_Frequency__c='One Time';
    insert m2list;

    //MCML insert-Negative case
    Merge_Contract_Manual_List__c mlist = CastIronTestClass.CreateContractMList('#Test-FC-MCML1', 'Test Contract');
    mlist.Original_Contract_Id__c=parentContract.Id;
    mlist.Review_Frequency__c='abcd';
    mlist.End_Date__c=Date.Today().toStartOfMonth().addMonths(-10);
    insert mlist;


    // Refresh      
    parentContract=CastIronTestClass.refreshContractHeader(parentContract);

    // Assert
    system.assertEquals(parentContract.Manual_List__c,true);

        }   


        static testMethod void Merge_Contract_Header_Manual_listCheck_Negative() 
        {//for Release 3.24.2
        Account acc = utilTestClass.CreateAccount('Test Account');
        acc.AKAM_Account_ID__c='F-AC-Test';
        insert acc;


        Merge_Contract_Header__c parentContract=CastIronTestClass.CreateContractHeader('Test Contract',acc.Id);
        insert parentContract;

        Merge_Contract_Manual_List__c mlist = CastIronTestClass.CreateContractMList('#Test-FC-MCML1', 'Test Contract');
        mlist.Original_Contract_Id__c=parentContract.Id;
        mlist.Review_Frequency__c='abcd';
        mlist.End_Date__c=Date.Today().toStartOfMonth().addMonths(-10);
    insert mlist;

    // Refresh      
    parentContract=CastIronTestClass.refreshContractHeader(parentContract);

    // Assert
    system.assertEquals(parentContract.Manual_List__c,false);

}*/


static testmethod void CastIronWSTest()
{
    System.runAs(utilTestClass.getTestRunUser())
    {
        //CR 2770464 - rsharma: putting start and stop of test class
        Test.startTest();
        Account acc=UtilTestClass.CreateAccount('Test Cast Iron WS Account');
        insert acc;
        Contact con=UtilTestClass.CreateContact('Test Cast Iron', 'WS Contact');
        con.AccountId=acc.Id;
        insert con;
        DateTime dt=DateTime.now().addMinutes(-2);
        List<String> objectNameList=new List<String>{'Account','Contact'};
        List<CIResponseWrapperClass> objectRecords=CastIronIntegrationWebservice.getObjectRecords(objectNameList,dt,'SalesforceEDWSyncV2','Default','TestHost','Production');
        Test.stopTest();
        for(CIResponseWrapperClass ciwr: objectRecords)
        {
            //System.assertEquals(ciwr.status,'Success');
        }
        CIResponseWrapperClass singleObjectRecords=CastIronIntegrationWebservice.getObjectBulkUpdates('Account',dt);
        //system.assertEquals(singleObjectRecords.Status,'Success');
        //system.assertEquals(singleObjectRecords.objectRecords.size()>0,true);

        CIResponseWrapperClass singleObjectUpdatedRecords=CastIronIntegrationWebservice.getSingleObjectUpdatedRecords('Contact',dt);
        //system.assertEquals(singleObjectUpdatedRecords.Status,'Success');
        //system.assertEquals(singleObjectUpdatedRecords.objectRecords.size()>0,true);
    }
}


static testmethod void castIronWSmatchStringTest_Positive()
{
    System.runAs(utilTestClass.getTestRunUser())
    {
        List<Cast_Iron_Project_Error_and_Alert__c> testDataToInsert = new List<Cast_Iron_Project_Error_and_Alert__c>();
        
        Cast_Iron_Project_Error_and_Alert__c testData1 = new Cast_Iron_Project_Error_and_Alert__c();
        testData1.Name = 'HREmployeeSync';
        testData1.Error_Message__c = '.*unable to obtain exclusive access to this record.*';
        testData1.Type_of_Error__c='Error';
        testData1.Action__c = 'Send Mail';
        testDataToInsert.add(testData1);
        
        Cast_Iron_Project_Error_and_Alert__c testData2 = new Cast_Iron_Project_Error_and_Alert__c();
        testData2.Name = 'HREmployeeSync';
        testData2.Error_Message__c = '.*An exception occurred while processing a SingleTableNotification job. Data error at row number 0 of table*.';
        testData2.Action__c = 'Send Mail';
        testData2.Type_of_Error__c='Error';
        testData2.Not_to_send__c = true;
        testData2.startCountTime__c = datetime.now();
        testData2.count__c = 0;
		testDataToInsert.add(testData2);

		Cast_Iron_Project_Error_and_Alert__c testData3 = new Cast_Iron_Project_Error_and_Alert__c();
        testData3.Name = 'HREmployeeSync';
        testData3.Error_Message__c = '.*table CRM.EDW_CSOD_SYNC_LOG. The Error is SQLSTATE: 23000 ERRORCODE: 1400 Error Message:.*';
        testData3.Action__c = 'Send Mail';
        testData3.Type_of_Error__c='Error';
        testData3.Not_to_send__c = true;
        Datetime day = datetime.now();
        testData3.startCountTime__c = day.addDays(-2);
		testDataToInsert.add(testData3);        
        
        insert testDataToInsert;
        
        String result1 = CastIronIntegrationWebservice.getMatchedString('HREmployeeSync','Orchestration: SyncSalesforceUser (project: HREmployeeSync; job: A69BDC1CED2895C7921ED367152F4747)Error while updating salesforce contact record (login=pfeldman) in HREmployeeSync: unable to obtain exclusive access to this record');
        String result2 = CastIronIntegrationWebservice.getMatchedString('HREmployeeSync','An exception occurred while processing a SingleTableNotification job. Data error at row number 0 of table');
    	String result3 = CastIronIntegrationWebservice.getMatchedString('HREmployeeSync','table CRM.EDW_CSOD_SYNC_LOG. The Error is SQLSTATE: 23000 ERRORCODE: 1400 Error Message:.');
    }
}

static testmethod void castIronWSmatchStringTest_Negative()
{
    System.runAs(utilTestClass.getTestRunUser())
    {
        String result=CastIronIntegrationWebservice.getMatchedString('TestProject','Testing test case');
        system.assertEquals(result,'not found');
    }
}

//Removed DuplicateRenewalOpportunityCreation_BulkPositive method from test class, which was based on functionality removed as part of SFDC-1394.

}