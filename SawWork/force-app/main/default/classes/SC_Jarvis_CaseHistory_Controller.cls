/* 
Author          : Sharath P 
Description     : Controller for JARVIS Case History

WARNING : THIS IS A CUSTOMER FACING APEX CLASS. PLEASE PERFORM ALL CODE REVIEWS WITH REQUIRED TEAM MEMBERS BEFORE
DEPLOYING CODE TO PRODUCTION.

Date                    Developer                   JIRA #                      Description                                                       
------------------------------------------------------------------------------------------------------------------
14 June 2021                Authors                                           Initial Development
------------------------------------------------------------------------------------------------------------------
*/


public without sharing class SC_Jarvis_CaseHistory_Controller 
{
    public SC_Jarvis_CaseHistory_Controller() 
    {

    }

    public class CaseHistoryWrapper implements Comparable
    {
        //@AuraEnabled public String fieldLabel {get;set;}
        @AuraEnabled public String action {get;set;}
        @AuraEnabled public String id {get;set;}
        @AuraEnabled public String actionTime {get;set;}
        @AuraEnabled public DateTime actionDateValue {get;set;}
        @AuraEnabled public String user {get;set;}
        public CaseHistoryWrapper(String keyId,String actionString, String actionDateTime, String username,
        DateTime actionDateValue)
        {
            id=keyId;
            action =actionString;
            actionTime = actionDateTime;
            user = username;
            this.actionDateValue = actionDateValue;
        }
        public Integer compareTo(Object compareTo) 
        {
            CaseHistoryWrapper historyRec = (CaseHistoryWrapper) compareTo;
            return actionDateValue == historyRec.actionDateValue ? 0 :
            actionDateValue < historyRec.actionDateValue? 1 :
                    -1;
        }
    }


    public static String addBoldHtml(Object input)
    {
        return '<b>'+input+'</b>';
    }

    public static List<CaseHistoryWrapper> slice(List<CaseHistoryWrapper> input, Integer fromIndex, Integer offset)
    {
        List<CaseHistoryWrapper> output = new List<CaseHistoryWrapper>();
        if(input != null && input.size() > fromIndex)
        {
            for (Integer index = fromIndex; index < (fromIndex+offset) && index < input.size(); index++)
            {
                output.add(input.get(index));
            }
        }
        return output;
    }

    public static String getCurrentAction(String oldValueString, String newValueString, String fieldLabel)
    {
        String action = oldValueString == '' && newValueString == '' ? 
        'Changed ' + addBoldHtml(fieldLabel):
        oldValueString == '' ? 'Changed ' + addBoldHtml(fieldLabel) + ' to ' + addBoldHtml(newValueString):
        newValueString == '' ? 'Deleted ' + addBoldHtml(oldValueString) + ' in ' + addBoldHtml(fieldLabel):
        'Changed ' + addBoldHtml(fieldLabel) + ' from ' +  addBoldHtml(oldValueString) + ' to ' + addBoldHtml(newValueString);    
        return action;    
    }

    @AuraEnabled
    public static List<CaseHistoryWrapper> getHistoryWrapper (String caseId, Integer currentCount, Integer offset)
    {
        CaseHistoryWrapper caseWrapper;
        List<CaseHistoryWrapper> wrappers = new List<CaseHistoryWrapper>();
        List<Case> caserec = [select recordType.Name,Sub_Type__c,AccountId from case where id = :caseId];
        if(caserec.size() == 1)
        {
            List<String> filters= new List<String>{caserec.get(0).recordType.Name + ':' + 'Custom',
            caserec.get(0).recordType.Name + ':' + 'Standard'};
            Set<String> customFields = new Set<String>();
            Set<String> standardFields = new Set<String>();
            Map<String,String> fieldToLabel = new Map<String,String>();
            
            for (SC_Utility__mdt metadataRec : [Select Value__c, Value_Text__c from SC_Utility__mdt where Active__c = true 
            and Value_Text__c in :filters and DeveloperName like 'JarvisCaseHistory%'])
            {
                //if(metadataRec.Value_Text__c.contains('Standard'))
                {
                    for(String field : metadataRec.Value__c.split(','))
                    {
                        if(metadataRec.Value_Text__c.contains('Standard'))
                        {
                            standardFields.add(field.split(':').get(0));    
                        }
                        else
                        {
                            customFields.add(field.split(':').get(0)); 
                        }
                        fieldToLabel.put(field.split(':').get(0),field.split(':').get(1));
                    }
                }
                
            }

            String action;
            String actionUser;
            String newValue;
            String oldValue;
            Id oldId;
            Id newId;
            for(CaseHistory history : [select id,oldvalue,newvalue,field, createddate, createdby.name,createdby.profile.Name from casehistory 
            where field in :standardFields and caseid = :caseId order by createddate desc])
            {
                try
                {
                    oldId = history.oldvalue != null? Id.valueOf(String.valueOf(history.oldvalue)) : null;
                }
                catch(Exception e)
                {
                }
                try
                {
                    newId = history.newValue != null? Id.valueOf(String.valueOf(history.newValue)) : null;
                }
                catch(Exception e)
                {
                }
                if(oldId == null && newId == null)
                {
                    String oldValueString = history.oldValue != null ? 
                    String.valueOf(history.oldValue) : '';
                    String newValueString = history.newValue != null ?
                    String.valueOf(history.newValue): '';
                    
                    if(history.field == 'Status')
                    {
                        oldValueString = oldValueString != ''?
                        SC_Jarvis_utility.getStatusValue(oldValueString):
                        oldValueString;
                        newValueString = newValueString != ''?
                        SC_Jarvis_utility.getStatusValue(newValueString):
                        newValueString;
                    }
                    else if((history.field == 'ownerAssignment' || history.field == 'Owner'))
                    {
                        oldValueString = oldValueString.containsIgnoreCase('queue') || oldValueString.containsIgnoreCase('_') ?
                        'In Queue' : oldValueString;
                        newValueString = newValueString.containsIgnoreCase('queue') || newValueString.containsIgnoreCase('_') ?
                        'In Queue' : newValueString;

                    }                     
                    else if(history.field == 'Severity__c' )
                    {
                        oldValueString = oldValueString != '' ?
                        SC_Jarvis_utility.getSeverityValuesCorrespondingToCase(caserec.get(0).RecordType.Name,caserec.get(0).Sub_Type__c,
                        caserec.get(0).AccountId,oldValueString):
                        oldValueString;

                        newValueString = newValueString != ''? 
                        SC_Jarvis_utility.getSeverityValuesCorrespondingToCase(caserec.get(0).RecordType.Name,caserec.get(0).Sub_Type__c,
                        caserec.get(0).AccountId,newValueString):
                        newValueString;

                    }

                    String fieldLabel = history.field == 'ownerAssignment' || history.field == 'Owner' ?
                    fieldToLabel.get('ownerAssignment') : fieldToLabel.get(history.field);

                    try
                    {

                        if(!
                            (history.field == 'Severity__c' && 
                            oldValueString != '' && 
                            newValueString != '' && 
                            (oldValueString.startsWith(newValueString) 
                            || oldValueString == newValueString))
                        )
                        {
                            action = getCurrentAction(oldValueString,newValueString,fieldToLabel.get(history.field));
                        }

                    }
                    catch(Exception e)
                    {
                        action = getCurrentAction(oldValueString,newValueString,fieldToLabel.get(history.field));
                    }
                                  
                    actionUser = history.createdby.profile.Name == 'SFCommunityCustomers'? history.createdby.name + ' (Customer)' : history.createdby.name + ' (Akamai)';
                    caseWrapper = new CaseHistoryWrapper(history.id,action, history.createddate.format(), actionUser,history.createddate);
                    wrappers.add(caseWrapper);

                }
                oldId = null;
                newId = null;
            }
            for(Case_History_Custom__c history : [select Field__c,New_Value__c,Original_Value__c,createddate, 
            createdby.name,createdby.profile.Name from Case_History_Custom__c where Field__c in :customFields and case__c = :caseId
            order by createddate desc])
            {
                String oldValueString = history.Original_Value__c == null? '':
                String.valueOf(history.Original_Value__c);
                
                String newValueString = history.New_Value__c == null? '':
                String.valueOf(history.New_Value__c);

                action = getCurrentAction(oldValueString,newValueString,fieldToLabel.get(history.Field__c));
                
                actionUser = history.createdby.profile.Name == 'SFCommunityCustomers'? history.createdby.name + ' (Customer)' : history.createdby.name + ' (Akamai)';
                caseWrapper = new CaseHistoryWrapper(history.id,action, history.createddate.format(), actionUser,history.createddate);
                wrappers.add(caseWrapper);
            }

        }
        if(wrappers.size() > currentCount)
        {
            wrappers.sort();            
            List<CaseHistoryWrapper> slicedList = (List<CaseHistoryWrapper>) slice(wrappers,currentCount,offset);
            system.debug('wrappers: ' + wrappers.size() + ' slicedList: ' + slicedList.size() + ' currentCount: ' + currentCount
            + ' offset: ' + offset);
            return slicedList;            
        }
        return null;
    }

}