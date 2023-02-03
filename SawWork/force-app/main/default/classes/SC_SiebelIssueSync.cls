/******

Author: Sharath Prasanna
Created Date: 14th July 2020
Description: This class is used to make API calls to Siebel to upsert Issue Activity records

Developer               Date                Jira            Description
Sharath Prasanna     14th July 2020        ESESP-3536    	Initial Development
Sharath Prasanna     28th Sep 2020         ESESP-4302       Dev Changes. Added Null check
Sharath Prasanna     20th Oct 2020                          Dev Changes. Added task comment limit
*/
public without sharing class SC_SiebelIssueSync 
{
	public SC_SiebelIssueSync()
    {
        
    }

    //This static Boolean flag is for recursion check
    public static Boolean siebelSyncRecursionCheck = true;
    public static Set<Id> taskIds = new Set<Id>();

    //The IssueActivityWrapper Wrapper class
    public class IssueActivityWrapper
    {
        //The akam activity Id
        String activityId;
        //The case Salesforce Id
        String caseId;
        //The akam case id
        String akamCaseId;
        //The Siebel Issue Id 
        String issueId;
        //The casenumber
        String caseNumber;
        //The Task description
        public String description;
        //The unique key which is the primary key for the Staging object
        String uniqueKey;
        
        //Constructor to set the class fields
        public IssueActivityWrapper(String setActivityId,String setCaseId, String setAkamCaseId
                                   ,String setCaseNumber, String setIssueId, String setUniqueKey, 
                                    String setDescription)
        {
            activityId = setActivityId;
            caseId = setCaseId;
            akamCaseId = setAkamCaseId;
            caseNumber = setCaseNumber;
            issueId = setIssueId;
            description = setDescription;
            uniqueKey = setUniqueKey;
        }
    }
    
    //The access token
    public static String accessToken;
    //The HTTP response string
    static String getResponseString;
    //The parsed HTTP response
    static Map<String, Object> results;
    //The Map for creating the body for POST
    static Map<String,String> postBody;    
    //The HTTP connector
    static Http http;
    //The Request object
    static HttpRequest request;            
    //The Response object
    static HttpResponse response;
    //The custom setting which stores the credentials
    public static SC_Case_Issue_Sync_Admin_Setting__c ipScrub;
    //This stores the number of API calls that can be made
    static Integer apiCount;
    //This is set to true if the access token was generated
    static Boolean updateToken;
	//This stores the number of retry attempts
    static Integer retryCount;
    //This stores the character limit
    static Integer commentLimit;
    
    //Function1: the method to get the access token   
    public static void getAccessToken()
    {
		//The oAuth endpoint: https://qa.dash-ext.akamai.com/oauth2/token
        String oAuthEndpoint = ipScrub.Hostname_Issues_API__c + ipScrub.Oauth_Endpoint_Issues_API__c; 
        //The client Id
        String clientId = ipScrub.Client_Id_Issues_API__c;
        //The client secret
        String clientSecret = ipScrub.Client_Secret_Issues_API__c;    
        //The scope: WRITE_ISSUES 
        String scope = ipScrub.Scope_Issues_API__c;
        //The certificate to connect: EAA_KMI_Signed_Certificate
        String certificate = ipScrub.Client_Certificate__c;
        
		http = new Http();
        request = new HttpRequest();            
	
        //Create the new request: to get the token
        request.setEndpoint(oAuthEndpoint);
        request.setMethod('GET');
        request.setHeader('client_id', clientId);
        request.setHeader('client_secret',clientSecret);
        request.setHeader('Content-Type','application/json');
        request.setHeader('grant_type','client_credentials');
        request.setHeader('scope',scope);
        request.setClientCertificateName(certificate);
		        
        try
        {
            //Get the response
            response = http.send(request);        
            //System.debug('## response.getStatusCode() '+ response.getStatusCode());
            //System.debug('## response.getBody() '+ response.getBody());
            
    		//If the request is successful: assign the token to the accessToken variable
            if (response.getStatusCode() == 200) 
            {    
                results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());    
                accessToken = (String) results.get('access_token');   
                System.debug('## access_token '+ accessToken);
            }
            else
            {
                //If the request status is not 200: Send a mail with the error body
                PSA_AutoCreateProjectUtil.sendErrorMails('Siebel Activity Sync: Error Getting Access Token!',
                    response.getBody());
                
            }
            
        }
        catch(Exception e)
        {
            //If the request fails: Send a mail with the error body
            PSA_AutoCreateProjectUtil.sendErrorMails('Siebel Activity Sync: Error Getting Access Token!',
                    e.getMessage());            
        }
        //return accessToken;
    }
    //end of Method 1
    
    //Function2: The method to make the post/patch request to Siebel
    public static List<String> postRequest(String method, String issueId )
    {
        
        system.debug('inside post method');
        //The list which stores the state: Success or Failure and the Error message on Failure
        List<String> responseList = new List<String>();
        //The endpoint: https://qa.dash-ext.akamai.com/network-services/issues/v1/issues/<Issue-Id>/activities
        String endPoint = ipScrub.Hostname_Issues_API__c + ipScrub.Upsert_Endpoint_Issues_API__c + issueId; 
        String certificate = ipScrub.Client_Certificate__c;
		
		String postString;        
        //create the Http Request
        http = new Http();
        request = new HttpRequest();                    
        request.setMethod('POST');
        request.setHeader('Content-Type','application/json');
        request.setHeader('authorization','bearer ' + accessToken);
       
        if(method == 'POST')
        {
            endPoint += '/activities';
            //postString = JSON.serialize(postBody);
        }
        else
        {
            //activityId
            if(postBody.containsKey('activityId'))
            {
                endPoint += '/activities/' + postBody.get('activityId');
                postBody.remove('activityId');
            }
            //Map<String, List<Map <String,string>>> postBodyMap = new Map<String, List<Map <String,string>>>();                                
            //postBodyMap.put('activities',new List<Map <String,string>>{postBody});
            //postString = JSON.serialize(postBodyMap);            
        }
        postString = JSON.serialize(postBody);
        system.debug('The endpoint: ' + endPoint + 'postString: ' + postString);
        
        request.setTimeout(4000);
        request.setEndpoint(endPoint);
        request.setBody(postString);
        request.setClientCertificateName(certificate);
		
        try
        {
            //Get the response
            system.debug('The endpoint: ' + request.toString());
            response = http.send(request);
            
            //System.debug('## response.getStatusCode() '+ response.getStatusCode());
            //System.debug('## response.getBody() '+ response.getBody());
    		
            //Method called to parse the response
            setPostResponse(responseList);
            //system.debug('responseList: ' + responseList);
            //if the rquest fails due to invalid token: get a new token
            //changes for ESESP-4302
            if(!updateToken && responseList.size() == 2 && responseList.get(0) == 'Failure' && responseList.get(1).contains('Invalid access token'))
            {
                //Get the token and set the updateToken variable: This variable limits the number of token calls to 1
                getAccessToken();
                updateToken = true;
                //the number of remaining APIs
                apiCount--;

                //make the post request with the new Token
                
                http = new Http();
                request = new HttpRequest();            
                request.setEndpoint(endPoint);
                request.setMethod('POST');
                request.setHeader('Content-Type','application/json');
                request.setHeader('authorization','bearer ' + accessToken);
               
                request.setBody(postString);
                request.setClientCertificateName(certificate);
                response = http.send(request);
                
                responseList= new List<String>();
                setPostResponse(responseList);
            }                
        }
        catch(Exception e)
        {
            responseList.add('Failure');
            responseList.add(e.getMessage());
            
        }
        return responseList;
    }
    //End of method2
    
    //Function 3: This method is used to set parse the response from the POST request
    public static void setPostResponse(List<String> responseList)
    {
        //If the response is 200 or 201
        if (response.getStatusCode() == 201 || response.getStatusCode() == 200) 
        {    
            results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());    
            //Set the response as Success
            responseList.add('Success');
            if(response.getStatusCode() == 201)
            {
            	responseList.add((String) results.get('activityId'));    
            }            
        }
        else
        {
            //set the response as Failure and set the error body
            responseList.add('Failure');
            responseList.add(response.getBody());
        }
        
    }
    
    //Function 4: Future method to be called from the trigger
    //Future method: callout enabled
    @future(callout=true)
    public static void syncActivitySiebelFuture(String wrapperJSON, Set<String> uniqueKeys,Boolean isInsert, Boolean fromBatch)
    {
     	syncActivitySiebel(wrapperJSON, uniqueKeys,isInsert,fromBatch);   
    }    

    //Function 5: The method to sync data to Siebel
    public static string syncActivitySiebel(String wrapperJSON, Set<String> uniqueKeys,Boolean isInsert,Boolean fromBatch)
    {
        
        //fetch the hierarchy custom setting record for System Admins: this stores the connection credentials
        Id profileId = [SELECT Id FROM Profile WHERE name = 'System Administrator'].Id;
        ipScrub = SC_Case_Issue_Sync_Admin_Setting__c.getInstance(profileId);
        String certificate = ipScrub.Client_Certificate__c;	
        //The retry count default value is 3
        retryCount = 3;
        //The api limit default value is 100
        apiCount = 100;
        //The task comment limit. The limit in Siebel is 16300. Setting this to 15000
        commentLimit = 15000;
        
        for (SC_Utility__mdt retryCountRec : [Select Value_Text__c,developername from SC_Utility__mdt where 
                                          Active__c = true and developername in ('CaseIssueRetryCount','CaseIssueSyncAPICount','CaseIssueCommentLimit') ])
        {
            retryCount = retryCountRec.developername == 'CaseIssueRetryCount' && retryCountRec.Value_Text__c != null?
                Integer.valueOf(retryCountRec.Value_Text__c):
                retryCount;
            apiCount = retryCountRec.developername == 'CaseIssueSyncAPICount' && retryCountRec.Value_Text__c != null?
                Integer.valueOf(retryCountRec.Value_Text__c):
                apiCount;
            commentLimit = retryCountRec.developername == 'CaseIssueCommentLimit' && retryCountRec.Value_Text__c != null?
                Integer.valueOf(retryCountRec.Value_Text__c):
                commentLimit;
        }
        
	    updateToken = false;
        //The Access token is stored in the custom setting. Token expiry time is also stored.
        //Check if the token is not present in the custom setting or if it has expired
        if(!fromBatch && (String.isBlank(ipScrub.Access_Token_Issues_API__c ) || Datetime.now() >= ipScrub.Token_Expiry_Date_Issues_API__c))
        {
            //Get the token
            getAccessToken();
            //Reduce the available API call count
            apiCount--;
            //Prevent further token calls
            updateToken = true;
        }
        //If the token is active, retrieve it
        else
        {
        	accessToken = ipScrub.Access_Token_Issues_API__c;    
        }       
        //if the token call fails, exit the method
        if(String.isBlank(accessToken))
        {
            system.debug('TOKEN BLANK');
			PSA_AutoCreateProjectUtil.sendErrorMails('Siebel Activity Sync: Error Getting Access Token!',
                    'The JSON:' + wrapperJSON);                 
            return null;
        }
        system.debug('Token not blank');
        
        //parse the wrapper list
        List<IssueActivityWrapper> wrapperList = (List<IssueActivityWrapper>)JSON.deserialize(wrapperJSON, List<IssueActivityWrapper>.class);
        System.debug('### POST Activity');  
        //Map stores the unique key to staging record
		Map<String, SC_CaseIssueStaging__c> keyToWrapper = new Map<String, SC_CaseIssueStaging__c>();
		//List of staging records to upsert
        List<SC_CaseIssueStaging__c> stagingUpsertList = new List<SC_CaseIssueStaging__c>();
		//The List of upsert results
        List<Database.UpsertResult> upsertResultRecords = new List<Database.UpsertResult>();
        //The errored record list
        List<SC_CaseIssueStaging__c> erroredList = new List<SC_CaseIssueStaging__c>();
        //The iterative staging object
        SC_CaseIssueStaging__c stagingRecord;
        //The iterative wrapper record
        IssueActivityWrapper wrapperRecord;
        
        //string that stores if the operation to be made is post or patch
        String method;
        List<String> reponseList;
        //the task description
        String description; 
        
        //If the method is called on task update, query for the existing staging records
        if(!isInsert)
        {
            //get the staging records and prepare a map of unique key to staging record
            for (SC_CaseIssueStaging__c caseIssueRecord: [Select Id,Last_Successful_Sync_Time__c,Last_Sync_Message__c,
                                                            Last_Sync_Status__c,Siebel_Integration_Id__c,Unique_Key__c,Retry_Count__c from SC_CaseIssueStaging__c
                                                           where Unique_Key__c in :uniqueKeys])
            {
                keyToWrapper.put(caseIssueRecord.Unique_Key__c,caseIssueRecord);
            }
            
        }
		//The for loop to make the API calls. the limit is apiCount or wrapperList.size(); whichever is smaller
		for(Integer index = 0; index < apiCount && index < wrapperList.size(); index++)        
        {
            System.debug('Here! inside for: ' + ' index: '+ index + ' apiCount: '+apiCount  );
            //get the current wrapper record
            wrapperRecord = wrapperList.get(index);
            
            //if the staging record exists for the wrapper, fetch it
            if(!isInsert && keyToWrapper.containsKey(wrapperRecord.uniqueKey))
            {
            	stagingRecord = keyToWrapper.get(wrapperRecord.uniqueKey);    
            }
            //Create a new staging record
            else
            {
                System.debug('New record');
                stagingRecord = new SC_CaseIssueStaging__c(Activity_Id__c=wrapperRecord.activityId,Issue__c=wrapperRecord.issueId,
                                                          Unique_Key__c=wrapperRecord.uniqueKey,Case__c=wrapperRecord.caseId, Retry_Count__c = retryCount);
            }
            postBody = new Map<String,String>();
            
            //prepare the post body:
            //Set the Description attribute to CaseNumber
            postBody.put('description',wrapperRecord.caseNumber);

            //if the description is null, set as blank
            description = wrapperRecord.description == null? '':wrapperRecord.description.length() > commentLimit?wrapperRecord.description.substring(0, commentLimit) : wrapperRecord.description;
            //Set the task description to Comment attribute
            postBody.put('comment',description);
            
            //Set the method as POST
            method = 'POST';
            if(stagingRecord.Siebel_Integration_Id__c != null)
            {
                //Set the activity id
               	method = 'PATCH';
                postBody.put('activityId',stagingRecord.Siebel_Integration_Id__c);                
            }
            //call the method to make the POST call
	        reponseList = postRequest(method, wrapperRecord.issueId);
            
            System.debug('Got res: '+ reponseList);
            //The response is not null
            if(reponseList != null)
            {
                //on success
				if (reponseList.get(0) == 'Success')
                {
                    //Set the last successful sync time, the status and the integration id on create
                    stagingRecord.Last_Successful_Sync_Time__c = DateTime.now();
                    stagingRecord.Last_Sync_Status__c = 'Success';
                    stagingRecord.Last_Sync_Message__c = 'Success';
                    stagingRecord.Siebel_Integration_Id__c = stagingRecord.Siebel_Integration_Id__c == null 
                        && reponseList.size() == 2?
                        reponseList.get(1) :stagingRecord.Siebel_Integration_Id__c;
                    stagingRecord.Retry_Count__c = retryCount;
                }
                else
                {
                    //on failure, set the error message
                    if(fromBatch)
                    {
                        stagingRecord.Retry_Count__c--;
                    }
                    stagingRecord.Last_Sync_Status__c = 'Failure';
                    stagingRecord.Last_Sync_Message__c = reponseList.get(1);
                }
                //If the operation is an update, include record for upsert
                stagingUpsertList.add(stagingRecord);
                //if the operation is a insert and the record has not been created, then include for error email
                if(stagingRecord.Siebel_Integration_Id__c == null)
                {
                    erroredList.add(stagingRecord);
                }
                
            }
        }
		
        String emailBody = '';
        //if there were more records to upsert, than the callout limit, then add the missed records to the email
        if(wrapperList.size() > apiCount)
        {
            emailBody += '<p>The Batch had more records than the system callout limits:</p>';
            for(Integer index = apiCount; index < wrapperList.size(); index++)
            {
                wrapperRecord = wrapperList.get(index);
                emailBody += '<p>' + JSON.serialize(wrapperList.get(index)) + '</p>';
                stagingRecord = new SC_CaseIssueStaging__c(Activity_Id__c=wrapperRecord.activityId,Issue__c=wrapperRecord.issueId,
                                                          Unique_Key__c=wrapperRecord.uniqueKey,Case__c=wrapperRecord.caseId,
                                                          Last_Sync_Status__c = 'Not Processed',Last_Sync_Message__c = 'Record exceeded the callout system limits',
                                                           Retry_Count__c = retryCount);                                    
				stagingUpsertList.add(stagingRecord);                
            }
        }

        //If the records to upsert are not empty, upsert
        if(!stagingUpsertList.isEmpty())
        {
            system.debug('before Upsert!!');
       		upsertResultRecords = Database.upsert(stagingUpsertList,false);
            //call the method to create a table with error messages
            emailBody += PopulateErrorTableForUpsert(upsertResultRecords,stagingUpsertList, 'Salesforce to Siebel Activity Sync Error');
        }
        //if there has been a token update, then update the custom setting
        if(updateToken)
        {
            ipScrub.Access_Token_Issues_API__c = accessToken;
            ipScrub.Token_Expiry_Date_Issues_API__c=  Datetime.now().addHours(12);
            try
            {
                update ipScrub;
            }
            Catch(Exception e)
            {
                //on failure, include the error message
            	emailBody += '<p>The access token update failed!: ' + e.getMessage() + '</p>';
            }
            
        }
        //add the errored records to the email
        if(!erroredList.isempty())
        {
            emailBody += '<p>Record not inserted: </p>' + erroredList;
        }        
        //if the email body is not null, send the email to services-engg mailing list
        if(!String.isBlank(emailBody) && !fromBatch)
        {
	        PSA_AutoCreateProjectUtil.sendErrorMails('Siebel Activity Sync Summary:',emailBody);     
            return null;
        }
		
        return emailBody;
    }
    
    //Function 6: method called from the task trigger
    public void checkForNOCCCase(Map<Id,Task> newMap, Map<Id,Task> oldMap, Boolean isInsert)
    {
        //List to store the keywords the task subject should not contain
		List<String> subjectFilter = new List<String>();
		//List of eligible case sub types
        List<String> subTypeFilter = new List<String>();
        //Set of unique keys
        Set<String> uniqueKeys = new Set<String>();
        //Map of task id to case id
        Map<Id,Id> activityToCase = new Map<Id,Id>();
        //map of case id to record
        Map<Id,Case> idToCase;
        //list of wrappers
        List<IssueActivityWrapper> wrapperList = new List<IssueActivityWrapper>();
        
        IssueActivityWrapper wrapper;
        Task taskRec;
        Case caseRec;
        
        //from the metadata, get the list of subject keywords and the case sub types
        for (SC_Utility__mdt utilRecord: [Select id,developername, Value_Text__c ,Value__c  from SC_Utility__mdt where 
                                          Active__c = true and developername in ('CaseIssueSyncSubject','CaseIssueSyncSubType')])
        {
            if(utilRecord.developername == 'CaseIssueSyncSubject')
            {
                subjectFilter = utilRecord.Value__c.split(',');
            }
            else
            {
                subTypeFilter = utilRecord.Value_Text__c.split(',');
            }
        }
        // Boolean to confirm that the task subject does not have the keywords listed
        Boolean validTask = true;
        //loop through the new map
        for(Id taskId: newMap.keySet())
        {
            //get the task record
            taskRec = newMap.get(taskId);
            validTask = true;
            // if its an insert or if there is change in the task description and the whatid is a case
            //changes for ESESP-4302
            if((isInsert || (oldMap != null && taskRec.Description != oldMap.get(taskRec.id).Description)) 
               && taskRec.WhatId != null && String.valueOf(taskRec.WhatId).startsWith('500'))
            {
                //check if the task subject doesnt contain the keywords
                for(String eachSubject: subjectFilter)
                {
                    if(taskRec.Subject != null && taskRec.Subject.contains(eachSubject))
                    {
                        validTask = false;
                    }
                }
                //if the task is valid, add to the map
                if(validTask)
                {
                    activityToCase.put(taskRec.Id,taskRec.WhatId);
                    //{taskRec.AKAM_Activity_ID__c,taskRec.Description}
                }
            }
        }
        //system.debug('caseToActivity: '+ caseToActivity + ' subTypeFilter: ' + subTypeFilter);
        //if the map activityToCase is not empty
        if(!activityToCase.isEmpty())
        {
            String uniqueKey;
            //get the cases which have the recordtype as Technical and the list of valid subtypes: 
            //For NOCC, its CMP Alerts and NIE/NOCC Request
            //and the case should have the issue populated
            idToCase = new Map<Id,Case>([Select Id, CaseNumber, AKAM_Case_ID__c, Issue__c from Case where RecordType.Name= 'Technical'
                              and Sub_Type__c in :subTypeFilter and Issue__c != null and Id in :activityToCase.values()]);
            
            //for each eligible task
            for(Id taskId: activityToCase.keySet())
            {	
                //if the Task has an eligible case
                if(idToCase.containsKey(activityToCase.get(taskId)))
                {
                    //case the case record
                    caseRec = idToCase.get(activityToCase.get(taskId));
                    //Get the task record
                    taskRec = newMap.get(taskId);
                    //prepare the unique key: case Id + issue id + activity id
                    uniqueKey = caseRec.AKAM_Case_ID__c + caseRec.Issue__c + taskRec.AKAM_Activity_ID__c;
                    uniqueKeys.add(uniqueKey);
                    //create the wrapper
                    wrapper = new IssueActivityWrapper(taskRec.AKAM_Activity_ID__c,caseRec.Id, caseRec.AKAM_Case_ID__c
                                       ,caseRec.CaseNumber, caseRec.Issue__c, uniqueKey, 
                                        taskRec.Description);
                    wrapperList.add(wrapper);
                    
                }
                //system.debug('Inside For: '+ wrapper);
            }
            //if the wrapper is not empty, call the future method
         	if(!wrapperList.isEmpty())
            {
            	syncActivitySiebelFuture(JSON.serialize(wrapperList),uniqueKeys,isInsert, false);    
            }
        }
    }
    
    //function 7: the method to populate the error table on upsert
    public static String PopulateErrorTableForUpsert(List<Database.UpsertResult> results,List<Sobject> records, String caption)
    {
        String errors = '';            
        String table = ''; 
        Database.UpsertResult sr;
        //loop through the upsert result records. get the error code and message if any
        for (Integer index = 0; index < results.size(); index++)
        {
            sr = results.get(index);
            if (!sr.isSuccess()) 
            {
                for(Database.Error err : sr.getErrors()) 
                {
                   errors += '<tr><td>' +records.get(index) + '</td><td>' + err.getStatusCode() + ': ' + err.getMessage() + '</td><td>'+ err.getFields() + '</td></tr>';
                }
            }
        }
        if(errors != '')
        {
          table = '<table><caption><b>' +caption + '</b></caption><tr>' +'<th>The Record </th>' +'<th>The error in Record </th>' + '<th> The fields that affected this error </th></tr>';
          table += errors;
          table += '</table><br/><br/>';  
        }
        return table;
    }

    
    
        
}