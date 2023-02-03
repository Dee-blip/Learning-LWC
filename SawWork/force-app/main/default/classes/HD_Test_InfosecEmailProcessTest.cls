/*
* File Name: HD_Test_InfosecEmailProcessTest
* Description : Test class for HD_InfosecEmailProcess
* @author :
* Modification Log ===============================================================
* Date 				Author 					Modification
* Aug 08th, 2020    Aneesh Budnar           PRTORES-1810 - Code scanner fixes
*/
@isTest(SeeAllData=false)
public class HD_Test_InfosecEmailProcessTest {
    

    // subject line.        
    static testMethod void testInfosecEmail() {
    
        HD_IncidentTestDataFactory idf = new HD_IncidentTestDataFactory();
        ManagedPkgErrorClass.isFromManagedPackage =  false;
        
        
        List<HD_EIS_INCIDENT_GROUP__c> incigroups = new List< HD_EIS_INCIDENT_GROUP__c>();
        incigroups.add(new HD_EIS_INCIDENT_GROUP__c(Name = 'HELPDESK_HARDWARE', IncidentGroup__c = 'Q_HELPDESK_HARDWARE'));
        incigroups.add(new HD_EIS_INCIDENT_GROUP__c(Name = 'HELPDESK_MALWARE', IncidentGroup__c = 'Q_HELPDESK_MALWARE'));
        incigroups.add(new HD_EIS_INCIDENT_GROUP__c(Name = 'HELPDESK_TRIAGE', IncidentGroup__c = 'Q_HELPDESK_TRIAGE'));
        incigroups.add(new HD_EIS_INCIDENT_GROUP__c(Name = 'ITOC', IncidentGroup__c = 'Q_ITOC'));
        incigroups.add(new HD_EIS_INCIDENT_GROUP__c(Name = 'ITOC_Alerts', IncidentGroup__c = 'Q_ITOC_Alerts'));
        insert incigroups;
        HD_Incident_Settings__c msact = new HD_Incident_Settings__c (Name='Missing_Actions_Update', Value__c='Email Sent');
        insert msact;
       // Create a new email and envelope object.
       Messaging.InboundEmail email = new Messaging.InboundEmail() ;
       Messaging.InboundEnvelope env    = new Messaging.InboundEnvelope();
       email.fromAddress = 'kahegde@akamai.com';
       email.subject = 'My Test Ticket' ;
       email.messageId = 're632fyetdf3764r376efi7326re73r2e7';
       email.htmlBody = '<h1> New email for testing<h1>' ;
        
       HD_InfosecEmailProcess hdinfosec = new HD_InfosecEmailProcess();
       Messaging.InboundEmailResult res =  hdinfosec.handleInboundEmail(email, env);
        
       Messaging.InboundEmail email2 = new Messaging.InboundEmail() ; 
       //Messaging.InboundEnvelope env    = new Messaging.InboundEnvelope();
       email2.fromAddress = 'kahegde@akamai.com';
       email2.subject = 'My Test Ticket';
       email2.messageId = '847485re632fyetdf3764r376efi7326re73r2e7';
       email2.references = new List<String>{'re632fyetdf3764r376efi7326re73r2e7','gjkfvt47867fu4gfot7834tf834'};
       email2.replyTo = 'kahegde@akamai.com'; 
       email2.htmlBody = '<h1>Spam and Closed</h1>' ;
       HD_InfosecEmailProcess hdinfosec1 = new HD_InfosecEmailProcess();
       Messaging.InboundEmailResult res2 =  hdinfosec1.handleInboundEmail(email2, env);
        
       List<HD_EmailBuffer__c> ebs = [Select ID,Name, Incident__c   from HD_EmailBuffer__c LIMIT 1000];
       System.assertEquals(2,ebs.size());
       
   
            
       }   
    
    static testMethod void testInfosecLimits() {
        
        
        
        List<HD_EmailBuffer__c> bufferList = new  List<HD_EmailBuffer__c>();
        for(integer i =0; i < 100; i++) {
           bufferList.add(new HD_EmailBuffer__c(
            From_Address__c = 'kahegde@akamai.com',
            Message_Id__c = '847485re632fyetdf3764r376ghfe73r2'+i,
            Email_Body__c = 'test email '+i
            ));
                          
     
            
         }
        System.debug(' BUFFER LIST SZ '+bufferList.size());
        insert bufferList;
       
        
        Long startingTime = System.now().getTime(); 
        Integer delayInMilliseconds = 2000; // tw-second delay
        /*while (System.now().getTime() - startingTime < delayInMilliseconds)  {
                    // Do nothing until desired delay has passed
         }*/
         DateTime cmdt =  DateTime.now().addSeconds(-100);
       List<HD_EmailBuffer__c> totalBuf = [Select ID,Name from HD_EmailBuffer__c WHERE CreatedDate > :cmdt LIMIT 10000]; 
        
        System.debug(' BUFF SIZE '+totalBuf.size());
       HD_IncidentTestDataFactory idf = new HD_IncidentTestDataFactory();
       ManagedPkgErrorClass.isFromManagedPackage =  false;
        
       
        List<HD_EIS_INCIDENT_GROUP__c> incigroups = new List<HD_EIS_INCIDENT_GROUP__c>();
        incigroups.add(new HD_EIS_INCIDENT_GROUP__c(Name = 'HELPDESK_HARDWARE', IncidentGroup__c = 'Q_HELPDESK_HARDWARE'));
        incigroups.add(new HD_EIS_INCIDENT_GROUP__c(Name = 'HELPDESK_MALWARE', IncidentGroup__c = 'Q_HELPDESK_MALWARE'));
        incigroups.add(new HD_EIS_INCIDENT_GROUP__c(Name = 'HELPDESK_TRIAGE', IncidentGroup__c = 'Q_HELPDESK_TRIAGE'));
        incigroups.add(new HD_EIS_INCIDENT_GROUP__c(Name = 'ITOC', IncidentGroup__c = 'Q_ITOC'));
        incigroups.add(new HD_EIS_INCIDENT_GROUP__c(Name = 'ITOC_Alerts', IncidentGroup__c = 'Q_ITOC_Alerts'));
        insert incigroups;
        HD_Incident_Settings__c msact = new HD_Incident_Settings__c (Name='Missing_Actions_Update', Value__c='Email Sent');
        insert msact;
        
        
       Messaging.InboundEmail email3 = new Messaging.InboundEmail() ; 
       Messaging.InboundEnvelope env    = new Messaging.InboundEnvelope();
       email3.fromAddress = 'kahegde@akamai.com';
       email3.subject = 'My Test Ticket';
       email3.messageId = '847485re63ncekwhco3erhiadfugiubff3764r376ghfe73r2e7';
       email3.htmlBody = '<h1>New Test Body</h1>' ;
       HD_InfosecEmailProcess hdinfosec3 = new HD_InfosecEmailProcess();
       Messaging.InboundEmailResult res3 =  hdinfosec3.handleInboundEmail(email3, env);
       
        List<HD_EmailBuffer__c> ebs = [Select ID,Name, Incident__c   from HD_EmailBuffer__c LIMIT 1000];
        System.assertNotEquals(0,ebs.size());
    }

}