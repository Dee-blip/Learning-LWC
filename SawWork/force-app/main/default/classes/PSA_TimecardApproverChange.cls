/*
 * CR: 3593271
 * Developer: Sharath Prasanna
 * Enhancement: Change the timecard approver based on the three use cases: Project manager change, Approver manager changes and Re-assigned approver becomes inactive
 * Date: 20th December 2016
 * 
*/ 
public class PSA_TimecardApproverChange implements Queueable 
{
	// The queryType classifies the use case
	// the values are 'project' -> project manager change, 'ManagerChange' -> Approver manager changes and the timecard are assigned to the manager, 'UserInactive' -> timecards are re-assigned to a user and the user becomes inactive
	public String queryType;
	// Map of projects to list of contacts: used in case 1 -> project 
	public Map<id,List<Contact>> projectToContacts;
	//Set of userIds
	public Set<Id> userIds;
	//Set of timecard Ids
	public Set<Id> timecardIDs;
	// Map of user id to managers -> case 2
	public Map<Id,List<Id>> userIdToManagers;
	// map of Id to contact
    public Map<Id,Contact> IdToContact;
    // set of user ids
    public Set<Id> inactiveUsers;

	public void execute(QueueableContext context) 
	{	
		// stores the number of timecards to update	
    	Integer workItemsToUpdate;
    	// stores the failure count
    	Integer failureCount;    
    	// map of Id to timecard record
    	Map<id,pse__Timecard_header__c> tcs;
    	List<PSA_Timecards_Approver_Change__c> existingTimecardChanges = new List<PSA_Timecards_Approver_Change__c>();
    	Map<Id,PSA_Timecards_Approver_Change__c> timecardToChanges = new Map<Id,PSA_Timecards_Approver_Change__c>();
    	//Get the custom setting value: Work Item Limit -> number of records to process per batch
    	String timecardLimitCustomSetting = PSA_Settings__c.getInstance('Work Item Limit').Value__c;
    	// convert the limit to Integer
    	Integer recordLimit = Integer.valueOf(timecardLimitCustomSetting);
    	// map of Id to ProcessInstanceWorkitem record
    	Map <Id,ProcessInstanceWorkitem> pwis;
    	// List of ProcessInstanceWorkitem to update
    	//List <ProcessInstanceWorkitem> pwisToUpdate;
    	// List of the save result records
    	List<Database.SaveResult> saveResultRecords = new List<Database.SaveResult>();
    	List<Database.UpsertResult> upsertResultRecords = new List<Database.UpsertResult>();
    	// Map of UserId to contact record
    	Map<Id,Contact> userIDtoContact;
    	// Stores a Timecard record
    	pse__Timecard_header__c timecard;
    	// Map of id to ProcessInstanceWorkitem record
    	Map<id,ProcessInstanceWorkitem> currentTimecardIds;
    	//variables to store ProcessInstanceWorkitem
    	ProcessInstanceWorkitem pIWI;
    	ProcessInstanceWorkItem p;
    	//the PSA_TimecardApproverChange object
    	PSA_TimecardApproverChange timecardApproverChange1;
        PSA_Timecards_Approver_Change__c approverChange;
        List<PSA_Timecards_Approver_Change__c> approverChangeRecords = new List<PSA_Timecards_Approver_Change__c>();


    	// CASE 1: project manager change
    	if(queryType == 'project' && projectToContacts != null && projectToContacts.size() > 0 )
    	{
    		 // timecardIDs stores the timecards already processed	

    		 if(timecardIDs == null )
    		 {
    		 	timecardIDs = new Set<id>();	
    		 }	
    		 //query for the timecards which are submitted, project is in the projectToContacts keyset and id not in the timecardIDs set
    		 tcs = new Map<id,pse__Timecard_header__c>([select id,pse__Resource__r.Email,pse__Project__c,pse__Project__r.name,pse__Resource__r.Name,pse__Project__r.pse__Project_Manager__r.email,pse__Project__r.pse__Project_Manager__r.pse__Salesforce_User__c,pse__Project__r.pse__Project_Manager__r.name,pse__Resource__r.pse__Salesforce_User__r.Manager.name,pse__Resource__r.pse__Salesforce_User__r.Manager.Email,pse__Resource__r.pse__Salesforce_User__r.ManagerId from pse__Timecard_header__c 
    		 											where pse__Status__c = 'Submitted' 
    		 											and pse__Project__c in :projectToContacts.keySet() and id not in :timecardIDs limit :recordLimit]);
    		 // Check if tcs is not null and has an entry
    		 if(tcs != null && tcs.size() > 0)
    		 {
    		 	//existingTimecardChanges = new List<PSA_Timecards_Approver_Change__c>([select id, Old_Approver__c, New_Approver__c, timecard__c from PSA_Timecards_Approver_Change__c where timecard__c in :tcs.keySet()]);
    		 	existingTimecardChanges = [select id, Old_Approver__c, New_Approver__c, timecard__c from PSA_Timecards_Approver_Change__c where timecard__c in :tcs.keySet() and IsProcessed__c = false limit :recordLimit];
    		 	if(existingTimecardChanges != null && 	existingTimecardChanges.size() > 0)
    		 	{
    		 		for(PSA_Timecards_Approver_Change__c changeRecord: existingTimecardChanges)
    		 		{
    		 			if(!timecardToChanges.containsKey(changeRecord.timecard__c))
    		 			{
    		 				timecardToChanges.put(changeRecord.timecard__c,changeRecord);	
    		 			}    		 			
    		 		}
    		 	}
    		 	// Query for the ProcessInstanceWorkitem records, which are in the Pending state, targetObjectID is in tcs.keyset and the actors/approvers are in the userIds set
			    pwis = new Map <Id,ProcessInstanceWorkitem>([select Id,ProcessInstance.TargetObjectId,ActorId
		        		from ProcessInstanceWorkitem  where Processinstance.Status = 'Pending' 
		        		and  ProcessInstance.TargetObjectId in :tcs.keySet() limit :recordLimit]) ;
			    //Check if pwis is not null and has an entry
		        if(pwis != null && pwis.size() > 0)
		        {		        			        	
			        //pwisToUpdate = new  List <ProcessInstanceWorkitem>();
			        // loop through the pwis.keySet
			        for (Id pId : pwis.keySet())
			        {
			        	// Get th corresponding ProcessInstanceWorkitem record. 	
			        	p = pwis.get(pId);
			        	// Check if tcs contains the TargetObjectId of p and the actor id should be the corresponding project's old project manager
			        	approverChange = null;
			        	if(tcs.containsKey(p.ProcessInstance.TargetObjectId))
			        	{
			        		// Assign the new actor/approver -> the latest project manager of the project
			        		// If the resource is the project manager, then the approver is the manager of the resource	
			        		if(timecardToChanges.containsKey(p.ProcessInstance.TargetObjectId) && timecardToChanges.get(p.ProcessInstance.TargetObjectId).New_Approver__c == projectToContacts.get(tcs.get(p.ProcessInstance.TargetObjectId).pse__Project__c).get(0).pse__Salesforce_User__c)
			        		{
			        			approverChange = timecardToChanges.get(p.ProcessInstance.TargetObjectId);
			        		}	       
			        		else if(p.ActorId == projectToContacts.get(tcs.get(p.ProcessInstance.TargetObjectId).pse__Project__c).get(0).pse__Salesforce_User__c )
			        		{
						        approverChange = new PSA_Timecards_Approver_Change__c();						        
						        approverChange.Old_Approver__c = p.ActorId;
						        approverChange.Timecard__c = p.ProcessInstance.TargetObjectId;
			        		}	
			        		if (approverChange != null)
			        		{
				        		if(projectToContacts.get(tcs.get(p.ProcessInstance.TargetObjectId).pse__Project__c).get(1).pse__Salesforce_User__c == tcs.get(p.ProcessInstance.TargetObjectId).pse__Resource__r.pse__Salesforce_User__c)
				        		{
				        			approverChange.New_Approver__c = tcs.get(p.ProcessInstance.TargetObjectId).pse__Resource__r.pse__Salesforce_User__r.ManagerId;
				        		}
				        		else
				        		{
						            approverChange.New_Approver__c = projectToContacts.get(tcs.get(p.ProcessInstance.TargetObjectId).pse__Project__c).get(1).pse__Salesforce_User__c;  
				        		}
				        		if(approverChange.Old_Approver__c == approverChange.New_Approver__c)
				        		{
				        			approverChange.IsProcessed__c = true;	
				        		}
					            approverChangeRecords.add(approverChange);

			        		}
					        
			        	}
			        }
			        //Check if the list pwisToUpdate is not null and has an entry
			        if(approverChangeRecords != null && approverChangeRecords.size() > 0)
			        {			        	
			        	try
			        	{
			        		// get the number of workItems to update
			        		workItemsToUpdate = approverChangeRecords.size();
			        		// Update the records and get the failure count
				        	upsertResultRecords = Database.Upsert(approverChangeRecords,false);
				        	failureCount = PopulateErrorTableForUpsert(upsertResultRecords,approverChangeRecords,tcs);	
				        	// if the failureCount is lower than the number of records to update, then enqueue the timecardApproverChange1 object. The query type is project.
				        	// this check will stop the process if the number of records to update is 0 or if the failureCount is equal to the number of timecards to update. If the process fails to update all the timecards, stop the process.
				        	if(failureCount < workItemsToUpdate)
				        	{
				                timecardApproverChange1 = new PSA_TimecardApproverChange();
				                timecardIDs.addAll(tcs.keySet());
				                timecardApproverChange1.queryType = 'project';
				                timecardApproverChange1.projectToContacts = projectToContacts;
				                timecardApproverChange1.userIds = userIds;
				                timecardApproverChange1.timecardIDs = timecardIDs;
				                System.enqueueJob(timecardApproverChange1);				        		
				        	}		        		
			        	}
			        	catch(Exception e)
			        	{
			        		sendErrorMails('Timecard Approver Update Exception',e.getMessage());
                			//return;
			        	}

			        }

		        }		
		        

    		 }

    	}
    	// CASE 2: the user manager changesa and the user is a project manager who has submitted timecards. Change the approver of those timecards
    	else if (queryType == 'ManagerChange' && userIdToManagers != null && userIdToManagers.size() > 0)
    	{
    		 // timecardIDs stores the timecards already processed	
    		 if(timecardIDs == null )
    		 {
    		 	timecardIDs = new Set<id>();	
    		 }	
    		 // Query the timecards which are submitted, resource is in the IdToContact map -> the current user whose manager changes and id not in the set timecardIDs.
    		 //tcs = new Map<id,pse__Timecard_header__c>([select id,pse__Resource__r.Email,pse__Project__c,pse__Project__r.name,pse__Project__r.pse__Project_Manager__c,pse__Resource__r.pse__Salesforce_User__c,pse__Resource__r.pse__Salesforce_User__r.ManagerId,pse__Resource__c,pse__Resource__r.Name,pse__Project__r.pse__Project_Manager__r.email,pse__Project__r.pse__Project_Manager__r.pse__Salesforce_User__c,pse__Project__r.pse__Project_Manager__r.name 
    		 //											from pse__Timecard_header__c 
    		 //											where pse__Status__c = 'Submitted' and pse__Resource__c in :IdToContact.keySet() 
    		 //											and pse__project__r.pse__Project_Manager__c in :IdToContact.keySet()
    		 //											and id not in :timecardIDs limit :recordLimit]);

    		 tcs = new Map<id,pse__Timecard_header__c>([select id,pse__Resource__r.Email,pse__Project__c,pse__Project__r.name,pse__Project__r.pse__Project_Manager__c,pse__Resource__r.pse__Salesforce_User__c,pse__Resource__r.pse__Salesforce_User__r.ManagerId,pse__Resource__c,pse__Resource__r.Name,pse__Project__r.pse__Project_Manager__r.email,pse__Project__r.pse__Project_Manager__r.pse__Salesforce_User__c,pse__Project__r.pse__Project_Manager__r.name 
    		 											from pse__Timecard_header__c 
    		 											where pse__Status__c = 'Submitted' and pse__Resource__c in :IdToContact.keySet()     		 											
    		 											and id not in :timecardIDs limit :recordLimit]);
    		 //Check if tcs is not null and has an entry
    		 if(tcs != null && tcs.size() > 0)
    		 {   
    		 	existingTimecardChanges = [select id, Old_Approver__c, New_Approver__c, timecard__c from PSA_Timecards_Approver_Change__c where timecard__c in :tcs.keySet() and IsProcessed__c = false limit :recordLimit];
    		 	if(existingTimecardChanges != null && 	existingTimecardChanges.size() > 0)
    		 	{
    		 		for(PSA_Timecards_Approver_Change__c changeRecord: existingTimecardChanges)
    		 		{
    		 			if(!timecardToChanges.containsKey(changeRecord.timecard__c))
    		 			{
    		 				timecardToChanges.put(changeRecord.timecard__c,changeRecord);	
    		 			}    		 			
    		 		}
    		 	}

    		 	// Query for the ProcessInstanceWorkitem records, which are in the Pending state, targetObjectID is in tcs.keyset and the actors/approvers are in the userIds set

			    pwis = new Map <Id,ProcessInstanceWorkitem>([select Id,ProcessInstance.TargetObjectId,ActorId
		        		from ProcessInstanceWorkitem  where Processinstance.Status = 'Pending' 
		        		and  ProcessInstance.TargetObjectId in :tcs.keySet() limit :recordLimit]) ;
		        if(pwis != null && pwis.size() > 0)
		        {		        	
			        //pwisToUpdate = new  List <ProcessInstanceWorkitem>();
			        for (Id pId : pwis.keySet())
			        {
			        	approverChange = null;
			        	p = pwis.get(pId);			        	 
			        	if(tcs.containsKey(p.ProcessInstance.TargetObjectId))
			        	{
			        		// get the current timecard record from the tcs map
			        		timecard = tcs.get(p.ProcessInstance.TargetObjectId);
			        		// If the userIdToManagers map contains an entry for timecard.pse__Resource__r.pse__Salesforce_User__c and the actor/approver is the old manager of the current resource and the timecard resoruce is the project manager then update the approver
			        		//if(userIdToManagers.containsKey(timecard.pse__Resource__r.pse__Salesforce_User__c) && p.ActorId == (userIdToManagers.get(timecard.pse__Resource__r.pse__Salesforce_User__c))[0] && timecard.pse__Project__r.pse__Project_Manager__c == timecard.pse__Resource__c)
			        		if(userIdToManagers.containsKey(timecard.pse__Resource__r.pse__Salesforce_User__c))
			        		{
			        			// update the approver to the new manager

			        			if(timecardToChanges.containsKey(p.ProcessInstance.TargetObjectId) && timecardToChanges.get(p.ProcessInstance.TargetObjectId).New_Approver__c == (userIdToManagers.get(timecard.pse__Resource__r.pse__Salesforce_User__c))[0])
			        			{
			        				approverChange = timecardToChanges.get(p.ProcessInstance.TargetObjectId);

			        			}
			        			else if(p.ActorId == (userIdToManagers.get(timecard.pse__Resource__r.pse__Salesforce_User__c))[0])
			        			{
							        approverChange = new PSA_Timecards_Approver_Change__c();
							        
							        approverChange.Old_Approver__c = p.ActorId;
							        approverChange.Timecard__c = timecard.id;

			        			}
			        			if(approverChange != null)
			        			{
				        			if(approverChange.Old_Approver__c == approverChange.New_Approver__c)
				        			{
				        				approverChange.IsProcessed__c = true;
				        			}
				        			approverChange.New_Approver__c = (userIdToManagers.get(timecard.pse__Resource__r.pse__Salesforce_User__c))[1];
						            approverChangeRecords.add(approverChange);

			        			}

					            //p.ActorId = (userIdToManagers.get(timecard.pse__Resource__r.pse__Salesforce_User__c))[1];           
					            //pwisToUpdate.add(p);
			        		}
			        	} 
			        }
			        if(approverChangeRecords != null && approverChangeRecords.size() > 0)
			        {
			        	try
			        	{
			        		// get the number of workItems to update
			        		workItemsToUpdate = approverChangeRecords.size();
			        		// Update the records and get the failure count
				        	upsertResultRecords = Database.upsert(approverChangeRecords,false);
				        	failureCount = PopulateErrorTableForUpsert(upsertResultRecords,approverChangeRecords,tcs);	
				        	// if the failureCount is lower than the number of records to update, then enqueue the timecardApproverChange1 object. The query type is ManagerChange.
				        	// this check will stop the process if the number of records to update is 0 or if the failureCount is equal to the number of timecards to update. If the process fails to update all the timecards, stop the process.				        	
				        	if(failureCount < workItemsToUpdate)
				        	{
				                timecardApproverChange1 = new PSA_TimecardApproverChange();
				                timecardIDs.addAll(tcs.keySet());
					            timecardApproverChange1.queryType = 'ManagerChange';
					            timecardApproverChange1.userIdToManagers = userIdToManagers;
					            timecardApproverChange1.userIds = userIds;
					            timecardApproverChange1.IdToContact = IdToContact;
				                timecardApproverChange1.timecardIDs = timecardIDs;
				                System.enqueueJob(timecardApproverChange1);				        		
				        	}		        		
			        	}
			        	catch(Exception e)
			        	{
			        		sendErrorMails('Timecard Approver Update Exception',e.getMessage());
                			//return;
			        	}

			        }

		        }		
		        

    		 }


    	}
    	// CASE 3: The user is re-assigned timecards and he becomes inactive
    	else if(queryType == 'UserInactive' && inactiveUsers != null && inactiveUsers.size() > 0)
    	{
    		// timecardIDs stores the timecards already processed	
    		if(timecardIDs == null )
    		{
    		  	timecardIDs = new Set<id>();	
    		}
    		//allocate memory to the map currentTimecardIds
    		currentTimecardIds =  new Map<id,ProcessInstanceWorkitem>();	
    		//Query for the ProcessInstanceWorkitems which are in the Pending state, TargetObjectId is not in timecardIDs, Actor is in the list of inactive users and  OriginalActorId is not in th current list of inactive users.		 	
		    pwis = new Map <Id,ProcessInstanceWorkitem>([select Id,ProcessInstance.TargetObjectId,ActorId,OriginalActorId
	        		from ProcessInstanceWorkitem  where Processinstance.Status = 'Pending' 
	        		and  ProcessInstance.TargetObjectId not in :timecardIDs and ActorId in :inactiveUsers limit :recordLimit]) ;
		    // loop through the pwis.keySet
	        for(Id pId : pwis.keySet())
	        {
	        	//get the ProcessInstanceWorkitem record
	        	p = pwis.get(pId);
	        	//Check if the inactiveUsers contains the Actor and the Actor is not the OriginalActor -> original actor is the person it was re-assigned from. If a Timecard is re-assigned from user1 to user2 -> originalActor = user1 and actor = user2
	        	if(inactiveUsers.contains(p.ActorId) && p.ActorId != p.OriginalActorId)
	        	{
	        		//populate the map of timecard Id to ProcessInstanceWorkitem
	        		currentTimecardIds.put(p.ProcessInstance.TargetObjectId,p);
	        	}
	        }
	        // Query the timecards which are submitted, id not in the set timecardIDs and the Timecard's resource's manager is not in the inactiveUsers set -> dont pick up the timecards when the resource's manager becomes inactive; 
	         tcs = new Map<id,pse__Timecard_header__c>([select id,pse__Resource__r.Email,pse__Resource__r.Name,pse__Project__c,pse__Project__r.name,pse__Project__r.pse__Project_Manager__r.pse__Salesforce_User__c,pse__Project__r.pse__Project_Manager__r.pse__Salesforce_User__r.id,pse__Resource__r.pse__Salesforce_User__r.ManagerId,pse__Resource__r.pse__Salesforce_User__r.Manager.name,pse__Resource__r.pse__Salesforce_User__r.Manager.Email,pse__Resource__r.pse__Salesforce_User__c,pse__Project__r.pse__Project_Manager__r.email,pse__Project__r.pse__Project_Manager__r.name from pse__Timecard_header__c where pse__Status__c = 'Submitted' and id in :currentTimecardIds.keySet()  limit :recordLimit]);

	        if(tcs != null && tcs.size() > 0)
	        {
			 	existingTimecardChanges = [select id, Old_Approver__c, New_Approver__c, timecard__c from PSA_Timecards_Approver_Change__c where timecard__c in :tcs.keySet() and IsProcessed__c = false limit :recordLimit];
			 	if(existingTimecardChanges != null && 	existingTimecardChanges.size() > 0)
			 	{
			 		for(PSA_Timecards_Approver_Change__c changeRecord: existingTimecardChanges)
			 		{
			 			if(!timecardToChanges.containsKey(changeRecord.timecard__c))
			 			{
			 				timecardToChanges.put(changeRecord.timecard__c,changeRecord);	
			 			}    		 			
			 		}
			 	}
		        for (Id timecardID : tcs.keySet())
		        {	

		        	// get the timecard record
	        		timecard = tcs.get(timecardID);
	        		// Get the corresponding ProcessInstanceWorkitem record from currentTimecardIds
	        		pIWI = currentTimecardIds.get(timecardID);
	        		if(pIWI.ActorId != timecard.pse__Resource__r.pse__Salesforce_User__r.ManagerId && pIWI.ActorId != timecard.pse__Project__r.pse__Project_Manager__r.pse__Salesforce_User__r.id)
	        		{

	        			if(!timecardToChanges.containsKey(timecard.id))
	        			{
					        approverChange = new PSA_Timecards_Approver_Change__c();
					        
					        approverChange.Old_Approver__c = pIWI.ActorId;
					        approverChange.Timecard__c = timecard.id;
			        		if(timecard.pse__Project__r.pse__Project_Manager__r.pse__Salesforce_User__c == timecard.pse__Resource__r.pse__Salesforce_User__c || timecard.pse__Project__r.pse__Project_Manager__r.pse__Salesforce_User__c == null)
			        		{
			        			approverChange.New_Approver__c = timecard.pse__Resource__r.pse__Salesforce_User__r.ManagerId;
			        		}
			        		else
			        		{
						        approverChange.New_Approver__c = timecard.pse__Project__r.pse__Project_Manager__r.pse__Salesforce_User__c; 

			        		}
					        //pwisToUpdate.add(pIWI);	
					        approverChangeRecords.add(approverChange);        			

	        			}
		        		// update the actor to the current project manager. If the resource is the project manager, then the approver should be the manager of the resource

	        		}
		        }


	        } 
	        //pwisToUpdate = new  List <ProcessInstanceWorkitem>();
	        // loop through the tcs.keySet

	        if(approverChangeRecords != null && approverChangeRecords.size() > 0)
	        {
	        	try
	        	{
	        		workItemsToUpdate = approverChangeRecords.size();
		        	upsertResultRecords = Database.upsert(approverChangeRecords,false);
		        	failureCount = PopulateErrorTableForUpsert(upsertResultRecords,approverChangeRecords,tcs);	
		        	if(failureCount < workItemsToUpdate)
		        	{
		                timecardApproverChange1 = new PSA_TimecardApproverChange();
		                timecardIDs.addAll(tcs.keySet());
			            timecardApproverChange1.queryType = 'UserInactive';
			            timecardApproverChange1.inactiveUsers = inactiveUsers;
		                timecardApproverChange1.timecardIDs = timecardIDs;
		                System.enqueueJob(timecardApproverChange1);				        		
		        	}		        		
	        	}
	        	catch(Exception e)
	        	{
	        		sendErrorMails('Timecard Approver Update Exception',e.getMessage());
        			//return;
	        	}

	        }
			 

    	}

	}
	// Function called to loop though the update results, send mails to the new approver and resource and to send error mails
    public Integer PopulateErrorTableForUpsert(List<Database.UpsertResult> results,List<PSA_Timecards_Approver_Change__c> objectLists,Map<id,pse__Timecard_header__c> timecardsMap)
    {
        String Errors = '';            
        String Table = ''; 
        Integer errorCount = 0;
        Database.UpsertResult sr;
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

        }
        //If there are errors, call the sendErrorMails function
        if(Errors != '')
        {
          Table = '<table><tr><th>' + 'The error in Record </th>' + '<th> The Record ID </th></tr>';
          Table += Errors;
          Table += '</table><br/><br/>';          
          sendErrorMails('Upsert Failed: ' + '',Table);
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

}