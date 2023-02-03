/*
Author: Vandhana Krishnamurthy
Description: Test class for SC_SI_LOECreationFromVFPage
Created Date : 1 March 2017

/*=====================================================================================================+

|  HISTORY  |                                                                            

|  DATE             DEVELOPER       CR/JIRA          DESCRIPTION                                                       

|  ===========      =========       =======     =========== 
                                    
|  20-July-2020     Komal Dwivedi    ESESP-3929   - Set seeAllData = false
												  - Added scsiLOETest2, scsiLOETest3 method
+=====================================================================================================*/


@isTest(SeeAllData = false)
public class SC_SI_LOECreationFromVFPage_Test 
{
        static Id SIRecordType;
        static BMCServiceDesk__Urgency__c urg;
        static BMCServiceDesk__Category__c cat;
        static BMCServiceDesk__Impact__c ima2;
        static Account newAccount;
        static Contact newContact;
    
    static  
    {
        SIRecordType = Schema.SObjectType.BMCServiceDesk__Incident__c.getRecordTypeInfosByName().get('Service Incident').getRecordTypeId();
        
        newAccount = utilTestClass.CreateAccount('Test Account');
        newContact = utilTestClass.CreateContact('FirstName','LastName');
        
        //Create Urgency
        urg = new BMCServiceDesk__Urgency__c();
        urg.Name='tempUrgency';
        urg.SI_Applies_to_Service_Incident__c = true;
        insert urg;
        

        // changes by Vandhana for 3695602
        // Setting category type for category based on new validation on Category - Category type is mandatory 
        BMCServiceDesk__CategoryTypes__c ctype = new BMCServiceDesk__CategoryTypes__c(Name = 'categoryTypeTest' );       
        insert ctype;

        //Create Category
        cat = new BMCServiceDesk__Category__c();
        cat.Name='tempCategory';
        cat.SI_Applies_to_Service_Incident__c = true;
        cat.BMCServiceDesk__AvailableForIncidents__c = true;
        cat.BMCServiceDesk__FKCategoryType__c = ctype.Id;

        insert cat;
        
        // Create impact
        ima2 = new BMCServiceDesk__Impact__c();
        ima2.Name='tempImpact2';
        ima2.SI_Applies_to_Service_Incident__c = true;
        insert ima2;
    }
	
    /* Method to cover the catch block */
    static testMethod void scsiLOETest1()
    {
        Test.startTest();
        ApexPages.StandardController newStdCtrl = new ApexPages.StandardController(new Service_Incident_age_by_status__c());
        BMCServiceDesk__Incident__c incident = new BMCServiceDesk__Incident__c();
        incident.BMCServiceDesk__FKUrgency__c = urg.Id;
        incident.RecordTypeID = SIRecordType;
        incident.BMCServiceDesk__FKCategory__c = cat.Id;
        incident.BMCServiceDesk__FKImpact__c = ima2.Id;
        incident.How_was_the_issue_detected__c = 'Others';
        insert incident;
        
        PageReference myPage = Page.SC_SI_LOECreationPage;
        
        
        Test.setCurrentPageReference(myPage);
        SC_SI_LOECreationFromVFPage sc_si_loeObj = new SC_SI_LOECreationFromVFPage(newStdCtrl);
        sc_si_loeObj.serviceIncidentIdFrmLoePage = incident.Id;
        sc_si_loeObj.serviceIncidentIdFrmLoePage = incident.Name;
        sc_si_loeObj.save();
        sc_si_loeObj.cancel();
        sc_si_loeObj.saveandNew();
        Test.stopTest();
    }
    
    /* Method to cover the try block */
    static testMethod void scsiLOETest2(){
        Test.startTest();
        ApexPages.StandardController newStdCtrl = new ApexPages.StandardController(new Service_Incident_age_by_status__c());
        BMCServiceDesk__Incident__c incident = new BMCServiceDesk__Incident__c();
        incident.BMCServiceDesk__FKUrgency__c = urg.Id;
        incident.RecordTypeID = SIRecordType;
        incident.BMCServiceDesk__FKCategory__c = cat.Id;
        incident.BMCServiceDesk__FKImpact__c = ima2.Id;
        incident.How_was_the_issue_detected__c = 'Others';
        insert incident;
        
        PageReference myPage = Page.SC_SI_LOECreationPage;
        myPage.getParameters().put('Incidentid', incident.id);
        myPage.getParameters().put('IncidentNumber', incident.name);
        Test.setCurrentPageReference(myPage);
        SC_SI_LOECreationFromVFPage sc_si_loeObj = new SC_SI_LOECreationFromVFPage(newStdCtrl);
        sc_si_loeObj.save();
        sc_si_loeObj.cancel();
        sc_si_loeObj.saveandNew();
        Test.stopTest();
    }
    
    /* Method to cover the saveandNew function */
    static testMethod void scsiLOETest3(){
        Test.startTest();
        ApexPages.StandardController newStdCtrl = new ApexPages.StandardController(new Service_Incident_age_by_status__c());
        BMCServiceDesk__Incident__c incident = new BMCServiceDesk__Incident__c();
        incident.BMCServiceDesk__FKUrgency__c = urg.Id;
        incident.RecordTypeID = SIRecordType;
        incident.BMCServiceDesk__FKCategory__c = cat.Id;
        incident.BMCServiceDesk__FKImpact__c = ima2.Id;
        incident.How_was_the_issue_detected__c = 'Others';
        insert incident;
        
        PageReference myPage = Page.SC_SI_LOECreationPage;
        myPage.getParameters().put('Incidentid', incident.id);
        myPage.getParameters().put('IncidentNumber', incident.name);
        Test.setCurrentPageReference(myPage);
        SC_SI_LOECreationFromVFPage sc_si_loeObj = new SC_SI_LOECreationFromVFPage(newStdCtrl);
        //sc_si_loeObj.save();
        sc_si_loeObj.cancel();
        sc_si_loeObj.saveandNew();
        Test.stopTest();
    }
    
    // to cover SC_KBDocumentSync_Scheduler class
    //@isTest static void testMethod_SC_KBDocumentSync_Scheduler()
    //{
    //    List<SObject> articles = new List<SObject>();
    //    articles.add(new How_To__kav(Title = 'TEST1',language = 'en_US', Visibility__c='External', UrlName='HowTo1'+System.currentTimeMillis(), Summary='How To Summary 1'));
    //    articles.add(new Release_Notes__kav(Title = 'TEST123',language = 'en_US', Visibility__c='External', UrlName='RN1'+System.currentTimeMillis(), Summary='RN 1'));
    //    insert articles;
                
    //    Document document = new Document();
    //    document.Body = Blob.valueOf('Some Text');
    //    document.ContentType = 'application/pdf';
    //    document.DeveloperName = 'my_document';
    //    document.IsPublic = true;
    //    document.Name = 'MyDocument_html';
    //    document.FolderId = [select id from folder where name = 'External KB Articles'].id;
    //    insert document;

    //    Test.startTest();
    //    SC_KBDocumentSync_Scheduler kbDocSyncObj = new SC_KBDocumentSync_Scheduler();
    //    System.schedule('Test for SC_KBDocumentSync_Scheduler', '0 0 0 * * ?', kbDocSyncObj);
    //    kbDocSyncObj.deleteArticles();
    //    Test.stopTest();
    //}
}