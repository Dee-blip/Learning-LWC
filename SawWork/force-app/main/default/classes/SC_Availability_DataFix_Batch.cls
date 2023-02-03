/*
Author          : Tejaswini 
Test Class      : SC_Availability_DataFix_BatchTest

Date                 Developer               JIRA #          Description                                                       
-----------------------------------------------------------------------------------------------------------------
23 Aug 2021        	 Tejaswini 				ESESP-5875	    Batch class for existing availability records Data fix
*/
public class SC_Availability_DataFix_Batch implements Database.Batchable<sObject>, Database.Stateful {
    
    public Integer recordsProcessed = 0;
    public Map <Integer,String > mDayNoDay = new Map <Integer, String>{1=>'Monday',2=>'Tuesday',3=>'Wednesday',4=>'Thursday',5=>'Friday',6=>'Saturday',7=>'Sunday'};
    public Integer methodNoFlag;
    Public String batchQuery = Null;
    public String DataFix_Query;
    public Integer successRecords = 0;
    public Integer failureRecords = 0;
    
    public string errorMessage = 'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' +'Batch Class Name = SC_Availability_DataFix_Batch\n' ;
    
    public SC_Availability_DataFix_Batch(Integer methodNo){
        this.methodNoFlag = methodNo;
        if(methodNoFlag==1)
        {
            this.DataFix_Query = 'Select  Id from SC_SOCC_Availability__c where Contact__c not in (Select contact_name__c from Authorized_Contact__c )';
        }
        else if(methodNoFlag==2)
        {
            if(!Test.isRunningTest()){
                this.DataFix_Query = 'Select  Id,Start_Time__c, End_Time__c from SC_SOCC_Availability__c where End_Time__c  = 00:00:00.000Z';
            }
            else{
                this.DataFix_Query = 'Select  Id,Start_Time__c, End_Time__c from SC_SOCC_Availability__c';
            }
		}
        else if(methodNoFlag==3)
        {
            this.DataFix_Query = 'Select Id,Start_Time__c, End_Time__c from SC_SOCC_Availability__c where Start_Time__c!=null AND End_Time__c!=null';
        }        
        /*else if(methodNoFlag==4)
        {
            this.DataFix_Query = 'Select Id,Start_Time__c,End_Time__c,Start_Date_Time__c, End_Date_Time__c, Timezone_offset__c, CreatedDate,Contact_Timezone_Name__c from SC_SOCC_Availability__c where Contact_Timezone_Name__c != null';
        }*/
        else if(methodNoFlag==5)
        {
            this.DataFix_Query = 'Select id From Contact where id not in (Select Contact__c from SC_SOCC_Availability__c) and id in (Select Contact_Name__c from Authorized_Contact__c)';
        }
        
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        batchQuery = DataFix_Query;
        return Database.getQueryLocator(batchQuery);
    }
    
    public void execute(Database.BatchableContext bc, List<sObject> scope){
        
        List<SC_SOCC_Availability__c> lAvailRecords = new List<SC_SOCC_Availability__c>();
   		
   		List<Authorized_Contact__c> lAuthContacts = new List<Authorized_Contact__c>();
        
        List<Contact> lContacts = new List<Contact>();

        if(methodNoFlag==1)
        {
            lAvailRecords = (SC_SOCC_Availability__c[]) scope; 
            DeleteAvailRecords(lAvailRecords);
        }
        else if(methodNoFlag==2)
        {
            lAvailRecords = (SC_SOCC_Availability__c[]) scope; 
            UpdateEndTimeOfAvailRecords(lAvailRecords);            
        }        
        else if(methodNoFlag==3)
        {
            lAvailRecords = (SC_SOCC_Availability__c[]) scope; 
            DeleteInconsistentAvailRecords(lAvailRecords);
        }
        /*else if(methodNoFlag==4)
        {
            lAvailRecords = (SC_SOCC_Availability__c[]) scope; 
            UpdateDSTInAvailRecords(lAvailRecords);
        }*/
        else if(methodNoFlag==5)
        {
            lContacts = (Contact[]) scope;  
            CreateDefaultAvailRecords(lContacts);
        }
    }
    
    public void finish(Database.BatchableContext bc){
        System.debug(recordsProcessed + ' total records are processed');
        System.debug(successRecords + ' records are successfully processed');
        System.debug(failureRecords + ' records are failed');
        
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors,JobItemsProcessed,TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bc.getJobId()];  
        
        List<Messaging.SingleEmailMessage> lemail = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<String> sendTo = new List<String>();
        sendTo.add('tenagara@akamai.com');
        mail.setToAddresses(sendTo);
        
        mail.setReplyTo('tejunagraj12@gmail.com');
        
        List<String> ccTo = new List<String>();
        ccTo.add('vrudrapp@akamai.com');
        mail.setCcAddresses(ccTo);
        
        mail.setSubject('Datafix batch results Method Number: '+ methodNoFlag);
        String body ='Total records that are processed : '+ recordsProcessed;
        body+='<br/> Number of records that are processed successfully : '+ successRecords;
        body+='<br/> Number of records that are failed : '+ failureRecords;
        body+='<br/> The job id is : '+job.Id;
        mail.setHtmlBody(body);
        lemail.add(mail);
        if(!Test.isRunningTest()){
            Messaging.sendEmail(lemail);
        }
                
    }
    
    
    public void DeleteAvailRecords(List<SC_SOCC_Availability__c> lAvailRecords){
        recordsProcessed = recordsProcessed + lAvailRecords.size();
        if(lAvailRecords.size()>0)
        {
           Database.DeleteResult [] drList = Database.delete(lAvailRecords,false);
                
           for (Database.DeleteResult  dr : drList) {
    			if (dr.isSuccess())
                {
        			System.debug('Successfully inserted Availrecords. Avail Record ID: ' + dr.getId());
                    successRecords = successRecords+1;
    			}
    			else 
                {
                    for(Database.Error err : dr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Failed Availrecords. Avail Record ID:  ' + err.getFields ());
                        failureRecords = failureRecords+1;
                    }
    			}
            }              
        }        
    }
    
    public void DeleteInconsistentAvailRecords(List<SC_SOCC_Availability__c> lAvailRecords)
    {
        List<SC_SOCC_Availability__c> lDeleteRecords = new List<SC_SOCC_Availability__c>();
		for(SC_SOCC_Availability__c eachRec:lAvailRecords)
		{	
	
    		Long startTimeMS = (eachRec.Start_Time__c).hour() * 60 * 60 * 1000 + (eachRec.Start_Time__c).minute() * 60 * 1000 + (eachRec.Start_Time__c).second() * 100 + (eachRec.Start_Time__c).millisecond();
    		Long endTimeMS = (eachRec.End_Time__c).hour() * 60 * 60 * 1000 + (eachRec.End_Time__c).minute() * 60 * 1000 + (eachRec.End_Time__c).second() * 100 + (eachRec.End_Time__c).millisecond();
    
    		System.debug('The start time');
    		System.debug(startTimeMS);
    
    		System.debug('The end time');
    		System.debug(endTimeMS);

			if(startTimeMS >= endTimeMS)
			{	
				lDeleteRecords.add(eachRec);
				System.debug('the id of records to be deleted ');
        		System.debug(eachRec.Id);
                recordsProcessed = recordsProcessed + 1;
			}	
		}
        
        if(lDeleteRecords.size()>0)
        {
            Database.DeleteResult [] drList = Database.delete(lDeleteRecords,false);
            
            for (Database.DeleteResult  dr : drList) {
                if (dr.isSuccess())
                {
                    System.debug('Successfully inserted Availrecords. Avail Record ID: ' + dr.getId());
                    successRecords = successRecords+1;
                }
                else 
                {
                    for(Database.Error err : dr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Failed Availrecords. Avail Record ID:  ' + err.getFields ());
                        failureRecords = failureRecords+1;
                    }
                }
            }              
        } 
    }
    
    public void UpdateEndTimeOfAvailRecords(List<SC_SOCC_Availability__c> lAvailRecords)
    {
        List<SC_SOCC_Availability__c> lUpdateRecords = new List<SC_SOCC_Availability__c>();
		for(SC_SOCC_Availability__c eachRec:lAvailRecords)
		{
			eachRec.End_Time__c = Time.newInstance(23, 59, 0, 0);
			lUpdateRecords.add(eachRec);
            recordsProcessed = recordsProcessed + 1;
		}
		if(lUpdateRecords.size()>0)
        { 
            Database.SaveResult[] srList = Database.update(lUpdateRecords,false);
            
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess())
                {
                    System.debug('Successfully updated Availrecords. Avail Record ID: ' + sr.getId());
                    successRecords = successRecords+1;
                }
                else 
                {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Failed Availrecords. Avail Record ID:  ' + err.getFields ());
                        failureRecords = failureRecords+1;
                    }
                }
            }                           
        }         
    }
    
    /*public void UpdateDSTInAvailRecords(List<SC_SOCC_Availability__c> lAvailRecords)
    {
        List<SC_SOCC_Availability__c> lUpdateRecords = new List<SC_SOCC_Availability__c>();
		DateTime currentDateTime = DateTime.now();
        System.debug('test 1');
		for(SC_SOCC_Availability__c eachRec:lAvailRecords)
        {
            System.debug('test 2');
			if(eachRec.Contact_Timezone_Name__c!=null)
            {
                System.debug('test 3');
				String tzName = eachRec.Contact_Timezone_Name__c;
    			System.debug('Timezone name' +tzName);
    			Timezone tz = Timezone.getTimeZone(tzName);
    			System.debug('Timezone tz' +tz);

    			Double ms = tz.getOffset(eachRec.CreatedDate);
 				System.debug('Offset miliseconds: ' + ms);
				Double curTzOffset = (ms/3600000);
 				System.debug('the curTzOffset:  '+curTzOffset);

 				eachRec.Timezone_offset__c = curTzOffset;
 				lUpdateRecords.add(eachRec);
                recordsProcessed = recordsProcessed + 1;
	   		 }	
		}
        if(lUpdateRecords.size()>0)
        {
            Database.SaveResult[] srList = Database.update(lUpdateRecords,false);
            
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess())
                {
                    System.debug('Successfully updated Availrecords. Avail Record ID: ' + sr.getId());
                    successRecords = successRecords+1;
                }
                else 
                {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Failed Availrecords. Avail Record ID:  ' + err.getFields ());
                        failureRecords = failureRecords+1;
                    }
                }
            }              
        } 
    }
    */
    
    public void CreateDefaultAvailRecords(List<Contact> lContacts)
    {
        Set<Id> uniqueConId = new Set<Id>();
        List<SC_SOCC_Availability__c> lAvailabilityRecords = new List<SC_SOCC_Availability__c>();
        
        for(Contact rec:lContacts){
			uniqueConId.add(rec.Id);
		}
		for(Id conId:uniqueConId)
        {
			for(Integer i=1;i<=7;i++)
			{
				SC_SOCC_Availability__c rec = new SC_SOCC_Availability__c();
				rec.Contact__c = conId ;
				rec.Day_Of_Week__c = mDayNoDay.get(i);
				rec.Start_Time__c = Time.newInstance(0, 0, 0, 0);
				rec.End_Time__c = Time.newInstance(23, 59, 0, 0);
				lAvailabilityRecords.add(rec);
                recordsProcessed = recordsProcessed + 1;
			}
		}
        
        if(lAvailabilityRecords.size()>0)
        {
            Database.SaveResult[] srList = Database.insert(lAvailabilityRecords,false);
                
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess())
                {
                    System.debug('Successfully inserted Availrecords. Avail Record ID: ' + sr.getId());
                    successRecords = successRecords+1;
                }
                else 
                {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Failed Availrecords. Avail Record ID:  ' + err.getFields ());
                        failureRecords = failureRecords+1;
                    }
                }
            }              
        }
    }
       
}