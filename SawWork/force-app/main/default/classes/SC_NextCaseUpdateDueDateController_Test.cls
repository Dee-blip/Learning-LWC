/*________________________________________________________________________________________________
    Test Class name                 :   SC_NextCaseUpdateDueDateController_Test 
    Purpose                         :   Test class to cover
    
   Last Modified        Developer           CR                  Purpose            
   =============        =========           ==                  ======= 
   17 January 2017      Vandhana        3622191 (17.2)      Increase Code Coverage of SC test classes
                                                            1. SC_NextCaseUpdateDueDateController 
                                                            2. StreamingPublisher  
                                                            3. CaptureCaseClosureComment  
                                                            4. SCCaseAttachmentHandler
	18-Sep-2020      	Tejaswini     	ESESP-4020 			Set seeAllData = false 
															added testSetup method
   
________________________________________________________________________________________________*/

@isTest
public class SC_NextCaseUpdateDueDateController_Test 
{
    @testSetup static void setup() {
        utilTestClass.createCustomSettings(); 
    }
    
    @isTest static void testMethod_SCNextCaseUpdate()
    {
        // to cover SC_NextCaseUpdateDueDateController
         
        Account acc = new Account(Name = 'NewTestAccount123', Support_Level__c = 'Reseller');
        insert acc;
        Case newCase = utilTestClass.createcase(acc.id);
        ApexPages.StandardController sc = new ApexPages.StandardController(newCase);
        SC_NextCaseUpdateDueDateController testObj = new SC_NextCaseUpdateDueDateController(sc);
        
        
        List<SLAProcess> newSLAProcess = [select id,Name from SLAProcess where Name = 'Premium' and IsVersionDefault=true];
        Entitlement eachEntitlementRec = new Entitlement();
        eachEntitlementRec.AccountId  = acc.Id;
        eachEntitlementRec.Name       = 'New Entitlement';
        eachEntitlementRec.Entitlement_Name_Account__c = 'New Entitlement' + '-' + acc.Id;
        eachEntitlementRec.StartDate  = system.today();
        eachEntitlementRec.SlaProcessId = newSLAProcess[0].Id;
        Insert eachEntitlementRec;
        
        newCase.EntitlementId = eachEntitlementRec.Id;
        
        newCase.Override_Next_Case_Update__c = System.today().addDays(2);
        Test.startTest();
        update newCase;
        sc = new ApexPages.StandardController(newCase);
        testObj = new SC_NextCaseUpdateDueDateController(sc);
        
        Id userId = SCUserIdCustomSetting__c.getValues('LunaPortalIntegration').UserId__c;
        User userLuna = [Select Email from User where Id = :userId limit 1];    
        
        // to cover CaptureCaseClosureComment class
        Id recType = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Emerging Products Engineering').getRecordTypeId();
        Case case1 = new Case(AccountId = acc.Id, Subject = 'Test Case',RecordTypeId = recType, Origin = 'Email');
        case1.OwnerId = UserInfo.getUserId();
        insert case1;
        
        List<Attachment> listAtt = new List<Attachment>();
        List<Task> listTask = new List<Task>();
        Attachment att; Task tsk;
        
        for(Integer i=0;i<3;i++)
        {
            att = new Attachment();
            att.Body=blob.valueOf('My new attachment');
            att.Name='Sample text.txt';
            att.ContentType='text/plain';
            att.ParentId=case1.Id;
            att.OwnerId = userId;
            listAtt.add(att);
            
            tsk = utilTestClass.CreateTask(userId, 'My new Task' + i, 'In Progress', 'Web Update', case1.Id);
            tsk.Internal_Only__c = false;
            tsk.RecordTypeId = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('BOCC Activity').getRecordTypeId();
            listTask.add(tsk);
        }
        insert listAtt;
        insert listTask;
        
        CaseComment caseComm = new CaseComment(CommentBody = 'Testing Comment Body', ParentId = case1.Id);
        insert caseComm;
        case1.Subject = 'Updated subject';
        case1.Validation_Override__c = true;
        case1.Origin = 'Jive';
        case1.Postback_Options__c = 'Post case closure comments as reply';
        case1.Status = 'Closed';
        case1.LOE_Hours__c = 10;
        case1.LOE_Minutes__c = 30;
        case1.Task_LOE__c = 20;
        update case1;
        Test.stopTest();
        
        Map<String,list<Attachment>> mCaseAndAttachment = new map<string,list<Attachment>>();
        
        // to cover StreamingPublisher class
        Profile pr = [select Id from Profile where Name = 'Support - Tech Support Agent' limit 1];
        User newUser = new User(Alias = 'TstUsr', email='testuser1@akamai.com',emailencodingkey='UTF-8', lastname='testLastName', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='testuser1_1@akamai.com',profileid = pr.Id);
        System.runAs(newUser)
        {
            StreamingPublisher sp = new StreamingPublisher(); 
        }
    }
}