/*
************************************************************************************************************
Author              :   Vikas R
Created             :   19-April-2022
Purpose             :   Controller for BOCC Dashboard
JIRA Story          :   ESESP-6534 :: BOCC Dashboard
Test Class          :   

@History
--Developer           --Date            --Change
Vikas				19-Apr-2022			ESESP-6534 : Initial Development

************************************************************************************************************
*/
public with sharing class SC_BOCCDashboard_Controller {
    public class CaseWrapper
    {
        @AuraEnabled public Case caseRec;
        @AuraEnabled public Id caseId;
        @AuraEnabled public String akamCaseId;
        @AuraEnabled public String accountName;
        @AuraEnabled public String caseSubject;
        @AuraEnabled public String caseBoccSupportType;
        @AuraEnabled public String caseStatus;
        @AuraEnabled public String caseWorkType;
        @AuraEnabled public String caseSeverity;
        @AuraEnabled public String caseOwnerName;
        @AuraEnabled public DateTime caseLastUpdatedDate;
        @AuraEnabled public String caseLastUpdatedDateTimeString;
        @AuraEnabled public String caseLastUpdatedBy;
        @AuraEnabled public Boolean hasTransition;
        @AuraEnabled public String hasTransitionText;
        @AuraEnabled public String caseColour;
        
        @AuraEnabled public String caseUrl;
        @AuraEnabled public String accountUrl;
        @AuraEnabled public String caseLastUpdatedByUrl;
        @AuraEnabled public String caseOwnerNameUrl;
    }
    @AuraEnabled
    public static List<CaseWrapper> fetchCaseList(String caseWorkType, String caseSeverity){
        List<CaseWrapper> caseWrapperList = new List<CaseWrapper>();
        List<Case> lstTransitionCase = new List<Case>();
        List<Case> lstCase = new List<Case>();
        Map<Id,Case_Transition__c> caseIdTransitionMap = new Map<Id,Case_Transition__c>();
        String workTypeQuery = '';
        String sevQuery = '';
        String orderByQuery = ' ORDER BY CreatedDate DESC';
        CaseWrapper caseWrap = new CaseWrapper();   
        Map<String,String> mapSCUtilMDTVal = new Map<String,String>();
        List<SC_Utility__mdt> lstSCUtilMDT = [SELECT DeveloperName,Value_Text__c FROM SC_Utility__mdt WHERE DeveloperName IN ('BOCC_Queue_ID','BOCC_Transition_Queue_ID')];
        
        for(SC_Utility__mdt eachRec : lstSCUtilMDT)
        {
            mapSCUtilMDTVal.put(eachRec.DeveloperName,eachRec.Value_Text__c);
        }
        
        String caseQuery = 'SELECT id,AKAM_Case_ID__c,AccountId,Account.Name,Subject, BOCC_Support_Type__c, Status, Work_Type__c,'
            + ' Severity__c, owner.Name, LastModifiedDate, LastModifiedBy.Name,Last_Case_Update__c,Last_Customer_Activity_Date__c,CreatedDate,ContactId from case'
            + ' WHERE RecordType.Name = \'Technical\' AND Sub_Type__c = \'BOCC\' AND'
            + ' Status != \'Closed\' AND Status != \'Invalid\'';
        
        if(!caseWorkType.equalsIgnoreCase('Reactive,Proactive')) 
        {
            List<String> WTVals = caseWorkType.split(',');
            workTypeQuery = ' AND Work_Type__c IN :WTVals';
        }
        if(!caseSeverity.equalsIgnoreCase('1,2,3')) 
        {
            List<String> sevVals = caseSeverity.split(',');
            sevQuery = ' AND Severity__c IN :sevVals';
        }
        caseQuery += workTypeQuery + sevQuery + orderByQuery;
        lstCase = Database.query(caseQuery);
        
        for(Case eachCase : lstCase){
            if(mapSCUtilMDTVal.values().contains(eachCase.ownerId) && eachCase.Status == 'Unassigned'){
                lstTransitionCase.add(eachCase);
            }
        }
        List<Case_Transition__c > caseTransitionList = [Select id,Case__c,completed__c from Case_Transition__c where Case__c in:(lstTransitionCase) AND completed__c != true];
        for(Case_Transition__c eachTransition : caseTransitionList){
            caseIdTransitionMap.put(eachTransition.Case__c, eachTransition);
        }
        for(Case eachCase : lstCase){
            caseWrap = new CaseWrapper();   
            caseWrap.caseRec = eachCase;
            caseWrap.caseUrl = '/lightning/r/Case/' + eachCase.Id + '/view';
            caseWrap.accountUrl = '/lightning/r/Account/' + eachCase.AccountId + '/view';
            caseWrap.caseOwnerNameUrl = '/lightning/r/User/' + eachCase.OwnerId + '/view';
            caseWrap.caseLastUpdatedByUrl = '/lightning/r/User/' + eachCase.LastModifiedById + '/view';
            
            caseWrap.caseId = eachCase.id;
            caseWrap.akamCaseId = eachCase.AKAM_Case_ID__c;
            caseWrap.accountName = eachCase.Account.Name;
            caseWrap.caseSubject = eachCase.Subject;
            caseWrap.caseBoccSupportType = eachCase.BOCC_Support_Type__c;
            caseWrap.caseStatus = eachCase.Status;
            caseWrap.caseWorkType = eachCase.Work_Type__c;
            caseWrap.caseSeverity = eachCase.Severity__c;
            caseWrap.caseOwnerName = eachCase.Owner.Name;
            caseWrap.caseLastUpdatedDate = eachCase.LastModifiedDate;
            caseWrap.caseLastUpdatedBy = eachCase.LastModifiedBy.Name;
            caseWrap.caseLastUpdatedDateTimeString = '';
            
            Integer min = Integer.valueOf((DateTime.now().getTime() - eachCase.LastModifiedDate.getTime())/1000/60);
            if(min/24/60 > 0)
                caseWrap.caseLastUpdatedDateTimeString += min/24/60 + 'd ';
            if(Math.mod(min/60,24) > 0)
                caseWrap.caseLastUpdatedDateTimeString += Math.mod(min/60,24) + 'h ';
            if(Math.mod(min,60) > 0)
                caseWrap.caseLastUpdatedDateTimeString += Math.mod(min,60) + 'm ';
            if(String.isNotBlank(caseWrap.caseLastUpdatedDateTimeString))
            {
                caseWrap.caseLastUpdatedDateTimeString += 'ago';
            }

            caseWrap.caseColour = 'blue';
            if(String.isNotBlank(String.valueOf(eachCase.Last_Customer_Activity_Date__c)) 
               && (String.isBlank(String.valueOf(eachCase.Last_Case_Update__c)) 
                   || (String.isNotBlank(String.valueOf(eachCase.Last_Case_Update__c)) && eachCase.Last_Case_Update__c <= eachCase.Last_Customer_Activity_Date__c))
              )
            {
                caseWrap.caseColour = 'yellow';
                caseWrap.caseLastUpdatedBy = 'Customer';
                caseWrap.caseLastUpdatedByUrl = '/lightning/r/Contact/' + eachCase.ContactId + '/view';
            }
            if(eachCase.CreatedDate.addMinutes(15) < system.now() && eachCase.Last_Case_Update__c == null){
                caseWrap.caseColour = 'red';
            }
            if(eachCase.Status == 'Unassigned' && mapSCUtilMDTVal.values().contains(eachCase.ownerId)){
                caseWrap.caseColour = 'white';
                if(caseIdTransitionMap.get(eachCase.Id) != null){
                    caseWrap.hasTransition = true;
                    caseWrap.hasTransitionText = 'utility:priority';
                }
            }
            caseWrapperList.add(caseWrap);
        }
        return caseWrapperList;
    }
    
    //SUMMARY DASHBOARD : SAVE FILTERS
    @AuraEnabled
    public static Map<String,String> saveBOCCFilters(String filterToSave)
    {
        Map<String,String> savedFilterVal = new Map<String,String>();
        String rectypeid = SC_User_Filter__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('BOCC').getRecordTypeId();
        String uniqueid = userinfo.getUserId()+'-'+rectypeid;
        String selectAll = 'CaseWorkType:Reactive,Proactive&CaseSeverity:1,2,3';
        List<SC_User_Filter__c> filter = new List<SC_User_Filter__c>();
        
        savedFilterVal.put('CaseWorkType','Reactive,Proactive');
        savedFilterVal.put('CaseSeverity','1,2,3');
        
        filter = [SELECT Unique_ID__c ,Filter_Values__c  FROM SC_User_Filter__c WHERE Unique_ID__c = :uniqueid limit 1];
        if(filter.size() == 0)
        {
            SC_User_Filter__c newrow = new SC_User_Filter__c(Filter_Values__c = selectAll,Unique_ID__c = uniqueid, recordtypeid=rectypeid);
            upsert newrow;
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