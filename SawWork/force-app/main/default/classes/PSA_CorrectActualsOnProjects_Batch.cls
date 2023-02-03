/*
 * CR: FFPSA-1811
 * Release: 21.6
 * Developer: Sujay
 * Summary: Actuals are incorrectly calculated by FF - this batch class runs and corrects Actuals in the org for the open projects 
 * Database.executeBatch(new PSA_CorrectActualsOnProjects_Batch(),2000);
*/
public class PSA_CorrectActualsOnProjects_Batch implements Database.Batchable<sObject>, Database.Stateful 
{
    
    public String query;
    public String table; 
    public String actualsRow;
    public PSA_Timecard_Approval__c stopApproval;
    public Map<Id, Decimal> 		projIdToBillableHours;
    public Map<Id, Decimal> 		projIdToCredNonBillIntHrs;
    public Map<Id, Decimal> 		projIdToNonBillableIntHrs;
    public Map<Id, Decimal> 		projIdToExcludedHours;
    public Map<Id, pse__Proj__c> 	projectIdToProjects;
    public List<pse__Proj__c> 		correctedActuals;
    public Map<Id, Pse__Proj__c> 	individualProjects;
    public string customQuery     = [select Value_Long__c from PSA_Common_Setting__mdt  where type__c = 'ActualsRecalcDateFilter'][0].value_Long__c;
    public string updateDB     	  = [select value__c from PSA_Common_Setting__mdt  where type__c = 'ActualsRecalcDateFilter'][0].value__c;
    
    
    public PSA_CorrectActualsOnProjects_Batch() 
    {   
		System.debug('in constructor');
        table = 'Id, RecordtypeId, pse__Billable_Internal_Hours__c, pse__Credited_Non_Billable_Internal_Hours__c, pse__Non_Billable_Internal_Hours__c, pse__Excluded_Hours__c \n';
        actualsRow = '';
        
		individualProjects 			= new Map<Id, Pse__Proj__c>();
		projIdToBillableHours 		= new Map<Id, Decimal>();
		projIdToCredNonBillIntHrs 	= new Map<Id, Decimal>();
        projIdToNonBillableIntHrs	= new Map<Id, Decimal>();
        projIdToExcludedHours		= new Map<Id, Decimal>();
		projectIdToProjects 		= new Map<Id, pse__Proj__c>();
		correctedActuals 			= new List<pse__Proj__c>();
        
        stopApproval = PSA_Timecard_Approval__c.getOrgDefaults();
        //stop Timecard Approvals till Actuals are calculated
        System.debug('stopApproval >> '+ stopApproval);
        if(stopApproval != null)
        {
            stopApproval.Stop_Approval__c = true;
            update stopApproval;
        }
        System.debug('stopApproval :: '+ stopApproval);
    }
    
    
    public Database.QueryLocator start(Database.BatchableContext BC) 
    {
        if(query == null)
        {
            //featch all active projects timecards for Actuals recalc
            query = customQuery;
            if(Test.isRunningTest())
            {
                query += ' limit 1';
            }
            System.debug('query :: '+ query);
        }
        return Database.getQueryLocator(query);
    }
    
    
    public void execute(Database.BatchableContext BC, List<sObject> scope) 
    {
        
        List<pse__Timecard_Header__c> lstTimecards	= (List<pse__Timecard_Header__c>)scope;
                
        System.debug('in execute method :: ' + lstTimecards.size());
        
        for(pse__Timecard_Header__c eTC : lstTimecards)
        {
            if(eTC.pse__Billable__c)
            {
                if(!projIdToBillableHours.containsKey(eTC.pse__Project__c))
                {
                    projIdToBillableHours.put(eTC.pse__Project__c,0);
                }
                projIdToBillableHours.put(eTC.pse__Project__c,(projIdToBillableHours.get(eTC.pse__Project__c) + eTC.pse__Total_Hours__c));
            }
            else
            {
                if(eTC.pse__Time_Credited__c)
                {
                    if(!projIdToCredNonBillIntHrs.containsKey(eTC.pse__Project__c))
                    {
                        projIdToCredNonBillIntHrs.put(eTC.pse__Project__c,0);
                    }
                	projIdToCredNonBillIntHrs.put(eTC.pse__Project__c,(projIdToCredNonBillIntHrs.get(eTC.pse__Project__c) + eTC.pse__Total_Hours__c));
                }
                else if(eTC.pse__Time_Excluded__c )
                {
                    if(!projIdToExcludedHours.containsKey(eTC.pse__Project__c))
                    {
                        projIdToExcludedHours.put(eTC.pse__Project__c,0);
                    }
                	projIdToExcludedHours.put(eTC.pse__Project__c,(projIdToExcludedHours.get(eTC.pse__Project__c) + eTC.pse__Total_Hours__c));
                }
                else if(!eTC.pse__Time_Credited__c && !eTC.pse__Time_Excluded__c)
                {
                    if(!projIdToNonBillableIntHrs.containsKey(eTC.pse__Project__c))
                    {
                        projIdToNonBillableIntHrs.put(eTC.pse__Project__c,0);
                    }
                	projIdToNonBillableIntHrs.put(eTC.pse__Project__c,(projIdToNonBillableIntHrs.get(eTC.pse__Project__c) + eTC.pse__Total_Hours__c));
                }
            }
			
            if(!individualProjects.containsKey(eTC.pse__Project__c))
            {
                //this is to store the current value of project with columns and avoiding an SOQL
                individualProjects.put(eTC.pse__Project__c,  new pse__Proj__c(
                    Id 											 = eTC.pse__Project__c, 
                    pse__Billable_Internal_Hours__c 			 = eTC.pse__Project__r.pse__Billable_Internal_Hours__c != null ? eTC.pse__Project__r.pse__Billable_Internal_Hours__c : 0,
                    pse__Credited_Non_Billable_Internal_Hours__c = eTC.pse__Project__r.pse__Credited_Non_Billable_Internal_Hours__c != null ? eTC.pse__Project__r.pse__Credited_Non_Billable_Internal_Hours__c : 0,
                    pse__Non_Billable_Internal_Hours__c 		 = eTC.pse__Project__r.pse__Non_Billable_Internal_Hours__c != null ? eTC.pse__Project__r.pse__Non_Billable_Internal_Hours__c : 0,
                    pse__Excluded_Hours__c 						 = eTC.pse__Project__r.pse__Excluded_Hours__c != null ? eTC.pse__Project__r.pse__Excluded_Hours__c : 0,
                    RecordTypeId								 = eTC.pse__Project__r.RecordtypeId));
            }
            
            // This will store the correct Actuals calculation over the payload iteration.
            projectIdToProjects.put(eTC.pse__Project__c, new pse__Proj__c(
                    Id 											 = eTC.pse__Project__c, 
                    pse__Billable_Internal_Hours__c 			 = projIdToBillableHours.get(eTC.pse__Project__c),
                    pse__Credited_Non_Billable_Internal_Hours__c = projIdToCredNonBillIntHrs.get(eTC.pse__Project__c),
                	pse__Non_Billable_Internal_Hours__c			 = projIdToNonBillableIntHrs.get(eTC.pse__Project__c),
                	pse__Excluded_Hours__c						 = projIdToExcludedHours.get(eTC.pse__Project__c)));
        }
        
    }
    
    public void finish(Database.BatchableContext BC) 
    {
        System.debug('in Finish method');
        for(pse__Proj__c eProj : individualProjects.values())
        {   
            System.debug('eProj :: ' + eProj);
            if( (projectIdToProjects.get(eProj.Id).pse__Billable_Internal_Hours__c != null ? projectIdToProjects.get(eProj.Id).pse__Billable_Internal_Hours__c : 0) != eProj.pse__Billable_Internal_Hours__c 
               	|| (projectIdToProjects.get(eProj.Id).pse__Credited_Non_Billable_Internal_Hours__c != null ? projectIdToProjects.get(eProj.Id).pse__Credited_Non_Billable_Internal_Hours__c : 0) != eProj.pse__Credited_Non_Billable_Internal_Hours__c
              		|| (projectIdToProjects.get(eProj.Id).pse__Non_Billable_Internal_Hours__c != null ? projectIdToProjects.get(eProj.Id).pse__Non_Billable_Internal_Hours__c : 0) != eProj.pse__Non_Billable_Internal_Hours__c
              			|| (projectIdToProjects.get(eProj.Id).pse__Excluded_Hours__c != null ? projectIdToProjects.get(eProj.Id).pse__Excluded_Hours__c : 0) != eProj.pse__Excluded_Hours__c
              ) 
            {
                correctedActuals.add(projectIdToProjects.get(eProj.Id));
                actualsRow += eProj.Id +',' + eProj.RecordtypeId  +','+ projectIdToProjects.get(eProj.Id).pse__Billable_Internal_Hours__c  + ','+ projectIdToProjects.get(eProj.Id).pse__Credited_Non_Billable_Internal_Hours__c + ','+ projectIdToProjects.get(eProj.Id).pse__Non_Billable_Internal_Hours__c + ','+ projectIdToProjects.get(eProj.Id).pse__Excluded_Hours__c +'\n'; 
            }
        }
        
        if(!correctedActuals.isempty())
        {
            if( updateDB == 'yes')
            {
            	Database.SaveResult[] saveResults = Database.update(correctedActuals,false);
            	PSA_AutoCreateProjectUtil.PopulateErrorTableForUpdate(saveResults, correctedActuals);	
            }
        }  
        
        System.debug('actualsRow :: ' + actualsRow);
        //Allow Timecard Approvals
        if(stopApproval != null)
        {
            stopApproval.Stop_Approval__c = false;
            update stopApproval;
        }
        
        
         if(actualsRow != '')
        {

            PSA_Settings__c EnggEmail = PSA_Settings__c.getInstance('Engineering Team Email');
            String emailAddress = EnggEmail != null ?EnggEmail.Value__c : 'services-engg@akamai.com';
            
            Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
            blob csvBlob = Blob.valueOf(table + actualsRow);
            string csvname= 'ActualtHoursWithProject.csv';
            csvAttc.setFileName(csvname);
            csvAttc.setBody(csvBlob);
            Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
            String subject ='ActualtHoursWithProject CSV';
            email.setSubject(subject);
            email.setToAddresses( new List<String>{emailAddress, 'sujs@akamai.com'});
            email.setPlainTextBody('PFA the ActualtHoursWithProject CSV.');
            email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
            Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});  
            System.debug('sending Email :: ' + r);
            
        }
        else
        {
            PSA_AutoCreateProjectUtil.sendErrorMails('Actuals Correction Batch Processed! ','No projects Hours Updated. ');
        }
    }
    
}