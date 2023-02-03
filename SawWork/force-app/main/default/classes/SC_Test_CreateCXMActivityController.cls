@isTest(seeAllData = false)
public class SC_Test_CreateCXMActivityController {
    public static List<Account> accountList = new List<Account>();
    private static Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
    public static User crmopsUser;
    
    
    // Setup method to create test data.
    static
    {
        crmopsUser = [SELECT id,name from user where alias='CRMOPS'];
       
    }
    @TestSetup
    public static void testDataSetupMethod(){
       
        Test.loadData(globalDescribe.get('Environment_Setup__c'), 'CS_Environment_Setup');
        List<Account> accList =  new List<Account>();
        Account acc = utilTestClass.CreateAccount('TestAccount');
        accList.add(acc);
        System.assertEquals( 'TestAccount', accList[0].Name );
        insert accList;
        
    }
    @isTest
    public static void fetchInitialDetailsTestMethod(){
        
        accountList = [Select Id,Name from Account];
        System.assertEquals( 'TestAccount', accountList[0].Name );
        Task t = new Task();
        System.runAs(crmopsUser){
        Test.startTest();
        SC_CreateCXMActivityController.fetchInitialDetails(accountList[0].Id);
        SC_CreateCXMActivityController.createCXMActivity('Customer Escalation','Not Started','2021-10-21','test',UserInfo.getUserId(),accountList[0].Id,null,'Normal','','');
        t = [Select Id from Task limit 1];
        SC_CreateCXMActivityController.fetchLookUpValues('test','User/Queue');
        SC_CreateCXMActivityController.fetchLookUpValues('test','Contact/Lead');
        SC_CreateCXMActivityController.getDependentPicklist('Task','Product__c','Features__c');
        ContentVersion contentVersion = new ContentVersion(
                    Title          = 'a picture',
                    PathOnClient   = 'Pic.jpg',
                    VersionData    = Blob.valueOf('Test Content'),
                    IsMajorVersion = true);
            insert contentVersion;
             List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];

//create ContentDocumentLink  record
            ContentDocumentLink cdl = new ContentDocumentLink();
            //cdl.LinkedEntityId = accountList[0].Id;
            cdl.LinkedEntityId = t.id;
            cdl.ContentDocumentId = documents[0].Id;
            cdl.ShareType = 'V';
            cdl.Visibility = 'AllUsers';
            insert cdl;
       		delete cdl;
            delete documents;
            Test.stopTest();
            }
          
    }
}