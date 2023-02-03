/*--=====================================================================================================+

|  HISTORY  |                                                                            

|  DATE           DEVELOPER   CR          DESCRIPTION                                                       

|  ===========    =========   =======     =========== 
                                                       
|  03-Oct-2016    Akhila      3527281     Batch class for the first version of Automating License Usage Report

+=====================================================================================================--*/
global class LicenseUsageReporterBatchClass implements Database.Batchable<sObject>, Database.Stateful {
  String query;
  Set<Id> uIdSet;
  Set<String> querySet;
  String currentQuery;
  Integer batchSize;
  License_Job_Logger__c logRec;
  DateTime sd,ed;   
    
  global LicenseUsageReporterBatchClass(Set<Id> uIdSet,Set<String> querySet,String currentQuery,Integer batchSize,License_Job_Logger__c logRec)
  {
      this.currentQuery = currentQuery;
      //Stores set of userIds which are using the license
      this.uIdSet = new Set<Id>();
      //Intitially for the first query objectUserIdSet would be empty, if not keep on adding for every batch
      if(!uIdSet.isEmpty())
          this.uIdSet.addAll(uIdSet);
      this.querySet = new Set<String>();
      if(!querySet.isEmpty())
          this.querySet.addAll(querySet);
      this.batchSize = batchSize;
      this.logRec = logRec;
      this.sd = logRec.Start_Date_Time__c;
	  this.ed = logRec.End_Date_Time__c;
  }
    
  //Start Method
  global Database.Querylocator start (Database.BatchableContext BC) {
    String q = currentQuery + ' and LastModifiedDate >=: sd and LastModifiedDate <=: ed';
    if(system.Test.isRunningTest())
    {
		q+=' limit 10';
    }
      return Database.getQueryLocator(q);
  }

  //Execute method
  global void execute (Database.BatchableContext BC, List<sobject> scope) {
    for(sObject s : scope)
    {
        //Fetch the fields part of the query For eg: Select "CreatedById,LastModifiedById" from Case
        String fields = currentQuery.toLowerCase().substringBetween('select ', ' from');
        //Get every user field and trim it
        Set<String> setFields = new Set<String>(fields.split(','));
        System.debug(setFields);
        for(String f : setFields)
        {
            //Add the user field values
            if(f.trim()!='createddate' && f.trim()!='lastmodifieddate')
            {
                uIdSet.add((Id) s.get(f.trim()));
            }    
    	}
    }
  }

  //Finish Method
  global void finish(Database.BatchableContext BC){
     
    //If there are any errors in the batch send an email  
    List<AsyncApexJob> lApexJobs = [Select a.TotalJobItems, a.Status, a.NumberOfErrors, a.JobType, a.JobItemsProcessed, a.ExtendedStatus, a.CreatedById, a.CompletedDate From AsyncApexJob a WHERE id = :BC.getJobId() and Status = 'Failed'];//get the job Id
    if(!lApexJobs.isEmpty())
    {    
        //Update the record status as "Failed"
        License_Job_Logger__c licJob = new License_Job_Logger__c(Id=logRec.Id);
        licJob.Status__c = 'Failed';
        update licJob;
        
        AsyncApexJob a = lApexJobs[0];
        List<License_Query__c> lQueries = [Select Query_Suffix__c from License_Query__c where Object__c = 'email'];    
        String[] emails = new List<String>{logRec.Email__c};	    
        if(lQueries.size() > 0)    
        {
            emails.add(lQueries[0].Query_Suffix__c);  
        }    
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();    
        //below code will send an email to Logger Email address as well as ops team about the status
        mail.setToAddresses(emails);
        mail.setSubject('License Usage Report Generation Failed - '+a.Status);
        mail.setPlainTextBody('The Batch Apex job processed  '+a.TotalJobItems+'batches with  '+a.NumberOfErrors+'failures'+'Job Item processed are'+a.JobItemsProcessed);
        Messaging.sendEmail(new Messaging.Singleemailmessage [] {mail});
    }  
    else
    {  
        QuerySet.remove(currentQuery);  
     
        if(!QuerySet.isEmpty())
        {
            String nextQuery;
            for(String q : QuerySet)
            {
                nextQuery = q;
                break;
            }
            LicenseUsageReporterBatchClass lURB = new LicenseUsageReporterBatchClass(uIdSet,querySet,nextQuery,batchSize,logRec);
            Database.executeBatch(lURB,batchSize);
        }
        else
        {    
            
            String csvContent = 'Email,Name,Profile Name,Department,Business Unit,Manager Name,Manager Email Address\n' ;
            //Query for those users who have license and are not using it
            List<Id> lUsrWithoutUsage = new List<Id>();
            for(UserPackageLicense userPkgLic : [SELECT Id, UserId FROM UserPackageLicense where 
                                                    PackageLicense.NamespacePrefix=:logRec.License_Namespace_Prefix__c
                                                    and UserId NOT IN: uIdSet])
            {
                 lUsrWithoutUsage.add(userPkgLic.UserId);       
            }
            for(User u: [Select Id,Profile.Name,Department,Name,Business_Unit_Name__c,Email,Manager.Name,Manager.Email from User where Id IN:lUsrWithoutUsage])  
            {
                //Creating csv rows
                csvContent = csvContent + u.Email + ',' + u.Name + ',' + u.Profile.Name + ',' + u.Department + ',' + u.Business_Unit_Name__c + ',' + u.Manager.Name + ',' + u.Manager.Email + '\n';
            }
            Attachment att = new Attachment();
            att.Body=Blob.valueOf(csvContent);
            //Making the passed License Job Logger recId as parent  
            att.ParentId = logRec.Id;
            att.Name='Users with unutilized '+logRec.License_Type__c+ 'License Start Date: '+logRec.Start_Date_Time__c.format().replace('/','-') + ' End Date: ' + logRec.End_Date_Time__c.format().replace('/','-')+'.csv';  
            insert att;    
            //Update the record status as "Completed"
            License_Job_Logger__c licJob = new License_Job_Logger__c(Id=logRec.Id);
            licJob.Status__c = 'Completed';
            update licJob;
            
            List<License_Query__c> listQuery = [Select Object__c from License_Query__c where License_type__c =: logRec.License_Type__c];
            List<String> listObjects = new List<String>();
            for(License_Query__c q: listQuery)
            {
            	listObjects.add(q.Object__c) ;
            }
            //Send email to the License Job logger email address
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {logRec.Email__c};
            mail.setToAddresses(toAddresses);
            mail.setSubject('Users with unutilized '+logRec.License_Type__c+ 'License Start Date: '+logRec.Start_Date_Time__c.format().replace('/','-') + ' End Date: ' + logRec.End_Date_Time__c.format().replace('/','-'));
            mail.setBccSender(false);
            mail.setUseSignature(true);
            mail.setPlainTextBody('License Usage Report of \nLicense Type: '+logRec.License_Type__c+'\nStart Date: '+logRec.Start_Date_Time__c+'\nEnd Date: '+logRec.End_Date_Time__c+
                                  '\n Attached report is based on usage of following objects:\n' + listObjects);        
            List<Messaging.Emailfileattachment> fileAttachments = new List<Messaging.Emailfileattachment>();
            Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
            efa.setFileName(att.Name);
            efa.setBody(att.Body);
            fileAttachments.add(efa);
            mail.setFileAttachments(fileAttachments);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }  
     }	          
  }
}