/***
    OEMCurrencyToUSDConversionBatchClass
    @author : Shivam Verma <shiverma@akamai.com>
    @Description : This batch class implements the following logic for the OEM Opportunity trigger :
                    - Update the OEM Opportunities for correct AMount in USD value for all the oem opportunity 
                      with closed date in last month and later.
   
    @History
    --Developer           --Date            --Change
    Shivam Verma          04/04/2015        Created the class.
***/
global class OEMCurrencyToUSDConversionBatchClass implements Database.Batchable<sObject>,Database.Stateful
{

    global Integer failedUpdates;
     global List<String> errorString ;
     global Boolean errorFlag {get;set;}
     public static Boolean nowRunningDataFix =false;
     
     global OEMCurrencytoUsdConversionBatchClass()
     {
         failedUpdates = 0;
         errorFlag = false;
         nowRunningDataFix = false;
         errorString = new List<String>();
     }
     
     global Database.QueryLocator start(Database.BatchableContext BC)
     {
          return Database.getQueryLocator([select Id,Name,CurrencyIsoCode,Amount__c,Amount_in_USD__c,Close_Date__c from OEM_Opportunity__c where Close_Date__c >= LAST_MONTH]);
     }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        nowRunningDataFix = true; 
        List<OEM_Opportunity__c> listOfOEMOpportunities = (List<OEM_Opportunity__c>)scope;
        List<Id> listOfOEMOppIds = new List<Id>();
        //Toggle functionality for the OTB Exchange Rate movement.
       if(Features_Toggle__c.getInstance('SFExchangeRateToggle').toggle__c){
            String futureDate=GSM_Custom_Settings__c.getInstance('CronCurrency#FutureDateDefault').value__c;
            List<Dated_Exchange_Rate__c> currentDateRange =[SELECT ConversionRate__c, CurrencyIsoCode, NextStartDate__c, StartDate__c, LastModifiedById, LastModifiedDate, SystemModStamp FROM Dated_Exchange_Rate__c WHERE (StartDate__c >=LAST_MONTH or NextStartDate__c=:Date.valueOf(futureDate))];

            for (OEM_Opportunity__c OEMOpp : listOfOEMOpportunities)
            {                   
                for(Dated_Exchange_Rate__c dcr:currentDateRange)
                {
                    if(dcr.CurrencyIsoCode==OEMOpp.CurrencyIsoCode && dcr.StartDate__c <= OEMOpp.Close_Date__c && dcr.NextStartDate__c > OEMOpp.Close_Date__c)
                    {
                        if (OEMOpp.Amount__c != null) {
                            OEMOpp.Amount_in_USD__c = OEMOpp.Amount__c / dcr.ConversionRate__c;
                        }
                        break;
                    }
                }                                 
            }
        }else{
            List<DatedConversionRate> currentDateRange =[SELECT ConversionRate, IsoCode, NextStartDate, StartDate, LastModifiedById, LastModifiedDate, SystemModStamp FROM DatedConversionRate WHERE (StartDate >=LAST_MONTH or NextStartDate=9999-12-31)];

            for (OEM_Opportunity__c OEMOpp : listOfOEMOpportunities)
            {                   
                for(DatedConversionRate dcr:currentDateRange)
                {
                    if(dcr.IsoCode==OEMOpp.CurrencyIsoCode && dcr.StartDate <= OEMOpp.Close_Date__c && dcr.NextStartDate > OEMOpp.Close_Date__c)
                    {
                        if (OEMOpp.Amount__c != null) {
                            OEMOpp.Amount_in_USD__c = OEMOpp.Amount__c / dcr.ConversionRate;
                        }
                        break;
                    }
                }                                 
            }
        }   

        Database.SaveResult[] resultsOfOpenOEMOppUpdate = Database.update(listOfOEMOpportunities, false);
        Integer count=0;
        String lineItemURL;
        String opportunityURL;
        String baseUrl;
        for (Database.SaveResult sr : resultsOfOpenOEMOppUpdate) 
        {
            System.Debug('Checkpoint X: in saveresults for loop');
            if (!sr.isSuccess()) 
            {
                errorFlag = true; 
                
                for(Database.Error err : sr.getErrors()) 
                {      
                    //links for Opportunity and Opportunity Line Item
                    baseUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/';
                    opportunityURL = '<a href="'+ baseUrl+ listOfOEMOpportunities[count].ID +'">' + listOfOEMOpportunities[count].Name + '</a>';           
                    errorString.add('<tr>' + '<td>'+ listOfOEMOpportunities[count].ID +'</td>'+'<td>'+ opportunityURL +'</td>'+'<td>'+ err.getMessage() +'</td>' + '<td>' + err.getFields() +'</td>' + '</tr>');
                    failedUpdates = failedUpdates + 1;
                }
                
            }      
             count = count +1;   
        }
    }
   
    global void finish(Database.BatchableContext BC)
    {
        AsyncApexJob a = [SELECT Id,Status,NumberOfErrors,JobItemsProcessed,TotalJobItems,ApexClass.name,
                             CompletedDate,ExtendedStatus,CreatedBy.Email,CreatedBy.Name
                          FROM AsyncApexJob 
                          WHERE Id =:BC.getJobId()];
        if(a.Status == 'Failed' || a.Status == 'Aborted')
        {
            List<Cron_Batch_Run__c> listOfCronRuns = [select id, CreatedDate, SystemModstamp, Result__c from Cron_Batch_Run__c  where Batch_Job_Type__C = 'Dollar Value Convert' and Result__c!=null order by CreatedDate DESC];
            if(listOfCronRuns.size()>0)
            {
                listOfCronRuns[0].Result__c = 'Error';
                listOfCronRuns[0].Results__c = 'OEM Currency to USD Conversion Failed. '+ a.ExtendedStatus;
                update listOfCronRuns[0];
            }
        }

         String emailMessage = 'Your batch job OEMCurrencytoUsdConversionBatchClass has finished.  It executed ' + a.totalJobItems + ' batches.  Of which, '+ a.jobitemsprocessed + ' processed without any exceptions'+ 'thrown and '+ a.numberOfErrors + ' batches threw unhandled exceptions.'
        + '  Of the batches that executed without error, ' + failedUpdates + ' records were not updated successfully.';
       
        //Sonali Tandon-CR 2863623 - Oppty USD Dollar Conversion: Detailed Exception Email-formatted exception mail as a table
        String tableBegin = '<table border="1" style="border-collapse:collapse;"cellpadding="10" cellspacing ="5"><tr><th>OEM Opportunity ID</th><th>OEM Opportunity Name</th><th>Error</th><th>Error Field</th></tr>';
        
        emailMessage = emailMessage + '<br/>' +  '<br/>' +  '<br/>' +tableBegin;
        
         if(errorFlag)
         {
             for( String str : errorString)
             {
                 emailMessage = emailMessage +  str;
             }
             emailMessage = emailMessage + '</table>';
         }
         
         Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
         //Sonali Tandon-CR 2863623 - Oppty USD Dollar Conversion: Detailed Exception- Added custom setting which holds email addresses to which exception mail needs to be sent.
         String emailAddresses = GSM_Custom_Settings__c.getInstance('CronCurrToUsdBatch#ErrorMailId').value__c;
         System.debug('custom'+emailAddresses);
         String[] toAddresses = emailAddresses.split(',');
         System.debug('toaddresses'+toAddresses);
         mail.setToAddresses(toAddresses);
         mail.setReplyTo('noreply@salesforce.com');
         mail.setSenderDisplayName('Batch Job Summary');
         mail.setSubject('OEM Batch job completed');
         mail.setPlainTextBody(emailMessage);
         mail.setHtmlBody(emailMessage);
         Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}