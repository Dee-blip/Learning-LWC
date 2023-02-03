@isTest(seeAllData=false)
public class MARIT_DriftCustomCodeTestClass {
    private static User dmlUser = [Select id from user where alias = 'DRFUSER' limit 1];
    @testSetup
    static void setupMethod(){
        MarketingIT_Custom_Settings__c settings = new MarketingIT_Custom_Settings__c();
        settings.Name = 'LeadAsyncConversionFlagStatus';
        settings.Flag_Status__c = false;
        insert settings;
        
        //create account
        Account acc = utilTestClass.CreateAccount('__Test Account');
        insert acc;
        
        // Create contact
        List<Contact> conList = new List<Contact>();
        Contact con = utilTestClass.CreateContact('__ Test First','__Test Contact');
        con.AccountId = acc.Id;
        con.email = 'test@akamai.com.invalid222';
        insert con;
        
        //Create Marketo Lead
        Id akamaiRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
        Lead l = new Lead();
        l.RecordTypeId = akamaiRecordTypeId;
        l.email = 'testml1@akamai.com.invalid';
        l.Status = 'New';
        l.firstname = 'Test';
        l.lastname = 'Test1';
        l.Associated_Account__c = acc.Id;
        l.Company = 'Test Company';
        l.Product_Line__c = 'Media';
        l.Country = 'India';
        l.State = 'Karnataka';
        insert l;
        
    }
    
    static testMethod void testTaskAssignmentToCTA(){
        Lead ml = [Select Id,Lead_Qualification_Stage__c,CQL_Score__c from Lead where email = 'testml1@akamai.com.invalid' limit 1];
        Test.startTest();
        //creation of task
        Task task = new Task();
        task.Subject = 'Conversation in Drift';
        task.Status = 'Completed';
        task.OwnerId = dmlUser.Id;
        task.WhoId = ml.Id;
        insert task;
        Task t = [Select Id,WhoId from task where WhoId =: ml.Id];
        System.assert(t.Id != null, 'task is not associated to marketo lead');
        //check task ownership to cta
        ml.CQL_Score__c = 3;
        update ml;
        Lead al = [Select Id,Parent_Lead__c from Lead where Parent_Lead__c =: ml.Id];
        Task t1 = [Select Id,WhoId from task where WhoId =: al.Id];
        System.assert(t1 != null,'Moved to open cta');
        Test.stopTest();
    }
    
    static testMethod void testTaskRedirectionToOpenCTA(){
        Id id = [Select Id from user where profile.name = 'Sales Development Representative' limit 1].Id;
        Lead ml1 = [Select Id,Lead_Qualification_Stage__c,CQL_Score__c from Lead where email = 'testml1@akamai.com.invalid' limit 1];
        Test.startTest();
        ml1.CQL_Score__c = 3;
        update ml1;
        //creation of task
        Task task = new Task();
        task.Subject = 'Conversation in Drift';
        task.Status = 'Completed';
        task.OwnerId = id;
        task.WhoId = ml1.Id;
        insert task;
        Lead al1 = [Select Id,Parent_Lead__c,OwnerId from Lead where Parent_Lead__c =: ml1.Id limit 1];
        Test.stopTest();
    }
    
    static testMethod void testTaskRedirectionToContact(){
        Contact c = [Select Id,Lead_Qualification_Stage__c,CQL_Score__c from contact where email = 'test@akamai.com.invalid222' limit 1];
        Test.startTest();
        //creation of task
        Task task = new Task();
        task.Subject = 'Conversation in Drift';
        task.Status = 'Completed';
        task.OwnerId = dmlUser.Id;
        task.WhoId = c.Id;
        insert task;
        Task t = [Select Id,WhoId from task where WhoId =: c.Id];
        System.assert(t.Id != null, 'task is not associated to marketo lead');
        //check task ownership to cta
        c.CQL_Score__c = 3;
        update c;
        Lead al2 = [Select Id,Associated_Contact__c from Lead where Associated_Contact__c =: c.Id];
        Task t1 = [Select Id,WhoId from task where WhoId =: al2.Id];
        System.assert(t1 != null,'Moved to open cta');
        Test.stopTest();

    }
    
}