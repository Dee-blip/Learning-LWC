/******

Author: Sharath Prasanna
Created Date: 24th June 2020
Description: This is the controller for cases component

Developer               Date                Jira            Description
Sharath Prasanna     24th June 2020       ESESP-3536         Initial Development
*/
public class SC_BillingLightningUtility 
{
    public SC_BillingLightningUtility() 
    {

    }
    //The case Wrapper for Both My cases and All cases
    public class CaseWrapper
    {
        
        @AuraEnabled public string akamCaseId{get;set;}
        @AuraEnabled public string caseUrl{get;set;}
        @AuraEnabled public string Id{get;set;}
        @AuraEnabled public String accountName{get;set;}
        @AuraEnabled public string accountUrl{get;set;}
        @AuraEnabled public string subject {get;set;}
        @AuraEnabled public string subjectUrl {get;set;}
        @AuraEnabled public string contactName {get;set;}
        @AuraEnabled public decimal age {get;set;}
        @AuraEnabled public string status {get;set;}
        @AuraEnabled public string origin {get;set;}
        @AuraEnabled public decimal taskLoe {get;set;}
        @AuraEnabled public string initialResponseSla {get;set;}
        @AuraEnabled public string initialResponseClass {get;set;}
        @AuraEnabled public string resolutionSla {get;set;}
        @AuraEnabled public string resolutionClass {get;set;}
        @AuraEnabled public string assignEmoji {get;set;}
        @AuraEnabled public String createdDate {get;set;}
        @AuraEnabled public Integer externalDependancies {get;set;}
        @AuraEnabled public String service {get;set;}
        @AuraEnabled public String requestType {get;set;}
    }

    //The External Dependency Wrapper
    public class EDWrapper
    {
        
        @AuraEnabled public string akamCaseId{get;set;}
        @AuraEnabled public string caseUrl{get;set;}
        @AuraEnabled public string name{get;set;}
        @AuraEnabled public string url{get;set;}
        @AuraEnabled public string typeId{get;set;}
        @AuraEnabled public string type{get;set;}
        @AuraEnabled public string comments{get;set;}        
    }

    //The record type wrapper
    public class RecordTypeWrapper
    {
        @AuraEnabled public string value{get;set;}
        @AuraEnabled public string label{get;set;}

        public RecordTypeWrapper(String name,String id)
        {
            value = id;
            label = name;
        }

    }

    //Summary data wrapper
    public class SummaryDataWrapper
    {
        @AuraEnabled public Integer inQueue{get;set;}
        @AuraEnabled public Integer inQueue24{get;set;}
        @AuraEnabled public Integer open{get;set;}
        @AuraEnabled public Integer closed{get;set;}
        @AuraEnabled public Integer irMiss{get;set;}
        @AuraEnabled public Integer resMiss{get;set;}
                
        public SummaryDataWrapper()
        {
            inQueue = 0;
            inQueue24 = 0;
            open = 0;
            closed = 0;
            irMiss = 0;
            resMiss = 0;         
        }
    }

    //List of records returned for navigation
    public class CaseSummaryWrapper
    {
        @AuraEnabled public string akamId{get;set;}
        @AuraEnabled public string recUrl{get;set;}
        @AuraEnabled public string Body{get;set;}
        public CaseSummaryWrapper(String caseId, String url, String info)
        {
            akamId = caseId;
            recUrl = url;
            Body = info;
        }
    }

    //Get the case data
    @AuraEnabled(cacheable=false)
    public static List<CaseWrapper> getCases(String viewType)    
    {
        String caseQuery;
        String caseFilter = '';
        String loggedInUser = UserInfo.getUserId();
        List<CaseWrapper> caseWrappers = new List<CaseWrapper>();
        CaseWrapper caseWrapperInstance;
        Set<String> queueIds = new Set<String>();
        List<Case> cases = new List<Case>();
    
        caseQuery = 'Select Id,Akam_Case_Id__c,AccountId,Account.Name,Subject,Age_days__c';
        if(viewType == 'MyView')
        {
            caseQuery += ',Status,Origin,Task_LOE__c,Service__c,Request_Type__c';
            caseQuery += ',(Select Id from External_Dependencies__r )';
            caseQuery += ',(select TimeRemainingInMins,isviolated,IsCompleted, milestonetype.Name from CaseMilestones where milestonetype.Name IN (\'Initial Response\', \'Resolution\'))';            

            caseFilter = ' and OwnerId = :loggedInUser';
        }
        else if(viewType == 'AllCases')
        {
            caseQuery += ',AKAM_Created_Date__c,Contact.Name';                        
            for (SC_Utility__mdt billingQueueRec : [Select Value__c,developername from SC_Utility__mdt where 
            Active__c = true and developername like 'BillingQueues%'])
            {
                if(billingQueueRec.Value__c != null)
                {
                    queueIds.addAll(billingQueueRec.Value__c.split(','));
                }
                
            }
            caseFilter = ' and OwnerId in :queueIds';

        }
        caseQuery += ' from Case where isClosed = False and RecordType.Name = \'Billing\'';
        caseQuery += caseFilter;
        Integer limitVariable = 250;
        for (SC_Utility__mdt billingQueueRec : [Select Value_Text__c from SC_Utility__mdt where 
        Active__c = true and developername = 'Billing_Record_Limit'])
        {
            if(billingQueueRec.Value_Text__c != null)
            {
                limitVariable = Integer.valueOf(billingQueueRec.Value_Text__c);
            }
            
        }
        caseQuery += ' order by AKAM_Created_Date__c desc limit :limitVariable';
        system.debug('The query: ' + caseQuery);
        cases = Database.query(caseQuery);
        string slaString = '';
        string slaClass = '';
        for(Case eachCase: cases)
        {
            caseWrapperInstance = new CaseWrapper();
            caseWrapperInstance.Id = eachCase.Id;
            caseWrapperInstance.akamCaseId = eachCase.Akam_Case_Id__c;
            caseWrapperInstance.caseUrl = '/' + eachCase.Id;            
            caseWrapperInstance.accountName = eachCase.Account.Name != null ?eachCase.Account.Name : '';
            caseWrapperInstance.accountUrl = eachCase.AccountId != null? '/' + eachCase.AccountId : '';
            caseWrapperInstance.subject = eachCase.subject != null? eachCase.subject : '';   
            caseWrapperInstance.subjectUrl = eachCase.subject != null? caseWrapperInstance.caseUrl: '';
            caseWrapperInstance.age = eachCase.Age_days__c;
            caseWrapperInstance.externalDependancies = 0;
            if(viewType == 'MyView')
            {
                caseWrapperInstance.status = eachCase.Status;
                caseWrapperInstance.origin = eachCase.Origin;
                caseWrapperInstance.taskLoe = eachCase.Task_LOE__c;
                caseWrapperInstance.service = eachCase.Service__c;
                caseWrapperInstance.requestType = eachCase.Request_Type__c;
                caseWrapperInstance.initialResponseSla = '';
                caseWrapperInstance.resolutionSla = '';
                caseWrapperInstance.initialResponseClass = '';
                caseWrapperInstance.resolutionClass = '';
                

                for(CaseMilestone milestone: eachCase.CaseMilestones)
                {
                    if(milestone.isCompleted)
                    {
                        slaString = '✅';                            
                    }
                    else if(milestone.isViolated)
                    {
                        slaString = 'Miss❗';
                        slaClass = 'slds-text-color_destructive';
                    }
                    else if(milestone.TimeRemainingInMins != null)
                    {
                        slaString = convertMinsToString(Integer.valueOf(milestone.TimeRemainingInMins.split(':')[0]));
                        slaClass = 'slds-text-color_success';
                    }
                    caseWrapperInstance.initialResponseSla = milestone.milestonetype.Name == 'Initial Response'? slaString : caseWrapperInstance.initialResponseSla;
                    caseWrapperInstance.resolutionSla = milestone.milestonetype.Name == 'Resolution'? slaString : caseWrapperInstance.resolutionSla;
                    caseWrapperInstance.initialResponseClass = milestone.milestonetype.Name == 'Initial Response'? slaClass : caseWrapperInstance.initialResponseClass;
                    caseWrapperInstance.resolutionClass = milestone.milestonetype.Name == 'Resolution'? slaClass : caseWrapperInstance.resolutionClass;
                }  
                caseWrapperInstance.externalDependancies =  eachCase.External_Dependencies__r != null ?eachCase.External_Dependencies__r.size() : 0;         
            }
            else if(viewType == 'AllCases')
            {
                caseWrapperInstance.createdDate = eachCase.AKAM_Created_Date__c.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'',UserInfo.getTimeZone().getID());
                system.debug('caseWrapperInstance.createdDate: ' + caseWrapperInstance.createdDate);
                //caseWrapperInstance.createdDate = eachCase.AKAM_Created_Date__c;
                caseWrapperInstance.contactName = eachCase.Contact.Name;   
                caseWrapperInstance.assignEmoji = '✋🏼';
            }
            caseWrappers.add(caseWrapperInstance);
        }
        return caseWrappers;
    }
    
    //Get the ED data
    @AuraEnabled(cacheable=false)
    public static List<EDWrapper> getExternalDependancyList(String caseId)    
    {
        system.debug('caseId: ' + caseId);
        List<EDWrapper> wrappers = new List<EDWrapper>();
        EDWrapper wrapper;
        for(External_Dependency__c eachRec: [Select Id, Name, Case__c,Case__r.Akam_Case_Id__c, 
        Type__c, Id__c, Comment_del__c from External_Dependency__c where Case__c = :caseId])
        {
            wrapper = new EDWrapper();
            wrapper.comments = eachRec.Comment_del__c;
            wrapper.akamCaseId = eachRec.Case__r.Akam_Case_Id__c;
            wrapper.caseUrl = '/' + eachRec.Case__c;
            wrapper.name = eachRec.Name;
            wrapper.url = '/' + eachRec.Id;
            wrapper.typeId = eachRec.Id__c;
            wrapper.type = eachRec.Type__c;

            wrappers.add(wrapper);
        }
        return wrappers;
    }

    //Method to convert mins to string
    public static string convertMinsToString(Integer inputPending)    
    {        
        string displayString = '';
        if(inputPending != null && inputPending != 0)
        {
            Integer days = inputPending/1440;
            Integer daysMod = Math.mod(inputPending, 1440);
            Integer hours = daysMod/60;
            Integer mins = Math.mod(daysMod,60);    
            
            displayString = days + 'd '+ hours + 'h ' + mins + 'm';    
        }
        
        return displayString;
    }

    //Assign to case user method
    @AuraEnabled
    public static string assignCaseToUser(string caseId)
    {
        String loggedInUser = UserInfo.getUserId();
        
        try
        {
            case updateowner = new case(id=caseId,ownerid=loggedInUser);
            update updateowner;
            return 'true';
        }
        catch (exception e)
        {
            return e.getMessage();
        }
        
    }

    //return Navigation data
    @AuraEnabled
    public static List<CaseSummaryWrapper> getNotificationDetails(String dateFilter,String viewName)
    {

        List<CaseSummaryWrapper> caseSummaryWrappers = new List<CaseSummaryWrapper>();
        CaseSummaryWrapper caseSummaryWrapperObject;
        String dateFilterString = dateFilter == 'Month' ? 'createddate = THIS_MONTH' : 
                                  dateFilter == 'Quarter' ? 'createddate = THIS_QUARTER' : 
                                  'createddate = THIS_YEAR';
        List<String> queueIds = new List<String>();

        String loggedInUser = UserInfo.getUserId();

        String caseWhereClause = ' from Case where RecordType.Name = \'Billing\' and isClosed = False' ;
        String caseQuery = 'Select Id, Akam_Case_Id__c';
        String milestoneName;
        Date yesterday = Date.today().addDays(-1);
        Date today = Date.today();

        if(viewName.startsWith('unassigned'))
        {
            for (SC_Utility__mdt billingQueueRec : [Select Value__c,developername from SC_Utility__mdt where 
            Active__c = true and developername like 'BillingQueues%'])
            {
                if(billingQueueRec.Value__c != null)
                {
                    queueIds.addAll(billingQueueRec.Value__c.split(','));
                }
                
            }
            caseWhereClause += ' and OwnerId in :queueIds and ';    
            if(viewName == 'unassigned24')
            {
                caseWhereClause += ' createddate < :yesterday and ';
            }
        }
        else
        {
            milestoneName = viewName == 'IR' ? 'Initial Response' : 'Resolution';
            caseQuery += ',(select milestonetype.Name from CaseMilestones where milestonetype.Name = :milestoneName and isviolated = true)';            
            caseWhereClause += ' and OwnerId = :loggedInUser and ';    
        }


        caseWhereClause += dateFilterString;
        caseQuery += caseWhereClause;
        List <Case> caseRecs = Database.query(caseQuery);

        for(Case caseRec: caseRecs)
        {
            if(!(!viewName.startsWith('unassigned') && (caseRec.CaseMilestones == null || caseRec.CaseMilestones.size() == 0)))
            {
                caseSummaryWrapperObject = new CaseSummaryWrapper(caseRec.Akam_Case_Id__c, '/' + caseRec.Id
                ,'Go to Case ' + caseRec.Akam_Case_Id__c);        
                caseSummaryWrappers.add(caseSummaryWrapperObject);
    
            }
    
        }        

        return caseSummaryWrappers;

    }

    //Return the Summary dashboard data
    @AuraEnabled
    public static SummaryDataWrapper getSummary(String dateFilter)
    {

        SummaryDataWrapper summaryDataWrapperObject = new SummaryDataWrapper();
        CaseSummaryWrapper caseSummaryWrapperObject;
        String dateFilterString = dateFilter == 'Month' ? 'createddate = THIS_MONTH' : 
                                  dateFilter == 'Quarter' ? 'createddate = THIS_QUARTER' : 
                                  'createddate = THIS_YEAR';
        List<String> queueIds = new List<String>();


        String loggedInUser = UserInfo.getUserId();

        for (SC_Utility__mdt billingQueueRec : [Select Value__c,developername from SC_Utility__mdt where 
        Active__c = true and developername like 'BillingQueues%'])
        {
            if(billingQueueRec.Value__c != null)
            {
                queueIds.addAll(billingQueueRec.Value__c.split(','));
            }
            
        }

        Date yesterday = Date.today().addDays(-1);
        Date today = Date.today();

        String caseQuery = 'Select Id, Akam_Case_Id__c, OwnerId,createddate, isClosed';
        caseQuery += ',(select milestonetype.Name from CaseMilestones where milestonetype.Name IN (\'Initial Response\', \'Resolution\') and isviolated = true)';
        caseQuery += ' from Case where RecordType.Name = \'Billing\'';
        caseQuery += ' and ((OwnerId in :queueIds and isClosed = False) or OwnerId = :loggedInUser) and ';
        caseQuery += dateFilterString;

        system.debug('The queueIds: ' + queueIds);        

        List <Case> caseRecs = Database.query(caseQuery);

        for(Case caseRec: caseRecs)
        {
            if(!String.valueOf(caseRec.OwnerId).startsWith('005') )
            {
                summaryDataWrapperObject.inQueue++;
                if(caseRec.createddate < yesterday)
                {
                    summaryDataWrapperObject.inQueue24++;
                }
            }
            else if(caseRec.isClosed)
            {
                summaryDataWrapperObject.closed++;
            }
            else 
            {
                summaryDataWrapperObject.open++;
                if(caseRec.CaseMilestones != null)
                {
                    caseSummaryWrapperObject = new CaseSummaryWrapper(caseRec.Akam_Case_Id__c, '/' + caseRec.Id
                ,'Go to Case ' + caseRec.Akam_Case_Id__c);
                    for(CaseMilestone milestoneRec: caseRec.CaseMilestones)
                    {
                        if(milestoneRec.milestonetype.Name == 'Initial Response')
                        {
                            summaryDataWrapperObject.irMiss++;
                        }
                        else if(milestoneRec.milestonetype.Name == 'Resolution')
                        {
                            summaryDataWrapperObject.resMiss++;
                        }
                    }
                }
            }

        }
    
        return summaryDataWrapperObject;
    }

    //upDate case data
    @AuraEnabled
    public static string updateCases(String caseIds,String jsonBody)
    {        
        system.debug('caseIds: ' + caseIds+ ' jsonBody: ' + jsonBody);
        List<Case> cases = new List<Case>();
        Case newCase;
        Map<String,String> params = (Map<String,String>) JSON.deserialize(jsonBody, Map<String,String>.class);
        if(params.size() == 1 && params.get('OwnerId') == 'Cash Apps')
        {
            Group cashApps = [select id from group where name = 'Cash Apps' and type = 'Queue' limit 1];
            params.put('OwnerId',cashApps.Id);                         
        }
        List<Database.SaveResult> results;
        String error = '';
        List<Id> failedIds = new List<Id>();

        for(String caseId: caseIds.split(','))
        {   
            newCase = new Case();
            newCase.Id = caseId;
            for(String key: params.keySet())
            {
                if(!String.isBlank(params.get(key)))
                {
                    newCase.put(key,params.get(key));
                }
                
            }
            cases.add(newCase);
        }
        results = Database.update(cases,false);
        Database.SaveResult sr;
        for(Integer i = 0; results != null && cases != null &&  i < results.size(); i++)
        {
            sr = results.get(i);
            if (!sr.isSuccess()) 
            {
                for(Database.Error err : sr.getErrors()) 
                {

                    error += cases.get(i).id + ': '+  renderUserfriendlyError(err.getMessage()) + '\n' ;
                }
                failedIds.add(cases.get(i).id);
            }

        }            

        Map<String,String> resultMap = new Map<String,String>();
        resultMap.put('error',error);
        resultMap.put('failedIds',JSON.serialize(failedIds));
        return JSON.serialize(resultMap);
    }

    //get case Billing record type
    @AuraEnabled
    public static List<RecordTypeWrapper> getRecordTypes()
    {
        List<RecordTypeWrapper> wrappers = new List<RecordTypeWrapper>();
        RecordTypeWrapper wrapper;
        for(RecordType rec: [Select Id, Name from RecordType where SobjectType = 'Case' and Name = 'Billing'])
        {
            wrapper = new RecordTypeWrapper(rec.Name,rec.Id);
            wrappers.add(wrapper);
        }
        return wrappers;
    }

    //rerender user friendly message
    public static String renderUserfriendlyError(String exceptionMessage)
    {
        if(!String.isBlank(exceptionMessage) && exceptionMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION, '))
        {
            exceptionMessage = exceptionMessage.split('FIELD_CUSTOM_VALIDATION_EXCEPTION, ')[1];
        }
        return exceptionMessage;
    }
}