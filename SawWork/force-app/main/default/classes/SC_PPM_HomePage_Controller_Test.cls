/*
Author          : Sheena
Description     : Test Class for SC_PPM_HomePage_Controller

Date                Developer                   JIRA #                 Description                                                       
------------------------------------------------------------------------------------------------------------
05 April 2022        Sheena               		ESESP-6533             Initial Version
------------------------------------------------------------------------------------------------------------ */

@isTest
public class SC_PPM_HomePage_Controller_Test {
    
    @testSetup
    static void setupMethod()
    {
        utilTestClass.createCustomSettings();
        
        Id techUserId = [Select Id from User where Profile.Name = 'Support - Tech Support Agent' and isactive=true limit 1].Id; 
        Id ppmQueue = [Select Id, Name From Group Where Type = 'Queue' and Name = 'ATS_CMP_QUEUE'].Id;
        
        // Insert Account
        Account accRec = new Account(Name ='Test12345',Website ='www.google.com',Override_Support_Geo__c='North America',Support_Level__c='SGE Enterprise Services');
        insert accRec;
        
        //Insert Case
        List<Case> caseList = new List<Case>();
        
        Case cs = new Case();
        cs.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        cs.AccountId = accRec.Id;
        cs.Subject = 'Test Case';
        cs.Service_Category__c = 'EdgeComputing';
        cs.Sub_Type__c = 'CMP Alerts';
        cs.Status = 'Assigned';
        cs.Origin = 'Akamai';
        cs.Service__c = 'Contract Management';
        cs.Request_Type__c = 'Contract Update';
        cs.Resolution_Sent__c = false;
        cs.Do_Not_Show_In_Portal_Picklist__c = 'Customer';
        cs.Work_Type__c = 'Reactive';
        cs.Do_Not_Show_in_Portal__c = False;
        cs.Problem__c = 'High App Exception Rates';
        cs.Severity__c = '3';
        cs.CreatedDate = system.now();
        cs.OwnerId = techUserId;
        caseList.add(cs);
        
        Case cs2 = new Case();
        cs2.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        cs2.AccountId = accRec.Id;
        cs2.Subject = 'Test Case';
        cs2.Service_Category__c = 'EdgeComputing';
        cs2.Sub_Type__c = 'CMP Alerts';
        cs2.Status = 'Assigned';
        cs2.Origin = 'Akamai';
        cs2.Service__c = 'Contract Management';
        cs2.Request_Type__c = 'Contract Update';
        cs2.Resolution_Sent__c = false;
        cs2.Do_Not_Show_In_Portal_Picklist__c = 'Internal Only';
        cs2.Work_Type__c = 'Proactive';
        cs2.Problem__c = 'High App Exception Rates';
        cs2.Severity__c = '1';
        cs2.OwnerId = ppmQueue;
        caseList.add(cs2); 
        
        Case cs3 = new Case();
        cs3.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        cs3.AccountId = accRec.Id;
        cs3.Subject = 'Test Case';
        cs3.Service_Category__c = 'EdgeComputing';
        cs3.Sub_Type__c = 'CMP Alerts';
        cs3.Status = 'Assigned';
        cs3.Origin = 'Akamai';
        cs3.Service__c = 'Contract Management';
        cs3.Request_Type__c = 'Contract Update';
        cs3.Resolution_Sent__c = false;
        cs3.Do_Not_Show_In_Portal_Picklist__c = 'Internal Only';
        cs3.Work_Type__c = 'Proactive';
        cs3.Problem__c = 'High App Exception Rates';
        cs3.Severity__c = '3';
        cs3.OwnerId = ppmQueue;
        caseList.add(cs3); 
        
        insert caseList;
        
        // Insert Task
        Task tsk = new Task();
        tsk.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Service Activity').getRecordTypeId();
        tsk.WhatId = cs.Id;
        tsk.Subject = 'Test Task';
        tsk.Status = 'In Progress';
        tsk.Type__c = 'Task';
        tsk.ActivityDate = system.today();
        insert tsk;
        
        // Insert Email Message
        EmailMessage[] newEmail = new EmailMessage[0]; 
        newEmail.add(new EmailMessage(FromAddress = 'abc@akamai.com', Incoming = true, ToAddress= 'abc@test.com', Subject = 'Test email', TextBody = 'hello this a test email', ParentId = cs.Id));
        Database.insert(newEmail);
        
    }
    
    @isTest 
    public static void testPPMCases(){
        
        List<String> severityFilter = new List<String>{'1','3'};
        String geographyFilter = 'Northam';
        String filterToSave = 'Severity1,2,3&Geography:All';
        String blankFilterToSave = '';
        
        Test.startTest();
        SC_PPM_HomePage_Controller.getCaseData(severityFilter,geographyFilter);
        SC_PPM_HomePage_Controller.saveFilters(filterToSave);
        SC_PPM_HomePage_Controller.saveFilters(filterToSave);
        Test.stopTest();       
    }
    
    @isTest 
    public static void testPPMFilters(){
        
        String filterToSave = 'Severity1,2,3&Geography:All';
        
        Test.startTest();
        SC_PPM_HomePage_Controller.saveFilters(filterToSave);
        SC_PPM_HomePage_Controller.saveFilters('');
        Test.stopTest();
    }
    
    
}