public class PSA_TimecardApproverChangeBatch implements Database.Batchable<sObject>,Database.Stateful {
	
	String query;
	//Set of userIds
	public Set<Id> userIds;
	//Set of timecard Ids
	public Set<Id> timecardIDs;
    //map if user id to map of name -> value and email -> value
    public Map<Id,Map<String,String>> userIdToNameEmail;
    // Map of project id to set of resources: Mails have to be sent to the resources once for every project
    public Map<Id,Set<Id>> projectIdtoResources;
    // map of project Id to approver Id
    public Map<Id,Id>projectIdtoApprover;

    public String timecardLimitCustomSetting;
    public Integer recordLimit;

	public List<PSA_Timecards_Approver_Change__c> approverChangeRecords;
	public Map<Id,PSA_Timecards_Approver_Change__c> timecardToApproverChangeRecords;
	
	public PSA_TimecardApproverChangeBatch() 
	{
		//timecardLimitCustomSetting = PSA_Settings__c.getInstance('Work Item Limit').Value__c;
		timecardLimitCustomSetting = [select Value_Long__c from PSA_Common_Setting__mdt where Name__c ='Work Item Limit' limit 1].Value_Long__c;
		recordLimit = Integer.valueOf(timecardLimitCustomSetting);
		userIdToNameEmail = new Map<Id,Map<String,String>>();
		projectIdtoResources = new Map<Id,Set<Id>>();
		timecardIDs = new Set<ID>();
		projectIdtoApprover = new Map<Id,Id>();
		userIdToNameEmail =  new Map<Id,Map<String,String>> ();	
		userIds = new Set<Id>();
		approverChangeRecords = new List<PSA_Timecards_Approver_Change__c>();
		timecardToApproverChangeRecords  = new Map<Id,PSA_Timecards_Approver_Change__c>();

	}

	
	public Database.QueryLocator start(Database.BatchableContext BC) 
	{

		query = 'select id,New_Approver__c,New_Approver__r.name,New_Approver__r.email,New_Approver__r.IsActive,Old_Approver__c,Timecard__c,IsProcessed__c from PSA_Timecards_Approver_Change__c where IsProcessed__c = false order by createddate desc';

		if(Test.isRunningTest())
		{
			query += ' limit 2';
		}
		return Database.getQueryLocator(query);
	}

   	public void execute(Database.BatchableContext BC, List<sObject> scope) 
   	{
    	// stores the failure count
    	Integer failureCount;    
    	// map of Id to timecard record
    	Map<id,pse__Timecard_header__c> tcs; 

    	// map of Id to ProcessInstanceWorkitem record
    	Map <Id,ProcessInstanceWorkitem> pwis;
    	// List of ProcessInstanceWorkitem to update
    	List <ProcessInstanceWorkitem> pwisToUpdate;
    	// List of the save result records
    	List<Database.SaveResult> saveResultRecords = new List<Database.SaveResult>();
    	// Stores a Timecard record
    	pse__Timecard_header__c timecard;
    	//variables to store ProcessInstanceWorkitem
    	ProcessInstanceWorkitem pIWI;
    	ProcessInstanceWorkItem p;
    	Id timecardId;

    	approverChangeRecords = (List<PSA_Timecards_Approver_Change__c>)scope;
		
		for (PSA_Timecards_Approver_Change__c approverChange : approverChangeRecords)
		{
			if(!timecardToApproverChangeRecords.containsKey(approverChange.Timecard__c))
			{
				timecardToApproverChangeRecords.put(approverChange.Timecard__c,approverChange);	
				userIds.add(approverChange.Old_Approver__c);
				if(!userIdToNameEmail.containsKey(approverChange.New_Approver__c))
				{
					userIdToNameEmail.put(approverChange.New_Approver__c,new Map<String,String>());
					userIdToNameEmail.get(approverChange.New_Approver__c).put('Name',approverChange.New_Approver__r.Name);
					userIdToNameEmail.get(approverChange.New_Approver__c).put('Email',approverChange.New_Approver__r.Email);							
				}

			}
        				 		
		}

		tcs = new Map<id,pse__Timecard_header__c>([select id,pse__Resource__r.Email,pse__Project__c,pse__Project__r.name,pse__Resource__r.Name,pse__Project__r.pse__Project_Manager__r.email,pse__Project__r.pse__Project_Manager__r.pse__Salesforce_User__c,pse__Project__r.pse__Project_Manager__r.name,pse__Resource__r.pse__Salesforce_User__r.Manager.name,pse__Resource__r.pse__Salesforce_User__r.Manager.Email,pse__Resource__r.pse__Salesforce_User__r.ManagerId from pse__Timecard_header__c  where pse__Status__c = 'Submitted' and id in :timecardToApproverChangeRecords.keyset()]);
		
		 if(tcs != null && tcs.size() > 0)
		 {
		 	// Query for the ProcessInstanceWorkitem records, which are in the Pending state, targetObjectID is in tcs.keyset and the actors/approvers are in the userIds set
		    pwis = new Map <Id,ProcessInstanceWorkitem>([select Id,ProcessInstance.TargetObjectId,ActorId
	        		from ProcessInstanceWorkitem  where Processinstance.Status = 'Pending' 
	        		and  ProcessInstance.TargetObjectId in :tcs.keySet() and ActorId in :userIds limit :recordLimit]) ;
		    //Check if pwis is not null and has an entry
	        if(pwis != null && pwis.size() > 0)
	        {		        			        	
		        pwisToUpdate = new  List <ProcessInstanceWorkitem>();
		        // loop through the pwis.keySet
		        for (Id pId : pwis.keySet())
		        {
		        	// Get th corresponding ProcessInstanceWorkitem record. 	
		        	p = pwis.get(pId);
		        	timecardId = p.ProcessInstance.TargetObjectId;
		        	// Check if tcs contains the TargetObjectId of p and the actor id should be the corresponding project's old project manager
		        	if(tcs.containsKey(timecardId) && p.ActorId == timecardToApproverChangeRecords.get(timecardId).Old_Approver__c )
		        	{
		        		// Assign the new actor/approver -> the latest project manager of the project
		        		// If the resource is the project manager, then the approver is the manager of the resource			        		
						p.ActorId = timecardToApproverChangeRecords.get(p.ProcessInstance.TargetObjectId).New_Approver__c;
						pwisToUpdate.add(p);
		        	}
		        }
		        //Check if the list pwisToUpdate is not null and has an entry
		        if(pwisToUpdate != null && pwisToUpdate.size() > 0)
		        {			        	
		        	try
		        	{
			        	saveResultRecords = Database.update(pwisToUpdate,false);
			        	failureCount = PopulateErrorTableForUpdate(saveResultRecords,pwisToUpdate,tcs);	
		        	}
		        	catch(Exception e)
		        	{
		        		sendErrorMails('Timecard Approver Update Exception',e.getMessage());
            			//return;
		        	}

		        }

	        }		
	        

		 }

		List<PSA_Timecards_Approver_Change__c> approverChangesToUpdate = new List<PSA_Timecards_Approver_Change__c>();
		for (PSA_Timecards_Approver_Change__c approverChange : approverChangeRecords)
		{
        		approverChange.IsProcessed__c = true;
        		approverChangesToUpdate.add(approverChange);		 		
		}
		Database.update(approverChangesToUpdate,false);

	
	}
	
	// Function called to loop though the update results, send mails to the new approver and resource and to send error mails
    public Integer PopulateErrorTableForUpdate(List<Database.SaveResult> results,List<ProcessInstanceWorkitem> objectLists,Map<id,pse__Timecard_header__c> timecardsMap)
    {
        String Errors = '';            
        String Table = ''; 
        Integer errorCount = 0;
        Database.SaveResult sr;
        Messaging.SingleEmailMessage[] mailsToBeSent = new List<Messaging.SingleEmailMessage>();
        Messaging.Singleemailmessage objEmail;
        String Body = '';
        // The subject is set to 'Timecard Approver Change'
        String Subject = 'Timecard Approver Change';
        pse__Timecard_header__c successTimecard;
        String approverName = '';
        String approverEmail = '';
        String projectLink = '';

        // loop through the results
        for(Integer i = 0; results != null && objectLists != null && timecardsMap != null && i < results.size(); i++)
        {
        	// get the current result record
          	sr = results.get(i);
          	// Check for failure
            if (!sr.isSuccess()) 
            {	
            	//increment the error count; once for the current record
            	errorCount++;
            	// Populate the error table
                for(Database.Error err : sr.getErrors()) 
                {                	
                    Errors += '<tr><td>' + err.getStatusCode() + ': ' + err.getMessage() + '</td><td>'+ objectLists.get(i).id + '</td></tr>';
                }
            }
            else
            {
            	// Success case
            	// Get the timecard record
            	successTimecard = timecardsMap.get(objectLists.get(i).ProcessInstance.TargetObjectId);  
            	// populate the project link; A href link to the project with the name
            	projectLink = '<a href = "' +URL.getSalesforceBaseUrl().toExternalForm() + '/' + successTimecard.pse__Project__c+ '">'+successTimecard.pse__Project__r.Name + '</a>';
            	
            	//Check if there is an entry for the actor in the userIdToNameEmail map
	        	if(userIdToNameEmail.containsKey(objectLists.get(i).ActorId))
	        	{
	        		approverName = userIdToNameEmail.get(objectLists.get(i).ActorId).get('Name');	
	        		approverEmail = userIdToNameEmail.get(objectLists.get(i).ActorId).get('Email');
	        	}

		        //Check if the map projectIdtoResources already has an entry for the project and doesnt have an entry for the current resource or if there is no entry for the project
            	if((projectIdtoResources.containsKey(successTimecard.pse__Project__c) && projectIdtoResources.get(successTimecard.pse__Project__c) != null && !projectIdtoResources.get(successTimecard.pse__Project__c).contains(successTimecard.pse__Resource__c) ) || !projectIdtoResources.containsKey(successTimecard.pse__Project__c))
            	{
            		// Check for an entry in the projectIdtoResources map and add the entry for the project and resource
            		if(!projectIdtoResources.containsKey(successTimecard.pse__Project__c))
            		{
	            		projectIdtoResources.put(successTimecard.pse__Project__c,new Set<Id>());	            		

            		}
            		// Add the resource to the map
        			projectIdtoResources.get(successTimecard.pse__Project__c).add(successTimecard.pse__Resource__c);	
        			// Send an email to the current resource -> Informing the approver change 	       
			        objEmail = new Messaging.Singleemailmessage();
			        objEmail.setReplyTo('noreply@akamai.com');
			        objEmail.setToAddresses(new list<String>{successTimecard.pse__Resource__r.email});            
			        objEmail.setSubject(Subject);
			        Body = 'Hi '+ successTimecard.pse__Resource__r.name + '<br/><br/>The Approver for your submitted timecards against the  project ' +  projectLink  + ' has been changed to ' + approverName;
			        objEmail.setHTMLBody(Body);
			        mailsToBeSent.add(objEmail); 
			        // Check if there is an entry for the project in the projectIdtoApprover map. If not, then send an email -> informing that he has become the approver for the timecards submitted against the project
			        if(!projectIdtoApprover.containsKey(successTimecard.pse__Project__c))
			        {			        	
			        	projectIdtoApprover.put(successTimecard.pse__Project__c,objectLists.get(i).ActorId);	
				        objEmail = new Messaging.Singleemailmessage();
				        objEmail.setReplyTo('noreply@akamai.com');
				        objEmail.setToAddresses(new list<String>{approverEmail});            
				        objEmail.setSubject(Subject);
				        Body = 'Hi '+ approverName + '<br/><br/>You have been assigned the Approver for the timecards submitted against the project ' + projectLink;
				        objEmail.setHTMLBody(Body);
				        mailsToBeSent.add(objEmail);  

				    }
            		
            	}

            }

        }
        //If there are errors, call the sendErrorMails function
        if(Errors != '')
        {
          Table = '<table><tr><th>' + 'The error in Record </th>' + '<th> The Record ID </th></tr>';
          Table += Errors;
          Table += '</table><br/><br/>';          
          sendErrorMails('Update Failed: ' + '',Table);
        }
        if(mailsToBeSent != null && mailsToBeSent.size() > 0)
        {
        	Messaging.sendEmail(mailsToBeSent,false);	
        }
        
        return errorCount;
        
    }
    // function to send error mails
    public  void sendErrorMails(String Subject, String Error)
    {

        if(Error == '')
        {
          return;
        }
        // Send an email to the engineering team -> including the error table
        PSA_Settings__c EnggEmail = PSA_Settings__c.getInstance('Engineering Team Email');  
        String Body = '<html><style> table {border-collapse: collapse;} td,th {border: 1px solid black;}</style><body>Hi ' + UserInfo.getName() + ',<br/><br/>';  
        Body += Error;
        Body += '</body></html>';
        Messaging.SingleEmailMessage[] mailsToBeSent1 = new List<Messaging.SingleEmailMessage>();
        Messaging.Singleemailmessage objEmail1;
        objEmail1 = new Messaging.Singleemailmessage();
        objEmail1.setReplyTo('noreply@akamai.com');
        objEmail1.setToAddresses(new list<String>{EnggEmail.Value__c});            
        objEmail1.setSubject(Subject);
        objEmail1.setHTMLBody( Body );
        mailsToBeSent1.add(objEmail1);
        Messaging.sendEmail(mailsToBeSent1,false);

    }

	public void finish(Database.BatchableContext BC) 
	{
				
	}
	
}