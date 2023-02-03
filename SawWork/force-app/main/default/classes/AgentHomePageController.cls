/*****************************************************************************
* Name             : AgentHomePageController
* Created By       : Pitamber Sharma
* Created Date     : 06-June-2013
* Purpose          : Controller class for Agent Home Page


Last Modified     : 17-Feb-2014 by Vijetha Vijayendran
Purpose      : Added limits to the Collection
DATE             DEVELOPER     CR              DESCRIPTION                               
===========      =========     =======         =========== 
17-Feb-2014        Vijetha                     Added limits to the Collection.
12-May-2014      Himanshu Kar      2578737(3.42)   Added Condition to exclude Close Case in Case Query
22-May-2015		Jay				2950085(4.8)	when users have single quotes in view, links were not clickable
04-Nov-2016		Aditya			3394061    		AMG Home Screen Redesign
07-Nov-2016        Vandhana        3568251      	AMG Homescreen for My LOE
21-June-2018		Vandhana		ESESP-734		Setting up a backup while going Unavailable
26-Oct-2018		Aditya		ESESP-1077		Modifyied AMG SLA alert button and SLA Column logic
27-Feb-2019		Aditya		ESESP-1935      Break/Fix on ESESP-1862: Added more filter for managers view
02-Jul-2019     Vishnu      ESESP-758       Updated milestone sub query of case query, to include AMG Post Initial Response Milestones
23-Sept-2019    Vishnu      ESESP-2636      Fix for miscalculation in SLA Indicator and SLA Alert widget
*****************************************************************************/

public with sharing class AgentHomePageController {
    public List<Case> lstCases{get;set;}
    public List<Task> lstTasks{get;set;}
    public Map<String, List<String>> queuesMap{get;set;}
    public List<BMCServiceDesk__Incident__c> lstIncidents{get;set;}
    
    public String caseFilter {get;set;}
    public List<Selectoption> caseFilterOptions {get;set;}
    
    public String taskFilter {get;set;}
    public List<Selectoption> taskFilterOptions {get;set;}
    
    public String incidentFilter {get;set;}
    public List<Selectoption> incidentFilterOptions {get;set;}
    
    public Map<String, String> caseListViewMap{get;set;}
    public Map<String, String> erListViewMap{get;set;}
    public Map<String, String> incidentsListViewMap{get;set;}
    
    public Boolean isAvailable{get;set;}
    public Boolean showAvailability{get;set;}
    public Boolean isAMGOrBilling{get;set;}
    public string slaAlertButtonColors{get;set;}
    public string ageingCaseButtonColors{get;set;}
    public integer totalAgeingCase{get;set;}
    public integer totalExternalCases{get;set;}
    public integer totalOnboardingCases{get;set;}
    public List<Case> lstLOECases{get;set;}
    public Decimal totalLOE{get;set;}
    public Map<Id,decimal> missingSlaInDaysMap{get;set;}
    public decimal missingSlaInDays{get;set;}
    public Map<id,Case> caseIdRecordMap{get;set;}
    public List<Case> listAgeingCases{get;set;}
    public Map<Id,String> caseIdButtonFlagMap{get;set;}
    private static boolean hasTaskLoeCalculated = false;
    
    
    public User currentUser{get;set;}
    public static Integer cLimit;
    public string loggedInManagerId = '';
    public list<User> userWithManagerList = new List<User>();
    public String viewName= '';
    public boolean isTestRunning = false;
    public AgentHomePageController() {
        showAvailability = false;
        isAMGOrBilling = false;
        populateLists();
        calculateLOE();
        //viewName = ApexPages.currentPage().getParameters().get('view');
        //system.debug('----viewName---'+viewName);
    }
    
    //Populates all the Lists
    public void populateLists() {
        caseFilterOptions = new List<Selectoption>();
        caseFilterOptions.add(new SelectOption('My Open Cases', 'My Open Cases'));
        caseFilterOptions.add(new SelectOption('Closed Cases', 'Closed Cases'));
        caseFilterOptions.add(new SelectOption('Resolved Cases', 'Resolved Cases'));
        caseFilterOptions.add(new SelectOption('All My Cases', 'All My Cases'));
        caseFilterOptions.add(new SelectOption('My Owned Cases', 'My Owned Cases'));
        caseFilterOptions.add(new SelectOption('My Team Cases', 'My Team Cases'));
        caseFilterOptions.add(new SelectOption('My Closed Cases', 'My Closed Cases'));
        caseFilterOptions.add(new SelectOption('My Resolved Cases', 'My Resolved Cases'));
        caseFilterOptions.add(new SelectOption('Order Form Review', 'Order Form Review'));
        caseFilterOptions.add(new SelectOption('My Manager Open Cases', 'My Manager\'s Open Cases with SLA Running'));
        
        taskFilterOptions = new List<Selectoption>();
        taskFilterOptions.add(new SelectOption('My Tasks Due Today', 'My Tasks Due Today'));
        taskFilterOptions.add(new SelectOption('My Activities', 'My Activities'));
        taskFilterOptions.add(new SelectOption('My Open Activities', 'My Open Activities'));
        taskFilterOptions.add(new SelectOption('My Team\'s Open Activities', 'My Team\'s Open Activities'));
        taskFilterOptions.add(new SelectOption('Overdue Tasks', 'Overdue Tasks'));
        
        incidentFilterOptions = new List<Selectoption>();
        incidentFilterOptions.add(new SelectOption('Last 24 Hours', 'Last 24 Hours'));
        incidentFilterOptions.add(new SelectOption('All Open Incidents', 'All Open Incidents'));
        
        caseFilter ='My Open Cases';
        incidentFilter = 'Last 24 Hours';
        taskFilter = 'My Open Activities';
        
        currentUser = [Select Id,Availability__c,Profile.Name,Backup_User__c,Backup_User__r.Profile.Name, ManagerId
                       FROM User 
                       WHERE Id =: Userinfo.getUserId()];
        
        isAvailable = currentUser.Availability__c;
        loggedInManagerId = currentUser.ManagerId;
        system.debug('----loggedInManagerId----'+loggedInManagerId);
        userWithManagerList = [Select id from user where managerId =:loggedInManagerId and isActive=true];
        system.debug('----userWithManagerList----'+userWithManagerList);
        
        viewName = ApexPages.currentPage().getParameters().get('view');
        system.debug('----viewName In Populate list---'+viewName); 
        
        if(currentUser.Profile.Name != null) {
            for(Business_Support_Profiles__c bsProfile : Business_Support_Profiles__c.getAll().values()){
                if(bsProfile.Value__c == currentUser.Profile.Name){
                    showAvailability = true;
                    isAMGOrBilling = true;
                    break;
                }
            }
            if(!isAMGOrBilling){
                for(Billing_Support_Profiles__c bsProfile : Billing_Support_Profiles__c.getAll().values()){
                    if(bsProfile.Value__c == currentUser.Profile.Name){
                        isAMGOrBilling = true;
                        break;
                    }
                }
            }
        }
        
        populateCases();
        populateTasks();
        populateQueues();
        populateIncidents();
        
        
        initializeCaseListViewMap();
        initializeERListViewMap();
        initializeIncidentListViewMap();
    }
    
    private void initializeCaseListViewMap() 
    {
        caseListViewMap = new Map<String, String>();
        
        List<Case> tmpLst = [SELECT Id FROM Case LIMIT 1];
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(tmpLst);
        
        for(Selectoption so : ssc.getListViewOptions()) 
        {
            caseListViewMap.put(String.escapeSingleQuotes(so.getLabel()), String.escapeSingleQuotes(so.getValue()));   
        }
    }
    
    private void initializeERListViewMap() 
    {
        erListViewMap = new Map<String, String>();
        
        List<Engagement_Request__c> tmpLst = [SELECT Id FROM Engagement_Request__c LIMIT 1];
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(tmpLst);
        
        for(Selectoption so : ssc.getListViewOptions()) {
            erListViewMap.put(so.getLabel(), so.getValue());    
        }
    }
    
    private void initializeIncidentListViewMap() {
        incidentsListViewMap = new Map<String, String>();
        
        List<BMCServiceDesk__Incident__c> tmpLst = [SELECT Id FROM BMCServiceDesk__Incident__c LIMIT 1];
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(tmpLst);
        
        for(Selectoption so : ssc.getListViewOptions()) {
            incidentsListViewMap.put(so.getLabel(), so.getValue()); 
        }
    }
    
    //Returns the list of Cases after applying the filter in whereClause
    public List<Case> getCasesList(String whereClause) 
    {
        // ESESP-2636  - Added TimeRemaining* and TimeSince* fields of CaseMilestone
        //             - Updated where condition for AMG - pick IR milestone if AMG_Transition__c = false, and pick AMG Post Transition milestone if AMG_Transition__c = true
        return Database.query('Select Id, Owner.Name,CaseNumber, AKAM_Case_ID__c, Subject, Severity__c, AutoClose__c, Status, AMG_Transition__c, Request_Type__c, ' 
        + ' Do_Not_Show_In_Portal_Picklist__c, Recent_Update__c, Account.Name, origin, Account.Support_Level__c, AKAM_Created_Date__c, OwnerId,ClosedDate,' 
        + ' RecordType.Name, Isclosed, Age_days__c,Do_Not_Show_In_Portal__c,Autogen_UseCase__c,CreatedDate,Total_LOE_min__c,'
        + ' (Select MilestoneType.Name,StartDate,IsCompleted,IsViolated,TargetResponseInMins,TimeRemainingInMins, BusinessHoursId, TimeRemainingInDays, TimeSinceTargetInMins, TimeSinceTargetInDays From CaseMilestones '
        + ' Where (MilestoneType.Name =\'Initial Response\' AND Case.RecordType.Name != \'AMG\') '
        + ' or ( MilestoneType.Name =\'Initial Response\' AND Case.RecordType.Name = \'AMG\' AND Case.AMG_Transition__c = false )'
        + ' or ( MilestoneType.Name =\'AMG Post Transition Initial Response\' AND Case.RecordType.Name = \'AMG\' AND Case.AMG_Transition__c = true ) order by createddate asc)'
        + ' From Case'
        + whereClause + ' Limit :cLimit');  
    }
    
    //Returns the list of Tasks after applying the filter in whereClause
    public List<Task> getTasksList(String whereClause) {
        return Database.query('Select Id, Account.Name,What.Name, Type__c, Subject, Status, ActivityDate From Task' + whereClause + ' Limit :cLimit');
    }
    
    //Populates list of queues in which the current user is a member
    public void populateQueues() 
    {
        queuesMap = new Map<String, List<String>>();
        Id allInternalUsersGId = [Select Id From Group Where DeveloperName = 'AllInternalUsers'].Id;
        List<Group> queues = new List<Group>();
        for(Group g : [Select Id, Name, (Select SobjectType From QueueSobjects where SobjectType = 'case')
                       From Group where Type = 'Queue' and Id In 
                       (Select GroupId from GroupMember Where UserOrGroupId =: UserInfo.getUserId() OR UserOrGroupId =: allInternalUsersGId)]) {
                           if(g.QueueSobjects.size() > 0) {
                               queues.add(g);
                           }
                       }
        
        //Populate Map for Case Queues
        List<String> tempLst;
        for(AggregateResult ar : [Select count(Id) cnt, Owner.Name QName, severity__c severity from Case 
                                  Where OwnerId IN : queues  and (NOT Status  like 'Close%') 
                                  group by severity__c, Owner.Name]) {
                                      if(!queuesMap.containsKey(String.valueOf(ar.get('QName')))) {
                                          queuesMap.put(String.valueOf(ar.get('QName')), new String[]{'0', '0', '0', '', 'Case'});
                                      }
                                      tempLst = queuesMap.get(String.valueOf(ar.get('QName')));
                                      if(String.valueOf(ar.get('severity')) == '1') {
                                          tempLst.remove(0);
                                          tempLst.add(0, String.valueOf(ar.get('cnt')));
                                      } else if(String.valueOf(ar.get('severity')) == '2') {
                                          tempLst.remove(1);
                                          tempLst.add(1, String.valueOf(ar.get('cnt')));
                                      } else if(String.valueOf(ar.get('severity')) == '3') {
                                          tempLst.remove(2);
                                          tempLst.add(2, String.valueOf(ar.get('cnt')));
                                      }
                                      queuesMap.put(String.valueOf(ar.get('QName')), tempLst);
                                  }
        
        Map<String, List<Case>> queueCaseMap = new Map<String, List<Case>>();
        for(Case cs : [Select Id, SLA_Violation_15min__c, SLA_Violation_45min__c, SLA_Violation_4h__c, SLA_Violation_6h__c,
                       Severity__c, IR_Violavtion_12h__c, IR_Violavtion_18h__c, owner.Name 
                       From Case Where owner.Name IN : queuesMap.keySet() and (NOT Status  like 'Close%') ]) {
                           if(!queueCaseMap.containsKey(cs.Owner.Name)) {
                               queueCaseMap.put(cs.Owner.Name, new List<Case>());
                           }
                           queueCaseMap.get(cs.Owner.Name).add(cs);
                       }
        
        for(Group g : queues) {
            if(!queuesMap.containsKey(g.Name)) {
                queuesMap.put(g.Name, new String[]{'0', '0', '0', '', 'Case'});
            }
            if(!queueCaseMap.containsKey(g.Name)) {
                queueCaseMap.put(g.Name, new List<Case>());
            }
        }
        QueueColorUtility.assignColorToCaseQueue(queuesMap, queueCaseMap);
        
        //Populate Map for Engagement Request Queues
        queues = new List<Group>();
        for(Group g : [Select Id, Name, (Select SobjectType From QueueSobjects where SobjectType = 'Engagement_Request__c')
                       From Group where Type = 'Queue' and Id In 
                       (Select GroupId from GroupMember Where UserOrGroupId =: UserInfo.getUserId() OR UserOrGroupId =: allInternalUsersGId)]) {
                           if(g.QueueSobjects.size() > 0) {
                               queues.add(g);
                           }
                       }
        system.debug('-----queues-----'+queues);
        Map<String, List<String>> erQueuesCntMap = new Map<String, List<String>>();
        Integer tmpCnt;
        for(Engagement_Request__c er : [Select Id, Owner.Name, severity__c 
                                        From Engagement_Request__c  
                                        Where OwnerId IN : queues Order By Owner.Name]) {
                                            if(!erQueuesCntMap.containsKey(er.Owner.Name)) {
                                                erQueuesCntMap.put(er.Owner.Name, new String[]{'0', '0', '0', '', 'ER'});
                                            }
                                            tempLst = erQueuesCntMap.get(er.Owner.Name);
                                            if(er.severity__c != null) {
                                                if(er.severity__c.equals('1')) {
                                                    tmpCnt = Integer.valueOf(tempLst.remove(0));
                                                    tmpCnt++;
                                                    tempLst.add(0, String.valueOf(tmpCnt));
                                                } else if(er.severity__c.equals('2')) {
                                                    tmpCnt = Integer.valueOf(tempLst.remove(1));
                                                    tmpCnt++;
                                                    tempLst.add(1, String.valueOf(tmpCnt));
                                                } else if(er.severity__c.equals('3')) {
                                                    tmpCnt = Integer.valueOf(tempLst.remove(2));
                                                    tmpCnt++;
                                                    tempLst.add(2, String.valueOf(tmpCnt));
                                                }
                                            }
                                            erQueuesCntMap.put(er.Owner.Name, tempLst);
                                        }
        
        Map<String, List<Engagement_Request__c>> queueERMap = new Map<String, List<Engagement_Request__c>>();
        for(Engagement_Request__c er : [Select Id, CreatedDate, Owner.Name 
                                        From Engagement_Request__c 
                                        Where owner.Name IN : erQueuesCntMap.keySet()]) {
                                            if(!queueERMap.containsKey(er.Owner.Name)) {
                                                queueERMap.put(er.Owner.Name, new List<Engagement_Request__c>());
                                            }
                                            queueERMap.get(er.Owner.Name).add(er);
                                        }
        
        QueueColorUtility.assignColorToERQueue(erQueuesCntMap, queueERMap);
        queuesMap.putAll(erQueuesCntMap);
        for(Group g : queues) {
            if(!queuesMap.containsKey(g.Name)) {
                queuesMap.put(g.Name, new String[]{'0', '0', '0', '#B2EC5D', 'ER'});
            }
        }
    }
    
    //Populates Incidents of last 24 hours
    public void populateIncidents()
    {
        datetime dt = System.now()-1;
        Agent_Home_Collection_Limit__c cl = Agent_Home_Collection_Limit__c.getValues('Limit Value');
        cLimit = cl.Collection_Limit__c.intValue();
        RecordType rType = [SELECT Id,DeveloperName FROM RecordType Where Sobjecttype = 'BMCServiceDesk__Incident__c' and Name = 'Service Incident' Limit 1];
        
        if(incidentFilter.equals('Last 24 Hours')) {
            lstIncidents = [Select Id, BMCServiceDesk__FKUrgency__r.Name, SI_Incident_Start_Time_InternationalForm__c, BMCServiceDesk__Service_Request_Title__c, 
                            Name, BMCServiceDesk__FKStatus__r.Name 
                            From BMCServiceDesk__Incident__c Where RecordTypeId = :rType.Id and BMCServiceDesk__openDateTime__c >: dt Limit :cLimit];  
        } else {
            lstIncidents = [Select Id, SI_Incident_Start_Time_InternationalForm__c, BMCServiceDesk__FKUrgency__r.Name, BMCServiceDesk__Service_Request_Title__c, 
                            Name, BMCServiceDesk__FKStatus__r.Name 
                            From BMCServiceDesk__Incident__c Where RecordTypeId = :rType.Id and BMCServiceDesk__FKStatus__r.Name != 'CLOSED' Limit :cLimit];
        }
    }
    
    public Pagereference populateCases() 
    {
        List<Case> tempLst1;
        List<Case> tempLst2;
        viewName = ApexPages.currentPage().getParameters().get('view');
        system.debug('----View Name---'+viewName);
        if(viewName != '' && viewName != Null){
            caseFilter = viewName;
        } 
        system.debug('----caseFilter---'+caseFilter);
        
        Agent_Home_Collection_Limit__c cl = Agent_Home_Collection_Limit__c.getValues('Limit Value');
        cLimit = cl.Collection_Limit__c.intValue();
        if(caseFilter.equals('My Open Cases')) {
            lstCases = getCasesList(' Where ownerID = \'' + UserInfo.getUserId() + '\' and Isclosed = false'  ); 
        } 
        
        else if(caseFilter.equals('Closed Cases')){
            tempLst1 = [Select Id From Case Where ownerId =: UserInfo.getUserId() And Isclosed = true order by ClosedDate desc];
            tempLst2 = Database.query('Select Id From Case Where ID IN (Select ParentId From CaseTeamMember Where MemberId = \'' + UserInfo.getUserId() + '\') and Isclosed = true order by ClosedDate desc');
            if(tempLst1.size() > 0 || tempLst2.size() > 0) {
                tempLst1.addAll(tempLst2);          
                lstCases = getCasesList(' Where Id IN (' + listToStringIds(tempLst1) + ')');
            } else {
                lstCases = new List<Case>();
            }
            //lstCases = getCasesList(' Where ownerID = \'' + UserInfo.getUserId() + '\' and Isclosed = true Order by ClosedDate desc');
            //lstCases.addAll(getCasesList(' Where ID IN (Select ParentId From CaseTeamMember Where MemberId = \'' + UserInfo.getUserId() + '\') and Isclosed = true Order by ClosedDate desc'));
        } else if(caseFilter.equals('Resolved Cases')){
            tempLst1 = [Select Id From Case Where ownerId =: UserInfo.getUserId() And status = 'Mitigated / Solution Provided'];
            tempLst2 = Database.query('Select Id From Case Where ID IN (Select ParentId From CaseTeamMember Where MemberId = \'' + UserInfo.getUserId() + '\') and Status = \'Mitigated / Solution Provided\'');
            if(tempLst1.size() > 0 || tempLst2.size() > 0) {
                tempLst1.addAll(tempLst2);          
                lstCases = getCasesList(' Where Id IN (' + listToStringIds(tempLst1) + ')');
            } else {
                lstCases = new List<Case>();
            }
            //lstCases = getCasesList(' Where ownerID = \'' + UserInfo.getUserId() + '\' and Status = \'Mitigated / Solution Provided\'');
            //lstCases.addAll(getCasesList(' Where ID IN (Select ParentId From CaseTeamMember Where MemberId = \'' + UserInfo.getUserId() + '\') and Status = \'Mitigated / Solution Provided\''));
        } else if(caseFilter.equals('All My Cases')){
            tempLst1 = [Select Id From Case Where ownerId =: UserInfo.getUserId() And Isclosed = false];
            tempLst2 = Database.query('Select Id From Case Where ID IN (Select ParentId From CaseTeamMember Where MemberId = \'' + UserInfo.getUserId() + '\') and Isclosed = false');
            if(tempLst1.size() > 0 || tempLst2.size() > 0) {
                tempLst1.addAll(tempLst2);
                lstCases = getCasesList(' Where Id IN (' + listToStringIds(tempLst1) + ')');
            } else {
                lstCases = new List<Case>();
            }
            //lstCases = getCasesList(' Where ownerID = \'' + UserInfo.getUserId() + '\' and Isclosed = false');
            //lstCases.addAll(getCasesList(' Where ID IN (Select ParentId From CaseTeamMember Where MemberId = \'' + UserInfo.getUserId() + '\') and Isclosed = false'));
        } else if(caseFilter.equals('My Owned Cases')){
            lstCases = getCasesList(' Where ownerID = \'' + UserInfo.getUserId() + '\'');
        } else if(caseFilter.equals('My Team Cases')){
            lstCases = getCasesList(' Where ID IN (Select ParentId From CaseTeamMember Where MemberId = \'' + UserInfo.getUserId() + '\') and Isclosed = false');
        } else if(caseFilter.equals('My Closed Cases')){
            lstCases = getCasesList(' Where ownerID = \'' + UserInfo.getUserId() + '\' and Isclosed = true Order by ClosedDate desc');
        } else if(caseFilter.equals('My Resolved Cases')){
            lstCases = getCasesList(' Where ownerID = \'' + UserInfo.getUserId() + '\' and Status = \'Mitigated / Solution Provided\'');
        }else if(caseFilter.equals('Order Form Review')){
            lstCases = getCasesList(' Where Isclosed = false and ownerID = \'' + UserInfo.getUserId() + '\' and Request_Type__c = \'Order Form Review\'');
        }else if(caseFilter.equals('My Manager Open Cases')){
            // ESESP-2636  - Added TimeRemaining* and TimeSince* fields of CaseMilestone
            //             - Updated where condition for AMG - pick IR milestone if AMG_Transition__c = false, and pick AMG Post Transition milestone if AMG_Transition__c = true
            lstCases = [Select Id,Owner.name, CaseNumber, AKAM_Case_ID__c, Subject, Severity__c, AutoClose__c, Status,Do_Not_Show_In_Portal_Picklist__c, 
                        Recent_Update__c, Account.Name, origin, Account.Support_Level__c, AKAM_Created_Date__c,Isclosed, Age_days__c,Do_Not_Show_In_Portal__c,
                        Autogen_UseCase__c,CreatedDate,Total_LOE_min__c,Request_Type__c,OwnerId,ClosedDate, RecordType.Name, AMG_Transition__c,
                        (Select MilestoneType.Name,StartDate,IsCompleted,IsViolated,TargetResponseInMins, TimeRemainingInMins, BusinessHoursId, TimeRemainingInDays, TimeSinceTargetInMins, TimeSinceTargetInDays  From CaseMilestones 
                        Where (
                            (MilestoneType.Name ='Initial Response' AND Case.RecordType.Name != 'AMG') 
                            or ( MilestoneType.Name ='Initial Response' AND Case.RecordType.Name = 'AMG' AND Case.AMG_Transition__c = false )
                            or ( MilestoneType.Name ='AMG Post Transition Initial Response' AND Case.RecordType.Name = 'AMG' AND Case.AMG_Transition__c = true )) and IsCompleted = false and IsViolated = false order by createddate asc) 
                        From Case Where Isclosed = false and Autogen_UseCase__c != 'QBR' and RecordType.Name = 'AMG' and ownerId IN : userWithManagerList
                        and (Do_Not_Show_In_Portal__c = false or Request_Type__c = 'Customer Onboarding') limit 5000];
            system.debug('---My Manager Cases Size---'+lstCases.size());
        }
        
        //if(lstCases != Null)
        SLAAlertButtonColor(lstCases);
        calculateLOE();
        
        return null;
    }
    
    // Aditya: CR 3394061 - Salesforce: AMG dashboard redesign
    
    public void SLAAlertButtonColor(list<Case> lstCasesForButton)
    {
        
        // list<Case> lstCasesForButton
        // populateCases();
        
        totalAgeingCase = 0;
        totalOnboardingCases = 0;
        totalExternalCases = 0;
        totalLOE = 0.0;
        missingSlaInDays = 0.0;
        slaAlertButtonColors = 'Green';
        ageingCaseButtonColors = 'Green';
        
        //List of task related to case with task type = 'User Setup'
        List<Task> userSetupTaskList = [Select Id,WhatId,Completed_Date_Time__c,ActivityDate, Compliance__c  from Task where WhatId IN :lstCasesForButton and Subject = 'User Setup' and (status != 'Not Applicable' OR status != 'Postponed - Agreed with Customer')];
        List<String> userSetupNonCompliantList = new List<String>();
        List<String> userSetupCompliantList = new List<String>();
        List<String> userSetupBlankList = new List<String>();
        
        if(userSetupTaskList != Null && userSetupTaskList.size() >0){
            for(Task t :userSetupTaskList){
                if(t.Compliance__c == 'Not Met')
                    userSetupNonCompliantList.add(t.WhatId);
                else if(t.Compliance__c == 'Met')
                    userSetupCompliantList.add(t.WhatId);
                else
                    userSetupBlankList.add(t.WhatId);
            }
        }
        
        
        // userSetupNonCompliantList.remove(null);
        // userSetupCompliantList.remove(null);
        string userSetupNonCompliantString = string.join(userSetupNonCompliantList,',');
        string userSetupCompliantString = string.join(userSetupCompliantList,',');
        string userSetupBlankString = string.join(userSetupBlankList,',');
        //list of case with 7days LOE
        lstLOECases = new List<Case>();
        
        //List of Cases with age days greater than 30
        listAgeingCases = new List<Case>();
        
        //Map to store Case Id and missingSlaInDays
        missingSlaInDaysMap = new Map<id,decimal>();
        
        //Map to store Case ID and Case for SLA Alert Page
        caseIdRecordMap = new Map<id,Case>();
        
        // Store difference of currenttime minus milestone start date
        Integer milestoneDiffMinutes;
        
        //Map to store Case Id and SLA Flag color 
        caseIdButtonFlagMap = new Map<id,String>();
        
        // Stores difference of Milestone Target Time and milestoneDiffMinutes
        Integer minutesToSLA;
        
        Set<case> caseExternalListSLA = new Set<case>();

		Set<case> caseExternalRunningSLAList = new Set<case>();

		Set<case> caseOnboardingList = new Set<case>();
        
        Set<case> caseListGreen = new Set<case>();
        
        for(case eachCase : lstCasesForButton){
            
            if(eachCase.CaseMilestones.size() > 0 && eachCase.CaseMilestones != Null && !eachCase.isClosed){ 
                Boolean caseWithMilestoneRunning = False;
                for(CaseMilestone eachCaseMS :eachCase.CaseMilestones){
                    String milestoneName = eachCaseMS.MilestoneType.Name;
                    if(!eachCaseMS.IsCompleted || isTestRunning){
                      // ESESP-2636  - Updated Manual SLA time calculation logic, to use the Case Milestone time fields
                        if(eachCaseMS.TimeRemainingInMins != '00:00') {
                            minutesToSLA = Integer.valueOf( eachCaseMS.TimeRemainingInMins.split(':')[0]);
                            missingSlaInDays = eachCaseMS.TimeRemainingInDays.setscale(2);
                        }
                        else {
                            minutesToSLA = -Integer.valueOf( eachCaseMS.TimeSinceTargetInMins.split(':')[0]);
                            missingSlaInDays = -eachCaseMS.TimeSinceTargetInDays.setscale(2);
                        }
                        
                        // Logic for Onboarding and QBR case//&& eachCase.OwnerId == UserInfo.getUserId() 
                        if((eachCase.Request_Type__c == 'Customer Onboarding')){
                            system.debug('--userSetupNonCompliantString--'+userSetupNonCompliantString);
                            system.debug('--userSetupCompliantString--'+userSetupCompliantString);
                            if(userSetupNonCompliantString.contains(eachCase.Id) && caseFilter != 'My Manager Open Cases'){
                                missingSlaInDaysMap.put(eachCase.id,missingSlaInDays);
                                caseIdButtonFlagMap.put(eachCase.id,'Red');
                                //caseOnboardingList.add(eachCase);
                                caseExternalListSLA.add(eachCase);
                                system.debug('--External Onboarding--with USerSetup Red--'+eachCase.id);
                            }
                            else if(userSetupCompliantString.contains(eachCase.Id) && caseFilter != 'My Manager Open Cases'){
                                caseIdButtonFlagMap.put(eachCase.id,'Green');
                                caseListGreen.add(eachCase);
                            }
                            else if(userSetupBlankString.contains(eachCase.Id)){
                                missingSlaInDaysMap.put(eachCase.id,missingSlaInDays);
                                caseIdButtonFlagMap.put(eachCase.id,'Yellow');
                                caseOnboardingList.add(eachCase); 
                                system.debug('--External Onboarding USerSetup Blank-- Yellow--'+eachCase.id);
                            }
                            else if(minutesToSLA != null && minutesToSLA < 0 && !eachCase.Do_Not_Show_in_Portal__c && caseFilter != 'My Manager Open Cases'){
                                caseIdButtonFlagMap.put(eachCase.id,'Red');
                                caseExternalListSLA.add(eachCase);
                                missingSlaInDaysMap.put(eachCase.id,missingSlaInDays);
                                system.debug('--External Onboarding No UserSetup-- minutesToSLA--'+minutesToSLA);
                                system.debug('--External Onboarding No UserSetup-- Red--'+eachCase.id);
                            }
                            else if(minutesToSLA != null && minutesToSLA < 1440 && !eachCase.Do_Not_Show_in_Portal__c && milestoneName != '' && ( milestoneName == 'Initial Response' || milestoneName == 'AMG Post Transition Initial Response' ) && caseFilter != 'My Manager Open Cases'){
                                //caseIdButtonFlagMap.put(eachCase.id,'Green');
                                //system.debug('--External Onboarding-- No UserSetup Less than 24hrs SLA Green--'+eachCase.id);
                                missingSlaInDaysMap.put(eachCase.id,missingSlaInDays);
                                caseIdButtonFlagMap.put(eachCase.id,'Yellow');
                                caseOnboardingList.add(eachCase); 
                                system.debug('--External Onboarding Initial Response Milestone Completed = False AND Violation = False -- Yellow--'+eachCase.id);
                            }
                            else{
                                system.debug('--External Onboarding--with USerSetup Blue--'+eachCase.id);
                                caseIdButtonFlagMap.put(eachCase.id,'Blue'); 
                            }
                            
                        }
                        
                        // Logic for External Case// && eachCase.OwnerId == UserInfo.getUserId()
                        else if(!eachCase.Do_Not_Show_in_Portal__c && (minutesToSLA < 1440) && (eachCase.Request_Type__c != 'Customer Onboarding' || eachCase.Request_Type__c != 'Quarterly Business Review')){
                            
                            missingSlaInDaysMap.put(eachCase.id,missingSlaInDays);
                            
                            if(minutesToSLA < 0 && caseFilter != 'My Manager Open Cases'){
                                caseIdButtonFlagMap.put(eachCase.id,'Red');
                                caseExternalListSLA.add(eachCase);
                                system.debug('--External--Red--'+eachCase.id);
                            }
                            else if(minutesToSLA > 0){
                                caseIdButtonFlagMap.put(eachCase.id,'Yellow');
                                caseExternalRunningSLAList.add(eachCase);
                                system.debug('--External--Yellow--'+eachCase.id);
                                
                            }
                            
                        }
                        //&& eachCase.OwnerId == UserInfo.getUserId()
                        else if(!eachCase.Do_Not_Show_in_Portal__c && eachCase.Request_Type__c != 'Quarterly Business Review' && userSetupCompliantList.contains(eachCase.Id) && caseFilter != 'My Manager Open Cases'){
                            caseIdButtonFlagMap.put(eachCase.id,'Green');
                            caseListGreen.add(eachCase);
                            system.debug('--External Not QBR and UserSetup Compliant--Green--'+eachCase.id);
                        }
                        else{
                            system.debug('----Blue Milestone Running--'+eachCase.id);
                            caseIdButtonFlagMap.put(eachCase.id,'Blue');
                        }
                    }
                    
                    else if(eachCase.Request_Type__c == 'Customer Onboarding'){
                        
                        if(userSetupNonCompliantString.contains(eachCase.Id) && caseFilter != 'My Manager Open Cases'){
                            caseIdButtonFlagMap.put(eachCase.id,'Red');
                            caseExternalListSLA.add(eachCase);
                            missingSlaInDaysMap.put(eachCase.id,missingSlaInDays);
                            system.debug('--Onboarding+USerSetup Not Met--Red--'+eachCase.id);
                        }
                        else if(userSetupCompliantString.contains(eachCase.Id) && caseFilter != 'My Manager Open Cases'){
                            caseIdButtonFlagMap.put(eachCase.id,'Green');
                            caseListGreen.add(eachCase);
                        }
                        else if(userSetupBlankString.contains(eachCase.Id)){
                            missingSlaInDaysMap.put(eachCase.id,missingSlaInDays);
                            caseIdButtonFlagMap.put(eachCase.id,'Yellow');
                            caseOnboardingList.add(eachCase); 
                            system.debug('--External Onboarding USerSetup Blank-- Yellow--'+eachCase.id);
                        }
                        else{
                            caseIdButtonFlagMap.put(eachCase.id,'Blue');
                            system.debug('----Onboarding Blue--'+eachCase.id);
                        }
                    }
                    
                    else if(!eachCaseMS.IsViolated && !eachCase.Do_Not_Show_in_Portal__c && caseFilter != 'My Manager Open Cases'){
                        caseIdButtonFlagMap.put(eachCase.id,'Green');
                        caseListGreen.add(eachCase);
                        system.debug('--External+Non-Voilation--Green--'+eachCase.id);
                    }
                    
                    else if(!eachCase.Do_Not_Show_in_Portal__c && eachCaseMS.IsViolated && caseFilter != 'My Manager Open Cases'){
                        caseIdButtonFlagMap.put(eachCase.id,'Red');
                        caseExternalListSLA.add(eachCase);
                        missingSlaInDaysMap.put(eachCase.id,missingSlaInDays);
                        system.debug('--External+Voilation--Red--'+eachCase.id);
                    }
                    
                    else{
                        caseIdButtonFlagMap.put(eachCase.id,'Blue');
                        system.debug('----Blue--'+eachCase.id);
                    }
                }
            }
            
            else if(eachCase.Request_Type__c == 'Customer Onboarding') {
                
                if (userSetupNonCompliantString.contains(eachCase.Id) && caseFilter != 'My Manager Open Cases') {
                    caseIdButtonFlagMap.put(eachCase.id, 'Red');
                    caseExternalListSLA.add(eachCase);
                    missingSlaInDaysMap.put(eachCase.id, missingSlaInDays);
                    system.debug('--Onboarding+USerSetup Not Met--Red--' + eachCase.id);
                } else if (userSetupCompliantString.contains(eachCase.Id) && caseFilter != 'My Manager Open Cases') {
                    caseIdButtonFlagMap.put(eachCase.id,'Green');
                    caseListGreen.add(eachCase);
                }
                else if(userSetupBlankString.contains(eachCase.Id)){
                    missingSlaInDaysMap.put(eachCase.id,missingSlaInDays);
                    caseIdButtonFlagMap.put(eachCase.id,'Yellow');
                    caseOnboardingList.add(eachCase); 
                    system.debug('--External Onboarding USerSetup Blank-- Yellow--'+eachCase.id);
                }
                else {
                    caseIdButtonFlagMap.put(eachCase.id, 'Blue');
                    
                    system.debug('----Blue Inside Onboarding No Match--' + eachCase.id);
                }
            }
            
            else if(eachCase.Request_Type__c != 'Existing Customer Onboarding'){
                
                if (userSetupNonCompliantString.contains(eachCase.Id) && caseFilter != 'My Manager Open Cases') {
                    caseIdButtonFlagMap.put(eachCase.id, 'Red');
                    caseExternalListSLA.add(eachCase);
                    missingSlaInDaysMap.put(eachCase.id, missingSlaInDays);
                    system.debug('-- Non Existing Customer Onboarding USerSetup Not Met--Red--' + eachCase.id);
                } else if (userSetupCompliantString.contains(eachCase.Id) && caseFilter != 'My Manager Open Cases') {
                    caseIdButtonFlagMap.put(eachCase.id,'Green');
                    caseListGreen.add(eachCase);
                }
                else if(userSetupBlankString.contains(eachCase.Id)){
                    missingSlaInDaysMap.put(eachCase.id,missingSlaInDays);
                    caseIdButtonFlagMap.put(eachCase.id,'Yellow');
                    caseOnboardingList.add(eachCase); 
                    system.debug('--Non Existing Customer Onboarding USerSetup Blank-- Yellow--'+eachCase.id);
                }
                else {
                    caseIdButtonFlagMap.put(eachCase.id, 'Blue');
                    system.debug('----Blue Inside Onboarding No Match--' + eachCase.id);
                }
            }
            else{
                    caseIdButtonFlagMap.put(eachCase.id, 'Blue');
                    system.debug('----No Match--' + eachCase.id);
            }
            
            //Logic for Ageing Case button 
            if(eachCase.Age_days__c >= 30 && eachCase.Request_Type__c != 'Customer Onboarding' && eachCase.Request_Type__c != 'Existing Customer Onboarding'){
                
                ageingCaseButtonColors = 'Red';
                totalAgeingCase = totalAgeingCase + 1;
                listAgeingCases.add(eachCase);
            }
        }              
        
        
        if(caseExternalRunningSLAList.size() > 0){
            slaAlertButtonColors = 'Yellow';
            for(case forCaseExtRunList :caseExternalRunningSLAList){ 
                system.debug('---forCaseExtRunList---'+forCaseExtRunList.Id);
                
                totalExternalCases = totalExternalCases + 1;
                caseIdRecordMap.put(forCaseExtRunList.id,forCaseExtRunList);
                
            }  
        }
        if(caseOnboardingList.size() > 0){
            slaAlertButtonColors = 'Yellow';
            for(case forCaseOnbrd :caseOnboardingList){    
                system.debug('---forCaseOnbrd---'+forCaseOnbrd.Id);
                totalExternalCases = totalExternalCases + 1;
                caseIdRecordMap.put(forCaseOnbrd.id,forCaseOnbrd);
                
            } 
        }
        if(caseExternalRunningSLAList.size() == 0 && caseOnboardingList.size() == 0 && caseExternalListSLA.size() > 0 ){ 
            slaAlertButtonColors = 'Red';
            for(case forCaseExt :caseExternalListSLA){    
                system.debug('---forCaseExt---'+forCaseExt.Id);
                totalExternalCases = totalExternalCases + 1;
                caseIdRecordMap.put(forCaseExt.id,forCaseExt);
                
            }
        }
        system.debug('---Final stage caseFilter---'+caseFilter);
        system.debug('---Final stage caseExternalRunningSLAList Size---'+caseExternalRunningSLAList.size());
        system.debug('---Final stage caseOnboardingList Size---'+caseOnboardingList.size());
        system.debug('---Final stage green case Size---'+caseListGreen.size());
        if(caseFilter == 'My Manager Open Cases'){
            lstCases.clear();
            lstCases.addAll(caseExternalRunningSLAList);
            lstCases.addAll(caseOnboardingList);
            lstCases.addAll(caseExternalListSLA);
            lstCases.addAll(caseListGreen);
        }
        system.debug('---Final stage lstCases Size---'+lstCases.size());
    }
    
    //Logic for My LOE button
    // changes by Vandhana for CR 3568251 - AMG homescreen for LOE
    // My LOE page should show User owned Closed Cases created in the last 7 days
    
    public void calculateLOE()
    {
        if(!hasTaskLoeCalculated){
            hasTaskLoeCalculated = true;
            datetime cutoffDate = Date.today() - 7;
            lstLOECases = new List<Case>();
            lstLOECases = [SELECT Id, AKAM_Case_ID__c, Subject, Status, Account.Name, Isclosed, ClosedDate, Total_LOE_min__c FROM Case WHERE ownerId =: UserInfo.getUserId() AND Isclosed = true AND ClosedDate > :cutoffDate ORDER BY ClosedDate DESC];
            //List<Case> userCaseTeamCasesList = Database.query('Select Id From Case Where ID IN (Select ParentId From CaseTeamMember Where MemberId = \'' + UserInfo.getUserId() + '\') AND Isclosed = true AND CreatedDate > :cutoffDate');
            if(lstLOECases.size() > 0)
            {
                for(Case eachLOECase : lstLOECases){
                    totalLOE += eachLOECase.Total_LOE_min__c; 
                }
            }
            totalLOE = (totalLOE/60).setscale(2);
        }
    }
    // end of changes by Vandhana
    
    
    public Pagereference populateTasks() {
        Agent_Home_Collection_Limit__c cl = Agent_Home_Collection_Limit__c.getValues('Limit Value');
        cLimit = cl.Collection_Limit__c.intValue();
        if(taskFilter.equals('My Tasks Due Today')){
            lstTasks = getTasksList(' Where ownerID = \'' + UserInfo.getUserId() + '\' AND ActivityDate = Today');
        } else if(taskFilter.equals('My Activities')){
            lstTasks = getTasksList(' Where ownerID = \'' + UserInfo.getUserId() + '\' ORDER BY ActivityDate NULLS LAST');
        } else if(taskFilter.equals('My Open Activities')){
            lstTasks = getTasksList(' Where ownerID = \'' + UserInfo.getUserId() + '\' AND (Status != \'Completed\' AND Status != \'Not Applicable\') ORDER BY ActivityDate NULLS LAST');
        } else if(taskFilter.equals('My Team\'s Open Activities')){
            if(UserInfo.getUserRoleId() != null) {
                String userIds = '';
                for(User u : Database.query('Select Id from User Where UserRoleId in (select Id from UserRole where parentRoleId = \'' + UserInfo.getUserRoleId()+ '\')')) {
                    userIds += '\'' + u.Id + '\',';
                }
                lstTasks = getTasksList(' Where ownerID IN (' + userIds.substring(0, userIds.lastIndexOf(',')) + ') AND ActivityDate = Today');
            } else {
                lstTasks = new List<Task>();
            }
        } else if(taskFilter.equals('Overdue Tasks')){
            lstTasks = getTasksList(' Where ownerID = \'' + UserInfo.getUserId() + '\' AND ActivityDate < Today AND (Status != \'Completed\' AND Status != \'Not Applicable\') ORDER BY ActivityDate NULLS LAST');
        }
        
        return null;
    }
    
    public Pagereference toggleUserAvailability()
    {
        currentUser.Availability__c = !isAvailable;
        if(currentUser.Availability__c)
            currentUser.Backup_User__c = NULL;
        update currentUser;
        Pagereference pr = Apexpages.currentPage();
        pr.setRedirect(true);
        return pr;
    }
    
    // changes by Vandhana
    public void updateBackupUser()
    {
        if(currentUser.Backup_User__c == UserInfo.getUserId())
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'You cannot select yourself as the Backup User. Please select another User',''));
            return;
        }
        try
        {
            if(String.isNotBlank(currentUser.Backup_User__c))
            {
                Set<String> amgProfile = new Set<String>([SELECT Value__c 
                                                          FROM SC_Utility__mdt 
                                                          WHERE MasterLabel = 'AMG Agent Profile List' limit 1].Value__c.split(','));
                User backupUsr = new User();
                backupUsr = [Select ProfileId,Profile.Name 
                             FROM User
                             WHERE Id = :currentUser.Backup_User__c
                             AND isActive = TRUE
                             LIMIT 1
                            ];
                if(!amgProfile.contains(backupUsr.Profile.Name))
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please select an AMG Agent',''));
                    return;
                }
            }
            update currentUser;
        }   
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'ERROR' + e.getMessage()));
        }
    }
    
    @TestVisible
    private String listToStringIds(List<Sobject> lst) {
        if(lst == null || lst.size() <= 0) {
            return '';
        }
        String str = '';
        for(Sobject obj : lst) {
            str += ',\'' + obj.get('Id') + '\'';
        }
        str = str.substring(1);
        return str;
    }
    
}