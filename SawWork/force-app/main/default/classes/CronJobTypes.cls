/***
    CronJobTypes
    @author : Lisha Murthy <limurthy@akamai.com>
    @Description : This class implements the Cron Job functionality.

    @History
    --Developer        --Date           --Change
    Ali KM             26/Sep/2012      CR 1912573 - Bug - Internal - Cron Job Scheduled To Run datetime changes for each run.
                                        -> Changed th logic for picking the next Batch Run date.
                                        -> As part of this CR added following components as well:
                                            - New Field - Parent_Scheduled_To_Run__c Formula DateTime field.
                                            - Validation Rule - Cron Batch Job - Ensure Scheduled To Run is Required
                                            - Validation Rule - Cron Batch Run - Ensure Scheduled To Run is Required
                                            - Page Layout - Cron Batch Job - Scheduled to Run is now Required
                                            - Page Layout - Cron Batch Run - Scheduled to Run is now Required
    Ali KM            01/Oct/2012       CR 1900927 - License Alert
                                            - enforcing FirstRunFlag in NAP alert job.
    Ali KM            06/Nov/2012       CR 1895176 - Systems Allows Oppty to be moved to SS-6 even after the expiration of Valid Until Date
                                            - adding a new cron job type.
    Ali KM            07/11/2012        CR 1895176 - Systems Allows Oppty to be moved to SS-6 even after the expiration of Valid Until Date
                                            - adding a new cron job type -  E-Sign alert for expired Order Forms
    Poojashri        18/03/2014         CR 2384895 -  Batch Job for Credit Check Validation.
    Himanshu          25/04/2014        CR 2556174 - Added 2 new Jobs for Autogen COB and TCR_WAF UseCase(Service Cloud)
    Sonia             07/29/2014        CR 2621316 - Send weekly email to Project and Time card owners  w/no contract line item on the project
    Hemant            24/06/2014        CR 2604459 - Problem Mgmt - Updated Priority & SLA matrix
    Rahul Gaira       30/07/2014        CR  2697069  Added the batch Batch_reciteContractshare
    Rahul Gaira       22/09/2014        CR  2762976   Added The cron Job for the auto flip of Status to closeAdmin and PAE notification after 14 days
    Rahul Gaira       22/02/2015        Added The cron Job Dollar value Convert Oppty
    Shivam Verma      07/09/2015        CR 3176771 -- Added logic for Address Doctor Validation Job
    Vandhana          12/02/2015        CR 3224261 - Batch job to delete records from Billing Queue every month
    Jaya              01/04/2016        CR 3172591 - Batch job to send out daily negative hour notifications.
    Sharath           04/04/2016        Batch job to de-provision PSA License when the user's profile changes from PSA to non-PSA
    Sharath           29/12/2016        Batch job to Change the timecard approvers - CR 3593271
    Aditya            28/04/2017        Batch job to scrub IP4 and IP6 Addrresses for Technical cases - JIRA ESESP-486
    Aditya            22/05/2017        Batch job for Autogen PIVC cases - JIRA ESESP-584
    Vamsee            29/01/2018        Removed Batch jor for Autogen PIVC cases - JIRA ESESP-613
    Vandhana          29/01/2018        Batch job for Autogen Order Form Review AMG cases - JIRA ESESP-646
    Aditya            16/04/2018        Batch job for NQLB- JIRA ESESP-1030
    Sharath           18/04/2018        Batch job for Auto-creation of tasks - FFPSA-496
    Suhas             21/05/2018        Batch job for FFPSA-490 Alerting to project owner when BED extended
    Aditya            23-05-2018        Batch Job for ESESP-1343-Community AddUserToGroup Batch
    Sujay             28/03/2019        Batch job for IP scrubbing for Case Notes - FFPSA-988
    Nagdeep           22/07/2019        Batch job for Contact clean up job for Annuitas - SFDC-5288
    Nagdeep           16/10/2019        Batch job for Laen data to find suitable Account
    Sharath           05/11/2019        Batch job for Approved Hours and Overages
    Sharath           14/08/2020        ESESP-3536: Batch job for Case Issue sync. This runs daily
    Sandeep           18/08/2020        Batch job for PSA Auto Renewal of Projects - FFPSA-636
	Kushal	          17/11/2020		batch job for PSA_mPulseCustomerReviewCasesBatch - FFPSA-1075
	Vikas	          15/01/2021		batch job for GSS_Autogen - ESESP-4175
    Sujay             23/05/2020        FFPSA-1811 : Batch job for calculation Actuals on incorrect on projects.
    Sujay             25/10/2121        FFPSA-1906 : Batch class to Auto create Time-Off projects every year
    Vandhana          28/04/2022        ESESP-6457 : SC IP Scrubbing
*/

global class CronJobTypes
{
    public static Boolean sendCronErrorEmailFirstRunFlag=true;
    public static Boolean cronJobFirstRunFlag=true;
    public static Boolean creditCheckFirstRunFlag = true;
    public static String jobType(Cron_Batch_Run__c pBatchrun)
    {
        String res = '0:No Job to Run.';
        String jobType = pBatchrun.Batch_Job_Type__c;

        if (jobType.equals('Account Collector Outstanding Invoices Notification'))
        {
            res = '1:Started the job'+ '\n \n';
            System.enqueueJob(new AccountCollectorNotificationAsync());
        }
        /*else if (jobType == 'Job to track governor limits at sObject and platform level in salesforce')
        {
            res = TrackGovLimits.TrackGovLimits();
        }*/
        else if (jobType == 'Clean Up')
        {
            res = CronCleanUp.cleanUp(Integer.valueOf(pBatchrun.Clean_After__c));
        }
        else if (jobType == 'Inactive Campaign Clean Up')
        {
            res = InactivateOldCampaigns.InactivateOldCampaigns();
        }
        else if (jobType.equals('CreateSobjectBackupAuditRecordJob-CreateAuditRecord') || jobType.equals('CreateSobjectBackupAuditRecordJob-SendEmailNotifications'))
        {
            res = SObjectAuditClass.invokeSObjectAuditBackupRecordJob(jobType);
        }
        else if (jobType.equals('Active Account Reassignment'))
        {
            //res = AccountReassignmentInterfaceClass.Reassign_ApprovedReassignments();
            Integer batchSize = Integer.valueOf(GSMSettings.getValue('AccountReassignmentBatchClass_BatchSize'));
            res = '1: Job started. Results will be updated here after the job completes';
            AccountReassignmentBatchClass batchObj = new AccountReassignmentBatchClass();
            Database.executebatch(batchObj,batchSize);
        }
        else if('Partner Marketing Activity Roll-Ups'.equals(jobType))
        {
            PartnerMarketingActivityBatchClass pmaClass = new PartnerMarketingActivityBatchClass();
            Database.executeBatch(pmaClass);
            res='1: Completed';
        }
        else if (jobType.equals('SendDocuSignInitiatorReminderEmail'))
        {
            res = DocuSignStatusTriggerClass.invokeDocuSignInitiatorReminderJob(jobType);
        }
        else if (jobType.equals('PRM DealAndMDF Notification'))
        {
            res = PRMScheduledJobs.SendDealRegEmailReminder();
        }
        else if (jobType.equals('PRM Add Admin to sales team'))
        {
            res = PRMScheduledJobs.AddPartnerAdminToSalesTeam();
        }
        else if (jobType.equals('Product Approvals TSP Reminder'))
        {
            res = ProductApprovalHandler.invokeTSPReminderEmail();
        }
        else if (jobType.equals('GetRSSFeed'))
        {
            res=(new RSS2Chatter_ScheduleGetRSS()).getRssFeeds();
        }
        else if(jobType.equals('Launch Approval Notification Reminder'))
        {
            res=(new PLM_LaunchItemApprovalGeneric()).sendNotificationReminders();
        }
        else if(jobType.equals('Fix Oppty-Product Forecast MRR'))
        {
            if (GsmUtilClass.isFeatureToggleEnabledCustomMetadata('isOOTBForecastingEnabled')) //SFDC-2391
                res= OpportunityLineItemTriggerClass.fixOpptyProducts();
            else
                res='0:' + GsmUtilClass.featureToggleMsg('isOOTBForecastingEnabled'); //SFDC-2391
        }
        //SFDC-5894
        // else if(jobType.equals('Unfollow Chatter'))  //Changes for CR 1690393 Chatter: Research whether we can use Chatter unfollow
        // {
        //     res = unfollowExecute.unfollowBatch_Cron();
        // }
        else if(jobType.equals('CriticalNAPLicenseAlert'))
        {
            if (!cronJobFirstRunFlag)
                    return '';
            res = PRMScheduledJobs.sendNotficationMailForNAPLicense();
            cronJobFirstRunFlag=false;
        }
        else if(jobType.equals('Auto-follow renewal Opportunities'))
            res = OpportunityScheduledJobsClass.createChatterForRenewalOppty();
        //else if(jobType.equals('Notification for Renewal Opportunities'))
            //res = OpportunityScheduledJobsClass.sendEmailForRenewalOppty();
        else if(jobType.equals('Close Old Opportunities'))
        {
            res = '1:In Progress, results will be updated once Batch process is completed.';
            if (!cronJobFirstRunFlag)
                return res;
            CloseOldOpportunityBatchable executeCloseAllOppty = new CloseOldOpportunityBatchable(pBatchrun);
            Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('SchOpptyClose', 'BatchSize'));
            pBatchrun.BatchProcessId__c=Database.executeBatch(executeCloseAllOppty,batchSize);
            GSM_Custom_Settings__c closeOpptySetting = new GSM_Custom_Settings__c();
            closeOpptySetting.Name = 'SchOpptyClose#lastBatchProcessId';
            closeOpptySetting.Value__c=pBatchrun.BatchProcessId__c;
            upsert closeOpptySetting Name;
            cronJobFirstRunFlag=false;
        }
        // SFDC-5894
        // else if(jobType.equals('Address Doctor Validation Job'))
        // {
        //     res = '1:In Progress, results will be updated once Batch process is completed.';
        //     if (!cronJobFirstRunFlag)
        //         return res;
        //     Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('AddressDoctor', 'BatchSize'));
        //     AddressDoctorValidationJob addressDoctorValidation = new AddressDoctorValidationJob(pBatchrun);
        //     pBatchrun.BatchProcessId__c = Database.executebatch(addressDoctorValidation,batchSize);
        //     GSM_Custom_Settings__c closeOpptySetting = new GSM_Custom_Settings__c();
        //     closeOpptySetting.Name = 'AddressDoctor#lastBatchProcessId';
        //     closeOpptySetting.Value__c=pBatchrun.BatchProcessId__c;
        //     upsert closeOpptySetting Name;
        //     cronJobFirstRunFlag=false;
        // }
        else if(jobType.equals('E-Sign alert for expired Order Forms'))
        {
            res = DocuSignStatusTriggerClass.invokePendingESignWithExpiredOrderFormEmailAlert();
        }
        //SFDC-3280
        else if(jobType.equals('Approval History Mailing Batch Job'))
        {
            Integer SendEmailBatchLimit = GSMSettings.getInt('SendEmailBatchLimit');
            SendEMailBatchJob smbj = new SendEMailBatchJob();
            Database.executeBatch(smbj,SendEmailBatchLimit);
            res='1: Completed';
        }

        //SFDC-3447
        else if(jobType.equals('Channel Mapping Cron Job'))
        {
            ChannelMappingCronJob cmrj = new ChannelMappingCronJob();
            Integer size = cmrj.executeCronJob();
            string results = 'Email sent for '+size + ' records';
            res='1: '+results;
        }

        //SFDC-3713
        else if(jobType.equals('Revenue Alignment Update Contract To Account'))
        {
            RevenueAlignmentUpdateContractToAccount rauca = new RevenueAlignmentUpdateContractToAccount();
            Database.executeBatch(rauca);
            res='1: Completed';
        }

         //SFDC-1632
        else if(jobtype.equals('Soasta Accounts With Pool User Email'))
        {
            ID jobID = System.enqueueJob(new SendEmail_Soasta_DPM());
            res = '1:In Progress, results will be updated once Batch process is completed.';
            //jobIds.add(jobID);

        }
        //SFDC-2133
        //SFDC-7073 - Deleted NAP Reporting For Partners batch job code as its no longer required with lightning report access self-serve


        //SFDC-2201
    //SFDC-2421
    //SFORCE-79 Commented unused Code - @future method used inside loop
    /*
    else if(jobType.contains('Order Approval Report Batch')){
        system.debug(LoggingLevel.ERROR,'jobType Order Approval Report Batch:: '+jobType);
        String day = DateTime.now().format('EEEE');
        System.debug('Mayank, day is : ' + day);
        if(day != 'Saturday'){
            //SFDC-2315
            GSM_Settings__mdt mdtRecord = [select Id, Value__c,label from GSM_Settings__mdt where DeveloperName = :'SA_Tasks_Report_2_Id'];
            String reportId = mdtRecord.value__c;
            String reportName = mdtRecord.label;
            Map<String,String> mdtRecordMap = new Map<String,String>();
            String subStr = jobtype.substringAfterLast('-').trim();
            system.debug(LoggingLevel.ERROR,'subStr in Order Approval Report Batch:: '+subStr);
            mdtRecordMap = GSMUtilClass.getGSMSettingValuePartialMatchMap('SA_Task_Report_Distribution_List');
            //ReportGenerator reportGen = new ReportGenerator();
            for(String rec: mdtRecordMap.keySet()){
                system.debug(LoggingLevel.ERROR,'rec in Order Approval Report Batch:: '+rec);
                if(rec.contains(subStr)){
                    system.debug(LoggingLevel.ERROR,'2nd DL: '+mdtRecordMap.get(rec));
                    ReportGenerator.generateReport(reportId,reportName,mdtRecordMap.get(rec));
                }
                //else
                //    ReportGenerator.generateReport(reportId,reportName,mdtRecordMap.get(rec).value__c);
            }
            //ascr.fetchrecords();
            res='1: Completed';
        }
    }
    */
        //SFDC-1483
        else if(jobtype.equals('Purchase Order Account Collector Email'))
        {
            res = '1:In Progress, results will be updated once Batch process is completed.';
            if (!cronJobFirstRunFlag)
                return res;
            ID jobID = System.enqueueJob(new SendEmail_PurchaseOrder_AccountCollector());
            cronJobFirstRunFlag = false;
        }
        //SFDC- 1641
        else if(jobType.equals('Campaign Cleanup Lead Opportunity'))
        {
            Integer campaignCleanupBatchSize = Integer.valueOf(GSMSettings.getValue('CampaignCleanupBatchSize'));

            CampaignCleanup_LeadToOpptyBatchClass ccBatch = new CampaignCleanup_LeadToOpptyBatchClass();
            Database.executebatch(ccBatch,campaignCleanupBatchSize);
            res='1:Completed';
        }
        else if(jobType.equalsIgnoreCase('Lead Auto-Conversion To Opportunity'))
        {
            Integer leadConversionBatchSize = GSMSettings.getInt('LeadAutoConversionBatchSize');
            LeadAutoConversionBatchClass lacbc = new LeadAutoConversionBatchClass();
            Database.executebatch(lacbc, leadConversionBatchSize);
            res='1:Job Started';
        }
        else if(jobType.equals('Cast Iron Monitoring'))
        {
            res=CastIronClass.checkCastIronPolling();
        }

        // Commented as part of SFDC-2728
        //Re commiting the change
      /* else if(jobType.equals('Manual List Trigger'))
        {
            res=MergeContractManualListClass.CronJobHandler();
        }*/
        else if(jobType.equals('Partner Oversharing'))
        {
            res=OpportunityTriggerClass.checkOverSharingForPartners();
        }
        else if(jobType.equals('Product Approval Escalations'))
        {
            res=PA_EscalationClass.CronJobHandler();
        }
        else if(jobType.equals('NAP News Subscription Daily'))
        {
            NAPNewsSubscriptionBatchClass obj = new NAPNewsSubscriptionBatchClass('Daily');
            database.executeBatch(obj);
            res='1:Completed';
        }
        else if(jobType.equals('NAP news Subscription Weekly'))
        {
            NAPNewsSubscriptionBatchClass obj = new NAPNewsSubscriptionBatchClass('Weekly');
            database.executeBatch(obj);
            res='1:Completed';
        }
        else if(jobtype.equals('Dollar Value Convert'))
        {
            Integer dvcBatchSize = Integer.valueOf(GSMSettings.getValue('DollarValueConvert_BatchSize'));
            CronCurrencytoUsdConversionBatchClass newCurrencyConversion = new CronCurrencytoUsdConversionBatchClass();
            Database.executebatch(newCurrencyConversion,dvcBatchSize);
            res='1:Opportunity Completed';

            //SFORCE-146 OEM functionality is not in use.
           /* OEMCurrencytoUsdConversionBatchClass newOEMCurrencyConversion = new OEMCurrencytoUsdConversionBatchClass();
            Database.executebatch(newOEMCurrencyConversion);
            res='1:OEM Opportunity Completed';*/
        }
        else if(jobType.equals('Account Engagement Level'))
        {
            Integer batchSize = Integer.valueOf(GsmUtilClass.getGSMSettingValue('CronAccEngagementLevel_batchSize')); //SFDC-2391
            CronAccountEngagementLevelBatchClass obj = new CronAccountEngagementLevelBatchClass();
            database.executeBatch(obj, batchSize);
            res='1:Completed';
        }
        else if(jobType.equals('Update Restricted Country on Accounts'))
        {
            SalesApprovedCountryBatchClass sacbc= new SalesApprovedCountryBatchClass();
            Database.executebatch(sacbc);
            res='1:Completed';
        }

        // Sonali Tandon  SFDC-1094 : NAP User -- Fix the NAP Last Login
        else if(jobType.equals('Update Last NAP Login on Contacts'))
        {
            Integer batchSize = Integer.valueOf(GSMSettings.getValue('LastNAPLoginBatchClass_BatchSize'));
            LastNAPLoginBatchClass batchInstance= new LastNAPLoginBatchClass();
            Database.executebatch(batchInstance,batchSize);
            res='1:Completed';
        }
        else if(jobType.equals('Current Sales Channel Insert and Update'))
        {
            Integer cscBatchSize = Integer.valueOf(GSMSettings.getValue('CurrentSalesChannelBatchSize'));

            CurrentSalesChannelBatchClass csc = new CurrentSalesChannelBatchClass();
            Database.executebatch(csc,cscBatchSize);
            res='1:Completed';
        }
        else if(jobType.equals('Current Sales Channel Delete'))
        {
            Integer cscBatchDeleteSize = Integer.valueOf(GSMSettings.getValue('CurrentSalesChannelBatchSize'));

            CurrentSalesChannelDeletionBatchClass csc = new CurrentSalesChannelDeletionBatchClass();
            Database.executebatch(csc,cscBatchDeleteSize);
            res='1:Completed';
        }

        else if(jobType.equals('EOL Products Insert Update Job'))
        {
            Integer eolBatchSize = Integer.valueOf(GSMSettings.getValue('EOLProductsBatchSize'));

            EOLProductsBatchClass eolBatchJob = new EOLProductsBatchClass();
            Database.executebatch(eolBatchJob,eolBatchSize);
            res='1:Completed';
        }
        else if(jobType.equals('EOL Products Delete Job'))
        {
            Integer eolBatchSize = Integer.valueOf(GSMSettings.getValue('EOLProductsBatchSize'));

            EOLProductsDeleteBatchClass eolBatchJob = new EOLProductsDeleteBatchClass();
            Database.executebatch(eolBatchJob,eolBatchSize);
            res='1:Completed';
        }
        else if(jobType.equals('Contract Share Account Opportunity'))
        {
            Integer csBatchSize = Integer.valueOf(GSMSettings.getValue('ContractShareATMOTMBatchSize'));
            L2Q_ATMOTMContractShareBatchClass cs = new L2Q_ATMOTMContractShareBatchClass();
            Database.executebatch(cs,csBatchSize);

            res='1:Completed';
        }
        else if(jobType.equals('Revenue Alignment Waiver Unset'))
        {
            RevenueAlignmentBatchClass rabc = new RevenueAlignmentBatchClass();
            Database.executebatch(rabc);
            res='1:Completed';
        }

           else if(jobType.equals('Update Account With NAP PSOR values from Contract'))
        {
            if (!Test.isRunningTest()){
                Integer batchSize = Integer.valueOf(GsmUtilClass.getGSMSettingValue('NAPContractPSORBatchSize'));
            NAPContractPSORBatchClass batchInstance= new NAPContractPSORBatchClass();
                Database.executebatch(batchInstance,batchSize);
            res='1:Completed';
        }
        }

               else if(jobType.equals('NAP File Subscription Digest'))
        {
            NAPFileSubscriptionDigestBatchClass nap= new NAPFileSubscriptionDigestBatchClass();
            Database.executebatch(nap);
            res='1:Completed';
        }


        else if(jobType.equals('Send Mail For Opportunities Past Closed Date'))  //adding method for email escalation
        {
            res=OpportunityScheduledJobsClass.sendMailforOpptyPastDue();
        }

        // Condition for Autogen COB Job
        else if(jobtype.equals('Autogen COB Case creation Batch'))
        {
            Integer batchSize = Integer.valueOf(SC_Autogen_Running_Freq__c.getValues('COB').Batch_Size__c);
            SC_Autogen_COB_Batch AutogenCOBBatch = new SC_Autogen_COB_Batch();
            database.executebatch(AutogenCOBBatch, batchSize);
            res='1:Completed';
        }

         // Condition for Autogen COB Plus Advanced
        /*else if(jobtype.equals('Autogen Plus Advanced Case Creation'))
        {
            Integer batchSize = Integer.valueOf(SC_Autogen_Running_Freq__c.getValues('COB').Batch_Size__c);
            SC_Autogen_PLUS_ADVANCED_Batch  AutogenCOBBatch = new SC_Autogen_PLUS_ADVANCED_Batch ();
            database.executebatch(AutogenCOBBatch,batchSize);
            res='1:Completed';
        }*/

        else if(jobtype.equals('Fund Claim Deadline Reminder'))
        {
            res = '1:' + FundClaimDeadlineMailer.sendMails();
        }

        // Condition for Autogen TCR WAF Job
        else if(jobtype.equals('Autogen TCR WAF Case creation Batch'))
        {
            Integer batchSize = Integer.valueOf(SC_Autogen_Running_Freq__c.getValues('TCR_WAF').Batch_Size__c);
            SC_Autogen_TCR_WAF_Batch Autogen_TCRWAF_Batch = new SC_Autogen_TCR_WAF_Batch();
            database.executebatch(Autogen_TCRWAF_Batch, batchSize);
            res='1:Completed';
        }
        
                //Changes by sandeep for FFPSA-636 PSA Auto Renewal of Projects
        else if(jobtype.equals('PSA Auto Renew Projects Batch'))
        {
            Integer batchsize = Integer.ValueOf([Select value__c from PSA_Common_Setting__mdt where type__c = 'PSA Auto Renew Project batch Limit'].value__c);
            PSA_AutoRenewProjectsBatch autoRenewBatchObj = new PSA_AutoRenewProjectsBatch();
            database.executebatch(autoRenewBatchObj, batchsize);
            res='1: Completed';
        }
        
        else if(jobtype.equals('Update Forecasted Opportunity Count'))
        {
            Integer batchSize = Integer.valueOf(GSMSettings.getValue('UpdForecastOpptyCount_BatchSize'));
            res = '1: Job started. Results will be updated here after the job completes';
            UpdateForecastedOpportunityCountBatch batchObj = new UpdateForecastedOpportunityCountBatch();
            Database.executebatch(batchObj,batchSize);
        }
        else if(jobtype.equals('Past Oppty Close Date Notification'))
        {
            Integer batchSize = Integer.valueOf(GSMSettings.getValue('PastOpptyCloseDate_AlertBatchSize'));
            res = '1: Job started. Results will be updated here after the job completes';
            PastOpptyCloseDateNotificationBatch batchObj = new PastOpptyCloseDateNotificationBatch();
            Database.executebatch(batchObj,batchSize);
        }
        else if(jobtype.equals('Remove Account Plan Access'))
        {
            Integer batchSize = Integer.valueOf(GSMSettings.getValue('Quip_RemoveAccountPlanAccessBatchSize'));
            res = '1: Job started. Results will be updated here after the job completes';
            RemoveAccountPlanAccessBatch batchObj = new RemoveAccountPlanAccessBatch();
            Database.executebatch(batchObj,batchSize);
        }
        else if(jobtype.equals('Update Missing Account Reassign Related Records'))
        {
            Integer batchSize = Integer.valueOf(GsmUtilClass.getAccountReassignSettingValue('UpdatAccReassignRelatedRecords_BatchSize'));
            res = '1: Job started. Results will be updated here after the job completes';
            UpdateMissingAccReassignRelatedRecords batchObj = new UpdateMissingAccReassignRelatedRecords();
            Database.executebatch(batchObj,batchSize);
        }
        else if(jobtype.equals('Uncheck Pull Forward On Opportunity'))
        {
            res = '1: Job started. Results will be updated here after the job completes';
            OpportunityTriggerClass.uncheckPullForward();
        }
        else if (jobType.equals('Partner Under Sharing'))
        {
            res=OpportunityTriggerClass.checkUnderSharingForPartners();
        }
        //Start of changes by ssawhney for CR 2621316
        else if(jobtype.equals('PSA Timecard Reminder'))
        {
            PSA_SendWeeklyRemindersForTimecards sendReminder = new PSA_SendWeeklyRemindersForTimecards();
            Database.executebatch(sendReminder);
            res='1:Completed';
        }
        //End of changes for CR 2621316


       //Start Condition for Helpdesk Jobs CR 2604459 - Problem Mgmt - Updated Priority & SLA matrix
          // else if(jobType.equals('Helpdesk Jobs'))


        //Commenting duplicate code - Shiva Ganesan
        // else if(jobtype.equals('Update Forecasted Opportunity Count'))
        // {
        //     res = '0: Job started. Results will be updated here after the job completes';
        //     OpportunityScheduledJobsClass.updateForecastedOpportunityCount();
        // }
        // else if (jobType.equals('Partner Under Sharing'))
        // {
        //     res=OpportunityTriggerClass.checkUnderSharingForPartners();
        // }
        // //Start of changes by ssawhney for CR 2621316
        // else if(jobtype.equals('PSA Timecard Reminder'))
        // {
        //     PSA_SendWeeklyRemindersForTimecards sendReminder = new PSA_SendWeeklyRemindersForTimecards();
        //     Database.executebatch(sendReminder);
        //     res='1:Completed';
        // }
        //End of changes for CR 2621316
       //Start of CR 3265961
       //commented in  shivam absence--- Cr not moving in prod
      /*  else if(jobtype.equals('Fund Claim Deadline Reminder'))
        {
            FundClaimDeadlineMailer fundClaimDeadlineRemind = new FundClaimDeadlineMailer();
            Database.executebatch(fundClaimDeadlineRemind);
            res='1:Fund Claim Deadline Reminder Cron job Completed';

        }*/

        //Start of changes by janantha for CR 3172591
        else if(jobtype.equals('FFSendNegativeHourNotification'))
        {
            FFSendNegativeHourNotification sendNegativeNotification = new FFSendNegativeHourNotification();
            Database.executebatch(sendNegativeNotification);
            res='1:Completed';
        }
        //End of changes for CR 3172591

        // start of changes by Vandhana for CR 3224261
        else if(jobType.equals('PSA Delete Billing Queue Data'))
        {
            PSA_DeleteBillingQueueData deleteBillingQueueData = new PSA_DeleteBillingQueueData();
            Database.executeBatch(deleteBillingQueueData);
            res='1: Completed';
        }
        //end of changes by Vandhana

       //Start Condition for Helpdesk Jobs CR 2604459 - Problem Mgmt - Updated Priority & SLA matrix
           else if(jobType.equals('Helpdesk Jobs'))
        //Start Condition for Helpdesk Jobs CR 2604459 - Problem Mgmt - Updated Priority & SLA matrix
        {
            HD_Problem_Pending_Periodic_batchapex hd_problem_periodic_email_update = new HD_Problem_Pending_Periodic_batchapex(false);
            Database.executeBatch(hd_problem_periodic_email_update);
            res='1:Completed';
        } //End CR 2604459 - Problem Mgmt - Updated Priority & SLA matrix
        else if(jobType.equals('Recite Contract Sharing')) //Start Code:Added the batch for the Undersharing CR 2697069
        {
            Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('ReciteContract', 'BatchSize'));
            Batch_reciteContractSharing ReciteBatch = new Batch_reciteContractSharing();
            STRING ids = database.executebatch(ReciteBatch, batchSize);
            if(ids != null && ids != '') {
                AsyncApexJob aJob = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
                                    TotalJobItems
                                    FROM AsyncApexJob WHERE Id =: ids];
                if(aJob.NumberOfErrors > 0){
                    res = '0:' +'\n' + 'JobItem Processed:'+ ajob.JobItemsProcessed +'\n'+'Total No Errors:'+ ajob.NumberOfErrors +'\n' + ReciteBatch.errorMessage;
                }else{
                    res='1: Batch Completed Successfully' +'\n' + 'JobItem Processed:'+ ajob.JobItemsProcessed +'\n' +'TotalJobItems:' + ajob.TotalJobItems + '\n'+ 'Total No Errors:'+ ajob.NumberOfErrors ;
                    }
                } else{
                res='0: unexpected Error , No Id generated for Batch';
                }
        }  //End Code:Added the batch for the Undersharing CR 2697069
        else if(jobType.equals('Task Creation for Credit Check'))
        {
            res = '1:In Progress, results will be updated once Batch process is completed.';
            if (!CreditCheckFirstRunFlag)
                return res;
            Q2O_AccountCreditCheckBatchable acc  = new Q2O_AccountCreditCheckBatchable(pBatchrun);
            Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('SchOpptyClose', 'BatchSize'));
            pBatchrun.BatchProcessId__c=Database.executeBatch(acc,batchSize);
            GSM_Custom_Settings__c creditCheckSetting = new GSM_Custom_Settings__c();
            creditCheckSetting.Name = 'CreditCheck#lastBatchProcessId';
            creditCheckSetting.Value__c=pBatchrun.BatchProcessId__c;
            upsert creditCheckSetting  Name;
            CreditCheckFirstRunFlag=false;
        }
                  //Start of the Deal Reg Code 2762976
        else if(jobType.equals('CloseAdmin from Deal unsubmitted')) {
            Integer NoofDaysUnsubmitted = Integer.valueof(GsmUtilClass.getGSMSettingValue('DealRegAutoClose_NoofDaysUnsubmitted').trim());
            DealRegAutoClose deal = new DealRegAutoClose();
            res = deal.DealClose('Deal Reg Unsubmitted' ,NoofDaysUnsubmitted , false);
        }
        else if(jobType.equals('CloseAdmin from Deal submitted')) {
           Integer NoofDaysSubmitted = Integer.valueof(GsmUtilClass.getGSMSettingValue('DealRegAutoClose_NoofDaysSubmitted').trim());
           DealRegAutoClose deal = new DealRegAutoClose();
           res = deal.DealClose('Deal Reg Submitted' ,NoofDaysSubmitted, false);
        }
       else if(jobType.equals('CloseAdmin from Deal rejected')) {
          Integer NoofDaysRejected = Integer.valueof(GsmUtilClass.getGSMSettingValue('DealRegAutoClose_NoofDaysRejected').trim());
          DealRegAutoClose deal = new DealRegAutoClose();
          res = deal.DealClose('Deal Reg Rejected' ,NoofDaysRejected ,false);
       }
       else if(jobType.equals('Email Notify Deal submitted')) {
          Integer NoofDaysEmail = Integer.valueof(GsmUtilClass.getGSMSettingValue('DealRegAutoClose_NoofDaysEmail').trim());
          DealRegAutoClose deal = new DealRegAutoClose();
          res = deal.DealClose('Deal Reg Submitted' ,NoofDaysEmail ,true);
       }

            //End of the Deal Reg Code 2762976
            //Start of PSA Update GDRAT Alignment Logic
       else if(jobType.equals('PSA Update GDRAT Alignment'))
       {
         PSA_CronGDRATController ex = new PSA_CronGDRATController();
         res = ex.executeGDRATAlignment();
       }

       else if(jobType.equals('Focus Attribute')){

            Integer  batchSize = Integer.valueOf(GsmUtilClass.getGSMSettingValue('Alexa_CronBatchSize')); //SFDC-2391
            CronPopulateAccountFocusAttributeClass newObj = new CronPopulateAccountFocusAttributeClass();
            Database.executeBatch(newObj,batchSize);
            res='1:Completed';

       }
       else if(jobType.equals('PSA Daily App Notify'))
       {
           PSA_NotifyPendingApprovalsDaily NotifyDaily = new PSA_NotifyPendingApprovalsDaily();
           database.executebatch(NotifyDaily,1);
           res='1: Completed';
       }
     else if(jobType.equals('PSA Weekly App Notify'))
     {
      PSA_NotifyPendingApprovalsWeekly NotifyWeekly = new PSA_NotifyPendingApprovalsWeekly();
           database.executebatch(NotifyWeekly,1);
           res='1: Completed';
     }
     //Start of changes by Samir
     else if(jobType.equals('PSA Set Approver'))
     {
        PSA_setApproverForTimecard setApproverForTimecard = new PSA_setApproverForTimecard();
           database.executebatch(setApproverForTimecard);
           res='1: Completed';
     }
     //End of changes by Samir
     //Changes by sharath
     else if (jobType.equals('PSA LicenseDeprovisionBatch'))
     {
           PSA_LicenseDeprovisionBatch deprovision = new PSA_LicenseDeprovisionBatch();
           database.executebatch(deprovision,100);
           res='1: Completed';
     }
     //Changes by sharath
     else if (jobType.equals('PSA Timecard Approver Change'))
     {
         PSA_TimecardApproverChangeBatch changeApprover = new PSA_TimecardApproverChangeBatch();
         database.executebatch(changeApprover);
         res='1: Completed';
     }
     //Changes by Sharath for FFPSA-1277
     else if (jobType.equals('PSA Approved Hours Recalc'))
     {
         PSA_ApprovedHoursReCalcBatch updateApprovedHours = new PSA_ApprovedHoursReCalcBatch();
         database.executebatch(updateApprovedHours, Integer.valueOf([select value__c from PSA_Common_Setting__mdt where type__c = 'PSA PS Approved Hr Recalc Batch Size'].value__c));
         res='1: Completed';
     }

     //Changes by Sujay for FFPSA-1811
     else if (jobType.equals('PSA Correct Actual Hours'))
     {
         PSA_CorrectActualsOnProjects_Batch correctActuals = new PSA_CorrectActualsOnProjects_Batch();
         database.executebatch(correctActuals,2000);
         res='1: Completed';
     }

     //Changes by Sujay for FFPSA-1906
     else if (jobType.equals('PSA AutoCreateTimeOffProject'))
     {
        PSA_AutoCreateTimeOffProjectYOY runBatch = new PSA_AutoCreateTimeOffProjectYOY();
        Database.executeBatch(runBatch);
        res='1: Completed';
     }

     //Changes by Sujay for : FFPSA-988
     else if (jobType.equals('IP scrubbing for Notes'))
     {
         Integer batchsize = Integer.ValueOf([Select value__c from PSA_Common_Setting__mdt where type__c = 'IP scrubbing for Notes batch Limit'].value__c);
         SC_ScrubIPCaseNotesMuleBatch ipScrub = new SC_ScrubIPCaseNotesMuleBatch();
         database.executebatch(ipScrub, batchsize);
         res='1: Completed';
     }

     //Added by Vandhana for ESESP-6457 for IP Scrubbing batch call for Collaboration Group and Cases
     else if (jobType.equals('SC IP Scrubbing Chatter Groups'))
     {
         Integer batchsize = Integer.ValueOf([Select Value_Text__c  from SC_Utility__mdt where MasterLabel = 'IP scrubbing for CollabFeed batch Limit'].Value_Text__c);
         SC_ScrubIPAddressesForCollabFeed_Batch ipScrub = new SC_ScrubIPAddressesForCollabFeed_Batch();
         database.executebatch(ipScrub, batchsize);
         res='1: Completed';
     }
     //end of changes by Vandhana

     //Changes by Suhas for 18.6 FFPSA-490
     else if (jobType.equals('PSA BEDDaily'))
     {

        PSA_BEDCheckfor5Days bed5Days = new PSA_BEDCheckfor5Days();
        database.executebatch(bed5Days);
        res='1: Completed';
     }

     else if (jobType.equals('PSA BEDWeekly'))
     {
        PSA_BEDCheckfor30Days bed30Days = new PSA_BEDCheckfor30Days();
        database.executebatch(bed30Days);
        res='1: Completed';
     }
     //End of Changes by Suhas for 18.6 FFPSA-490
     
     //Start of changes by Suhas for FFPSA-1929
     else if(jobType.equals('PSA PCLIAssociationHistory'))
     {
        PSA_Settings__c workItemLimit;
        if (PSA_Settings__c.getInstance('ContractDetailBatch') == null)
        {
            workItemLimit = new PSA_Settings__c();
            workItemLimit.Name = 'ContractDetailBatch';
            workItemLimit.Value__c = '2021-10-08T07:59:35.000+0000';
            insert workItemLimit;
            
        }
        PSA_PCLIAssociationHistory pcliAH = new PSA_PCLIAssociationHistory();
        database.executebatch(pcliAH, Integer.valueOf([select value__c from PSA_Common_Setting__mdt where type__c = 'PSA Contract Detail Batch'].value__c));
        res='1: Completed';
     }
     //End of changes by Suhas for FFPSA-1929

     
     else if (jobType.equals('PSA AutoRenewCases'))
     {
        PSA_mPulseCustomerReviewCasesBatch autorenew = new PSA_mPulseCustomerReviewCasesBatch();
        database.executebatch(autorenew);
        res='1: Completed';
     }
     //End of Changes by Kushal for 21.1 FFPSA-1075

    // ************** Below Added by Ashin for ESESP-6983 2.b **************
     else if (jobType.equals('SC Reminder Emails'))
     {
         SC_PSReminderEmailsForSc_Batch SCreminderBatch = new SC_PSReminderEmailsForSc_Batch();
        database.executebatch(SCreminderBatch,30);
        res='1: Completed';
     }
     //************** Above Added by Ashin for ESESP-6983 2.b ***************
     
     //************ Below Added by Ashin for ESESP-6983 2.b *****************
     else if (jobType.equals('Manager Reminder Emails'))
     {
         SC_PSReminderEmailsForManager_Batch ManagerreminderBatch = new SC_PSReminderEmailsForManager_Batch();
        database.executebatch(ManagerreminderBatch,30);
        res='1: Completed';
     }
     // ************ Above Added by Ashin for ESESP-6983 2.b ******************
     
     else if (jobtype.equals('Partner Executive Shares'))
     {
        try
        {
            BatchableOpportunityShares bos = new BatchableOpportunityShares();
            Database.executeBatch(bos);
            res='1:Completed';
        }
        catch(Exception e)
        {
            res = '0:Error while creating Opportunity Shares. \n ' + e.getMessage();
        }
     }

     else if (jobtype.equals('Update Lead Campaign Member Status'))
     {
        Integer batchsize = Integer.valueOf(GsmUtilClass.getGSMSettingValue('Lead_Campaign_Member_Status_Update_Batch'));
        try
        {
            UpdateLeadStatusBatchClass uls = new UpdateLeadStatusBatchClass();
            Database.executeBatch(uls,batchsize);
            res='1:Completed';
        }
        catch(Exception e)
        {
            res = '0:Error while updating lead campaign member status. \n ' + e.getMessage();
        }
     }//SFDC-1595
    else if(jobType.equals('Update Channel Level on Opportunity'))
    {   system.debug(LoggingLevel.Error,'Update Channel Level on Opportunity job will run');
        Integer batchsize = Integer.valueOf(GsmUtilClass.getPRMSettingValue('Channel_Level_on_Opportunity_Update_Batc'));
        system.debug(LoggingLevel.Error,'batchsize:: '+batchsize);
        try
        {
        ChannelLevelKeyChangeSync batchInstance= new ChannelLevelKeyChangeSync();
        Database.executebatch(batchInstance,batchsize);
        res='1:Completed';
        }
        catch(Exception e)
        {
            system.debug(LoggingLevel.Error,'res before:: '+e.getMessage());
            res = '0:Error while updating Channel Level on Opportunity. \n ' + e.getMessage();
        }

    }//SFDC-4223
    else if(jobType.equals('Update Channel Level for Opportunity'))
    {   system.debug(LoggingLevel.Error,'Update Channel Level for Opportunity job will run');
        Integer batchsize = Integer.valueOf(GsmUtilClass.getPRMSettingValue('Channel_Level_on_Opportunity_Update_Batc'));
        system.debug(LoggingLevel.Error,'batchsize:: '+batchsize);
        try
        {
        ChannelLevelKeyChangeSyncOppty batchInstance= new ChannelLevelKeyChangeSyncOppty();
        Database.executebatch(batchInstance,batchsize);
        res='1:Completed';
        }
        catch(Exception e)
        {
            system.debug(LoggingLevel.Error,'res before:: '+e.getMessage());
            res = '0:Error while updating Channel Level for Opportunity. \n ' + e.getMessage();
        }

    }
      else if(jobType.equals('Renewal Process'))
     {
        res=RenewalOpportunityCreationClass.createRenewalOpportunityMonthlyJob();
     }
     else if(jobtype.equals('Content Version Tag Copy'))
     {
         ContentVersionTagCopyBatchClass cvbc = new ContentVersionTagCopyBatchClass();
         Database.executeBatch(cvbc);
         res='1:Completed';
     }

     //Added by Saket More

     else if(jobtype.equals('Pre Sales Value Confirmation')){
            Integer batchsize = Integer.valueOf(GsmUtilClass.getGSMSettingValue('CBR_Creation_Batch_Size'));
            try{
                PreSalesValueConfirmationBatchClass pvc = new PreSalesValueConfirmationBatchClass();
                Database.executeBatch(pvc, batchsize);
                res='1:Completed';
            }
            catch(Exception e)
            {
                res = '0:Error in PreSalesValueConfirmationBatchClass . \n ' + e.getMessage();
            }

        }

    //Added by Aditya
    else if(jobType.equals('Scrub IP Addresses')){
        SC_ScrubIPAddresses_Batch scrubIPAddresses = new SC_ScrubIPAddresses_Batch();
        database.executebatch(scrubIPAddresses, 50);
        res='1: Completed';
    }


    else if(jobType.equals('Send IAT Survey')){
            GSSSurvey_SendSurveyToUsers sendSurveyToUsersInstance = new GSSSurvey_SendSurveyToUsers();
            sendSurveyToUsersInstance.sendSurveyToATMs();
            res='1: Completed';
    }

    // Commented by Vamsee
    /*
    //Added by Aditya
    else if(jobType.equals('Autogen PIVC Batch')){
            SC_Autogen_PIVC_Batch pivcBatch = new SC_Autogen_PIVC_Batch();
            database.executebatch(pivcBatch);
            res='1: Completed';
    }
    */
    // end of changes by Vamsee

    // changes by Vandhana for Autogen Order Form Review AMG cases - ESESP-646
    else if(jobType.equals('Autogen Order Form Review Batch')){
            SC_Autogen_Order_Form_Batch ofrBatch = new SC_Autogen_Order_Form_Batch();
            database.executebatch(ofrBatch);
            res='1: Completed';
    }

    // changes by Vandhana for Support Advocacy - ESESP-603
    else if(jobType.equals('Support Advocacy Batch')){
            SC_Sync_SupportAdvocacy_Batch saBatch = new SC_Sync_SupportAdvocacy_Batch();
            database.executebatch(saBatch);
            res='1: Completed';
    }
   //Added by Aditya
   else if(jobType.equals('Community NQLB Batch')){
            SC_SFCommunityNQLBBatch nqlbBatch = new SC_SFCommunityNQLBBatch();
            database.executebatch(nqlbBatch);
            res='1: Completed';
    }
    else if(jobType.equals('Community AddUserToGroup Batch')){
            SC_AddCommunityUserToGroupBatch commUserGrpBatch = new SC_AddCommunityUserToGroupBatch();
            database.executebatch(commUserGrpBatch);
            res='1: Completed';
    }
    else if(jobType.equals('SC Autogen SOA Batch')){
            SC_Autogen_SOA_Reminder_Batch autogenSOABatch = new SC_Autogen_SOA_Reminder_Batch();
            database.executebatch(autogenSOABatch);
            res='1: Completed';
    }
    else if(jobType.equals('SC Autogen Premium Three Batch')){
            SC_Autogen_Premium_Three_Batch autogenPremiumBatch = new SC_Autogen_Premium_Three_Batch();
            database.executebatch(autogenPremiumBatch);
            res='1: Completed';
    }
    else if(jobType.equals('SC CPS Retry Email Batch')){
            SC_CPS_RetryEmailBatch cpsRetryBatch = new SC_CPS_RetryEmailBatch();
            database.executebatch(cpsRetryBatch);
            res='1: Completed';
    }
    //End

    //Changes for FFPSA-496: Auto creation of Tasks by Shprasan
    else if (jobType.equals('PSA Create Task'))
    {
        Database.executeBatch(new PSA_CreateProjectTaskBatch());
        res='1: Completed';
    }

    //Added by kusharma
    else if(jobType.equals('CLI Deletion On DPM Deployment')){
        PSA_ProjectActions sendNotificationForCLIDel = new PSA_ProjectActions();
        sendNotificationForCLIDel.sendCLIDeletionEmail();
        res='1: Completed';
    }

    //Added by kusharma as part of RAMD requirements.
    else if(jobType.equals('RAMDPendingRecordsProcessor')){
        Database.executeBatch(new RAMDPendingRecordsProcessorBatch(), 300);
        res='1: Completed';
    }
    else if(jobType.equals('RAMDProcessATMChanges')){
        Database.executeBatch(new RAMDProcessATMChangesBatch(), 300);
        res='1: Completed';
    }

    //SFDC-2110
    else if(jobType.equals('CreateSobjectBackupAuditFieldJob-CreateAuditRecord'))
    {	
        System.debug('Before CreateSobjectBackupAuditFieldJob-CreateAuditRecord');
        SObjectAuditClass.invokeSObjectAuditBackupFieldJob(jobType);
        System.debug('After CreateSobjectBackupAuditFieldJob-CreateAuditRecord');
        res='1: Completed';
    }

    else if(jobType.equals('Notify About Newly Created Fields'))
    {
        System.debug('Before Notify About Newly Created Fields');
        SObjectAuditClass.fieldReportCreation();
        System.debug('After Notify About Newly Created Fields');
        res='1: Completed';
    }
    //End of SFDC-2110

    //SFDC-2596
    else if (jobtype.equals('Lead Campaign Member Creation'))
     {
        try
        {
            MissingLeadCampaignMembersCreationJob mlcm = new MissingLeadCampaignMembersCreationJob();
            Database.executeBatch(mlcm);
            res='1:Completed';
        }
        catch(Exception e)
        {
            res = '0:Error while updating lead campaign member status. \n ' + e.getMessage();
        }
     }
     //End of SFDC-2596

     else if(jobtype.equals('Annuitas_ContactUpdate')){
         Integer contactUpdateBatchLimit = GSMSettings.getInt('AnnuitasContactUpdateBatchLimit');
         Annuitas_ContactUpdateBatch b = new Annuitas_ContactUpdateBatch();
         database.executebatch(b,contactUpdateBatchLimit);
         res='1: Completed';
     }else if(jobtype.equals('LeanData_ContactAccountMatch')){
         Integer jobSize =Integer.valueOf(MarketingUtilClass.getMarketingSettingsValue('LeandDataContactBatchSize'));
         LeanDataReassignContactBatch ldR = new LeanDataReassignContactBatch();
         database.executeBatch(ldr,jobSize);
         res='1: Completed';
     }
    else if (jobtype.equals('Update Lead On Account Update')){
        try
        {
            Integer leadUpdateBatchLimit = MarketingUtilClass.getInt('BatchSizeRelatedToFormulaUpdateCDP');
            UpdateLeadOnAccountUpdate updateLead = new UpdateLeadOnAccountUpdate();
            Database.executeBatch(updateLead, leadUpdateBatchLimit);
            res='1:Completed';
        }
        catch(Exception e)
        {
            res = '0:Error while updating Lead Updated_Date_For_CDP__c field. \n ' + e.getMessage();
        }
    }
    else if (jobtype.equals('Update Contact On Account Update')){
        try
        {
            Integer contactUpdateBatchLimit = MarketingUtilClass.getInt('BatchSizeRelatedToFormulaUpdateCDP');
            UpdateContactOnAccountUpdate updateContact = new UpdateContactOnAccountUpdate();
            Database.executeBatch(updateContact, contactUpdateBatchLimit);
            res='1:Completed';
        }
        catch(Exception e)
        {
            res = '0:Error while updating Contact Updated_Date_For_CDP__c field. \n ' + e.getMessage();
        }
    }
    else if (jobtype.equals('Update OCR On Opportunity Update')){
        try
        {
            Integer ocrUpdateBatchLimit = MarketingUtilClass.getInt('BatchSizeRelatedToFormulaUpdateCDP');
            UpdateOCROnOpportunityUpdate updateOCR = new UpdateOCROnOpportunityUpdate();
            Database.executeBatch(updateOCR, ocrUpdateBatchLimit);
            res='1:Completed';
        }
        catch(Exception e)
        {
            res = '0:Error while updating OCR Updated_Date_For_CDP__c field. \n ' + e.getMessage();
        }
    }
     else if(jobtype.equals('Lean Data Lead Automation for Account')){ //MARIT-418
         try{
             LeanDataUpdateLeadWithMatchedAcc ldulma = new LeanDataUpdateLeadWithMatchedAcc();
             database.executeBatch(ldulma);
             res='1: Completed';
             } catch(Exception e){
                 res = '0:Error while updating Lean Data Automate Account Update \n ' + e.getMessage();
             }
     } else if(jobtype.equals('CTA Auto Close Batch Job')){
         try{
             Integer autoCloseBatchSize =Integer.valueOf(MarketingUtilClass.getMarketingSettingsValue('CTACronAutoCloseBatchSize'));
             MARIT_CTAAutoCloseBatch ctaAutoClose = new MARIT_CTAAutoCloseBatch();
             database.executeBatch(ctaAutoClose, autoCloseBatchSize);
             res='1: Completed';
         } catch(Exception e){
             res = '0:Error while updating CTA Auto Close \n ' + e.getMessage();
         }
     } else if (jobtype.equals('Marketo Activity Batch Job')){
        try
        {
            MARIT_MarketoActivity marketoActivity = new MARIT_MarketoActivity();
            marketoActivity.execute(null);
            res='1:Completed';
        }
        catch(Exception e)
        {
            res = '0:Error while running daily marketo activity. \n ' + e.getMessage();
        }
    }  else if (jobtype.equals('Contact Owner Update Batch Job')){
        try
        {
            Integer contactUpdateBatchLimit = MarketingUtilClass.getInt('CTACronAutoCloseBatchSize');
            MARIT_ContactOwnerUpdateBatchJob contactOwnerUpdate = new MARIT_ContactOwnerUpdateBatchJob();
            Database.executeBatch(contactOwnerUpdate, contactUpdateBatchLimit);
            res='1:Completed';
        }
        catch(Exception e)
        {
            res = '0:Error while running daily contact Owner Update. \n ' + e.getMessage();
        }
    }
     //Changes by Sharath for ESESP-3536: case issue sync
     else if(jobtype.equals('Case Issue Sync'))
     {
        SC_CaseSiebelIssueSyncBatch syncBatch = new  SC_CaseSiebelIssueSyncBatch();
        Database.executeBatch(syncBatch,20);
        res='1: Completed';
     }
     //Changes by Vikas for ESESP-4175: New Approach for Autogen Case/Project Creation
     else if(jobtype.equals('GSS Autogen Batch'))
     {
         GSS_Autogen_Batch gssAutogenBatch = new GSS_Autogen_Batch();
         database.executebatch(gssAutogenBatch);
         res='1: Completed';
     }

        System.debug('Result is '+res);
        return res;
    }

    public static void insertBatchJobAndRun(String pJobType, String pRecordTypeName, Integer pCleanAfter)
    {
        Cron_Batch_Job__c batchJob = new Cron_Batch_Job__c();
        batchJob.Name = pJobType + ' : Testcase';
        batchJob.Batch_Job_Type__c = pJobType;
        batchJob.RecordTypeId = Schema.SObjectType.Cron_Batch_Job__c.getRecordTypeInfosByName().get(pRecordTypeName).getRecordTypeId();
        batchJob.Clean_After__c = pCleanAfter;
        batchJob.Run_Every__c = 1;
        batchJob.Period__c = 'Day';
        batchJob.Scheduled_to_Run__c = DateTime.now();
        batchJob.Validation_Override__c = true;
        insert batchJob;

        Cron_Batch_Run__c batchRun = new Cron_Batch_Run__c();
        batchRun.Trigger_Batch_Run__c = true;
        batchRun.Cron_Batch_Job__c = batchJob.Id;
        batchRun.Scheduled_to_Run__c =  DateTime.now();
        batchRun.Validation_Override__c = true;
        insert batchRun;
    }
    public static void insertBatchJobAndRun(String pJobType)
    {
        insertBatchJobAndRun(pJobType, 'Custom Job', 0);
    }

    Webservice static void insertFirstRunRecord(Id pBatchjobId)
    {
/*                List<Cron_Batch_Run__c> newRecords = new List<Cron_Batch_Run__c>();
                c.Trigger_Batch_Run__c = true;
                c.Cron_Batch_Job__c = '{!Cron_Batch_Job__c.Id}';
                c.Scheduled_to_Run__c = {!Cron_Batch_Job__c.Scheduled_to_Run__c};
                newRecords.push(c);

                String result = sforce.connection.create(newRecords);*/
        Cron_Batch_Job__c batchJob;
        for(Cron_Batch_Job__c bj:[select Id, Scheduled_to_Run__c from Cron_Batch_Job__c where Id = :pBatchjobId])
            batchJob = bj;

        Cron_Batch_Run__c batchRun = new Cron_Batch_Run__c();
        if(batchJob.Scheduled_to_Run__c == null || batchJob.Scheduled_to_Run__c <= Datetime.now())
            batchRun.Trigger_Batch_Run__c = true;
        batchRun.Cron_Batch_Job__c = batchJob.Id;
        //if (batchJob.Scheduled_to_Run__c > Datetime.now())
            batchRun.Scheduled_to_Run__c = batchJob.Scheduled_to_Run__c;
        //else
            //batchRun.Scheduled_to_Run__c = Datetime.now();
        insert batchRun;
    }

    public static DateTime calculateNextRun(Cron_Batch_Run__c pBatchRun)
    {
        DateTime now = datetime.now();
        DateTime nextRun;
        DateTime parentScheduledToRun =  pBatchRun.Parent_Scheduled_To_Run__c;
        //System.debug('now=' + now);
        //System.debug('nextRun=' + nextRun);
        //System.debug('ParentScheduledToRun=' + parentScheduledToRun);
        //System.debug('now init=' + now);

        // add a custom settings for Minutes/Hours
        if(pBatchRun.Scheduled_to_Run__c==null || pBatchRun.Parent_Scheduled_To_Run__c==null)
            pBatchRun.addError('Scheduled to Run cannot be empty');

        String str_Interval = pBatchRun.Period__c;
        if (str_Interval.contains('Hour'))
            nextRun = now.addHours(pBatchRun.Run_Every__c.intValue());
        else if (str_Interval.contains('Minute') || str_Interval.contains('Minutes'))
            nextRun = now.addMinutes(pBatchRun.Run_Every__c.intValue());
        else
        {
            System.debug('Inside non-Hour/minute block');
            nextRun = datetime.newInstance(now.year(), now.month(), now.day(), ParentScheduledToRun.hour(), ParentScheduledToRun.minute(), ParentScheduledToRun.second());
            //System.debug('next Run based on ParentScheduledToRun=' + nextRun);
            if (str_Interval.contains('Month'))
                nextRun= nextRun.addMonths(pBatchRun.Run_Every__c.intValue());
            else    if (str_Interval.contains('Week'))
                nextRun= nextRun.addDays(7*pBatchRun.Run_Every__c.intValue());
            else if (str_Interval.contains('Day'))
                nextRun= nextRun.addDays(pBatchRun.Run_Every__c.intValue());
        }
        //System.debug('next Run FINAL=' + nextRun);
        return nextRun;
    }

    public static void cronTriggerMethod(List<Cron_Batch_Run__c> cronBatchRunList)
    {
        //  This Apex trigger is designed to fire when the batch workflow scheduler
        //  checks the Trigger Batch Run checkbox or when changes are made to the Batch Run
        //  record manually.

        Boolean error = false;  // Var used by each batch job to flag and return an error to the Batch Run object.
        String results, res;    // Batch job results, also returned to the Batch Run object.
        List<Cron_Batch_Run__c> listOfNewRuns = new List<Cron_Batch_Run__c>();

        for (Cron_Batch_Run__c batchRun : cronBatchRunList)
        {
            System.debug(LoggingLevel.Error, 'Cron_Batch_Run__c:: '+batchRun);

            // Skip batch jobs not handled by this trigger

            if ( batchRun.Completed__c != null)
            {
                System.debug(LoggingLevel.Error, 'Job is already completed');
                continue;    // Job has alread run, skip all this

            }

            if ( batchRun.Trigger_Batch_Run__c == true && batchRun.Parent_Cron_Batch_Run__c==null)
            {
                System.debug(LoggingLevel.Error, 'Trigger Batch Run set. Running batch job.');

                // --------------- Batch Job Housekeeping --------------------
                  //Datetime lastrun = Datetime.now();
                  //Datetime lastrun = (batchRun.Scheduled_to_Run__c==null||batchRun.Scheduled_to_Run__c < Datetime.now()?Datetime.now():batchRun.Scheduled_to_Run__c);
                  Datetime lastrun;
                  if(batchRun.Scheduled_to_Run__c==null || batchRun.Scheduled_to_Run__c < Datetime.now())
                    lastrun = Datetime.now();
                  else
                    lastrun = batchRun.Scheduled_to_Run__c;

                  Datetime nextrun;
                  System.debug(LoggingLevel.Error, 'Last run '+lastrun);

                  nextrun = calculateNextRun(batchRun);//calculateNextRun(lastrun, batchRun);

                  /*CR 1476082: Cron scheduled job changes
                            -> If the calculated nextrun is lesser than Datetime.now then recalculate nextrun with current time.

                  if (nextrun < Datetime.now())
                  {
                      nextrun = calculateNextRun(Datetime.now(),batchRun);
                  } */

                // Create the next Batch Run and configure it so that the scheduler workflow
                // adds a Trigger_Batch_Run field update in the time-based workflow queue.
                Cron_Batch_Run__c newRun = new Cron_Batch_Run__c(
                        Scheduled_to_Run__c = nextrun,
                        Trigger_Batch_Run__c = false,
                        Cron_Batch_Job__c = batchRun.Cron_Batch_Job__c
                );
                // Code scanner clean up as part of SFDC-1314
                  listOfNewRuns.add(newRun);
               // insert newRun;

                // Update the current Batch Run dates and uncheck batch job trigger
                        batchRun.Completed__c = Datetime.now();
                        if (batchRun.Scheduled_to_Run__c == null)
                        {
                            batchRun.Scheduled_to_Run__c = lastrun;
                        }
                        //batchRun.Trigger_Batch_Run__c = false;

                // ------------ End Batch Job Housekeeping -------------------


                // ----------- Begin batch jobs -----------------
                System.debug(LoggingLevel.Error, 'going to start jobType');
                res = CronJobTypes.jobType(batchRun);


                // ----------- End batch jobs -----------------

                if (res.startsWith('0'))
                    error = true;

                if(res.startsWith('0') || res.startsWith('1'))
                    results = res.subString(2);
                else
                    results = res;

                // Report Governor Limit Stats and set return values
                String limitText = 'Aggregate Queries: '+
                        Limits.getAggregateQueries() +'/' +
                        Limits.getLimitAggregateQueries();
                limitText += '\nSOQL Queries: '+
                        Limits.getQueries() +'/' +
                        Limits.getLimitQueries();
                limitText += '\nQuery Rows: '+
                        Limits.getQueryRows() +'/' +
                        Limits.getLimitQueryRows();
                limitText += '\nDML Statements: '+
                        Limits.getDMLStatements() +'/' +
                        Limits.getLimitDMLStatements();
                System.debug(limitText);

                batchRun.Results__c = results;
                //batchRun.Results__c += '\n\n'+limitText;
                if (error)
                {
                    // write error to batch run notes field and set error flag
                    batchRun.Result__c = 'Error';
                } else
                {
                    batchRun.Result__c = 'Success';
                }
            }
        }
        // Code scanner clean up as part of SFDC-1314
        insert listOfNewRuns;
    }

    public static void sendCronErrorEmail(List<Cron_Batch_Run__c> triggerNew ,Map<Id, Cron_Batch_Run__c> triggerOldMap)
    {
        if (!sendCronErrorEmailFirstRunFlag || !GsmUtilClass.isFeatureToggleEnabled('isCronErrorMailViaCode'))
            return;
        string CRMOpsOrgWideId = GsmUtilClass.getPRMSettingValue('CRM_Ops_Org_Wide_Address'); //SFDC-2391
        String PartnerSfURL=null;
        String SFURL=null;

        if(PartnerSfURL==null || SfURL==null)
        {
            if (Test.isRunningTest()) {
                PartnerSfURL= GsmUtilClass.getGSMSettingValue('CFA_SendEmailController_SfUrl'); //SFDC-2391
                SfURL=GsmUtilClass.getGSMSettingValue('CFA_SendEmailController_SfUrl'); //SFDC-2391
            }
            else{
                Organization org=[select Fax,Division from Organization limit 1][0];
                PartnerSfURL=org.Fax;
                SFURL=org.Division;
            }
        }

        EmailTemplate EmTempInternal=null;
        for(EmailTemplate em:[select Body,Subject from EmailTemplate where Name='CronJobFailureAlert']) {
            EmTempInternal=em;
        }
        // check if email found, if not return.
        if (EmTempInternal==null)
            return;

        List<Cron_Batch_Run__c> cronBatchRunList = new List<Cron_Batch_Run__c>();
        String error='error';
        String SubjectText = EmTempInternal.Subject;
        String bodyText = EmTempInternal.Body;

        String emailDestro = GsmUtilClass.getGSMSettingValue('CronBatchJob_EmailDestro'); //SFDC-2391
        Messaging.SingleEmailMessage[] sendEmailList = new List<Messaging.SingleEmailMessage>();
        for(Cron_Batch_Run__c batchRun : triggerNew)
        {
            String tempEmailSubject=SubjectText;
            String tempEmailBody=bodyText;

            if (!batchRun.Trigger_Batch_Run__c || batchRun.Result__c==triggerOldMap.get(batchRun.id).Result__c || !error.equalsIgnoreCase(batchRun.Result__c))
                continue;
            else
            {
                tempEmailSubject = tempEmailSubject.replace('{!Cron_Batch_Run__c.Batch_Job_Name__c}', batchRun.Batch_Job_Name__c);
                tempEmailBody=tempEmailBody.replace('{!Cron_Batch_Run__c.Name}', batchRun.Name);

                tempEmailBody=tempEmailBody.replace('{!Cron_Batch_Run__c.Scheduled_to_Run__c}', batchRun.Scheduled_to_Run__c.format());
                tempEmailBody=tempEmailBody.replace('{!Cron_Batch_Run__c.Results__c}', batchRun.Results__c);
                tempEmailBody=tempEmailBody.replace('{!Cron_Batch_Run__c.Link}', SfURL+'/'+ batchRun.Id);

                sendEmailList.add(GsmUtilClass.createSingleEmailWithOrgId(emailDestro,'',tempEmailSubject,tempEmailBody,tempEmailBody,CRMOpsOrgWideId));
                System.debug('sendEmailList=' + sendEmailList);
                System.debug('Email Subject=' + tempEmailSubject);
                System.debug('Email Body=' + tempEmailBody);
            }
        }
        if (sendEmailList.size()>0)
        {
            Messaging.sendEmail(sendEmailList);
            system.debug('EmailList:'+sendEmailList);
            sendCronErrorEmailFirstRunFlag=false;
        }
    }
}