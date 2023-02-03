/*
************************************************************************************************************
    Authors             :   Vandhana Krishnamurthy / Sumukh SS
    Created             :   21 October 2020
    Purpose             :   Test Class for SC_UCD_HomePage 
    JIRA Story          :   ESESP-3829 : Unified Case Dashboard

************************************************************************************************************
*/

@isTest
public class SC_UCD_HomePage_Test 
{
    /* CLASS VARIABLES */
    
    static
    {
        createTestData();
    }
    
    public static Case psCase;
    
    public static PSA_TestUtility testUtil;
    public static pse__Region__c reg;
    public static Account acct;
    public static Contact resource;
    
    public static pse__Project_Methodology__c  product1;
    public static pse__Proj__c proj1;
    public static pse__Practice__c pract;
    
    public static pse__Grp__c grp;
    
    public static Id practId;
    public static pse__Milestone__c milestone;
    public static pse__Assignment__c assign;
    public static User usr;
    public static Merge_Contract_Header__c contract;
    public static Merge_Contract_Detail__c contDetailCommitted;
    public static Merge_Contract_Detail__c contDetailOverage;
    public static Project_Contract__c projCont;
    public static Project_Contract_Line_Item__c projContItem;
    public static pse__Schedule__c sched;
    public static pse__Permission_Control__c pc;
    public static SC_SupportEmail__c scEmailSetup;
    
    /* TEST DATA SETUP */
    
    public static void createTestData()
    {
        utilTestClass.createCustomSettings();
        utilTestClass.SC_Autogen_init_Method();
        
        testUtil = new PSA_TestUtility();
        //setup this as it is needed during this transaction
        scEmailSetup = testUtil.newSCEmailSetup(true);
        reg = testUtil.newRegionMaster(true);
        
        acct = utilTestClass.CreateAccount('Test Account2');
        acct.Area__c = 'Carrier EMEA Resellers';
        insert acct;
        
        pract = testUtil.newPracticeMaster(true);
        practId = pract.ID;
        
        usr = [Select Id FROM User WHERE Profile.Name = 'GSS Professional Services' AND IsActive = TRUE and ManagerId != null LIMIT 1];
        
        List<sObject> lstObj = new List<sObject>();
        resource = testUtil.newResource(false, acct.Id, usr.Id);
        resource.email = 'PSAProjMgr2@akamai.com';
        lstObj.add(resource);
        insert lstObj;

        proj1 = testUtil.newProject(false,reg.id,practId,true,'One-Time: Fixed Price', resource.Id, acct.Id);
        proj1.pse__Allow_Timecards_Without_Assignment__c = false;
        proj1.pse__Allow_Self_Staffing__c =  true;
        insert proj1;
        milestone = testUtil.newMilestone(false,proj1.Id,100,date.newInstance(2015, 08, 21));            
        milestone.Billable__c = true;
        insert milestone;

        //projCont = testUtil.newProjectContract(true, proj1.Id, contract.Id, acct.Id);
        //projContItem = testUtil.newProjectContractLineItem(true, proj1.Id, contract.Id, contDetailCommitted.Id, projCont.Id);
        sched = testUtil.newSchedule(true, System.today().addDays(-10), System.today().addDays(50));
        product1 = testUtil.newProjectProduct(true,proj1.Id,'Test Proj Prod');
        pc = testUtil.newPermissionControl(true, usr.Id, reg.Id); 
       
        List<Case> newCaseInsertList = new List<Case>();
        Case newCase = new Case();
        
        for(Integer i=0; i<3; i++)
        {
            newCase = new Case();
            newCase.Subject = 'New UCD Case ' + i;
            newCase.Description = 'New UCD Description ' + i;
            newCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
            newCase.Validation_Override__c = true;
            newCase.AccountId = acct.Id;
            newCase.OwnerId = usr.Id;
            newCase.origin='Akamai';
            newCase.Severity__c='1';
            newcase.Status = 'Unassigned';
            newcase.Close_Code__c = 'Complete';
            newcase.Next_Planned_Activity_Date__c = System.today().addDays(1);
            newcase.Living_Summary_Next_Steps__c = '* 2 Nov :Customer Call | Time Spent: 1.00 | LOE Needed: 10.00 | Next Activity: 3 Nov | Vandhana Krishnamurthy \n* 2 Nov : Customer Call | Time Spent: 1.00 | LOE Needed: 10.00 | Next Activity: 30 Nov | Vandhana Krishnamurthy';
            
            if(Math.mod(i,3) == 0)
            {
                newcase.Service__c = 'Other (Security)';
                newcase.Request_Type__c = 'Other';
                newcase.Severity__c = '1';
                newcase.LOE_Hours__c = 4;
                newcase.Billable_Hours__c = 5;
            }
            else if(Math.mod(i,3) == 1)
            {
                newcase.Service__c = 'Other (Security)';
                newcase.Request_Type__c = 'Scheduled Deployment';
                newcase.Severity__c = '2';
                newcase.Requested_Completion_Date_UTC__c = System.today().addDays(1);
                newcase.Requested_Completion_Time_UTC__c = '00:00';
                newcase.LOE_Hours__c = 14;
                newcase.Non_Billable_Hours__c = 5;
            }
            else
            {
                newcase.Service__c = 'Emergency Integration';
                newcase.Request_Type__c = 'Scheduled Deployment';
                newcase.Requested_Completion_Date_UTC__c = System.today().addDays(2);
                newcase.Requested_Completion_Time_UTC__c = '00:00';
                newcase.Severity__c = '4';
                newcase.LOE_Hours__c = 14;
                newcase.Internal_Hours__c = 5;
            }
            newCaseInsertList.add(newCase); 
        }
        
        insert newCaseInsertList;   
    }
    
    public static testMethod void testUCDGetMyCases()
    {
        Map<String,String> filter = new Map<String,String>();
        List<SC_UCD_HomePage.CaseWrapper> caseWrapperList = new List<SC_UCD_HomePage.CaseWrapper>();
        proj1 = [SELECT Id,
                 (SELECT Id FROM pse__Milestones__r LIMIT 1),
                 (SELECT Id FROM pse__Project_Methodologies__r LIMIT 1)
                 FROM pse__Proj__c LIMIT 1];
            
        pse__Milestone__c milestone = !proj1.pse__Milestones__r.isEmpty() ? proj1.pse__Milestones__r[0] : null;
        pse__Project_Methodology__c prod = !proj1.pse__Project_Methodologies__r.isEmpty() ? proj1.pse__Project_Methodologies__r[0] : null;
        pse__Timecard_Header__c timecard1 = new pse__Timecard_Header__c();
        
        filter.put('sevValue','1,2,4');
        filter.put('utilizedHoursValue','red,yellow');
        
        Test.startTest();
        
        psCase = [SELECT Id,AKAM_Case_ID__c FROM Case WHERE RecordType.Name = 'Professional Services' LIMIT 1];

        System.runAs(usr)
        {
            assign = testUtil.newAssignment(false,proj1.Id,resource.Id,sched.Id);
            assign.pse__Bill_Rate__c = 0;
            insert assign;
            
            timecard1 = testUtil.newTimecardHeader(false, resource.Id, proj1.Id, assign.Id, milestone.Id, System.today(), System.today().addDays(6));           
            timecard1.Case__c = psCase.Id;
            timecard1.pse__Billable__c = true;
            timecard1.pse__Project_Methodology_Object__c = prod.Id;
            timecard1.pse__Status__c = 'Saved'; 
            timecard1.pse__Monday_Hours__c = 20;
            timecard1.pse__Tuesday_Hours__c = 20;
            insert timecard1; 
            
            caseWrapperList = SC_UCD_HomePage.getMyCases('myopen',filter,'tsc');
            Test.stopTest();
            caseWrapperList = SC_UCD_HomePage.getMyCases('myteam',filter,'gs2');
            String returnVal = SC_UCD_HomePage.updateCaseLivingSummaryAndTimecard('testLivingSummary', psCase.Id,psCase.AKAM_Case_ID__c,false,
                                                                                  proj1.Id, milestone.Id, prod.Id,'daily notes',5,System.today().addDays(1),5);
            // EXCEPTION HANDLING
            String str = 'testing123testing123testing123testing123';
            for(Integer i=0;i<7;i++)
            {
                str+= str;
            }
            try
            {
                returnVal = SC_UCD_HomePage.updateCaseLivingSummaryAndTimecard('testLivingSummary', psCase.Id,psCase.AKAM_Case_ID__c,false,
                                                                                  proj1.Id, milestone.Id, prod.Id,str,5,System.today().addDays(1),5);
            }
            catch(Exception e){}
        }
        
    }
    
    public static testMethod void testUCDGetMyCasesNewTC()
    {
        proj1 = [SELECT Id,
                 (SELECT Id FROM pse__Milestones__r LIMIT 1),
                 (SELECT Id FROM pse__Project_Methodologies__r LIMIT 1)
                 FROM pse__Proj__c LIMIT 1];
            
        pse__Milestone__c milestone = !proj1.pse__Milestones__r.isEmpty() ? proj1.pse__Milestones__r[0] : null;
        pse__Project_Methodology__c prod = !proj1.pse__Project_Methodologies__r.isEmpty() ? proj1.pse__Project_Methodologies__r[0] : null;
        
        Test.startTest();
        
        psCase = [SELECT Id,AKAM_Case_ID__c FROM Case WHERE RecordType.Name = 'Professional Services' LIMIT 1];

        System.runAs(usr)
        {
            String returnVal = SC_UCD_HomePage.updateCaseLivingSummaryAndTimecard('testLivingSummary', psCase.Id,psCase.AKAM_Case_ID__c,false,
                                                                                  proj1.Id, milestone.Id, prod.Id,'daily notes',5,System.today().addDays(1),5);
        }
        Test.stopTest();
    }
    
    public static testMethod void testFetchProjMilestoneProd()
    {
        Test.startTest();
        proj1 = [SELECT Id FROM pse__Proj__c LIMIT 1];
        Map<String,List<SC_UCD_HomePage.SelectOption>> mapResult = SC_UCD_HomePage.fetchProjectMilestonesAndProducts(proj1.Id);
        SC_UCD_HomePage.fetchAccountActiveProjects(acct.Id);
        Test.stopTest();
    }
    
    public static testMethod void testLOEMethods()
    {
        Test.startTest();
        psCase = [SELECT Id,AKAM_Case_ID__c FROM Case WHERE RecordType.Name = 'Professional Services' LIMIT 1];
        String result = SC_UCD_HomePage.fetchCaseLivingSummary(psCase.Id);
        SC_UCD_HomePage.updateCaseLOE(psCase.Id,50,'Wrong Product');
        Test.stopTest();
    }
    
    public static testMethod void testCloneMethods()
    {
        Test.startTest();
        psCase = [SELECT Id,AKAM_Case_ID__c FROM Case WHERE RecordType.Name = 'Professional Services' LIMIT 1];
        SC_UCD_HomePage.accountOption(acct.Id);
        String result = SC_UCD_HomePage.cloneSingleCase(psCase.Id);
        SC_UCD_HomePage.fetchSavedAccountForMultiClone();
        SC_UCD_HomePage.cloneMultiCase(psCase.Id, new List<String>{acct.Id});
        Test.stopTest();
    }
    
    public static testMethod void testAckCase()
    {
        Test.startTest();
        psCase = [SELECT Id,AKAM_Case_ID__c FROM Case WHERE RecordType.Name = 'Professional Services' LIMIT 1];
        SC_UCD_HomePage.acknowledgeCase(psCase.Id);
        Test.stopTest();
    }
    
    public static testMethod void testSearchLoadWrap()
    {
        Test.startTest();
        List<Case> psCaseList = [SELECT Id,AKAM_Case_ID__c FROM Case WHERE RecordType.Name = 'Professional Services' LIMIT 3];
        SC_UCD_HomePage.globalSearchAndRecentlyViewed(psCaseList[0].AKAM_Case_ID__c, true);
        SC_UCD_HomePage.globalSearchAndRecentlyViewed(psCaseList[1].AKAM_Case_ID__c + ',' + psCaseList[2].AKAM_Case_ID__c , true);
        SC_UCD_HomePage.myCasesOnLoadWrap();
        Test.stopTest();
    }
    
    public static testMethod void testBulkClose()
    {
        Map<String,Map<String,String>> mapCasesToClose = new Map<String,Map<String,String>>();
        Map<String,String> mapCaseFields = new Map<String,String>();
        mapCaseFields.put('closeCode','Complete');
        mapCaseFields.put('solutionSummary','Testing');
        
        Test.startTest();
        List<Case> psCaseList = [SELECT Id,AKAM_Case_ID__c FROM Case WHERE RecordType.Name = 'Professional Services' LIMIT 1];
        mapCasesToClose.put(psCaseList[0].Id,mapCaseFields);
        SC_UCD_HomePage.bulkCloseCases(mapCasesToClose);
        SC_UCD_HomePage.getPSCaseRecTypeId();
        Test.stopTest();
    }
    
    public static testMethod void testCasesinQueue()
    {
        Test.startTest();
        SC_UCD_HomePage.getSavedDashboardView();
        SC_UCD_HomePage.saveUserUCDView('GS2');
        SC_UCD_HomePage.getOnLoadValues();
        /*QueueSobject q = [Select QueueId,Queue.Name from QueueSobject where SobjectType = 'Case' and Queue.DeveloperName like 'PS_%' ORDER BY QueueId LIMIT 1];
        
        sc_user_filter__c u = [select id,filter_values__c from sc_user_filter__c LIMIT 1];
        System.debug(u.filter_values__c);
        List<Case> lstCase = new List<Case>();
        
        for(Case c : [SELECT Owner.Name FROM Case])
        {
            c.OwnerId = q.QueueId;
            lstCase.add(c);
        }
        update lstCase;*/
        
        List<string> psQueues = new list<string>();
        List<string> sev = new list<string>{'1', '2'};
       	List<string> status = new list<string>{'Pending', 'Assigned','Unassigned'};
        List<string> dgrat = new list<string>{'Carrier EMEA Resellers', 'Carrier Japan'};
        for(QueueSobject q1 : [Select QueueId,Queue.Name from QueueSobject where SobjectType = 'Case' and Queue.DeveloperName like 'PS_%' ORDER BY QueueId LIMIT 5])
        {
            psQueues.add(q1.id);
        }
        list<case> caselst = [SELECT Id,ownerid FROM Case WHERE RecordType.Name = 'Professional Services' LIMIT 1];
    	psQueues.add(caselst[0].ownerid);
        
        SC_UCD_HomePage.generateDynamicQuery(psQueues,sev,status,dgrat);
        dgrat.clear();
        SC_UCD_HomePage.saveSelectedFilters(psQueues,sev,status,dgrat,'testclassfilter');
        
        SC_UCD_HomePage.getCasesinQueue();
        
        SC_UCD_HomePage.editSelectedFilter(psQueues,sev,status,dgrat,'testclassfilter');
        SC_UCD_HomePage.ApplyFilterMapping(psQueues,sev,status,dgrat,'testclassfilter');
        SC_UCD_HomePage.DeleteFilterMapping('testclassfilter');
        
        SC_UCD_HomePage.findLookupRecords('PS','Select QueueId,Queue.Name from QueueSobject where SobjectType = \'Case\' and Queue.DeveloperName like ');
        string psCase = [SELECT Id FROM Case LIMIT 1].id;

        SC_UCD_HomePage.assignPendingReasonToCase(true,'Awaiting IAT response',psCase,'test');
        list<string> lstcases = new list<string>{psCase};
        SC_UCD_HomePage.changeCaseOwnerQueue(lstcases,null);
        Test.stopTest();
    }
}