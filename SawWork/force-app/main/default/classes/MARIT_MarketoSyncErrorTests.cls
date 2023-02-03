@isTest(seeAllData=false)
public class MARIT_MarketoSyncErrorTests {
    @testSetup
    static void setupMethod() 
    {
        // setup to create all test data related to Metadata.
        List <Marketo_Sync_Metadata__c> testObjList = new List<Marketo_Sync_Metadata__c>();
       
        Marketo_Sync_Metadata__c testObj1 = new Marketo_Sync_Metadata__c();
        testObj1.Name = 'Account with AKAM_Account_Id';
        testObj1.Error_Type__c = 'Account With Specific AKAM ID does not Exist';
        testObj1.Fatal__c = false;
        testObjList.add(testObj1);
        
        Marketo_Sync_Metadata__c testObj2 = new Marketo_Sync_Metadata__c();
        testObj2.Name = 'Invalid username, password, security token';
        testObj2.Error_Type__c = 'Invalid Credentials';
        testObj2.Fatal__c = true;
        testObjList.add(testObj2);
        
        insert testObjList;
        
        // setup create Marketo Sync Object.
        List <Marketo_Sync_Details__c> testSyncObjList = new List<Marketo_Sync_Details__c>();
        
        Marketo_Sync_Details__c testSyncObj1 = new Marketo_Sync_Details__c();
        testSyncObj1.Name = 'Test Normal';
        testSyncObj1.Type__c = 'Account With Specific AKAM ID does not Exist';
        testSyncObj1.Fatal__c = false;
        testSyncObjList.add(testSyncObj1);
        
        Marketo_Sync_Details__c testSyncObj2 = new Marketo_Sync_Details__c();
        testSyncObj2.Name = 'Test Fatal';
        testSyncObj2.Type__c = 'Invalid Credentials';
        testSyncObj2.Fatal__c = true;
        testSyncObjList.add(testSyncObj2);
        
        insert testSyncObjList;
    }
        
    // method to test for already existant errors.
    public static testMethod void testNormalError(){
        
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        String emailBody = 'Salesforce Sync Error' +
                            'Why: Marketo is unable to update Lead in Salesforce.'+
                            'Error details: FIELD_CUSTOM_VALIDATION_EXCEPTION: Account with AKAM_Account_Id : 1-HP7QL does not exist'+
                            'Sample Leads: Showing 244 of total 244 affected Leads ' +
                            'What to do now? Contact your Salesforce admin for further troubleshooting';
        email.subject = 'Normal Sync Error';
        email.fromAddress = 'someaddress@marketo.com';
        email.plainTextBody = emailBody;
        
        MARIT_MarketoSyncError  testNormal=new  MARIT_MarketoSyncError();
        testNormal.handleInboundEmail(email, env);  
        List<Marketo_Sync_Details__c> syncObjList1 = [Select Id,Type__c from Marketo_Sync_Details__c where Type__c = 'Account With Specific AKAM ID does not Exist'];
        System.assertEquals(true,syncObjList1.size() > 0, 'Object should exist');
        
    } 
    
    // method to test for already existant fatal errors.
    public static testMethod void testFatalError(){
        
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        String emailBody = 'Salesforce Sync Error' +
                            'Why: Marketo is unable to log into your Salesforce account because the username/password credentials no longer work.'+
                            'Error details: Invalid username, password, security token; or user locked out.'+
                            'What to do now? Update the credentials and try again. Learn more about Troubleshooting your Salesforce sync.';
        email.subject = 'Fatal Sync Error';
        email.fromAddress = 'someaddress@marketo.com';
        email.plainTextBody = emailBody;
        
        MARIT_MarketoSyncError testFatal = new  MARIT_MarketoSyncError();
        testFatal.handleInboundEmail(email, env);
        List<Marketo_Sync_Details__c> syncObjList1 = [Select Id,Type__c,Fatal__c from Marketo_Sync_Details__c where Type__c = 'Invalid Credentials' AND Fatal__c = true LIMIT 1000];
        System.assertEquals(true,syncObjList1.size() > 0, 'Object should exist');
    }
    // method to test for new errors.
    public static testMethod void testNewError(){
        
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        String emailBody = 'Salesforce Sync Error' +
                            'Why: Marketo is unable to update Lead in Salesforce.'+
                            'Error details: FIELD_CUSTOM_VALIDATION_EXCEPTION: Last Name should not be greater than 50 characters. '+
                            'What to do now? Contact your Salesforce admin for further troubleshooting';
        email.subject = 'Some New Unknown Sync Error';
        email.fromAddress = 'someaddress@marketo.com';
        email.plainTextBody = emailBody;
        
        MARIT_MarketoSyncError testNew=new MARIT_MarketoSyncError();
        testNew.handleInboundEmail(email, env);
        List<Marketo_Sync_Details__c> syncObjList3 = [Select Id,Type__c from Marketo_Sync_Details__c where Type__c = 'Last Name should not be greater than' LIMIT 1000];
        System.assertEquals(true,syncObjList3.size() == 0, 'Object should exist');
           
    }

}