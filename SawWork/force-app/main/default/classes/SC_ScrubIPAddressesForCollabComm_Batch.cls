/*---------------------------------------------------------------------------------
 * Class Name 			: SC_ScrubIPAddressesForCollabComm_Batch
 * Developer Name 		: Aditi Singh, Vandhana Krishnamurthy
 * Date 				: 25th April,2022
 * JIRA 				: ESESP-6457
 * Test Class			: SC_ScrubIPAddressBatchClasses_Test

 ---------------------------------------------------------------------------------*/ 

global class SC_ScrubIPAddressesForCollabComm_Batch implements Database.Batchable<sObject>, Database.Stateful{
    
    Public string collabCommentQuery;
    Public string collabCommentQuery_Test;
    
    //Stateful variable to store all the feedcommentIds that did not process out in the end
    global Map<Id,String> mapOfFailedFeedCommentToError = new Map<Id,String>();

    //creating object of the other batch to be used in the code to get different methods
    SC_ScrubIPAddressesForFeed_Batch objectOfBatch = new SC_ScrubIPAddressesForFeed_Batch();
    
    public SC_ScrubIPAddressesForCollabComm_Batch()
    {    
        SC_Scrubbing_Object_Queries__mdt  scrubIPSettings = [SELECT Id, Query__c FROM SC_Scrubbing_Object_Queries__mdt  WHERE Object__c = 'CollaborationGroupFeedComment'];
        
        SC_Utility__mdt  crmOpsUserId = SC_Utility__mdt.getInstance('CRM_Ops_Id');

        if(scrubIPSettings != null && String.isNotBlank(scrubIPSettings.Query__c))
        { 
            /*
            //added for testing - 1 day after testing (Will have to remove this for Prod)
            //Code to get date 4 months before
            //System.debug(System.now().addDays(-1).format('yyyy-MM-dd\'T\'HH:mm:ssZ'));
            //dateToCheck = System.now().addDays(-1).format('yyyy-MM-dd\'T\'HH:mm:ssZ');
            */
            
            //Code to get date 4 months before
            System.debug(System.now().addMonths(-4).format('yyyy-MM-dd\'T\'HH:mm:ssZ'));
            String dateToCheck = System.now().addMonths(-4).format('yyyy-MM-dd\'T\'HH:mm:ssZ');
            
            //collabCommentQuery = scrubIPSettings.Query__c + ' AND ((LastEditDate = null AND (CreatedDate >= 2017-05-01T00:00:00Z AND CreatedDate<='+dateToCheck+')) OR (LastEditDate != null AND (LastEditDate >= 2017-05-01T00:00:00Z AND LastEditDate <='+dateToCheck+'))) AND  LastEditById !=\''+crmOpsUserId.Value_Text__c+'\'';
            collabCommentQuery = scrubIPSettings.Query__c
                + ' AND ((LastEditDate = null AND CreatedDate<=' + dateToCheck + ') OR (LastEditDate != null AND LastEditDate <=' + dateToCheck +')) ' 
                + ' AND ( LastEditById = null OR ( LastEditById != null AND LastEditById !=\'' + crmOpsUserId.Value_Text__c + '\'))';
            
            collabCommentQuery_Test =  scrubIPSettings.Query__c;
        }
        System.debug('collabCommentQuery ::'+collabCommentQuery);
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) 
    { 
        //Check whether its a test class execution or normal execution
        string batchQuery = (System.Test.isRunningTest()) ? collabCommentQuery_Test : collabCommentQuery;
        if(batchQuery != null)
        {
            return Database.getQueryLocator(batchQuery);
        }
        else { return null;}
    }

    public void execute(Database.BatchableContext info, List<sObject> scope) 
    {
        System.debug('Scope :: ' + scope.size());
        
        List<FeedComment> qualifiedFeedCommentList = (FeedComment[]) scope;
        
        //-************************************************************************ Collaboration Post Comment starts *****************************************************************************
        
        //Variable to store the feedcomment to update
        List<FeedComment> tempLstOfFeedCommentToProcess = new List<FeedComment>();
        list<FeedComment> collabFeedCommentListForUpdate = new list<FeedComment>();
        Map<Id,FeedComment> mapOfFeedCommentIdtoFeedComment = new Map<Id,FeedComment>();

        //Get all the feedcomments records which contain ip address in order to process them further
        For(FeedComment fs : qualifiedFeedCommentList)
        {
            if(objectOfBatch.checkIfIPFound(fs.CommentBody))
            {
                tempLstOfFeedCommentToProcess.add(fs);
            }
        }
        System.debug('tempLstOfFeedCommentToProcess ::'+tempLstOfFeedCommentToProcess);

        //Get all the feeditems records for scope of cases
        For(FeedComment fcomm : tempLstOfFeedCommentToProcess)
        {
            fcomm.CommentBody = !String.isBlank(fcomm.CommentBody) ? objectOfBatch.searchAndReplaceIP(fcomm.CommentBody) : fcomm.CommentBody;
            fcomm.CommentBody = !String.isBlank(fcomm.CommentBody) && fcomm.CommentBody.length() > 10000 ? fcomm.CommentBody.substring(0,10000-1) : fcomm.CommentBody;
            collabFeedCommentListForUpdate.add(fcomm);
            mapOfFeedCommentIdtoFeedComment.put(fcomm.Id,fcomm);
        }

        System.debug('collabFeedCommentListForUpdate ::'+collabFeedCommentListForUpdate);
        
        //First time update
        list<FeedComment> collabFeedCommentListForUpdate2 = new list<FeedComment>();
        if(!collabFeedCommentListForUpdate.isEmpty())
        {
            Database.SaveResult[] srList = Database.update(collabFeedCommentListForUpdate, false);
            
            //For all the cases that failed in the first we will store them in a list and retry updating them again
            for (Database.SaveResult sr : srList) 
            {
                if (!sr.isSuccess()) {collabFeedCommentListForUpdate2.add(mapOfFeedCommentIdtoFeedComment.get(sr.getId()));}
            }
        }
        System.debug('collabFeedCommentListForUpdate2 ::'+collabFeedCommentListForUpdate2);
        
        //2nd update - retry for feedcomment
        if(!collabFeedCommentListForUpdate2.isEmpty()){
            Database.SaveResult[] srList = Database.update(collabFeedCommentListForUpdate2, false);
            
            // Iterate through each returned result
            for(Integer i=0;i<srList.size();i++){
                if (!srList.get(i).isSuccess()){
                    //code to go here if posts fail to update
                    Database.Error err = srList.get(i).getErrors().get(0);
                    mapOfFailedFeedCommentToError.put(srList.get(i).getId(), err.getMessage()+'\n'+err.getFields());
                }
            }
        }
        System.debug('mapOfFailedFeedCommentToError ::'+mapOfFailedFeedCommentToError);
    }

    public void finish(Database.BatchableContext info) 
    { 
        //Lastly if we have failed records in any of the stateful vars we will be sending an update to support email address
        if(mapOfFailedFeedCommentToError.size()>0)
        {
            string setEmailSub = 'SC_ScrubIPAddresses_Batch Collaboration Fedd and Comment Batch';
            string errorMessage =  	'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n\n';
            if(mapOfFailedFeedCommentToError.size()>0){
                errorMessage += '\n\nAll the CollaborationGroup FeedComments for which the scrubbing failed are as below :\n\n';
                for(String key : mapOfFailedFeedCommentToError.keySet()) {errorMessage += Key+':'+mapOfFailedFeedCommentToError.get(key)+'\n';}
            }
            System.debug('setEmailSub :: '+setEmailSub);
            System.debug('errorMessage :: '+errorMessage);
            objectOfBatch.senEmailWhenError(setEmailSub, errorMessage);
        }
        
        // Invoke Case Scrubbing Batch Job
        SC_ScrubIPAddressesForFeed_Batch caseFeedBatchObj = new SC_ScrubIPAddressesForFeed_Batch();
        Database.executeBatch(caseFeedBatchObj);
    }
}