/*
 * CR: FFPSA-142
 * Developer: Sharath Prasanna
 * Enhancement: Set the delegated approver from the custom page. Run validations before saving the record.
 * Date: 23rd Feb 2018
 * 
*/ 
public without sharing class PSA_DelegatedApproverController 
{
	//The logged in user
	public User loggedInUser 
	{
		get
		{
			if(loggedInUser == null)
			{
				loggedInUser = [select id,ManagerId, DelegatedApproverid,Delegation_StartTime__c,Delegation_EndTime__c,Delegated_Approver_Custom__c from user where id=:userinfo.getuserid()];
			}
			return loggedInUser;
		}
		set;
	}

	//Used to show messages on the screen
	public String messageString 
	{
		get
		{
			if(messageString == null)
			{
				messageString = '';	
			}
			return messageString;
		}

		set;
	}

	public PSA_DelegatedApproverController() 
	{
		
	}

	public String saveApprover()
	{
		messageString = '';
		List<UserPackageLicense> licenses;
		List<Contact> contacts;
		List<pse__Permission_Control__c> permControls;
		List<User> delegatedUser;
		Boolean valid = false;

		if(loggedInUser.DelegatedApproverid != null)
		{
			String approverId = (String)loggedInUser.DelegatedApproverid;

			if(approverId.length() != 15 && approverId.length() != 18 && !approverId.startsWith('005'))
			{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid User!!'));
				//messageString = 'Invalid User!!';				
				return null;
			}
			//Cannot set the end date in the past
			if(loggedInUser.Delegation_EndTime__c < date.today())
			{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'End date cannot be in the past'));
				//messageString = '';
				return null;	
			}

			//Check if the user has license
			PackageLicense pl = [SELECT Id FROM PackageLicense WHERE NamespacePrefix = 'pse' limit 1];  

			licenses = [select UserId from UserPackageLicense where PackageLicenseId = :pl.Id and UserId = :loggedInUser.DelegatedApproverid ];
			//Check if the user has PSA Resource contact record
			Id PSAResourceId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('PSA Resource').getRecordTypeId();
			contacts = [select Id from Contact where RecordTypeid = :PSAResourceId and pse__is_resource__c = true and pse__is_resource_active__c = true and pse__salesforce_user__c = :loggedInUser.DelegatedApproverid];
			//Check if the user has permission control
			permControls = [select Id,pse__User__c from pse__Permission_Control__c where pse__End_Date__c > :Date.today() and pse__User__c = :loggedInUser.DelegatedApproverid];

			//Check if the delegated approver is the line manager of the approver or has the same line manager
			delegatedUser = [select id,ManagerId from user where id=:loggedInUser.DelegatedApproverid];

			if(!licenses.isEmpty() && !contacts.isEmpty() && !permControls.isEmpty())
			{
				if(!delegatedUser.isEmpty() && (loggedInUser.ManagerId == loggedInUser.DelegatedApproverid || delegatedUser.get(0).ManagerId == loggedInUser.ManagerId))
				{
					valid = true;
				}
				else
				{
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'The selected approver should be the Line Manager of the current user or should have the same Line Manager'));
					//messageString = 'The selected approver should be the Line Manager of the current user or should have the same Line Manager';				
				}
			  
			}
			else
			{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'The selected approver is not a Financial Force user'));
				 //messageString = 'The selected approver is not a Financial Force user';

			}

		}
		if(valid || loggedInUser.DelegatedApproverid == null)
		{
			//set the delegation custom field. Set the delegation start time
			//loggedInUser.Delegation_StartTime__c = Datetime.now();
			loggedInUser.Delegated_Approver_Custom__c = loggedInUser.DelegatedApproverid;
			List<user> userToUpdate = new List<user>{loggedInUser};
			List<Database.saveresult> results = Database.update(userToUpdate,false);
			
			for(Database.saveresult result :results)
			{
	            if (!result.isSuccess()) 
	            {
	                for(Database.Error err : result.getErrors()) 
	                {
	                   messageString +=  ' '+ err.getMessage();
	                }
	                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, messageString));
	            }
	            else
	            {
	            	//system.assertEquals(1,2);
	            	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Saved Succesfully!!'));
	            	//messageString = '!';	
	            }

			}


		}
		return null;
	}
}