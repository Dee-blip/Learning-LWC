@isTest
public class SendMailForManualStepTest {
    @testSetup
    static void setup() {
        DeploymentStepTestUtilClass.createGSMCustSettData('Release#ReminderOffSet_day:hh:mm', '-3:13:30');
        DeploymentStepTestUtilClass.createGSMCustSettData('CRM_Integration', UserInfo.getUserId()); //second parameter takes salesforce Id as value , Since Hard Coaded Salesforce Id should be avoided , Using the userId
        
        DeploymentStepTestUtilClass.initDevUser();
        Release__c rel = DeploymentStepTestUtilClass.createRelease();
        
        DeploymentStepTestUtilClass.createDS('DS1', rel.id); 
        Deployment_Step__c ds = [select id, Name from Deployment_Step__c where Name=:('DS1')][0];
        DeploymentStepTestUtilClass.createDSRequest('DS-request1', ds.id, 'New');
        
        DeploymentStepTestUtilClass.createDS('DS2', rel.id); 
        ds = [select id, Name from Deployment_Step__c where Name=:('DS2')][0];
        DeploymentStepTestUtilClass.createDSRequest('DS-request2', ds.id, 'Assigned');
    }

    @isTest
    static void checkDS() {
        List<Deployment_Step__c> ds = [select id, Name from Deployment_Step__c LIMIT 100];  
        System.assertEquals(2, ds.size());
    }

    @isTest
    static void checkDSReq() {
        List<Deployment_Step_Request__c> dsNewReqs = [select id, Name, status__c from Deployment_Step_Request__c where status__c=:'New'];
        System.assertEquals(1, dsNewReqs.size());

        List<Deployment_Step_Request__c> dsAssignedReqs = [select id, Name, status__c from Deployment_Step_Request__c where status__c=:'Assigned'];
        System.assertEquals(1, dsAssignedReqs.size());
    }

    @isTest
    static void checkMailWithNoNewDS(){
        Deployment_Step_Request__c dsReq = [select id, Name, Deployment_Step__c, Instance_URL__c, status__c from Deployment_Step_Request__c where status__c=:'New' LIMIT 1];
        delete dsReq;

        /* Mail shouldn't be sent */
        SendMailForManualStep.sendMail();
        Integer invocations = Limits.getEmailInvocations();
        System.assertEquals(0, invocations);
    }

    @isTest
    static void checkMail() {
        /* Mail should be sent */
        SendMailForManualStep.sendMail();
        Integer invocations = Limits.getEmailInvocations();
        System.assertEquals(1, invocations);
    }

    @isTest
    static void checkBody(){
        List<Deployment_Step_Request__c> dsReqs = [select id, Name, Deployment_Step__r.Name, Deployment_Step__r.Release__r.Release_Date__c, Instance_URL__c, status__c from Deployment_Step_Request__c where status__c=:'New'];
        String expectedBody = 'Mentioned below is the list of all the <b>Deployment Steps</b> which have <b>Manual Step Requests</b> with status as \'New\':<br/><br/>' +
                            '<ol><li><a href="' + dsReqs[0].Instance_URL__c + '/' + dsReqs[0].Deployment_Step__c+ '">DS1</a></li><br/></ol><br/>' +
                            'You can also view all the requests on the <a href="' + dsReqs[0].Instance_URL__c + '/apex/MSM"> Manual Step Manager</a>  page. ' +
                            '<br/><br/>Thank You<br/><br/><br/><br/>' +
                            '<b>NOTE:</b> This is a system generated mail. Please do not reply';

        String body = SendMailForManualStep.fetchNamesAddToBody(dsReqs);
        System.assertEquals(expectedBody, body);
    }
}