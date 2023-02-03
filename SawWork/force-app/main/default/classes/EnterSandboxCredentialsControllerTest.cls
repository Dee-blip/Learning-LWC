@isTest(seeAllData=false)
public class EnterSandboxCredentialsControllerTest {
    Static testmethod void shouldInsertSandboxDetailsEnteredOnPage() {
        Sandbox_Details__c sandboxDetail = new Sandbox_Details__c(Username__c='proteususer@akamai.com.reldev',Sandbox_Name__c='reldev',Password__c='helloWorld');
        ApexPages.StandardController sc = new ApexPages.StandardController(sandboxDetail);
        EnterSandboxCredentialsController controller = new EnterSandboxCredentialsController(sc);
        controller.saveDetails();
        List<Sandbox_Details__c> reldev = [select id from Sandbox_Details__c where Sandbox_Name__c = 'reldev'];
        System.assertEquals(1, reldev.size());
    }
    
    Static testmethod void shouldUpdateSandboxDetailsEnteredOnPage() {
        Sandbox_Details__c sandboxDetail = new Sandbox_Details__c(Username__c='proteususer@akamai.com.reldev',Sandbox_Name__c='reldev',Password__c='helloWorld');
        insert sandboxDetail;
        sandboxDetail.Username__c = 'knath@akamai.com.reldev';
        ApexPages.StandardController sc = new ApexPages.StandardController(sandboxDetail);
        EnterSandboxCredentialsController controller = new EnterSandboxCredentialsController(sc);
        controller.saveDetails();
        List<Sandbox_Details__c> reldev = [select id, Username__c from Sandbox_Details__c where Sandbox_Name__c = 'reldev'];
        System.assertEquals(1, reldev.size());
        System.assertEquals('knath@akamai.com.reldev', reldev[0].Username__c);
    }
    
    Static testmethod void shouldShowErrorMessageIfThereIsAnError() {
        Sandbox_Details__c sandboxDetail = new Sandbox_Details__c(Sandbox_Name__c='',Password__c='');
        ApexPages.StandardController sc = new ApexPages.StandardController(sandboxDetail);
        EnterSandboxCredentialsController controller = new EnterSandboxCredentialsController(sc);
        try {
            controller.saveDetails();
        } catch (exception e) {
            List<ApexPages.Message> msgList = ApexPages.getMessages();    
            System.assertEquals(1, msgList.size());
            System.assertEquals(ApexPages.Severity.ERROR, msgList[0].getSeverity());
        }
        
    }
}