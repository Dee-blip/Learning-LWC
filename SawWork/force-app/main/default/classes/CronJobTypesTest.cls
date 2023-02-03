@isTest(seeAllData=false)
public class CronJobTypesTest
{
	//private static Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
	static
    {
    	System.runAs(utilTestClass.getTestRunUser())
      	{
        	utilTestClass.insertCustomSettings();

                  	}
    }





    public static testmethod void removeAccountPlanBatchTest()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            Test.startTest();
            Cron_Batch_Job__c testBatchJob = utilTestClass.createCronBatchJob('Remove Account Plan Access','Remove Account Plan Access');
            insert testBatchJob;
            Cron_Batch_Run__c testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
            insert testBatchRun;
            testBatchRun.Trigger_Batch_Run__c = true;
            update testBatchRun;

            testBatchJob = utilTestClass.createCronBatchJob('Update Missing Account Reassign Related Records','Update Missing Account Reassign Related Records');
            insert testBatchJob;
            testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
            insert testBatchRun;
            testBatchRun.Trigger_Batch_Run__c = true;
            update testBatchRun;
            Test.stopTest();
        }
    }


	public static testmethod void startBatchJobs1()
	{
		System.runAs(utilTestClass.getTestRunUser())
		{
			Test.startTest();

			Cron_Batch_Job__c testBatchJob = utilTestClass.createCronBatchJob('Clean Up','Clean Up');
			insert testBatchJob;
			Cron_Batch_Run__c testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('Inactive Campaign Clean Up','Inactive Campaign Clean Up');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('Active Account Reassignment','Active Account Reassignment');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('SendDocuSignInitiatorReminderEmail','SendDocuSignInitiatorReminderEmail');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('PRM DealAndMDF Notification','PRM DealAndMDF Notification');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('PRM Add Admin to sales team','PRM Add Admin to sales team');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('GetRSSFeed','GetRSSFeed');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('Launch Approval Notification Reminder','Launch Approval Notification Reminder');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('Fix Oppty-Product Forecast MRR','Fix Oppty-Product Forecast MRR');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('Unfollow Chatter','Unfollow Chatter');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('CriticalNAPLicenseAlert','CriticalNAPLicenseAlert');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('Auto-follow renewal Opportunities','Auto-follow renewal Opportunities');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			//test fix

            testBatchJob = utilTestClass.createCronBatchJob('Lead Auto-Conversion To Opportunity','Lead Auto-Conversion To Opportunity');
            insert testBatchJob;
            testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
            insert testBatchRun;
            testBatchRun.Trigger_Batch_Run__c = true;
            update testBatchRun;

            testBatchJob = utilTestClass.createCronBatchJob('Soasta Accounts With Pool User Email','Soasta Accounts With Pool User Email');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;


			testBatchJob = utilTestClass.createCronBatchJob('Address Doctor Validation Job','Address Doctor Validation Job');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			CronJobTypes.cronJobFirstRunFlag = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('Close Old Opportunities','Close Old Opportunities');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			CronJobTypes.cronJobFirstRunFlag = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('E-Sign alert for expired Order Forms','E-Sign alert for expired Order Forms');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('Cast Iron Monitoring','Cast Iron Monitoring');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

            // Commented as part of SFDC-2728
            //Recommiting the changes
			/*testBatchJob = utilTestClass.createCronBatchJob('Manual List Trigger','Manual List Trigger');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;
             */
			testBatchJob = utilTestClass.createCronBatchJob('Partner Oversharing','Partner Oversharing');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('Product Approval Escalations','Product Approval Escalations');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			//SFDC-2315
   //         testBatchJob = utilTestClass.createCronBatchJob('Order Approval Report Batch','Order Approval Report Batch');
			//insert testBatchJob;
			//testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			//insert testBatchRun;
			//testBatchRun.Trigger_Batch_Run__c = true;
			//update testBatchRun;

			Test.stopTest();
		}
	}

	public static testmethod void startBatchJobs2()
	{
        utilTestClass.SC_Autogen_init_Method();
		System.runAs(utilTestClass.getTestRunUser())
		{


			Cron_Batch_Job__c testBatchJob = utilTestClass.createCronBatchJob('Dollar Value Convert','Dollar Value Convert');
			insert testBatchJob;
			Cron_Batch_run__c testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('Account Engagement Level','Account Engagement Level');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('Update Restricted Country on Accounts','Update Restricted Country on Accounts');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('Current Sales Channel Insert and Update','Current Sales Channel Insert and Update');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('Current Sales Channel Delete','Current Sales Channel Delete');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('Contract Share Account Opportunity','Contract Share Account Opportunity');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('Revenue Alignment Waiver Unset','Revenue Alignment Waiver Unset');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('Update Account With NAP PSOR values from Contract','Update Account With NAP PSOR values from Contract');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('Send Mail For Opportunities Past Closed Date','Send Mail For Opportunities Past Closed Date');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('Update Forecasted Opportunity Count','Update Forecasted Opportunity Count');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('Partner Under Sharing','Partner Under Sharing');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			//Start of change By Aditya
			testBatchJob = utilTestClass.createCronBatchJob('Autogen COB Case creation Batch','Autogen COB Case creation Batch');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('Autogen TCR WAF Case creation Batch','Autogen TCR WAF Case creation Batch');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('Scrub IP Addresses','Scrub IP Addresses');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('Community NQLB Batch','Community NQLB Batch');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

            testBatchJob = utilTestClass.createCronBatchJob('SC Autogen SOA Batch','SC Autogen SOA Batch');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('SC Autogen Premium Three Batch','SC Autogen Premium Three Batch');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('SC CPS Retry Email Batch','SC CPS Retry Email Batch');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;
			//End of change By Aditya

            // added by Vandhana
			testBatchJob = utilTestClass.createCronBatchJob('Autogen Order Form Review Batch','Autogen Order Form Review Batch');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;
            Test.startTest();
			// added by Vandhana ESESP-603
			testBatchJob = utilTestClass.createCronBatchJob('Support Advocacy Batch','Support Advocacy Batch');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('Helpdesk Jobs','Helpdesk Jobs');
            insert testBatchJob;
            testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
            insert testBatchRun;
            testBatchRun.Trigger_Batch_Run__c = true;
            update testBatchRun;
            testBatchJob = utilTestClass.createCronBatchJob('Update Campaign Information','Update Campaign Information');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

            testBatchJob = utilTestClass.createCronBatchJob('Recite Contract Sharing','Recite Contract Sharing');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('CloseAdmin from Deal unsubmitted','CloseAdmin from Deal unsubmitted');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('CloseAdmin from Deal submitted','CloseAdmin from Deal submitted');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('CloseAdmin from Deal rejected','CloseAdmin from Deal rejected');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('Email Notify Deal submitted','Email Notify Deal submitted');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('Focus Attribute','Focus Attribute');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('Partner Executive Shares','Partner Executive Shares');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('Update Lead Campaign Member Status','Update Lead Campaign Member Status');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('Renewal Process','Renewal Process');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('Content Version Tag Copy','Content Version Tag Copy');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('Pre Sales Value Confirmation','Pre Sales Value Confirmation');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

            List<Cron_Batch_Run__c> listBatchRun = new List<Cron_Batch_Run__c>();
            listBatchRun.add(testBatchRun);

            Map<Id, Cron_Batch_Run__c> idToCronBatchRun = new Map<Id, Cron_Batch_Run__c>();
            idToCronBatchRun.put(testBatchRun.Id, testBatchRun);

            CronJobTypes.sendCronErrorEmailFirstRunFlag = true;
            CronJobTypes.sendCronErrorEmail(listBatchRun,idToCronBatchRun);

			Test.stopTest();
		}
	}

     //Changes by Sharath Prasannan for PSA batch jobs
	  public static testmethod void startBatchJobs3()
	  {
	    System.runAs(utilTestClass.getTestRunUser())
	    {
	      Test.startTest();

	      pse__Region__c corporate = new pse__Region__c();
	      corporate.Name = 'Corporate';
	      insert corporate;
	      List<PSA_Settings__c> psaSettings = new List<PSA_Settings__c>();

	      PSA_Settings__c psaSetting1 = new PSA_Settings__c();
	      psaSetting1.name = 'Work Item Limit';
	      psaSetting1.Value__c = '1';
	      psaSettings.add(psaSetting1);

	      PSA_Settings__c psaSetting2 = new PSA_Settings__c();
	      psaSetting2.name = 'Engineering Team Email';
	      psaSetting2.Value__c = 'shprasan@akamai.com';
	      psaSettings.add(psaSetting2);

	      PSA_Settings__c psaSetting3 = new PSA_Settings__c();
	      psaSetting3.name = 'FromEmailAdress';
	      if(URL.getSalesforceBaseUrl().toExternalForm().contains('qa') || URL.getSalesforceBaseUrl().toExternalForm().contains('QA'))
	      {
	            psaSetting3.Value__c = 'qa-ps-notify@akamai.com';
	      }
	      else
	      {
	            psaSetting3.Value__c = 'prod-ps-notify@akamai.com';
	      }
	      psaSettings.add(psaSetting3);

	      PSA_Settings__c psaSetting4 = new PSA_Settings__c();
	      psaSetting4.name = 'JobNotificationAdress';
	      psaSetting4.Value__c = 'shprasan@akamai.com';
	      psaSettings.add(psaSetting4);


	      insert psaSettings;

          SC_Case_Issue_Sync_Admin_Setting__c adminRec =  new SC_Case_Issue_Sync_Admin_Setting__c();
          adminRec.Access_Token_Issues_API__c = '';
          adminRec.Client_Certificate__c = 'EAA_KMI_Signed_Certificate';
          adminRec.Client_Id_Issues_API__c = '90f8e0f1-696b-46f9-a504-3811b8ce00fc';
          adminRec.Client_Secret_Issues_API__c = 'b8a4f2c9-24e5-4d5e-a794-6b98730b6915';
          adminRec.Hostname_Issues_API__c = 'https://qa.dash-ext.akamai.com/';
          adminRec.Oauth_Endpoint_Issues_API__c = 'oauth2/token';
          adminRec.Scope_Issues_API__c = 'network-services/issues/v1/issues/';
          insert adminRec;


	      Cron_Batch_Job__c testBatchJob = utilTestClass.createCronBatchJob('FFSendNegativeHourNotification','FFSendNegativeHourNotification');
	      insert testBatchJob;
	      Cron_Batch_run__c testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
	      insert testBatchRun;
	      testBatchRun.Trigger_Batch_Run__c = true;
	      update testBatchRun;

	      testBatchJob = utilTestClass.createCronBatchJob('PSA Delete Billing Queue Data','PSA Delete Billing Queue Data');
	      insert testBatchJob;
	      testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
	      insert testBatchRun;
	      testBatchRun.Trigger_Batch_Run__c = true;
	      update testBatchRun;


	      testBatchJob = utilTestClass.createCronBatchJob('PSA Set Approver','PSA Set Approver');
	      insert testBatchJob;
	      testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
	      insert testBatchRun;
	      testBatchRun.Trigger_Batch_Run__c = true;
	      update testBatchRun;

	      testBatchJob = utilTestClass.createCronBatchJob('PSA Update GDRAT Alignment','PSA Update GDRAT Alignment');
	      insert testBatchJob;
	      testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
	      insert testBatchRun;
	      testBatchRun.Trigger_Batch_Run__c = true;
	      update testBatchRun;

	      testBatchJob = utilTestClass.createCronBatchJob('PSA LicenseDeprovisionBatch','PSA LicenseDeprovisionBatch');
	      insert testBatchJob;
	      testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
	      insert testBatchRun;
	      testBatchRun.Trigger_Batch_Run__c = true;
	      update testBatchRun;

	      testBatchJob = utilTestClass.createCronBatchJob('PSA Timecard Approver Change','PSA Timecard Approver Change');
	      insert testBatchJob;
	      testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
	      insert testBatchRun;
	      testBatchRun.Trigger_Batch_Run__c = true;
	      update testBatchRun;

	      //19.4 Sujay : for IP scrubbing for Notes and PSA Daily App Notify
          testBatchJob = utilTestClass.createCronBatchJob('IP scrubbing for Notes','IP scrubbing for Notes');
	      insert testBatchJob;
	      testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
	      insert testBatchRun;
	      testBatchRun.Trigger_Batch_Run__c = true;
	      update testBatchRun;

          testBatchJob = utilTestClass.createCronBatchJob('PSA Daily App Notify','PSA Daily App Notify');
	      insert testBatchJob;
	      testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
	      insert testBatchRun;
	      testBatchRun.Trigger_Batch_Run__c = true;
	      update testBatchRun;

	      testBatchJob = utilTestClass.createCronBatchJob('Community AddUserToGroup Batch','Community AddUserToGroup Batch');
	      insert testBatchJob;
	      testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
	      insert testBatchRun;
	      testBatchRun.Trigger_Batch_Run__c = true;
	      update testBatchRun;

	      testBatchJob = utilTestClass.createCronBatchJob('PSA Timecard Reminder','PSA Timecard Reminder');
	      insert testBatchJob;
	      testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
	      insert testBatchRun;
	      testBatchRun.Trigger_Batch_Run__c = true;
	      update testBatchRun;

	      testBatchJob = utilTestClass.createCronBatchJob('PSA Weekly App Notify','PSA Weekly App Notify');
	      insert testBatchJob;
	      testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
	      insert testBatchRun;
	      testBatchRun.Trigger_Batch_Run__c = true;
	      update testBatchRun;

	      testBatchJob = utilTestClass.createCronBatchJob('PSA Weekly App Notify','PSA Weekly App Notify');
	      insert testBatchJob;
	      testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
	      insert testBatchRun;
	      testBatchRun.Trigger_Batch_Run__c = true;
	      update testBatchRun;

	      testBatchJob = utilTestClass.createCronBatchJob('PSA Create Task','PSA Create Task');
	      insert testBatchJob;
	      testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
	      insert testBatchRun;
	      testBatchRun.Trigger_Batch_Run__c = true;
	      update testBatchRun;

          testBatchJob = utilTestClass.createCronBatchJob('PSA BEDDaily','PSA BEDDaily');
	      insert testBatchJob;
	      testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
	      insert testBatchRun;
	      testBatchRun.Trigger_Batch_Run__c = true;
	      update testBatchRun;

          testBatchJob = utilTestClass.createCronBatchJob('PSA BEDWeekly','PSA BEDWeekly');
	      insert testBatchJob;
	      testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
	      insert testBatchRun;
	      testBatchRun.Trigger_Batch_Run__c = true;
	      update testBatchRun;
          
          testBatchJob = utilTestClass.createCronBatchJob('PSA PCLIAssociationHistory','PSA PCLIAssociationHistory');
	      insert testBatchJob;
	      testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
	      insert testBatchRun;
	      testBatchRun.Trigger_Batch_Run__c = true;
	      update testBatchRun;

          PSA_Timecard_Approval__c stopApproval = PSA_Timecard_Approval__c.getOrgDefaults();
          stopApproval.Stop_Approval__c = false;
          upsert stopApproval;

          testBatchJob = utilTestClass.createCronBatchJob('PSA Approved Hours Recalc','PSA Approved Hours Recalc');
	      insert testBatchJob;
	      testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
	      insert testBatchRun;
	      testBatchRun.Trigger_Batch_Run__c = true;
	      update testBatchRun;

          testBatchJob = utilTestClass.createCronBatchJob('PSA AutoRenewCases','PSA AutoRenewCases');
	      insert testBatchJob;
	      testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
	      insert testBatchRun;
	      testBatchRun.Trigger_Batch_Run__c = true;
	      update testBatchRun;

          testBatchJob = utilTestClass.createCronBatchJob('Case Issue Sync','Case Issue Sync');
	      insert testBatchJob;
	      testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
	      insert testBatchRun;
	      testBatchRun.Trigger_Batch_Run__c = true;
	      update testBatchRun;
          
          testBatchJob = utilTestClass.createCronBatchJob('PSA Auto Renew Projects Batch','PSA Auto Renew Projects Batch');
	      insert testBatchJob;
	      testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
	      insert testBatchRun;
	      testBatchRun.Trigger_Batch_Run__c = true;
	      update testBatchRun;

	      testBatchJob = utilTestClass.createCronBatchJob('PSA Correct Actual Hours','PSA Correct Actual Hours');
	      insert testBatchJob;
	      testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
	      insert testBatchRun;
	      testBatchRun.Trigger_Batch_Run__c = true;
	      update testBatchRun;


	      testBatchJob = utilTestClass.createCronBatchJob('PSA AutoCreateTimeOffProject','PSA AutoCreateTimeOffProject');
	      insert testBatchJob;
	      testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
	      insert testBatchRun;
	      testBatchRun.Trigger_Batch_Run__c = true;
	      update testBatchRun;

	      Test.stopTest();
	    }
	  }
	  //end of changes by Sharath Prasanna for PSA batch jobs


      //Below added by Ashin for SC_PS_Automation batch jobs
	  public static testmethod void startBatchJobs4()
	  {
	    System.runAs(utilTestClass.getTestRunUser())
	    {
	      Test.startTest();

          //************ Below Added by Ashin for ESESP-6983 2.b *************
          Cron_Batch_Job__c testBatchJob = utilTestClass.createCronBatchJob('SC Reminder Emails','SC_Reminder_Emails_Job');
	      insert testBatchJob;
	      Cron_Batch_run__c testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
	      insert testBatchRun;
	      testBatchRun.Trigger_Batch_Run__c = true;
	      update testBatchRun;
            
          testBatchJob = utilTestClass.createCronBatchJob('Manager Reminder Emails','Manager_Reminder_Emails_Job');
	      insert testBatchJob;
	      testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
	      insert testBatchRun;
	      testBatchRun.Trigger_Batch_Run__c = true;
	      update testBatchRun;
          // ************ Above added by Ashin for ESESP-6983 2.b ************

	      Test.stopTest();
	    }
	  }
      //Above added by Ashin for SC_PS_Automation batch jobs


	  // Changes by Q2O
	  public static testmethod void startBatchJobsQ2O()
      {
        System.runAs(utilTestClass.getTestRunUser())
        {
            Test.startTest();

            Cron_Batch_Job__c testBatchJob = utilTestClass.createCronBatchJob('Task Creation for Credit Check','Task Creation for Credit Check');
            insert testBatchJob;
            Cron_Batch_run__c testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
            insert testBatchRun;
            testBatchRun.Trigger_Batch_Run__c = true;
            update testBatchRun;

         }
       }
	//GSSServices changes
	public static testmethod void startGSSServicesBatch(){
        System.runAs(utilTestClass.getTestRunUser()){
            Test.startTest();
            Cron_Batch_Job__c testBatchJob = utilTestClass.createCronBatchJob('Send IAT Survey','Send IAT Survey');
            insert testBatchJob;
            Cron_Batch_run__c testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
            insert testBatchRun;
            testBatchRun.Trigger_Batch_Run__c = true;
            update testBatchRun;

            testBatchJob = utilTestClass.createCronBatchJob('CLI Deletion On DPM Deployment','CLI Deletion On DPM Deployment');
            insert testBatchJob;
            testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
            insert testBatchRun;
            testBatchRun.Trigger_Batch_Run__c = true;
            update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('RAMDPendingRecordsProcessor','RAMDPendingRecordsProcessor');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('RAMDProcessATMChanges','RAMDProcessATMChanges');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

            Test.stopTest();

         }
    }

    public static testmethod void startBatchJobsGSM4()
    {
    	System.runAs(utilTestClass.getTestRunUser())
    	{
    		Test.startTest();

			Cron_Batch_Job__c testBatchJob = utilTestClass.createCronBatchJob('CreateSobjectBackupAuditFieldJob-CreateAuditRecord','CreateSobjectBackupAuditFieldJob-CreateAuditRecord');
			insert testBatchJob;
			Cron_Batch_run__c testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('Notify About Newly Created Fields','Notify About Newly Created Fields');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('Update Channel Level on Opportunity','Update Channel Level on Opportunity');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('Update Last NAP Login on Contact','Update Last NAP Login on Contact');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			//testBatchJob = utilTestClass.createCronBatchJob('NAP Reporting For Partners','NAP Reporting For Partners');
			//insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('Lead Campaign Member Creation','Lead Campaign Member Creation');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

            //SFORCE-79
            /*
            testBatchJob = utilTestClass.createCronBatchJob('Order Approval Report Batch','Order Approval Report Batch');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;
            */

            testBatchJob = utilTestClass.createCronBatchJob('Purchase Order Account Collector Email','Purchase Order Account Collector Email');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

            testBatchJob = utilTestClass.createCronBatchJob('Campaign Cleanup Lead Opportunity','Campaign Cleanup Lead Opportunity');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

            testBatchJob = utilTestClass.createCronBatchJob('EOL Products Insert Update Job','EOL Products Insert Update Job');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

            testBatchJob = utilTestClass.createCronBatchJob('EOL Products Delete Job','EOL Products Delete Job');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

            testBatchJob = utilTestClass.createCronBatchJob('Lean Data Lead Automation for Account','Lean Data Lead Automation for Account');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

            CronJobTypes.insertFirstRunRecord(testBatchJob.id);
			Test.stopTest();
		}
    }
    public static testmethod void insertBatchJobAndRun_Test()
    {
    	System.runAs(utilTestClass.getTestRunUser()){
    		Test.startTest();
    		CronJobTypes.insertBatchJobAndRun('Update Forecasted Opportunity Count');
    		Test.stopTest();
    	}
    }


    public static testmethod void pastOpptyCloseDateNotificationBatch_Test()
    {
    	System.runAs(utilTestClass.getTestRunUser()){
    		Account acc = utilTestClass.CreateAccount('Test Account');
    		insert acc;
    		List<Opportunity> oppList = new List<Opportunity>();
            Opportunity opp1 = utilTestClass.CreateOpportunity('__Test Oppty 1','1-Create');
            opp1.AccountId = acc.Id;
            opp1.CloseDate = Date.today().addDays(-7);
            oppList.add(opp1);
            Opportunity opp2 = utilTestClass.CreateOpportunity('__Test Oppty 2','1-Create');
            opp2.AccountId = acc.Id;
            opp2.CloseDate = Date.today().addDays(-14);
            oppList.add(opp2);
            Opportunity opp3 = utilTestClass.CreateOpportunity('__Test Oppty 3','1-Create');
            opp3.AccountId = acc.Id;
            opp3.CloseDate = Date.today().addDays(-30);
            oppList.add(opp3);
            insert oppList;

    		Test.startTest();
    		Cron_Batch_Job__c batchJob = utilTestClass.createCronBatchJob('Past Oppty Close Date Notification','Past Oppty Close Date Notification');
			insert batchJob;
			Cron_Batch_run__c batchRun = utilTestClass.createCronBatchRun(batchJob.Id);
			insert batchRun;
			batchRun.Trigger_Batch_Run__c = true;
			update batchRun;
            batchJob = utilTestClass.createCronBatchJob('Update Campaign Information','Update Campaign Information');
			insert batchJob;
		    batchRun = utilTestClass.createCronBatchRun(batchJob.Id);
			insert batchRun;
            batchRun.Trigger_Batch_Run__c = true;
			update batchRun;
            batchJob = utilTestClass.createCronBatchJob('Annuitas_ContactUpdate','Annuitas_ContactUpdate');
			insert batchJob;
		    batchRun = utilTestClass.createCronBatchRun(batchJob.Id);
			insert batchRun;
            batchRun.Trigger_Batch_Run__c = true;
			update batchRun;
            batchJob = utilTestClass.createCronBatchJob('Update Campaign Information','Update Campaign Information');
			insert batchJob;
		    batchRun = utilTestClass.createCronBatchRun(batchJob.Id);
			insert batchRun;
            batchRun.Trigger_Batch_Run__c = true;
			update batchRun;
            batchJob = utilTestClass.createCronBatchJob('PSA Daily App Notify','PSA Daily App Notify');
			insert batchJob;
		    batchRun = utilTestClass.createCronBatchRun(batchJob.Id);
			insert batchRun;
            batchRun.Trigger_Batch_Run__c = true;
			update batchRun;
            batchJob = utilTestClass.createCronBatchJob('PSA Weekly App Notify','PSA Weekly App Notify');
			insert batchJob;
		    batchRun = utilTestClass.createCronBatchRun(batchJob.Id);
			insert batchRun;
            batchRun.Trigger_Batch_Run__c = true;
			update batchRun;
            batchJob = utilTestClass.createCronBatchJob('PSA Set Approver','PSA Set Approver');
			insert batchJob;
		    batchRun = utilTestClass.createCronBatchRun(batchJob.Id);
			insert batchRun;
            batchRun.Trigger_Batch_Run__c = true;
			update batchRun;


    		Test.stopTest();
    	}
    }
    public static testmethod void startBatchJobsMarketing()
    {
    	System.runAs(utilTestClass.getTestRunUser())
    	{
    		Test.startTest();

			Cron_Batch_Job__c testBatchJob = utilTestClass.createCronBatchJob('LeanData_ContactAccountMatch','LeanData_ContactAccountMatch');
			insert testBatchJob;
			Cron_Batch_run__c testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('Update Lead On Account Update','Update Lead On Account Update');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('Update Contact On Account Update','Update Contact On Account Update');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			testBatchJob = utilTestClass.createCronBatchJob('Update OCR On Opportunity Update','Update OCR On Opportunity Update');
			insert testBatchJob;
			testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
			insert testBatchRun;
			testBatchRun.Trigger_Batch_Run__c = true;
			update testBatchRun;

			Account acc1 = utilTestClass.CreateAccount('__Test Account');
            acc1.Type = 'Lead';
            acc1.Website = 'www.test.com';
            acc1.Rev_Aligned__c = false;
            insert acc1;

            Merge_Contract_Header__c contract = new Merge_Contract_Header__c();
            contract.Account_Name__c = acc1.id;
            contract.Revenue_Aligned__c = true;
            insert contract;
            
            testBatchJob = utilTestClass.createCronBatchJob('Revenue Alignment Update Contract To Account','Revenue Alignment Update Contract To Account');
            insert testBatchJob;
            testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
            insert testBatchRun;
            testBatchRun.Trigger_Batch_Run__c = true;
            update testBatchRun;

			Test.stopTest();
		}
	}
}