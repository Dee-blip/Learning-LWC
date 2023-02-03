/* History:
* =========================
* @author  Himanshu Verma,  19th May 2020 
MARIT-488
*/
@isTest(seeAllData=false)
public class MARIT_TaskTriggerClassTest {
    private static Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
    static User dmlUser = new User(id=UserInfo.getUserId());
    
    // Setup method to create test data.
    @testSetup
    static void setupMethod() 
    {
        System.runAs(dmlUser) 
        {
            /* Start Of Custom Setting Insertion */
            Test.loadData(globalDescribe.get('Environment_Setup__c'), 'CS_Environment_Setup');
            /* End Of Custom Setting Insertion */
            
            Account testAccount = utilTestClass.CreateAccount('Test Account2');
            insert testAccount;
            
            Contact testContact = utilTestClass.CreateContact('Test','Contact2');
            testContact.AccountId = testAccount.Id;
            insert testContact;
            
            Map<String,Schema.RecordTypeInfo> leadRecordTypeInfo  = Schema.SObjectType.Lead.getRecordTypeInfosByName();
            Id akamaiLeadRecordTypeId = leadRecordTypeInfo.get('Akamai Lead').getRecordTypeId();
            Lead lead = new Lead();
            lead.LeadSource = 'Web';
            lead.Associated_Account__c = testAccount.Id;
            lead.Associated_Contact__c = testContact.Id;
            lead.RecordTypeId = akamaiLeadRecordTypeId;
            insert lead;
        }
    }
    public static testmethod void TestTaskCreatedOnAkamaiLead_ActivityAdded_ActivityCountUpdated() 
    {
        System.runAs(dmlUser) 
        {
            Account testAccount = [select Id, name from Account where Name = 'Test Account2'];
            Contact testContact = [Select Id from Contact where FirstName = 'Test' and LastName = 'Contact2'];
            Lead initialAkamaiLead = [Select Id from Lead where Associated_Account__c = :testAccount.Id];
            
            List<Task> taskList = new List<Task>();
            
            for (Integer i = 0; i < 3; i++) {
                // Create five new imaginary friends!
                Task task = new Task();
                task.WhoId = initialAkamaiLead.Id;
                task.Subject = '__Test Subject';
                task.Priority = 'Normal';
                task.Status = 'In Progress';                
                taskList.add(task);
            }
            taskList[0].Type__c = 'Email';
            taskList[1].Type__c = 'Call';
            taskList[2].Type__c = 'Other';
            
            insert taskList;
            
            Lead akamaiLead = [Select Id, All_Email_Activities_Count__c, All_Call_Activities_Count__c, All_Other_Activities_Count__c from Lead where Id = :initialAkamaiLead.Id];
            
            System.assertEquals(1, akamaiLead.All_Call_Activities_Count__c , 'Must have 1 Call activity');
            System.assertEquals(1, akamaiLead.All_Email_Activities_Count__c , 'Must have 1 Email activity');
            System.assertEquals(1, akamaiLead.All_Other_Activities_Count__c , 'Must have 1 Other activity');
            
            // dereferencing whoId is a must before deleting the tasks
            taskList[0].WhoId = null;
            taskList[1].WhoId = null;
            taskList[2].WhoId = null;
            update taskList;
      
            delete taskList;
            
            Lead akamaiLeadAfterDelete = [Select Id, All_Email_Activities_Count__c, All_Call_Activities_Count__c, All_Other_Activities_Count__c from Lead where Id = :initialAkamaiLead.Id];
            System.assertEquals(0, akamaiLeadAfterDelete.All_Call_Activities_Count__c , 'Must have 0 Call activity');
            System.assertEquals(0, akamaiLeadAfterDelete.All_Email_Activities_Count__c , 'Must have 0 Email activity');
            System.assertEquals(0, akamaiLeadAfterDelete.All_Other_Activities_Count__c , 'Must have 0 Other activity');
        }
    }
}