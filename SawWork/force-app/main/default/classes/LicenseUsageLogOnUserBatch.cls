/*--=====================================================================================================+

|  HISTORY  |                                                                            

|  DATE           DEVELOPER   CR          DESCRIPTION                                                       

|  ===========    =========   =======     =========== 
                                                       
|  03-Oct-2016    Akhila      3527281     Batch class to log object usage of every user on UserLicenseUsageLog__c
+=====================================================================================================--*/
global class LicenseUsageLogOnUserBatch implements Database.Batchable<sObject>, Database.Stateful{
	Set<String> QuerySet;
    String currentQuery;
    Map<Id,UserLicenseUsageLog__c> userMap ; 
    Static String numDays;
    Static
    {
        List<License_Query__c> lQ = [Select Object__c,Query_Suffix__c from License_Query__c where Object__c = 'days'];
        numDays = lQ.isEmpty() ? '1': lQ[0].Query_Suffix__c;
    }
    Map<String,String> mObjectLicense;

    public LicenseUsageLogOnUserBatch(Set<String> QuerySet,String currentQuery,Map<String,String> mObjectLicense)
    {
        this.QuerySet = QuerySet;
        this.currentQuery = currentQuery;
        this.mObjectLicense = mObjectLicense;
        userMap = new Map<Id,UserLicenseUsageLog__c>();
        for(UserLicenseUsageLog__c u: [Select Id, LicenseUsageLog__c, UserExternalId__c  from UserLicenseUsageLog__c ])
        {
            userMap.put(u.UserExternalId__c,u);
        }
    }
    
    global Database.Querylocator start (Database.BatchableContext BC) 
    {
        String q = currentQuery.toLowerCase()+ ' where LastModifiedDate = LAST_N_DAYS:'+numDays;
		if(system.Test.isRunningTest())
		{    
			q+=' limit 100';             
        }
        return Database.getQueryLocator(q);
  	}

  	//Execute method
  	global void execute (Database.BatchableContext BC, List<sobject> scope) 
    {
        //Fetch the fields part of the query For eg: Select "CreatedById,LastModifiedById" from Case
        String fields = currentQuery.toLowerCase().substringBetween('select ', ' from');
        String objectName = currentQuery.toLowerCase().substringAfter('from ').trim();
        //Get every user field and trim it
        Set<String> setFields = new Set<String>(fields.split(','));
        System.debug(setFields);
        
        for(sObject s : scope)
        {
            //Avoid CreatedDate and LastModifiedDate
            for(String f : setFields)
            {
                Boolean matchFoundLicense = false;
                Boolean matchFoundObject = false;
                Integer licenseIndex = 0;
                Integer objectIndex = 0;
                //Add the user field values and skip dates
                System.debug(f.trim());
                System.debug(s.get(f.trim()));
                if(f.trim().toLowerCase()!='createddate' && f.trim().toLowerCase()!='lastmodifieddate' && s.get(f.trim())!=null)
                {    
                    String userId = ((String)s.get(f.trim()));
                    DateTime lastDate = (f.trim().toLowerCase()=='createdbyid'? (DateTime)s.get('createddate'):(DateTime)s.get('lastmodifieddate'));
                    //get the UserLicenseUsageLog__c corresponding to every user id field
					if(!userMap.isEmpty() && userMap.containsKey(userId) && userMap.get(userId).LicenseUsageLog__c != null)
                    {    
                        List<Object> lexistingLicenseLog = (List<Object>) JSON.deserializeUntyped(userMap.get(userId).LicenseUsageLog__c);
                        for(Object existingLicenseLogRec :  lexistingLicenseLog)
                        {
                            licenseIndex ++;
                            
                            //If there is an entry for License
                            Map<String,Object> mExistingLicenseLogRec = (Map<String,Object>)existingLicenseLogRec;   
                            system.debug((String)mExistingLicenseLogRec.get('licenseName') == mObjectLicense.get(objectName.toLowerCase()));
                            if((String)mExistingLicenseLogRec.get('licenseName') == mObjectLicense.get(objectName.toLowerCase()))
                            {
                                //Iterate through list of Object Usage entries
                                List<Object> listOfMapExistingLicenseLogRec = new List<Object>();
                                listOfMapExistingLicenseLogRec = (List<Object>)mExistingLicenseLogRec.get('objectsUsage');
                                System.debug(listOfMapExistingLicenseLogRec);
                                for(Object objectUsageEntry : listOfMapExistingLicenseLogRec)
                                {
                                    Map<String,Object> mapObjectUsageEntry = (Map<String,Object>)objectUsageEntry;
                                    objectIndex++;
                                    //If there is an entry for object
                                    System.debug((String)mapObjectUsageEntry.get('object') == objectName.toLowerCase());
                                    if((String)mapObjectUsageEntry.get('object') == objectName.toLowerCase() )
                                    {
                                        //if the last stamped date is less than the new value else ignore
                                        System.debug(lastDate);
                                        System.debug(datetime.valueOf(((String)mapObjectUsageEntry.get('lastUsedDate')).replace('T', ' ').substringBefore('.')) < lastDate);
                                        if(datetime.valueOf(((String)mapObjectUsageEntry.get('lastUsedDate')).replace('T', ' ').substringBefore('.')) < lastDate)
                                        {
                                             mapObjectUsageEntry.put('lastUsedDate', lastDate);  
                                             System.debug(mapObjectUsageEntry);
                                             //Setting the Object Usage Entry
                                             listOfMapExistingLicenseLogRec[objectIndex - 1] = mapObjectUsageEntry;  
                                             System.debug(listOfMapExistingLicenseLogRec);
                                        } 
                                        matchFoundObject = True;
                                        break;
                                    }
                                }
                                //End of looping through object usage entries
                                //License exists and no entry for object
                                System.debug(!matchFoundObject);
                                if(!matchFoundObject)
                                {
                                    //Add entry for the object
                                    Map<String,Object> mObjectUsageEntry = new Map<String,Object>();
                                    mObjectUsageEntry.put('object',objectName);                                     
                                    mObjectUsageEntry.put('lastUsedDate', lastDate);                                
                                    System.debug(mObjectUsageEntry);
                                    listOfMapExistingLicenseLogRec.add(mObjectUsageEntry);
                                    matchFoundObject = True;
                                }
                                //Update lastUsedDate on License level                            
                                if(matchFoundObject)
                                {
                                    if(datetime.valueOf(((String)mExistingLicenseLogRec.get('lastUsedDate')).replace('T', ' ').substringBefore('.')) < lastDate)
                                    {
                                        mExistingLicenseLogRec.put('lastUsedObject',objectName);                                             
                                        mExistingLicenseLogRec.put('lastUsedDate', lastDate);
                                    }
                                    mExistingLicenseLogRec.put('objectsUsage',listOfMapExistingLicenseLogRec);
                                    System.debug(mExistingLicenseLogRec);
                                    lexistingLicenseLog[licenseIndex - 1] = mExistingLicenseLogRec;
                                    System.debug(lexistingLicenseLog);
                                    userMap.get(userId).LicenseUsageLog__c = JSON.serializePretty(lexistingLicenseLog);
                                } 
                                matchFoundLicense = true;
                                break;
                            }
                        }
                    }
                    System.debug(userMap.isEmpty() || !userMap.containsKey(userId) || (!userMap.isEmpty() && userMap.containsKey(userId) && ((userMap.get(userId).LicenseUsageLog__c != null && !matchFoundLicense) 
                                                       || userMap.get(userId).LicenseUsageLog__c == null || userMap.get(userId).LicenseUsageLog__c == '')));
                    //If field is not null and doesnt have an entry for license or field is null
                    if(userMap.isEmpty() || !userMap.containsKey(userId) || (!userMap.isEmpty() && userMap.containsKey(userId) && ((userMap.get(userId).LicenseUsageLog__c != null && !matchFoundLicense) 
                                                       || userMap.get(userId).LicenseUsageLog__c == null || userMap.get(userId).LicenseUsageLog__c == '')))
                    {
                       
                        Map<String,Object> mLicenseLog = new Map<String,Object>();
                        System.debug(objectName + mObjectLicense);
                        System.debug(mObjectLicense.get(objectName.toLowerCase()));
                        mLicenseLog.put('licenseName',mObjectLicense.get(objectName.toLowerCase()));
                        mLicenseLog.put('lastUsedObject',objectName);
                        mLicenseLog.put('lastUsedDate',lastDate);                            
                        
                        Map<String,Object> mObjectUsageRec = new Map<String,Object>();
                        mObjectUsageRec.put('object', objectName);
                        mObjectUsageRec.put('lastUsedDate',lastDate);
						List<Object> lObjectUsage = new List<Object>();
                        lObjectUsage.add(mobjectUsageRec); 
                        mLicenseLog.put('objectsUsage',lObjectUsage);
                        List<Object> lLicenseLog;
 						if(!userMap.isEmpty() && userMap.containsKey(userId))
                        {   
                            if( userMap.get(userId).LicenseUsageLog__c == null || userMap.get(userId).LicenseUsageLog__c == '')
                            {                                
                                lLicenseLog = new List<Object>();
                                lLicenseLog.add(mLicenseLog);
                            }
                            else
                            {
                                lLicenseLog = (List<Object>) JSON.deserializeUntyped(userMap.get(userId).LicenseUsageLog__c);
                                lLicenseLog.add(mLicenseLog);
    
                            }                            
                        	userMap.get(userId).LicenseUsageLog__c = JSON.serializePretty(lLicenseLog);
                        }
                        else if(userMap.isEmpty() || (!userMap.isEmpty() &&!userMap.containsKey(userId)))
                        {
                            UserLicenseUsageLog__c uLic = new UserLicenseUsageLog__c();
                            uLic.UserExternalId__c = userId;
                            uLic.User__c = userId;
                            lLicenseLog = new List<Object>();
                            lLicenseLog.add(mLicenseLog);
                            uLic.LicenseUsageLog__c = JSON.serializePretty(lLicenseLog);
							userMap.put(userId,uLic);
                        }
                    }                                         
                }    
            }
        }
  	}

  	//Finish Method
  	global void finish(Database.BatchableContext BC)
    {
        //upsert all the UserLicenseUsageLog__c
        if(!userMap.isEmpty())
        { 
    		upsert userMap.values() UserExternalId__c;
        }    
        
        //If there are any errors in the batch send an email  
        List<AsyncApexJob> lApexJobs = [Select a.TotalJobItems, a.Status, a.NumberOfErrors, a.JobType, a.JobItemsProcessed, a.ExtendedStatus, a.CreatedById, a.CompletedDate From AsyncApexJob a WHERE id = :BC.getJobId() and Status = 'Failed'];//get the job Id
        if(!lApexJobs.isEmpty())
        {               
            AsyncApexJob a = lApexJobs[0];
            List<License_Query__c> lQueries = [Select Query_Suffix__c from License_Query__c where Object__c = 'email'];    
            String[] emails = new List<String>();
            if(lQueries.size() > 0)    
            {
                emails.add(lQueries[0].Query_Suffix__c);  
            }    
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();    
            //below code will send an email to Logger Email address as well as ops team about the status
            mail.setToAddresses(emails);
            mail.setSubject('License Usage Log On User Batch Failed - '+a.Status);
            mail.setPlainTextBody('The Batch Apex job processed  '+a.TotalJobItems+'batches with  '+a.NumberOfErrors+'failures'+'Job Item processed are'+a.JobItemsProcessed);
            Messaging.sendEmail(new Messaging.Singleemailmessage [] {mail});
        }  
        else
        {  
            QuerySet.remove(currentQuery);  
            
            if(!QuerySet.isEmpty())
            {
                String nextQuery;
                for(String q : QuerySet)
                {
                    nextQuery = q;
                    break;
                }
                LicenseUsageLogOnUserBatch lURB = new LicenseUsageLogOnUserBatch(QuerySet,nextQuery,mObjectLicense);
                Database.executeBatch(lURB,1000);
            }        
        } 
    }        
}