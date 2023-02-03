/*---------------------------------------------------------------------------------
 * Class Name 			: SC_ScrubIPAddressesForFeed_Batch
 * Developer Name 		: Aditi Singh, Vandhana Krishnamurthy
 * Date 				: 25th April,2022
 * JIRA 				: ESESP-6457
 * Test Class			: SC_ScrubIPAddressBatchClasses_Test
 ---------------------------------------------------------------------------------*/ 

global class SC_ScrubIPAddressesForFeed_Batch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts
{
    Id recTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();
    public String caseQuery;
    public String caseQuery_Test;
    public List<String> feedItemFilterList = new List<String>();
    
    //Stateful variable to store all the caseIds that did not process out in the end - these mean that the cases have one or more failed feeditems/feedcomments
    global Map<Id,String> mapOfFialedCaseIdsAndFailedObjectNames = new Map<Id,String>();
    
    public SC_ScrubIPAddressesForFeed_Batch()
    {    
        caseQuery_Test =    'SELECT Id, IP_Scrubbing_Failed_Objects__c ' +
                            'FROM Case ';
        
        //SC_Scrubbing_Object_Queries__mdt  scrubIPSettings = [SELECT Id, Query__c FROM SC_Scrubbing_Object_Queries__mdt  WHERE DeveloperName = 'Case_VK'];
        SC_Scrubbing_Object_Queries__mdt  scrubIPSettings = [SELECT Id, Query__c FROM SC_Scrubbing_Object_Queries__mdt  WHERE DeveloperName = 'Case'];
        
        feedItemFilterList = ([Select FeedItem_Filters__c from SC_Scrub_IP_Addresses_Setting__mdt where developerName = 'Technical' limit 1].FeedItem_Filters__c).split(',');
        
        if(scrubIPSettings != null && String.isNotBlank(scrubIPSettings.Query__c)){ 
            caseQuery = scrubIPSettings.Query__c;
        }
        System.debug('caseQuery ::'+caseQuery);
    }
    
    // -------------------------------------- START -------------------------------------- 
    public Database.QueryLocator start(Database.BatchableContext BC) 
    { 
        //Check whether its a test class execution or normal execution
        string batchQuery = (System.Test.isRunningTest()) ? caseQuery_Test : caseQuery;
        if(batchQuery != null)
        {
            return Database.getQueryLocator(batchQuery);
        }
        else
        {
             return null;   
        }
    }

    // -------------------------------------- EXECUTE -------------------------------------- 
    public void execute(Database.BatchableContext info, List<sObject> scope) 
    {    
        //System.debug('scope ::'+scope);
        System.debug('scope size ::'+scope.size());
        
        List<Case> scopeLst = (Case[]) scope;
        
        Map<Id,Case> mapOfCaseIdAndItsRecord = new Map<Id,Case>();
        List<Case> qualifiedcaseList = new List<Case>();
        
        for(Case cs : scopeLst){
            //Check if the case should be processed for FeedItem/FeedComment - this is only possible if the case entered first time or if for that case the objects failed
            if(String.isBlank(cs.IP_Scrubbing_Failed_Objects__c)  || (String.isNotBlank(cs.IP_Scrubbing_Failed_Objects__c) && (cs.IP_Scrubbing_Failed_Objects__c.contains('FeedItem') || cs.IP_Scrubbing_Failed_Objects__c.contains('FeedComment')))){
                qualifiedcaseList.add(cs);
                mapOfCaseIdAndItsRecord.put(cs.Id,cs);
            }
        }
        
        System.debug('mapOfCaseIdAndItsRecord ::'+mapOfCaseIdAndItsRecord);
        
        Map<Id,Case> mapofCaseIdtoCaseToBEUpdated = new Map<Id,Case>();
        
        
        //-************************************************************************ Feed Item starts *****************************************************************************
        
        //Variable to store the feeditems to update
        List<FeedItem> tempLstOfFeedItemToProcess = new List<Feeditem>();
        Map<Id,Case> mapOfFeedItemRecordToparentCase = new Map<Id,Case>();
        Map<Id,FeedItem> mapOfFeedItemToUpdate = new Map<Id,FeedItem>();
        list<FeedItem> caseFeedItemListForRetry = new list<FeedItem>();

        //Filter out only the records that have an Ip and needs to be scrubbed - Get all the feeditems records for scope of cases
        for(FeedItem fs : [SELECT Id,Body,Title,ParentId,type FROM FeedItem where ParentId IN :qualifiedcaseList and type NOT IN :feedItemFilterList])
        {
            System.debug('fs.Body ::'+fs.Body);
            System.debug('checkIfIPFound(fs.Body) ::'+checkIfIPFound(fs.Body));
            System.debug('fs.Title ::'+fs.Title);
            System.debug('checkIfIPFound(fs.Title) ::'+checkIfIPFound(fs.Title));
            if((string.isNotBlank(fs.Body) && checkIfIPFound(fs.Body)) || (string.isNotBlank(fs.Title) && checkIfIPFound(fs.Title))){
                tempLstOfFeedItemToProcess.add(fs);
            } 
        }
        System.debug('tempLstOfFeedItemToProcess ::'+tempLstOfFeedItemToProcess);
        
        //Scrub all the feeditems which we have filtered
        for(FeedItem fs : tempLstOfFeedItemToProcess)
        {
            fs.Title = !String.isBlank(fs.Title) ? searchAndReplaceIP(fs.Title) : fs.Title;
            fs.Title = !String.isBlank(fs.Title) && fs.Title.length() > 255 ? fs.Title.substring(0,255-1) : fs.Title;
            fs.Body = !String.isBlank(fs.Body) ? searchAndReplaceIP(fs.Body) : fs.Body;
            fs.Body = !String.isBlank(fs.Body) && fs.Body.length() > 10000 ? fs.Body.substring(0,10000-1) : fs.Body;
            //fs.Body = randomStr;
            mapOfFeedItemToUpdate.put(fs.Id, fs);
            mapOfFeedItemRecordToparentCase.put(fs.Id,mapOfCaseIdAndItsRecord.get(fs.ParentId));
        }
        
        System.debug('mapOfFeedItemToUpdate ::'+mapOfFeedItemToUpdate);
        System.debug('mapOfFeedItemRecordToparentCase ::'+mapOfFeedItemRecordToparentCase);
        
        //First attempt to try to updating
        if(!mapOfFeedItemToUpdate.isEmpty())
        {
            Database.SaveResult[] feedItemFailureList = Database.update(mapOfFeedItemToUpdate.values(), false);
    
            // Iterate through each returned result
            for (Database.SaveResult sr : feedItemFailureList) {
                if (!sr.isSuccess()) 
                {
                    //For all the feeditems that have failed we will retry again and if again they do not pass we will update failed on case
                    caseFeedItemListForRetry.add(mapOfFeedItemToUpdate.get(sr.getId()));
                }
                else
                {
                    //Logic - here we are checking if the case already had a failed object as feeditem then we will basically remove it as the fedeitem update has passed now, we will leave other as they were
                    if(string.isNotBlank(mapOfFeedItemRecordToparentCase.get(sr.getId()).IP_Scrubbing_Failed_Objects__c) 
                       && mapOfFeedItemRecordToparentCase.get(sr.getId()).IP_Scrubbing_Failed_Objects__c.contains('FeedItem'))
                    {

                        //This means case already had failed CaseFeed
                        //check if update case map already has this case for update
                        if(mapofCaseIdtoCaseToBEUpdated.containsKey(mapOfFeedItemRecordToparentCase.get(sr.getId()).Id))
                        {
                            Case newCaseToUpdate = new Case();
                            newCaseToUpdate = mapofCaseIdtoCaseToBEUpdated.get(mapOfFeedItemRecordToparentCase.get(sr.getId()).Id); //we got the case here
                            newCaseToUpdate.IP_Scrubbing_Failed_Objects__c = formFailedObjectStr(newCaseToUpdate.IP_Scrubbing_Failed_Objects__c, 'FeedItem');//we removed the feeditem from map data if found
                            newCaseToUpdate.Validation_Override__c = true;
                            mapofCaseIdtoCaseToBEUpdated.put(newCaseToUpdate.Id, newCaseToUpdate);
                        }
                        else
                        {
                            Case newCaseToUpdate = new Case();
                            newCaseToUpdate = mapOfFeedItemRecordToparentCase.get(sr.getId()); //got the case as it was not already added for update
                            newCaseToUpdate.IP_Scrubbing_Failed_Objects__c = formFailedObjectStr(newCaseToUpdate.IP_Scrubbing_Failed_Objects__c, 'FeedItem');//we removed the feeditem from map data if found
                            newCaseToUpdate.Validation_Override__c = true;
                            mapofCaseIdtoCaseToBEUpdated.put(newCaseToUpdate.Id, newCaseToUpdate);
                        }
                    }
                }
            }
        }

        System.debug('caseFeedItemListForRetry ::'+caseFeedItemListForRetry);
        System.debug('mapofCaseIdtoCaseToBEUpdated ::'+mapofCaseIdtoCaseToBEUpdated);
        
        //retry logic for Feed Item
        if(!caseFeedItemListForRetry.isEmpty())
        {
            Database.SaveResult[] feedItemFailureList2 = Database.update(caseFeedItemListForRetry, false);
            
            System.debug('feedItemFailureList2 ::'+feedItemFailureList2);
    
            // Iterate through each returned result
            for (Database.SaveResult sr : feedItemFailureList2) 
            {
                if (!sr.isSuccess()) 
                {
                    //get the caseId and update that case with failed recordfield
                    Case newCaseToUpdate = new Case();
                    newCaseToUpdate.Id = mapOfFeedItemRecordToparentCase.get(sr.getId()).Id;
                    newCaseToUpdate.IP_Scrubbing_Failed_Objects__c= mapOfFeedItemRecordToparentCase.get(sr.getId()).IP_Scrubbing_Failed_Objects__c == null?'FeedItem ':(mapOfFeedItemRecordToparentCase.get(sr.getId()).IP_Scrubbing_Failed_Objects__c != null && !mapOfFeedItemRecordToparentCase.get(sr.getId()).IP_Scrubbing_Failed_Objects__c.contains('FeedItem')?
                        mapOfFeedItemRecordToparentCase.get(sr.getId()).IP_Scrubbing_Failed_Objects__c+' FeedItem ':mapOfFeedItemRecordToparentCase.get(sr.getId()).IP_Scrubbing_Failed_Objects__c);
                    newCaseToUpdate.Validation_Override__c = true;
                    mapofCaseIdtoCaseToBEUpdated.put(newCaseToUpdate.Id, newCaseToUpdate);
                }
                else
                {
                    //Logic - here we are checking if the case already had a failed object as feeditem then we will basically remove it as the fedeitem update has passed now, we will leave other as they were
                    if(string.isNotBlank(mapOfFeedItemRecordToparentCase.get(sr.getId()).IP_Scrubbing_Failed_Objects__c) && mapOfFeedItemRecordToparentCase.get(sr.getId()).IP_Scrubbing_Failed_Objects__c.contains('FeedItem')){

                        //This means case already had failed CaseFeed
                        //check if update case map already has this case for update
                        if(mapofCaseIdtoCaseToBEUpdated.containsKey(mapOfFeedItemRecordToparentCase.get(sr.getId()).Id)){
                            Case newCaseToUpdate = new Case();
                            newCaseToUpdate = mapofCaseIdtoCaseToBEUpdated.get(mapOfFeedItemRecordToparentCase.get(sr.getId()).Id); //we got the case here
                            newCaseToUpdate.IP_Scrubbing_Failed_Objects__c = formFailedObjectStr(newCaseToUpdate.IP_Scrubbing_Failed_Objects__c, 'FeedItem');//we removed the feeditem from map data if found
                            newCaseToUpdate.Validation_Override__c = true;
                            mapofCaseIdtoCaseToBEUpdated.put(newCaseToUpdate.Id, newCaseToUpdate);
                        }
                        else{
                            Case newCaseToUpdate = new Case();
                            newCaseToUpdate = mapOfFeedItemRecordToparentCase.get(sr.getId()); //got the case as it was not already added for update
                            newCaseToUpdate.IP_Scrubbing_Failed_Objects__c = formFailedObjectStr(newCaseToUpdate.IP_Scrubbing_Failed_Objects__c, 'FeedItem');//we removed the feeditem from map data if found
                            newCaseToUpdate.Validation_Override__c = true;
                            mapofCaseIdtoCaseToBEUpdated.put(newCaseToUpdate.Id, newCaseToUpdate);
                        }
                    }
                }
            }
        }

        System.debug('mapofCaseIdtoCaseToBEUpdated ::'+mapofCaseIdtoCaseToBEUpdated);
        
        
        //-************************************************************************ FEED COMMENT *****************************************************************************
        
        //Variables used in feed comment update
        List<FeedComment> tempLstOfFeedCommentToProcess = new List<FeedComment>();
        Map<Id,Case> mapOfFeedCommentRecordToparentCase = new Map<Id,Case>();
        Map<Id,FeedComment> mapOfFeedCommentToUpdate = new Map<Id,FeedComment>();
        list<FeedComment> caseFeedCommentListForRetry = new list<FeedComment>();

        //Filter out only the records that have an Ip and needs to be scrubbed - Get all the feedcomments records for scope of cases
        For(FeedComment fcomm : [SELECT Id,CommentBody,ParentId FROM FeedComment where ParentId IN :qualifiedcaseList])
        {
            if( string.isNotBlank(fcomm.CommentBody) && checkIfIPFound(fcomm.CommentBody))
            {
                tempLstOfFeedCommentToProcess.add(fcomm);
            } 
        }
        System.debug('tempLstOfFeedCommentToProcess ::'+tempLstOfFeedCommentToProcess);
        
        //Scrub all the feedcomments which we have filtered
        For(FeedComment fcomm : tempLstOfFeedCommentToProcess)
        {
            fcomm.CommentBody = !String.isBlank(fcomm.CommentBody) ? searchAndReplaceIP(fcomm.CommentBody) : fcomm.CommentBody;
            fcomm.CommentBody = !String.isBlank(fcomm.CommentBody) && fcomm.CommentBody.length() > 10000 ? fcomm.CommentBody.substring(0,10000-1) : fcomm.CommentBody;
            mapOfFeedCommentToUpdate.put(fcomm.Id, fcomm);
            mapOfFeedCommentRecordToparentCase.put(fcomm.Id,mapOfCaseIdAndItsRecord.get(fcomm.ParentId));
        }
        
        System.debug('mapOfFeedCommentToUpdate ::'+mapOfFeedCommentToUpdate);
        System.debug('mapOfFeedCommentRecordToparentCase ::'+mapOfFeedCommentRecordToparentCase);
        
        //First attempt to try to updating
        if(!mapOfFeedCommentToUpdate.isEmpty())
        {
            Database.SaveResult[] feedCommentFailureList = Database.update(mapOfFeedCommentToUpdate.values(), false);
    
            // Iterate through each returned result
            for (Database.SaveResult sr : feedCommentFailureList) 
            {
                if (!sr.isSuccess()) 
                {
                    //For all the feedcomments that have failed we will retry again and if again they do not pass we will update failed on case
                    caseFeedCommentListForRetry.add(mapOfFeedCommentToUpdate.get(sr.getId()));
                }
                else
                {
                    //Logic - here we are checking if the case already had a failed object as feeditem then we will basically remove it as the fedeitem update has passed now, we will leave other as they were
                    if(String.isNotBlank(mapOfFeedCommentRecordToparentCase.get(sr.getId()).IP_Scrubbing_Failed_Objects__c) 
                       && mapOfFeedCommentRecordToparentCase.get(sr.getId()).IP_Scrubbing_Failed_Objects__c.contains('FeedComment'))
                    {
                        //This means case already had failed CaseFeed
                        //check if update case map already has this case for update
                        if(mapofCaseIdtoCaseToBEUpdated.containsKey(mapOfFeedCommentRecordToparentCase.get(sr.getId()).Id))
                        {
                            Case newCaseToUpdate = new Case();
                            newCaseToUpdate = mapofCaseIdtoCaseToBEUpdated.get(mapOfFeedCommentRecordToparentCase.get(sr.getId()).Id); //we got the case here
                            newCaseToUpdate.IP_Scrubbing_Failed_Objects__c = formFailedObjectStr(newCaseToUpdate.IP_Scrubbing_Failed_Objects__c, 'FeedComment');//we removed the feeditem from map data if found
                            newCaseToUpdate.Validation_Override__c = true;
                            mapofCaseIdtoCaseToBEUpdated.put(newCaseToUpdate.Id, newCaseToUpdate);
                        }
                        else
                        {
                            Case newCaseToUpdate = new Case();
                            newCaseToUpdate = mapOfFeedCommentRecordToparentCase.get(sr.getId()); //got the case as it was not already added for update
                            newCaseToUpdate.IP_Scrubbing_Failed_Objects__c = formFailedObjectStr(newCaseToUpdate.IP_Scrubbing_Failed_Objects__c, 'FeedComment');//we removed the feeditem from map data if found
                            newCaseToUpdate.Validation_Override__c = true;
                            mapofCaseIdtoCaseToBEUpdated.put(newCaseToUpdate.Id, newCaseToUpdate);
                        }
                    }
                }
            }
        }
        
        System.debug('caseFeedCommentListForRetry ::'+caseFeedCommentListForRetry);
        System.debug('mapofCaseIdtoCaseToBEUpdated ::'+mapofCaseIdtoCaseToBEUpdated);
        
        //retry logic for Feed Comment
        if(!caseFeedCommentListForRetry.isEmpty())
        {
            Database.SaveResult[] feedCommentFailureList2 = Database.update(caseFeedCommentListForRetry, false);
            
            System.debug('feedCommentFailureList2 ::'+feedCommentFailureList2);
    
            // Iterate through each returned result
            for (Database.SaveResult sr : feedCommentFailureList2) 
            {
                if (!sr.isSuccess()) 
                {
                    //get the caseId and update that case with failed recordfield
                    if(mapofCaseIdtoCaseToBEUpdated.containsKey(mapOfFeedCommentRecordToparentCase.get(sr.getId()).Id)){
                        Case newCaseToUpdate = mapofCaseIdtoCaseToBEUpdated.get(mapOfFeedCommentRecordToparentCase.get(sr.getId()).Id);
                        newCaseToUpdate.IP_Scrubbing_Failed_Objects__c= newCaseToUpdate.IP_Scrubbing_Failed_Objects__c.contains('FeedComment')?newCaseToUpdate.IP_Scrubbing_Failed_Objects__c:newCaseToUpdate.IP_Scrubbing_Failed_Objects__c+' FeedComment ';
                        newCaseToUpdate.Validation_Override__c = true;
                        mapofCaseIdtoCaseToBEUpdated.put(newCaseToUpdate.Id,newCaseToUpdate);
                    }
                    else
                    {
                        //Logic - here we are checking if the case already had a failed object as feeditem then we will basically remove it as the fedeitem update has passed now, we will leave other as they were
                        if(String.isNotBlank(mapOfFeedCommentRecordToparentCase.get(sr.getId()).IP_Scrubbing_Failed_Objects__c) && mapOfFeedCommentRecordToparentCase.get(sr.getId()).IP_Scrubbing_Failed_Objects__c.contains('FeedComment')){
    
                            //This means case already had failed CaseFeed
                            //check if update case map already has this case for update
                            if(mapofCaseIdtoCaseToBEUpdated.containsKey(mapOfFeedCommentRecordToparentCase.get(sr.getId()).Id))
                            {
                                Case newCaseToUpdate = new Case();
                                newCaseToUpdate = mapofCaseIdtoCaseToBEUpdated.get(mapOfFeedCommentRecordToparentCase.get(sr.getId()).Id); //we got the case here
                                newCaseToUpdate.IP_Scrubbing_Failed_Objects__c = formFailedObjectStr(newCaseToUpdate.IP_Scrubbing_Failed_Objects__c, 'FeedComment');//we removed the feeditem from map data if found
                                newCaseToUpdate.Validation_Override__c = true;
                                mapofCaseIdtoCaseToBEUpdated.put(newCaseToUpdate.Id, newCaseToUpdate);
                            }
                            else
                            {
                                Case newCaseToUpdate = new Case();
                                newCaseToUpdate = mapOfFeedCommentRecordToparentCase.get(sr.getId()); //got the case as it was not already added for update
                                newCaseToUpdate.IP_Scrubbing_Failed_Objects__c = formFailedObjectStr(newCaseToUpdate.IP_Scrubbing_Failed_Objects__c, 'FeedComment');//we removed the feeditem from map data if found
                                newCaseToUpdate.Validation_Override__c = true;
                                mapofCaseIdtoCaseToBEUpdated.put(newCaseToUpdate.Id, newCaseToUpdate);
                            }
                        }
                    }
            	}
            }
        }
        
        System.debug('mapofCaseIdtoCaseToBEUpdated ::'+mapofCaseIdtoCaseToBEUpdated);
        
        //-************************************************************************ FINALLY UPDATE CASE ******************************************************************************
        
        //Update the case for the first time
        List<Case> lstOfCasesThatFailedInFirstAttempt = new List<Case>();
        
        //First attempt to try to updating
        if(!mapofCaseIdtoCaseToBEUpdated.isEmpty())
        {
            Database.SaveResult[] casesFailureSaveResult = Database.update(mapofCaseIdtoCaseToBEUpdated.values(), false);
            for (Database.SaveResult sr : casesFailureSaveResult) 
            {   //For all the cases that failed in the first we will store them in a list and retry updating them again
                if (!sr.isSuccess()) {	lstOfCasesThatFailedInFirstAttempt.add(mapofCaseIdtoCaseToBEUpdated.get(sr.getId()));}
            }
        }
        
        System.debug('lstOfCasesThatFailedInFirstAttempt ::'+lstOfCasesThatFailedInFirstAttempt);
        
        //Second retry for the cases that failed in the first attempt
        if(!lstOfCasesThatFailedInFirstAttempt.isEmpty())
        {
        	Database.SaveResult[] casesFailureSaveResult2 = Database.update(lstOfCasesThatFailedInFirstAttempt, false);
            
            for (Database.SaveResult sr : casesFailureSaveResult2) 
            {   //These are the cases which could not be updated till the end and have failed records that did not get scrubbed
                if (!sr.isSuccess()) {	mapOfFialedCaseIdsAndFailedObjectNames.put(sr.getId(),mapofCaseIdtoCaseToBEUpdated.get(sr.getId()).IP_Scrubbing_Failed_Objects__c);}
            }
        }
        
        System.debug('mapOfFialedCaseIdsAndFailedObjectNames ::'+mapOfFialedCaseIdsAndFailedObjectNames);        
    }

    // -------------------------------------- FINISH, CALL MULE FLOW -------------------------------------- 
    public void finish(Database.BatchableContext info) 
    {     
        // Enqueue Callout first, then SendEmail
        System.enqueueJob(new SC_ScrubIPAddressMuleCalloutQueueable());
        
        //First send out alert for all the caseIds that have failed to get their child records scrubbed if setOfCaseIdsThatFailed.size()>0
        
        if(!mapOfFialedCaseIdsAndFailedObjectNames.isEmpty())
        {
            string setEmailSub = 'SC_ScrubIPAddresses_Batch Main Case Batch';
            string errorMessage =  	'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n\n';
            errorMessage += 'All the caseIds for which the update failed are as below :\n\n';
            for(String key : mapOfFialedCaseIdsAndFailedObjectNames.keySet()) { errorMessage += Key+':'+mapOfFialedCaseIdsAndFailedObjectNames.get(key)+'\n';}
            //senEmailWhenError(setEmailSub, errorMessage);
        }
        
    }
    
    //Method for searching and replacing all IPv4 and IPv6 addresses
    public String searchAndReplaceIP(String dataForScrubbing)
    {       
        String afterMaskingJSON = '';
        List<String> splitStringList = new List<String>();
        // if(dataForScrubbing.length() > 0){
        splitStringList = string.isNotBlank(dataForScrubbing)?dataForScrubbing.split('[\n]'):new List<String>();
        //}
        if(splitStringList.size() > 0)
        {
            for(string eachString : splitStringList)
            {
                String regExIPv4Andv6 = '(\\s*(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])\\s*)|(\\s*([\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:[\\dA-Fa-f]{1,4})|(:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:[\\dA-Fa-f]{1,4})|([\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:[\\dA-Fa-f]{1,4})|([\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4})|([\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f][\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4})|([\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4})|([\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f])|([\\dA-Fa-f]{1,4}:{2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4})\\s*)';
                String regexForIPv6Short = '\\s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)(\\.(25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)(\\.(25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)(\\.(25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)(\\.(25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)(\\.(25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)(\\.(25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)(\\.(25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)){3}))|:)))(%.+)?\\s*';
                Pattern regexPattern = Pattern.compile(regExIPv4Andv6);
                Matcher regexMatcher = regexPattern.matcher(eachString); 
                Boolean hasV4 = regexMatcher.find();
                
                system.debug('hasV4 : '+hasV4);

                Pattern regexPattern1 = Pattern.compile(regexForIPv6Short);
                Matcher regexMatcher1 = regexPattern1.matcher(eachString);
                Boolean hasV6 = regexMatcher1.find();
                
                system.debug('eachString : '+eachString);
                system.debug('hasV6 : '+hasV6);
                
                if(hasV6)
                {
                    afterMaskingJSON = afterMaskingJSON + eachString.replaceAll(regexForIPv6Short,' [IP Removed for Data Privacy] ');
                    system.debug('afterMaskingJSON v6 found: '+afterMaskingJSON);
                    
                    //Now lets check if the remaining string has any other ip(ipv4)
                    Matcher regexMatcherForv4 = regexPattern.matcher(afterMaskingJSON); 
                    Boolean newV4Found = regexMatcherForv4.find();
                    system.debug('newV4Found : '+newV4Found);
                    if(newV4Found)
                    {
                        afterMaskingJSON = afterMaskingJSON.replaceAll(regExIPv4Andv6,' [IP Removed for Data Privacy] ');
                    	system.debug('afterMaskingJSON v4 found inside v6: '+afterMaskingJSON);
                    }
                }
                else if(hasV4)
                {
                    afterMaskingJSON = afterMaskingJSON + eachString.replaceAll(regExIPv4Andv6,' [IP Removed for Data Privacy] ');
                    
                    //Now lets check if the remaining string has any other ip(ipv6)
                    Matcher regexMatcherForv6 = regexPattern1.matcher(afterMaskingJSON); 
                    Boolean newV6Found = regexMatcherForv6.find();
                    
                    if(newV6Found){	afterMaskingJSON = afterMaskingJSON.replaceAll(regexForIPv6Short,' [IP Removed for Data Privacy] ');	}
                }
                else {	afterMaskingJSON = afterMaskingJSON + eachString; }
                afterMaskingJSON = afterMaskingJSON + '<--br-->';
                system.debug('afterMaskingJSON ekdum out: '+afterMaskingJSON);
            }
        }
        afterMaskingJSON = afterMaskingJSON.removeEnd('<--br-->');
        afterMaskingJSON = afterMaskingJSON.replaceAll('<--br-->','\n');
        system.debug('afterMaskingJSON return se pehle: '+afterMaskingJSON);
        return afterMaskingJSON;
    }

    //Method for searching match for IP only
    public Boolean checkIfIPFound(String dataForScrubbing)
    {   
        List<String> splitStringList = new List<String>();
        // if(dataForScrubbing.length() > 0){
        splitStringList = string.isNotBlank(dataForScrubbing)?dataForScrubbing.split('[\n]'):new List<String>();
        //}
        if(splitStringList.size() > 0)
        {
            for(string eachString : splitStringList)
            {
                String regExIPv4Andv6 = '(\\s*(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])\\s*)|(\\s*([\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:[\\dA-Fa-f]{1,4})|(:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:[\\dA-Fa-f]{1,4})|([\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:[\\dA-Fa-f]{1,4})|([\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4})|([\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f][\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4})|([\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4})|([\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f])|([\\dA-Fa-f]{1,4}:{2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4})\\s*)';
                String regexForIPv6Short = '\\s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)(\\.(25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)(\\.(25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)(\\.(25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)(\\.(25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)(\\.(25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)(\\.(25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)(\\.(25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)){3}))|:)))(%.+)?\\s*';
                Pattern regexPattern = Pattern.compile(regExIPv4Andv6);
                Matcher regexMatcher = regexPattern.matcher(eachString);  
                Boolean hasV4 = regexMatcher.find();
                
                system.debug('hasV4 : '+hasV4);

                Pattern regexPattern1 = Pattern.compile(regexForIPv6Short);
                Matcher regexMatcher1 = regexPattern1.matcher(eachString);
                Boolean hasV6 = regexMatcher1.find();
                
                system.debug('hasV6 : '+hasV6);
                
                if(hasV4 || hasV6)
                {
                    return true;
                }
            }
        }
        return false;
    }

    //Method to form the failed objects field
    public String formFailedObjectStr(String strToConsider, String strToFind)
    {   
        String tempFailedObj = '';
        for(String str : strToConsider.split(' ')){
            if(str != strToFind)
            {
                tempFailedObj +=str+' ';
            }
        }
        return tempFailedObj;
    }
    
    public void senEmailWhenError(string emailSubject, string emailBody)
    {    
        // Fetch Support Email Address from Custom Setting - SC_SupportEmail__c
        SC_SupportEmail__c supEmailValues = SC_SupportEmail__c.getValues('1');
        
        // Setting To Address
        String[] toAdd = new String[] {};
        toAdd.add(supEmailValues.Support_Email_AutoGen__c);
        
        // Sending Email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(toAdd);
        mail.subject = emailSubject;
        mail.plainTextBody = emailBody;
        Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});        
    }

}