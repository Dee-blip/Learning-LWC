global class BatchCronCurrencyToUsdConversionClass {

// Sonali Tandon - CR 3234771 - Merging CronCurrencyToUSDConversion and this class. 
//implements Database.Batchable<sObject>, Database.Stateful
/**{
 
     global Integer failedUpdates;
     global List<String> errorString ;
     global Boolean errorFlag {get;set;}
     public static Boolean nowRunningDataFix =false;
     public static Boolean DataFix;
     
     global BatchCronCurrencyToUsdConversionClass()
     {
         failedUpdates = 0;
         errorFlag = false;
         nowRunningDataFix = false;
         errorString = new List<String>();
         
     }
    
     global Database.QueryLocator start(Database.BatchableContext BC)
     {
          return Database.getQueryLocator([select Id,Name, CloseDate,CurrencyIsoCode,EMR_Impac_USD__c,Opportunity_Revenue_Impact__c,AKAM_Opportunity_ID__c from Opportunity where CloseDate >= LAST_MONTH]);
        
     }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        nowRunningDataFix = true; 
        System.Debug('checkpoint X: in execute' + scope);
        List<Opportunity> listOfOpenOpportunities = (List<Opportunity>)scope;
        List<Id> listOfOppIds = new List<Id>();
       
       //Toggle functionality for the OTB Exchange Rate movement.
       if(Features_Toggle__c.getInstance('SFExchangeRateToggle').toggle__c){
           String futureDate=GSM_Custom_Settings__c.getInstance('CronCurrency#FutureDateDefault').value__c;
           List<Dated_Exchange_Rate__c> currentDateRange = new List<Dated_Exchange_Rate__c>();
           currentDateRange =[SELECT ConversionRate__c, CurrencyIsoCode, NextStartDate__c, StartDate__c, LastModifiedById,LastModifiedDate, SystemModStamp FROM Dated_Exchange_Rate__c WHERE (StartDate__c >=LAST_MONTH or NextStartDate__c=:Date.valueOf(futureDate))];
           
             for(Opportunity currentOpp: listOfOpenOpportunities){
                 for(Dated_Exchange_Rate__c dcr:currentDateRange)
                 {
                    if(dcr.CurrencyIsoCode==currentOpp.CurrencyIsoCode && dcr.StartDate__c<=currentOpp.CloseDate && dcr.NextStartDate__c>currentOpp.CloseDate){
                      if(currentOpp.Opportunity_Revenue_Impact__c != null) {
                        currentOpp.EMR_Impac_USD__c= CurrentOpp.Opportunity_Revenue_Impact__c/dcr.ConversionRate__c;
                        currentOpp.Validation_Override__c=true;
                        break;
                        }
                    }
                 }
              }
         }else{
             List<DatedConversionRate> currentDateRange = new List<DatedConversionRate>();
             currentDateRange =[SELECT ConversionRate, IsoCode, NextStartDate, StartDate, LastModifiedById,LastModifiedDate, SystemModStamp FROM DatedConversionRate WHERE (StartDate >=LAST_MONTH or NextStartDate=9999-12-31)];
           
             for(Opportunity currentOpp: listOfOpenOpportunities){
                 for(DatedConversionRate dcr:currentDateRange)
                 {
                    if(dcr.IsoCode==currentOpp.CurrencyIsoCode && dcr.StartDate<=currentOpp.CloseDate && dcr.NextStartDate>currentOpp.CloseDate){
                      if(currentOpp.Opportunity_Revenue_Impact__c != null) {
                        currentOpp.EMR_Impac_USD__c= CurrentOpp.Opportunity_Revenue_Impact__c/dcr.ConversionRate;
                        currentOpp.Validation_Override__c=true;
                        break;
                        }
                    }
                 }
              }

         }     

        Database.SaveResult[] resultsOfUpdate = Database.update(listOfOpenOpportunities, false);
        Integer count=0;
        String lineItemURL;
        String opportunityURL;
        String baseUrl;
        integer errorCount=0;
        for (Database.SaveResult sr : resultsOfUpdate) 
        {
            System.Debug('Checkpoint X: in saveresults for loop');
            
            if(errorCount>0)
                    break;
            if (!sr.isSuccess()) 
            {
                errorFlag = true;
                for(Database.Error err : sr.getErrors()) 
                {      
                    //links for Opportunity
                    baseUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/';
                    opportunityURL = '<a href="'+ baseUrl+ listOfOpenOpportunities[count].Id +'">' + listOfOpenOpportunities[count].Name + '</a>';           
                   // lineItemURL = '<a href="'+ baseUrl+ listOfOpportunityLineItemsAssociatedWithOpenOpportunities[count].Id +'">' + listOfOpportunityLineItemsAssociatedWithOpenOpportunities[count].Product_Name__c + '</a>';           
                    //Added to avoid heap issue
                    if(Limits.getHeapSize() < (Limits.getLimitHeapSize()-5000000)){
                     errorString.add('<tr>' + '<td>'+ listOfOpenOpportunities[count].AKAM_Opportunity_ID__c +'</td>'+'<td>'+ opportunityURL +'</td>'+ '<td>' + err.getMessage() +'</td>' + '<td>' + err.getFields() +'</td>' + '</tr>');
                    failedUpdates = failedUpdates + 1;
                    }
                    else
                    {
                     errorString.add('<tr>' + '<td>'+'There are more items but could not add because of heap size limit.'+'</td>'+'</tr>');
                    }
                }
                errorCount=errorCount+1;
                 //Sonali Tandon-CR 2863623 - Oppty USD Dollar Conversion: Detailed Exception Email
            }      
             count = count +1;   
        }
    }
   
    global void finish(Database.BatchableContext BC)
    {
        if(errorFlag)
        {
            List<Cron_Batch_Run__c> listOfCronRuns = [select id, CreatedDate, SystemModstamp, Result__c from Cron_Batch_Run__c  where Batch_Job_Type__C = 'Dollar Value Convert Oppty' and Result__c!=null order by CreatedDate DESC];
            if(listOfCronRuns.size()>0)
            {
                listOfCronRuns[0].Result__c = 'Error';
                update listOfCronRuns[0];
            }
         }
         
         AsyncApexJob a = [SELECT id, ApexClassId, JobItemsProcessed, TotalJobItems, NumberOfErrors, CreatedBy.Email FROM AsyncApexJob WHERE id = :BC.getJobId()];
        
         String emailMessage = 'Your batch job BatchCronCurrencyToUsdConversionClass has finished.  It executed ' + a.totalJobItems + ' batches.  Of which, '+ a.jobitemsprocessed + ' processed without any exceptions'+ 'thrown and '+ a.numberOfErrors + ' batches threw unhandled exceptions.'
        + '  Of the batches that executed without error, ' + failedUpdates + ' records were not updated successfully.';
       
        
        String tableBegin = '<table border="1" style="border-collapse:collapse;"cellpadding="10" cellspacing ="5"><tr><th>Opportunity AKAM ID</th><th>Opportunity Name</th><th>Product Name</th><th>Error</th><th>Error Field</th></tr>';
        
        emailMessage = emailMessage + '<br/>' +tableBegin;
        
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
         mail.setSubject('Batch job completed');
         mail.setPlainTextBody(emailMessage);
         mail.setHtmlBody(emailMessage);
         Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }**/
 }