/* Created By: Vivek Baidya
* Created Date: 27-Dec-2018
* Description: Test class for ClosePlanTriggerFramework. 
*/
@isTest(seeAllData=false)
public class ClosePlanTriggerTest {
    //static User
    static User dmlUser = utilTestClass.getTestRunUser();
    
    // Setup method to create test data.
    @testSetup
    static void setupMethod() {
        System.runAs(dmlUser) {
            //Account Creation
            Account acc = utilTestClass.CreateAccount('Test Account');
            insert acc;
            
            //Opportunity Creation
            Opportunity oppty = utilTestClass.CreateOpportunity('__Test Opportunity','1-Create');
            oppty.AccountId = acc.Id;
            oppty.CloseDate = Date.today().addMonths(4);
            insert oppty;
        }
    }
    
    @isTest static void closePlanCreationTest(){
        System.runAs(dmlUser) {
            Id opptyId = [select Id from Opportunity where name = '__Test Opportunity' limit 1][0].Id;
            Close_Plan__c cp = new Close_Plan__c();
            cp.Opportunity__c = opptyId;
            Test.startTest();
            insert cp;
            delete cp;
            Test.stopTest();
        }
    }
    
    @isTest static void createAndViewClosePlanControllerWithClosePlan(){
        System.runAs(dmlUser) {
            Opportunity oppty = [select Id, Name from Opportunity where name = '__Test Opportunity' limit 1][0];
            Close_Plan__c cp = new Close_Plan__c();
            cp.Opportunity__c = oppty.Id;
            insert cp;
            Test.startTest();
            PageReference pageRef = Page.CreateAndViewClosePlan;
            Test.setCurrentPage(pageRef);
            ApexPages.StandardController sc = new ApexPages.StandardController(oppty);
            CreateAndViewClosePlanController conObj = new CreateAndViewClosePlanController(sc);
            conObj.cpList = [select Id from Close_Plan__c where Opportunity__c =: oppty.Id];
            conObj.navigateToCreateAndViewClosePlan();
            Test.stopTest();
        }
    }
    
    @isTest static void createAndViewClosePlanControllerWithoutClosePlan(){
        System.runAs(dmlUser) {
            Opportunity oppty = [select Id, Name from Opportunity where name = '__Test Opportunity' limit 1][0];
            Test.startTest();
            PageReference pageRef = Page.CreateAndViewClosePlan;
            Test.setCurrentPage(pageRef);
            ApexPages.StandardController sc = new ApexPages.StandardController(oppty);
            CreateAndViewClosePlanController conObj = new CreateAndViewClosePlanController(sc);
            conObj.cpList = [select Id from Close_Plan__c where Opportunity__c =: oppty.Id];
            conObj.navigateToCreateAndViewClosePlan();
            Test.stopTest();
        }
    }
    
    @isTest static void closePlanDetailControllerTest(){
        System.runAs(dmlUser) {
            Opportunity oppty = [select Id, Name from Opportunity where name = '__Test Opportunity' limit 1][0];
            Close_Plan__c cp = new Close_Plan__c();
            cp.Opportunity__c = oppty.Id;
            insert cp;
            Test.startTest();
            PageReference pageRef = Page.ClosePlanDetail;
            Test.setCurrentPage(pageRef);
            ApexPages.StandardController sc = new ApexPages.StandardController(cp);
            ClosePlanDetailController conObj = new ClosePlanDetailController(sc);
            conObj.setRenderClosePlanPage();
            conObj.refreshCurrentPage();
            Test.stopTest();
        }
    }

    @isTest static void notesAndAttachmentVfCompCntrlTest(){
        System.runAs(dmlUser) {
            Id opptyId = [select Id from Opportunity where name = '__Test Opportunity' limit 1][0].Id;
            Blob b = Blob.valueOf('Test Data');
            
            Test.startTest();
            NotesAndAttachmentVfCompCntrl obj = new NotesAndAttachmentVfCompCntrl();
            obj.parentId = opptyId;
            obj.AttchBody = b;
            obj.AttchName = 'TestFile';
            obj.fileList = new List<ContentDocumentLink>();
            obj.onFileChange();
            obj.getFileList();
            Test.stopTest();
        }
    }

}