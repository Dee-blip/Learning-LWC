global class CastIronIntegrationWebservice {
    
    public static Map<String, Schema.SObjectType> allObjectsMap = Schema.getGlobalDescribe();
    public static Boolean isCreatedDateToUse=false;
    public static Boolean isLastModifiedDateToUse=false; 
    
    webservice static List<CIResponseWrapperClass> getObjectRecords(List<String> ObjectNameList,DateTime defaultPollStartTime,String ProjectName,String configurationName,String routerHostName,String environment)
    {
        List<CIResponseWrapperClass> responseList=new List<CIResponseWrapperClass>();
        List<CastIron_Polling__c> castIronPollingList=[select orchkey__c,PollRangeToTime__c from CastIron_Polling__c where orchkey__c like 'SalesforceEDWSync%'];
        Map<String,DateTime> orchKeyToPollTimeMap=new Map<String,DateTime>();
        Integer totalRecordCount=0;
        for(CastIron_Polling__c cip: castIronPollingList)
        {
            orchKeyToPollTimeMap.put(cip.orchkey__c,cip.PollRangeToTime__c);
        }
        for(String ObjectName : ObjectNameList)
        {
            isCreatedDateToUse=false;
            isLastModifiedDateToUse=false;
            String orchKey=ProjectName+'_'+configurationName+'_'+ObjectName;
            
            if(environment!='Production')
            orchKey=orchKey+'_'+routerHostName;
            
            DateTime pollStartTime=orchKeyToPollTimeMap.get(orchKey);
            if(pollStartTime==null)
            {
                pollStartTime=defaultPollStartTime;
            }
            DateTime pollEndTime=pollStartTime;
            List<Sobject> objectRecordsList=null;
            CIResponseWrapperClass response=null;
            try
            {
              if(totalRecordCount < 25000)
              {              
              objectRecordsList=getObjectRecords(ObjectName,pollStartTime,false);
               if(objectRecordsList!=null && objectRecordsList.size()>0)
               {
                pollEndTime=getPollEndTime(objectRecordsList);
                if(objectRecordsList.size() > 25000)
                {
                    throw new CustomException('More than 25000 rows returned for Object '+ObjectName+ '. Please use Bulk option.');
                }
                if(totalRecordCount+objectRecordsList.size() >25000)
                {
                    throw new CustomException('Total records returned for processed Objects is more than 25000. Please make another call for rest of the objects.');
                }
                totalRecordCount=totalRecordCount+objectRecordsList.size();
               }
              }
              else
              {
                throw new CustomException('25000 records are already retrieved for processed objects. Please make another call for rest of the objects.');
              }
            response=new CIResponseWrapperClass(objectName,objectRecordsList,'Success',null,pollStartTime,pollEndTime,true);
            }
            catch(Exception e)
            {
             response=new CIResponseWrapperClass(objectName,null,'Error',e.getMessage(),pollStartTime,pollEndTime,true);
            }
            
            responseList.add(response);
            
       }
        return responseList;
    }
    
    webservice static CIResponseWrapperClass getObjectBulkUpdates(String ObjectName, DateTime pollStartTime)
    {
        CIResponseWrapperClass response=null;
        List<Sobject> queriedObjectList=null;
        DateTime nextPollTime=null;
        List<Sobject> objectList=new List<Sobject>();
        DateTime maxEndPollTime=null;
        DateTime endTime=null;
        isCreatedDateToUse=false;
        isLastModifiedDateToUse=false;
        try
        {
            queriedObjectList=getObjectRecords(ObjectName,pollStartTime,true);
            maxEndPollTime=getMaxEndTime(ObjectName);
            if(queriedObjectList!=null && queriedObjectList.size()>0)
              endTime=getPollEndTime(queriedObjectList);
        
            for(Sobject obj: queriedObjectList)
            {   if((!isCreatedDateToUse && !isLastModifiedDateToUse && endTime > (DateTime)obj.get('SystemModStamp')) 
                   || (isCreatedDateToUse && endTime > (DateTime)obj.get('CreatedDate')) 
                   || (isLastModifiedDateToUse && endTime > (DateTime)obj.get('LastModifiedDate'))) 
                  objectList.add(obj);
                else if(endTime ==maxEndPollTime  
                        &&((!isCreatedDateToUse && !isLastModifiedDateToUse  && endTime==(DateTime)obj.get('SystemModStamp')) 
                           || (isCreatedDateToUse && endTime==(DateTime)obj.get('CreatedDate'))
                           || (isLastModifiedDateToUse && endTime==(DateTime)obj.get('LastModifiedDate'))
                           ))
                  objectList.add(obj);  
            }
            if(objectList.size()>0)
              nextPollTime=getPollEndTime(objectList);
        
            if(maxEndPollTime == endTime)
            response=new CIResponseWrapperClass(ObjectName,objectList,'Success',null,pollStartTime,nextPollTime,true);
            else
            response=new CIResponseWrapperClass(ObjectName,objectList,'Success',null,pollStartTime,nextPollTime,false);
        }
        catch(Exception e)
        {
            response=new CIResponseWrapperClass(ObjectName,objectList,'Error',e.getMessage(),pollStartTime,nextPollTime,true);  
        }
        return response;
         
    }
    
    Webservice static CIResponseWrapperClass getSingleObjectUpdatedRecords(String ObjectName, DateTime pollStartTime)
    {
        CIResponseWrapperClass response=null;
        List<Sobject> objectList=null;
        DateTime pollEndTime=null;
        isCreatedDateToUse=false;
        isLastModifiedDateToUse=false;
        try
        {
            objectList=getObjectRecords(ObjectName,pollStartTime,false);
            if(objectList!=null && objectList.size()>0)
            {
                pollEndTime=getPollEndTime(objectList);
                response=new CIResponseWrapperClass(ObjectName,objectList,'Success',null,pollStartTime,pollEndTime,true);
            }

      //JIRA Issue - SFDC 194 - sganesan: adding an else block so that this web method doesn't return null if objectList is null
            else
            {
              response=new CIResponseWrapperClass(ObjectName,objectList,'Success',null,pollStartTime,pollStartTime,true);
            }
        }
        catch(Exception e)
        {
            response=new CIResponseWrapperClass(ObjectName,objectList,'Error',e.getMessage(),pollStartTime,pollEndTime,true);
        }
        return response;
    }
    
    public static List<Sobject> getObjectRecords(String ObjectName,DateTime pollStartTime,Boolean isBulkUpdate)
    {
        List<Sobject> objectList=null;
        try
        {
         objectList=Database.query(generateSOQLQuery(ObjectName,pollStartTime,isBulkUpdate));
        }
        catch(Exception e)
        {
            if(e.getMessage().contains('No such column \'SystemModStamp\' on entity'))
                {
                    isCreatedDateToUse=true;
                    try
                    {
                    objectList=Database.query(generateSOQLQuery(ObjectName,pollStartTime,isBulkUpdate));
                    }
                    catch(Exception exc)
                    {
                      if(exc.getMessage().contains('No such column \'CreatedDate\' on entity'))
                        {
                          isLastModifiedDateToUse=true;
                          isCreatedDateToUse=false;
                          objectList=Database.query(generateSOQLQuery(ObjectName,pollStartTime,isBulkUpdate));
                        }
                        else throw exc;
                    }
                }
             else throw e;
        }
        return objectList;
    }
    
    public static DateTime getMaxEndTime(String ObjectName) 
    {
        DateTime maxPollEndTime=null;
        List<Sobject> objList=null;
        String soql='';
        if(!isCreatedDateToUse && !isLastModifiedDateToUse)
        soql='select SystemModStamp from '+ ObjectName+ ' Order By SystemModStamp DESC Limit 1';
        else if(isCreatedDateToUse)
        soql='select CreatedDate from '+ ObjectName+ ' Order By CreatedDate DESC Limit 1';
        else 
        soql='select LastModifiedDate from '+ ObjectName+ ' Order By LastModifiedDate DESC Limit 1';
        
        objList=Database.query(soql);
             for(Sobject obj: objList)
            {
                if(!isCreatedDateToUse && !isLastModifiedDateToUse)
                maxPollEndTime=(DateTime)obj.get('SystemModStamp');
                else if(isCreatedDateToUse)
                maxPollEndTime=(DateTime)obj.get('CreatedDate');
                else 
                maxPollEndTime=(DateTime)obj.get('LastModifiedDate');
            }
        return maxPollEndTime;
    }
    
    public static DateTime getPollEndTime(List<Sobject> objList)
    {
        DateTime endDateTime=null;
        if(!isCreatedDateToUse && !isLastModifiedDateToUse)
        endDateTime=(DateTime)objList[objList.size()-1].get('SystemModStamp');
        else if(isCreatedDateToUse)
        endDateTime=(DateTime)objList[objList.size()-1].get('CreatedDate');
        else 
        endDateTime=(DateTime)objList[objList.size()-1].get('LastModifiedDate');
       return endDateTime;
    }
    
   /* public static DateTime getLastModifiedTime(Sobject obj)
    {
        DateTime lastModifiedDateTime=null;
        try
        {
            lastModifiedDateTime=(DateTime)obj.get('SystemModStamp');
        }
        catch(Exception e)
        {
            if(e.getMessage().contains('Invalid field SystemModStamp for'))
            {
                lastModifiedDateTime=(DateTime)obj.get('CreatedDate');
            }
            else throw e;
        }   
        return lastModifiedDateTime;
    }*/
    public static String dateTimeToString(DateTime dt)
    {
        String dateTimeString=dt+'';
        dateTimeString=dateTimeString.replace(' ', 'T')+'Z';
        return dateTimeString;
    }

    public static String generateSOQLQuery(String ObjectName,DateTime pollStartTime,Boolean isBulkUpdate)
    {
        String soql='select Id,SystemModStamp from '+ObjectName;
        //Start of changes by Sharath Prasanna: for CR 3662133 - Subtracting 2 minutes as fix for Timecard record sync issue
        Set<String> PSAObjectNames = new Set<String>();
        PSA_Settings__c psaSetting = PSA_Settings__c.getInstance('CastIronPSAObjectList');
        if (psaSetting != null)
        {
          //PSAObjectNames.addAll(PSA_Settings__c.getInstance('CastIronPSAObjectList').Value__c.split(','));
          for (string currentObjectName: psaSetting.Value__c.split(','))
          {
              PSAObjectNames.add(currentObjectName.trim());
          }  
        }
        
        //End of changes by Sharath
        if(pollStartTime != null) 
        {
      // JIRA issue - CI-57 - sganesan - Subtracting 2 minutes as fix for RSM Data Exceptions
          Integer subtractMinutes = 0;
          if(ObjectName == 'Opportunity')
          {
            subtractMinutes = Integer.valueOf((GSM_Custom_Settings__c.getInstance('CastIronWebService#SubtractMinutes').Value__c).trim());
          }
          //Start of changes by Sharath Prasanna: for CR 3662133 - Subtracting 2 minutes as fix for Timecard record sync issue
          else if(PSAObjectNames.contains(ObjectName))
          {
              subtractMinutes = Integer.valueOf((PSA_Settings__c.getInstance('CastIronSubtractMinutes').Value__c).trim());
          }
          //End of changes by Sharath
          soql=soql +' where SystemModStamp > '+dateTimeToString(pollStartTime.addMinutes(subtractMinutes));
        }
        
        soql=soql + ' order by SystemModStamp ASC';
        
        if(isCreatedDateToUse)
        soql=soql.replaceAll('SystemModStamp','CreatedDate');
        if(isLastModifiedDateToUse)
        soql=soql.replaceAll('SystemModStamp','LastModifiedDate');
        //if(isBulkUpdate)
        //CR 2770464 - rsharma: putting a different limit on query for test class
        if(!Test.isRunningTest()){
        soql=soql+' limit 30000';
        }else{
          soql=soql+' limit 1000';
        }

        //else soql=soql+' limit 25000';
        return soql;
    }
  
     public static Boolean  matchString(String salesforce,String customMessage){
    Boolean result;
    System.debug(salesforce);
    System.debug(customMessage);
    Pattern p = Pattern.compile(salesforce);
    Matcher pm = p.matcher( customMessage );

    if( pm.matches() ){
         
         return true;
         
    }
    return false;
    }


   webservice static String getMatchedString(String project,String Message)
    {
    Integer i;
    Boolean matched=false;
    String result='not found';
    if(Message==''||project=='')
    {
    return result;
    }
    else
    {
    List<Cast_Iron_Project_Error_and_Alert__c> errorObjectsToUpdate = new List<Cast_Iron_Project_Error_and_Alert__c>();
    for(Cast_Iron_Project_Error_and_Alert__c ErrorObjects : [SELECT Id,Error_Message__c,count__c,Action__c,Not_to_send__c,startCountTime__c,endCountTime__c FROM Cast_Iron_Project_Error_and_Alert__c WHERE Name = :(project) AND Type_of_Error__c='Error'] )
     { 
        matched=matchString(ErrorObjects.Error_Message__c,Message);
        if(matched)
        {
        
            if(ErrorObjects.Action__c=='Send Mail')
            {
                
                     try {
                     Double num=ErrorObjects.count__c;
                      Id idfield=ErrorObjects.Id;
                      datetime current;
                      current=datetime.now();
                         
                         //send mail once and make count 0
                           if(ErrorObjects.Not_to_send__c==false)
                            {
                                  ErrorObjects.startCountTime__c=current;//set current date and time
                                  ErrorObjects.endCountTime__c=current;
                                  ErrorObjects.Not_to_send__c=true;//dont send any more mails
                                  ErrorObjects.count__c=1;
                                  errorObjectsToUpdate.add(ErrorObjects);
                                //return ErrorObjects.Error_Message__c;
                                  return 'unchecked';
                             
                               }
                              else//if not_to_send==true dont send mails
                              {
                                      if(ErrorObjects.startCountTime__c.date()<current.date())//if it is not the same day
                                     {
                                         ErrorObjects.startCountTime__c=current;//set current date and time
                                         ErrorObjects.endCountTime__c=current;
                                         ErrorObjects.count__c=1;
                                         errorObjectsToUpdate.add(ErrorObjects);
                                         return 'unchecked';
                                     }
                                     else
                                     {
                                      ErrorObjects.count__c=num+1;
                                      ErrorObjects.endCountTime__c=current;//change end time
                                      errorObjectsToUpdate.add(ErrorObjects);
                                      return 'checked';
                                      }   
                            }                  
                             } //end of try
                         catch (DmlException e) {
                               System.debug('Error in updating count variable'); 
                                                     }
                        
            }
            else 
            return ErrorObjects.Action__c;
        
        }
       
       }
        if(errorObjectsToUpdate.size() > 0) {
            update errorObjectsToUpdate;
        }
       }
        return result;
    }
  
  
}