/*
    Class name          :   EOLProductsBatchTestClass 
    Author              :   Hitesh Chawda
    Modified By         :   Vivek Baidya - 03/May/2019

    Purpose             :   This test class is used to cover code for below Components
    1. EOLProductsBatchClass
    2. EOLProductsDeleteBatchClass 
*/

@isTest(seeAllData=false)
public class EOLProductsBatchTestClass
{
    //For Account Record
    public static Account accRec;
    
    //For Contract Header Record
    public static List<Merge_Contract_Header__c> activeContracts;
    public static List<Account> activeAccounts;
    public static Integer numberOfActiveTestAccounts=10;
    private static Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
    static User dmlUser = utilTestClass.getTestRunUser();
    
    @testSetUp 
    static void setupMethod()
    {
        System.runAs(dmlUser)
        {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            Test.loadData(globalDescribe.get('Communities_Settings__c'), 'CS_Communities_Settings');
            Test.loadData(globalDescribe.get('Environment_Setup__c'), 'CS_Environment_Setup');
            utilTestClass.createCustomSettings();
            
            
            List<Marketing_Product__c> allMProdList = new List<Marketing_Product__c>();
            List<Merge_Contract_Detail__c> detailList = new List<Merge_Contract_Detail__c>();
            
            String user_role = GsmUtilClass.getGSMSettingValue('User_Role');
            
            List<User> userList = new List<User>();
            User accOwnerUser = utilTestClass.CreateUser('nUnMP', user_role, 'Sales Operations');
            userList.add(accOwnerUser);
            insert userList; 
            
            List<Account_Reassignment_Rule__c> ruleList = new List<Account_Reassignment_Rule__c>();
            Account_Reassignment_Rule__c rule = utilTestClass.CreateAccountReassignmentRule('__TRNMP', accOwnerUser.Id, user_role);
            ruleList.add(rule);
            insert ruleList;
            
            List<Account> acclist = new List<Account>();
            Account acc = new Account();
            acc.Name = '__Test TRNMP';
            acc.OwnerId = accOwnerUser.Id;
            acc.BillingCountry = 'India';
            acc.BillingState = 'Delhi';
            acclist.add(acc);
            Account acc1 = new Account();
            acc1.Name = '__Test TRNEP';
            acc1.OwnerId = accOwnerUser.Id;
            acc1.BillingCountry = 'India';
            acc1.BillingState = 'Delhi';
            acclist.add(acc1);
            insert acclist;
            
            List<Merge_Contract_Header__c> activeContracts = new List<Merge_Contract_Header__c>();
            for(integer i=0;i<2;i++)
            {
                activeContracts.add(new Merge_Contract_Header__c(Name='MCHCSC'+i, Original_Contract_Id__c='MCHCSC'+i, Account_Name__c=acclist[i].Id, Active__c=true, Contract_Type__c='Indirect Customer', Effective_End_Date__c=Date.Today().addDays(+10)));
            }
            insert activeContracts;
            
            for(integer i=0;i<numberOfActiveTestAccounts-5;i++)
            {
                allMProdList.add(utilTestClass.createMarketingProduct('On_Demand_Str::Content_Targeting','MPId'+i,'PPId'+i,'MPKey'+i)) ;
            }
            
            for(integer i=numberOfActiveTestAccounts;i>5;i--)
            {
                allMProdList.add(utilTestClass.createMarketingProduct('End_of_Life_Product::End_of_Life_Product','MPId'+i,'PPId'+i,'MPKey'+i));  
            }
            insert allMProdList;
            
            for(integer i=0;i<numberOfActiveTestAccounts-5;i++)
            {
                detailList.add(utilTestClass.createContractDetail('Marketing Product'+i,'MPId'+i,activeContracts.get(0).id, System.today().addDays(-10), System.today().addDays(50)));
                detailList.add(utilTestClass.createContractDetail('Parent Marketing Product'+i,'PPId'+i,activeContracts.get(0).id, System.today().addDays(-10), System.today().addDays(50)));
            }
            
            for(integer i=numberOfActiveTestAccounts;i>5;i--)
            {
                detailList.add(utilTestClass.createContractDetail('Marketing Product'+i,'MPId'+i,activeContracts.get(1).id, System.today().addDays(-10), System.today().addDays(50)));
                detailList.add(utilTestClass.createContractDetail('Parent Marketing Product'+i,'PPId'+i ,activeContracts.get(1).id, System.today().addDays(-10), System.today().addDays(50)));
            }
            
            for(integer i=numberOfActiveTestAccounts+2;i>numberOfActiveTestAccounts;i--)
            {
                detailList.add(utilTestClass.createContractDetail('CLI Product'+i,'MPId'+i,activeContracts.get(1).id, System.today().addDays(-10), System.today().addDays(50)));
            }
            insert detailList;
            
            List<End_of_Life_Products__c> allEOLProductsList = new List<End_of_Life_Products__c>();
            End_of_Life_Products__c eolRec ;
            for(integer i =0; i < 2 ; i++)
            {    
                eolRec = new End_of_Life_Products__c();
                eolRec.Account_Name__c = acclist[i].Id;
                if(i==0)
                    eolRec.EndOfLifeProductsExternalID__c = acclist[i].Id+'#Undefined';
                else
                    eolRec.EndOfLifeProductsExternalID__c   = 'ETId'+i;
                eolRec.EOL_Product__c = 'MPName'+i;
                allEOLProductsList.add(eolRec);
            }
            insert allEOLProductsList;
            
            List<Impacted_Contract_Lines__c> eolCLIUpsertList = new List<Impacted_Contract_Lines__c>();
            Impacted_Contract_Lines__c eclRec ;
            for(integer i=numberOfActiveTestAccounts+2;i>numberOfActiveTestAccounts;i--)
            {  
                eclRec = new Impacted_Contract_Lines__c();
                eclRec.ImpactedProductLinesExternalID__c= 'EPId'+i;
                eclRec.EOL_Impact__c = 'Feature Impacted';
                eclRec.Contract_Line_Item__c = detailList[i].Id;
                eclRec.End_of_Life_Product__c = allEOLProductsList[0].Id;
                eclRec.Original_Contract_ID__c = detailList[i].Original_Contract_ID__c;
                eclRec.Product_Name__c = detailList[i].Product__c;
                eolCLIUpsertList.add(eclRec);
            }
            insert eolCLIUpsertList;
        }
    }
    
    static testmethod void Test_BatchJob()  
    {
        System.runAs(dmlUser){
            List<Marketing_Product__c> mpList = [Select Id,Engineering_Product_Name__c,Marketing_Product_Id__c,Parent_Product_Id__c From Marketing_Product__c limit 100];
            test.startTest();
            EOLProductsBatchClass bClass = new EOLProductsBatchClass();
            Database.executeBatch(bClass);
            test.stopTest();
            List<End_of_Life_Products__c> eolList = [Select Id From End_of_Life_Products__c limit 100];
            system.assertEquals(True,eolList.size()>2);
        }
    } 
}