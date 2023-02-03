/***
    CS_PopulateMaster
    @version 1.0
    @author Jayalakshmi Anantharaman (janantha@akamai.com)
    @date 01/03/2010
    @Description : This trigger is called on 'before insert' events on the SurveyResponse-NameValue object.
                   It takes care of the following :
                   - Populating the Survey Response Id of the Survey Response Name Value records.    
    @Modified Date: CR 1115769 
    19th May 2011 for handling the case if two survey responses are created with the same created date and time.           
*/ 

trigger CS_PopulateMasterTrigger on CS_SurveyResponseNameValue__c (before insert) 
{
    String objectType = 'SurveyResponseNameValue';
    DateTime latestSurveyRecord;
    CS_SurveyException__c surveyException = new CS_SurveyException__c();
    //start of changes for CR 1115769 
    List<CS_SurveyResponse__c> surveyResponse = new List<CS_SurveyResponse__c>();
    //end of changes for CR 1115769
    Id id;
    
    try
    {
        //start of changes for CR 1115769
        surveyResponse = [select Id, CreatedDate from CS_SurveyResponse__c where (CS_SyncStatus__c='New' and CS_isDeleted__c=false) order by CreatedDate DESC limit 2];
        if(surveyResponse.size()>1)
        {
            DateTime t1 = surveyResponse[0].CreatedDate;
            DateTime t2 = surveyResponse[1].CreatedDate;
        
            if(t1 == t2)
            {
                CS_SurveyException__c surveyException1 = new CS_SurveyException__c();
                surveyException1.CS_ExceptionInObject__c = 'Survey Response Name-Value';
                surveyException1.CS_ExceptionMessage__c = 'Possible failure detected due to multiple candidates of survey responses with the same created dates '+'['+surveyResponse[0].Id+','+surveyResponse[1].Id+']';
                insert surveyException1;
            }
        }       
        id = surveyResponse[0].Id;
        //end of changes for CR 1115769
        Integer i = 0;
        Integer j = 0;
        if(trigger.new[i].CS_SurveyResponse__c==null)
        {
            for(j=0;j<trigger.new.size();j++)
            {
              trigger.new[j].CS_SurveyResponse__c = id;
            }
        }  
    }
    catch(Exception e)
    {
        surveyException.CS_ExceptionMessage__c = 'Error in trigger populate Master '+e.getMessage();
        surveyException.CS_ExceptionInObject__c = 'Survey Response Name-Value';
        surveyException.CS_SurveyResponse__c = id;
        insert surveyException;
    }  
}