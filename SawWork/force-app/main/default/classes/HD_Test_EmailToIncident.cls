/*
* File Name: HD_Test_EmailToIncident
* Description : Test class for HD_EmailToIncident
* @author :
* Modification Log ===============================================================
* Date 				 Author 			  Modification
* Aug 08th, 2020     Aneesh Budnar        PRTORES-1810 - Code scanner fixes
* Nov 29th, 2021     Aneesh Budnar         PRTORES-2358 - HD Code Scanner 1 fixes
*/
@isTest(SeeAllData=false)
public class HD_Test_EmailToIncident {
    public static testMethod void testEmailToIncident()
    {
        HD_Test_Data_Factory.init();
        ManagedPkgErrorClass.isFromManagedPackage=false;
        Messaging.InboundEmail email  = new Messaging.InboundEmail();
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        email.subject = 'Test';
        email.plainTextBody = 'Test email body';
        List<HD_Email_Addresses__mdt>  emailCategories = [SELECT mailId__c ,HD_Category__r.Category__c,HD_Category__r.Parent_Tree__c,HD_Category__r.Priority__c, HD_Category__r.Client_Username__c from HD_Email_Addresses__mdt LIMIT 500];
        HD_Email_Addresses__mdt emailCat;
        for(HD_Email_Addresses__mdt emailAdd : emailCategories) {
            if(emailAdd.HD_Category__r.Category__c == 'Search Akamai') {
                emailCat = emailAdd;
                break;
            }
        }

        insert new BMCServiceDesk__Category__c(
            Name = emailCat.HD_Category__r.Category__c,
            BMCServiceDesk__AvailableForIncidents__c = true,
            BMCServiceDesk__parentTree__c = emailCat.HD_Category__r.Parent_Tree__c
        );
        email.fromAddress = emailCat.mailId__c;
        HD_EmailToIncident etoi = new HD_EmailToIncident();
        Test.startTest();
        Messaging.InboundEmailResult result = etoi.handleInboundEmail(email, envelope);
        System.assertEquals( true, result.success );
        Test.stopTest();
    }
}