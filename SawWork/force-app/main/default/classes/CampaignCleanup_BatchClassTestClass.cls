/* History:
 * =========================
 *  @author     Hitesh Chawda,     5th June'17
    Test class for CampaignCleanup_LeadToOpptyBatchClass
    SFDC-1641
 */
@isTest
public class CampaignCleanup_BatchClassTestClass {

    @testSetUp static void createTestData()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            utilTestClass.insertCustomSettings();

            List<Account> listOfTestAccounts = new List<Account>();
            List<Contact> listOfTestContacts = new List<Contact>();
            List<Lead> listOfTestLeads = new List<Lead>();
            List<CampaignMember> listOfTestCampaignMembers = new List<CampaignMember>();
            List<Task> listOfTestTasks = new List<Task>();
            List<Event> listOfTestEvents = new List<Event>();
            Set<Id> setOfLeadIds = new Set<Id>();


            for(integer i=0;i<5;i++)
            {
                Account tAccount = utilTestClass.createAccount('__Testacc'+i);
                tAccount.BillingStreet = 'Maple Ave';
                tAccount.BillingState = 'NY';
                tAccount.BillingPostalCode = '10514';
                tAccount.BillingCountry = 'USA';
                tAccount.BillingCity = 'Chappaqua';
                tAccount.Vertical__c = 'Gaming';
                tAccount.Type = 'Agency - Active';
                tAccount.Network_Account__c = false;
                listOfTestAccounts.add(tAccount);

            }
            insert listOfTestAccounts;

            for(integer i=0;i<5;i++)
            {
                Contact tCon   = utilTestClass.CreateContact('_Tes'+i, 'LASTest');
                tCon.AccountId =listOfTestAccounts[i].id;        
                tCon.MailingCountry = 'USA';
                tCon.Network_Contact__c = false;
                tCon.Email = 'testlas'+i+'@akamai.com';

                listOfTestContacts.add(tCon);
            }
            insert listOfTestContacts;

            Test.startTest();

            Id akamaiLeadRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Akamai Lead').getRecordTypeId();

            Campaign cmpgn = utilTestClass.CreateCampaign('__ TEST CMPGN');
            insert cmpgn;


            for(integer i=0;i<5;i++)
            {
                Lead tLead = utilTestClass.CreateLead();
                tLead.LastName = 'Last';
                tLead.AKAM_Lead_ID__c ='TESTL'+i;
                tLead.AKAM_Created_by__c='MAPI';
                tLead.Company = 'Company';
                tLead.Associated_Contact__c = listOfTestContacts[i].Id;
                tLead.RecordTypeId = akamaiLeadRecordTypeId;   
                tLead.Status = 'Qualifying';
                tLead.QFA_Meeting_Date__c = date.today();
                tLead.Validation_Override__c = true;
                tLead.Business_Pain__c = 'Performance';
                tLead.Competitor__c='No Competitor';
                tLead.Destination__c = 'ECG';
                tLead.Disposition__c='New';
                tLead.Lead_Type__c = 'Customer';
                tLead.Product__c= 'Custom';
                tLead.Product_Line__c = 'Aqua';
                tLead.Project_Timeframe__c = '3 months or less';
                tLead.Prospect_Customer__c = 'Customer';
                tLead.Customer_Type__c = 'Direct';
                tLead.Budget__c = 'Unsure'; 
                tLead.Company = 'Use Contact Info';
                tLead.LastName = 'Use Contact Info';           
                tLead.LeadSource = 'Advertisement';
                tLead.Email = 'abc@akamai.com';
                tLead.Associated_Account__c = listOfTestAccounts[i].Id;
                tLead.OwnerId = GSMSettings.getValue('LeadAutoConvert_QueueId');
                tLead.AKAM_Created_By__c = 'MAPI';
                listOfTestLeads.add(tLead);

            }
            insert listOfTestLeads;

        for(Integer i=0;i<5;i++)
        {
            listOfTestLeads[i].AKAM_Created_By__c = 'MAPI';
        }
           update  listOfTestLeads;


            for(integer i=0;i<2;i++)
            {
                

                CampaignMember cmpgnMember = utilTestClass.CreateCampaignMember(listOfTestLeads[i].Id, cmpgn.Id);
                cmpgnMember.Status = 'Sent';
                listOfTestCampaignMembers.add(cmpgnMember);

                

            }
            

            insert listOfTestCampaignMembers;
            
            List<Opportunity> opptyList = new List<Opportunity>();
            for(Integer i=0;i<5;i++)
            {
                Opportunity oppty = utilTestClass.CreateOpportunity('opp+1', '1-Create');
                oppty.AccountId = listOfTestAccounts[i].Id;
                oppty.Associated_Lead__c = listOfTestLeads[i].Id;
                oppty.AKAM_Created_By__c = 'MAPI';
                oppty.QFA__c = true;
                oppty.CloseDate = Date.today();
                opptyList.add(oppty);
            }
            insert opptyList;

            for(Integer i=3;i<5;i++)
            {
                opptyList[i].CampaignId = cmpgn.Id;
            }
            update opptyList;

        }
    }

    static testmethod void testMethodLeadOpptySingle() {

        Campaign cmpg = [Select Id From Campaign limit 1];
        List<Opportunity> opptyList = [Select Id,CampaignId From Opportunity limit 5];
        List<Contact> contactList = [Select Id From Contact limit 5];
        
        CampaignMember cmpgnMemberRec = new CampaignMember();
            cmpgnMemberRec.ContactId = contactList[2].Id;
            cmpgnMemberRec.CampaignId = cmpg.Id;
        
        for(Integer i=3;i<5;i++)
            {
                opptyList[i].CampaignId = cmpg.Id;
            }
        
        Test.startTest(); 
            insert cmpgnMemberRec;
            update opptyList;

        Cron_Batch_Job__c testBatchJob = utilTestClass.createCronBatchJob('CampaignCleanup_LeadToOpptyBatchClass','CampaignCleanup_LeadToOpptyBatchClass');
        insert testBatchJob;
        Cron_Batch_Run__c testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
        insert testBatchRun;
        testBatchRun.Trigger_Batch_Run__c = true;
        update testBatchRun;

        CampaignCleanup_LeadToOpptyBatchClass bClass = new CampaignCleanup_LeadToOpptyBatchClass();
        Database.executeBatch(bClass);
        Test.stopTest();
       
    }

    


}