/*=====================================================================================================+
Class name          :   SC_Akatec_Lightning_Homepage 
Author              :   Sumukh SS
Created             :   11-Feb-19
Purpose             :   This is the Test class for SC Akatec Lightning Home Page

Last Modified Developer                 Purpose            
============= ========================  =======
11-FEB-19     Sumukh SS                 ESESP-1900
+=====================================================================================================*/
@isTest
public class SC_Akatec_Lightning_TC 
{
    
    // For Test Data setup
    @testSetup static void datasetup() 
    {    
        //Create all custom settings
        utilTestClass.createCustomSettings();
        
        Id getUserID = [select id from user where isactive=true and profile.name ='Support - Tech Support Manager' limit 1][0].Id;
        string queueid; string escqueueid;
        
        //Create a new record in SC QM User Filter with empty geos
        SC_QM_User_Filter__c newScQmRecordNoGeo= new SC_QM_User_Filter__c(User_Id__c='NoGeo');
        insert newScQmRecordNoGeo;
        
        //getting user of system admin
        user getadminUserID = [select id from user where isactive=true and profile.name ='System Administrator' limit 1];
        
        //Create list of Groups
        List<Group> gLst = new List<Group>();
        
        // String to store all Group Names
        List<string> allGrpNames = new List<string>{'STBE Media Queue','AMG EMEA Queue','ATS_WEBEXP_QUEUE','Billing Queue',
            'ATS_ER_API_QUEUE','STBE Media Escalation Queue','ATS_ER_WEB_QUEUE'};
                
                Group grp;
        // Loop to add all Groups to List
        for(string eachGroupName : allGrpNames){
            
            grp = new Group(Name=eachGroupName, type='Queue');
            gLst.add(grp);
            
        }
        System.runas(getadminUserID) 
        {
            insert gLst;
        }
        
        //Create list of queues 
        List<QueuesObject> qLst = new List<QueuesObject>(); 
        QueuesObject q1 = new QueueSObject(QueueID = gLst[0].id, SobjectType = 'Case');
        qLst.add(q1);
        QueuesObject q2 = new QueueSObject(QueueID = gLst[1].id, SobjectType = 'Case');
        qLst.add(q2);
        QueuesObject q3 = new QueueSObject(QueueID = gLst[2].id, SobjectType = 'Case');
        qLst.add(q3);
        QueuesObject q4 = new QueueSObject(QueueID = gLst[3].id, SobjectType = 'Case');
        qLst.add(q4);
        QueuesObject q5 = new QueueSObject(QueueID = gLst[4].id, SobjectType = 'Engagement_Request__c');
        qLst.add(q5);
        QueuesObject q6 = new QueueSObject(QueueID = gLst[5].id, SobjectType = 'Case');
        qLst.add(q6);
        QueuesObject q7 = new QueueSObject(QueueID = gLst[6].id, SobjectType = 'Engagement_Request__c');
        qLst.add(q7);
        System.runas(getadminUserID) 
        {
            insert qLst;
        }
        
        // Insert Group Member
        List<GroupMember> gmLst = new List<GroupMember>();
        GroupMember gm;
        
        for(Group eachGrp : gLst){
            
            gm = new GroupMember(GroupId=eachGrp.id, UserOrGroupId = getUserID); 
            gmLst.add(gm);
        }
        
        System.runas(getadminUserID) 
        {
            insert gmLst;
        }
        
        //Getting Case Queue Id
        queueid = gmLst[2].GroupId;
        
        //Getting ESC Queue Id'
        escqueueid = gmLst[4].GroupId;
        
        // Creating Account
        Account accRec = new Account(Name='Test Account IP Address',AKAM_Account_ID__c='Test-ABC-1234IPAddr',Type='Brand - Active',Support_Delivery_Type__c='Global');
        insert accRec;  
        
        //Creating Account Team member for TSE Details
        List<AccountTeamMember> accTeamInsert = new List<AccountTeamMember>();
        List<AccountShare> sharingRules = new list<AccountShare>();
        accTeamInsert.add(new AccountTeamMember(AccountId = accRec.Id, UserId = getUserID,TeamMemberRole='Technical Support - Primary'));
        sharingRules.add(new AccountShare(AccountAccessLevel = 'Edit', OpportunityAccessLevel = 'Edit', CaseAccessLevel = 'Edit',
                                          UserOrGroupId = getUserID, AccountId = accRec.Id));
        
        insert accTeamInsert;
        insert sharingRules;
        
        //Creating Case Product
        EB_AccountProductMap__c eb_product = new EB_AccountProductMap__c();
        eb_product.Name='Test Product';
        eb_product.EB_MarkedForDeletion__c = false;
        eb_product.EB_Product__c='Test-456';
        eb_product.EB_Account__c=accRec.id;
        insert eb_product;
        
        Entitlement entl = new entitlement(name='Test Entilement',accountid = accRec.id,type ='Phone Support', StartDate=Date.valueof(System.now().addDays(-2)), EndDate=Date.valueof(System.now().addYears(2)));
        insert entl;
        
        List<SlaProcess> lstEntitlementProcess = [SELECT Id, Name FROM SlaProcess WHERE Name='Technical' and IsActive = true LIMIT 1];
        if (lstEntitlementProcess.size()>0)
        {
            entl.SlaProcessId = lstEntitlementProcess[0].id;
            update entl;        
        }
        
        List<Case> newCaseInsertList = new List<Case>();
        // Creating Case with User Owner
        Case newCase = new Case();
        newCase.Subject = 'TestCase';
        newCase.Description = 'TestDescription';
        newCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        newCase.validation_override__c = true;
        newCase.AccountId = accRec.Id;
        newCase.Status = 'Assigned';        
        newCase.origin='Email';
        newCase.Severity__c='1';
        newCase.recent_update__c=true;
        newcase.ownerid=userinfo.getUserId();
        newcase.Case_Assignment_Using_Active_Rules__c =false;
        newcase.EntitlementId = entl.Id;
        newCaseInsertList.add(newCase);  
        
        //Creating case with technical queue owner
        Case newCasetech = new Case();
        newCasetech.Subject = 'TestCasetechnical';
        newCasetech.Description = 'TestDescription';
        newCasetech.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        newCasetech.validation_override__c = true;
        newCasetech.AccountId = accRec.Id;
        newCasetech.origin='Email';
        newCasetech.EntitlementId = entl.Id;
        newCasetech.recent_update__c=true;
        newCasetech.Case_Assignment_Using_Active_Rules__c =false;
        newCasetech.Severity__c='1';
        newCasetech.Case_Product__c =eb_product.id;
        newCasetech.has_active_transition__c=true;
        newCasetech.ownerid=queueid;
        newCaseInsertList.add(newCasetech);  
        
        Insert newCaseInsertList;
        
        //Creating CCare Escalation
        Engagement_Request__c newEscalation = new Engagement_Request__c();
        newEscalation.Subject__c = 'testescalation';
        newEscalation.Area__c = 'API';
        newEscalation.RecordTypeId = Schema.SObjectType.Engagement_Request__c.getRecordTypeInfosByName().get('CCare Technical Escalation').getRecordTypeId();
        newEscalation.Description__c = 'test';
        newEscalation.case__c = newCaseInsertList[0].Id;
        newEscalation.ownerid=escqueueid;
        newEscalation.Accept_Target_Date__c=Date.Today().addDays(5);
        insert newEscalation;
        
        //Creating Escalation with User Owner
        Engagement_Request__c newUserEscalation = new Engagement_Request__c();
        newUserEscalation.Subject__c = 'testescalationuser';
        newUserEscalation.Area__c = 'API';
        newUserEscalation.RecordTypeId = Schema.SObjectType.Engagement_Request__c.getRecordTypeInfosByName().get('CCare Technical Escalation').getRecordTypeId();
        newUserEscalation.Description__c = 'test';
        newUserEscalation.case__c = newCaseInsertList[0].Id;
        newUserEscalation.ownerid=getUserID;
        newUserEscalation.Accept_Target_Date__c=Date.Today().addDays(5);
        insert newUserEscalation; 
        
        //Creating case transition
        Case_Transition__c newtransition = new Case_Transition__c(case__c =newCaseInsertList[1].id, Target_Shift__c='APAC');
        insert newtransition;
        
        //Creating Live Chat visitor
        LiveChatVisitor vistor = new LiveChatVisitor();
        insert vistor;
        
        //Creating Akachat transcript
        livechattranscript transcript = new livechattranscript(LiveChatVisitorID = vistor.Id,Body = 'hello',
                                                               caseid=newCaseInsertList[0].Id);
        insert transcript;       
        
        
    }
    
    @isTest
    static void Test_Lightning()
    {   
        List<case> CaseDet = new List<case>();
        
        CaseDet = [Select Id,ownerid,owner.name from Case where Subject='TestCase' LIMIT 1];
        string getCaseID=CaseDet[0].Id;
        string getOwnerId=CaseDet[0].ownerid;
        string ownername=CaseDet[0].owner.name;
        string gettechCaseID=[Select Id from case where Subject='TestCasetechnical' LIMIT 1][0].Id;
        string getOwnerIdtech= [Select ownerid from Case where Subject='TestCasetechnical' LIMIT 1][0].ownerId;
        User userRec = [select id from user where id=: getOwnerId limit 1];
        string getEscID=[select id from Engagement_Request__c limit 1][0].Id;
        string akachatid=[select id from livechattranscript limit 1][0].Id;
        string scQmNoGeoId=[select User_Id__c from sc_qm_user_filter__c where User_Id__c='NoGeo' Limit 1][0].User_Id__c;
        string getEscOwnerId = [select ownerid from Engagement_Request__c where Subject__c = 'testescalationuser'][0].ownerid;
        
        List<String> geos = new List<String>{'NORTHAM','LATAM','APJ','EMEA'};
            List<String> twoGeos = new List<String>{'APJ','EMEA'};
                List<String> oneGeo = new List<String>{'APJ'};
                    
                    List<String> sev = new List<String>{'1','2','3'};
                        
                        Test.startTest(); 
        // Calling all the Methods for Code Coverage
        
        string getReturn=SC_Akatec_Lightning_Homepage.getSessionId();
        getReturn=SC_Akatec_Lightning_Homepage.getTargetShift(gettechCaseID);
        //Covering Cases subscribed by the user
        
        system.runAs(userRec){
            List<SC_Akatec_Lightning_Homepage.sub_Case_Wrapper> rt=SC_Akatec_Lightning_Homepage.getCases('true',getOwnerId,geos,'All Queues');
            List<SC_Akatec_Lightning_Homepage.sub_Case_Wrapper> rt1=SC_Akatec_Lightning_Homepage.getCases('true',getOwnerId,geos,'My Queues');
            List<SC_Akatec_Lightning_Homepage.sub_Case_Wrapper> rt2=SC_Akatec_Lightning_Homepage.getCases('true',getOwnerId,twoGeos,'All Queues');
            List<SC_Akatec_Lightning_Homepage.sub_Case_Wrapper> rt3=SC_Akatec_Lightning_Homepage.getCases('true',getOwnerId,oneGeo,'All Queues');
            
        }
        
        getReturn=SC_Akatec_Lightning_Homepage.assignCaseToUser(getCaseID,gettechCaseID);
        
        //Covering Escalations owned by a user
        List<SC_Akatec_Lightning_Homepage.sub_Esc_Wrapper> rtype=SC_Akatec_Lightning_Homepage.getMyOpenEscalations(getOwnerId);
        
        //Covering Escalations owned by a user 
        List<SC_Akatec_Lightning_Homepage.sub_Esc_Wrapper> rtype1=SC_Akatec_Lightning_Homepage.getMyOpenEscalations(getEscOwnerId);
        
        //Covering escalations subscribed by a user
        system.runAs(userRec){
            List<SC_Akatec_Lightning_Homepage.sub_Esc_Wrapper> escalationret=SC_Akatec_Lightning_Homepage.getMyEscalations('My Queues');
            List<SC_Akatec_Lightning_Homepage.sub_Esc_Wrapper> escalationret1=SC_Akatec_Lightning_Homepage.getMyEscalations('All Queues');
            
        }
        
        List<SC_Akatec_Lightning_Homepage.sub_Case_Wrapper> return1=SC_Akatec_Lightning_Homepage.getMyopenCases(getOwnerId,'MyOpenCases');
        List<SC_Akatec_Lightning_Homepage.sub_Case_Wrapper> return2=SC_Akatec_Lightning_Homepage.getMyopenCases(getOwnerId,'MyTeamCases');
        
        list <livechattranscript> retakachat=SC_Akatec_Lightning_Homepage.getAkaChatTranscript(akachatid);
        getReturn=SC_Akatec_Lightning_Homepage.assignEscalationToUser(getOwnerId,getEscID);
        getReturn=SC_Akatec_Lightning_Homepage.suppressCaseUpdate(gettechCaseID);
        
        //Covering Saved Geographies for All geos
        List<string> savedGeoAll= SC_Akatec_Lightning_Homepage.getSavedGeo(getOwnerIdtech);
        
        //Covering Saved Geographies for empty geo
        List<string> savedGeoNone= SC_Akatec_Lightning_Homepage.getSavedGeo(scQmNoGeoId);
        
        
        
        //Covering Dynamic Queries of Escalation Filters
        List<SC_Akatec_Lightning_Homepage.sub_Esc_Wrapper> filterrettype= SC_Akatec_Lightning_Homepage.getMyFilteredEscalations(getOwnerId,sev,'All');
        filterrettype= SC_Akatec_Lightning_Homepage.getMyFilteredEscalations(getOwnerId,sev,'Pending');
        sev.clear(); sev.add('1');
        sev.add('2');
        filterrettype= SC_Akatec_Lightning_Homepage.getMyFilteredEscalations(getOwnerId,sev,'Pending');
        filterrettype= SC_Akatec_Lightning_Homepage.getMyFilteredEscalations(getOwnerId,sev,'All');
        
        Map<string,Integer> CaseDirectReportee_CountMap = new Map<string,Integer>();
        
        system.runAs(userRec){
            CaseDirectReportee_CountMap=SC_Akatec_Lightning_Homepage.getDirectReporteeCount();
        }
        
        string userid=SC_Akatec_Lightning_Homepage.getprofileId();
        Test.stopTest(); 
        
    }
    
    @isTest
    static void testAkatecLightningHomev2Cases()
    {  
        List<case> CaseDet = new List<case>();
        
        string getCaseID = [Select Id from Case where Subject='TestCase' LIMIT 1].id;
        string akachatid=[select id from livechattranscript limit 1][0].Id;
        string gettechCaseID=[Select Id from case where Subject='TestCasetechnical' LIMIT 1][0].Id;
        user getManagerUserID = [select id from user where isactive=true and profile.name ='Support - Tech Support Manager' limit 1];

        Test.startTest(); 
        
        List<String> geos = new List<String>{'NORTHAM','LATAM','APJ','EMEA'};
        list<string> sev = new list<string>{'1','2'};
        list<string> suppDelType = new list<string>{'Geo','Global'};
        list<string> worktype = new list<string>{'Reactive', 'Proactive'};
        list<string> status = new list<string>{'Assigned', 'Work in Progress', 'Mitigated / Solution Provided'};
        list<string> akatecQueues = new list<string>();
        list<case> caselst = [select id,ownerid from case where subject='TestCasetechnical'];

        for(QueueSobject q :[Select QueueId,Queue.Name from QueueSobject where SobjectType = 'Case' and (Queue.DeveloperName like 'ATS_%') limit 5])
        {
            akatecQueues.add(q.id);
        }
        akatecQueues.add(caselst[0].ownerid);        
        SC_Akatec_Lightning_Homepage_v2.getAkaChatID(caselst);
        SC_Akatec_Lightning_Homepage_v2.getSavedGeo();
        SC_Akatec_Lightning_Homepage_v2.getMyOpenCasesOnloadvalues();   
        SC_Akatec_Lightning_Homepage_v2.saveSelectedFilters(geos,akatecQueues,sev,suppDelType); 
        SC_Akatec_Lightning_Homepage_v2.getSavedGeo();
        SC_Akatec_Lightning_Homepage_v2.getAkaChatTranscript(akachatid);
        SC_Akatec_Lightning_Homepage_v2.getMyopenCases('MyOpenCases',worktype,sev,status);
        system.runAs(getManagerUserID)
        {
        SC_Akatec_Lightning_Homepage_v2.getDirectReporteeCount();
        SC_Akatec_Lightning_Homepage_v2.getMyopenCases('MyTeamCases',worktype,sev,status);
        }
        SC_Akatec_Lightning_Homepage_v2.assignCaseToUser(getCaseID,gettechCaseID);
        SC_Akatec_Lightning_Homepage_v2.getCases();
        SC_Akatec_Lightning_Homepage_v2.getAccountTeamDetails(getCaseID);
        SC_Akatec_Lightning_Homepage_v2.suppressCaseUpdate(getCaseID);
        SC_Akatec_Lightning_Homepage_v2.changeHomeView('Show Cases on Home');
        SC_Akatec_Lightning_Homepage_v2.getUserSummaryDashboardDetails();
        Test.stopTest(); 
    }
    
    
    @isTest
    static void testAkatecLightningHomev2Escalations()
    {
        Test.startTest(); 
        
        List<String> geos = new List<String>{'NORTHAM','LATAM','APJ','EMEA'};
        list<string> sev = new list<string>{'1', '2'};
        list<string> status = new list<string>{'Accepted','Pending'};
        string getCaseID = [Select Id from Case where Subject='TestCase' LIMIT 1].id;
        string getEscID=[select id from Engagement_Request__c limit 1][0].Id;

        list<string> escQueues = new list<string>();
        for(QueueSobject q :[Select QueueId,Queue.Name from QueueSobject where SobjectType = 'Engagement_Request__c' and (Queue.DeveloperName like 'ATS_%') limit 5])
        {
            escQueues.add(q.id);
        }
        
        SC_Akatec_Lightning_Homepage_v2.createTaskLOE(getCaseID,'Call','Test',5.0,'Internal Only');
        SC_Akatec_Lightning_Homepage_v2.getSavedQueues();
        SC_Akatec_Lightning_Homepage_v2.saveEscFilters(escQueues);
        SC_Akatec_Lightning_Homepage_v2.getSavedQueues();
        SC_Akatec_Lightning_Homepage_v2.getAllEscalations();
        SC_Akatec_Lightning_Homepage_v2.getMyFilteredEscalations(sev,geos,status);
        SC_Akatec_Lightning_Homepage_v2.getAllServiceIncidents();
        SC_Akatec_Lightning_Homepage_v2.assignEscalationToUser(getEscID);
        Test.stopTest();    
    }   
}