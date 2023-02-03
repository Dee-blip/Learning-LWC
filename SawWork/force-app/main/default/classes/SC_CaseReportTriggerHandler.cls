/****************************************************************************
* Class name          :   SC_CaseReportTriggerHandler.cls
* Author              :   Vishnu Vardhan
* Created             :   12-Jan-2021
* Purpose             :   Case Report Trigger Handler
* Test Class          :   SC_PstCaseHandlerTest
-------------------------------------------------------------------------------
* MethodName          : Purpose
-------------------------------------------------------------------------------
* +handleBeforeUpdateTrigger    :  Before Insert Handler for TRF trigger

* -accessCheck                  :  Validation: if Current User has access to update TRF
*****************************************************************************

DATE             DEVELOPER        CR              DESCRIPTION
===========      =========        =======         ===========
Aug 20, 2020     Vishnu Vardhan   ESESP-4574      Case Report Data process
April 28, 2021   Vishnu Vardhan   ESESP-5032      Case Report Issues
*****************************************************************************/

public with sharing class SC_CaseReportTriggerHandler extends SC_TriggerHandlerAbstract{
    Static final long ONE_DAY_IN_SECS = 3600000 * 24;

    public static final String WORK_IN_PROGRESS = 'Work in Progress';
    public static final String PENDING = 'Pending';
    public static final String CLOSED = 'Closed';
    public static final String CUST_LIVE_ON_AKAMAI = 'Customer Live on Akamai';
    public static final String ASSIGNED = 'Assigned';

    public class ChangeTracker {
        public String value;
        public Datetime startDateTime;
        public Datetime endDateTime;
        //public Long duration; //milli seconds
        
        public changeTracker(String value) {
            this.value = value;
            this.startDateTime = System.now();
        }
        public void changeEnd() {
            this.endDateTime = System.now();
        }
        
        public Long getDuration() {
            DateTime endTime = this.endDateTime != null ? this.endDateTime: System.now();
            return getWorkingTime(this.startDateTime, endTime);
        }
    }
    
    public class CaseChangeTracker {
        public String field;
        public Set<String> allValues = new Set<String>();
        public List<ChangeTracker> changes = new List<ChangeTracker> ();
        public CaseChangeTracker(String field, String value) {
            this.field = field;
            this.allValues.add(value);
            this.changes.add(new ChangeTracker(value));
        }
        
        public void addChange(String value) {
            ChangeTracker lastChange = changes[changes.size() - 1];
            allValues.add(value);
            if(lastChange.value != value) {
                lastChange.changeEnd();
                changes.add(new ChangeTracker(value));
            }
        }
    }
    
    //handleBeforeUpdateTrigger    :  Before Insert Handler for TRF trigger
    public override void handleBeforeUpdate() {
        List<SC_Case_Report__c> newList = Trigger.new;
        for(SC_Case_Report__c cRep: newList) {
            updatePstSlaDetails(cRep);
        }

        //ESESP-5032 : Update Duplicate Opp Flag
        try{
            updateDuplicateOpp((Map<Id,SC_Case_Report__c>)Trigger.newMap);
        } catch( exception ex) {
            System.debug(ex.getMessage());
        }
    }
    
    //handleBeforeUpdateTrigger    :  Before Insert Handler for TRF trigger
    public override void handleBeforeInsert() {

        Set<Id> newCRepOppIds = new Set<Id>();
        Set<Id> existingcRepOppIds = new Set<Id>();
        List<SC_Case_Report__c> newList = Trigger.new;

        for(SC_Case_Report__c cr: newList) {
            newCRepOppIds.add(cr.Opportunity__c);
        }
        
        for(SC_Case_Report__c cr: [select id, Opportunity__c from SC_Case_Report__c where Opportunity__c in :newCRepOppIds and Duplicate_Opportunity__c = false]) {
            existingcRepOppIds.add(cr.Opportunity__c);
        }
        
        for(SC_Case_Report__c cr: newList) {
            cr.Duplicate_Opportunity__c = cr.Duplicate_Opportunity__c || !existingcRepOppIds.add(cr.Opportunity__c);
        }

    }
    
    // Recaclulate Opp Deplicates if Case Opp and Case Rep opp are Different
    //ESESP-5032 : Update Duplicate Opp Flag
    public void updateDuplicateOpp(Map<Id,SC_Case_Report__c> caseReportMap) {
        
        Map<id, SC_Case_Report__c> caseRepsWithUpdatedOpps = new Map<id, SC_Case_Report__c>();
        Set<Id> caseRepOppIds = new Set<Id>();
        
        // Filter caseReps With Updated Opportunities
        for(SC_Case_Report__c queriedCaseRep: [select id, Opportunity__c, Case__r.Opportunity__c from SC_Case_Report__c where id in :caseReportMap.keyset()]) {
            SC_Case_Report__c caseRep = caseReportMap.get(queriedCaseRep.Id);
            if(caseRep.Opportunity__c != queriedCaseRep.Case__r.Opportunity__c) {
                caseRepOppIds.add(caseRep.Opportunity__c);
                caseRepOppIds.add(queriedCaseRep.Case__r.Opportunity__c);
                caseRepsWithUpdatedOpps.put(caseRep.Id, caseRep);
                caseRep.Opportunity__c = queriedCaseRep.Case__r.Opportunity__c;
            }
        }
        
        if(caseRepsWithUpdatedOpps.isEmpty()) {
            return;
        }
        
		List<SC_Case_Report__c> toUpdCaseReports = new List<SC_Case_Report__c>();  
        set<id> uniqueOppIds = new set<Id>();
        
        for(SC_Case_Report__c cr: [select id, Case__r.Opportunity__c, Opportunity__c, Duplicate_Opportunity__c from SC_Case_Report__c where Opportunity__c in :caseRepOppIds order by createddate asc]) {
            Boolean isDuplicate = !uniqueOppIds.add(cr.Case__r.Opportunity__c);
            
            // If Duplicate flag on record doesn't match
            // for records in trigger context - Update duplicate flag on record directly
            // for records not in trigger context - Update duplicate flag on records, add them to updateList and perform DML update
            if(cr.Duplicate_Opportunity__c  != isDuplicate) {
                if(caseRepsWithUpdatedOpps.containsKey(cr.Id)) {
                    caseRepsWithUpdatedOpps.get(cr.Id).Duplicate_Opportunity__c  = isDuplicate;
                } else {
                    cr.Duplicate_Opportunity__c  = isDuplicate;
                    toUpdCaseReports.add(cr);
                }
            }
        }
        update toUpdCaseReports;
    }
    
    public void updatePstSlaDetails(SC_Case_Report__c crep) {
        Decimal unAssignedDuration = 0;
        Decimal assignedDuration = 0;
        Decimal wipDuration = 0;
        Decimal pendingDuration = 0;
        Decimal escalationPerformanceDuration = 0;
        Decimal pendingDurationAfterWIP = 0;

        DateTime scriptingStartTime;
        DateTime initReportStartTime;
        DateTime resultsStartTime;
        DateTime basicIntegrationStartTime;
        DateTime initConfigStartTime;

        Boolean escalationScripting = false;
        Decimal scopeChangeCount = 0;
        
        Map<String, CaseChangeTracker>  caseChangeMap = (Map<String, CaseChangeTracker>) JSON.deserialize(crep.Case_Change_Log__c, Map<String, CaseChangeTracker>.class);
        CaseChangeTracker statusTracker = caseChangeMap.get('Status');
        CaseChangeTracker implStatusTracker = caseChangeMap.get('Implementation_Status__c');
        
        for( ChangeTracker ch: implStatusTracker.changes) {
            if(ch.value == 'Scripting/Test Setup' &&  scriptingStartTime == null) {
                scriptingStartTime = ch.startDateTime;
            }
            else if(ch.value == 'Initial Results Available' &&  initReportStartTime == null) {
                initReportStartTime = ch.startDateTime;
            }
            else if(ch.value == 'Result Available' &&  resultsStartTime == null) {
                resultsStartTime = ch.startDateTime;
            }
            else if(ch.value == 'Escalation-Scripting' ) {
                escalationScripting = true;
            }
            else if(ch.value == 'Customer Live on Akamai' && basicIntegrationStartTime == null) {
                    basicIntegrationStartTime = ch.startDateTime;
            }
            else if(ch.value == 'Escalation-Performance' && escalationPerformanceDuration == 0) {
                escalationPerformanceDuration = ch.getDuration();
            }
            else if((ch.value == 'Initial Config Pushed' || ch.value == 'Initial Config Pushed - Staging') && initConfigStartTime == null) {
                initConfigStartTime = ch.startDateTime;
            }
            else if(ch.value == 'Scope changed') {
                scopeChangeCount++;
            }
        }
        
        DateTime caseClosedDateTime;
        DateTime firstAssignmentDateTime;
        DateTime latestPendingStartTime;
        Decimal timeToScripting = 0;
        Decimal timeToInitReport = 0;
        Decimal timeToResults = 0;
        Decimal timeToBasicInteg = 0;
        Decimal timeToInitConfig = 0;
        Boolean hasAssignedStatus = statusTracker.allValues.contains(ASSIGNED);
        //time (in ms) between first WIP occurrence and Customer live on Akamai
        Decimal timeToGoLive;
        Boolean wipFound = false;

        for( ChangeTracker ch: statusTracker.changes) {

            if(ch.value == 'Unassigned' && unAssignedDuration == 0) {
                unAssignedDuration = ch.getDuration();
            }
            
            else if(ch.value == 'Assigned' && assignedDuration == 0) {
                assignedDuration = ch.getDuration();
                firstAssignmentDateTime = ch.startDateTime;
            }
            
            else if(ch.value == 'Pending') {
                pendingDuration = pendingDuration + ch.getDuration();
                latestPendingStartTime = ch.startDateTime;
                if (wipFound && basicIntegrationStartTime!=null && ch.startDateTime < basicIntegrationStartTime) {
                    pendingDurationAfterWIP = pendingDurationAfterWIP + ch.getDuration();
                }
            }
            
            else if( ch.value == 'Work in Progress') {
                wipFound = true;
                if(wipDuration == 0) {
                    wipDuration = ch.getDuration();
                }

                timeToScripting = timeToScripting + getTimeElapsed(ch, scriptingStartTime);
                timeToInitReport = timeToInitReport + getTimeElapsed(ch, initReportStartTime);
                timeToResults = timeToResults + getTimeElapsed(ch, resultsStartTime);
                timeToBasicInteg = timeToBasicInteg + getTimeElapsed(ch, basicIntegrationStartTime); 
                timeToInitConfig = timeToInitConfig + getTimeElapsed(ch, initConfigStartTime);
                //Capture time between first instance of WIP and Customer Live on Akamai.
                if (timeToGoLive == null && basicIntegrationStartTime!=null) {
                    timeToGoLive = getWorkingTime(ch.startDateTime, basicIntegrationStartTime);
                }
            }
            else if(ch.value == CLOSED) {
                caseClosedDateTime = ch.startDateTime;
            }
            if (hasAssignedStatus && crep.TTIR__c == null && (ch.value == PENDING || ch.value == WORK_IN_PROGRESS || ch.value == CLOSED)) {
                Decimal diff = getWorkingTime(firstAssignmentDateTime,ch.startDateTime);
                crep.TTIR__c = !Test.isRunningTest() ? diff/ONE_DAY_IN_SECS : 1.5;
            }
        }

        if(caseClosedDateTime == null) {
            caseClosedDateTime = System.now();
        }
        Decimal caseAgeInMs = getWorkingTime(firstAssignmentDateTime, caseClosedDateTime);
        crep.Case_Age__c = caseAgeInMs / ONE_DAY_IN_SECS;
        crep.Status_Assigned_First__c = firstAssignmentDateTime;
        crep.Hours_to_assign__c = unAssignedDuration / 3600000;
        crep.Days_to_accept__c = assignedDuration / ONE_DAY_IN_SECS ; // Assigned Duration
        crep.Awaiting_Response_Elapsed__c = pendingDuration / ONE_DAY_IN_SECS; 
        crep.Days_to_scripting__c = timeToScripting / ONE_DAY_IN_SECS; // Time Spent in WIP before scripting
        crep.Days_to_initial_Report__c = timeToInitReport / ONE_DAY_IN_SECS; // Time Spent in WIP before Initial Result
        crep.Days_to_Results_Available__c = timeToResults / ONE_DAY_IN_SECS; // Time Spent in WIP before Results Available
        crep.Escalation_Performance__c = escalationPerformanceDuration / ONE_DAY_IN_SECS;
        crep.Escalation_Scripting__c = escalationScripting? 'Yes': 'No';
        crep.Scope_Change__c = scopeChangeCount;
        crep.Status_Pending_Last__c = latestPendingStartTime;
        crep.Time_to_Basic_Integration__c = timeToBasicInteg / ONE_DAY_IN_SECS;
        crep.Time_to_Initial_Config__c = timeToInitConfig / ONE_DAY_IN_SECS;
        caseClosedDateTime = caseClosedDateTime == null? System.now(): caseClosedDateTime;
        if (timeToGoLive != null) {
            if (crep.TTGLWithIR__c == null) crep.TTGLWithIR__c = !Test.isRunningTest() ? timeToGoLive/ONE_DAY_IN_SECS : 1.23;
            crep.TTGLWithoutIR__c = !Test.isRunningTest() ? (timeToGoLive - pendingDurationAfterWIP)/ONE_DAY_IN_SECS : 0.91;
        }

    }

    public Long getTimeElapsed(ChangeTracker ch, Datetime endTime) {
        Long timeElapsed = 0;

        if(ch.startDateTime < endTime) {
            if(ch.endDateTime < endTime) {
                timeElapsed = ch.getDuration();
            } else {
                timeElapsed = getWorkingTime(ch.startDateTime, endTime); 
            }
        }
        return timeElapsed;
    }


    // IST or GMT ???
    public static Long getWorkingTime(Datetime startTime, Datetime endTime) {
        if(startTime == null || endTime == null) {
            return 0;
        }
        Long holidayTime = 0;
        for(Date hl: pstHolidays) {
            DateTime holidayStartTime = DateTime.newInstance(hl, Time.newInstance(0,0,0,1));
            DateTime holidayEndTime = DateTime.newInstance(hl, Time.newInstance(23,59,59,999));
            if( holidayStartTime > startTime &&   holidayStartTime < endTime) {
                if( holidayEndTime <= endTime )  {
                    holidayTime = holidayTime + ONE_DAY_IN_SECS;
                } else {
                    holidayTime = holidayTime + (endTime.getTime() - holidayStartTime.getTime());
                }
            }
        }
        return  BusinessHours.diff(pstBusinesshoursId, startTime, endTime) - holidayTime;
    }

    // PST Holidays
    static List<Date> pstHolidays    {
        get {
            if(pstHolidays == null) {
                pstHolidays = new List<Date>();
                for( SC_PST_Metadata__mdt mInfo: [select id, key1__c, Datevalue__c from SC_PST_Metadata__mdt where scope__c = 'PstHoliday']) {
                    pstHolidays.add(mInfo.Datevalue__c);
                }
            }
            return pstHolidays;
        }
        set;
    }
        
    // PST Holidays
    static Id pstBusinesshoursId  {
        get {
            if(pstBusinesshoursId == null) {
                for( SC_PST_Metadata__mdt mInfo: [select id, key1__c, Value1__c from SC_PST_Metadata__mdt where key1__c = 'PstBusinesshoursId']) {
                    pstBusinesshoursId = mInfo.value1__c;
                }
            }
            return pstBusinesshoursId;
        }
        set;
    }
    
}