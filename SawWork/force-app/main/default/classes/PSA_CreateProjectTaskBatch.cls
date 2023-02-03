/*
 * CR: FFPSA-496
 * Developer: Sharath Prasanna
 * Enhancement: Automated creation of tasks
 * Date: 17th April 2018
 * 
 * CR: FF Upgrade 19.1
 * Developer: Sandeep Naga
 * Change: Changes made to merge custom metadata from PSA_Create_Task__mdt to PSA_Common_Setting__mdt
 * Date: 28th November 2018
 * 
 */

  
public class PSA_CreateProjectTaskBatch implements Database.Batchable<sObject> 
{
	//The query string
	String query;
	//The set to store the region names
	public Set<String> regionNames; 
	//The set to store the product Ids
	public Set<String> productIds; 
	//The variable that stores the subject
	public String subject;
	//The variable that stores the due date
	public Integer dueDay;
	//The variable that stores the run date
	public Integer runDay;
	//The variable that stores the status
	public String status;
	//the PSA Activity record type ID
	public Id PSAActivityId;
	
	public PSA_CreateProjectTaskBatch() 
	{
		regionNames = new Set<String> ();
		productIds = new Set<String> ();
        
        //Changes made by Sandeep in custom metadata to merge PSA_Create_Task__mdt into PSA_Common_Setting__mdt
        Map<String,PSA_Common_Setting__mdt> taskMetadata = new Map<String,PSA_Common_Setting__mdt>();
        for(PSA_Common_Setting__mdt cmd : [SELECT Name__c, Value__c, LOE_Low_Limts__c,Static_Default_Fields__c  FROM PSA_Common_Setting__mdt where type__c='PSA_Create_Task__mdt'])
        {
            if(cmd.Name__c != NULL && !taskMetadata.containsKey(cmd.Name__c)){
                taskMetadata.put(cmd.Name__c, cmd);
            }
            
        }
		//for (PSA_Create_Task__mdt taskMetadata : [select Regions__c ,Due_date__c,RunDay__c, Product_Ids__c,Subject__c, Status__c from PSA_Create_Task__mdt])
		//{	
			if(subject == null)
			{
				subject = taskMetadata.get('Subject').Value__c;
				//subject = taskMetadata.Subject__c;
			}
			//if(dueDay == null && taskMetadata.Due_date__c != null)
            if(dueDay == null && taskMetadata.get('dueDay').LOE_Low_Limts__c != null)
			{
                dueDay = taskMetadata.get('dueDay').LOE_Low_Limts__c.intValue();
				//dueDay = Integer.valueOf(taskMetadata.Due_date__c);
			}
			//if(runDay == null && taskMetadata.RunDay__c != null)
            if(runDay == null && taskMetadata.get('runDay').LOE_Low_Limts__c != null)
			{
				runDay = taskMetadata.get('runDay').LOE_Low_Limts__c.intValue();
                //runDay = Integer.valueOf(taskMetadata.RunDay__c);
			}
			if(status == null)
			{
				status = taskMetadata.get('status').Value__c;
                //status = taskMetadata.Status__c;
			}
        
        	// "!NOTICE!": this metadata will always contain only one record, but might have multiple comma seperated values for product IDs and region field values.
        
			//if(taskMetadata.Regions__c != null)
			if(taskMetadata.get('region').Static_Default_Fields__c != null)
			{
				//for(String region: taskMetadata.Regions__c.split(','))
				for(String region: taskMetadata.get('region').Static_Default_Fields__c.split(','))
				{
					regionNames.add(region.trim());	
				}				
			}		
			//if(taskMetadata.Product_Ids__c != null)
			if(taskMetadata.get('product').Static_Default_Fields__c != null)
			{
				//for(String product: taskMetadata.Product_Ids__c.split(','))
				for(String product: taskMetadata.get('product').Static_Default_Fields__c.split(','))
				{
					productIds.add(product.trim());	
				}				
			}		
		//}
		PSAActivityId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('PSA Activity').getRecordTypeId();

	}
	
	public Database.QueryLocator start(Database.BatchableContext BC) 
	{
		Date today = Date.today();
		query = 'Select id, pse__Account__r.TERR_HIER_2__c,Name, OwnerId, Owner.Name, pse__Project_Manager__r.pse__Salesforce_User__c, ' 
				+	'(Select id, product_id__c from Project_Contract_Line_Items__r where product_id__c in :productIds)' 
				+ ' from pse__Proj__c where pse__Stage__c = \'In Progress\' and pse__Is_Active__c = true' 
				+ ' and pse__Account__r.TERR_HIER_2__c in :regionNames and pse__End_Date__c >= :today';

		//for test classes
		if(Test.isRunningTest())
		{
			query += ' order by createddate desc limit 1 ';
		}		
        System.debug('query ::: ' + query);
		return Database.getQueryLocator(query);
	}

   	public void execute(Database.BatchableContext BC, List<sObject> scope) 
   	{
		List<pse__Proj__c> projects = (List<pse__Proj__c>)scope;
		List<Task> tasksToInsert = new List<Task>();
		Set<String> currentProjectProducts;
        //commented below line as part of merging Custommetadata
		//PSA_Create_Task__mdt taskMetadata;
		Task taskRecord;
		date today = date.today();
		List<Database.UpsertResult> upsertResultRecords = new List<Database.UpsertResult>();
		
		for(pse__Proj__c proj: projects)
		{
            System.debug('proj :: ' + proj);
			currentProjectProducts = new Set<String>();
			if(proj.Project_Contract_Line_Items__r != null && !proj.Project_Contract_Line_Items__r.isEmpty() && 
				regionNames.contains(proj.pse__Account__r.TERR_HIER_2__c) && 
				proj.pse__Project_Manager__r.pse__Salesforce_User__c == proj.OwnerId)
			{
				taskRecord = new Task();
				taskRecord.whatID  = proj.id;
				taskRecord.ownerid = proj.Owner.Id;
				taskRecord.status = status;
				taskRecord.subject = subject;
				taskRecord.recordtypeid = PSAActivityId;
				taskRecord.Activitydate = date.newInstance(today.year(), today.month(), dueDay);
		
				tasksToInsert.add(taskRecord);
                System.debug('Creating an instance of Task :: ' + tasksToInsert);
			}
		}
		System.debug('today.day() :: ' + today.day()+ ' :::::: '+ 'runDay ::::: ' + runDay );
		if(today.day() == runDay)
		{
            System.debug(' inside if condition runDay');
			upsertResultRecords = Database.upsert(tasksToInsert,false);
			PSA_AutoCreateProjectUtil.PopulateErrorTableForUpsert(upsertResultRecords, 'Project Tasks');
		}
	}
	
	public void finish(Database.BatchableContext BC) 
	{
		PSA_AutoCreateProjectUtil.sendErrorMails('Automated creation of tasks',
												'The tasks have been sucessfully created');			
	}
	
}