public with sharing class PLM_SendTaskNotificationTriggerClass {

	/**
		@obvious This is a method to send email. Code is from Salesforce tutorial
	*/
	private static Messaging.SingleEmailMessage sendEmail(PLM_EmailBodyBean emailContent, String subject, String messageBody){

		// Create a new single email message object
		// that will send out a single email to the addresses in the To, CC & BCC list.
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

		// Assign the addresses for the To and CC lists to the mail object.
		mail.setToAddresses(emailContent.toAddress);
		mail.setCcAddresses(emailContent.ccAddresses);

		// Specify the name used as the display name.
		mail.setSenderDisplayName('Product Launch Management');

		// Set to True if you want to BCC yourself on the email.
		mail.setBccSender(false);

		// The email address of the user executing the Apex Code will be used.
		mail.setUseSignature(false);

		// Specify the subject line for your email address.
		mail.setSubject(subject);

		//Set message body
		mail.setHtmlBody(messageBody);

		return mail;

	}

	/**
		This method prepares email subject and body based on data entered in task and launch items
		assignee - The user to whom task has been assigned to. This is User id
		launchItemName - Product name/Launch item name
		taskName - Name of the task as it appears on launch item page
		createDate - Date on which task was created
		dueDate - Date by which task has to be completed
		assignedFrom - Previous owner of the task

	*/
	public static Messaging.SingleEmailMessage prepareEmailForNotifyingTaskAssignmentDate(PLM_EmailBodyBean emailContent, Boolean newtask){

		String launchItem = '<a href="' +emailContent.launchItemLink + '">' + emailContent.launchItemName+ '</a>';
		String dueDate = emailContent.dueByDate!=null? (emailContent.dueByDate+''):'Not set';

		String emailSubject;
		if(newtask){
		 emailSubject = 'New Task: ' + emailContent.taskName + ' assigned to  ' + emailContent.assignee + ' on '  +emailContent.createDate;
		}
		else{
		 emailSubject = 'Due date changed: Task ' + emailContent.taskName +  ' assigned to  ' + emailContent.assignee + ' on '  +emailContent.createDate + ' is now due on '+ dueDate;
		}

		String emailBody = '<body><p>Task assigned to '+ emailContent.assignee + ' on '+ emailContent.createDate + ' by '+ emailContent.assignedFrom +
							' </p><p><br>Task: '+ emailContent.taskName + '<br>Related To: '+ launchItem + '<br>Due by: '+ dueDate +
							'<br><br>To  complete this task:<br>1.	Review: '+ emailContent.link
							+'<br>2.	Perform the specific activities required for this task  on the Launch Item Page(To navigate to the Launch Item  page, click on the Related to field) <br>3.	Change the Status and hit Save<br>4.	Navigate back to the task, change the Status to Completed and hit Save<br><br><br></p></body>';


		return sendEmail(emailContent, emailSubject, emailBody);
	}



	/**
		This method prepares email subject and body based on data entered in task and launch items
		assignee - The user to whom task has been assigned to. This is User id
		launchItemName - Product name/Launch item name
		taskName - Name of the task as it appears on launch item page
		createDate - Date on which task was created
		dueDate - Date by which task has to be completed
		assignedFrom - Previous owner of the task

	*/
	public static Messaging.SingleEmailMessage prepareEmailForSendingReminderBeforeDueDate(PLM_EmailBodyBean emailContent){

		String launchItem = '<a href="' +emailContent.launchItemLink + '">' + emailContent.launchItemName+ '</a>';
		String dueDate = emailContent.dueByDate!=null? (emailContent.dueByDate+''):'Not set';

		String emailSubject = 'Reminder:  Task: '+ emailContent.taskName + ' assigned to  ' + emailContent.assignee + ' on '  +emailContent.createDate + ' is due on '+ dueDate;
		String emailBody = '<body><p>Task assigned to '+ emailContent.assignee + ' on '+ emailContent.createDate + ' is due on '
		+ dueDate + ' </p><p><br>Task: '+ emailContent.taskName + '<br>Related To: '+ launchItem + '<br>Due by: '
		+ dueDate + '<br><br>To  complete this task:<br>1.Review: '
		+ emailContent.link +'<br>2.Perform the specific activities required for this task  on the Launch Item Page(To navigate to the Launch Item'
		+ 'page, click on the Related to field) <br>3.	Change the Status and hit Save<br>4.	Navigate back to the task, change the Status to Completed and hit Save<br><br><br></p></body>';

		return sendEmail(emailContent, emailSubject, emailBody);
	}


	/**
		This method prepares email subject and body based on data entered in task and launch items
		assignee - The user to whom task has been assigned to. This is User id
		launchItemName - Product name/Launch item name
		taskName - Name of the task as it appears on launch item page
		createDate - Date on which task was created
		dueDate - Date by which task has to be completed
		assignedFrom - Previous owner of the task

	*/
	public static Messaging.SingleEmailMessage prepareEmailForSendingOverdueReminder(PLM_EmailBodyBean emailContent){


		String launchItem = '<a href="' +emailContent.launchItemLink + '">' + emailContent.launchItemName+ '</a>';
		String dueDate = emailContent.dueByDate!=null? (emailContent.dueByDate+''):'Not set';

		String emailSubject = 'Overdue:  Task: '+ emailContent.taskName + ' assigned to  ' + emailContent.assignee + ' on '  +emailContent.createDate + ' is overdue';
		String emailBody = '<body><p>Task assigned to '+ emailContent.assignee + ' on '+ emailContent.createDate + ' is overdue ' +  ' </p><p><br>Task: '+ emailContent.taskName + '<br>Related To: '+ launchItem + '<br>DUE BY: '+ dueDate + '<br><br>To  complete this task:<br>1.Review: '+ emailContent.link +'<br>2.	Perform the specific activities required for this task  on the Launch Item Page(To navigate to the Launch Item  page, click on the Related to field) <br>3.	Change the Status and hit Save<br>4.	Navigate back to the task, change the Status to Completed and hit Save<br><br><br></p></body>';

		return sendEmail(emailContent, emailSubject, emailBody);
	}


	public static Messaging.SingleEmailMessage prepareEmailForSendingTaskCompletion(PLM_EmailBodyBean emailContent,String pendingTaskList){

		String launchItem = '<a href="' +emailContent.launchItemLink + '">' + emailContent.launchItemName+ '</a>';
		String dueDate = emailContent.dueByDate!=null? (emailContent.dueByDate+''):'Not set';

		String emailSubject = 'Completed: Task assigned to  ' + emailContent.assignee + ' on '  +emailContent.createDate + ' is completed';
		String emailBody = '<body><p>Task assigned to '+ emailContent.assignee + ' on '+ emailContent.createDate + ' is completed ' +  ' </p><p><br>Task: '+ emailContent.taskName + '<br>Related To: '+ launchItem + '<br>DUE BY: '+ dueDate + '<br><br>View completed task: '+ emailContent.link +'<br></p>'+ pendingTaskList + '</body>';

		return sendEmail(emailContent, emailSubject, emailBody);

	}


	public static String preparePendingTaskItemListForLaunchItem(Id launchItemId,Id taskId, Id recordTypeId, String org){


		List<Task> pendingTaskList = [Select t.CreatedDate, t.Description,t.Id,t.OwnerId,t.Status,t.Subject,t.WhatId,t.ActivityDate From Task t  WHERE t.RecordTypeId = :recordTypeId  AND t.WhatId = :launchItemId  AND t.Status != 'Completed' AND t.Id != :taskId Order by t.ActivityDate];
		Set<Id> userSet = new Set<Id>();
		Map<Id, String> userNameMap = new Map<Id, String>();

		for(Task pendingTask: pendingTaskList){
			userSet.add(pendingTask.OwnerId);
		}

		for(User user: [Select u.Id, u.Name, u.Email From User u where u.Id in :userSet]){
			userNameMap.put(user.Id, user.Name);
		}

		String htmlBody = '<p>Following tasks are pending for the launch:<br>';

		htmlBody = htmlBody + '<table> <tr> <td><h3> Task name </h3></td> <td>&nbsp;&nbsp;&nbsp;</td> <td> <h3>Assignee</h3> </td> <td>&nbsp;&nbsp;&nbsp;</td> <td> <h3>Due date</h3> </td> </tr>';

		for(Task pendingTask: pendingTaskList){
			String pendingTaskDate = pendingTask.ActivityDate!=null? (pendingTask.ActivityDate + ''): 'Not set';
			//htmlBody = htmlBody + '<br>' + '<a href="' +org + '/' +  pendingTask.Id + '">' + pendingTask.Subject + '</a>' + ' assigned to ' +userNameMap.get(pendingTask.ownerId)+ pendingTaskDate;
			htmlBody = htmlBody + '<tr>' + '<td><a href="' +org + '/' +  pendingTask.Id + '">' + pendingTask.Subject + '</a></td><td>&nbsp;&nbsp;&nbsp;</td><td>' +userNameMap.get(pendingTask.ownerId)+ '</td> <td>&nbsp;&nbsp;&nbsp;</td><td> ' + pendingTaskDate + '</td></tr>';

		}

		htmlBody =  htmlBody + '</table></p>';
		return htmlBody;

	}



	public static Map<Id,List<String>> prepareNotificationList(List<Id> launchItemIdList){

					List<PLM_Task_Notification_User__c> notificationList = new List<PLM_Task_Notification_User__c>();
				//List<User> userList = new List<User>();
					
					Map<Id,List<String>> LaunchItemDistributionList=new Map<Id,List<String>>();
					//String[] ccAddresses;
				// Identifier for the object on which task has been created
				//String objectId = t.WhatId;

					// If object is of type, Launch_Item__c
				//if(objectId!=null && objectId.startsWith(Schema.Sobjecttype.Launch_Item__c.getKeyPrefix())){

						// Prepare notification list
					notificationList = [Select p.User__r.UserName,p.User__r.Email,p.Launch_Item__c From PLM_Task_Notification_User__c p where p.Launch_Item__c IN :launchItemIdList ];
						for(Id launchItemId: launchItemIdList)
						{
							List<String> userEmailList = new List<string>();
							
							for(PLM_Task_Notification_User__c p: notificationList)
							{
								if(launchItemId==p.Launch_Item__c)
								{
								 userEmailList.add(p.User__r.Email);
								}
							}
							LaunchItemDistributionList.put(launchItemId,userEmailList);
					}
					//Integer i = 0;
						//userList = [Select u.Username, u.Email From User u where u.Id in :userIdList];
						//ccAddresses = new String[userList.size()];

					/*for(User u:userList){
						ccAddresses[i] = u.Email;
							i++;
					}*/
					//}

				return LaunchItemDistributionList;
}



	public static Boolean isNotificationRequiredForTask(String taskName, Date dueDate){

		Boolean notify = true;

		/*	Date todayDate = Date.today();

			// If we are trying to send a mail 5 days before the due date, check if activity is eligible
			if((todayDate.daysBetween(dueDate)) > 4){

			    if(taskName.equals('Upload Scope Document') || taskName.equals('Upload Product Design Documents') ||
	            taskName.equals('Upload Package Design Documents') || taskName.equals('Upload Go-To-Market Design Documents') ||
	            taskName.equals('Setup Package Design Review Date') || taskName.equals('Assign Readiness Date') ||
	            taskName.equals('Post Prototype Order Forms') || taskName.equals('Setup System Integration Review Date') ||
	            taskName.equals('Update Product Catalog Structure') || taskName.equals('Post Test Order Forms and Invoice Item Designs') ||
	            taskName.equals('Complete Portal Provisioning')|| taskName.equals('Assign Backend Integration Completion Date'))
	            {
	                notify = true;
	            }

			}	// Send mail for all tasks
			else if((todayDate.daysBetween(dueDate)) == 2){

				notify = true;
			}
			else if(todayDate.isSameDay(dueDate)){

			    if(taskName.equals('Upload Launch Checklist') || taskName.equals('Upload PLU Presentation') ||
	            taskName.equals('Assign Backend Integration Completion Date'))
	            {
	                notify = true;
	            }

			}
		*/
		return notify;

	}







}