public class AccountCollectorNotificationAsync implements Queueable 
{
    public Id collectorId;
    public List<Id> collectorIds;
    private final String batchJobType = 'Account Collector Outstanding Invoices Notification';

    public AccountCollectorNotificationAsync()
    {
        this.collectorIds = new List<Id>();
        for(AggregateResult collectors : [select Original_Contract_Id__r.Account_Name__r.Collector__c from Invoice__c where Age_Days__c>:GSMSettings.getInt('OutstandingInvoicesSinceNDays')  and Outstanding_Amount__c>:GSMSettings.getInt('MinimumOutstandingAmountAllowed') and Original_Contract_Id__r.Account_Name__r.Collector__c!=null group by Original_Contract_Id__r.Account_Name__r.Collector__c])
        {
            System.Debug(LoggingLevel.Error, 'AGH_D first run collector:'+collectors);
            this.collectorIds.add((Id)collectors.get('Collector__c'));
        }

        if(this.collectorIds.size()>0)
            this.collectorId = collectorIds.remove(collectorIds.size()-1);

    }


    public AccountCollectorNotificationAsync(List<Id> collectorIdsParam)
    {
        this.collectorIds = collectorIdsParam;
        if(this.collectorIds.size()>0)
            this.collectorId = collectorIds.remove(collectorIds.size()-1);
    }

    
    public void execute(QueueableContext context)
    {
        Set<id> collectionCasesWithUpdatesInLastNDays = new Set<Id>();


        //get cases which were updated in last 7 days
        Date nthDay = Date.today().addDays(-GSMSettings.getInt('CollectionCaseSinceNDays'));
        for(AggregateResult collectorCase : [select Collection_Account__c from Case where Collection_Account__r.Collector__c=:this.collectorId and AKAM_Modified_Date__c>=:nthDay and RecordType.Name='Collections' and Status!='Closed' group by collection_Account__c])
        {
            System.Debug(LoggingLevel.Error, 'AGH_D updated cases:'+collectorCase);
            collectionCasesWithUpdatesInLastNDays.add((Id)collectorCase.get('Collection_Account__c'));
        }

        //SFDC-1718
        EmailNotificationConfig enc = new EmailNotificationConfig(batchJobType);
        String csvFields = enc.getCSVFields();
        Integer outstandingNDays = GSMSettings.getInt('OutstandingInvoicesSinceNDays');
        Integer minimumNDays = GSMSettings.getInt('MinimumOutstandingAmountAllowed');


        // get accounts without such cases and with outstanding invoices
        String invoiceQuery = 'Select ' + csvFields + ' from Invoice__c where Age_Days__c > :outstandingNDays and Outstanding_Amount__c > :minimumNDays and Account_Name__r.Collector__c=:collectorId and Account_Name__c NOT in :collectionCasesWithUpdatesInLastNDays';
        System.debug('Invoice Query: '+invoiceQuery);
        List<Invoice__c> outstandingInvoices = Database.query(invoiceQuery);
        System.debug('Outstanding Invoices :'+outstandingInvoices);

        // get accounts without such cases and with outstanding invoices
        //List<Invoice__c> outstandingInvoices = [select Account_Name__r.Name, Account_Name__c, Invoice_Date__c, Due_Date__c, Age_Days__c, Original_Contract_Id__r.Name, Original_Amount__c, Outstanding_Amount__c,Name from Invoice__c where Age_Days__c>:GSMSettings.getInt('OutstandingInvoicesSinceNDays') and Outstanding_Amount__c>:GSMSettings.getInt('MinimumOutstandingAmountAllowed') and Account_Name__r.Collector__c=:collectorId and Account_Name__c NOT in :collectionCasesWithUpdatesInLastNDays ];
        //End of SFDC-1718

            
        String cronRunResult = '\nThere are no outstanding invoices in need of attention for :'+collectorId;

        if(outstandingInvoices.size()>0)
        {
            String collectorEmailAddress;
            String mentorEmailAddress;
            // assume 1:1 mapping
            for(User collecterUser : [select Email, (select Mentor__r.Email from Collector_To_Mentor_Mappings__r) from User where id=:collectorId limit 1])
            {
                collectorEmailAddress = collecterUser.Email;
                for(Collector_To_Mentor_Mapping__c cmm : collecterUser.Collector_To_Mentor_Mappings__r)
                {
                    mentorEmailAddress = cmm.Mentor__r.Email;
                }
            }

            if(mentorEmailAddress!=null)
            {
                EmailNotificationConfig emailNotificationConf = new EmailNotificationConfig(batchJobType);

                EmailWithCSVAttachment em = new EmailWithCSVAttachment()
                    .withEmailTemplate(emailNotificationConf.getTemplate())
                    .withCSVHeader(emailNotificationConf.getCSVHeader())
                    .withCSVFields(emailNotificationConf.getCSVFields())
                    .withCSVRecords(outstandingInvoices)
                    .withToAddress(collectorEmailAddress)
                    .withCCAddress(mentorEmailAddress)
                    .withFromAddress('CRM Admins');

                cronRunResult = em.send();
            }
            else
            {
                cronRunResult = '\n No Mentor found for Collector: '+collectorEmailAddress;
            }
        }
        //update cron run
        for(Cron_Batch_Run__c cronRun :[select id, CreatedDate, Results__c, Result__c from Cron_Batch_Run__c  where Batch_Job_Type__c = :batchJobType and Result__c!=null order by CreatedDate DESC limit 1])
        {
            cronRun.Results__c = String.isBlank(cronRun.Results__c) ? cronRunResult : (cronRun.Results__c + cronRunResult);
            update cronRun;
        }

        if(collectorIds.size()>0)
        {
            System.enqueueJob(new AccountCollectorNotificationAsync(collectorIds));
        }
    }
}