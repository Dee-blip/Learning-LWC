/*
* Developer  : Vandhana Krishnamurthy
* Purpose    : Test Class for SC_Elevation_TriggerHandler
* Date       : 2 Aug 2021
* 
* Date                 Developer           JIRA                            Changes
* 2-Aug-2021            Vandhana        ESESP-4359                 Elevate/Escalate on Account
*/ 

@isTest
private class SC_Elevation_TriggerHandler_Test 
{
    @testSetup
    static void testDataSetupMethod()
    {
        utilTestClass.createCustomSettings();
        
        List<Account> accList =  new List<Account>();
        Account acc = utilTestClass.CreateAccount('TestAcc1');   
        acc.Account_Elevation_Mailing_List__c = 'test@akamai.com';
        insert acc;
        
        Elevation__c elev = new Elevation__c();
        elev.Account__c = acc.Id;
        elev.Status__c = 'Open';
        elev.Customer_Temperature__c = 'Medium';
        elev.Customer_Watch__c = true;
        elev.Reason_for_Elevation__c = 'Testing Elevation 1';
        elev.Elevation_Visibility__c = 'Geo Leadership';//Added by Aditi - fixing test class error for ESESP-6831
        insert elev;
        
        Id amgSLAProcessId = [SELECT Id, Name, IsActive, IsVersionDefault FROM SlaProcess where Name = 'AMG' and IsVersionDefault = TRUE and IsActive = TRUE].Id;
        Entitlement amgEnt = new Entitlement();
        amgEnt.SlaProcessId = amgSLAProcessId;
        amgEnt.StartDate = System.today();
        amgEnt.Name = 'AMG';
        amgEnt.AccountId = acc.Id;
        insert amgEnt;
        
        EntitlementID__c entId = new EntitlementID__c();
        entId.Case_Record_Type__c = 'AMG';
        entId.Name = 'AMG';
        entId.EntitlementID__c = amgEnt.Id;
        insert entId;
        
        Case newCase;
        List<Case> lstNewCase = new List<Case>();
        
        for(Integer i=0; i<3; i++)
        {
            newCase = new Case();
            newCase.Subject = 'New Case ' + i;
            newCase.Description = 'New Description ' + i;
            newCase.Validation_Override__c = true;
            newCase.AccountId = acc.Id;
            newCase.Origin='Akamai';
            newcase.Status = 'Unassigned';
            
            newCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();

            if(Math.mod(i,3) == 1)
            {
                newCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
                newcase.Service__c = 'Other (Security)';
                newcase.Request_Type__c = 'Other';
            }
            else if(Math.mod(i,3) == 2)
            {
                newCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Managed Security').getRecordTypeId();
            }
            else if(Math.mod(i,3) == 3)
            {
                newCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('AMG').getRecordTypeId();
            }
            lstNewCase.add(newCase); 
        }
        
        insert lstNewCase;
    }
    
    public static testMethod void updateElevation()
    {
        Test.startTest();
        Elevation__c elev = [SELECT Account__c,Customer_Watch__c,Status__c FROM Elevation__c LIMIT 1];
        
        //Updated by Aditi - added elevation visibility for fixing test class error for ESESP-6831
        Elevation__c newElev = new Elevation__c(Account__c = elev.Account__c, Status__c = 'Open',Customer_Temperature__c = 'Low',Customer_Watch__c = false,Reason_for_Elevation__c = 'Test Elevation 2',Elevation_Visibility__c = 'Geo Leadership');
        insert newElev;
        
        elev.Customer_Watch__c = false;
        update elev;
        
        Account acc = [SELECT Id,Elevated__c,Customer_Watch__c FROM Account WHERE Id = :elev.Account__c LIMIT 1];
        System.assertEquals(acc.Customer_Watch__c,false);
        Test.stopTest();
    }
    
    public static testMethod void closeElevation()
    {
        Test.startTest();
        Elevation__c elev = [SELECT Account__c,Customer_Watch__c,Status__c FROM Elevation__c LIMIT 1];
        elev.Status__c = 'Closed';
        update elev;
        
        Account acc = [SELECT Id,Elevated__c,Customer_Watch__c FROM Account WHERE Id = :elev.Account__c LIMIT 1];
        System.assertEquals(acc.Customer_Watch__c,false);
        System.assertEquals(acc.Elevated__c,false);
        
        elev.Status__c = 'Open';
        update elev;

        acc = [SELECT Id,Elevated__c,Customer_Watch__c FROM Account WHERE Id = :elev.Account__c LIMIT 1];
        System.assertEquals(acc.Elevated__c,true);
        Test.stopTest();
    }                     
    
    public static testMethod void newElevationFromCase()
    {
        Test.startTest();
        Case caseRec = [SELECT Id,AccountId,Subject FROM Case WHERE RecordType.Name = 'Managed Security' LIMIT 1];
        Map<String,String> mapElevFields = new Map<String,String>();
        mapElevFields.put('Account__c',String.valueOf(caseRec.AccountId));
        mapElevFields.put('Status__c','Open');
        mapElevFields.put('Customer_Temperature__c','High');
        mapElevFields.put('Customer_Watch__c','false');
        mapElevFields.put('Reason_for_Elevation__c','Testing Elevation 2');
        mapElevFields.put('Elevation_Visibility__c','Geo Leadership');//Added by Aditi - fixing test class error for ESESP-6831
        SC_Case_LightningUtility.createElevation(JSON.serialize(mapElevFields),caseRec.Id);
        caseRec = [SELECT Elevation__r.Id,Elevation__r.Reason_for_Elevation__c FROM Case WHERE Subject = :caseRec.Subject];
        System.assertEquals(caseRec.Elevation__r.Reason_for_Elevation__c, 'Testing Elevation 2');
        
        Task elevTask = new Task();
        elevTask.RecordTypeId = Task.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Elevation_Activity').getRecordTypeId();
        elevTask.Subject = 'Testing New Elevation Task';
        elevTask.WhatId = caseRec.Elevation__r.Id;
        elevTask.Description = 'Comments';
        
        try
        {
            insert elevTask;
        }
        catch(Exception e) 
        {}
        
        Test.stopTest();
    }
    
    public static testMethod void addRecordToElevation()
    {
        Test.startTest();
        Case caseRec = [SELECT Id FROM Case WHERE RecordType.Name = 'Technical' LIMIT 1];
        Elevation__c elev = [SELECT Id FROM Elevation__c LIMIT 1];
        SC_Case_LightningUtility.addExistingRecordToElevation(caseRec.Id,'case',elev.Id);
        caseRec = [SELECT Elevation__c FROM Case WHERE Id = :caseRec.Id];
        System.assertEquals(elev.Id,caseRec.Elevation__c);
        
        Engagement_Request__c escReq = new Engagement_Request__c();
        escReq.ID__c = 'JIRA-123';
        escReq.System__c = 'JIRA';
        escReq.Case__c = caseRec.Id;
        insert escReq;
        SC_Case_LightningUtility.addExistingRecordToElevation(escReq.Id,'escalation',elev.Id);
        escReq = [SELECT Elevation__c FROM Engagement_Request__c WHERE Id = :escReq.Id];
        System.assertEquals(elev.Id,escReq.Elevation__c);
        
        SC_SI_Service_Incident__c incRec = new SC_SI_Service_Incident__c();
        incRec.Status__c = 'Incident Request';
        incRec.Severity__c ='Severity 1';
        incRec.Title__c = 'Test Incident 1';
        incRec.Summary__c ='Test Summary';
        incRec.Symptoms__c ='Test Symptoms';
        incRec.What_Incident_Criteria_is_Met__c='Test Criteria';
        incRec.Customer_Temperature__c='High';
        incRec.How_was_the_issue_detected__c='Customer';
        incRec.Customer_Advisory__c='Test Advisory';
        incRec.Validation_Override__c = true;
        incRec.Impact_Started__c = system.now();
        insert incRec;
        SC_Case_LightningUtility.addExistingRecordToElevation(incRec.Id,'serviceincident',elev.Id);
        Elevation_and_Service_Incident__c elevNSI = [SELECT Unique_ID__c FROM Elevation_and_Service_Incident__c WHERE Service_Incident__c = :incRec.Id];
        System.assertEquals(elevNSI.Unique_ID__c,String.valueOf(elev.Id) + String.valueOf(incRec.Id));
        
        Test.stopTest();
    }
    
    public static testMethod void deleteElevation()
    {
        Test.startTest();
        Elevation__c elev = [SELECT Account__c,Customer_Watch__c,Status__c FROM Elevation__c LIMIT 1];
        try
        {
            delete elev;
        }
        catch(Exception e)
        {
            System.assertEquals(e.getMessage().contains('You cannot delete an Elevation record'),true);
        }
        Test.stopTest();
    }
    
    public static testMethod void updateAccountElevationDL()
    {
        Account acc = [SELECT Account_Elevation_Mailing_List__c FROM Account LIMIT 1];
        acc.Account_Elevation_Mailing_List__c = 'new@akam.com;';
        try
        {
            update acc;
        }
        catch(Exception e)
        {
            System.assertEquals(e.getMessage().contains('Please enter valid Akamai email addresses separated by comma'),true);
        }
    }
}