/***
    Send_Notification_For_PLM_Tasks
    @author Sachin Siddaveerappa <sveerapp@akamai.com>
    @Description : This trigger sends notification on three occassion 
                   - When a PLM task due date or owner is changed
                   - 'n' days before due date. This trigger watches Associated_AKAM_Campaign_ID__c and when it is updated assumes mail 
                        has to be sent. A WFT watches due date and updates Associated_AKAM_Campaign_ID__c 'n' days before due date using
                        time based trigger
                   - 'n' days after due date is overdue. This trigger watches Associated_AKAM_Campaign_ID__c and when it is updated assumes mail 
                        has to be sent. A WFT watches due date and updates Associated_AKAM_Campaign_ID__c 'n' days before due date using
                        time based trigger
                   
*/  
trigger PLM_Send_Notification_For_Tasks on Task (before insert, before update) {
	

    if(Trigger.isUpdate){
        
        
		Id recordType = Schema.SObjectType.Task.getRecordTypeInfosByName().get('PLM Task').getRecordTypeId();
		Boolean isPlmTask = false;
     	
     	// Get all users email address and launch item details in each SOSL query to avoid breaching governor limit
     	  Set<Id> assignedUserList = new Set<Id>();
		  Set<Id> taskList = new Set<Id>();
		  Map<Id, User> userMailDetails = new Map<Id, User>();
		  Map<Id, Launch_Item__c> launchItemMap = new Map<Id, Launch_Item__c> ();
		  Organization org;
		  
		  List<Messaging.SingleEmailMessage> notifyAssignmentMailList = new List<Messaging.SingleEmailMessage>();
		  List<Messaging.SingleEmailMessage> notifyBeforeDueDateList = new List<Messaging.SingleEmailMessage>();
		  List<Messaging.SingleEmailMessage> notifyOverdueList = new List<Messaging.SingleEmailMessage>();
		  List<Messaging.SingleEmailMessage> notifyTaskCompletionList = new List<Messaging.SingleEmailMessage>();
		  
		   
		
		  for(Task t:Trigger.new){
		  		assignedUserList.add(t.OwnerId);
		  		assignedUserList.add(t.LastModifiedById);
		  		taskList.add(t.WhatId);
		  		
		  		 if(t.RecordTypeId == recordType){
		  		 	isPlmTask = true;
		  		 }
		  		
		  }
		  
		  if(isPlmTask){
		  	
		  	org = [Select division From Organization] ;
			  			  
			  for(User user: [Select u.Id, u.Name, u.Email From User u where u.Id in :assignedUserList]){
			  	userMailDetails.put(user.Id, user);
			  }
			  
			  for(Launch_Item__c launchItem: [Select  Id,Name From Launch_Item__c where Id in: taskList]){
			  		launchItemMap.put(launchItem.Id, launchItem);
			  }	
		  
		  }

		 /*Start Modified by Chandra For CR 1459234  */
        List<Id> launchItemIdList=new List<Id>();
        for(Task t:Trigger.new)
        {
        	if(t.RecordTypeId == recordType)
        	{
        		String objectId=t.WhatId;
        		if(objectId!=null && objectId.startsWith(Schema.Sobjecttype.Launch_Item__c.getKeyPrefix()))
        		{
        		   launchItemIdList.add(t.WhatId);
        		}
        	}
        }
        Map<Id,List<String>> launchItemDistributionListMap=PLM_SendTaskNotificationTriggerClass.prepareNotificationList(launchItemIdList);
        /*End Modified by Chandra For CR 1459234  */ 


        for(Task t:Trigger.new){
        
            // If PLM task is updated, then
            if(t.RecordTypeId == recordType){
            	
            		// Get launch item's name
            		String objectId = t.WhatId;
            		String launchItemName = launchItemMap.get(objectId).Name;
            		String launchItemLink = org.Division + '/' + objectId;
                    String link = org.Division + '/' + t.Id;

                   
                //********************************************************************************************************
                //  This block notifies distribution list whenever the task is reassigned or the due date for a task is modified 
                //********************************************************************************************************
                if((Trigger.oldMap.get(t.Id).OwnerId  != t.OwnerId) ||(Trigger.oldMap.get(t.Id).ActivityDate != t.ActivityDate) && PLM_CastIronClass.firstRun){
                	

                    String[] ccAddresses;
                    Messaging.SingleEmailMessage email;
                    PLM_EmailBodyBean emailContent = new PLM_EmailBodyBean();
					Boolean newtask =  (Trigger.oldMap.get(t.Id).OwnerId  != t.OwnerId);
 				
                    // If object is of type, Launch_Item__c
                    if(objectId!=null && objectId.startsWith(Schema.Sobjecttype.Launch_Item__c.getKeyPrefix()) && PLM_CastIronClass.firstRun){
    
                    // Strings to hold the email addresses to which you are sending the email.  
                    String[] toAddress = new String[] {userMailDetails.get(t.OwnerId).Email}; 
		    
                    if(newtask)
                        ccAddresses = launchItemDistributionListMap.get(t.WhatId);    // Modifed By Chandra for CR 1459234

                    
                    
                    emailContent.assignee = userMailDetails.get(t.OwnerId).Name;
                    emailContent.launchItemName = launchItemName;
                    emailContent.launchItemLink = launchItemLink;
                    emailContent.taskName = t.Subject;
                    emailContent.createDate = t.CreatedDate;
                    emailContent.dueByDate = t.ActivityDate;
                    emailContent.assignedFrom = userMailDetails.get(t.LastModifiedById).Name;
                    emailContent.link = link;
                    emailContent.toAddress = toAddress;
                    emailContent.ccAddresses = ccAddresses;
                    
                    email = PLM_SendTaskNotificationTriggerClass.prepareEmailForNotifyingTaskAssignmentDate(emailContent,newtask);
                    notifyAssignmentMailList.add(email);
              		
                    }
                }
                
                // Campaign id is modified by WFT before due date. When this is modified, trigger mail
                //********************************************************************************************************
                //  This block reminds assignee and distribution list before due date.  
                //********************************************************************************************************
                if((Trigger.oldMap.get(t.Id).Associated_AKAM_Campaign_ID__c  != t.Associated_AKAM_Campaign_ID__c) && t.Status != 'Completed' && PLM_CastIronClass.firstRun){
                               
                               
					Messaging.SingleEmailMessage email;
					
                    // Clean to indicate mail has been sent
                    t.Associated_AKAM_Account_ID__c = 'CLEAN';
                    String[] toAddress = new String[] {userMailDetails.get(t.OwnerId).Email}; 
                    String[] ccAddresses = launchItemDistributionListMap.get(t.WhatId);  // Modifed By Chandra for CR 1459234

                    if(PLM_SendTaskNotificationTriggerClass.isNotificationRequiredForTask(t.Subject,t.ActivityDate)){

	                    PLM_EmailBodyBean emailContent = new PLM_EmailBodyBean();
                    	
	                    emailContent.assignee = userMailDetails.get(t.OwnerId).Name;
	                    emailContent.launchItemName = launchItemName;
	                    emailContent.launchItemLink = launchItemLink;
	                    emailContent.taskName = t.Subject;
	                    emailContent.createDate = t.CreatedDate;
	                    emailContent.dueByDate = t.ActivityDate;
	                    emailContent.assignedFrom = userMailDetails.get(t.LastModifiedById).Name;
	                    emailContent.link = link;
	                    emailContent.toAddress = toAddress;
	                    //emailContent.ccAddresses = ccAddresses;
	                    
	                    
	                    email = PLM_SendTaskNotificationTriggerClass.prepareEmailForSendingReminderBeforeDueDate(emailContent);
	                    notifyBeforeDueDateList.add(email);
                    
                    }
                                            
                }
                
                                
                // Campaign id is modified by WFT after due date. When this is modified, trigger mail
                //********************************************************************************************************
                //  This block reminds assignee and distribution list if a task is overdue 
                //********************************************************************************************************              
                if((Trigger.oldMap.get(t.Id).Associated_AKAM_Contact_ID__c  != t.Associated_AKAM_Contact_ID__c) && t.Status != 'Completed' && PLM_CastIronClass.firstRun){
                	
                	Messaging.SingleEmailMessage email;
                    PLM_EmailBodyBean emailContent = new PLM_EmailBodyBean();
                      
                    // Clean to indicate mail has been sent
                    t.Associated_AKAM_Lead_ID__c = 'CLEAN';
                    String[] toAddress = new String[] {userMailDetails.get(t.OwnerId).Email}; 
                    String[] ccAddresses = launchItemDistributionListMap.get(t.WhatId);  // Modifed By Chandra for CR 1459234 

                    emailContent.assignee = userMailDetails.get(t.OwnerId).Name;
                    emailContent.launchItemName = launchItemName;
                    emailContent.launchItemLink = launchItemLink;
                    emailContent.taskName = t.Subject;
                    emailContent.createDate = t.CreatedDate;
                    emailContent.dueByDate = t.ActivityDate;
                    emailContent.assignedFrom = userMailDetails.get(t.LastModifiedById).Name;
                    emailContent.link = link;
                    emailContent.toAddress = toAddress;
                    emailContent.ccAddresses = ccAddresses;

                    email = PLM_SendTaskNotificationTriggerClass.prepareEmailForSendingOverdueReminder(emailContent);
                    
                    notifyOverdueList.add(email);
                                            
                }
                
                //********************************************************************************************************
                //  This block notifies assignee when task is completed
                //********************************************************************************************************              
                if((Trigger.oldMap.get(t.Id).Status  != t.Status) && t.Status == 'Completed' && PLM_CastIronClass.firstRun){

                	Messaging.SingleEmailMessage email;
                    PLM_EmailBodyBean emailContent = new PLM_EmailBodyBean();
                    
                    // Clean to indicate mail has been sent
                    t.Associated_AKAM_Lead_ID__c = 'CLEAN';
					t.Associated_AKAM_Account_ID__c = 'CLEAN';
                    String[] toAddress = new String[] {userMailDetails.get(t.OwnerId).Email}; 
                    String[] ccAddresses = launchItemDistributionListMap.get(t.WhatId);  // Modifed By Chandra for CR 1459234 

                    emailContent.assignee = userMailDetails.get(t.OwnerId).Name;
                    emailContent.launchItemName = launchItemName;
                    emailContent.launchItemLink = launchItemLink;
                    emailContent.taskName = t.Subject;
                    emailContent.createDate = t.CreatedDate;
                    emailContent.dueByDate = t.ActivityDate;
                    emailContent.assignedFrom = userMailDetails.get(t.LastModifiedById).Name;
                    emailContent.link = link;
                    emailContent.toAddress = toAddress;
                    emailContent.ccAddresses = ccAddresses;
                    
                    // Tasks which are pending for launch item are prepared here
                    String pendingList = PLM_SendTaskNotificationTriggerClass.preparePendingTaskItemListForLaunchItem(objectId, t.Id, recordType,org.Division);
                    email = PLM_SendTaskNotificationTriggerClass.prepareEmailForSendingTaskCompletion(emailContent,pendingList);
                    
                    
                    notifyTaskCompletionList.add(email);
                }
                
                
                // If due date is modified, change the Associated_AKAM_Account_ID__c to indicate that new mail has to be sent for post
                // and pre date
                if(Trigger.oldMap.get(t.Id).ActivityDate  != t.ActivityDate){
                        t.Associated_AKAM_Account_ID__c = 'DIRTY';
                        t.Associated_AKAM_Lead_ID__c = 'DIRTY';
                }
                
                

                    
                
                
            }
        }
        
        // Defensively sending emails in four separate invocation to avoid any possible Gov. limit issue around number of messages sent in one invocation
		if(notifyAssignmentMailList != null && notifyAssignmentMailList.size() > 0)
	        Messaging.sendEmail(notifyAssignmentMailList);
	        
		if(notifyBeforeDueDateList != null && notifyBeforeDueDateList.size() > 0)
	        Messaging.sendEmail(notifyBeforeDueDateList);
	        
		if(notifyOverdueList != null && notifyOverdueList.size() > 0)
	        Messaging.sendEmail(notifyOverdueList);
	        
		if(notifyTaskCompletionList != null && notifyTaskCompletionList.size() > 0)
	        Messaging.sendEmail(notifyTaskCompletionList);
	        
	        
        
        // After first run, update this flag to false
		PLM_CastIronClass.firstRun = false;
    }

}