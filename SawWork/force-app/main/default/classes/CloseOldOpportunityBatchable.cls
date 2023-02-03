/***
    CloseOldOpportunityBatchable
    @author : Ali KM
    @Description :  This class closes open opportunities to Closed Admin.
                    
    @History
    --Developer           --Date            --Change
    Ali KM				  29/07/12			CR 1762643 Re-schedule job to make opportunity 'Closed Admin'.
    										Logic: If the job runs today, it should pick up Opportunities (ADS/Akamai Only) with SS NOT IN (ss6,closed won, closed lost) and 
    										Close Date <= previous Month's 1st.
    Sujan				  18/06/13			CR 2247491 PRM: Close out open DR after 45 days past Close date
    								        Logic : Used the existing Close Old Opp functionality
    								        Added the record types Deal Reg Submitted/Unsubmitted/Rejected to list of existing  (ADS/Akamai) and added them to custom 
    								        setting GSM.Deals also which have 'Close Date <= previous Month's 1st' will be closed by changing the stage to 'Close Admin' and Record Type is changed to Rejected.
    													
*/
global class CloseOldOpportunityBatchable implements Database.Batchable<sObject> 
{	
    private String query;
    Cron_Batch_Run__c parentCronBatchRun=null;
    Boolean initialized=false;
	Integer intTotalDaysOld=0;
	
    // Fetch Custom Settings
	global static final String[] SS_TO_IGNORE = GsmUtilClass.getGSMSettingValue('SchOpptyClose_SalesStagesToIgnore').split(',');
	global static final Integer NO_OF_MONTHS_OLD = Integer.valueOf(GsmUtilClass.getGSMSettingValue('SchOpptyClose_NoOfMonthsOld'));
	global static final Integer CLOSEDATE_LAST_N_DAYS_OLD = Integer.valueOf(GsmUtilClass.getGSMSettingValue('SchOpptyClose_CloseDateNDaysOld'));
	global static final String[] Opportunity_Record_Types = GsmUtilClass.getGSMSettingValue('Opportunity_Record_Types').split(',');
	global static final String[] Record_Type_Ids = GsmUtilClass.getGSMSettingValue('Opportunity_Record_Type_Ids').split(',');
	global static final Datetime Close_Start_Date = datetime.valueOf(GsmUtilClass.getGSMSettingValue('Start_date_of_close_deals'));
	// constructor #1
    global 	CloseOldOpportunityBatchable() 
    {
    	this.initialized=doInitialize();
    }
    // constructor #2    
    global 	CloseOldOpportunityBatchable(Cron_Batch_Run__c pParentCronBatchRun)  
    {
    	this.parentCronBatchRun = pParentCronBatchRun;
    	this.initialized=doInitialize();
    }
    
    // implement start method
    global database.querylocator start(Database.BatchableContext BC)
    {	
        return Database.getQueryLocator(query);
	}
	
	// implement execute method
	global void execute(Database.BatchableContext BC, List<sObject> scope)
	{
		if (!this.initialized)
			return;
		
		String res = 'No records to process';
		List<Opportunity> toUpdateOpptyList = new List<Opportunity>();
		//system.debug('toUpdateOpptyList=' + toUpdateOpptyList);
        toUpdateOpptyList =scope;
        // Loop thru qualified
        for(Opportunity opp : toUpdateOpptyList)
        {	
        	// if it is a deal update the record type to deal_reg_rejected and AKAM_Created_Date__c should be greater than Close_Start_Date
        	if((opp.RecordTypeId == Record_Type_Ids[0] || opp.RecordTypeId == Record_Type_Ids[1])) {
             if(opp.AKAM_Created_Date__c > Close_Start_Date) {
              opp.Validation_Override__c = true;
              opp.StageName = 'Closed Admin';
              opp.RecordTypeId = Record_Type_Ids[2];
             }
             } else {
               opp.Validation_Override__c = true;
               opp.StageName = 'Closed Admin';
            }
        }   

        //System.debug('updateOpptys for CloseOldOpptys=' + updateOpptys + '\n CloseOpptyListSize=' + updateOpptys.size());
        
        if(toUpdateOpptyList.size() > 0)
        {	
			//System.debug('CloseOldOpptyScheduleClass.updateCloseOldOpportunityFlag BEFORE update=' + CloseOldOpptyScheduleClass.updateCloseOldOpportunityFlag);
			Set<Id> erroredOpptyIds = new Set<Id>();
			// Ensure no @future methods are run in Opportunity trigger code.
			CloseOldOpptyScheduleClass.updateCloseOldOpportunityFlag=true;
			// Update the Opptys.            
			Database.SaveResult[] results = Database.update(toUpdateOpptyList, false);
			// Disable the flag.
			CloseOldOpptyScheduleClass.updateCloseOldOpportunityFlag=false;
			
			
			String strErrorLog=null;
			Integer failedCount=0;
			Integer count=0;
			//Integer noOfOpportunitiesClosedAdmin=0;
			// Loop thru the results.
			for(Database.SaveResult sr:results)
			{
			   if(!sr.isSuccess())
			   {
			      	strErrorLog+='\nFailed Record count:'+ ++failedCount;
		            strErrorLog+='##getStatusCode:'+sr.getErrors()[0].getStatusCode();
		            strErrorLog+='##getRecordId:'+ toUpdateOpptyList[count].Id;
			   }
			   count++;
			}			
			res='No. of Opportunities Closed Admin=' + (count-failedcount);
			
			if (this.parentCronBatchRun!=null)				
			{	
				//System.debug('BC Job Id=' + BC.getJobId());
				//System.debug('LASTBATCHPROCESSID=' + GSM_Custom_Settings__c.getInstance('SchOpptyClose#lastBatchProcessId').Value__c);
				//System.debug('parent cronBatchRecord=' + this.parentCronBatchRun);
				
				// Refresh the this.parentCronBatchRun
				if (this.parentCronBatchRun!=null)
					this.parentCronBatchRun = [Select Id, Scheduled_to_Run__c, Cron_Batch_Job__c, Completed__c, Trigger_Batch_Run__c, Parent_Cron_Batch_Run__c,BatchProcessId__c,  
						Results__c, Result__c, Validation_Override__c from Cron_Batch_Run__c where BatchProcessId__c = : GSM_Custom_Settings__c.getInstance('SchOpptyClose#lastBatchProcessId').Value__c][0];
				
				//String result='No. of Opportunities Closed Admin=' + (count-failedcount);
				Cron_Batch_Run__c cbr = new Cron_Batch_Run__c();
				cbr.Cron_Batch_Job__c = parentCronBatchRun.Cron_Batch_Job__c;
				cbr.Parent_Cron_Batch_Run__c = parentCronBatchRun.Id;
				cbr.Scheduled_to_Run__c = parentCronBatchRun.Scheduled_to_Run__c;
				
				if(strErrorLog!=null)
				{
					cbr.Result__c ='Error';
					res+=strErrorLog;
				}
				else
					cbr.Result__c = 'Success';
				
				// Trim the length of Result to ensure its less than 32K	
				if (res.length()>31990)
					res = res.substring(0,31900);	 
				cbr.Results__c = res;
				cbr.Validation_Override__c=true;
				cbr.Trigger_Batch_Run__c = true;
				cbr.Completed__c = Datetime.now();
				insert cbr;
			}
        }	
	}
	
    global void finish(Database.BatchableContext BC)
    {   
		// Get the ID of the AsyncApexJob representing this batch job from Database.BatchableContext.   
		// Query the AsyncApexJob object to retrieve the current job's information.
		AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
							FROM AsyncApexJob WHERE Id = :BC.getJobId()];
							
		if (this.parentCronBatchRun!=null)					
		{	
			Cron_Batch_Run__c cbr = [Select Id, Cron_Batch_Job__c, Completed__c, Trigger_Batch_Run__c, Parent_Cron_Batch_Run__c, 
				BatchProcessId__c, Results__c, Result__c, Validation_Override__c from Cron_Batch_Run__c where BatchProcessId__c =: GSM_Custom_Settings__c.getInstance('SchOpptyClose#lastBatchProcessId').Value__c][0];//BC.getJobId()][0];
			if (a.NumberOfErrors>0)
				cbr.Result__c ='Error';
			else
				cbr.Result__c = 'Success';
			cbr.Results__c = '\n BatchProcessId=' +BC.getJobId()+ '\n CustomSetting BatchProcessID='+ GSM_Custom_Settings__c.getInstance('SchOpptyClose#lastBatchProcessId').Value__c +'\nThe job processed ' + a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures.\n';
			cbr.Validation_Override__c=true;
			update cbr;
		}
	}
	
	/**
		doInitialize()
		- Builds the query for execution.
	*/
	public Boolean doInitialize() 
	{	
		// Get Today's date.
		Date dtToday = Date.today();
		// set totalDaysOld for current month.
		intTotalDaysOld = dtToday.day();
		//calculate total no. of Days old Oppty.CloseDate should be.
		for (Integer i=1; i<NO_OF_MONTHS_OLD; i++)
		{	
		    intTotalDaysOld += Date.daysInMonth(dtToday.year(), dtToday.month()-i);
		    //System.debug('intTotalDaysOld:' + i + ':=' + intTotalDaysOld);
		}
		
		//Debug
		/*
    	System.debug('strSSToIgnoreList=' + SS_TO_IGNORE);
    	System.debug('strNoOfMonthsOld=' + NO_OF_MONTHS_OLD);
    	System.debug('dtToday=' + dtToday);
		System.debug('DAYS OF YEAR=' + dtToday.dayOfYear());
    	System.debug('intTotalDaysOld=' + intTotalDaysOld);
		System.debug('Close Date Less Than dtToday=' + dtToday.addDays(-1*intTotalDaysOld));
		System.debug('Close Date Less Than TODAY=' + Date.today().addDays(-1*intTotalDaysOld));
    	*/
    	
    	// Build the query.	  
		String opptyStagesExclude = '';
    	for (String opptyStage : SS_TO_IGNORE)
    	{
    		if (opptyStagesExclude=='')
    			opptyStagesExclude= '\'' + opptyStage + '\'';
    		else
    			opptyStagesExclude+= ',\'' + opptyStage + '\'';
    	}
    	
   	 	
   	 	List<Id> opptyRecTypes = new List<Id>();
   	 	for(String OppRt : Opportunity_Record_Types)
   	 	{
   	 		opptyRecTypes.add(Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(OppRt).getRecordTypeId());
   	 	}
   	 	String strOpptyRecTypes = '';
	    for (Id recId : opptyRecTypes )
	    {
	    	if (strOpptyRecTypes=='')
    			strOpptyRecTypes= '\'' + recId + '\'';
    		else
    			strOpptyRecTypes+= ',\'' + recId + '\'';
	    }
	    // opptyRecTypes.add(Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('ADS Record Type').getRecordTypeId());
	   
	    //System.debug('strOpptyRecTypes='+ strOpptyRecTypes);
   	 	// added o.RecordTypeId to the query as i am updating the RecordTypeId to rejected if they are deals.
		String query = 'SELECT o.Id,o.RecordTypeId,o.AKAM_Created_Date__c, o.StageName, o.CloseDate, o.Validation_Override__c FROM Opportunity o WHERE o.CloseDate !=null';
			query+= ' AND o.CloseDate <=' + getDateString(Date.today().addDays(-1*intTotalDaysOld)) + ' AND o.CloseDate=LAST_N_DAYS:' + CLOSEDATE_LAST_N_DAYS_OLD;
			query+= ' AND o.StageName!=null AND o.StageName NOT IN (' + opptyStagesExclude + ') AND o.RecordTypeId IN (' + strOpptyRecTypes + ')';
		
		this.query = query; 				
		//System.debug('query='+ this.query);
		
		return true;
	}

	public static String getPaddedDateComponent(Integer pDtComponent)
	{
		String temp=String.valueOf(pDtComponent);
		 if (pDtComponent<10)
			temp = '0' + String.valueOf(pDtComponent);
		return temp;
	}
	
	public static String getDateString(Date pDate)
	{
		return pDate.year() + '-' + getPaddedDateComponent(pDate.month()) + '-' + getPaddedDateComponent(pDate.day());
	}
}