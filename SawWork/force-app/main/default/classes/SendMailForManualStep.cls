public class SendMailForManualStep {
    public static String fetchNamesAddToBody(List<Deployment_Step_Request__c> dsRequests){
        String body = 'Mentioned below is the list of all the <b>Deployment Steps</b> which have <b>Manual Step Requests</b> with status as \'New\':<br/><br/><ol>';
        String footer = '<b>NOTE:</b> This is a system generated mail. Please do not reply';
        String msg = 'You can also view all the requests on the <a href="' + dsRequests[0].Instance_URL__c + '/apex/MSM"> ' + 
                    'Manual Step Manager</a>  page. <br/><br/>Thank You<br/><br/>';

        for (Deployment_Step_Request__c dsRequest : dsRequests){
            if(dsRequest.Deployment_Step__r.Release__r.Release_Date__c > date.today()){
                body += '<li><a href="' + dsRequest.Instance_URL__c + '/' + dsRequest.Deployment_Step__c + '">' + dsRequest.Deployment_Step__r.Name +'</a></li><br/>';
            }
        }
        body = body + '</ol><br/>' + msg + '<br/><br/>' + footer;
    
        return body;
    }

    public static void sendMail(){
        /* Fetching Template */
        EmailTemplate template = [select Id,DeveloperName,Body,HtmlValue,Subject from EmailTemplate where Name=:'mailPendingManualStepsRequest'][0];
        String body = template.HtmlValue;
        String subject = template.Subject;

        /* Getting Manual Step Requests with status 'New' */
        List<Deployment_Step_Request__c> dsRequests = [select Name,Deployment_Step__r.Name, Deployment_Step__r.Release__r.Release_Date__c, Instance_URL__c from Deployment_Step_Request__c where status__c=:'New'];

        if(dsRequests.size() > 0){
            /* Fetching names and adding to body */
            body += fetchNamesAddToBody(dsRequests);

            /* Setting up mail and sending */
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            List<String> toAddress= new List<String>{'eaeblrops@akamai.com'}; // Change to eaeblrops@akamai.com
            List<Messaging.SingleEmailMessage> listOfMail = new List<Messaging.SingleEmailMessage>{mail};
            mail.setSubject(subject);
            mail.setHtmlBody(body);
            mail.setToAddresses(toAddress);

            OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'sf-no-reply@akamai.com'];
            if ( owea.size() > 0 ) {
                mail.setOrgWideEmailAddressId(owea.get(0).Id);
            }

            Messaging.sendEmail(listOfMail, false);
        }
    }

    /* Run this in execute Anonymous window to start the scheduler(SchedulerForMailMSM). 
        The job can be stopped by deleting the job under 'Scheduled Jobs' in Setup

    String CRON_EXP = '0 0 1,3,5,7,9,13,15,17,19,21,23 * * ?';
    SchedulerForMailMSM sch = new SchedulerForMailMSM();
    System.schedule('MSM-Mail-2-hour job', CRON_EXP, sch);

    */
}