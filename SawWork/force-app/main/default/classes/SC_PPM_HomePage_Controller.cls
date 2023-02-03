/*
Author          : Sheena
Description     : Apex Controller for PPM Dashboard LWC
Test Class      : SC_PPM_HomePage_Controller_Test

Date                Developer                   JIRA #                 Description                                                       
---------------------------------------------------------------------------------------------------------------------------------------------------
22 March 2022        Sheena               		ESESP-6533             Initial Version
---------------------------------------------------------------------------------------------------------------------------------------------------

*/
public class SC_PPM_HomePage_Controller {
    
    Public static integer redCount=0; 
    Public static integer whiteCount=0;
    Public static integer yellowCount=0;
    
    public class MainWrapper{
        @AuraEnabled public list<CaseWrapper> CaseData;
        @AuraEnabled public integer totalCaseCount=0;
        @AuraEnabled public integer totalRedCount=0;
        @AuraEnabled public integer totalWhiteCount=0;
        @AuraEnabled public integer totalYellowCount=0;
    }
    
    public class CaseWrapper implements Comparable{
        
        @AuraEnabled public string akamCaseId{get;set;}
        @AuraEnabled public string caseUrl{get;set;}
        @AuraEnabled public string caseId{get;set;}
        @AuraEnabled public string accountName{get;set;}
        @AuraEnabled public string accountTier{get;set;}
        @AuraEnabled public string caseSubject{get;set;}
        @AuraEnabled public string geography{get;set;}
        @AuraEnabled public string problem{get;set;}
        @AuraEnabled public string severity{get;set;}
        @AuraEnabled public string caseOwnerName{get;set;}
        @AuraEnabled public string taskType{get;set;}
        @AuraEnabled public string taskSubject{get;set;}
        @AuraEnabled public string taskDueDateinMinutes{get;set;} 
        @AuraEnabled public string caseLastUpdateTimeinMinutes{get;set;} 
        @AuraEnabled public string caseLastUpdateBy{get;set;} 
        @AuraEnabled public string caseColour{get;set;}
        @AuraEnabled public integer caseColourPriority{get;set;}
        
        
        
        public Integer compareTo(Object compareTo) {
            CaseWrapper compareToRec = (CaseWrapper)compareTo;
            if (caseColourPriority > compareToRec.caseColourPriority) {
                return 1;
            } else if (caseColourPriority < compareToRec.caseColourPriority) {
                return -1;
            } else {
                // First value the same, consider second value
                if (severity > compareToRec.severity) {
                    return 1;
                } else if (severity < compareToRec.severity) {
                    return -1;
                } else {
                    return 0;
                }          
            }       
        }
    }
    
    // Method - 1 : Main method for returning Case Data
    @AuraEnabled
    public static MainWrapper getCaseData(List<String> severityFilter, String geographyFilter){
        
        List<Case> caseList = new List<Case>();
        
        List<CaseWrapper> caseWrapperList = new List<CaseWrapper>();
        CaseWrapper caseWrap;
        Integer taskDueInMins;
        String caseQuery = '';
        String severityQuery = '';
        String geoQuery = '';
        String orderByQuery = '';
        
        String ownerManager = [SELECT Value_Text__c FROM SC_Utility__mdt WHERE DeveloperName = 'PPM_Manager' LIMIT 1].Value_Text__c; // Abhijit Dev Choudhury
        Id queueId = [SELECT Value_Text__c FROM SC_Utility__mdt WHERE DeveloperName = 'PPM_Queue_Id' LIMIT 1].Value_Text__c; // ATS_CMP_QUEUE
        Id closedQueueId = [SELECT Value_Text__c FROM SC_Utility__mdt WHERE DeveloperName = 'PPM_Closed_Queue_Id' LIMIT 1].Value_Text__c; // Closed Queue

        
        /*---Case Query----*/        
        
        caseQuery = 'Select Id, AKAM_Case_ID__c, status, IR_Customer_Tier__c, Case_Owner_Name__c,'
            + ' Last_Update_By__c, AKAM_Modified_By__c, Problem__c, Support_Geography__c, Account.Name, '
            + ' lastmodifieddate, Severity__c,subject,Sub_Type__c,CreatedDate,'
            + ' (Select Subject, Type__c, ActivityDate from tasks where status != \'Completed\'),'
            + ' (Select Id,Incoming from EmailMessages order by MessageDate desc limit 1),'
            + ' (Select Id from CaseMilestones where MilestoneType.Name = \'Initial Response\' and IsCompleted = false)'
            + ' from case where Recordtype.name = \'Technical\' and OwnerId != \''+ closedQueueId +'\' and'
            + ' (Sub_Type__c = \'CMP Alerts\' or (Sub_Type__c = \'NIE/NOCC Request\' and (Case_Owner_Manager__c = \''+ ownerManager + '\' or OwnerId = \''+ queueId + '\')))'
            + ' and isClosed = FALSE';
        
        if(severityFilter.size()<3){
            severityQuery = ' and Severity__c IN :severityFilter';  
        }
        
        if(!geographyFilter.equalsIgnoreCase('All')){
            geoQuery = ' and Support_Geography__c =  \''+ geographyFilter + '\'';
        }
        
        orderByQuery = ' order by createddate desc';
        caseQuery += severityQuery + geoQuery + orderByQuery;
        
        
        caseList= database.query(caseQuery);
        
        for(Case cs: caseList){
            
            
            // If No Tasks
            if(cs.Tasks.isEmpty()){
                caseWrap = new CaseWrapper();
                // Assigning Case Data to Wrapper
                getCaseWrapperData(cs, caseWrap);
                caseWrapperList.add(caseWrap);
            }
            
            /*---Fetching Task Details----*/
            else{
                for(Task t: cs.Tasks) {
                    caseWrap = new CaseWrapper();
                    // Assigning Case Data to Wrapper
                    getCaseWrapperData(cs, caseWrap);
                    caseWrap.taskType = t.Type__c;
                    caseWrap.taskSubject  = t.Subject;
                    caseWrap.taskDueDateinMinutes = cs.AKAM_Case_ID__c; 
                    /*---Caculating Task DueIn Mins----*/
                    taskDueInMins = 0;
                    if(t.ActivityDate != null){
                        Time dueTime = Time.newInstance(0, 0, 0, 0);
                        DateTime dueDateTime = DateTime.newInstance(t.ActivityDate, dueTime);
                        taskDueInMins = integer.valueOf((dueDateTime.getTime() - system.now().getTime())/1000/60);
                    } 
                    caseWrap.taskDueDateinMinutes = (taskDueInMins < 0) ? '-'+ (taskDueInMins/60 * -1) + 'h ' +  Math.mod(taskDueInMins * -1,60) + 'm' :
                    (taskDueInMins == 0) ? '-' : taskDueInMins/60 + 'h ' +  Math.mod(taskDueInMins,60) + 'm';
                    caseWrapperList.add(caseWrap);
                }               
            }
            
        }
        caseWrapperList.sort();
        MainWrapper mainWrap = new MainWrapper();
        mainWrap.caseData = caseWrapperList;
        mainWrap.totalCaseCount = caseWrapperList.size();
        mainWrap.totalRedCount = redCount;
        mainWrap.totalWhiteCount = whiteCount;
        mainWrap.totalYellowCount = yellowCount;
        
        system.debug('mainWrap//'+mainWrap);
        
        return mainWrap;
    }
    
    public static void getCaseWrapperData(Case cs, CaseWrapper caseWrap){

        Integer minsSinceCaseCreated;
        Integer minsSinceCaseUpdated;
        
        caseWrap.akamCaseId = cs.AKAM_Case_ID__c;
        caseWrap.caseUrl  = '/lightning/r/Case/' + cs.Id + '/view';
        caseWrap.caseId = cs.Id;
        caseWrap.accountName = cs.Account.Name;
        caseWrap.accountTier = cs.IR_Customer_Tier__c;
        caseWrap.caseSubject = cs.Subject;
        caseWrap.geography = cs.Support_Geography__c;
        caseWrap.problem = cs.Problem__c;
        caseWrap.severity = cs.Severity__c;
        caseWrap.caseOwnerName = cs.Case_Owner_Name__c;
        
        /*--Calculating  Case Modified Time---*/
        minsSinceCaseUpdated = integer.valueOf((cs.lastmodifieddate.getTime() - system.now().getTime())/1000/60 );
        caseWrap.caseLastUpdateTimeinMinutes = (minsSinceCaseUpdated/60 * -1) + 'h ' +  Math.mod(minsSinceCaseUpdated * -1,60) + 'm ago';
        
        /*---Calculating Case Last Updated By ----*/
        caseWrap.caseLastUpdateBy = (cs.Last_Update_By__c=='Customer') ? 'Customer' : cs.AKAM_Modified_By__c; 
        
        /*---Calculating Case Colour Code value----*/
        caseWrap.caseColour = 'blue';
        caseWrap.caseColourPriority = 4;
        
        if(!cs.CaseMilestones.isEmpty()){
            minsSinceCaseCreated = Integer.valueOf((DateTime.now().getTime() - cs.CreatedDate.getTime())/1000/60);
            if(minsSinceCaseCreated > 30){
                caseWrap.caseColour = 'red'; 
                caseWrap.caseColourPriority = 1;
                redCount++;
            }
        }
        else if(cs.Status=='Unassigned'){
            caseWrap.caseColour = 'white';
            caseWrap.caseColourPriority = 2;
            whiteCount++;
        }
        else if(!cs.EmailMessages.isEmpty() && cs.EmailMessages[0].incoming==true){
            caseWrap.caseColour = 'yellow';
            caseWrap.caseColourPriority = 3;
            yellowCount++;
        }
        
    }
    
    
    // this method will save filters in SC User Filter object
    @AuraEnabled
    public static Map<String,String> saveFilters(String filterToSave)
    {
        system.debug('filterToSave//'+filterToSave);
        Map<String,String> savedFilterVal = new Map<String,String>();
        
        string rectypeid = SC_User_Filter__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('PPM').getRecordTypeId();
        string uniqueid = userinfo.getUserId()+'-'+rectypeid;
        
        List<SC_User_Filter__c> filter = new List<SC_User_Filter__c>();
        
        filter = [SELECT Unique_ID__c ,Filter_Values__c  FROM SC_User_Filter__c WHERE Unique_ID__c = :uniqueid limit 1];
        system.debug('filter...'+filter);
        
        String selectAll = 'Severity:1,2,3&Geography:All';
        savedFilterVal.put('Severity','1,2,3');
        savedFilterVal.put('Geography','All');
        
        if(filter.size() == 0)
        {
            SC_User_Filter__c newFilterRec = new SC_User_Filter__c(Filter_Values__c = selectAll,Unique_ID__c = uniqueid, recordtypeid=rectypeid);
            upsert newFilterRec;
        }
        else if(String.isBlank(filter[0].Filter_Values__c))
        {
            filter[0].Filter_Values__c = selectAll;
            upsert filter;
        }
        else
        {
            if(String.isNotBlank(filterToSave))
            {
                filter[0].Filter_Values__c = filterToSave;
                upsert filter;
                return NULL;
            }
            else
            {
                savedFilterVal = new Map<String,String>();
                List<String> filterVals = filter[0].Filter_Values__c.split('&');
                for(String s : filterVals)
                {
                    List<String> text = s.split(':');
                    savedFilterVal.put(text[0],text[1]);
                }
            }
        }   
        return savedFilterVal; 
    }
    
}