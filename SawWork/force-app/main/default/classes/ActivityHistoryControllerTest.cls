@isTest(seeAllData=false)
private class ActivityHistoryControllerTest {
    private static Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
    
    //static User
    static User dmlUser = utilTestClass.getTestRunUser();
    
    // Setup method to create test data.
    @testSetup
    static void setupMethod() {
        System.runAs(dmlUser) {
            
            ManagedPkgErrorClass.isFromManagedPackage = false;
            
            /* Start Of Custom Setting Insertion */
            Test.loadData(globalDescribe.get('Communities_Settings__c'), 'CS_Communities_Settings');
            Test.loadData(globalDescribe.get('Environment_Setup__c'), 'CS_Environment_Setup');
            /* End Of Custom Setting Insertion */
            
            User accOwnerUser = utilTestClass.CreateUser('newUser', GsmUtilClass.getGSMSettingValue('User_Role'), 'Sales Operations');
            insert accOwnerUser;

            Account_Reassignment_Rule__c rule = utilTestClass.CreateAccountReassignmentRule('__Test Rule', accOwnerUser.Id, GsmUtilClass.getGSMSettingValue('User_Role'));
            insert rule; 
            
            //Account Creation
            List<Account> accList = new List<Account>();
            Account acc = utilTestClass.CreateAccount('__Test Account');
            acc.Vertical__c = 'Gaming'; 
            acc.Sub_Vertical__c = 'Console Mfs';
            accList.add(acc);
            
            Account acc1 = utilTestClass.CreateAccount('__Test Account With Division And Area');
            acc1.Vertical__c = 'Gaming';
            acc1.TERR_HIER_1__c = 'APJ'; // Geo
            acc1.TERR_HIER_3__c = 'B'; // Area
            acc1.OwnerId = accOwnerUser.Id;
            accList.add(acc1);
            
            Account acc2 = utilTestClass.CreateAccount('__Test Account Credit Check');
            acc2.Vertical__c = 'Gaming';
            acc2.Sub_Vertical__c = 'Console Mfs';   
            acc2.taskCreatedForCreditCheck__c = true;
            accList.add(acc2);
            
            Account acc3 = utilTestClass.CreateAccount('__Test Account Credit Check 1');
            acc3.Vertical__c = 'Gaming';
            acc3.Sub_Vertical__c = 'Console Mfs';   
            acc3.taskCreatedForCreditCheck__c = true;
            accList.add(acc3);
            insert accList;
            
            //Contact Creation
            List<Contact> conList = new List<Contact>();
            Contact con = utilTestClass.CreateContact('__ Test First','__Test Contact 1');
            con.AccountId = acc.Id;
            conList.add(con);
            Contact con2 = utilTestClass.CreateContact('__ Test First','__Test Contact 2');
            con2.AccountId = acc.Id;                            
            conList.add(con2);
            insert conList;
            
            //Opportunity Creation
            List<Opportunity> oppList = new List<Opportunity>();
            Opportunity opp = utilTestClass.CreateOpportunity('__Test Oppty','1-Create');
            opp.AccountId = acc.Id;
            opp.CloseDate = Date.today().addDays(30);   
            oppList.add(opp);   
            
            Opportunity opp1 = utilTestClass.CreateOpportunity('__Test Oppty 1','1-Create');
            opp1.AccountId = acc1.Id;
            opp1.CloseDate = Date.today().addDays(30);  
            oppList.add(opp1);  
            insert oppList;
            
            //Lead Creation
            Lead lead = utilTestClass.CreateLead();
            lead.Status = 'Qualifying';
            lead.LeadSource ='Live Chat';
            lead.How_did_you_hear_about_Akamai__c = 'Through good unit tests';
            lead.Associated_Contact__c = con.Id;    
            lead.Disposition__c='Existing Customer';
            lead.Product_line__c='Aura';
            lead.LastName = 'live chat last name';
            lead.Company = 'Live Chat Test company';
            insert lead; 
            
            //Campaign Creation
            List<Campaign> campaignList = new List<Campaign>();
            Campaign cmpgn1 = new Campaign();
            cmpgn1.Name = '__Test Campaign1';
            campaignList.add(cmpgn1);
            Campaign cmpgn2 = new Campaign();
            cmpgn2.Name = '__Test Campaign2';
            campaignList.add(cmpgn2);
            insert campaignList;
        }
    }

    static testmethod void fetchActivityList()
    {

        Test.startTest();
        Lead lead = [Select status, AKAM_Lead_ID__c from Lead where Status = 'Qualifying'];
        System.debug('Lead : ' +lead);
        String akamLeadId = (String) lead.AKAM_Lead_ID__c;
        String s = ActivityHistoryController.getTaskRecords(akamLeadId);
        Test.stopTest();
    }
}