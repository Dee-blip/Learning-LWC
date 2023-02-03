@isTest
private class PACE_PhaseMovementMailer_TestClass {
	
	@isTest static void testScheduledJob() {
		PACE_Program__c program = new PACE_Program__c (Program_Phase__c = 'Launch', Mail_exception__c = false, Program_Manager__c = UserInfo.getUserId(), Division__c = 'Media',Name = 'Launch Phase Pgm',Program_Type__c='New Product',Version__c='1.0');
	    insert program;

	    program.Planned_LA__c = Date.today() - 1;
	    program.Planned_GA__c = Date.today() - 1;
	    update program;

	    PACE_Program__c program2 = new PACE_Program__c (Program_Phase__c = 'Development', Mail_exception__c = false, Program_Manager__c = UserInfo.getUserId(), Division__c = 'Media',Name = 'Development Phase Pgm',Program_Type__c='New Product',Version__c='1.0');
	    insert program2;

	    program2.Planned_LC__c = Date.today() - 1;
	    update program2;

	    PACE_Program__c program3 = new PACE_Program__c (Program_Phase__c = 'Concept', Mail_exception__c = false, Program_Manager__c = UserInfo.getUserId(), Division__c = 'Media',Name = 'Concept Phase Pgm',Program_Type__c='New Product',Version__c='1.0');
	    insert program3;

	    program3.Skipped_CC__c = true;
	    update program3;

	    PACE_Program__c program5 = new PACE_Program__c (Program_Phase__c = 'Concept', Mail_exception__c = false, Program_Manager__c = UserInfo.getUserId(), Division__c = 'Media',Name = 'Concept Phase Pgm2',Program_Type__c='New Product',Version__c='1.0');
	    insert program5;

	    program5.Planned_CC__c = Date.today() - 1;
	    update program5;

	    PACE_Program__c program4 = new PACE_Program__c (Program_Phase__c = 'Definition', Mail_exception__c = false, Program_Manager__c = UserInfo.getUserId(), Division__c = 'Media',Name = 'Definition Phase Pgm',Program_Type__c='New Product',Version__c='1.0');
	    insert program4;

	    program4.Planned_EC__c = Date.today() - 1;
	    update program4;
		Id EOL_EOS_CC_LockedRT =  Schema.SObjectType.PACE_Program__c.getRecordTypeInfosByName().get('EOL/EOS CC Locked').getRecordTypeId();
	    PACE_Program__c program6 = new PACE_Program__c (RecordTypeId=EOL_EOS_CC_LockedRT, Program_Phase__c = 'Definition', Mail_exception__c = false, Program_Manager__c = UserInfo.getUserId(), Division__c = 'Media',Name = 'EOL Phase Pgm',Program_Type__c='EOL/EOS',Version__c='1.0');
	    insert program6;

	    program6.Planned_EC__c = Date.today() - 1;
	    update program6;
		
	    PACE_Program__c program7 = new PACE_Program__c (RecordTypeId=EOL_EOS_CC_LockedRT, Program_Phase__c = 'Definition', Mail_exception__c = false, Program_Manager__c = UserInfo.getUserId(), Division__c = 'Media',Name = 'EOL Phase Pgm',Program_Type__c='EOL/EOS',Version__c='1.0');
	    insert program7;
	    Test.setCreatedDate(program7.Id, Date.today()-10);

	    PACE_Program__c program8 = new PACE_Program__c (Program_Phase__c = 'Concept', Mail_exception__c = false, Program_Manager__c = UserInfo.getUserId(), Division__c = 'Media',Name = 'Concept Phase Pgm2',Program_Type__c='New Product',Version__c='1.0');
	    insert program8;
	    Test.setCreatedDate(program8.Id, Date.today()-10);

	    PACE_Program__c program9 = new PACE_Program__c (Schedule_Status__c='At Risk', Program_Phase__c = 'Concept', Mail_exception__c = false, Program_Manager__c = UserInfo.getUserId(), Division__c = 'Media',Name = 'Concept Phase Pgm2',Program_Type__c='New Product',Version__c='1.0');
	    insert program9;

	    PACE_Program__c program10 = new PACE_Program__c (Resource_Status__c='At Risk', Program_Phase__c = 'Concept', Mail_exception__c = false, Program_Manager__c = UserInfo.getUserId(), Division__c = 'Media',Name = 'Concept Phase Pgm2',Program_Type__c='New Product',Version__c='1.0');
	    insert program10;

	    PACECustomSettings__c cs = new PACECustomSettings__c(Name='PACE_Batch_mail', Value__c='hverma@akamai.com');
	    insert cs;

	    PACECustomSettings__c cs1 = new PACECustomSettings__c(Name='Batch_ReplyToEmail', Value__c='hverma@akamai.com');
	    insert cs1;

		Test.startTest();
	    Datetime dt = Datetime.now().addSeconds(1);
	    String CRON_EXP = dt.second() + ' ' + dt.minute() + ' * ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();
	    String jobId = System.schedule('Test_Run', CRON_EXP, new PACE_PhaseMovementMailer());
	    Test.stopTest();
	    // Get the information from the CronTrigger API object
	    CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
	    System.assertEquals(CRON_EXP, ct.CronExpression);
	}

	@isTest static void testMailsForPhaseContractDates()
	{
		PACE_Program__c program = new PACE_Program__c (Program_Phase__c = 'Launch', Status__c = 'In Progress', Program_Manager__c = UserInfo.getUserId(), Division__c = 'Media',Name = 'Launch Phase Pgm',Program_Type__c='New Product',Version__c='1.0');
	    insert program;

	    program.Planned_LA__c = Date.today();
	    program.Planned_GA__c = Date.today()+1;
	    program.Planned_LC__c = Date.today();
	    program.Planned_Actual_SC__c = Date.today();
	    program.Phase_contract_LC_Date__c = Date.today() - 40;
	    program.Phase_contract_SC_Date__c = Date.today() - 40;
	    program.Phase_contract_LA_Date__c = Date.today() - 40;
	    program.Phase_contract_GA_Date__c = Date.today() - 40;
	    update program;

	    PACECustomSettings__c cs = new PACECustomSettings__c(Name='PACE_Batch_mail', Value__c='hverma@akamai.com');
	    insert cs;

	    PACECustomSettings__c cs1 = new PACECustomSettings__c(Name='Batch_ReplyToEmail', Value__c='hverma@akamai.com');
	    insert cs1;
	    
	    Test.startTest();
	    Datetime dt = Datetime.now().addSeconds(1);
	    String CRON_EXP = dt.second() + ' ' + dt.minute() + ' * ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();
	    String jobId = System.schedule('Test_Run', CRON_EXP, new PACE_PhaseMovementMailer());
	    Test.stopTest();
	    // Get the information from the CronTrigger API object
	    CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
	    System.assertEquals(CRON_EXP, ct.CronExpression);
	}
	
}