/*---------------------------------------------------------------------------------
 * Class Name 			: SC_ScrubIPAddressesForCollabFeed_Batch
 * Developer Name 		: Aditi Singh, Vandhana Krishnamurthy
 * Date 				: 25th April,2022
 * JIRA 				: ESESP-6457
 * Test Class			: SC_ScrubIPAddressBatchClasses_Test

 ---------------------------------------------------------------------------------*/ 

global class SC_ScrubIPAddressesForCollabFeed_Batch implements Database.Batchable<sObject>, Database.Stateful{
    
    Public string collabGroupQuery;
    Public string collabGroupQuery_Test;
    
    //Stateful variable to store all the feeditemIds that did not process out in the end
    global Map<Id,String> mapOfFailedFeedItemToError = new Map<Id,String>();

    //creating object of the other batch to be used in the code to get different methods
    SC_ScrubIPAddressesForFeed_Batch objectOfBatch = new SC_ScrubIPAddressesForFeed_Batch();
    
    public SC_ScrubIPAddressesForCollabFeed_Batch(){
        
        SC_Scrubbing_Object_Queries__mdt  scrubIPSettings = [SELECT Id, Query__c FROM SC_Scrubbing_Object_Queries__mdt  WHERE Object__c = 'CollaborationGroupFeedPost'];
        
        SC_Utility__mdt  crmOpsUserId = SC_Utility__mdt.getInstance('CRM_Ops_Id');

        if(scrubIPSettings != null && String.isNotBlank(scrubIPSettings.Query__c))
        { 
            /*
            //added for testing - 1 day after testing (Will have to remove this for Prod)
            
            //System.debug(System.now().addDays(-1).format('yyyy-MM-dd\'T\'HH:mm:ssZ'));
            //dateToCheck = System.now().addDays(-1).format('yyyy-MM-dd\'T\'HH:mm:ssZ');
            */
            
            //Code to get date 4 months before
            System.debug(System.now().addMonths(-4).format('yyyy-MM-dd\'T\'HH:mm:ssZ'));
            String dateToCheck = System.now().addMonths(-4).format('yyyy-MM-dd\'T\'HH:mm:ssZ');
            
            //collabGroupQuery = scrubIPSettings.Query__c + ' AND ((LastEditDate = null AND (CreatedDate >= 2017-05-01T00:00:00Z AND CreatedDate<='+dateToCheck+')) OR (LastEditDate != null AND (LastEditDate >= 2017-05-01T00:00:00Z AND LastEditDate <='+dateToCheck+'))) AND  LastEditById !=\''+crmOpsUserId.Value_Text__c+'\'';
            collabGroupQuery = scrubIPSettings.Query__c
                + ' AND ((LastEditDate = null AND CreatedDate<=' + dateToCheck + ') OR (LastEditDate != null AND LastEditDate <=' + dateToCheck +')) ' 
                + ' AND ( LastEditById = null OR ( LastEditById != null AND LastEditById !=\'' + crmOpsUserId.Value_Text__c + '\'))';
            collabGroupQuery_Test =  scrubIPSettings.Query__c;
        }
        System.debug('collabGroupQuery ::'+collabGroupQuery);
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) 
    { 
        //Check whether its a test class execution or normal execution
        string batchQuery = (System.Test.isRunningTest()) ? collabGroupQuery_Test : collabGroupQuery;
        if(batchQuery != null)
            return Database.getQueryLocator(batchQuery);
        else
            return null;
    }

    public void execute(Database.BatchableContext info, List<sObject> scope) 
    {    
        System.debug('scope ::' + scope.size());
        
        List<FeedItem> qualifiedFeedItemList = (FeedItem[]) scope;

        //-************************************************************************ Collaboration Post starts *****************************************************************************

        //Variable to store the feeditems to update
        List<FeedItem> tempLstOfFeedItemToProcess = new List<Feeditem>();
        list<FeedItem> collabFeedItemListForUpdate = new list<FeedItem>();
        Map<Id,FeedItem> mapOfFeedItemIdtoFeedItem = new Map<Id,FeedItem>();

        //Get all the feeditems records which contain ip address in order to process them further
        For(FeedItem fs : qualifiedFeedItemList){
            if(objectOfBatch.checkIfIPFound(fs.Title) || objectOfBatch.checkIfIPFound(fs.Body)){
                tempLstOfFeedItemToProcess.add(fs);
            }
        }
        System.debug('tempLstOfFeedItemToProcess ::'+tempLstOfFeedItemToProcess);

        //Get all the feeditems records for scope of cases
        For(FeedItem fs : tempLstOfFeedItemToProcess){
            fs.Title = !String.isBlank(fs.Title) ? objectOfBatch.searchAndReplaceIP(fs.Title) : fs.Title;
            fs.Title = !String.isBlank(fs.Title) && fs.Title.length() > 255 ? fs.Title.substring(0,255-1) : fs.Title;
            fs.Body = !String.isBlank(fs.Body) ? objectOfBatch.searchAndReplaceIP(fs.Body) : fs.Body;
            fs.Body = !String.isBlank(fs.Body) && fs.Body.length() > 10000 ? fs.Body.substring(0,10000-1) : fs.Body;
            collabFeedItemListForUpdate.add(fs);
            mapOfFeedItemIdtoFeedItem.put(fs.Id,fs);
        }

        System.debug('collabFeedItemListForUpdate ::'+collabFeedItemListForUpdate);
        
        //First time update
        list<FeedItem> collabFeedItemListForUpdate2 = new list<FeedItem>();
        if(!collabFeedItemListForUpdate.isEmpty()){
            Database.SaveResult[] srList = Database.update(collabFeedItemListForUpdate, false);
            
            for (Database.SaveResult sr : srList) {
                if (!sr.isSuccess()) {
                    //For all the cases that failed in the first we will store them in a list and retry updating them again
                    collabFeedItemListForUpdate2.add(mapOfFeedItemIdtoFeedItem.get(sr.getId()));
                }
            }
        }
        System.debug('collabFeedItemListForUpdate2 ::'+collabFeedItemListForUpdate2);
        
        //2nd update - retry for feeditem
        if(!collabFeedItemListForUpdate2.isEmpty()){
            Database.SaveResult[] srList = Database.update(collabFeedItemListForUpdate2, false);
            
            // Iterate through each returned result
            for(Integer i=0;i<srList.size();i++){
                if (!srList.get(i).isSuccess()){
                    //code to go here if posts fail to update
                    Database.Error err = srList.get(i).getErrors().get(0);
                    mapOfFailedFeedItemToError.put(srList.get(i).getId(), err.getMessage()+'\n'+err.getFields());
                }
            }
        }
        System.debug('mapOfFailedFeedItemToError ::'+mapOfFailedFeedItemToError);
        
    }

    public void finish(Database.BatchableContext info) 
    { 
        //Lastly if we have failed records in any of the stateful vars we will be sending an update to support email address
        if(mapOfFailedFeedItemToError.size()>0)
        {
            string setEmailSub = 'SC_ScrubIPAddresses_Batch Collaboration Fedd and Comment Batch';
            string errorMessage =  	'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n\n';
            if(mapOfFailedFeedItemToError.size()>0){
                errorMessage += '\n\nAll the CollaborationGroup Feedposts for which the scrubbing failed are as below :\n\n';
                For(String key : mapOfFailedFeedItemToError.keySet()){
                    errorMessage += Key+':'+mapOfFailedFeedItemToError.get(key)+'\n';
                }
            }
            System.debug('setEmailSub :: '+setEmailSub);
            System.debug('errorMessage :: '+errorMessage);
            objectOfBatch.senEmailWhenError(setEmailSub, errorMessage);
        }
        
        //Called the second batch for feed Comment
        SC_ScrubIPAddressesForCollabComm_Batch objSecond = new SC_ScrubIPAddressesForCollabComm_Batch();
        Database.executeBatch(objSecond);
    }

}