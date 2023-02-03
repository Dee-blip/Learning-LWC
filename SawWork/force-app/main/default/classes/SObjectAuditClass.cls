/***
   SObjectAuditClass
   @author         Chandra Lohani(clohani@akamai.com)
   @description    This class will run a schedule job which check for all the Sobjects exists in Salesforce
                   and create an corresponding audit record into Audit Object if not exists already.
                   
   @History 
   
        Date                 Developer               Description
     03/16/2011         Chandra Mohan Lohani      Created the Class and added folowing methods 
                                                     createAuditRecord     : Will be called from a scheduled Job and create Sobject Backup audit record
                                                     deploymentComplete    : This will be called from UI when user clicks on 'Deployed' button
                                                     cancelDeployment      : This will be called from UI when User clicks on 'Cancel Deployment' button
                                                     execute               : This is starting point for a scheduled job
                                                     sendEmailNotifications: This will be called from scheduled job and send summary emails to responsible/approver user for Sobject Backup Audit records
                                                     createMessage         : This message will be called internally from sendEmailNotifications method
                                                     sendMail              : This method will be callled internally from sendEmailNotifications method   
*/                                                   


global class SObjectAuditClass implements Schedulable{
	private static SobjectAuditClassSetings__c sobjectCustomSetting=SobjectAuditClassSetings__c.getInstance('SobjectSettings');
	private static RecordType cancelDeloymentRecType= [select Id from RecordType where Name='Sobject Backup Record Type'][0];
	private static RecordType deploymentCompleteRecType= [select Id from RecordType where Name='Sobject Backup Approved Record Type'][0];
	
	/**
	 createAuditRecord()
	
	 - This method will be called from Scheduled job
	 - It will retrieve all sobject Map using getGlobalDescribe method, from Map gets all objectNames exists in Salesforce
	   Comapares those object Names with the record's object Name exists for Sobject_Backup_Audit__c 
	   and crates a new record for Object Name if there is no Sobject_Backup_Audit__c record found corresponding to that object name  
	*/
	public String createAuditRecord()
	{
		String ids='';
		Integer count=0;
		String responsibleUserAlias='NARKUMAR';
		String approverUserAlias='EJERSKEY';
		Set<String> userAliasSet=new Set<String>();
		userAliasSet.add(responsibleUserAlias);
		userAliasSet.add(approverUserAlias);
		Map<String,Id> defaultUserMap=new Map<String,Id>();
		List<User> defaultUserList=[select Id,Alias from User where alias IN :userAliasSet];
		for(User defaultUser: defaultUserList)
		{
			defaultUserMap.put(defaultUser.Alias,defaultUser.Id);
		}
		List<SObject_Backup_Audit__c> objectSynched=[select Object_Name__c from Sobject_backup_Audit__c];
		Map<String, Schema.SObjectType> allObjectsMap = Schema.getGlobalDescribe();
		
		Set<String> allObjectSet=allObjectsMap.keySet();
		Set<String> synchedObjectSet=new Set<String>();
		for(SObject_Backup_Audit__c audit: objectSynched)
		{
			synchedObjectSet.add(audit.Object_Name__c);
		}
		List<SObject_Backup_Audit__c> objectsToSyncList=new List<SObject_Backup_Audit__c>();
		for(String s: allObjectSet)
		 {
		 	if(!synchedObjectSet.contains(s))
		 	{
		 		SObject_Backup_Audit__c newSobjectAudit=new SObject_Backup_Audit__c();
		 		newSobjectAudit.Object_Name__c=s;
		 		newSobjectAudit.Responsible__c=defaultUserMap.get(responsibleUserAlias);
		 		newSobjectAudit.Approver__c=defaultUserMap.get(approverUserAlias);
		 		objectsToSyncList.add(newSobjectAudit);
		 	}
		 }
		 if(objectsToSyncList.size()>0)
		  {
		   try
		    {	
		     insert objectsToSyncList;
		     if(ObjectsToSyncList.size()==1)
		     {
		     	ids=ObjectsToSyncList[0].Id;
		     }
		     else
		     {
		     	Integer i =0;
		     	for(SObject_Backup_Audit__c sobjectAudit:ObjectsToSyncList)
		     	{
		     		if(i==0)
		     		{
		     			ids=sobjectAudit.Id;
		     		}
		     		else
		     		{
		     			ids=ids+','+sobjectAudit.Id;
		     		}
		     	}
		     }
		    }
		    catch(Exception e)
		    {
		    	String [] recipient=new String[]{sobjectCustomSetting.RecipientEmail__c};
		    	sendEmail(recipient,null,'Error Occured  while inserting Sobject Audit record',e.getMessage());
		    }
		  }
		  count=objectsToSyncList.size();
		  ids=count+'\n'+ids;
		return ids;
	}
	/**
	 deploymentComplete(Id sobjectId)
	 @param  - Id 
	 @return - String
	 - This method will be called from UI when user clicks on 'Deployed' button
	 - This method will set Status__c='Approved' and change recordType='Sobject Backup Approved Record Type'   
	*/
	Webservice static String deploymentComplete(Id sobjectId)
	{
		Sobject_Backup_Audit__c backupObject=[select Id,Name,Status__c from Sobject_Backup_Audit__c where Id =:sObjectId][0];
		//RecordType recType= [select Id from RecordType where Name='Sobject Backup Approved Record Type'][0];
		backupObject.Status__c='Approved';
		backupObject.RecordTypeId=deploymentCompleteRecType.Id;
		try
		{
		 upsert backupObject;
		}
		catch(exception e)
		{
			return e.getMessage();
		}
	    return 'success';	
	}
	/**
	 cancelDeployment(Id sobjectId)
	 @param  - Id 
	 @return - String
	 - This method will be called from UI when user clicks on 'Cancel Deployment' button
	 - This method will set Status__c='Pending Review' and change recordType='Sobject Backup Record Type'   
	*/
	
	Webservice static String cancelDeployment(Id sobjectId)
	{
		Sobject_Backup_Audit__c backupObject=[select Id,Name,Status__c from Sobject_Backup_Audit__c where Id =:sObjectId][0];
		//RecordType recType= [select Id from RecordType where Name='Sobject Backup Record Type'][0];
		backupObject.Status__c='Pending Review';
		backupObject.RecordTypeId=cancelDeloymentRecType.Id;
		try
		{
		 upsert backupObject;
		}
		catch(exception e)
		{
			return e.getMessage();
		}
	    return 'success';	
	}
	/**
	 execute(SchedulableContext sc)
	 @param  - SchedulableContext 
	 
	 - This method is a starting point of scheduled job
	 - It will call createAuditRecord() and sendEmailNotifications() method   
	*/
	global void execute(SchedulableContext sc)
	{
	  String [] recipient=new String[]{sobjectCustomSetting.RecipientEmail__c};
  	  SObjectAuditClass sobjectClass= new SObjectAuditClass();
		try
		{
		    sobjectClass.createAuditRecord();
		}
		catch(Exception e)
		{
			sobjectClass.sendEmail(recipient,null,'Error Occured  while creating Sobject Audit record',e.getMessage());
		}
		
		try
		{
			sobjectClass.sendEmailNotifications();
		}
		catch(Exception e)
		{
			sobjectClass.sendEmail(recipient,null,'Error Occured  while sending summary email notifications',e.getMessage());
		}
	}
	
	public static String invokeSObjectAuditBackupRecordJob(String jobName)
	{
		String res='1:';
		String [] recipient=new String[]{sobjectCustomSetting.RecipientEmail__c};
  	    SObjectAuditClass sobjectClass= new SObjectAuditClass();
		try
		{
		    if(jobName.equals('CreateSobjectBackupAuditRecordJob-CreateAuditRecord'))
		       {
		       	String createdRecordCountAndIds=sobjectClass.createAuditRecord();
		        res=res+ '\n Count: '+ createdRecordCountAndIds;
		       }
		    else if(jobName.equals('CreateSobjectBackupAuditRecordJob-SendEmailNotifications'))
		    {
		    	Boolean emailSent=sObjectClass.sendEmailNotifications();
		    	res=res+ '\n Email sent: '+ emailSent;
		    }   
		}
		catch(Exception e)
		{
			if(jobName.equals('CreateSobjectBackupAuditRecordJob-CreateAuditRecord'))
			{
				sobjectClass.sendEmail(recipient,null,'Error Occured  while creating Sobject Audit record',e.getMessage());
			}
			else if(jobName.equals('CreateSobjectBackupAuditRecordJob-SendEmailNotifications'))
			{
				 sobjectClass.sendEmail(recipient,null,'Error Occured  while sending email notifications',e.getMessage());
			}
			res='0#'+e;
		}
		return res;
	}
	/**
	 sendEmailNotifications()
	 @retrun  - Boolean 
	 
	 - This method will be called from scheduled job
	 - It will send weekly summary emails to Approver and responsible users for Sobject_Backup_audit__C records   
	*/
	public Boolean sendEmailNotifications()
	{
		List<Sobject_Backup_Audit__c> sobjectList=[select Id,Object_Name__c,Responsible__c,Responsible__r.FirstName,Responsible__r.Email,Approver__c,Approver__r.FirstName,Approver__r.Email,Status__c 
		                                                   from Sobject_Backup_Audit__c 
		                                                   where Status__c IN ('Pending Review','Pending Approval','Pending Deployment')];
        Set<Id> responsibleUserSet=new Set<Id>();
        Set<Id>	approverUserSet=new Set<Id>();
        Set<String> auditRecordNameForResponsible=new Set<String>();
        Set<String> auditRecordNameForApprover=new Set<String>();
        String message=null;
        String subject=null;
        Boolean responsibleMailSent=true;
        Boolean approverMailSent=true;
        Map<Id,String> userEmailMap=new Map<Id,String>();
        for(Sobject_Backup_Audit__c sobjectAudit: sobjectList)  
        {
        	    	
        	if(sobjectAudit.Status__c=='Pending Review')
        	{
        		responsibleUserSet.add(sobjectAudit.Responsible__c);
        		userEmailMap.put(sobjectAudit.Responsible__c,sobjectAudit.Responsible__r.Email);
        		
        	}
        	else if(sobjectAudit.Status__c=='Pending Approval' || sobjectAudit.Status__c=='Pending Deployment')
        	{
        	    approverUserSet.add(sobjectAudit.Approver__c);
        	    userEmailMap.put(sobjectAudit.Approver__c,sobjectAudit.Approver__r.Email);
        	    
        	}
        }
       /* List<User> userList= [select Id,Email,Manager.Email from User where Id IN :responsibleUserSet 
                                                                         or ID IN :approverUserSet];
       
        for(User user: userList)
        {
        	userMap.put(user.Id,user);
        }
        */
        if(responsibleUserSet.size()>0)
        { 
        	subject='Pending audit records for review';
        	for(Id responsibleUserId: responsibleUserSet)
        	 {
        	  String responsibleUserEmail=userEmailMap.get(responsibleUserId);
        	  message=createMessage(sobjectList,responsibleUserId,'responsible');
        	  List<String> toAddressess=new List<String>();
        	  List<String> ccAddressess=new List<String>();
        	  toAddressess.add(responsibleUserEmail);
        	/*  if(responsibleUser.Manager.Email!=null)
        	  {
        	   ccAddressess.add(responsibleUser.Manager.Email);
        	   responsibleMailSent=sendEmail(toAddressess,ccAddressess,subject,message);
        	  }
        	  else
        	  {*/
        	  	responsibleMailSent=sendEmail(toAddressess,null,subject,message);
        	  //}
        	  
        	 }
        }
        if(approverUserSet.size()>0)
        {
        	subject='Pending audit records for approval or deployment';
        	for(Id approverUserId: approverUserSet)
        	 {
        	  String approverUserEmail=userEmailMap.get(approverUserId);
        	  message=createMessage(sobjectList,approverUserId,'approver');
        	  List<String> toAddressess=new List<String>();
        	  List<String> ccAddressess=new List<String>();
        	  System.debug('approverUserEmail : '+approverUserEmail);
        	  toAddressess.add(approverUserEmail);
        	  //System.debug('approverUser\'s Manager Email : '+ approverUser.Manager.Email);
        	  /*if(approverUser.Manager.Email != null)
        	  {
        	   ccAddressess.add(approverUser.Manager.Email);
        	   approverMailSent=sendEmail(toAddressess,ccAddressess,subject,message);
        	  }
        	  else
        	  {*/
        	  	approverMailSent=sendEmail(toAddressess,null,subject,message);
        	  //}
        	  
        	 }
        }                                                
		return approverMailSent && responsibleMailSent;                                                  
	}
	/**
	 createMessage(List<Sobject_Backup_Audit__c> sobjectList,Id userId,String userType)
	 @retrun  - String 
	 @param   -List<Sobject_backup_Audit__c>,Id,String
	 
	 - This method will be called internally by sendEmailNotifications() method 
	 - It will create message to send summary emails   
	*/
	public String createMessage(List<Sobject_Backup_Audit__c> sobjectList,Id userId,String userType)
	{
		String message=null;
		Integer i=0;
		Integer j=0;
		for(Sobject_Backup_Audit__c sobjectAudit : sobjectList)
		{
			if(userType=='responsible')
			{
				if((sobjectAudit.Responsible__c == userId) && sobjectAudit.Status__c=='Pending Review')
				{   if(j==0)
					{
					 message=sobjectAudit.Responsible__r.FirstName+',\n\n'+'Following Objects are pending for your review: \n';
					 message+=sobjectAudit.Object_Name__c+'\n';
					}
					else
					 message+=sobjectAudit.Object_Name__c+'\n';
				 j++;	 
				}
				
				if(i==sobjectList.size()-1)
				{
					message+='\nPlease login to SFDC and review sobject audit records.';
				}
			}
		   else if(userType=='approver')
		   {
		   	 if((sobjectAudit.Approver__c == userId) && (sobjectAudit.Status__c=='Pending Approval' || sobjectAudit.Status__c=='Pending Deployment' ))
				{   if(j==0)
					{
					 message=sobjectAudit.Approver__r.FirstName +',\n\n'+ 'Following Objects are pending for either your approval or deployment: \n';
					 message+=sobjectAudit.Object_Name__c+'\n';
					}
					else
					 message+=sobjectAudit.Object_Name__c+'\n';
				 System.debug('Integer j : '+ j);
				 j++;	 
				}
			if(i==sobjectList.size()-1)
				{
					message+='\nPlease login to SFDC and approve sobject audit records.';
				}
		   }
		   i++;
		}
		return message;
	}
	/**
	sendEmail(List<String> toRecipient,List<String> ccRecipient,String subject, String message)
	 @retrun  - Boolean
	 @param   - List<String> , List<String>,String,String 
	 
	 - This method will be called internally by sendEmailNotifications() method 
	 - It will create message to send summary emails   
	*/
	public Boolean sendEmail(List<String> toRecipient,List<String> ccRecipient,String subject, String message)
  {
  	     Messaging.SingleEmailMessage mail=new Messaging.SingleEmailMessage();
  	     mail.setToAddresses(toRecipient);
         mail.setSubject(subject);
         if(ccRecipient!=null)
         {
         	mail.setCcAddresses(ccRecipient);
         }
         mail.setBccSender(false);
         mail.setUseSignature(false);
         mail.setPlainTextBody(message);
      	 System.debug('Mail Object ==>'+mail);
         List<Messaging.Sendemailresult> results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
      	 System.debug('results ==>'+results);
         System.debug('Mail Sent ==>'+ results[0].isSuccess());
         if(results[0].isSuccess()==true)
         {
         	return true;
         }
  	     
  	     return false;
  	           
  }
  /*
  public static void testScheduledMethod()
  {
  	 String [] recipient=new String[]{sobjectCustomSetting.RecipientEmail__c};
  	 SObjectAuditClass sobjectClass= new SObjectAuditClass();
		try
		{
		    sobjectClass.createAuditRecord();
		}
		catch(Exception e)
		{
			sobjectClass.sendEmail(recipient,null,'Error Occured  while creating Sobject Audit record',e.getMessage());
		}
		
		try
		{
			sobjectClass.sendEmailNotifications();
		}
		catch(Exception e)
		{
			sobjectClass.sendEmail(recipient,null,'Error Occured  while sending summary email notifications',e.getMessage());
		}
  }
  */

  //SFDC-2110 - Job for Auditing the fields for SObjects
  public static void invokeSObjectAuditBackupFieldJob(String jobType)
  {
    System.debug('Inside invokeSObjectAuditBackupFieldJob');  
  	List<Sobject_Backup_Audit_Field__c> newFieldsToBeInserted = new List<Sobject_Backup_Audit_Field__c>();

  	List<String> objectsSyncedToEDW = SObjectAuditClass.getSObjectSettingValue('ObjectsSyncedToEDW').split(',');

  	String responsibleUserAlias='NARKUMAR';
	String approverUserAlias='EJERSKEY';
	Set<String> userAliasSet=new Set<String>();
	userAliasSet.add(responsibleUserAlias);
	userAliasSet.add(approverUserAlias);
	Map<String,Id> defaultUserMap=new Map<String,Id>();
	List<User> defaultUserList=[select Id,Alias from User where alias IN :userAliasSet];
	for(User defaultUser: defaultUserList)
	{
		defaultUserMap.put(defaultUser.Alias,defaultUser.Id);
	}

  	List<Sobject_Backup_Audit_Field__c> objectSynched=[select Object_Name__c,Field_Name__c from Sobject_Backup_Audit_Field__c where Object_Name__c in :objectsSyncedToEDW and Field_Name__c like '%__c'];

  	Map<String,Set<String>> objectToFieldMap = new Map<String,Set<String>>();

  	for(Sobject_Backup_Audit_Field__c eachField : objectSynched)
  	{
  		if(objectToFieldMap.containsKey(eachField.Object_Name__c))
  		{
  			Set<String> allFields = objectToFieldMap.get(eachField.Object_Name__c);
  			allFields.add(eachField.Field_Name__c);
  			objectToFieldMap.put(eachField.Object_Name__c,allFields);
  		}
  		else
  		{
  			objectToFieldMap.put(eachField.Object_Name__c,new Set<String>{eachField.Field_Name__c});
  		}
  	}

  	Map<String,Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();

  	for(String eachObject : objectsSyncedToEDW)
  	{
  		if(schemaMap.containsKey(eachObject))
  		{
  			Map<String,Schema.SObjectField> fieldMap = schemaMap.get(eachObject).getDescribe().fields.getMap();

  			Set<String> fieldsForEachObject = objectToFieldMap.get(eachObject);

			if(fieldsForEachObject != null)
			{
				for(String eachField : fieldMap.keySet())
				{
					if(!fieldsForEachObject.contains(eachField) && eachField.contains('__c'))
					{
						Sobject_Backup_Audit_Field__c newSobjectAudit=new Sobject_Backup_Audit_Field__c();
				 		newSobjectAudit.Object_Name__c=eachObject;
				 		newSobjectAudit.Field_Name__c=eachField;
				 		newSobjectAudit.Responsible__c=defaultUserMap.get(responsibleUserAlias);
				 		newSobjectAudit.Approver__c=defaultUserMap.get(approverUserAlias);
				 		newFieldsToBeInserted.add(newSobjectAudit);
					}
				}
			}

			else
			{
				for(String eachField : fieldMap.keySet())
				{
					if(eachField.contains('__c'))
					{
						Sobject_Backup_Audit_Field__c newSobjectAudit=new Sobject_Backup_Audit_Field__c();
				 		newSobjectAudit.Object_Name__c=eachObject;
				 		newSobjectAudit.Field_Name__c=eachField;
				 		newSobjectAudit.Responsible__c=defaultUserMap.get(responsibleUserAlias);
				 		newSobjectAudit.Approver__c=defaultUserMap.get(approverUserAlias);
				 		newFieldsToBeInserted.add(newSobjectAudit);
					}
				}
			}
  		}
  	}
	System.debug('Before newFieldsToBeInserted.size() > 0==>'+ newFieldsToBeInserted.size());
  	if(newFieldsToBeInserted.size() > 0)
  	{
        System.debug('Inside newFieldsToBeInserted.size() > 0==>'+ newFieldsToBeInserted.size());
  		insert newFieldsToBeInserted;
  	}
  }

  //SFDC-2110 - Job for sending reports for newly created objects and fields
  public static void fieldReportCreation()
  {
  	Integer daysToBeSubtracted = Integer.valueOf(SObjectAuditClass.getSObjectSettingValue('FieldsCreatedDaysBefore'));
  	List<String> toEmailAddresses = SObjectAuditClass.getSObjectSettingValue('NewlyCreatedFieldsReportEmail').split(',');
  	Map<String,Set<String>> objectToFieldMap = new Map<String,Set<String>>();

  	Date lastPolledDate = Date.today().addDays((-1) * daysToBeSubtracted);
  	List<Sobject_Backup_Audit_Field__c> newFieldsList = [select Id,Object_Name__c,Field_Name__c,Reviewed__c from Sobject_Backup_Audit_Field__c where CreatedDate > :lastPolledDate and Reviewed__c = false];
  	List<Sobject_Backup_Audit__c> newObjectsList = [select Id,Object_Name__c,Reviewed__c from Sobject_Backup_Audit__c where CreatedDate > :lastPolledDate and Reviewed__c = false];
	System.debug('newFieldsList ==>'+newFieldsList);
    System.debug('newObjectsList ==>'+newObjectsList);
  	for(Sobject_Backup_Audit_Field__c eachField : newFieldsList)
  	{
  		if(objectToFieldMap.containsKey(eachField.Object_Name__c))
  		{
  			Set<String> allFields = objectToFieldMap.get(eachField.Object_Name__c);
  			allFields.add(eachField.Field_Name__c);
  			objectToFieldMap.put(eachField.Object_Name__c,allFields);
  		}
  		else
  		{
  			objectToFieldMap.put(eachField.Object_Name__c,new Set<String>{eachField.Field_Name__c});
  		}

  		eachField.Reviewed__c = true;
  	}

  	String emailBody = null;

  	if(objectToFieldMap != null)
  	{
  		if(objectToFieldMap.keySet() != null && !objectToFieldMap.isEmpty())
  		{
  			emailBody = 'Fields created newly in the last ' + String.valueOf(daysToBeSubtracted) + ' days \n\n';

  			for(String eachObject : objectToFieldMap.keySet())
	  		{
	  			emailBody += 'Object Name : ' + eachObject + '\n\n';
	  			for(String eachField : objectToFieldMap.get(eachObject))
	  			{
	  				emailBody += 'Field Name : ' + eachField + '\n';
	  			}
	  			emailBody += '\n';
	  		}
  		}
  	}

  	if(newObjectsList != null && newObjectsList.size() > 0)
  	{
  		emailBody += 'Objects created newly in the last ' + String.valueOf(daysToBeSubtracted) + ' days \n\n';

  		for(Sobject_Backup_Audit__c eachObject : newObjectsList)
  		{
  			emailBody += String.valueOf(eachObject.Object_Name__c) + '\n';
  			eachObject.Reviewed__c = true;
  		}
  	}

  	if(emailBody != null)
  	{
  		SObjectAuditClass soac = new SObjectAuditClass();
  		Boolean mailSent = soac.sendEmail(toEmailAddresses,null,'Newly Created Fields and Objects',emailBody);
  	}

  	if(newFieldsList.size() > 0)
  	{
  		update newFieldsList;
  	}

  	if(newObjectsList.size() > 0)
  	{
  		update newObjectsList;
  	}
  }

  public static String getSObjectSettingValue(String developerName)
  {
    Sobject_Objects_and_Fields__mdt mdtRecord = [select Id, Value__c from Sobject_Objects_and_Fields__mdt where DeveloperName = :developerName];
    return mdtRecord.Value__c;
  }
  //End of SFDC-2110
}