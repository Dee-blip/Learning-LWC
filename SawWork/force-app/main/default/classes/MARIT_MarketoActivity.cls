global class MARIT_MarketoActivity implements Schedulable {
   global void execute(SchedulableContext sc) {
     
       // Custom object to store the daily activites done by Marketo
       List<Marketo_Activity_Details__c> marketoActivityRecordsList = new List<Marketo_Activity_Details__c>();
   
       List<Error_Log__c> errorLogs = new List<Error_Log__c>();
       Integer ctaInsertionCount = 0;
       Integer marketoLeadInsertionCount = 0;
       Integer campaignMemberInsertionCount = 0;
           
       String profileId;
       String returnMessage='';
    
       try{
           //profileId = MarketingUtilClass.getMarketingSettingsValue('MarketoIntegrationProfileId'); //'00eA0000000VTG1IAO' 
           profileId = GsmUtilClass.getGSMSettingValue('MarketoIntegrationProfileId');
           ctaInsertionCount = [Select COUNT() from Lead where CreatedDate = Yesterday and CreatedBy.Profile.Id = :profileId and RecordType.Name = 'Akamai Lead'];
           marketoLeadInsertionCount = [Select COUNT() from Lead where CreatedDate = Yesterday and CreatedBy.Profile.Id = :profileId and RecordType.Name = 'Marketo Lead'];
           campaignMemberInsertionCount = [Select COUNT() from CampaignMember where CreatedDate = Yesterday and CreatedBy.Profile.Id = :profileId];
           
           System.debug('marketoLeadInsertionCount: ' + marketoLeadInsertionCount);
           
           Marketo_Activity_Details__c ctaInsertion = new Marketo_Activity_Details__c();
           Marketo_Activity_Details__c marketoLeadInsertion = new Marketo_Activity_Details__c();
           Marketo_Activity_Details__c campaignMemberInsertion = new Marketo_Activity_Details__c();
          
           // tracking insertion for call to action
           ctaInsertion.Operation__c = 'Insert';
           ctaInsertion.Object_Type__c = 'Call To Action';
           ctaInsertion.Count_Of_Records__c = ctaInsertionCount; 
           marketoActivityRecordsList.add(ctaInsertion);
           
           // tracking insertion for Marketo Leads
           marketoLeadInsertion.Operation__c = 'Insert';
           marketoLeadInsertion.Object_Type__c = 'Marketo Lead';
           marketoLeadInsertion.Count_Of_Records__c = marketoLeadInsertionCount;
           marketoActivityRecordsList.add(marketoLeadInsertion);
           
           // tracking insertion for campaign member 
           campaignMemberInsertion.Operation__c = 'Insert';
           campaignMemberInsertion.Object_Type__c = 'Campaign Member';
           campaignMemberInsertion.Count_Of_Records__c =  campaignMemberInsertionCount;
           marketoActivityRecordsList.add(campaignMemberInsertion);
           
           System.debug(LoggingLevel.INFO,'Successfully Done the Activity');
           insert marketoActivityRecordsList;
           for (Marketo_Activity_Details__c activityObj : marketoActivityRecordsList) {
               returnMessage = activityObj.Id +','; 
           }
       } catch(Exception e) {
           System.debug(LoggingLevel.ERROR, 'The following exception has occurred: ' + e.getMessage());
           errorLogs.add(new Error_Log__c(Name='MarketoActivity', Class__c='MARIT_MarketoActivity', Error_Message__c=e.getMessage()));
           Database.insert(errorLogs, false);
        } finally {
            List<Cron_Batch_Run__c> cronBatchRunList=[select Id,results__c,lastModifiedDate from Cron_Batch_Run__c where trigger_batch_run__c = true and cron_batch_job__r.Name='Marketo Activity Batch Job' order by lastModifiedDate desc];
            if(cronBatchRunList!=null && cronBatchRunList.size()>0)
            {
                Cron_Batch_Run__c cronBatchRun=cronBatchRunList[0];
                cronBatchRun.results__c=returnMessage;
                update cronBatchRun;
            }
        }
   }
}