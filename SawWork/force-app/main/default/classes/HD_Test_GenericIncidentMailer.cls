/*
* File Name: HD_Test_GenericIncidentMailer
* @author : Amogh M P
* Classes associated : HD_GenericIncidentMailer
*/

@isTest(SeeAllData = false)
public class HD_Test_GenericIncidentMailer {
    
    @TestSetup
    static void makeData(){
        HD_Test_Data_Factory.init();
        insert(new HD_Incident_Settings__c(Name = 'Missing_Actions_Update',value__c = 'Email Sent'));
    }
    
    @isTest
    static void testCreateIncident() {

        ManagedPkgErrorClass.isFromManagedPackage=false;
        Messaging.InboundEmail email  = new Messaging.InboundEmail();
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        
        Messaging.InboundEmail emailDup  = new Messaging.InboundEmail();
        Messaging.InboundEnvelope envelopeDup = new Messaging.InboundEnvelope();

        email.subject = 'Test';
        email.plainTextBody = 'Impact#LOW#Category#Investigate / Action on Backup Alerts#Urgency#Severity 3#Description#' + '\n'+
                              'CLIENT: prod-www-pstool02' + '\n'+
                              'DATE: Mon Oct 12 23:34:33 GMT 2020'+ '\n'+
                              'POLICY: bos_vcenter_Munich_prod'+ '\n'+
                              'SCHEDULE: Incremental'+ '\n'+
                              'SCHEDULE TYPE: INCR'+ '\n'+
                              'STATUS: 233'+ '\n'+
                              'STREAM: 2987'+ '\n'+
                              'DONE_TRYING: 0'+ '\n'+
                              'PRIMARY JOBID: 19534211';
        List<HD_Email_Addresses__mdt>  emailCategories = [SELECT mailId__c ,HD_Category__r.Category__c,HD_Category__r.Parent_Tree__c,HD_Category__r.Priority__c, HD_Category__r.Client_Username__c from HD_Email_Addresses__mdt where HD_Category__r.Category__c = 'Investigate / Action on Backup Alerts' limit 1];

        insert new BMCServiceDesk__Category__c(
            Name = emailCategories[0].HD_Category__r.Category__c,
            BMCServiceDesk__AvailableForIncidents__c = true,
            BMCServiceDesk__parentTree__c = emailCategories[0].HD_Category__r.Parent_Tree__c
        );

        email.fromAddress = emailCategories[0].mailId__c;
        List<String> cc = new List<String>{'amp@akamai.com'};
        email.ccAddresses = cc;

        emailDup.subject = 'Test duplicate';
        emailDup.plainTextBody = 'Impact##Category##Urgency##Description#' + '\n'+
                              'CLIENT: prod-www-pstool02' + '\n'+
                              'DATE: Mon Oct 12 23:34:33 GMT 2020'+ '\n'+
                              'POLICY: bos_vcenter_Munich_prod'+ '\n'+
                              'SCHEDULE: Incremental'+ '\n'+
                              'SCHEDULE TYPE: INCR'+ '\n'+
                              'STATUS: 233'+ '\n'+
                              'STREAM: 2987'+ '\n'+
                              'DONE_TRYING: 0'+ '\n'+
                              'PRIMARY JOBID: 19534211';
        emailDup.fromAddress = emailCategories[0].mailId__c;
        emailDup.ccAddresses = email.ccAddresses;
        
        HD_GenericIncidentMailer mtoi = new HD_GenericIncidentMailer();
        Test.startTest();
        Messaging.InboundEmailResult result = mtoi.handleInboundEmail(email, envelope);
        System.assertEquals( true, result.success, 'Failed' );
        Messaging.InboundEmailResult resultDup = mtoi.handleInboundEmail(emailDup, envelopeDup);
        System.assertEquals( true, resultDup.success, 'Failed' );
        Test.stopTest();  
    }

    @isTest
    static void testSubjectDuplicate() {
        
        ManagedPkgErrorClass.isFromManagedPackage=false;
        Messaging.InboundEmail emailSub  = new Messaging.InboundEmail();
        Messaging.InboundEnvelope envelopeSub = new Messaging.InboundEnvelope();
        
        Messaging.InboundEmail emailSubDuplicate  = new Messaging.InboundEmail();
        Messaging.InboundEnvelope envelopeSubDuplicate = new Messaging.InboundEnvelope();
        
        List<HD_Email_Addresses__mdt>  emailCategories = [SELECT mailId__c ,HD_Category__r.Category__c,HD_Category__r.Parent_Tree__c,HD_Category__r.Priority__c, HD_Category__r.Client_Username__c from HD_Email_Addresses__mdt where HD_Category__r.Category__c = 'ACD TTEC Support' limit 1];

        insert new BMCServiceDesk__Category__c(
            Name = emailCategories[0].HD_Category__r.Category__c,
            BMCServiceDesk__AvailableForIncidents__c = true,
            BMCServiceDesk__parentTree__c = emailCategories[0].HD_Category__r.Parent_Tree__c
        );
        
        emailSub.subject = 'Incident eTKT0875777, "This is the test" has been Updated';
        emailSub.plainTextBody = 'Test Ticket';
        emailSub.fromAddress = emailCategories[0].mailId__c;
        
        emailSubDuplicate.subject = 'Re: Incident eTKT0875777, "This is the test" has been Updated';
        emailSubDuplicate.plainTextBody = 'Test Ticket Duplicate' + '\n' +
                                          'From: "P, Amogh" <amp@akamai.com>' + '\n' +
                                          'Date: Monday, December 7, 2020 at 11:15 AM ';
        emailSubDuplicate.fromAddress = emailCategories[0].mailId__c;
        
        HD_GenericIncidentMailer mtoi = new HD_GenericIncidentMailer();
        Test.startTest();
        Messaging.InboundEmailResult result = mtoi.handleInboundEmail(emailSub, envelopeSub);
        System.assertEquals( true, result.success, 'Failed' );
        Messaging.InboundEmailResult resultDup = mtoi.handleInboundEmail(emailSubDuplicate, envelopeSubDuplicate);
        System.assertEquals( true, resultDup.success, 'Failed' );
        Test.stopTest();  
    }
}