/*
Author          : Sheena Bhan
Description     : Test Class for SC_AMG_Lightning


Date                Developer             JIRA #                            Description                                                       
------------------------------------------------------------------------------------------------------------------
23 Jan 2019         Sheena               ESESP-2039                     AMG Migration to Lightning
4 March 2019        Vandhana             ESESP-2039                     AMG Migration to Lightning
------------------------------------------------------------------------------------------------------------------
*/

@isTest(seeAllData = false)
public class SC_AMG_Lightning_Test 
{
    public static User amgUser;
    public static User amgUser1;
    public static Id accId; public static String userName;
    
    // Setup method to create test data.
    static
    {
        List<User> userList = [SELECT id,name,createddate,KCS_Level__c from user where Profile.Name like '%Support - AMG%' 
                               and IsActive = TRUE and KCS_Level__c = 'KCS Coach' ORDER BY CreatedDate LIMIT 2];
        amgUser = userList[0];
        amgUser1 = userList[1];
    }
    
    @testSetup
    static void setupMethod()
    {
        utilTestClass.createCustomSettings();
        userName = amgUser.Name;
        Group amgNAHotseatQ = [Select Id, Name From Group Where Type = 'Queue' 
                               And Name = 'AMG NA Hotseat Queue'];
        
        // Creating Account
        List<Account> accList =  new List<Account>();
        Account acc = utilTestClass.CreateAccount('TestAMGAccount');   
        accList.add(acc);
        insert accList;
        
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
        
        
        System.debug('1.Number of Queries used after Account Insert: ' + Limits.getQueries());
        
        accid = acc.Id;
        
        // Creating Account Team Member
        List<AccountTeamMember> accTeamInsert = new List<AccountTeamMember>();
        //accTeamInsert.add(new AccountTeamMember(AccountId = acc.Id, UserId = amgUser.Id,TeamMemberRole='Services - Primary'));
        accTeamInsert.add(new AccountTeamMember(AccountId = acc.Id, UserId = UserInfo.getUserId(),TeamMemberRole='Services - Primary'));
        insert accTeamInsert; 
        System.debug('2.Number of Queries used after AccountTeamMember Insert: ' + Limits.getQueries());
        
        LiveChatVisitor visitor = new LiveChatVisitor();
        insert visitor;
        
        System.debug('3.Number of Queries used after LiveChatVisitor Insert: ' + Limits.getQueries());
        
        Test.startTest();
        // Creating Case
        
        List<Case> newCaseInsertList = new List<Case>();
        Case newCase = new Case();
        newCase.Subject = 'TestCase';
        newCase.Description = 'TestDescription';
        newCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('AMG').getRecordTypeId();
        newCase.validation_override__c = true;
        newCase.AccountId = acc.Id;
        newCase.OwnerId = amgUser.Id;
        newCase.origin='Akamai';
        newcase.Status = 'Assigned';
        newcase.Service__c = 'Alerts';
        newcase.Request_Type__c = 'Add Alerts';
        newcase.Request_Sub_Type__c ='N/A - Not Applicable';
        newcase.Do_Not_Show_In_Portal_Picklist__c = 'Customer';
        newcase.Resolution_Field__c = 'N/A - Not Applicable';
        newcase.Resolvable_by_Partner__c = false;
        newcase.LOE_Hours__c=2;
        newcase.LOE_Minutes__c=30; 
        newcase.Solution_Summary__c= 'Test';
        newcase.PRISM_Used__c = 'Yes';
        newcase.Task_LOE__c= 8;
        newcase.Last_Case_Owner_Update__c = System.now();
        newcase.Last_Non_Case_Owner_Update__c = System.now();
        newcase.Last_Customer_Activity_Date__c = System.now();
        
        //newcase.Autogen_UseCase__c = 'COB';
        newcase.Validation_Override__c = true;
        newCaseInsertList.add(newCase);
        
        List<LiveChatTranscript> lLiveChatTranscript = new List<LiveChatTranscript>();
        List<Task> taskList = new List<Task>();
        
        for(Integer i=0; i<10; i++)
        {
            newCase = new Case();
            newCase.Subject = 'AMG Case ' + i;
            newCase.Description = 'TestDescription ' + i;
            if(Math.mod(i,2) == 0)
            {
                newCase.OwnerId = amgNAHotseatQ.Id;
            }
            else
            {
                newCase.OwnerId = amgUser.Id;
                newCase.Subject = 'AMG Chat Case ' + i;
                LiveChatTranscript liveChatTranscript = new LiveChatTranscript(CaseId = newCase.id, LiveChatVisitorId = visitor.Id, StartTime = System.now(), EndTime = System.now().addSeconds(100));
                lLiveChatTranscript.add(liveChatTranscript);
                Task tsk = new Task();
                tsk.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('AMG Activity').getRecordTypeId();
                tsk.WhatId = newCase.Id;
                tsk.Subject = 'User Setup';
                tsk.Status = 'In Progress';
                tsk.Type__c = 'Task';
                taskList.add(tsk);
            }
            newCase.Do_Not_Show_In_Portal__c = TRUE;
            newCase.origin='Akamai';
            newcase.Service__c = 'Accounts Audits';
            newcase.Request_Type__c = 'Customer Onboarding';
            newcase.Request_Sub_Type__c ='New Customer Onboarding';
            newcase.Resolution_Field__c = 'N/A - Not Applicable';
            newcase.Resolvable_by_Partner__c = false;
            newcase.LOE_Hours__c = 2;
            newcase.LOE_Minutes__c = 30; 
            newcase.Solution_Summary__c= 'Test';
            newcase.PRISM_Used__c = 'Yes';
            newcase.Task_LOE__c= 8;
            newcase.Last_Case_Owner_Update__c = System.now();
            newcase.Last_Non_Case_Owner_Update__c = System.now();
            newcase.Last_Customer_Activity_Date__c = System.now();
            newcase.Autogen_UseCase__c = 'COB';
            newCaseInsertList.add(newCase);  
        }
        
        newcase = newCaseInsertList[0];
        
        System.runAs(amgUser)
        {
            insert newCaseInsertList;
            System.debug('4.Number of Queries used after Case part 1 Insert: ' + Limits.getQueries());
            
            
            Engagement_Request__c  escReq = new Engagement_Request__c();
            escReq.ID__c = 'Test Id';
            escReq.System__c = 'Non - JIRA';
            escReq.Case__c = newCaseInsertList[0].Id;
            insert escReq;
            
            System.debug('5.1. Number of Queries used after Engagement_Request__c Insert: ' + Limits.getQueries());
            
            
            insert lLiveChatTranscript;
            System.debug('5.Number of Queries used after lLiveChatTranscript Insert: ' + Limits.getQueries());
            
            Knowledge__kav  k = new Knowledge__kav ();
            k.Title = 'APEX TEST';
            k.UrlName = 'APEX-TEST';
            k.Language = 'en_US';
            insert k;
            
            k = [SELECT KnowledgeArticleId FROM Knowledge__kav  WHERE Id = :k.Id];    
            KbManagement.PublishingService.publishArticle(k.KnowledgeArticleId, true);
            CaseArticle ca = new CaseArticle();
            ca.CaseId = newCaseInsertList[0].Id;
            ca.KnowledgeArticleId = k.KnowledgeArticleId;
            insert ca;
            
            
            Attachment attach=new Attachment();     
            attach.Name='Unit Test Attachment';
            Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
            attach.body=bodyBlob;
            attach.parentId=newCaseInsertList[0].id;
            insert attach;
            
            Blob b = Blob.valueOf('Test Data');
            Attachment attachment = new Attachment();
            attachment.ParentId = newCaseInsertList[0].Id;
            attachment.Name = 'Test Attachment for Parent';
            attachment.Body = b;
            insert(attachment);
            
            
            newCaseInsertList.clear();
            
            
            // System.debug('9.1.Number of Queries used after attach  Insert: ' + Limits.getQueries());
            
            Case newCase3 = new Case();
            newCase3.Subject = 'TestCase2';
            newCase3.Description = 'TestDescription';
            newCase3.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('AMG').getRecordTypeId();
            newCase3.validation_override__c = true;
            newCase3.AccountId = acc.Id;
            newCase3.origin='Akamai';
            newCase3.Status = 'Assigned';
            newCase3.Service__c = 'Accounts Audits';
            newCase3.Request_Type__c = 'Customer Onboarding';
            newCase3.Request_Sub_Type__c ='Existing Customer Onboarding';
            newCase3.Do_Not_Show_In_Portal_Picklist__c = 'Internal Only';
            newCase3.Resolution_Field__c = 'N/A - Not Applicable';
            newCase3.Resolvable_by_Partner__c = false;
            newCase3.LOE_Hours__c=2;
            newCase3.LOE_Minutes__c=30; 
            newCase3.Solution_Summary__c= 'Test';
            newCase3.PRISM_Used__c = 'Yes';
            newCase3.Task_LOE__c= 8;
            newCase3.Partner_Account__c = acc.Id;
            newCase3.Indirect_Customer__c = acc.Id;
            newCase3.Last_Case_Owner_Update__c = System.now();
            newCase3.Last_Non_Case_Owner_Update__c = System.now();
            newCase3.Last_Customer_Activity_Date__c = System.now();
            newCaseInsertList.add(newCase3);
            try 
            {
                Database.insert(newCaseInsertList,false);
                System.debug('9.2.Number of Queries used after Case Insert part 2 Insert: ' + Limits.getQueries());
                
            }
            catch(Exception e){ }
            
            /*    BMCServiceDesk__CategoryTypes__c ctype = new BMCServiceDesk__CategoryTypes__c(Name = 'categoryTypeTest' );       
insert ctype;

BMCServiceDesk__Category__c cat = new BMCServiceDesk__Category__c();
cat.Name='TempCategory';
cat.SI_Applies_to_Service_Incident__c = true;
cat.BMCServiceDesk__AvailableForServiceCatalog__c = true;
cat.BMCServiceDesk__FKCategoryType__c = ctype.Id;
insert cat;

BMCServiceDesk__Impact__c ima = new BMCServiceDesk__Impact__c();
ima.Name='tempImpact';
ima.SI_Applies_to_Service_Incident__c = true;
insert ima;

BMCServiceDesk__Urgency__c  urg = new BMCServiceDesk__Urgency__c();
urg.Name='tempUrgency1';
urg.SI_Applies_to_Service_Incident__c = true;
insert urg;

BMCServiceDesk__Status__c sta2 = new BMCServiceDesk__Status__c();
sta2.Name='ON HOLD';
sta2.SI_Applies_to_Service_Incident__c = true;
sta2.BMCServiceDesk__inactive__c=false;
sta2.BMCServiceDesk__appliesToIncident__c = true;
insert sta2;

List<BMCServiceDesk__Incident__c> lstIncident = new List<BMCServiceDesk__Incident__c>();
BMCServiceDesk__Incident__c incident = new BMCServiceDesk__Incident__c();
incident.RecordTypeId = BMCServiceDesk__Incident__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Service Incident').getRecordTypeId();
incident.BMCServiceDesk__FKCategory__c = cat.Id;
incident.BMCServiceDesk__FKUrgency__c = urg.id;
incident.BMCServiceDesk__FKImpact__c = ima.Id;
incident.BMCServiceDesk__shortDescription__c = 'Inc1';
incident.how_was_the_issue_detected__c = 'others';
incident.BMCServiceDesk__FKStatus__c = sta2.id;
//insert incident;
*/
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
            
        }
        
        
        
        Test.stopTest();
        
        System.runAs(amgUser)
        {
            insert taskList;
        }
        System.debug('6.Number of Queries used after taskList Insert: ' + Limits.getQueries());
        
        //  List<Attachment> attachments=[select id, name from Attachment where parent.id=:newCaseInsertList[0].id];/
        
    }
    
    /*   @isTest
public static void testAMGCaseMethods()
{        
Test.startTest();
System.debug('10. Number of Queries used after testCaseMethods 1 Insert: ' + Limits.getQueries());
Account acc = [Select Id from Account where name='TestAMGAccount' LIMIT 1];
List<Case> CaseDet = [Select Id,Subject,Description,origin,Service__c,Request_Type__c,Request_Sub_Type__c,
Resolution_Field__c,Solution_Summary__c,ResolvableByPartner__c,Recommended_Partner_Action__c,LOE_Hours__c,
LOE_Minutes__c,PRISM_Used__c,Task_LOE__c from Case where Subject='TestCase' LIMIT 1];



map<String,String> mCaseFieldVal = new map<String,String>();
mCaseFieldVal.put('Id',CaseDet[0].Id);
mCaseFieldVal.put('Subject',CaseDet[0].Subject);
mCaseFieldVal.put('Description',CaseDet[0].Description);
mCaseFieldVal.put('origin',CaseDet[0].origin);
mCaseFieldVal.put('Service__c',CaseDet[0].Service__c);
mCaseFieldVal.put('Request_Type__c',CaseDet[0].Request_Type__c);
mCaseFieldVal.put('Request_Sub_Type__c',CaseDet[0].Request_Sub_Type__c);
mCaseFieldVal.put('Resolution_Field__c',CaseDet[0].Resolution_Field__c);
mCaseFieldVal.put('Solution_Summary__c',CaseDet[0].Solution_Summary__c);
mCaseFieldVal.put('ResolvableByPartner__c',CaseDet[0].ResolvableByPartner__c);
mCaseFieldVal.put('Recommended_Partner_Action__c',CaseDet[0].Recommended_Partner_Action__c);
mCaseFieldVal.put('LOE_Hours__c', string.valueOf(CaseDet[0].LOE_Hours__c));
mCaseFieldVal.put('LOE_Minutes__c',string.valueOf(CaseDet[0].LOE_Minutes__c));
mCaseFieldVal.put('PRISM_Used__c',CaseDet[0].PRISM_Used__c);
mCaseFieldVal.put('Task_LOE__c',string.valueOf(CaseDet[0].Task_LOE__c));

String caseVals = '[' + JSON.serialize(mCaseFieldVal) + ']';
String caseValues = caseVals.removeEnd('__c');

system.debug('accId//'+accId);
List<String> accIdSet = new List<String>();
accIdSet.add(acc.Id);
system.debug('accIdSet//'+accIdSet);
SC_AMG_Lightning scAMG = new SC_AMG_Lightning();
SC_AMG_Lightning.getCaseRecType();
SC_AMG_Lightning.getAMGCaseRecTypeId();
SC_AMG_Lightning.cloneMulti(accIdSet, CaseDet[0].Id);
SC_AMG_Lightning.createChildcase(CaseDet[0].Id, 'AMG');
SC_AMG_Lightning.reopenClosedCase(CaseDet[0].Id);
SC_AMG_Lightning.cloneCaseRec(CaseDet[0].Id);
SC_AMG_Lightning.closeCaseInvalid(CaseDet[0].Id, 'Test');
SC_AMG_Lightning.closeCases(CaseDet[0].Id, mCaseFieldVal);
SC_AMG_Lightning.updateClosedCases(caseValues);
SC_AMG_Lightning.getCaseStatus(CaseDet[0].Id);
SC_AMG_Lightning.getAccountData(CaseDet[0].Id);
SC_AMG_Lightning.getAccounts(acc.Id);
// CaseTriggerClass.createRelatedRecs(mcaseIds);
SC_AMG_Lightning.ParseCaseClosePayload parseWrap = new SC_AMG_Lightning.ParseCaseClosePayload();
SC_AMG_Lightning.WrapperResponse respWrap = new SC_AMG_Lightning.WrapperResponse(); 

Test.stopTest();
}*/
    
    
    @isTest
    public static void testCloseMethods()
    {        
        Test.startTest();
        System.debug('10. Number of Queries used after testCaseMethods 1 Insert: ' + Limits.getQueries());
        List<Case> CaseDet = [Select Id,Subject,Description,origin,Service__c,Request_Type__c,Request_Sub_Type__c,
                              Resolution_Field__c,Solution_Summary__c,ResolvableByPartner__c,Recommended_Partner_Action__c,LOE_Hours__c,
                              LOE_Minutes__c,PRISM_Used__c,Task_LOE__c from Case where Subject='TestCase' LIMIT 1];
        
        map<String,String> mCaseFieldVal = new map<String,String>();
        mCaseFieldVal.put('Id',CaseDet[0].Id);
        mCaseFieldVal.put('Subject',CaseDet[0].Subject);
        mCaseFieldVal.put('Description',CaseDet[0].Description);
        mCaseFieldVal.put('origin',CaseDet[0].origin);
        mCaseFieldVal.put('Service__c',CaseDet[0].Service__c);
        mCaseFieldVal.put('Request_Type__c',CaseDet[0].Request_Type__c);
        mCaseFieldVal.put('Request_Sub_Type__c',CaseDet[0].Request_Sub_Type__c);
        mCaseFieldVal.put('Resolution_Field__c',CaseDet[0].Resolution_Field__c);
        mCaseFieldVal.put('Solution_Summary__c',CaseDet[0].Solution_Summary__c);
        mCaseFieldVal.put('ResolvableByPartner__c',CaseDet[0].ResolvableByPartner__c);
        mCaseFieldVal.put('Recommended_Partner_Action__c',CaseDet[0].Recommended_Partner_Action__c);
        mCaseFieldVal.put('LOE_Hours__c', string.valueOf(CaseDet[0].LOE_Hours__c));
        mCaseFieldVal.put('LOE_Minutes__c',string.valueOf(CaseDet[0].LOE_Minutes__c));
        mCaseFieldVal.put('PRISM_Used__c',CaseDet[0].PRISM_Used__c);
        mCaseFieldVal.put('Task_LOE__c',string.valueOf(CaseDet[0].Task_LOE__c));
        
        String caseVals = '[' + JSON.serialize(mCaseFieldVal) + ']';
        String caseValues = caseVals.removeEnd('__c');
        
        SC_AMG_Lightning.closeCaseInvalid(CaseDet[0].Id, 'Test');
        SC_AMG_Lightning.closeCases(CaseDet[0].Id, mCaseFieldVal);
        SC_AMG_Lightning.updateClosedCases(caseValues);
        Test.stopTest();
    }
    
    
    @isTest
    public static void testCloneMethods()
    {        
        Test.startTest();
        System.debug('10. Number of Queries used after testCaseMethods 1 Insert: ' + Limits.getQueries());
        Account acc = [Select Id from Account where name='TestAMGAccount' LIMIT 1];
        List<Case> CaseDet = [Select Id,Subject,Description,origin,Service__c,Request_Type__c,Request_Sub_Type__c,
                              Resolution_Field__c,Solution_Summary__c,ResolvableByPartner__c,Recommended_Partner_Action__c,LOE_Hours__c,
                              LOE_Minutes__c,PRISM_Used__c,Task_LOE__c from Case where Subject='TestCase' LIMIT 1];
        
        
        
        List<String> accIdSet = new List<String>();
        accIdSet.add(acc.Id);
        
        SC_AMG_Lightning.cloneMulti(accIdSet, CaseDet[0].Id);
        SC_AMG_Lightning.cloneCaseRec(CaseDet[0].Id);
        SC_AMG_Lightning.getAccounts(acc.Id);
        
        
        
        Test.stopTest();
    }
    
    @isTest
    public static void testCaseRecMethods()
    {        
        Test.startTest();
        List<Case> CaseDet = [Select Id,Subject,Description,origin,Service__c,Request_Type__c,Request_Sub_Type__c,
                              Resolution_Field__c,Solution_Summary__c,ResolvableByPartner__c,Recommended_Partner_Action__c,LOE_Hours__c,
                              LOE_Minutes__c,PRISM_Used__c,Task_LOE__c from Case where Subject='TestCase' LIMIT 1];
        
        
        SC_AMG_Lightning.createChildcase(CaseDet[0].Id, 'AMG');
        SC_AMG_Lightning.reopenClosedCase(CaseDet[0].Id);
        SC_AMG_Lightning.getCaseStatus(CaseDet[0].Id);
        SC_AMG_Lightning.getAccountData(CaseDet[0].Id);
        
        Test.stopTest();
    }
    
    @isTest
    public static void testAMGCaseMethods()
    {        
        Test.startTest();
        SC_SI_Service_Incident__c siRec = [SELECT Id, Name, Severity__c , Impact_Started__c , Title__c ,Status__c  FROM SC_SI_Service_Incident__c  WHERE Status__c != 'Closed' LIMIT 500];
        
        SC_AMG_Home_Lightning.SIWrapper siWrapper = new SC_AMG_Home_Lightning.SIWrapper();
        siWrapper.siRec = siRec;
        siWrapper.siRecId = siRec.Id;
        siWrapper.IncidentNumber = siRec.Name;
        siWrapper.Title = siRec.Title__c;
        siWrapper.Status = siRec.Status__c;
        siWrapper.IncidentStart =  string.valueOf(siRec.Impact_Started__c.format());
        siWrapper.Urgency = siRec.Severity__c; 
        
        SC_AMG_Lightning.getCaseRecType();
        SC_AMG_Lightning.getAMGCaseRecTypeId();
        SC_AMG_Lightning.ParseCaseClosePayload parseWrap = new SC_AMG_Lightning.ParseCaseClosePayload();
        SC_AMG_Lightning.WrapperResponse respWrap = new SC_AMG_Lightning.WrapperResponse(); 
        
        Test.stopTest();
    }
    
    
    // changes by Vandhana to cover SC_AMG_Home_Lightning controller class
    public static testMethod void amgHomeLightning_test()
    {
        List<Case> CaseDet = [Select Id,Subject,Description,origin,Service__c,Request_Type__c,Request_Sub_Type__c,
                              Resolution_Field__c,Solution_Summary__c,ResolvableByPartner__c,Recommended_Partner_Action__c,LOE_Hours__c,
                              LOE_Minutes__c,PRISM_Used__c,Task_LOE__c from Case where Subject like 'AMG Chat Case%' LIMIT 1];
        
        List<Id> caseIdList = new List<Id>();
        caseIdList.add(CaseDet[0].Id);
        Account acc = [Select Id from Account where name='TestAMGAccount' LIMIT 1];
        
        System.debug('12. Number of Queries used after amgHomeLightning_test Insert: ' + Limits.getQueries());
        
        Test.startTest();
        System.runAs(amgUser)
        {
            SC_AMG_Home_Lightning obj = new SC_AMG_Home_Lightning();
            SC_AMG_Home_Lightning.isUserManagerCheck();
            List<SC_AMG_Home_Lightning.CaseWrapper> caseWrapperList = SC_AMG_Home_Lightning.getCaseListForAMG('My Open Cases', 'user', 50, 0);
            
            // get Cases tagged to Queue
            caseWrapperList = SC_AMG_Home_Lightning.getCaseListForAMG('AMG NA Hotseat Queue', 'queue', 50, 0);
            
            
            SC_AMG_Home_Lightning.CaseWrapper csWrapper = new SC_AMG_Home_Lightning.CaseWrapper();
            SC_AMG_Home_Lightning.EscalationWrapper esWrapper = new SC_AMG_Home_Lightning.EscalationWrapper();
            SC_AMG_Home_Lightning.SIWrapper siWrapper = new SC_AMG_Home_Lightning.SIWrapper();
            SC_AMG_Home_Lightning.TaskWrapper taskWrapper = new SC_AMG_Home_Lightning.TaskWrapper();
            
            SC_AMG_Home_Lightning.searchAMGManagers(amgUser.Name);
            SC_AMG_Home_Lightning.getAMGQueues();
            SC_AMG_Home_Lightning.toggleUserAvailability();
            //SC_AMG_Home_Lightning.assignCase(CaseDet[0].Id);
            SC_AMG_Home_Lightning.assignCaseToUser(CaseDet[0].Id,amgUser.Id);
            SC_AMG_Home_Lightning.getUserAvailabilility();
            SC_AMG_Home_Lightning.fetchUserBackup(amgUser.Id);
            SC_AMG_Home_Lightning.fetchSelectedAMGUser(amgUser.Id);
            SC_AMG_Home_Lightning.fetchAccountTeamMembers(acc.Id);
            SC_AMG_Home_Lightning.akachatTranscript(caseIdList);
            //SC_AMG_Home_Lightning.akachatTranscriptBody(CaseDet[0].Id);
        }
        try
        {
        SC_AMG_Home_Lightning.addBackupUser(amgUser.Id);
        }
        catch(Exception e) {}
        
        
        Test.stopTest();
    }
    
    public static testMethod void amgHomeLightning_test2()
    {
        Test.startTest();
        System.debug('13. Number of Queries used after amgHomeLightning_test2 Insert: ' + Limits.getQueries());
        
        Agent_Home_Collection_Limit__c aHomeSet =  new Agent_Home_Collection_Limit__c();
        aHomeSet.Name = 'Limit Value';
        aHomeSet.Collection_Limit__c = 10;
        insert aHomeSet;
        
        System.runAs(amgUser)
        {
            SC_AMG_Home_Lightning.SLAAlertButtonColor('My Open Cases');
            SC_AMG_Home_Lightning.populateSLACases('My Open Cases');
            SC_AMG_Home_Lightning.ageingCasesCount('My Open Cases');
            SC_AMG_Home_Lightning.populateAgeingCases('My Open Cases');
            SC_AMG_Home_Lightning.populateEscalationsCount();
            SC_AMG_Home_Lightning.populateEscalations('Open Escalations');
            SC_AMG_Home_Lightning.amgEscalationRecTypeId();
            SC_AMG_Home_Lightning.populateIncidents('All Open Incidents');
            SC_AMG_Home_Lightning.populateIncidentsCount('All Open Incidents');
            SC_AMG_Home_Lightning.getCasesForAMGQueue('Transition Queue');
            SC_AMG_Home_Lightning.isUserManagerCheck();
            SC_AMG_Home_Lightning.getCaseListForAMGCount('My Open Cases','user');
        }
        
        Test.stopTest();
    }
    
    public static testMethod void amgHomeLightning_test3()
    {
        Test.startTest();
        List<Case> CaseDet = [Select Id,Subject,Description,origin,Service__c,Request_Type__c,Request_Sub_Type__c,
                              Resolution_Field__c,Solution_Summary__c,ResolvableByPartner__c,Recommended_Partner_Action__c,LOE_Hours__c,
                              LOE_Minutes__c,PRISM_Used__c,Task_LOE__c from Case where Subject like 'AMG Case%' LIMIT 1];
        System.debug('14. Number of Queries used after amgHomeLightning_test3 part 1 Insert: ' + Limits.getQueries());
        
        
        List<Task> TaskList = new List<Task>();
        Task tsk = new Task();
        // tsk.OwnerId = getUserId;
        tsk.Subject = 'User Setup';
        tsk.Status = 'In Progress';
        tsk.Type__c = 'Task';
        tsk.Priority = 'High';
        tsk.WhatId = CaseDet[0].Id;
        tsk.OwnerId = amgUser.Id;
        tsk.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('AMG Activity').getRecordTypeId();
        //tsk.DueDateProlexic__c = myDateTime;
        TaskList.add(tsk);
        insert TaskList;
        System.debug('15. Number of Queries used after TaskList Insert: ' + Limits.getQueries());
        
        System.debug('16. Number of Queries used after amgHomeLightning_test3 part 2 Insert: ' + Limits.getQueries());
        
        System.runAs(amgUser)
        {
            SC_AMG_Home_Lightning.getOpenTaskAMG('My Open Tasks',5,0);
            SC_AMG_Home_Lightning.getOpenTaskAMGCount('My Open Tasks');
            SC_AMG_Home_Lightning.UserWrapper usrWrapper = new SC_AMG_Home_Lightning.UserWrapper();
            SC_AMG_Home_Lightning.TaskWrapper tskWrapper = new SC_AMG_Home_Lightning.TaskWrapper();
            SC_AMG_Home_Lightning.EscalationWrapper  escWrapper = new SC_AMG_Home_Lightning.EscalationWrapper();
            SC_AMG_Home_Lightning.SIWrapper siWrapper = new SC_AMG_Home_Lightning.SIWrapper();
            try
            {
            SC_AMG_Home_Lightning.assignCase(CaseDet[0].Id);
        }
            catch(Exception e){}
        }
        
        Test.stopTest();
    }
    
    public static testMethod void testingTaskCreation(){
        List<Task> lTasks = [SELECT Id, Type__c, Status, Owner.Name, OwnerId, WhatId FROM Task];
        System.debug('### ' + lTasks);
        System.debug('#### AMG User ' + amgUser);
        Test.startTest();
        System.runAs(amgUser)
        {            
            SC_AMG_Home_Lightning.getOpenTaskAMG('My Open Tasks',0,5);
            SC_AMG_Home_Lightning.populateIncidents('All Open Incidents');
        }
        Test.stopTest();
    }
    
    public static testMethod void relcaseTest()
    {
        Test.startTest();   
        
        List<Case> CaseDet = [Select Id,Subject,Description,origin,Service__c,Request_Type__c,Request_Sub_Type__c,
                              Resolution_Field__c,Solution_Summary__c,ResolvableByPartner__c,Recommended_Partner_Action__c,LOE_Hours__c,
                              LOE_Minutes__c,PRISM_Used__c,Task_LOE__c from Case where Subject='TestCase' LIMIT 1];
        
        List<Case> CaseDet1 = [Select Id,Subject,Description,origin,Service__c,Request_Type__c,Request_Sub_Type__c,
                               Resolution_Field__c,Solution_Summary__c,ResolvableByPartner__c,Recommended_Partner_Action__c,LOE_Hours__c,
                               LOE_Minutes__c,PRISM_Used__c,Task_LOE__c from Case where Subject like '%AMG Case%' LIMIT 1];
        System.debug('111. Number of Queries used after RelcaseTest query: ' + Limits.getQueries());
        
        
        map<id,id> mcaseIds  = new  map<id,id>();
        mcaseIds.put(CaseDet[0].id,CaseDet1[0].id);
        CaseTriggerClass.createRelatedRecs(mcaseIds);
        Test.stopTest();  
        
        System.debug('112. Number of Queries used aftercalling Relcases: ' + Limits.getQueries());
    } 
    
    public static testMethod void testSLACasesOrange()
    {
        CaseMilestone cm = [SELECT Id,StartDate,TargetDate,CompletionDate,CaseId,TimeRemaininginMins,TimeRemaininginHrs FROM CaseMilestone WHERE MilestoneType.Name = 'Initial Response' AND IsCompleted = FALSE and Case.OwnerId = :amgUser.Id and Case.IsClosed = FALSE LIMIT 1];
        cm.StartDate = System.now().addHours(-22);
        update cm;
        
        cm = [SELECT Id,StartDate,TargetDate,CompletionDate,CaseId,TimeRemaininginMins,TimeRemaininginHrs FROM CaseMilestone WHERE Id = :cm.Id LIMIT 1];
        if(Decimal.valueOf(cm.TimeRemainingInHrs.replace(':','.')) > 4)
        {
            cm.StartDate = System.now().addHours(-46);
            update cm;
        }
        
        cm = [SELECT Id,StartDate,TargetDate,CompletionDate,CaseId,TimeRemaininginMins,TimeRemaininginHrs FROM CaseMilestone WHERE Id = :cm.Id LIMIT 1];
        if(Decimal.valueOf(cm.TimeRemainingInHrs.replace(':','.')) > 4)
        {
            cm.StartDate = System.now().addHours(-70);
            update cm;
        }
        
        Case amgCase = [SELECT OwnerId FROM Case WHERE Id = :cm.CaseId];
        amgCase.OwnerId = amgUser1.Id;
        amgCase.AKAM_Created_Date__c  = System.today().addDays(-12);
        update amgCase;
        
        System.debug('MILESTONE START DATE : ' + cm.StartDate);
        System.debug('MILESTONE TIME LEFT : ' + cm.TimeRemainingInHrs);
        
        Test.startTest(); 
        
        System.runAs(amgUser1)
        {
            SC_AMG_Home_Lightning.SLAAlertButtonColor('My Open Cases');
            SC_AMG_Home_Lightning.populateSLACases('My Open Cases');
            SC_AMG_Home_Lightning.ageingCasesCount('My Open Cases');
            SC_AMG_Home_Lightning.populateAgeingCases('My Open Cases');
        }
        
        Test.stopTest();  
        
        System.debug('112. Number of Queries used aftercalling Relcases: ' + Limits.getQueries());
    }  
    
    public static testMethod void testSLACasesGreen()
    {
        CaseMilestone cm = [SELECT Id,StartDate,TargetDate,CompletionDate,CaseId FROM CaseMilestone WHERE MilestoneType.Name = 'Initial Response' AND IsCompleted = FALSE and Case.OwnerId = :amgUser.Id and Case.IsClosed = FALSE LIMIT 1];
        Case amgCase = [SELECT OwnerId FROM Case WHERE Id = :cm.CaseId];
        amgCase.OwnerId = amgUser1.Id;
        amgCase.AKAM_Created_Date__c  = System.today().addDays(-12);
        
        Test.startTest(); 
        
        update amgCase;
        cm.CompletionDate = cm.StartDate;
        update cm;
        
        System.runAs(amgUser1)
        {
            SC_AMG_Home_Lightning.SLAAlertButtonColor('My Open Cases');
            SC_AMG_Home_Lightning.populateSLACases('My Open Cases');
            SC_AMG_Home_Lightning.ageingCasesCount('My Open Cases');
            SC_AMG_Home_Lightning.populateAgeingCases('My Open Cases');
        }
        
        Test.stopTest();  
        
        System.debug('112. Number of Queries used aftercalling Relcases: ' + Limits.getQueries());
    }  
    
    public static testMethod void testSLACasesRed()
    {
        CaseMilestone cm = [SELECT Id,StartDate,TargetDate,CaseId,CompletionDate FROM CaseMilestone WHERE MilestoneType.Name = 'Initial Response' AND IsCompleted = FALSE and Case.OwnerId = :amgUser.Id LIMIT 1];
        
        Case amgCase = [SELECT OwnerId FROM Case WHERE Id = :cm.CaseId];
        amgCase.OwnerId = amgUser1.Id;
        amgCase.AKAM_Created_Date__c  = System.today().addDays(-22);
        
        Test.startTest();  
        
        update amgCase;
        cm.StartDate = System.now().addHours(-72);
        update cm;
        
        System.runAs(amgUser1)
        {
            SC_AMG_Home_Lightning.SLAAlertButtonColor('My Open Cases');
            SC_AMG_Home_Lightning.populateSLACases('My Open Cases');
            SC_AMG_Home_Lightning.ageingCasesCount('My Open Cases');
            SC_AMG_Home_Lightning.populateAgeingCases('My Open Cases');
        }
        
        Test.stopTest();  
        
        System.debug('112. Number of Queries used aftercalling Relcases: ' + Limits.getQueries());
    } 
    
    public static testMethod void testMultiTaskUpdateMethod()
    {
        Case amgCase = [SELECT OwnerId FROM Case LIMIT 1];
        Task tsk = [SELECT Id,Status FROM Task LIMIT 1];
        SC_Amg_Lightning.allOpenTaskRelatedToCase(amgCase.id, 0, 5);
        SC_Amg_Lightning.openTaskCount(amgCase.id);
        String result = SC_Amg_Lightning.updateBulkTaskStatus('Completed',new list<String>{''+tsk.Id});
        SC_Amg_Lightning.fetchRecordTypeValues();
        SC_Amg_Lightning.getRecTypeId('AMG Activity');
        System.assertEquals('',result);
        SC_Amg_Lightning.getCaseFields(amgCase.Id);	
        SC_Amg_Lightning.peerReviewClone(amgCase.Id);
    }
    
    public static testMethod void getDefaultListViewInCacheTest()
    {
        Test.startTest();
        SC_AMG_Home_Lightning.setDefaultListViewInCache('filterSelect','All');
        SC_AMG_Home_Lightning.setDefaultListViewInCache('queueFilter','AMG NA Hotseat Queue');
        SC_AMG_Home_Lightning.setDefaultListViewInCache('taskFilter','All');
        SC_AMG_Home_Lightning.getDefaultListViewInCache('myCase');
        SC_AMG_Home_Lightning.getDefaultListViewInCache('myQueue');
        SC_AMG_Home_Lightning.getDefaultListViewInCache('myTask');
        
    }
}