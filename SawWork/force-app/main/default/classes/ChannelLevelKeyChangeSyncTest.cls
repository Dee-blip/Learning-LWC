@isTest
private class ChannelLevelKeyChangeSyncTest {
	static
    {
      System.runAs(utilTestClass.getTestRunUser())
      {
        utilTestClass.insertCustomSettings();
      }
    }
    public static Map<String,GSM_Settings__mdt> testcaseCustomSettings = GsmUtilClass.getGsmSettingValue();    

	@isTest static void test_method_one() {
		// Implement test code
		//create opportunity
		User accOwnerUser = utilTestClass.CreateUser('accUsr1', 'Marketing Operations', 'Marketing Operations');
        insert accOwnerUser;
        Account_Reassignment_Rule__c rule = utilTestClass.CreateAccountReassignmentRule('__TestRule', accOwnerUser.Id, testcaseCustomSettings.get('User_Role').Value__c);
        
        
        Account acc = utilTestClass.CreateAccount('__Test Account'+utilTestClass.getRandomString(5));
        acc.OwnerId = accOwnerUser.Id;
        acc.Indirect_Customer__c = true;
        acc.Website = 'www.nowwhere@torun.com';     
        //acc.Parent_Division__c = 'Web Americas_Web';
        //acc.Region__c = 'WA Web';
        acc.TERR_HIER_1__c = 'APJ';
        acc.TERR_HIER_3__c = 'ANZ Media & Enterprise'; //SFDC-7937

        Account partneracc = utilTestClass.CreateAccount('__Test partner Account'+utilTestClass.getRandomString(5));
        partneracc.OwnerId = accOwnerUser.Id;
        partneracc.IsPartnerCustom__c = true;
        partneracc.Partner_Type__c = 'ADS Partner';
        partneracc.Partner_status__c = 'Partner';
        partneracc.Website = 'www.nowwherepartner@torun.com'; 
        partneracc.GSSM_Class__c = 'AT&T';
        partneracc.GSSM_Sector__c = 'AT&T';
        List<Account> accList = new List<Account>();
        accList.add(acc);
        accList.add(partneracc);

        
        System.runAs(accOwnerUser) {
            insert rule;
            //AccountTriggerClass.createUpdateEntitlementFirstRunFlag=true;
            insert accList;
            //insert chmlist;
        }
        //accList = [select id,IsPartnerCustom__c,Indirect_Customer__c,Parent_Division__c,Region__c from account];
        //acc = [select id,IsPartnerCustom__c,Indirect_Customer__c,Parent_Division__c,Region__c from account where id=:acc.id];
        //system.debug(LoggingLevel.ERROR,'accList: '+acc);

        //partneracc = [select id,IsPartnerCustom__c,Indirect_Customer__c,Parent_Division__c,Region__c from account where id=:partneracc.id];
        //system.debug(LoggingLevel.ERROR,'accList: '+partneracc);

        //for(Account accVar:accList){
        //    if(accVar.Indirect_Customer__c)
        //        acc = accVar;
        //    if(accVar.IsPartnerCustom__c)
        //        partneracc = accVar;
        //}
        //system.debug(LoggingLevel.ERROR,'partneracc: '+partneracc);
        //partneracc.IsPartner = true;
        //System.runAs(accOwnerUser){
        //    update partneracc;
        //}
        Opportunity oppty1 = utilTestClass.CreateOpportunity('__Test Oppty 0','1-Create');
        oppty1.AccountId =acc.Id;
        //oppty1.OwnerId = opptySCMOwnerUser.Id;
        oppty1.CloseDate = Date.today(); 
        Oppty1.deal_type__c = 'Indirect';
        oppty1.Partner_Involved__c = partneracc.id;
        Test.startTest();
        System.runAs(accOwnerUser){
            //AccountTriggerClass.createUpdateEntitlementFirstRunFlag=true;
            insert oppty1;
        }

        Channel_Hierarchy_Map__c chm1 = new Channel_Hierarchy_Map__c(Name='AT&T-AT&T',CHANNEL_GEOGRAPHY__c='Americas',CHANNEL_ID__c='1601',CHANNEL_LEVEL_1__c='Team AT&T',CHANNEL_LEVEL_2__c='Team AT&T',CHANNEL_LEVEL_3__c='Team AT&T',GLOBAL_PARTNER__c='AT&T');
        Channel_Hierarchy_Map__c chm2 = new Channel_Hierarchy_Map__c(Name='AT&T-AT&T-ANZ Media & Enterprise',CHANNEL_GEOGRAPHY__c='EMEA',CHANNEL_ID__c='2320',CHANNEL_LEVEL_1__c='Team UKI',CHANNEL_LEVEL_2__c='Team UKI',CHANNEL_LEVEL_3__c='Team UKI',GLOBAL_PARTNER__c='AT&T');
        List<Channel_Hierarchy_Map__c> chmlist = new List<Channel_Hierarchy_Map__c>();
        chmlist.add(chm1);
        chmlist.add(chm2);
        System.runAs(accOwnerUser) {
        	insert chmlist;
        	CronJobTypes.insertBatchJobAndRun('Update Channel Level on Opportunity');
        
        //create CHM
	        Integer batchsize = Integer.valueOf(GsmUtilClass.getPRMSettingValue('Channel_Level_on_Opportunity_Update_Batc'));
	        system.debug(LoggingLevel.ERROR,'batchsize:: '+batchsize);

	        ChannelLevelKeyChangeSync batchInstance= new ChannelLevelKeyChangeSync();
	        Database.executebatch(batchInstance,batchsize);
			Test.stopTest();
		}
        //chmlist = [select name from Channel_Hierarchy_Map__c];
        //system.debug(LoggingLevel.ERROR,'chmlist: '+chmlist);
        //for(Channel_Hierarchy_Map__c chmVar: chmlist){
        //    if(chmVar.name=='AT&T-AT&T')
        //        chm1=chmVar;
        //    else if(chmVar.name=='UKI Media-AT&T')
        //        chm2=chmVar;
        //}
        
        oppty1 = [select id,Channel_Hierarchy_Map__c from Opportunity where id=:oppty1.id];
        system.debug(LoggingLevel.ERROR,'oppty1: '+oppty1);
        system.assertEquals(oppty1.Channel_Hierarchy_Map__c,chm2.id);

        
        

		
	}
	
	
@isTest static void test_method_two() {
        // Implement test code
        //create opportunity
        User accOwnerUser = utilTestClass.CreateUser('accUsr1', 'Marketing Operations', 'Marketing Operations');
        insert accOwnerUser;
        Account_Reassignment_Rule__c rule = utilTestClass.CreateAccountReassignmentRule('__TestRule', accOwnerUser.Id, testcaseCustomSettings.get('User_Role').Value__c);
        
        
        Account acc = utilTestClass.CreateAccount('__Test Account'+utilTestClass.getRandomString(5));
        acc.OwnerId = accOwnerUser.Id;
        acc.Indirect_Customer__c = true;
        acc.Website = 'www.nowwhere@torun.com';     
        // acc.Parent_Division__c = 'Web Americas_Web';
        // acc.Region__c = 'WA Web';
        acc.TERR_HIER_1__c = 'APJ';
        acc.TERR_HIER_3__c = 'ANZ Media & Enterprise'; //SFDC-7937


        Account partneracc = utilTestClass.CreateAccount('__Test partner Account'+utilTestClass.getRandomString(5));
        partneracc.OwnerId = accOwnerUser.Id;
        partneracc.IsPartnerCustom__c = true;
        partneracc.Partner_Type__c = 'ADS Partner';
        partneracc.Partner_status__c = 'Partner';
        partneracc.Website = 'www.nowwherepartner@torun.com'; 
        partneracc.GSSM_Class__c = 'AT&T';
        partneracc.GSSM_Sector__c = 'AT&T';
        List<Account> accList = new List<Account>();
        accList.add(acc);
        accList.add(partneracc);

        
        System.runAs(accOwnerUser) {
            insert rule;
            insert accList;
        }
        
        Opportunity oppty1 = utilTestClass.CreateOpportunity('__Test Oppty 0','1-Create');
        oppty1.AccountId =acc.Id;
        //oppty1.OwnerId = opptySCMOwnerUser.Id;
        oppty1.CloseDate = Date.today(); 
        Oppty1.deal_type__c = 'Indirect';
        oppty1.Partner_Involved__c = partneracc.id;
        Test.startTest();
        System.runAs(accOwnerUser){
            //AccountTriggerClass.createUpdateEntitlementFirstRunFlag=true;
            insert oppty1;
        }

        Channel_Hierarchy_Map__c chm1 = new Channel_Hierarchy_Map__c(Name='AT&T-AT&T',CHANNEL_GEOGRAPHY__c='Americas',CHANNEL_ID__c='1601',CHANNEL_LEVEL_1__c='Team AT&T',CHANNEL_LEVEL_2__c='Team AT&T',CHANNEL_LEVEL_3__c='Team AT&T',GLOBAL_PARTNER__c='AT&T');
        Channel_Hierarchy_Map__c chm2 = new Channel_Hierarchy_Map__c(Name='AT&T-AT&T-ANZ Media & Enterprise',CHANNEL_GEOGRAPHY__c='EMEA',CHANNEL_ID__c='2320',CHANNEL_LEVEL_1__c='Team UKI',CHANNEL_LEVEL_2__c='Team UKI',CHANNEL_LEVEL_3__c='Team UKI',GLOBAL_PARTNER__c='AT&T');
        List<Channel_Hierarchy_Map__c> chmlist = new List<Channel_Hierarchy_Map__c>();
        chmlist.add(chm1);
        chmlist.add(chm2);
        System.runAs(accOwnerUser) {
            insert chmlist;
            CronJobTypes.insertBatchJobAndRun('Update Channel Level on Opportunity');
        
        //create CHM
            Integer batchsize = Integer.valueOf(GsmUtilClass.getPRMSettingValue('Channel_Level_on_Opportunity_Update_Batc'));
            system.debug(LoggingLevel.ERROR,'batchsize:: '+batchsize);

            ChannelLevelKeyChangeSyncOppty batchInstance= new ChannelLevelKeyChangeSyncOppty();
            Database.executebatch(batchInstance,batchsize);
            Test.stopTest();
        }
        
        oppty1 = [select id,Channel_Hierarchy_Map__c from Opportunity where id=:oppty1.id];
        system.debug(LoggingLevel.ERROR,'oppty1: '+oppty1);
        system.assertEquals(oppty1.Channel_Hierarchy_Map__c,chm2.id);

        
        

        
    }
    
    
}